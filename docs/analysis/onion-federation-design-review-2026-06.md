# Onion Federation — Review Adversarial do Design (2026-06-14)

> **Alvo:** [onion-federation-design-2026-06.md](onion-federation-design-2026-06.md) (PR #36)
> **Método:** frota de 6 lentes críticas independentes → refutação adversarial achado a achado → consolidação.
> **Contrato:** read-only sobre o design; este relatório é a única escrita. **Não** executa nada — propõe ajustes ao design **antes** de construir.

---

## 0. Sumário

| Métrica | Valor |
|---|---|
| Achados crus (6 lentes × 6) | 36 |
| **Confirmados** (sobreviveram à refutação) | **24** |
| Refutados/descartados (fracos, duplicados, já cobertos) | 12 (33%) |
| Blockers | 7 · Recommended 15 · Opportunistic 2 |
| Frota | 42 agents · ~1.46M tokens · 24 min · Run `wf_dbfb2b91-cd3` |

**Confirmados por lente:** identity 6 · safety 5 · completeness 4 · feasibility 3 · reuse 3 · phasing 3.

**Veredito geral:** o design é **direcionalmente sólido e fiel à identidade canônica** (Claude Code-nativo, sem ressuscitar a visão abandonada) — nenhuma lente o acusou de reintroduzir CLI standalone/`.onion/`/multi-IDE. Mas tem **dois buracos estruturais que o tornam não-executável como está**: (1) cria estruturas que violam meta-specs L0 sem tratar a emenda como fase bloqueante; (2) a "máquina de segurança" — o coração do pedido ("não pode quebrar") — é declarada, não especificada. Ambos são corrigíveis no próprio design, antes de uma linha de código.

---

## 1. Alertas sistêmicos (causa-raiz compartilhada)

Três causas explicam 16 dos 24 achados. Atacá-las na raiz resolve o backlog em bloco.

### 🔴 SA-1 — Violação de meta-spec tratada como nota, não como Fase 0 (7 achados: #1, #2, #3, #7, #9, #10, #18)

O design cria **cinco** estruturas novas que colidem com proibições L0 explícitas:

| Estrutura proposta | Meta-spec violada | Achado |
|---|---|---|
| `.claude/federation/manifest.yaml` | architecture.md §7 (subdir fora de §1.2) | #1, #7 |
| categoria de comando `federation/` | commands.md §8 (categoria fora da lista §2) | #2, #3 |
| categoria de agente `federation/` | agents.md §2 (9 categorias fixas) | #1 |
| skill `onion-federation` | architecture.md §1.2 (5 skills canônicas) | #10 |
| `docs/integration-contracts/` | architecture.md §1.3 (estrutura de `docs/`) | #9, #18 |

O design **reconhece** isso, mas em §7 (lista de "spikes/incertezas"), ao lado de dúvidas técnicas — sem sequenciá-la como pré-condição. Executar a Fase 1 como escrita **viola o framework no ato**, e o `@metaspec-gate-keeper` rejeitaria (precedente: agents.md mostra `misc/` sendo barrado com "Categoria inválida").

**Correção raiz — duas opções, o juiz adversarial recomenda a (B):**
- **(A) Fase 0 de meta-spec:** PRs em `architecture.md §1.2/§1.3`, `commands.md §2`, `agents.md §2` adicionando `federation/` com justificativa; merge só após aval do gate-keeper; **só então** a Fase 1 roda.
- **(B) Encaixar no canônico existente** (dissolve a maioria dos blockers sem nova categoria): manifesto em `docs/` ou `.claude/sessions/`; comandos em `meta/` (`/meta:federation-adopt`, precedente `/meta:fleet`, `/meta:evolve`); experts em `agents/meta/` com naming `federation-<member>-expert.md`; contratos em `docs/knowledge-base/concepts/` ou `docs/meta-specs/`; skill dobrada na `onion-fleet` existente como modo cross-repo.

> **Recomendação:** adotar (B) onde houver encaixe limpo e usar (A) só para o resíduo irredutível. Qualquer caminho exige veredito do gate-keeper **antes do primeiro arquivo**.

### 🔴 SA-2 — A "máquina de segurança" é declarada, não especificada (5 achados: #4, #5, #14, #15, #16)

O valor central do pedido — "não pode quebrar, monitorável, testável" — depende de 5 camadas que o design **nomeia** mas não **operacionaliza**:

| Camada (doc §6) | Buraco confirmado | Achado |
|---|---|---|
| Contract-tests = gate | Ninguém garante que existam/cubram; contrato sem teste = gate vazio | #4 |
| Veto do expert | Expert é LLM sem `VetoSchema`; veto não é determinístico nem fail-safe | #5 |
| Gate de compatibilidade | Só detecta quebra **sintática**; mudança **semântica** (mesma assinatura, outro comportamento) passa invisível | #14 |
| Rollback coordenado | Sem protocolo: quem dispara, ordem, o que fazer se um revert falha | #15 |
| Monitor (`/federation:status`) | Só vê CI/PR; cego a **contract drift** e commit fora do fluxo federado | #16 |

**Correção raiz:** o formato de contrato (Fase 4) precisa ser o ponto de ancoragem da segurança, com campos **obrigatórios e verificáveis**: `tests:` (paths + lint que falha se ausente), fixtures de payload por operação (contrato **comportamental**, não só sintático), e schema estruturado para o veto (`{approved, blocked_contracts, required_migrations, reasoning}` — ausência de output = veto, fail-safe). Sem isso, "garantia de sucesso" é promessa, não mecanismo.

### 🟡 SA-3 — O spike cross-dir é load-bearing e está alocado tarde demais (3 achados: #3, #11, #23)

Toda a topologia de fan-out cross-repo (Fases 3–5) repousa numa capacidade **não verificada**: um subagente do `Workflow` consegue operar com o dir de outro membro como contexto primário? Se não, as Fases 3–5 colapsam. O design o trata como spike da Fase 3 — mas a Fase 1 já depende dele (adopt **escreve** em `<member>/.claude/`).

**Correção raiz:** elevar a **Fase 0-spike** (go/no-go, time-boxed, sem PR de produto): prova mínima de que o Claude Code escreve/lê num `additionalDirectory` como raiz. Documentar resultado como KB em `docs/knowledge-base/platforms/`. Se falhar, a arquitetura cross-dir é repensada antes de qualquer fase de produto.

---

## 2. Backlog priorizado de ajustes ao design

> Ordem de aplicação: resolver SA-1/SA-2/SA-3 reescreve a espinha do doc; os demais são refinamentos pontuais.

### 🔴 Blockers (7) — corrigir antes de aprovar o design para execução

| # | Lente | Ajuste ao design | Esf. |
|---|---|---|---|
| 1 | identity | Fase 0 de meta-spec **ou** realocar manifesto+experts em estrutura canônica (`docs/`/`agents/meta/`) | M |
| 2 | identity | Decidir `federation/` como categoria nova (PR meta-spec) **ou** comandos em `meta/` (recomendado) | S |
| 3 | feasibility | Reordenar backlog: PR de `commands.md §2` + `architecture.md §1.2` como Fase 0 explícita | S |
| 7 | phasing | Tornar PRs de meta-spec **pré-condição formal**, não pós-nota §7 | M |
| 4 | safety | Campo obrigatório `tests:` no contrato + lint "contrato sem teste = blocker"; dimensão de scan p/ contratos sem cobertura | M |
| 5 | safety | `MemberExpertSchema` (`approved`/`blocked_contracts`/`required_migrations`/`reasoning`); ausência de output = veto fail-safe | S |
| 6 | reuse | adopt deve passar `output_path=<member-root>/docs/reverse/` ao `/docs:reverse-consolidate` e gravar o path no manifesto (senão o reverse cai no hub, não no membro) | S |

### 🟡 Recommended (15) — fechar antes da fase correspondente

| # | Lente | Ajuste | Fase alvo | Esf. |
|---|---|---|---|---|
| 8 | identity | Reconciliar guardrail "SDAAL ≤400 linhas": o framework já o viola (jira 887, clickup 796, linear 785…); revisar a régua (400 p/ factory/interface/types; adapters ricos isentos) ou parar de citá-lo como proteção | design | S |
| 9 | identity | Mapear contratos p/ local canônico (`knowledge-base/concepts/` ou `meta-specs/`) ou incluir PR de `architecture.md §1.3` | F4 | S |
| 10 | identity | PR de `architecture.md §1.2` p/ skill nova **ou** dobrar em `onion-fleet` | F5 | S |
| 11 | identity | Elevar spike cross-dir a Fase 0 go/no-go (ver SA-3) | F0 | S |
| 12 | feasibility | Especificar enforcement da ordem de merge (gate humano), polling de status por membro, rollback | F5 | M |
| 13 | feasibility | Protocolo de merge de `.claude/` em repo legado (4 passos: inventariar conflitos → diff+confirmação → CLAUDE.md append → settings.json key-merge) | F1 | M |
| 14 | safety | Contrato **comportamental**: fixtures de payload por operação; juiz com mandato de revisar semântica | F4/F5 | M |
| 15 | safety | Seção "Rollback Protocol" no orchestrate (trigger, ordem inversa, falha→gate humano, pin de contrato) | F5 | M |
| 16 | safety | `status` com 3 dimensões: CI health, contract-code sync (drift), federation compliance (commit fora do fluxo) | F2/F5 | M |
| 17 | reuse | Corrigir citação: `/federation:scan` **não** delega a `/meta:evolve` (topologia fixa D1-D8); reusa o **padrão** onion-fleet + estilo de relatório | F3 | S |
| 18 | reuse | `docs/integration-contracts/` ao §7 spikes em pé de igualdade com `.claude/federation/`; aceite F4 inclui aval do gate-keeper | F4 | S |
| 19 | phasing | Schema mínimo estável do manifesto (`name`/`path`/`remote`) já na F1, ou declarar migração no aceite da F2 | F1/F2 | S |
| 20 | completeness | Classificar modos de membro: full-member / observe-only (não-Onion) / external (só contrato publicado) | F4 | M |
| 21 | completeness | Protocolo de desempate entre experts em conflito + checkpoints human-in-the-loop explícitos no F5 | F5 | S |
| 22 | completeness | Modelo de budget de token por fase (`budget_per_run` no manifesto); `status` expõe tokens/run | F3/F5 | M |

### 🟢 Opportunistic (2)

| # | Lente | Ajuste | Esf. |
|---|---|---|---|
| 23 | phasing | Dividir F3 em F3a (spike puro go/no-go) e F3b (`/federation:scan` produto) — descartável em horas se o spike falhar | S |
| 24 | completeness | Manifesto: `id` estável (sobrevive a rename) + política de remove/rename + lock file (`.claude/federation/.lock`) p/ concorrência de orquestradores | S |

---

## 3. O que foi refutado (12) — e por quê

A frota descartou 12 achados (33%) — confiança de que o backlog acima é sinal, não ruído. Padrões dos refutados: duplicatas da mesma violação de categoria entre lentes (consolidadas em SA-1); achados já cobertos por uma frase do próprio doc; e exageros sobre primitivas que de fato funcionam como o design assume (ex.: `additional working directories` existem e o doc os cita corretamente).

---

## 4. Invariantes de identidade — respeitadas

A lente `identity` **não** encontrou ressurreição da visão abandonada de 2026-05-18:
- ✅ Sem CLI standalone, sem `.onion/`, sem `packages/`, sem multi-IDE.
- ✅ Orquestração em skill/comando, experts em agentes — `agents→commands` não violado.
- ✅ Reuso de SDAAL/forge/fleet/Workflow como substrato, não runtime novo.

As violações de SA-1 são de **estrutura de diretório/categoria** (resolvíveis por encaixe canônico ou PR de meta-spec), **não** de filosofia.

---

## 5. Próximos passos

1. **Aplicar SA-1/SA-2/SA-3 ao doc de design** (#36): adicionar Fase 0 (meta-spec + spike cross-dir), reescrever §5-F4/F5 com a máquina de segurança especificada, e decidir encaixe canônico vs nova categoria. → revisão deste relatório com o usuário antes de editar.
2. **Validar a Fase 0 proposta com `@metaspec-gate-keeper`** antes de criar qualquer arquivo.
3. **Só então** liberar a Fase 1 (bootstrap-adopt) para `/meta:evolve` ou execução manual faseada.

> Este relatório é **efêmero** (convenção `docs/analysis/`): removível após os ajustes serem incorporados ao design.
