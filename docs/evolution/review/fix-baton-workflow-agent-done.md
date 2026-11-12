---
branch: fix/baton-workflow-agent-done
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: "o próprio agente de execução, sobre o defeito que a sessão principal mediu na 1ª batida real depois do #1617; sem subagente (o brief proíbe lançar agentes)"
nota: "tokens = 0 e duration_min = 0: não medidos. Medidos: família baton_pulse 58/58 (29 casos, 2 novos, cada um reprovando contra o mutante dele), censo das formas de fim nos 4851 transcripts de workflow da máquina e dogfood real antes e depois."
---

# Passada adversarial: `fix/baton-workflow-agent-done`

## O que muda

O `baton-pulse.sh` passa a reconhecer o fim do agente da ferramenta Workflow. Esse agente entrega por
`StructuredOutput`, e o tool_result dela agora encerra o agente como `AGENT_DONE`, como já fazia o do
`SubagentHandback`. As duas ferramentas ficam em `FINAL_TOOLS`.

A idade do agente passa a vir do carimbo da última entrada user/assistant, não do mtime do arquivo. A linha
`attachment` que o harness grava depois do fim não conta mais como atividade. Sem carimbo, vale o mtime.

## Achados

1. **Bloqueava, curado: 160 falsos `AGENT_SILENT`.** Na primeira batida real depois do #1617, todos os agentes de
   Workflow já concluídos da sessão do kg-ssot saíam calados. O fim deles é o tool_result «Structured output provided
   successfully», que o medidor não reconhecia. Caso (ab).
2. **Bloqueava, curado: a linha `attachment` final rejuvenescia o agente.** O mtime do arquivo vinha dela, então um
   agente calado havia uma hora parecia escrito agora e saía RUNNING. Caso (ac).

Censo das formas de fim nos 4851 transcripts de workflow da máquina, contadas antes de cravar:

| Forma do fim | Transcripts | Classe com a cura |
|---|---|---|
| tool_result do StructuredOutput, sem linha depois | 4678 | DONE (novo) |
| tool_result do StructuredOutput, com `attachment` depois | 66 | DONE (novo) |
| texto do assistente com `stop_sequence` | 47 | DONE (já era) |
| texto do assistente com `end_turn` (2 com `attachment` depois) | 43 | DONE (já era) |
| `[Request interrupted by user…]` | 17 | DONE (já era) |

Dogfood real: na batida do checkout principal, os agentes iam de 146 DONE, 2 RUNNING e 160 SILENT para 306 DONE e 2
RUNNING, com 0 SILENT. Com todas as sessões da máquina como peers, os 4851 agentes de workflow saem DONE. Os 11
SILENT e 5 STALLED que sobram são subagentes comuns e antigos: os SILENT terminam num tool_result ou num pedido à
API sem resposta, e os STALLED em laços de espera pendurados. Isso é o sintoma que a classe deve acusar, e não outra
forma de fim.

## Mutantes

- (ab): o `StructuredOutput` sai de `FINAL_TOOLS`.
- (ac): a idade volta a ser só o mtime (`if last_ts:` vira `if False:`).

## Limites declarados

- A idade pelo carimbo vale para todas as classes. Uma ferramenta longa que só grava linhas de progresso (fora de
  user/assistant) não rejuvenesce o agente. Não medi se o harness grava progresso assim; o refutador já tinha visto
  28 ferramentas longas legítimas saírem STALLED pelo mtime, e o limite do falso STALLED segue o mesmo.
- `FINAL_TOOLS` é uma lista. Uma ferramenta de entrega nova do harness volta a sair SILENT até entrar nela, e esse
  SILENT é o sinal de que ela precisa entrar.
