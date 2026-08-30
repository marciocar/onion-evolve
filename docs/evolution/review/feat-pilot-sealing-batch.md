---
title: "Revisão — o lote de selagem do piloto: 4 decisões do maestro aplicadas nos 6 grafos"
date: 2026-08-30
branch: feat/pilot-sealing-batch
reviewer: "o conteúdo selado JÁ passou por 3 camadas (padrão-ouro sha c975fce6 × workers × juízes opus/high, PR #715); este PR só APLICA os selos do maestro (AskUserQuestion 2026-08-30, 4 respostas) pela tabela de selagem do /meta:kg-freshness — cada flip conferido pelo radar (--integrity --schema exit 0 nos 6 grafos)"
reviewed_diff_sha256: df1465edfc0cbff55a4b628fa24a32249a22937282197f6b59eea9eea055bb68
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 0
duration_min: 25
---

# Resíduo — REGRA 56

Selos do maestro (2026-08-30): **B** = juiz FIXO, veredito=proposta · **C** = censo dos 190 com
juízo escopado aos CONFIRMED, em lotes · **EN_MAESTRO** = refuted · **carimbos** = como montado
(8 sim, 4 não).

## O que foi aplicado, por grafo (tabela de selagem do comando)

| grafo | flip/append |
|---|---|
| colaboracao | `EN_MAESTRO`→refuted + `C_MAESTRO_NAO_E_UNICO_RELAY` (REFUTES) + 2 carimbos |
| identidade-vps | `Q_BACKUP…`→superseded + `Q_BACKUP_MECANISMO_ARMADO_SEM_AGENDAMENTO` (SUPERSEDES) + 2 carimbos |
| federation-reconciled | `REC_STAGING…`→superseded + `REC_STAGING_ROT_2026_08_REMEASURED` (SUPERSEDES) + 1 carimbo |
| guardas-revisao | 3 carimbos |
| dogfood | `D_JUIZ_CALIBRACAO_GATED`→done + `D_B_JUIZ_FIXO_VEREDITO_PROPOSTA` + `D_C_CENSO_190_JUIZ_EM_CONFIRMED` |
| fios-abertos | `D_CENSO_VIRA_AMOSTRA…`→superseded + `D_CENSO_190_EM_LOTES` (a ponta de execução) |

**Não carimbados (decisão do maestro, medição reprovada pelo juiz):** `EN_REPO` (ls curado),
`D_MEDIR_O_DONO…` (3/6), `C_TRES_MODELOS…` (3/7), `REC_A2A…` (4/7) — ficam para re-medição.

## REGRA 63 — id removido, nomeado

- `Q_CENSO_EM_VEZ_DE_AMOSTRA` (colhido de `fios-abertos`, estava `done` com carimbo; a resposta
  vive em `D_C_CENSO_190_JUIZ_EM_CONFIRMED` no grafo dogfood e no histórico git). A colheita
  manteve o arquivo no TETO 20 ao entrar `D_CENSO_190_EM_LOTES`. Aresta `DEPENDS_ON` re-apontada
  ao sucessor.

## Duas correções às propostas dos workers (achados desta aplicação)

1. O worker do REC_STAGING propunha **reescrever o label do nó antigo in-place** — a tabela
   proíbe ("nunca reescreva o label do antigo"). Aplicado como nó novo + SUPERSEDES.
2. O contrato do comando ainda dizia "juiz se >30% DRIFTED" — regra com furo medido (gatilho
   dependente do autojulgamento dos workers). Substituída pela decisão B, com o porquê inline.

## Gate mecânico

- radar `--integrity --schema` → **exit 0 nos 6 grafos** (colaboracao 36/45 · identidade 32/28 ·
  federation · guardas · dogfood · fios-abertos 20/20 no teto)
- censo do drive: `pronto=1 = D_CENSO_190_EM_LOTES [execution]` — a fila voltou a dizer a verdade
- `kg-reverify-schema-check` rc=0 · assemble do vertical onion regenerado (R19) ·
  `docs/backlog.md` regenerado (R62, 190 abertos)
