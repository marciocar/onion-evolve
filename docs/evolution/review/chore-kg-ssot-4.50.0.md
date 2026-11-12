---
branch: chore/kg-ssot-4.50.0
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: 044f941f083d83bf92e6abf957cd33f6e8234228337c28d3f47b7ec0d4ad2794
reviewed_code_sha256: a94f21be996b7ec79ec1759ac2df80fe860f7fd6352fe403c3e2d16b869a0741
findings_total: 2
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 75
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: agente de execução da sessão do core, por comando, sem revisor independente (o brief vedou lançar agentes)
nota: "tokens 0 = não medido. Vendor do kg-ssot 4.50.0, sem contrato novo (segue o v4.21). Passada do próprio autor; nenhum agente separado, e o refutador do preâmbulo fica para a sessão principal antes do PR."
---

# Passada: `chore/kg-ssot-4.50.0`

## O que muda

- **Vendor:** `kg-ssot-v4.49.0` → `kg-ssot-v4.50.0` (`e77d82848189`), 765 arquivos, pelo espelho
  `https://github.com/marciocar/kg-ssot` com `--verify-attestation` (rc 0; o carimbo grava
  `attestation.repo marciocar/kg-ssot` e `manifest_sha256 0bd1cade3212…`). `kg_vendor.py check` rc 0.
  24 arquivos mudam no vendor, nenhum arquivo novo: `kg_mcp.py` (papéis e tetos na política de áreas; chave repetida ou
  arquivo acima de 1 MiB invalidam a política), `kg_gate.py` (o `--touched` ignora a troca apelido↔classe inglesa do
  `provenance.method` com o detalhe idêntico), `kg_validate.py` (o mapa `METHOD_ALIASES`, fonte única),
  `kg_migrate.py` (`--manifest-out`), testes, manual, CHANGELOG, ADOPTING e locale.
- **Contrato:** nenhum (segue o v4.21); o `contract_sha256` da base não muda.
- **Base do gate:** só o `kit` de `.kg-ssot/gate/contract.json` sobe para 4.50.0 (protege contra voltar o kit).
  Nenhum registro de grafo muda.
- **Política de áreas do kg-mcp:** o core não roda `--area-policy` (busca fora de `vendor/` e de resíduos antigos: zero
  uso), então a mudança de veredito não alcança o core.

## Achados

1. **(real, fora do escopo, não bloqueia) O `--update` da base trazia deriva alheia.** `bash ops/kg-gate-ci.sh --update`
   gravou, além do `kit`, dois registros de grafo que ainda não estavam na base (`forge-baton-2026-11`,
   `subagent-background-wait-2026-11`) e a baixa de `integrity.bare-decision` (671 → 0) em
   `pr-decision-history-2026-08`. Nada disso vem da 4.50.0: é a base atrasada em relação à `main`. Ficou fora deste PR
   (revertido; só o `kit` entrou), e o gate sem `--update` segue rc 0 com a base atual. Quem regrava a base é outra
   tarefa.
2. **(não é defeito) 24 contra 718.** O CHANGELOG cita 718 dívidas antigas num corpus grande; no core, o `--touched` da
   4.49.0 sobre o lote do migrador reprova 24 nós. São corpora diferentes; o mecanismo é o mesmo.

## Medições

- `ops/kg-gate-ci.sh`: rc 0 (vendor íntegro, catraca, `--touched` com 0 grafos alterados, critério 14/0, nomes 0 novos).
- `kg-contract-check.sh` nos 304 `.kg.yaml` rastreados fora do vendor: rc 1, 259 ✓ e 45 ✗ (40 fixtures propositalmente
  inválidas e 5 com dívida herdada que o gate exclui). Saída **idêntica byte a byte** à do vendor 4.49.0 no mesmo HEAD
  (`diff` vazio). Zero grafos a curar.
- `kg-radar.sh --integrity --schema` nos 261 grafos fora de fixture: 261 rc 0, igual à 4.49.0.
- Bancada (`LC_ALL=C`, `ONION_ASK_DIR` isolado), em três lotes:
  `adopter_shape, kg_contract_check, kg_gate_ci, kgssot_tools, kg_migrate_v3, adopter_gate, vendor_pin, vendor_manifest,
  design_context` 161/161; `decide, kg_trace_resolve, remeasure_contract` 115/115 (49 + 39 + 27); `mcp_onion_kg_writer, plan_contract_migration, mcp_onion_kg` 125/125 (68 + 34 + 23).
  Nenhum ⊘, nenhum ✗.
- `lint-artifacts.sh`: rc 0, 0 HARD, 65 SOFT (frescor de KB, radar de mundo, contagens do `docs/INDEX.md`; nenhum ligado
  ao vendor).

## Dogfood da cura do `--touched` (worktree descartável, nada commitado)

- `kg_migrate.py methods apply --root . --manifest-out <tsv>`: rc 0, 5327 trocas em 206 arquivos; o manifesto tem 5327
  linhas mais o cabeçalho `graph id old new`.
- Sobre esse lote, `kg_gate.py --touched HEAD` (com os `--exclude` do `ops/kg-gate-ci.sh`): **4.50.0 rc 0** (206 grafos
  alterados, nenhum nó tocado com dívida); **4.49.0 rc 1**, 24 nós com `integrity.bare-decision`.
- Modo de falha: mudar o detalhe do method (não só o prefixo) num grafo de triagem de relay de `docs/onion/graph` faz a 4.50.0
  reprovar de novo (rc 1, 2 nós); restaurado o arquivo, rc 0.

## Mutantes

Nenhum mutante plantado por `ops/mutate-and-restore.sh`: este PR não muda guarda nem bancada do core. O par
4.49.0/4.50.0 e o detalhe alterado acima fazem o papel de controle negativo para a cura do vendor.

## Limites declarados

- A migração dos aliases não foi feita (outra tarefa); o lote do dogfood ficou na worktree descartável.
- A base do gate segue atrasada em dois grafos e numa dívida paga (achado 1).
- A política de áreas do kg-mcp não foi exercitada: o core não a usa.
- Sem refutador independente nesta passada.
