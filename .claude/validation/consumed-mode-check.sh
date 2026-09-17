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
# 8 falsos positivos (`onion-guardas-mapa-2026-08` (core-only):277-280). Aqui não há inferência:
# lê-se a INVOCAÇÃO REAL dos dois lados — `bash "${helper}" … --flags` na produção e no selftest — e
# compara-se o conjunto de flags. Se a produção consome uma combinação que o teste nunca exercita,
# existe um caminho vivo sem cobertura. É fato observável, não julgamento.
#
# TETO DECLARADO: cobre invocação por variável resolvida no MESMO escopo (`local h="${SCRIPT_DIR}/x.sh"`
# … `bash "${h}" --flag`), que é a forma canônica desta casa. Invocação montada dinamicamente (flag
# vinda de variável, `eval`, array) NÃO é julgada — e é CONTADA, nunca silenciosa.
#
# ═══ HISTÓRICO DO WIRE-IN — e a ironia de este cabeçalho ter ficado stale ═══
# ⚠️ ATUALIZADO 2026-08-13: este script ESTÁ ligado ao lint — a REGRA 59 [HARD]
# (check_consumed_modes, lint-artifacts.sh) o consome desde que o trabalho descrito abaixo
# convergiu. A frase anterior ("NÃO está ligado como REGRA HARD, e não deve ser") era verdadeira
# quando escrita e ficou stale QUANDO o wire-in aconteceu — ninguém voltou aqui. Um Elenxo de
# 2026-08-13 pegou: o instrumento cuja função é medir `declarado≠consumido` carregava a própria
# autodescrição divergente do consumo real. O parágrafo original fica abaixo como registro da
# decisão da época, não como estado atual.
# ═══ (registro histórico, 2026-08-06) INSTRUMENTO, NÃO GATE — a decisão foi MEDIDA ═══
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
# (`onion-guardas-mapa-2026-08` (core-only):277-280). Prometer cobertura que a extração não
# sustenta seria a classe C — a manchete afirmando mais que a evidência — aplicada ao remédio.
#
# ELE JÁ SE PAGOU MESMO ASSIM, e é por isso que fica: na 1ª execução real pegou um defeito MEU,
# em código escrito na mesma hora — o selftest da REGRA 56 exercitava o modo HUMANO enquanto
# `check_review_artifact` consome `--format=tsv`. O defeito IDÊNTICO ao que eu curara de manhã no
# kg-trace-resolve. Nenhuma releitura minha o pegou; este join pegou.
#
# LACUNAS REAIS QUE ELE ACHOU à época — ⚠️ AMBAS FECHADAS DESDE ENTÃO (Elenxo 2026-08-13:
# lint-selftest.sh:6023 exercita `inventory.sh --markdown`; :6078 exercita
# um --check consumido pela produção; o próprio instrumento devolve `0 sem teste` hoje):
#   · inventory.sh          — a produção consome `--markdown` (era lacuna; coberto)
#   · migalhas-generate.sh  — (HISTÓRICO: aposentado no cutover Astro 2026-08-25; o par sumiu da medição)
#
# O QUE FALTAVA para virar REGRA (registro de 2026-08-06 — ⚠️ o ciclo FOI puxado: a REGRA 59
# [HARD] existe e consome este script, ver o topo deste cabeçalho): (a) distinguir invocação de
# menção-em-string; (b) triar o resíduo; (c) wire-in HARD. Cumprido.
#
# Uso  : bash .claude/validation/consumed-mode-check.sh [<repo_root>] [--format tsv|--list]
# Exit : 0 = todo modo consumido é exercitado · 1 = há modo sem teste · 2 = uso inválido
set -euo pipefail

