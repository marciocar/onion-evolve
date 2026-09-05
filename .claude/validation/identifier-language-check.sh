#!/usr/bin/env bash
# identifier-language-check.sh — identificador de código em INGLÊS (code-standards.md §1).
#
# POR QUE EXISTE (dano medido, 2026-08-09): o revisor de CI apontou identificador em pt-BR em SEIS
# PRs de uma única sessão (#559, #562, #563, #565, #566 e um rename interno). Não havia guarda
# mecânica — era disciplina, e esta casa já mediu que o gatilho eficaz de correção é SOCIAL, logo
# "vou prestar mais atenção" é cura nula. [[fix-must-become-mechanism]]
#
# COMO JULGA — e cada escolha tem número ao lado, medido no PR #568 antes de escrever uma linha:
#   · por SEGMENTO, não por palavra inteira. Casando identificador inteiro, só 3 de 636 casavam:
#     cobertura baixa demais, porque os achados reais eram COMPOSTOS (`semAspas`, `_lib_ao_lado`,
#     `_dep_faltando`). Split por `_` e por fronteira camelCase pega 10 dos 12 históricos.
#   · contra lista SEM HOMÓGRAFO (lib/pt-br-words.txt). Zero falsos nos substitutos em inglês
#     (`unquoted`, `_lib_beside`, `_missing_deps`, `dirty_before`).
#   · com BASELINE. O repo tem 3 residuais anteriores à sessão; dívida existente é SOFT e
#     ocorrência NOVA é HARD, como a REGRA 49 e a REGRA 45. Nascer HARD sobre dívida velha é como
#     se ensina a desligar um gate.
#
# ⚠️ SÓ IDENTIFICADOR, NUNCA COMENTÁRIO NEM STRING. A doutrina da casa é explícita: código em
# inglês, PROSA EM pt-BR. Uma guarda que acusasse comentário estaria cobrando o oposto do padrão —
# e a varredura que fiz à mão no PR #565 já errou assim, acusando 48 "sobras" que eram todas
# comentário. Grep que não distingue código de comentário produz falso-positivo tão grande que
# esconde o verdadeiro.
#
# Exit: 0 = ok · 1 = violação · 2 = erro de uso/arquivo.
# Determinístico. Exercitado por lint-selftest.sh (run_identifier_language_selftests).
set -uo pipefail

FORMAT=human
_root=""
for a in "$@"; do
  case "$a" in
    --format=tsv|tsv) FORMAT=tsv ;;
    --format)         : ;;
    --emit-baseline)  FORMAT=emit ;;
    -*)               : ;;
    *)                [ -z "${_root}" ] && _root="$a" ;;
  esac
done
# ⚠️ A LIB SE RESOLVE ANTES DO `cd`, e a ordem inversa era um bug MEDIDO nos tres adotantes reais
# desta maquina: `BASH_SOURCE[0]` costuma ser RELATIVO (`.claude/validation/...`), entao resolve-lo
# DEPOIS de `cd "${REPO_ROOT}"` faz o caminho apontar para o repo JULGADO, e nao para onde o script
# vive. Rodando o script do core contra TRES repos adotantes reais desta maquina, os tres davam
# `exit 2 — lib AUSENTE`: a guarda morria antes de julgar, em 3 de 3.
# Achado pelo dogfood que a doutrina desta casa chama de padrao master, e que eu nao tinha feito.
WORDS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/pt-br-words.txt"

REPO_ROOT="$(cd "${_root:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'identifier-language: repo_root inválido: %s\n' "${_root}" >&2; exit 2; }
cd "${REPO_ROOT}"
# FAIL-LOUD: lista ausente jamais vira "nenhuma violação" (P0 da REGRA 30).
[ -f "${WORDS}" ] || { printf 'identifier-language: lib/pt-br-words.txt AUSENTE (%s) — sem a lista nao ha o que cobrar, e "nao sei" nunca vira "ok".\n' "${WORDS}" >&2; exit 2; }
BASELINE="${REPO_ROOT}/.claude/validation/identifier-language-baseline.txt"

