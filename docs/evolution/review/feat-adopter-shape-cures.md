---
branch: feat/adopter-shape-cures
pr: 1159
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 13
findings_real: 10
tokens: 177543
duration_min: 16
findings_fixed: 10
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose opus em worktree isolada (mandato de refutar, foco no veto do .env)
nota: "10, 11 e 13 são notas sem defeito; o 12 (catraca da REGRA 100 suspensa nesta rodada pelo escopo novo) foi conferido à mão: 30 citações, 30 entradas, o baseline só encolheu"
---

# Passada adversarial: `feat/adopter-shape-cures`

## O que muda

Este é o PR 2 de 2 da SAC-149, com as curas guiadas pela medição da família `adopter_shape`.

- **Aplicabilidade por papel.** A regra declara `# aplica-se:` no docstring. Fora dos papéis declarados ela
  não roda e sai como `NÃO SE APLICA`, fora de HARD e SOFT. As REGRAS 85 e 92 declaram `source`. O
  rules-registry valida a declaração e a projeta.
- **REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse) nas mensagens.** Ela
  agora julga também o ops/ que uma `violation` imprime.
- **Pin com escritor único.** O `write-stamp.sh` chama `utils/kg/stamp-adoption-graph-pin.sh`, e a REGRA 108
  (Pin do grafo de adoção concorda com o carimbo) cobra que os dois concordem.
- **Pontuais.**
  - A semente v2 passa a ser migrada.
  - O veto do .env deixa de julgar o padrão do grep como arquivo.
  - A semente e o githook marcam o ops/ como (core-only).
  - O materializador ganha `--from WORKTREE`.

As catracas da família ficam zeradas.

## Achados

O refutador rodou sobre 27f09cd0, com o hook chamado por JSON de PreToolUse contra um .env sintético e a
base 48a94d7d como controle. Achou 13 itens.

1. **BLOQUEADOR — TOCTOU no scratchpad.** `cp .env $S/x.env; cat $S/x.env` saía rc 0. **Curado:** a isenção
   do scratchpad saiu. O falso positivo original segue vetado (teto declarado), e a mensagem do veto passa a
   pedir outra extensão.
2. **BLOQUEADOR — "cara de segredo" fraca.** Os testes deixavam passar `DB_PW=…` e URL com credencial.
   **Curado** junto com o 1: a isenção por conteúdo saiu.
3. **BLOQUEADOR — abreviação de opção longa do GNU grep.** `grep --reg=. .env` saía rc 0, e o rg aceitava
   config com `--regexp`. **Curado:**
   - toda opção longa que é prefixo de `--regexp` ou `--file` devolve o veto;
   - o rg saiu da isenção;
   - uma variável `GREP_*` no segmento devolve o veto.
4. **`# aplica-se:` lido em lugares diferentes pelo lint e pelo registry.** **Curado:**
   - o lint só lê a linha no docstring;
   - o registry recusa um 2º `# aplica-se:`;
   - a REGRA 100 também só lê o docstring.
5. **O escritor do pin trocava só o hash do label.** **Curado:** o label e o `verified_against` do dono ficam
   intactos, e só o `x_pin` é gravado (rc 3).
6. **A REGRA 108 errava com pin de 7 hex e com id entre aspas.** **Curado:** a comparação usa o menor
   comprimento, e o id entre aspas é aceito.
7. **O promote-hub sujava o grafo.** **Curado:** o escritor ficou idempotente; com o mesmo pin, nada muda.
8. **`--from WORKTREE` falhava com caminho relativo.** **Curado** com `--path-format=absolute`.
9. **`dd if=.env` lia o .env sem veto.** A falha é anterior ao diff. **Curado:** o `if=` é lido do segmento.
10. A migração v2 não alterou dados, e recusa as sementes editadas sem provenance. Nota.
11. As REGRAS 85 e 92 continuam rodando no core. Nota.
12. A catraca da REGRA 100 ficou suspensa nesta rodada pelo escopo novo. Foi conferida à mão. Nota.
13. Os consumidores do write-stamp não quebram. Nota.

Além disso, a REGRA 108, rodada em `--check` contra 17 adotantes locais, deu 3 divergências reais e nenhum
falso positivo.

## Mutantes

Foram 16, plantados pelo `ops/mutate-and-restore.sh` com `LC_ALL=C`, e todos mordem. Os que vivem DENTRO
da fixture rodaram com `ONION_ADOPTER_FROM=WORKTREE`.

| Mutante | Caso que pegou |
|---|---|
| `_rule_na_here` sempre aplica | (c), (g) |
| padrão do grep não sai da lista | (r) |
| isenção do scratchpad (antes de sair) | (r) |
| teste de segredo (antes de sair) | (r) |
| abreviação de opção longa | (r) |
| `dd if=` | (r) |
| semente v2 | (v2), (v2b) |
| escritor do pin no write-stamp | (i) |
| REGRA 108 rebaixada | (i2) |
| ops/ na semente | (h) |
| registro sem source | (ap) |
| registro repetido | (ap) |
| label do semeador | (i3) |
| idempotência | (i3) |
| mensagem da REGRA 100 | (xviii) |
| source-only da REGRA 100 | (xix) |

O dogfood dos mutantes pegou três defeitos da própria família, curados no laço:
- o SUT dentro da fixture vinha do índice, então o mutante não chegava até ele;
- a chamada direta do helper mascarava o escritor;
- o (i2) aceitava QUALQUER HARD.

## Limites declarados

- O `*.env` de trabalho do scratchpad segue vetado.
- O githook impresso 3 vezes não foi reproduzido. Está registrado como pergunta com gatilho.
- O `tm.sh comment.add` aceitou `--body-file` como TEXTO. Fica como achado aberto: o adapter não tem
  `comment.delete`.
- Só o papel adopted é medido.
- O lint só lê `# aplica-se:` no docstring. Não há caso de bancada para a linha posta dentro da função: o
  registry a recusa, mas a recusa do lado do lint não está coberta.

## Re-revisão (rebase sobre a main depois do merge do #1156)

O #1156 entrou na main, e o merge-serial recusou o auto-rebase deste PR: havia conflito no resíduo do #1156,
que este PR empilhado também carregava. Rebaseei só os commits deste PR sobre `origin/main` (rebase --onto).
O resíduo do #1156 fica como está na main, e este PR leva apenas o próprio. Os conflitos de projeção
(`docs/backlog.md`, `docs/onion/testing-inventory.md`) foram resolvidos pelo lado da main e regenerados pelo
`pr-finalize`. O código do PR 2 não mudou no rebase. A re-revisão foi feita por mim, não pelo refutador:
re-rodei as famílias afetadas com `LC_ALL=C`.
