---
branch: fix/radar-edge-type-whole-word
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: dc4e508b161af85f9318e541115dbde8d0a939c985085ad135a6eb7c196bca0f
reviewed_code_sha256: c0ba5716bbbd071205f37ac4fc4f9891eb50ea509e4697580fd3d682935a32bb
findings_total: 4
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "1ª passada: o agente de execução que escreveu a cura, relendo o próprio diff. 2ª passada independente em 2026-11-17: agente revisor separado, só leitura, mandato de refutar"
nota: "tokens 0 e duration_min 0 = não medidos: a passada foi a releitura do diff pelo mesmo agente que curou, sem cronômetro; a 2ª passada foi de um agente separado, cujo custo não chegou a este agente."
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

Quatro pontos examinados, dois reais:

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

4. **Nenhum caso da bancada tocava `external_edges`** (observação de cobertura da revisão independente). Reverter só
   a chamada das arestas externas à cerca de espaços antiga passava calado. Real, não bloqueia, curado: casos (v) e
   (w) e o mutante (x).

O `status` não entra na classe: `statusFactor` compara por igualdade.

## Mutantes

- (t) a linha do `edge_type` volta a `index(VE, etype[i]) == 0 || etype[i] == ""`: o grafo com
  `edge_type: SUPPORT` passa com saída 0. A âncora é conferida antes de mutar (`grep -cF` igual a 1).
- (u) a igualdade dentro de `enumHas` vira `index(a[k], v) > 0`: o grafo com `node_type: clai` passa com saída 0.
  Mesma conferência de âncora.
- (x) só a chamada das arestas externas volta a `index(VX, " " xtype[i] " ") == 0 || xtype[i] == ""`: a aresta
  externa com `edge_type: "SUPPORTS REFUTES"` passa com saída 0. Mesma conferência de âncora.

Os três morreram na família `kg_radar_integrity`: 27 passaram, 0 falharam, 0 pularam.

## Revisão independente (2026-11-17)

Segunda passada, de um agente revisor separado, só leitura, com mandato de refutar. Sem achado bloqueante.

**Mediu:**

- O `split` do awk com separador de espaço colapsa espaços e tira as pontas; o valor chega aparado de espaço, TAB,
  CR e de uma aspa de cada lado.
- 97 grafos de `docs/onion/graph/` e `docs/evolution/research/` sem diferença de código de saída nem de saída byte a
  byte entre o radar antigo e o novo.
- O cenário das arestas externas reproduzido: radar antigo sai 0, novo sai 1.
- Família `kg_radar_integrity`: 24 passaram, 0 falharam (antes dos casos (v) a (x)).

**Leu:**

- `status` não é da classe.
- Não sobrou `index(` de validação.
- `--integrity` é o awk próprio do radar e não chama o contrato vendorizado; o defeito era explorável por quem roda
  o radar sem o leitor.

**Não verificou:**

- O lint completo.
- O caminho com o vendor presente.

## Limites declarados

- O mutante (u) prova a igualdade com o caso de `node_type`; `plane`, `layer` e o valor que atravessa dois itens
  numa aresta interna têm caso positivo, sem mutante próprio.
- Só a família `kg_radar_integrity` rodou até o fim. O pre-commit selecionou 125 famílias (o radar viaja num
  plugin e o inventário da bancada é lido por 69) e a faixa foi terminada pelo runner antes de reportar, com a carga
  da máquina acima da régua. Os dois commits saíram com `--no-verify`; a seleção e a completa ficam para o CI.
- O lint do pre-commit rodou inteiro antes disso: 0 HARD, 31 SOFT, com o inventário da bancada regenerado pelo
  próprio hook (2747 para 2754 sítios de asserção no primeiro commit; 2758 depois dos casos das arestas externas).
- `reviewed_diff_sha256` segue `pendente`: o carimbo é do `pr-finalize`, que não rodou.
- Com o `vendor/kg-ssot` presente, o lint lê a integridade do contrato, que já reprovava `edge_type: SUPPORT`
  (`form.enum.edge.edge_type`, medido). O defeito alcançava quem roda o radar direto e o adotante sem o leitor.
- A separação da lista é por espaço. Um enum futuro com espaço dentro do nome não caberia em `enumHas`.
