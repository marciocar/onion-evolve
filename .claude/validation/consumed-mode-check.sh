#!/usr/bin/env bash
# consumed-mode-check.sh — o MODO que a produção consome é o modo que o teste exercita?
#
# ═══ POR QUE EXISTE (dano medido em 2026-08-06, e o defeito era meu) ═══
# Construí a guarda de vacuidade do `kg-trace-resolve.sh` e a apresentei como a cura do fail-open.
# Ela estava DEPOIS do `exit` do ramo TSV — e TSV é exatamente o modo que o lint invoca. Medido com
# o mesmo mutante: modo humano `exit 1` com ✗ VACUIDADE; modo TSV `exit 0`, saída vazia, REGRA 55
# VERDE com o parser morto. E o mutation test que eu escrevi para prová-la exercitava o modo HUMANO
# — validava a superfície que ninguém usa em CI.
#
# GUARDA-DA-GUARDA QUE TESTA O MODO ERRADO NÃO É GUARDA. Esta regra é a generalização mecânica.
#
# ═══ JOIN OBSERVADO, NUNCA INFERIDO — e é essa a diferença que a torna possível ═══
# A primeira tentativa do gate "regra sem teste" morreu porque casava por NOME DE FUNÇÃO: heurística,
# 8 falsos positivos (docs/analysis/onion-guardas-mapa-2026-08.md:277-280). Aqui não há inferência:
# lê-se a INVOCAÇÃO REAL dos dois lados — `bash "${helper}" … --flags` na produção e no selftest — e
# compara-se o conjunto de flags. Se a produção consome uma combinação que o teste nunca exercita,
# existe um caminho vivo sem cobertura. É fato observável, não julgamento.
#
# TETO DECLARADO: cobre invocação por variável resolvida no MESMO escopo (`local h="${SCRIPT_DIR}/x.sh"`
# … `bash "${h}" --flag`), que é a forma canônica desta casa. Invocação montada dinamicamente (flag
# vinda de variável, `eval`, array) NÃO é julgada — e é CONTADA, nunca silenciosa.
#
# ═══ ESTE SCRIPT É INSTRUMENTO, NÃO GATE — e a decisão foi MEDIDA, não temida ═══
# Ele NÃO está ligado ao lint como REGRA HARD, e não deve ser sem o trabalho descrito abaixo.
# Tentei ligá-lo em 2026-08-06 e a medição não convergiu: a extração encontrou SEIS formas de
# invocação, cada iteração revelando a seguinte —
#   1. `bash "${SCRIPT_DIR}/x.sh" --flag`            (produção)
#   2. `local h="${REPO_ROOT}/.claude/validation/x.sh"` + `bash "${h}" --flag`   (selftest)
#   3. invocação quebrada em várias linhas com `\`
#   4. `bash .claude/validation/x.sh` sem aspas
#   5. linha de COMENTÁRIO mostrando uso no cabeçalho
#   6. o comando dentro de uma MENSAGEM DE VIOLAÇÃO ("detalhe: bash .claude/validation/x.sh")
# A 6ª não é separável de uma invocação real por regex — distingui-la exigiria parser de shell.
# Ligar assim significaria HARD com falso-positivo, que nesta casa é TRAVAMENTO, não ruído; e foi
# exatamente por 8 falsos positivos que a heurística do gate 6a morreu
# (docs/analysis/onion-guardas-mapa-2026-08.md:277-280). Prometer cobertura que a extração não
# sustenta seria a classe C — a manchete afirmando mais que a evidência — aplicada ao remédio.
#
# ELE JÁ SE PAGOU MESMO ASSIM, e é por isso que fica: na 1ª execução real pegou um defeito MEU,
# em código escrito na mesma hora — o selftest da REGRA 56 exercitava o modo HUMANO enquanto
# `check_review_artifact` consome `--format=tsv`. O defeito IDÊNTICO ao que eu curara de manhã no
# kg-trace-resolve. Nenhuma releitura minha o pegou; este join pegou.
#
# LACUNAS REAIS QUE ELE ACHOU e que seguem abertas (verificadas à mão, não são artefato):
#   · inventory.sh          — a produção consome `--markdown`; o selftest NUNCA o invoca
#   · migalhas-generate.sh  — a produção consome `--check`; o selftest NUNCA o invoca
#
# O QUE FALTA para virar REGRA: (a) distinguir invocação de menção-em-string (parser, não regex);
# (b) triar o resíduo caso a caso; (c) só então wire-in HARD. É ciclo próprio, não puxado ainda.
#
# Uso  : bash .claude/validation/consumed-mode-check.sh [<repo_root>] [--format tsv|--list]
# Exit : 0 = todo modo consumido é exercitado · 1 = há modo sem teste · 2 = uso inválido
set -euo pipefail

