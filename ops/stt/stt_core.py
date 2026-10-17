"""Núcleo PURO do serviço de STT do core (só stdlib): autenticação, teto de corpo, palavras e formas de resposta.

Mora separado do server.py para a bancada exercitar, no CI e sem o motor, o que decide segurança (o 401, o 413 e o
fail-closed do token) e o que decide a forma que os clientes desserializam. O server.py importa daqui; a bancada
(ops/stt/selftest.py) também. Nada aqui importa numpy, onnx_asr ou starlette.

Origem: reescrita (não cópia) do adaptador medido pela curadoria — repo onion-curation, pin 8d08d726c117,
docs/evolution/research/meeting-capture-2026-10/data/vps-stt/emenda2/server.py (sha256 do arquivo lido em
2026-10-17: ver o cabeçalho do server.py). As regras de agrupamento de palavras e as chaves das respostas seguem as
que a Emenda 2 do VPS-STT-PROTOCOL.md mediu contra os clientes (o verbose_json que a Vexa lê; o pré-gravado que o
anarlog desserializa); o código é outro.
"""
from __future__ import annotations

import hmac
import math
import os
import re
import stat
import unicodedata

FRAME_S = 0.08  # passo do encoder do Parakeet (10 ms × subamostragem 8): a duração mínima de um token
TOKEN_MIN_LEN = 32
AUTH_SCHEMES = ("bearer", "token")  # Bearer = clientes OpenAI (Vexa); Token = clientes Deepgram (anarlog)
PROTECTED_PREFIX = "/v1/"


class ConfigError(Exception):
    """Configuração recusada no boot: o serviço não sobe (fail-closed)."""


# ── token ────────────────────────────────────────────────────────────────────────────────────────────
def load_token(path: str) -> bytes:
    """Lê o token do arquivo (credencial do systemd ou arquivo 0600). Recusa: ausente, symlink, legível por outros,
    curto ou com caractere fora de [A-Za-z0-9._~+/=-]. Nunca devolve vazio."""
    if not path:
        raise ConfigError("token: caminho vazio (sem token o serviço não sobe)")
    try:
        st = os.lstat(path)
    except OSError as e:
        raise ConfigError(f"token: não li {path}: {e.strerror}") from None
    if stat.S_ISLNK(st.st_mode) or not stat.S_ISREG(st.st_mode):
        raise ConfigError(f"token: {path} não é arquivo regular")
    if st.st_mode & 0o077:
        raise ConfigError(f"token: {path} com modo {oct(st.st_mode & 0o777)} (grupo/outros têm acesso; exija 0600 ou 0400)")
    with open(path, "rb") as f:
        raw = f.read(4096)
    tok = raw.strip()
    if len(tok) < TOKEN_MIN_LEN:
        raise ConfigError(f"token: curto demais ({len(tok)} < {TOKEN_MIN_LEN})")
    if not re.fullmatch(rb"[A-Za-z0-9._~+/=-]+", tok):
        raise ConfigError("token: caractere fora do alfabeto aceito")
    return tok


def parse_auth(header_value: str | None) -> str | None:
    """'Bearer <t>' ou 'Token <t>' → <t>. Outro esquema, vazio ou ausente → None."""
    if not header_value:
        return None
    scheme, _, cred = header_value.strip().partition(" ")
    if scheme.lower() not in AUTH_SCHEMES:
        return None
    cred = cred.strip()
    return cred or None


def authorized(header_value: str | None, token: bytes) -> bool:
    """Comparação em tempo constante. Sem token configurado, NINGUÉM passa (fail-closed)."""
    if not token:
        return False
    cred = parse_auth(header_value)
    if cred is None:
        return False
    return hmac.compare_digest(cred.encode("utf-8", "surrogateescape"), token)


def _header(scope, name: bytes) -> str | None:
    for k, v in scope.get("headers") or ():
        if k.lower() == name:
            return v.decode("latin-1")
    return None


async def _send_json(send, status: int, body: bytes, extra=()):
    await send({"type": "http.response.start", "status": status,
                "headers": [(b"content-type", b"application/json"), (b"content-length", str(len(body)).encode()), *extra]})
    await send({"type": "http.response.body", "body": body})


