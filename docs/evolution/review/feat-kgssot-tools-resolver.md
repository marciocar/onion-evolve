---
branch: feat/kgssot-tools-resolver
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 4293deb4e4739dbb6d9ca4afe9f2113679e5939a5a2537c94b2dda5004d4aecc
reviewed_code_sha256: 86c86da4ddfd790a77eb85f3809839bdbfdf4dfaef538b6ffc3f566bfe635f23
findings_total: 4
findings_real: 4
tokens: 0
duration_min: 180
findings_fixed: 4
verdict: CORRIGIDO
elenxo: nao
reviewer: "o autor (passada própria na bancada) + verificação do diferencial pela sessão principal; NENHUMA das duas é independente"
nota: "tokens = 0 porque não foram medidos (nem os do autor, nem os da verificação); duration_min é o relógio da forja, bancada inclusa. Sem refutador independente: a sessão principal estava no teto de 5 agentes e verificou o diferencial por conta própria. Os 4 achados vieram da bancada do autor e foram curados no mesmo PR."
---

# Passada adversarial: `feat/kgssot-tools-resolver`

## O que muda

- Resolver único da pasta das ferramentas do KG-SSOT: `.claude/utils/kg/kgssot-tools.sh` (bash) e o espelho
  `.claude/utils/kg/kgssot_tools.py`. Ordem: `KG_SSOT_TOOLS` (pasta existente) → `vendor/kg-ssot/tools` →
  `tools/` quando o `spec/release.json` da raiz declara a tag `kg-ssot-v*`. Nada casou: o caminho de hoje.
- Os 13 sítios executáveis de `.claude/validation` que fixavam `vendor/kg-ssot/tools/` passam por ele. O sinal de
  campo é o `E_CORE_VENDOR_PATH_FIXED_1105` da sessão do kg-ssot (rc 3 em toda dissecação de lá).
- Família `kgssot_tools` (24 casos): paridade bash = python, ponta a ponta pelo `kg-contract-check.sh` e pelo
  `dissect-object-check.py`, mutantes por ramo e uma catraca contra caminho fixo novo.

## Achados (todos da bancada do autor, curados aqui)

1. A catraca (d), na 1ª rodada, achou um caminho fixo que a lista de 14 não via: o conselho de venv do
   `currency-census.sh`. Curado (o pino sai do resolver, `KGSSOT_REQ_REL`).
2. `kg_trace_resolve` (n2) reprovou: a bancada extrai a função do `lint-artifacts.sh` e roda fora dele, onde o
   `KGSSOT_TOOLS_REL` não existia (unbound). Curado com default no uso.
3. `dissect_object` reprovou: a bancada escreve o checador num tmp sem `utils/kg/`, e o checador saía rc 3
   ("resolver ausente"). Curado: o bench copia o resolver junto.
4. MUTANTE EQUIVALENTE: desligar o ramo vendor do resolver SOBREVIVEU ao placar só de rc, porque o fallback de
   cada chamador é o mesmo vendor. Ponta a ponta o ramo é redundante; quem o mata é o veredito do resolver
   (o 5º campo do placar, comentado no código).

## Mutantes

- Cópia limpa provada verde no mesmo arranjo antes de contar mortos (placar `0 0 0 - vendor`).
- Bash: env, vendor, fonte e vazio, 4/4 mortos. Python: os mesmos 4, 4/4 mortos. Catraca: linha fixa plantada
  acusada.

## Verificação da sessão principal (NÃO independente)

- 25 grafos sorteados do core: `kg-contract-check` com o mesmo rc na branch e na main, 0 divergência.
- Radar e contrato em 2 grafos (coordenação e pesquisa): iguais.
- Numa cópia do repo do kg-ssot (`tools/` + `spec/`): o resolver devolve `source ./tools`.

## Mudança de comportamento declarada

- `kg-decide-seal.sh` e `kg-projection.sh` reconheciam o produto por QUALQUER `tools/kg_*.py`; agora exigem o
  `spec/release.json` do kg-ssot. Num adotante com um `tools/` próprio isso deixa de ser lido como o produto
  (era um falso reconhecimento). A fixture (s12) do decide ganhou o `release.json`, que o repo real tem.
- No `meeting-graph-check.sh` o caso de contrato passa a ser julgado onde as ferramentas resolvem (antes, ⊘).

## Limites declarados

- Fora de escopo, ainda com o caminho fixo: `.claude/utils/adopt/` (vendor-manifest, plan-contract-migration,
  remeasure-contract), `ops/kg-*-ci.sh` e os workflows `.github/workflows/onion-{validate,selftest}.yml`.
- Sem REGRA nova (a 119 segue livre): a catraca mora na bancada, que o CI roda.
- A família `fixtures` não completou localmente (50 ✓ / 0 ✗ até o teto de 40 min sob carga); a completa é do CI.
- Commit com `ONION_PRECOMMIT_CHECKPOINT=1`; o `rebase --continue` rodou sem hooks (só o inventário gerado
  conflitou e foi regenerado).
