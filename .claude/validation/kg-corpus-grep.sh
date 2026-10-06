#!/usr/bin/env bash
# kg-corpus-grep.sh — "o que os grafos JÁ sabem sobre este tema" (passo 0 de toda pesquisa Onion).
#
# Uso: bash .claude/validation/kg-corpus-grep.sh <termo> [termo...] [--json] [--all-status]
#   Casa cada termo (case-insensitive) no id OU no label de todo nó de todo .kg.yaml versionado
#   (git ls-files '*.kg.yaml', fixtures excluídas — o glob hardcoded era 36% cego). Imprime, por nó:
#   grafo · id · status · verified_at · source_tier · label (recortado). Default: esconde refuted/superseded
#   (use --all-status para ver a Aufhebung). Fail-loud: nenhum grafo no corpus = exit 2, nunca "0 achados".
#
# Por que existe (medido 2026-09-02, meta-research-lens): 27 grafos de pesquisa guardados e NENHUMA
# pesquisa os lia antes de buscar fora — o único reuso era por eixo do radar. Custo: 0 tokens.
set -uo pipefail

# Predicado de FIXTURE — caminho ABSOLUTO resolvido ANTES de qualquer `cd`, e ausência é FAIL-CLOSED.
# (A 1ª ligação usava `$(dirname "${BASH_SOURCE[0]}")` no ponto de uso e morria depois de um `cd`:
#  o erro era engolido por `|| true` e o script dizia "nenhum grafo" — verde por vacuidade. 2026-09-05.)
_KFP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kg-fixture-paths.sh"
[ -f "${_KFP}" ] || { echo "ERRO: predicado de fixture ausente (${_KFP}) — sem ele a varredura de grafos ficaria VAZIA e verde por vacuidade." >&2; exit 2; }
ROOT="${ONION_KG_CORPUS_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
JSON=0; ALL=0; TERMS=()
# `--query "<frase inteira>"` existe porque o CHAMADOR não consegue passar uma pergunta livre em
# segurança: a skill onion-research injeta `$ARGUMENTS` por `!`backtick`` e precisa dele SEM quotes,
# para que cada palavra vire um termo. Medido em 2026-10-01: uma pergunta com PARÊNTESES
# ("JEV (jevtypesafeai.com): ...") produziu `syntax error near unexpected token '('` e **abortou a
# invocação da skill inteira** — não degradou, matou. Com `--query` o chamador quota a frase e QUEM
# separa em termos é este script, onde o texto já é dado e não código.
# TETO DECLARADO: `"`, `` ` `` e `$` no texto do chamador ainda podem quebrar a injeção, porque um erro
# de SINTAXE no eval não é capturável por `|| true`. Resolver isso exige o substrato passar argumento
# fora da linha de comando; até lá, está escrito na skill.
# `while`+`shift`, NÃO `for a in "$@"`: num `for` a lista é expandida ANTES da 1ª volta, então o
# `shift` do `--query` não move a iteração e a frase entrava DUAS vezes — como termos e como termo
# inteiro (medido na própria cura, em 2026-10-01).
PHRASE=0; _WARN=""; TOP=""
while [ "$#" -gt 0 ]; do case "$1" in
  --json) JSON=1;;
  --all-status) ALL=1;;
  --query) shift; read -r -a _q <<< "${1:-}"; [ "${#_q[@]}" -gt 0 ] && TERMS+=("${_q[@]}");;
  -h|--help) sed -n '2,10p' "$0"; exit 0;;
  # ⚠️ TERMO POSICIONAL COM ESPACOS e tratado como `--query`, e DECLARADO (dano medido 2026-10-03):
  #    `kg-corpus-grep.sh "auto-evolucao evolve laco raio-X auditoria"` casava a frase INTEIRA como UM
  #    termo, nenhum label a continha e a saida foi `0 no(s)` sobre 120 grafos — zero que parece
  #    "o corpus nao sabe nada disto" e na verdade era invocacao errada. A forma certa (`--query`)
  #    existia; ninguem e obrigado a adivinhar qual das duas. Separar aqui e seguro porque aqui a
  #    frase JA e dado, nunca codigo (o teto do eval esta documentado acima e nao muda).
  # ⚠️ --phrase e a ESCOTILHA, e ela nasceu de reprovacao (Elenxo do PR #909, 2026-10-03): a 1a cura
  #    separava TODO termo posicional com espacos e MATOU a busca-frase, sem alternativa — `--query`
  #    tambem separa. Medido: `'o maestro'` devolvia 396 nos por casamento de frase no label e passou
  #    a devolver 4114, porque `o` e substring de quase todo id. Trocar consulta precisa por esguicho
  #    nao e cura; e a propria "ampliacao por termo generico" que a mensagem nova ensina a evitar.
  --phrase) shift; [ -n "${1:-}" ] && { TERMS+=("$1"); PHRASE=1; };;
  # ⚠️ --top EXISTE PARA O CORTE DECLARAR-SE, e nasceu de uma ASSIMETRIA reprovada (Elenxo do PR
  #    #909): o `forge-census` foi obrigado a declarar o corte da projecao dele, e os consumidores
  #    DESTE script seguiam cortando com `| head -N` em silencio — `onion-research/SKILL.md` injeta
  #    40 de 298 achados, e 259 caiam sem uma palavra. Pior: a cura da frase AUMENTOU o resultado,
  #    entao um zero falso e BARULHENTO virou um quarenta quieto e igualmente falso. Quem corta
  #    aqui dentro conta o total antes de cortar; `head` nunca sabe o que descartou.
  --top) shift; TOP="${1:-}";;
  *) case "$1" in
       *[[:space:]]*) read -r -a _p <<< "$1"
                      [ "${#_p[@]}" -gt 0 ] && TERMS+=("${_p[@]}")
                      # ⚠️ O AVISO E BUFFERIZADO, nunca emitido aqui: decidir no parse amarra o
                      #    comportamento a ORDEM DOS FLAGS — `'frase' --json` tem JSON=0 nesta linha
                      #    e o aviso escapava, que foi exatamente como a 1a cura do R7 falhou no
                      #    proprio dogfood. Quem decide e o emissor, depois de TODOS os flags lidos.
                      _WARN="kg-corpus-grep: termo posicional com espacos separado em ${#_p[@]} termos (igual a --query). Isto AMPLIA o resultado; para casar a frase LITERAL use --phrase \"$1\".";;
       *) TERMS+=("$1");;
     esac;;
