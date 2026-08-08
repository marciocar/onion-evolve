#!/usr/bin/env bash
# kg-verification-coverage.sh — REGRA 49: nó `plane: PROD` de alto impacto carrega verificação.
#
# A PERGUNTA: dos nós que AFIRMAM COISAS SOBRE PRODUÇÃO e cujo erro custa caro
# (`plane: PROD` + `impact >= 4` + status vivo), quantos nunca foram medidos contra o vivo?
#
# ═══ POR QUE EXISTE ═══
# O `kg-radar.sh` DETECTA frescor (STALE-MISSING/STALE-OLD/UNANCHORED) e PARA AÍ — e o faz como
# "⚠ atenção, NÃO reprova". Consequência medida em 2026-08-02: o passivo pode CRESCER SEM LIMITE.
# São 53 nós vivos, `plane: PROD`, `impact >= 4`, SEM NENHUM `verified_at` — afirmando coisas sobre
# produção sem que ninguém jamais tenha medido.
#
# O CASO FUNDADOR (docs/../meta/kg-freshness.md:34): `C_ancestor_cap_zeroes_floors` afirmava em
# `plane: PROD` que os floors de memória tinham "proteção efetiva ZERO" — FALSO desde 2026-07-26.
# Carregava `verified_against` e `verified_at` do próprio dia: os três vereditos passavam e o radar
# ficava em silêncio. Um nó `impact: 5` mentindo com carimbo do dia, invisível a TODO mecanismo.
#
# ═══ O QUE ESTE GATE FAZ, E O QUE NÃO FAZ (limite honesto, na cara) ═══
# FAZ: garante que nó novo de alto impacto sobre PROD NASÇA com carimbo, e impede o passivo de crescer.
# NÃO FAZ: não checa se o carimbo é VERDADE — só que existe. Igual à REGRA 42, que declara o mesmo
#          limite. Logo ELE NÃO PEGA O CASO FUNDADOR. E isso não é falha: é a divisão correta —
#          o GATE cria a cadência, o WORKER (`/meta:kg-freshness`) testa a verdade contra o vivo.
#          Nenhum script determinístico sabe se `memory.min=402653184` contradiz um label.
#
# ═══ O GATILHO, e é o ponto do desenho ═══
# Este gate NUNCA diz "rode o /meta:kg-freshness". Ele torna RODAR o kg-freshness a ÚNICA forma de
# diminuir o número: para tirar um nó do baseline, você tem de medi-lo. A cadência vem do trabalho
# de reduzir um número que está no CI — RESÍDUO MATERIAL AUDITADO POR TERCEIRO, DESACOPLADO DO ATOR.
# É a única propriedade que sobreviveu a todos os replays de 2026-08-02 (4 de 4 guardas que pegaram).
#
# ═══ A CATRACA (doutrina da casa: REGRA 28/29/42) ═══
#   · passivo existente vai para BASELINE VERSIONADO e é TOLERADO (SOFT);
#   · nó NOVO fora do baseline sem carimbo é HARD;
#   · o baseline SÓ PODE ENCOLHER — acrescentar path é REGRESSÃO (HARD);
#   · e ENCOLHER SÓ VALE POR MEDIÇÃO — sair do escopo por reetiqueta é FUGA (HARD).
#   A métrica de saúde é o BASELINE DIMINUINDO, não o gate passando.
#
# ⚠️ O FAIL-OPEN QUE ESTA CATRACA TINHA — reproduzido em 2026-08-07, curado em 2026-08-08.
#   Bastava trocar UM nó `plane: PROD` / `impact>=4` de `confirmed` para `drifted`, SEM medir nada
#   e sem escrever uma linha de evidência, e o gate caía de 48 para 47 dizendo:
#       [OBSOLETA] entrada OBSOLETA (no ja carimbado ou removido) — remova do baseline
#   O gate AFIRMAVA um carimbo que não existia. Duas raízes, e as duas eram de desenho:
#     1. o predicado de escopo era ALLOWLIST (`st == "open" || st == "confirmed"`), em DUAS cópias.
#        `drifted` e `unverifiable` NASCERAM em 2026-08-06 como saída do `/meta:kg-freshness` — o
#        enum cresceu POR BAIXO do predicado. Allowlist quebra quando o enum cresce; denylist não.
#     2. o `OBSOLETA` não distinguia nó REMOVIDO de nó REETIQUETADO — e essa distinção É a catraca.
#   Sem isso, a única propriedade que funda a REGRA 49 ("a única forma de diminuir o número é MEDIR")
#   tinha porta dos fundos aberta, e ela se abria com um `sed`.
#
# ⚠️ MEIA-VIDA POR CLASSE — GATED, deliberadamente fora daqui.
#   Medido 2026-08-02: nós com `verified_at` VENCIDO (>30d) = ZERO. A doutrina do KG tem 29 dias;
#   nada teve tempo de envelhecer. Regra de expiração sobre conjunto vazio é cerimônia elegante.
#   GATILHO PARA ABRIR: >=20 nós no escopo com `verified_at` mais velho que 30 dias. Aí a classe
#   nasce com dado real. O desenho (derivar a classe do `trace:`/`verified_against:`, sem tocar a
#   gramática) está em docs/analysis/onion-adr-kg-halflife-2026-08.md.
#
# Uso : bash .claude/validation/kg-verification-coverage.sh [<repo_root>] [--emit-baseline] [--format tsv]
# SEPARADORES (invariante, declarado UMA vez): registro INTERNO usa \037 (US); a SAIDA usa \t
#   porque e contrato externo — lint-artifacts.sh agrega a classe PASSIVO por ele. TAB NUNCA
#   volta para dentro: e IFS-whitespace, runs colapsam e campo vazio SOME, deslocando o resto
#   (selftests (t) e (t2)).
# TSV : sev<TAB>tag<TAB>path<TAB>msg  (mesmo contrato do kg-provenance-coverage.sh, para o lint
#       agregar a classe PASSIVO numa linha só — dezenas de linhas iguais afogam o acionável)
# Exit: 0 = sem HARD · 1 = HARD presente · 2 = erro de uso
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EMIT=0; FMT=human
while [ $# -gt 0 ]; do
  case "$1" in
    --emit-baseline) EMIT=1 ;;
    --format)        FMT="${2:-human}"; shift ;;
    -*)              printf 'uso: %s [<repo_root>] [--emit-baseline] [--format tsv]\n' "$0" >&2; exit 2 ;;
    *)               [ -d "$1" ] && REPO_ROOT="$(cd "$1" && pwd)" ;;
  esac
  shift
