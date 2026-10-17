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
ap.add_argument("--until", default=None)
A = ap.parse_args()
spec = importlib.util.spec_from_file_location("stt_core_under_test", A.core)
core = importlib.util.module_from_spec(spec)
spec.loader.exec_module(core)

TOK = b"t0k3n-de-teste-com-mais-de-32-caracteres-xyz"
RESULTS = []


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
        w = core.words_from_tokens(TOKS, TS, LPS, 0.0, 3.0)
        # "Logo": último token 0.40 + 2×0.08 = 0.56, a seguinte começa em 0.80 → 0.56; "após": 0.88+0.16=1.04 > 1.20? não → 1.04
        ok = w[0]["end"] == 0.56 and w[1]["end"] == 1.04 and all(x["end"] <= y["start"] for x, y in zip(w, w[1:]))
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
except Stop:
    pass

n_fail = sum(1 for _, ok in RESULTS if not ok)
print(f"TOTAL {len(RESULTS)} FAIL {n_fail}")
sys.exit(1 if n_fail else 0)
