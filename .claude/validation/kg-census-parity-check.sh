#!/usr/bin/env bash
# kg-census-parity-check.sh — REGRA 82: os DOIS leitores do corpus concordam sobre QUEM É NÓ.
#
# IRMÃ DA REGRA 78, e a divisão entre elas é exata. A 78 fecha *"o arquivo é YAML válido"*. Esta
# fecha *"o awk e o YAML veem a MESMA população"* — e a segunda não decorre da primeira.
#
# O SINAL QUE A CRIOU (venda-direta-pdi, pin 5dcc706b2233; REPRODUZIDO no core em 30 segundos):
# um `.kg.yaml` PERFEITAMENTE VÁLIDO em que os dois leitores veem grafos DIFERENTES com todos os
# gates verdes. Um nó `B_ESCONDIDO` escrito DENTRO do bloco `label: |` de outro nó, com uma aresta
# SUPPORTS saindo dele. PyYAML vê 2 nós; o `kg-radar.sh` — QUE É QUEM EMITE O VEREDITO — anuncia
# `3 nós, 2 arestas`, e o nó forjado PESA na centralidade. A REGRA 78 sai rc=0 e está CERTA: o
# arquivo É válido.
#
# CAUSA: o matcher do radar casa `- id:` com QUALQUER indentação dentro de `nodes:`, sem rastrear
# blocos literais. É permissividade correta para um motor awk, e o preço declarado da economia de
# motores — mas o preço só é aceitável se alguém o COBRAR. Esta guarda é a cobrança.
#
# ⚠️ O REQUISITO NÃO-NEGOCIÁVEL, que o adotante descobriu na pele: a 1ª guarda DELES ancorava em
#    dois espaços fixos e NÃO VIA o nó forjado a seis. Media, saía 0, e não replicava nada.
#    **Guarda que não replica o contador que DÁ O VEREDITO é decoração.**
#
# 🔁 E A MINHA 1ª VERSÃO COMETEU A MESMA CLASSE POR OUTRO FLANCO (passada adversarial 2026-09-11).
#    Ela TRANSCREVIA a máquina de estados do awk para Python — e transcrição é cópia, não o motor:
#      · o awk casa `[[:space:]]`, eu escrevi `lstrip(" \t")`. Divergem em VT, FF e **CR** — e com CR
#        o arquivo segue YAML-válido. Um nó forjado indentado com CR: o radar conta o fantasma, o
#        PyYAML não, e a guarda criada para exatamente esse caso saía **0 com saída vazia**.
#      · o awk aplica `trim` DUAS vezes (antes e depois do `sub`), eu aplicava uma — a guarda
#        NOMEAVA um id diferente do que o radar usa, e "fantasma NOMEADO" é o contrato.
#      · mudar UM caractere no matcher do radar não era detectado: a cópia congelava e a guarda
#        passava a acusar um motor que não existe mais — com a bancada aplaudindo.
#
#    A CURA NÃO É TRANSCREVER MELHOR. É PERGUNTAR AO MOTOR. Esta guarda agora INVOCA o
#    `kg-radar.sh --status-tsv` — o feed que o próprio radar emite com a população que ele usou para
#    dar o veredito — e confronta com o PyYAML. Não há o que divergir: o contador é o mesmo objeto,
#    não uma imitação dele. Toda mudança futura no matcher do radar viaja de graça.
#
# CATRACA COM BASELINE VERSIONADA (padrão das REGRAS 29/42/45/49/74/78): arquivo já divergente fica
# TOLERADO e visível como SOFT; arquivo NOVO é HARD; e o baseline CRESCER vs `origin/main` é HARD.
#
# Uso : bash .claude/validation/kg-census-parity-check.sh [<raiz>] [--format tsv|--emit-baseline]
# Exit: 0 = os dois leitores concordam · 1 = divergem (fantasmas NOMEADOS) · 2 = NAO MEDIDO.
set -uo pipefail