class AuthGate:
    """ASGI: tudo sob /v1/ exige o token; o resto (/health) passa. WebSocket sob /v1/ sem token é fechado antes de
    aceitar. Fica FORA do app de rotas, então nenhuma rota nova escapa por esquecimento."""

    def __init__(self, app, token: bytes):
        if not token:
            raise ConfigError("AuthGate sem token")
        self.app, self.token = app, token

    async def __call__(self, scope, receive, send):
        if scope["type"] in ("http", "websocket") and scope.get("path", "").startswith(PROTECTED_PREFIX):
            if not authorized(_header(scope, b"authorization"), self.token):
                if scope["type"] == "websocket":
                    await send({"type": "websocket.close", "code": 1008})
                    return
                await _send_json(send, 401, b'{"error":{"message":"invalid or missing token","type":"invalid_request_error"}}',
                                 [(b"www-authenticate", b'Bearer realm="onion-stt"')])
                return
        await self.app(scope, receive, send)


class BodyLimit:
    """ASGI: recusa com 413 o corpo acima de `max_bytes` — pelo Content-Length declarado e, sem ele (chunked), pela
    contagem do que chega. O app nunca vê o byte acima do teto."""

    def __init__(self, app, max_bytes: int):
        if max_bytes <= 0:
            raise ConfigError("BodyLimit com teto não positivo")
        self.app, self.max_bytes = app, max_bytes

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        cl = _header(scope, b"content-length")
        if cl is not None:
            try:
                n = int(cl)
            except ValueError:
                n = -1
            if n < 0 or n > self.max_bytes:
                await _send_json(send, 413, b'{"error":{"message":"request body too large","type":"invalid_request_error"}}')
                return
        seen = 0
        started = False

        async def guarded_receive():
            nonlocal seen
            msg = await receive()
            if msg["type"] == "http.request":
                seen += len(msg.get("body", b""))
                if seen > self.max_bytes:
                    raise BodyTooLarge()
            return msg

        async def tracking_send(msg):
            nonlocal started
            if msg["type"] == "http.response.start":
                started = True
            await send(msg)

        try:
            await self.app(scope, guarded_receive, tracking_send)
        except BodyTooLarge:
            if not started:
                await _send_json(send, 413, b'{"error":{"message":"request body too large","type":"invalid_request_error"}}')


class BodyTooLarge(Exception):
    pass


# ── palavras e segmentos ─────────────────────────────────────────────────────────────────────────────
_EDGE_PUNCT = re.compile(r"^[\W_]+|[\W_]+$", re.UNICODE)
_SENTENCE_END = ".?!…"


def words_from_tokens(tokens, timestamps, logprobs, offset: float, seg_end: float):
    """Tokens SentencePiece → palavras com início, fim e probabilidade. Token que começa com espaço abre palavra.
    O fim de cada palavra é o último token + 2 passos do encoder, limitado pelo início da seguinte e pelo fim do
    trecho (`seg_end`, absoluto); nunca menor que início + 10 ms. Os tempos saem absolutos (somados a `offset`)."""
    tokens = list(tokens or [])
    timestamps = list(timestamps or [])
    logprobs = list(logprobs) if logprobs else [0.0] * len(tokens)
    groups = []
    for tok, ts, lp in zip(tokens, timestamps, logprobs):
        if tok.startswith(" ") or not groups:
            groups.append([tok.strip(), ts, ts, [lp]])
        else:
            g = groups[-1]
            g[0] += tok
            g[2] = ts
            g[3].append(lp)
    groups = [g for g in groups if g[0]]
    rel_end = seg_end - offset
    out = []
    for i, (text, start, last, lps) in enumerate(groups):
        end = last + 2 * FRAME_S
        if i + 1 < len(groups) and groups[i + 1][1] > start:
            end = min(end, groups[i + 1][1])
        if rel_end > 0:
            end = min(end, rel_end)
        end = max(end, start + 0.01)
        prob = min(math.exp(sum(lps) / len(lps)), 1.0)
        out.append({"word": text, "start": round(offset + start, 3), "end": round(offset + end, 3),
                    "probability": round(prob, 4), "_lps": lps})
    return out


def public_words(words):
    return [{k: v for k, v in w.items() if k != "_lps"} for w in words]


def split_sentences(words, fallback_text: str, start: float, end: float, first_id: int):
    """Corta as palavras em segmentos na pontuação final, como o Whisper entrega. Trecho sem palavras mas com texto
    vira um segmento só com o texto (nunca se perde fala reconhecida)."""
    runs, cur = [], []
    for w in words:
        cur.append(w)
        if w["word"][-1:] in _SENTENCE_END:
            runs.append(cur)
            cur = []
    if cur:
        runs.append(cur)
    segs = []
    for i, ws in enumerate(runs):
        lps = [lp for w in ws for lp in w["_lps"]]
        segs.append({"id": first_id + i, "seek": 0, "start": ws[0]["start"], "end": ws[-1]["end"],
                     "text": " ".join(w["word"] for w in ws), "tokens": [], "temperature": 0.0,
                     "avg_logprob": round(sum(lps) / len(lps), 5) if lps else 0.0,
                     "compression_ratio": 1.0, "no_speech_prob": 0.0, "words": public_words(ws)})
    if not segs and fallback_text:
        segs.append({"id": first_id, "seek": 0, "start": round(start, 3), "end": round(end, 3), "text": fallback_text,
                     "tokens": [], "temperature": 0.0, "avg_logprob": 0.0, "compression_ratio": 1.0,
                     "no_speech_prob": 0.0, "words": []})
    return segs


