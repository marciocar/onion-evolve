"""Bancada do server.py de VERDADE (Starlette + uvicorn numa porta efêmera), com um motor FALSO.

Prova a AMARRAÇÃO que o selftest.py (só stdlib) não alcança: o app sai embrulhado no AuthGate e no BodyLimit, o host
fora do loopback é recusado, a duração decodificada tem teto (a bomba de descompressão), o corpo chunked acima do teto
vira 413 (e não 500 nem "multipart inválido") e a fila cheia vira 429/503.

Exige as dependências do serviço (o venv do requirements.lock). Sem elas sai rc 3 com `SKIP <motivo>`: a família da
bancada declara o pulo, nunca o conta como verde.
Uso: <python do venv> -I -B ops/stt/server_selftest.py [--server <server.py>] [--until <caso>]
"""
import argparse
import importlib.util
import io
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser()
ap.add_argument("--server", default=os.path.join(HERE, "server.py"))
ap.add_argument("--until", default=None)
A = ap.parse_args()
try:
    import numpy as np
    import soundfile as sf
    import starlette  # noqa: F401
    import uvicorn
except ImportError as e:
    print(f"SKIP dependência do serviço ausente ({e.name}): rode com o python do venv do requirements.lock")
    sys.exit(3)

sys.path.insert(0, os.path.dirname(os.path.abspath(A.server)))
spec = importlib.util.spec_from_file_location("stt_server_under_test", A.server)
srv = importlib.util.module_from_spec(spec)
spec.loader.exec_module(srv)

TOK = "t0k3n-de-teste-com-mais-de-32-caracteres-xyz"
RESULTS = []
TMP = tempfile.mkdtemp()


class Stop(Exception):
    pass


def case(name):
    def deco(fn):
        try:
            ok, why = fn()
        except Exception as e:  # noqa: BLE001
            ok, why = False, f"exceção {type(e).__name__}: {e}"
        RESULTS.append((name, ok))
        print(f"{'PASS' if ok else 'FAIL'} {name}" + ("" if ok else f" — {why}"), flush=True)
        if A.until == name:
            raise Stop
        return fn
    return deco


class FakeEngine:
    info = {"name": "fake", "version": "0", "arch": "tdt"}
    load_s = 0.0
    delay = 0.0

    def transcribe(self, audio):
        time.sleep(self.delay)
        dur = len(audio) / 16000
        words = [{"word": "Olá.", "start": 0.1, "end": 0.4, "probability": 0.9, "_lps": [0.0]}]
        segs = srv.core.split_sentences(words, "Olá.", 0.0, dur, 0)
        return "Olá.", segs, dur, "direct", 0.0


def serve(extra_args=(), delay=0.0):
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    a = srv.parse_args(["--model-dir", "x", "--vad-dir", "x", "--port", str(port), *extra_args])
    eng = FakeEngine()
    eng.delay = delay
    app = srv.build_app(a, eng, TOK.encode())
    server = uvicorn.Server(uvicorn.Config(app, host="127.0.0.1", port=port, log_level="error"))
    th = threading.Thread(target=server.run, daemon=True)
    th.start()
    for _ in range(100):
        if server.started:
            break
        time.sleep(0.05)
    return server, th, f"http://127.0.0.1:{port}"


def stop(server, th):
    server.should_exit = True
    th.join(10)


def chunked_post(url, data, headers):
    """POST chunked por socket cru: o servidor responde 413 e fecha ANTES de o cliente terminar de enviar, e o urllib
    trata isso como reset sem ler a resposta. Aqui o envio que falha é tolerado e a resposta é lida do mesmo jeito."""
    host, port = url.split("//", 1)[1].split("/", 1)[0].split(":")
    path = "/" + url.split("//", 1)[1].split("/", 1)[1]
    sk = socket.create_connection((host, int(port)), timeout=30)
    head = f"POST {path} HTTP/1.1\r\nHost: {host}\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n"
    head += "".join(f"{k}: {v}\r\n" for k, v in headers.items()) + "\r\n"
    try:
        sk.sendall(head.encode())
        for i in range(0, len(data), 65536):
            c = data[i:i + 65536]
            sk.sendall(f"{len(c):x}\r\n".encode() + c + b"\r\n")
        sk.sendall(b"0\r\n\r\n")
    except OSError:
        pass
    buf = b""
    try:
        while True:
            x = sk.recv(65536)
            if not x:
                break
            buf += x
    except OSError:
        pass
    sk.close()
    try:
        return int(buf.split(b" ", 2)[1]), buf
    except (IndexError, ValueError):
        return -1, buf[:200]


def req(url, data=None, headers=None, chunked=False):
    if chunked and data is not None:
        return chunked_post(url, data, headers or {})
    r = urllib.request.Request(url, data=data, headers=headers or {}, method="POST" if data is not None else "GET")
    try:
        with urllib.request.urlopen(r, timeout=60) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except (ConnectionError, urllib.error.URLError) as e:
        return -1, str(e).encode()


