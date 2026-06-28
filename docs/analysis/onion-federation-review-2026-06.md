# Revisão: Federação do Onion vs. estado da arte de IA/desenvolvimento (junho/2026)

| Campo | Valor |
|-------|-------|
| **Data** | 2026-06-15 |
| **Tipo** | Revisão analítica (read-only sobre o conceito; não muta `.claude/`) |
| **Escopo** | Conceito de "multi-repo federation" do Onion vs. padrões externos de federação de agentes (A2A) e coordenação multi-repo, atualizados a jun/2026 |
| **Fontes internas** | `docs/knowledge-base/concepts/multi-repo-federation.md`, `docs/knowledge-base/frameworks/agent-orchestration-landscape-2026.md`, `docs/analysis/onion-federation-design-v2-2026-06.md` |
| **Fontes externas** | A2A (Linux Foundation, Google), padrões de coordenação multi-agente 2026 (ver §6) |
| **Método** | Leitura das KBs internas + busca web (jun/2026) + síntese comparativa |

---

## 1. O ponto central: existem **duas** "federações" — e o Onion escolheu a menos óbvia

A indústria usa a mesma palavra para coisas diferentes. Separar isso é o pré-requisito de qualquer revisão honesta:

| | **Federação no sentido da indústria (A2A)** | **"Multi-repo federation" do Onion** |
|---|---|---|
| O que federa | **Agentes vivos** de vendors distintos se descobrindo e delegando entre si | **Repositórios soberanos** coordenando mudanças de integração |
| Meio | HTTP/SSE/JSON-RPC, Agent Cards, runtime (client↔remote agent) | **Git assíncrono** — ledger versionado, sem servidor, sem conexão viva |
| Quem decide | O agente cliente orquestra autonomamente | **Humano = maestro** (`multi-repo-federation.md:34`) |
| Unidade de verdade | Capability / Agent Card | **Contrato spec-as-code versionado (semver)** (`:41-58`) |

O Onion **deliberadamente não faz** federação A2A. É linha vermelha registrada: *"Instâncias vivas A2A / runtime distribuído — Fase 5 ABANDONADA … nunca IA-fala-IA em tempo real"* (`multi-repo-federation.md:171`), abandonada formalmente em 2026-05-18.

**Consequência:** a "federação de agentes" do Onion **não é** federação de agentes no sentido que o mercado dá ao termo em jun/2026 — é **federação de repositórios/contratos com humano no loop**. Não é defeito; é uma divergência de nomenclatura que custa caro na comunicação externa (ver §5).

## 2. O que o Onion efetivamente construiu (funcionalidades — Fases 1-3)

**5 comandos** (`/meta:federation-*`, orquestram no nível principal):
- `register` — valida + grava+commita o contrato (não toca o inbox)
- `publish` — **único escritor do CHANGELOG/inbox**; classifica o bump, checkpoint do maestro
- `check` — lado consumer: **veto de 1ª mão** fail-safe (`MemberExpertSchema`; breaking/ausência = bloqueia)
- `status` — monitor read-only: contract-drift + CI por membro via **forge adapter**
- `rollback` — Rollback Protocol guiado, **human-gated**, ordem inversa

**3 scripts determinísticos** (`.claude/validation/`, sem LLM): `federation-contract-validate.sh`, `federation-inbox-scan.sh`, `federation-status-scan.sh`.

**Decisões de design que se sustentam:**
- Contrato exige `tests:` **e** `fixtures:` obrigatórios (`:54-58`) → transforma "promessa" em gate **comportamental** (pega mudança de *significado* com a mesma assinatura).
- `id` estável que sobrevive a rename (`:89`).
- Validação determinística **fora de agente** (ajuste 6a) — separação de poderes madura: o comando orquestra, o script decide.

## 3. Confronto com o estado da arte (junho/2026)

### 3a. Onde o Onion está **alinhado ao consenso verificado** ✅

Achado mais forte da revisão: os **seis padrões canônicos** de coordenação multi-repo de 2026 (fonte externa) batem quase 1:1 com o que o Onion faz:

| Padrão de consenso (externo, jun/2026) | Equivalente no Onion |
|---|---|
| Spec-scoped tasks | Contrato como SSOT de escopo (`:41`) |
| Worktree isolation | Camada de orquestração (`agent-orchestration`) + repos soberanos |
| Coordinator / specialist / **verifier** | maestro + `check` (verifier) + `MemberExpertSchema` |
| Tests + automated gates antes do merge | `contract-validate.sh` + `tests`/`fixtures` obrigatórios |
| **Verification nodes at handoff boundaries** | `check` no consumer = exatamente isso |
| Sequential merge order | ordem producer-compatível→consumers com gate CI verde (`:152`) |

Conclusão: **a engenharia de coordenação do Onion é mainstream-correta** — não é exótica nem desatualizada.

### 3b. Onde o Onion **diverge** — e o custo dessa divergência

