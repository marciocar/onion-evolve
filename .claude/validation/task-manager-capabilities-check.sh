#!/usr/bin/env bash
# =============================================================================
# task-manager-capabilities-check.sh — REGRA 103: adapter do task-manager declara TODAS as
# capacidades da interface, com fonte, e a declaração bate com o que o adapter faz
#
# O QUE   : `.claude/utils/task-manager/interface.md` carrega um bloco lido por máquina (entre
#           `<!-- capabilities:begin -->` e `<!-- capabilities:end -->`) com o vocabulário canônico:
#           capability · requirement (required|optional) · scope (remote|local) · surface (`método(`
#           ou `field:<campo>`). Cada provedor de `TaskManagerProvider` (types.md, menos `none`) tem
#           `adapters/<provedor>.capabilities.tsv` com capability · requirement · status
#           (implemented|not_implemented|unverified) · api_version · source · note. Esta guarda cobra:
#             · declaração presente por provedor; nenhuma declaração de provedor inexistente;
#             · o MESMO conjunto de capacidades da interface (nenhuma faltando, nenhuma inventada,
#               nenhuma duplicada) e o MESMO requirement;
#             · enum válido e api_version não vazia;
#             · `required` nunca `not_implemented`;
#             · `implemented` com fonte, e fonte que RESOLVE: `kg:<id-do-grafo>#<NÓ>` aponta nó que
#               existe (grafo achado pelo meta.id, nó por igualdade, nunca regex) e não é só objeção do
#               Elenxo; `adapter:<arquivo>§<trecho>` cita trecho de ≥12 caracteres que está no adapter
#               DESTE provedor; `local` só em capacidade de scope local;
#             · o vocabulário da interface é válido (sem duplicata, enum, superfície bem formada);
#             · a declaração bate com o ADAPTER: `implemented`/`unverified` exigem que o adapter DEFINA a
#               superfície (linha de código que começa pelo método, ou cabeçalho que o nomeia);
#               `not_implemented` de MÉTODO exige que ele NÃO a defina. Citação em prosa não conta.
#
# DEFEITO DATADO (SAC-63, medido em 2026-10-11, depois da Onda 1 de primárias — PR #1027):
#           (1) o CLAUDE.md prescreve "Bulk-first … Jira `/issue/bulk`, ClickUp bulk endpoints" e
#               "usar POST /rest/api/3/issue/bulk (até 50/req)" — e NENHUM adapter implementa lote: o
#               próprio jira.md diz "(não usado aqui)". O consumidor fala com `taskManager.*`, então a
#               capacidade declarada na doutrina não existe na abstração. É a classe "declara
#               capacidade que não exerce", que esta casa já nomeou como a pior (zoho-glpi-adapters,
#               C_OPCAO_B).
#           (2) a interface publicava um mapa de prioridade do Zoho "da UI, não medido contra a API",
#               no mesmo formato das colunas medidas, e o Asana como `-` — sem dizer qual célula tinha
#               fonte. A Onda 1 achou, no mesmo dia, uma afirmação sem fonte (o /search do Jira
#               "removido em maio/2025") em 5 superfícies do core: só uma rodada de pesquisa a viu,
#               nenhuma guarda. Prosa de adapter não tem campo para "ninguém mediu isto".
#           Cura: a declaração estruturada (o campo que faltava) + esta guarda (o veto).
#
# FORA DO ESCOPO / TETO (cada item é declarado, não esquecido):
#   · SUPERFÍCIE DE CAMPO (`field:priority`, `field:tags`…) é conferida só por PRESENÇA da palavra no
#     adapter: ela pega o adapter que nem menciona o campo (Zoho declarando prioridade), mas não
#     distingue LER de ESCREVER — o Linear lê labels e não as escreve. Para `not_implemented` de campo,
#     não há conferência reversa (a palavra aparece em prosa).
#   · SUPERFÍCIE DE MÉTODO é DEFINIÇÃO por forma (linha que começa por `nome(` ou cabeçalho com
#     `` `nome( ``): um cabeçalho markdown que nomeia o método sem implementá-lo passa (o zoho.md inteiro é
#     prosa em cabeçalhos), e uma CHAMADA que abre a linha conta como definição.
#   · a guarda confere que a fonte EXISTE, não que ela SUSTENTA a afirmação: um `kg:` que aponta nó real
#     mas sobre outra coisa passa. Isso é juízo (passada adversarial), não forma.
#   · `adapter:<arquivo>§<trecho>` prova que o trecho está lá, não que ele registra uma medição — e a
#     passada adversarial de 2026-10-11 achou 4 trechos que registravam medição NEGATIVA (a falha) citados
#     como prova do positivo; foram rebaixados a unverified. A guarda não distingue os dois.
#   · grafo fabricado em docs/ com o meta.id certo resolve: a forma não sabe quem escreveu o grafo.
#   · num repo DERIVADO (carimbo `.claude/.onion-version`), ref `kg:` cujo grafo não viajou não é
#     conferida — a pesquisa do core não viaja; o core a conferiu antes de publicar.
#   · porta onion-mini: leva o task-manager, não leva o lint — a guarda não roda lá, por desenho.
#
# Uso    : task-manager-capabilities-check.sh [REPO_DIR] [--format text|tsv]
#          task-manager-capabilities-check.sh --selftest
# Saída  : HARD<TAB><classe><TAB><caminho><TAB><msg> (tsv) · vazio = limpo
#          classes: vocabulario-ausente · vocabulario-invalido · provedores-ausentes · declaracao-ausente · declaracao-orfa ·
#                   cabecalho · capacidade-faltando · capacidade-inventada · duplicada · requisito-diverge ·
#                   valor-invalido · obrigatoria-nao-implementada · fonte-ausente · fonte-invalida ·
#                   fonte-nao-resolve · superficie-diverge
# Exit   : 0 = limpo · 1 = ao menos uma HARD · 2 = uso.
# =============================================================================
set -uo pipefail

