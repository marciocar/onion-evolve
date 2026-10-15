---
branch: fix/selftest-family-registry
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
tokens: 160206
duration_min: 17
findings_fixed: 6
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose (opus), mandato de refutar
nota: "Refutador sem bloqueador; 2 maiores e 4 menores curados com caso e mutante; o achado 5 (rótulos e conflictStyle da volta ao merge padrão) fica declarado e não curado."
---

# Passada adversarial: `fix/selftest-family-registry`

## O que muda

SAC-146. A bancada `.claude/validation/lint-selftest.sh` ganha um merge driver próprio,
`ops/merge-drivers/selftest-families.py`. O `.gitattributes` o liga ao arquivo
(`merge=onion-selftest-families`), e o `ops/pr-finalize.sh --rebase` passa a config dele por `git -c`,
no rebase e em cada `--continue`. Nada persiste na config do repo.

O driver é tudo-ou-nada. Ele só resolve se TODOS os conflitos do arquivo cumprirem estas condições:
- a base é vazia;
- o ponto fica na região de famílias, no topo, logo depois de uma invocação `_family`;
- cada lado é um bloco inteiro, que termina em `_family` e passa sozinho no `bash -n`;
- nenhum nome de topo se repete;
- o resultado passa no `bash -n`.

Em qualquer outro caso ele devolve o merge de texto padrão, com marcadores, e sai ≠ 0.

O `ops/pr-merge-verified.sh` passa a reconhecer a resolução. Põe a causa no rastro do PR e, quando o
pr-finalize para no carimbo, diz "rebaseado só na worktree, NÃO enviado, re-revise". Antes dizia
"conflito de FONTE / nada mudou".

A família nova `selftest_family_merge` tem 12 casos. O grafo novo é
`docs/evolution/research/selftest-family-merge-2026-10/`.

Opções pesadas antes da escolha:
- **`merge=union`**: descartado. O caso (c) prova a perda calada: duas edições da mesma linha viram
  duas atribuições.
- **Família por arquivo**: adiada, porque teria de ensinar o diretório a pelo menos 5 leitores
  estáticos. Fica a pergunta `Q_FAMILIA_POR_ARQUIVO`.
- **Convenção de lugar**: descartada, porque não é mecanismo.

## Achados

1. **MAIOR, curado.** A bancada não mordia a remoção do cheque "o lado termina numa invocação
   `_family`" (o mutante do refutador dava 10/10 verde). Cura: caso (i), acréscimo de topo que não é
   família, onde esse cheque é o único que rejeita. Agora o mutante morde.
2. **MAIOR, curado.** No auto-rebase, a resolução do driver virava "conflito de FONTE… nada mudou na
   branch", o que é falso: a branch fica rebaseada localmente e não é enviada. Cura: o
   `pr-merge-verified.sh` lê a linha `conflito de famílias acrescentadas lado a lado resolvido em`,
   põe isso na causa e para com uma mensagem verdadeira. A ligação é conferida no caso (g), e um
   mutante dela morde.
3. **Menor, curado.** Um driver configurado que não consegue rodar (sem python3) deixava o arquivo do
   lado HEAD sem marcadores. Cura: o pr-finalize só passa a config com o python3 presente, o caminho
   vai entre aspas simples e o cabeçalho do driver avisa.
4. **Menor, curado.** O motivo de não resolver se perdia antes do `die "conflito REAL"`. Cura: as
   linhas `SELFTEST-FAMILIES:` saem no stderr antes do abort.
5. **Menor, declarado e NÃO curado.** A volta ao merge padrão usa os rótulos `HEAD`/`reaplicado` e
   ignora `merge.conflictStyle` e `-X ours/theirs`. Nada que leia `^<<<<<<<` quebra.
6. **Menor, curado.** Os repos de fixture não se isolavam da config global. Agora usam
   `-c commit.gpgsign=false -c core.hooksPath=/dev/null`.
7. **Menor, curado.** O grafo dizia "não há outra lista a editar". Corrigido: a lista
   `SELFTEST_CORE_ONLY_FAMILIES` fica nomeada, com a medição do refutador (9 commits contra 119), e o
   comportamento tudo-ou-nada fica dito.

Também: o caso (j) cobre a mistura de um conflito bom com um ruim. O refutador tinha provado esse
caso à mão, e ele não tinha caso na bancada.

## Mutantes

Onze mutantes, todos por `ops/mutate-and-restore.sh`, todos mordendo:
- **m1**: base vazia → (b).
- **m2**: região → (e).
- **m3**: colisão de nome → (d).
- **m4**: ponto no topo → (f).
- **m5**: `--continue` sem a config → (g).
- **m6**: descarta o lado HEAD → (a) e (d).
- **m7**: merge limpo sem escrever → (h).
- **m8**: `.gitattributes` sem a linha → 7 casos.
- **m9**: o cheque "termina em `_family`", que é o mutante do refutador → (i).
- **m10**: base não vazia resolvida pelo lado HEAD → (b), (c) e (j).
- **m11**: o merge verificado sem ler a resolução → (g).

## Limites declarados

- **Re-revisão continua.** O hash de código (patch-id sobre `-U3`) muda pelo contexto quando o driver
  resolve; medido: 8e35… → 141e…, com as linhas `-U0` idênticas. Uma colisão resolvida pelo driver
  ainda pede re-revisão (`reviewed_diff_sha256: pendente`). O que some é a resolução à mão e a recusa
  do conflito. Pergunta aberta: `Q_REREVISAO_SO_PELO_CONTEXTO`.
- **Prova real limitada.** Duas branches de fixture sobre o `lint-selftest.sh` real e o replay dos
  três blocos reais (#1133–#1135) rebasearam limpos com a config que o pr-finalize passa. O
  `pr-finalize --rebase` de ponta a ponta NÃO foi rodado, porque exige o forge.
- **Seleção da bancada.** Mudar `ops/pr-merge-verified.sh` não seleciona esta família: a anotação
  `selftest-covers` expandia o mapa para o repo inteiro. Ele é coberto pela bancada completa no push
  ao main.
- **`--list` e `--map` contra a main.** `--list` difere só pela linha `selftest_family_merge`. `--map`
  difere só pelas 8 linhas da família nova e pelas linhas que o grafo novo acrescenta às famílias de
  corpus. O stderr dos dois é idêntico.
