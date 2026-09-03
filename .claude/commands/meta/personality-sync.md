---
name: personality-sync
description: 'Gera a personalidade EMERGENTE de uma instância Onion — .claude/identity/personality.md, 5 seções — a partir da EVIDÊNCIA DE USO (diário, .onion-version, primeiros 30 commits), nunca declarada à mão. Materializa a RFC-0003 §2.4 (Fase 2). Cada sync REGENERA (a personalidade acompanha o uso). O arquivo é PROJEÇÃO one-way (compatível A2A Agent Card), não fonte da verdade. Produz também a linha `personality_summary` do members.yaml para a própria instância. É o declarado≠verificado aplicado à identidade: mata os seeds manuais pré-F2.'
category: meta
tags: [federation, identity, personality, emergent, rfc-0003, declared-vs-verified, a2a-card]
version: "1.0.0"
updated: "2026-07-24"
allowed-tools: Read Write Edit Grep Glob Bash(bash .claude/validation/onion-version.sh) Bash(ls .claude/diary/*) Bash(cat .claude/diary/index.md) Bash(git log*) Bash(git rev-list*)
argument-hint: "[--dry-run]  (sem arg = gera/regenera para ESTA instância; --dry-run = mostra sem escrever)"
---

# 🪞 /meta:personality-sync — Personalidade emergente (RFC-0003 §2.4, Fase 2)

Gera o arquivo de identidade **.claude/identity/personality.md** (gerado por este comando — não existe até o 1º sync) desta instância **a partir do que ela FEZ**, não do que alguém
declarou que ela é. A personalidade **emerge do uso** — cada sync a **regenera** contra a evidência viva.
É o `declarado≠verificado` (a doutrina do core) virado para dentro: o `personality_summary` do `members.yaml`
era um **seed manual pré-F2**; este comando o substitui pelo que a evidência sustenta.

> **O que este comando NÃO é.** Não é fonte de verdade nem contrato — é **projeção one-way** (`a2a_card_projection:
> true`), compatível com A2A Agent Card, para o peer te conhecer. Não vendoriza nem executa em repo alheio (I3).
> Cada instância roda o seu (o core sincroniza o core; o adotante sincroniza o adotante na sessão dele).

## Passo 1 — Identidade da instância (determinístico)

Ler o **stamp `.claude/.onion-version`** (`role:`, `adopted_at`, `mode`, `source_commit`); só se ausente,
`bash .claude/validation/onion-version.sh`. Resolver `instance`/`tier`:
- `role: source` → `tier: source` (o core; `instance` = id do core no `members.yaml`, ex.: `onion-evolve`)
- `role: adopted` → `tier` = `hub|standalone|consumer` do próprio registro (o adotante conhece o seu id)

## Passo 2 — Reunir a EVIDÊNCIA DE USO (as 3 fontes da RFC-0003 §2.4)

1. **Diário** — a fonte mais rica. `cat .claude/diary/index.md` (o índice Tier-0: tipo, classificação, slug,
   **significância**, classe por entrada). Para as seções que pedem profundidade, abrir as entradas
   `innovation`/`decision`/`learning`/`error`/`reflection` mais significativas (as com `significance:`).
2. **`.onion-version`** — origem, adoção, modo (de onde a instância veio, quando, como).
3. **Git — os 30 primeiros commits:** `git log --reverse --format='%s' | head -30` — **o que o projeto fez
   PRIMEIRO** (a semente do caráter). E `git log --format='%s' -50` para o traço recente.

## Passo 3 — Sintetizar as 5 seções (EMERGENTE, com âncora)

Escrever o arquivo **.claude/identity/personality.md** (saída deste comando) no formato da RFC-0003 §2.4. **Regra dura:** cada afirmação
material **traça à evidência** (cite o slug da migalha, o commit, ou o campo do stamp) — se não emerge de
uma fonte do Passo 2, **não entra** (é o mesmo rigor do `declarado≠verificado`; personalidade inventada é o
modo-de-falha). Seções:

- **Domínio e contexto** — o que a instância faz e o terreno onde opera (do `.onion-version` + git inicial).
- **Especialidades desenvolvidas** — capacidades que EMERGIRAM (dos `innovation`/`learning` do diário).
- **Adaptações do core** — o que a instância mudou/estendeu no core (dos `decision`/`innovation`).
- **Padrões de erro superados** — os `error`/`reflection` do diário (as lições que viraram mecanismo).
- **O que ofereço à rede** — a doutrina/ferramenta compartilhável (`classification: collective 📤`).

Frontmatter: `instance`, `tier`, `generated: <hoje>`, `review_after: <hoje+30>`, `a2a_card_projection: true`.

## Passo 4 — `personality_summary` (1 linha) + members.yaml

Destilar UMA linha densa (o núcleo do caráter emergente) e **substituir** o `personality_summary` +
`personality_last_sync` da própria instância no `members.yaml`:
- **Core (`role: source`):** edita o próprio registro no `members.yaml` (o core é dono do ledger).
- **Adotante:** gera a linha e a **relaya upstream** (`/meta:co-relay` → `inbox/` do core) — o core é quem
  escreve no ledger (I3: o adotante não commita no repo do core).

Remover o comentário `# seed manual pré-F2` — o campo passa a ser **auto-gerado, com âncora na evidência**.

## Passo 5 — Gate humano (RFC-0003 §4, F2)

Mostrar o `personality.md` gerado + a linha-resumo e **pedir confirmação** ao maestro: *"o texto reflete a
instância?"*. O gate mecânico (arquivo existe, 5 seções preenchidas, gerado-não-manual) + o gate humano
fecham a Fase 2. `--dry-run` mostra tudo sem escrever.

## ⚠️ Notas

- **Regenera, não acumula.** Cada sync reescreve o `personality.md` inteiro contra a evidência atual — a
  personalidade **acompanha** o uso (o `review_after +30` cobra o próximo sync).
- **Projeção, não fonte** (`a2a_card_projection: true`): nunca derive decisão/gate deste arquivo; a verdade
  vive no diário/KG/members.yaml. Ele **conta**, não **governa**.
- **Âncora obrigatória:** afirmação sem fonte no Passo 2 é o mesmo que pin declarado sem verificar — não entra.

## 🔗 Referências
- Spec: [RFC-0003 §2.4](../../../docs/evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md) · Roadmap F2 (§4)
- Fonte da evidência: [`/meta:diary`](diary.md) (o diário é a matéria-prima) · `.claude/.onion-version` · git
- Transporte upstream (adotante): [`/meta:co-relay`](co-relay.md) · Registro: [members.yaml](../../../docs/evolution/federation/members.yaml)
