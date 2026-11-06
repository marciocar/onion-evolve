---
branch: feat/register-onion-vps-ops
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: APROVADO
elenxo: sim
reviewer: autor (agente de execução da sessão do core, sem subagente por regra do brief)
nota: >-
  Passada adversarial feita pelo próprio agente, porque o brief proibia lançar subagente: não é
  revisão independente, e isso fica declarado. Tokens não medidos (0). Dois mutantes rodados contra
  as guardas que julgam a entrada, os dois mortos. Os 2 achados reais são limites, nenhum bloqueia.
---

# Passada adversarial: `feat/register-onion-vps-ops`

## O que muda

- `docs/evolution/federation/members.yaml`: entrada nova `onion-vps-ops` (`role: standalone`,
  `kind: adopter`, `parent: onion-evolve`, `mode: greenfield`), pin `6760a7bede50` conferido por
  `pin-integrity-check.sh` (`pin-ok 6760a7bede50`). Decisão de origem: `D_SESSAO_OPS_ONION_VPS_OPS_1106`.
- Projeções regeneradas: `docs/onion/federation-map.md` (REGRA 38) e `docs/onion/federation-console.html` (REGRA 24).

## Achados

| # | achado | real? | destino |
|---|---|---|---|
| 1 | O carimbo do alvo diz `role: adopted` e o registro diz `role: standalone`: parece divergência | não | É o vocabulário de cada lado: o registro não aceita `adopted` (medido no mutante 1), e o precedente `onion-curation` tem o mesmo par (carimbo `adopted`, registro `standalone`) |
| 2 | A descrição poderia carregar IP ou hostname da máquina | não | Conferido: `personality_summary` só nomeia ferramentas e a decisão; `projection-safety.sh` OK e `door-leak-scan.sh` sem achado nas raízes que viajam |
| 3 | O comentário do `onion_version` diz que a main remota nasce com o PR da adoção: hoje o repo remoto está **vazio** (o push da `main` foi barrado pela guarda de repo alheio e é ato do maestro). O `ops/registry-pins.sh`, que carimba pelo remoto, não acha o pin até lá | sim | Limite declarado abaixo |
| 4 | Com o membro registrado, a família `word` da REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação) passa a acusar `onion-vps-ops` em superfície que viaja | sim | Medido: `git grep -w onion-vps-ops` no core só casa `members.yaml`, as duas projeções e o grafo/síntese da pesquisa de mensageria, nenhum deles em raiz que viaja. Limite: citação futura numa raiz que viaja vai reprovar, e é esse o desenho |

## Mutantes

- **M1**: `role: adopted` na entrada → `members-validate.sh --json` sai `valid:false` ("'role' inválido"). Morto.
- **M2**: `name:` sem o id antes do parêntese (P6) → `members-validate` passa, `projection-safety.sh` sai rc 1. Morto pela guarda certa.
- Cópia limpa restaurada e conferida igual ao índice (`git diff --quiet`).

## Limites declarados

- Achado 3: até o maestro empurrar a `main` do alvo, o pin do registro só é conferível localmente.
- Achado 4: é o comportamento desejado da guarda, não defeito do PR.
- A passada é do autor, não independente (brief sem subagente).
