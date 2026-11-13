---
description: "Doutrina da batuta: a orquestração de sessões e agentes numa máquina compartilhada vira mecanismo (carga, parado, dona da pergunta, o pulso). Fragmento canônico; as superfícies referenciam."
---

# 🎼 Doutrina da batuta — quem rege as sessões é o mecanismo, não a memória de quem rege

**Por que existe (2026-11-10).** O maestro cobrou várias vezes: «tem gente parado e tarefa pela metade e peça
faltando, falta a batuta». Ele selou «Batuta primeiro» em 2026-11-09 (nó `D_MD_EVOLUTION_FIRST_BLOCK_BATUTA_1109`
de `docs/onion/graph/maestro-decisions-1109b.kg.yaml`). No dia seguinte, a falha se repetiu três vezes:
- sessões ociosas, porque o trabalho seguinte foi gateado sem trabalho para o meio-tempo;
- subagentes cuja espera em segundo plano nunca acordou;
- carga de 16 a 19 com três agentes rodando bancada e mutantes juntos.

O estudo e o diário das janelas vivem em `docs/evolution/research/session-orchestration-2026-11/` (core-only).

## Cláusulas

1. **Passo pesado passa pela porta de admissão.** Bancada, mutantes e fechamento de PR esperam a carga e uma das
   **N vagas de passo pesado** da máquina pelo lease de carga do core. A bancada e o harness de mutantes chamados
   direto se re-executam sob ele, e o `pr-finalize` pega uma vaga sempre. **N se deriva da carga** a cada tentativa:
   N = piso((12 − load) / 2), entre 1 e 4, com 12 sendo a retomada da régua selada. N limita os **donos**: entra
   quem chega com menos de N vagas tomadas, contadas todas sob uma trava de admissão. Com carga baixa entram vários
   juntos; perto de 12, um só; na régua, nenhum novo entra, nem quando uma vaga se solta durante a espera. A vaga
   única serializava demais: às 13:35 UTC de 2026-11-10 havia 4 na fila com load 3,5 em 8 CPUs. O modo sem execução
   da bancada (`--list`, `--map`, `--dry-run`, `--checkpoint`) não espera vaga. Pressão de CPU ilegível com o sinal
   ligado é «não medido», e a admissão cai só na carga. Espera própria (`until load < N`, `flock` num arquivo do
   scratchpad) é a regra repetida à mão que diverge. A régua (15, retoma abaixo de 12, PSI de CPU 30) é decisão
   do maestro (`D_SO_LIMITES_DERIVADOS_DO_LEASE_1106`), e a forma é a de mercado: `flock` do kernel mais admissão
   por carga, como o `parallel --load` e os slots por recurso do Temporal. A trava é de **eficiência**, não de
   correção (Kleppmann): por isso não leva fencing token.
2. **Parado se julga por prazo, nunca pela frase.** O medidor do `/meta:decide` (`decide-census.sh`) dá a cada
   worktree com pendência e a cada PR aberto a **idade da última atividade**: a data de **autor** do commit (rebase e
   amend renovam a do committer), o arquivo tocado e o `updatedAt` do PR.
   A partir de `--idle-hours` (4 h por padrão) o estado diz PARADO. É o heartbeat timeout do mercado (Temporal,
   SQS, Airflow) com a prova que já existe no git e no forge. Quem espera o maestro também envelhece: PARADO é
   idade, não culpa.
3. **Toda pergunta ao maestro tem uma sessão dona.** Antes de perguntar, a sessão reserva a chave
   `<repo>#<ID do nó>` em `.claude/utils/orchestration/maestro-ask.sh`. O `<repo>` é o nome da pasta do checkout
   principal do repo dono do nó (`onion-evolve` no core; num adotante, a pasta dele), o mesmo que o censo usa para casar a linha `seal`. Se a chave já tem dona viva, o rc é 3:
   não se pergunta de novo, leva-se o id a ela. A forma é a do `dedup_key` do PagerDuty e do `alias` do Opsgenie,
   com no máximo uma aberta. O prazo é de 24 h por padrão. A vencida não troca de dona sozinha: quem lê o censo
   assume com `--takeover`, e o assumir fica no `resolved.log`. Ack não é resolução: só o `release` fecha. A
   **dona é o id da sessão** (`--session`, ou por padrão o `CLAUDE_CODE_SESSION_ID`), e o `--owner` é só o rótulo. Com
   o nome livre, duas sessões chamadas `core` se renovavam uma à outra. Sem id, a reserva é recusada. O censo usa o
   mesmo id como «eu».
4. **Sinal sem ack é pendência.** O censo lê o estado da campainha (`doorbell-state.py`) e põe os sinais sem ack
   na mesma lista dos fios em voo.
