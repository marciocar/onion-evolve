"""onion-stt — STT em LOTE do core, servido na VPS (core-only: ops/ não viaja para adotante).

Motor: NVIDIA Parakeet TDT 0.6b v3 em int8 (ONNX, repo istupakov/parakeet-tdt-0.6b-v3-onnx, CC-BY-4.0) pelo onnx-asr,
com o Silero VAD (istupakov/silero-vad-onnx, MIT) cortando o arquivo longo. Os dois chegam ao disco na INSTALAÇÃO
(ops/stt-service.sh, revisão fixada e sha256 conferido); em runtime nada é baixado (o --model-dir e o --vad-dir são
diretórios locais e a unit nega rede de saída).

Rotas (todas sob /v1/ exigem o token — `Authorization: Bearer <t>` ou `Token <t>`):
  POST /v1/audio/transcriptions   forma OpenAI (multipart `file`; response_format json|verbose_json|text). É o lote
                                   da extensão da Vexa: verbose_json com segments[].words[] e tempos.
  POST /v1/listen                  forma Deepgram pré-gravada (corpo = o áudio; WAV/FLAC/OGG, outros pelo ffmpeg, ou
                                   PCM cru com encoding=linear16&sample_rate&channels; multichannel=true separa os
                                   canais). É o lote do anarlog.
  GET  /health                     sem token: só prontidão e identidade do código (sha256 deste arquivo e do núcleo).
NÃO HÁ ao vivo: o WS /v1/listen do adaptador da curadoria NÃO foi reescrito. A regra pré-registrada do
VPS-STT-PROTOCOL.md deu N = 0 streams ao vivo nesta VPS sem GPU (D_MC_CAPTURA_WINDOWS_LOTE_VPS_1017); voltar a ele é
nova medição, não flag a ligar.

Configuração medida (Emenda 2 da curadoria, lote de 61 min: WER 6,19 %, RTF <= 0,118): intra_op 4, inter_op 1, 1
worker; VAD do lote FIXO (não vem do cliente): fim de fala 500 ms de silêncio, teto de 30 s por trecho, corte só acima
de 25 s. O `--vad-batch` (trechos por inferência) é o ajuste de memória: ver o grafo meeting-capture-2026-10.

Origem: REESCRITA (não cópia) de onion-curation @ 8d08d726c117,
docs/evolution/research/meeting-capture-2026-10/data/vps-stt/emenda2/server.py (sha256 199e1f82b52f…, lido em
2026-10-17). Mudou: Starlette em vez de FastAPI; auth por token (fail-closed) e teto de corpo como ASGI por fora das
rotas; VAD do lote fixo (o cliente não o ajusta mais); teto da DURAÇÃO decodificada (--max-audio-s, lido do cabeçalho
antes de decodificar); o ffmpeg (fallback do que o libsndfile não lê) só lê arquivo, com lista fechada de formatos; a
reamostragem fora de 16 kHz é do ffmpeg (a interpolação linear foi embora); sem o WS ao vivo.
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import io
import ipaddress
import json
import os
import subprocess
import sys
import tempfile
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import stt_core as core  # noqa: E402

SR = 16_000
MODEL_REPO = "istupakov/parakeet-tdt-0.6b-v3-onnx"
MODEL_UUID = str(uuid.uuid5(uuid.NAMESPACE_URL, MODEL_REPO))
FFMPEG_FORMATS = "wav,flac,ogg,mp3,matroska,webm,mov,mp4,m4a,3gp,3g2,mj2,aac,opus,w64,caf,aiff"
FFMPEG_TIMEOUT_S = 600


class AudioTooLong(ValueError):
    """Duração decodificada acima do teto: vira 413, nunca chega ao motor."""


def _sha256_file(p: str) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description="onion-stt: STT em lote (Parakeet TDT 0.6b v3 int8)")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--model-dir", required=True)
    ap.add_argument("--vad-dir", required=True)
    ap.add_argument("--token-file", default=None, help="padrão: $CREDENTIALS_DIRECTORY/token (LoadCredential= da unit)")
    ap.add_argument("--intra-op", type=int, default=4)
    ap.add_argument("--workers", type=int, default=1)
    ap.add_argument("--queue-max", type=int, default=2, help="pedidos em curso + na fila antes do 503/429")
    ap.add_argument("--vad-batch", type=int, default=1, help="trechos do VAD por inferência (8 = o medido pela curadoria)")
    ap.add_argument("--max-body-mb", type=int, default=384)
    ap.add_argument("--max-audio-s", type=float, default=10800.0, help="teto da duração DECODIFICADA por canal (3 h)")
    ap.add_argument("--direct-max-s", type=float, default=25.0)
    ap.add_argument("--file-max-speech-s", type=float, default=30.0)
    ap.add_argument("--file-min-silence-ms", type=float, default=500.0)
    a = ap.parse_args(argv)
    try:
        if not ipaddress.ip_address(a.host).is_loopback:
            ap.error(f"--host {a.host}: só loopback (o TLS e a exposição são do proxy)")
    except ValueError:
        ap.error(f"--host {a.host}: informe um IP de loopback, não um nome")
    for name in ("intra_op", "workers", "queue_max", "vad_batch", "max_body_mb"):
        if getattr(a, name) < 1:
            ap.error(f"--{name.replace('_', '-')} tem de ser >= 1")
    return a


class Engine:
    """O motor carregado UMA vez; as chamadas rodam no pool (`workers` threads)."""

    def __init__(self, a):
        import numpy as np
        import onnx_asr
        import onnxruntime as rt

        self.np, self.a = np, a
        so = rt.SessionOptions()
        so.intra_op_num_threads = a.intra_op
        so.inter_op_num_threads = 1
        t0 = time.perf_counter()
        # caminho LOCAL: o onnx-asr só vai ao Hugging Face se o diretório não existir — e aqui ele tem de existir
        for d in (a.model_dir, a.vad_dir):
            if not os.path.isdir(d):
                raise core.ConfigError(f"diretório de modelo ausente: {d} (o modelo chega na instalação, nunca em runtime)")
        self.asr = onnx_asr.load_model("nemo-parakeet-tdt-0.6b-v3", a.model_dir, quantization="int8",
                                       sess_options=so, providers=["CPUExecutionProvider"])
        self.asr_ts = self.asr.with_timestamps()
        vso = rt.SessionOptions()
        vso.intra_op_num_threads = 1
        vso.inter_op_num_threads = 1
        self.vad = onnx_asr.load_vad("silero", a.vad_dir, sess_options=vso, providers=["CPUExecutionProvider"])
        self.vad_asr = self.asr.with_vad(self.vad, batch_size=a.vad_batch, max_speech_duration_s=a.file_max_speech_s,
                                         min_silence_duration_ms=a.file_min_silence_ms).with_timestamps()
        self.load_s = time.perf_counter() - t0
        self.info = {"name": "parakeet-tdt-0.6b-v3-int8", "version": f"onnx-asr-{getattr(onnx_asr, '__version__', '?')}",
                     "arch": "tdt"}

    def transcribe(self, audio):
        """audio: float32 mono 16 kHz → (texto, segmentos, duração, modo, segundos de processamento)."""
        t = time.perf_counter()
        dur = len(audio) / SR
        if dur <= self.a.direct_max_s:
            r = self.asr_ts.recognize(audio, sample_rate=SR)
            text = r.text.strip()
            words = core.words_from_tokens(r.tokens, r.timestamps, r.logprobs, 0.0, dur)
            segments, mode = core.split_sentences(words, text, 0.0, dur, 0), "direct"
        else:
            segments, texts = [], []
            for seg in self.vad_asr.recognize(audio, sample_rate=SR):
                st = seg.text.strip()
                ws = core.words_from_tokens(seg.tokens, seg.timestamps, seg.logprobs, seg.start, seg.end)
                segments += core.split_sentences(ws, st, seg.start, seg.end, len(segments))
                if st:
                    texts.append(st)
            text, mode = " ".join(texts), "vad"
        return text, segments, dur, mode, time.perf_counter() - t


def decode_audio(np, sf, raw: bytes, query, tmpdir: str, max_s: float):
    """→ lista de canais float32 a 16 kHz e a taxa de origem. PCM cru pela query; contêiner pelo libsndfile; o resto
    (e toda taxa != 16 kHz) pelo ffmpeg, que só lê o arquivo temporário e só aceita a lista fechada de formatos."""
    pcm = core.raw_pcm_params(query)
    if pcm is not None:
        sr, ch = pcm
        n = len(raw) // (2 * ch) * (2 * ch)
        why = core.audio_too_long(n // (2 * ch), sr, ch, max_s)
        if why:
            raise AudioTooLong(why)
        data = (np.frombuffer(raw[:n], dtype="<i2").astype(np.float32) / 32768.0).reshape(-1, ch)
        if sr == SR:
            return [np.ascontiguousarray(data[:, c]) for c in range(ch)], sr
        raw = None  # reamostra pelo ffmpeg a partir de um WAV que nós mesmos escrevemos
        src = os.path.join(tmpdir, "in.wav")
        sf.write(src, data, sr, subtype="PCM_16")
    else:
        try:
            info = sf.info(io.BytesIO(raw))
        except Exception:  # noqa: BLE001 — contêiner que o libsndfile não lê: vai ao ffmpeg
            info = None
        if info is not None:
            # o cabeçalho diz a duração ANTES de decodificar: a bomba é recusada sem alocar nada
            why = core.audio_too_long(int(info.frames), int(info.samplerate), int(info.channels), max_s)
            if why:
                raise AudioTooLong(why)
        sr = None
        if info is not None and int(info.samplerate) == SR:
            data, sr = sf.read(io.BytesIO(raw), dtype="float32", always_2d=True)
            return [np.ascontiguousarray(data[:, c]) for c in range(data.shape[1])], sr
        src = os.path.join(tmpdir, "in.bin")
        with open(src, "wb") as f:
            f.write(raw)
    out = os.path.join(tmpdir, "out.wav")
    # -t corta a decodificação UM segundo acima do teto (o cabeçalho de quem não é libsndfile não é lido antes): o
    # que passar disso é recusado abaixo, e o disco do /tmp privado nunca recebe mais que o teto
    cmd = ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-protocol_whitelist", "file",
           "-format_whitelist", FFMPEG_FORMATS, "-i", src, "-vn", "-t", str(int(max_s) + 1), "-ar", str(SR),
           "-c:a", "pcm_f32le", "-y", out]
    try:
        p = subprocess.run(cmd, capture_output=True, timeout=FFMPEG_TIMEOUT_S, check=False)
    except subprocess.TimeoutExpired:
        raise ValueError("cannot decode audio: ffmpeg timeout") from None
    if p.returncode or not os.path.exists(out):
        raise ValueError("cannot decode audio: " + p.stderr[-300:].decode(errors="replace").replace(tmpdir, "<tmp>").strip())
    oinfo = sf.info(out)
    if int(oinfo.channels) > core.MAX_CHANNELS:
        raise ValueError(f"too many channels ({oinfo.channels})")
    why = core.audio_too_long(int(oinfo.frames), int(oinfo.samplerate), int(oinfo.channels), max_s)
    if why:
        raise AudioTooLong(why)
    data, osr = sf.read(out, dtype="float32", always_2d=True)
    return [np.ascontiguousarray(data[:, c]) for c in range(data.shape[1])], (sr or osr)


def build_app(a, engine, token: bytes):
    import numpy as np
    import soundfile as sf
    from starlette.applications import Starlette
    from starlette.requests import Request
    from starlette.responses import JSONResponse, PlainTextResponse
    from starlette.routing import Route

    pool = ThreadPoolExecutor(max_workers=a.workers, thread_name_prefix="asr")
    state = {"inflight": 0, "rejected": 0, "served": 0}
    code_ids = {"server_sha256": _sha256_file(os.path.abspath(__file__)),
                "core_sha256": _sha256_file(os.path.join(HERE, "stt_core.py"))}

    def log(**kw):  # NUNCA o conteúdo: só metadados (a transcrição é dado de reunião)
        print(json.dumps({"ts": datetime.now(timezone.utc).isoformat(timespec="seconds"), **kw}), flush=True)

    async def run(fn, *args):
        return await asyncio.get_running_loop().run_in_executor(pool, fn, *args)

    def decode_mono(raw, query, multichannel):
        with tempfile.TemporaryDirectory(prefix="stt-") as td:
            chans, _sr = decode_audio(np, sf, raw, query, td, a.max_audio_s)
        if not chans or len(chans[0]) == 0:
            raise ValueError("empty audio")
        if multichannel and len(chans) > 1:
            return chans
        return [np.mean(np.stack(chans), axis=0).astype(np.float32) if len(chans) > 1 else chans[0]]

    async def health(_request: Request):
        return JSONResponse({"ready": True, "engine": engine.info["name"], "live": False, "load_s": round(engine.load_s, 2),
                             "vad_batch": a.vad_batch, "intra_op": a.intra_op, "workers": a.workers, **code_ids, **state})

    def busy():
        if state["inflight"] >= a.queue_max:
            state["rejected"] += 1
            return True
        return False

    async def transcriptions(request: Request):
        rid = str(uuid.uuid4())
        if busy():
            return JSONResponse({"error": {"message": "server busy: queue full", "type": "server_error"}}, status_code=503,
                                headers={"Retry-After": "30"})
        state["inflight"] += 1
        try:
            try:
                form = await request.form(max_files=1, max_fields=16)
            except core.BodyTooLarge:
                raise  # o teto de corpo vira 413 pelo handler do app, nunca "multipart inválido"
            except Exception:  # noqa: BLE001 — multipart malformado
                return JSONResponse({"error": {"message": "invalid multipart body", "type": "invalid_request_error"}}, status_code=400)
            f = form.get("file")
            if f is None or isinstance(f, str):
                return JSONResponse({"error": {"message": "file is required", "type": "invalid_request_error"}}, status_code=400)
            fmt = str(form.get("response_format") or "json")
            if fmt not in core.OPENAI_FORMATS:
                return JSONResponse({"error": {"message": f"response_format {fmt} not supported", "type": "invalid_request_error"}}, status_code=400)
            language = form.get("language") or None
            raw = await f.read()
            try:
                audio = (await run(decode_mono, raw, {}, False))[0]
            except AudioTooLong as e:
                return JSONResponse({"error": {"message": str(e), "type": "invalid_request_error"}}, status_code=413)
            except ValueError as e:
                return JSONResponse({"error": {"message": str(e), "type": "invalid_request_error"}}, status_code=400)
            del raw
            text, segments, dur, mode, proc = await run(engine.transcribe, audio)
        finally:
            state["inflight"] -= 1
        state["served"] += 1
        log(event="transcriptions", rid=rid, duration_s=round(dur, 2), proc_s=round(proc, 2), mode=mode, fmt=fmt)
        hdr = {"X-Request-Id": rid, "X-Proc-S": f"{proc:.3f}", "X-Mode": mode}
        body = core.openai_body(fmt, text, segments, dur, language)
        if fmt == "text":
            return PlainTextResponse(body, headers=hdr)
        return JSONResponse(body, headers=hdr)

    async def listen(request: Request):
        rid = str(uuid.uuid4())
        if busy():
            return JSONResponse({"err_code": "TOO_MANY_REQUESTS", "err_msg": "server busy: queue full", "request_id": rid},
                                status_code=429, headers={"Retry-After": "30"})
        state["inflight"] += 1
        try:
            raw = await request.body()
            if not raw:
                return JSONResponse({"err_code": "Bad Request", "err_msg": "empty body", "request_id": rid}, status_code=400)
            q = request.query_params
            multichannel = (q.get("multichannel") or "").lower() in core.TRUE_WORDS
            digest = hashlib.sha256(raw).hexdigest()
            try:
                chans = await run(decode_mono, raw, q, multichannel)
            except AudioTooLong as e:
                return JSONResponse({"err_code": "PAYLOAD_TOO_LARGE", "err_msg": str(e), "request_id": rid}, status_code=413)
            except ValueError as e:
                return JSONResponse({"err_code": "Bad Request", "err_msg": str(e), "request_id": rid}, status_code=400)
            del raw
            out, proc_total, modes, dur = [], 0.0, [], 0.0
            for audio in chans:
                text, segments, dur, mode, proc = await run(engine.transcribe, audio)
                proc_total += proc
                modes.append(mode)
                out.append(core.deepgram_channel(text, [w for s in segments for w in s["words"]]))
        finally:
            state["inflight"] -= 1
        state["served"] += 1
        log(event="listen", rid=rid, duration_s=round(dur, 2), channels=len(out), proc_s=round(proc_total, 2), mode=",".join(modes))
        body = core.deepgram_body(out, dur, rid, digest, datetime.now(timezone.utc).isoformat(), MODEL_UUID, engine.info)
        return JSONResponse(body, headers={"X-Proc-S": f"{proc_total:.3f}", "X-Mode": ",".join(modes), "dg-request-id": rid})

    routes = [Route("/health", health, methods=["GET"]),
              Route("/v1/audio/transcriptions", transcriptions, methods=["POST"]),
              Route("/v1/listen", listen, methods=["POST"])]
    async def too_large(_request, _exc):
        # o BodyLimit levanta no meio da leitura do corpo (chunked): sem este handler, o ServerErrorMiddleware do
        # Starlette respondia 500 antes de o BodyLimit poder responder 413 (refutador, passada 1, medido)
        return JSONResponse({"error": {"message": "request body too large", "type": "invalid_request_error"}}, status_code=413)

    inner = Starlette(routes=routes, exception_handlers={core.BodyTooLarge: too_large})
    return core.AuthGate(core.BodyLimit(inner, a.max_body_mb * 1024 * 1024), token)


def main(argv=None):
    a = parse_args(argv)
    cred_dir = os.environ.get("CREDENTIALS_DIRECTORY", "")
    token_path = a.token_file or (os.path.join(cred_dir, "token") if cred_dir else "")
    try:
        token = core.load_token(token_path)
        engine = Engine(a)
    except core.ConfigError as e:
        print(json.dumps({"event": "refused", "reason": str(e)}), file=sys.stderr, flush=True)
        return 2
    app = build_app(a, engine, token)
    print(json.dumps({"event": "ready", "load_s": round(engine.load_s, 2), "pid": os.getpid(), "port": a.port,
                      "vad_batch": a.vad_batch, "intra_op": a.intra_op}), flush=True)
    import uvicorn
    uvicorn.run(app, host=a.host, port=a.port, log_level="warning", access_log=False, timeout_keep_alive=5)
    return 0


if __name__ == "__main__":
    sys.exit(main())