ROOT=""; FMT=""; SEEN_EMIT=0; SEEN_FMT=0; ONLY_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --emit-baseline|--emit) SEEN_EMIT=1; FMT="emit"; shift ;;
    --format)
      [ $# -ge 2 ] || { echo "ERRO: --format exige um valor (tsv)" >&2; exit 2; }
      case "$2" in tsv|human) : ;; *) echo "ERRO: --format desconhecido '$2' (use tsv)" >&2; exit 2 ;; esac
      SEEN_FMT=1; [ "${SEEN_EMIT}" -eq 1 ] || FMT="$2"; shift 2 ;;
    --tsv) SEEN_FMT=1; [ "${SEEN_EMIT}" -eq 1 ] || FMT="tsv"; shift ;;
    # ESCOPO REAL, não filtro na entrada: sem isto o helper varria os 128 grafos a cada `--only`,
    # reportava violação de arquivo ALHEIO (que o chamador não pediu) e cobrava +22% por invocação.
    --file)
      [ $# -ge 2 ] || { echo "ERRO: --file exige um caminho" >&2; exit 2; }
      ONLY_FILE="$2"; shift 2 ;;
    -*) echo "ERRO: flag desconhecida '$1'" >&2; exit 2 ;;
    *)  [ -z "${ROOT}" ] || { echo "ERRO: raiz duplicada '$1'" >&2; exit 2; }; ROOT="$1"; shift ;;
  esac
done
[ "${SEEN_EMIT}" -eq 1 ] && [ "${SEEN_FMT}" -eq 1 ] && {
  echo "ERRO: --emit-baseline e --format são exclusivos" >&2; exit 2; }
[ -n "${ROOT}" ] || ROOT="$(pwd)"
[ -d "${ROOT}" ] || { echo "ERRO: raiz inexistente: ${ROOT}" >&2; exit 2; }

# NAO MEDIDO É DESFECHO DE PRIMEIRA CLASSE, nunca zero. Sem estas três, a guarda não sabe nada —
# e "não sei" impresso como "concordam" é o fail-open que esta casa passou a onda inteira curando.
for _dep in python3 git; do
  command -v "${_dep}" >/dev/null 2>&1 || { echo "kg-census-parity: ${_dep} ausente — NAO MEDIDO" >&2; exit 2; }
done
python3 -c 'import yaml' 2>/dev/null || { echo "kg-census-parity: PyYAML ausente — NAO MEDIDO" >&2; exit 2; }

# O RADAR É DEPENDÊNCIA DURA, e é o ponto inteiro desta guarda: ela não imita o contador, ela o
# INVOCA. Sem o radar ao lado não há com o que confrontar o PyYAML — e "não sei" nunca é "concordam".
RADAR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kg-radar.sh"
[ -f "${RADAR}" ] || { echo "kg-census-parity: kg-radar.sh ausente (${RADAR}) — NAO MEDIDO" >&2; exit 2; }

_top="$(git -C "${ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "${_top}" ] || { echo "kg-census-parity: '${ROOT}' não é repositório git — NAO MEDIDO" >&2; exit 2; }
ROOT="${_top}"

BASELINE="${ROOT}/.claude/validation/kg-census-parity-baseline.txt"
BASELINE_REL=".claude/validation/kg-census-parity-baseline.txt"
_out() {
  case "${FMT}" in
    tsv) printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" ;;
    *)   printf '%s: [kg-parity/%s] %s — %s\n' "$1" "$2" "$3" "$4" ;;
  esac
}

# `-z` direto do git para o python: `$(...)` do bash DESCARTA bytes nulos e colaria todos os
# caminhos num nome só (cicatriz medida na irmã 78, e ela custou a cobertura do corpus inteiro).
if [ -z "$(cd "${ROOT}" && git ls-files '*.kg.yaml' 2>/dev/null | head -1 || true)" ]; then
  [ "${FMT}" = "emit" ] || _out SOFT SEM-CORPUS "${BASELINE_REL}" "nenhum .kg.yaml versionado — nada a confrontar (git respondeu; o corpus é que está vazio)"
  exit 0
fi

# A POPULAÇÃO DO RADAR VEM DO RADAR. `--status-tsv` emite `id<TAB>status` de TODOS os nós — é o
# feed que o próprio motor produz a partir da população com que ele deu o veredito. Sai rc=0 mesmo
# em grafo com integridade quebrada (medido), então o rc aqui separa "não rodou" de "rodou e viu".
# ⚠️ O RC DO RADAR É LIDO. Sem isto, um radar que MORRE (lib ausente, arquivo ilegível, exit 2)
#    devolve saída vazia e a guarda lê `radar=0` — ausência virando RESULTADO, que é exatamente a
#    classe que esta onda inteira está curando. Achado no dogfood desta própria cura: num sandbox
#    sem a `lib/status-factor.awk` ao lado, a guarda acusou DIVERGE num grafo perfeitamente são.
#    `--status-tsv` sai 0 mesmo com integridade quebrada (medido), então rc != 0 aqui é SEMPRE
#    "não consegui medir", nunca "medi e deu zero".
_radar_ids() {   # $1 = arquivo; ecoa os ids OU `__RADARFAIL__<rc>` na 1ª linha
  local _o _rc=0
  _o="$(bash "${RADAR}" "$1" --status-tsv 2>/dev/null)" || _rc=$?
  if [ "${_rc}" -ne 0 ]; then printf '__RADARFAIL__%s\n' "${_rc}"; return 0; fi
  printf '%s\n' "${_o}" | awk -F'\t' 'NF{print $1}'
}