esac; shift; done
case "${TOP}" in
  '') : ;;
  *[!0-9]*|0) printf 'kg-corpus-grep: --top invalido (%s) — inteiro >= 1. Recuso.\n' "${TOP}" >&2; exit 2 ;;
esac
# agora sim: todos os flags lidos, o emissor decide. Em --json o aviso viaja no payload (campo mode).
[ -n "${_WARN}" ] && [ "${JSON}" != "1" ] && printf '%s\n' "${_WARN}" >&2
[ "${#TERMS[@]}" -gt 0 ] || { echo "uso: kg-corpus-grep.sh <termo> [termo...] | --query \"<frase>\" | --phrase \"<frase literal>\" [--json] [--all-status]" >&2; exit 2; }
if [ -n "${ONION_KG_CORPUS_FILES:-}" ]; then files="${ONION_KG_CORPUS_FILES}"
# ⚠️ A isenção de FIXTURE vem do predicado ÚNICO kg-fixture-paths.sh (2026-09-05): antes cada
#    consumidor repetia `grep -v '/fixtures/'` e o `__fixtures__/` do Vitest ESCAPAVA — 5 grafos
#    deliberadamente inválidos de um adotante viraram 5 HARD no dia 1 da adoção dele.
# ⚠️ E o material DIDÁTICO (docs/materials/) também sai (2026-10-06): dado fictício não é conhecimento.
else files="$(cd "${ROOT}" && git ls-files '*.kg.yaml' 2>/dev/null | bash "${_KFP}" --filter-knowledge | sed "s|^|${ROOT}/|")"; fi
[ -n "${files}" ] || { echo "kg-corpus-grep: FAIL-LOUD — nenhum .kg.yaml no corpus (${ROOT}); não devolvo '0 achados' por corpus vazio" >&2; exit 2; }
LIST="$(mktemp)"; trap 'rm -f "${LIST}"' EXIT; printf '%s\n' "${files}" > "${LIST}"
# a lista vai por ARQUIVO, não por pipe: o heredoc do python abaixo É o stdin (bug medido no 1º dogfood: "0 grafos")
python3 - "${JSON}" "${ALL}" "${LIST}" "${PHRASE}" "${TOP:-0}" "${TERMS[@]}" <<'PY'
import sys,re,json,os
json_out=sys.argv[1]=="1"; all_status=sys.argv[2]=="1"
# ⚠️ argv[4] e o flag PHRASE; os termos comecam em argv[5]. Em modo frase os termos NAO sao
#    separados pelo chamador, entao a lista tem UM elemento e o casamento por substring ja e
#    o casamento de frase que se quer — o flag existe para o RELATORIO nao mentir sobre o modo.
phrase=sys.argv[4]=="1"; top=int(sys.argv[5] or 0); terms=[t.lower() for t in sys.argv[6:]]
files=[l.strip() for l in open(sys.argv[3],encoding="utf-8") if l.strip()]
hits=[]; graphs=0
for f in files:
    try: txt=open(f,encoding="utf-8",errors="replace").read()
    except Exception: continue
    graphs+=1
    g=os.path.basename(f)[:-8]
    node=None
    for line in txt.split("\n"):
        m=re.match(r'^\s*-\s+id:\s*(\S+)',line)
        if m:
            if node: hits.append(node) if node.get("_hit") else None
            node={"grafo":g,"id":m.group(1),"status":"","verified_at":"","source_tier":"","label":"","_hit":False}
            if any(t in node["id"].lower() for t in terms): node["_hit"]=True
            continue
        # ── CHAVE DE TOPO ENCERRA O NÓ (bug reportado pelo adotante `sge`, 2026-09-24) ──────
        # O loop abria um nó em `- id:` e engolia todo `label:` seguinte — inclusive os da seção
        # `edges:`, que também tem `- from:`/`label:`. Consequência medida: o ÚLTIMO nó de `nodes:`
        # herdava o label de CADA aresta e terminava com o da última, e qualquer termo presente no
        # label de qualquer aresta marcava `_hit` nele. Isso não é cosmético: o corpus é o PASSO 1
        # da skill `onion-research` ("corpus primeiro"), então um label trocado ali entra no Scope,
        # no Elenxo e no write(KG). A REGRA 82 (Os dois leitores do corpus CONCORDAM sobre quem é
        # nó) não pegou porque ela compara IDS — quem é nó — e não os CAMPOS de cada nó.
        # Qualquer chave sem indentação (`edges:`, `meta:`) fecha o nó corrente.
        # A 1ª cura fechava o nó em QUALQUER chave sem indentação. Funciona no schema real (todo
        # `.kg.yaml` desta casa tem `nodes:`/`edges:` no topo), mas trata INDENTAÇÃO e não SEÇÃO — com
        # `graph: / nodes: / edges:` aninhados o bug sobrevive idêntico. Achado por passada
        # adversarial, e o reparo é fechar em qualquer chave `edges:`/`meta:` QUALQUER QUE SEJA a
        # indentação dela, mais a regra antiga para as chaves de topo. Assim a guarda cobre o que ela
        # diz cobrir em vez de depender de o corpus nunca aninhar.
        if re.match(r'^\s*(edges|meta):\s*$',line) or re.match(r'^\S',line):
            if node and node.get("_hit"): hits.append(node)
            node=None
            continue
        if node is None: continue
        # ⚠️ `impact` e `confidence` ENTRAM por defeito medido (juiz do radar E3, rodada 6,
        # 2026-10-03): a saída imprimia `tier=` e NÃO imprimia os dois, e eu tratei três nós tier 9
        # — DOIS com impact 2 e um com confidence 0,4 e auto-rótulo "informação próxima de zero" —
        # como COBERTURA SELADA de seis versões do Claude Code, isentando-me de medi-las. O juiz
        # provou a falha colhendo um item de dentro da janela que eu declarei coberta.
        # A LIÇÃO QUE A COLUNA CARREGA: tier alto é qualidade da FONTE, nunca extensão da COBERTURA.
        # Quem usa o corpus para decidir o que NÃO medir precisa ler o quanto ele mediu — e esta cura
        # faz essa leitura acontecer por DEFAULT, em vez de depender de eu abrir o grafo.
        km=re.match(r'^\s*(status|verified_at|source_tier|impact|confidence|label):\s*(.*)$',line)
        if km:
            k,v=km.group(1),km.group(2).strip().strip("'\"")
            node[k]=v
            if k=="label" and any(t in v.lower() for t in terms): node["_hit"]=True
    if node and node.get("_hit"): hits.append(node)
