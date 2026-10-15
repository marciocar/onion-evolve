#!/usr/bin/env bash
# ===========================================================================
# materialize-adopter.sh — monta um ADOTANTE de fixture com o MESMO corte que o /meta:adopt vendoriza
# (core-only, irmão de ops/materialize-door.sh (core-only)).
#
# ── POR QUE EXISTE (SAC-149, medido em 2026-10-15) ─────────────────────────────────────────────
# O core testava a maquinaria no formato do CORE, nunca no formato do adotante que a recebe. Três
# achados do `--update` de um adotante para 7a50fc14 têm essa raiz: o `kg-contract-check.sh` viajava
# sem o leitor do contrato (vendor/kg-ssot) e lá saía sempre rc 2; as REGRAS 85 e 92 emitiam SOFT de
# "não pôde julgar" num adotante comum, com a mensagem da 85 mandando rodar um `ops/` que ele não tem;
# e o pin do grafo de adoção era passo à mão. Nenhuma família da bancada montava um adotante: a do mini
# monta a PORTA didática, as do vendor medem a LISTA. Testar no caminho errado é não testar.
#
# O QUE FAZ: monta em <DEST> um repo git greenfield (um arquivo de produto), aplica o framework pelo
# MESMO caminho do `--update` (o manifesto vem de `vendor-branch.sh --print-manifest`, que lê papel e
# destino como o update os lê) e roda os helpers REAIS da adoção, na ordem do adopt.md: stub e checagem
# do bundle, configuração pós-cópia, carimbo, semente do KG, baselines e o commit durável. Quem consome
# é a família `adopter_shape` da bancada, que roda no clone dele o lint, o contrato do grafo e o radar.
#
# O QUE NÃO FAZ (teto declarado):
#   · não é o /meta:adopt: o procedimento é markdown e tem passos de julgamento (diff, confirmação do
#     maestro, Fase 1 de engenharia reversa, oferta de CI, CLAUDE.md fundido). Aqui entram só os passos
#     determinísticos, e a lista deles é desta cópia — se o adopt.md ganhar um passo, este script não
#     o vê sozinho;
#   · `--with-gate` instala o githook e roda a prova de vida (o lint inteiro, de novo): fica fora do
#     default porque dobra o tempo da família;
#   · a existência das raízes do manifesto é lida do HEAD (vendor-manifest.sh), e o conteúdo do --from:
#     uma raiz NOVA só no índice não entra até ser commitada.
#
# Uso : ops/materialize-adopter.sh <DEST> [--role adopted|hub|standalone] [--from INDEX|WORKTREE|<ref>] [--with-gate]
#         --from WORKTREE = os rastreados como estão no DISCO (para rodar mutante sobre SUT que roda na fixture)
#         --from INDEX (default) = a árvore do ÍNDICE (o que o pre-commit vai commitar), pelo mesmo motivo
#         do `_archive_staged` da bancada: fixture do HEAD testa o já commitado e esconde o staged.
# Saída: rc 0 montado (última linha `materialize-adopter: OK <DEST> pin=<sha12> arquivos=<n>`) ·
#        2 uso · 3 um passo falhou (nomeado). Determinístico, sem rede.
# ===========================================================================
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST=""; ROLE="adopted"; FROM="INDEX"; WITH_GATE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --role) ROLE="${2:-}"; shift 2 || { echo "materialize-adopter: --role sem valor" >&2; exit 2; } ;;
    --from) FROM="${2:-}"; shift 2 || { echo "materialize-adopter: --from sem valor" >&2; exit 2; } ;;
    --with-gate) WITH_GATE=1; shift ;;
    -h|--help) sed -n '2,34p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) echo "materialize-adopter: opção desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${DEST}" ] && DEST="$1" || { echo "materialize-adopter: destino já informado" >&2; exit 2; }; shift ;;
  esac
done
[ -n "${DEST}" ] || { echo "uso: ops/materialize-adopter.sh <DEST> [--role adopted|hub|standalone] [--from INDEX|<ref>] [--with-gate]" >&2; exit 2; }
case "${ROLE}" in adopted|hub|standalone) : ;; *) echo "materialize-adopter: --role '${ROLE}' não é papel de ADOÇÃO (adopted|hub|standalone); porta é do materialize-door" >&2; exit 2 ;; esac

