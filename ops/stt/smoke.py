"""Prova de pé do onion-stt (só stdlib). Roda DENTRO de uma unit transitória do systemd, com o token entregue por
LoadCredential= (o operador nunca o segura), em dois modos:

  --serve <python> <server.py> [args do servidor…]   sobe o servidor numa porta efêmera dentro da própria unit (o
                                                     ensaio do --apply, antes de trocar a unit de produção) e prova
  --url http://127.0.0.1:<porta>                     prova o serviço VIVO (o verify)

Cada checagem imprime OK|FALHA <o quê>; a última linha é sempre `n_fail=<N>` (sem ela, quem chamou NÃO MEDIU).
Checagens: /health pronto e com o sha256 do código esperado; 401 sem token, com token errado e com esquema estranho;
o fixture pt-BR transcrito pelas duas rotas (OpenAI verbose_json e Deepgram) com palavras, tempos crescentes dentro da
duração e recall mínimo das palavras da referência; e a rede de saída NEGADA (conexão a um IP público tem de falhar).
"""
from __future__ import annotations

import argparse
import json
import os
import socket
import subprocess
import sys
import time
import unicodedata
import urllib.error
import urllib.request
import uuid

FAILS = []


def ok(msg):
    print(f"OK {msg}", flush=True)


def bad(msg):
    FAILS.append(msg)
    print(f"FALHA {msg}", flush=True)


def norm_words(s: str):
    s = unicodedata.normalize("NFC", s).lower()
    s = "".join(c if (c.isalnum() or c.isspace() or c == "-") else " " for c in s)
    return s.split()


def recall(ref: str, hyp: str) -> float:
    r, h = norm_words(ref), norm_words(hyp)
    if not r:
        return 0.0
    pool = {}
    for w in h:
        pool[w] = pool.get(w, 0) + 1
    hit = 0
    for w in r:
        if pool.get(w, 0) > 0:
            pool[w] -= 1
            hit += 1
    return hit / len(r)


