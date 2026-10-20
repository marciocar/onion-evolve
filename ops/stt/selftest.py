"""Bancada do núcleo do onion-stt (ops/stt/stt_core.py) — só stdlib, roda no CI sem o motor.

Uso: python3 -I -B ops/stt/selftest.py [--core <stt_core.py>] [--until <caso>]
  --core   carrega o núcleo deste caminho (a bancada passa uma CÓPIA mutada; o arquivo vivo nunca é mutado)
  --until  para depois do caso nomeado (o mutante daquele caso tem de reprovar ali)
Saída: uma linha PASS|FAIL <caso> por caso e, no fim, `TOTAL <n> FAIL <k>`; rc 0 só sem FAIL.
"""
import argparse
import asyncio
import importlib.util
import json
import os
import sys
import tempfile

ap = argparse.ArgumentParser()
ap.add_argument("--core", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "stt_core.py"))
ap.add_argument("--smoke", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "smoke.py"))
ap.add_argument("--until", default=None)
A = ap.parse_args()


def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


core = _load("stt_core_under_test", A.core)
smoke = _load("stt_smoke_under_test", A.smoke)
FIXTURE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures", "fleurs-ptbr-8821974356183732066.flac")

TOK = b"t0k3n-de-teste-com-mais-de-32-caracteres-xyz"
RESULTS = []
TMPDIRS = []


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


# ── ASGI de teste ────────────────────────────────────────────────────────────────────────────────────
def asgi_call(app_factory, scope, chunks=(b"",)):
    """Roda um app ASGI embrulhado; devolve (status, corpo, app_interno_chamado, bytes_lidos_pelo_app)."""
    seen = {"called": False, "read": 0}
    sent = []

    async def inner(scope, receive, send):
        seen["called"] = True
        if scope["type"] == "http":
            while True:
                m = await receive()
                seen["read"] += len(m.get("body", b""))
                if not m.get("more_body"):
                    break
            await send({"type": "http.response.start", "status": 200, "headers": []})
            await send({"type": "http.response.body", "body": b"ok"})
        else:
            await send({"type": "websocket.accept"})

    msgs = [{"type": "http.request", "body": c, "more_body": i + 1 < len(chunks)} for i, c in enumerate(chunks)]

    async def receive():
        return msgs.pop(0) if msgs else {"type": "http.disconnect"}

    async def send(m):
        sent.append(m)

    asyncio.run(app_factory(inner)(scope, receive, send))
    status = next((m.get("status") for m in sent if m["type"] == "http.response.start"), None)
    body = b"".join(m.get("body", b"") for m in sent if m["type"] == "http.response.body")
    ws_close = next((m.get("code") for m in sent if m["type"] == "websocket.close"), None)
    return status, body, seen["called"], seen["read"], ws_close


def http_scope(path, headers=()):
    return {"type": "http", "path": path, "method": "POST", "headers": [(k.encode(), v.encode()) for k, v in headers]}


def gate(app):
    return core.AuthGate(app, TOK)


