---
title: "Federação × tipos de uso — a matriz canônica de reconciliação"
date: 2026-07-01
type: concept
status: active
related:
  - multi-repo-federation.md
  - ../../applying/adoption-lifecycle.md
  - ../../evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md
  - ../../onion/co-evolution-reference.md
  - ../../analysis/onion-adr-ledger-format-location-2026-06.md
  - ../../analysis/onion-federation-adr-a2a-format-interop-2026-06.md
---

# Federação × tipos de uso

> **O que esta KB resolve:** o papel da federação muda conforme o **tipo de uso** do Onion — mas os eixos
> que definem "tipo de uso" viviam espalhados em 4 artefatos que nunca foram cruzados
> ([adoption-lifecycle](../../applying/adoption-lifecycle.md), [RFC-0003](../../evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md),
> [cartão de co-evolução](../../onion/co-evolution-reference.md), [members.yaml](../../evolution/federation/members.yaml)).
> Esta KB é a **reconciliação canônica**: nomeia os eixos, cruza-os numa matriz única e consolida os
> gatilhos de graduação com o estado real verificado (auditoria orquestrada de 2026-07-01,
> run `wf_48c138b0-5f6`).

## 1. Os cinco eixos (e por que não são o mesmo)

| Eixo | Valores | Vive em | Descreve |
|---|---|---|---|
| **A. Cenário do alvo** | `greenfield` · `legacy` · `regulated` | `--mode` do `/meta:adopt`; campo `mode:` do members.yaml | o **estado do repo** no momento da adoção |
| **B. Modelo de controle** | `install` (vendorizado, durável) · `in-place` (efêmero) | flag `--in-place` do adopt | **como** o Onion vive no alvo |
| **C. Tier de federação** | `source` (T0) · `hub` (T1) · `consumer` (T2) · `standalone` (T3) | `role:` do members.yaml (RFC-0003 §2.1) | a **posição na rede** pós-adoção |
| **D. Operação de co-evolução** | quem-executa × direção-do-dado | [cartão de referência](../../onion/co-evolution-reference.md) | **cada comando** individual |
| **E. Topologia de sessão** | W1 source-por-path · W2 sessão-do-alvo · W3 duas-sessões-mesmo-repo · W4 par local · W5 remoto · W6 responder-gated · W7 agendada (🔴 rejeitada como base) | [ADR work-models](../../analysis/onion-adr-work-models-session-topologies-2026-07.md) | **quem trabalha onde, a partir de onde** |

**Regra de reconciliação:**

- Eixos **A + B** descrevem o **momento da adoção** (uma decisão pontual, tomada uma vez).
- Eixo **C** descreve a **vida em rede pós-adoção** (uma relação contínua).
- **`in-place` (efêmero) ⇒ sem tier.** Não instala `.claude/`, não carrega `role:`, não entra no
  members.yaml — está **fora da federação por construção** (decisão registrada, não lacuna).
- A e C são **ortogonais**: qualquer cenário (greenfield/legacy/regulated) pode ocupar qualquer tier T1/T3.
  O cruzamento `regulated` × classificação de dados tem doutrina própria (RFC-0003 §2.2, decisão
  2026-07-02): default **`protected`**, promoção a `public`/`collective` só com revisão humana explícita.

### 1.0 Eixo E — as sete topologias de sessão (resumo; canônico no [ADR](../../analysis/onion-adr-work-models-session-topologies-2026-07.md))

| W | Topologia | Uma linha |
|---|-----------|-----------|
| W1 | Source-driven por path | sessão do core opera o alvo por path (adopt por-path, `--in-place`, ponta adormecida com commit isolado + log) |
| W2 | Sessão do alvo (canônico) | um escritor por repo (I3); o core **indica**, a instância executa |
| W3 | Duas sessões, mesmo repo | handoff por worktree (escopo) OU sala-de-design/sala-de-obra (função); layout dos worktrees: [worktree-convention](../../evolution/worktree-convention-2026.md) |
| W4 | Par local (1 máquina) | carteiro-local automatiza transporte+notificação (`co-deliver`/`co-relay`) |
| W5 | Membro remoto | git-async mediado pelo maestro (sem carteiro-local) |
| W6 | **Responder-gated** | a sessão do destino **propõe rascunho** ao ver 📬/📥/⏰; maestro confirma (ato 3 = propor→confirmar) |
| W7 | Sessão agendada | 🔴 rejeitada como base (serviço vivo + autonomia-default); equivalente soberano = trigger *lazy por sessão* (hooks) |