_die() { echo "materialize-adopter: ✗ passo '$1' falhou${2:+ — $2}" >&2; exit 3; }
U="${REPO_ROOT}/.claude/utils/adopt"

# (0) destino: novo ou vazio, e fora de qualquer repo (senão o índice seria o do repo hospedeiro)
if [ -e "${DEST}" ] && [ -n "$(ls -A "${DEST}" 2>/dev/null)" ]; then
  echo "materialize-adopter: '${DEST}' existe e não está vazio — recuso montar por cima" >&2; exit 2
fi
mkdir -p "${DEST}" || _die destino "não criei ${DEST}"
DEST="$(cd "${DEST}" && pwd -P)"
_host="$(git -C "$(dirname "${DEST}")" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "${_host}" ] || _die destino "${DEST} está DENTRO do repo ${_host}; monte a fixture fora dele"

# (1) a árvore-fonte
if [ "${FROM}" = WORKTREE ]; then
  # A ÁRVORE DE TRABALHO (os rastreados, com as edições não stajadas), num índice TEMPORÁRIO — o do repo não é
  # tocado. Existe para o MUTANTE (PR 2 da SAC-149, 2026-10-15): o ops/mutate-and-restore.sh muda o arquivo no
  # disco, e um SUT que roda DENTRO da fixture (o lint, por exemplo) vinha do índice, sem o mutante — o caso
  # passava verde com a cura revertida, e parecia que o mutante não mordia.
  _ti="$(mktemp)"; cp "$(git -C "${REPO_ROOT}" rev-parse --git-path index)" "${_ti}" 2>/dev/null || : > "${_ti}"
  GIT_INDEX_FILE="${_ti}" git -C "${REPO_ROOT}" add -u >/dev/null 2>&1 || _die fonte "não consegui montar o índice temporário da árvore de trabalho"
  TREE="$(GIT_INDEX_FILE="${_ti}" git -C "${REPO_ROOT}" write-tree 2>/dev/null || true)"; rm -f "${_ti}"
  [ -n "${TREE}" ] || _die fonte "write-tree do índice temporário falhou"
elif [ "${FROM}" = INDEX ]; then
  TREE=""
  for _t in 1 2 3 4 5; do TREE="$(git -C "${REPO_ROOT}" write-tree 2>/dev/null || true)"; [ -n "${TREE}" ] && break; sleep 0.2; done
  [ -n "${TREE}" ] || _die fonte "git write-tree não respondeu (disputa de .git/index.lock ou índice ilegível) — não caio para HEAD calado"
else
  TREE="$(git -C "${REPO_ROOT}" rev-parse --verify --quiet "${FROM}^{tree}" 2>/dev/null || true)"
  [ -n "${TREE}" ] || _die fonte "--from '${FROM}' não resolve para uma árvore"
fi

# (2) o manifesto pelo caminho do --update (papel e destino como o update os passa)
_mf_out="$(ONION_ROLE="${ROLE}" ONION_KIND=adoption bash "${U}/vendor-branch.sh" --print-manifest "${REPO_ROOT}" 2>/dev/null)" \
  || _die manifesto "vendor-branch.sh --print-manifest saiu ≠0"
mapfile -t SPEC <<< "${_mf_out}"
[ -n "${_mf_out}" ] && [ "${#SPEC[@]}" -gt 0 ] || _die manifesto "VAZIO — pathspec ausente significa TODOS para o git"

# (3) o repo do adotante: greenfield com um arquivo de produto e a integração em main
git -C "${DEST}" init -q -b main >/dev/null 2>&1 || git -C "${DEST}" init -q >/dev/null 2>&1 || _die "git init"
git -C "${DEST}" config user.email fixture@onion.invalid; git -C "${DEST}" config user.name "fixture"
git -C "${DEST}" config commit.gpgsign false
mkdir -p "${DEST}/src"; printf '# produto de fixture\n' > "${DEST}/README.md"; printf 'export const x = 1;\n' > "${DEST}/src/app.js"
git -C "${DEST}" add -A >/dev/null 2>&1 && git -C "${DEST}" commit -q --no-verify -m "produto" >/dev/null 2>&1 || _die "commit do produto"
git -C "${DEST}" branch -M main >/dev/null 2>&1 || true

