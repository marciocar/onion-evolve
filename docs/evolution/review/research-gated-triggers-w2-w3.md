---
title: "Revisão — gatilhos de W2/W3 saem do arquivo externo e viram grafo"
date: 2026-08-28
branch: research/gated-triggers-w2-w3
reviewer: "self-review — achado nasceu de pergunta cética do maestro; ausência CONFIRMADA por grep com rc e stderr à vista antes de qualquer escrita"
reviewed_diff_sha256: 40903b5ee2f29b4b8776affb98dd904fafb82c49565d210c270cbfa28f02ff28
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 16000
duration_min: 12
---

# Resíduo — REGRA 56

Seis nós `question`/`decision` + o plano trazido para dentro do repo como projeção. **Zero lógica.**

## Achados

1. **Os seis gatilhos estavam fora de qualquer grafo** — confirmado com `grep -rl ... ; rc=1` e
   `<nenhum arquivo>` impresso, **não** com um `grep -c` que devolveria `0` tanto para ausência
   quanto para erro. (A guarda anti-fail-open do shell cobrou exatamente isso na 1ª tentativa.)

2. **A causa foi decisão de sequenciamento minha, não acidente.** O plano os programava para a F6.
   Isso contraria `gated-work-derives-fresh`: **o gatilho é o que sobrevive ao tempo**; o "como"
   apodrece. Guardar o durável para o fim é pô-lo no lugar mais frágil — e o lugar era um arquivo
   **fora do repositório**.

3. **Documento derivado sem o que o superou vira item morto.** O `SYNTHESIS.md` não foi copiado cru:
   leva cabeçalho declarando ser **derivação** e uma tabela dos **quatro pontos** em que medições
   posteriores já o superaram — inclusive a minha proposta de aging (derrubada) e a citação falsa do
   KARMA. É a tese fundadora do `fios-abertos` aplicada ao próprio artefato desta onda.

4. **O CI achou o que eu não achei.** O `SYNTHESIS.md` nasceu **sem nenhum nó o citando em
   `trace:`** — a guarda `proveniência-invertida` acusou: *"achado estruturado nasce no grafo; o
   markdown é vista"*. Ironia registrada: o PR que traz um documento para dentro do repo **para não
   evaporar** quase o deixou como prosa solta, que é a mesma doença noutra embalagem. Curado na forma
   do irmão `kg-read-leg-2026-08`.

## Disciplina

- **Só gatilho, nenhum desenho de solução** nos seis nós — a regra transversal que o plano fixou.
- **`D_AGREGACAO_CROSS_REPO_E_MOAT` foi escrito como `decision`, não `question`**, de propósito: MOAT
  permanente não é "ainda não", e como pergunta alguém o reabriria como fio esperando amadurecer.
- **`DEPENDS_ON` para a Onda 1**: o censo passou a 4 prontos / **4 bloqueados** — a guarda segurando
  o que depende, exatamente como o contrato descreve (guarda, não ordenação).

## Verificação

`kg-radar --integrity --schema` **exit 0** (25 nós, 24 arestas) · `kg-drive-project --check` READY
4/4 · `lint` **0 HARD** · o grafo de pesquisa segue fora de `docs/backlog.md` (190).

## Teto declarado

O **compromisso** da onda em `fios-abertos` continua **não escrito** — aquele grafo está em 20/20
(teto cheio) e escrever lá exige colheita, que é flip de status e **selo do maestro**. O que este PR
resolve é a exposição do *gatilho*; o *compromisso* segue pendente por desenho, não por esquecimento.
