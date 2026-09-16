---
title: "ADR — Design estende o KG (não ganha grafo próprio): divergir vs reger, atom-map como join"
date: 2026-07-09
type: adr
status: accepted
decision-scope: design + investigation (KG-SDAAL)
supersedes: none
related:
  - onion-adr-comms-transport-vs-execution-2026-06.md
  - onion-adr-verticals-investigation-cartography-2026-07.md
  - ../evolution/inbox/_processed/2026-07-09-sdaal-generaliza-para-design-ia.md
  - ../knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md
---

# ADR — Design estende o KG (não ganha grafo próprio)

| Campo | Valor |
|-------|-------|
| **Decisão** | A vertical de **design** e o **KG-SDAAL** são **eixos ortogonais**, não concorrentes: design **DIVERGE** (generativo — largar N versões, gate WCAG decide) e o KG **REGE** (rastreabilidade + fonte-única, depois de decidir). A rastreabilidade de átomos de front (`atom-map`/`SourceTag`) **estende o KG dogfoodado** — **não** constrói um 2º grafo/registro de "fonte da verdade". |
| **Escopo** | Design + investigação (KG). Não toca produto/engenharia/compliance nem o transporte. |
| **Status** | ✅ **Aceito (doutrinário)** — 2026-07-09. Doutrina; **zero código agora**. A materialização (átomos de design como nós do KG) fica **gated no artefato** `atom-map` de um adotante (declarado≠verificado). **Gate SATISFEITO em 2026-07-09** — o artefato real chegou via relay de OUTRO adotante (inbox/_processed/2026-07-09-artefato-command-center-atom-map.md (core-only)): ~35 átomos com fonte/dono-de-exibição/dono-de-escrita, ledger de de-dup e invariante grep-verificável. **Materialização EXECUTADA em 2026-07-10** (branch `feat/kg-domain-layer`): átomo = nó `layer: domain`, fonte-única = checagem do radar-de-domínio (`kg-radar.sh`), doutrina na KB [knowledge-graph-sdaal §design/atom-map](../../knowledge-base/concepts/knowledge-graph-sdaal.md). |
| **Origem** | Síntese do maestro ao triar o sinal 2 de um adotante (SDAAL→design): "cara-crachá interessante… a questão é manter eficiência e eficácia **sem sobrepor**". |

---

## Status
✅ **Aceito (doutrinário)** — 2026-07-09. Decide a **postura de não-sobreposição**; a implementação (nós de
design no KG + checagem de integridade) liga quando o artefato `atom-map` real chegar (relay de um adotante).
**Update (mesmo dia, triagem noturna):** o artefato chegou — relay de OUTRO adotante (não do que pediu),
arquivado em `../evolution/inbox/_processed/2026-07-09-artefato-command-center-atom-map.md`. O gate está
satisfeito; a materialização é item de backlog aberto (não executado nesta triagem).
**Update 2026-07-10:** materialização **executada** junto com a promoção da camada domain (sinal
kg-dogfood-completo): schema do átomo (`entity` + `READS`/`WRITES`/`TRACES_TO`), checagem fonte-única no
radar-de-domínio e doutrina na KB. `SourceTag` permanece adaptador do adotante — o core não ganhou motor de UI.

## Contexto
Duas forças convergiram e **pareciam competir**:
1. **Vertical de design (generativa):** `brand-generator` larga N candidatas → gate **WCAG** decide
   (`/design:generate`). É *explorar o espaço*.
2. **Sinal de um adotante (estrutural):** ao redesenhar o front, o mesmo método do KG-SDAAL curou a UI "por
   identidade, não por analogia": **`atom-map`** (1 átomo = 1 fonte + 1 dono-de-exibição + 1 dono-de-escrita) +
   **`SourceTag`** (rastreabilidade como componente) + invariante de fonte-única verificável por grep.

O risco que o maestro apontou: se o design ganhar um **registro paralelo** de "fonte da verdade" só para o
front, cria-se **sobreposição** com o KG (que já é o substrato de rastreabilidade) — dois motores para a mesma
função, contra "eficiência e eficácia sem sobrepor".

## Decisão (o desenho)
- **Dois eixos ortogonais, não concorrentes.** *Divergir* (generativo) é **antes** de decidir; *reger*
  (fonte-única) é **depois**. Não se sobrepõem porque são **fases** distintas.
- **`atom-map` = JOIN, não novo grafo.** `design-context/` é o **conteúdo** (tokens); o **KG** é a **relação**
  (`TRACES_TO`); o `atom-map` é o **join** entre eles. Um átomo de UI vira **nó de 1ª classe do KG**.
- **`SourceTag` = aresta `TRACES_TO` renderizada** — **adaptador**, não motor. A *ideia* (rastreabilidade-como-UI,
  fonte-única no front) é **framework**; a *impl React* (`SourceTag`) é **do adotante** — absorve-se o conceito,
  não o código.
- **O "cara-crachá" = a checagem de integridade.** Verificar que o valor **renderizado** (dono-de-exibição)
  usa o crachá da sua **fonte real** (dono-de-escrita) é o padrão [`verify-read-path-first`](../../knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md)
  aplicado ao frontend → vira uma **checagem de integridade do KG** (radar do `/meta:kg`, irmã do gate do
  `.kg.yaml`), **não** um mecanismo novo de design.
- **"2+ versões" não conflita com fonte-única.** São eixos de versão distintos: **candidatas** (no espaço,
  muitas ao mesmo tempo — generate-and-filter) vs **`SUPERSEDES`** (no tempo, verdade que evolui). Fonte-única
  é sobre **uma** verdade autoritativa por átomo **numa** versão. Muitas candidatas a montante, um dono a jusante.

## Consequências
- **Não fazer:** um grafo/registro de fonte-da-verdade só para design (sobreposição). **Não** portar o
  `SourceTag` React para o core (é do adotante).
- **Fazer (quando destravar):** átomos de design como nós do KG; invariante fonte-única como checagem de
  integridade no radar do `/meta:kg`. Generation continua a **frente divergente**; o KG continua a
  **governança atrás**; o `SourceTag` é **adaptador**.
- **Alinha** com `onion-adr-verticals-investigation-cartography` (KG-SDAAL como espinha da investigação) e com
  a resposta downstream ao adotante (vertical design já existe; mapear atom-map contra ela).

## Gatilho de materialização (gated)
Ligar quando o **`atom-map` real** de um adotante for relayado (o sinal pediu; ainda não ancorado no core —
declarado≠verificado). Aí: 1 dogfood modelando átomos de design no KG + a checagem de integridade. Até lá,
**doutrina de postura**, sem código.
