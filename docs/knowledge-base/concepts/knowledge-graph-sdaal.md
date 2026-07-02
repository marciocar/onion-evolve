# Knowledge Graph SDAAL — fonte da verdade como grafo ponderado (CANDIDATA)

> **Status: CANDIDATA** — padrão recebido via co-evolução (sinal upstream
> `docs/evolution/inbox/_processed/2026-07-02-sinal-sdaal-knowledge-graph.md`), nascido e dogfoodado
> na instância **rhilo-metagamify** durante uma auditoria real de produção (WRR/Modo Equilíbrio,
> 01-02/jul/2026). Autoria do método: instância rhilo (T1 hub). Esta KB porta o **conceito
> generalizado**; a implementação de referência vive no rhilo (`scripts/kg/radar.js` +
> `docs/rhilo/graph/wrr-audit.kg.yaml`).
>
> **Gate (comando `/meta:kg`): fechado até o core dogfoodar o método uma vez** — a próxima
> auditoria/investigação longa do core deve modelar seus achados num `.kg.yaml` e só então o comando
> gradua (mesma doutrina gated-until-trigger de F2-F5). Construir o comando antes do dogfood seria
> construir à frente do gatilho.

## O problema que o padrão resolve

Investigações longas degradam para **log cronológico**: cada achado é datado e as auto-correções
("X era verdade → refutado") ficam enterradas em prosa. Consequências observadas em campo:

1. **Verdade×verdade não se confronta** — contradições espalhadas que o log não sabe que tem.
2. **Confusão DEV↔PROD** — conclusões tiradas do código lido (branch de trabalho) em vez do artefato
   vivo (commit deployado + flags + env + dados).
3. **Whack-a-mole** — variáveis compartilhadas alimentam gates com semânticas distintas; consertar um
   quebra outro sem aviso.

## O modelo

Um arquivo `.kg.yaml` (espírito [SDAAL](specification-driven-ai-abstraction-layer.md): spec
estruturada executável por IA) com **nós tipados** e **arestas tipadas ponderadas**:

- **`node_type`**: `entity` · `claim` · `decision` · `question` · `evidence` · `artifact`
- **`edge_type`**: `SUPPORTS` · `REFUTES` · `SUPERSEDES` · `CAUSES` · `DEPENDS_ON` · `TRACES_TO`
- **`plane`**: `DEV` (código/branch/commit) ou `PROD` (artefato vivo: deploy + config + dados)
- **peso do nó**: `impact` (1–5) × `confidence` (0–1) × `status` (`open|confirmed|refuted|superseded|done`)
- **migalha unificada**: aresta `TRACES_TO` → `{file:line | task | commit | env | reason | snapshot}`

O grafo é **append-mostly**: auto-correções viram arestas `REFUTES` explícitas — a história não se
apaga, se **reconcilia** (mesmo parentesco do protocolo de re-teste do diário: `superseded: true`,
nunca deletar — `/meta:diary review`).

## As três saídas (o que uma ferramenta `radar` computa)

1. **RADAR** — perguntas/decisões abertas ranqueadas por **atenção = impacto × confiança ×
   centralidade** (PageRank ponderado). Responde *o que fazer agora*.
2. **RECONCILIAÇÃO** — todas as arestas `REFUTES`/`SUPERSEDES`: verdades confrontadas, explícitas.
3. **INTEGRIDADE** — o grafo se contradiz? Reprova: nó `refuted` ainda recebendo `SUPPORTS`; `decision`
   `done` fora do plane PROD; órfãos; migalhas pendentes; ciclos `DEPENDS_ON`.

## Governança DEV↔PROD (a regra dura)

> **Comportamento em produção = artefato deployado + config viva + env + dados.**
> Uma `decision` só vira `done` quando **verificada no plane PROD** — "o código deveria" não fecha nó.

Evidência de campo no próprio core (mesmo dia, direção oposta): o incidente do **pin forjado**
(anúncio "você já tem o fix" raciocinou sobre o *carimbo* em vez do *artefato vendorizado*; guard
permanente: `.claude/validation/pin-integrity-check.sh`). A regra generaliza: **carimbo/doc/branch é
plane DEV; só o artefato vivo é plane PROD.**

## Anti-whack-a-mole (disciplina complementar)

- **SSOT-por-conceito**: uma variável = um significado; nomear distinto quando fluxos divergem.
- **Blast-radius**: modelar variável→consumidores (`DEPENDS_ON`/`CAUSES`) e listar consumidores
  **antes** de mexer.
- **Replay/golden-test**: snapshot→muda→replay+diff pega regressão em outro fluxo.
- **Invariantes como asserts testados**, não comentários.

## Generalização para o core (quando o gate abrir)

A implementação do rhilo reusa o stack ML dele (embeddings MiniLM, pgvector, grafo `ElementLink`) —
**não portar dependências**. A versão core deve ser **soberana e determinística** (bash/node puro,
zero serviço externo), como todo `.claude/validation/`. O MVP não precisa de embedding: RADAR +
RECONCILIAÇÃO + INTEGRIDADE são computáveis do YAML puro; similaridade semântica é Fase 2.

## Relações

- **≠ `/meta:graph`**: aquele é a lente sócio-técnica da *spec-as-code* (estrutura do framework);
  este é o grafo do *conhecimento de uma investigação* (claims/decisões/evidência). Complementares.
- **Parentesco**: protocolo de re-teste do diário (`/meta:diary review`); doutrina de dogfood
  ([onion-dogfooding-doctrine](onion-dogfooding-doctrine.md)) — "invoque o artefato e observe" é a
  regra PROD-plane em outra roupa.
- **Origem e crédito**: instância rhilo-metagamify, auditoria WRR (evidência: radar priorizou cura de
  raiz sobre paliativos; reconciliou 6 auto-correções como `REFUTES`; integridade pegou 3 órfãos).