done
BASELINE="${REPO_ROOT}/.claude/validation/kg-verification-baseline.txt"

# emissor único: em TSV o lint agrega; em human o operador lê direto
emit() { # $1=sev $2=tag $3=path $4=msg
  if [ "${FMT}" = "tsv" ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
  elif [ "$1" = "HARD" ]; then  printf 'VIOLATION: %s: [kg-verificacao/%s] %s\n' "$3" "$2" "$4"
  else                          printf 'SOFT: %s: [kg-verificacao/%s] %s\n' "$3" "$2" "$4"; fi
}

cd "${REPO_ROOT}" || exit 2

# ══ O PREDICADO DE ESCOPO — DENYLIST, SITE ÚNICO ═══════════════════════════════════════════════
# Era ALLOWLIST em DUAS cópias (ver o bloco do fail-open no cabeçalho). Agora existe UM literal, e
# ele é o único lugar do repo que decide o que a REGRA 49 enxerga.
#
# A denylist tem exatamente DOIS estados, e são os dois em que o nó DEIXA DE AFIRMAR sobre produção:
#   `superseded` — outro nó carrega a verdade agora;  `refuted` — a afirmação caiu.
# `open`, `confirmed`, `done`, `drifted` e `unverifiable` PERMANECEM no escopo. `drifted` mais que
# todos: é justamente o estado em que a reconciliação é DEVIDA, e era por onde a fuga passava.
#
# CUSTO MEDIDO no corpus real antes de escrever (PROD + impact>=4 + sem carimbo):
#   allowlist antiga: 43 confirmed + 5 open                       = 48
#   denylist nova   : os mesmos 48 + 0 drifted + 0 unverifiable + 0 done = 48
# A porta fecha SEM mexer no número — o que é o teste de que isto é cura, e não aperto disfarçado.
SCOPE_PREDICATE='
function inScope(plane, imp, st, ver) {
  return (plane == "PROD" && imp+0 >= 4 && ver == "" && st != "superseded" && st != "refuted")
}'

# ══ O UNIVERSE — UMA passada, TODOS os nós, TODOS os campos ════════════════════════════════════
# Antes eram DUAS varreduras idênticas (`scan` e `scan_named`) diferindo só no hash da saída — a
# mesma família de duplicação que deixou a allowlist em dois lugares. Agora os arquivos são lidos
# UMA vez e todo o resto é filtro sobre este TSV. E o guarda de direção PRECISA do universo inteiro,
# inclusive dos nós FORA do escopo: é exatamente a SAÍDA do escopo que ele julga.
#
# ⚠️ O flush é no DELIMITADOR do nó (`- id:` / EOF), NUNCA num campo. Erro real de 2026-08-02: a
# primeira medição fechava o nó no `label:` e contou 64 onde eram 53 — onze nós, como
# `C_COEVOLVE_VALUE` em onion-identity-2026-07.kg.yaml, têm `verified_at:` DEPOIS do `label:`, e o
# scanner lia o nó pela METADE, via `ver=""` e acusava falta de carimbo em nó carimbado. Instrumento
# que lê estado PARCIAL e reporta como FATO é `declarado != verificado` dentro do próprio medidor.
UNIVERSE=""; UNIVERSE_LOADED=0
load_universe() {
  [ "${UNIVERSE_LOADED}" -eq 1 ] && return 0
  local f
  UNIVERSE="$(for f in $(git ls-files '*.kg.yaml' 2>/dev/null | grep -v '/fixtures/'); do
    awk -v F="$f" '
      function flush(   ) {
        if (id != "") printf "%s\037%s\037%s\037%s\037%s\037%s\n", F, id, plane, imp, st, ver
        id=""; plane=""; imp=0; ver=""; st=""
      }
      /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ { flush(); id=$3; next }
      /^[[:space:]]*plane:[[:space:]]*/           { plane=$2; next }
      /^[[:space:]]*impact:[[:space:]]*/          { imp=$2+0;  next }
      /^[[:space:]]*verified_at:[[:space:]]*/     { ver=$2;    next }
      /^[[:space:]]*status:[[:space:]]*/          { st=$2;     next }
      END { flush() }
    ' "$f"
  done)"
  UNIVERSE_LOADED=1
}

