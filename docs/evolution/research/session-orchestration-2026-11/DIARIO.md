---
title: Diário da orquestração de sessões — 2026-11-03
date: 2026-11-03
status: vivo (atualizado durante a janela; vira estudo com grafo no fim dela)
pedido: "o maestro: gravar as estratégias desta orquestração para virar mecanismo do Onion Core (automático ou semi-automático), casando com o vigia de eventos, o A2A e o grafo de coordenação; manter documentado, mapeado e em diários e migalhas, para artigos e outras publicações"
---

# Diário da orquestração de sessões — 2026-11-03

O maestro viajou e acompanhou a janela das 13h às 23h de São Paulo só pelo celular. Durante esse tempo, a sessão do core
orquestrou outras duas sessões peer na mesma VPS, a da curadoria e a do kg-ssot. Este diário registra **o que foi
feito e por quê**, para que a maquinaria aprenda com o caso. Ele não é relato de conversa.

## Papéis que emergiram

| Sessão | Papel | O que fez |
|---|---|---|
| core | orquestrador e construtor | fila, rodízio de CPU, executor dos spikes, comandos do vigia, PRs e merges do próprio repo |
| curadoria | dona da especificação e revisora adversarial | pré-registro do vigia (PLAN-E), julgamentos de semântica, revisão (Elenxo) em agente separado |
| kg-ssot | fornecedora de medida e revisora técnica | receita do modelo local, revisão de código reclassificando a partir do commit (`git archive`) |

Cada repo executa e faz merge só do que é dele. Mensagem de peer é informação, nunca aprovação do maestro.

## Estratégias, na ordem em que apareceram

1. **Rodízio de CPU por janela.** Os spikes do core rodam das 16:00 à 01:00 UTC. Nessa janela os peers seguram
   bancada cheia e workflow grande, e avisam antes de rodar algo pesado. A VPS é um recurso compartilhado, coordenado
   por um lock social declarado.
2. **Revisão cruzada em paralelo.** Duas sessões revisam o mesmo artefato com focos diferentes. Achado que aparece nas
   duas tem prioridade. O autor devolve um mapa de cada achado para o trecho que o cura (§9 e §9b do pré-registro).
3. **Pedido de ajuda direto entre peers.** É reforço do maestro. A curadoria e o kg-ssot se acionam sem passar pelo
   core, e só copiam o core quando o pedido toca a CPU na janela ou um nó do core.
4. **Proveniência entre repos.** Cita-se por `caminho@commit` mais `node_sha256`. Quem vai mudar um nó que outro repo
   fixou por hash avisa antes. O pin fica no commit do selo.
5. **Ritmo por evento.** O `/loop` dinâmico acorda com o fim de tarefa de fundo ou com mensagem de peer. O despertar
   de reserva é de 25 a 30 minutos.
6. **Merge pela espera de todos os check-runs do head.** A espera conta o total e os pendentes. O `--watch` não serve:
   sai cedo e o merge é recusado.
7. **Modelo stub para medir harness.** O comportamento de hook é do cliente, não do modelo. Um servidor stub
   compatível com OpenAI, que decide pelo conteúdo do pedido, transformou uma matriz que não cabia em 9 horas de CPU em
   minutos. O modelo real fica como braço de confirmação.
8. **Autorização pontual com validade e limites escritos na memória.** Ela expira às 02:00 UTC.
9. **Divisão entre especificação e construção entre repos.** A curadoria escreve o pré-registro e fixa o critério por
   sha256. O core constrói. Nomes e caminhos são negociáveis; campos e critérios não.
10. **Pré-registro revisado em iteração.** Foram a v1, a v2 e a v3 em cerca de uma hora. Cada revisão cita o arquivo do
    código instalado dos clientes, e não a documentação.
11. **Regra do medidor (Emenda 1, proposta da curadoria).** Qualquer mudança na função de veredito, ou no que o
    executor grava, aplicada a evidência já colhida põe a célula em INCONCLUSIVO e manda rodar de novo, para todas as
    células daquele executor. Isso separa «consertar o instrumento» de «mudar o critério depois do dado».
12. **Construção e revisão em paralelo.** O agente construtor recebe os achados novos por mensagem enquanto ainda roda.
13. **Reprodutibilidade provada pelo artefato commitado.** O kg-ssot reclassificou a partir do `git archive` e achou que
    o `*.log` do `.gitignore` da raiz tirava toda a prova do commit. A pasta de trabalho não prova nada.
