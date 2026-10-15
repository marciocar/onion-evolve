---
branch: feat/a2a-invite-live-wrapper
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 12
tokens: 158618
duration_min: 8
findings_fixed: 9
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "subagente general-purpose (opus), mandato REFUTAR"
nota: "3 ALTA + 4 MÉDIA + 5 BAIXA medidos; 9 curados na branch com caso, 3 declarados como teto (xargs -I, python -c, motor renomeado sem marcador) e 1 pré-existente sem cura (trava em /tmp sob protected_regular)"
---

# Passada adversarial: `feat/a2a-invite-live-wrapper`

## O que muda

O wrapper core-only `ops/a2a-invite-live.sh` passa a ser o único caminho de escrita no arquivo de convites A2A do bridge de produção. Ele roda o motor do clone servido como a conta do serviço, com trava, ensaio por padrão, backup cifrado, check, prova por contagem e rollback impresso.

O juiz do MOAT (`moat-judge.py`) passou a julgar como escrita os argumentos do motor de convites (`--file`, `--invite-out`, `--token-out`). A linha nova do `ops/moat-targets.tsv` nomeia o wrapper.

Bancada: casos (i1)–(i16) em `moat_gate` e a família nova `a2a_invite_live`, com (w1)–(w13).

## Achados

1. **ALTA, curado.** Com `--file` repetido, o juiz lia só o primeiro e o motor usa o último. Agora toda ocorrência é julgada. Caso (i11).
2. **ALTA, curado.** Um symlink para o motor servido passava, porque o reconhecimento era pelo nome do link. Agora o juiz reconhece também pelo realpath e pelo link criado na própria string. Caso (i12).
3. **ALTA, curado.** `revoke --receiver` era dado como falha e o rollback impresso desfazia a revogação: a contagem não filtrava o receptor. Agora filtra. Caso (w12).
4. **MÉDIA, curado.** `--invite-out` e `--token-out` do motor escreviam no caminho servido sem julgamento. Agora entram na spec e no marcador. Caso (i13).
5. **MÉDIA, curado.** O modo de teste lavava um script não versionado através do wrapper. Agora `ONION_A2A_LIVE_TEST` na linha de comando fecha, inclusive por `export` e por atribuição. Caso (i14).
6. **MÉDIA, curado.** Uma cópia mutada do wrapper herdava a fronteira do original, e uma cópia em /tmp chamaria `sudo <dir>/bridge-backup.sh`.
   - No juiz, a cópia é julgada pelo corpo. Caso (i15).
   - No wrapper, a produção exige que ele e o backup estejam rastreados e limpos. Caso (w13).
   - Pré-existente, sem cura: um arquivo versionado sujo continua valendo como fronteira.
7. **MÉDIA, curado.** O mutante do (w5) abria a trava real de produção. Agora as cópias da bancada trocam `PROD_LOCK` por um arquivo do sandbox, e o (w5) confere a mensagem.
8. **BAIXA, curado.** Falso positivo em script só de leitura que cita o motor num comentário. Agora o juiz exige o nome do motor fora de comentário, mais `create`/`revoke`, mais o sinal do alvo. Caso (i16).
9. **BAIXA, parcial.** `bash -s … < motor` foi curado (o `-s` deixa de tratar argumentos como script). `xargs -I` e `python3 -c` seguem como teto declarado; o segundo é classe pré-existente.
10. **BAIXA, curado.** A conferência de inode na reabertura do fd 3 era código morto e saiu. Os casos que faltavam ganharam bancada: receptor, `--file` duplicado, symlink e `--invite-out`.
11. **BAIXA, pré-existente.** A trava em /tmp está sujeita a `protected_regular=2`. Não foi curada porque a trava é a mesma do `update-bridge.sh`.
12. **BAIXA, curado (suspeito).** O rollback com `mv` podia trocar o arquivo por um vazio se o tar falhasse. Agora o `mv` só roda depois de `[ -s ]` e `json.load`.

## Mutantes

Cada caso novo tem mutante executado na bancada (`_prove_mutation`). Com `LC_ALL=C bash .claude/validation/lint-selftest.sh --families=moat_gate,a2a_invite_live`: 167 passaram, 0 falharam, 0 pulados.

Mutantes plantados com `ops/mutate-and-restore.sh` (core-only) no juiz real, julgando o comando de campo:

| mutante | comando de campo | rc |
|---|---|---|
| M1: `_moat_arg_writer` em `_moat_script` | motor do clone servido por `bash`, `--file` no arquivo de convites | 2 → 0 |
| M2: ramo de execução por caminho | idem | 2 → 0 |
| M3: corpo de script não versionado | cópia do wrapper | 2 → 0 |
| M4: todas as ocorrências | `--file` duplicado | 2 → 0 |
| M5: busca dos argumentos | symlink | 2 → 0 |
| M6: veto do modo de teste | `export` | 2 → 0 |

Restauração conferida: `grep -c ONION_MUTANTE` = 0.

## Limites declarados

- **NÃO MEDIDO:** a escrita no arquivo de produção. Fica para a prova viva da sessão principal, depois do merge.
- **NÃO MEDIDO:** o backup real via `sudo bridge-backup.sh` dentro do wrapper. Na bancada o backup é stub.
- Teto do juiz: motor renomeado sem o marcador, `xargs -I` e `python3 -c` chamando o motor.
- O `count` usa o `list --json` do motor. Se o arquivo estiver num estado não-ok antes da escrita, o wrapper recusa com rc 2.
