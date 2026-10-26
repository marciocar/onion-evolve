---
branch: research/codex-as-core
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: 642ec1e6fac01b159752ceb7423869f86928534319b5218889e807b35796d319
reviewed_code_sha256: 5c41d93884bbc14e136522489a0415053a68decf627ccad9362b1d5e18a2e2cf
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

## Re-revisão (2026-10-26, depois do CI)

O CI reprovou a faixa 1 da bancada: a guarda de caminho de máquina em nó de grafo (REGRA 99) achou a isenção
`x_path_is_content: "citação"` do `E_CUSTOM_AGENTS_ARE_TOML` fora do baseline. O delta novo é uma linha no
`.claude/validation/kg-machine-path-baseline.txt`, emitida por `kg-machine-path-check.sh --emit-baseline`.
Conferido à mão: o único caminho do nó é `~/.codex/agents/` / `.codex/agents/`, que é a citação verbatim da doc do
Codex no `verified_against`. É conteúdo, não caminho desta máquina. A guarda sai rc 0 e sem linhas depois do baseline.
Achados novos: 0.