# ⚠️ AS FLAGS SAIAM DO CAMINHO ANTES DE `$1` VIRAR RAIZ — e a versao anterior nao fazia isso:
# `${1:-...}` engolia QUALQUER flag como caminho, entao `--selftest` (e `--format`) davam
# `cd --selftest` -> "repo_root invalido", exit 2. O script que existe para achar MODO SEM TESTE
# nao conseguia rodar o proprio teste. Agora o posicional e o 1o argumento que NAO comeca com `-`.
FORMAT=human
SELFTEST=0
_root=""
for a in "$@"; do
  case "$a" in
    --selftest)        SELFTEST=1 ;;
    tsv|--format=tsv)  FORMAT=tsv ;;
    --format)          : ;;                      # o valor vem no proximo argumento
    --list)            FORMAT=list ;;
    -*)                : ;;                      # flag desconhecida nao vira caminho
    *)                 [ -z "${_root}" ] && _root="$a" ;;
  esac
done
REPO_ROOT="$(cd "${_root:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'consumed-mode-check: repo_root inválido: %s\n' "${_root}" >&2; exit 2; }
cd "${REPO_ROOT}"

# ── --selftest: o detector prova a si mesmo, contra fixture ────────────────────────────────────
# POR QUE EXISTE: este script acusa "modo consumido sem teste" e ELE PROPRIO nao tinha teste — e nem
# conseguia ter, porque `${1:-...}` engolia a flag como caminho. Ligar ao gate um detector que nunca
# se provou seria ligar uma guarda que ja se sabe cega, que e como esta casa produz falso-verde.
# ORDEM DELIBERADA, escrita no grafo antes de comecar: --selftest -> bloco na bancada -> ENTAO wire-in.
#
# As fixtures sao repos FALSOS em mktemp com os dois lados (producao e bancada) escritos a mao, e o
# script roda de verdade contra eles. Assim o teste exercita o CAMINHO INTEIRO — parse de argumento,
# extracao de pares, diferenca e formatacao — e nao um pedaco reimplementado.
if [ "${SELFTEST:-0}" = "1" ]; then
  _st_pass=0; _st_fail=0
  _st_ok()  { _st_pass=$((_st_pass+1)); printf '  ✓ consumed-mode: %s\n' "$1"; }
  _st_bad() { _st_fail=$((_st_fail+1)); printf '  ✗ consumed-mode: %s — %s\n' "$1" "$2"; }
  _st_repo() { # $1=dir  $2=linha da PRODUCAO  $3=linha da BANCADA
    mkdir -p "$1/.claude/validation"
    printf '#!/usr/bin/env bash\n%s\n' "$2" > "$1/.claude/validation/lint-artifacts.sh"
    printf '#!/usr/bin/env bash\n%s\n' "$3" > "$1/.claude/validation/lint-selftest.sh"
  }
  _st_me="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

  # (a) modo consumido E exercitado -> SILENCIO, exit 0. Sem este caso, (b) provaria o nada:
  #     um detector que acusa SEMPRE tambem "pega" o modo sem teste.
  _d="$(mktemp -d)"
  _st_repo "$_d" 'bash "${SCRIPT_DIR}/alvo.sh" --modo' 'bash "${SCRIPT_DIR}/alvo.sh" --modo'
  _rc=0; _out="$(bash "${_st_me}" "$_d" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 0 ] && ! grep -q 'MODO-SEM-TESTE' <<< "${_out}"; then
    _st_ok '(a) modo consumido E exercitado -> silencio, exit 0'
  else _st_bad '(a)' "acusou modo coberto (rc=${_rc}): ${_out}"; fi
  rm -rf "$_d"

  # (b) o PAR de (a): mesmo alvo, a bancada deixa de exercitar -> ACUSA, exit 1, NOMEANDO script+flag.
  #     Filtro anti-ruido sem o par e como silenciar um alarme e passar no teste.
  _d="$(mktemp -d)"
  _st_repo "$_d" 'bash "${SCRIPT_DIR}/alvo.sh" --modo' 'bash "${SCRIPT_DIR}/outro.sh" --modo'
  _rc=0; _out="$(bash "${_st_me}" "$_d" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 1 ] && grep -q 'MODO-SEM-TESTE' <<< "${_out}" \
     && printf '%s' "${_out}" | grep -q 'alvo.sh' && printf '%s' "${_out}" | grep -q -- '--modo'; then
    _st_ok '(b) modo consumido e NAO exercitado -> acusa, exit 1, nomeando script e flag'
  else _st_bad '(b)' "nao acusou ou nao nomeou (rc=${_rc}): ${_out}"; fi
  rm -rf "$_d"

  # (c) A FLAG IMPORTA, nao so o script. Sem isto, "exercitar o script com QUALQUER flag" passaria —
  #     e o valor inteiro do instrumento e distinguir `--markdown` de `(sem-flag)`.
  _d="$(mktemp -d)"
  _st_repo "$_d" 'bash "${SCRIPT_DIR}/alvo.sh" --modo' 'bash "${SCRIPT_DIR}/alvo.sh" --outroModo'
  _rc=0; _out="$(bash "${_st_me}" "$_d" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 1 ] && printf '%s' "${_out}" | grep -q -- '--modo'; then
    _st_ok '(c) mesmo script com flag DIFERENTE ainda acusa — o par e (script, flags)'
  else _st_bad '(c)' "o detector ignorou a flag (rc=${_rc}): ${_out}"; fi
  rm -rf "$_d"

  # (d) FAIL-LOUD: fonte ilegivel e exit 2, nunca "nenhum modo sem teste". Fonte ausente jamais vira
  #     aprovacao (P0 da REGRA 30) — e um repo sem os dois lados e indistinguivel de um repo limpo
  #     para quem so olha o exit code 0.
  _d="$(mktemp -d)"; mkdir -p "$_d/.claude/validation"
  _rc=0; _out="$(bash "${_st_me}" "$_d" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 2 ] && printf '%s' "${_out}" | grep -qi 'ileg'; then
    _st_ok '(d) fonte ausente -> exit 2 nomeando o arquivo (fail-loud, nunca aprovacao)'
  else _st_bad '(d)' "fonte ausente nao deu exit 2 (rc=${_rc}): ${_out}"; fi
  rm -rf "$_d"

  printf '  consumed-mode --selftest: %d passaram, %d falharam\n' "${_st_pass}" "${_st_fail}"
  [ "${_st_fail}" -eq 0 ] || exit 1
  exit 0
