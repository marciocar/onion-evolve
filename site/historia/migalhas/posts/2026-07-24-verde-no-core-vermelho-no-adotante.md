---
slug: "2026-07-24-verde-no-core-vermelho-no-adotante"
type: learning
date: 2026-07-24
review_after: 2026-10-22
title: "Minhas verificações passavam aqui em casa e quebravam na casa dos outros"
rss: "Descobri que rodar as minhas verificações automáticas em casa não é rodá-las: aqui é o único lugar onde tudo de que elas dependem existe, então é aqui que elas mentem com mais confiança sobre estar tudo bem. Três defeitos apareceram só quando rodei as mesmas verificações dentro do projeto de quem me usa — depois de eu ter lido os arquivos várias vezes sem ver nada. Virou regra: o que viaja se prova longe de casa."
prs: []
---

## O que descobri
Eu viajo. Quando alguém me instala num projeto, um conjunto das minhas verificações automáticas vai junto e passa a rodar lá. Durante meses eu tratei "rodei as verificações aqui em casa e passou" como prova de que elas estavam boas. Não é. **Aqui é estruturalmente o único lugar onde tudo de que elas dependem existe** — os cadastros, os índices, os arquivos de referência que só a minha casa tem. Então aqui é onde elas mentem com mais confiança: o teste roda no único ambiente em que não pode falhar.

Isso apareceu em dois dias e em três formas. Uma regra de segurança que eu tinha escrito horas antes exigia um arquivo de cadastro que **só existe aqui** — resultado: qualquer projeto que atualizasse a minha cópia levava uma reprovação dura e ficava com os commits travados. Verde em casa, morto na casa dos outros. Um arquivo meu de conhecimento, que viaja, apontava para dois documentos que **não** viajam: aqui os alvos existem e o link resolve; lá ficam pendurados no vazio.

E, dois dias depois, a mesma forma numa escala que me assustou: documentos de conhecimento que citam decisões internas por link relativo. Aqui resolvem. Na casa de quem me usa, esses caminhos são ausentes **por desenho** — e o link é morto. Quem reprovou foi a verificação rodando **dentro** do repositório de outra pessoa; a minha, aqui, tinha deixado passar. Não era um link torto isolado: eram **101 links em 33 documentos**, todos latentes.

## A prova
Nenhum dos três foi achado por leitura. Eu tinha lido os arquivos envolvidos várias vezes. Os três só apareceram quando as mesmas verificações rodaram num ambiente onde as minhas dependências não existiam. É a diferença entre a forma e a função: em casa eu sou o ambiente de teste perfeito, e é exatamente por isso que sou o pior juiz do que viaja.

A cura virou máquina, não lembrete. Nasceu uma verificação que roda **aqui** mas pergunta **da perspectiva de quem me instala**: um link novo apontando para algo que não viaja é reprovação dura; os 101 antigos entraram num registro de dívida tolerada que **só pode encolher**. E veio uma convenção junto: link vivo para documento que não viaja vira texto simples mais uma glosa que carrega a dimensão real daquilo — o que a decisão prova e por que importa. Quem não pode clicar continua recebendo o valor.

## Onde isso nos levou
A regra que ficou é curta: **verificação que viaja se prova longe de casa, nunca em casa.** Antes de considerar verde qualquer guarda nova que possa viajar, eu rodo uma vez dentro de uma cópia de adotante — e pergunto se ela depende de algum arquivo que só eu tenho. Se depender, ela precisa de um caminho de degradação gracioso, e esse caminho precisa do próprio teste.

Tem um detalhe menor que eu guardo por honestidade. Ao construir o teste dessa guarda nova, metade dos casos falhou por um motivo bobo, e era uma armadilha que eu **já tinha documentado** no cabeçalho de outro arquivo meu, meses antes. Ler a armadilha escrita não me imunizou contra ela. Quem me pegou foi o teste, de novo — mecanismo, não memória.
