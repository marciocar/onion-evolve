---
branch: feat/background-probe-replaces-prose-veto
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
findings_fixed: 5
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: o próprio subagente executor (SAC-140), sem revisor independente; ataques por dogfood no transcript real da sessão e no do subagente, com 6 mutantes por ops/mutate-and-restore.sh
nota: "passada adversarial feita pelo executor, não por um revisor independente. tokens e duration_min ficam em 0 porque não foram medidos (não é custo zero). O hash do diff é carimbado no pr-finalize."
---

# Passada adversarial: `feat/background-probe-replaces-prose-veto` (SAC-140)

Executa `D_VETO_DE_PROSA_APOSENTADO_PELA_SONDA` (guard-forge-2026-10): sai o veto Stop sobre a prosa
(`background-state-needs-evidence.sh`) e entra a sonda UserPromptSubmit `background-task-probe.sh`, que
mede o processo de cada tarefa de fundo sem notificação de término e injeta o estado. Ela nunca veta.

## Achados (4 reais, 4 curados nesta branch)

1. **Tarefa parada por TaskStop virava fantasma.** No 1º dogfood, no transcript real da sessão (45 MB),
   as duas únicas linhas "sem processo nem notificação" eram tarefas paradas por `TaskStop`. O harness
   não emite `<task-notification>` para elas, só o tool_result "Successfully stopped task: <id>".
   Curado: esse evento conta como término. Caso (f), mutante M4.
2. **Lançamento citado numa saída de ferramenta virava tarefa.** No 2º dogfood, no transcript do
   subagente, um `grep` meu que imprimiu linhas "Output is being written to:" de outro transcript gerou
   duas tarefas fantasmas. Curado: o lançamento só conta se o `<id>` aparece no campo
   `"backgroundTaskId":"<id>"` do toolUseResult. Só o harness escreve esse campo; citado, ele sai escapado
   e não casa. Caso (h), mutante M5.
3. **Varrimento que falha dizia "sem processo".** Com o `find` fora do PATH (ensaio sem jq), a sonda
   afirmou "sem processo nem notificação" para uma tarefa VIVA. Curado: rc 124/126/127 do
   `timeout find` vira "NÃO MEDIDO … estado DESCONHECIDO". O rc 1 é o normal (processo que some no
   meio, fd de outro usuário). Caso (i), mutante M6.
4. **A bancada abortava sob `set -e`.** O `wait` do filho morto devolve 143 e matou a suíte depois do
   último ✓ (a bancada acusou "ABORTOU ANTES DA SOMA"). Curado com `|| true` no `wait`/`kill` e com o
   rc capturado por `|| rc=$?`.

**Defeito de método (não conta como achado do produto):** dois mutantes da 1ª rodada (M5 e M6) quebravam
a SINTAXE da sonda (um `#` dentro do programa awk, um `#` que engolia o `esac`). Por isso reprovavam
todos os casos pela razão errada. Refeitos com uma troca que mantém a sintaxe válida, cada um reprova SÓ
o caso dele. Um mutante que derruba tudo não prova nada sobre o caso.

## Mutantes (ops/mutate-and-restore.sh, marcador ONION_MUTANTE, restauração conferida por hash)

| # | Mutante | Reprova |
|---|---------|---------|
| M1 | mapeamento PID desligado (`-lname '<dir>/*.ONION_MUTANTE'`) | (a) e (b) |
| M2 | limiar 10 → 60 min | (b) |
| M3 | notificação de término ignorada | (c) |
| M4 | TaskStop ignorado | (f) |
| M5 | exigência do campo harness-only desligada | (h) |
| M6 | rc do find sempre aceito | (i) |

## Limites declarados (não curados, e erram para o lado de calar)

- **Processo que redireciona a própria saída.** Observado ao vivo: a tarefa `b7cvw92ho` (a bancada com
  `> aff.log`) apareceu como `bash` em `do_wait`, CPU 0,0%, saída parada há 23 min, **sem SUSPEITO**.
  A folha medida é o wrapper, e `do_wait` fica fora de `READ_WCHAN`. O dado está certo, mas o processo
  que trabalha de fato não é visto.
