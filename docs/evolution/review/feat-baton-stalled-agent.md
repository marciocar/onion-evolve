---
branch: feat/baton-stalled-agent
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 11
findings_real: 11
findings_blocking: 5
tokens: 6959210
duration_min: 19
findings_fixed: 11
verdict: REJECTED_AND_FIXED
elenxo: false
reviewer: "1ª passada: o próprio agente de execução (1 bloqueio, curado); 2ª passada: refutador separado (subagente opus, que não escreveu o diff), REJECTED com 3 bloqueios e 10 de 10 mutantes vivos; 3ª passada: re-revisão do mesmo refutador sobre 3827fff2f, REJECTED com 1 bloqueio novo; tudo curado pelo agente"
nota: "tokens e duration_min são do refutador separado nas duas passadas dele, lidos do transcript (entrada com cache 6907242 + saída 51968; 19 min ativos, intervalos acima de 10 min descontados). Re-revisão sozinha: 2151764 tokens. Medidos depois da última cura: família baton_pulse 54/54 (27 casos, 19 novos, cada um reprovando contra o mutante dele), dogfood real contra os transcripts da máquina e replay dos três refutadores travados de 2026-11-12."
---

# Passada adversarial: `feat/baton-stalled-agent`

## O que muda

O `baton-pulse.sh` ganha a seção de subagentes (SAC-421, a tarefa do agente parado). Para cada sessão viva (classe
diferente de `UNREACHABLE`) e para a própria sessão, lê cada `<projects>/*/<sessão>/subagents/agent-<id>.jsonl` e os
da ferramenta Workflow em `subagents/workflows/<run>/`, e classifica `AGENT_STALLED` (`tool_use` sem `tool_result` do
mesmo id há mais de `--stall-min`, padrão 15), `AGENT_SILENT` (sem pendência, sem fim e sem escrita além do teto),
`AGENT_RUNNING`, `AGENT_DONE` (texto final, relatório entregue por `SubagentHandback` ou interrupção pelo humano) e
`AGENT_UNMEASURED` (transcript ilegível ou sem entrada user/assistant). O comando pendente sai redigido e cortado em
120 caracteres nas três formas: linha `agent` no `--tsv`, seção no `--markdown` (os terminados só em contagem) e linha
por agente em alerta no `--quiet` que fala. Só STALLED, SILENT e UNMEASURED entram no sha do estado.

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

2. **Bloqueava (refutador), curado: a cutucada escondia o travamento.** A mensagem do líder chega como linha `user`
   de texto («The coordinator sent a message while you were working») no meio da ferramenta, e o `pend.clear()` a
   tratava como prompt novo: o STALLED virava RUNNING para sempre (5 casos reais na varredura dele). Cura: só o
   `tool_result` do mesmo `tool_use_id` fecha a pendência; o que a abandona é uma NOVA mensagem do assistente (outro
   `message.id`), porque a API só aceita a próxima resposta depois de todos os resultados. Casos (n) e (r).
3. **Bloqueava (refutador), curado: RUNNING eterno.** O agente que entrega o relatório por `SubagentHandback` (14 casos)
   e o que se calou sem pendência (31 dos 34 não terminados que ele mediu) saíam RUNNING. Cura: o handback é
   `AGENT_DONE`; sem pendência, sem fim e sem escrita além de `--stall-min` é `AGENT_SILENT`, com o «Exit code 137» do
   último resultado nomeado. Casos (o) e (p).
4. **Bloqueava (refutador), curado: agentes de Workflow ignorados.** Eles moram em
   `<sessão>/subagents/workflows/<run>/agent-*.jsonl` (4744 na máquina) e não entravam. Cura: o caminho é lido, e o
   id sai como `<run>/<agente>`. Caso (s).
5. **Curado (M5 do refutador): o sha não provava que um agente parado muda a batida.** Caso (v): o `--quiet` com o sha
   de antes da parada fala e cita o STALLED.
6. **Curado (limite 5): o comando pendente vazava segredo e caminho.** Antes de exibir, `sk-`, `gh*_`, `Bearer`,
   `token=`/`secret=`/`password=` viram `[REDACTED]` (ampliada na re-revisão, achado 11) e `/home/<usuário>` vira `~`; no markdown a cerca de crase cresce
   (CommonMark) quando o comando tem crase. Casos (t) e (u).
7. **Curado (limite 7): o sha mudava a cada agente rodando ou terminando.** Só STALLED, SILENT e UNMEASURED (e a
   contagem deles) entram no sha. Caso (w). E o M9: na leva paralela o comando exibido é o PRIMEIRO pendente, o que
   segura os outros, com `(+N pendente(s))`; o replay mostra que o a19bb3f2 travou no `rm -rf "$(cat …)"`, não no `ls`
   que a 1ª versão exibia. Caso (q).

## Re-revisão (refutador, sobre 3827fff2f)

