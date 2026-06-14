# 🧅 Onion Federation — Design + Backlog (Orquestração Multi-Repo Contract-Safe)

> **Status:** efêmero / forward-looking (segue [analysis/README.md](README.md)) — **design e backlog** de uma capacidade nova, pronto para a próxima `/meta:evolve` (ou execução manual faseada) consumir. Remover/curar após executado; as conclusões duradouras migram para a KB `multi-repo-federation.md` e a meta-spec do formato de contrato (criadas na execução).
>
> **Data:** 2026-06-14 · **Origem:** pedido do usuário ("próxima auto-evolução") · **Pesquisa:** 3 Explore agents sobre frota/evolve, onboarding/forge, identidade/SDAAL.

---

## 1. Context — o pedido

Capacidade desejada:
1. Passar o **caminho de uma pasta** ou uma **URL git** → o Onion **clona/adota** o projeto (instala o framework, gera contexto).
2. "Premium": o projeto vira **membro de uma federação** operável por uma instância orquestradora; cada membro **defende seus interesses** (protege as próprias invariantes/integrações) enquanto um **orquestrador principal** coordena **mudanças cross-repo** — sobretudo **ajustes em integrações que não podem quebrar o que está funcionando**, com **garantia de sucesso, monitorável e testável**.

**Decisões travadas (com o usuário):**
- **Topologia:** orquestrador **único** sobre repos locais (Claude Code-nativo: Workflow fan-out + worktrees + manifesto/contratos compartilhados; "instâncias" = subagentes-especialistas por repo). Instâncias vivas separadas = Fase 6 premium/futura, fora do escopo.
- **MVP (Fase 1):** bootstrap-adopt.
- **Resultado:** blueprint executável de uma capacidade "Onion Federation" — (a) automatiza onboarding de repos e (b) coordena mudanças cross-repo sem quebrar integrações, dentro da identidade canônica.

---

## 2. Guardrails de identidade (NÃO violar)

A visão "instâncias vivas autônomas conversando" beira o que foi **formalmente abandonado em 2026-05-18** (CLI standalone, multi-IDE, `.onion/`, `packages/`, aprendizado contínuo — ver [onion-review-2026-05.md](onion-review-2026-05.md) §4). Logo, o design é **Claude Code-nativo**:

- ✅ Comandos + skills + agentes + adapters SDAAL + git/forge/MCP como substrato. ❌ Nenhum runtime/CLI standalone, `.onion/` ou `packages/`.
- ✅ Orquestração vive em **skill/comando**, nunca em agente ([architecture.md](../meta-specs/architecture.md) §4.2). Experts por repo são **agentes** (especialistas) invocados pelo orquestrador.
- ✅ Operação cross-repo usa **working directories adicionais do Claude Code** — documentar, não inventar runtime.
- ✅ Cada arquivo SDAAL-like ≤ 400 linhas. Mudanças em metaspec/estrutura passam pelo `@metaspec-gate-keeper`.
- ✅ "Cada instância defende seus interesses" = **checks-and-balances**: o expert de um repo tem mandato de **proteger as invariantes/contratos daquele repo** e vetar mudanças que quebrem suas integrações sem migração explícita. Não é autonomia competitiva.

---

## 3. Visão — "como seria isso"

Uma **federação** é um conjunto de **repos-membro** Onion-enabled, coordenados a partir de um **hub** (o repo onde se roda o orquestrador). O hub guarda o **manifesto** (registro de membros) e os **contratos de integração** (APIs/eventos/tipos compartilhados que **não podem quebrar**). **Uma** sessão orquestradora faz fan-out para **agentes-especialistas por membro**. Mudanças cross-repo passam por **checagem de compatibilidade de contrato + contract-tests**, gerando **PRs coordenados por membro**, monitoráveis e reversíveis.

```
            ┌─────────────── HUB (orquestrador, skill/comando) ───────────────┐
            │  manifesto da federação  +  contratos de integração (SSOT)       │
            └───────────────┬───────────────┬───────────────┬─────────────────┘
            fan-out (Workflow)              │               │
        ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
        │ @member-A-expert  │  │ @member-B-expert  │  │ @member-C-expert  │  ← cada um defende
        │ (repo A / dir A)  │  │ (repo B / dir B)  │  │ (repo C / dir C)  │    o próprio repo
        └─────────┬─────────┘  └─────────┬─────────┘  └─────────┬─────────┘
                  └── propõe diff ────────┴── gate de contrato ─┘ → PRs coordenados
```

