#!/usr/bin/env bash
# =============================================================================
# starter-research-seed.sh — cria a semente de PESQUISA no alvo da adoção
#
# POR QUÊ : a rule `.claude/rules/research-lens.md` declara `paths: docs/evolution/research/**`. Uma
#           rule cujo glob não casa NENHUM arquivo rastreado nunca carrega — e a REGRA 53 reprova isso
#           HARD. Medido em 2026-09-02: TODO adotante greenfield nascia vermelho no dia 1.
#           ⚠️ RASTREADO, não "existe em disco": `git ls-files` é a régua. Por isso o arquivo só cura
#           de fato depois do commit durável da adoção — antes dele o HARD é esperado.
#
# COMO    : idempotente; nunca clobba README em uso. Confere o próprio efeito (`exit 0` é declaração
#           do script sobre si; verificar é contar o que ele produziu).
#
# USO     : starter-research-seed.sh <DEST>
# =============================================================================
set -u
DEST="${1:?uso: starter-research-seed.sh <DEST>}"
R="${DEST}/docs/evolution/research"
_verifica() { [ -f "${R}/README.md" ] && exit 0
              echo "starter-research-seed: ${R}/README.md nao ficou no lugar" >&2; exit 1; }
[ -f "${R}/README.md" ] && _verifica
mkdir -p "${R}"
cat > "${R}/README.md" <<'PTR'
# Pesquisas deste repo (grafo primeiro)

Toda pesquisa/estudo/decisão nasce aqui como `<slug>-<AAAA-MM>/<slug>-<AAAA-MM>.kg.yaml` (SSOT) com a
prosa como projeção. A lente carrega sozinha ao tocar esta pasta (`.claude/rules/research-lens.md`);
a doutrina inteira está em `.claude/commands/common/prompts/research-doctrine.md`. Comece por
`bash .claude/validation/kg-corpus-grep.sh <tema>` — o que os grafos já sabem — e, para pesquisar,
`/onion-research <pergunta>`.
PTR
_verifica
