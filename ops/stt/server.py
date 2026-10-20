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
DIARIZAÇÃO (opt-in por pedido, D_MC_DIARIZACAO_NO_SERVICO_PROXIMO_1019): `diarize=true` na query do /v1/listen (como o
Deepgram: `speaker` int por palavra) ou no campo `diarize` do multipart OpenAI (só com verbose_json: `speaker` por
palavra e por segmento, e o segmento é cortado onde o falante muda). Roda DEPOIS do Parakeet, sobre o mesmo áudio, o
Nemotron-3-Diarization q8_0 pelo NeMo-Speech.cpp 0.2.0 (preset v3-offline, CPU) num subprocesso sem PATH e dentro da
unit sem rede de saída; o gguf é local. Falha, demora ou áudio acima do --diar-max-s NUNCA derrubam a transcrição: ela
sai sem falante e o bloco `diarization` (OpenAI) ou `metadata.onion_diarization` (Deepgram), mais o cabeçalho
X-Diarization, declaram ok|failed|skipped|unavailable e o motivo.
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
import shutil
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
DIAR_MAX_S_DEFAULT = 10800.0  # o teto da duração do serviço (3 h); o wrapper o fixa pelo que o MemoryMax comporta


def out_size(p: str) -> int:
    return os.path.getsize(p)


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
    ap.add_argument("--diar-bin", default=None, help="o nemo-speech da área do serviço (sem ele, diarize=true declara unavailable)")
    ap.add_argument("--diar-model", default=None, help="o GGUF local do Nemotron-3-Diarization (nunca baixado em runtime)")
    ap.add_argument("--diar-max-s", type=float, default=DIAR_MAX_S_DEFAULT,
                    help="duração máxima diarizada; acima dela a resposta sai sem falante, declarando skipped")
    a = ap.parse_args(argv)
    if bool(a.diar_bin) != bool(a.diar_model):
        ap.error("--diar-bin e --diar-model andam juntos")
    if a.diar_max_s <= 0:
        ap.error("--diar-max-s tem de ser > 0")
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


def decode_audio(np, sf, raw: bytes, query, tmpdir: str, max_s: float, multichannel: bool = False):
    try:
        return _decode_audio(np, sf, raw, query, tmpdir, max_s, multichannel)
    except (RuntimeError, OSError) as e:  # LibsndfileError é RuntimeError: arquivo corrompido é 400, nunca 500
        raise ValueError(f"cannot decode audio: {str(e).replace(tmpdir, '<tmp>')[:200]}") from None