**Nuance técnica (corrige confusão comum):** membros são **repos separados** (dirs/remotes distintos). O `isolation: 'worktree'` do Workflow é **intra-membro** (paralelizar dentro de UM repo), **não** o mecanismo cross-repo. O cross-repo é: orquestrador opera sobre **dirs adicionais** + subagente por membro com o dir daquele membro como contexto + **PRs coordenados** (forge adapter). É um **spike** (Fase 3).

---

## 4. Arquitetura (componentes + onde vivem + reuso)

| Componente | Artefato (onde) | Reuso |
|---|---|---|
| **Bootstrap-adopt** | `.claude/commands/federation/adopt.md` (nova categoria) | [`docs/applying/`](../applying/) (greenfield/legacy), [`/docs:reverse-consolidate`](../../.claude/commands/docs/reverse-consolidate.md) + `@docs-reverse-engineer`, `/meta:setup-integration`, `git clone` (git puro; forge cobre PR, não clone) |
| **Manifesto da federação** | `.claude/federation/manifest.yaml` (nova subpasta operacional) | novo; SSOT de membros (name, path, remote, stack, role producer/consumer/lib) |
| **Experts por membro** | `.claude/agents/federation/<member>-expert.md` (gerados) | padrão de agente especialista; contexto = docs reverse-consolidated do membro |
| **Contratos de integração** | `docs/integration-contracts/<contract>.md` + padrão em meta-spec | SDAAL ([sdaal](../sdaal/), `.claude/utils/{task-manager,forge}/`): interface/types/versão/producer↔consumers/breaking-change policy |
| **Fan-out cross-repo** | skill `onion-federation` + `.claude/commands/federation/orchestrate.md` | [onion-fleet](../../.claude/skills/onion-fleet/SKILL.md), `/meta:fleet`, [agent-fleet-orchestration](../knowledge-base/concepts/agent-fleet-orchestration.md), Workflow (`parallel`/`pipeline`/`schema`/`budget`/tiering) |
| **Loop read-only de auditoria** | `.claude/commands/federation/scan.md` | [`/meta:evolve`](../../.claude/commands/meta/evolve.md) (FindingSchema, judge veto, relatório em `docs/analysis/`) |
| **Status / monitor** | `.claude/commands/federation/status.md` | manifesto + forge adapter (CI/PR por membro) |
| **Gate de contrato + PRs coordenados** | dentro de `orchestrate.md` | [forge](../../.claude/utils/forge/) (PR por membro), `/git:flow`, contract-tests, `@metaspec-gate-keeper` |
| **KB conceitual** | `docs/knowledge-base/concepts/multi-repo-federation.md` | enquadra como instância de SDAAL + fleet + spec-as-code |

---

## 5. Backlog faseado

> Risco crescente; cada fase é PR(s) atômico(s). Fases 1-3 aditivas; 4-5 introduzem a máquina de segurança; 6 é premium/futuro.

**Fase 1 — Bootstrap-adopt (MVP).** `/federation:adopt <path|git-url> [--target <dir>]`: aceita path local OU URL git → se URL, `git clone` (confirmar antes); instala Onion (copia `.claude/` + CLAUDE.md template + scaffolds de contexto — greenfield se vazio, **merge cuidadoso** se legado, nunca sobrescrever `.claude/` existente); roda `/docs:reverse-consolidate`; registra o membro no manifesto; sugere adicionar o dir aos working directories. **Aceite:** repo fica Onion-enabled e listado no manifesto; idempotente; nada sobrescrito sem confirmação.

**Fase 2 — Registry + experts + status.** Schema do manifesto formalizado; gerador de `@<member>-expert` (contexto do membro + mandato de defender interesses); `/federation:status` (membros + saúde). **Aceite:** `status` lista membros e estado; cada membro tem expert agent.

