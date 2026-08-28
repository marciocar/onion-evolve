---
date: 2026-08-28
instance: onion-evolve
type: learning
classification: public
tags: [regra-62, projecao-gerada, catraca, dogfood, bancada, fail-open, gated-until-trigger]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "guarda nova: escrever o caso de modo-de-falha ANTES de acreditar na regra — foi o caso que reprovou que achou a falha destrutiva, não a leitura do código"
review_after: 2026-11-26
conflict_class: dynamic
significance: "A pergunta do maestro ('não é hora de um comando de gestão de backlog?') respondeu-se com NÃO — o que faltava era catraca, não superfície. E a bancada que escrevi para provar a catraca achou um defeito destrutivo meu que a leitura do código não tinha achado."
kg: "docs/onion/graph/guardas-revisao-2026-08.kg.yaml"
---

## Signal
**A resposta certa para "falta um comando?" foi "não — falta catraca".** E o caminho até lá passou por
um defeito **destrutivo** que só apareceu porque um caso de teste reprovou.

## Evidence
- **A pergunta e a régua:** "gestão de backlog" não tem *fronteira distinta* — o território já está
  repartido entre projeção (`/meta:backlog`), teto+carimbo (REGRA 58), condução (`/meta:drive`) e
  drift (`/meta:realign`). Comando novo **substituiria** pedaços deles em vez de compor. E dispatcher
  também não: o `§4.2` consolida **N verbos que já existem**; aqui N=1. Inventar seis subcomandos para
  depois "consolidá-los" inverte a regra — seria a catedral do `.onion/` repetida por simetria.
- **O gatilho real estava escrito no corpus, num nó ABERTO:** `Q_INDICE_DO_DIARIO_SEM_CATRACA`
  prescrevia *"uma checagem determinística de projeção-vs-fonte no lint"*. Não é vontade — é uso que
  já falhou.
- **O defeito destrutivo, achado pela bancada e não pela leitura:** o projetor enumera grafos por
  `git ls-files`. Sem índice git (ou com `GIT_DIR` torto — incidente já medido em 04/08) isso devolve
  vazio e o render sai com cabeçalho e **zero itens**. Não é vazio o bastante para o `_gen_into`
  chamar de QUEBRA → viraria **DRIFT**, e a mensagem mandaria **regenerar por cima**, sobrescrevendo
  a projeção boa por uma quase-vazia. Falha aberta que vira **destrutiva**, entrando pelo lado do
  *gerador* — exatamente a classe que o `_gen_into` existe para impedir do lado da *detecção*.
  A mutação que remove a cura devolve `mutou=SIM`: a sobrescrita acontece de verdade.
- **Dois outros modos de falha fechados no caminho:** `MODE="${1:---write}"` era **fail-open num
  caminho de escrita** (`--dry-run` sobrescrevia em silêncio); e o `iconv` degradava para `cat`, o
  que faria a catraca HARD acusar **o ambiente** em vez do conteúdo.
- **O que NÃO foi construído, e por quê:** `owner:` é lido pelo projetor desde a origem e **nunca foi
  escrito por ninguém** (0 ocorrências), enquanto três lugares em prosa prometiam agrupamento por ele.
  O gatilho disparou para **honestidade**, não para mecanismo: a projeção passa a **imprimir** que
  zero nós declaram `owner`. Mesma assinatura que originou a REGRA 58.
- **O que ficou aberto por medição, não por esquecimento:** tentei estender a catraca ao índice do
  diário e **não deu** — `diary-index.sh` trata o 1º argumento como *caminho do repo* (chamá-lo com
  `--markdown` criaria um diretório com esse nome) e o índice embute `Gerado em: <hoje>`, o que faria
  a comparação por bytes disparar **todo dia**. O nó segue aberto com o gatilho refinado. Fechá-lo
  agora seria fechá-lo por decreto.

## Next crumb
- Antes de acreditar numa guarda nova, escrever o caso do **modo de falha** e vê-lo reprovar. Aqui,
  o caso que reprovou foi o que achou a falha destrutiva; a leitura do código não a tinha achado.
- Gerador que enumera por `git ls-files` deve tratar **enumeração vazia como QUEBRA**, nunca como
  "zero resultados" — a diferença entre as duas é um arquivo bom sobrescrito.
