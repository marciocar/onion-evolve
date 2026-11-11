---
branch: chore/kg-ssot-4.49.0
pr: pendente
date: 2026-11-11
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 30
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: agente de execução da sessão do core, por comando, sem revisor independente
nota: "tokens 0 = não medido. Vendor do kg-ssot 4.49.0 (contratos v4.20 e v4.21, só SHOULD) com a dívida dos dois avisos novos aceita como linha de base. Passada do próprio autor; nenhum agente separado."
---

# Passada: `chore/kg-ssot-4.49.0`

## O que muda

- **Vendor:** `kg-ssot-v4.48.0` → `kg-ssot-v4.49.0` (`76d6698011ba`), 765 arquivos, pelo espelho
  `https://github.com/marciocar/kg-ssot` com `--verify-attestation` (rc 0). `kg_vendor.py check` rc 0.
- **Contrato:** v4.20 (perfil `x_classification`) e v4.21 (dois avisos SHOULD), segundo o ADOPTING do vendor.
- **Linha de base do gate:** `ops/kg-gate-ci.sh` acusou exatamente os dois códigos novos
  (`form.deprecated.node.provenance.method` 0 → 5327; `form.required.node.provenance` 0 → 159) e mais nada.
  Aceitos por `--update --accept-regression` com o motivo do ADOPTING (`.kg-ssot/gate/accepted/bf19376f64ad39f2.json`).
  Nenhum grafo foi alterado para calar o aviso. Depois do update, o gate dá rc 0.

## Achados

1. **O commit da tag difere do informado no brief.** O brief dava `0bc99fbee8fb`; a tag `kg-ssot-v4.49.0` no espelho
   resolve (tag anotada, `^{}`) para `76d6698011ba`, e a atestação confere com esse commit. O vendor carimba o que a
   release atestada diz. A tag foi republicada depois do commit inicial, ou o brief citou o commit pré-release.

## Medições

- `kg_migrate.py methods plan --root .`: rc 0, 5327 apelidos a trocar em 206 arquivos, 0 para revisor, 0 na cauda,
  3975 nós `confirmed` tocados. Nada gravado (apply não foi rodado).
- `kg-radar.sh <grafo> --integrity --schema` em 3 grafos de `docs/onion/graph`: rc 0 nos três.
