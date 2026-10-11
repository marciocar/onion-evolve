#!/usr/bin/env bash
# =============================================================================
# emit-eol-gitattributes.sh — leva o `eol=lf` dos executáveis à raiz de quem recebe o Onion.
#
# POR QUÊ : o core fixou `text eol=lf` no próprio .gitattributes (SAC-107, rodada r9 do radar E3,
#           2026-10-11): num checkout Windows com core.autocrlf=true, os .sh saíam com CRLF e o bash
#           dos hooks quebrava com o retorno de carro. Mas o .gitattributes do core NÃO viaja — o
#           manifesto cobre só .claude/ e docs/, e a raiz da porta levava README, CLAUDE.md, LICENSE e
#           LICENSE-DOCS. Quem mais precisava da cura (o adotante e a porta pública, clonados em
#           qualquer máquina) era exatamente quem não a recebia.
#
# MODOS   : --door   a raiz da porta é PROJEÇÃO: o arquivo é (re)escrito inteiro a cada materialização.
#           --adopt  a raiz do adotante é DELE: never-clobber. Três desfechos, todos declarados:
#                    (1) sem .gitattributes → cria com o bloco;
#                    (2) .gitattributes que já governa EOL (text/eol/crlf/binary num padrão NOSSO, em
#                        `*` ou em `**`; `[attr]` e padrão alheio não contam) → NÃO toca e diz a linha;
#                    (3) .gitattributes sem governo de EOL (ex.: só as linhas merge=union do adopt) →
#                        acrescenta só os padrões ausentes (idempotente).
#
# SUBCONJUNTO MEDIDO, não lista cega: só entra o padrão que CASA arquivo no destino (a porta não leva
# .githooks/, então não ganha a linha). E no adotante, padrão que casa arquivo com CRLF NO ÍNDICE (ou
# rastreado como binário, i/-text) fica de fora e é nomeado: acrescentar `eol=lf` ali mudaria bytes
# rastreados dele (renormalize pendente aparecendo como modificação fantasma) — a mesma régua do core, que mediu ZERO bytes mudando antes de
# fixar. Fora de propósito: *.md, *.yaml, *.json (o core os fixa, mas a cura aqui é dos EXECUTÁVEIS).
#
# PARIDADE: os padrões abaixo são subconjunto das linhas `text eol=lf` do .gitattributes do core; a
#           família eol_gitattributes da bancada reprova se um deles sair de lá.
#
# USO     : emit-eol-gitattributes.sh <DEST> --door|--adopt   → rc 0 (imprime o que fez); 2 = uso
# =============================================================================
set -uo pipefail
DEST="${1:-}"; MODE="${2:-}"
[ -n "${DEST}" ] && [ -d "${DEST}" ] || { echo "uso: emit-eol-gitattributes.sh <DEST> --door|--adopt" >&2; exit 2; }
case "${MODE}" in --door|--adopt) : ;; *) echo "uso: emit-eol-gitattributes.sh <DEST> --door|--adopt" >&2; exit 2 ;; esac
GA="${DEST}/.gitattributes"
PATTERNS=('*.sh' '*.awk' '*.py' '*.js' '*.mjs' '*.ts' '.githooks/*')
MARK='# EOL fixado em LF nos executáveis (Onion, SAC-107): checkout Windows com autocrlf quebraria o bash.'

_present() {   # $1 = padrão → 0 se casa ao menos um arquivo do destino (fora de .git/)
  local p="$1" hit=""
  if [ "${p}" = ".githooks/*" ]; then
    [ -d "${DEST}/.githooks" ] && hit="$(find "${DEST}/.githooks" -maxdepth 1 -type f -print -quit 2>/dev/null)"
  else
    hit="$(find "${DEST}" -path "${DEST}/.git" -prune -o -type f -name "${p}" -print -quit 2>/dev/null)"
  fi
  [ -n "${hit}" ]
}

_crlf_in_index() {   # $1 = padrão → 0 se algum arquivo rastreado que casa vive com CRLF no índice
  git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1 || return 1
  #   `:(glob)` porque o pathspec cru casa RECURSIVO (`.githooks/*` pegaria `.githooks/sub/x`), e a linha
  #   do .gitattributes não. E `i/-text` também barra: é arquivo rastreado que o git trata como BINÁRIO
  #   (um vídeo MPEG-TS em `*.ts`); `text eol=lf` sobre ele tiraria os bytes CR na próxima renormalização.
  #   Padrão SEM barra casa em qualquer profundidade (como no .gitattributes); com barra, ancorado na raiz.
  local -a ps=(":(glob)$1"); case "$1" in */*) : ;; *) ps+=(":(glob)**/$1") ;; esac
  git -C "${DEST}" ls-files --eol -- "${ps[@]}" 2>/dev/null \
    | awk '$1=="i/crlf" || $1=="i/mixed" || $1=="i/-text" {f=1} END {exit !f}'
}

