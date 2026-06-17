---
title: "Sessão de Estratégia — Reposicionamento como Produto + Avaliação SDAAL"
date: 2026-06-17
type: strategy-session-handoff
status: active
scope: framework-template-instalavel
participants: [marcio, claude-code-instance-onion-evolve]
purpose: >
  Handoff entre sessões. Esta pasta (onion-evolve) é a "sala de design";
  a obra acontece em outra pasta/instância. Este doc É o canal de
  coordenação — não há comunicação viva entre instâncias.
feeds:
  - "ADR de reposicionamento (a criar) — distribuição como produto"
related:
  - docs/analysis/onion-review-2026-05.md
  - docs/sdaal/sdaal.md
  - docs/meta-specs/integrations.md
---

# Sessão de Estratégia — Reposicionamento + SDAAL (2026-06-17)

## 0. Por que este doc existe

Coordenação entre **duas sessões Claude Code em pastas diferentes**. Fatos
operacionais que motivam o formato:

- Instâncias em pastas distintas são **processos isolados** — sem contexto
  compartilhado, sem comunicação viva.
- A **memória persistente é indexada por caminho de projeto** → não cruza
  pastas. Só artefatos versionados em git bridgeam as sessões.
- **Modelo de trabalho adotado**: esta pasta = *sala de design* (conversa,
  decisão, geração de docs); a outra pasta = *sala de obra* (implementação em
  `.claude/`/código). Uma fonte de verdade por arquivo por vez.
- **Bridge**: este doc commitado → `git pull` na outra pasta (se for clone do
  mesmo repo) **ou** cópia manual (se repo separado).

---

## 1. Decisão estratégica: reposicionamento como produto

### O que foi esclarecido
- O **produto real é a consultoria** de implantação do Onion em projetos de
  outras empresas. O foco em Claude Code é **deliberado**: maximizar a
  plataforma e a metodologia da Anthropic.
- As **portas em outras IDEs** (cursor, antigravity, zed, codex, copilot) foram
  **testes**. Claude Code venceu na avaliação. As portas são **despriorizadas** —
  serão mantidas no futuro como versões simplificadas para apresentar o Claude a
  desenvolvedores. **Não são preocupação agora.**

### Reconciliação com a decisão de 2026-05 (onion-review-2026-05.md)
- "Usar em projetos de outras empresas" **já era a lente oficial** desde maio
  (linha 54 do review: "framework reutilizável para aplicação em projeto-alvo").
  → Isto **não é reversão**, é continuidade.
- O que foi abandonado em maio (`.onion/` agnóstico, CLI standalone, multi-IDE
  via engine único) **permanece abandonado**. A resposta para "outros modelos no
  futuro" é a **família de portas por plataforma**, não um engine model-agnostic.
- **Única decisão genuinamente NOVA**: passar de "instalável de forma privada"
  para **distribuível como produto**. O review de maio explicitamente dizia "não
  é distribuído publicamente, não tem CLI standalone" (linha 588). Cruzar essa
  linha exige **ADR próprio**.

### Perguntas em aberto para o ADR de reposicionamento
1. **Distribuição**: como uma empresa externa obtém e atualiza o Onion?
   (`/meta:adopt` via git URL é o candidato — é template público? licença?
   serviço?)
2. **Multi-modelo**: adotar oficialmente o modelo "família de portas" como
   resposta (recomendado), em vez de sonhar com engine agnóstico (enterrado por
   bons motivos estruturais).
3. **Suporte sem mantenedor**: distribuir como produto eleva a régua do veredito
   de maio ("operador externo consegue usar sem mantenedor de plantão") — agora
   precisa de "consegue **e tem para onde recorrer quando quebra**".

### Progresso desde maio (a favor do reposicionamento)
Dos 3 bloqueios do veredito de maio:
1. KBs/docs com visões abandonadas → ✅ limpo (curadoria 2026-06-14)
2. 5 meta-specs ausentes → ✅ **as 5 existem** (agents/commands/architecture/
   code-standards/integrations)
3. Guias operacionais por cenário → 🟡 `docs/applying/` existe; falta confirmar
   cobertura greenfield/legado/regulado

---

## 2. Avaliação do SDAAL (pedido explícito: "vale a pena?")

Avaliação feita do ponto de vista do **runtime** (o LLM que interpreta os specs).

### Veredito
**Vale a pena — decisivamente — contra a alternativa certa.** O comparativo
honesto não é "SDAAL vs adapters em código" (código é mais pesado num sistema
operado por IA); é **SDAAL vs deixar cada comando improvisar a integração**.
Contra esse baseline, SDAAL é a diferença entre **auditável e ad-hoc**.

### O que o SDAAL acerta (confirmado de dentro)
- O artefato **É** o runtime → elimina o drift clássico "doc vs código".
- **Tabelas de mapeamento explícitas matam alucinação** (sem tabela, o agente
  improvisa e erra).