# `path::sha1(id)\037id` — registro INTERNO, separado por US (\037) e nao por TAB. O irmao
# `resolve_key` foi corrigido no mesmo diff e este ficou para tras: comentario que descreve o
# formato errado e a semente do proximo parser errado. A CHAVE VERSIONADA nunca carrega o id cru.
# POR QUÊ (a REGRA 36 pegou isto na 1ª rodada, 2026-08-02): ids de nó carregam nome de adotante, e
# ESTE BASELINE VIAJA na superfície vendorizada — seria vazamento cross-tenant por adoção. O path já
# é público (está no repo); o id não precisa estar. O hash mantém a identidade estável sem publicar
# o nome. O id anda JUNTO em memória, só para a MENSAGEM (que não é versionada) poder nomear o nó —
# num corpus de 881 nós, "o arquivo tem problema" é inacionável.
scope_pairs() {
  load_universe
  printf '%s\n' "${UNIVERSE}" \
    | awk -F'\037' "${SCOPE_PREDICATE}"' inScope($3, $4, $5, $6) { printf "%s\037%s\n", $1, $2 }' \
    | while IFS=$'\037' read -r p id; do
        [ -n "${id}" ] || continue
        printf '%s::%s\037%s\n' "${p}" "$(printf '%s' "${id}" | sha1sum | cut -c1-12)" "${id}"
      done | sort -u
}

