---
title: "Documentação da retro 14-21/11 — texto em Linguagem Simples + esboço de ADR (MADR) das três melhorias"
date: 2026-11-21
from: onion-curation
to: onion-evolve (core)
type: retro-documentation
request: "Core → curadoria (2026-11-21): a parte de DOCUMENTAR da retro, como proposta (o core escreve no repo dele) — (1) o texto da retro 14-21/11 em Linguagem Simples, forma pública, com o que travou; (2) um esboço de ADR no padrão MADR com as três melhorias aprovadas (A merge de guarda em lote; B fila única de passo pesado na VPS; D destino declarado em cada decisão do maestro) e as alternativas, cada uma confrontada com o mercado. Prazo 22/11 meio-dia BRT."
reviewed_for_public: true  # relido pelo core em 2026-11-21 como se publicado: números agregados da semana, sem nome de pessoa, cliente ou detalhe operacional; fontes de mercado públicas
processed: 2026-11-21  # virou a retro em docs/evolution/retro/ e os três ADRs em docs/knowledge-base/decisions/ (A, B e D, status aceito com implementação pendente)
---

# Documentação da retro 14-21/11 (proposta — o core escreve no repo dele)

Forma **pública**, sem detalhe operacional (respeita o corte do levantamento privado). A Parte 1 aplica a régua
de **Linguagem Simples** (NBR ISO 24495-1:2024) que a curadoria dissecou e o core selou: princípios Relevante,
Localizável, Compreensível e Usável; uma ideia por frase; voz ativa; título que reflete o conteúdo; lista onde
há três ou mais itens.

---

## Parte 1 — A semana de 14 a 21 de novembro, em Linguagem Simples

### Para que serve este texto

Este texto conta, em palavras simples, o que o ecossistema fez na semana e o que atrapalhou. Serve para o time
olhar junto e decidir o que melhorar. Os números vêm do levantamento de fatos; aqui está só a forma pública.

### O que andou bem

- O time entregou muito e rápido. Foram **211 mudanças mergeadas** na semana, e a maioria entrou em menos de
  duas horas.
- Saíram **dois estudos profundos**: o contrato de canal de conversa e a peça de páginas por link.
- As ferramentas-base ficaram **atualizadas**.

### O que travou

1. **A fila de merge do maestro.** Doze mudanças de guarda ficaram esperando. Cada uma muda uma regra, então só
   o maestro a mergeia, e uma de cada vez. Elas se acumularam.
2. **Sessões paradas com trabalho possível.** Algumas sessões pararam esperando uma resposta e não voltaram,
   mesmo havendo trabalho a fazer.
3. **A carga da VPS passou de 15.** Vários passos pesados rodaram ao mesmo tempo na mesma máquina. A máquina
   ficou sobrecarregada.
4. **Quedas por limite de uso.** O limite de uso derrubou agentes no meio do trabalho.
5. **Troca de login e sessão duplicada.** A troca de login e duas sessões ao mesmo tempo causaram confusão sobre
   quem fazia o quê.
6. **Atalhos de shell.** Em alguns casos, comandos avulsos de shell foram usados no lugar do caminho próprio da
   casa.

### O que o maestro decidiu melhorar

O maestro escolheu três melhorias. A Parte 2 as descreve no padrão de registro de decisão (ADR), com as opções
e o que o mercado faz.

---

## Parte 2 — Esboço de ADR (padrão MADR) das três melhorias

> **Status de todos:** `proposto` (esboço). O core/maestro sela. **Aqui nada é selado.** Cada ADR traz o campo
> **destino de implementação** (mecanismo com card de guarda, ou desenho só-texto) — que é a própria melhoria D.

### ADR-001 — Merge de guarda em lote (melhoria A)

- **Status:** proposto
- **Contexto e problema:** mudanças de guarda (regras de lint, hooks) só o maestro mergeia, uma a uma. Na
  semana, 12 ficaram na fila, cada uma pedindo um toque. A fila trava o ritmo.
- **Decisores (drivers):** reduzir o número de toques do maestro; manter a segurança (cada guarda revisada);
  deixar rastro de quem mergeou o quê.