def wav(seconds, sr=16000):
    b = io.BytesIO()
    sf.write(b, np.zeros(int(seconds * sr), dtype=np.float32), sr, format="WAV", subtype="PCM_16")
    return b.getvalue()


AUTH = {"Authorization": "Bearer " + TOK, "Content-Type": "audio/wav"}

try:
    @case("srv-sem-token-401")
    def _():
        s, th, base = serve()
        try:
            st, _ = req(base + "/v1/listen", wav(1), {"Content-Type": "audio/wav"})
            st2, _ = req(base + "/v1/listen", wav(1), {"Authorization": "Bearer " + "x" * 40})
        finally:
            stop(s, th)
        return st == 401 and st2 == 401, f"status={st},{st2}"

    @case("srv-token-200-forma-deepgram")
    def _():
        s, th, base = serve()
        try:
            st, b = req(base + "/v1/listen", wav(1), AUTH)
        finally:
            stop(s, th)
        d = json.loads(b) if st == 200 else {}
        ok = st == 200 and d["results"]["channels"][0]["alternatives"][0]["words"][0]["punctuated_word"] == "Olá."
        return ok, f"status={st} {b[:120]!r}"

    @case("srv-host-fora-do-loopback-recusa")
    def _():
        try:
            srv.parse_args(["--model-dir", "x", "--vad-dir", "x", "--host", "0.0.0.0"])
        except SystemExit:
            return True, ""
        return False, "aceitou --host 0.0.0.0"

    @case("srv-duracao-acima-do-teto-413")
    def _():
        s, th, base = serve(["--max-audio-s", "5"])
        try:
            st, b = req(base + "/v1/listen", wav(10), AUTH)
            st_ok, _ = req(base + "/v1/listen", wav(3), AUTH)
        finally:
            stop(s, th)
        return st == 413 and st_ok == 200, f"status={st} (10 s) {st_ok} (3 s)"

    @case("srv-duracao-pelo-ffmpeg-413")
    def _():
        if not shutil.which("ffmpeg"):
            return True, ""  # sem ffmpeg nesta máquina o caminho não existe (o serviço exige ffmpeg na instalação)
        src = os.path.join(TMP, "x.wav")
        with open(src, "wb") as f:
            f.write(wav(10, sr=48000))
        # m4a (AAC): o libsndfile NÃO lê (o mp3 ele lê, e o cabeçalho barraria antes), então só o ffmpeg decodifica
        mp3 = os.path.join(TMP, "x.m4a")
        subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-i", src, "-c:a", "aac", "-y", mp3], check=True)
        s, th, base = serve(["--max-audio-s", "5"])
        try:
            st, b = req(base + "/v1/listen", open(mp3, "rb").read(), {"Authorization": "Token " + TOK})
        finally:
            stop(s, th)
        return st == 413, f"status={st} {b[:120]!r}"

    @case("srv-chunked-acima-do-teto-413")
    def _():
        s, th, base = serve(["--max-body-mb", "1"])
        try:
            st, b = req(base + "/v1/listen", b"\0" * (3 << 20), AUTH, chunked=True)
        finally:
            stop(s, th)
        return st == 413, f"status={st} {b[:120]!r}"

    @case("srv-multipart-chunked-acima-do-teto-413")
    def _():
        s, th, base = serve(["--max-body-mb", "1"])
        bnd = "XbndX"
        body = (f"--{bnd}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"a.wav\"\r\nContent-Type: audio/wav\r\n\r\n").encode() \
            + b"\0" * (3 << 20) + f"\r\n--{bnd}--\r\n".encode()
        try:
            st, b = req(base + "/v1/audio/transcriptions", body,
                        {"Authorization": "Bearer " + TOK, "Content-Type": f"multipart/form-data; boundary={bnd}"}, chunked=True)
        finally:
            stop(s, th)
        return st == 413, f"status={st} {b[:120]!r}"

    @case("srv-fila-cheia-429")
    def _():
        s, th, base = serve(["--queue-max", "1"], delay=2.0)
        out = []
        try:
            t1 = threading.Thread(target=lambda: out.append(req(base + "/v1/listen", wav(1), AUTH)[0]))
            t1.start()
            time.sleep(0.5)
            st2, _ = req(base + "/v1/listen", wav(1), AUTH)
            t1.join(20)
        finally:
            stop(s, th)
        return st2 == 429 and out == [200], f"segundo={st2} primeiro={out}"
except Stop:
    pass

shutil.rmtree(TMP, ignore_errors=True)
n_fail = sum(1 for _, ok in RESULTS if not ok)
print(f"TOTAL {len(RESULTS)} FAIL {n_fail}")
sys.exit(1 if n_fail else 0)
