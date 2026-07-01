---
title: 'Sinal de campo — Capability "Descoberta Adaptativa Object-Led" (promover objeto a papel sem migração imperativa)'
date: 2026-06-29
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (maestro principal / core)
re: gap de método ao "promover X a um componente premium" — feito imperativo (migração à mão ×N) em vez de descoberta dirigida pelo objeto; dogfood = DataTable premium do dashboard de gamificação
type: field-signal
status: assess
related:
  - docs/analysis/onion-adr-capability-contract-2026-06.md      # framework onde isto encaixa (aceito)
  - docs/analysis/onion-research-self-describing-components-2026-06.md  # Information Expert / self-describing
  - docs/sdaal/sdaal.md                                         # adapters provider-agnósticos (LLM=VM)
  - docs/evolution/rfc/rfc-0002-meta-strategy-verdict.md        # catálogo-first ratificado
  - docs/evolution/inbox/_processed/2026-06-25-sinal-mecanica-transporte-regime-manual.md  # S2 (precedente de tom)
---

# Sinal de campo — Capability "Descoberta Adaptativa Object-Led"

> **TL;DR.** Quando o maestro pede "promova este objeto a um padrão premium" (ex.: uma `<table>` solta → um
> componente de tabela reutilizável e rico), o agente hoje **improvisa o método imperativamente**: lê
> exemplos, infere requisitos, escolhe ferramentas e migra à mão, caso a caso. Funciona, mas é
> **não-reproduzível, não-catalogado e dependente da atenção do operador**. Proponho **canonizar o ciclo**
> como uma capability Onion: **espelhar → descobrir (object-led) → vestir (capability-fitting) →
> materializar (dirigido pelo maestro)**. É **adaptação** — o centro do Onion — operacionalizada por
> **transformer + SDAAL**. As peças já existem no core (Capability Contract, Self-Describing Components,
> SDAAL, catálogo-first); falta a **síntese operável**. `status: assess` — veredito é do maestro principal.