- **Opções consideradas:** (a) seguir como está (um toque por PR); (b) **merge em lote pela catraca** — «pode
  rodar lote», só PR com CI verde e revisão isolada, com registro por merge; (c) mergear guarda sem revisão
  (rejeitada: tira a segurança).
- **Decisão proposta:** opção (b). Um «pode rodar lote» na catraca de decisões aprova vários PRs de guarda de
  uma vez, desde que cada um esteja verde no CI e tenha passado por revisão isolada; cada merge fica registrado.
- **Consequências:** (+) menos toques, fila não acumula; (−) exige a catraca distinguir «lote» de «um»; risco de
  mergear junto algo que deveria ser olhado sozinho (mitigado pela revisão isolada por PR antes do lote).
- **Mercado (confronto):** o mercado SUPORTA fortemente; o mais próximo é o **merge queue do GitHub** com
  estratégia ALLGREEN (ver §mercado-A). A proposta Onion adiciona revisão humana isolada + registro por-merge
  **acima** do padrão (que dispensa toque humano), não contra.
- **Destino de implementação:** **mecanismo** (muda a catraca → pede card de guarda).

### ADR-002 — Fila única de passo pesado na VPS (melhoria B)

- **Status:** proposto
- **Contexto e problema:** passos pesados (pre-commits, bancadas) rodam numa só VPS. Quando vários rodam juntos,
  a carga passa de 15 e tudo fica lento.
- **Decisores:** limitar a carga da máquina; não parar o trabalho, só serializar o pesado; medir antes de
  escalar a máquina.
- **Opções consideradas:** (a) seguir sem limite; (b) **fila única com teto de 2 passos pesados ao mesmo tempo**;
  (c) máquina maior (custo, adia o problema).
- **Decisão proposta:** opção (b). Uma fila única serializa os passos pesados, com teto de **2 simultâneos**; o
  terceiro espera a vez.
- **Consequências:** (+) carga previsível, sem sobrecarga; (−) passo pesado pode esperar na fila; é preciso um
  mecanismo de fila (lock/semáforo) na VPS.
- **Mercado (confronto):** o mais próximo do «teto de 2 por máquina» é o **`concurrent` do GitLab Runner**
  (cap por-host) e o `max-parallel: 2` do GitHub Actions (ver §mercado-B). Proposta alinhada ao padrão de
  concorrência de runner self-hosted.
- **Destino de implementação:** **mecanismo** (fila/semáforo na VPS → pede card de guarda, dono vps-ops).

### ADR-003 — Destino declarado em cada decisão do maestro (melhoria D)

- **Status:** proposto
- **Contexto e problema:** na semana, dos 49 selos do maestro, 9 viraram mecanismo e 40 ficaram texto. Alguns
  "texto" eram desenho de propósito; outros deviam ter virado guarda e não viraram. Sem um campo que declare o
  destino, não se sabe qual é qual.
- **Decisores:** saber, por decisão, se ela deve virar mecanismo ou é só desenho; cobrar a implementação do que
  é mecanismo; não cobrar o que é desenho.
- **Opções consideradas:** (a) seguir sem o campo (ambíguo); (b) **cada decisão declara o destino** — `mecanismo`
  (vem com card da guarda) ou `desenho` (só texto, sem cobrança).
- **Decisão proposta:** opção (b). Todo selo do maestro declara o destino. `mecanismo` abre um card da guarda a
  construir; `desenho` fica como texto, sem dívida.
- **Consequências:** (+) a dívida de "decisão que devia virar guarda e não virou" fica visível e contável; (−)
  um campo a mais por decisão; é preciso definir onde o campo mora (no nó do selo).
- **Mercado (confronto):** o mercado rastreia SE a decisão foi aceita/superada (campo `status` do MADR), mas
  **não** distingue nativamente «virou mecanismo» de «ficou texto» (ver §mercado-D). A proposta Onion é uma
  **superação declarada** do padrão — um eixo de implementação/enforcement que o `status` não tem.
- **Destino de implementação:** **mecanismo** (campo + contagem no lint → pede card de guarda).

---

## Confronto de mercado (por melhoria)

Fontes primárias, tier DREAM (docs oficiais ≈9), como em 2026-11.