Veredito REJECTED com 1 bloqueio novo; os 3 antigos, o sha e a redação confirmados curados.

8. **Bloqueava, curado: o abandono por `message.id` novo errava nos dados.** Nos 6462 transcripts há 14 abandonos, e
   em 12 o `tool_result` do id largado chegou DEPOIS: depois de uma cutucada o harness roda dois fluxos do assistente
   ao mesmo tempo. Daí um falso DONE construível: X pendente, cutucada, m2 com Y e o resultado de Y, m3 com texto
   final. Cura: o abandono saiu; só o `tool_result` do mesmo id fecha, e pendência aberta nunca é DONE, nem com
   texto final. Os 2 abandonos legítimos ficam STALLED, falha ruidosa e preferível. O caso (r) virou a forma
   intercalada, e o mutante que recoloca o abandono morre.
9. **Curado: mutantes vivos M7, M8 e M3.** Casos (y) (o `--quiet` lista SILENT e UNMEASURED), (z) (os subagentes da
   própria sessão entram pelo `--self`) e (aa) (sem diretório de transcripts, a lacuna «NÃO MEDIDOS» sai). O
   diretório que existe e não se lê também vira lacuna, por `os.access`.
10. **Curado (cosmético): a coluna fonte do `--tsv`** mostra o caminho relativo real,
    `subagents/workflows/<run>/agent-<id>.jsonl`; o caso (s) confere.
11. **Curado em parte, e declarado como limite: a redação por lista.** Passaram a ser cobertos `x-api-key:`,
    `-u <u>:<x>`, `-p<x>`, `--password <x>`/`--password=<x>` e `NOME=valor` com token, secret, password ou `_key`
    no nome (inclui `AWS_SECRET_ACCESS_KEY=`). Caso (x).

## Mutantes

Cada caso novo da família `baton_pulse` reprova contra o mutante plantado no próprio caso:

- (i) parado com comando pendente: `if age > stall_s` vira `if False`.
- (j) pendente recente sai RUNNING: o teto vira `age >= 0`.
- (k) texto final sai DONE: o `tool_result` deixa de fechar o `tool_use`.
- (l) ilegível sai UNMEASURED: o retorno vira `AGENT_DONE`.
- (m) texto do meio do turno não é fim: a condição do `stop_reason` é removida.
- (n) a linha `user` de texto volta a limpar a pendência (o M1 do refutador, no sentido da cura).
- (o) o handback deixa de ser fim. (p) o ramo do SILENT é desligado. (q) o pendente exibido vira o último (M9).
- (r) a nova mensagem do assistente deixa de largar a pendência. (s) o caminho de Workflow é removido do glob.
- (t) a redação de segredo é desligada. (u) a cerca de crase volta a ser simples.
- (v) os agentes saem do sha (M5). (w) RUNNING entra no sha.
- (r) agora recoloca o abandono por `message.id` novo. (x) o padrão do `--password` deixa de casar.
- (y) o `--quiet` volta a listar só STALLED (M7). (z) a própria sessão sai da lista (M8). (aa) a lacuna é calada (M3).
- Também mudou o mutante de (k): o `tool_result` deixa de tirar o id da pendência (`pop` vira `get`).

## Limites declarados

- Mede o **sintoma**, não a causa. **Falso STALLED de ferramenta longa legítima:** o refutador mediu 28 casos acima
  de 15 min (bancada, mutantes, gates em primeiro plano); eles saem STALLED até a ferramenta voltar. `--stall-min` sobe
  o teto; a classe não distingue espera legítima de travamento.
- **Custo sem cache:** cada batida relê os transcripts inteiros das sessões vivas. O refutador mediu 15,6 s numa
  sessão de 625 MB; aqui, a batida inteira levou 16,2 s com ~75 MB de transcripts (o decide-census domina). Não há
  cache por mtime.
- **UNREACHABLE fora da medida:** os subagentes de sessão `UNREACHABLE` não são lidos (sessão morta não tem agente vivo
  para acusar, mas um farol fora da lista do harness esconde os agentes dela).
- Não sabe se o processo do subagente vive: o harness não expõe pid por subagente. Um agente morto no meio de uma
  ferramenta fica `AGENT_STALLED` enquanto a sessão dona estiver viva.
- **Abandono legítimo fica STALLED:** uma ferramenta largada de verdade (2 dos 14 casos medidos) nunca recebe
  `tool_result`, e o agente sai STALLED enquanto a sessão viver. É escolha: falso STALLED ruidoso em vez de falso DONE.
- **Redação por lista:** o que não está na lista passa (outro cabeçalho de credencial, senha posicional, token em
  URL sem `nome=`). O comando exibido serve para localizar o travamento, não é canal seguro para segredo.
- O `--tsv` lista todos os terminados (50 no dogfood). O markdown só os conta.
