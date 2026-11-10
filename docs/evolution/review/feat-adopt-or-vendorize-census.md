---
title: 'Resíduo — doutrina do estado da peça e a coluna de peças do mapa de interconexão'
branch: feat/adopt-or-vendorize-census
pr: pendente
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
findings_blocking: 2
tokens: 60000
duration_min: 35
verdict: FIXED
elenxo: false
nota: >-
  Passada adversarial feita pela própria sessão sobre o diff, sem refutador separado: o brief proíbe
  criar agentes, logo elenxo: false. Dois achados que mudariam o que o maestro lê foram curados; três
  são LIMITE declarado. O escopo foi reduzido pelo maestro no meio do trabalho: o medidor, a bancada e o
  grafo próprios da 1ª versão saíram da branch (guardados fora do repo como patch), e ficaram a
  doutrina, a coluna e o selo.
---

# Resíduo — REGRA 56 (Resíduo de revisão por branch)

## Achados que bloqueavam (curados)

1. **`kind: method` não é projeção.** Na 1ª versão (o medidor, hoje fora da branch), quem adota só o
   método aparecia como «escrito pelo core por desenho». A doutrina nova não repete o erro: os estados
   são de peça, não de natureza de membro, e a porta é o único estado que o core escreve por desenho.
2. **O `/meta:adopt` passava de 800 linhas** com a linha que citava a doutrina (REGRA 5 (Limites de
   linhas)). A linha saiu; a doutrina é citada pela `PIECES.md` e pelo nó
   `E_INTERCONNECT_PIECES_COLUMN_1110`.

## LIMITE declarado (não bloqueia)

3. Os números da coluna são de uma janela de 30 dias, lidos por git sem fetch: o clone do bridge estava
   em `92079ae` (2026-11-07), anterior ao HEAD remoto que o mapa local cita.
4. A coluna não mede valor estratégico; diz o estado e qual gatilho acendeu.
5. A doutrina não cria guarda. Ninguém reprova uma peça por estado; quem aplica é a decisão do maestro.

## Medido

- Grafo do perfil: `E_INTERCONNECT_PIECES_COLUMN_1110` (trace `PIECES.md`) e
  `D_PIECE_STATE_DOCTRINE_1110` selado pelo `kg-decide-seal.sh` com `--other`; radar exit 0, contrato
  conforme; TETO 12 → 14 com justificativa.
- Gate A2A: blob git idêntico no core e na mensageria (`c4f1e34d…`). Três unidades da fila ativas.
  Bridge: 15 arquivos de operação, 34 de 34; mensageria: 25 de 25.

## Não mudou

- Nenhuma adoção, nenhum vendor e nenhum repo de peça escrito.