O A2A consolidou-se como **a camada de interoperabilidade** entre agentes de vendors diferentes: governado pela Linux Foundation, **150+ organizações em abril/2026** (Atlassian, Salesforce, SAP, ServiceNow, MongoDB, PayPal…), com Agent Cards para descoberta de capacidade. É async-capável e não exige "IA-fala-IA em tempo real" no sentido ingênuo.

O Onion fica **fora desse ecossistema por escolha**.

**Preço:**
- Não interopera com agentes/repos **não-Onion** (o próprio KB admite: `:170`).
- Descoberta de capacidade é manual (`members.yaml`) vs. Agent Cards padronizados.

**Ganho (real):**
- **Zero vendor lock-in** a um protocolo ainda em maturação.
- Evita modos de falha que o landscape lista como **não resolvidos por ninguém**: segurança adversarial em fan-out (prompt injection cross-agent, exfiltração via tool-call), break-even de custo, reprodutibilidade para domínios regulados (`landscape:80-87`).
- **Git como trilha de auditoria durável** — exatamente o que falta às plataformas A2A (o landscape aponta "baixa rastreabilidade de agentes" como fraqueza enterprise, `:42`).

## 4. Veredito sobre a decisão de abandonar A2A vivo

**Defensável e bem fundamentada para o escopo declarado do Onion**, com uma ressalva.

**Defensável porque:** o valor entregue (coordenar mudanças contract-safe entre repos que o próprio Onion gerencia, humano no loop, git como spine auditável) **não precisa** de A2A vivo, e A2A vivo traria exatamente os riscos que o landscape marca como sem solução. "Controle antes de autonomia" é a tese da corrente #1 (Anthropic/Claude Code), e o Onion a respeita.

**Ressalva (meio-termo não explorado):** o A2A de jun/2026 **não é só** runtime vivo — ele padroniza **semântica de descoberta de capacidade** (Agent Cards), conceitualmente irmã do par `members.yaml` + `contracts/`. O Onion poderia adotar o **formato de contrato/discovery do A2A como serialização** (interop de *formato*, não de *runtime*) sem violar a linha vermelha do "IA-fala-IA". Hoje a doutrina trata A2A como monólito a rejeitar, quando há uma camada (descoberta/contrato) compatível com a filosofia git-async.

## 5. Gaps e recomendações concretas

1. **Nomenclatura (comunicação externa)** — Nos materiais de divulgação (`docs/materials/`), renomear de "federação de agentes" para **"federação de repositórios contract-safe"** / "multi-repo contract federation". Senão um leitor técnico de jun/2026 espera A2A e conclui (erradamente) que o Onion está atrasado.

2. **Posicionar a divergência A2A explicitamente** — A KB §7 lista A2A como abandonado, mas não **argumenta** contra o estado atual (150+ orgs, Linux Foundation). Vale uma subseção "Por que não A2A (e o que reavaliaríamos)" citando os riscos não-resolvidos do landscape. Vira munição honesta para `docs/materials/critical-article-outline.md`.

3. **Explorar interop de formato** — Avaliar adotar Agent Cards / semântica A2A **apenas como formato de contrato/discovery**, mantendo transporte git-async. Candidato a ADR.

4. **Gaps que o landscape diz que *ninguém* resolve** continuam abertos no Onion: segurança adversarial em fan-out, modelo de break-even de custo, reprodutibilidade regulada. A federação herda esses gaps da camada de orquestração — registrar no backlog `/meta:evolve`.

5. **Frescor das KBs** — `multi-repo-federation.md` (2026-06-15) e `agent-orchestration-landscape-2026.md` (atualizado nesta leva para 2026-06-15, com os números A2A de abril/2026). Próxima atualização planejada do landscape: dez/2026.

---

## Resumo em uma linha

A federação do Onion é **engenharia de coordenação mainstream-correta** (bate com os 6 padrões de consenso de 2026) sobre uma **escolha arquitetural deliberadamente contrária** (git-async + humano-maestro em vez de A2A vivo) que é **defensável para seu escopo** — o que falta é (a) **nomeá-la corretamente** para não parecer atrasada e (b) **argumentar a divergência A2A** em vez de apenas declará-la abandonada.

---

## 6. Fontes externas (junho/2026)

- [Linux Foundation — A2A Protocol Project](https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project-to-enable-secure-intelligent-communication-between-ai-agents)
- [Google Developers — Announcing the A2A Protocol](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)
- [Google Cloud — Agent2Agent protocol is getting an upgrade](https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade)
- [Augment Code — Multi-Agent AI Architecture: Patterns for Enterprise Development (2026)](https://www.augmentcode.com/guides/multi-agent-ai-architecture-patterns-enterprise)
- [Hugging Face — 2026 Agentic Coding Trends](https://huggingface.co/blog/Svngoku/agentic-coding-trends-2026)

> Números de adoção (150+ orgs, contagens de vendor) são tratados como **indicativos** — adoção de protocolo é parcialmente self-report. O fato estrutural (A2A sob Linux Foundation como camada de interop dominante) é cross-source.

---

**Mantido por:** Sistema Onion · **Última atualização:** 2026-06-15
