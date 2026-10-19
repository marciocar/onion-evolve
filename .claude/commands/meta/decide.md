---
name: decide
description: |
  Mede o que está em voo (checkpoints, PRs e CI, worktrees, inbox, nós citados), filtra o que é do
  maestro, pergunta em rodadas com opções e recomendação, e sela cada resposta no grafo. Para cada ato
  diz quem executa: oferece-se para fazer o que pode, e entrega o passo a passo do que é só do maestro.
category: meta
tags:
  - decision
  - kg
  - forge
version: "1.1.0"
updated: "2026-10-19"
related_commands:
  - /meta:drive
  - /meta:forge
  - /onion-research
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion, TodoWrite
---

# 🗳️ /meta:decide — o que está em voo vira questionário, e a resposta vira selo

Quando há opções, pendências e fios abertos, e principalmente quando há uma decisão a tomar ou um
entendimento a selar, este comando **mede** o que está acontecendo, **tira** o que a sessão pode medir
ou derivar sozinha, **pergunta** o resto ao maestro em rodadas estruturadas (cada opção com a sua
implicação, a recomendada primeiro) e **sela** cada resposta no grafo no mesmo movimento. A doutrina
inteira (as 8 cláusulas e o que ela não promete) vive em
[`common:prompts:decide-doctrine`](../common/prompts/decide-doctrine.md). **Referencie, não copie.**

**Por que existe:** pedido do maestro em 2026-10-12, forjado pelo `/meta:forge` no mesmo dia; decisão
de topologia e evidência em `docs/evolution/research/forge-decide-2026-10/`.

## Degrau e limites

- **Viaja para todo papel com KG** (core, onion-core, hub, adotado, standalone, plugins), por decisão do
  maestro em 2026-10-14; **não** vai para o onion-mini, que nasce sem KG por desenho. Maestro-invocado;
  sem cron, sem agendamento (MOAT).
- **Não decide pelo maestro** e **não sela o que não foi perguntado**.
- **O "sim" do maestro é a autorização; o ato vai pelo caminho da casa.** Merge de PR **deste** repo
  com o "sim" a sessão executa pelo caminho verificado (`faço-eu`). Merge em repo alheio, deploy e o
  que pede TTY, segredo ou corpo **continuam do maestro**: aí a sessão entrega o **card de passo a
  passo** (cláusula 8), nunca contorna o veto.

## Contexto medido injetado (peça 3 — o medidor roda ANTES de você pensar)

**Hoje:** !`date +%F`

!`bash .claude/validation/decide-census.sh . --markdown 2>&1 || true`

> ⚠️ **As duas linhas acima são diretivas de injeção — bang seguido de crase —, e o harness executa
> TODA diretiva do arquivo**, inclusive uma escrita como exemplo. Por isso a forma literal não aparece
> em mais nenhum lugar daqui: é descrita, nunca escrita (lição paga pelo `/meta:forge-guard`, e a
> mesma advertência do `/meta:cc-update`). O `|| true` existe para que a carga do comando não morra
> quando o medidor sai rc 2: a mensagem dele (grafo que não parseia, PyYAML ausente) chega no texto
> injetado, e isso **é** a medição.

Leia o censo como ele se declara: ele lista o que está **em voo**, com origem citável; ele **não**
diz o que é do maestro (esse é o passo 2), e os "trechos com forma de opção" são cópia literal, não
opções compostas. Quando a linha traz **quem chega por aresta**, leia esses nós antes de compor:
opções e objeções às vezes vivem neles, não na prosa do nó. Os avisos (gh indisponível, override ativo, teto) vêm antes das linhas: **ausência
de linha com aviso não é zero**.

Cada linha traz **quem executa** o ato seguinte e o comando pronto (`▶`), e a linha `quem executa:`
conta as quatro classes. A classe só sai onde a medição a prova; a **pista de ato manual** das linhas
`seal` é cópia literal do nó (pode errar para os dois lados), e quem decide o card é você, lendo o nó.

| Classe | Quando (medido) | O que você faz |
|---|---|---|
| 🤖 **faço-eu** | a sessão executa: selo, checkpoint, merge **deste** repo pelo caminho verificado, triagem, a worktree onde o medidor roda | **oferece-se**: "Eu faço agora (Recomendado)" |
| ⌨️ **maestro-com-!** | merge de PR de **outro** repo (`--foreign-repo`): no core o veto (exit 2) barra a sessão e o prefixo de bang no prompt do maestro não passa por ele; em todo papel, repo alheio não é da sessão (MOAT) | entrega o **card**, com `! ` na frente de cada comando |
| 🙋 **maestro-fora** | precisa do que a sessão não tem: TTY, navegador, segredo, corpo (o `gh auth login`) | entrega o **card**, dizendo **onde** rodar |
| ↪️ **outro-dono** | worktree de outra sessão ou agente (I3), e o PR cuja branch está numa delas | vai para "o que o filtro tirou", **sem** oferta de mexer |