# resolve uma CHAVE do baseline contra o vivo → "id\037plane\037imp\037st\037ver" (US, nao TAB), ou vazio se o
# nó não existe mais. O hash aqui é LAZY: só roda quando há entrada FORA do escopo. No estado
# saudável (baseline == escopo) o custo é ZERO.
resolve_key() { # $1 = path::hash
  load_universe
  local p="${1%%::*}" h="${1##*::}"
  printf '%s\n' "${UNIVERSE}" | awk -F'\037' -v P="${p}" '$1 == P' \
    | while IFS=$'\037' read -r _f id plane imp st ver; do
        [ "$(printf '%s' "${id}" | sha1sum | cut -c1-12)" = "${h}" ] || continue
        printf '%s\037%s\037%s\037%s\037%s\n' "${id}" "${plane}" "${imp}" "${st}" "${ver}"
      done | head -1
}

# ══ A ARESTA QUE JUSTIFICA A SAÍDA — e as três coisas que ela NÃO pode aceitar ═════════════════
# A 1ª versão casava `(ef == ID || eto == ID)` com o tipo DERIVADO do status. O Elenxo desta branch
# a derrubou com três rotas, duas delas medidas no corpus REAL e sem forjar uma linha:
#   · DIREÇÃO — um nó que REFUTA outro ganhava passe livre para se declarar `refuted`. OITO das 48
#     entradas do baseline são `from` de uma aresta REFUTES/SUPERSEDES: fugiam com UM `sed` no
#     `status:`. A convenção do corpus é inequívoca no outro sentido — nas 3 conformidades reais o
#     refutado/superseded é sempre o `to`.
#     (⚠️ a 1ª redação deste comentário NOMEAVA os oito nós, e o `vendor-scrub` reprovou: ids de nó
#     carregam nome de adotante e ESTE ARQUIVO viaja vendorizado. É a mesma REGRA 36 pela qual o
#     baseline guarda hash e não id — cometida no comentário que explica o hash. Conte, não liste.)
#   · DUAS PONTAS — `from: X / to: X / edge_type: REFUTES`, três linhas, comprava RECONCILIADO.
#     Um nó não se refuta sozinho.
#   · TIPO DERIVADO DO STATUS — exigir SUPERSEDES só porque o status é `superseded` acusa a
#     reconciliação que o `kg-radar.sh:620-621` SANCIONA: *"recebe REFUTES mas segue status=…
#     (reconciliar: refuted ou superseded)"*. Quem escolhe `superseded` nesse fork não tem — e não
#     deve ter — aresta SUPERSEDES. Mesma família dos 3 falsos-positivos que o Elenxo da REGRA 57
#     derrubou, e no mesmo grafo (`m2-bridge-logto`) que o contrato chama de "o dogfood CERTO".
# Logo o predicado é: aresta ENTRANDO (o nó é o `to`), com as DUAS PONTAS distintas, de qualquer um
# dos dois tipos de reconciliação. Não é *"existe uma aresta por perto"* — é *"ALGUÉM, que não ele
# mesmo, o reconciliou"*.
#
# Flush no DELIMITADOR (`- from:` / EOF), não posicional: o `kg-seal-check.sh` guarda `to:` e consome
# no `edge_type:`, o que só funciona porque as arestas do corpus estão na ordem canônica — dívida
# declarada no Elenxo dele. Aqui a ordem from/edge_type/to é indiferente.
has_reconciliation_edge() { # $1=arquivo $2=id → exit 0 se ALGUÉM reconciliou o nó
  awk -v ID="$2" '
    function flush(   ) {
      if (ef != "" && ef != eto && eto == ID && (et == "REFUTES" || et == "SUPERSEDES")) achou=1
      ef=""; et=""; eto=""
    }
    /^[[:space:]]*-[[:space:]]*from:[[:space:]]*/ { flush(); ef=$3;  next }
    /^[[:space:]]*to:[[:space:]]*/                { eto=$2; next }
    /^[[:space:]]*edge_type:[[:space:]]*/         { et=$2;  next }
    END { flush(); exit(achou ? 0 : 1) }
  ' "$1"
}

