---
branch: docs/decide-2026-11-04-company-brain
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 3
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão do core (passada inline)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `docs/decide-2026-11-04-company-brain`

## O que muda

Quatro selos do /meta:decide de 2026-11-04 no grafo `company-brain-multiaudiencia-2026-10`, todos pelo
`kg-decide-seal.sh`:
- `Q_MA_WRITE_SURFACE`: três camadas;
- `Q_MA_ENFORCEMENT`: plano gratuito, medindo antes o card `Q_MA_FREE_ORG_READ_ENFORCED`;
- `D_MA_CANAL_EXTERNO_SO_APOS_CLASSIFICACAO_1104`: o canal com parceiro externo só entra depois da classificação;
- `D_MA_RUNTIME_PESQUISAR_ANTES_1104`: o runtime do Slack se escolhe só depois de uma pesquisa.

As propostas consideradas foram `C_PROPOSAL_KG_MCP_AREAS_AND_PROMOTION_1104` (kg-ssot) e
`D_CB_CHANNEL_PROMOTION_PROPOSAL` (curadoria, f07034d).

## Achados

1. Hipótese: o selo da superfície fechar a escolha da arquitetura (`D_MA_ARCH`) sem pergunta. Conferido: a
   `D_MA_ARCH` segue aberta, e a pergunta das audiências (`Q_MA_AUDIENCES`) também, à espera da lista de papéis do
   hub.

## Mutantes

Nenhum: não há código.