## 1. Incidente que originou o sinal
Numa sessão do rhilo-app (frente: dashboard de gamificação WRR), o maestro pediu "promover as tabelas a um
componente premium". A execução foi **imperativa**: destilei um `<DataTable>` canônico a partir de exemplos
ricos do próprio repo (FoldersTable/UnifiedFoldersTable), inventariei as ~13 tabelas, escolhi a stack
(@tanstack/react-table + xlsx, já instaladas) e **migrei tabela a tabela à mão** (piloto: SlaConfigTable,
OverridesEditor). A cada novo pedido do maestro ("faltou seletor", "tela cheia", "dimensionar/travar
coluna"), eu **re-improvisava** o acréscimo no core.

O maestro nomeou o gap: eu **deveria ter instanciado um módulo de descoberta** — um stub/draft/clone/adapter
que se **veste** sobre o objeto, faz a descoberta do que ele precisa e então desempenha o papel. *"Quem sabe
sobre o objeto é o próprio objeto"* — o objeto se apropria de ferramentas/estratégias/técnicas para cumprir
um papel. Isso é adaptação pura; o transformer só atinge eficácia/eficiência máximas se o **fluxo for
dirigido** (human-in-the-loop).

## 2. Cinco porquês → causa-raiz
1. Por que foi imperativo? Porque não há uma função Onion para "promover objeto a papel".
2. Por que não há? Porque o método de descoberta+fitting vive só na cabeça do agente, recriado a cada vez.
3. Por que isso é problema? Não é reproduzível nem catalogável; a qualidade depende da atenção pontual.
4. Por que importa agora? Porque o mesmo ciclo vai se repetir em N objetos (tabelas, forms, dashboards,
   integrações) — é um **padrão de trabalho**, não um caso isolado.
5. **Causa-raiz:** falta canonizar o ciclo **object-led discovery + capability-fitting** como capability
   dirigível, ancorada nas peças que o core já tem.

## 3. Grounding (não é invenção — é síntese)
- **Information Expert / Self-Describing Components** (`onion-research-self-describing-components-2026-06.md`):
  "quem responde sobre o objeto é o objeto" — exatamente o princípio que o maestro enunciou.
- **Capability Contract** (ADR aceito): `provides/requires/loads` + conformance Bronze/Silver/Gold — o
  formato em que o objeto descreve o que sabe/precisa e em que maturidade está.
- **SDAAL** (`sdaal.md`): adapters provider-agnósticos com **LLM=runtime, Markdown=bytecode** — a forma de
  "vestir" o objeto de ferramentas/estratégias sem código intermediário.
- **Catálogo-first / Strategy-Playbooks** (RFC-0002, ratificado): reconhece situação → fluxo → grupo de
  ferramentas → reroute; resíduo sem-match vira novo playbook. O ciclo proposto **alimenta** esse catálogo.
- **Transformer dirige o fluxo:** o poder não está em "o LLM decide tudo", e sim em **o maestro direcionar**
  um ciclo que o transformer executa com as peças certas à mão.

## 4. Proposta (superfície mínima para o maestro avaliar)
Canonizar uma capability — nome de trabalho **`object-led discovery & fitting`** (ex.: invocação
`/onion:promote <objeto> --to <papel-alvo>`) — que executa um ciclo **dirigível**:

1. **Espelhar** — cria um *stub/draft* do objeto (worktree/clone descartável), sem tocar o original.
2. **Descobrir (object-led)** — introspecta o objeto e seus pares no repo; monta um **Capability Contract**
   (o que ele provê, o que requer, em que tier está) — a descoberta parte do objeto, não de suposição.
3. **Vestir (capability-fitting)** — seleciona, do catálogo/SDAAL, os adapters/estratégias/técnicas que o
   **papel-alvo** exige (ex.: "tabela premium" ⇒ sort/filtro/export/pin/resize/seleção), reusando o que já
   existe no repo antes de criar.
4. **Materializar** — aplica sob **direção do maestro** (gates por etapa), com verificação (tsc/build/test).
5. **Realimentar** — o resíduo (o que não casou com nenhum playbook) vira **novo playbook** no catálogo
   (fecha o loop do RFC-0002).

**Encaixe (não é skill solta):** estende o **Capability Contract** (o objeto auto-descreve) + o **catálogo
de playbooks** (o reconhecedor situa "promover a papel X") ; os "trajes" são abstrações **SDAAL**. Coerente
com a doutrina catálogo-first e com a toolbox `create-*` (sinal S1) — provável parente de
`@onion:create-*`, porém **partindo do objeto existente** (promoção), não do zero (criação).

## 5. Questões ao maestro principal (com nossa inclinação)
- **(a) Forma:** vira ADR + skill própria, ou extensão do strategy-playbooks + Capability Contract?
  *Inclinação:* extensão (menor superfície, casa com RFC-0002), com uma skill fina de orquestração.
- **(b) "Espelho/stub":** artefato físico (worktree/draft descartável) ou conceitual (plano)?
  *Inclinação:* físico quando há risco de mutação (migração de N arquivos); conceitual quando é leitura.
- **(c) Gate assess→trial:** qual o 1º caso canônico? *Inclinação:* o **próprio DataTable premium** (já
  temos o resultado à mão — bom baseline para medir "dirigido vs improvisado").
- **(d) Relação com `create-*`:** "promover" (objeto existe) vs "criar" (do zero) — mesmo toolbox, gatilho
  diferente?

## 6. Evidência anexa (dogfood desta sessão)
O DataTable premium foi construído **imperativamente** — e essa é a prova do gap. Artefatos no rhilo-app
(branch `feat/gamification-dose-viz`): `apps/frontend/src/components/data-table/*` (core: DataTable,
Toolbar, ColumnHeader, useTableView, export-table) + migração das âncoras `SlaConfigTable.tsx` e
`gestao/OverridesEditor.tsx`. Capacidades acumuladas por pedidos sucessivos do maestro (sort/filtro/busca/
agrupar/expandir/colunas/export/salvar-visão/seleção+bulk/tela-cheia/densidade/resize/pin). Uma capability
**object-led** teria dirigido o **mesmo resultado** de forma **reproduzível e catalogada** — em vez de
re-improvisar a cada interação.

> **Pedido ao maestro:** avaliar (`assess`) se esta capability entra no roadmap do core e em que forma.
> Não é decisão do adotante — é sinal de campo nascido de operar o Onion + transformer + SDAAL no dia a dia.