- **Auditabilidade**: decisão rastreável a uma linha de Markdown versionada →
  este é o **ativo de venda** para clientes regulados, não a elegância.

### Onde empurrar de volta (riscos subvendidos pelo whitepaper)
1. **"Simula consistentemente" é probabilístico, não determinístico.** O mesmo
   spec lido 2× pode divergir sob ambiguidade ou pressão de context window.
2. **Não há testes — furo central.** O §14.6 do whitepaper admite que "spec
   desatualizada é pior que sem spec" (o agente acredita e erra com confiança),
   mas esse risco **não tem guarda automatizada**. Ex. real: o `/search` do Jira
   removido em maio/2025 — sem correção manual, o agente chamaria endpoint morto.
   **SDAAL não tem CI para provider-drift.**
3. **Custo amortizado por chamada**: releitura factory→detector→adapter consome
   context window e latência em cada operação.
4. **"Compounding" corta dos dois lados**: valor compõe, mas superfície de
   staleness silenciosa também.

### Evidência concreta de drift (a corrigir)
- O whitepaper torna `adapters/none.md` **obrigatório** (§7, §14.3).
- `forge/adapters/` tem `none.md` ✅.
- `task-manager/adapters/` (a implementação de **referência**) **NÃO tem
  `none.md`** (só asana, clickup, jira, linear). → A referência viola a regra
  dura do próprio padrão. **Verificar** se `none` está tratado inline
  (factory/detector) ou genuinamente ausente.

### Teto do padrão ("até que nível dá pra chegar?")
> **SDAAL escala com o NÚMERO de capabilities provider-swappable, não com a
> PROFUNDIDADE/criticidade de nenhuma. É jogada de largura, não de profundidade.**

- **Zona doce**: task-manager, notification, forge, calendar, storage — baixa
  frequência, tolerância a variância, múltiplos providers, valor de auditoria.
- **Zona de erosão**: alta vazão, correção estrita, provider único, loops
  apertados, transações stateful.
- **Caso a repensar**: a abstração `llm-provider` do roadmap — abstrair o LLM via
  spec que o próprio LLM interpreta tem bootstrapping estranho; comportamentos
  provider-específicos (tool-calling, limites de token) são onde "simular
  consistentemente" fica fino.

### Condições para o "sim" sem ressalvas
1. **Adicionar um harness de validação mínimo** ("golden-payload": dado um input,
   afirmar que o payload documentado do adapter bate com um fixture). Fecha o
   maior furo (§14.6) sem precisar rodar o LLM.
2. **A implementação de referência tem que seguir o padrão** — entrar com o
   `none.md` da task-manager (ou relaxar §7/§14.3 conscientemente).

### Posicionamento de venda
Liderar com **auditabilidade + portabilidade** (à prova de bala). Usar "Markdown
é o bytecode, o LLM é a VM" como metáfora **didática**, não como argumento técnico
— o engenheiro sênior do cliente vai perguntar "cadê os testes?", e a resposta
(harness do item 1) precisa estar pronta antes da pergunta.

---

## 3. Itens de ação (handoff para a sala de obra)

| # | Ação | Tipo | Onde |
|---|------|------|------|
| 1 | Verificar tratamento de `none` na task-manager (inline vs ausente) | investigação | `.claude/utils/task-manager/{factory,detector}.md` |
| 2 | Se ausente: criar `task-manager/adapters/none.md` (Null Object) | implementação | `.claude/utils/task-manager/adapters/` |
| 3 | Prototipar harness "golden-payload" numa abstração | implementação | `.claude/validation/` (a definir) |
| 4 | Redigir ADR de reposicionamento (produto distribuível) | design (aqui) | `docs/analysis/onion-adr-*` |
| 5 | Decidir mecanismo de distribuição (`/meta:adopt` via git URL?) | decisão | ADR do item 4 |

---

## 4. Estado de continuidade

- **Conversa estratégica**: continuou nesta pasta (sala de design) e aprofundou no
  modelo de negócio — ver §5 e §6 abaixo.
- **Para a outra instância**: este doc agora carrega um **plano de reposicionamento
  PROPOSTO** (§6) para **reavaliação**, não para execução cega. Reconcilie com o que
  você já evoluiu antes de mexer nos arquivos de §7.

---

## 5. Modelo de negócio — pesquisa + decisões (2026-06-17)

Aprofundamento após o usuário esclarecer: **o Onion vira PRODUTO** (a consultoria é só
uma das atividades de uso). Três explorações paralelas (fan-out) fundamentaram:

### Síntese da pesquisa
1. **Mercado jun/2026**: o modelo vencedor é **open-core local + camada hospedada de
   coordenação/governança** como receita (PostHog ~70% no cloud, Terraform HCP,
   Confluent Schema Registry, Kong). Cobra-se pelo *hub* que coordena, não pelo que roda
   no cliente. **SaaS clássico puro não encaixa** (Onion não tem runtime hospedado — roda
   no Claude Code do cliente). Fadiga de assinatura é real; não dá para marcar markup em
   token de Claude → valor capturável = abstração + governança + comunidade.