**Fase 3 — Fan-out cross-repo READ-ONLY** *(spike de ergonomia cross-dir).* `/federation:scan "<pergunta>"`: fan-out de **análise** sobre os membros (ex.: "onde a API X é consumida?"). **Sem mutação.** Valida o spike (orquestrador sobre N dirs adicionais via Workflow). **Aceite:** pergunta cross-repo → relatório consolidado com evidência por membro; zero escrita.

**Fase 4 — Contratos de integração como spec-as-code.** Meta-spec do **formato de contrato** (interface/types, producer↔consumers, semver, política de breaking-change, como testar) — validável pelo `@metaspec-gate-keeper`. Comando para extrair/registrar contratos de integrações existentes. Contract-tests. **Aceite:** contrato versionado para ≥1 integração real; gate-keeper valida o formato; teste falha se o contrato quebrar.

**Fase 5 — Mudança cross-repo CONTRACT-SAFE (valor premium).** `/federation:orchestrate "<mudança>"`: lê manifesto + contratos; decompõe por membro; fan-out aos experts (cada um propõe SEU diff defendendo o repo); **gate de compatibilidade** (producer que muda contrato exige consumers atualizados no mesmo change-set OU backward-compat); **verificação adversarial** (juiz tenta achar a quebra); **PRs coordenados** (um por membro, linkados, com contract-test como gate); monitor + rollback coordenado. **Aceite:** mudança em ≥2 repos sem quebrar contratos (testes verdes), PRs linkados/reversíveis; tentativa de quebra bloqueada.

**Fase 6 — (premium/futuro) Instâncias vivas (MCP/A2A).** Fora do escopo. Requer **decisão de identidade própria**. Apenas costura/flag; não implementar sem nova aprovação.

---

## 6. Máquina de segurança ("não pode quebrar", monitorável, testável)

Núcleo do pedido — 5 camadas sobre primitivas existentes:
1. **Contratos de integração** (F4) = SSOT do que não pode quebrar (spec-as-code, versionado).
2. **Contract-tests** = gate objetivo (falha → bloqueia merge).
3. **Gate de compatibilidade** no orchestrate: producer↔consumers no mesmo change-set ou prova de backward-compat.
4. **Veto do expert do membro** = "defende seus interesses" (checks-and-balances).
5. **Verificação adversarial** (juiz, padrão `/meta:evolve`) + **PRs coordenados com CI por membro** + **`/federation:status`** (monitor) + **rollback coordenado** (revert por membro + pin de versão de contrato).

---

## 7. Spikes / incertezas técnicas (resolver cedo)
- **Ergonomia cross-dir do Workflow** (F3): subagente operando com dir-membro como raiz? Como passar o dir alvo?
- **PRs coordenados atômicos**: GitHub não tem merge atômico multi-repo → PRs linkados + gate de contract-test + ordem de merge (consumers após producer compatível, ou feature flag).
- **Local do manifesto**: `.claude/federation/` nova → update em `architecture.md` §1/§7 + aval do gate-keeper.
- **Nova categoria `federation/`** → update na lista de categorias de `commands.md` + `/meta:inventory`.

---

## 8. Verificação (E2E por fase)
- **F1:** `/federation:adopt <url>` em repo de teste → `.claude/` instalado, `docs/reverse/consolidated.md` gerado, entrada no manifesto; rodar 2x → idempotente.
- **F2:** `/federation:status` lista membro com saúde correta; existe `@<member>-expert`.
- **F3:** `/federation:scan` responde pergunta cross-repo com evidência; `git status` limpo em todos.
- **F4:** quebrar um contrato → contract-test falha; gate-keeper valida o formato.
- **F5:** mudança compatível → PRs verdes/linkados; incompatível → bloqueada com mensagem acionável; rollback restaura o estado.
- **Transversal:** `/meta:inventory` após novos comandos/categoria; `@metaspec-gate-keeper`/`/meta:metaspec-validate` em mudanças de metaspec/estrutura.

---

## 9. Onde isto entra na evolução
Ao executar: criar primeiro a **KB `multi-repo-federation.md`** (enquadramento) e a **meta-spec do formato de contrato** (F4) — para o gate-keeper ter régua. A **Fase 1 (bootstrap-adopt)** é o ponto de entrada concreto e independente; as demais empilham sobre ela. Este documento é o backlog que a próxima `/meta:evolve` (ou execução manual faseada) consome.
