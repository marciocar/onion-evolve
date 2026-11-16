---
branch: chore/adopt-kg-ssot-4.53.0
pr: pendente
date: 2026-11-16
reviewed_diff_sha256: 060948d69c0e91efba57648710c4355981dba19833e92cf789f0ff165532235d
reviewed_code_sha256: 146f4d6e1899fa2431c11b816589f0b32349e51017b4d469e9c46ae556257591
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "bancada do core sobre a 4.53.0: antes da tag (commit do kg-ssot vendorizado em cópia, KG_GATE_ALLOW_UNRELEASED=1 ops/kg-gate-ci.sh = RC 0, benção dada em 2026-11-16) e depois da tag (kg_vendor.py update --tag kg-ssot-v4.53.0 com a atestação herdada do carimbo, ops/kg-gate-ci.sh released = RC 0). Medido no released: changed graphs 0, critérios pré-registrados 14 com 0 achados, códigos novos 0."
nota: "Adoção de vendor (v4.52.0 → v4.53.0, commit aa7fa13e, 810 arquivos; 21 mudam no core). Sem código do core alterado e sem mudança de contrato (nenhum veredito MUST ou SHOULD muda). O que a versão traz: kg_audit.py falha fechado no grafo que reprova no MUST; o perfil gate do vendor passa a levar tools/kg_vocab.py."
---

# Adoção da kg-ssot 4.53.0 (sem mudança de contrato)

## O que muda

`vendor/kg-ssot` v4.52.0 → v4.53.0 (commit aa7fa13e). O contrato não muda. Duas mudanças de ferramenta:

- `kg_audit.py` passa a conferir, com o leitor de referência, os grafos que o pacote lê; grafo que parseia e reprova no MUST vira entrada quebrada (rc 2, nenhum pacote, uma linha por grafo no stderr). Antes, uma aresta com `edge_type` fora do enum fazia a evidência sumir do pacote com rc 0.
- o perfil `gate` do vendor leva o `tools/kg_vocab.py`: o adotante que vendoriza só esse perfil saía com exit 1 na conferência de códigos da casa.

## Achados

Nenhum. Bancada do core verde antes da tag e de novo com a tag publicada (RC 0 nas duas); nenhum grafo do core mudou.

## Limites declarados

- Não medi se algum fluxo do core chama o `kg_audit.py` com grafo que hoje reprova no MUST; se chamar, ele passa a sair rc 2 em vez de montar pacote com lacuna falsa. O gate do core (`ops/kg-gate-ci.sh`) não usa o `kg_audit.py`.
- A publicação da 4.53.0 no npm segue pendente do maestro; a adoção do core é pela tag do git e não depende dela.
