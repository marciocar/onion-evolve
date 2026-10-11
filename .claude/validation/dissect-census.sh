#!/usr/bin/env bash
# ===========================================================================
# dissect-census.sh — censo das DISSECAÇÕES de ferramenta já pagas pelo corpus.
#
# É o MEDIDOR da peça 3 (contexto medido injetado) do `/meta:dissect`: a saída daqui é o que a
# sessão lê ANTES de abrir qualquer fonte externa. Responde por MEDIÇÃO a pergunta que o modelo
# responde de memória e erra — "já dissecamos esta ferramenta? até que nível? quando?".
#
# ── POR QUE EXISTE (defeito medido, 2026-10-01) ────────────────────────────────────────────
# Numa única rodada de pesquisa a casa (a) re-abriu Zep, Port e Roadie sem ler o que o corpus já
# dizia e (b) registrou "a Onyx não entrega grafo" como achado, quando a doc do próprio
# fornecedor diz `AI-generated knowledge graphs` e o módulo `backend/onyx/kg` está vivo no
# código. Nível 0 repagado é o desperdício; nível 2 errado por folheto é o defeito.
#
# ── DESCOBERTA POR REFERÊNCIA, NUNCA POR NOME CONSTRUÍDO ───────────────────────────────────
# Mesma cláusula 1 que rege o forge-census.sh, e pela mesma razão: construir o caminho/nome do
# artefato a partir do nome do candidato errou 3 vezes em 2026-09-28. Aqui a dissecação se
# ANUNCIA — o grafo carrega `x_dissect_tool:` no meta e `x_dissect_level:`/`x_dissect_verdict:` (contrato v4: extensão leva `x_`; a forma sem prefixo segue lida em grafo herdado) nos
# nós, e o censo LÊ esses marcadores. Grafo que fala de uma ferramenta sem se declarar
# dissecação é invisível a este censo, e isso é verdade útil: a sessão também não o acharia.
#
# ── FRONTEIRA DECLARADA ────────────────────────────────────────────────────────────────────
# Mede o que o corpus DECLARA. Não sabe de ferramenta que ninguém anotou, não julga qualidade
# da dissecação, e não confere se a medição do nível de fato ocorreu (o marcador é
# auto-atestado — mesmo teto honesto do kg-seal-exception.sh).
#
# Uso:  bash .claude/validation/dissect-census.sh [<repo>] [--markdown|--tsv|--plans [<ferramenta>]]
# Exit: 0 = censo emitido (inclusive "zero dissecação", que é resposta) · 3 = NÃO PUDE MEDIR.
#       --plans: 0 = todo plano listado está COMPLETO (ou não há plano) · 1 = há plano INCOMPLETO.
#
# ── --plans: A COSTURA dissect→forge (SAC-77, 2026-10-11) ─────────────────────────────────
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
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_dissect_selftests).
# ===========================================================================
set -uo pipefail

REPO="${1:-}"; FMT="${2:---markdown}"; TOOL_FILTER="${3:-}"
case "${REPO}" in --*) FMT="${REPO}"; TOOL_FILTER="${2:-}"; REPO="" ;; esac
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "dissect-census: alvo inexistente: ${REPO}" >&2; exit 3; }

# FAIL-CLOSED no índice: o censo é do conjunto RASTREADO (o que viaja e o que o CI vê). Sem
# índice, "nenhuma dissecação" seria falso e caríssimo — zero NÃO é resultado quando a causa é
# não ter podido olhar. É a lição do exit-code-nao-e-a-verificacao.
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "dissect-census: sem índice git em ${REPO} — o censo seria de outro conjunto que o do CI. Recusa." >&2; exit 3; }

mapfile -t GRAPHS < <(git -C "${REPO}" ls-files -- '*.kg.yaml' 2>/dev/null | sort -u)
[ "${#GRAPHS[@]}" -gt 0 ] \
  || { echo "dissect-census: nenhum .kg.yaml RASTREADO em ${REPO} — sem corpus não há censo a emitir. Recusa." >&2; exit 3; }

TODAY="$(date +%F)"