def request(url, data=None, headers=None, timeout=120):
    req = urllib.request.Request(url, data=data, headers=headers or {}, method="POST" if data is not None else "GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:  # noqa: S310 — URL local montada aqui
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


def multipart(fields, file_name, file_bytes, ctype="audio/flac"):
    b = uuid.uuid4().hex
    out = []
    for k, v in fields.items():
        out.append(f'--{b}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
    out.append(f'--{b}\r\nContent-Disposition: form-data; name="file"; filename="{file_name}"\r\nContent-Type: {ctype}\r\n\r\n'.encode())
    out.append(file_bytes)
    out.append(f"\r\n--{b}--\r\n".encode())
    return b"".join(out), f"multipart/form-data; boundary={b}"


def check_words(label, words, duration, key_start="start", key_end="end"):
    if not words:
        bad(f"{label}: sem palavras")
        return
    prev = -1.0
    for w in words:
        s, e = w.get(key_start), w.get(key_end)
        if not isinstance(s, (int, float)) or not isinstance(e, (int, float)) or not (0 <= s < e <= duration + 0.05) or s < prev:
            bad(f"{label}: tempo inválido na palavra {w!r}")
            return
        prev = s
    ok(f"{label}: {len(words)} palavra(s) com tempos crescentes dentro de {duration:.2f} s")


def run_checks(base, token, fixture, meta, expect_sha, expect_core_sha=""):
    st, body = request(f"{base}/health", timeout=10)
    try:
        h = json.loads(body)
    except ValueError:
        h = {}
    if st == 200 and h.get("ready") is True and h.get("live") is False:
        ok(f"/health pronto (motor {h.get('engine')}, vad_batch {h.get('vad_batch')})")
    else:
        bad(f"/health não pronto (HTTP {st})")
    if expect_sha:
        if h.get("server_sha256") == expect_sha:
            ok("o processo serve o código esperado (server_sha256 confere)")
        else:
            bad(f"server_sha256 {str(h.get('server_sha256'))[:12]} != esperado {expect_sha[:12]}")
    if expect_core_sha:
        if h.get("core_sha256") == expect_core_sha:
            ok("o processo serve o núcleo esperado (core_sha256 confere)")
        else:
            bad(f"core_sha256 {str(h.get('core_sha256'))[:12]} != esperado {expect_core_sha[:12]}")
    audio = open(fixture, "rb").read()
    body_mp, ctype = multipart({"response_format": "verbose_json", "language": "pt"}, os.path.basename(fixture), audio)
    for label, hdrs in (("sem token", {}), ("token errado", {"Authorization": "Bearer " + "x" * 48}),
                        ("esquema Basic", {"Authorization": "Basic " + token})):
        st1, _ = request(f"{base}/v1/audio/transcriptions", body_mp, {"Content-Type": ctype, **hdrs})
        st2, _ = request(f"{base}/v1/listen", audio, {"Content-Type": "audio/flac", **hdrs})
        if st1 == 401 and st2 == 401:
            ok(f"401 {label} nas duas rotas")
        else:
            bad(f"{label}: esperado 401/401, veio {st1}/{st2}")
    dur = float(meta["duration_s"])
    st, b = request(f"{base}/v1/audio/transcriptions", body_mp, {"Content-Type": ctype, "Authorization": "Bearer " + token}, timeout=300)
    if st != 200:
        bad(f"OpenAI com token: HTTP {st}")
    else:
        d = json.loads(b)
        rc = recall(meta["reference"], d.get("text", ""))
        (ok if rc >= meta["min_word_recall"] else bad)(f"OpenAI: recall {rc:.2f} (mínimo {meta['min_word_recall']})")
        check_words("OpenAI verbose_json", [w for s in d.get("segments", []) for w in s.get("words", [])], dur)
    st, b = request(f"{base}/v1/listen?language=pt-BR", audio, {"Content-Type": "audio/flac", "Authorization": "Token " + token}, timeout=300)
    if st != 200:
        bad(f"Deepgram com token: HTTP {st}")
    else:
        d = json.loads(b)
        try:
            alt = d["results"]["channels"][0]["alternatives"][0]
        except (KeyError, IndexError, TypeError):
            alt = {}
        rc = recall(meta["reference"], alt.get("transcript", ""))
        (ok if rc >= meta["min_word_recall"] else bad)(f"Deepgram: recall {rc:.2f} (mínimo {meta['min_word_recall']})")
        check_words("Deepgram", alt.get("words", []), dur)


def check_egress():
    """A unit nega rede de saída: conectar a um IP público TEM de falhar (e rápido, sem DNS)."""
    for ip in ("1.1.1.1", "8.8.8.8"):
        try:
            socket.create_connection((ip, 443), timeout=4).close()
            bad(f"rede de saída ABERTA: conectou em {ip}:443")
            return
        except OSError:
            pass
    ok("rede de saída negada (1.1.1.1:443 e 8.8.8.8:443 recusados)")


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def main(argv=None):
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--url")
    g.add_argument("--serve", nargs=argparse.REMAINDER)
    ap.add_argument("--fixture", required=True)
    ap.add_argument("--expect-sha", default="")
    ap.add_argument("--expect-core-sha", default="")
    ap.add_argument("--token-file", default=None)
    ap.add_argument("--no-egress-check", action="store_true")
    a = ap.parse_args(argv)
    proc = None
    try:
        cred_dir = os.environ.get("CREDENTIALS_DIRECTORY", "")
        tf = a.token_file or (os.path.join(cred_dir, "token") if cred_dir else "")
        try:
            token = open(tf).read().strip()
        except OSError as e:
            bad(f"não li o token ({e.strerror})")
            return 1
        meta = json.load(open(a.fixture.rsplit(".", 1)[0] + ".json", encoding="utf-8"))
        if a.serve:
            port = free_port()
            proc = subprocess.Popen([*a.serve, "--port", str(port), "--token-file", tf], stdout=subprocess.DEVNULL,
                                    stderr=subprocess.PIPE)
            base = f"http://127.0.0.1:{port}"
            for _ in range(180):
                if proc.poll() is not None:
                    bad(f"o servidor morreu no boot (rc {proc.returncode}): {proc.stderr.read()[-300:].decode(errors='replace')}")
                    return 1
                try:
                    if request(f"{base}/health", timeout=2)[0] == 200:
                        break
                except OSError:
                    pass
                time.sleep(1)
            else:
                bad("o servidor não ficou pronto em 180 s")
                return 1
        else:
            base = a.url.rstrip("/")
        run_checks(base, token, a.fixture, meta, a.expect_sha, a.expect_core_sha)
        if not a.no_egress_check:
            check_egress()
        return 1 if FAILS else 0
    except Exception as e:  # noqa: BLE001 — exceção é reprovação medida, nunca n_fail=0
        bad(f"exceção na prova: {type(e).__name__}: {str(e)[:200]}")
        return 1
    finally:
        if proc is not None:
            proc.terminate()
            try:
                proc.wait(20)
            except subprocess.TimeoutExpired:
                proc.kill()
        print(f"n_fail={len(FAILS)}", flush=True)


if __name__ == "__main__":
    sys.exit(main())