## Procedimento

1. **MEDIR.** O censo injetado acima é a medição sem a conversa. Rode-o de novo com o que a sessão
   sabe: `--cite -` recebendo pela entrada o texto que cita ids (as decisões mencionadas na conversa,
   o que o maestro escreveu ao invocar), e `--theme "<termos>"` quando houver tema. Exemplo:
   `printf '%s' "<texto com os ids>" | bash .claude/validation/decide-census.sh . --markdown --cite -`.
   A conversa citou PR de **outro** repo? Passe `--foreign-repo <dono/nome>` (repetível): os PRs de lá
   entram com o CI e o método de merge que o repo aceita, medidos.
   Linha de erro (rc 2) → declare a lacuna e pare; nunca reconstrua os fios de memória. Precisa do
   conjunto inteiro (o markdown corta no teto e **nomeia** o resto)? `--tsv` (colunas `actor`,
   `action` e `hint` no fim).
2. **FILTRAR** (cláusula 1 da doutrina). Para cada linha: é **medível**? meça e reporte. É
   **derivável** da doutrina ou de decisão selada? aplique e cite. É de **outro dono** (repo alheio,
   outra sessão, merge/deploy)? encaminhe. O que sobra é do maestro. Guarde a lista do que saiu e o
   porquê: ela vai no relatório. **O que saiu não se sela pelo selador** (ele grava testemunho do
   maestro): nó fechado por medição fecha pelo `/meta:kg-freshness` ou pelo fluxo normal, nunca "em
   lote, sem pergunta". Para filtrar, **leia o nó** (e quem chega por aresta) — o texto do censo é
   recorte, não o nó. Fechando o filtro, **classifique quem executa** cada ato que sobrou (cláusula
   8): a classe do censo onde ela veio medida; nas linhas `seal`, a decisão é do maestro e o selo é
   seu, mas o ato **depois** do selo pode ser dele (a pista diz onde olhar).
