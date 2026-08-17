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
# MEDIDO numa adoção greenfield real (PoC BW&P / HPE Autos, 2026-08-17): o irmão
# `kg-verification-baseline.txt` chegou com **47 chaves de grafos do core** (docs/discussions,
# onion-pessoal, bridge-produto) e o lint do alvo nasceu com **47 violações HARD**, todas
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
# Uso:  bash regen-baselines.sh <DEST>
# Saída: relatório por baseline (chaves antes → depois) no stdout; avisos no stderr.
# Códigos: 0 = todos resolvidos · 2 = uso inválido/alvo inexistente · 3 = algum não resolvido.

set -u

DEST="${1:-}"
if [ -z "${DEST}" ] || [ ! -d "${DEST}" ]; then
  echo "uso: regen-baselines.sh <DEST>   (alvo inexistente: '${DEST}')" >&2
  exit 2
fi

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

shopt -s nullglob
for bpath in "${VDIR}"/*-baseline.txt; do
  bname="$(basename "${bpath}")"

  # Resolve o EMISSOR: script que (a) aceita --emit-baseline e (b) menciona este baseline.
  # `lint-selftest.sh` é a BANCADA — ela cita todos os baselines por exercitá-los, e tomá-la
  # por emissor faria o helper regenerar cinco arquivos com a saída da suíte de testes.
  emitter=""
  emitter_count=0
  for s in "${VDIR}"/*.sh; do
    case "$(basename "${s}")" in lint-selftest.sh|regen-baselines.sh) continue ;; esac
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

echo "  → ${regenerated} baseline(s) regenerado(s) do corpus do ALVO; ${unresolved} não resolvido(s)."
[ "${unresolved}" -eq 0 ] || exit 3
exit 0
