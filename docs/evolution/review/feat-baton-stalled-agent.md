---
branch: feat/baton-stalled-agent
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
findings_blocking: 1
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: FIXED
elenxo: false
reviewer: "o próprio agente de execução, com mandato de refutar o diff; sem subagente (o brief proíbe lançar agentes): a sessão principal roda o refutador separado antes do PR"
nota: "tokens = 0 e duration_min = 0: não medidos. Medidos: família baton_pulse da bancada 26/26 (13 casos, 5 novos, cada um reprovando contra o mutante dele), lint-artifacts 0 HARD e 27 SOFT antes e depois, dogfood real contra os transcripts da máquina e replay dos três refutadores travados de 2026-11-12."
---

# Passada adversarial: `feat/baton-stalled-agent`

## O que muda

O `baton-pulse.sh` ganha a seção de subagentes (SAC-421). Para cada sessão viva (classe diferente de
`UNREACHABLE`) e para a própria sessão, lê o fim de cada `<projects>/*/<sessão>/subagents/agent-<id>.jsonl` e
classifica `AGENT_STALLED` (`tool_use` sem `tool_result` há mais de `--stall-min`, padrão 15), `AGENT_RUNNING`,
`AGENT_DONE` (texto final do assistente, ou a marca de interrupção pelo humano) e `AGENT_UNMEASURED` (transcript
ilegível ou sem entrada user/assistant). O comando pendente sai cortado em 120 caracteres nas três formas: linha
`agent` no `--tsv`, seção no `--markdown` (só os não terminados; os terminados em contagem) e linha por agente parado
no `--quiet` que fala. Os não terminados entram no sha do estado, então um agente que trava muda a batida.

Onde ficam os transcripts (medido no disco): `~/.claude/projects/<projeto>/<sessão>/subagents/agent-<id>.jsonl`, com
`agent-<id>.meta.json` ao lado (dá a `description`). O `/tmp/claude-<uid>/<projeto>/<sessão>/tasks/<id>.output` dos
agentes é symlink para o mesmo arquivo, então não é segunda fonte. Os `.output` sem prefixo `a` são de tarefa de shell
de fundo, não de agente, e ficam fora.

Doutrina: uma linha na cláusula 7 da `baton-doctrine` e um parágrafo no `/meta:baton` dizendo o que a classe mede (o
sintoma) e o que não mede (a causa, e se o processo ainda vive).

## Achados

1. **Bloqueava, curado: texto do meio do turno lido como fim.** O harness grava os blocos de uma resposta do
   assistente um por linha (`apiBlockIndex`), e o bloco de texto que antecede um `tool_use` sai numa linha própria
   com `stop_reason: tool_use`. Lido nesse instante, o agente que vai chamar uma ferramenta saía `AGENT_DONE`. Medido:
   72 linhas dessa forma nos transcripts de subagentes de uma sessão só. Cura: `AGENT_DONE` exige `stop_reason`
   diferente de `tool_use`; caso (m) da bancada com mutante.

## Mutantes

Cada caso novo da família `baton_pulse` reprova contra o mutante plantado no próprio caso:

- (i) parado com comando pendente: `if age > stall_s` vira `if False`.
- (j) pendente recente sai RUNNING: o teto vira `age >= 0`.
- (k) texto final sai DONE: o `tool_result` deixa de fechar o `tool_use`.
- (l) ilegível sai UNMEASURED: o retorno vira `AGENT_DONE`.
- (m) texto do meio do turno não é fim: a condição do `stop_reason` é removida.

## Limites declarados

- Mede o **sintoma**, não a causa. No replay, um dos três refutadores de hoje travou em `ls -la ~/.local/state/...`
  e não em `rm -rf $var`, então a causa não era uma só.
- Não sabe se o processo do subagente vive: o harness não expõe pid por subagente. Um agente morto no meio de uma
  ferramenta fica `AGENT_STALLED` enquanto a sessão dona estiver viva.
- Um prompt de texto do usuário limpa o que estava pendente. Uma mensagem que chegasse com uma ferramenta ainda aberta
  esconderia o pendente. Nos transcripts medidos, mensagem nova só chega na volta da ferramenta.
- Subagente de sessão `UNREACHABLE` fica fora: sessão morta não tem agente vivo para acusar.
- O `--tsv` lista todos os terminados (50 no dogfood). O markdown só os conta.
