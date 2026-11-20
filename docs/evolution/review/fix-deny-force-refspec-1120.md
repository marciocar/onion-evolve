---
branch: fix/deny-force-refspec-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: 20ede220b4b024d4e29b60d54fa8d8bda8fd142d7c70cf203e15ac8873e7a966
reviewed_code_sha256: d31d67bba43f429b9e6717237df4dfb04a5616d7bf58d617f6669ab4dee37ce5
findings_total: 8
findings_real: 8
findings_blocking: 2
tokens: 197000
duration_min: 9
findings_fixed: 3
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, com mandato de refutar e medição no motor real do Claude Code 2.1.329, no git real e no hook com e sem python3. A 1ª passada (head d73d8d2b5) deu REJECTED com 2 achados bloqueantes. A 2ª passada (head 4762090a3) deu APPROVED."
nota: "tokens = soma das duas passadas pelo harness (91.943 + 104.939); duration_min = 6,4 + 2,6 min. Achados 3, 5 e 6 da 1ª passada e os 2 da 2ª são tetos declarados, não código."
---

# Passada adversarial: `fix/deny-force-refspec-1120`

## O que muda

O achado vem da sessão messaging (19/11), sobre a lista de comandos proibidos. Os dois defeitos foram provados no motor real
(`ops/testing/permissions-deny-bench.py`, Claude Code 2.1.329, com o settings de `origin/main`):

- **(a)** `git push origin +main`, `+HEAD:main`, `+refs/heads/x:refs/heads/y`, `git -C . push +feat/x` e `'+main'`
  saíam `approval`, e não `deny`. O refspec com `+` força o push sem flag. O hook `pretooluse-protect-main.sh` já vetava o
  caso da main (a lib converte `+ref` em `--force`); o buraco era o deny, que barra force em qualquer branch.
- **(b)** `git clean -n -x`, `--dry-run -x`, `-n -fdx`, `-f -n -x` e `git -C . clean -n -x` caíam no `deny`, porque o `*` do
  meio de `git clean* -x*` casa o `-n`.

A cura:

- No deny entram `git push* +*`, `git -* push +*` e `git -* push * +*`.
- As 16 regras do clean com `*` no meio foram aposentadas em `deny-retired.tsv`. O adotante as perde no `--update`, e o
  `deny-monotonic.sh` nomeia a retirada sem reprovar. No lugar delas entra o grupo destrutivo como 1º argumento
  (`git clean -fdx*`).
- A ordem livre (`-f -d -x`, `-e keep -fdx`) passou ao hook, que julga por token e deixa passar `-n` e `--dry-run`. O glob
  não tem negação, então o deny sozinho não sabe dizer "exceto `-n`".

## Bancada

- **Motor real.** 209 casos e 0 divergentes (antes: 19 divergentes nos casos novos). Na fase bypass, 153 casos e 0
  divergentes. Os 75 mutantes por regra morrem todos, nenhum decorativo.
- **`lint-selftest.sh`, família `pretooluse_veto`.** Casos cl1 a cl5 com mutante, np-pm-clean e np-pm-clean-cmt com mutante,
  e mais dez casos de modo de falha.
- **`lint-selftest.sh`, família `update_base_and_deny`.** O fr1 roda a emulação do glob sobre o deny real, com dois
  mutantes. O fr2 roda o merge no adotante, com mutante na lista de aposentadas. O fr3 roda o `deny-monotonic`.

## Achados do revisor

1ª passada (head d73d8d2b5), REJECTED:

1. **Bloqueante, curado.** `git clean --exc -n -f -x` apagava o `.env` sem deny nem hook, porque o git toma o `-n` como padrão
   do `--exclude` abreviado. O juiz passou a reconhecer a longa abreviada (cl5).
2. **Bloqueante, curado por declaração e bancada.** `git push … | tail -n +2` cai em `git push* +*`, porque o motor julga o
   pipe inteiro. Fica como custo, com saída na doutrina (`| tail -n 2`) e caso C13. A emulação do fr1 partia no `|` e
   divergia do motor; deixou de partir.
3. **Menor, declarado.** `eval "git clean -fdx"` não é visto pelo hook, porque a lib só marca inanalisável o que cita push ou merge.
4. **Menor, curado.** Sem python3, o `clean` de um comentário roubava o lugar do verbo. O corte agora pega o 1º `clean`
   depois do `git`.
5. **Menor, declarado.** `-xn` e `-fdxn` seguem barrados pelo deny (C14).
6. **Menor, declarado.** O veto de clean vale em qualquer pasta, como o deny. O np-pm-clean ganhou mutante.

2ª passada (head 4762090a3), APPROVED, com dois achados menores declarados aqui:

7. Sem python3, `git -C clean status -x` é vetado, porque o awk toma o valor do `-C` como verbo. O modo sem python fecha
   por desenho.
8. A emulação parte no `||`, e nenhum caso do motor mede isso.

## O que esta passada não viu

A passada não viu adotante real com `--update`: o merge e o monotonic foram medidos em fixture. Também não viu a
fase sandbox da bancada do motor, nem `git clean -i`, que é interativo e o hook veta sem `-n`.