fi

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

# ⚠️ O VALOR, NAO A LINHA. `grep -c '^#DYN'` conta QUANTAS LINHAS casam — e o awk emite UMA linha
# `#DYN<TAB>N`. O rodape dizia "1 flag dinâmica" tendo perdido 13: erro de 13x num numero que existe
# para dizer O TAMANHO DO QUE NAO FOI JULGADO. Contador de supressao errado e pior que ausente —
# ele da a dimensao errada do proprio teto.
DYN="$(awk -F'\t' '$1=="#DYN"{s+=$2} END{print s+0}' "${TMPDIR:-/tmp}/.cmc-prod.$$" 2>/dev/null || echo 0)"
DYN_TEST="$(awk -F'\t' '$1=="#DYN"{s+=$2} END{print s+0}' "${TMPDIR:-/tmp}/.cmc-test.$$" 2>/dev/null || echo 0)"
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
  # ⚠️ A DELEGACAO POR `--selftest` FOI REMOVIDA, e a razao e a pior que existe: ela MATAVA UMA
  # REGRA HARD. Passada adversarial mediu, no core, hoje — emudecendo SO o ramo `tsv` do
  # `ladder-integrity-check.sh` (o modo que a producao consome), o `--selftest` dele seguia 8/8
  # VERDE, esta regra declarava o par COBERTO, e o lint deixava de acusar uma classe forjada:
  # 8 HARD viraram 7. A regra que existe para pegar "o modo consumido diverge do modo testado"
  # declarava cobertura EXATAMENTE sobre o par onde isso estava acontecendo.
  #
  # A isencao vinha de um raciocinio honesto e errado: "nao da para saber daqui se o `--selftest`
  # embutido cobre o modo tsv, e acusar sem medir e o erro que esta regra caca". Mas o oposto de
  # ACUSAR-SEM-MEDIR nao e ABSOLVER-SEM-MEDIR — e DECLARAR QUE NAO SABE. Absolver por ignorancia e
  # o fail-open que o P0 da REGRA 30 proibe, com a agravante de o teto estar escrito no comentario
  # e ninguem o ler ao ver o ✅.
  #
  # No lugar: os pares que viviam disso ganharam caso EXPLICITO na bancada, exercitando `--format
  # tsv` de verdade. Cobertura PROVADA substitui cobertura PRESUMIDA.
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

