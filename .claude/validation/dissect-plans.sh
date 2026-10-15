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
# ── A RÉGUA E O ESTUDO (SAC-135, decisões do maestro de 2026-10-14) ──────────────────────────
# (a) RÉGUA POR ALVO: `meta.x_dissect_against: <repo>` declara que o plano é para o repo do ALVO,
#     não para o framework. Ausente (ou `onion`) = o comportamento de sempre: as peças se medem
#     neste repo. Com outro alvo, as peças se medem NO REPO DO ALVO, com o forge-census DESTE repo
#     (o hub forja; o alvo pode nem ter o medidor). A raiz do alvo é PASSADA, nunca adivinhada:
#     `--against-root <repo>=<caminho>`. Construir o caminho a partir do nome é a classe que a
#     cláusula 1 do forge-census proíbe (3 erros medidos em 2026-09-28). Sem a raiz, o plano sai
#     NAO-MEDIDO — jamais medido contra este repo, que é outra régua. Caminho relativo resolve
#     contra o <repo> deste leitor, não contra o diretório de quem chama.
# (b) ESTUDO NÃO É PLANO: grafo com `meta.x_dissect_mode: study` para no N2 sem veredito; nó
#     `x_absorb_*` dentro dele contradiz o modo e sai INCOMPLETO(estudo-nao-tem-plano). Modo que
#     este leitor não conhece sai INCOMPLETO(modo-desconhecido) — nunca lido como modo normal.
# (c) RÉGUA PADRÃO = O PRÓPRIO REPO, e ESCOPO (SAC-147, decisão de 2026-10-15): num adotado o
#     dissect sem `--against` grava a régua = o id DESTE repo, derivado pelo dissect-census.sh
#     `--regua-padrao` (a SSOT da derivação — este leitor a chama, não a repete). Plano dessa régua
#     se mede AQUI, com `=.` implícito: o operador não passa `--against-root` para medir o próprio
#     repo (passar continua valendo e vence). Grafo com `meta.x_dissect_scope: <pathspec[,…]>`
#     escreveu o plano para um COMPONENTE do repo; o escopo tem de casar arquivo RASTREADO no repo
#     da régua, ou o plano sai INCOMPLETO(escopo-sem-arquivo): plano para um componente que não
#     existe lá é plano para outro repo. Escopo de régua sem raiz não é medido (já é NAO-MEDIDO).
#
# Uso:  bash .claude/validation/dissect-plans.sh [<repo>] [<ferramenta>] [--against-root <repo>=<caminho>]...
# Exit: 0 = todo plano listado COMPLETO (ou não há plano) · 1 = há plano INCOMPLETO ·
#       3 = NÃO PUDE MEDIR (sem índice, sem corpus, sem forge-census, ou plano de outra régua
#       sem a raiz do alvo / com o alvo que o forge-census não mediu) · 2 = uso inválido.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_dissect_selftests, casos p*).
# ===========================================================================
set -uo pipefail

REPO=""; TOOL_FILTER=""; AGAINST_ROOTS=""; _npos=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --against-root)
      [ "$#" -ge 2 ] || { echo "dissect-plans: --against-root pede <repo>=<caminho>" >&2; exit 2; }
      _ar="$2"; shift 2 ;;
    --against-root=*) _ar="${1#--against-root=}"; shift ;;
    --*) echo "dissect-plans: opção desconhecida: $1" >&2; exit 2 ;;
    *) _npos=$((_npos + 1))
       case "${_npos}" in 1) REPO="$1" ;; 2) TOOL_FILTER="$1" ;;
         *) echo "dissect-plans: argumento a mais: $1" >&2; exit 2 ;; esac
       shift; continue ;;
  esac
  case "${_ar}" in ?*=?*) ;; *) echo "dissect-plans: --against-root pede <repo>=<caminho>, veio '${_ar}'" >&2; exit 2 ;; esac
  AGAINST_ROOTS="${AGAINST_ROOTS}${_ar%%=*}	${_ar#*=}
"
done
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
  against="$(sed -n 's/^[[:space:]]*x_dissect_against:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#]*\).*/\1/p' "${f}" | head -1 | sed 's/[[:space:]]*$//')"
  mode="$(sed -n 's/^[[:space:]]*x_dissect_mode:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#[:space:]]*\).*/\1/p' "${f}" | head -1)"
  scope="$(sed -n 's/^[[:space:]]*x_dissect_scope:[[:space:]]*["'"'"']\{0,1\}\([^"'"'"'#]*\).*/\1/p' "${f}" | head -1 | sed 's/[[:space:]]*$//')"
  graphs_by_tool="${graphs_by_tool}$(printf '%s\t%s\t%s\t%s\t%s' "${tool}" "${rel}" "${against:-onion}" "${mode:--}" "${scope:--}")
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

