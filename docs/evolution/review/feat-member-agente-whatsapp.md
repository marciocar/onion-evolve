---
branch: feat/member-agente-whatsapp
pr: pendente
date: 2026-11-23
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 3
findings_blocking: 1
tokens: 0
duration_min: 5
findings_fixed: 3
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "subagente general-purpose (opus), isolado, mandato REFUTAR, só leitura"
nota: "registro do membro agente-whatsapp no members.yaml e o mapa da federação regenerado"
---

# Passada: `feat/member-agente-whatsapp`

## O que muda

- `members.yaml`: o membro `agente-whatsapp` (standalone, adopter, greenfield, parent onion-evolve), adotado pelo
  core em 2026-11-22/23 (PR #1 do repo merjado em 2026-11-23, pin 6276201205d3). Sem `a2a` (não assina sinais ainda)
  e sem `owner_session` (não há sessão dona; o core opera até ela nascer).
- `docs/onion/federation-map.md` regenerado (REGRA 38 (Mapa da federação sincronizado com members.yaml)).
- `members-validate.sh` rc 0 (36 membros).

## Passada isolada (2026-11-23)

Veredito **APPROVED**. Conferido: `members-validate.sh` rc 0 (36 membros); o id não colide com o framework
(`grep -rnw` vazio em `.claude/`, meta-specs e KBs; `projection-safety.sh` OK; `private-name-check.sh` 0 achados); o
mapa bate com `graph.sh --map`; o repo é privado e o nome não expõe cliente nem pessoa.

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 1 | O comentário do pin dizia adoção em 2026-11-22; a adoção é de 2026-11-23 | sim | não | Curado |
| 2 | Resíduo com veredito e sha pendentes | sim | não | Curado: veredito gravado; o sha é carimbado pelo `pr-finalize` |

## Passada isolada do onion-svc-gokapi (2026-11-23)

O PR passou a registrar também o repo de serviço `onion-svc-gokapi` (dono: a sessão onion-vps-ops), o que o #1703
pedia. Passada isolada (opus, REFUTAR, só leitura): **FIXES_NEEDED**, um bloqueio, curado.

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 3 | `integration_branch: main`, mas o repo usa `master` (defaultBranchRef, origin e PRs 1 a 3) | sim | sim | Curado: `master` |
| 4 | `(privado)` na URL do remote | menor | não | Mesmo molde dos irmãos; o `norm()` do `_pmv_member_row` remove o parêntese |

`members-validate.sh` rc 0 (41 membros); o mapa bate com `graph.sh --map`; o id não colide com o framework.