### §mercado-A — lote de merge de guardas
- **GitHub merge queue** (tier ~9): agrupa PRs num «merge group» (evento `merge_group`), roda os checks por
  grupo (speculative) e mergeia só quando verde. Estratégia **ALLGREEN** = cada PR do grupo verde **isolado**
  (vs HEADGREEN, só a cabeça) — é o guard-rail «cada PR verde sozinho». Tamanho mín/máx do grupo é configurável.
  Pré-requisito forte: branch protection/ruleset + required checks + `merge_group` no `on:` dos workflows.
  (`docs.github.com/.../managing-a-merge-queue`)
- **GitLab merge trains** (tier ~9): equivalente — o pipeline testa o MR + todos os à frente; mergeia após o
  próprio passar e os da frente mergearem; falha remove e reinicia os de trás. Premium/Ultimate.
  (`docs.gitlab.com/ci/pipelines/merge_trains/`)
- **Encaixe:** o mercado dispensa toque humano (CI verde + branch protection). A proposta Onion ADICIONA revisão
  humana isolada + registro por-merge — guard-rail **acima** do padrão, não contra.

### §mercado-B — teto de passos pesados por máquina
- **GitLab Runner `concurrent`** no `config.toml` (tier ~9): teto de jobs simultâneos em **toda a máquina**
  (ex.: `concurrent = 3` → no máximo 3 jobs); `limit` por-runner afina. É o padrão de mercado para capar pesado
  numa só máquina. (`docs.gitlab.com/runner/configuration/advanced-configuration/`)
- **GitHub Actions `max-parallel`** (matrix, tier ~9): limita quantos jobs da matriz rodam de uma vez; o doc traz
  `max-parallel: 2` — literalmente o teto de 2, como análogo por-workflow.
- **Actions `concurrency` group / `queue: max`** (tier ~9): serializa ou enfileira, mas **não** expressa um teto
  N arbitrário por máquina.
- **Encaixe:** o mais próximo do «teto de 2 na VPS» é o `concurrent` do GitLab Runner (cap por-host explícito).
  A lacuna do `concurrency`/`queue` do Actions (sem teto N por máquina) é exatamente o que a «fila única com
  cap 2» preenche. Proposta alinhada ao padrão de concorrência de runner self-hosted.

### §mercado-D — destino declarado (mecanismo × texto)
- **MADR `status`** (tier ~8, MADR 4.0.0, set/2024): campo de status por registro (proposed/rejected/accepted/
  deprecated/superseded); o ADR-0008 «Add Status Field» fixou a forma. (`adr.github.io/madr`)
- **Ciclo de vida ADR (Nygard/Fowler)** (tier ~8): proposed→accepted→superseded, com **link** ao registro que
  supera; o ADR é imutável (nunca apagado, só superado). (`martinfowler.com/bliki/ArchitectureDecisionRecord`)
- **Supersede + link automatizado:** GDS gov.uk e `adr-tools` (o novo referencia o antigo; o antigo vira
  «superseded»); AWS Prescriptive Guidance rastreia os estados no ciclo de governança.
- **Encaixe:** o mercado rastreia **se** a decisão foi aceita/superada, mas **não** distingue nativamente «virou
  mecanismo executável» de «ficou só texto». O mais próximo é `status` do MADR + link decisão→artefato. A
  proposta Onion (destino MECANISMO × DESENHO) é uma **superação declarada** do padrão — um eixo de
  implementação/enforcement que o `status` não tem. **Registrar como superação, não como padrão existente.**

## Síntese do confronto (3 linhas)

1. **A e B** têm mecanismo de mercado maduro e nomeado (merge queue/merge trains ALLGREEN; GitLab Runner
   `concurrent`/Actions `max-parallel`) — as propostas Onion **estendem** esses padrões (toque humano + registro
   por-merge em A; teto explícito por-host em B), não os contrariam.
2. **D** é a única onde o mercado fica aquém: o padrão (MADR `status`, Nygard supersede+link) rastreia
   aceitação/superação, mas não o eixo «virou mecanismo × ficou texto» — a proposta Onion é superação declarada.
3. **Guard-rail comum a A e B no mercado:** cada unidade verde **isoladamente** antes de agrupar (ALLGREEN;
   limite por-runner) — alinhado ao «só verdes com revisão isolada» do Onion.

---

Orquestrado com 🧅 Onion Evolve