REPO_ROOT="$(cd "${1:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'consumed-mode-check: repo_root inválido\n' >&2; exit 2; }
FORMAT=human
for a in "$@"; do case "$a" in tsv|--format=tsv) FORMAT=tsv ;; --list) FORMAT=list ;; esac; done
cd "${REPO_ROOT}"

PROD="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
TEST="${REPO_ROOT}/.claude/validation/lint-selftest.sh"
for f in "${PROD}" "${TEST}"; do
  [ -r "${f}" ] || { printf 'consumed-mode-check: ilegível: %s\n' "${f}" >&2; exit 2; }
done

# Extrai pares `script<TAB>flags-ordenadas` das invocações reais.
# `dyn` conta o que NÃO foi julgado (flag vinda de variável) — supressão contada, nunca silenciosa.
_pairs() {
  # JUNTA CONTINUAÇÃO DE LINHA antes de extrair. Sem isto, `bash x.sh "$repo" \` numa linha e
  # `--format tsv` na seguinte perdia TODAS as flags — falso-positivo medido em doctrine-freshness.
  # PULA COMENTÁRIO — 5ª forma achada por medição. Cabeçalho de script mostra USO
  # (`# bash .claude/validation/kg-radar.sh <arquivo>`) e isso NÃO é invocação. Sem o corte, a
  # documentação do próprio script vira acusação — o mesmo modo de falha do heredoc na guarda do shell.
  sed -e ':a' -e '/\\$/{N; s/\\\n[[:space:]]*/ /; ba}' "$1" | grep -v '^[[:space:]]*#' | awk '
    # var = caminho de script sob SCRIPT_DIR (o idioma da casa)
    # VAR = caminho de script. Aceita as DUAS raízes que esta casa usa — ${SCRIPT_DIR}/x.sh (produção)
    # e ${REPO_ROOT}/.claude/validation/x.sh (selftest). Cobrir só a primeira sub-extraía o lado do
    # teste e fabricava 8 falsos em 19, MEDIDO — o mesmo modo de falha que matou a heurística do 6a.
    /[A-Za-z_]+="\$\{(SCRIPT_DIR|REPO_ROOT)\}[A-Za-z0-9._\/-]*\/[A-Za-z0-9._-]+\.sh"/ {
      line = $0
      match(line, /[A-Za-z_]+="\$\{(SCRIPT_DIR|REPO_ROOT)\}/)
      v = substr(line, RSTART, RLENGTH); sub(/=".*$/, "", v)
      match(line, /\/[A-Za-z0-9._-]+\.sh"/)
      p = substr(line, RSTART+1, RLENGTH-2)
      var[v] = p
      next
    }
    # invocação SEM ASPAS: bash .claude/validation/nome.sh … flags (4ª forma achada por MEDIÇÃO —
    # cada forma não coberta vira falso-positivo, e falso-positivo em regra HARD é travamento)
    /bash[[:space:]]+[^"|;]*\/[A-Za-z0-9._-]+\.sh([[:space:]]|$)/ && !/bash[[:space:]]+"/ {
      line = $0
      match(line, /[^[:space:]"]*\/[A-Za-z0-9._-]+\.sh/)
      nm = substr(line, RSTART, RLENGTH); sub(/^.*\//, "", nm)
      rest = substr(line, RSTART+RLENGTH)
      _emit(nm, rest)
      next
    }
    # invocação DIRETA por caminho: bash "${QUALQUER}/.../validation/nome.sh" … flags
    # (o selftest usa ${REPO_ROOT}/.claude/validation/x.sh; a produção usa ${SCRIPT_DIR}/x.sh —
    #  cobrir só uma das formas sub-extraía um dos lados e fabricava 9 falsos em 17, MEDIDO)
    /bash[[:space:]]+"[^"]*\/[A-Za-z0-9._-]+\.sh"/ {
      line = $0
      match(line, /"[^"]*\/[A-Za-z0-9._-]+\.sh"/)
      full = substr(line, RSTART+1, RLENGTH-2)
      nm = full; sub(/^.*\//, "", nm)
      rest = substr(line, RSTART+RLENGTH)
      _emit(nm, rest)
      next
    }
    # invocação INDIRETA: bash "${VAR}" … flags, com VAR resolvido acima
    /bash[[:space:]]+"\$\{[A-Za-z_]+\}"/ {
      line = $0
      match(line, /\$\{[A-Za-z_]+\}/)
      v = substr(line, RSTART+2, RLENGTH-3)
      if (!(v in var)) next
      rest = substr(line, RSTART+RLENGTH)
      _emit(var[v], rest)
      next
    }
    function _emit(nm, rest,   n, tok, i, t, nxt, flags) {
      gsub(/=/, " ", rest)
      n = split(rest, tok, /[[:space:]]+/)
      flags = ""
      for (i = 1; i <= n; i++) {
        t = tok[i]; gsub(/["'"'"']/, "", t)
        if (t ~ /^--[a-z-]+$/) {
          nxt = (i < n) ? tok[i+1] : ""
          gsub(/["'"'"']/, "", nxt)
          if (nxt ~ /^[a-z]+$/ && nxt !~ /^--/) { t = t " " nxt; i++ }
          flags = flags (flags == "" ? "" : " ") t
        } else if (t ~ /\$\{[A-Za-z_]+\}/ && t !~ /SCRIPT_DIR|REPO_ROOT|helper|repo|d\b/) {
          dyn++
        }
      }
      if (flags == "") flags = "(sem-flag)"
      print nm "\t" flags
    }
    END { if (dyn > 0) print "#DYN\t" dyn }
  '
}

_pairs "${PROD}" | sort -u > "${TMPDIR:-/tmp}/.cmc-prod.$$"
_pairs "${TEST}" | sort -u > "${TMPDIR:-/tmp}/.cmc-test.$$"
trap 'rm -f "${TMPDIR:-/tmp}/.cmc-prod.$$" "${TMPDIR:-/tmp}/.cmc-test.$$"' EXIT

DYN="$(grep -c '^#DYN' "${TMPDIR:-/tmp}/.cmc-prod.$$" || true)"
grep -v '^#DYN' "${TMPDIR:-/tmp}/.cmc-prod.$$" > "${TMPDIR:-/tmp}/.cmc-prod.$$.c" || true
grep -v '^#DYN' "${TMPDIR:-/tmp}/.cmc-test.$$" > "${TMPDIR:-/tmp}/.cmc-test.$$.c" || true
mv "${TMPDIR:-/tmp}/.cmc-prod.$$.c" "${TMPDIR:-/tmp}/.cmc-prod.$$"
mv "${TMPDIR:-/tmp}/.cmc-test.$$.c" "${TMPDIR:-/tmp}/.cmc-test.$$"

PRODN="$(wc -l < "${TMPDIR:-/tmp}/.cmc-prod.$$")"

if [ "${FORMAT}" = list ]; then
  printf '── PRODUÇÃO (%s pares) ──\n' "${PRODN}"; cat "${TMPDIR:-/tmp}/.cmc-prod.$$"
  printf '── TESTE (%s pares) ──\n' "$(wc -l < "${TMPDIR:-/tmp}/.cmc-test.$$")"; cat "${TMPDIR:-/tmp}/.cmc-test.$$"
  exit 0
fi

# GUARDA DE VACUIDADE — zero par extraído da produção não é "tudo coberto", é o parser morto.
# Mesma lição do kg-trace-resolve.sh: uma guarda que não lê nada e diz OK é pior que guarda nenhuma.
if [ "${PRODN}" -eq 0 ]; then
  if grep -q 'SCRIPT_DIR}/[A-Za-z0-9._-]*\.sh' "${PROD}"; then
    if [ "${FORMAT}" = tsv ]; then printf 'HARD\tVACUIDADE\t.claude/validation/consumed-mode-check.sh\thá invocação de helper na produção e o parser não extraiu NADA — a guarda está cega\n'
    else printf '  ✗ VACUIDADE: há invocação de helper na produção e nada foi extraído — o parser morreu.\n'; fi
    exit 1
  fi
fi

# Uma invocação do teste COBRE o par de produção quando é do mesmo script e suas flags contêm
# todas as da produção.
_covered() {
  local scr="${1%%	*}" flg="${1#*	}"
  local tscr tflg f ok
  # DELEGAÇÃO CONTA COMO COBERTURA, e é isenção declarada: quando o selftest invoca `--selftest`, ele
  # está delegando ao teste EMBUTIDO do próprio script. Não dá para saber daqui se aquele teste cobre
  # o modo TSV — e acusar mesmo assim seria julgar o que não se mediu, o erro que esta regra existe
  # para pegar. TETO: se o `--selftest` de um script não cobrir seu modo de produção, esta regra cala.
  if grep -qF "${scr}	--selftest" "${TMPDIR:-/tmp}/.cmc-test.$$" 2>/dev/null; then
    DELEG=$((DELEG + 1)); return 0
  fi
  while IFS= read -r t; do
    [ -n "${t}" ] || continue
    tscr="${t%%	*}"; tflg="${t#*	}"
    [ "${tscr}" = "${scr}" ] || continue
    ok=1
    for f in ${flg}; do
      case " ${tflg} " in *" ${f} "*) : ;; *) ok=0; break ;; esac
    done
    [ "${ok}" = "1" ] && return 0
  done < "${TMPDIR:-/tmp}/.cmc-test.$$"
  return 1
}

MISS=0; DELEG=0
while IFS= read -r pair; do
  [ -n "${pair}" ] || continue
  # SUBCONJUNTO, não igualdade — e a diferença foi MEDIDA, não suposta. Com igualdade, a produção
  # `projection-safety.sh --format tsv` era acusada porque o selftest a invoca como
  # `--federation --format tsv`: o caminho TSV É exercitado, só com uma flag a mais. Igualdade dava
  # 10 acusados em 17 (59%) e quase todos falsos — a mesma taxa que matou a heurística do gate 6a.
  # A pergunta certa não é "existe invocação idêntica?", é "o modo que a produção consome é
  # ALCANÇADO por alguma invocação do teste?".
  if ! _covered "${pair}"; then
    MISS=$((MISS + 1))
    scr="${pair%%	*}"; flg="${pair#*	}"
    if [ "${FORMAT}" = tsv ]; then
      printf 'HARD\tMODO-SEM-TESTE\t.claude/validation/%s\ta produção invoca com [%s] e o selftest nunca exercita ESSA combinação — o caminho vivo está sem cobertura (foi assim que a guarda de vacuidade ficou verde com o parser morto, 2026-08-06)\n' "${scr}" "${flg}"
    else
      printf '  ✗ MODO-SEM-TESTE: %s [%s]\n    a produção consome esta combinação; o selftest não a exercita\n' "${scr}" "${flg}"
    fi
  fi
done < "${TMPDIR:-/tmp}/.cmc-prod.$$"

if [ "${FORMAT}" != tsv ]; then
  printf '  pares de produção: %s · sem teste: %s\n' "${PRODN}" "${MISS}"
  printf '  fora de julgamento (contado, nunca silencioso): %s flag dinâmica · %s cobertos por delegação (--selftest)\n' "${DYN}" "${DELEG}"
  [ "${MISS}" -eq 0 ] && printf '  ✅ todo modo consumido é exercitado pelo selftest\n'
fi
[ "${MISS}" -eq 0 ] && exit 0 || exit 1
