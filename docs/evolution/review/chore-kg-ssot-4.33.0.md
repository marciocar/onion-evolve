---
branch: chore/kg-ssot-4.33.0
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: 1744c60461c0662e1059b25285e547810d5215fa21facd046d606db400f411a5
reviewed_code_sha256: 6bc998937baf0b37b7a740ebcd9198694ea7d49103eaf0ccd2d6fb8e94b79be2
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 20
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "subagente de adoção (claude-opus-5-5), passada própria sobre o diff inteiro"
nota: "tokens não medidos; a passada mediu os consumidores do kg_query.py no core e o modo de falha do --chain"
---

# Passada adversarial: `chore/kg-ssot-4.33.0`

## O que muda

A adoção da kg-ssot 4.33.0 (contrato v4.16 sem mudança). Só muda ferramenta: o `kg_query.py` ganha o `--chain <id>`,
que projeta a cadeia de transmissão de um nó até a origem. Em `spec/` só muda o `release.json`. O vendor segue com 658
arquivos. Entra o nó de adoção `E_KG_SSOT_433_ADOTADA_1027` em `sinais-de-campo-2026-09`, e o índice de leitura é
regenerado.

## Achados

1. **Afirmação sobre a linha de base sem medida** (real, corrigido): o rascunho da narrativa dizia que "o gate não
   reclama do grafo novo". A linha de base tem 194 registros e a main tem 195 grafos. Li o contrato de rc do
   `kg_gate.py --help`: um grafo novo é julgado pelo MUST e falha só se reprovar. A frase passou a dizer isso, em vez
   de afirmar silêncio.

Conferido e sem defeito:

- **Quem consome o `kg_query.py` no core**: `kg-trace.sh`, `peer-ref-check.sh` e `dissect-object-check.py`. A única
  mudança no código antigo é o `resolve()`, que ganhou o parâmetro `flag` com o padrão `--around`. A mensagem do
  `--around` sai igual (`--around NAO_EXISTE_XYZ: the node does not exist in the corpus`, rc 2). Nenhum leitor do
  core lê essa prosa: eles leem o rc. As famílias `kg_trace_resolve`, `kg_trace_root_file`, `peer_ref_check`,
  `dissect` e `dissect_object` passaram com 210 casos e nenhuma falha.
- **Modo de falha do `--chain`**: um id inexistente dá rc 2 com BROKEN INPUT. O `--format json` sai com
  `schema_version` e as quatro cadeias.
- **A árvore da tag** é idêntica à da ref `12dcfc491c69` da bancada (mesmo tree `08542cc292d6`), e o `--chain` sobre
  `D_A2A_EMPRESA_ADOTANTE_TOPOLOGIA_1027` sai igual byte a byte à saída da bancada.
- **A identidade do contrato** não mudou: o gate não emite a linha `· identity`, então o `--update` não foi rodado.
- REGRA 87 (PR que EDITA um `.kg.yaml` enxergou os `confirmed` dele): conferi os `confirmed` de maior impacto do
  grafo editado, que são `E_RADAR_IGNORAVA_O_SEGUNDO_MODO`, `C_O_CAMPO_ACHA_DECLARADO_MAIOR_QUE_MEDIDO`,
  `E_CENSO_EM_VOO_LE_NOME_DE_BRANCH` e `E_SPIKE_SOBREVIVENCIA_PREMIA_O_TRIVIAL_1012`. Nenhum trata do `kg_query` nem
  da projeção da cadeia, e o nó novo não contraria nenhum deles: ele só registra a adoção, no molde do 4.32.0.

Rebase sobre a main: o conflito em `sinais-de-campo-2026-09` era só de arestas vizinhas. As arestas da peça de
rascunho entre agentes que chegaram da main e a aresta do nó de adoção ficaram as duas. Depois disso, o
`kg-radar.sh` deu 73 nós e 74 arestas sem contradição, e o `kg-contract-check.sh` deu conforme. Revisei de novo o
diff rebaseado, que tem o mesmo conteúdo, e por isso o carimbo voltou a `pendente`.

## Mutantes

Nenhum mutante novo. O PR não toca maquinaria do core: o código novo vem do vendor, e a bancada dele é da kg-ssot.

## Limites declarados

- O `--chain` ainda não tem consumidor no core. A adoção só deixa a ferramenta disponível.
- Não medi o desempenho do `--chain` em corpus maior que o do core. Os tetos (200 passos e 1000 caminhos) são da
  kg-ssot.
