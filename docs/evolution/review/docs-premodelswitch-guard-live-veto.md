---
title: "Revisão — D_HOOK_PREMODELSWITCH_GUARDA selada: veto observado ao vivo no /model do maestro"
date: 2026-09-02
branch: docs/premodelswitch-guard-live-veto
reviewer: "condutor com observação ao vivo: o maestro tentou /model → Sonnet 5 na sessão principal (main 1b795de2) e o Claude Code respondeu 'Model switch to Sonnet 5 was blocked by a PreModelSwitch hook' com a mensagem da guarda; log model-switch.jsonl 18:28:27Z decision=block; radar --integrity --schema exit 0 (34/34); backlog regenerado LC_ALL=C"
reviewed_diff_sha256: a4adbfbccea4f89e41f7cc5d31aec9aea6f7915d501897255887f96db8058fa2
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 15000
duration_min: 5
---

# Resíduo — REGRA 56

Fecha o fio nascido na pesquisa Fable 5.1 (#763): declarado → observado (#767) → curada a cegueira
processo-vs-disco (#768) → guarda entregue (#770) → **veto observado ao vivo** (este). A decisão vira
`done` em plane PROD com a observação como `verified_against`.

## Achados

1. **Não precisou reiniciar**: o hook foi carregado do `settings.json` novo na mesma sessão após o merge
   — corrige a minha afirmação anterior ("hooks carregam no início da sessão"). Registrado no carimbo.
2. **A mensagem da guarda chegou inteira ao maestro** (rota de escape incluída): o stderr do exit 2 é
   repassado pelo picker; não precisa de `decision: block` em JSON.

## Não mudou

- Nenhum nó novo (grafo no TETO 34/34): a observação vive no `verified_against` da própria decisão.
- Opção 2 (confirmação por custo de cache) segue não selada.