FORMAT="text"; SELFTEST=0; REPO_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --selftest) SELFTEST=1; shift ;;
    -h|--help) sed -n '2,60p' "$0"; exit 0 ;;
    -*) echo "uso: $0 [REPO_DIR] [--format text|tsv] | --selftest" >&2; exit 2 ;;
    *) REPO_DIR="$1"; shift ;;
  esac
done

FOUND=0
_emit() {  # $1=classe $2=caminho relativo $3=mensagem
  FOUND=1
  if [ "${FORMAT}" = "tsv" ]; then printf 'HARD\t%s\t%s\t%s\n' "$1" "$2" "$3"
  else printf 'HARD [%s] %s: %s\n' "$1" "$2" "$3"; fi
}

# Normaliza a entrada: tira BOM e CR (um checkout com CRLF não pode virar 75 HARD de "declara
# capacidade que não exerce" — achado 13 da passada adversarial de 2026-10-11).
_norm() { LC_ALL=C sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r$//' "$1"; }

# Grafo pelo meta.id, não pelo 1º arquivo homônimo: candidatos <id>.kg.yaml fora de fixtures/ cujo
# bloco meta declara `id: <id>`. Um homônimo com outro meta.id não sombreia nem é sombreado (achado 12).
_graph_files() {  # $1=repo $2=id → caminhos, um por linha
  local f
  while IFS= read -r -d '' f; do
    awk -v want="$2" '
      /^meta:/ { inmeta = 1; next }
      inmeta && /^[^[:space:]#]/ { exit }
      inmeta && /^[[:space:]]+id:/ { v = $0; sub(/^[[:space:]]+id:[[:space:]]*/, "", v); sub(/[[:space:]]+#.*$/, "", v)
                                     gsub(/^["'"'"']|["'"'"'][[:space:]]*$/, "", v); sub(/[[:space:]]+$/, "", v)
                                     if (v == want) found = 1; exit }
      END { exit found ? 0 : 1 }' "${f}" && printf '%s\n' "${f}"
  done < <(find "$1/docs" -name "$2.kg.yaml" -not -path '*/fixtures/*' -print0 2>/dev/null)
}
# O nó existe? Igualdade de string (nunca o id interpolado num regex — achado 16), aceitando o id entre
# aspas, com comentário na linha, ou como chave que não é a 1ª do item (achado 11).
_node_in() {  # $1=arquivo $2=id
  awk -v want="$2" '
    /^[[:space:]]*(-[[:space:]]+)?id:[[:space:]]*/ { v = $0; sub(/^[[:space:]]*(-[[:space:]]+)?id:[[:space:]]*/, "", v)
      sub(/[[:space:]]+#.*$/, "", v); gsub(/^["'"'"']|["'"'"'][[:space:]]*$/, "", v); sub(/[[:space:]]+$/, "", v)
      if (v == want) { found = 1; exit } }
    END { exit found ? 0 : 1 }' "$1"
}
# A superfície de MÉTODO é DEFINIDA no adapter? Definição = linha de código que começa pelo método
# (`  async nome(`, `  nome(`) ou cabeçalho markdown que o nomeia entre crases (`### \`nome(`). Citação em
# prosa ou tabela NÃO conta — nem para provar implementação, nem para acusar not_implemented (achado 10).
_defines() {  # $1=adapter $2=surface (termina em "(")
  awk -v m="$2" '
    { l = $0; sub(/^[[:space:]]+/, "", l); sub(/^(async|private|public|static)[[:space:]]+/, "", l) }
    index(l, m) == 1 { found = 1; exit }
    /^#+[[:space:]]/ && index($0, "`" m) > 0 { found = 1; exit }
    END { exit found ? 0 : 1 }' "$1"
}

check_repo() {
  local repo="$1" tm="$1/.claude/utils/task-manager"
  [ -d "${tm}" ] || return 0
  local iface="${tm}/interface.md" types="${tm}/types.md" rel_tm=".claude/utils/task-manager"
  [ -f "${iface}" ] || return 0
  local derived=0; [ -f "${repo}/.claude/.onion-version" ] && derived=1

  # ── vocabulário da interface ───────────────────────────────────────────────
  local vocab
  vocab="$(_norm "${iface}" | awk -F'\t' '
    /<!-- capabilities:begin -->/ { on = 1; next }
    /<!-- capabilities:end -->/   { on = 0; next }
    on && /^```/ { next }
    on && NF == 4 && $1 != "capability" { print $1 "\t" $2 "\t" $3 "\t" $4 }
  ')"
  if [ -z "${vocab}" ]; then
    _emit "vocabulario-ausente" "${rel_tm}/interface.md" "bloco <!-- capabilities:begin/end --> ausente ou vazio — sem ele nenhuma declaração pode ser conferida"
    return 0
  fi
  # O vocabulário também é conferido: é ele que decide o resto (achado 17).
  local vbad
  vbad="$(awk -F'\t' '
    { if ($1 in seen) print "capacidade duplicada: " $1; seen[$1] = 1
      if ($2 != "required" && $2 != "optional") print $1 ": requirement \"" $2 "\""
      if ($3 != "remote" && $3 != "local") print $1 ": scope \"" $3 "\""
      if ($4 !~ /^[A-Za-z_][A-Za-z0-9_]*\($/ && $4 !~ /^field:[A-Za-z_][A-Za-z0-9_]*$/) print $1 ": surface \"" $4 "\"" }' <<< "${vocab}")"
  if [ -n "${vbad}" ]; then
    _emit "vocabulario-invalido" "${rel_tm}/interface.md" "bloco de capacidades com linha inválida: $(tr '\n' ';' <<< "${vbad}" | cut -c1-300)"
    return 0
  fi

  # ── provedores (types.md: TaskManagerProvider, menos none; a união pode quebrar linha até o `;`) ──
  local providers=""
  if [ -f "${types}" ]; then
    providers="$(_norm "${types}" | awk '
      /type[[:space:]]+TaskManagerProvider[[:space:]]*=/ { on = 1 }
      on { line = $0
           while (match(line, /'"'"'[a-z0-9_-]+'"'"'/)) { p = substr(line, RSTART + 1, RLENGTH - 2)
             if (p != "none") print p; line = substr(line, RSTART + RLENGTH) }
           if ($0 ~ /;/) exit }')"
  fi
  if [ -z "${providers}" ]; then
    _emit "provedores-ausentes" "${rel_tm}/types.md" "não achei 'type TaskManagerProvider = …' — sem a lista de provedores a guarda não sabe quem declara"
    return 0
  fi

  # ── declarações órfãs ──────────────────────────────────────────────────────
  local f base
  for f in "${tm}"/adapters/*.capabilities.tsv; do
    [ -f "${f}" ] || continue
    base="$(basename "${f}" .capabilities.tsv)"
    grep -qxF -- "${base}" <<< "${providers}" || \
      _emit "declaracao-orfa" "${rel_tm}/adapters/${base}.capabilities.tsv" "provedor '${base}' não existe em TaskManagerProvider (types.md)"
  done

  # ── cada provedor ──────────────────────────────────────────────────────────
  local p decl adapter rel out
  while IFS= read -r p; do
    [ -n "${p}" ] || continue
    decl="${tm}/adapters/${p}.capabilities.tsv"; adapter="${tm}/adapters/${p}.md"
    rel="${rel_tm}/adapters/${p}.capabilities.tsv"
    if [ ! -f "${decl}" ]; then
      _emit "declaracao-ausente" "${rel}" "o provedor '${p}' não declara capacidades — crie ${p}.capabilities.tsv (formato em interface.md §Capacidades)"
      continue
    fi
    # Comparação estrutural em awk: vocabulário × declaração.
    # Saída do awk separada por \x1f (US), NUNCA por TAB: TAB é espaço para o `read`, que colapsa
    # campos vazios consecutivos e desloca os seguintes.
    out="$(_norm "${decl}" | awk -F'\t' -v VOCAB="${vocab}" -v S=$'\x1f' '
      BEGIN {
        n = split(VOCAB, L, "\n")
        for (i = 1; i <= n; i++) { split(L[i], c, "\t"); req[c[1]] = c[2]; scope[c[1]] = c[3]; surf[c[1]] = c[4]; order[i] = c[1] }
        nv = n; hdr = 0
      }
      /^#/ || /^[[:space:]]*$/ { next }
      !hdr {
        hdr = 1
        if ($0 != "capability\trequirement\tstatus\tapi_version\tsource\tnote") print "cabecalho" S "cabeçalho diferente de capability<TAB>requirement<TAB>status<TAB>api_version<TAB>source<TAB>note"
        next
      }
      {
        if (NF != 6) { print "valor-invalido" S "linha " NR " tem " NF " colunas (esperado 6, separadas por TAB)"; next }
        cap = $1
        if (cap in seen) { print "duplicada" S cap " aparece mais de uma vez"; next }
        seen[cap] = 1
        if (!(cap in req)) { print "capacidade-inventada" S cap " não existe no vocabulário de interface.md"; next }
        if ($2 != "required" && $2 != "optional") print "valor-invalido" S cap ": requirement \"" $2 "\" fora de required|optional"
        else if ($2 != req[cap]) print "requisito-diverge" S cap ": declarada " $2 ", a interface diz " req[cap]
        if ($3 != "implemented" && $3 != "not_implemented" && $3 != "unverified") print "valor-invalido" S cap ": status \"" $3 "\" fora de implemented|not_implemented|unverified"
        if ($4 ~ /^[[:space:]]*$/) print "valor-invalido" S cap ": api_version vazia"
        if (req[cap] == "required" && $3 == "not_implemented") print "obrigatoria-nao-implementada" S cap " é required e está not_implemented"
        if ($3 == "implemented" && ($5 == "" || $5 == "-")) print "fonte-ausente" S cap " está implemented sem fonte (kg:…#NÓ, adapter:…§trecho ou local)"
        # linha para as conferências que awk não faz (fonte e superfície): cap, status, source, scope, surface
        print "@" S cap S $3 S $5 S scope[cap] S surf[cap]
      }
      END {
        if (!hdr) print "cabecalho" S "declaração vazia"
        for (i = 1; i <= nv; i++) if (!(order[i] in seen)) print "capacidade-faltando" S order[i] " (" req[order[i]] ") não está declarada"
      }
    ')"

    local cls msg cap st src sc sf ref g gf gfs node anchor afile tok refs strong
    while IFS=$'\x1f' read -r cls msg st src sc sf; do
      [ -n "${cls}" ] || continue
      if [ "${cls}" != "@" ]; then _emit "${cls}" "${rel}" "${msg}"; continue; fi
      cap="${msg}"; strong=0
      # ── fonte ── (read -ra, nunca expansão sem aspas: o trecho citado pode ter `*`)
      if [ -n "${src}" ] && [ "${src}" != "-" ]; then
        IFS=';' read -ra refs <<< "${src}"
        for ref in "${refs[@]}"; do
          case "${ref}" in
            kg:*'#'*)
              g="${ref#kg:}"; node="${g#*#}"; g="${g%%#*}"
              if ! [[ "${g}" =~ ^[A-Za-z0-9._-]+$ && "${node}" =~ ^[A-Za-z0-9_]+$ ]]; then
                _emit "fonte-invalida" "${rel}" "${cap}: ref kg: fora da forma kg:<id-do-grafo>#<NÓ> (só [A-Za-z0-9_] no nó): ${ref}"; continue
              fi
              # objeção do Elenxo LIMITA a afirmação; sozinha nunca a prova (achado 17)
              case "${node}" in E_ELENXO_*) : ;; *) strong=1 ;; esac
              gfs="$(_graph_files "${repo}" "${g}")"
              if [ -z "${gfs}" ]; then
                [ "${derived}" -eq 1 ] || _emit "fonte-nao-resolve" "${rel}" "${cap}: grafo '${g}' não existe (procurei ${g}.kg.yaml com meta.id ${g} em docs/)"
              else
                local hit=0
                while IFS= read -r gf; do _node_in "${gf}" "${node}" && { hit=1; break; }; done <<< "${gfs}"
                [ "${hit}" -eq 1 ] || _emit "fonte-nao-resolve" "${rel}" "${cap}: nó '${node}' não existe no grafo '${g}'"
              fi ;;
            adapter:*'§'*)
              afile="${ref#adapter:}"; anchor="${afile#*§}"; afile="${afile%%§*}"
              # o trecho é do PRÓPRIO adapter (ou de um companheiro <p>-*.md), não de outro provedor (achado 15)
              case "${afile}" in "${p}.md"|"${p}"-*.md) : ;; *)
                _emit "fonte-invalida" "${rel}" "${cap}: adapter:${afile} não é o adapter deste provedor (${p}.md ou ${p}-*.md)"; continue ;;
              esac
              # trecho vazio, curto ou igual à superfície casa qualquer coisa (achado 14)
              if [ "${#anchor}" -lt 12 ] || [ "${anchor}" = "${sf}" ]; then
                _emit "fonte-invalida" "${rel}" "${cap}: trecho de adapter: curto demais para ser fonte (mínimo 12 caracteres, diferente da superfície): '${anchor}'"; continue
              fi
              strong=1
              if [ ! -f "${tm}/adapters/${afile}" ]; then
                _emit "fonte-nao-resolve" "${rel}" "${cap}: adapter '${afile}' não existe"
              elif ! grep -qF -- "${anchor}" "${tm}/adapters/${afile}"; then
                _emit "fonte-nao-resolve" "${rel}" "${cap}: o trecho citado não está em adapters/${afile}: ${anchor}"
              fi ;;
            local)
              strong=1
              [ "${sc}" = "local" ] || _emit "fonte-invalida" "${rel}" "${cap}: 'local' só vale para capacidade de scope local (esta é ${sc})" ;;
            *) _emit "fonte-invalida" "${rel}" "${cap}: fonte '${ref}' fora das formas kg:<grafo>#<NÓ> · adapter:<arquivo>§<trecho> · local" ;;
          esac
        done
        if [ "${st}" = "implemented" ] && [ "${strong}" -eq 0 ]; then
          _emit "fonte-invalida" "${rel}" "${cap}: implemented só com objeção do Elenxo (E_ELENXO_*) como fonte — objeção limita, não prova"
        fi
      fi
      # ── superfície × adapter ──
      [ -f "${adapter}" ] || { [ "${st}" = "not_implemented" ] || _emit "superficie-diverge" "${rel}" "${cap}: declarada ${st}, mas adapters/${p}.md não existe"; continue; }
      case "${sf}" in
        field:*)
          tok="${sf#field:}"
          if [ "${st}" != "not_implemented" ] && ! grep -qw -- "${tok}" "${adapter}"; then
            _emit "superficie-diverge" "${rel}" "${cap}: declarada ${st}, mas o campo '${tok}' não aparece em adapters/${p}.md"
          fi ;;
        *)
          if [ "${st}" = "not_implemented" ]; then
            _defines "${adapter}" "${sf}" && _emit "superficie-diverge" "${rel}" "${cap}: declarada not_implemented, mas adapters/${p}.md DEFINE '${sf}' — a declaração mente sobre o adapter"
          else
            _defines "${adapter}" "${sf}" || _emit "superficie-diverge" "${rel}" "${cap}: declarada ${st}, mas adapters/${p}.md não define '${sf}' (linha de código ou cabeçalho) — declara capacidade que o adapter não exerce"
          fi ;;
      esac
    done <<< "${out}"
  done <<< "${providers}"
}

# =============================================================================
run_selftest() {
  local tmp; tmp="$(mktemp -d)"; local fails=0 out total=27
  local T="${tmp}/.claude/utils/task-manager" A="${tmp}/.claude/utils/task-manager/adapters"
  # captura em VAR e here-string — nunca `produtor | grep -q` (SIGPIPE sob pipefail).
  _run() { out="$(bash "$0" "${tmp}" --format tsv 2>/dev/null)"; }
  _has() { command grep -q -- "$1" <<< "${out}"; }
  _ok() { echo "  ✅ $1"; }
  _ko() { echo "  ✗ $1"; fails=$((fails+1)); }
  _reset() {
    rm -rf "${tmp}/.claude" "${tmp}/docs"; mkdir -p "${A}" "${tmp}/docs/evolution/research/g"
    printf '# Interface\n\n<!-- capabilities:begin -->\n```tsv\ncapability\trequirement\tscope\tsurface\nitem.create\trequired\tremote\tcreateTask(\nbulk.create\toptional\tremote\tbulkCreate(\npriority.set\toptional\tremote\tfield:priority\nid.validate\trequired\tlocal\tvalidateTaskId(\n```\n<!-- capabilities:end -->\n' > "${T}/interface.md"
    printf "type TaskManagerProvider = 'alpha' | 'none';\n" > "${T}/types.md"
    printf '# Alpha\n\n  async createTask(input) { /* MEDIDO AO VIVO 2026-10-02: 201 */ }\n  validateTaskId(id) { }\n  priority: map(input.priority)\n' > "${A}/alpha.md"
    printf 'meta:\n  id: gid\nnodes:\n  - id: E_OK\n    node_type: evidence\n' > "${tmp}/docs/evolution/research/g/gid.kg.yaml"
    _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_OK\t' 'bulk.create\toptional\tnot_implemented\tv1\t-\t' \
          'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'
  }
  _decl() { { printf '# declaração\ncapability\trequirement\tstatus\tapi_version\tsource\tnote\n'; local l; for l in "$@"; do printf "${l}\n"; done; } > "${A}/alpha.capabilities.tsv"; }

  # (i) o caso HONESTO: tudo declarado, fontes resolvem, superfícies batem => cala
  _reset; _run
  if [ -z "${out}" ]; then _ok "(i) declaração completa e honesta cala"; else _ko "(i) honesto acusou: ${out}"; fi

  # (ii) o DEFEITO VERBATIM (1): lote declarado implementado, com fonte real do provedor, e o adapter sem bulkCreate
  _reset; _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_OK\t' 'bulk.create\toptional\timplemented\tv1\tkg:gid#E_OK\taté 50' \
                'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if _has $'^HARD\tsuperficie-diverge\t.*bulk.create: declarada implemented'; then _ok "(ii) capacidade declarada que o adapter não exerce reprova (o defeito verbatim do bulk)"; else _ko "(ii) ${out}"; fi

  # (iii) o DEFEITO VERBATIM (2): mapa 'da UI, não medido' declarado como implementado, sem fonte
  _reset; _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_OK\t' 'bulk.create\toptional\tnot_implemented\tv1\t-\t' \
                'priority.set\toptional\timplemented\tv1\t-\tda UI, não medido' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if _has $'^HARD\tfonte-ausente\t.*priority.set'; then _ok "(iii) implemented sem fonte reprova (o mapa 'da UI, não medido')"; else _ko "(iii) ${out}"; fi

  # (iv) declaração ausente para provedor existente
  _reset; rm -f "${A}/alpha.capabilities.tsv"; _run
  if _has $'^HARD\tdeclaracao-ausente\t.*alpha.capabilities.tsv'; then _ok "(iv) provedor sem declaração reprova"; else _ko "(iv) ${out}"; fi

  # (v) capacidade da interface faltando
  _reset; _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_OK\t' 'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if _has $'^HARD\tcapacidade-faltando\t.*bulk.create'; then _ok "(v) capacidade faltando reprova"; else _ko "(v) ${out}"; fi

  # (vi) capacidade inventada fora da interface
  _reset; _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_OK\t' 'bulk.create\toptional\tnot_implemented\tv1\t-\t' \
                'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t' 'item.teleport\toptional\tunverified\tv1\t-\t'; _run
  if _has $'^HARD\tcapacidade-inventada\t.*item.teleport'; then _ok "(vi) capacidade inventada reprova"; else _ko "(vi) ${out}"; fi

  # (vii) required declarada not_implemented
  _reset; _decl 'item.create\trequired\tnot_implemented\tv1\t-\t' 'bulk.create\toptional\tnot_implemented\tv1\t-\t' \
                'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if _has $'^HARD\tobrigatoria-nao-implementada\t.*item.create'; then _ok "(vii) required not_implemented reprova"; else _ko "(vii) ${out}"; fi

  # (viii) requirement rebaixado na declaração
  _reset; _decl 'item.create\toptional\timplemented\tv1\tkg:gid#E_OK\t' 'bulk.create\toptional\tnot_implemented\tv1\t-\t' \
                'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if _has $'^HARD\trequisito-diverge\t.*item.create'; then _ok "(viii) requirement diferente da interface reprova"; else _ko "(viii) ${out}"; fi

  # (ix) enum inválido e api_version vazia
  _reset; _decl 'item.create\trequired\tdone\tv1\tkg:gid#E_OK\t' 'bulk.create\toptional\tnot_implemented\t \t-\t' \
                'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if _has $'^HARD\tvalor-invalido\t.*status "done"' && _has $'^HARD\tvalor-invalido\t.*bulk.create: api_version vazia'; then _ok "(ix) status fora do enum e api_version vazia reprovam"; else _ko "(ix) ${out}"; fi

  # (x) fonte kg: que aponta nó inexistente
  _reset; _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_INVENTADO\t' 'bulk.create\toptional\tnot_implemented\tv1\t-\t' \
                'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if _has $'^HARD\tfonte-nao-resolve\t.*E_INVENTADO'; then _ok "(x) kg: com nó inexistente reprova"; else _ko "(x) ${out}"; fi

  # (xi) fonte adapter: com trecho que não está no adapter; e o trecho que está cala
  _reset; _decl 'item.create\trequired\timplemented\tv1\tadapter:alpha.md§MEDIDO AO VIVO 2026-09-99\t' 'bulk.create\toptional\tnot_implemented\tv1\t-\t' \
                'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  local okA=0; _has $'^HARD\tfonte-nao-resolve\t.*trecho citado' && okA=1
  _decl 'item.create\trequired\timplemented\tv1\tadapter:alpha.md§MEDIDO AO VIVO 2026-10-02\t' 'bulk.create\toptional\tnot_implemented\tv1\t-\t' \
        'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if [ "${okA}" -eq 1 ] && [ -z "${out}" ]; then _ok "(xi) adapter: com trecho ausente reprova, com trecho presente cala"; else _ko "(xi) okA=${okA} ${out}"; fi

  # (xii) not_implemented com o método PRESENTE no adapter (a declaração mente para baixo)
  _reset; printf '  async bulkCreate(inputs) { }\n' >> "${A}/alpha.md"; _run
  if _has $'^HARD\tsuperficie-diverge\t.*bulk.create: declarada not_implemented'; then _ok "(xii) not_implemented com o método no adapter reprova"; else _ko "(xii) ${out}"; fi

  # (xiii) campo declarado sem a palavra no adapter (o Zoho declarando prioridade)
  _reset; printf '# Alpha\n\n  async createTask(input) { /* MEDIDO AO VIVO 2026-10-02: 201 */ }\n  validateTaskId(id) { }\n' > "${A}/alpha.md"; _run
  if _has $'^HARD\tsuperficie-diverge\t.*campo .priority.'; then _ok "(xiii) campo declarado que o adapter nem menciona reprova"; else _ko "(xiii) ${out}"; fi

  # (xiv) declaração órfã (provedor que não existe em types.md)
  _reset; cp "${A}/alpha.capabilities.tsv" "${A}/beta.capabilities.tsv"; _run
  if _has $'^HARD\tdeclaracao-orfa\t.*beta.capabilities.tsv'; then _ok "(xiv) declaração de provedor inexistente reprova"; else _ko "(xiv) ${out}"; fi

  # (xv) repo DERIVADO: kg: cujo grafo não viajou cala; no core o mesmo grafo ausente reprova
  _reset; rm -rf "${tmp}/docs"; _run
  local okC=0; _has $'^HARD\tfonte-nao-resolve\t.*grafo .gid.' && okC=1
  printf 'role: adopted\n' > "${tmp}/.claude/.onion-version"; _run
  if [ "${okC}" -eq 1 ] && [ -z "${out}" ]; then _ok "(xv) grafo ausente reprova no core e cala no derivado"; else _ko "(xv) okC=${okC} ${out}"; fi

  # (xvi) linha duplicada
  _reset; _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_OK\t' 'item.create\trequired\timplemented\tv1\tkg:gid#E_OK\t' 'bulk.create\toptional\tnot_implemented\tv1\t-\t' \
                'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if _has $'^HARD\tduplicada\t.*item.create'; then _ok "(xvi) capacidade duplicada reprova"; else _ko "(xvi) ${out}"; fi

  # (xvii) vocabulário ausente na interface => HARD, nunca verde vazio
  _reset; printf '# Interface sem bloco\n' > "${T}/interface.md"; _run
  if _has $'^HARD\tvocabulario-ausente\t'; then _ok "(xvii) interface sem o bloco de capacidades reprova (não passa verde vazio)"; else _ko "(xvii) ${out}"; fi

  # (xviii) 'local' em capacidade remota, e fonte em forma desconhecida
  _reset; _decl 'item.create\trequired\timplemented\tv1\tlocal\t' 'bulk.create\toptional\tnot_implemented\tv1\thttps://x\t' \
                'priority.set\toptional\tunverified\tv1\t-\t' 'id.validate\trequired\timplemented\tv1\tlocal\t'; _run
  if _has $'^HARD\tfonte-invalida\t.*item.create: .local. só vale' && _has $'^HARD\tfonte-invalida\t.*https://x'; then _ok "(xviii) local em capacidade remota e fonte fora das formas reprovam"; else _ko "(xviii) ${out}"; fi

  # ── Casos da passada adversarial de 2026-10-11 (achados 10 a 17) ─────────────
  local H='bulk.create\toptional\tnot_implemented\tv1\t-\t' P='priority.set\toptional\tunverified\tv1\t-\t' V='id.validate\trequired\timplemented\tv1\tlocal\t'

  # (xix) trecho de adapter: vazio, curto ou igual à superfície não é fonte
  _reset; _decl 'item.create\trequired\timplemented\tv1\tadapter:alpha.md§\t' "${H}" "${P}" "${V}"; _run
  local okE=0; _has $'^HARD\tfonte-invalida\t.*item.create: trecho de adapter: curto' && okE=1
  _decl 'item.create\trequired\timplemented\tv1\tadapter:alpha.md§createTask(\t' "${H}" "${P}" "${V}"; _run
  if [ "${okE}" -eq 1 ] && _has $'^HARD\tfonte-invalida\t.*item.create: trecho de adapter: curto'; then _ok "(xix) trecho de adapter vazio ou igual à superfície não é fonte"; else _ko "(xix) okE=${okE} ${out}"; fi

  # (xx) adapter: de OUTRO provedor não é fonte deste
  _reset; printf '# Beta\nMEDIDO AO VIVO 2026-10-02: 201\n' > "${A}/beta.md"
  _decl 'item.create\trequired\timplemented\tv1\tadapter:beta.md§MEDIDO AO VIVO 2026-10-02\t' "${H}" "${P}" "${V}"; _run
  if _has $'^HARD\tfonte-invalida\t.*adapter:beta.md não é o adapter deste provedor'; then _ok "(xx) trecho de adapter de outro provedor reprova"; else _ko "(xx) ${out}"; fi

  # (xxi) nó com curinga de regex não passa por âncora
  _reset; _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_.*\t' "${H}" "${P}" "${V}"; _run
  if _has $'^HARD\tfonte-invalida\t.*ref kg: fora da forma'; then _ok "(xxi) kg: com curinga no nó reprova (igualdade, nunca regex)"; else _ko "(xxi) ${out}"; fi

  # (xxii) método só CITADO em prosa: não prova implementado, e não acusa not_implemented
  _reset; printf '# Alpha\n\nEste adapter NÃO implementa `bulkCreate(` — veja a declaração.\n  async createTask(input) { /* MEDIDO AO VIVO 2026-10-02: 201 */ }\n  validateTaskId(id) { }\n  priority: map(input.priority)\n' > "${A}/alpha.md"; _run
  local okP=0; [ -z "${out}" ] && okP=1
  _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_OK\t' 'bulk.create\toptional\tunverified\tv1\t-\t' "${P}" "${V}"; _run
  if [ "${okP}" -eq 1 ] && _has $'^HARD\tsuperficie-diverge\t.*bulk.create: declarada unverified, mas .* não define'; then _ok "(xxii) citação em prosa cala no not_implemented e não prova implementação"; else _ko "(xxii) okP=${okP} ${out}"; fi

  # (xxiii) CRLF e BOM na declaração honesta calam (o defeito é de checkout, não de declaração)
  _reset; LC_ALL=C sed -i -e '1s/^/\xEF\xBB\xBF/' -e 's/$/\r/' "${A}/alpha.capabilities.tsv" "${T}/interface.md"; _run
  if [ -z "${out}" ]; then _ok "(xxiii) CRLF e BOM na declaração e na interface honestas calam"; else _ko "(xxiii) ${out}"; fi

  # (xxiv) objeção do Elenxo como fonte única de implemented reprova
  _reset; printf '  - id: E_ELENXO_X\n    node_type: evidence\n' >> "${tmp}/docs/evolution/research/g/gid.kg.yaml"
  _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_ELENXO_X\t' "${H}" "${P}" "${V}"; _run
  if _has $'^HARD\tfonte-invalida\t.*objeção do Elenxo'; then _ok "(xxiv) objeção do Elenxo sozinha não prova implemented"; else _ko "(xxiv) ${out}"; fi

  # (xxv) grafo HOMÔNIMO com outro meta.id não sombreia o verdadeiro; id entre aspas e com comentário resolve
  _reset; mkdir -p "${tmp}/docs/a"; printf 'meta:\n  id: outro\nnodes:\n  - id: E_NADA\n' > "${tmp}/docs/a/gid.kg.yaml"
  printf '  - id: "E_ASPAS"   # comentário\n    node_type: evidence\n' >> "${tmp}/docs/evolution/research/g/gid.kg.yaml"
  _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_OK;kg:gid#E_ASPAS\t' "${H}" "${P}" "${V}"; _run
  local okH=0; [ -z "${out}" ] && okH=1
  _decl 'item.create\trequired\timplemented\tv1\tkg:gid#E_NADA\t' "${H}" "${P}" "${V}"; _run   # E_NADA só existe no homônimo
  if [ "${okH}" -eq 1 ] && _has $'^HARD\tfonte-nao-resolve\t.*E_NADA'; then _ok "(xxv) homônimo com outro meta.id é ignorado; id entre aspas e com comentário resolve"; else _ko "(xxv) okH=${okH} ${out}"; fi

  # (xxvi) vocabulário da interface inválido (duplicada, superfície vazia) reprova antes de tudo
  _reset; printf '# I\n<!-- capabilities:begin -->\n```tsv\ncapability\trequirement\tscope\tsurface\nitem.create\trequired\tremote\tcreateTask(\nitem.create\trequired\tremote\tcreateTask(\nbulk.create\toptional\tremote\t(\n```\n<!-- capabilities:end -->\n' > "${T}/interface.md"; _run
  if _has $'^HARD\tvocabulario-invalido\t.*capacidade duplicada: item.create' && _has $'^HARD\tvocabulario-invalido\t.*surface "("'; then _ok "(xxvi) vocabulário com duplicata ou superfície inválida reprova"; else _ko "(xxvi) ${out}"; fi

  # (xxvii) união de provedores em várias linhas
  _reset; printf "type TaskManagerProvider =\n  | 'alpha'\n  | 'gamma'\n  | 'none';\n" > "${T}/types.md"; _run
  if _has $'^HARD\tdeclaracao-ausente\t.*gamma.capabilities.tsv' && ! _has 'provedores-ausentes'; then _ok "(xxvii) união de provedores em várias linhas é lida até o ;"; else _ko "(xxvii) ${out}"; fi

  rm -rf "${tmp}"; echo "  selftest: $((total-fails))/${total} verdes"
  [ "${fails}" -eq 0 ] && return 0 || return 1
}

[ "${SELFTEST}" -eq 1 ] && { run_selftest; exit $?; }
[ -n "${REPO_DIR}" ] || REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
check_repo "${REPO_DIR}"
[ "${FOUND}" -eq 0 ] && exit 0 || exit 1
