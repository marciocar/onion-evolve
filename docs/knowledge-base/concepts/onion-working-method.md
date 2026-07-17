# Método de Trabalho do Onion

> **Versão**: 1.1.0 | **Última atualização**: 2026-07-17 | **Categoria**: Conceitos
> A **porta de entrada** do método de trabalho do Onion — como o framework **decide e executa** um
> trabalho, e como **sabe que ficou certo**. É um **mapa**, não uma nova fonte: destila e **aponta** para
> as fontes canônicas (que permanecem SSOT). Nasceu da pesquisa de evolução de 2026-06-27
> ([discovery](../../analysis/onion-research-how-we-work-2026-06.md)), que achou o método **maduro mas
> fragmentado** em 6 lugares — esta KB é o ponto de síntese que faltava.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-06-27 |
| **Categoria** | Conceitos |
| **Origem** | discovery `onion-research-how-we-work-2026-06.md` + `onion-research-harness-ledger-3-modes-2026-06.md` |
| **KBs-irmãs** | [Dogfooding Doctrine](onion-dogfooding-doctrine.md) · [Worklog Protocol](worklog-protocol.md) · [Spec-as-Code Strategy](spec-as-code-strategy.md) |

---

## Como ler este mapa

O método tem **três camadas** (Seleção → Execução → Validação) atravessadas por uma **disciplina**
transversal. Cada seção abaixo é **curta de propósito**: destila o essencial e **aponta** para a fonte
canônica — leia a fonte quando precisar de profundidade. **Não duplicar** é regra: se esta KB divergir de
uma fonte, a fonte vence (e esta KB é corrigida).

```
            ┌──────────── DISCIPLINA (transversal) ────────────┐
            │  git · multi-repo · legibilidade · fan-out · mem  │
            └──────────────────────────────────────────────────┘
   1. SELEÇÃO            2. EXECUÇÃO              3. VALIDAÇÃO
   qual fluxo aplicar →  como correr o fluxo  →  como sei que ficou certo
   (catálogo/playbook)   (PFR + coordenação)     (dogfood + adversarial)
```

---

## 0. KG-first — ler o SSOT antes de selecionar (o primeiro ato)

**Se o repo tem um `.kg.yaml`, ele é consultado ANTES de qualquer seleção** — é o SSOT de estado/verdade,
**acima** do git e da memória (que reconstroem por *inferência*; o grafo *declara*). Rodar o radar, citar
**ids de nó**, e **drive-to-verify** (cruzar claim `plane: PROD` contra o vivo) antes de agir.

Não é preferência de estilo: sem forcing function o default é prosa — reincidência medida em campo
(≥4×, inclusive com quem escreveu a doutrina) e no próprio core.

