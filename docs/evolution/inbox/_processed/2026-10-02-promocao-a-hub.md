---
title: "brain-granaai promovido a hub — registrar no members.yaml e corrigir o snippet do --promote-hub (carimbaria pin inexistente)"
date: 2026-10-02
type: signal
from: brain-granaai (hub, pin 663fdbc5bdcc)
severity: medium
---

# Promoção a hub (decisão do maestro, 2026-10-02)

O maestro promoveu o brain-granaai de `adopted` para **`hub`**: segue apoiado pelo onion-evolve (recebe
`/meta:adopt --update`) e passa a adotar e atualizar os projetos da GranaAI (Camada 2). Carimbo atual:

```
framework: onion-evolve
source_commit: 663fdbc5bdcc
source_commit_date: 2026-10-02
role: hub
adopted_at: 2026-10-01
updated_at: 2026-10-02
```

`pin-integrity-check` → `pin-ok 663fdbc5bdcc`; lint 0 HARD.

## Pedidos ao core

1. **Registrar a mudança de papel no `members.yaml`** (entrada `brain-granaai` → `role: hub`). Sem isso a REGRA 92
   (paridade papel do registro × carimbo) segue sem poder julgar aqui, e a REGRA 85 continua `SEM-OBJETO`.
2. **Próximo `--update` com o papel `hub`**: o `vendor-branch.sh` deve receber `ONION_ROLE=hub` (lido do stamp) para
   entregar o conjunto de verticais e work tools de hub do `roles.yaml`.

## Bug no snippet do `--promote-hub` (`.claude/commands/meta/adopt.md`)

O snippet chama `write-stamp.sh` com:

```bash
--commit "$(git -C "$REPO" rev-parse --short=12 HEAD)" \
--commit-date "$(git -C "$REPO" log -1 --format=%cd --date=short)" \
```

Isso carimba como `source_commit` o **HEAD do próprio adotante**, que não existe na história do core. O
`pin-integrity-check` do próximo `--update` acusaria pin inválido (delta e early-exit desligados, e o carimbo
mentiria sobre a versão do framework). Aqui a promoção foi feita preservando o pin vigente:

```bash
--commit "$(awk '/^source_commit:/{print $2}' .claude/.onion-version)" \
--commit-date "$(awk '/^source_commit_date:/{print $2}' .claude/.onion-version)" \
```

Sugestão: o snippet (ou o `write-stamp.sh` no caminho `--role` sem `--commit`) preservar `source_commit` e
`source_commit_date` do stamp existente, e um selftest que prove `pin-ok` depois da promoção.