3. **COMPOR as rodadas** (cláusulas 2 a 4). Até **4 perguntas por rodada**, **2 a 4 opções** por
   pergunta, `header` com até 12 caracteres, ordem **bloqueio → atenção** (a do censo). Cada opção:
   rótulo curto e descrição com **custo, o que destrava e o que fica gated**. A recomendada é a
   **primeira**, com o rótulo terminando em "(Recomendado)" e o porquê na descrição. Faltou
   embasamento? Uma opção é "pesquisar antes" (`/onion-research`, modo `decision`). Mais de 4
   perguntas → anuncie ao maestro as que ficam para a rodada seguinte, pelo nome, antes de perguntar.
   **Ato, não decisão** (cláusula 8): o que é **faço-eu** vira a pergunta "faço?", com
   **"Eu faço agora (Recomendado)"** primeiro (a descrição diz o comando, o custo e o que destrava),
   **"Me dê o passo a passo"** e **"Depois"**. O que é **maestro-com-!** ou **maestro-fora** vira
   **"Me dê o passo a passo (Recomendado)"**, **"Já fiz, confira"** (você roda a conferência do card)
   e **"Depois"**. Decisão cuja execução é do maestro carrega isso na própria opção ("selar e receber
   o card"), em vez de gastar uma 2ª pergunta.
4. **PERGUNTAR** com `AskUserQuestion`. Uma rodada por vez.
5. **SELAR** (cláusulas 5 a 7), resposta a resposta, **antes** da rodada seguinte, sempre pelo selador
   (peça 5), nunca editando o grafo à mão:
   - nó existente (`decision`/`question` `open`):
     `bash .claude/validation/kg-decide-seal.sh <grafo> <NODE_ID> --chosen "<opção>" --rejected "<a|b>" --date <hoje> --question "<pergunta>"`
   - decisão sem nó: `--new D_<ID> --label "<afirmação>" --link <nó de onde veio>` no grafo do tema;
   - resposta livre ("Other"): a mesma chamada com `--other`; ambígua → não sela, pergunta de novo.
   - **checkpoint** do `/meta:drive` respondido "selar": o selo é do mecanismo dele,
     `bash .claude/validation/kg-drive-project.sh <grafo> --seal` (o selador desta peça não escreve
     `meta`); **merge** deste repo respondido "Eu faço agora": rode o comando da linha (o caminho
     verificado, que recusa CI vermelho; recusou → diga por quê, não contorne); merge de **outro**
     repo: o card, que o maestro roda com o prefixo de bang.
   O selador sai **0** só com o radar `--integrity --schema` exit 0 (e o contrato, onde vendorizado);
   **2** = recusou e nada escreveu (nó inexistente, já `done`, campo cego, id duplicado); **3** = o
   gate reprovou e a escrita foi **desfeita**. Em 2 ou 3, leia a mensagem, conserte a causa e
   re-tente; nunca contorne pela edição à mão.
6. **EXECUTAR o que é seu.** Cada "Eu faço agora" roda **já**, na ordem da rodada, e o resultado
   (rc, o que mudou) entra no relatório. Falhou? Diga o rc e a causa, e ofereça o card.
7. **PRÓXIMOS MOVIMENTOS.** Devolva ao maestro, nesta ordem, denso e escaneável:
   - ✅ **feito agora**: o que foi selado (nó, grafo, escolhida) e o que você executou;
   - 🧭 **cards do maestro**: um por ato **maestro-com-!** / **maestro-fora**, na forma da cláusula 8
     (objetivo, por que é dele, pré-condição medida **agora**, passos copiáveis, como conferir, tempo,
     o que você faz depois). Re-meça a pré-condição antes de escrever o card: card de ontem é palpite;
   - ↪️ **o que o filtro tirou** e por quê (medido · derivado · de outro dono);
   - ⏭️ **em voo**, o que ficou para "Depois", pelo nome.
   Commit dos grafos tocados no fluxo normal da sessão, com o selo e o trabalho no mesmo PR quando for
   o caso.

## Destino (peça 5)

O selo no nó, escrito por `.claude/validation/kg-decide-seal.sh`, com o **radar exit 0**
(`kg-radar.sh --integrity --schema`) como condição de sucesso e o desfazer automático quando ele
reprova. O **contrato de custo** (`run_id` · `tokens` · `agents` · `duration_min`) **não se aplica**:
não há run de workflow, e medidor e selador são 0 tokens. Declarado aqui e na doutrina.

## Peça 4 (orquestração faseada) — AUSENTE por desenho, declarado

Uma sessão, um questionário: medir, filtrar, perguntar e selar são seriais e dependem do maestro a
cada rodada; não há fan-out com independência real, e um `.claude/workflows/*.js` seria coordenação
sem nada a coordenar. **Gatilho nomeado:** o filtro (passo 2) passar a exigir medição paralela pesada
por linha (por exemplo, re-verificar dezenas de nós contra o vivo antes de perguntar), que é trabalho
do `/meta:kg-freshness` e, se virar rotina aqui, pede a peça 4.

## Peça 6 (lente) — sem lente PRÓPRIA, por desenho, declarado

Não há diretório próprio a vigiar: o comando escreve em qualquer grafo do tema, e os grafos já têm a
lente da gramática (`.claude/rules/kg-grammar.md`, que carrega ao tocar um `.kg.yaml`) — é ela que o
censo da forja conta na coluna 6, e é a que de fato carrega quando o selo toca o grafo. Uma lente nova
sem caminho próprio reprovaria na REGRA 53 (Regra path-scoped declara `paths:` que casa algo real) ou
duplicaria a existente. **Gatilho nomeado:** nascer um diretório de selos próprio (por exemplo, um
registro de decisões por sessão), e aí a lente se deriva do caminho medido.

## O que este comando NÃO faz

- Não decide pelo maestro, não sela o que não foi perguntado e não grava recomendação como resposta.
- Não re-pesquisa: sem embasamento, a opção é "pesquisar antes" (`/onion-research`, modo `decision`).
- Não faz merge sem o "sim" do maestro, e com ele só pelo caminho verificado; não faz deploy nem
  escreve em repo alheio (MOAT), e para esses entrega o card; não muda hook, guarda ou regra.
- Não contorna veto: o card existe **porque** a sessão não pode, e nenhum passo dele pede à sessão
  o que o veto barra.
- Não lê o transcript: o que foi dito na conversa entra pelo `--cite`.
- **Não vai para o onion-mini.** Desde 2026-10-14 ele está no conjunto `full` do `roles.yaml` e viaja
  para todo papel que tem KG (o medidor, o selador e o radar viajam junto, em `.claude/validation/`). O mini
  nasce sem KG por desenho, e um selo lá não teria onde gravar. Esta superfície não cita `ops/` (REGRA 100
  (Superfície que viaja não cita ops/ como se o destinatário o tivesse)).

## 🔗 Referências

- Doutrina (peça 2): [`common:prompts:decide-doctrine`](../common/prompts/decide-doctrine.md)
- Medidor (peça 3): `.claude/validation/decide-census.sh` · destino (peça 5):
  `.claude/validation/kg-decide-seal.sh` · bancada (peça 7): `run_decide_selftests`
- Lente da gramática que já cobre os grafos tocados: `.claude/rules/kg-grammar.md`
- Molde: [`/meta:cc-update`](cc-update.md) (peças 2, 3, 7) e o checkpoint do [`/meta:drive`](drive.md)
