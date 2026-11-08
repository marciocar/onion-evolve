---
branch: chore/permissions-deny-minimal
pr: 1552
date: 2026-11-08
reviewed_diff_sha256: pendente
findings_total: 15
findings_real: 15
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 11
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
- **R4 (curado).** A bancada falhava aberta: sem resultado medido dava ok. Agora a linha é NÃO MEDIDO e o rc é 3; com
  um `claude` falso, mutantes e flows não dão verde.
- **R5 (curado).** O `(p1)` só via caminho `//` e o corpo do PR afirmava mais que isso. Agora julga a forma por lista
  fechada (`Read` só `.env` em `//**/` ou dotfile do home; `Bash` sem `palavra/palavra`). Nome de cliente é da REGRA 119
  (O diff não acrescenta nome de repo ou de clone de adotante não federado); o corpo diz isso.
- **R6 (declarado).** Os 10 flows provam só que o deny não barra a chamada.
- **R7 (medido em parte).** Em fixture com sandbox: `.ssh` e `.aws` somem, `ssh -i` avisa chave inacessível, gpg falha
  com e sem o deny. Push por ssh de ponta a ponta não foi medido; declarado.
- **R8 (curado).** O `--diff` nomeia cada regra nova e os `allow` que ela anula. É comparação de texto: allow com
  curinga que só em parte se sobrepõe não aparece.
- **R9 (curado).** `permissions.deny` fora da forma de lista: rc 0, hooks chegam, deny não soma, stderr avisa.

## O que esta passada não viu

O sandbox no core real, o login real, e a re-revisão independente das curas.
