---
branch: chore/permissions-deny-minimal
pr: 1552
date: 2026-11-08
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 10
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 8
verdict: FIXED
elenxo: true
reviewer: refutador independente sobre o head 4f6429476, chamado pela sessão do core, mais a passada do autor com os mutantes por regra no motor real; as curas do refutador foram medidas pelo autor, sem nova passada independente
nota: "tokens e duração não medidos (0). B2 não é cura de código: é custo aceito pelo core em nome do maestro, revogável, declarado na doutrina e no nó de decisão."
---

# Passada adversarial: `chore/permissions-deny-minimal`

## O que muda

64 regras de `permissions.deny` em `.claude/settings.json`, a soma do deny da fonte no `merge-onion-hooks.sh`, a seção
da camada nativa na doutrina de guardas, a bancada no motor real (`ops/testing/permissions-deny-bench.py`) e o grafo
`docs/evolution/research/permissions-deny-minimal-2026-11/`.

## Achados do autor

1. **Regras decorativas (curado).** O mutante por regra mostrou 11 regras que nenhum caso exigia. Dez ganharam caso;
   a do `$HOME` entre aspas saiu, porque o motor já a barra pela regra sem aspas.
2. **Regra Read com alcance maior que o previsto (curado na lista).** O motor leva a regra Read a `ls` e `stat`, e o
   censo mostrou `ls` e `find` em `~/.password-store` no fluxo real. Essa pasta saiu da lista: o conteúdo já é cifrado.
   `ls .env` fica como custo declarado, com `test -f` de saída.
3. **Bancada sem o allow real (curado).** Os casos rodavam sem o `allow` do core, que libera `Read`. Passaram a rodar
   com ele, e o deny seguiu vencendo.
4. **Falso positivo (declarado).** Parte saiu com a forma nova das regras; o que resta está no achado R3.

## Achados do refutador (head 4f6429476)

- **B1, bloqueante (curado).** `Bash(git clean -*x*)` atravessava espaços e barrava `--exclude=keep`, `-e '*.txt'` e
  caminho com `x`, e deixava passar `-fdX`, que apaga `.env` ignorado. Virou grupos explícitos (`-x`, `-fx`, `-fdx`,
  `-dfx`, `-dx`, e os cinco com `-X`), nus e com `git -*`, com caso e mutante para cada regra.
- **B2, bloqueante (custo aceito).** As regras `Read` do `.env` também barram `Write` e `Edit`, inclusive arquivo novo.
  Aceito pelo core em nome do maestro, revogável. Casos W01 a W04 e W10 na bancada, declarado na doutrina e no nó.
- **R1 (curado).** `git push -fu`, `-uf`, `-vf`, `-qf` passaram a cair. `git -C . push origin x -uf` (no fim, com
  `-C`) fica declarado.
- **R2 (curado).** A doutrina dizia que `grep` e `rg` são alcançados; só quando o arquivo é nomeado. `grep -rn` passa e
  devolve o `.env`.
- **R3 (reduzido e declarado).** Saíram os casos de `branch push-tmp -f`, `tag push-1 -f`, `fetch origin push-x -f`,
  `log -- push.sh -f`, `checkout … --force` e `gh release delete-asset`. Restam a menção em `git -C . commit -m` e
  `rm -f my-report /`, declaradas como custo.
- **R4 (curado).** A bancada falhava aberta: sem resultado medido dava ok. Agora é reprovação; com um `claude` falso,
  mutantes e flows saem rc 1.

## O que esta passada não viu

O sandbox no core real, o login real, e a re-revisão independente das curas. F04, F05 e F09 pararam em recusa do
próprio script no fixture: provam que o deny não barra a chamada, não que o fluxo foi até o fim.
