#!/usr/bin/env bash
# ===========================================================================
# dissect-plans.sh — o LEITOR dos planos de absorção do /meta:dissect, entrada do /meta:forge.
#
# ── A COSTURA dissect→forge (SAC-77, 2026-10-11) ─────────────────────────────────
# O veredito `absorver`/`costurar` do N4 vira NÓS de plano no grafo da dissecação (KG-SSOT
# first), um por peça absorvida, com os campos `x_absorb_*`. Este modo é o LEITOR desses nós,
# e é o que o `/meta:forge` injeta como entrada. Ele faz duas coisas que a prosa não fazia:
#   (1) as PEÇAS que já existem NÃO são digitadas no plano — são medidas AGORA pelo
#       forge-census.sh contra o alvo nomeado. Plano que carregasse "peça 4 existe" à mão seria
#       plano preenchido sem medir (a objeção do refutador do SAC-77); por isso o campo nem existe.
#   (2) PROVENIÊNCIA, LICENÇA, PARIDADE e FORMA são obrigatórias, e plano sem elas sai INCOMPLETO
#       com o motivo nomeado. Absorver sem registrar a origem é o roubo que a casa proíbe.
# TETO DECLARADO: confere FORMA (URL com pin, licença com cara de SPDX, família de bancada
# nomeada, forma no enum), não VERDADE — não abre a rede para conferir que a licença é aquela.
#
# ── POR QUE É UM SCRIPT SEPARADO do dissect-census.sh (medido, 2026-10-11) ──────────────────
# Nasceu como modo `--plans` do dissect-census.sh, e o CI reprovou a montagem do plugin
# `onion-meta`: o dissect-census VIAJA nele, o forge-census NÃO (mede o harness do repo, que quem
# instala plugin não tem), e o assembler recusou o bundle — "dissect-census.sh precisa de
# forge-census.sh, que NAO esta no VALIDATION[]". A costura é do FORGE, e o forge não viaja no
# plugin; logo o leitor fica do lado do forge (core e standalone), e o censo que viaja segue sem a
# dependência. Mesmo padrão do forge-census, que fica fora do plugin pela mesma razão.
#
# Uso:  bash .claude/validation/dissect-plans.sh [<repo>] [<ferramenta>]
# Exit: 0 = todo plano listado COMPLETO (ou não há plano) · 1 = há plano INCOMPLETO ·
#       3 = NÃO PUDE MEDIR (sem índice, sem corpus, sem forge-census).
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_dissect_selftests, casos p*).
# ===========================================================================
set -uo pipefail

REPO="${1:-}"; TOOL_FILTER="${2:-}"
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "dissect-plans: alvo inexistente: ${REPO}" >&2; exit 3; }
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "dissect-plans: sem índice git em ${REPO} — o corpus seria de outro conjunto que o do CI. Recusa." >&2; exit 3; }
mapfile -t GRAPHS < <(git -C "${REPO}" ls-files -- '*.kg.yaml' 2>/dev/null | sort -u)
[ "${#GRAPHS[@]}" -gt 0 ] \
  || { echo "dissect-plans: nenhum .kg.yaml RASTREADO em ${REPO} — sem corpus não há plano. Recusa." >&2; exit 3; }

# As dissecações se ANUNCIAM pelo marcador `x_dissect_tool:` (o mesmo que o dissect-census lê).
graphs_by_tool=""
for rel in "${GRAPHS[@]}"; do
  f="${REPO}/${rel}"
  [ -f "${f}" ] || continue
  tool="$(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_tool:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#]*\).*/\2/p' "${f}" | head -1 | sed 's/[[:space:]]*$//')"
  [ -n "${tool}" ] || continue
  graphs_by_tool="${graphs_by_tool}$(printf '%s\t%s' "${tool}" "${rel}")
"
done

# ── lê os nós de plano de absorção e MEDE as peças do alvo ao vivo ─────────────────
FORGE_CENSUS="${REPO}/.claude/validation/forge-census.sh"
[ -f "${FORGE_CENSUS}" ] \
  || { echo "dissect-plans: precisa do forge-census.sh (as peças são MEDIDAS, não digitadas) e ele não está em ${REPO}. Recusa." >&2; exit 3; }
# O censo das peças roda UMA vez, e a saída inteira vai para uma variável (sem fechador
# precoce sob pipefail). rc != 0 dele é "não pude medir", e sem peças medidas não há plano.
if ! fc_tsv="$(bash "${FORGE_CENSUS}" "${REPO}" --tsv 2>/dev/null)"; then
  echo "dissect-plans: forge-census.sh não pôde medir — sem peças medidas não há plano a julgar. Recusa." >&2; exit 3
fi

plans=""
while IFS=$'\t' read -r tool rel; do
  [ -n "${tool}" ] || continue
  [ -z "${TOOL_FILTER}" ] || [ "${tool}" = "${TOOL_FILTER}" ] || continue
  # Um registro por nó que declara `x_absorb_target:`. Campos em ordem fixa; vazio vira "-".
  plans="${plans}$(awk -v tool="${tool}" -v rel="${rel}" '
    function flush() {
      if (id != "" && tgt != "")
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", tool, id, tgt,
          (pcs==""?"-":pcs), (org==""?"-":org), (lic==""?"-":lic), (par==""?"-":par), (frm==""?"-":frm), rel
      id=""; tgt=""; pcs=""; org=""; lic=""; par=""; frm=""
    }
    function val(line) {
      sub(/^[^:]*:[[:space:]]*/, "", line); sub(/[[:space:]]+$/, "", line)
      gsub(/^["\047]|["\047]$/, "", line); return line
    }
    /^[[:space:]]*- id:/              { flush(); id=$0; sub(/^[[:space:]]*- id:[[:space:]]*/, "", id); next }
    /^edges:/                          { flush(); next }
    /^[[:space:]]*x_absorb_target:/    { tgt=val($0); next }
    /^[[:space:]]*x_absorb_pieces:/    { pcs=val($0); next }
    /^[[:space:]]*x_absorb_origin:/    { org=val($0); next }
    /^[[:space:]]*x_absorb_license:/   { lic=val($0); next }
    /^[[:space:]]*x_absorb_parity:/    { par=val($0); next }
    /^[[:space:]]*x_absorb_form:/      { frm=val($0); next }
    END { flush() }' "${REPO}/${rel}")
