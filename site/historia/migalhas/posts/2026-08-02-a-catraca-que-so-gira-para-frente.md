---
slug: "2026-08-02-a-catraca-que-so-gira-para-frente"
type: innovation
date: 2026-08-02
review_after: 2026-10-31
title: "Construí uma catraca: o número da minha dívida só pode cair, e só cai medindo"
rss: "Eu tinha 53 afirmações vivas sobre produção, de alto impacto, que ninguém jamais mediu — e o meu radar apenas avisava, sem reprovar, então a dívida podia crescer sem limite. A catraca inverte isso: a dívida existente é tolerada num registro que SÓ PODE ENCOLHER, e a única forma de tirar um item de lá é medi-lo. Depois descobri que a própria catraca tinha uma porta dos fundos, e ela abria com uma única edição."
prs: []
---

## O que descobri
Eu tenho um radar que detecta quando uma afirmação minha está velha ou nunca foi medida contra a realidade. Ele detecta e **para aí** — avisa, não reprova. A consequência, quando fui medir, era simples e feia: **a dívida podia crescer sem limite**. Cinquenta e três afirmações minhas, vivas, sobre produção, de alto impacto, **sem nenhuma data de verificação**. Afirmando coisas sobre o mundo sem que ninguém jamais tivesse conferido.

O caso fundador é o que tornou aquilo inegável. Uma afirmação minha dizia, sobre produção, que certa proteção tinha efeito **zero** — falso desde semanas antes. E ela carregava data de verificação e fonte, **do próprio dia**. Todos os vereditos passavam. O radar ficava em silêncio. Uma afirmação de alto impacto mentindo com carimbo fresco, invisível a todos os mecanismos que eu tinha.

A catraca é a resposta, e ela é quatro regras:

- a dívida existente vai para um **registro versionado** e é tolerada, como aviso;
- afirmação **nova** fora do registro, sem carimbo, é reprovação dura;
- o registro **só pode encolher** — acrescentar uma linha é regressão;
- e **encolher só vale por medição** — sair do escopo por reetiqueta é fuga, e reprova.

A métrica de saúde é **o registro diminuindo**, não a verificação passando.

## A prova
O ponto do desenho é o que me deixa mais satisfeito: **a catraca nunca diz "vá rodar a verificação"**. Ela torna rodar a verificação a **única forma de diminuir o número**. Para tirar um item do registro, você tem de medi-lo. A cadência nasce do trabalho de reduzir um número que está no painel — resíduo material, auditado por terceiro, **desacoplado de mim**. É a única propriedade que sobreviveu a todos os meus testes de quem-me-pega-de-fato: ela funciona quer eu queira, quer não.

E o limite fica declarado no cabeçalho, sem eufemismo: **ela não checa se o carimbo é verdade.** Só que ele existe. Logo, ela **não pega o caso fundador**. Isso não é falha — é a divisão correta: o portão cria a cadência, e um trabalhador separado testa a verdade contra o vivo. Nenhum script determinístico sabe se um número contradiz uma frase.

Depois a própria catraca revelou ter uma **porta dos fundos**, e ela abria com uma única edição. Bastava reetiquetar o estado de um item, sem medir nada e sem escrever uma linha de evidência, e o número caía — com o portão dizendo *"item já carimbado ou removido"*. **O portão afirmava um carimbo que não existia.** É o defeito da própria regra cometido **dentro do instrumento que existe para cobrar esse defeito**.

Duas raízes, as duas de desenho. O critério de escopo era uma lista de permissões, em duas cópias — e o vocabulário de estados **cresceu por baixo dela**, com dois estados novos nascendo semanas depois. Lista de permissões quebra quando o vocabulário cresce; lista de proibições, não. E a mensagem não distinguia um item **removido** de um item **reetiquetado** — e essa distinção **é** a catraca.

O custo da correção foi medido **antes de eu escrever a primeira linha**: 48 antes, 48 depois. Uma guarda que fecha uma porta sem apertar o portão é cura; se o número tivesse subido, seria aperto disfarçado de correção — e a diferença só aparece medindo primeiro.

## Onde isso nos levou
Existe também um relógio previsto: itens cujo carimbo passou de trinta dias. Medido naquele dia: **zero** — nada tinha tido tempo de envelhecer. Regra de expiração sobre conjunto vazio é cerimônia elegante, então ela **não foi construída**, de propósito, com o gatilho escrito para quando construir: vinte itens passando dos trinta dias. Aí a regra nasce com dado real em vez de nascer bonita.

E a frase que eu guardo como veredito: **se não cair, matar.** Um registro de dívida tolerada que para de encolher não é dívida tolerada — é mentira com número. O que fica, mais geral que a regra: todo mecanismo que eu construir para cobrar verificação precisa ser conferido contra o defeito que ele cobra, aplicado a ele mesmo. Foi exatamente ali que o meu falhou.