# ── formas de resposta ───────────────────────────────────────────────────────────────────────────────
OPENAI_FORMATS = ("json", "verbose_json", "text")


def openai_body(fmt: str, text: str, segments, duration: float, language: str | None):
    """Corpo de /v1/audio/transcriptions. `text` sai como text/plain (o server decide o content-type)."""
    if fmt == "text":
        return text
    if fmt == "json":
        return {"text": text}
    words = [w for s in segments for w in s["words"]]
    return {"task": "transcribe", "language": language or "unknown", "duration": round(duration, 3), "text": text,
            "segments": segments, "words": words}


def deepgram_word(w):
    bare = _EDGE_PUNCT.sub("", unicodedata.normalize("NFC", w["word"])).lower()
    return {"word": bare or w["word"].lower(), "start": w["start"], "end": w["end"], "confidence": w["probability"],
            "punctuated_word": w["word"]}


def deepgram_channel(text: str, words):
    dw = [deepgram_word(w) for w in words]
    conf = sum(w["confidence"] for w in dw) / len(dw) if dw else 0.0
    return {"alternatives": [{"transcript": text, "confidence": round(conf, 4), "words": dw}]}


def deepgram_body(channels, duration: float, request_id: str, sha256: str, created: str, model_uuid: str, model_info):
    return {"metadata": {"transaction_key": "deprecated", "request_id": request_id, "sha256": sha256, "created": created,
                         "duration": round(duration, 3), "channels": len(channels), "models": [model_uuid],
                         "model_info": {model_uuid: model_info}},
            "results": {"channels": channels}}


def audio_too_long(frames: int, sample_rate: int, channels: int, max_s: float) -> str | None:
    """Teto da DURAÇÃO decodificada (a bomba de descompressão: 4 MB de FLAC de silêncio são 6 h de áudio). Devolve a
    mensagem do 413, ou None. Vale por canal (a duração) e no total (canais × duração, o que o motor vai processar)."""
    if sample_rate <= 0 or frames < 0 or channels < 1:
        return "invalid audio header"
    if channels > MAX_CHANNELS:
        return f"too many channels ({channels} > {MAX_CHANNELS})"
    dur = frames / sample_rate
    if dur > max_s:
        return f"audio too long ({dur:.0f} s > {max_s:.0f} s)"
    if dur * channels > 2 * max_s:
        return f"audio too long across channels ({dur * channels:.0f} s > {2 * max_s:.0f} s)"
    return None


UNKNOWN_FRAMES = 1 << 60  # o libsndfile devolve ~2^63 quando o FLAC de stream não declara total_samples


def header_frames_known(frames: int) -> bool:
    """Cabeçalho que não sabe a própria duração (FLAC escrito para pipe) não é bomba: vai ao ffmpeg, que tem -t e -fs."""
    return 0 <= frames < UNKNOWN_FRAMES


TRUE_WORDS = ("true", "1", "yes")
PCM_RATES = (8000, 16000, 22050, 24000, 32000, 44100, 48000)
MAX_CHANNELS = 8


def raw_pcm_params(query) -> tuple[int, int] | None:
    """Query do Deepgram → (sample_rate, channels) para PCM cru, ou None se o corpo é contêiner. Só linear16.
    Levanta ValueError com mensagem para o 400."""
    enc = query.get("encoding")
    if not enc:
        return None
    if enc != "linear16":
        raise ValueError(f"encoding {enc} not supported (linear16 only)")
    try:
        sr = int(query.get("sample_rate") or 16000)
        ch = int(query.get("channels") or 1)
    except ValueError:
        raise ValueError("sample_rate and channels must be integers") from None
    if sr not in PCM_RATES:
        raise ValueError(f"sample_rate {sr} not supported")
    if not 1 <= ch <= MAX_CHANNELS:
        raise ValueError(f"channels must be 1..{MAX_CHANNELS}")
    return sr, ch
