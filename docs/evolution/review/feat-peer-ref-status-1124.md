---
branch: feat/peer-ref-status-1124
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
findings_blocking: 2
tokens: 112000
duration_min: 4
findings_fixed: 9
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "refutador INDEPENDENTE (agente separado, brief sem a conclusão do condutor; cópia por git archive, matriz dos 2 parsers em 14 ids, 5 mutantes próprios) REPROVOU com 2 bloqueios e 7 limites; o condutor curou os 9 e matou de novo os 3 mutantes que viviam (M1 PyYAML sempre open, M2 sem guarda de status ausente, M3 != done)"
nota: "tokens e duração são os do refutador; a passada do condutor não foi medida"
---

# Passada adversarial: `feat/peer-ref-status-1124`

## O que muda

- `peer-ref-check.sh`: a linha diz o `status` do nó; `--want-open` (3º argumento) sai rc 3 quando o nó não está
  `open` (qualquer outro status, inclusive `confirmed`), rc 2 sem `#ID` (antes de qualquer desvio), sem status ou com
  status que não é texto simples. Status é dado do par: nunca vira 2ª linha na saída.
- Bancada `peer_ref_check`: casos (j), (j2), (j3), com o caminho PyYAML.
- `co-evolve.md` e a KB de canais entre sessões citam o rc 3.

## Achados e curas

1. **Bloqueante.** sha com `--want-open` saía rc 0, ignorando a flag. Cura: a guarda vem antes de todo desvio; rc 2.
2. **Bloqueante.** 3 mutantes viviam (PyYAML sempre `open`; sem guarda de status ausente; `!= done`). Cura: (j3) com
   `confirmed`, nó sem status, sha com a flag e o fallback PyYAML; os 3 mutantes morrem.
3. Rótulo `(i)` duplicado com caso antigo: virou `(j)`.
4. `"open\n"` passava como open; 5. status com quebra de linha forjava 2ª linha; 6. status não-string dizia «não
   declara». Cura comum: status com caractere de controle ou não-string vira marcador; com a flag, rc 2 «não é texto
   simples»; sem a flag, a linha diz isso.
7. Cabeçalho: `Uso` com `[--want-open]`, rc 2 e rc 3 descritos.
8. Chamadores (`co-evolve.md`, KB) citam o rc 3.
9. Arquivo ausente sem `#ID` com a flag dava rc 1: agora a guarda vem antes e dá rc 2.