- **Subagente.** A sonda vê só o que o transcript do payload lançou. O UserPromptSubmit é da sessão
  principal, então a tarefa de fundo de um subagente não entra. Rodada à mão sobre o transcript do
  subagente, a sonda funciona: o basename não bate com a sessão e ela cai no diretório do último
  lançamento. O próprio agente de fundo (`.output` symlink para o jsonl) não é medido.
- **CPU é a média da vida da folha**, não uma amostra. Quem trabalhou muito e depois travou escapa do SUSPEITO.
- **Notificação ou TaskStop CITADOS** em saída de ferramenta com o `<output-file>` exato de uma tarefa
  viva a tiram da conta. Isso erra para calar, e a citação precisaria do caminho exato.
- Tarefas de diretórios de sessões anteriores (transcript retomado) ficam fora: só entra o `tasks/` desta sessão.

## Tempo (medido em 2026-10-14/15, transcript de 45 MB, ~840–916 processos, load average 10–14)

- Sem tarefa pendente (sai antes do `find`): 169–363 ms.
- Com 1 tarefa viva: 465–531 ms com `cat` por campo de /proc. Trocado por leitura builtin `$(<…)`, caiu
  para 129–206 ms. O `find` sozinho mede 94–132 ms e tem teto de 0,5 s. O registro tem `timeout: 5`.

## Os `confirmed` do grafo editado (REGRA 87 (PR que EDITA um `.kg.yaml` enxergou os `confirmed` dele))

- **`E_ERA_A_UNICA_DAS_CINCO_SEM_MECANISMO`** é a razão de existir da guarda: a classe não tinha
  mecanismo e o gatilho social é cura nula. A aposentadoria **não** deixa a classe sem mecanismo de
  novo. Troca o mecanismo que julgava a frase (17 de 20 vetos sobre afirmação certa, 0 no defeito de
  origem) por um que mede o processo e injeta o dado antes da frase. O nó continua de pé, e a decisão
  troca o substrato, não a necessidade.
- **`E_BANCADA_VERDE_COM_ARTEFATO_INUTIL`** (bancada verde porque os casos não exercitavam o hook como
  o harness o invoca) é respondido por construção. Todos os casos entram por stdin JSON + transcript
  sintético na forma real do harness, com processos REAIS segurando o fd. O mapeamento por /proc, a
  metade "harvester" desta sonda, tem mutante próprio (M1).
- **`E_SUPERFICIE_MORTA_NA_CARGA_PELO_PROPRIO_EXEMPLO`** (só a invocação revelou) se repetiu aqui no
  bom sentido: os três achados do produto saíram de invocar a sonda no transcript real e no do
  subagente. Nenhum caso escrito antes os previa.

## Retirada

O registro Stop e o arquivo do `background-state-needs-evidence.sh` saem. A `lib/transcript-tail.py` fica,
porque o `rule-title-in-prose.sh` a usa. O caso (f) do `guard_forge` deixa de delegar ao selftest do hook
aposentado. A família nova é `background_task_probe` (9 casos). O hook não viajava em nenhum manifesto de
plugin, e a sonda também não viaja (core-only). Como um arquivo apagado não é citado por nenhuma família,
o `--affected` deste diff cai no failsafe "tudo".

## Rodada 1 do CI: o nome do wchan muda com o kernel

O caso (b), com um FIFO real, reprovou no CI: lá a espera em pipe aparece como `anon_pipe_read` (kernel mais novo),
e aqui (6.8) como `pipe_read`. A lista `READ_WCHAN` só tinha o nome local, então a sonda não marcava SUSPEITO no
runner. Real, curado: a família do pipe aceita o prefixo `anon_`, com o porquê no comentário. Caso novo (j) exige que
o padrão case os dois nomes e não case `do_wait`, sem depender do kernel que roda a bancada; mutante sem o `anon_`
reprova o (j). É a mesma classe de lista (o vocabulário do kernel), contida aqui porque o conjunto de esperas de
leitura é pequeno e o caso com processo real a cobre em cada runner.