try:
    # ── autenticação ─────────────────────────────────────────────────────────────────────────────────
    @case("token-vazio-fail-closed")
    def _():
        return core.authorized("Bearer ", b"") is False and core.authorized("Bearer x", b"") is False, "token vazio deixou passar"

    @case("bearer-aceito")
    def _():
        return core.authorized("Bearer " + TOK.decode(), TOK), "Bearer correto recusado"

    @case("token-scheme-deepgram-aceito")
    def _():
        return core.authorized("Token " + TOK.decode(), TOK), "Token correto (Deepgram) recusado"

    @case("token-errado-recusa")
    def _():
        bad = TOK[:-1] + b"Q"
        return not core.authorized("Bearer " + bad.decode(), TOK) and not core.authorized("Bearer " + TOK.decode() + "x", TOK), \
            "token diferente passou"

    @case("esquema-estranho-recusa")
    def _():
        t = TOK.decode()
        return not any(core.authorized(h, TOK) for h in (f"Basic {t}", t, f"Bearer{t}", "", None)), "esquema fora de Bearer/Token passou"

    @case("authgate-401-sem-token")
    def _():
        st, body, called, _, _ = asgi_call(gate, http_scope("/v1/listen"))
        return st == 401 and not called and b"token" in body, f"status={st} app_chamado={called}"

    @case("authgate-401-token-errado")
    def _():
        st, _, called, _, _ = asgi_call(gate, http_scope("/v1/audio/transcriptions", [("Authorization", "Bearer " + "z" * 40)]))
        return st == 401 and not called, f"status={st} app_chamado={called}"

    @case("authgate-token-certo-passa")
    def _():
        st, _, called, _, _ = asgi_call(gate, http_scope("/v1/listen", [("Authorization", "Token " + TOK.decode())]))
        return st == 200 and called, f"status={st} app_chamado={called}"

    @case("authgate-health-livre")
    def _():
        st, _, called, _, _ = asgi_call(gate, {"type": "http", "path": "/health", "method": "GET", "headers": []})
        return st == 200 and called, f"status={st}"

    @case("authgate-ws-fecha-sem-token")
    def _():
        _, _, called, _, code = asgi_call(gate, {"type": "websocket", "path": "/v1/listen", "headers": []})
        return code == 1008 and not called, f"close={code} app_chamado={called}"

    @case("authgate-recusa-construir-sem-token")
    def _():
        try:
            core.AuthGate(lambda *a: None, b"")
        except core.ConfigError:
            return True, ""
        return False, "AuthGate aceitou token vazio"

    # ── token em arquivo ────────────────────────────────────────────────────────────────────────────
    def tokfile(content: bytes, mode: int):
        d = tempfile.mkdtemp()
        TMPDIRS.append(d)
        p = os.path.join(d, "token")
        with open(p, "wb") as f:
            f.write(content)
        os.chmod(p, mode)
        return d, p

    @case("load-token-ok-0600")
    def _():
        _, p = tokfile(TOK + b"\n", 0o600)
        return core.load_token(p) == TOK, "token válido 0600 não carregou"

    def refused(p):
        try:
            core.load_token(p)
        except core.ConfigError:
            return True
        return False

    @case("load-token-curto-recusa")
    def _():
        _, p = tokfile(b"curto\n", 0o600)
        return refused(p), "token curto aceito"

    @case("load-token-modo-aberto-recusa")
    def _():
        _, p = tokfile(TOK, 0o644)
        return refused(p), "token 0644 aceito"

    def in_creddir(d, fn):
        old = os.environ.get("CREDENTIALS_DIRECTORY")
        os.environ["CREDENTIALS_DIRECTORY"] = d
        try:
            return fn()
        finally:
            if old is None:
                os.environ.pop("CREDENTIALS_DIRECTORY", None)
            else:
                os.environ["CREDENTIALS_DIRECTORY"] = old

    @case("load-token-credencial-systemd-0440-ok")
    def _():
        d, p = tokfile(TOK, 0o440)
        return in_creddir(d, lambda: core.load_token(p) == TOK), "credencial 0440 do systemd recusada"

    @case("load-token-credencial-0444-recusa")
    def _():
        d, p = tokfile(TOK, 0o444)
        return in_creddir(d, lambda: refused(p)), "credencial legível por outros aceita"

    @case("load-token-0440-fora-da-credencial-recusa")
    def _():
        d, p = tokfile(TOK, 0o440)
        other = tempfile.mkdtemp()
        TMPDIRS.append(other)
        return in_creddir(other, lambda: refused(p)) and refused(p), "0440 fora do diretório de credenciais aceito"

    @case("load-token-symlink-recusa")
    def _():
        d, p = tokfile(TOK, 0o600)
        ln = os.path.join(d, "ln")
        os.symlink(p, ln)
        return refused(ln), "symlink aceito"

    @case("load-token-alfabeto-recusa")
    def _():
        _, p = tokfile(b"a" * 20 + b" " + b"b" * 20, 0o600)
        return refused(p) and refused(""), "token com espaço (ou caminho vazio) aceito"

    # ── teto de corpo ────────────────────────────────────────────────────────────────────────────────
    def lim(n):
        return lambda app: core.BodyLimit(app, n)

    @case("bodylimit-content-length-413")
    def _():
        st, _, called, _, _ = asgi_call(lim(100), http_scope("/v1/listen", [("Content-Length", "101")]), [b"x" * 101])
        return st == 413 and not called, f"status={st} app_chamado={called}"

    @case("bodylimit-chunked-413")
    def _():
        st, _, _, read, _ = asgi_call(lim(100), http_scope("/v1/listen"), [b"x" * 60, b"x" * 60, b"x" * 60])
        return st == 413 and read <= 100, f"status={st} lidos={read}"

    @case("bodylimit-content-length-invalido-413")
    def _():
        a = asgi_call(lim(100), http_scope("/v1/listen", [("Content-Length", "-5")]))[0]
        b = asgi_call(lim(100), http_scope("/v1/listen", [("Content-Length", "abc")]))[0]
        return a == 413 and b == 413, f"status={a},{b}"

    @case("bodylimit-dentro-passa")
    def _():
        st, _, called, read, _ = asgi_call(lim(100), http_scope("/v1/listen", [("Content-Length", "100")]), [b"x" * 50, b"x" * 50])
        return st == 200 and called and read == 100, f"status={st} lidos={read}"

    # ── palavras ─────────────────────────────────────────────────────────────────────────────────────
    TOKS = [" Lo", "go", " a", "pós", " o", " iní", "cio", "."]
    TS = [0.32, 0.40, 0.80, 0.88, 1.20, 1.40, 1.50, 1.60]
    LPS = [0.0] * len(TOKS)

    @case("words-agrupa-por-espaco")
    def _():
        w = core.words_from_tokens(TOKS, TS, LPS, 0.0, 3.0)
        got = [x["word"] for x in w]
        return got == ["Logo", "após", "o", "início."], f"palavras={got}"

    @case("words-fim-limitado-pela-seguinte")
    def _():
        # "a": 0.00 + 2×0.08 = 0.16, mas "b" começa em 0.10 → o fim de "a" é 0.10; "b": 0.10 + 0.16 = 0.26 (trecho até 3 s)
        w = core.words_from_tokens([" a", " b"], [0.0, 0.1], [0.0, 0.0], 0.0, 3.0)
        ok = [x["end"] for x in w] == [0.1, 0.26]
        return ok, f"fins={[x['end'] for x in w]}"

    @case("words-fim-limitado-pelo-trecho")
    def _():
        w = core.words_from_tokens([" a", " b"], [0.0, 0.5], [0.0, 0.0], 10.0, 10.55)
        return w[-1]["end"] == 10.55 and w[0]["start"] == 10.0, f"palavras={w}"

    @case("words-offset-absoluto")
    def _():
        w = core.words_from_tokens(TOKS, TS, LPS, 100.0, 103.0)
        return w[0]["start"] == 100.32 and w[-1]["start"] == 101.4, f"inícios={[x['start'] for x in w]}"

    @case("words-probabilidade-da-media-de-logprob")
    def _():
        import math
        w = core.words_from_tokens([" a", "b"], [0.0, 0.1], [math.log(0.5), math.log(0.5)], 0.0, 1.0)
        return w[0]["probability"] == 0.5, f"prob={w[0]['probability']}"

    @case("split-pontuacao-final")
    def _():
        w = core.words_from_tokens([" Um", ".", " Dois", "?", " três"], [0, 0.1, 0.5, 0.6, 1.0], [0.0] * 5, 0.0, 2.0)
        s = core.split_sentences(w, "Um. Dois? três", 0.0, 2.0, 7)
        return [x["text"] for x in s] == ["Um.", "Dois?", "três"] and [x["id"] for x in s] == [7, 8, 9], f"segs={[x['text'] for x in s]}"

    @case("split-fallback-texto")
    def _():
        s = core.split_sentences([], "texto sem tokens", 1.0, 2.0, 0)
        return len(s) == 1 and s[0]["text"] == "texto sem tokens" and s[0]["words"] == [], f"segs={s}"

    # ── formas que os clientes desserializam ───────────────────────────────────────────────────────────
    W = core.words_from_tokens(TOKS, TS, LPS, 0.0, 3.0)
    SEGS = core.split_sentences(W, "Logo após o início.", 0.0, 3.0, 0)

    @case("openai-verbose-forma")
    def _():
        b = core.openai_body("verbose_json", "Logo após o início.", SEGS, 3.0, "pt")
        need = {"task", "language", "duration", "text", "segments", "words"}
        seg_need = {"id", "start", "end", "text", "words", "avg_logprob", "no_speech_prob", "compression_ratio"}
        w_need = {"word", "start", "end", "probability"}
        ok = need <= set(b) and all(seg_need <= set(s) for s in b["segments"]) \
            and all(set(w) == w_need for s in b["segments"] for w in s["words"]) and len(b["words"]) == 4 \
            and "_lps" not in json.dumps(b)
        return ok, f"chaves={sorted(b)}"

    @case("openai-json-e-text")
    def _():
        return core.openai_body("json", "abc", SEGS, 1.0, None) == {"text": "abc"} and core.openai_body("text", "abc", SEGS, 1.0, None) == "abc", \
            "json/text com forma errada"

    @case("deepgram-forma")
    def _():
        ch = core.deepgram_channel("Logo após o início.", [w for s in SEGS for w in s["words"]])
        b = core.deepgram_body([ch], 3.0, "rid", "0" * 64, "2026-10-17T00:00:00+00:00", "uuid", {"name": "m"})
        md = b["metadata"]
        alt = b["results"]["channels"][0]["alternatives"][0]
        ok = {"request_id", "sha256", "created", "duration", "channels", "models", "model_info"} <= set(md) \
            and md["channels"] == 1 and set(alt) == {"transcript", "confidence", "words"} \
            and all(set(w) == {"word", "start", "end", "confidence", "punctuated_word"} for w in alt["words"]) \
            and alt["words"][3]["word"] == "início" and alt["words"][3]["punctuated_word"] == "início."
        return ok, f"alt={alt}"

    @case("duracao-acima-do-teto")
    def _():
        ok = core.audio_too_long(16000 * 10, 16000, 1, 5) is not None and core.audio_too_long(16000 * 3, 16000, 1, 5) is None \
            and core.audio_too_long(16000 * 4, 16000, 3, 5) is not None and core.audio_too_long(10, 0, 1, 5) is not None
        return ok, "teto de duração errado (por canal, no total ou cabeçalho inválido)"

    @case("canais-acima-do-teto")
    def _():
        return core.audio_too_long(16000, 16000, core.MAX_CHANNELS + 1, 5) is not None \
            and core.audio_too_long(16000, 16000, core.MAX_CHANNELS, 5) is None, "teto de canais errado"

    @case("frames-desconhecidos-vao-ao-ffmpeg")
    def _():
        return not core.header_frames_known(9223372036854775807) and core.header_frames_known(16000) \
            and not core.header_frames_known(-1), "sentinela de duração desconhecida errado"

    @case("pcm-params")
    def _():
        ok = core.raw_pcm_params({}) is None and core.raw_pcm_params({"encoding": "linear16", "sample_rate": "48000", "channels": "2"}) == (48000, 2)
        for q in ({"encoding": "mp3"}, {"encoding": "linear16", "channels": "0"}, {"encoding": "linear16", "channels": "9"},
                  {"encoding": "linear16", "sample_rate": "12345"}, {"encoding": "linear16", "sample_rate": "x"}):
            try:
                core.raw_pcm_params(q)
                ok = False
            except ValueError:
                pass
        return ok, "parâmetro de PCM inválido aceito"
    # ── a prova do verify (smoke.py) contra um servidor FALSO: ela tem de reprovar o que está errado ────
    import http.server
    import threading

    META = json.load(open(FIXTURE.rsplit(".", 1)[0] + ".json", encoding="utf-8"))
    REF_WORDS = META["reference"].split()

    def fake_server(mode):
        """mode: auth (exige o token) | open (200 para todos) | badtimes (palavras com fim < início) | wrong (outra frase)
        | sha (health com outro sha)"""
        words = [{"word": w, "start": round(0.3 + 0.4 * i, 3), "end": round(0.6 + 0.4 * i, 3), "probability": 0.99}
                 for i, w in enumerate(REF_WORDS)]
        text = META["reference"]
        if mode == "badtimes":
            words[3] = dict(words[3], start=2.0, end=1.0)
        if mode == "wrong":
            text = "nada a ver com a frase de referência"
            words = [dict(w, word="x") for w in words]

        class H(http.server.BaseHTTPRequestHandler):
            def log_message(self, *a):
                pass

            def _send(self, code, obj):
                b = json.dumps(obj).encode()
                self.send_response(code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(b)))
                self.end_headers()
                self.wfile.write(b)

            def do_GET(self):
                self._send(200, {"ready": True, "live": False, "engine": "fake",
                                 "server_sha256": "f" * 64 if mode == "sha" else "a" * 64,
                                 "core_sha256": "e" * 64 if mode == "coresha" else "c" * 64})

            def do_POST(self):
                n = int(self.headers.get("Content-Length") or 0)
                self.rfile.read(n)
                auth = self.headers.get("Authorization") or ""
                if mode != "open" and auth not in ("Bearer " + TOK.decode(), "Token " + TOK.decode()):
                    return self._send(401, {"error": "x"})
                if self.path.startswith("/v1/audio/transcriptions"):
                    return self._send(200, {"text": text, "segments": [{"words": words}], "words": words})
                dw = [{"word": w["word"].lower(), "start": w["start"], "end": w["end"], "confidence": 0.99,
                       "punctuated_word": w["word"]} for w in words]
                return self._send(200, {"results": {"channels": [{"alternatives": [{"transcript": text, "words": dw}]}]}})

        srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H)
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        return srv

    def run_smoke(mode, expect_sha="a" * 64, expect_core="c" * 64):
        srv = fake_server(mode)
        smoke.FAILS.clear()
        import contextlib
        import io as _io
        buf = _io.StringIO()
        try:
            with contextlib.redirect_stdout(buf):
                smoke.run_checks(f"http://127.0.0.1:{srv.server_address[1]}", TOK.decode(), FIXTURE, META, expect_sha, expect_core)
        finally:
            srv.shutdown()
        return list(smoke.FAILS), buf.getvalue()

    @case("smoke-aprova-servidor-correto")
    def _():
        fails, out = run_smoke("auth")
        return not fails and out.count("OK ") >= 8, f"falhas={fails}"

    @case("smoke-reprova-servidor-sem-auth")
    def _():
        fails, _ = run_smoke("open")
        return sum("401" in f for f in fails) == 3, f"falhas={fails}"

    @case("smoke-reprova-tempos-invalidos")
    def _():
        fails, _ = run_smoke("badtimes")
        return sum("tempo inválido" in f for f in fails) == 2, f"falhas={fails}"

    @case("smoke-reprova-recall-baixo")
    def _():
        fails, _ = run_smoke("wrong")
        return sum("recall" in f for f in fails) == 2, f"falhas={fails}"

    @case("smoke-reprova-codigo-diferente")
    def _():
        fails, _ = run_smoke("sha")
        return any("server_sha256" in f for f in fails), f"falhas={fails}"

    @case("smoke-reprova-nucleo-diferente")
    def _():
        fails, _ = run_smoke("coresha")
        return any("core_sha256" in f for f in fails), f"falhas={fails}"

    @case("smoke-recall-conta-repeticao")
    def _():
        return smoke.recall("a a b", "a b") == 2 / 3 and smoke.recall("Logo, após!", "logo após") == 1.0, "recall errado"

    # ── diarização: RTTM, falante por sobreposição, corte do segmento e o subprocesso que nunca derruba ──────────
    RTTM = ("SPEAKER x 1 0.300 5.000 <NA> <NA> speaker_1 <NA> <NA>\n"
            "SPEAKER x 1 9.000 4.000 <NA> <NA> speaker_2 <NA> <NA>\n"
            "\n# comentário\n"
            "SPEAKER x 1 17.500 5.000 <NA> <NA> speaker_1 <NA> <NA>\n")

    @case("rttm-le-turnos-ordenados")
    def _():
        t = core.parse_rttm(RTTM.splitlines()[1] + "\n" + RTTM)
        ok = t[0] == (0.3, 5.3, "speaker_1") and t[-1] == (17.5, 22.5, "speaker_1") and [x[0] for x in t] == sorted(x[0] for x in t)
        return ok, f"turnos={t}"

    @case("rttm-forma-invalida-recusa")
    def _():
        bad_lines = ("LEXEME x 1 0 1 <NA> <NA> a <NA> <NA>", "SPEAKER x 1 zero 1 <NA> <NA> a", "SPEAKER x 1 -1 1 <NA> <NA> a",
                     "SPEAKER x 1 0 0 <NA> <NA> a", "SPEAKER x 1 0 1 <NA> <NA> a;rm", "SPEAKER x 1 0 1", "SPEAKER x 1 nan 1 <NA> <NA> a")
        survivors = []
        for ln in bad_lines:
            try:
                core.parse_rttm(ln)
                survivors.append(ln)
            except ValueError:
                pass
        return not survivors, f"aceitou: {survivors}"

    @case("rttm-teto-de-falantes")
    def _():
        nine = "".join(f"SPEAKER x 1 {i}.0 0.5 <NA> <NA> s{i} <NA> <NA>\n" for i in range(core.DIAR_MAX_SPEAKERS + 1))
        eight = "".join(f"SPEAKER x 1 {i}.0 0.5 <NA> <NA> s{i} <NA> <NA>\n" for i in range(core.DIAR_MAX_SPEAKERS))
        try:
            core.parse_rttm(nine)
            return False, "aceitou 9 falantes"
        except ValueError:
            pass
        return len(core.parse_rttm(eight)) == core.DIAR_MAX_SPEAKERS, "recusou 8 falantes"

    TURNS = core.parse_rttm(RTTM)

    @case("speaker-ids-na-ordem-da-primeira-fala")
    def _():
        ids = core.speaker_ids([(9.0, 10.0, "z"), (0.0, 1.0, "q"), (20.0, 21.0, "z")])
        return ids == {"q": 0, "z": 1}, f"ids={ids}"

    @case("speaker-maior-sobreposicao")
    def _():
        ids = core.speaker_ids(TURNS)
        # a palavra 4,8–9,6 cobre 0,5 s do turno 1 (até 5,3) e 0,6 s do turno 2 (desde 9,0): fica com o 2
        return core.speaker_for(4.8, 9.6, TURNS, ids) == 1 and core.speaker_for(1.0, 1.5, TURNS, ids) == 0, "sobreposição errada"

    @case("speaker-na-pausa-vai-ao-turno-mais-proximo")
    def _():
        ids = core.speaker_ids(TURNS)
        ok = core.speaker_for(5.6, 5.9, TURNS, ids) == 0 and core.speaker_for(8.2, 8.6, TURNS, ids) == 1 \
            and core.speaker_for(1.0, 2.0, [], {}) is None
        return ok, "palavra na pausa sem o falante vizinho"

    @case("assign-speakers-em-cada-palavra")
    def _():
        ws = [{"word": "a", "start": 1.0, "end": 1.2}, {"word": "b", "start": 10.0, "end": 10.3}, {"word": "c", "start": 18.0, "end": 18.4}]
        got = core.assign_speakers(ws, TURNS)
        return [w["speaker"] for w in got] == [0, 1, 0] and "speaker" not in ws[0] and core.assign_speakers(ws, None) == ws, f"{got}"

    @case("diar-segmento-cortado-na-troca-de-falante")
    def _():
        ws = [{"word": "Um", "start": 4.0, "end": 4.5}, {"word": "dois", "start": 4.6, "end": 5.0},
              {"word": "três.", "start": 9.5, "end": 10.0}]
        seg = {"id": 7, "seek": 0, "start": 4.0, "end": 10.0, "text": "Um dois três.", "words": ws, "avg_logprob": -0.1}
        empty = {"id": 8, "seek": 0, "start": 18.0, "end": 19.0, "text": "só texto", "words": []}
        out = core.diarize_segments([seg, empty], TURNS)
        ok = [s["text"] for s in out] == ["Um dois", "três.", "só texto"] and [s["speaker"] for s in out] == [0, 1, 0] \
            and [s["id"] for s in out] == [0, 1, 2] and out[0]["end"] == 5.0 and out[1]["start"] == 9.5 \
            and all(w["speaker"] == s["speaker"] for s in out for w in s["words"]) and out[1]["avg_logprob"] == -0.1
        return ok, f"segs={[(s['id'], s['text'], s.get('speaker')) for s in out]}"

    @case("deepgram-palavra-leva-speaker")
    def _():
        w = {"word": "Olá.", "start": 0.1, "end": 0.4, "probability": 0.9}
        with_s, without = core.deepgram_word(dict(w, speaker=1)), core.deepgram_word(w)
        return with_s.get("speaker") == 1 and "speaker" not in without, f"{with_s} / {without}"

    # o subprocesso de verdade, com binários FALSOS em /bin/sh (só builtins: o PATH do filho é /nonexistent)
    def fake_bin(body):
        d = tempfile.mkdtemp()
        TMPDIRS.append(d)
        p = os.path.join(d, "nemo-speech")
        with open(p, "w") as f:
            f.write("#!/bin/sh\n" + body + "\n")
        os.chmod(p, 0o755)
        return d, p

    WRITE_RTTM = ('o=""; prev=""; for a in "$@"; do [ "$prev" = -o ] && o="$a"; prev="$a"; done\n'
                  'printf "%s\\n" "$*" > "${0%/*}/args"; printf "%s %s %s\\n" "$PATH" "$HOME" "$NEMO_SPEECH_MODEL_DIR" > "${0%/*}/env"\n'
                  'printf "SPEAKER onion-stt 1 0.000 1.000 <NA> <NA> speaker_1 <NA> <NA>\\nSPEAKER onion-stt 1 1.000 1.000 <NA> <NA> speaker_2 <NA> <NA>\\n" > "$o"')

    def run_diar(body, timeout=20.0, pcm=b"\0\0" * 32000):
        d, p = fake_bin(body)
        td = tempfile.mkdtemp()
        TMPDIRS.append(td)
        wav = os.path.join(td, "in.wav")
        core.write_wav16(wav, pcm, 16000)
        return core.diarize(p, os.path.join(d, "model.gguf"), wav, td, timeout), d, td

    @case("diarize-ok-com-o-comando-medido")
    def _():
        r, d, _ = run_diar(WRITE_RTTM)
        args = open(os.path.join(d, "args")).read().split()
        need = ["diarize", "--device", "cpu", "--preset", "v3-offline", "--format", "rttm", "-o"]
        ok = r.status == "ok" and len(r.turns) == 2 and r.public()["speakers"] == 2 and all(x in args for x in need) \
            and args[args.index("--preset") + 1] == "v3-offline" and args[args.index("--device") + 1] == "cpu"
        return ok, f"status={r.status} {r.reason} args={args}"

    @case("diarize-ambiente-fechado")
    def _():
        r, d, td = run_diar(WRITE_RTTM)
        env = open(os.path.join(d, "env")).read().split()
        return r.status == "ok" and env == ["/nonexistent", td, td], f"env={env}"

    @case("diarize-rc-nao-zero-vira-failed")
    def _():
        r, _, _ = run_diar('printf "boom\\n" >&2; exit 3')
        return r.status == "failed" and "rc=3" in r.reason and r.turns is None, f"{r.status} {r.reason}"

    @case("diarize-timeout-vira-failed")
    def _():
        r, _, _ = run_diar("exec /bin/sleep 30", timeout=0.5)
        return r.status == "failed" and "timeout" in r.reason, f"{r.status} {r.reason}"

    @case("diarize-sem-rttm-vira-failed")
    def _():
        r, _, _ = run_diar("exit 0")
        return r.status == "failed" and "no RTTM" in r.reason, f"{r.status} {r.reason}"

    @case("diarize-rttm-estranho-vira-failed")
    def _():
        r, _, _ = run_diar('o=""; prev=""; for a in "$@"; do [ "$prev" = -o ] && o="$a"; prev="$a"; done; printf "lixo total\\n" > "$o"')
        return r.status == "failed" and "ValueError" in r.reason, f"{r.status} {r.reason}"

    @case("diarize-rttm-vazio-vira-failed")
    def _():
        r, _, _ = run_diar('o=""; prev=""; for a in "$@"; do [ "$prev" = -o ] && o="$a"; prev="$a"; done; : > "$o"')
        return r.status == "failed" and "no speech" in r.reason, f"{r.status} {r.reason}"

    @case("diarize-binario-ausente-vira-failed")
    def _():
        td = tempfile.mkdtemp()
        TMPDIRS.append(td)
        wav = os.path.join(td, "in.wav")
        core.write_wav16(wav, b"\0\0", 16000)
        r = core.diarize(os.path.join(td, "nao-existe"), "m", wav, td, 5)
        r2 = core.diarize("/bin/true", "m", os.path.join(td, "sem-wav.wav"), td, 5)
        return r.status == "failed" and r.turns is None and r2.status == "failed" and "input missing" in r2.reason, \
            f"{r.status} {r.reason} / {r2.status} {r2.reason}"

    @case("diarize-wav-e-o-mesmo-audio")
    def _():
        import wave
        td = tempfile.mkdtemp()
        TMPDIRS.append(td)
        pcm = bytes(range(256)) * 10
        core.write_wav16(os.path.join(td, "a.wav"), pcm, 16000)
        with wave.open(os.path.join(td, "a.wav")) as w:
            ok = w.getnchannels() == 1 and w.getsampwidth() == 2 and w.getframerate() == 16000 and w.readframes(10 ** 6) == pcm
        return ok, "o WAV do diarizador não é o áudio recebido"

    @case("speaker-longe-de-turno-fica-sem-falante")
    def _():
        ws = [{"word": "a", "start": 1.0, "end": 1.2}, {"word": "longe", "start": 40.0, "end": 40.3}]
        got = core.assign_speakers(ws, TURNS)
        return got[0].get("speaker") == 0 and "speaker" not in got[1], f"{got}"

    @case("speaker-ids-pela-primeira-palavra")
    def _():
        turns = [(0.0, 1.0, "q"), (5.0, 6.0, "z"), (8.0, 9.0, "q")]
        got = core.assign_speakers([{"word": "x", "start": 5.2, "end": 5.4}, {"word": "y", "start": 8.2, "end": 8.4}], turns)
        return [w["speaker"] for w in got] == [0, 1], f"{got}"

    @case("diarize-rttm-velho-nao-conta")
    def _():
        d, p = fake_bin("exit 0")
        td = tempfile.mkdtemp()
        TMPDIRS.append(td)
        with open(os.path.join(td, "diar-out.rttm"), "w") as f:
            f.write("SPEAKER x 1 0 1 <NA> <NA> velho <NA> <NA>\n")
        wav = os.path.join(td, "in.wav")
        core.write_wav16(wav, b"\0\0" * 100, 16000)
        r = core.diarize(p, "m", wav, td, 10)
        return r.status == "failed" and "no RTTM" in r.reason, f"{r.status} {r.reason}"

    @case("diarize-rttm-grande-vira-failed")
    def _():
        old = core.DIAR_RTTM_MAX_BYTES
        core.DIAR_RTTM_MAX_BYTES = 10
        try:
            r, _, _ = run_diar(WRITE_RTTM)
        finally:
            core.DIAR_RTTM_MAX_BYTES = old
        return r.status == "failed" and "too large" in r.reason, f"{r.status} {r.reason}"

    @case("diarize-stderr-sem-caminho-do-modelo")
    def _():
        r, d, _ = run_diar('printf "erro lendo %s\\n" "$4" >&2; exit 1')
        model = os.path.join(d, "model.gguf")
        return r.status == "failed" and model not in r.reason and "<model>" in r.reason, f"{r.reason}"

    @case("diar-status-fora-do-vocabulario-recusa")
    def _():
        try:
            core.DiarResult("talvez")
            return False, "status inventado aceito"
        except ValueError:
            return True, ""

    @case("diar-timeout-escala-com-a-duracao")
    def _():
        return core.diar_timeout_s(0) == 120.0 and core.diar_timeout_s(3600) == 1920.0, "teto de tempo do diarizador errado"

    # ── a prova da diarização no smoke contra um servidor FALSO ─────────────────────────────────────────────
    DFIX = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures", "fleurs-ptbr-2spk-aba.flac")
    DMETA = json.load(open(DFIX.rsplit(".", 1)[0] + ".json", encoding="utf-8"))

    def diar_server(mode):
        """mode: ok | none (sem speaker) | one (tudo no falante 0) | failed (status failed) | nohealth (health sem diarização)"""
        ref_spk = {"A": 0, "B": 1}
        words = []
        for t in DMETA["turns"]:
            n = 6
            for i in range(n):
                s = t["start"] + (t["end"] - t["start"]) * i / n
                w = {"word": f"w{i}", "start": round(s, 3), "end": round(s + 0.3, 3), "probability": 0.9}
                if mode != "none":
                    w["speaker"] = 0 if mode == "one" else ref_spk[t["speaker"]]
                words.append(w)
        status = "failed" if mode == "failed" else "ok"

        class H(http.server.BaseHTTPRequestHandler):
            def log_message(self, *a):
                pass

            def _send(self, code, obj):
                b = json.dumps(obj).encode()
                self.send_response(code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(b)))
                self.end_headers()
                self.wfile.write(b)

            def do_GET(self):
                self._send(200, {"ready": True, "diarization": {"available": mode != "nohealth", "engine": "fake", "preset": "v3-offline"}})

            def do_POST(self):
                self.rfile.read(int(self.headers.get("Content-Length") or 0))
                if self.path.startswith("/v1/audio/transcriptions"):
                    segs = []
                    for w in words:
                        if segs and segs[-1]["speaker"] == w.get("speaker"):
                            segs[-1]["words"].append(w)
                        else:
                            segs.append({"speaker": w.get("speaker"), "words": [w]})
                    return self._send(200, {"text": DMETA["reference"], "segments": segs, "diarization": {"status": status}})
                dw = [dict(w, punctuated_word=w["word"], confidence=0.9) for w in words]
                return self._send(200, {"metadata": {"onion_diarization": [{"status": status, "reason": ""}]},
                                        "results": {"channels": [{"alternatives": [{"transcript": DMETA["reference"], "words": dw}]}]}})

        srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H)
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        return srv

    def run_dsmoke(mode):
        srv = diar_server(mode)
        smoke.FAILS.clear()
        import contextlib
        import io as _io
        buf = _io.StringIO()
        try:
            with contextlib.redirect_stdout(buf):
                smoke.run_diar_checks(f"http://127.0.0.1:{srv.server_address[1]}", TOK.decode(), DFIX, DMETA)
        finally:
            srv.shutdown()
        return list(smoke.FAILS), buf.getvalue()

    @case("smoke-diar-aprova-servidor-correto")
    def _():
        fails, out = run_dsmoke("ok")
        return not fails and out.count("OK ") == 4, f"falhas={fails} saída={out[-300:]}"

    @case("smoke-diar-reprova-sem-falante")
    def _():
        fails, _ = run_dsmoke("none")
        return sum("sem speaker" in f for f in fails) == 2, f"falhas={fails}"

    @case("smoke-diar-reprova-um-falante-so")
    def _():
        fails, _ = run_dsmoke("one")
        return sum("falante(s)" in f for f in fails) == 2, f"falhas={fails}"

    @case("smoke-diar-reprova-status-failed")
    def _():
        fails, _ = run_dsmoke("failed")
        return sum("status" in f for f in fails) == 2, f"falhas={fails}"

    @case("smoke-diar-reprova-health-sem-diarizacao")
    def _():
        fails, _ = run_dsmoke("nohealth")
        return any("/health declara" in f for f in fails), f"falhas={fails}"

    @case("smoke-diar-concordancia-exige-mapa-injetivo")
    def _():
        turns = [{"speaker": "A", "start": 0, "end": 1}, {"speaker": "B", "start": 2, "end": 3}]
        same = [{"start": 0.1, "end": 0.2, "speaker": 0}, {"start": 2.1, "end": 2.2, "speaker": 0}]
        diff = [{"start": 0.1, "end": 0.2, "speaker": 5}, {"start": 2.1, "end": 2.2, "speaker": 3}]
        return smoke.speaker_agreement(same, turns)[0] == 0.0 and smoke.speaker_agreement(diff, turns)[:2] == (1.0, 2), \
            "dois rótulos no mesmo falante contaram como acerto"
except Stop:
    pass

import shutil  # noqa: E402
for _d in TMPDIRS:
    shutil.rmtree(_d, ignore_errors=True)
n_fail = sum(1 for _, ok in RESULTS if not ok)
print(f"TOTAL {len(RESULTS)} FAIL {n_fail}")
sys.exit(1 if n_fail else 0)
