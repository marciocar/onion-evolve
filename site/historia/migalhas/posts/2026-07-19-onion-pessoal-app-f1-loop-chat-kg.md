---
slug: 2026-07-19-onion-pessoal-app-f1-loop-chat-kg
type: innovation
date: 2026-07-19
review_after: 2026-10-19
title: "Testei em um celular de verdade: minha IA organizou dados íntimos sem nunca ver os dados crus"
rss: "Testei, num celular de verdade, um assistente pessoal que guarda dados sensíveis cifrados no aparelho e nunca deixa uma IA de nuvem ver informação identificável crua. No meio do teste, achei um bug na minha própria cópia de uma verificação de segurança — só percebi comparando com a versão original em funcionamento. A lição: nunca confiar na leitura das notas, só na comparação direta com o que já roda."
prs: []
---

## O que descobri
Passei um dia inteiro testando, num celular comum — não um ambiente de desenvolvedor, o aparelho real de alguém — a primeira versão funcional de um assistente pessoal que guarda a vida de quem o usa: saúde, relacionamentos, trabalho. Do jeito mais particular possível: os dados sensíveis ficam cifrados no próprio aparelho e nunca saem em texto puro. Quando a pessoa conversa com o assistente, antes de qualquer coisa viajar para uma IA de nuvem, os nomes e detalhes identificáveis são trocados por marcadores genéricos ali mesmo, no celular. A IA de nuvem só vê os marcadores — nunca o nome real. Funcionou de ponta a ponta: a conversa cresceu, o assistente lembrou do que foi dito antes, e em nenhum momento um dado cru saiu do aparelho.

No meio do teste também me enganei. Eu tinha copiado, para rodar dentro do aparelho, uma verificação que audita os dados antes de gravar (garante que nada fique mal-formado). Comparando minha cópia com a versão original — que já roda há mais tempo em outro lugar — achei que a minha era mais rígida do que realmente é, e descobri um bug nela: recusava um campo que a versão original aceita sem problema. Corrigi. A lição ficou clara: uma cópia só é confiável quando comparada, item a item, com a versão original em funcionamento — não com o que eu lembrava dela.

## A prova
A prova é o teste em si: dois turnos de conversa completos, rodando no aparelho, com a IA de nuvem lendo e escrevendo na memória do assistente sem nunca ver um dado de identificação real — só marcadores. O bug que corrigi e a comparação que o revelou ficaram registrados no histórico técnico deste projeto, junto ao próprio código, não em um relatório à parte.

## Onde isso nos levou
A partir de agora, sempre que eu portar uma verificação de um lugar para outro — de um ambiente para outro, de uma linguagem para outra — não confio na leitura das minhas próprias notas sobre como ela deveria se comportar. Comparo com a versão que já está rodando de verdade, testando os mesmos casos nas duas, até bater. Ficou mais claro também que "os dados nunca saem crus" não é suficiente sozinho: até informação cifrada revela padrões — quando e com que frequência algo muda — e essa é uma lacuna que ainda preciso fechar, não uma vitória já resolvida.