_ours() {   # $1 = linha → 0 se é uma linha que ESTE helper escreve
  local l="$1" p
  for p in "${PATTERNS[@]}"; do [ "${l}" = "${p} text eol=lf" ] && return 0; done
  return 1
}

present=(); for p in "${PATTERNS[@]}"; do _present "${p}" && present+=("${p}"); done

if [ "${MODE}" = "--door" ]; then
  if [ "${#present[@]}" -eq 0 ]; then
    rm -f "${GA}"; echo ".gitattributes: nenhum executável na porta — arquivo não escrito"; exit 0
  fi
  { echo "${MARK}"; echo "# Gerado na materialização da porta (projeção do core): não edite aqui."
    for p in "${present[@]}"; do echo "${p} text eol=lf"; done; } > "${GA}"
  echo ".gitattributes: eol=lf em ${#present[@]} padrão(ões): ${present[*]}"
  exit 0
fi

# --adopt ───────────────────────────────────────────────────────────────────────────────────────
if [ -f "${GA}" ]; then
  gov="$(awk -v pats="$(printf '%s\n' "${PATTERNS[@]}")" '
    BEGIN { n = split(pats, P, "\n"); for (i = 1; i <= n; i++) ours[P[i]] = 1 }
    { sub(/\r$/, "") }
    /^[[:space:]]*(#|$)/ { next }
    /^[[:space:]]*\[attr\]/ { next }   # definição de macro não governa arquivo nenhum
    { pat = $1; line = $0; sub(/^[[:space:]]+/, "", line); sub(/[[:space:]]+$/, "", line)
      if ((pat in ours) && line == pat " text eol=lf") next
      # só governa o NOSSO padrão quem fala dele ou de tudo (`*`, `**`): `*.png -text` não diz nada sobre .sh
      if (!((pat in ours) || pat == "*" || pat == "**")) next
      for (i = 2; i <= NF; i++) {
        a = $i
        if (a ~ /^[-!]?text(=.*)?$/ || a ~ /^eol=/ || a ~ /^[-!]?crlf$/ || a == "binary") {
          print NR ": " line; exit
        }
      }
    }' "${GA}")"
  if [ -n "${gov}" ]; then
    echo ".gitattributes: NÃO APLICADO (never-clobber) — o .gitattributes do alvo já governa EOL (linha ${gov}). Avalie à mão: ${PATTERNS[*]} com text eol=lf."
    exit 0
  fi
fi

add=(); skipped=()
for p in "${present[@]}"; do
  # comparação APARADA (espaços nas pontas e CR), a mesma do awk acima — senão a linha do adotante com
  # CRLF ou recuo seria reconhecida como nossa ali e reacrescentada aqui
  if [ -f "${GA}" ] && sed 's/\r$//; s/^[[:space:]]*//; s/[[:space:]]*$//' "${GA}" | grep -xF "${p} text eol=lf" >/dev/null; then continue; fi  # sem -q: sob pipefail o -q fecha o pipe cedo (EPIPE)
  if _crlf_in_index "${p}"; then skipped+=("${p}"); continue; fi
  add+=("${p}")
done
if [ "${#add[@]}" -gt 0 ]; then
  {
    [ -s "${GA}" ] && [ -n "$(tail -c1 "${GA}")" ] && echo
    grep -qxF "${MARK}" "${GA}" 2>/dev/null || echo "${MARK}"
    for p in "${add[@]}"; do echo "${p} text eol=lf"; done
  } >> "${GA}"
  echo ".gitattributes: eol=lf acrescentado em ${#add[@]} padrão(ões): ${add[*]}"
else
  echo ".gitattributes: eol=lf já presente (ou nada a cobrir) — nada a fazer"
fi
if [ "${#skipped[@]}" -gt 0 ]; then
  echo "⚠️  .gitattributes: padrão(ões) FORA porque casam arquivo com CRLF no índice do alvo (eol=lf mudaria bytes rastreados): ${skipped[*]}"
  echo "   Se quiser normalizar: acrescente a linha e rode git add --renormalize . num commit próprio."
fi
exit 0
