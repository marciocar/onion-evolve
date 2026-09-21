#!/usr/bin/env python3
"""Leg-1 analyzer — implementa a ORDEM FIXA do pré-registro (NOTE-06 §2):
  passo-0: filtro de prefixo claude_code.* / gen_ai.*  (substrato ruidoso, NOTE-05 achado B)
  passo-1: baseline POR-SESSÃO (agrupa por session.id)
  passo-2: recorrência SÓ sobre os 3 sinais declarados, em ≥3 sessões independentes acima do baseline
  passo-3: held-out — ≥1 sessão onde o padrão reaparece SEM ter formulado o candidato
Nada fora dos 3 sinais entra. Nenhum critério muda aqui (mudar = exploratório, marcar como tal)."""
import sys, json, sys, os, glob
from collections import defaultdict, Counter

CAP = sys.argv[1]
KEEP_PREFIX = ("claude_code.", "gen_ai.")          # passo-0
DROP_HINT = ("prisma:", "rhilo.", "nodejs.", "v8js.", "http.")  # ruído documentado
BLOCKED_FLOOR_MS = 1000   # piso: gate humano real dura segundos; <1s = ruído headless (NOTE-05 A)

def load(sig):
    p = os.path.join(CAP, f"{sig}.ndjson")
    return [json.loads(l) for l in open(p)] if os.path.exists(p) else []

def attrs_to_dict(attrs):
    d = {}
    for a in attrs or []:
        v = a.get("value", {})
        d[a["key"]] = v.get("stringValue", v.get("intValue", v.get("doubleValue", v.get("boolValue"))))
    return d

def sid_from(resource_attrs, rec_attrs):
    for src in (rec_attrs, resource_attrs):
        for k in ("session.id", "gen_ai.conversation.id"):
            if src.get(k): return str(src[k])
    return "?"

# ---- per-session accumulators ----
sess = defaultdict(lambda: {"decisions": Counter(), "blocked_ms": [], "spans": Counter(),
                            "tool_seq": []})   # tool_seq: [(time, tool_name)] p/ detecção de episódio

# LOGS → tool_decision (accept/reject) + sequência ordenada de ferramentas
for p in load("logs"):
    for rl in p.get("resourceLogs", []):
        ra = attrs_to_dict(rl.get("resource", {}).get("attributes"))
        for sl in rl.get("scopeLogs", []):
            for lr in sl.get("logRecords", []):
                a = attrs_to_dict(lr.get("attributes"))
                ename = str(a.get("event.name") or (lr.get("body") or {}).get("stringValue", ""))
                is_tool_evt = "tool_decision" in ename or "tool_result" in ename or a.get("tool_name")
                if not (ename.startswith(KEEP_PREFIX) or is_tool_evt or "decision" in a):
                    continue                                   # passo-0
                sid = sid_from(ra, a)
                if "tool_decision" in ename or a.get("decision"):
                    sess[sid]["decisions"][a.get("decision", "?")] += 1
                # sequência: 1 passo por tool_result (invocação efetiva), ordenado por tempo
                tn = a.get("tool_name")
                if tn and "tool_result" in ename:
                    t = int(lr.get("timeUnixNano") or lr.get("observedTimeUnixNano") or 0)
                    sess[sid]["tool_seq"].append((t, str(tn)))

# TRACES → blocked_on_user + repeated spans (só claude_code.* / gen_ai.*)
for p in load("traces"):
    for rs in p.get("resourceSpans", []):
        ra = attrs_to_dict(rs.get("resource", {}).get("attributes"))
        for ss in rs.get("scopeSpans", []):
            for sp in ss.get("spans", []):
                nm = sp.get("name", "?")
                if not nm.startswith(KEEP_PREFIX):             # passo-0
                    continue
                a = attrs_to_dict(sp.get("attributes"))
                sid = sid_from(ra, a)
                st, en = int(sp.get("startTimeUnixNano", 0)), int(sp.get("endTimeUnixNano", 0))
                dur = (en - st) / 1e6 if en > st else 0
                sess[sid]["spans"][nm] += 1
                if "blocked_on_user" in nm:
                    sess[sid]["blocked_ms"].append(dur)

def quartile_top(vals):
    if not vals: return 0
    s = sorted(vals); return s[int(0.75 * (len(s) - 1))]

