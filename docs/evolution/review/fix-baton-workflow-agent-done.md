---
branch: fix/baton-workflow-agent-done
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: f5f7cd9f9b27a9c599d27e376d9db50d8366378ca2a4f95d005fce491507a4bc
reviewed_code_sha256: c8018d9511c1f644bc586529f75f157b6e668140498588ced0452d4bd901c16b
findings_total: 5
findings_real: 5
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 5
verdict: FIXED
elenxo: false
reviewer: "1ª passada: o próprio agente de execução, sobre o defeito que a sessão principal mediu na 1ª batida real depois do #1617; 2ª passada: refutador separado (subagente que não escreveu o diff), APPROVED sem bloqueio e com 3 limites, curados pelo agente"
nota: "tokens = 0 e duration_min = 0: não medidos. Medidos: família baton_pulse 64/64 (32 casos, 5 novos, cada um reprovando contra o mutante dele), censo das formas de fim nos 4851 transcripts de workflow da máquina e dogfood real antes e depois."
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

## Passada do refutador (APPROVED)

Nada bloqueia; família 58/58 no 98b491bc3. Três limites baratos, curados na mesma branch:

3. **Carimbo no futuro dava idade negativa.** O agente pendente saía `RUNNING há -1440min` para sempre. Cura: idade
   negativa cai no mtime. Caso (ad).
4. **Entrega com `is_error: true` fechava como DONE.** O agente tenta de novo depois dela (65 casos reais). Cura: só o
   tool_result sem erro de uma ferramenta final é fim. Caso (ae).
5. **Mutante W5 vivo: a marca de fim não zerava na nova mensagem do assistente.** O código já zerava, mas nenhum caso
   provava. Um agente que entregou, seguiu trabalhando e morreu calado sai SILENT, não DONE. Caso (af).

Os casos sintéticos do refutador (carimbo epoch, no futuro, lixo, ausente, ingênuo, com fuso, velho com mtime novo,
StructuredOutput com pendência, StructuredOutput com erro) rodados contra a cura: os pendentes saem STALLED ou RUNNING
pela idade, a entrega com erro sai SILENT, e nenhum sai DONE.

## Mutantes

- (ab): o `StructuredOutput` sai de `FINAL_TOOLS`.
- (ac): a idade volta a ser só o mtime (`if last_ts:` vira `if False:`).
- (ad): a idade negativa deixa de cair no mtime. (ae): o `is_error` deixa de ser conferido. (af): a marca de fim não zera (W5).

## Limites declarados

- A idade pelo carimbo vale para todas as classes. Uma ferramenta longa que só grava linhas de progresso (fora de
  user/assistant) não rejuvenesce o agente. Não medi se o harness grava progresso assim; o refutador já tinha visto
  28 ferramentas longas legítimas saírem STALLED pelo mtime, e o limite do falso STALLED segue o mesmo.
- `FINAL_TOOLS` é uma lista. Uma ferramenta de entrega nova do harness volta a sair SILENT até entrar nela, e esse
  SILENT é o sinal de que ela precisa entrar.