# ⚠️ IÇADO DE PROPÓSITO, e a linha vale 12 segundos. `load_universe` memoiza numa variável de
# shell, e TODO consumidor abaixo roda em command substitution — a atribuição morria com o subshell
# e o universo era relido a CADA chave. Medido no estado-ALVO da própria catraca (os 48 nós já
# medidos): 19,9s contra 0,67s do script que este substitui. Chamando aqui, no escopo pai, os
# subshells HERDAM: 7,4s, saída byte-idêntica. O gradiente era perverso — quanto mais a doutrina
# fosse obedecida, mais lento ficaria o gate que a cobra.
load_universe

PAIRS="$(scope_pairs)"
UNVERIFIED="$(printf '%s\n' "${PAIRS}" | cut -d$'\037' -f1 | grep -v '^$' || true)"

if [ "${EMIT}" -eq 1 ]; then
  printf '# Baseline da REGRA 49 — PASSIVO TOLERADO de nós PROD/impact>=4 sem verified_at.\n'
  printf '# Gerado por: bash .claude/validation/kg-verification-coverage.sh --emit-baseline\n'
  printf '# Esta lista SO PODE ENCOLHER. Acrescentar entrada aqui e REGRESSAO (HARD).\n'
  printf '# Para remover uma entrada: MEÇA o no contra o vivo (/meta:kg-freshness) e carimbe.\n'
  printf '%s\n' "${UNVERIFIED}"
  exit 0
fi

# ── FAIL-CLOSED: baseline ausente não libera tudo (lição da REGRA 29/42) ────────────────────────
if [ ! -f "${BASELINE}" ]; then
  emit HARD NO-BASELINE ".claude/validation/kg-verification-baseline.txt" \
    "baseline AUSENTE — gere com --emit-baseline. Sem ele o gate nao distingue passivo tolerado de no NOVO (fail-closed: nao libera tudo)."
  exit 1
fi

known="$(grep -vE '^[[:space:]]*(#|$)' "${BASELINE}" 2>/dev/null | sort -u)"
# O baseline do commit ANTERIOR. Lido aqui, e não lá embaixo no bloco (3), porque o laço (2) precisa
# dele: ver TO_JUDGE.
prev="$(git show HEAD:.claude/validation/kg-verification-baseline.txt 2>/dev/null | grep -vE '^[[:space:]]*(#|$)' | sort -u || true)"

# ⚠️ O UNIVERSE DE JULGAMENTO É `prev ∪ known`, NÃO `known`. O Elenxo desta branch reproduziu o
# bypass total: reetiquetar o nó E apagar a linha do baseline NO MESMO COMMIT. Iterando só o baseline
# ATUAL, a chave apagada some do julgamento e ninguém a classifica; e o bloco (3) só reprova quando
# o baseline CRESCE, então encolher era sempre livre. Saída medida antes da correção:
#   `exit=0 · 0 VIOLATION · no escopo sem carimbo: 47 · passivo tolerado: 47 · HARD: 0`
# O custo do bypass tinha subido de UM `sed` para UM `sed` + UM `grep -v` — e o desenho punia quem
# fazia a coisa MENOS encoberta (deixava a linha e levava HARD) e liberava quem apagava o rastro
# inteiro. Com a união, a linha apagada continua sendo cobrada até que o nó explique a própria saída.
TO_JUDGE="$(printf '%s\n%s\n' "${prev}" "${known}" | grep -v '^$' | sort -u || true)"
hard=0; soft=0