5. **Espera de agente é em primeiro plano e com teto.** O aviso de fim de tarefa de fundo não acorda um subagente
   que encerrou o turno (memória da casa, quatro casos em 2026-11-05). O brief pede `timeout` em primeiro plano. A
   sessão principal confere o PID antes de acreditar em «estou esperando».
   O ajudante `bash .claude/utils/orchestration/agent-brief.sh <brief>` monta o brief final com o cabeçalho do preâmbulo e essa linha copiada dele.
6. **A batuta tem dono do resultado.** Mecanismo sem quem responda pelo todo deixa gente parada e tarefa pela metade:
   em 2026-11-10, perguntado como estava a batuta, o core respondeu carga de CPU, e ninguém a segurava. Quem assume
   declara em uma frase o resultado e o critério de pronto, decide o que é reversível e registra, identifica o próximo
   passo sem esperar ser chamado, e entrega verificado, com cada pendência com dono. Escalar é trazer diagnóstico e
   recomendação, nunca só a pergunta. **Firmeza nunca é contornar veto:** bloqueio de guarda, deploy, merge em repo
   alheio, gasto e o que muda o objetivo seguem indo ao maestro, e um caminho alternativo que passa por fora da guarda
   é o defeito, não a persistência. **A exceção é o ato delegado por selo, e só na forma dele** (2026-11-13,
   `D_DELEGATE_*_1113`): o merge em repo da família por `ops/pr-merge-verified.sh --foreign-repo`, o deploy do site (core-only)
   por `ops/deploy-site.sh deploy --verified-pr <N>` e o update do bridge e a persona do Slack (install, start, (core-only)
   verify) pela cópia de root do sudoers em `/usr/local/lib/onion-ops`. Esses a batuta toca sem esperar, porque o
   script confere as condições do selo e recusa sozinho. Recusou, a batuta não procura outra forma: leva ao maestro
   o motivo que o script imprimiu. O push de porta segue com ele (`D_DOOR_PUBLISH_STAYS_WITH_MAESTRO_1113`).

7. **O pulso da batuta (baton) mede quem está parado com trabalho pronto, e fala só quando muda.** Pedido do maestro
   em 2026-11-12: as sessões ficavam ociosas esperando algo, com trabalho necessário em outra fila. O
   [`/meta:baton`](../meta/baton.md) roda o medidor `.claude/validation/baton-pulse.sh`, que lista as sessões vivas do
   repo e da família (a lista de peers do harness e os faróis) e dá a cada uma uma classe de máquina: `ACTIVE`,
   `IDLE_WITH_QUEUE`, `IDLE_NO_QUEUE`, `PARKED` ou `UNREACHABLE`. Ociosa é idade (20 min sem prova de atividade no
   transcript ou no farol), como na cláusula 2. **A fila vem só de dono declarado:** nó `open` com `owner:`, pergunta
   reservada pela sessão, PR da branch dela. O que não tem dono declarado sai como «fila sem sessão casada», nunca
   atribuído por palpite. **Quem responde é a sessão:** o medidor mede, e a sessão que segura a batuta pergunta a cada
   sessão viva o estado em 3 linhas, como na memória da casa («como estão as sessões» se pergunta, não se lembra).
   **Quando fala:** o gatilho principal é evento (fim de tarefa, campainha, PR mergeado ou vermelho, resposta de
   sessão), com batimento de reserva de 20 a 30 min no `/loop`; a batida sem mudança (o sha do estado igual ao da batida anterior)
   sai em uma linha e se recolhe, para não virar fadiga de alerta. **É nível 0** da escada selada (`D_AUTOMATION_LEVELS_0_TO_2_SCHEDULED_1111`): só mede e
   lê. **Parada por ordem não se acorda:** `PARKED` vence qualquer outra classe e não recebe mensagem; um `parked.tsv`
   ilegível é lacuna e fail-closed (`PARK_UNMEASURED`, sem oferta), nunca «ninguém parado». **Puxar, não
   empurrar:** a sessão ociosa com fila recebe, no máximo, a oferta do que já é dela (a fase 2, desenhada e não
   construída); quem pega é ela ou o maestro. **Subagente parado (SAC-421):** o pulso lê o fim do transcript de cada
   subagente das sessões vivas (inclusive os de Workflow) e acusa `AGENT_STALLED` quando há `tool_use` sem `tool_result`
   do mesmo id há mais de 15 min, e `AGENT_SILENT` quando o agente se calou sem pendência e sem fim; mede o SINTOMA, não a
   causa (aprovação sem quem responda, comando pendurado, harness travado e ferramenta longa legítima saem iguais), e não
   sabe se o processo do subagente ainda vive.

