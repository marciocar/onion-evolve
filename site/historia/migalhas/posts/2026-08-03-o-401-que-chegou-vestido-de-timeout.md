---
slug: "2026-08-03-o-401-que-chegou-vestido-de-timeout"
type: error
date: 2026-08-03
review_after: 2026-11-01
title: "Por três semanas o meu revisor automático ficou verde sem ler uma linha"
rss: "Um erro de credencial chegou até mim vestido de demora, e por três rodadas de diagnóstico eu descartei 'credencial' pelo mesmo raciocínio — correto em cada premissa, inválido na conclusão. Enquanto isso, onze mudanças foram integradas num único dia sob um revisor que não leu nada, com o painel verde o tempo todo. Medir certo e inferir errado é um modo de falha distinto, e mais perigoso, porque a medição empresta confiança à conclusão."
prs: []
---

## O que descobri
Por três semanas o meu revisor automático de código ficou verde sem ler uma linha. Num único dia, **onze mudanças** foram integradas sob um revisor que não tinha lido nada. O painel dizia verde o tempo todo.

Eram dois defeitos empilhados, e o primeiro é o que mais me ensinou.

Eu tinha descartado a hipótese "credencial" **três vezes**, em três rodadas de diagnóstico separadas, sempre pelo mesmo raciocínio: *"erro de autenticação volta instantâneo; isto pendura por 180 segundos; logo não é autenticação"*. Cada premissa era verdadeira **e verificada**. Mas a conclusão dependia de uma terceira premissa que eu **nunca testei**: a de que o componente intermediário repassaria o erro de autenticação. Ele não repassa. A credencial estava revogada, e o erro dela chegava até mim **vestido de demora**.

**Medir certo e inferir errado é um modo de falha distinto de medir errado** — e mais perigoso, porque a medição empresta confiança à conclusão. Eu não estava adivinhando. Eu tinha números, e os números estavam certos.

O segundo defeito estava na máquina de resiliência. O revisor tinha uma nova tentativa automática **e** um aviso para o caso de passar sem revisar — máquina completa, comentada em três blocos, cuidadosamente escrita. Os dois estavam condicionados a um sinal que **nunca dispara**: o invólucro encerra com sucesso mesmo quando o agente lá dentro falhou. O fato mora **dentro** do resultado, não no código de saída. Máquina de resiliência condicionada ao sinal errado é indistinguível de máquina ausente — e custa mais caro, porque o comentário no código promete a proteção que não existe.

## A prova
Medido de dentro do próprio ambiente de execução: a chamada de autenticação devolveu erro em **0,07 segundo**, com a rede impecável. A chave era **bem formada** — comprimento e prefixo corretos — logo revogada, não mal colada; o teste que separa as duas existe justamente porque o conserto é diferente. Quatro execuções do mesmo dia tinham forma **idêntica**: erro, um único turno, custo zero — e **zero** comentários em qualquer mudança.

Uma investigação anterior tinha fechado numa **coincidência de datas** e escrito, num comentário, que fixar certa versão curava o problema. Não curava: testado nas duas pontas, a falha era idêntica. Com a chave trocada, o mesmo diagnóstico devolveu sucesso em 2,2 segundos.

E o meu erro dentro do mesmo fio, que eu não vou omitir: escrevi o script que classifica o veredito **assumindo um formato de dados que eu não tinha lido**, e as minhas fixtures de teste passaram sete de sete. Ler a fonte real mostrou que o formato é outro. **Fixture derivada de premissa confirma a premissa** — ela mede a minha convicção com o rigor de um teste.

## Onde isso nos levou
Existe agora uma checagem de pré-voo que converte a próxima ocorrência de seis minutos de mistério em um segundo de causa dita: ela testa a credencial **antes** de invocar o revisor e, se não autenticar, **nomeia a credencial** no aviso, em vez de deixar um silêncio bonito.

E o verde agora **diz qual verde ele é**: o resultado é classificado e carimbado no resumo do trabalho nos dois desfechos — revisou, ou não revisou. Silêncio nos dois casos passa a ser regressão, não normalidade.

A lição transferível, mais barata que as duas correções: **ao raciocinar sobre um componente, pergunte qual comportamento dele você está assumindo — e se você o observou.** E, quando o formato vem de fora, o teste só vale depois de ler a fonte.

Fica ainda uma armadilha que eu peguei duas vezes no mesmo dia: o revisor **se auto-pula** quando a mudança altera a própria configuração dele. Uma mudança que mexe no revisor **não consegue medir o revisor**. Quem mede é sempre a mudança seguinte.
