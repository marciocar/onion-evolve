---
title: "Revisão — colheita do fios-abertos + três flips selados por medição"
date: 2026-08-29
branch: chore/harvest-fios-abertos-onda1
reviewer: "selo do maestro + medição executada por flip (nenhum carimbo sem medir) + gates determinísticos (radar, REGRA 58, realign, drive, lint)"
reviewed_diff_sha256: aa5c5e6fd6f5bf5514f633328b760853082b4159a29f0a8f649ed7ca0ed24de0
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 28000
duration_min: 22
---

# Resíduo — REGRA 56

Operação **destrutiva por desenho** (colheita remove 18 nós) + **três flips de status de verdade**.
É a classe de maior risco do corpus: apagar genealogia e carimbar sem medir.

## Achados

1. **Eram TRÊS flips, não dois.** O maestro autorizou "os dois"; a varredura por `drifted` no corpus
   inteiro achou **três**. Reportar dois e selar três em silêncio seria o erro; reportar a diferença
   é o ponto. Os dois extras (`C_command_side_gap`, `E_floors_effective_measured_20260729`) **não
   foram flipados por autorização** — foram **re-medidos contra o vivo** e o flip seguiu a medição.

2. **Nenhum flip foi carimbo.** `federation-member.md` medido: `argument-hint` só `register`,
   OP-2/3/4 ausentes → o label `drifted` descreve o vivo → `confirmed`.
   `/sys/fs/cgroup/system.slice/memory.min` = **402653184** (não-zero) + cgroup do bridge presente →
   o fix do teto de ancestral segue efetivo → `confirmed`. A invariante — *o único caminho para um
   `verified_at` novo passa por medição executada* — foi honrada nos três.

3. **A Aufhebung estrita só foi possível com o selo.** O radar havia **recusado** (`--integrity`
   exit 1) a aresta `REFUTES` contra alvo `drifted`, e estava certo. Com o alvo em `superseded` +
   nó sucessor, a aresta volta a ser `REFUTES` e a genealogia fica auditável — nada apagado.

4. **Achado colateral, medido no caminho: 4 de 75 grafos não eram YAML válido.** O formato se chama
   `.kg.yaml` e o parser real falha em quatro (aspas quebradas em `label:`). O radar é **awk
   linha-a-linha** e tolera — por isso nunca ninguém viu. O `fios-abertos` era um deles e **voltou a
   ser válido por acidente da colheita**. Os 3 restantes viraram nó `open` com **gatilho que declara
   a ORDEM**: consertar primeiro, guarda depois — ligar a catraca antes reprovaria o repo inteiro.

## Disciplina da colheita

- **Dois nós preservados** por serem **teses duráveis**, não itens de onda:
  `C_BACKLOG_DE_DOCUMENTO_ORDENA_ITEM_MORTO` e `C_ORDEM_DO_RADAR_NAO_E_ORDEM_DE_EXECUCAO`.
- **Onda nova no MESMO commit** que a colheita, como o `meta:` prescreve — e respeitando a fronteira
  do arquivo (*"nenhum fato nasce aqui; aqui mora o compromisso, citando o id alheio"*): os fatos
  ficam em `backlog-grafo-2026-08`, aqui só o compromisso.
- **O que falta da onda tem gatilho que é um NÚMERO**, não impressão: o delta da taxa de mortalidade
  entre F1 e F6, contra a baseline medida de 33%.
- **Arestas penduradas eliminadas junto** — remover nó sem remover aresta reprovaria no radar.

## Verificação

| gate | resultado |
|---|---|
| `kg-radar --integrity --schema` (4 grafos tocados) | **exit 0** |
| REGRA 58 (`kg-backlog-check`) | **OK 6/20** — 14 vagas livres |
| `realign --check` | ALINHADO |
| `drive --check` | READY 1 |
| `lint-artifacts` | **0 HARD** |
| `drifted` no corpus | **ZERO** |
| `fios-abertos` como YAML | passou a **válido** |

## Teto declarado

A colheita **apaga nós**, e a casa prega *Aufhebung* (nunca apagar). O `meta:` resolve por decreto —
*"a história fica no git"* — e **esse decreto nunca passou por Elenxo**. Está registrado como lente
L2 da F4 no plano da onda; esta colheita **exerceu** o decreto sem tê-lo validado. Se ele cair, o
TETO de 20 muda de natureza, e este PR será o caso a reexaminar.
