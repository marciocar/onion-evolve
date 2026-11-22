---
branch: fix/one-touch-midturn-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: 43c27a8fa9e9b37f0560cba4d89290b61b313d8863181d529a22aa073c1588dc
reviewed_code_sha256: 0db6bfb1a7503f1baed787c6f5b325b39b66ee73c5d9eacf758b8247200b9057
findings_total: 7
findings_real: 4
findings_blocking: 0
tokens: 112383
duration_min: 8
findings_fixed: 4
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, mandato de forja (outra sessão, mod/canal, o próprio modelo), ~8 min: APPROVED_WITH_NITS, sem forja nova. Mediu contra o transcript real de 120 MB: d82f5d09 e 81ad8498 aceitas como meio do turno, sugestão aceita de topo recusada, censo das 362 queued_command (peer e channel sempre emoldurados e isMeta; as 44 humanas com humanTurn e commandMode=prompt), disparos agendados nunca viram queued_command. Quatro MENORES (M1 a M4), todos tratados neste PR; três notas fora do diff (injeção por tmux send-keys, RecursionError, mensagem possivelmente duplicada)."
nota: "tokens = os do revisor (subagent_tokens)."
---

# Passada adversarial: `fix/one-touch-midturn-1120`

## O que muda

O «pode rodar» digitado com a sessão trabalhando (SAC-485, fase 1 da catraca, SAC-493) era recusado pelo executor
com «a frase do prompt da palavra … não está no transcript». Medido em 20/11 no transcript do core: o hook recebe o
`prompt_id` do **turno em curso** e a mensagem entra como `type: attachment`, `attachment.type: queued_command`,
**sem** `promptId`. O leitor só via a entrada `type: user` de topo. Agora `transcript_word` acha as duas formas; a do
meio do turno só vale dentro do turno do `prompt_id`, a até 30 s da aprovação, com `origin.kind: human`,
`humanTurn: true`, `commandMode: prompt`, sem `isMeta`. O livro guarda o id da palavra (`prompt_id` ou
`prompt_id/source_uuid`).

## O que se tentou refutar (revisor isolado)

- **Forja por outra sessão**: peer chega emoldurado e com `isMeta` (235 de 235); peer com frase nua recusa pela origem.
- **Forja pelo modelo**: tool_result com texto, resumo de compactação (origin ausente), disparo agendado
  (`promptSource: system`, `isMeta`, sempre de topo), entrada `isSidechain`: todos recusam.
- **Outro turno, janela, replay**: recusam; replay com hash novo cai no livro pelo id da palavra.
- **Travas antigas**: frase exata, prazo da palavra, sha, sugestão aceita de topo: iguais.

## Achados e destino

- **M1** — a forma do meio do turno não distingue digitado de sugestão aceita (o harness não grava `promptSource`
  ali). Medido: os 32 aceites de sugestão vieram com a sessão parada. Tratado: limite declarado no motor e no README;
  o caso `(ot18)` foi rotulado como «forma não medida».
- **M2** — o fallback do consume gravava o `prompt_id` cru e deixava `P/uuid` livre. Tratado: grava `P/*`, que gasta
  todo o turno; caso `(ot26)` com mutante.
- **M3** — exceção fora da lista no consume impedia o gasto. Tratado: `except Exception` no fallback; `RecursionError`
  no `json.loads` do leitor também cai fechado.
- **M4** — tool_result com promptId antigo moveria a amarra ao turno. Tratado: tool_result não move a amarra; caso
  `(ot25)` com mutante.
- **Fora do diff**: injeção por `tmux send-keys` entra no teto declarado (README); a possível entrega dupla da mesma
  mensagem (meio do turno e depois topo) fica como observação não medida.

## Veredito

Revisor separado: APPROVED_WITH_NITS. Com os quatro menores tratados neste PR, o veredito do resíduo é FIXED. O PR toca guarda (o motor da aprovação e a
bancada): o merge é do maestro.
