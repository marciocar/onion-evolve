---
branch: research/codex-as-core
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: b2dd911d9d8a2090787126a3308ed2bf84ead2a8fcb36146b178c80963aeca53
reviewed_code_sha256: 3a49be32065392bc25691075a2c8b094f529ebc72e89b60f040a8a9a41e9ae73
findings_total: 16
findings_real: 16
tokens: 1384791
duration_min: 12
findings_fixed: 16
verdict: CORRIGIDO
elenxo: sim
reviewer: "workflow onion-research em modo primaries (wf_e4a2a9be-bb5): 8 leitores, 8 verificadores de ancoragem separados e o Elenxo; verificador separado do grafo com radar e contrato rc 0"
nota: "os 16 achados são as claims rejeitadas na ancoragem (9 sem citação, 7 exageradas), que não viraram nó"
---

# Passada adversarial: `research/codex-as-core`

## O que muda

- `docs/evolution/research/codex-as-core-2026-10/codex-as-core-2026-10.kg.yaml`: grafo novo, com 62 nós (32
  evidências ancoradas, 8 vereditos por peça, 11 objeções do Elenxo, 7 superações e a recomendação).
- `docs/evolution/research/codex-as-core-2026-10/SYNTHESIS.md`: a projeção, com o contrato de custo.

## Achados

Os 16 achados são as claims que a ancoragem rejeitou (9 sem citação e 7 exageradas). Elas não viraram nó e estão
contadas no `E_LACUNAS_PRIMARIES_CODEX_AS_CORE_1026`.

## Limites declarados

- Nenhum spike rodou, e o veredito da peça do hook é «falta equivalente provado», não «impossível».
- O Codex CLI não está instalado no ambiente do core; os spikes pedem a instalação, que é do maestro, ou o ambiente
  da curadoria, que já o tem.
