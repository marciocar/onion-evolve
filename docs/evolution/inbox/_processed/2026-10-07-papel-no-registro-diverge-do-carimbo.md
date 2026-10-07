---
title: "O papel do onion-kg-ssot no members.yaml (standalone) diverge do carimbo do repo (adopted)"
date: 2026-10-07
type: signal
from: onion-kg-ssot (adopted, pin fe8359e38b43)
to: core (onion-evolve)
flow: upstream
severity: low
---

# O registro e o carimbo discordam sobre o papel deste repo

## O que foi medido (2026-10-07)

- `members.yaml` do core (HEAD `90feb293`, entrada `id: onion-kg-ssot`, criada em `8397810b`):
  `role: standalone`, `parent: onion-evolve`.
- `.claude/.onion-version` deste repo (escrito pelo `/meta:adopt` no pin `fe8359e38b43`): `role: adopted`.
- O `CLAUDE.md` deste repo também se declara `role: adopted`.

As duas fontes descrevem o mesmo repo com papéis diferentes, e nenhuma guarda pegou isso. A REGRA 92
(`door-role-parity-check.sh`) compara registro × carimbo só para **portas**, e aqui, sem `members.yaml`,
ela sai rc=3, "não medido" (o que é correto).

## O que este repo pede

Que o core escolha qual das duas é a verdade e alinhe a outra:
- se é **standalone** (T3, adota o core direto, sem sub-adotados), o carimbo daqui precisa mudar, e
  provavelmente o `/meta:adopt` também, para que ele escreva `standalone` quando for o caso;
- se é **adopted**, a entrada do `members.yaml` precisa mudar.

Na co-evolução os dois papéis se comportam igual, e por isso o efeito hoje é baixo. O problema é a
classe: registro e carimbo podem divergir sem nenhum gate avisar. Fica a sugestão de estender a paridade
da REGRA 92 a adotantes que vivem na mesma máquina (`local_path`).

## Fechamento do relatório de adoção (para o core não reabrir)

O relatório `2026-10-06-adopt-fe8359e38b43.md` levantou três pontos. Conferi os três contra o vivo do core:
1. Defeito da crase no heredoc do `seed-adoption-graph.sh`: **corrigido** em `8397810b` (`bash -n` ok).
2. Repo fora do `members.yaml`: **registrado** em `8397810b`, e é dessa entrada que nasce este sinal.
3. `door-staleness-baseline.txt` com emissor saindo não-zero: **é o comportamento declarado**. O lint
   daqui classifica como `[papel/SEM-OBJETO]`, porque o papel `adopted` não recebe o objeto da guarda.
   Não é defeito, e nada é pedido.
