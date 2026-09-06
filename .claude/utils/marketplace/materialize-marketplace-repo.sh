#!/usr/bin/env bash
# =============================================================================
# materialize-marketplace-repo.sh — o "project-door" que faltava (ADR family-repo-topology D5/F5).
#
# Materializa um repo PÚBLICO de marketplace (ex.: onion-plugins) a partir do SOURCE (o core):
# monta TODOS os plugins publicáveis fresco (loop sobre verticals/*.manifest.sh) num <TARGET>/plugins/,
# gera <TARGET>/.claude-plugin/marketplace.json (self-contained, sources relative-path) + README.
#
# FRONTEIRA (moat): só empacota o que os manifestos declaram — e a REGRA 61 (check_moat_boundary) já
# reprova qualquer manifesto que liste meta-fábrica ou grafo privado. Aqui, uma 2ª guarda em cinto-e-
# suspensório: recusa materializar se algum plugin montado contiver ARQUIVO de meta-fábrica ou *.kg.yaml.
#
# I3 (um escritor por repo): comita NO <TARGET> (repo próprio do maestro, escritor único) mas NUNCA faz
# push — o push é human-gated. Nunca escreve em repo de terceiro nem toca o remote.
#
# Uso:  bash materialize-marketplace-repo.sh <TARGET> [--name <marketplace-name>] [--no-commit]
#       <TARGET>        dir do repo-alvo (vazio ou já-git). Default do name: onion-plugins.
# Saída: relatório por plugin; exit 0 ok · 2 erro de precondição · 3 vazamento de moat (aborta).
# Determinístico, sem jq. Exercitado por lint-selftest.sh (run_materialize_repo_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || true)"
VDIR="${HERE}/verticals"
ASM="${HERE}/assemble-plugin.sh"
GEN="${HERE}/generate-marketplace.sh"

TARGET=""; MKT_NAME="onion-plugins"; DO_COMMIT=1
while [ "$#" -gt 0 ]; do
  case "$1" in
    --name) MKT_NAME="${2:-}"; shift 2 ;;
    --no-commit) DO_COMMIT=0; shift ;;
    -*) echo "materialize: opção desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${TARGET}" ] && TARGET="$1" || { echo "materialize: alvo já informado ('${TARGET}')" >&2; exit 2; }; shift ;;
  esac
done

[ -n "${TARGET}" ] || { echo "uso: materialize-marketplace-repo.sh <TARGET> [--name <n>] [--no-commit]" >&2; exit 2; }
[ -n "${SRC}" ] || { echo "ERRO: não consegui resolver o SOURCE (core) a partir de ${HERE}." >&2; exit 2; }
[ -f "${ASM}" ] && [ -f "${GEN}" ] || { echo "ERRO: assemble-plugin.sh / generate-marketplace.sh ausentes." >&2; exit 2; }
[ -d "${VDIR}" ] || { echo "ERRO: verticals/ ausente em ${VDIR}." >&2; exit 2; }

# GUARDA DE PAPEL: só a FONTE materializa (o core lê os próprios manifestos e escreve o repo público).
# Um adotante/consumidor não tem os manifestos-fonte completos e não deve gerar marketplace.
_role="$(awk -F': *' '/^role:/{print $2; exit}' "${SRC}/.claude/.onion-version" 2>/dev/null || true)"
if [ -n "${_role}" ] && [ "${_role}" != "source" ]; then
  echo "ERRO: materialize só roda na FONTE (role: source); aqui role='${_role}'." >&2; exit 2
fi

mkdir -p "${TARGET}/plugins" "${TARGET}/.claude-plugin" || { echo "ERRO: não consegui criar ${TARGET}." >&2; exit 2; }

# Semeia o top-level do marketplace.json com o NOME PÚBLICO (o generate preserva o topo existente).
if [ ! -f "${TARGET}/.claude-plugin/marketplace.json" ]; then
  cat > "${TARGET}/.claude-plugin/marketplace.json" <<JSON
{
  "name": "${MKT_NAME}",
  "owner": { "name": "Onion - Marcio Carvalho" },
  "metadata": {
    "description": "Marketplace publico do Sistema Onion — o framework operacional como plugins instalaveis (/plugin marketplace add).",
    "version": "0.1.0",
    "pluginRoot": "./plugins"
  },
  "plugins": []
}
JSON
fi

