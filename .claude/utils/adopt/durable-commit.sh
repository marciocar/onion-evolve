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
# ONION_REQUIRED_LIST=<arquivo> (opcional; ONION_REQUIRED_NUL=1 = separado por NUL): caminhos que TÊM de estar no commit — staja com
#   `-f` (atravessa .gitignore) e confere depois; faltou algum → exit 3 nomeando. Ver o bloco abaixo.
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

# ── ARQUIVO EXIGIDO atravessa o .gitignore (sinal de campo de um hub, 2026-10-04) ──────────────────
# `git add <dir>` PULA em silêncio todo arquivo NOVO que um .gitignore cubra — sem erro, rc=0. Num
# alvo cuja branch ignorava `.claude/`, o update reportou "merge limpo" e 17 arquivos novos do core
# nunca chegaram (entre eles um hook JÁ registrado no settings.json: erro em todo fim de turno).
# O `-f` NÃO pode ir no `.claude` inteiro — ali há o que é ignorado DE PROPÓSITO (sessions, worktrees,
# settings.local.json). Ele vai só na lista EXATA que o chamador sabe ter transportado, e a
# pós-condição confere que cada um está no índice: o que faltar é NOMEADO e o exit é 3.
if [ -n "${ONION_REQUIRED_LIST:-}" ]; then
  [ -r "${ONION_REQUIRED_LIST}" ] || { echo "ERRO: ONION_REQUIRED_LIST ilegível: ${ONION_REQUIRED_LIST}" >&2; exit 3; }
  # ONION_REQUIRED_NUL=1 → lista separada por NUL (o vendor-branch a produz assim: nome acentuado ou com
  # espaço nunca é escapado). Sem ele, um caminho por linha. Internamente tudo vira NUL.
  _rq="$(mktemp)"; trap 'rm -f "${_rq}"' EXIT
  if [ "${ONION_REQUIRED_NUL:-0}" = 1 ]; then LC_ALL=C sort -zu "${ONION_REQUIRED_LIST}" > "${_rq}"
  else grep -v '^$' "${ONION_REQUIRED_LIST}" | tr '\n' '\0' | LC_ALL=C sort -zu > "${_rq}"; fi
  if [ -s "${_rq}" ]; then
    # AUSENTE da árvore é nomeado ANTES do add: um pathspec que não casa aborta o `git add` INTEIRO, e
    # 1 faltante virava N "faltantes" no relatório (Elenxo, executado com 3 presentes + 1 ausente).
    _absent="$(while IFS= read -r -d '' _f; do [ -e "${DEST}/${_f}" ] || printf '%s\n' "${_f}"; done < "${_rq}")"
    if [ -n "${_absent}" ]; then
      echo "ERRO: $(grep -c . <<< "${_absent}") arquivo(s) EXIGIDO(S) ausentes da árvore — nada foi forçado:" >&2
      printf '%s\n' "${_absent}" | head -20 | sed 's/^/    /' >&2
      exit 3
    fi
    # `--literal-pathspecs`: `x[1].md` é o arquivo `x[1].md`, nunca o glob que forçaria `x1.md` ignorado.
    git --literal-pathspecs -C "${DEST}" add -f --pathspec-from-file="${_rq}" --pathspec-file-nul 2>&1 >/dev/null \
      | sed 's/^/  git add -f: /' >&2
    _miss="$(git -C "${DEST}" ls-files --cached -z 2>/dev/null | LC_ALL=C sort -zu \
             | LC_ALL=C comm -z -13 - "${_rq}" | tr '\0' '\n')"
    if [ -n "${_miss}" ]; then
      echo "ERRO: $(grep -c . <<< "${_miss}") arquivo(s) EXIGIDO(S) presentes na árvore mas RECUSADOS pelo git add:" >&2
      printf '%s\n' "${_miss}" | head -20 | sed 's/^/    /' >&2
      exit 3
    fi
  fi
fi

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
# ASSINATURA (2026-10-06, medido nas adoções do onion-curation e do onion-kg-ssot): o commit de adoção saía
# SEM a assinatura, e as duas sessões fizeram amend à mão. Vale a do PRÓPRIO adotante (`attribution.commit` do
# settings.json DELE, que o merge never-clobber preserva — PR #936); sem ela, o commit sai sem assinatura.
_sig=""
if [ -f "${DEST}/.claude/settings.json" ] && command -v python3 >/dev/null 2>&1; then
  _sig="$(python3 -c 'import json,sys
try: print((json.load(open(sys.argv[1])).get("attribution") or {}).get("commit") or "")
except Exception: print("")' "${DEST}/.claude/settings.json")"
fi
_msg=(-m "chore(onion): ${_subj}")
[ -n "${_sig}" ] && _msg+=(-m "${_sig}")
git -C "${DEST}" commit --no-verify "${_msg[@]}" >/dev/null 2>&1 \
  && { echo "Onion: instalação commitada em ${BR} (durável — imune a descarte de working-tree)."; exit 0; } \
  || { echo "⚠️  commit durável falhou em ${DEST} (${BR})." >&2; exit 1; }
