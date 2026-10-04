#!/usr/bin/env bash
# =============================================================================
# kg-drive-project.sh — o CENSO do /meta:drive: a FILA-PRONTA de um plano-grafo.
#
# Propósito : projetar, determinística e sem LLM, O QUE ESTÁ PRONTO PARA AVANÇAR
#             num plano-grafo — os nós `status: open` cujos predecessores
#             `DEPENDS_ON` já FECHARAM (não estão mais open), ordenados por
#             atenção (a régua do radar), anotados com o `drive_kind` (research/
#             verification/execution/decision). É o "Censo" do ADR autonomous-
#             thread-runtime virado MECANISMO — o que hoje só existe como prosa.
#
#             `DEPENDS_ON` aqui é GUARDA, não ordenação: "não faça B antes de A".
#             A ordenação topológica DIRIGIDA é Fase 2 gated (transformar atenção
#             em precedência é o defeito fundador da REGRA 49 — aviso do fios-abertos).
#
# Grafo-primeiro: NÃO reparseia YAML para estado — consome `kg-radar --open-tsv`
#             (fila de abertos + atenção) e `--triples` (arestas DEPENDS_ON). Um
#             predecessor está SATISFEITO sse NÃO está no conjunto de abertos.
#             (Só o `drive_kind:` opcional é lido do arquivo, à la owner: do backlog.)
#
# Uso       : bash .claude/validation/kg-drive-project.sh [<grafo.kg.yaml>] [--check]
#             sem grafo → o plano de execução do core (fios-abertos.kg.yaml)
#             --check   → só o veredito; exit 1 se há ABERTOS mas a FILA-PRONTA está
#                         VAZIA (tudo bloqueado = anomalia de plano/deadlock) OU se o grafo
#                         carrega um CHECKPOINT PENDENTE (meta.drive_checkpoint: pending)
#
# P0.5 MECANIZADO (2026-10-04): o checkpoint do lote vive NO GRAFO, versionado, em
#             `meta.drive_checkpoint: pending|sealed` (+ `meta.drive_checkpoint_note:`). Antes ele
#             vivia só no `.claude/sessions/<slug>/STATE.md`, que é GITIGNORADO e que NENHUM script
#             lia: o anti-thrashing existia só na máquina onde foi escrito e só como prosa — num
#             clone ou worktree novo o P0.5 passava por AUSÊNCIA (rodada do /meta:evolve de
#             2026-10-04, nó C_CHECKPOINT_DO_DRIVE_E_SO_PROSA_E_NAO_VIAJA). Pendente vence
#             qualquer outro veredito: é o passo ANTERIOR ao censo.
# =============================================================================
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
RADAR=".claude/validation/kg-radar.sh"

GRAPH_DEFAULT="docs/onion/graph/fios-abertos.kg.yaml"; GRAPH="$GRAPH_DEFAULT"; MODE="project"; NOTE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check" ;;
    # escrita do checkpoint — o P5 RODA isto, nunca edita à mão (Elenxo da leva 2: a leitura tinha
    # sido mecanizada e a ESCRITA continuava dependendo de alguém lembrar)
    --close-lot) MODE="close"; [ $# -ge 2 ] && [ -n "$2" ] || { echo "ERRO: --close-lot exige a nota do lote" >&2; exit 2; }; NOTE="$2"; shift ;;
    --seal) MODE="seal" ;;
    *.kg.yaml) GRAPH="$1" ;;
    *) echo "arg desconhecido: $1" >&2; exit 2 ;;
  esac; shift
done
# O DEFAULT é o plano-grafo DO CORE; num repo que só instalou o plugin ele não existe, e "grafo
# ausente" sozinho não diz o que fazer. A mensagem passa a nomear o caminho: passe o seu grafo.
[ -f "$GRAPH" ] || { echo "ERRO: grafo ausente: $GRAPH" >&2
  [ "$GRAPH" = "$GRAPH_DEFAULT" ] && echo "       (esse é só o DEFAULT — o plano-grafo do CORE, que não existe num repo que apenas instalou o plugin)" >&2
  echo "       passe o grafo deste repo: $(basename "$0") <grafo.kg.yaml> [--check]   ·   ache com: git ls-files '*.kg.yaml'" >&2
  exit 2; }

