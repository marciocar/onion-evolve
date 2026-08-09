---
branch: docs/medicao-guarda-idioma
date: 2026-08-09
reviewed_diff_sha256: d86a4e94cc5af50ed7a95a180798421711d6f0adecd7a4a6508e71bb32e70d44
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-DIFF-DE-UMA-LINHA-SEM-CODIGO-A-MEDICAO-E-QUE-E-O-CONTEUDO
reviewer: sem passada adversarial — justificativa medida abaixo
---

# Resíduo de um diff de uma linha

**Uma linha, zero código** (`git diff -- '*.sh'` devolve **0**). O conteúdo do PR é uma **medição**
escrita num rótulo de nó — não há superfície executável para um refutador atacar.

## Por que não houve passada adversarial

A REGRA 56 exige resíduo em todo PR aberto, e ela está certa em não abrir exceção por tamanho: foi
justamente num PR "pequeno" que a casa aprendeu que o soft-pass do revisor não substitui a passada.
Mas o que um Elenxo audita é **comportamento**, e aqui não há comportamento novo.

O que substitui, e é o próprio conteúdo do PR: **a medição foi feita antes de decidir o desenho**, e
os números estão no nó, cada um ao lado da escolha que justifica.

| medido | número |
|---|---|
| identificadores distintos varridos | 636 |
| casam por **palavra inteira** | **3** → cobertura baixa demais |
| casam por **segmento**, contra 59 palavras sem homógrafo | pega **10 de 12** históricos |
| falsos nos substitutos em inglês | **0** |
| resíduo pré-existente no repo | **3** (`alvoPendente`, `atencao`, `vazio`) |

## O que o próximo ciclo herda

A decisão de desenho já está tomada **por medição**, não por gosto:

- **segmento, não palavra inteira** — porque os achados reais eram compostos;
- **lista sem homógrafo** (`base`, `total`, `local`, `final`, `real` fora) — porque falso-positivo em
  regra HARD é a corrente que o Elenxo do #566 reconstruiu;
- **baseline desde o nascimento** — 3 residuais anteriores à sessão, então dívida existente é SOFT e
  ocorrência nova é HARD, como a R49 e a R45;
- **teto declarado**: abreviações (`donenu`, `arq`) escapam e isso está escrito, não escondido.

## O que este PR NÃO faz

**Não constrói a guarda.** E a razão é a lição que a sessão inteira ensinou: construí-la agora, como
apêndice de outra entrega, é como nasceram os dois fail-opens que a passada adversarial derrubou hoje.
O ciclo dela tem de ser **próprio, com Elenxo**.

## Verificação

- backlog **18/20**, nenhum `done` sem carimbo · radar do grafo **verde** (18 nós, 18 arestas)
- lint **0 HARD** + 4 SOFT pré-existentes