# (4) cópia segura: archive da árvore + stub dos baselines + checagem do bundle
git -C "${REPO_ROOT}" archive "${TREE}" -- "${SPEC[@]}" | tar -x -C "${DEST}" || _die "archive"
bash "${U}/vendor-manifest.sh" --stub-baselines "${DEST}" >/dev/null || _die "stub-baselines"
bash "${U}/vendor-manifest.sh" --repo "${REPO_ROOT}" --check-bundle "${DEST}" >/dev/null || _die "check-bundle" "o bundle carrega biografia"

# (5) configuração pós-cópia (os passos determinísticos do adopt.md, na ordem dele)
bash "${U}/scope-claude-gitignore.sh" "${DEST}" >/dev/null 2>&1 || _die scope-claude-gitignore
bash "${U}/ensure-secret-gitignore.sh" "${DEST}" >/dev/null 2>&1 || _die ensure-secret-gitignore
bash "${U}/emit-licenses.sh" "${DEST}" "${REPO_ROOT}" >/dev/null 2>&1 || _die emit-licenses
git -C "${REPO_ROOT}" show "${TREE}:.claude/settings.json" > "${DEST}/.claude/settings.json" 2>/dev/null || _die settings.json
bash "${U}/starter-coevolution.sh" "${DEST}" >/dev/null 2>&1 || _die starter-coevolution
bash "${U}/starter-kg-inbox.sh" "${DEST}" >/dev/null 2>&1 || _die starter-kg-inbox
bash "${U}/starter-research-seed.sh" "${DEST}" >/dev/null 2>&1 || _die starter-research-seed
git -C "${DEST}" config gitflow.branch.develop main
bash "${U}/regen-ssot-projections.sh" "${DEST}" >/dev/null 2>&1 || _die regen-ssot-projections

# (6) carimbo (identidade da FONTE) → semente do KG → baselines do corpus do ALVO
eval "$(bash "${REPO_ROOT}/.claude/validation/onion-version.sh" | awk -F': ' \
  '/^framework/{print "SRC_FRAMEWORK="$2} /^commit:/{print "SRC_COMMIT="$2} /^commit_date/{print "SRC_COMMIT_DATE="$2}')"
[ -n "${SRC_COMMIT:-}" ] || _die carimbo "onion-version.sh não devolveu o commit da fonte"
bash "${U}/write-stamp.sh" "${DEST}" --framework "${SRC_FRAMEWORK}" --commit "${SRC_COMMIT}" \
  --commit-date "${SRC_COMMIT_DATE}" --adopted-from "${REPO_ROOT}" --role "${ROLE}" --mode greenfield >/dev/null 2>&1 \
  || _die write-stamp
bash "${U}/seed-adoption-graph.sh" "${DEST}" --gate-unproven >/dev/null 2>&1 || _die seed-adoption-graph
_rb=0; bash "${U}/regen-baselines.sh" "${DEST}" --ensure-from "${REPO_ROOT}" >/dev/null 2>&1 || _rb=$?
[ "${_rb}" -eq 2 ] && _die regen-baselines "rc=2: o alvo herdaria o baseline do core"
[ "${_rb}" -eq 3 ] && echo "materialize-adopter: ⚠️ regen-baselines rc=3 (baseline não resolvido) — segue, como no adopt.md" >&2

# (7) gate (opcional, lento): instala o githook e roda a prova de vida, como o passo (6) do adopt.md
if [ "${WITH_GATE}" -eq 1 ]; then
  bash "${U}/install-onion-githook.sh" "${DEST}" > "${DEST}.githook.log" 2>&1 || _die install-onion-githook "log em ${DEST}.githook.log"
fi

# (8) commit durável REAL (o helper do adopt), direto na integração da fixture
bash "${U}/durable-commit.sh" "${DEST}" adopt "${SRC_COMMIT}" main >/dev/null 2>&1 || _die durable-commit
[ -z "$(git -C "${DEST}" status --porcelain --untracked-files=all 2>/dev/null)" ] \
  || echo "materialize-adopter: ⚠️ sobrou arquivo FORA do commit durável (um clone do adotante não o recebe): $(git -C "${DEST}" status --porcelain --untracked-files=all | head -5 | tr '\n' ' ')" >&2

echo "materialize-adopter: OK ${DEST} pin=${SRC_COMMIT} papel=${ROLE} arquivos=$(git -C "${DEST}" ls-files | wc -l | tr -d ' ')"