# ── O CHECKPOINT (P0.5/P5) é lido e escrito por YAML de verdade ──────────────────────────────
# ⚠️ A 1a versão lia com awk e o Elenxo mediu 7 formas YAML válidas em que ela errava (aspas simples,
#    a chave citada dentro de um label, `drive_checkpoint : x`, bloco `>-`, chave duplicada, meta
#    depois de nodes, `xdrive_checkpoint`). Campo de controle se lê com o parser que o define.
_ckpt() {   # $1 = read | close | seal ; lê/escreve meta.drive_checkpoint(+_note) de $GRAPH
  python3 - "$1" "$GRAPH" "$NOTE" <<'CKPT_PY'
import sys, re
try:
    import yaml
except ImportError:
    print("ERRO: PyYAML ausente — o checkpoint NAO pode ser lido (fail-loud, nunca 'selado')", file=sys.stderr); sys.exit(2)
mode, path, note = sys.argv[1:4]
txt = open(path, encoding='utf-8').read()
try:
    meta = (yaml.safe_load(txt) or {}).get('meta') or {}
except Exception as e:
    print("ERRO: YAML ilegivel em %s: %s" % (path, e), file=sys.stderr); sys.exit(2)
if mode == 'read':
    v = meta.get('drive_checkpoint')
    v = '' if v is None else str(v)
    n = meta.get('drive_checkpoint_note') or ''
    print(v + '\t' + ' '.join(str(n).split())); sys.exit(0)
# escrita: só no bloco `meta:` em forma de BLOCO (flow-style não se edita com segurança)
lines = txt.split('\n')
try:
    i = next(k for k, l in enumerate(lines) if l.rstrip() == 'meta:')
except StopIteration:
    print("ERRO: %s nao tem `meta:` em forma de bloco no nivel 0 — escrita recusada (converta o meta)" % path, file=sys.stderr); sys.exit(2)
j = i + 1
while j < len(lines) and (lines[j].startswith(' ') or lines[j].strip() == '' or lines[j].lstrip().startswith('#')):
    j += 1
body = [l for l in lines[i+1:j] if not re.match(r'^\s+drive_checkpoint(_note)?\s*:', l)]
new = ['  drive_checkpoint: ' + ('pending' if mode == 'close' else 'sealed')]
if mode == 'close':
    new.append('  drive_checkpoint_note: "%s"' % note.replace('\\', '\\\\').replace('"', '\\"'))
out = '\n'.join(lines[:i+1] + new + body + lines[j:])
chk = (yaml.safe_load(out) or {}).get('meta') or {}
want = 'pending' if mode == 'close' else 'sealed'
if chk.get('drive_checkpoint') != want or (mode == 'close' and chk.get('drive_checkpoint_note') != note):
    print("ERRO: a escrita nao releu como escrita — nada gravado", file=sys.stderr); sys.exit(2)
open(path, 'w', encoding='utf-8').write(out)
print("checkpoint %s em %s" % (want, path))
CKPT_PY
}
if [ "$MODE" = "close" ] || [ "$MODE" = "seal" ]; then
  _ckpt "$MODE" || exit 2
  bash "$RADAR" "$GRAPH" --integrity --schema >/dev/null 2>&1 \
    || { echo "ERRO: depois de escrever o checkpoint, $GRAPH reprova no radar — revise" >&2; exit 2; }
  exit 0
fi

# Passo 0 — LEGIBILIDADE antes de conduzir (não se dirige grafo que o motor não lê)
bash "$RADAR" "$GRAPH" --integrity --schema >/dev/null 2>&1 \
  || { echo "ERRO: $GRAPH reprova integridade/schema no radar — corrija antes de conduzir" >&2; exit 2; }