# O PyYAML lê o MESMO arquivo. Sozinho ele não decide nada: só a diferença entre os dois decide.
_PYYAML_IDS='
import sys, yaml
try:
    txt = open(sys.argv[1], "rb").read().decode("utf-8", "replace")
except OSError as e:
    print("__IO__\t%s" % str(e).replace("\n", " ")[:140]); sys.exit(0)
try:
    docs = list(yaml.safe_load_all(txt))
except Exception as e:
    print("__YAMLERR__\t%s" % str(e).replace("\n", " ")[:100]); sys.exit(0)
for doc in docs:
    if isinstance(doc, dict) and isinstance(doc.get("nodes"), list):
        for n in doc["nodes"]:
            if isinstance(n, dict) and "id" in n:
                print(str(n["id"]))
'

# Varredura: um arquivo por vez, porque cada um exige uma invocação do radar. O laço lê a lista via
# `-z` direto do git — `$(...)` do bash DESCARTA bytes nulos e colaria todos os caminhos num nome só
# (cicatriz medida na irmã 78, e custou a cobertura do corpus inteiro).
_scan_one() {   # $1 = arquivo relativo à ROOT; emite `arquivo<TAB>CLASSE<TAB>detalhe`
  local f="$1" ypop rpop fant invis nr ny
  ypop="$(cd "${ROOT}" && python3 -c "${_PYYAML_IDS}" "${f}" 2>/dev/null)"
  case "${ypop}" in
    __IO__*)      printf '%s\tIO\t%s\n'      "${f}" "${ypop#*$'\t'}"; return 0 ;;
    __YAMLERR__*) printf '%s\tYAMLERR\t%s\n' "${f}" "${ypop#*$'\t'}"; return 0 ;;
  esac
  rpop="$(cd "${ROOT}" && _radar_ids "${f}")"
  case "${rpop}" in
    __RADARFAIL__*) printf '%s\tRADARFAIL\t%s\n' "${f}" "rc=${rpop#__RADARFAIL__}"; return 0 ;;
  esac
  nr="$(printf '%s\n' "${rpop}" | grep -c . || true)"
  ny="$(printf '%s\n' "${ypop}" | grep -c . || true)"
  # FANTASMA = só o radar vê (o caso do nó dentro de bloco literal).
  # INVISÍVEL = só o YAML vê (o radar perdeu um nó — causa OPOSTA, e por isso classe separada).
  fant="$(comm -23 <(printf '%s\n' "${rpop}" | LC_ALL=C sort -u | grep -v '^$' || true) \
                   <(printf '%s\n' "${ypop}" | LC_ALL=C sort -u | grep -v '^$' || true) | tr '\n' ' ' || true)"
  invis="$(comm -13 <(printf '%s\n' "${rpop}" | LC_ALL=C sort -u | grep -v '^$' || true) \
                    <(printf '%s\n' "${ypop}" | LC_ALL=C sort -u | grep -v '^$' || true) | tr '\n' ' ' || true)"
  if [ -n "${fant// }" ] || [ -n "${invis// }" ] || [ "${nr}" != "${ny}" ]; then
    local det="radar=${nr} yaml=${ny}"
    [ -n "${fant// }" ]  && det="${det} | FANTASMA (so o radar ve): ${fant% }"
    [ -n "${invis// }" ] && det="${det} | INVISIVEL (so o YAML ve): ${invis% }"
    printf '%s\tDIVERGE\t%s\n' "${f}" "${det}"
  fi
  return 0
}

_scan=""
while IFS= read -r -d '' _f; do
  _scan="${_scan}$(_scan_one "${_f}")"$'\n'
done < <(cd "${ROOT}" && if [ -n "${ONLY_FILE}" ]; then git ls-files -z -- "${ONLY_FILE}"; else git ls-files -z '*.kg.yaml'; fi)

