---
title: "Revisao adversarial — re-selamento kg-freshness do m2-bridge-logto"
date: 2026-08-23
branch: chore/kg-freshness-m2-reseal
reviewer: "@branch-code-reviewer (passada adversarial, mandato REFUTAR)"
reviewed_diff_sha256: dae32842b05f845879f4ee0a782f291fa48c857dfa3c2ae815457498158c0f2f
findings_total: 6
findings_real: 1
tokens: 67286
duration_min: 7
verdict: APROVADO
---

# Residuo de revisao — REGRA 56

Passada adversarial sobre o re-selamento de 16 nos do `m2-bridge-logto-2026-07.kg.yaml` pelo
`/meta:kg-freshness` (16 workers mediram o vivo read-only; o maestro selou). **6 frentes, 1 achado real.**

## Verificacoes mecanicas (todas passaram)
- radar `--integrity --schema` exit 0 (123 nos, 171 arestas) · `--reconcile` exit 0 ("nenhum alvo de
  SUPERSEDES ficou por reconciliar") · as 5 novas SUPERSEDES apontam ao no `superseded` certo · nenhum
  orfao grau 0 novo · lint 0 HARD · grep de redacao (grana.ai|arthur) vazio · os 5 traces existem.
- **Conformidade com a tabela do Passo 4 EXATA**: CONFIRMED(4) so verified_at+verified_against ·
  DRIFTED(5) so status→superseded com **label byte-identico** + novo no + SUPERSEDES · UNVERIFIABLE(7)
  verified_at NAO tocado, confidence↓, reverify_note.
- **Anti-fabricacao**: os 5 nos novos sao medicoes ao vivo (Logto 1.42.0, psql tenant, systemctl show),
  internamente coerentes e conservadoras — `E_org_membership_grows` AUTO-REFUTA (registra cardinalidade
  crescente em vez de trocar "1"→"2"). Ground-truth remoto nao reproduzivel do repo — declarado, nao e defeito.

## Achado F1 (medio-baixo) — ENDERECADO neste PR
4 nos UNVERIFIABLE seguiam `status: confirmed` com labels que a sessao MEDIU como falsos (dual-legacy
removido no P11, rotas /admin|/a2a→404, client m-default invalidado) — a drift so aparecia no
`reverify_note`, invisivel a quem le so status/label. E o proprio declarado≠verificado, aplicado a cura.
**Cura:** marquei o label de E_p4/E_p5/E_p7 com "[⚠ superficie parcialmente obsoleta — ver reverify_note]"
(nao viola a regra: esses nos sao UNVERIFIABLE, nao superseded; a marca flagra, nao reescreve o conteudo).
E_p9 (reforco, nao drift) fica como esta.

## Veredito
**APROVADO** — selo mecanicamente correto, tabela exata, reconciliacao limpa, lint verde; F1 (a unica
recomendacao) curado neste PR. Verificado por comportamento (radar/lint/grep rodados), nao declaracao.
