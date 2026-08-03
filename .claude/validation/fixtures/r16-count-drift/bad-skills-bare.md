# Fixture de drift — caso BAD (Regra 16, forma BARE 'N skills' com âncora `.claude/skills/`)

O Sistema Onion entrega __ONION_SKILLS_DRIFT__ skills em `.claude/skills/` para orquestração.

A forma bare 'N skills' só é total-atual com a âncora `.claude/skills/` na mesma linha
(sem ela, 'skills' é ruído comum demais em prosa). Com a âncora presente e o número
divergindo da SSOT (placeholder + offset), a Regra 16 (SOFT) deve citar este arquivo —
é a classe que driftou em docs/INDEX.md e na KB de identidade sem nenhum feeder
disparar (PR #517).