_div="$(printf '%s\n' "${_scan}" | awk -F'\t' '$2=="DIVERGE"{print $1"\t"$3}')"
_io="$(printf  '%s\n' "${_scan}" | awk -F'\t' '$2=="IO"{print $1"\t"$3}')"
_yerr="$(printf '%s\n' "${_scan}" | awk -F'\t' '$2=="YAMLERR"{print $1"\t"$3}')"
_rfail="$(printf '%s\n' "${_scan}" | awk -F'\t' '$2=="RADARFAIL"{print $1"\t"$3}')"

if [ "${FMT}" = "emit" ]; then
  printf '# kg-census-parity-baseline — .kg.yaml em que radar e PyYAML DIVERGEM sobre quem é nó, TOLERADOS.\n'
  printf '# Gerado por: bash .claude/validation/kg-census-parity-check.sh --emit-baseline\n'
  printf '# A métrica de saúde é esta lista ENCOLHENDO — e é MECANISMO: crescer vs origin/main é HARD.\n'
  printf '%s\n' "${_div}" | awk -F'\t' 'NF{print $1}' | LC_ALL=C sort
  exit 0
fi

_tol=""
[ -f "${BASELINE}" ] && _tol="$(grep -vE '^[[:space:]]*(#|$)' "${BASELINE}" || true)"
rc=0

# CATRACA — o passivo SÓ ENCOLHE. Três defeitos MEDIDOS na passada adversarial, curados juntos:
#
#  (a) DESARMADA NO ESTADO DE HOJE. A versão anterior exigia `_prev > 0`, e `git show` falhando
#      devolvia 0 pelo `|| true`. Como o baseline AINDA NÃO EXISTE no repo, toda transição 0→N
#      passava livre — inclusive o PRIMEIRO baseline, de tamanho ilimitado. A guarda descrevia
#      maquinaria que não rodava.
#  (b) COMPARAVA CONTAGEM DE LINHAS, não CONJUNTO. Trocar um arquivo por outro (5→5) passava, e
#      linha duplicada nos dois lados falseava o veredito nas duas direções.
#  (c) SEM origin/main ELA NÃO MEDIA **E NÃO AVISAVA** — justo no adotante, que é quem tem `master`
#      ou nenhum remoto. O arquivo declara NÃO MEDIDO como desfecho de 1ª classe para python3/git/
#      PyYAML e não o aplicava a si mesmo.
_cur_set="$(printf '%s\n' "${_tol}" | grep -v '^[[:space:]]*$' | LC_ALL=C sort -u || true)"
if git -C "${ROOT}" rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
  _prev_raw="$(git -C "${ROOT}" show "origin/main:${BASELINE_REL}" 2>/dev/null || printf '__AUSENTE__')"
  if [ "${_prev_raw}" = "__AUSENTE__" ]; then
    # Baseline ainda não nasceu no main: a catraca não tem contra o que travar. Dizer isso é o
    # ponto — é exatamente aqui que o primeiro baseline entraria com tamanho livre.
    [ -z "${_tol}" ] || _out SOFT CATRACA-NAO-MEDIDA "${BASELINE_REL}" "o baseline não existe em origin/main — a catraca não tem referência para travar; esta é a entrada INICIAL do passivo ($(printf '%s\n' "${_cur_set}" | grep -c . || true) entrada(s)) e ninguém a está limitando"
  else
    _prev_set="$(printf '%s\n' "${_prev_raw}" | grep -vE '^[[:space:]]*(#|$)' | LC_ALL=C sort -u || true)"
    # CONJUNTO, não contagem: o que INTEROU é o que importa (troca 5→5 escondia arquivo novo).
    _new_ones="$(comm -13 <(printf '%s\n' "${_prev_set}") <(printf '%s\n' "${_cur_set}") | grep -v '^$' | tr '\n' ' ' || true)"
    if [ -n "${_new_ones// }" ]; then
      rc=1
      _out HARD CATRACA-VIOLADA "${BASELINE_REL}" "o baseline GANHOU entrada(s) vs origin/main — o passivo só encolhe. Novo(s): ${_new_ones% }"
    fi
  fi
else
  [ -z "${_tol}" ] || _out SOFT CATRACA-NAO-MEDIDA "${BASELINE_REL}" "sem origin/main alcançável — a catraca NÃO FOI MEDIDA (não é aprovação); num adotante com 'master' ou sem remoto o passivo pode crescer sem ninguém ver"
fi