8. **Toda peça estratégica tem sessão dona e patrocinador humano; peça sem dono é aviso, nunca bloqueio.** Selado pelo
   maestro em 2026-11-12 (`D_BACKBONE_OWNER_1112`), no molde do kg-ssot: a peça é o membro com `piece: true` no
   `docs/evolution/federation/members.yaml`, com `owner_session` (o NOME da sessão Onion que a defende) e
   `sponsor: maestro`. O `kind:` segue sendo a natureza do membro (a peça continua adotante). O dono se resolve em
   **ordem fixa, parando na primeira que responde:** `owner_session` do members.yaml, depois o `owners.tsv` do estado
   da batuta (a linha cujo rótulo é o id da peça), depois a sessão do core, como último recurso e com aviso. O pulso
   casa pelo **nome** da sessão, nunca pelo ref `[xxxx]`, porque a retomada troca o ref. Ele dá a cada peça uma
   classe: `PIECE_OWNED`, `PIECE_UNOWNED` (nenhuma sessão viva com aquele nome), `PIECE_OWNER_NAME_MISMATCH` (há sessão
   viva no repo da peça com outro nome: um desencontro de nome não é dono ausente) e `PIECE_UNMEASURED` (sem a lista
   de peers não há nome a casar). Cada aviso traz o **card de arranque**, o comando que abre a sessão nomeada no repo
   da peça, como texto: o pulso nunca abre sessão. Abrir é ato do maestro. As três formas vêm do mercado
   (dono obrigatório que aponta entidade registrada, do `spec.owner` do Backstage; ordem fixa de resolução, do Spotify
   Portal AI Explorer; patrocinador humano ao lado do dono, do Entra Agent ID). O mercado não tem nome para «agente
   dono de repo», e esse desenho é do Onion (`docs/evolution/research/agent-repo-ownership-2026-11/`).

## O que ela NÃO promete (fronteira declarada)

- **O pulso não vê o que o harness e o git não veem.** Sem a lista de peers, a classe sai só pela idade do farol, e uma
  sessão que espera um processo longo em primeiro plano sai ociosa. O rótulo que casa `owner:` com sessão é derivado do
  nome e da pasta ou declarado em `owners.tsv`; o que não casa fica sem sessão, dito. Nada disso vale para outra máquina.
- **O pulso não grava nem oferta.** A medição de horas ociosas com fila (o TSV de pulsos) e a oferta à sessão são a
  fase 2; viajar às portas é a fase 3.
- **Não despacha.** O censo lista e diz quem age; mandar trabalho de uma sessão a outra é o degrau 3
  (`D_SO_MECANISMO_EM_DEGRAUS`), e o rascunho da próxima fila é o degrau 2, com gatilho próprio
  (`Q_SO_GATILHO_DE_CONSTRUCAO`).
- **Não é teto do sistema operacional.** cgroup, slice e timer do systemd são postura do host, decisão do maestro.
  Quem não passa pelos chamadores (um processo pesado rodado à mão fora da bancada, do harness e do
  `pr-finalize`) segue sem admissão.
- **A vaga é por uid, e esse é o custo.** As vagas moram em `/run/user/<uid>/` (ou `/tmp/…-<uid>`) e valem para
  **toda sessão deste usuário** nesta máquina: core, peers e agentes dividem as mesmas N. Outro usuário (uma equipe
  com conta própria) não entra na conta dela, e a carga que ele gera só aparece pelo load. Outra máquina não vê nada.
- **A dona separa sessões, não agentes.** Medido: um subagente herda o `CLAUDE_CODE_SESSION_ID` da sessão-mãe. Por
  isso renovar e fechar exigem o mesmo nome e a mesma sessão. Um agente que se apresenta com outro nome na mesma
  sessão recebe «já tem dona» (rc 3), mas o id sozinho não o separa da mãe: o nome é o que separa.
- **A contagem de donos vale entre versões novas.** Um `load-lease.sh` da versão anterior, noutra worktree, não pega a
  `admit.lock` e só tenta as vagas 0 a N−1. Ele pode furar a contagem até todas as worktrees subirem para a `main`.
- **Parado só vê o que o git vê.** Um agente vivo que escreve só em arquivo ignorado ou fora da worktree sai PARADO
  falso. O `updatedAt` do PR sobe também com bot e CI, e um PR parado pode sair «em voo».
- **Não junta perguntas iguais com chaves diferentes.** A identidade é a chave escolhida por quem reserva, como no
  mercado.
- **Não mede a sessão viva sem pendência.** Uma sessão ociosa com a worktree limpa e sem PR não deixa rastro no
  git: o censo não a vê, e o farol de sessão (`session-beacon.sh`) só diz que ela existe.

## 🔗 Referências

- Medidor (peça 3): `.claude/validation/decide-census.sh`, com as linhas `ask` e `signal` e o estado PARADO
- Registro de pergunta: `.claude/utils/orchestration/maestro-ask.sh`
- Bancada (peça 7): `run_load_lease_selftests` (porta de admissão), `run_maestro_ask_selftests`, `run_batuta_census_selftests`, `run_baton_pulse_selftests` (o pulso)
- Pulso (cláusula 7): comando [`/meta:baton`](../meta/baton.md) e medidor `.claude/validation/baton-pulse.sh`
- Colheita de mercado (core-only): `docs/evolution/research/session-orchestration-2026-11/data/market-supervision-2026-11-10.md`