# Monta cada plugin publicável fresco no TARGET (SRC=core lê a fonte; DEST=alvo/plugins/<nome>).
count=0; PRODUZIDOS=""
for m in "${VDIR}"/*.manifest.sh; do
  [ -f "${m}" ] || continue
  case "$(basename "${m}")" in __*) continue ;; esac   # ignora fixtures de teste
  pname="$( set +u; . "${m}" >/dev/null 2>&1; printf '%s' "${PLUGIN_NAME:-}" )"
  [ -n "${pname}" ] || { echo "⚠️  ${m}: sem PLUGIN_NAME — pulado." >&2; continue; }
  rm -rf "${TARGET}/plugins/${pname}"
  if bash "${ASM}" "${m}" "${SRC}" "${TARGET}/plugins/${pname}" >/dev/null 2>&1; then
    echo "  ✓ ${pname}"
    PRODUZIDOS="${PRODUZIDOS} ${pname}"
    count=$((count+1))
  else
    echo "ERRO: falha ao montar '${pname}' de ${m}." >&2; exit 2
  fi
done
[ "${count}" -gt 0 ] || { echo "ERRO: nenhum plugin montado." >&2; exit 2; }


# 2ª GUARDA DE MOAT (cinto-e-suspensório): nenhum plugin materializado pode conter ARQUIVO de
# meta-fábrica nem grafo privado. A REGRA 61 já barra na declaração; aqui barra no resultado.
# Nomes ESPECÍFICOS da meta-fábrica (comandos achatados no plugin → só o basename resta; um glob
# `create-*` false-positivaria em create-task-structure, comando de PRODUTO legítimo). + federação
# downstream/ledger + QUALQUER grafo .kg.yaml.
leak="$(find "${TARGET}/plugins" -type f \( \
        -name 'create-abstraction.md' -o -name 'create-agent.md' -o -name 'create-agent-express.md' \
        -o -name 'create-command.md' -o -name 'create-knowledge-base.md' -o -name 'create-skill.md' \
        -o -name 'create-vertical.md' -o -name 'adopt.md' -o -name 'evolve.md' \
        -o -name 'co-announce.md' -o -name 'co-deliver.md' -o -name 'federation-*.md' -o -name 'absorb-skill.md' \
        -o -name 'assemble-plugin.sh' -o -name 'generate-marketplace.sh' -o -name 'decouple-source.sh' \
        -o -name '*.kg.yaml' \) 2>/dev/null || true)"
if [ -n "${leak}" ]; then
  echo "ABORTA (moat): plugin materializado contém fonte de meta-fábrica/grafo privado:" >&2
  printf '%s\n' "${leak}" | sed 's/^/    /' >&2
  exit 3
fi

# ---------------------------------------------------------------------------
# PODA — plugin que SUMIU do core tem de sumir do marketplace.
#
# POR QUE EXISTE (medido 2026-09-06, ao materializar para publicar a consolidação 8→5). O laço de
# build só remove o diretório do plugin que está prestes a reconstruir. Plugin que deixou de existir
# no core NUNCA era removido do alvo — e o `marketplace.json` é gerado VARRENDO `TARGET/plugins/`,
# então herdava os órfãos: 5 construídos, 8 diretórios, 8 entradas no catálogo, e o commit dizendo
# "materializa (5 plugins)". `declarado != verificado` no artefato que vai para o PÚBLICO.
#
# ⚠️ QUATRO CICATRIZES DE UMA PASSADA ADVERSARIAL, todas medidas, nenhuma hipotética:
#   (a) `rm -rf "${dir}/"` — com a BARRA FINAL que o glob `*/` sempre produz — ATRAVESSA SYMLINK e
#       apaga o conteúdo do ALVO, fora do TARGET, com rc=0 e o link sobrevivendo para repetir na
#       rodada seguinte. Aqui: symlink nunca é podado (só reportado), e o `rm` usa `${_d%/}`.
#   (b) o marcador de "foi este script que gerou" NÃO é `plugin.json` (isso é marcador de SER
#       plugin): é `provenance.json`, que o assemble escreve. Com `plugin.json`, um plugin que o
#       maestro publicasse à mão no marketplace seria APAGADO — perda de dado no repo dele.
#   (c) a poda enumerava com glob (cego a dot-dir) e o gerador do catálogo com `find` (que enxerga):
#       um órfão OCULTO sobrevivia à poda E entrava no catálogo, mantendo vivo o próprio sintoma
#       que esta seção existe para matar. Aqui a enumeração inclui ocultos.
#   (d) a poda rodava ANTES da guarda de moat: um abort (exit 3) deixava o alvo PIOR que antes —
#       catálogo apontando para diretório já apagado, irreversível. Agora roda DEPOIS.
podados=""; simbolicos=""
if [ -d "${TARGET}/plugins" ]; then
  while IFS= read -r _d; do
    [ -n "${_d}" ] || continue
    _n="$(basename "${_d}")"
    case " ${PRODUZIDOS} " in *" ${_n} "*) continue ;; esac
    if [ -L "${_d}" ]; then
      simbolicos="${simbolicos} ${_n}"; continue          # NUNCA seguir link para apagar
    fi
    if [ -f "${_d}/.claude-plugin/provenance.json" ]; then
      rm -rf "${_d%/}"; podados="${podados} ${_n}"
    else
      echo "  ⚠️  ${_n}: em plugins/ sem provenance.json — NÃO podado (não foi gerado por este script)" >&2
    fi
  done <<EOF
$(find "${TARGET}/plugins" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) 2>/dev/null | LC_ALL=C sort)
EOF
fi
[ -z "${podados}" ]   || echo "  ⊘ podado(s) do marketplace (não existem mais no core):${podados}"
[ -z "${simbolicos}" ] || echo "  ⚠️  link(s) simbólico(s) em plugins/ IGNORADO(s) pela poda (apagar através deles sairia do alvo):${simbolicos}" >&2

# Gera o marketplace.json self-contained (varre TARGET/plugins/*, preserva o topo semeado acima).
bash "${GEN}" "${TARGET}" > "${TARGET}/.claude-plugin/marketplace.json.new" 2>/dev/null \
  && mv "${TARGET}/.claude-plugin/marketplace.json.new" "${TARGET}/.claude-plugin/marketplace.json" \
  || { echo "ERRO: generate-marketplace falhou." >&2; exit 2; }

# README do marketplace (padrão de referência do Claude Code) — GERADO do próprio alvo pelo marketplace-readme.sh
# (quick start slash+CLI, tabela de plugins com o que cada um traz, manter em dia, requisitos, política de versão, moat).
bash "${HERE}/marketplace-readme.sh" "${TARGET}" "${MKT_NAME}" >&2 || { echo "ERRO: marketplace-readme.sh falhou" >&2; exit 2; }

# ⚠️ A MENSAGEM DIZ AS DUAS CONTAS QUANDO ELAS DIVERGEM. `count` é quanto veio do CORE; o catálogo
#    pode ter mais (plugin que o dono do marketplace publicou à mão, preservado pela poda). Dizer só
#    um número num artefato público é a mesma classe de `declarado != verificado` que a poda cura.
CAT_COUNT="$(python3 -c "import json,sys;print(len(json.load(open(sys.argv[1]))['plugins']))" \
             "${TARGET}/.claude-plugin/marketplace.json" 2>/dev/null || printf '%s' "${count}")"
if [ "${CAT_COUNT}" = "${count}" ]; then MSG_COUNT="${count} plugins"
else MSG_COUNT="${count} do core · ${CAT_COUNT} no catálogo"; fi
echo "Onion: marketplace '${MKT_NAME}' materializado em ${TARGET} (${MSG_COUNT})."

# I3: comita NO alvo (escritor único = o repo do maestro), NUNCA push.
if [ "${DO_COMMIT}" -eq 1 ]; then
  git -C "${TARGET}" rev-parse --git-dir >/dev/null 2>&1 || git -C "${TARGET}" init -q
  git -C "${TARGET}" add -A
  if git -C "${TARGET}" diff --cached --quiet 2>/dev/null; then
    echo "  (nada a commitar — já atualizado)"
  else
    git -C "${TARGET}" commit -q --no-verify -m "chore(marketplace): materializa ${MKT_NAME} (${MSG_COUNT}) do source Onion" \
      && echo "  ✓ commit no alvo (SEM push — I3: o push é human-gated)."
  fi
fi
