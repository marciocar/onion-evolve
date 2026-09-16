#!/usr/bin/env bash
# regen-baselines.sh — regenera TODOS os baselines de catraca a partir do corpus DO ALVO.
#
# ── POR QUE ESTE HELPER EXISTE (achado de dogfood de campo, 2026-08-17) ───────────────────
# O manifesto de adoção copia `.claude/validation/` INTEIRO, então TODO baseline de catraca do
# core viaja para o adotante — carregando o PASSIVO do core (chaves de paths que só existem
# aqui). O passo (9) do adopt regenerava **um** deles (`kg-coverage-baseline.txt`) e escrevia,
# no próprio comentário, exatamente o modo-de-falha que a omissão dos outros produz: *"o gate
# nasceria reprovando o repo do adotante no dia 1 e seria desligado"*.
#
# MEDIDO numa adoção greenfield real (PoC de cliente, 2026-08-17): o irmão
# `kg-verification-baseline.txt` chegou com **47 chaves de grafos do core** (docs/discussions,
# verticais privados do core) e o lint do alvo nasceu com **47 violações HARD**, todas
# `[kg-verificacao/REMOVIDO]` — o adotante era cobrado por nós que nunca teve. Cinco baselines
# viajam; a adoção regenerava um. A cura é regenerar todos.
#
# ⚠️ E POR QUE POR DESCOBERTA, NÃO POR LISTA: o histórico desta casa diz que guarda de lista
# falha pelo VOCABULÁRIO, não pela lógica (3 ocorrências em um único dia, 2026-08-11). Uma lista
# de cinco nomes aqui envelheceria no primeiro baseline novo — e o defeito voltaria em silêncio,
# porque baseline não-regenerado não grita: ele REPROVA o adotante. Então o helper VARRE
# `*-baseline.txt` e resolve o emissor de cada um. Baseline novo entra coberto por construção.
#
# ⚠️ FALHA RUIDOSA (a lição do `exit 0` que é declaração, não verificação): se algum baseline
# ficar SEM emissor resolvido, o helper NÃO devolve zero fingindo sucesso — ele reporta e sai 3.
# Um baseline não regenerado é passivo alheio cobrado do adotante, e isso tem de ser visível.
#
# ── DUAS OPERAÇÕES, E CONFUNDI-LAS ENFRAQUECE A CATRACA ──────────────────────────────────
# `--emit` (regenerar do corpus do alvo) é o certo na ADOÇÃO: dia 1, história vazia, e a intenção
# é justamente TOLERAR o estado pré-existente do adotante — sem isso o gate vê todo documento
# próprio dele como HARD-novo e ele desliga a guarda.
#
# No `--update` a MESMA operação estaria errada, e o erro seria invisível: o adotante já tem
# história, então re-emitir re-tolera toda a dívida acumulada DESDE a última atualização — a
# catraca perderia justamente o que ela mede. Ali a operação correta é FILTRAR: derrubar só as
# chaves ESTRANGEIRAS (cujo arquivo não existe no alvo — o passivo do core que veio na cópia) e
# preservar as locais.
#
# ⚙️ E A ESCOLHA É MECÂNICA, NÃO DO CHAMADOR (`--auto`, o default). A 1ª versão exigia que o
# procedimento exportasse `--filter` no caminho do update — isto é, pedia DISCIPLINA de quem chama,
# e quem esquecesse enfraquecia a catraca EM SILÊNCIO. O discriminador correto é objetivo e não é
# "tem história?" (adoção de repo LEGADO tem história, e ali emitir é o certo): é **este baseline já
# esteve na história deste alvo?**
#   · NÃO esteve → é a PRIMEIRA vez que ele chega aqui → `emit` (tolerar o dia 1 do adotante).
#   · JÁ esteve  → o alvo já tinha catraca → `filter` (só a chave estrangeira cai).
# Decidido POR BASELINE, porque baseline novo do core chega depois num alvo antigo. `--emit` e
# `--filter` seguem disponíveis para forçar à mão.
#
# Uso:  bash regen-baselines.sh <DEST> [--auto|--filter|--emit]
# Saída: relatório por baseline (chaves antes → depois) no stdout; avisos no stderr.
# Códigos: 0 = todos resolvidos · 2 = uso inválido/alvo inexistente · 3 = algum não resolvido.

set -u

