---
title: 'Adoção não vendoriza .claude/workflows/ — a skill onion-research aponta para um script ausente'
date: 2026-09-04
from: portal-gamificacao (consumidor, role adopted, greenfield)
to: core (onion-evolve)
type: bug
flow: upstream (consumidor→core)
---

## O que aconteceu
`/meta:adopt` (pin 0432320ee697) copia `.claude/{agents,commands,skills,utils,validation,hooks,rules}`.
A skill vendorizada `.claude/skills/onion-research/SKILL.md` instrui
`Workflow({ scriptPath: '.claude/workflows/onion-research.js', … })`, mas `.claude/workflows/` não está no
manifesto — no adotante o caminho não existe. Mesmo estado em `sacola-de-ideias` (verificado: sem `.claude/workflows`).

## Contorno aplicado aqui
Copiamos o script do core para `.claude/workflows/onion-research.js` e commitamos (branch `onion/adopt`).
`docs/onion/radar-sources.yaml` também não viaja; criamos um roster local.

## Proposta
Incluir `.claude/workflows` (e `docs/onion/radar-sources.yaml`, ou um roster mínimo) no manifesto `want=(…)` do
procedimento de cópia segura, ou fazer a skill degradar com mensagem clara quando o script não existir.

---

## Triagem do core — 2026-09-05

**Veredito: FIX — curado na fonte** (PR do dia 2026-09-04).
`.claude/workflows` entrou na superfície de adoção nos dois lugares que decidem o que viaja:
`want=` do `vendor-branch.sh` e os dois `want=` do `/meta:adopt`. Sem o diretório a skill `onion-research`
instrui `Workflow({scriptPath: ".claude/workflows/onion-research.js"})` e o comando NASCE MORTO no
adotante — era o caso. Guarda: caso `(b)` da mesma familia, ancorado em `^[^#]*want=\(` (a primeira
versão da guarda casava com o próprio comentario explicativo e passava verde). Rode `/meta:adopt --update`
para receber o diretório.