# RÉGUA PADRÃO deste repo: lida do dissect-census.sh (SSOT da derivação). Sem ele não se sabe
# qual régua é "o próprio repo", e adivinhar seria medir outra régua — recusa, como sem forge-census.
DISSECT_CENSUS="${REPO}/.claude/validation/dissect-census.sh"
[ -f "${DISSECT_CENSUS}" ] \
  || { echo "dissect-plans: precisa do dissect-census.sh (deriva a régua padrão deste repo) e ele não está em ${REPO}. Recusa." >&2; exit 3; }
# FORMA conferida: um dissect-census de pin ANTIGO ignora `--regua-padrao` e imprime o markdown, cujo
# cabeçalho viraria "régua" (achado da passada adversarial). Só vale `<régua>\t<origem>` de id limpo.
_rp_line="$(bash "${DISSECT_CENSUS}" "${REPO}" --regua-padrao 2>/dev/null | head -1)" || _rp_line=""
SELF_REGUA=""
if [[ "${_rp_line}" == *$'\t'* ]] && [[ "${_rp_line%%$'\t'*}" =~ ^[A-Za-z0-9._-]+$ ]]; then SELF_REGUA="${_rp_line%%$'\t'*}"; fi
[ -n "${SELF_REGUA}" ] \
  || { echo "dissect-plans: dissect-census.sh --regua-padrao não derivou a régua deste repo. Recusa." >&2; exit 3; }
# `=.` IMPLÍCITO: a régua = o próprio repo mede aqui, sem o operador passar. Explícito vence (vem antes).
AGAINST_ROOTS="${AGAINST_ROOTS}${SELF_REGUA}	.
"