DEST=""
MODE=auto
while [ $# -gt 0 ]; do
  case "$1" in
    --auto)   MODE=auto; shift ;;
    --filter) MODE=filter; shift ;;
    --emit|--emit-baseline) MODE=emit; shift ;;
    --ensure-from) ENSURE_FROM="${2:-}"; shift 2 ;;
    -*) echo "regen-baselines: opção desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${DEST}" ] && DEST="$1" || { echo "regen-baselines: alvo já informado ('${DEST}')" >&2; exit 2; }; shift ;;
  esac
done
if [ -z "${DEST}" ] || [ ! -d "${DEST}" ]; then
  echo "uso: regen-baselines.sh <DEST> [--auto|--filter|--emit]   (alvo inexistente: '${DEST}')" >&2
  exit 2
fi

: "${ENSURE_FROM:=}"
VDIR="${DEST}/.claude/validation"
if [ ! -d "${VDIR}" ]; then
  echo "⊘ regen-baselines: ${VDIR} não existe — nada a regenerar (alvo sem maquinaria vendorizada)." >&2
  exit 0
fi

# ⛔ NUNCA no core. No adotante o baseline herdado é PASSIVO ALHEIO (regenerar é a cura); no core
# ele é o LEDGER LEGÍTIMO da própria dívida — regenerar ali zeraria a medição que a catraca existe
# para fazer subir, e em silêncio (a catraca passaria a comparar contra o presente).
#
# ⚠️ O papel se PERGUNTA ao `onion-version.sh` (a autoridade), não se lê do arquivo `.onion-version`.
# Medido em 2026-08-17: a primeira versão desta guarda checava o ARQUIVO e ficou MUDA no core —
# porque o core não tem esse arquivo (ali o papel é COMPUTADO; o stamp existe no adotante). Ela
# passou só por idempotência (os baselines do core saíram byte-idênticos), isto é: certo por sorte,
# não por verificação. Fallback no arquivo cobre alvo que tenha stamp mas não o script.
_role=""
if [ -f "${DEST}/.claude/validation/onion-version.sh" ]; then
  _role="$(bash "${DEST}/.claude/validation/onion-version.sh" 2>/dev/null | awk '/^role:/{print $2; exit}')"
fi
if [ -z "${_role}" ] && [ -f "${DEST}/.claude/.onion-version" ]; then
  _role="$(awk '/^role:/{print $2; exit}' "${DEST}/.claude/.onion-version" 2>/dev/null)"
fi
if [ "${_role}" = "source" ]; then
  echo "⛔ regen-baselines: '${DEST}' é o CORE (role: source) — abortado." >&2
  echo "   Ali o baseline é o ledger da dívida própria, não passivo herdado: regenerar apagaria a medição." >&2
  exit 2
fi

# Conta chaves REAIS (ignora comentário e linha vazia) — o cabeçalho emitido não é chave, e
# confundir os dois foi o que me fez ler "5 linhas" como "5 chaves" na medição de 2026-08-17.
# ⚠️ `grep -c` com zero casamentos imprime "0" E SAI 1 — então `grep -c ... || echo 0` emite DUAS
# linhas ("0\n0") e qualquer relatório que use isso sai deformado. Medido aqui em 2026-08-17.
count_keys() {
  [ -f "$1" ] || { printf '0'; return 0; }
  local n; n="$(grep -cvE '^[[:space:]]*(#|$)' "$1" 2>/dev/null)" || n=0
  printf '%s' "${n:-0}"
}

unresolved=0
regenerated=0

