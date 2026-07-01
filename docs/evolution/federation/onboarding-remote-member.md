---
title: 'Onboarding de membro remoto — federar um onion que vive em outra máquina'
date: 2026-07-01
type: guide
status: living
related:
  - members.yaml (registro de membros)
  - ../rfc/rfc-0003-federated-identity-collective-intelligence.md (hierarquia de tiers)
  - ../../../.claude/commands/meta/co-announce.md (producer do doc-bridge)
  - ../../../.claude/commands/meta/co-deliver.md (Carteiro-local — só mesma máquina)
  - ../../../.claude/commands/meta/co-relay.md (Carteiro-local upstream — só mesma máquina)
  - ../../../.claude/commands/meta/adopt.md (instala o framework no alvo)
---

# Onboarding de membro remoto

> **Quando usar este guia:** alguém (colega, outro time) tem o **próprio checkout do Onion**, numa
> **máquina diferente da sua** — sem filesystem compartilhado. Você quer registrar esse onion no seu
> `members.yaml` (federá-lo) e manter co-evolução com ele, mesmo sem acesso local ao repo dele.

## O que "adotar/federar" significa aqui (e o que não é)

`/meta:adopt` só faz uma coisa: **instala o framework** num repo-alvo, a partir de uma fonte. O seu
onion-evolve **não "adota"** o onion de outra pessoa — o que você quer é **federar**: registrar aquele
onion como **membro** no seu `docs/evolution/federation/members.yaml`, para que a co-evolução (CHANGELOG,
inbox/inbound) o reconheça.

**Diferença-chave vs. o caso 1-máquina (ex. `rhilo-metagamify`, `arandek`):** quando o adotante está no
mesmo filesystem, os atalhos "Carteiro-local" (`/meta:co-deliver`/`/meta:co-relay`) automatizam a
entrega/notificação. **Sem filesystem compartilhado, esses atalhos não funcionam** — a comunicação vira
**git-async, mediada por você (maestro)**, sem atalho automático de cópia de arquivo.

## Passo a passo

### 1. Ele adota o Onion primeiro (na sessão dele, na máquina dele)

Se o repo dele ainda não tem o framework: ele roda `/meta:adopt` apontando para a **URL git** do seu
`onion-evolve` (não um path local — as máquinas são diferentes):

```
/meta:adopt https://github.com/marciocar/onion-evolve.git
```

Isso carimba `.claude/.onion-version` no repo dele (`role: adopted`, pin no commit que ele puxou).

### 2. Você registra o onion dele no SEU `members.yaml`

Edite [`members.yaml`](members.yaml) aqui no core e adicione uma entrada:

```yaml
- id: <slug-do-projeto-dele>
  name: <nome>
  role: hub | standalone   # hub SE ele for ter sub-adotados próprios (T2); standalone se não
  parent: onion-evolve
  remote: github.com/<org>/<repo-dele>
  # local_path: OMITIDO — máquinas diferentes, sem filesystem compartilhado
  onion_version: <commit que ele pinou no passo 1>
  adopted_at: <AAAA-MM-DD>
  mode: greenfield | legacy | regulated
  personality_summary: "<1 linha>"
  specializations: []
  personality_last_sync: <AAAA-MM-DD>
  trust:
    can_receive_from: [onion-evolve]
    can_advise_to: [onion-evolve]
    can_correct_to: []
    diary_readable_by: [onion-evolve]
    diary_classifications_shared: [public, collective]
    exposes_downstream: []
```

Sem `local_path`, `/meta:co-deliver` e `/meta:co-relay` recusam operar nesse membro (exigem `--target`
resolvível no mesmo filesystem) — é esperado, não um bug.

### 3. Comunicação vira git-async, mediada por você — sem atalho automático

| Direção | Fluxo normal (1-máquina) | Sem filesystem compartilhado |
|---|---|---|
| **Downstream** (você → ele) | `/meta:co-announce` (gera outbox) → `/meta:co-deliver` (copia pro `inbound/` dele) | `/meta:co-announce` gera o rascunho na sua `outbox/<id>/` normalmente; **pule o `co-deliver`** — copie o conteúdo manualmente (cola/PR/e-mail) e **ele** commita no `inbound/` **da sessão dele** |
| **Upstream** (ele → você) | ele deposita em `inbox/` dele → `/meta:co-relay` (copia pro seu `inbox/`) | ele deposita em `inbox/` dele; **pule o `co-relay`** — ele transporta manualmente (PR/e-mail) e **você** commita no seu `inbox/` e tria |

### 4. Se ele tiver sub-adotados próprios (T2, "adotando outro repo")

Isso é gerenciado **por ele**, não por você — é a fronteira de tiers do RFC-0003: **T0 (você) supervisiona
T1 (o hub dele); T1 supervisiona T2**. Se ele mantiver o próprio `members.yaml` (sendo `role: hub`), os
sub-adotados dele entram lá, com `parent: <id-dele>`. No seu registro, você só marca que o dele **expõe**
downstream (campo `exposes_downstream` da entrada dele) — não lista os T2 diretamente no seu `members.yaml`.

## Referência rápida — hierarquia de tiers (RFC-0003)

| Tier | `role` | Adota de quem | Pode ter sub-adotados? |
|---|---|---|---|
| T0 | `source` | — (é a fonte) | sim, T1s |
| T1 | `hub` | core (T0), diretamente | sim, T2s |
| T1 | `standalone` | core (T0), diretamente | não |
| T2 | `consumer` | um hub (T1), não o core diretamente | não |

Um membro remoto onboardado por este guia é sempre **T1** (`hub` ou `standalone`) — ele adota o core
**diretamente**, mesmo estando numa máquina diferente. `local_path` ausente não muda o tier; só desliga os
atalhos de mesma-máquina.

## Checklist

- [ ] Ele rodou `/meta:adopt <url-do-core>` na máquina/sessão dele — `.onion-version` carimbado lá
- [ ] Você adicionou a entrada dele em `members.yaml` (sem `local_path`)
- [ ] Ele sabe que precisa transportar `inbox/`↔`inbound/` manualmente (sem `co-relay`/`co-deliver`)
- [ ] Se ele for `hub`: ele entende que os T2 dele são responsabilidade dele, não sua
