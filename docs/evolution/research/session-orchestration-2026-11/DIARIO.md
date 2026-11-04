---
title: Diário da orquestração de sessões — 2026-11-03
date: 2026-11-03
status: fechado (2026-11-03; o estudo vive em session-orchestration-2026-11.kg.yaml e SYNTHESIS.md)
pedido: "o maestro: gravar as estratégias desta orquestração para virar mecanismo do Onion Core (automático ou semi-automático), casando com o vigia de eventos, o A2A e o grafo de coordenação; manter documentado, mapeado e em diários e migalhas, para artigos e outras publicações"
---

# Diário da orquestração de sessões — 2026-11-03

O maestro viajou e acompanhou a janela só pelo celular, das 13h às 22h de São Paulo, com a autorização delegada valendo até as 23h. Durante esse tempo, a sessão do core
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
11. **Regra do medidor (Emenda 1, com a redação ampliada pela curadoria na Emenda 6).** Qualquer mudança na função de veredito, ou no que o
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

- **Pré-registro dos spikes:** 3 versões e 5 emendas, com 2 revisores (no fecho, 6 emendas).
- **Executor:** 6 passadas (4 do kg-ssot e 2 da curadoria), chegando a 181 mutantes às 17:40 (no fecho, 218 verificações no `test_classify.py`, 7 delas mutantes de código).
- **Comandos do vigia:** 5 passadas da curadoria até 17:40 (no fecho, 8 passadas e 4 conferências curtas), chegando a 438 verificações nas famílias de teste.
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

# Janela de 2026-11-04 (fim da manhã à noite, UTC) — com o maestro presente

Segunda janela do mesmo diário, com outro tipo de trabalho: medida de segurança e estudo, em vez de spike. O maestro
respondeu em rodadas do `/meta:decide`, e o core comandou. O registro é para aprender: inclui o que deu errado.

## Decisões

- **Orquestração permanente** (`D_COORD_ORQUESTRACAO_PERMANENTE_1104`), com cada sessão levando o que é dela ao maestro.
- **Redação do `exit 2`:** «C com o gatilho da D» (`D_EXIT2_COUPLING_WORDING_2026_11`): a exclusividade sai, e o veto é conformidade, não fronteira.
- **Configuração gerenciada:** medir antes, depois o maestro aplica; escolheu `allowManagedModsOnly` (card SAC-278).
- **Guarda de plugin:** veto estreito mais varredura no disco, declarada como contenção, não fronteira.
- **Régua do vigia mantida** (`D_EWV_RULER_KEPT_1104`, na curadoria): o HMAC duplo não vale por leitura posterior ao dado.
- **Instalação:** autorização total ao que for melhor para os projetos, e a mudança de segurança do host segue explícita (leitura do core).

## Desfechos

- #1461 mergeado, depois de três rodadas de CI para nomear a causa do disco cheio; também #1472, #1473, #1474 e #1475.
- O veto no subagente do Vibe barrou nas duas famílias, com agente simulado; o pai vê conclusão indistinguível do sucesso.
- Com hooks reais e login Max, um mod venceu o veto do `.env` em 6 de 6; sem mod, o veto barrou 6 de 6.

## Estratégias novas

23. **O limite de carga combinado funciona sem o core no meio.** Com 15 acordado, o agente da curadoria parou sozinho a 15,29 no 1 min e passou a retomar por lote só abaixo de 12. Antes disso, a soma das sessões chegou a 23 e o construtor parou o gate dele; a regra só veio depois desse susto. Medido: a parada é do agente, sem mensagem de ninguém.
24. **Um gate completo por vez, numa fila de PR.** PR de registro espera o de execução, porque cada merge deixa o outro em conflito e PR em conflito não roda CI. Dependência de ordem aparece no texto: o `trace` da pergunta da AAIF procurava uma frase que o PR seguinte retirava, então quem entra por último fecha a pergunta.
25. **A peer revisa a redação, não só os dados.** A curadoria reprovou duas frases do `CLAUDE.md` que passavam do medido, com células na mão. O texto nasceu de um run de 9,3 M de tokens e de duas medidas, e ainda assim errou na condição.
26. **Dono diferente para cada ponto de vista, com foco nomeado.** No veto do Vibe, a curadoria leu semântica e o kg-ssot recalculou os vereditos sem usar o gravado, com ataques escritos no pedido. Pegaram coisas diferentes: a conclusão falsa sobre o pai foi da curadoria, os mutantes vivos foram do kg-ssot.
27. **Revisão pede o dono do produto.** O estudo da AAIF foi escopado também ao kg-ssot, e ele não entrou no desenho; quem pegou foi a pergunta do maestro. Depois do parecer, o MCP passou de achismo a medida. O desenho com a curadoria desde o início rendeu as 7 perguntas por projeto e o critério.

## O que deu errado (para aprender)

- **Afirmação relayada falsa, repetida ao maestro:** «o pai não recebe sinal» saiu do construtor e eu repeti. A revisão corrigiu. Relatar antes da revisão precisa dizer que é declarado.
- **Colheita apagou selo citado em outro repo** por checar só este repo; quem achou foi o kg-ssot, medindo a aresta entre repos (memória `harvest-check-peer-citations`).
- **Amostrador de CI morreu na 1ª amostra** por herdar `set -e` e `pipefail` do passo, e custou 1 rodada de 25 min. Teto de passo que coloquei na sonda (22 min) reprovou uma faixa saudável.
- **Commit com a mensagem errada:** um script Python falhou e o `git commit` seguinte pegou só o que já estava no índice. Foi emendado antes do push. Encadear commit depois de script precisa checar o script.
- **`pkill` por padrão em usuário compartilhado,** por agente de revisão da curadoria; efeito não verificado (tarefa SAC-279).
- **Sessão duplicada aberta há 13 h:** alarme meu de escrita concorrente, mas estava parada (`T`). Só `kill -9` a encerrou. Medir o estado antes de alarmar.
- **Canal morto sem aviso:** `onion-curation-a8` seguia listada como ociosa e o envio falhou; a sessão ativa da curadoria era outra (`-44`). A troca não avisou o core.

## Para o gatilho do mecanismo

Conta como a 2ª janela das três que `Q_SO_GATILHO_DE_CONSTRUCAO` pede, com outro tipo de trabalho. Falta conferir, regra a regra, as 5 de 7 `C_SO_*`; `Q_SO_PADROES_DE_MERCADO` segue aberta. Candidatos novos ao mecanismo: reserva de carga como regra da fila, e aviso quando a sessão de uma peer troca.