if not all_status: hits=[h for h in hits if h["status"] not in ("refuted","superseded")]
for h in hits: h.pop("_hit",None)
if json_out:
    # ⚠️ `--json` com aviso em stderr QUEBRA quem captura `2>&1` (achado do Elenxo do PR #909): a
    #    linha de aviso precede o `{` e o payload deixa de ser JSON valido. `2>&1` e a convencao da
    #    casa nas diretivas injetadas, logo era armadilha armada. O aviso vai DENTRO do payload.
    print(json.dumps({"graphs":graphs,"terms":terms,"mode":("phrase" if phrase else "terms"),"hits":hits},ensure_ascii=False,indent=1)); sys.exit(0)
print(f"# corpus: {graphs} grafos · {'FRASE' if phrase else 'termos'}: {', '.join(terms)} · {len(hits)} nó(s)")
# ⚠️ ZERO NAO E RESULTADO (a mesma clausula que o forge-census declara, 2026-10-03): um `0 no(s)`
#    sobre corpus POPULADO quase nunca significa "o corpus nao sabe"; significa termo que nenhum
#    `id` nem `label` contem. Deixar o zero nu convida a conclusao de que o tema e inedito — e foi
#    exatamente o que aconteceu, com 120 grafos na mao.
if not hits and graphs:
    print(f"# ⚠️ ZERO sobre {graphs} grafos POPULADOS — zero NAO e resultado. O que checar, nesta ordem:")
    print("#    1. termo casa `id` ou `label` por SUBSTRING (sem stemming): 'laco' casa 'relacoes'; 'raio-X' nao casa nada")
    print("#    2. a busca e OR entre termos: um termo generico a mais AMPLIA, nunca restringe")
    print("#    3. status `refuted`/`superseded` sao ocultos por default — repita com --all-status")
    if phrase:
        print("#    3b. MODO FRASE: o casamento e LITERAL — pontuacao, acento e ordem contam. Tente os termos soltos")
    print("#    4. so entao conclua ausencia, e registre a LACUNA como no (nunca como silencio)")
# o corte acontece AQUI, onde o total ainda e conhecido — e ele se declara ao final
_shown = hits[:top] if top else hits
for h in _shown:
    print(f"{h['grafo']}\t{h['id']}\t{h['status'] or '-'}\t{h['verified_at'] or '-'}"
          f"\ttier={h.get('source_tier') or '-'}\timp={h.get('impact') or '-'}"
          f"\tconf={h.get('confidence') or '-'}\t{h['label'][:160]}")
if top and len(hits) > top:
    print(f"# ⚠️ LISTA CORTADA: {len(_shown)} de {len(hits)} nós acima (ordem do corpus, NAO por atenção).")
    print(f"#    Os {len(hits) - len(_shown)} restantes NAO estão aqui e NAO são zero. Para o conjunto,")
    print("#    repita sem --top; para estreitar de verdade, use termos mais específicos ou --phrase.")
PY