def _decode_audio(np, sf, raw: bytes, query, tmpdir: str, max_s: float, multichannel: bool):
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
        if info is not None and not core.header_frames_known(int(info.frames)):
            info = None  # duração desconhecida no cabeçalho: o ffmpeg decide, com -t e -fs
        if info is not None:
            # o cabeçalho diz a duração e os canais ANTES de decodificar: a bomba é recusada sem alocar nada
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
    # -t corta a decodificação UM segundo acima do teto e -fs corta o ARQUIVO no teto de canais × duração (sem -fs, 64
    # canais de opus num mka escreviam 245 MB por minuto no /tmp antes da recusa: refutador, passada 2, medido). Sem
    # multichannel, -ac 1 já mistura no ffmpeg. PCM de 16 bits: metade do disco do float32, e o motor lê float de volta.
    fs = int((2 * max_s + 2) * SR * 2 + (1 << 20))
    cmd = ["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-protocol_whitelist", "file",
           "-format_whitelist", FFMPEG_FORMATS, "-i", src, "-vn", "-t", str(int(max_s) + 1), "-ar", str(SR),
           *([] if multichannel else ["-ac", "1"]), "-c:a", "pcm_s16le", "-fs", str(fs), "-y", out]
    try:
        p = subprocess.run(cmd, capture_output=True, timeout=FFMPEG_TIMEOUT_S, check=False)
    except subprocess.TimeoutExpired:
        raise ValueError("cannot decode audio: ffmpeg timeout") from None
    if p.returncode or not os.path.exists(out):
        raise ValueError("cannot decode audio: " + p.stderr[-300:].decode(errors="replace").replace(tmpdir, "<tmp>").strip())
    oinfo = sf.info(out)
    if out_size(out) >= fs - (1 << 16):  # o -fs cortou: o que sobrou é parcial, nunca transcrição
        raise AudioTooLong("decoded audio too large (channels × duration)")
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
            chans, _sr = decode_audio(np, sf, raw, query, td, a.max_audio_s, multichannel)
        if not chans or len(chans[0]) == 0:
            raise ValueError("empty audio")
        if multichannel and len(chans) > 1:
            return chans
        return [np.mean(np.stack(chans), axis=0).astype(np.float32) if len(chans) > 1 else chans[0]]

    diar_info = {"available": bool(a.diar_bin), "engine": "nemotron-3-diarization-q8_0" if a.diar_bin else None,
                 "preset": "v3-offline", "max_s": a.diar_max_s}

    class DiarJob:
        """Um áudio a diarizar. A ORDEM é a da memória (medida: o filho do v3-offline cresce ~0,31 MB por segundo de
        áudio, 3,44e9 B em 3 h): o WAV de 16 bits é escrito ANTES da transcrição (prepare), o float32 é solto pelo
        chamador e só então o filho sobe (run). Nada aqui levanta: a diarização nunca derruba a transcrição."""

        def __init__(self, audio, td: str, idx: int = 0):
            self.dur = len(audio) / SR
            self.td, self.wav, self.early = td, os.path.join(td, f"diar-in-{idx}.wav"), None
            if not a.diar_bin:
                self.early = core.DiarResult("unavailable", "diarization not configured on this server")
            elif self.dur > a.diar_max_s:
                self.early = core.DiarResult("skipped", f"audio longer than the diarization ceiling ({self.dur:.0f} s > {a.diar_max_s:.0f} s)")

        def prepare(self, audio):
            if self.early is not None:
                return
            try:
                pcm = (np.clip(audio, -1.0, 1.0) * 32767.0).astype("<i2")
                core.write_wav16(self.wav, memoryview(pcm).cast("B"), SR)
            except Exception as e:  # noqa: BLE001 — a diarização nunca derruba a transcrição
                self.early = core.DiarResult("failed", f"{type(e).__name__}: {str(e)[:160]}")

        def run(self):
            if self.early is not None:
                return self.early
            try:
                return core.diarize(a.diar_bin, a.diar_model, self.wav, self.td, core.diar_timeout_s(self.dur))
            except Exception as e:  # noqa: BLE001 — exceção do diarizador vira failed, nunca 500
                return core.DiarResult("failed", f"{type(e).__name__}: {str(e)[:160]}")
            finally:
                try:
                    os.unlink(self.wav)
                except OSError:
                    pass

    def diar_requested(value) -> bool:
        return str(value or "").lower() in core.TRUE_WORDS

    async def health(_request: Request):
        return JSONResponse({"ready": True, "engine": engine.info["name"], "live": False, "load_s": round(engine.load_s, 2),
                             "vad_batch": a.vad_batch, "intra_op": a.intra_op, "workers": a.workers, "diarization": diar_info,
                             **code_ids, **state})

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
            # diarização na forma OpenAI: campo `diarize` (extensão deste serviço; o verbose_json é a única forma com
            # palavras e tempos, então é a única que a aceita). Sai `speaker` em cada palavra e em cada segmento.
            want_diar = diar_requested(form.get("diarize"))
            if want_diar and fmt != "verbose_json":
                return JSONResponse({"error": {"message": "diarize requires response_format=verbose_json",
                                               "type": "invalid_request_error"}}, status_code=400)
            raw = await f.read()
            try:
                audio = (await run(decode_mono, raw, {}, False))[0]
            except AudioTooLong as e:
                return JSONResponse({"error": {"message": str(e), "type": "invalid_request_error"}}, status_code=413)
            except ValueError as e:
                return JSONResponse({"error": {"message": str(e), "type": "invalid_request_error"}}, status_code=400)
            del raw
            td = tempfile.mkdtemp(prefix="diar-") if want_diar else None
            try:
                job = DiarJob(audio, td) if want_diar else None
                if job is not None:
                    await run(job.prepare, audio)
                text, segments, dur, mode, proc = await run(engine.transcribe, audio)
                del audio  # o float32 sai da memória ANTES de o diarizador subir
                diar = (await run(job.run)) if job is not None else None
            finally:
                if td:
                    shutil.rmtree(td, ignore_errors=True)
        finally:
            state["inflight"] -= 1
        state["served"] += 1
        log(event="transcriptions", rid=rid, duration_s=round(dur, 2), proc_s=round(proc, 2), mode=mode, fmt=fmt,
            diar=diar.status if diar else None, diar_s=round(diar.proc_s, 2) if diar else None)
        hdr = {"X-Request-Id": rid, "X-Proc-S": f"{proc:.3f}", "X-Mode": mode}
        if diar is not None:
            hdr["X-Diarization"] = diar.status
            if diar.status == "ok":
                segments = core.diarize_segments(segments, diar.turns)
        body = core.openai_body(fmt, text, segments, dur, language)
        if diar is not None:
            body["diarization"] = diar.public()
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
            want_diar = diar_requested(q.get("diarize"))  # como no Deepgram: com multichannel, cada canal à parte
            digest = hashlib.sha256(raw).hexdigest()
            try:
                chans = await run(decode_mono, raw, q, multichannel)
            except AudioTooLong as e:
                return JSONResponse({"err_code": "PAYLOAD_TOO_LARGE", "err_msg": str(e), "request_id": rid}, status_code=413)
            except ValueError as e:
                return JSONResponse({"err_code": "Bad Request", "err_msg": str(e), "request_id": rid}, status_code=400)
            del raw
            out, proc_total, modes, dur, diars = [], 0.0, [], 0.0, []
            td = tempfile.mkdtemp(prefix="diar-") if want_diar else None
            try:
                for i in range(len(chans)):
                    audio, chans[i] = chans[i], None
                    job = DiarJob(audio, td, i) if want_diar else None
                    if job is not None:
                        await run(job.prepare, audio)
                    text, segments, dur, mode, proc = await run(engine.transcribe, audio)
                    del audio  # o float32 do canal sai da memória ANTES de o diarizador subir
                    proc_total += proc
                    modes.append(mode)
                    words = [w for s in segments for w in s["words"]]
                    if job is not None:
                        diar = await run(job.run)
                        diars.append(diar)
                        if diar.status == "ok":
                            words = core.assign_speakers(words, diar.turns)
                    out.append(core.deepgram_channel(text, words))
            finally:
                if td:
                    shutil.rmtree(td, ignore_errors=True)
        finally:
            state["inflight"] -= 1
        state["served"] += 1
        dstat = ",".join(d.status for d in diars) if diars else None
        log(event="listen", rid=rid, duration_s=round(dur, 2), channels=len(out), proc_s=round(proc_total, 2), mode=",".join(modes),
            diar=dstat, diar_s=round(sum(d.proc_s for d in diars), 2) if diars else None)
        body = core.deepgram_body(out, dur, rid, digest, datetime.now(timezone.utc).isoformat(), MODEL_UUID, engine.info)
        hdr = {"X-Proc-S": f"{proc_total:.3f}", "X-Mode": ",".join(modes), "dg-request-id": rid}
        if diars:
            # a declaração mora em metadata (o cliente Deepgram ignora chave que não conhece) e no cabeçalho
            body["metadata"]["onion_diarization"] = [d.public() for d in diars]
            hdr["X-Diarization"] = dstat
        return JSONResponse(body, headers=hdr)

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
        if a.diar_bin:
            # configurado e ausente é defeito de INSTALAÇÃO (o wrapper monta os dois): recusa o boot, o verify o vê. Em
            # runtime, a falha do diarizador nunca derruba a transcrição (ver DiarJob).
            if not (os.path.isfile(a.diar_bin) and os.access(a.diar_bin, os.X_OK)):
                raise core.ConfigError(f"diarizador ausente ou não executável: {a.diar_bin}")
            if not os.path.isfile(a.diar_model):
                raise core.ConfigError(f"modelo do diarizador ausente: {a.diar_model} (chega na instalação, nunca em runtime)")
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