if [ ! -f "${BASELINE}" ] && [ -n "${_div}" ]; then
  _out SOFT NO-BASELINE "${BASELINE_REL}" "há grafo divergente e NÃO existe baseline — a catraca não está armada (emita com --emit-baseline)"
fi

passivo=0
while IFS=$'\t' read -r f det; do
  [ -n "${f}" ] || continue
  if grep -qxF "${f}" <<< "${_tol}"; then
    passivo=$((passivo+1))
  else
    rc=1
    _out HARD DIVERGE "${f}" "os dois leitores discordam sobre QUEM É NÓ (${det}) — o radar emite o veredito sobre uma população que o YAML não tem; nó dentro de bloco literal é o caso conhecido"
  fi
done <<< "${_div}"

# ⚠️ O BURACO ENTRE AS DUAS IRMAS, e ele e o achado mais silencioso da passada adversarial de
#    2026-09-11: os 4 grafos que esta regra nao consegue medir sao BYTE A BYTE os 4 do baseline da
#    REGRA 78. A 78 os tolera (passivo, SOFT); a 82 nao os mede (SOFT). Resultado: em 4 grafos
#    VIVOS, NENHUMA das duas cobra nada em HARD — e um fantasma injetado ali passa pelas duas.
#    Provado pelo refutador: no baseline injetado, rc78=0 e rc82=0 com o nó forjado presente.
#    Não é duplicidade: é buraco. A cura possível AQUI é torná-lo VISÍVEL e CONTADO — a cobrança
#    de verdade é encolher o passivo da 78, que é onde o arquivo é consertado.
_nyerr=0
while IFS=$'\t' read -r f det; do
  [ -n "${f}" ] || continue
  _nyerr=$(( _nyerr + 1 ))
  _out SOFT NAO-MEDIDO "${f}" "paridade NÃO MEDIDA: o PyYAML não parseou (${det}) — isto é a REGRA 78, não esta; não leia como paridade OK"
done <<< "${_yerr}"
if [ "${_nyerr}" -gt 0 ]; then
  _out SOFT BURACO-78-82 "${BASELINE_REL}" "${_nyerr} grafo(s) ficam FORA das duas irmãs ao mesmo tempo: a REGRA 78 os TOLERA pelo baseline e a REGRA 82 NÃO OS MEDE (o PyYAML não parseia). Nesses arquivos um nó forjado dentro de bloco literal passa pelas DUAS — a cobrança real é encolher o passivo da 78, que é onde eles se consertam"
fi

# OS DOIS RC DO RADAR SIGNIFICAM COISAS DIFERENTES, e tratá-los igual produziu um HARD falso na
# 1ª rodada desta cura (a fixture `bad-grammar.kg.yaml`, ilegível DE PROPÓSITO para a bancada):
#   rc=1 → o radar LEU e se recusou a opinar (guarda de LEGIBILIDADE: extraiu 0 nós). A divergência
#          é real, mas quem cobra é a guarda de gramática, que já reprova alto. Aqui vira SOFT
#          NOMEADO — a paridade declara que não mediu, e diz de quem é a cobrança.
#   rc=2 → o radar NÃO RODOU (lib ausente, erro de uso, ambiente quebrado). Aí é HARD: o motor que
#          dá o veredito de TODO grafo do repo está fora do ar, e isso nunca é aprovação.
while IFS=$'\t' read -r f det; do
  [ -n "${f}" ] || continue
  case "${det}" in
    rc=1) _out SOFT RADAR-ILEGIVEL "${f}" "o kg-radar.sh se recusou a opinar (guarda de LEGIBILIDADE: extraiu 0 nós) — paridade NÃO MEDIDA aqui; a cobrança é da gramática do grafo, não desta regra" ;;
    *)    rc=1
          _out HARD RADAR-NAO-RESPONDEU "${f}" "o kg-radar.sh NÃO RODOU neste arquivo (${det}) — a paridade não foi medida e isto NÃO é concordância; o motor que dá o veredito de todo grafo do repo está fora do ar" ;;
  esac
done <<< "${_rfail}"

while IFS=$'\t' read -r f det; do
  [ -n "${f}" ] || continue
  _out SOFT ILEGIVEL "${f}" "versionado mas não deu para LER (${det}) — apagado sem git rm? symlink quebrado?"
done <<< "${_io}"

[ "${passivo}" -eq 0 ] || _out SOFT PASSIVO "${BASELINE_REL}" "${passivo} grafo(s) divergente(s) tolerado(s) pelo baseline — a métrica de saúde é este número DIMINUINDO"
exit "${rc}"