2. **Infra já existente no repo**: o **subsistema de Federação** (`/meta:federation-*` +
   ledger git + contratos + validação determinística + rollback) **é o núcleo já
   prototipado de um control plane** — o ledger é só um repo git (sem runtime),
   hospedável e auditável. Precedente: Confluent/Kong cobram pelo hub. `/meta:adopt` já
   cobre distribuição/instalação/update (pull-based).
3. **Bloqueador de produto**: licença é **MIT** + repo público → qualquer um clona e
   revende. Licença de código perpétua node-locked é inviável (é Markdown, sem binário).

### Decisões do usuário (confirmadas via AskUserQuestion)
- **Monetização faseada**: licença comercial agora → control plane (sobre Federação) depois.
- **Licença**: migrar **MIT → BSL/dual-license** (uso interno livre; comercial paga).
- **ICP**: **orgs reguladas e multi-repo** (federação + compliance + auditoria compõem valor juntos).

### Gaps de produto que a pesquisa de infra revelou (a fechar)
- Sem **semver formal** do framework (versão implícita no `main`) → assinatura exige
  versões nomeadas.
- Update a repos adotados é **pull-based**; sem notificação push.
- Sync entre as 6 portas da família é **manual**, sem automação.

---

## 6. Plano de reposicionamento PROPOSTO (reavaliar — NÃO executado)

> Plano completo também em `~/.claude/plans/onion-n-o-vai-virar-swirling-moon.md`
> (local da outra sessão — não viaja por git; por isso está replicado aqui).

**FASE 0 — ADR de reposicionamento** (`docs/analysis/onion-adr-product-repositioning-2026-06.md`,
seguindo padrão `onion-adr-*-2026-06.md`): registra produto-não-consultoria, reconcilia
com 2026-05 (única reversão = "distribuível como produto"), modelo faseado, ICP,
distribuição via `/meta:adopt`, multi-modelo = família de portas, suporte = item aberto.

**FASE 1 — Licença BSL + fronteiras comerciais** *(gate humano / revisão jurídica)*:
substituir `LICENSE` (MIT→BSL 1.1, Change License + Change Date +4 anos), criar
`docs/onion/commercial-license.md` (definir "uso comercial"), atualizar `README.md` +
`CLAUDE.md`.

**FASE 2 — Versionamento nomeado**: semver via **git tags** (externo ao arquivo → respeita
anti-auto-referência de `architecture.md §6.1`); estender `.claude/validation/onion-version.sh`;
`docs/onion/RELEASE-NOTES-<versão>.md`. Mudança em `architecture.md §6` → validar com gate-keeper.

**FASE 3 — Design do Control Plane sobre Federação** *(só design)*:
`docs/analysis/onion-control-plane-design-2026-06.md` — hospedar/sincronizar ledger,
monitorar drift (reusar `federation-status-scan.sh`), alertar breaking changes
(`federation-inbox-scan.sh`), compliance-at-scale. Fronteira: framework local = livre/BSL;
coordenação hospedada = SaaS pago.

**FASE 4 — Go-to-market**: reescrever FAQ "modelo de negócio" em `docs/materials/press-kit.md`
(hoje diz "não é produto comercial" — contradiz a decisão) + `landing-page.md` com tiers.

**Verificação**: `@metaspec-gate-keeper` sobre ADR + `architecture.md`; coerência
LICENSE↔README↔CLAUDE; `onion-version.sh` emite semver; `federation-status-scan.sh` roda
determinístico (prova que o kernel do control plane é executável hoje); `/meta:inventory`
+ lint se tocar comando/agente.

**Fora de escopo agora**: implementar o control plane; notificação push/sync entre portas;
precificação/billing; modelo de suporte/SLA.

---

## 7. Arquivos com risco de OVERLAP entre instâncias (coordenar antes de editar)

Se a outra instância (evolução) e a execução deste plano tocarem os mesmos arquivos →
conflito. Coordenar ownership antes:

- `CLAUDE.md` (bloco de identidade)
- `docs/meta-specs/architecture.md` (§6 versionamento)
- `LICENSE`, `README.md`
- `docs/analysis/` (novos ADRs + este doc)
- `docs/materials/press-kit.md`, `landing-page.md`
- `.claude/validation/onion-version.sh`

**Recomendação de coordenação**: a outra instância (obra) decide se assume estas FASES ou
se delega de volta à sala de design; em qualquer caso, **uma instância por arquivo por vez**.

---

## 8. Pergunta aberta para a reavaliação na outra instância

1. A evolução em curso lá **muda alguma premissa** deste plano (ex: já mexeu em licença,
   versionamento, federação)?
2. Confirma o modelo **BSL agora + control plane depois**, ou a obra sugere outra ordem?
3. Quem executa cada FASE — e em que branch — para não colidir com a evolução em curso?