As topologias **compõem** (W4 pode conter W3 em cada repo; W6 opera sobre W2/W4/W5). O **gatilho
invariável de reflexão** (⏰ migalha vencida no boot + protocolo de re-teste no `/meta:diary`) é parte
do eixo E — decidido com pesquisa fundamentada ([relatório](../../analysis/onion-work-models-research-2026-07.md)).

### 1.1 Os três namespaces de "role" (fonte de metade da confusão)

O termo *role* (e o par *producer/consumer*) tem **três significados distintos** no Onion — nunca declarados
como eixos separados até esta KB:

| Namespace | Campo | Valores | Onde | Status |
|---|---|---|---|---|
| **role de contrato** | `producer:` / `consumers:` | ids de membros | `contracts/<id>.md` (Federação formal) | ativo e **correto** — papel *por contrato*, ortogonal ao tier |
| **role de membro** | `role:` | `source·hub·standalone·consumer` | `members.yaml` v2 | canônico desde a RFC-0003 (substituiu `producer/consumer/lib` de membro) |
| **role de stamp** | `role:` | `source` · `adopted` | `.claude/.onion-version` | binário deliberado — o stamp só distingue fonte de instância; o tier fino vive no members.yaml |

> Regra prática: **contrato fala producer/consumers; rede fala tier; stamp fala source/adopted.**
> Um doc que use `producer` para membro (pré-RFC-0003) está desatualizado — ver backlog da
> [auditoria 2026-07-01](../../analysis/onion-federation-audit-2026-07-01.md).

## 2. A matriz canônica — tier × adoção × maquinaria

Legenda (herdada do adoption-lifecycle): 🟢 implementado/vivo · 🟠 parcial/a-desenhar · 🔒 gated (liga no gatilho) · — não se aplica

| Tier | Modos de adoção (eixos A+B) | Doc-bridge leve (co-evolve/announce/deliver/relay) | Federação formal (register/publish/check/status/rollback) | Identidade RFC-0003 (diary/personality/trust) |
|---|---|---|---|---|
| **T0 source** (core, `onion-evolve`) | — (não se auto-adota; é quem roda `/meta:adopt`) | 🟢 emissor de todos os fluxos; `co-announce`/`co-deliver` só rodam aqui | 🔒 seria o *producer* dos contratos que emitir | 🟢 diary implementado (F1; gate de 10 entradas pendente) · 🟠 personality (F2 a-desenhar) · 🟠 trust construído, bug de parsing pendente |
| **T1 hub** (ex.: um adotante) | greenfield/legacy/regulated × install — **sempre dirigido pelo Core** (hub-driven adoption = gatilho futuro; RFC-0003 §2.1, decisão 2026-07-02) | 🟢 `co-evolve`/`co-relay` ativos (caso 1-máquina); `co-relay --to peer` 🔒 (F3) | 🔒 | 🟠 bloco `trust:` no members.yaml; diary/personality do hub não rodaram |
| **T2 consumer-de-hub** | **core-driven** (RFC-0003 §5, decisão 2026-07-02): maestro roda `/meta:adopt` do core + registra `parent: <hub-id>`; o hub não roda adopt | 🔒 fora do desenho atual (`co-relay --to peer` é F3) | 🔒 | 🔒 tier definido na RFC + template do members.yaml; nenhum T2 real ainda |
| **T3 standalone** | greenfield/legacy/regulated × install, via Core direto | 🟢 idêntico ao T1, com `exposes_downstream` sempre vazio por definição | 🔒 | 🟠 igual ao T1 |
| **in-place (efêmero)** | qualquer cenário × `--in-place` | — fora da rede por construção | — | — |

## 3. O papel da federação por tipo de uso (narrativa)

- **T0 — core:** autoridade emissora. Anuncia (CHANGELOG → `co-announce` → `co-deliver`), registra membros,
  tria o `inbox/`. Lê tudo **por papel**, escreve **só em si** (invariante I3 — um escritor por repo). É quem
  gradua a Federação formal quando o gatilho chegar.
- **T1 — hub, 1-máquina (o caso real hoje):** consome downstream (`inbound/` + `/meta:adopt --update`),
  emite upstream (`inbox/` próprio → `co-relay` para o core). O "hub" só se diferencia do standalone quando
  tiver sub-adotados (T2) — mecanismo ainda sem doutrina. Enquanto isso, opera na prática como standalone
  com potencial de crescer.
- **T2 — consumer-de-hub:** doutrina fechada (RFC-0003 §5, decisão 2026-07-02): onboarda **via core**
  (source-driven) com `parent: <hub-id>` registrado; o hub não roda adopt e a relação hub→T2 é só de
  leitura (`exposes_downstream`). *Hub-driven adoption* é gatilho futuro (1º T2 real + dor de roteamento).
  Nenhum T2 real existe ainda.