# ── extração: identificadores DECLARADOS, ignorando comentário ────────────────────────────────
# `local x=` · `x=` no início da linha · `function nome` · `nome() {`
# ⚠️ A ORDEM E O QUE FAZ A GUARDA SERVIR, e a 1a versao a errou nas DUAS pontas. Passada
# adversarial mediu os dois danos, e o pior estava no artefato que EU entreguei:
#   · CORTAR COMENTARIO ANTES DE ELIDIR ASPAS lia `chave=` DENTRO de string como declaracao.
#     Prova: 2 das 7 "dividas" do baseline que eu gerei NAO ERAM IDENTIFICADORES — eram prosa
#     pt-BR em mensagem, nascidas carimbadas como divida. E um script com identificadores 100%
#     INGLES e mensagens em pt-BR (exatamente o que a doutrina MANDA) levava 5 HARD.
#   · E `sed 's/#.*//'` DECAPITAVA a linha em `$#`, `${v#pfx}` e `"#fff"` — o idioma de
#     arg-parsing do proprio repo, em 27 arquivos. Declaracao pt-BR REAL depois disso ficava
#     invisivel: fail-open medido em 3 declaracoes.
# A ordem certa: elide o CORPO das aspas primeiro (vira vazio), e so entao corta `#`, e apenas
# quando ele INICIA token — nunca colado a `$` nem dentro de `${...}`.
_elide() {
  sed -E 's/"[^"]*"/""/g; s/'"'"'[^'"'"']*'"'"'/'"'"''"'"'/g' "$1" 2>/dev/null \
    | sed -E 's/(^|[[:space:]])#.*$/\1/'
}
_ids() {
  local f="$1"
  _elide "$f" | grep -oE '(^|[[:space:]])(local[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*=' \
    | sed 's/^[[:space:]]*//; s/^local[[:space:]]*//; s/=$//'
  _elide "$f" | grep -oE '(^|[[:space:]])function[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*' | sed 's/.*function[[:space:]]*//'
  _elide "$f" | grep -oE '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' | sed 's/()$//'
}

WORDLIST="$(grep -v '^[[:space:]]*\(#\|$\)' "${WORDS}" | tr '\n' '|' | sed 's/|$//')"
[ -n "${WORDLIST}" ] || { printf 'identifier-language: lista VAZIA — a guarda mediria o nada.\n' >&2; exit 2; }

# ── UNIVERSO: rastreado UNIAO nao-rastreado, e VAZIO nunca vira "ok" ─────────────────────────
# Duas fugas medidas por passada adversarial, e a segunda e a pior:
#   · `git ls-files` sozinho NAO VE arquivo untracked — e "ocorrencia NOVA e HARD" e justamente o
#     contrato desta regra. Codigo novo esta untracked no instante exato em que se roda o lint:
#     medido, o MESMO arquivo passava rc=0 antes do `git add` e reprovava depois.
#   · e universo VAZIO imprimia `✅ nenhum identificador NOVO em pt-BR`, rc=0. O caso mais afiado e
#     o adotante recem-adotado: `/meta:adopt` instala `.claude/` SEM commitar, entao 51 scripts no
#     disco, 0 rastreados, e a guarda nascia MUDA no dia 1 EXIBINDO APROVACAO. E a mesma classe que
#     a linha da lista ausente ja trata certo (exit 2) e que aqui foi esquecida.
_universe() {
  { git ls-files '.claude/**/*.sh' '.claude/*.sh' 2>/dev/null || true
    find .claude -name '*.sh' -type f 2>/dev/null || true
    # ⚠️ FILTRO PRÓPRIO, por decisão declarada (2026-09-05): o predicado único de isenção de fixture
    #    (em `.claude/validation/`, o que os consumidores de grafo usam) NÃO é usado aqui — e esta nota
    #    evita citar o nome dele de propósito, porque a guarda deriva os consumidores por menção.
    #    O escopo desta varredura é `.claude/**/*.sh` — não
    #    há `.kg.yaml` nem convenção `__fixtures__` neste universo, então o ganho é zero; e ligar o
    #    predicado quebrou 4 casos da família `idioma`, cujo sandbox copia este checker sem ele.
    #    Dívida registrada com gatilho: se aparecer fixture de shell em convenção não-canônica
    #    (`__fixtures__/`, `testdata/`) sob `.claude/`, ligue o predicado E espelhe-o no sandbox.
  } | sed 's#^\./##' | grep -v '/fixtures/' | sort -u
}