# ── --ensure-from: adotante PRE-CATRACA (sem baseline proprio) ficaria com a catraca em FAIL-CLOSED
# (NO-BASELINE) apos o update, porque o loop abaixo so itera baselines PRESENTES. Semeia um STUB VAZIO
# para cada baseline que o SOURCE (core) DEFINE mas o alvo NAO tem — o loop --auto entao o trata como
# "1a chegada -> emit" e o preenche do CORPUS DO ADOTANTE (nunca do core). Fecha D_ADOPT_MUST_EMIT_
# MISSING_BASELINES (adotante pré-catraca): o motor viaja, o baseline nasce do alvo.
if [ -n "${ENSURE_FROM}" ] && [ -d "${ENSURE_FROM}/.claude/validation" ]; then
  shopt -s nullglob
  for _sb in "${ENSURE_FROM}/.claude/validation"/*-baseline.txt; do
    _bn="$(basename "${_sb}")"
    if [ ! -e "${VDIR}/${_bn}" ]; then
      printf '# Baseline semeado por regen-baselines --ensure-from (sera emitido do corpus do alvo).\n' > "${VDIR}/${_bn}"
      printf '  + %-38s AUSENTE no alvo → stub semeado (sera emitido do corpus do adotante)\n' "${_bn}"
    fi
  done
  shopt -u nullglob
fi

shopt -s nullglob
for bpath in "${VDIR}"/*-baseline.txt; do
  bname="$(basename "${bpath}")"

  # `--auto`: decide POR BASELINE pela pergunta objetiva "este arquivo já esteve na história deste
  # alvo?". Nunca por "o alvo tem história" — adoção de repo LEGADO tem, e ali emitir é o certo.
  bmode="${MODE}"
  if [ "${bmode}" = "auto" ]; then
    rel=".claude/validation/${bname}"
    if git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1 \
       && [ -n "$(git -C "${DEST}" log -1 --format=%H -- "${rel}" 2>/dev/null)" ]; then
      bmode=filter    # já esteve versionado aqui → o alvo já tinha catraca
    else
      bmode=emit      # 1ª chegada deste baseline → tolerar o estado do dia 1
    fi
  fi

  # ── MODO FILTER: derruba só a chave ESTRANGEIRA, preserva a local ──────────────────────
  # Estrangeira = a linha cita um arquivo que NÃO EXISTE no alvo, logo é passivo que veio na
  # cópia do core. Local = arquivo existe ali; é dívida do adotante e a catraca tem de continuar
  # cobrando. Linha sem forma de caminho reconhecível é PRESERVADA (conservador: na dúvida a
  # catraca cobra, nunca perdoa — perdoar em silêncio é o modo-de-falha caro).
  if [ "${bmode}" = "filter" ]; then
    before="$(count_keys "${bpath}")"
    tmpf="$(mktemp)"; foreign=0
    while IFS= read -r line || [ -n "${line}" ]; do
      case "${line}" in ''|\#*) printf '%s\n' "${line}" >> "${tmpf}"; continue ;; esac
      # separadores de chave observados nos baselines desta casa: `path::hash` e `path|target`
      p="${line%%::*}"; [ "${p}" = "${line}" ] && p="${line%%|*}"
      # ⚠️ E AS DUAS FORMAS SEM ESSES SEPARADORES, que a versão anterior deixava passar INTEIRAS:
      #    `path<TAB>contagem` (pipe-verdict) e o CAMINHO NU (kg-yaml-validity). Sem isto, a chave
      #    do core sobrevivia no adotante e a "métrica de saúde" dele nascia inflada para sempre —
      #    a mesma contaminação já curada uma vez nesta casa, por outro baseline. O corte é o
      #    PRIMEIRO campo delimitado por espaço em branco; o teste de existência abaixo continua
      #    sendo o juiz, então entrada cujo arquivo EXISTE no alvo segue preservada.
      [ "${p}" = "${line}" ] && p="${line%%[[:space:]]*}"
      # A condição é a FORMA DE CAMINHO (tem barra), não a presença de separador: a versão anterior
      # exigia `p != line`, o que excluía justamente a chave que É um caminho inteiro. Linha sem
      # barra continua PRESERVADA — conservador, como o cabeçalho promete.
      if case "${p}" in */*) true ;; *) false ;; esac; then
        if [ ! -e "${DEST}/${p}" ]; then foreign=$((foreign + 1)); continue; fi
      fi
      printf '%s\n' "${line}" >> "${tmpf}"
    done < "${bpath}"
    if [ "${foreign}" -gt 0 ]; then
      mv "${tmpf}" "${bpath}"
      printf '  ✓ %-38s %s → %s chave(s)   [filtradas %s estrangeira(s)]\n' \
        "${bname}" "${before}" "$(count_keys "${bpath}")" "${foreign}"
      regenerated=$((regenerated + 1))
    else
      rm -f "${tmpf}"
      printf '  · %-38s %s chave(s), nenhuma estrangeira — INTACTO (dívida local segue cobrada)\n' \
        "${bname}" "${before}"
      regenerated=$((regenerated + 1))
    fi
    continue
  fi

  # Resolve o EMISSOR: script que (a) aceita --emit-baseline e (b) menciona este baseline.
  #
  # ── OS TRÊS QUE NÃO SÃO EMISSORES, E A REGRA QUE OS UNE ─────────────────────────────────
  # `lint-selftest.sh` é a BANCADA — ela cita todos os baselines por exercitá-los, e tomá-la
  # por emissor faria o helper regenerar cinco arquivos com a saída da suíte de testes.
  #
  # `lint-artifacts.sh` é o LINT, e entrou nesta lista em 2026-09-14 por um defeito MEDIDO:
  # uma mensagem de remediação nova — *"regenere: bash ... --emit-baseline > ...baseline.txt"* —
  # pôs a string `--emit-baseline` no lint pela PRIMEIRA VEZ (`grep -c` era 0, virou 1). Como o
  # lint cita TODO baseline nas mensagens de como consertá-lo, aquela única linha o tornou
  # candidato a emissor de **8 dos 10** baselines de uma vez, `emitter_count` virou 2 em todos, e
  # a adoção parou de regenerar qualquer um. O adotante voltaria a nascer com o passivo do core.
  #
  # A REGRA, e ela é o que impede a próxima recorrência: **quem FALA de todos os baselines não é
  # emissor de nenhum.** Emissor é o script de UMA guarda, que emite O SEU baseline. Bancada e
  # lint são consumidores universais — citam por ofício, não por emitir.
  #
  # ⚠️ TETO DECLARADO: isto continua sendo uma LISTA, e nesta casa guarda de lista falha pelo
  # VOCABULÁRIO. O critério robusto seria "implementa `--emit-baseline` num dispatch de
  # argumento" em vez de "menciona a string", mas distinguir isso em shell é frágil. A rede que
  # substitui a lista é o caso de bancada com mutante: qualquer consumidor universal futuro
  # reprova o `regen-baselines` inteiro, ruidosamente, na primeira adoção simulada.
  emitter=""
  emitter_count=0
  for s in "${VDIR}"/*.sh; do
    case "$(basename "${s}")" in lint-selftest.sh|lint-artifacts.sh|regen-baselines.sh) continue ;; esac
    grep -q -- '--emit-baseline' "${s}" 2>/dev/null || continue
    grep -q "${bname}" "${s}" 2>/dev/null || continue
    emitter="${s}"; emitter_count=$((emitter_count + 1))
  done

  if [ "${emitter_count}" -ne 1 ]; then
    printf '  ✗ %-38s emissor NÃO resolvido (%d candidatos) — baseline mantido COMO VEIO DO CORE\n' \
      "${bname}" "${emitter_count}"
    echo "    ⚠️  passivo do core segue cobrado deste alvo neste baseline; resolva à mão:" >&2
    echo "        bash <script-emissor> --emit-baseline > ${bpath}" >&2
    unresolved=$((unresolved + 1))
    continue
  fi

  before="$(count_keys "${bpath}")"

  # Emite para TMP e só promove se o emissor teve sucesso — sobrescrever com a saída de um
  # script que falhou trocaria passivo alheio por baseline VAZIO, que é pior: catraca vazia
  # não cobra nada e a guarda passa a mentir verde.
  tmp="$(mktemp)"
  if ( cd "${DEST}" && bash "${emitter}" --emit-baseline ) > "${tmp}" 2>/dev/null; then
    mv "${tmp}" "${bpath}"
    after="$(count_keys "${bpath}")"
    printf '  ✓ %-38s %s → %s chave(s)   [%s]\n' \
      "${bname}" "${before}" "${after}" "$(basename "${emitter}")"
    regenerated=$((regenerated + 1))
  else
    rm -f "${tmp}"
    printf '  ✗ %-38s emissor falhou (%s) — baseline mantido COMO VEIO DO CORE\n' \
      "${bname}" "$(basename "${emitter}")"
    echo "    ⚠️  ${bname}: o emissor saiu não-zero; baseline NÃO foi trocado por vazio (proposital)." >&2
    unresolved=$((unresolved + 1))
  fi
done
shopt -u nullglob

if [ "${regenerated}" -eq 0 ] && [ "${unresolved}" -eq 0 ]; then
  echo "  ⊘ nenhum *-baseline.txt encontrado em ${VDIR} — nada a regenerar."
  exit 0
fi

case "${MODE}" in
  filter) echo "  → ${regenerated} baseline(s) conferido(s) (só chave ESTRANGEIRA cai; dívida local segue cobrada); ${unresolved} não resolvido(s)." ;;
  emit)   echo "  → ${regenerated} baseline(s) regenerado(s) do corpus do ALVO; ${unresolved} não resolvido(s)." ;;
  *)      echo "  → ${regenerated} baseline(s) tratado(s) (modo decidido por baseline: 1ª chegada emite, já-versionado filtra); ${unresolved} não resolvido(s)." ;;
esac
[ "${unresolved}" -eq 0 ] || exit 3
exit 0