# forge-census do REPO DO ALVO (régua != onion), medido uma vez por alvo e guardado em arquivo.
_fc_cache="$(mktemp -d)"; trap 'rm -rf "${_fc_cache}"' EXIT
_fc_of() {  # $1=régua → imprime o tsv do alvo; rc 4 = sem raiz, rc 5 = o censo não mediu
  local root key; root="$(printf '%s' "${AGAINST_ROOTS}" | awk -F'\t' -v a="$1" '$1==a {print $2; exit}')"
  [ -n "${root}" ] || return 4
  key="$(printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_')"
  if [ ! -f "${_fc_cache}/${key}.tsv" ]; then
    case "${root}" in /*) ;; *) root="${REPO}/${root}" ;; esac
    bash "${FORGE_CENSUS}" "${root}" --tsv > "${_fc_cache}/${key}.tsv" 2>/dev/null || : > "${_fc_cache}/${key}.fail"
  fi
  [ ! -f "${_fc_cache}/${key}.fail" ] || return 5
  cat "${_fc_cache}/${key}.tsv"
}
_root_of() {  # $1=régua → imprime a raiz absoluta do repo da régua (onion = este repo); rc 4 = sem raiz
  local root
  if [ "$1" = "onion" ]; then printf '%s' "${REPO}"; return 0; fi
  root="$(printf '%s' "${AGAINST_ROOTS}" | awk -F'\t' -v a="$1" '$1==a {print $2; exit}')"
  [ -n "${root}" ] || return 4
  case "${root}" in /*) ;; *) root="${REPO}/${root}" ;; esac
  printf '%s' "${root}"
}

plans=""
while IFS=$'\t' read -r tool rel against mode scope; do
  [ -n "${tool}" ] || continue
  [ -z "${TOOL_FILTER}" ] || [ "${tool}" = "${TOOL_FILTER}" ] || continue
  # Um registro por nó que declara `x_absorb_target:`. Campos em ordem fixa; vazio vira "-".
  plans="${plans}$(awk -v tool="${tool}" -v rel="${rel}" -v against="${against}" -v mode="${mode}" -v scope="${scope}" '
    function flush() {
      if (id != "" && tgt != "")
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", tool, id, tgt,
          (pcs==""?"-":pcs), (org==""?"-":org), (lic==""?"-":lic), (par==""?"-":par), (frm==""?"-":frm), rel,
          against, mode, scope
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

n_plans=0; n_incomplete=0; n_unmeasured=0; out=""
while IFS=$'\t' read -r tool id tgt pcs org lic par frm rel against mode scope; do
  [ -n "${id}" ] || continue
  n_plans=$((n_plans + 1)); why=""; unmeasured=""
  # ESTUDO NÃO É PLANO — e o modo desconhecido não vira modo normal por omissão.
  case "${mode}" in
    -) ;;
    study) n_incomplete=$((n_incomplete + 1))
      out="${out}- **${tool}** · \`${id}\` → alvo \`${tgt}\` · INCOMPLETO(estudo-nao-tem-plano)
  o grafo é ESTUDO (x_dissect_mode: study): para no N2 sem veredito, e estudo não emite plano.
  Para decidir, disseque de novo sem --study; o N3 julga e só o N4 escreve plano.
"
      continue ;;
    *) why="${why} modo-desconhecido(${mode})" ;;
  esac
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
  # RÉGUA: `onion` mede neste repo (o de sempre); outro alvo mede no repo DELE.
  target_tsv="${fc_tsv}"; target_repo="este repo"
  if [ "${against}" = "${SELF_REGUA}" ] && [ "$(_root_of "${against}")" = "${REPO}/." ]; then
    # régua = o próprio repo, sem raiz explícita: mede AQUI (o `=.` implícito), com o censo já feito.
    target_repo="${against} (este repo)"
  elif [ "${against}" != "onion" ]; then
    target_repo="${against}"
    if target_tsv="$(_fc_of "${against}")"; then :; else
      case "$?" in
        4) unmeasured="repo-do-alvo-sem-raiz: passe --against-root ${against}=<caminho>" ;;
        *) unmeasured="forge-census-nao-mediu-o-repo-do-alvo ${against}" ;;
      esac
      target_tsv=""
    fi
  fi
  # ESCOPO: o componente tem de existir (arquivo RASTREADO) no repo da régua. Sem raiz, não se mede.
  if [ "${scope}" != "-" ] && [ -z "${unmeasured}" ] && scope_root="$(_root_of "${against}")"; then
    # Os pathspecs vão JUNTOS ao ls-files (as exclusões valem sobre os positivos); escopo só de
    # exclusão (`:(exclude)…`, `:!…`, `:^…`) casaria o repo inteiro e não nomeia componente nenhum.
    _sc_list=(); _sc_pos=0
    IFS=',' read -r -a _sc_specs <<< "${scope}"
    for _sc in "${_sc_specs[@]}"; do
      _sc="$(printf '%s' "${_sc}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      [ -n "${_sc}" ] || continue
      _sc_list+=("${_sc}")
      case "${_sc}" in ':(exclude)'*|':!'*|':^'*) ;; *) _sc_pos=$((_sc_pos + 1)) ;; esac
    done
    if [ "${_sc_pos}" -eq 0 ]; then why="${why} escopo-sem-pathspec-positivo"
    else
      _sc_n="$(git -C "${scope_root}" ls-files -- "${_sc_list[@]}" 2>/dev/null | wc -l)"
      [ "${_sc_n}" -gt 0 ] || why="${why} escopo-sem-arquivo"
    fi
  fi
  case "${tgt}" in
    novo:*) measured="alvo novo — nenhuma peça existe ainda" ;;
    *) if [ -z "${unmeasured}" ]; then
         row="$(printf '%s\n' "${target_tsv}" | awk -F'\t' -v t="${tgt}" 'NR>1 && $2==t && !seen {print; seen=1}')"
         [ -n "${row}" ] || why="${why} alvo-fora-do-forge-census"
       fi ;;
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
  if [ -n "${why}" ]; then status="INCOMPLETO(${why# })"; n_incomplete=$((n_incomplete + 1))
  elif [ -n "${unmeasured}" ]; then status="NAO-MEDIDO(${unmeasured})"; n_unmeasured=$((n_unmeasured + 1))
  else status="COMPLETO"; fi
  out="${out}- **${tool}** · \`${id}\` → alvo \`${tgt}\` no repo \`${target_repo}\` (régua ${against} · escopo ${scope}) · ${status}
  peças pedidas (medidas agora pelo forge-census): ${measured:-—}
  forma: ${frm} · licença: ${lic} · origem: ${org}
  paridade: ${par}
"
done <<< "${plans}"

printf '# planos de absorção (costura dissect→forge) · %s plano(s) · %s incompleto(s) · %s não-medido(s)\n' "${n_plans}" "${n_incomplete}" "${n_unmeasured}"
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
[ "${n_unmeasured}" -eq 0 ] || exit 3
exit 0
