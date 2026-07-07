# Semente de pesquisa — o Onion como lente para modelos × o significado de "lente" no Onion hoje

> **Status: SEMENTE (2026-07-06)** — plantada pelo maestro numa rodada de sementes especulativas
> ("de forma independente, sem julgamento"). Território **novo** como conceito formal — mas o
> vocabulário "lente" já é usado no Onion, só que com outro sentido. Ver §1.

## Por que esta pesquisa

O maestro pergunta: como ser uma lente para modelos — o Onion como camada que medeia, interpreta
ou expõe acesso a modelos de terceiros, em vez de ser ele mesmo um modelo (semente
`onion-as-model`) ou orquestrar vários (semente `federated-slm-orchestration`).

**"Lente" já é palavra viva no Onion — mas nunca com esse sentido.** Todo uso encontrado é
metáfora de **perspectiva de leitura sobre o próprio sistema**, nunca "camada sobre modelos
externos":
- `/meta:graph` se autodescreve como *"a lente sócio-técnica do Onion"* — um grafo gerado da
  spec-as-code, que o Transformer lê para achar caminho/impacto/órfãos. É uma lente sobre o
  **conhecimento do Onion**, não sobre modelos.
- O judge-panel de orquestração usa "lentes diversas" (`onion-orchestration-math-phase-transition-
  2026-06.md`) no sentido de **pontos de vista de avaliação** (correctness/security/perf), não de
  acesso a modelo.
- A "lente do Onion" sobre PLEA/SRL é leitura interpretativa de uma teoria, não infraestrutura.

O vizinho mais próximo de "lente sobre modelos de terceiros" é, de novo, `llm-provider` —
abstração do roadmap do SDAAL (`docs/sdaal/sdaal.md` §10.4, não construída), que abstrai *qual*
modelo executa por trás de uma interface única. Mas isso é abstração de **acesso** (troca de
provider), não necessariamente "lente" no sentido de **interpretação/tradução** entre modelos e o
resto do sistema.

## Questões de pesquisa

**Q1 — "Lente" nesta semente significa o quê, exatamente?** Ao menos duas leituras possíveis, que
a pesquisa deveria separar antes de prosseguir: (a) o Onion como **abstração de acesso** — uma
interface única por trás da qual qualquer modelo (Claude, GPT, Gemini, um SLM local) pode ser
chamado, tipo `llm-provider` levado a sério; (b) o Onion como **camada de tradução/interpretação**
— pegar o output bruto de um modelo qualquer e reformatá-lo/verificá-lo/contextualizá-lo segundo a
doutrina do Onion (mais parecido com o que o SDAAL já faz para *providers de negócio* — task
manager, forge — aplicado a modelos de IA em vez de APIs de produto).

**Q2 — Isso já está acontecendo, sem nome formal?** O onion-mini já É, na prática, o master-prompt
(doutrina) sendo interpretado por qualquer Transformer — Claude, e desde esta sessão também GPT
via Custom GPT. Isso já é uma forma primitiva de "lente sobre modelos" (a doutrina é a lente; o
modelo por baixo é intercambiável) — só que hoje só é discutido como "distilação/produto-irmão",
nunca nomeado como "lente". A pesquisa deveria checar se nomear formaliza algo útil, ou se é
etiqueta nova pra comportamento que já existe.

**Q3 — Onde isso colide com a rejeição de model-routing multi-LLM.** Se "lente" na leitura (a) —
abstração de acesso a qualquer modelo — é essencialmente o mesmo território da semente
`federated-slm-orchestration` e da rejeição já registrada em `onion-engine-economy.md` §5. A
pesquisa precisa dizer se a leitura (b) (tradução/interpretação, não escolha-de-orquestrador)
escapa dessa rejeição por ser uma categoria genuinamente diferente, ou se é a mesma ideia com outro
nome.

## Método previsto

Não é pesquisa externa pesada — é primariamente **clareza conceitual interna**: uma sessão
dedicada a decidir qual das leituras (Q1) é a que o maestro tem em mente, testando cada uma contra
o vocabulário já controlado (`onion-relation-vocabulary.md`) e contra a rejeição de Q3. Só depois
de resolver isso vale abrir pesquisa externa (ex.: como outros frameworks de abstração de LLM —
LangChain, LiteLLM — tratam essa camada, e o que isso ensina sobre riscos de "bootstrapping
estranho" já citados contra `llm-provider`).

## Gatilho

O maestro pede ("vamos esclarecer o que 'lente pra modelos' significa") → executar a partir DESTA
semente, começando pela clarificação conceitual (Q1), não pela pesquisa externa. Registro na
memória da sessão: `sementes-modelo-federacao-lente-radar-2026-07` (ponteiro consolidado).