# ── Leitura de UM grafo ────────────────────────────────────────────────────────────────────
# Os marcadores são lidos com grep ancorado e o resultado DRENADO: nenhum fechador precoce
# (`grep -q`/`head`) a jusante de escritor grande, que sob `set -o pipefail` devolve 141 e faz
# a peça existente contar como ausente — classe pipefail-epipe-early-closer, curada aqui por
# construção (laços que leem até o fim).
rows=""; parked=""; found=0; graphs_by_tool=""
for rel in "${GRAPHS[@]}"; do
  f="${REPO}/${rel}"
  [ -f "${f}" ] || continue

  tool="$(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_tool:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#]*\).*/\2/p' "${f}" | head -1 | sed 's/[[:space:]]*$//')"
  [ -n "${tool}" ] || continue
  found=$((found + 1))

  # NÍVEL ALCANÇADO = o MAIOR nível declarado em qualquer nó. Maior, não último: a ordem no
  # arquivo não é a ordem da escada, e confiar nela seria ler a projeção como fonte.
  level=0
  while IFS= read -r lv; do
    case "${lv}" in ''|*[!0-9]*) continue ;; esac
    [ "${lv}" -gt "${level}" ] && level="${lv}"
  done < <(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_level:[[:space:]]*\([0-9]\+\).*/\2/p' "${f}")

  verdict="$(sed -n 's/^[[:space:]]*\(x_\)\{0,1\}dissect_verdict:[[:space:]]*["'"'"']\{0,1\}\([a-z]*\).*/\2/p' "${f}" | head -1)"
  [ -n "${verdict}" ] || verdict="-"
  # ⚠️ DATA ENTRE ASPAS é a forma que a gramática EXIGE desde o contrato v3 (`yaml.unquoted-date`),
  #    e a 1a versão deste sed só lia a data NUA: a 2a dissecação do corpus (conductor-2026-10,
  #    escrita pela gramática) saiu NAO-DECLARADO no dogfood do SAC-77, com review_after presente.
  #    A aspa (simples ou dupla) é opcional na leitura; o grafo herdado sem aspa segue lido.
  baseline="$(sed -n 's/^[[:space:]]*baseline:[[:space:]]*["'"'"']\{0,1\}\([0-9-]\{10\}\).*/\1/p' "${f}" | head -1)"
  [ -n "${baseline}" ] || baseline="-"
  review="$(sed -n 's/^[[:space:]]*review_after:[[:space:]]*["'"'"']\{0,1\}\([0-9-]\{10\}\).*/\1/p' "${f}" | head -1)"
  [ -n "${review}" ] || review="-"

  # FRESCOR: comparação lexical de ISO-8601 é correta e dispensa `date -d` (que difere entre
  # GNU e BSD). Sem `review_after` a resposta é NAO-DECLARADO, nunca "fresco" por omissão.
  if [ "${review}" = "-" ]; then fresh="NAO-DECLARADO"
  elif [ "${review}" \< "${TODAY}" ]; then fresh="VENCIDO"
  else fresh="fresco"; fi

  rows="${rows}${tool}	${level}	${verdict}	${baseline}	${review}	${fresh}	${rel}
"
  [ "${verdict}" = "parquear" ] && parked="${parked}${tool}	${rel}
"
  graphs_by_tool="${graphs_by_tool}$(printf '%s\t%s' "${tool}" "${rel}")
"
done

# ── --plans: lê os nós de plano de absorção e MEDE as peças do alvo ao vivo ─────────────────
if [ "${FMT}" = "--plans" ]; then
  FORGE_CENSUS="${REPO}/.claude/validation/forge-census.sh"
  [ -f "${FORGE_CENSUS}" ] \
    || { echo "dissect-census: --plans precisa do forge-census.sh (as peças são MEDIDAS, não digitadas) e ele não está em ${REPO}. Recusa." >&2; exit 3; }
  # O censo das peças roda UMA vez, e a saída inteira vai para uma variável (sem fechador
  # precoce sob pipefail). rc != 0 dele é "não pude medir", e sem peças medidas não há plano.
  if ! fc_tsv="$(bash "${FORGE_CENSUS}" "${REPO}" --tsv 2>/dev/null)"; then
    echo "dissect-census: forge-census.sh não pôde medir — sem peças medidas não há plano a julgar. Recusa." >&2; exit 3
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
fi

sorted_rows="$(printf '%s' "${rows}" | sort -t'	' -k2,2nr -k1,1)"

if [ "${FMT}" = "--tsv" ]; then
  printf 'ferramenta\tnivel\tveredito\tbaseline\treview_after\tfrescor\tgrafo\n'
  [ "${found}" -gt 0 ] && printf '%s\n' "${sorted_rows}"
  exit 0
fi

# ── Markdown: a projeção que entra na superfície como contexto injetado ────────────────────
printf '# censo de dissecações · %s grafo(s) rastreado(s) · %s dissecação(ões) declarada(s)\n' \
  "${#GRAPHS[@]}" "${found}"
if [ "${found}" -eq 0 ]; then
  printf '\nNenhum grafo do corpus se declara dissecação (marcador `x_dissect_tool:` no `meta:`).\n'
  printf 'Toda ferramenta entra pelo N0 — não há nível pago a reusar.\n'
else
  printf 'ferramenta | nível | veredito | baseline | review_after | frescor\n'
  printf '%s\n' "${sorted_rows}" | awk -F'\t' 'NF>=6 && $1!=""{
    printf "%s | N%s | %s | %s | %s | %s\n", $1, $2, $3, $4, $5, $6 }'
  if [ -n "${parked}" ]; then
    printf '\n## parqueadas (técnica a investigar — exigem gatilho nomeado)\n'
    printf '%s' "${parked}" | awk -F'\t' '$1!=""{ printf "- %s  (%s)\n", $1, $2 }'
  fi
fi
printf '\n(ferramenta com nível fresco ENTRA no nível seguinte — re-derivar nível pago é o\n'
printf 'desperdício que este censo corta. VENCIDO não se cita como se fosse de hoje: licença,\n'
printf 'mantenedor e preço mudam em semanas. TETO DECLARADO: o censo mede o que o corpus\n'
printf 'DECLARA, não sabe de ferramenta que ninguém anotou, e não confere se a medição do nível\n'
printf 'de fato ocorreu — o marcador é auto-atestado.)\n'