14. **O lote em execução fica separado das correções do medidor.** Corrige-se o classificador e o agregador, nunca o
    executor, enquanto o lote roda, e depois se reclassifica pela evidência, que é determinística.
15. **O dono da especificação julga a semântica.** A curadoria julgou os pontos abertos da construção do vigia. Um
    princípio saiu daí: o log de medida não é controle de segurança, então não trava a entrada; o registro de envio é
    auditoria, então falha fechado.
16. **Revisão em três camadas.** A primeira é o desenho (pré-registro), a segunda o código (executor), a terceira o
    processo (registro e procedência). O kg-ssot fechou o código e reprovou o processo: havia um veredito criado depois
    do dado, um hash fora de commit e procedência sobrescrita. Reclassificar acrescenta, nunca sobrescreve.
17. **Frase de veredito vem do instrumento.** A frase «o real confirma o stub» saiu de uma comparação à mão, porque o
    agregador não pareava entre lotes (achado A1 da curadoria). Toda frase de veredito na SYNTHESIS cita o campo do
    agregado que a produz, ou diz que foi feita à mão e com quantas células.

## Medida (até 17:40 UTC)

- **Pré-registro dos spikes:** 3 versões e 5 emendas, com 2 revisores.
- **Executor:** 6 passadas (4 do kg-ssot e 2 da curadoria), chegando a 181 mutantes.
- **Comandos do vigia:** 5 passadas da curadoria, chegando a 438 verificações nas famílias de teste.
- **Achados reais pegos antes de qualquer veredito valer:** mais de 60.
- **O que mais pesou:**
  - três defeitos que dariam BARRA falso: o modo padrão recusando antes do hook, o push que não discriminava e a
    evidência ausente;
  - um gatilho que dispararia por ausência: a lacuna fechada por qualquer linha.

## Ligações com a maquinaria

- **Vigia de eventos (`event-watcher-2026-10`).** Os comandos de medida dele foram construídos neste mesmo dia, com a
  mesma revisão cruzada.
- **A2A.** O teste da ida e volta (`a2a-ida-e-volta-vps-notebook-2026-10`) também é orquestração entre máquinas.
- **Grafo de coordenação (`coordenacao-sessoes-2026-10`).** A fila desta janela vive nele.
- **Personas de vertical.** As sessões peer são personas longas, cada uma com o seu papel.

## Adendo das 18h UTC

18. **Revisão até a fronteira do segundo.** Na 6ª passada dos comandos do vigia, a curadoria passou dos casos de
    comportamento para os da régua: o mesmo segundo em três lugares (leitor, escritor e modo vigente), e o escritor e
    o leitor discordando na fronteira. Daí saiu uma invariante geral: toda recusa do escritor a um produtor oficial
    vira lacuna, por qualquer causa, e nunca some.
19. **Repetição prevista no pré-registro absorve o ruído de fronteira.** Uma célula do timeout do Vibe ficou 1 ms
    abaixo do piso de 5 s (4,999 s). Pela regra de até 6 repetições, a 4ª fechou a família em 3 de 3 válidas, sem
    mudar a régua.
20. **Rodada inteira de novo quando o instrumento muda.** Com o executor final, a matriz inteira rodou de novo (m2,
    121 células em cerca de 20 minutos) e reproduziu a m1 família a família. É a regra do medidor aplicada sem
    exceção, possível porque o stub torna a re-rodada barata.

## Adendo do fechamento (22h UTC)

21. **Quem cita revisa a fonte.** A revisão adversarial do kg-ssot sobre a própria citação achou dois exageros na
    SYNTHESIS dos spikes, já mergeada. O texto citava só um dos dois lotes reais, e afirmava uma hipótese que os
    dados não separavam, porque nenhum pedido passou de 900 s. O aviso veio com os números tirados da evidência,
    e o core conferiu nos logs antes de corrigir. A correção na fonte é barata quando o citador mede, em vez de só
    repetir.
22. **Fechar uma branch de medição custa mais que a medição parece.** O squash dos spikes passou por quatro paradas
    do pr-finalize: rastro do pré-registro e teto do grafo, re-revisão por código que mudou, sigla sem glosa e
    etiqueta longa. Cada uma é uma guarda que funcionou. O custo vem de as guardas rodarem em série, e roteiro de
    fechamento que antecipe as quatro é candidato a peça do mecanismo.
