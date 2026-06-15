# Sistema Onion — Estudos de Caso

**Status:** Esqueleto desenvolvido (Fase 4 — Materiais Derivados)
**Fonte:** [Onion: Identidade e Produto](../knowledge-base/meta/onion-framework-identity.md) · [Material Bruto](../analysis/onion-product-material-raw-2026-06.md)
**Data:** 2026-06-15

---

> Três estudos de caso reais, extraídos de uma mega-sessão de auto-evolução em que o
> próprio Sistema Onion foi usado para se auditar e melhorar — **22 PRs mergeados num
> único ciclo**. Cada caso segue a estrutura Contexto → Abordagem → Resultado → Lição,
> com métricas rastreáveis à KB de identidade e ao material bruto.
>
> O fio condutor: o Onion não é um conjunto de prompts. É um framework que **coordena
> mudanças cross-repo sem quebrar contratos**, **se auto-diagnostica** e **avalia novos
> substratos de orquestração com evidência empírica** — não por opinião.

---

## Índice

1. [Federation v2 — Coordenação multi-repo sem quebrar nada](#caso-1)
2. [`/meta:evolve` — O framework que se auto-audita](#caso-2)
3. [Cursor→Native + Agent Teams — Modernizar a base e validar o novo substrato](#caso-3)

---

<a name="caso-1"></a>
## Caso 1 — Federation v2: Coordenação Multi-Repo Sem Quebrar Nada

### Contexto / Desafio

Times maduros raramente vivem num único repositório. Uma plataforma típica tem um repo
de **API**, um de **frontend** e um de **infra** — todos integrados por contratos
implícitos. O problema clássico: uma mudança de contrato na API (renomear um campo,
mudar um payload, depreciar um endpoint) pode quebrar silenciosamente o frontend ou a
infra que dependem dela.

A coordenação dessas mudanças, na ausência de ferramenta, é **Slack + esperança**. O
produtor avisa "vou mudar X", o consumidor responde "ok" sem realmente validar, e a
quebra só aparece em produção — onde custa caro. Não há garantia de que quem consome o
contrato **validou a mudança antes** de quem produz fazer o merge.

Por que importava: para um framework que se propõe a orquestrar o ciclo completo de
desenvolvimento, **multi-repo sem coordenação é um vazio estrutural** — o tipo de
problema que vira incidente de produção e erode a confiança no processo.

### Abordagem — O que o Onion fez

1. **Design adversarial antes de codar.** A primeira proposta (v1) era um hub
   centralizado — um repo "mestre" que coordenaria os demais. O Onion disparou uma frota
   de **42 agentes** para revisar o design; **24 de 36 achados críticos** apontaram para
   o mesmo risco: o hub vira ponto único de falha e de autoridade. O design pivotou para
   uma **topologia peer com ledger git** — sem mestre, cada repo é soberano.
2. **Implementação em fases retomáveis**, não big-bang:
   - **KB / ledger** — o ledger git como working directory adicional, onde contratos e
     anúncios ficam versionados.
   - **`register`** — validar e gravar o contrato que o repo publica.
   - **`publish` + `check`** — o produtor anuncia a mudança de contrato; cada consumidor
     tem **poder de veto**, validando localmente.
   - **`status` + `rollback`** — monitorar drift entre repos e recuperar estado quando
     necessário.
3. **Validação de 1ª mão.** Cada repo roda `/meta:federation-check` **localmente** — o
   repo dono valida as mudanças que o afetam com conhecimento direto, não delegado. Quem
   melhor sabe se uma mudança quebra o frontend é o próprio repo do frontend.
4. **Rollback coordenado e seguro.** Recuperação em ordem inversa, com pin de versão e um
   **gate humano** para falhas parciais — o humano-maestro decide, o framework executa.

### Resultado

| Métrica | Valor |
|---------|-------|
| Achados que provocaram o pivot de design (hub → peer) | 24 de 36 críticos (revisão de 42 agentes) |
| Ciclo implementado | `register → publish → check → status → rollback` completo |
| PRs de implementação | 4 |
| Comportamento testável | mudança incompatível **bloqueada** com mensagem acionável; rollback coordenado restaura o estado |

O ciclo `register→publish→check→status→rollback` chegou a produção. Uma tentativa de
mudança incompatível agora é **barrada antes do merge** com uma mensagem que diz o que
quebrou e onde — não um stacktrace pós-deploy.

### Citação

> *"Cada Onion defende seus interesses — o repo dono valida localmente as mudanças que o
> afetam (conhecimento de 1ª mão)."*
> — [onion-federation-design-v2-2026-06.md](../analysis/onion-federation-design-v2-2026-06.md) §2

### Lição Aprendida / Aplicabilidade

A descoberta de design — **peer vence hub** — generaliza para qualquer time com
múltiplos repos. Centralizar a autoridade de validação num único ponto recria o gargalo
que o multi-repo deveria eliminar. A validação tem que morar **onde o conhecimento mora**:
o consumidor valida o impacto sobre si mesmo.

Para um time que adota o Onion, isso significa que coordenação cross-repo deixa de ser um
ritual humano frágil e vira um **fluxo com veto distribuído e rollback coordenado** — sem
mestre, sem ponto único de falha, com o humano dirigindo a ordem de merge. Aplicável
diretamente a microsserviços, monorepos federados e qualquer arquitetura onde contratos
atravessam fronteiras de repositório.

---

<a name="caso-2"></a>
## Caso 2 — `/meta:evolve`: O Framework que se Auto-Audita

### Contexto / Desafio

Todo framework envelhece silenciosamente. Documentação fica obsoleta, agentes acumulam
redundância, KBs ficam stale, links quebram, conformidade arquitetural deriva. O sintoma
é insidioso: **ninguém percebe até doer**, porque auditar manualmente cada artefato —
dezenas de comandos, dezenas de agentes, dezenas de KBs — é trabalho que sempre fica para
depois.

O gatilho concreto: após um ciclo grande de mudanças (migração Cursor→native, Federation,
novos comandos), o framework estava **sem auditoria formal recente**. O mantenedor
precisava de um "raio-X de saúde" completo — sem passar uma semana lendo artefato por
artefato.

Por que importava: um framework que se propõe a orquestrar desenvolvimento de outros
precisa, antes de tudo, **conseguir cuidar de si mesmo**. Auto-evolução não é vaidade —
é a única forma de o framework não virar dívida técnica do próprio time que o mantém.

### Abordagem — O que o Onion fez

1. **Disparo de frota em 8 dimensões.** `/meta:evolve` lançou **28 agentes** cobrindo
   D1–D8: peso/tamanho, redundância, duplicação, KBs stale, conformidade arquitetural,
   legado/modernização, links, e frontmatter. Cada dimensão tem auditores próprios.
2. **Escala real, em minutos.** Em **~26 minutos**: **1.27M tokens** consumidos, **635
   tool-uses**, **41 achados brutos** levantados.
3. **Juízo adversarial, não acúmulo.** Um juiz `opus` refutou **11 dos 41 achados** — por
   exemplo, fusões propostas em D2 que na verdade eram "diferenciação real", não
   duplicação. Sobreviveram **30 achados** que resistiram à refutação.
4. **Backlog acionável, não relatório morto.** Cada achado sobrevivente veio com
   **evidência citada (`arquivo:linha`)** e um **comando atuador** — o que rodar para
   corrigir. O relatório não descreve o problema; ele aponta a cura.
5. **Read-only por contrato.** O comando **nunca muta** `.claude/`; a única escrita é o
   relatório em `docs/analysis/`. A auditoria diagnostica; a correção é um passo separado
   e deliberado.
6. **Execução até o fim.** Todo o backlog foi executado: **8 PRs** (#54–#61) — sweep
   MCP-first, índices reconciliados, 51 comandos ganhando `allowed-tools`, calibração da
   régua de frescor de KBs.

### Resultado

| Métrica | Valor |
|---------|-------|
| Agentes na frota | 28 (8 auditores + ~19 juízes + critic) |
| Tokens / tool-uses / duração | 1.27M · 635 · ~26 min |
| Achados brutos → sobreviventes | 41 → 30 (11 refutados pelo juiz adversarial) |
| Distribuição de severidade | 2🔴 · 18🟡 · 10🟢 |
| Achados D1 (peso/tamanho) | 0 outliers — "framework dentro dos limites" |
| Backlog executado | 100% — 8 PRs (#54–#61) |

Trinta achados, zero pendentes. O framework se diagnosticou, priorizou e executou o
próprio plano de cura — com um humano aprovando cada PR, nunca em piloto automático.

### Citação

> *"28 agentes (8 auditores + ~19 juízes + critic) · 1.27M tokens · 635 tool-uses · ~26 min."*
> — [onion-evolution-2026-06-15.md](../analysis/onion-evolution-2026-06-15.md) §0

E, sobre a disciplina que torna isso seguro:

> *"Read-only por contrato. O comando nunca muta `.claude/`; a única escrita é o relatório
> em `docs/analysis/`."*
> — `evolve.md` §Objetivo

### Lição Aprendida / Aplicabilidade

O padrão central é **auditoria como frota, com juízo adversarial e separação
diagnóstico/execução**. Três decisões de design fazem a diferença entre um relatório útil
e ruído:

- **Refutação adversarial** — um juiz que tenta *derrubar* achados elimina falsos
  positivos antes de gerarem trabalho. Aqui, 27% dos achados brutos não sobreviveram.
- **Evidência + atuador por item** — `arquivo:linha` mais o comando que corrige torna o
  backlog imediatamente acionável, sem investigação adicional.
- **Read-only por contrato** — separar diagnóstico de mutação dá ao humano o controle
  sobre *o quê* e *quando* corrigir.

Para qualquer time, o takeaway se generaliza além do Onion: **codebases grandes precisam
de um mecanismo de auto-diagnóstico periódico** que não dependa de alguém ter disciplina
de ler tudo. A frota faz o scan; o juiz filtra o ruído; o humano aprova a cura. É
sustentável justamente porque não exige heroísmo manual.

---

<a name="caso-3"></a>
## Caso 3 — Cursor→Native + Agent Teams: Modernizar a Base e Validar o Novo Substrato

### Contexto / Desafio

Este caso tem duas faces da mesma moeda — **lidar com a evolução da plataforma**. Quando a
plataforma subjacente muda, um framework tem duas tarefas: **modernizar o que ficou
legado** e **avaliar o que é novo** sem se deixar levar pelo hype.

**A face do legado.** Os **49 agentes** do Onion usavam nomes de ferramentas do dialeto
Cursor (`create_file`, `rewrite_file`, `search_files`). O Claude Code, plataforma única do
Onion desde a consolidação de identidade, usa nomes nativos (`Write`, `Edit`, `Grep`).
Pior: o lint da REGRA 12 estava validando o **dialeto errado** — ou seja, a régua que
deveria pegar o problema fazia parte dele.

**A face do novo.** Quase simultaneamente, a Anthropic lançou uma feature experimental:
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` — um substrato de peers persistentes que se
coordenam em runtime. A pergunta estratégica: **o Onion deveria adotar isso como novo
padrão de frota?** Reescrever toda a doutrina de orquestração em cima de uma feature
gated e acoplada a versão?

Por que importava: errar em qualquer das faces é caro. Deixar o legado apodrecer trava a
evolução; adotar o novo cedo demais acopla o framework a um substrato instável. A maturidade
está em **fazer as duas coisas com método**.

### Abordagem — O que o Onion fez

**Modernizando a base (Cursor→Native):**

1. **Diagnosticou o propagador.** A causa-raiz não eram os 49 agentes — era o
   `agent-template.md`, do qual cada agente novo herdava os nomes errados. Corrigir as 49
   folhas sem corrigir a raiz garantiria recaída no próximo agente criado.
2. **Corrigiu o propagador PRIMEIRO** (PR #44), antes de tocar nas folhas.
3. **Fan-out paralelo** migrou os 49 agentes em 2 PRs (#42, #43) — frota, não trabalho
   serial.
4. **Corrigiu o lint** (REGRA 12) para validar os nomes nativos corretos, fechando o loop
   entre régua e realidade.

**Validando o novo (Agent Teams):**

1. **Smoke-test empírico, não leitura de docs.** `TeamCreate → TaskCreate → SendMessage`
   round-trip — testado de verdade, com resultado PASS.
2. **Demo real** com um time dividido por tarefas, usando `owner`/`blockedBy` para
   coordenar dependências.
3. **Avaliação estruturada** das três primitivas de orquestração — sessões faseadas /
   `Workflow` / Agent Teams — mapeando o nicho, as limitações e o "quando preferir" de
   cada uma.
4. **Decisão documentada como ADR**, com critério explícito: experimental + gated +
   acoplado a versão = **não vira padrão obrigatório**, mas merece um lugar.

### Resultado

| Frente | Resultado |
|--------|-----------|
| Migração Cursor→native | **49/49 agentes (100%)** com tool names nativos; lint REGRA 12 corrigido; **zero falsos positivos** |
| Avaliação Agent Teams | ADR formal: entra como **3º modo opt-in**, com detecção de capacidade e **fallback gracioso** — os padrões `Workflow`-first permanecem |

Nenhuma das duas decisões foi por gosto. A migração corrigiu a raiz e propagou para 100%
das folhas; a avaliação de Agent Teams produziu uma decisão **conservadora e
fundamentada** — adotar o novo substrato como opção, sem sacrificar o que já funcionava.

### Citação

Sobre a refatoração em escala:

> *"Conserta o propagador, não só as folhas."*
> — princípio de refatoração em escala, salvo como padrão (migração Cursor→native)

Sobre a distinção que orientou a decisão de Agent Teams:

> *"Workflow = orquestração que o orquestrador desenha. Agent Teams = coordenação que
> emerge."*
> — [onion-agent-teams-evaluation-2026-06.md](../analysis/onion-agent-teams-evaluation-2026-06.md) §3

### Lição Aprendida / Aplicabilidade

Duas lições generalizáveis emergem deste caso:

**1. Em refatoração de escala, conserte o propagador antes das folhas.** Quando um padrão
errado se replica por um template, gerador ou classe-base, corrigir as instâncias sem
corrigir a fonte garante recaída. Identificar e consertar a raiz *primeiro* é o que
transforma um esforço de 49 correções num esforço de 1 correção + 1 fan-out. Aplica-se a
qualquer codebase com herança de configuração — templates, scaffolds, classes-base.

**2. Avalie o novo com evidência, não com hype.** A pergunta certa diante de uma feature
de plataforma nova não é "é legal?" mas "ela substitui o que tenho, complementa, ou não
serve?". O Onion **testou empiricamente** (smoke-test + demo), **mapeou os trade-offs**
(três primitivas, cada uma com seu nicho) e **documentou a decisão como ADR** com critério
explícito. O resultado — adotar como opt-in com fallback gracioso, mantendo o padrão
existente — é o tipo de decisão que protege o framework contra acoplamento prematuro a
plataformas instáveis. Qualquer time enfrenta esse dilema a cada release de ferramenta;
o método (testar → mapear → decidir com critério → documentar) é o que separa adoção
madura de churn por moda.

---

## Síntese — O Padrão Comum aos Três Casos

Os três casos contam uma história única: um framework que **não terceiriza o cuidado
consigo mesmo**.

- **Federation v2** mostrou que coordenação distribuída vence centralização — e que design
  adversarial pega o erro antes do código.
- **`/meta:evolve`** mostrou que auto-diagnóstico em frota, com juízo adversarial e
  separação diagnóstico/execução, mantém um codebase grande saudável sem heroísmo manual.
- **Cursor→Native + Agent Teams** mostrou disciplina diante da evolução da plataforma:
  consertar a raiz do legado e avaliar o novo com evidência empírica.

O denominador comum em todos: **o humano é o maestro, a frota é a orquestra, e cada
decisão é rastreável a evidência citada.** Foi assim que uma única sessão de auto-evolução
produziu 22 PRs mergeados — não por automação cega, mas por orquestração disciplinada.

---

**Próximo passo sugerido:** estes três casos alimentam diretamente o site (seção de prova
social), apresentações de vendas (slides de "como funciona na prática") e o press kit. Para
versões de uma página por caso, extrair Contexto + Resultado + Citação de cada um.
