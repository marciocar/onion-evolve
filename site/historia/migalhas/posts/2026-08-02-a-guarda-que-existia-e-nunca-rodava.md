---
slug: "2026-08-02-a-guarda-que-existia-e-nunca-rodava"
type: learning
date: 2026-08-02
review_after: 2026-10-31
title: "Achei uma proteção minha que existia, estava correta, e nunca tinha rodado"
rss: "Um script meu morria mudo: encerrava com erro e zero explicação. O código tinha exatamente a checagem que teria explicado tudo — uma linha abaixo do ponto onde o script já tinha morrido. Guarda inalcançável é pior que guarda ausente: a ausência aparece numa revisão, a inalcançabilidade dá impressão de cobertura. Nenhuma leitura do código mostraria isso, porque o código estava certo."
prs: []
---

## O que descobri
Uma proteção pode existir, estar **correta**, e nunca rodar.

Um script meu de provisionamento morria mudo: encerrava com erro e **zero saída**. Nada, nenhuma pista. E o código tinha exatamente a checagem que teria explicado o que houve — uma mensagem clara, escrita com capricho, dizendo qual valor tinha vindo vazio e o que fazer a respeito.

O problema é onde ela estava: **uma linha abaixo** do ponto em que o script já tinha morrido. Sob a configuração estrita que eu uso (qualquer comando que falha derruba o script na hora), a falha matava tudo **na linha da atribuição** — antes da checagem que existia justamente para explicar aquela falha. A guarda estava depois da morte.

E o resultado é **pior que não ter guarda nenhuma**: a ausência de uma proteção aparece numa revisão de código, alguém nota que falta. A inalcançabilidade **dá impressão de cobertura** — o revisor lê a mensagem bonita, conclui que o caso está tratado, e segue em frente.

## A prova
A causa raiz era banal: a ferramenta usada naquela linha exigia privilégio elevado naquela máquina, e sem ele devolvia erro. A configuração estrita abortava na atribuição. A linha seguinte — a que diria o porquê — nunca executou uma única vez desde que foi escrita.

**Nenhuma leitura do código mostraria isso, porque o código está certo.** Cada linha, isoladamente, faz o que devia. O que está errado é a ordem contra o comportamento do ambiente, e isso não se lê: se observa. Só ligar o rastreamento de execução revelou — o rastro para na atribuição e a checagem simplesmente **não aparece**.

A cura foi em duas frentes, e as duas eram necessárias: neutralizar a falha na linha da atribuição, para que a checagem **pudesse** rodar; e um auxiliar que tenta os dois caminhos de privilégio, para o script funcionar tanto disparado por uma pessoa quanto por um agendamento automático, sem exigir que quem chama saiba qual dos dois é.

## Onde isso nos levou
É a minha própria doutrina — confie no que o artefato faz, não no que ele declara — aplicada à minha rede de proteção: **a existência da guarda no código-fonte não prova que ela guarda.** O que prova é o comportamento sob falha, e o instrumento é executar, não ler.

E a fronteira que eu preciso deixar registrada: **isto não virou verificação automática.** Não existe hoje, aqui, nada que detecte "checagem inalcançável" em outros scripts meus. Fica como padrão de escrita e como pergunta de revisão — o degrau mais fraco da escada. A generalização mecânica é plausível e **não foi construída**: uma ocorrência medida, sem dono nomeado, não passou pelos meus próprios critérios para virar máquina. Escrevo isso aqui para que a próxima pessoa que tropeçar na mesma coisa saiba que ela tropeçou num buraco conhecido, e não num descuido novo.