- **Fonte canônica:** [Knowledge Graph SDAAL §SSOT-as-runtime](knowledge-graph-sdaal.md#ssot-as-runtime--o-kg-é-o-primeiro-ato-mecanismo-não-conselho)
  (ciclo `read→verify→act→write`; gênero **SSOT-first** × espécie **KG-first**) + ADR
  [kg-freshness-gate](../../analysis/onion-adr-kg-freshness-gate-2026-07.md).
- **Onde está cabeado:** `catch-up`, `warm-up`, `engineer:work` — Passo 0.

## 1. Seleção — qual fluxo aplicar

**Reconhece a situação → aplica o playbook (barato); sem match → delibera (caro) e o resíduo vira playbook
novo.** É a doutrina **catálogo-first / recognition-primed**: seleção antes de composição-do-zero.

- **Fonte canônica:** skill [`onion-patterns`](../../../.claude/skills/onion-patterns/SKILL.md) §Playbooks +
  [RFC-0002](../../evolution/rfc/rfc-0002-meta-strategy-verdict.md) (veredito que aceitou a doutrina).
- **Playbooks canônicos** (recognition-primed): descoberta→backlog · planejamento→entrega · adoção-agnóstica
  ("adota não impõe") · agir-em-ambiente-compartilhado · laço-sem-guarda.
- **Quando deliberar:** sem playbook que case → análise estruturada (`/meta:analyze-complex-problem`), e o
  padrão destilado **realimenta** o catálogo.

## 2. Execução — como correr o fluxo

### 2a. O esqueleto: Padrão Faseado Retomável (PFR)

Workflows não-triviais correm sobre o **PFR**: sessão durável + `STATE.md` (Tier-0, ~300 tokens) + retomada
**fria** (de arquivos, sem transcript) ou **quente**, com checkpoint em limites de fase e vocabulário de
estado determinístico (`[DONE]`/`[ACTIVE]`/`[TODO]`).

- **Fontes canônicas:** [Worklog Protocol](worklog-protocol.md) (mecânica) +
  [ADR onion-adr-phased-resumable-pattern](../../analysis/onion-adr-phased-resumable-pattern-2026-06.md)
  (nomeia o PFR — provisório, no caminho de cravar em `commands.md §3`).
- **Invariantes:** `product/collect→feature` e `engineer/plan→pr-update` são PFRs do framework (CLAUDE.md).

### 2b. Coordenação por modo: harness + comunicação = f(escala)

O **harness** (sessões, subagentes, a ferramenta nativa `Workflow`/orquestração) e a **camada de comunicação** (o
**Ledger** é uma camada de comunicação) instanciam o **mesmo modelo** em escalas diferentes. O Ledger é
**isomórfico**: `{registry (quem/versões) · changelog (o-quê/porquê) · contracts (o-que-quebra)}`.

| Modo | Unidade que se comunica | Mecanismo | Estado |
|------|-------------------------|-----------|--------|
| **Solo** | eu-comigo-no-tempo | memória + sessões (recall automático) | ✅ maduro |
| **Equipe** | devs-no-mesmo-repo | worktrees + handoff (1-escritor/escopo; layout: [worktree-convention](../../evolution/worktree-convention-2026.md)) | 🟡 layout codificado; orquestração N-devs segue **gated** |
| **Federação** | repos-separados | Ledger git + doc-bridge (`/meta:co-*`, `/meta:federation-*`) | ✅ produção |

- **Fontes canônicas:** [Multi-repo Federation](multi-repo-federation.md) ·
  [discovery harness+ledger](../../analysis/onion-research-harness-ledger-3-modes-2026-06.md) ·
  orquestração de subagentes: [Agent Orchestration](agent-orchestration.md) + skill `onion-orchestration`.
- **Gated:** o modo **equipe** é o maior eixo de evolução futura — só com dogfood (1º caso N-devs/1-repo).

## 3. Validação — como sei que ficou certo

### 3a. Loop de dogfood (o padrão master)

Toda mudança de core se valida **rodando o artefato de verdade**: testar **modo-de-falha** (não só
happy-path), **fix → re-dogfood** no mesmo loop. Dois gates: **mecânico** (determinístico — lint + selftest
+ inventory em `.claude/validation/`) e **de uso** (invocar e observar — julgamento humano).

O loop fecha no **KG** nas duas pontas: `read(KG)` antes de auditar (§0), `write(KG)` depois de dogfoodar
— senão o achado morre na prosa.

- **Fonte canônica:** [Dogfooding Doctrine](onion-dogfooding-doctrine.md).

### 3c. O "re-" — toda verdade tem TTL

**Re-dogfood**, **re-teste de migalha** (`review_after`/⏰) e **re-verificação de frescor**
(`verified_at`/STALE) são **o mesmo invariante**: *declarado ≠ verificado; re-testar, nunca re-carimbar*.

- **Fonte canônica:** [Dogfooding Doctrine §♻️](onion-dogfooding-doctrine.md) (o enunciado + as 3
  instâncias) · mecânica: [`/meta:diary review`](../../../.claude/commands/meta/diary.md) ·
  [KG §Frescor](knowledge-graph-sdaal.md#frescor-e-versão-de-schema--o-radar-recusaavisa-quando-a-ssot-driftou).

### 3b. Revisão adversarial e fechar o loop

Revisão **independente** com prompt neutro (deixar o reviewer achar sozinho); **veredito é hipótese a
verificar com evidência** (rejeitar falso-positivo com prova); **re-revisar o fix** (pode introduzir
regressão). "Validação adversarial é insumo, não ordem."

- **Fontes canônicas:** [Dogfooding Doctrine](onion-dogfooding-doctrine.md) §loop +
  `~/.claude/rules/working-discipline.md` §Validação.

## 4. Disciplina (transversal)

A disciplina operacional do executor é **regra global** (carrega em toda sessão, multi-projeto) — esta KB
**não a duplica**, aponta:

- **Fonte canônica:** `~/.claude/rules/working-discipline.md` — git (confirmar PR merged antes de deletar
  branch; add seletivo em repo que recebe correspondência), localização multi-repo/worktree (anunciar onde
  se opera; layout canônico: [worktree-convention](../../evolution/worktree-convention-2026.md)),
  legibilidade (rotular referências opacas), fan-out (detectar é dever, executar é opt-in),
  gestão de memória (híbrido + recall automático + checagem leve de coerência).

## 5. O que NÃO fazer (anti-padrões — doutrina anti-inchaço)

A pesquisa de evolução **refutou** (com evidência) propostas recorrentes de "codificar o método" que
**contradizem a própria doutrina** do Onion. Registradas aqui para **não reaparecerem**:

- ❌ **Guarda-hard mecânica para comportamento** (lint que detecta `git add -A`, stale branch, etc.): o
  veredito catálogo-first **já rejeitou** — "guarda-hard vira atrito ou bypass"; **recall recognition-primed
  > bloqueio**. A working-discipline (regra global, toda sessão) **é** o mecanismo de recall.
- ❌ **Comando que mecaniza julgamento** (`/meta:dogfood` para o gate de uso): o gate de uso é **humano por
  design** ("invoque e observe"). Mecanizar adiciona superfície sem capturar o que importa.
- ❌ **Schema/lint para vereditos adversariais ou meta-spec de memória com captura automática:** o
  veredito-como-hipótese é **disciplina de pensamento**, não artefato a validar; a memória **já funciona**
  (híbrido + recall). Produto sem dogfood = inchaço.
- ❌ **Migrar a memória pessoal (`~/.claude/.../memory`) para dentro do repo:** ela é do *dev*, não do
  *repo* — commitá-la quebra a separação proposital memória-pessoal vs ledger-de-repo.

**Princípio:** o método se codifica como **conhecimento navegável (esta KB) + recall (recognition-primed)**,
não como N gates/comandos/schemas. Doutrina + recall > guarda-hard.

## 6. Mapa de fontes — onde cada coisa vive

O método amarra **4 camadas de artefato** (ver [Spec-as-Code Strategy](spec-as-code-strategy.md) para a
hierarquia L0-L3). Esta KB **cita**; cada uma permanece SSOT do seu tipo:

| Camada | Pergunta | Natureza | Exemplos |
|--------|----------|----------|----------|
| **Meta-spec (L0)** | a lei que não se viola | invariante **validável** (`@metaspec-gate-keeper`) | `docs/meta-specs/{architecture,commands,agents,code-standards,integrations}.md` |
| **KB** | como funciona/navega hoje | síntese **viva**, guia | esta KB, dogfooding-doctrine, worklog-protocol |
| **ADR** | **por que** decidimos X | datado, **superseded nunca removido** | `docs/analysis/onion-adr-*.md` |
| **RFC** | proposta/deliberação | forward-looking, vira decisão | `docs/evolution/rfc/rfc-000{1,2}-*.md` |
| **Regra global** | disciplina do executor | carrega toda sessão, multi-projeto | `~/.claude/rules/working-discipline.md` |
| **Memória** | estado/feedback entre sessões | por-dev, privada, recall automático | `~/.claude/projects/<repo>/memory/` |
| **KG** (`.kg.yaml`) | **o que é verdade agora** (estado/domínio) | grafo tipado, **append-mostly**, verdades reconciliadas (`REFUTES`/`SUPERSEDES`), com frescor (`verified_at`) | `docs/onion/graph/*.kg.yaml` · motor `kg-radar.sh` · [KG SDAAL](knowledge-graph-sdaal.md) |
| **Diário** (migalha) | o que o Transformer **deve absorver** | frontmatter estruturado, TTL (`review_after`), re-teste dirigido (`conflict_class`) | `.claude/diary/` · [`/meta:diary`](../../../.claude/commands/meta/diary.md) · RFC-0003 §2.3 |

**Caminho de graduação:** uma decisão nasce **ADR** (provisório) → pode **cravar em meta-spec** (lei) num PR
constitucional (ex.: o PFR está nesse caminho). Esta KB descreve o estado vigente e aponta para o artefato
canônico **atual** — quando algo gradua, a KB só troca o ponteiro.

---

> **Manutenção:** esta KB é mapa, não SSOT. Ao mudar uma fonte (ADR novo, meta-spec cravada, playbook
> destilado), **atualize o ponteiro aqui** — não copie o conteúdo. Se um ponteiro divergir da fonte, a
> fonte vence.