"
done <<< "${graphs_by_tool}"

n_plans=0; n_incomplete=0; out=""
while IFS=$'\t' read -r tool id tgt pcs org lic par frm rel; do
  [ -n "${id}" ] || continue
  n_plans=$((n_plans + 1)); why=""
  # PROVENIÊNCIA: URL com PIN (sha de 7+ hex ou tag de versão). URL sem pin aponta um alvo que
  # anda — a origem registrada hoje não é a de amanhã, e paridade contra alvo móvel não prova nada.
  case "${org}" in
    http://*|https://*)
      # O pin vale só na POSIÇÃO de pin (após /blob/ /tree/ /commit/ /tag/ @ ou ref=): hex solto
      # em nome de repo ("deadbeefcafe-tool/blob/main") não é pin — achado da passada adversarial.
      [[ "${org}" =~ (/blob/|/tree/|/commit/|/tag/|@|ref=)(v?[0-9]+[.][0-9]+|[0-9a-f]{7,40}) ]] \
        || why="${why} origem-sem-pin" ;;
    *) why="${why} origem-ausente" ;;
  esac
  # LICENÇA: cara de SPDX, ou `proprietary`. "-", "?" e "unknown" são ausência declarada.
  case "${lic}" in
    -|'?'|unknown|UNKNOWN|desconhecida|'') why="${why} licenca-ausente" ;;
    *) [[ "${lic}" =~ ^[A-Za-z0-9][A-Za-z0-9.+-]*$ ]] || why="${why} licenca-malformada" ;;
  esac
  # FORMA: o enum da costura. Código proprietário NUNCA se vendoriza: reescreve-se o conceito
  # ou costura-se por adapter (SDAAL), como o contrato do KG-SSOT entra por pin.
  case "${frm}" in
    reescrita|adapter-sdaal) ;;
    vendor-pin) [ "${lic}" != "proprietary" ] || why="${why} vendor-de-proprietario" ;;
    *) why="${why} forma-fora-do-enum" ;;
  esac
  # PARIDADE: nomeia a família da bancada que a cobra. A família pode nascer no PR da absorção;
  # o que não pode é o plano não dizer onde a paridade será provada.
  [[ "${par}" =~ run_[a-z0-9_]+_selftests ]] || why="${why} paridade-sem-bancada"
  # PEÇAS pedidas: lista de 1..7. As que EXISTEM saem do forge-census, nunca do plano.
  pcs_ok=0; [[ "${pcs}" =~ ^[1-7](,[1-7])*$ ]] && pcs_ok=1
  [ "${pcs_ok}" = "1" ] || why="${why} pecas-malformadas"
  row=""; measured=""
  case "${tgt}" in
    novo:*) measured="alvo novo — nenhuma peça existe ainda" ;;
    *) row="$(printf '%s\n' "${fc_tsv}" | awk -F'\t' -v t="${tgt}" 'NR>1 && $2==t && !seen {print; seen=1}')"
       [ -n "${row}" ] || why="${why} alvo-fora-do-forge-census" ;;
  esac
  if [ -n "${row}" ] && [ "${pcs_ok}" = "1" ]; then
    for pc in ${pcs//,/ }; do
      # forge-census --tsv: col 3=peça 2 (doutrina) … col 8=peça 7 (bancada); a peça 1 é a
      # própria superfície e existe por construção quando o alvo está no censo.
      if [ "${pc}" = "1" ]; then st="existe"
      else st="$(printf '%s\n' "${row}" | awk -F'\t' -v c="$((pc + 1))" '{print ($c=="1" ? "existe" : "falta")}')"; fi
      measured="${measured}${measured:+ · }${pc}:${st}"
    done
  fi
  if [ -n "${why}" ]; then status="INCOMPLETO(${why# })"; n_incomplete=$((n_incomplete + 1)); else status="COMPLETO"; fi
  out="${out}- **${tool}** · \`${id}\` → alvo \`${tgt}\` · ${status}
  peças pedidas (medidas agora pelo forge-census): ${measured:-—}
  forma: ${frm} · licença: ${lic} · origem: ${org}
  paridade: ${par}
"
done <<< "${plans}"

printf '# planos de absorção (costura dissect→forge) · %s plano(s) · %s incompleto(s)\n' "${n_plans}" "${n_incomplete}"
if [ "${n_plans}" -eq 0 ]; then
  printf '\nNenhum nó `x_absorb_target:` nos grafos de dissecação%s — não há plano para o forge ler.\n' \
    "${TOOL_FILTER:+ de ${TOOL_FILTER}}"
else
  printf '\n%s' "${out}"
fi
printf '\n(peças "existe/falta" são MEDIDAS agora pelo forge-census.sh no alvo, nunca lidas do plano.\n'
printf 'TETO DECLARADO: proveniência e licença são conferidas na FORMA, não na verdade — quem\n'
printf 'preenche o plano mede a origem; este leitor recusa o plano que nem a declara.)\n'
[ "${n_incomplete}" -eq 0 ] || exit 1
exit 0