# (1) nó sem carimbo FORA do baseline → HARD (nasce verificado)
# O id vem JUNTO da chave (`PAIRS`), então a mensagem nomeia o nó sem nenhuma busca reversa — a
# versão anterior refazia sha1 dentro de um `cmd | getline` por candidato só para reencontrar o nome.
while IFS=$'\037' read -r n nid; do
  [ -n "${n}" ] || continue
  if ! printf '%s\n' "${known}" | grep -qxF "${n}"; then
    emit HARD NOVO "${n%%::*}" \
      "no '${nid:-<id oculto>}' e plane:PROD impact>=4 SEM verified_at e FORA do baseline — meca contra o vivo antes de selar (/meta:kg-freshness), ou o grafo afirma sobre producao sem nunca ter olhado."
    hard=$((hard+1))
  fi
done <<< "${PAIRS}"

# ══ (2) GUARDA DE DIREÇÃO — POR QUE esta entrada saiu do escopo? ═══════════════════════════════
# ANTES: toda saída virava um SOFT único — "OBSOLETA — no ja carimbado ou removido". A mensagem
# AFIRMAVA um carimbo sem nunca ter olhado se ele existia, e era FALSA em todo caso de reetiqueta.
# É o `declarado != verificado` dentro do instrumento que existe para cobrar verificação.
#
# AGORA a saída é CLASSIFICADA contra o vivo. Três classes são legítimas e duas são fuga:
#   CARIMBADO        o nó está lá e ganhou `verified_at`                          → SOFT (é a saída que o gate EXISTE para produzir)
#   RECONCILIADO     virou refuted/superseded COM a aresta que justifica          → SOFT
#   REMOVIDO         o nó não existe mais naquele arquivo                         → SOFT (ato visível no diff)
#   FUGA-SEM-ARESTA  virou refuted/superseded por reetiqueta NUA, sem aresta      → HARD
#   FUGA-DE-ESCOPO   segue sem carimbo e saiu rebaixando plane/impact             → HARD
#
# ⚠️ SOBRE A COBERTURA DESTE BLOCO — a versão anterior deste comentário afirmava um número que
# NINGUÉM OBSERVOU, e o Elenxo o falsificou em um comando. Ela dizia: *"sem a checagem de aresta o
# guarda acusaria 3 CONFORMIDADES"*. FALSO. Hoje `--emit-baseline` é IDÊNTICO ao baseline versionado,
# logo este laço NUNCA EXECUTA no corpus real, e nenhum dos 3 nós citados está no baseline. Medição:
#   sed 's/exit(achou ? 0 : 1)/exit(1)/' kg-verification-coverage.sh > /tmp/sem-aresta.sh
#   bash /tmp/sem-aresta.sh --format tsv | awk -F'\t' '{print $1,$2}' | sort | uniq -c
#   → 48 SOFT PASSIVO, ZERO HARD
# A checagem é PREVENTIVA, e o que prova que ela discrimina é o selftest (p), não o corpus. Escrever
# consequência não-observada no cabeçalho de um gate cuja tese é `declarado != verificado` é o
# defeito da própria REGRA 49 cometido dentro do instrumento — por isso a correção fica aqui, com o
# comando que a falsifica junto.
#
# ⚠️ E o corolário, que é o fio mais honesto deste PR: as CINCO classes abaixo não têm NENHUMA
# cobertura de campo. Toda a evidência é sintética. O primeiro nó que sair do baseline de verdade —
# via `/meta:kg-freshness` — é o PRIMEIRO dogfood real desta guarda. O verde do CI não substitui isso.
while IFS= read -r k; do
  [ -n "${k}" ] || continue
  printf '%s\n' "${UNVERIFIED}" | grep -qxF "${k}" && continue
  kp="${k%%::*}"
  # a linha ainda está no baseline, ou o operador já a removeu? muda só o conselho da mensagem
  if printf '%s\n' "${known}" | grep -qxF "${k}"; then hint="remova do baseline"; else hint="a linha ja saiu do baseline"; fi
  rec="$(resolve_key "${k}")"
  if [ -z "${rec}" ]; then
    emit SOFT REMOVIDO ".claude/validation/kg-verification-baseline.txt" \
      "no que NAO EXISTE MAIS em ${kp} — ${hint}: ${k}"
    soft=$((soft+1)); continue
  fi
  IFS=$'\037' read -r rid rplane rimp rst rver <<< "${rec}"
  if [ -n "${rver}" ]; then
    emit SOFT CARIMBADO ".claude/validation/kg-verification-baseline.txt" \
      "no '${rid}' foi MEDIDO (verified_at: ${rver}) — ${hint}: ${k}"
    soft=$((soft+1)); continue
  fi
  case "${rst}" in
    refuted|superseded)
      if has_reconciliation_edge "${kp}" "${rid}"; then
        emit SOFT RECONCILIADO ".claude/validation/kg-verification-baseline.txt" \
          "no '${rid}' saiu do escopo como '${rst}' COM aresta de reconciliacao (REFUTES|SUPERSEDES) ENTRANDO, vinda de OUTRO no — ${hint}: ${k}"
        soft=$((soft+1))
      else
        emit HARD FUGA-SEM-ARESTA "${kp}" \
          "no '${rid}' virou '${rst}' SEM carimbo e SEM aresta de reconciliacao ENTRANDO (REFUTES ou SUPERSEDES, vinda de OUTRO no — aresta SAINDO nao reconcilia, e no nao se refuta sozinho). Ou meca contra o vivo (/meta:kg-freshness), ou escreva a aresta que justifica o '${rst}'."
        hard=$((hard+1))
      fi ;;
    *)
      emit HARD FUGA-DE-ESCOPO "${kp}" \
        "no '${rid}' saiu do escopo SEM carimbo (hoje plane:${rplane:-<vazio>} impact:${rimp:-0} status:${rst:-<vazio>}) — o baseline so encolhe por MEDICAO, nunca por rebaixar plane/impact."
      hard=$((hard+1)) ;;
  esac
