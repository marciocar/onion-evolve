# 🧅 Co-evolução & evolução — cartão de referência

> Referência rápida da família de comandos de co-evolução do Sistema Onion. Como o core
> (`onion-evolve`) e seus adotantes co-evoluem por **git-async**, com o humano como **maestro**.
> Vocabulário canônico (2026-06-24): **downstream / upstream / handoff** (ex-flow A/B/C —
> ver [ADR](../analysis/onion-adr-coevolution-flow-naming-2026-06.md)).

## Dois eixos independentes

Ao ler a tabela, não confunda:

- **▶ Quem executa** — em que lado o comando roda: `core` · `adotante` · `ambos` · `maestro` · `producer`/`consumer` (papéis de federação).
- **Direção do dado** — pra onde a informação flui: `downstream` / `upstream` / `handoff`.

Quem roda ≠ pra onde o dado vai. Ex.: `/meta:co-deliver` **roda no core** mas o dado é **downstream** (vai para o adotante).

> Estes dois eixos descrevem **cada comando**. Os eixos maiores — tier de federação (T0-T3), modo de adoção,
> **topologia de sessão (Eixo E, valores W1-W7: quem trabalha onde, a partir de onde)** e qual maquinaria vale em cada
> combinação — estão reconciliados na KB
> [federation-usage-modes.md](../knowledge-base/concepts/federation-usage-modes.md) (matriz canônica + gatilhos de graduação).

## Os 3 fluxos

| Fluxo | Direção | Canal | Conteúdo |
|-------|---------|-------|----------|
| **downstream** | core → adotante | `inbound/` (no adotante) | release / anúncio / decisão |
| **upstream** | adotante → core | `inbox/` (no core) | sinal / feedback / bug / pedido-de-ajuda |
| **handoff** | intra-repo | git worktrees | um escritor por escopo (concorrência, não direção cross-repo) |

## Ciclo de vida de um sinal de campo

```
sinal              → /meta:co-evolve   → /meta:co-announce → /meta:co-deliver  → processa
▶ adotante           ▶ core              ▶ core              ▶ core               ▶ adotante
(inbox/, upstream)   (triagem+veredito)  (gera no outbox/)   (entrega no inbound/) (📥 lê, commita de lá)
```

## Comandos

### Auto-evolução do core

| Comando | ▶ Roda | Direção | O que faz |
|---------|--------|---------|-----------|
| `/meta:evolve` | core | intra-core | Auto-auditoria via **orquestração** (fan-out → síntese) → backlog priorizado com evidência em `docs/analysis/`. **Read-only** (propõe, não muta). |

### Co-evolução — doc-bridge leve

| Comando | ▶ Roda | Direção | O que faz |
|---------|--------|---------|-----------|
| `/meta:co-evolve` | **ambos** | lê upstream + downstream | **Bússola**: detecta o papel (source/adopted), lê `inbox/` + `inbound/`, mostra a posição, gerencia (move p/ `_processed/`). |
| `/meta:co-announce [<data\|slug>]` | core | downstream | **Producer**: transforma uma entrada do `CHANGELOG` em anúncio pronto em `outbox/<id>/`; resolve destinatário via `members.yaml`. _Guarda: só source._ |
| `/meta:co-deliver <id> [<file>] --target <path>` | core | downstream | **Carteiro-local** (NOVO): entrega o anúncio no `inbound/` de adotante na mesma máquina → dispara o 📥. **Entrega-sem-commit** (untracked; core nunca commita no repo alheio — I3). Não-gated. |
| `/meta:adopt <path\|url> [--update]` | core → alvo | downstream | Instala / atualiza o Onion num repo (greenfield · legacy · regulated); auto-emite relatório no `inbound/` do alvo; provisiona canais + hook "you have mail". Faseado, retomável. |

### Federação formal — ledger de contratos (gated)

> Liga só no **gatilho de graduação**: contrato que pode quebrar consumers **ou** ≥3–5 adotantes.
> Até lá, o doc-bridge leve acima basta. Ledger = repo git neutro (resolução via `--ledger` / `.env FEDERATION_LEDGER`).

| Comando | ▶ Roda | Direção | O que faz |
|---------|--------|---------|-----------|
| `/meta:federation-register <contract>` | producer | — | Registra + valida contrato spec-as-code no ledger (tests + fixtures **obrigatórios**). Não anuncia. |
| `/meta:federation-publish <id>` | producer | downstream | Anuncia o bump (breaking/compatível) aos consumers no `CHANGELOG` do ledger. |
| `/meta:federation-check` | consumer | upstream | Consumer valida em casa os contratos endereçados; **veto fail-safe** (breaking ou output ausente = veta). |
| `/meta:federation-status` | qualquer | — | Monitor read-only cross-repo: contract-drift + status de CI por membro. |
| `/meta:federation-rollback <id>` | maestro | — | Rollback guiado: pina versão anterior no ledger + guia reverts em ordem inversa (consumers → producer). Human-gated. |

### Sinais de sessão

| Comando | ▶ Roda | O que faz |
|---------|--------|-----------|
| `/warm-up` · `/catch-up` | qualquer | Apontam para os canais quando há mensagens (📬 inbox / 📥 inbound). O hook `co-evolution-inbox-check.sh` já conta no SessionStart. |

## Invariantes (valem em qualquer fluxo)

- **Um escritor por repo** — o core nunca commita no repo alheio (entrega untracked é OK).
- **Maestro humano** — roteia e decide ordem de merge / rollback.
- **git-async** — coordenação por markdown commitado; sem IA↔IA viva.
- **Append-only** — `CHANGELOG` e `_processed/` nunca se reescrevem (auditoria).
- **A2A runtime proibido** — formato permitido como projeção one-way (gated).
- **Eficiência > cerimônia** — doc-bridge leve agora; Federação = graduação.

## Referências

- Protocolo dos 3 fluxos: [docs/evolution/README.md](../evolution/README.md) · [RFC-0001](../evolution/rfc/rfc-0001-co-evolution-comms.md)
- ADRs: [vocabulário](../analysis/onion-adr-coevolution-flow-naming-2026-06.md) · [formato/localização do ledger](../analysis/onion-adr-ledger-format-location-2026-06.md)
- Registro de adotantes: [members.yaml](../evolution/federation/members.yaml) · Anúncios: [CHANGELOG](../evolution/federation/CHANGELOG.md)
