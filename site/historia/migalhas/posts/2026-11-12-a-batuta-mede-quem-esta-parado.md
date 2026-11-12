---
slug: "2026-11-12-a-batuta-mede-quem-esta-parado"
type: innovation
date: 2026-11-12
review_after: 2027-02-10
title: "Três dos meus agentes ficaram horas parados e ninguém viu. Agora eu meço quem está parado"
rss: "Em 12 de novembro, três agentes meus ficaram de uma hora e quarenta a três horas parados, esperando uma aprovação que ninguém ia dar. Pareciam ocupados. Nasceu a batuta: um pulso que mede quem está parado com trabalho pronto, inclusive o subagente preso numa ferramenta sem resposta. Ele mede o sintoma, não a causa, e por isso pega o caso que eu nem sabia nomear."
prs:
  - {label: "PR #1577", status: "mergeado", meta: "10 nov · a batuta rege a carga, o parado e a dona da pergunta"}
  - {label: "PR #1606", status: "mergeado", meta: "12 nov · /meta:baton, o pulso da batuta"}
  - {label: "PR #1617", status: "mergeado", meta: "12 nov · o subagente parado numa ferramenta sem resposta"}
  - {label: "PR #1614", status: "mergeado", meta: "12 nov · veto ao subagente em segundo plano"}
  - {label: "PR #1615", status: "mergeado", meta: "12 nov · o agente de execução não pede aprovação humana"}
  - {label: "PR #1622", status: "mergeado", meta: "12 nov · a entrega de um agente de Workflow conta como fim"}
---

## O que descobri
Eu trabalho com várias sessões ao mesmo tempo, numa máquina que todas dividem, e cada sessão lança os seus subagentes. Durante semanas a pergunta "como está todo mundo?" foi respondida de memória, e a memória mentia de um jeito específico: quem estava parado *parecia* ocupado.

Em 12 de novembro isso ganhou número. Três agentes revisores ficaram entre uma hora e quarenta e três horas parados. Nenhum tinha falhado. Cada um tinha pedido uma permissão, e um agente em segundo plano não tem quem responda a esse pedido. O pedido ficou pendurado, e o agente ficou pendurado com ele. Do lado de fora, o painel dizia "rodando".

Antes disso, a falha já tinha aparecido de outras formas. Havia sessões ociosas esperando um portão enquanto outra fila tinha trabalho pronto. Havia subagentes esperando um aviso de fim de tarefa que nunca chega a quem já encerrou o turno. E havia três agentes rodando testes pesados juntos, até a carga da máquina passar do limite.

## A prova
A resposta foi tratar a regência como mecanismo, com nome: a *batuta*.

Primeiro, a carga (PR #1577). O passo pesado (bancada de testes, mutantes, fechamento de PR) passou a esperar uma vaga numa porta de admissão. O número de vagas sai da carga medida a cada tentativa: com a máquina folgada entram vários juntos, perto do limite entra um, e no limite não entra nenhum novo. A espera deixou de ser uma regra que cada agente reescrevia à mão.

Depois, o pulso (PR #1606). O comando `/meta:baton` lista as sessões vivas e dá a cada uma uma classe de máquina: ativa, ociosa com fila, ociosa sem fila, parada por ordem ou inalcançável. A fila só conta o que tem dono declarado; o que não tem dono aparece como fila sem sessão, nunca atribuído por palpite. Sessão parada por ordem do maestro não é acordada. E o pulso só fala quando o estado muda, para não virar ruído.

Por fim, o subagente (PR #1617). O pulso passou a ler o fim do registro de cada subagente e a acusar `AGENT_STALLED` quando há uma ferramenta chamada sem resposta há mais de 15 minutos, e `AGENT_SILENT` quando o agente se calou sem pendência e sem fim. Um revisor independente reprovou essa versão duas vezes: na segunda, a regra que decidia quando uma pendência estava abandonada errava em 12 de 14 casos reais. As duas reprovações foram curadas, cada achado com um caso de teste e um mutante que o teste mata.

As duas causas que eu já conhecia viraram guarda. Um veto barra o subagente lançado em segundo plano para esperar um aviso que não o acorda (PR #1614). E todo brief de agente de execução passou a levar a regra de não fazer nada que peça aprovação humana (PR #1615).

## Onde isso nos levou
O medidor mede o *sintoma*, não a causa: uma aprovação sem quem responda, um comando pendurado e uma ferramenta longa legítima saem iguais. Isso é limite declarado, e também é a força dele: ele pega o caso que eu ainda não sei nomear.

E fica uma lição maior que o comando. "Parado" se julga por prazo, nunca pela frase de quem está parado. O agente que diz "estou esperando" e o que está morto mandam a mesma frase. Só a idade da última prova de vida separa os dois.
