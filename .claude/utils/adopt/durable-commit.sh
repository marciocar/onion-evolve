#!/usr/bin/env bash
# =============================================================================
# durable-commit.sh — materializa a instalação Onion como OBJETO GIT (never-clobber).
#
# Usado pelo /meta:adopt: Fase 5 (adoção) e --update, APÓS aplicar + config + re-carimbar.
# Fecha o incidente-fonte 2026-07-08 (inbox/_processed/2026-07-08-proposta-branch-onion-vendor.md):
# o apply é `cp` na working tree; enquanto uncommitted, um DESCARTE de working-tree
# (git restore / git checkout -- . / reset --hard / remoção de worktree) apaga tudo — inclusive
# revertendo o .onion-version. (Verificado por dogfood: `git checkout` de branch SIMPLES carrega/
# bloqueia tracked sujo; quem destrói é o descarte.) Este helper commita a superfície Onion numa
# branch dedicada → a instalação vira objeto git durável, imune a qualquer descarte.
#
# Uso     : durable-commit.sh <DEST> <OP> <PIN> [BR]      (env SUBJECT=... sobrepõe o assunto)
#   DEST  = repo alvo · OP = adopt|update · PIN = source_commit curto
#   BR    = branch do commit (default: chore/onion-<OP>-<PIN>; a adoção passa onion/adopt,
#           branch que a Fase 2 já cria; o --update dedica chore/onion-update-<pin>)
#
# Never-clobber: staja SÓ a superfície Onion — código de produto uncommitted do maestro fica de fora.
# commit --no-verify (worktree legacy sem node_modules: husky/lint-staged daria ENOENT e REVERTERIA).
# Gracioso: DEST não-git → aviso + exit 0. Nada a commitar → exit 0 (idempotente).
# Determinístico, sem jq. Exercitado por lint-selftest.sh (run_durable_commit_selftests).
# =============================================================================
set -uo pipefail

DEST="${1:?uso: durable-commit.sh <DEST> <OP> <PIN> [BR]}"
OP="${2:?OP (adopt|update) obrigatório}"
PIN="${3:?PIN (source_commit curto) obrigatório}"
BR="${4:-chore/onion-${OP}-${PIN}}"

git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "⚠️  ${DEST} não é repo git — commit durável pulado." >&2; exit 0; }

# Branch do commit: entra se já existe, cria a partir do HEAD atual senão. A working tree segue INTACTA
# (só ganha ponteiro de branch + o commit) — NÃO é vendor-branch "que se usa direto".
git -C "${DEST}" rev-parse --verify "${BR}" >/dev/null 2>&1 \
  && git -C "${DEST}" checkout "${BR}" >/dev/null 2>&1 \
  || git -C "${DEST}" checkout -b "${BR}" >/dev/null 2>&1

# Stage SÓ a superfície Onion (never-clobber do staging do maestro — produto fica de fora).
# Inclui os ARTEFATOS GERADOS na adoção (CLAUDE.md, inventário, .gitattributes, contextos de domínio) —
# achado de campo 2026-07-09 (adoção greenfield de um adotante de campo): sem eles, ficavam uncommitted = a mesma
# lacuna de durabilidade que #301 fecha p/ o framework. `git add` só staja o que mudou → seguro no --update.
# ⚠️ LICENSE-ONION / LICENSE-ONION-DOCS entram aqui porque o `emit-licenses.sh` as ESCREVE no alvo
# e sem staging elas ficariam untracked — chegariam e nunca seriam commitadas, sumindo num
# `git clean`. O NOME PRÓPRIO é deliberado: `LICENSE` na raiz rege o repositório inteiro por
# convenção, e entregá-lo assim declararia a titularidade do autor do core sobre o código do
# adotante (medido e recusado em 2026-09-15). Emissor e staging são um PAR: curar um só não entrega.
#
# ⚠️ E NÃO, esta lista NÃO é a 5ª cópia do manifesto de transporte — foi assim que eu a li primeiro,
# e a leitura estava errada. Ela usa `.claude` INTEIRO (superset das 8 raízes `.claude/*` da SSOT) e
# acrescenta os ARTEFATOS GERADOS na adoção, que não viajam do core: CLAUDE.md, docs/onion, os três
# contextos de domínio, .githooks. Propósitos diferentes — a SSOT diz o que COPIA, esta diz o que se
# COMMITA no alvo. Unificá-las quebraria a durabilidade dos gerados.
ONION_PATHS=(.claude docs/meta-specs docs/knowledge-base docs/sdaal docs/evolution \
             docs/onion docs/business-context docs/technical-context docs/compliance-context \
             CLAUDE.md CLAUDE.onion.md .gitattributes .prettierignore .githooks .env.example.onion \
             LICENSE-ONION LICENSE-ONION-DOCS)
add=(); for p in "${ONION_PATHS[@]}"; do [ -e "${DEST}/${p}" ] && add+=("${p}"); done
[ "${#add[@]}" -gt 0 ] && git -C "${DEST}" add -- "${add[@]}" 2>/dev/null

# Guard nada-a-commitar (re-run idempotente).
if git -C "${DEST}" diff --cached --quiet 2>/dev/null; then
  echo "Onion: nada novo a commitar (instalação já durável em ${BR})."
  exit 0
fi

# ASSUNTO EM pt-BR (sinal de campo de um adotante, 2026-09-04): o prefixo Conventional é contrato de
# máquina (inglês), o ASSUNTO é narrativa (pt-BR) — code-standards.md §3.4, ratificado em 2026-08-03. O
# helper emitia "adopt to pin <x>" e a revisão adversarial do adotante pegou o desvio. `SUBJECT=` permite
# ao alvo com outra política passar o seu; sem ele, o default segue a política da casa.
case "${OP}" in
  adopt)  _subj="adotar o Onion no pin ${PIN}" ;;
  update) _subj="atualizar o Onion para o pin ${PIN}" ;;
  *)      _subj="${OP} no pin ${PIN}" ;;
esac
[ -n "${SUBJECT:-}" ] && _subj="${SUBJECT}"
git -C "${DEST}" commit --no-verify -m "chore(onion): ${_subj}" >/dev/null 2>&1 \
  && { echo "Onion: instalação commitada em ${BR} (durável — imune a descarte de working-tree)."; exit 0; } \
  || { echo "⚠️  commit durável falhou em ${DEST} (${BR})." >&2; exit 1; }
