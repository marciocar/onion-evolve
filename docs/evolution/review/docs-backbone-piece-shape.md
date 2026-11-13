---
branch: docs/backbone-piece-shape
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: f2e2100fde3efa1498f6a006445ab5f3b9351e95e37836ad05a80e42ba1f40c4
reviewed_code_sha256: e393b90c9d1332fd35ec43b05873b555a4a0cb2e2736eaeb92db92b6d7c90c1a
findings_total: 3
findings_real: 3
findings_blocking: 2
tokens: 0
duration_min: 20
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: sessão do core (passada própria, sem subagente)
nota: "tokens 0 = não medido: passada feita na própria sessão, sem run separado"
---

# Passada adversarial: `docs/backbone-piece-shape`

## O que muda

O grafo novo da rodada de primárias sobre a forma da peça do backbone de comunicação (63 nós do workflow mais 4
termos), a `SYNTHESIS.md` como projeção dele, dois selos do maestro no grafo do estudo do Brain
(`D_BACKBONE_OWNER_1112`, `D_BACKBONE_OPEN_LICENSE_1112`) e o `docs/backlog.md` regenerado.

## Achados

1. **Códigos de lacuna sem nome, e dois com o sentido de outro estudo** (real, bloqueava, corrigido). O lint de nomes
   (`ops/kg-vocab-ci.sh`) saiu rc 1 com 14 achados novos: G3 e G4 sem termo, e o E3 solto ambíguo entre dois estudos.
   Pior, e calado: G1 e G2 resolviam para o «gabarito» do estudo `problem-route-2026-11`, sentido errado com nome
   único, que o lint não acusa. Cura: quatro nós `T_BACKBONE_GAP_G1..G4` com `x_term` no esquema
   `backbone-piece-gaps`, ligados por `TRACES_TO` à pergunta, e o E3 reescrito como `E3_DESCARTE_SEM_MEDIDA`.
   O TETO subiu de 63 para 67, com o motivo no comentário do `meta`. Depois: rc 0, novos 0.
2. **Nenhum nó sem `trace:` para citar a síntese** (real, bloqueava, corrigido). Os 63 nós já tinham `trace:`, e uma
   segunda chave faria o leitor YAML ficar com a última e o radar reprovar. Cura: o caminho da síntese entrou na frente
   do valor existente de `Q_BACKBONE_PIECE_SHAPE_2026_11`, com `;`, que o `kg-provenance-coverage.sh` separa.
3. **O retorno do workflow aponta o grafo no checkout principal** (real, não corrigido, limite). O `kgPath` do run
   nomeia a raiz do checkout principal, mas o arquivo está nesta worktree e não existe lá. Não muda o conteúdo; o rc
   do radar e do contrato foi medido de novo aqui.

## Mutantes

- Tirar a citação da síntese do `trace:` (e da `provenance` dos termos): `kg-provenance-coverage.sh` sai rc 1 com
  `HARD NEW` sobre a `SYNTHESIS.md`. Com a citação: saída vazia, rc 0. Arquivo restaurado e conferido por `git diff --quiet`.
- Sem os nós `T_BACKBONE_GAP_*` (o estado anterior à cura): `kg-vocab-ci.sh` rc 1, 14 achados novos.

## Limites declarados

- O achado 3 fica como está: é do motor do workflow, não deste PR.
- A conferência de fatos da síntese contra o grafo foi feita pelos ids dos nós e pelas contagens do retorno do run;
  nenhuma fonte web foi relida.
