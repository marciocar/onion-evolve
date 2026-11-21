---
branch: feat/meta-restart
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: af0443c03ca616161f57dad5eaaa1f13e6cf7ee5443237811baf33352656d5b6
reviewed_code_sha256: 3033267816e859c177f36a8437e3d24c017239116172eca91f821f73d577fe65
findings_total: 22
findings_real: 22
findings_blocking: 7
findings_fixed: 16
tokens: 267000
duration_min: 23
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "revisor isolado (agente branch-code-reviewer que não escreveu o código), duas passadas: o artefato inteiro e depois só as curas"
nota: >-
  /meta:restart: reinício gracioso (drain) antes de atualizar ou reabrir o Claude Code, que mata os subagentes e as
  tarefas de fundo. 1ª passada: 16 achados, 7 bloqueiam. 2ª passada, só sobre as curas: os 7 curados (cada um
  conferido rodando o script), 5 limites novos, nenhum bloqueio. Depois, a bancada achou 1 defeito na sonda de fundo
  (curado aqui). tokens = soma das duas passadas do revisor
  (109.903 + 157.071), medida pelo harness.
---

# O drain que media o que não via e chamava de zero

O pedido nasceu de um dano medido: em 2026-11-21 uma atualização do Claude Code derrubou 5 agentes no meio de
pre-commit e CI, e a retomada foi à mão, um por um. A peça entregue é o `/meta:restart` e o seu medidor e escritor,
`.claude/utils/orchestration/restart-drain.sh`, que reusa o `baton-pulse.sh --tsv` (agentes) e a sonda
`background-task-probe.sh` (tarefas de fundo).

## 1ª passada: o artefato inteiro (REPROVADO, 7 bloqueios)

O revisor rodou o script contra sandboxes próprias e contra a sessão real, com estado descartável. Os bloqueios:

1. **O caso (f) da bancada reprovava contra o código intacto.** A fixture gravava o título com JSON espaçado e o script
   procurava por regex sem espaço. Cura: o título é lido como JSON (a linha `type: custom-title`, o último vence) e a
   fixture grava compacto, como o harness.
2. **Segredo vazava no bilhete.** A redação própria era mais fraca que a do baton-pulse (`Bearer`, `ghp_`, `sk-`,
   `x-api-key` passavam). Cura: o comando cru não é mais lido para o bilhete. O último passo é o `pendente:` do
   baton-pulse, já redigido pela lista dele; sem pendência, só ferramenta e arquivo. Caso (j) com mutante.
3. **Falha do medidor durante a espera saía rc 0 e esvaziava as tarefas.** Cura: a última medição boa fica e a saída
   é rc 5. Caso (k) com mutante.
4. **`--now` sem medir os agentes gravava «nenhum agente».** Cura: sonda as tarefas mesmo assim, escreve «agentes NÃO
   MEDIDOS», rc 5; o `--status` e o `--resume-check` mostram a lacuna, e este sai rc 5. Caso (l) com mutante.
5. **Na drenagem, o que não foi medido valia zero** (sessão com id errado, sonda ausente). Cura: medidor ou sonda
   ausente e transcript não achado recusam antes do marcador, rc 2. Caso (m) com mutante.
6. **Inventário stageado defasado** (122 contra 123). Cura: `/meta:inventory` depois do rebase e `lint --fix` na prosa.
7. **Comando de retomada com título sem validar** (um título real desta sessão, com espaço e parênteses, dava erro de
   sintaxe). Cura: o nome passa pelo padrão do `session-open.sh` e por `shlex.quote`; fora dele, `claude --resume <id>`
   dito. Caso (n) com mutante.

Dos limites da 1ª passada, foram curados também: agente não medido segura a espera (caso (o) com mutante), a pasta
padrão usa `XDG_STATE_HOME` como a batida, arquivos 0600, flags incompatíveis recusadas, marcador órfão e id de agente
de Workflow documentados.

## 2ª passada: só as curas (APPROVED_WITH_LIMITS, 0 bloqueios)

Os 7 bloqueios conferidos rodando o script, um a um. Os casos (j) a (n) não são decorativos: cada mutante tem âncora
única e derruba a asserção do seu caso. A falta de cobertura do agente não medido na espera virou o caso (o), e o
`--status` passou a dizer «agentes NÃO MEDIDOS» em vez de «0 agente(s)» quando há lacuna.

## Achado da bancada depois das passadas: a sonda de fundo engolia a tarefa viva

Rodando a família nova, os casos que dependem da tarefa de fundo reprovaram contra o código intacto. A causa estava na
sonda `.claude/hooks/background-task-probe.sh`, não no drain: a lista de términos chega ao `awk` pelo stdin e, numa
sessão **sem nenhuma tarefa terminada**, ela vem vazia; aí o `NR==FNR` vale também para o 2º arquivo, todo lançamento
vai para `done` e a tarefa viva some sem aviso. Nas sessões reais sempre há término, por isso ninguém viu. Cura: uma
linha sentinela antes da lista. Caso (m) novo na família `background_task_probe`, com mutante que tira a sentinela. A
mudança toca hook, então este PR não se merja sozinho.

## Limites declarados

- A redação é a lista do baton-pulse; `--token X` (com espaço) e `usuário:senha@` em URL passam. O bilhete é 0600,
  fora do repo, e o `restart.md` diz para não colá-lo sem ler.
- A bancada não exercita o passo com pendência e segredo (a redação é do baton-pulse, provada na família dele), nem a
  falha da sonda no meio da drenagem.
- A pasta padrão do drain e a da batida só concordam com o `BATON_STATE_DIR` padrão; com ele customizado, passe
  `ONION_RESTART_DIR` aos dois. Dito no `restart.md`.
- Não sabe se o processo de um subagente vive (o harness não expõe pid por subagente): mede o transcript.
- Que o id do agente sobreviva ao reinício e aceite `SendMessage` é o que se mediu em 2026-11-21; para o agente da
  ferramenta Workflow (`<run>/<id>`) não está medido.
- O marcador é aviso, não trava: nada barra um despacho com ele presente.
