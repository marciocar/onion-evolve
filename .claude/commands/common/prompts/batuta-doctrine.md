---
description: "Doutrina da batuta: a orquestração de sessões e agentes numa máquina compartilhada vira mecanismo (carga, parado, dona da pergunta). Fragmento canônico; as superfícies referenciam."
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

1. **Passo pesado passa pela porta de admissão.** Bancada, mutantes e fechamento de PR esperam a carga e a
   **vaga única** da máquina pelo lease de carga do core: a bancada e o harness de mutantes chamados direto se
   re-executam sob ele, e o `pr-finalize` pega a vaga sempre. Espera própria (`until load < N`, `flock` num arquivo
   do scratchpad) é a regra repetida à mão que diverge. A régua (15, retoma abaixo de 12, PSI de CPU 30) é decisão
   do maestro (`D_SO_LIMITES_DERIVADOS_DO_LEASE_1106`), e a forma é a de mercado: `flock` do kernel mais admissão
   por carga, como o `parallel --load` e os slots por recurso do Temporal. A trava é de **eficiência**, não de
   correção (Kleppmann): por isso não leva fencing token.
2. **Parado se julga por prazo, nunca pela frase.** O medidor do `/meta:decide` (`decide-census.sh`) dá a cada
   worktree com pendência e a cada PR aberto a **idade da última atividade** (commit, arquivo tocado, `updatedAt`).
   A partir de `--idle-hours` (4 h por padrão) o estado diz PARADO. É o heartbeat timeout do mercado (Temporal,
   SQS, Airflow) com a prova que já existe no git e no forge. Quem espera o maestro também envelhece: PARADO é
   idade, não culpa.
3. **Toda pergunta ao maestro tem uma sessão dona.** Antes de perguntar, a sessão reserva a chave
   `<repo>#<ID do nó>` em `.claude/utils/orchestration/maestro-ask.sh`. O `<repo>` é o nome da pasta do checkout
   principal do repo dono do nó (`onion-evolve` no core; num adotante, a pasta dele), o mesmo que o censo usa para casar a linha `seal`. Se a chave já tem dona viva, o rc é 3:
   não se pergunta de novo, leva-se o id a ela. A forma é a do `dedup_key` do PagerDuty e do `alias` do Opsgenie,
   com no máximo uma aberta. O prazo é de 24 h por padrão. A vencida não troca de dona sozinha: quem lê o censo
   assume com `--takeover`, e o assumir fica no `resolved.log`. Ack não é resolução: só o `release` fecha.
4. **Sinal sem ack é pendência.** O censo lê o estado da campainha (`doorbell-state.py`) e põe os sinais sem ack
   na mesma lista dos fios em voo.
5. **Espera de agente é em primeiro plano e com teto.** O aviso de fim de tarefa de fundo não acorda um subagente
   que encerrou o turno (memória da casa, quatro casos em 2026-11-05). O brief pede `timeout` em primeiro plano. A
   sessão principal confere o PID antes de acreditar em «estou esperando».

## O que ela NÃO promete (fronteira declarada)

- **Não despacha.** O censo lista e diz quem age; mandar trabalho de uma sessão a outra é o degrau 3
  (`D_SO_MECANISMO_EM_DEGRAUS`), e o rascunho da próxima fila é o degrau 2, com gatilho próprio
  (`Q_SO_GATILHO_DE_CONSTRUCAO`).
- **Não é teto do sistema operacional.** cgroup, slice e timer do systemd são postura do host, decisão do maestro.
  Quem não passa pelos chamadores (um processo pesado rodado à mão fora da bancada, do harness e do
  `pr-finalize`) segue sem admissão.
- **Não vê outra máquina.** A vaga e o registro de perguntas são por usuário nesta máquina; a sessão do notebook
  não os enxerga.
- **Não sabe qual sessão é «eu».** Sem `--self <dona>`, o censo mostra a reserva da própria sessão como `outro-dono`,
  com o nome da dona na linha.
- **Não junta perguntas iguais com chaves diferentes.** A identidade é a chave escolhida por quem reserva, como no
  mercado.
- **Não mede a sessão viva sem pendência.** Uma sessão ociosa com a worktree limpa e sem PR não deixa rastro no
  git: o censo não a vê, e o farol de sessão (`session-beacon.sh`) só diz que ela existe.

## 🔗 Referências

- Medidor (peça 3): `.claude/validation/decide-census.sh`, com as linhas `ask` e `signal` e o estado PARADO
- Registro de pergunta: `.claude/utils/orchestration/maestro-ask.sh`
- Bancada (peça 7): `run_load_lease_selftests` (porta de admissão), `run_maestro_ask_selftests`, `run_batuta_census_selftests`
- Colheita de mercado (core-only): `docs/evolution/research/session-orchestration-2026-11/data/market-supervision-2026-11-10.md`
