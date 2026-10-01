#!/usr/bin/env bash
# ===========================================================================
# mutant-leftover-check.sh — MUTANTE esquecido na árvore (REGRA 94)
#
# ── POR QUE EXISTE (dano consumado, medido em 2026-10-01) ──────────────────────────────────
# Um `exit 137` (SIGKILL do OOM killer) matou a sessão no meio de um teste de mutação e deixou um
# `git add` plantado dentro do `.githooks/pre-commit`. O repo ficou PIOR que antes do teste: o mutante
# era precisamente o defeito que a guarda recém-escrita existia para pegar, e ele sobreviveu no disco.
#
# ⚠️ POR QUE `trap` NÃO RESOLVE, e esta guarda não é redundante: **trap não intercepta SIGKILL**. Um
# helper que confie só em trap é cura falsa para o caso que de fato ocorreu. Esta guarda é a camada que
# **não depende do processo sobreviver** — mesmo que a sessão evapore, o próximo lint acusa.
#
# O CONTRATO: todo mutante plantado por `ops/mutate-and-restore.sh` carrega o marcador ONION_MUTANTE
# (o helper RECUSA plantar sem ele). Logo o marcador na árvore significa uma coisa só: alguém mutou e
# não restaurou. HARD, sem catraca e sem baseline — mutante esquecido não é passivo a tolerar, é
# contaminação a remover.
#
# ── A PROSA QUE NOMEIA A REGRA NÃO É MUTANTE (achado do próprio gate, 2026-10-01) ──────────
# A 1ª versão acusou o RESÍDUO DE REVISÃO deste PR, porque o documento explica a regra e portanto
# escreve o marcador. O sítio legítimo não é só o par helper+guarda: é toda DOUTRINA e todo RESÍDUO
# que ensinam o mecanismo — e eles não se podem enumerar um a um, porque o nome do resíduo deriva da
# branch. Daí a allowlist por PREFIXO abaixo.
#
# ⚠️ TETO DECLARADO, e a troca é deliberada: um mutante plantado dentro de um caminho da allowlist
# ESCAPA. Aceita-se porque (a) o harness planta em ARTEFATO EXECUTÁVEL, que é o que o dano de
# 2026-10-01 provou, e (b) acusar prosa geraria falso positivo em toda doutrina que explica a regra —
# e guarda que grita no caminho correto ensina a ignorar o vermelho. Fixture `.md` fora da allowlist
# SEGUE sendo julgada: a exceção é por CAMINHO, nunca por extensão.
#
# Saída: uma linha por achado, prefixada por `REGRA 94: `. Exit: 0 limpo · 1 achado · 3 não pude julgar.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_mutant_leftover_selftests).
# ===========================================================================
set -uo pipefail
REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "mutant-leftover: alvo inexistente: ${REPO}" >&2; exit 3; }
command -v git >/dev/null 2>&1 || { echo "mutant-leftover: git ausente — NÃO PUDE JULGAR" >&2; exit 3; }
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 || { echo "mutant-leftover: ${REPO} não é repo git — NÃO PUDE JULGAR" >&2; exit 3; }

# O marcador é partido em duas metades na fonte: senão ESTA GUARDA se acusaria, e guarda que reprova a
# si mesma nasce morta (medido na própria escrita, 2026-10-01).
_M="ONION""_MUTANTE"

found=0
# Só arquivos RASTREADOS: o marcador num scratchpad ou num tmp é legítimo (é lá que a bancada trabalha).
while IFS= read -r f; do
  [ -n "${f}" ] || continue
  # o próprio helper e esta guarda citam o marcador por contrato — e são os ÚNICOS sítios legítimos
  # SÍTIOS LEGÍTIMOS: o par helper+guarda+bancada (contrato), e a prosa que ENSINA o mecanismo
  # (doutrina e resíduo de revisão). Allowlist por PREFIXO porque o nome do resíduo deriva da branch.
  case "${f}" in
    ops/mutate-and-restore.sh|.claude/validation/mutant-leftover-check.sh|.claude/validation/lint-selftest.sh) continue ;;
    .claude/validation/lint-rules.md|docs/evolution/review/*|docs/knowledge-base/*|.claude/commands/common/prompts/*) continue ;;
  esac
  echo "REGRA 94: [mutante-esquecido] ${f} contém o marcador ${_M} — alguém plantou um mutante e NÃO restaurou (trap não pega SIGKILL; foi assim que um \`git add\` ficou no pre-commit em 2026-10-01). Restaure do commitado: git checkout -- ${f}"
  found=1
done < <(cd "${REPO}" && git grep -lF -- "${_M}" 2>/dev/null | sort || true)

exit "${found}"