# ── PISO DE COBERTURA — a guarda de vacuidade so disparava em ZERO EXATO ────────────────────────
# Passada adversarial mediu a fuga: um refactor de estilo derrubou 32 pares para 11 e o veredito
# seguiu ✅ rc=0. Um extrator que perde 2/3 da producao "cobre" tudo o que ainda ve, e o verde fala
# do que sobrou — nao do que existe. E este extrator JA errou por essa familia: a cegueira a prefixo
# de env produziu DUAS acusacoes falsas, cuja "cura" cerimonial gerou um caso que escrevia no repo.
#
# O piso e DECLARADO aqui, com data e motivo, e so encolhe por edicao que aparece no diff — mesma
# doutrina da catraca da REGRA 49. Crescer e livre; encolher exige alguem escrever por que.
COVERAGE_FLOOR=30   # medido 2026-08-09: 32 pares. Margem de 2 para refactor legitimo.
# ⚠️ SO ONDE A SUITE INTEIRA VIVE. O piso afirma sobre a cobertura DESTE repo; aplica-lo a um repo
# sintetico (as fixtures do `--selftest`, que tem 1 par de proposito) faria a guarda acusar o proprio
# teste — falso-positivo em regra HARD, que e como se ensina a ignorar o gate. O marcador e a
# presenca deste script no root julgado: as fixtures escrevem so `lint-artifacts.sh` e
# `lint-selftest.sh`, e um adotante que nao vendoriza o detector simplesmente nao e julgado.
if [ -f "${REPO_ROOT}/.claude/validation/consumed-mode-check.sh" ] && [ "${PRODN}" -lt "${COVERAGE_FLOOR}" ]; then
  if [ "${FORMAT}" = tsv ]; then
    printf 'HARD\tPISO-DE-COBERTURA\t.claude/validation/consumed-mode-check.sh\to extrator achou %s pares e o piso declarado e %s — ele perdeu visao da producao, e o verde falaria so do que sobrou\n' "${PRODN}" "${COVERAGE_FLOOR}"
  else
    printf '  ✗ PISO-DE-COBERTURA: %s pares, piso declarado %s — o extrator perdeu visao da producao\n' "${PRODN}" "${COVERAGE_FLOOR}"
  fi
  MISS=$((MISS + 1))
fi

# ── A SUPRESSAO TEM DE APARECER NO MODO QUE O GATE CONSOME ──────────────────────────────────────
# O rodape inteiro vivia sob `if FORMAT != tsv`, entao a promessa escrita em letra grande no
# cabecalho — "supressao CONTADA, nunca silenciosa" — era FALSA justamente no unico modo que o
# lint invoca: 0 bytes. Contar para quem nao le e o mesmo que nao contar.
if [ "${FORMAT}" = tsv ]; then
  [ "${DYN}" -gt 0 ] && printf 'SOFT\tSUPRESSAO\t.claude/validation/consumed-mode-check.sh\t%s invocacao(oes) de producao com flag DINAMICA ficaram fora do julgamento — nao sao cobertura, sao teto\n' "${DYN}"
  : # (o `[ ]` acima nao pode ser o ultimo comando: exit code dele viraria o do script sob `set -e`)
else
  printf '  pares de produção: %s · sem teste: %s\n' "${PRODN}" "${MISS}"
  printf '  fora de julgamento (contado, nunca silencioso): %s flag dinâmica · %s cobertos por delegação (--selftest)\n' "${DYN}" "${DELEG}"
  [ "${MISS}" -eq 0 ] && printf '  ✅ todo modo consumido é exercitado pelo selftest\n'
fi
[ "${MISS}" -eq 0 ] && exit 0 || exit 1
