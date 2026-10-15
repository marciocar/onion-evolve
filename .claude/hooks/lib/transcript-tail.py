# transcript-tail.py — lê só a CAUDA do transcript JSONL, de trás para frente, com teto e fail-safe.
# Carregado pelo hook Stop rule-title-in-prose.sh por importlib a partir do caminho; não roda
# sozinho. (O outro consumidor, background-state-needs-evidence.sh, foi APOSENTADO em 2026-10-14 —
# D_VETO_DE_PROSA_APOSENTADO_PELA_SONDA; a sonda que o substituiu, background-task-probe.sh, lê o
# transcript por grep, não por esta biblioteca.)
#
# ── POR QUE (SAC-137, rodada r11 do radar E3, medido em 2026-10-14) ──────────────────────────────────
# Os dois hooks Stop liam e parseavam o transcript INTEIRO com json.loads linha a linha, a cada turno:
# ~1,0 s e ~0,55 s num transcript de 44,7 MB, sem timeout. A 2.1.300 do Claude Code faz o transcript
# crescer ~63 KB por resposta (registros api-request, api-request-shape, api-request-blob com system
# prompt, tools e parâmetros de cada requisição) — o custo cresce com a vida da sessão, não com o turno.
# Os dois hooks só precisavam do FIM: o último turno (background-state, hoje aposentado) ou a última
# resposta com texto (rule-title).
#
# ── O CONTRATO: o mesmo veredito por três caminhos ──────────────────────────────────────────────────
# tail_until(path, pred) devolve as linhas parseadas desde a ÚLTIMA linha em que pred(row) é verdade
# até o fim do arquivo, em ordem. Se nenhuma linha satisfaz pred, devolve TODAS (é o que a leitura
# inteira de antes fazia: start = 0). Três caminhos, mesma resposta:
#   · "tail" — achou a linha dentro do teto lendo de trás para frente (o caso comum);
#   · "bof"  — chegou ao início do arquivo dentro do teto sem achar: devolve tudo;
#   · "full" — estourou o TETO sem achar (turno autônomo LONGO: o último pedido humano ficou longe do
#              fim). Aí relê o arquivo inteiro para frente, EXATAMENTE como antes. É o fail-safe: falta
#              de leitura nunca vira silêncio — vira a leitura lenta de sempre.
# Linha que não parseia é pulada nos três caminhos (a escrita parcial do harness no fim do arquivo,
# por exemplo), igual à leitura de antes.
#
# TETO DECLARADO: ONION_STOP_HOOK_TAIL_MAX_BYTES (padrão 16 MiB). Com ~63 KB por resposta, 16 MiB
# cobre ~260 respostas no mesmo turno antes de cair no caminho lento. A bancada força um teto baixo
# para exercitar o "full". ONION_TRANSCRIPT_TAIL_TRACE=<arquivo> faz o lib anotar o caminho e os bytes
# lidos (só a bancada usa).
import json
import os

DEFAULT_MAX_BYTES = 16 * 1024 * 1024
BLOCK = 1 << 20


def max_bytes():
    try:
        v = int(os.environ.get("ONION_STOP_HOOK_TAIL_MAX_BYTES", ""))
        return v if v >= 0 else DEFAULT_MAX_BYTES
    except ValueError:
        return DEFAULT_MAX_BYTES


def _parse(raw):
    try:
        return json.loads(raw.decode("utf-8", errors="replace"))
    except Exception:
        return None


def _trace(mode, nbytes):
    tf = os.environ.get("ONION_TRANSCRIPT_TAIL_TRACE")
    if not tf:
        return
    try:
        with open(tf, "a", encoding="utf-8") as fh:
            fh.write("mode=%s bytes=%d\n" % (mode, nbytes))
    except Exception:
        pass


def _full(path, pred):
    rows = []
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            rows.append(json.loads(line))
        except Exception:
            continue
    start = 0
    for i, j in enumerate(rows):
        if pred(j):
            start = i
    return rows[start:]


def tail_until(path, pred, cap=None):
    cap = max_bytes() if cap is None else cap
    size = os.path.getsize(path)
    got = []                 # linhas parseadas, do FIM para o começo
    pos = size
    carry = b""              # pedaço de linha que começou antes do bloco já lido
    read = 0
    with open(path, "rb") as fh:
        while pos > 0:
            if read >= cap:
                _trace("full", size)
                return _full(path, pred)
            n = min(BLOCK, pos, cap - read)   # o teto é em bytes, não em blocos
            pos -= n
            fh.seek(pos)
            buf = fh.read(n) + carry
            read += n
            parts = buf.split(b"\n")
            # a 1ª parte pode ser linha cortada pelo início do bloco: só é inteira no início do arquivo
            carry = parts[0] if pos > 0 else b""
            whole = parts[1:] if pos > 0 else parts
            for raw in reversed(whole):
                if not raw.strip():
                    continue
                j = _parse(raw)
                if j is None:
                    continue
                got.append(j)
                if pred(j):
                    _trace("tail", read)
                    got.reverse()
                    return got
    _trace("bof", read)
    got.reverse()
    return got


def is_tool_result(j):
    c = (j.get("message") or {}).get("content")
    return isinstance(c, list) and any(
        isinstance(x, dict) and x.get("type") == "tool_result" for x in c)


def is_turn_start(j):
    # `type == "user"` NÃO é "mensagem humana": tool_result também é row `user` (85% delas, medido).
    return j.get("type") == "user" and not is_tool_result(j)


def _text_parts(j):
    if j.get("type") != "assistant":
        return []
    return [c.get("text", "") for c in (j.get("message") or {}).get("content") or []
            if isinstance(c, dict) and c.get("type") == "text"]


def has_text(j):
    # resposta do assistente com ao menos um bloco de texto (mesmo vazio: era o critério de antes)
    return bool(_text_parts(j))


def assistant_text(j):
    return "\n".join(_text_parts(j))
