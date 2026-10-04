---
reviewed_diff_sha256: f9fc0ace5813d4b242973dadac11674dd197c16edb91516907c04dbb230de999
findings_total: 14
findings_real: 14
tokens: 165782
duration_min: 20
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Refutador opus/high em worktree isolada, mandato REFUTAR: 165.782 tokens, 72 chamadas, ~20 min.
  Placar dele: 3 aprovados, 5 reprovados, 1 não-verificado. O núcleo da reprovação: o raio-X
  publicava NÚMEROS FALSOS COM CARA DE CERTOS — exatamente o risco que o mandato nomeava. Todos os
  14 achados curados, e a bancada achou um 15º que nenhum de nós viu (a lista do não-medido morria
  no subshell do `$( )`). Pós-cura: 9 casos, 9 mutantes mordendo — incluindo o M7, que tinha
  SOBREVIVIDO ao Elenxo. O selo do nó do anúncio, também nesta branch, foi aprovado por ele
  contra origin/main (5.496 bytes, 4 sítios, 9/9).
---

# Resíduo — `chore/seal-announce-and-reforge-evolve`

## O núcleo: número falso com cara de certo

O mandato pedia atenção especial a *"número errado com cara de certo — um raio-X que transcreve
mal um medidor é pior que nenhum, porque empresta autoridade ao número falso"*. Foi exatamente o
que ele achou:

| número publicado | o real | a causa |
|---|---|---|
| **1 dissecação vencida** | **0** | `grep -ci vencido` casava a **legenda** do dissect-census. E o número falso **já estava num nó de grafo** |
| **✅ auto-auditoria fresca** (medidor quebrado) | **não medida** | contagem de sinais = zero sobre saída vazia — **verde falso** |
| **14 doutrinas carregadas** | **4** | somava linhas `NUNCA` e 6 sondas já apagadas |
| **15 ou 16 guardas** (variava) | **16** | corrida de EPIPE no `guard-census`, que o raio-X herdava |

## Os demais

- Medidor com rc **1 ou 2 virava zero** (só `>=3` era tratado como falha).
- O `--tsv` **não tinha lista do não-medido** — tudo que falhava saía 0.
- O passivo de guardas era **filtrado para fora**: o `grep` pegava só as linhas que começavam com `(`, que são justamente o caso feliz.
- O **Passo 0.5 prometia** que o raio-X apontava alvos; ele só **contava**. Curado do jeito certo: a seção 7 passou a **nomear**, em vez de a promessa ser apagada.
- A injeção dependia de **`date`, fora do `allowed-tools`** — só rodou porque a sessão estava em bypass. Removida: o cabeçalho do raio-X já traz a data.
- O tempo publicado (~5s, "1-2s cada") era otimista: **~6-9s medidos**, forge-census a 5,4s sob carga.
- O caso `(d)` da bancada se chamava *"nunca zero"* e **não afirmava zero nenhum**: o mutante que fazia `NAO-MEDIDO` emitir 0 sobrevivia.
- Inseri a família da bancada **no meio do comentário** da família vizinha.

## O 15º, que a bancada viu e nenhum dos dois

A lista do não-medido era uma **variável acumulada dentro de `$( )`** — e uma variável num
subshell **morre quando ele sai**. Os números saíam `?` corretamente, mas o *porquê* sumia para
**cinco das sete dimensões**. É a armadilha clássica de shell, e ela anulava exatamente a
propriedade que o Elenxo tinha exigido. Agora a lista vive em arquivo.

## Um defeito meu de operação, que custou 3 HARD

Interrompi o commit em voo com `TaskStop` no meio da bancada (para não pagar 24 min de gate
por uma versão reprovada) — e isso **deixou duas fixtures órfãs** (`__scrubtest__`, `__mbguard__`)
na árvore viva, que geraram 3 HARD sem relação com o diff. Conferidas como não-rastreadas,
criadas pela bancada, com `mtime` batendo com a interrupção, e removidas. **Interromper bancada
no meio tem custo de limpeza** — fica registrado.

## O que fica declarado em vez de resolvido

- **A peça 4 (workflow em arquivo)** segue ausente, com gatilho: a próxima rodada real do evolve.
- **O "aterrissou"** segue não-medido — o raio-X mede só "carregou", e diz isso na própria saída.
- **Não verificado**: se a injeção executa sem bypass agora que o `date` saiu (o comando
  restante, `bash .claude/validation/*`, está no `allowed-tools`).
