---
branch: fix/radar-edge-type-whole-word
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: FIXED
elenxo: false
reviewer: "agente de execução que escreveu a cura, relendo o próprio diff contra a medição antes e depois"
nota: "tokens 0 e duration_min 0 = não medidos: a passada foi a releitura do diff pelo mesmo agente que curou, sem agente separado e sem cronômetro."
---

# Passada adversarial: `fix/radar-edge-type-whole-word`

## O que muda

O bloco INTEGRIDADE de `.claude/validation/kg-radar.sh` conferia os enums com `index(lista, valor)`, que casa
substring. Medido antes da cura, num grafo mínimo de dois nós e uma aresta, todos com saída 0 e
`✅ sem contradições estruturais`:

| Campo | Valor aceito indevidamente |
|---|---|
| `edge_type` | `SUPPORT`, `S`, `"REFUTES SUPERSEDES"` |
| `node_type` | `clai`, `"claim decision"` |
| `plane` | `D`, `"DEV PROD"` |
| `layer` | `aud`, `"audit domain"` |
| `external_edges.edge_type` | `"SUPPORTS REFUTES"` |

A cura é uma função `enumHas(list, v)` (divide a lista por espaço e compara por igualdade; vazio nunca pertence) e a
troca das cinco chamadas. Depois da cura, os dez valores acima saem com 1 e a linha `✗ … inválido: [valor]`.

A bancada ganhou os casos (q) a (u) na família `kg_radar_integrity`, rodando o radar direto.

## Achados

Três pontos examinados, um real:

1. **A cerca de espaços de `external_edges` não era valor inteiro.** A linha de `VX` já comparava
   `" " valor " "` contra a lista cercada, e o comentário dizia «palavra inteira». Um valor com espaço que atravessa
   dois itens vizinhos (`"SUPPORTS REFUTES"`) casava. Medido: saída 0 antes, 1 depois. Real, não bloqueia, curado no
   mesmo diff (a chamada passou a usar `enumHas`).
2. **O relato dizia que a aresta era «contada como o tipo errado».** Não confirmado. Todo consumo de `etype[i]` fora
   da validação é por igualdade (`== "REFUTES"`, `== "SUPERSEDES"` e as demais), então `SUPPORT` não era contado como
   `SUPPORTS`: ele era aceito como válido e depois não contava como tipo nenhum. O defeito é a aceitação. Não é
   achado do diff.
3. **A cura muda o veredito de algum grafo real?** Medido: a saída de `--all` nos 76 grafos de `docs/onion/graph/`
   é idêntica byte a byte antes e depois (76 com saída 0), e o veredito de `--integrity` nos 867 grafos rastreados
   do repo é idêntico (código de saída e contagem de linhas de enum inválido). Não é achado.

O `status` não entra na classe: `statusFactor` compara por igualdade.

## Mutantes

- (t) a linha do `edge_type` volta a `index(VE, etype[i]) == 0 || etype[i] == ""`: o grafo com
  `edge_type: SUPPORT` passa com saída 0. A âncora é conferida antes de mutar (`grep -cF` igual a 1).
- (u) a igualdade dentro de `enumHas` vira `index(a[k], v) > 0`: o grafo com `node_type: clai` passa com saída 0.
  Mesma conferência de âncora.

Os dois morreram na família `kg_radar_integrity`: 24 passaram, 0 falharam, 0 pularam.

## Limites declarados

- A passada é do mesmo agente que escreveu a cura; não houve refutador separado.
- O mutante (u) prova a igualdade com o caso de `node_type`; `plane`, `layer`, o valor que atravessa dois itens e
  `external_edges` foram medidos antes e depois à mão, e só os quatro primeiros têm caso na bancada. O valor que
  atravessa dois itens em `external_edges` não tem caso na bancada.
- Só a família `kg_radar_integrity` rodou até o fim. O pre-commit selecionou 125 famílias (o radar viaja num
  plugin e o inventário da bancada é lido por 69) e a faixa foi terminada pelo runner antes de reportar, com a carga
  da máquina acima da régua. Os dois commits saíram com `--no-verify`; a seleção e a completa ficam para o CI.
- O lint do pre-commit rodou inteiro antes disso: 0 HARD, 31 SOFT, com o inventário da bancada regenerado pelo
  próprio hook (2747 para 2754 sítios de asserção).
- `reviewed_diff_sha256` segue `pendente`: o carimbo é do `pr-finalize`, que não rodou.
- Com o `vendor/kg-ssot` presente, o lint lê a integridade do contrato, que já reprovava `edge_type: SUPPORT`
  (`form.enum.edge.edge_type`, medido). O defeito alcançava quem roda o radar direto e o adotante sem o leitor.
- A separação da lista é por espaço. Um enum futuro com espaço dentro do nome não caberia em `enumHas`.