def loop_episodes(tool_seq, has_reject):
    """Heurístico de loop APERTADO (v2). Não conta mais span-name repetido (cadência normal).
    Um loop candidato é um EPISÓDIO contíguo repetido na sequência de FERRAMENTAS:
      (a) ciclo multi-tool: sub-sequência de len≥2 com ≥2 tipos DISTINTOS, repetida ≥2× (ex.: edit↔test); ou
      (b) mesma tool ≥3× consecutivas SÓ SE a sessão teve reject (retry-após-negação).
    Batch produtivo de 1 tool (Write×3, sem reject) NÃO é loop. O refutador decide stuck-vs-produtivo depois."""
    seq = [t for _, t in sorted(tool_seq)]
    out = set()
    n = len(seq)
    # (a) ciclos multi-tool repetidos
    for L in range(2, n // 2 + 1):
        counts = Counter(tuple(seq[i:i+L]) for i in range(n - L + 1))
        for ep, c in counts.items():
            if c >= 2 and len(set(ep)) >= 2:
                out.add("loop:cycle:" + ">".join(ep))
    # (b) mesma tool ≥3× consecutivas + reject na sessão
    if has_reject:
        i = 0
        while i < n:
            j = i
            while j < n and seq[j] == seq[i]:
                j += 1
            if j - i >= 3:
                out.add(f"loop:retry:{seq[i]}×{j-i}")
            i = max(j, i + 1)
    return out

# ---- passo-1: baseline por-sessão + sinais de atrito ----
print(f"═══ Leg-1 — captura: {CAP} ═══")
print(f"passo-0 filtro: mantém {KEEP_PREFIX}; descarta {DROP_HINT}\n")
n = len(sess)
if "?" in sess and n == 1:
    print("⚠️  NENHUM session.id encontrado — 1 bucket anônimo. Recorrência cross-sessão IMPOSSÍVEL de aferir.")
print(f"sessões distintas (por session.id): {n}\n")

# ⚠️ ZERO SESSÃO NÃO É RESULTADO — é "não li nada", e sai por erro.
# POR QUE EXISTE (medido 2026-09-21, na 1ª rodada interativa real): a captura trouxe só
# `claude_code.session.count`; o analisador leu 0 sessões e ainda assim imprimiu "nenhum
# span-pattern de atrito em ≥3 sessões" e saiu rc=0. Uma captura PERDIDA ficava indistinguível de
# "o loop não tem atrito" — e o segundo é justamente a conclusão que este estudo existe para testar.
# Varredura vazia devolvendo veredito é fail-open com cara de cobertura; aqui custa a tese inteira.
if n == 0:
    print("✗ NENHUMA sessão analisável na captura.")
    print("  Isto NÃO é 'sem atrito' — é ausência de dado, e os dois não podem sair iguais.")
    print("  Sinais esperados: `tool_decision` em logs.ndjson · `blocked_on_user` e spans em traces.ndjson.")
    print("  Causa mais provável (medida em 2026-09-21): a sessão foi fechada antes do flush do")
    print("  buffer OTLP. Use `/exit` (não feche o terminal), e prefira sessões com trabalho real —")
    print("  o sinal nasce quando um gate PARA e espera por você.")
    sys.exit(2)

friction_by_session = {}   # sid -> set de span-patterns de atrito acima do baseline
for sid, d in sess.items():
    tot = sum(d["decisions"].values()); rej = d["decisions"].get("reject", 0)
    rr = rej / tot if tot else 0
    q = quartile_top(d["blocked_ms"])
    bmax = max(d["blocked_ms"]) if d["blocked_ms"] else 0
    fric = set()
    # sinal 1: reject-rate > 0 → atrito de retrabalho (marca a sessão)
    if rej > 0: fric.add("tool_decision:reject")
    # sinal 2: blocked_on_user no topo do quartil da sessão E acima do piso de magnitude
    #          (piso mata o falso-positivo de ~7ms headless — NOTE-05 achado A)
    if bmax >= BLOCKED_FLOOR_MS and bmax >= q and q > 0: fric.add("blocked_on_user:top-quartile")
    # sinal 3: loop APERTADO — episódio repetido na sequência de ferramentas (v2), não span-name
    fric |= loop_episodes(d["tool_seq"], has_reject=(rej > 0))
    friction_by_session[sid] = fric
    sid_show = sid if len(sid) <= 12 else sid[:8] + "…"
    print(f"  sessão {sid_show:14s} decisions={dict(d['decisions'])} reject-rate={rr:.0%} "
          f"blocked_on_user(max={bmax:.0f}ms q75={q:.0f}ms n={len(d['blocked_ms'])}) "
          f"spans={sum(d['spans'].values())}")
    if fric: print(f"                 atrito: {sorted(fric)}")

# ---- passo-2: recorrência (≥3 sessões independentes com o mesmo span-pattern) ----
pat_sessions = defaultdict(set)
for sid, fset in friction_by_session.items():
    for pat in fset: pat_sessions[pat].add(sid)

print("\n═══ passo-2: recorrência (limiar pré-registrado = ≥3 sessões independentes) ═══")
candidates = {pat: s for pat, s in pat_sessions.items() if len(s) >= 3}
if not candidates:
    print("  nenhum span-pattern de atrito em ≥3 sessões. (Esperado com poucas sessões / headless.)")
for pat, s in candidates.items():
    print(f"  CANDIDATO: {pat}  em {len(s)} sessões")

# ---- passo-3: held-out ----
print("\n═══ passo-3: held-out (≥1 sessão que confirma sem ter formulado) ═══")
if candidates:
    for pat, s in candidates.items():
        discover = set(list(s)[:3]); heldout = s - discover
        ok = len(heldout) >= 1
        print(f"  {pat}: descoberta={len(discover)} held-out={len(heldout)} → "
              f"{'CONFIRMADO (N≥4)' if ok else 'PENDENTE (falta held-out)'}")
else:
    print("  — sem candidatos a confirmar —")

print("\nNota: reject por DENIAL headless ≠ blocked_on_user (espera humana). Só sessão INTERATIVA gera o sinal 2 (NOTE-05 achado A).")
