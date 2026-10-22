---
branch: fix/a2a-accept-to-channel-selftest
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: dc13b273812141b23f02fd9cae83b17e8bd03b97349c6e0decf32dee569080fa
reviewed_code_sha256: 6d6a03fc15f89b1d4573aedc8e75debf3a2fbf039f3c5b1016c6f4eb5ed12eca
findings_total: 11
findings_real: 4
tokens: 172218
duration_min: 5
findings_fixed: 3
verdict: CORRIGIDO
elenxo: sim
reviewer: code-reviewer (subagente refutador, 2 passadas, harness próprio em sandbox)
nota: >-
  A 1ª passada derrubou o 1º desenho da cura: ele fazia o selftest passar fundindo as duas raízes de
  confiança numa só, a raiz servida, que é da conta onion, o mesmo UID que escreve a fila. O desenho
  final mantém as duas raízes, e um caso novo com mutante prova a diferença. tokens = soma das 2
  passadas do refutador.
---

# Passada adversarial: `fix/a2a-accept-to-channel-selftest`

## O que muda

- O `vps/accept-to-channel.selftest.sh` dava 9/12 na `origin/main`. Agora dá **13/13**, porque ganhou
  um caso, o das duas raízes. Eram duas causas:
  1. O registro sintético não tinha `receivedAt`, que o `a2a-accept.sh` passou a exigir em e97fe410.
  2. A reverificação do `a2a-accept` lia a raiz de confiança do checkout, que no selftest não tem a
     chave descartável.
- O `accept-to-channel.sh` passa ao `a2a-accept` a flag que ele já tem e que a bancada usa
  (`run_a2a_accept_selftests`): `--trust-repo`.
  - O valor é `A2A_SPIKE_ACCEPT_TRUST_REPO`, e o default é o **checkout**, ou seja, o comportamento de
    produção de antes. Quando há override, ele deixa uma linha `ACC-TRUST-OVERRIDE` no `accept.tsv`.
  - O script também passa `--receiver onion-evolve`, de forma explícita.
  - O razão de aceites vai para o estado do spike (`--ledger`).
- O P3b da §12.11 passa a dizer 13/13.

## Achados

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | O 1º desenho (um trust-repo montado com os MESMOS bytes da raiz servida) tirava a independência da reverificação. Um UID do bridge comprometido, com a chave plantada no clone servido e um registro forjado, passaria. O refutador provou com o script antigo contra o selftest novo: 9/12, porque o gate recusava | importante | curado: as duas raízes têm de concordar, e a 2ª tem o checkout como default. Caso e mutante M2 |
| 2 | Falha de `cp`/`mkdir` sob `set -e` dava rc 1 sem mensagem | menor | dissolvido: o desenho final não copia nada |
| 3 | O override da 2ª raiz deixava aviso só no stderr | menor | curado: linha `ACC-TRUST-OVERRIDE` no `accept.tsv`, asserida no selftest. Mutante M4 |
| 4 | O `case` do KID aceita `.x` e caracteres fora de `[A-Za-z0-9._-]` | menor (anterior ao PR) | declarado. O `a2a-verify` veta a jusante. Não mexi |
| 5 | O `refuse` do `a2a-accept` devolve rc 1 em falha de ferramenta | menor (anterior ao PR, motor do core) | declarado. Não mexi |
| 6–11 | O trust-repo mínimo tem tudo o que é lido. O ledger novo não perde dedupe relevante, e com o ledger no checkout um aceite do spike suprimiria o doc no inbox do core (`a2a-accept.sh`, rc 0 "já aceito"). O `receivedAt` e o members.yaml do selftest são coerentes. A env nova não cria fronteira nova, porque mora no ambiente do maestro, como `A2A_SPIKE_JWKS`/`MEMBERS` | confirmação | — |

## Mutantes

Os quatro rodaram contra o selftest final:

| mutante | o que faz | resultado |
|---|---|---|
| M1 | tira o `--trust-repo` | 10/13 (`trust-denied`) |
| M2 | volta à raiz única, o 1º desenho | 10/13: cai o caso "chave só na raiz servida" (rc 0 quando devia ser 1) |
| M3 | tira o `receivedAt` do fixture, ou seja, o defeito original | 10/13 |
| M4 | tira o rastro do override | 12/13 |

Restaurado: 13/13.

## Limites declarados

- **NÃO MEDIDO em produção:**
  - O aceite real na VPS, com a raiz servida lida por `sudo -n` e o checkout `~/onion-evolve` como 2ª
    raiz.
  - Se os dois `members.yaml`/JWKS estão hoje em sincronia. Se divergirem, o aceite recusa, e isso é
    o comportamento desejado.
- Nenhuma bancada do CI roda este selftest, e foi por isso que ele apodreceu sem ninguém ver. Ligá-lo a
  uma família do `lint-selftest` fica fora deste PR.
- Não toquei motor do core (`.claude/utils/federation-transport/`), `fetch-replies.sh`, a 12.14,
  trust-log nem `a2a-verify`.