OPEN="$(mktemp)"; EDGES="$(mktemp)"; trap 'rm -f "$OPEN" "$EDGES"' EXIT
bail() { echo "ERRO: radar falhou em $GRAPH ($1)" >&2; exit 2; }
bash "$RADAR" "$GRAPH" --open-tsv 2>/dev/null > "$OPEN" || bail --open-tsv
bash "$RADAR" "$GRAPH" --triples  2>/dev/null > "$EDGES" || bail --triples

# Motor — 1 awk lê ABERTOS + ARESTAS + o GRAFO (só p/ drive_kind opcional) e emite:
#   READY   \t atenção \t id \t drive_kind
#   BLOCKED \t atenção \t id \t drive_kind \t bloqueador(es)
RESULT="$(awk '
  function infer(nt) {   # drive_kind default pelo node_type (o campo drive_kind: sobrepõe)
    if (nt=="question") return "research"
    if (nt=="claim")    return "verification"
    if (nt=="decision") return "execution"
    return "review"
  }
  # chaveia por FILENAME (não por contador): robusto a --open-tsv VAZIO (plano completo),
  # que quebrava um FNR==1{part++} — as arestas vazavam como "nós abertos" (dogfood mediu).
  # ---- ARGV[1]=--open-tsv (file id node_type plane status impact conf att ...) ----
  FILENAME==ARGV[1] { open[$2]=1; att[$2]=$8+0; ntype[$2]=$3; next }
  # ---- ARGV[2]=--triples (from EDGE to) ----
  FILENAME==ARGV[2] { if ($2=="DEPENDS_ON") dep[$1]=dep[$1] " " $3; next }
  # ---- ARGV[3]=o GRAFO cru, só para o campo opcional drive_kind: ----
  FILENAME==ARGV[3] {
    if ($0 ~ /^[[:space:]]*- id:/) { cur=$0; sub(/^[[:space:]]*- id:[[:space:]]*/,"",cur); sub(/[[:space:]]*$/,"",cur) }
    else if ($0 ~ /^[^[:space:]]/) cur=""
    if ($0 ~ /^[[:space:]]*drive_kind:/ && cur!="") { dk=$0; sub(/^[^:]*:[[:space:]]*/,"",dk); gsub(/"/,"",dk); sub(/[[:space:]]*$/,"",dk); DKIND[cur]=dk }
    next
  }
  END {
    for (id in open) {
      kind = (id in DKIND) ? DKIND[id] : infer(ntype[id])
      # bloqueadores = predecessores DEPENDS_ON que AINDA estão abertos
      blk=""; n=split(dep[id], preds, " ")
      for (i=1;i<=n;i++) { p=preds[i]; if (p!="" && (p in open)) blk = blk (blk==""?"":",") p }
      if (blk=="") printf "READY\t%.2f\t%s\t%s\n", att[id], id, kind
      else         printf "BLOCKED\t%.2f\t%s\t%s\t%s\n", att[id], id, kind, blk
    }
  }
' "$OPEN" "$EDGES" "$GRAPH")"

n_open=$(printf '%s\n' "$RESULT" | grep -c . || true)
n_ready=$(printf '%s\n' "$RESULT" | awk -F'\t' '$1=="READY"' | grep -c . || true)
n_blocked=$(printf '%s\n' "$RESULT" | awk -F'\t' '$1=="BLOCKED"' | grep -c . || true)

# veredito: DEADLOCK = há abertos mas nenhum pronto (tudo bloqueado); DONE = 0 abertos
verdict() {
  if [ "$n_open" -eq 0 ]; then echo "DONE"                 # plano sem trabalho aberto
  elif [ "$n_ready" -eq 0 ]; then echo "DEADLOCK"          # anomalia: tudo bloqueado
  else echo "READY"; fi
}
V="$(verdict)"

# P0.5 — checkpoint pendente NO GRAFO, lido por YAML. Valor fora de pending|sealed é RECUSADO: um
# campo de controle com valor que ninguém reconhece é exatamente o selo que ninguém vê.
_CK="$(_ckpt read)" || exit 2
CKPT="${_CK%%$'\t'*}"; CKPT_NOTE="${_CK#*$'\t'}"
case "$CKPT" in
  ""|sealed) : ;;
  pending) V="CHECKPOINT-PENDENTE" ;;
  *) echo "ERRO: meta.drive_checkpoint com valor desconhecido: '$CKPT' (aceito: pending|sealed)" >&2; exit 2 ;;
