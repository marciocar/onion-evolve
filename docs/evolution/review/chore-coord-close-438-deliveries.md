---
branch: chore/coord-close-438-deliveries
pr: pendente
date: 2026-10-29
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: a própria sessão do PR (agente do core), sem revisor separado
nota: "tokens não medidos (0). PR de registro curto: fecha dois nós do grafo de coordenação e arquiva três sinais."
---

# Passada adversarial: `chore/coord-close-438-deliveries`

## O que muda

- `Q_COORD_KGSSOT_WITH_NO_REVISIT_E_DECISION` e `Q_COORD_KGSSOT_HASH_CANONICO_SCHEME_KG_NODE` vão a `done`, com
  evidência medida: `gh pr view 292 -R marciocar/onion-kg-ssot` (MERGED, 55db567), a tag `kg-ssot-v4.38.0` no
  espelho pelo `git ls-remote --tags`, a API JSON do PyPI na 4.38.0, o PR 1427 do core (MERGED) e o
  `grep -n node_sha256` no `kg_trace.py` vendorizado.
- Os dois sinais da curadoria vão verbatim para `_processed/`; o do hub vai como stub genérico (REGRA 36
  (Superfície VENDORIZADA sem nome comercial de cliente)).
- `docs/backlog.md` regenerado.

## Achados

1. **Real, curado:** o label do nó do hash seguia dizendo "em versão futura da kg-ssot" com o nó em `done`.
   Reescrito para dizer que foi pedido para uma versão futura e entregue na 4.38.0.

Conferido sem achado: o stub do hub não traz setor, auditoria, lacuna de segurança, pessoas, canais nem comitês;
os sinais da curadoria citam o repo do hub só pelo nome do repo adotante, que já aparece em `_processed/`.

## Mutantes

- Status `fechado` (fora do enum) numa cópia do grafo: o radar `--integrity --schema` reprova com rc 1
  (`status inválido: [fechado]`); o original passa com rc 0.

## Limites declarados

- O "32 de 32 pontes" da curadoria e o critério E3 do pré-registro são relato do kg-ssot, citados em texto e não
  re-executados pelo core.
- Revisão feita pela própria sessão, sem agente separado.