- **T3 — standalone:** adota o core direto, sem sub-adotados; lê só o `public` do core; não vê outros
  membros. É o tier default para um novo adotante sem ambição de rede própria.
- **Membro remoto (outra máquina):** qualquer tier T1/T3 **sem** `local_path` — os atalhos Carteiro-local
  (`co-deliver`/`co-relay`) recusam operar e a comunicação vira git-async mediada pelo maestro
  ([onboarding-remote-member](../../evolution/federation/onboarding-remote-member.md)).
- **in-place:** sessão efêmera de inspeção/operação. Sem stamp, sem canais, sem tier. Se o repo precisar
  entrar na rede, o caminho é re-adotar com install.

## 4. Gatilhos de graduação — tabela única

Consolidação dos gatilhos hoje espalhados em ≥4 docs, com o **estado real** verificado pela auditoria de
2026-07-01:

| Graduação | Gatilho | Fonte canônica | Estado real (2026-07-01) |
|---|---|---|---|
| Doc-bridge → **Federação formal** (contratos + publish/check/status/rollback) | contrato que pode quebrar consumers **OU** ≥3-5 adotantes | RFC-0001 §gatilho; [ADR ledger](../../analysis/onion-adr-ledger-format-location-2026-06.md) | 🔒 corretamente desligada (1 adotante, 0 contratos); núcleo mecânico saudável (scripts + fixtures ✓) |
| **F1 diary** → F2 | 10 entradas reais + 1 semana de dogfood | RFC-0003 §4 | 🟠 comando existe; **0 entradas** — gate pendente |
| F2 **personality-sync** → F3 | híbrido (decisão 2026-07-02): mecânico (personality.md gerado pelo sync, 5 seções preenchidas) + confirmação do maestro | RFC-0003 §4 | 🟠 comando não existe; campos semeados à mão no members.yaml (marcados como seed) |
| F3 **trust + co-relay peer** → F4 | 1º relay peer real bem-sucedido | RFC-0003 §4 | 🟠 infra construída **antecipadamente** (antes do gate F1); parsing do bloco `trust:` com bug; `--to peer` não existe |
| F4 **synthesize-collective** | 3+ instâncias com diários maduros (90+ dias) | RFC-0003 §4 | 🔒 não existe (correto) |
| F5 **market-scan** | híbrido (decisão 2026-07-02): mecânico (≥1 entrada `market-signal` no diário OU pedido em `inbox/`) + confirmação do maestro | RFC-0003 §4 | 🔒 não existe (correto) |
| Carteiro-local → **Carteiro distribuído** (transporte automático entre máquinas) | mesmo gatilho da graduação formal / membro remoto real | [ADR ledger §3.3](../../analysis/onion-adr-ledger-format-location-2026-06.md) | 🟢 local entregue (`co-deliver`/`co-relay`); distribuído 🔒 a-desenhar (correto) |
| **Agent Card A2A** (projeção one-way do members.yaml) | 1º consumer não-Onion **OU** necessidade nomeada de interop | [ADR A2A](../../analysis/onion-federation-adr-a2a-format-interop-2026-06.md) | 🔒 não construído (correto — "não é dívida ativa") |

## 5. Invariantes que atravessam todos os tipos de uso

- **A2A runtime proibido** — agentes não executam em repos alheios; só o *formato* (Agent Card) é
  projeção one-way permitida, e ainda gated.
- **Um escritor por repo (I3)** — o core nunca commita no repo do adotante; entrega é sempre
  *sem-commit* (untracked no destino).
- **Maestro humano no ato 3** — transportar e notificar são automatizáveis; **executar** o que chega é
  gate humano, em qualquer tier.
- **Registro nunca à frente (nem atrás) da realidade** — members.yaml espelha os stamps reais; campos de
  maquinaria futura são marcados como seed. (Candidato a guard determinístico: comparar `members.yaml` vs
  `.onion-version` dos `local_path` — mesmo padrão inventory↔lint.)
- **Eficiência > cerimônia** — o doc-bridge leve basta até o gatilho; graduar antes é especulação.

## Referências

- Auditoria que verificou o estado real: [onion-federation-audit-2026-07-01.md](../../analysis/onion-federation-audit-2026-07-01.md)
- Federação formal (contratos, ledger): [multi-repo-federation.md](multi-repo-federation.md)
- Ciclo de vida da adoção (eixos A+B): [adoption-lifecycle.md](../../applying/adoption-lifecycle.md)
- Tiers e identidade federada: [RFC-0003](../../evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md)
- Referência rápida de comandos (eixo D): [co-evolution-reference.md](../../onion/co-evolution-reference.md)