TMP="$(mktemp)"; trap 'rm -f "${TMP}"' EXIT
_UNI="$(_universe | grep -c . || true)"
if [ "${_UNI:-0}" -eq 0 ]; then
  printf 'identifier-language: universo VAZIO — nenhum .sh sob .claude/. Repo sem git, fora do checkout, ou .claude/ ainda nao instalado. "Nao sei" NUNCA vira "ok".\n' >&2
  exit 2
fi
while IFS= read -r f; do
  [ -f "${f}" ] || continue
  _ids "${f}" | sort -u | awk -v W="${WORDLIST}" -v F="${f}" '
    BEGIN { n = split(W, w, "|"); for (i = 1; i <= n; i++) dic[w[i]] = 1 }
    {
      id = $0
      # split por `_` e por fronteira camelCase (minuscula/digito seguida de MAIUSCULA)
      # ⚠️ SPLIT camelCase A MAO: awk POSIX NAO tem backreference em `gsub`, entao
      # `gsub(/([a-z0-9])([A-Z])/, "\\1_\\2")` nao faz nada — o camelCase ficava INTEIRO e so o `_`
      # separava. `semAspas` (a forma EXATA dos achados reais) escapava. O caso (c) da bancada existe
      # para isto e foi ele que pegou; sem ele a guarda nasceria cobrindo metade do que promete.
      s = ""
      for (k = 1; k <= length(id); k++) {
        c = substr(id, k, 1); pc = (k > 1 ? substr(id, k-1, 1) : "")
        if (c ~ /[A-Z]/ && pc ~ /[a-z0-9]/) s = s "_"
        s = s c
      }
      gsub(/[^A-Za-z0-9_]/, "_", s)
      m = split(tolower(s), seg, "_")
      for (i = 1; i <= m; i++) if (seg[i] != "" && (seg[i] in dic)) { print F "\t" id "\t" seg[i]; break }
    }'
done < <(_universe) | sort -u > "${TMP}"

if [ "${FORMAT}" = emit ]; then
  printf '# Baseline da REGRA 60 — identificadores em pt-BR TOLERADOS (divida anterior a 2026-08-09).\n'
  printf '# Gerado por: bash .claude/validation/identifier-language-check.sh --emit-baseline\n'
  printf '# Esta lista SO PODE ENCOLHER. Acrescentar entrada aqui e REGRESSAO.\n'
  cut -f1,2 "${TMP}" | sort -u
  exit 0
fi

KNOWN=""
[ -f "${BASELINE}" ] && KNOWN="$(grep -v '^[[:space:]]*\(#\|$\)' "${BASELINE}" | sort -u)"

HARD=0; SOFT=0
while IFS=$'\t' read -r f id seg; do
  [ -n "${id}" ] || continue
  if printf '%s\n' "${KNOWN}" | grep -qxF "${f}	${id}"; then
    SOFT=$((SOFT + 1))
    [ "${FORMAT}" = tsv ] || printf '  ⊘ tolerado pelo baseline: %s (%s) em %s\n' "${id}" "${seg}" "${f}"
  else
    HARD=$((HARD + 1))
    if [ "${FORMAT}" = tsv ]; then
      printf 'HARD\tIDIOMA-DE-IDENTIFICADOR\t%s\tidentificador `%s` tem segmento pt-BR `%s` — code-standards.md manda CODIGO em ingles (prosa e comentario seguem em pt-BR)\n' "${f}" "${id}" "${seg}"
    else
      printf '  ✗ IDIOMA: `%s` (segmento `%s`) em %s\n' "${id}" "${seg}" "${f}"
    fi
  fi
done < "${TMP}"

if [ "${FORMAT}" != tsv ]; then
  printf '  identificadores acusados: %s HARD · %s tolerados pelo baseline\n' "${HARD}" "${SOFT}"
  [ "${HARD}" -eq 0 ] && printf '  ✅ nenhum identificador NOVO em pt-BR\n'
fi
[ "${HARD}" -eq 0 ] && exit 0 || exit 1