esac

if [ "$MODE" = "check" ]; then
  printf 'drive %s — %s: pronto=%s bloqueado=%s (aberto=%s)\n' \
    "$(basename "$GRAPH" .kg.yaml)" "$V" "$n_ready" "$n_blocked" "$n_open"
  [ "$V" = "CHECKPOINT-PENDENTE" ] && printf '  lote anterior NÃO selado: %s\n' "${CKPT_NOTE:-(sem drive_checkpoint_note)}"
  case "$V" in DEADLOCK|CHECKPOINT-PENDENTE) exit 1 ;; *) exit 0 ;; esac
fi

# projeção legível — a FILA-PRONTA que o driver consome
printf '# Censo do plano — %s  ·  veredito: **%s**\n\n' "$(basename "$GRAPH" .kg.yaml)" "$V"
printf '> Fila-pronta do `/meta:drive` (determinística, consome o radar). Nós `open` cujos\n'
printf '> predecessores `DEPENDS_ON` já fecharam, por atenção. `DEPENDS_ON` é GUARDA ("não faça B\n'
printf '> antes de A"), não ordenação — a topológica dirigida é Fase 2 gated.\n\n'
printf '**pronto=%s · bloqueado=%s · aberto=%s**\n\n' "$n_ready" "$n_blocked" "$n_open"

printf '## Fila-pronta (o próximo trabalho, por atenção)\n'
if [ "$n_ready" -gt 0 ]; then
  printf '%s\n' "$RESULT" | awk -F'\t' '$1=="READY"' | sort -t$'\t' -k2,2nr \
    | while IFS=$'\t' read -r _s att id kind; do printf '  - [%s] `%s` (atenção %.1f)\n' "$kind" "$id" "${att:-0}"; done
else printf '  _fila-pronta vazia._\n'; fi

printf '\n## Bloqueados (esperando predecessor DEPENDS_ON abrir/fechar)\n'
if [ "$n_blocked" -gt 0 ]; then
  printf '%s\n' "$RESULT" | awk -F'\t' '$1=="BLOCKED"' | sort -t$'\t' -k2,2nr \
    | while IFS=$'\t' read -r _s att id kind blk; do printf '  - [%s] `%s` (atenção %.1f) — bloqueado por: %s\n' "$kind" "$id" "${att:-0}" "$blk"; done
else printf '  _nada bloqueado._\n'; fi

printf '\n## Ação\n'
case "$V" in
  CHECKPOINT-PENDENTE) printf '  ⛔ P0.5: o lote anterior NÃO foi selado (meta.drive_checkpoint: pending) — %s. PARE: o maestro sela (troca para sealed) antes de nova passada. `--check` sai ≠0.\n' "${CKPT_NOTE:-sem nota}" ;;
  DONE)     printf '  ✅ plano sem trabalho aberto — nada a conduzir.\n' ;;
  DEADLOCK) printf '  ⛔ há aberto(s) mas a fila-pronta está VAZIA: um predecessor DEPENDS_ON está travado (predecessor UNVERIFIABLE, ciclo, ou onda mal-modelada). Resolva o bloqueador antes de seguir. `--check` sai ≠0.\n' ;;
  READY)    printf '  ▶ conduza o topo da fila-pronta (P2 do laço); os bloqueados voltam sozinhos quando o predecessor fechar.\n' ;;
esac