done <<< "${TO_JUDGE}"

# (3) CATRACA — baseline que CRESCEU vs a versão anterior no git → HARD (regressão).
# `prev` é lido lá em cima, junto do `known`, porque o laço (2) depende dele (TO_JUDGE = prev ∪ known).
if [ -n "${prev}" ]; then
  np=$(printf '%s\n' "${prev}"  | grep -c . || true)
  nk=$(printf '%s\n' "${known}" | grep -c . || true)
  if [ "${nk}" -gt "${np}" ]; then
    emit HARD CATRACA ".claude/validation/kg-verification-baseline.txt" \
      "o baseline CRESCEU (${np} -> ${nk}). Ele SO PODE ENCOLHER: passivo novo e no NOVO sem carimbo, nao entrada de baseline."
    hard=$((hard+1))
  fi
fi

n_tot=$(printf '%s\n' "${UNVERIFIED}" | grep -c . || true)
n_base=$(printf '%s\n' "${known}" | grep -c . || true)
# PASSIVO: uma linha por entrada tolerada — o LINT agrega em uma só (contrato da REGRA 29)
i=0; while [ "${i}" -lt "${n_base}" ]; do
  emit SOFT PASSIVO ".claude/validation/kg-verification-baseline.txt" "no ainda sem verificacao, tolerado pelo baseline"
  i=$((i+1))
done
if [ "${FMT}" != "tsv" ]; then
  printf '  [kg-verificacao] no escopo sem carimbo: %s · passivo tolerado: %s · HARD: %s · SOFT: %s\n' \
    "${n_tot}" "${n_base}" "${hard}" "${soft}"
  printf '  [kg-verificacao] saude = o baseline DIMINUINDO. Para reduzir: /meta:kg-freshness mede o no e voce carimba.\n'
fi

[ "${hard}" -eq 0 ]
