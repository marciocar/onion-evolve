---
reviewed_diff_sha256: 96d66058eabc94768ceb295e39b2e2c4b6e7417e3ec382e529c17cbfb689c278
reviewed_code_sha256: bdb9882db5e83c40b4bac8aca9041dfe1aab8aba32e3cf7ecc6d6c92b6cddfbe
findings_total: 12
findings_real: 11
tokens: 76766
duration_min: 3
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Código do degrau 1 de D_ONION_BRAIN_MCP_REMOTO no core. As seis curas pedidas vieram do Elenxo da
  pesquisa. Duas passadas: a minha, na escrita, achou três buracos que BLOQUEIAM (caminho absoluto no
  kg_radar, symlink no kb_get, raiz em subdiretório); a de um refutador independente aprovou com
  ressalvas, sem bloqueio, e deixou três mutantes sobreviventes e a promessa de frescor cumprida só em
  parte. Tudo curado no mesmo laço, com caso no harness (21 para 29) e mutante na família (14 para 20),
  menos dois tetos declarados.
---

# Resíduo — `feat/mcp-onion-kg-degrau-1`

O `ops/mcp-onion-kg/server.py` passa a servir **uma raiz fixada pela instância** (`ONION_KG_ROOT`), com
frescor (`served_commit`, `fetched_at`, `arvore_limpa`) e a marca `untrusted_data` em toda resposta, e
ganha a tool `kg_node`, que lê o nó só pelos modos determinísticos do radar. Nada foi ligado: deploy,
systemd, firewall e LibreChat ficam com o maestro (runbook no README).

## Passada 1 (autor, na escrita): 3 achados, os 3 BLOQUEIAM

| # | Severidade | Achado | Cura |
|---|---|---|---|
| 1 | BLOQUEIA | `kg_radar` aceitava caminho **absoluto** (`'..'` era a única barreira) e lia `.kg.yaml` de fora do repo. O resíduo de 2026-08-20 só testou `..` | grafo tem de estar no `git ls-files` da raiz + confinamento por realpath; caso `kg_radar-absoluto-recusado` |
| 2 | BLOQUEIA | `kb_get` seguia **symlink** em `docs/knowledge-base/` para fora da raiz | realpath confinado; caso + mutante `kb_get-symlink-para-fora-recusado` |
| 3 | BLOQUEIA | raiz num **subdiretório** de um repo: o git sobe ao pai e o servidor declararia o commit errado | `--show-toplevel` igual à raiz; caso + mutante `raiz-subdiretorio-recusa` |

## Passada 2 (refutador independente): APROVADO com ressalvas, 9 achados, 8 reais

| # | Severidade | Achado | Cura |
|---|---|---|---|
| 4 | MENOR | `kg_node` podia trocar `verified_at`/`verified_against` sem teste ver (mutante sobreviveu) | caso `kg_node-vivo-rastreado` + mutante |
| 5 | MENOR | recusa de grafo não versionado sem teste (mutante sobreviveu) | caso `kg_radar-nao-versionado-recusado` + mutante |
| 6 | MENOR | `grep -r` (não `-R`) sem teste: trocar por `-R` sobreviveu | caso `kb_search-symlink-para-fora-nao-aparece` + mutante |
| 7 | MENOR | `served_commit` podia não ser o commit do conteúdo: `kb_get`/diário/inventário liam arquivo não versionado, e havia janela entre o frescor e a leitura | arquivo versionado exigido; `arvore_limpa` no envelope; HEAD relido depois da tool. Casos `kb_get-nao-versionado-recusado`, `arvore-limpa-declarada`, `arvore-suja-declarada` + mutantes |
| 8 | MENOR | `Content-Length` negativo prendia uma thread (`rfile.read(-1)`) | 400 fora de 0..1 MB; caso + mutante |
| 9 | MENOR | `params` não-objeto derrubava a conexão sem resposta | 400 / -32602; caso + mutante |
| 10 | TETO | regex BRE patológica segura thread até 60 s; sem checagem de `Origin` | declarado no README para o degrau 2 |
| 11 | TETO | README lia `fetch_head_commit` ≠ `served_commit` como "atrás" | texto corrigido: "atrás, ou fixado de propósito" |
| 12 | falso | `NODE_ID_RE` aceita `\n` final | a comparação exata devolve "inexistente"; nada vaza |

## Medido

- `LC_ALL=C python3 -I ops/mcp-onion-kg/selftest.py`: 29/29, servidor real em porta efêmera de 127.0.0.1,
  processos encerrados pelo handle, fixture removida.
- Versão antiga do `kb_search` (mutante): `-efoo` devolveu `a.md` (o `-e` virou flag) e `--version`
  devolveu o banner `grep (GNU grep) 3.11`.
- Família `mcp_onion_kg`: 21/21 (harness + 20 mutantes, cada um nomeando o caso que reprova).
- Dogfood manual contra o próprio core (porta 38917, PID encerrado no fim): sem token 401; `kg_node` de
  um nó real com `served_commit` e arestas; `kb_search --version` como padrão; nó inexistente com erro e
  commit declarado.
- Tetos de mutante (defesa dupla, sobrevivem um a um): `os.path.isabs` e a recusa de raiz em runtime
  antes/depois da tool.
- `lint-artifacts.sh` 0 HARD. Não rodei a bancada completa: só a família tocada.
