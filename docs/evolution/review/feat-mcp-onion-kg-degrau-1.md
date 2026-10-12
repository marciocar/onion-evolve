---
reviewed_diff_sha256: b3940018a6e10c131ce268549381d594ad5b4ecce646a7c4088b14a07a7bbfd3
reviewed_code_sha256: e5ff3e083cafa6a397e4e25bdd0e188b83e557c9b2a1101799b55407cc614318
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 0
verdict: PENDENTE
elenxo: parcial
nota: >
  Código do degrau 1 de D_ONION_BRAIN_MCP_REMOTO no core. As seis curas pedidas vieram do Elenxo da
  pesquisa (kb_search sem --, raiz fixa, sem frescor, sem kg_node, saída sem marca de não confiável,
  token fail-closed mantido). Na escrita apareceram mais três buracos, todos curados com caso e mutante.
  A passada adversarial da REGRA 56 sobre o diff final ainda não rodou; o sha fica pendente até ela.
---

# Resíduo — `feat/mcp-onion-kg-degrau-1`

O `ops/mcp-onion-kg/server.py` passa a servir **uma raiz fixada pela instância** (`ONION_KG_ROOT`), com
frescor (`served_commit`, `fetched_at`) e a marca `untrusted_data` em toda resposta, e ganha a tool
`kg_node`, que lê o nó só pelos modos determinísticos do radar. Nada foi ligado: deploy, systemd,
firewall e LibreChat ficam com o maestro (runbook no README).

## Achados da escrita, além das seis curas pedidas

| # | Severidade | Achado | Cura |
|---|---|---|---|
| 1 | BLOQUEIA | `kg_radar` aceitava caminho **absoluto** (`'..'` era a única barreira): lia um `.kg.yaml` de fora do repo. O resíduo de 2026-08-20 só testou `..` | o grafo tem de estar no `git ls-files` da raiz, e o caminho é confinado por realpath; caso `kg_radar-absoluto-recusado` |
| 2 | BLOQUEIA | `kb_get` seguia **symlink** dentro de `docs/knowledge-base/` para fora da raiz | realpath confinado à raiz; caso + mutante `kb_get-symlink-para-fora-recusado` |
| 3 | BLOQUEIA | raiz apontada para um **subdiretório** de um repo: o git sobe até o pai e o servidor declararia o commit do repo errado | exige `--show-toplevel` igual à raiz; caso + mutante `raiz-subdiretorio-recusa` |

## Medido

- `python3 -I ops/mcp-onion-kg/selftest.py` com `LC_ALL=C`: 21/21, servidor real em porta efêmera de
  127.0.0.1, processos encerrados pelo handle.
- Versão antiga do `kb_search` (mutante): `-efoo` devolveu `a.md` (o `-e` virou flag) e `--version`
  devolveu o banner do `grep (GNU grep) 3.11`.
- Família `mcp_onion_kg`: harness + 14 mutantes, cada um nomeando o caso que tem de reprovar.
- Teto: o mutante de `os.path.isabs` sobrevive (defesa redundante com o `git ls-files` e o prefixo da KB).
