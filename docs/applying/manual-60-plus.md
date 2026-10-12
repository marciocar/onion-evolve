# Onion: guia fácil

> Espelho em texto de [`manual-60-plus.html`](manual-60-plus.html), com a mesma substância.
> A versão para ler e imprimir é a HTML: letra grande, alto contraste e botões de tamanho de letra.
> **Rascunho do SAC-51, de 2026-10-12.** A nota para o revisor fica no fim deste arquivo.

Para organizar ideias, projetos e conversas com a ajuda do Claude.
Sem programação. Um passo de cada vez.

## Neste guia

1. Antes de começar: o que você precisa
2. Tarefa 1: preparar o aplicativo e instalar o Onion
3. Tarefa 2: guardar uma ideia sem perder nada
4. Tarefa 3: dividir um projeto grande em passos pequenos
5. Tarefa 4: resumir uma conversa ou reunião
6. Tarefa 5: criar um caderno para um assunto
7. Dicas para tirar o melhor
8. O que é o Onion, em uma página
9. Palavras novas, explicadas
10. Quando algo não funciona

---

## Antes de começar: o que você precisa

Você vai usar o **aplicativo do Claude**. Ele funciona no navegador (o site **claude.ai**) e no
computador (o programa **Claude**).

Você precisa de três coisas:

1. **Uma conta no Claude.** Com e-mail e senha.
2. **Um plano pago** (Pro, Max, Team ou Enterprise). No plano gratuito, o Onion não funciona.
3. **Uns 15 minutos** para a primeira vez. Depois fica rápido.

> **Faça a instalação no computador.** A tela é maior e fica mais fácil. Depois de instalado, o Onion
> também aparece no celular, na mesma conta.

---

## Tarefa 1: preparar o aplicativo e instalar o Onion

Você faz isto **uma vez só**.

> **Os nomes dos botões podem estar em inglês.** Neste guia, o nome aparece como está na tela, entre
> aspas. Se o seu aplicativo estiver em português, o nome pode aparecer traduzido.

### Parte A: ligar uma opção

**Passo 1.** Abra o Claude e entre na sua conta.
*O que você vai ver:* uma caixa grande para escrever, no meio da tela. À esquerda, uma barra com opções.
`[CAPTURA: tela inicial do Claude, com a caixa de mensagem e a barra lateral]`

**Passo 2.** Abra as configurações: **"Settings"**. Depois clique em **"Capabilities"**.
*O que você vai ver:* uma lista de opções, cada uma com um botão de ligar e desligar.
`[CAPTURA: página Settings > Capabilities]`

**Passo 3.** Ligue a opção **"Code execution and file creation"**.
*O que você vai ver:* o botão dessa opção muda de cor. Isso quer dizer que está ligada.
`[CAPTURA: a opção "Code execution and file creation" ligada]`
Se você usa o Claude pelo trabalho e a opção estiver bloqueada, peça ao responsável pela conta da
empresa para ligar.

### Parte B: instalar o Onion

**Passo 4.** Na barra da esquerda, clique em **"Customize"**. Depois clique em **"Plugins"**.
*O que você vai ver:* a página de complementos do Claude, com uma aba **"Discover"** e um botão **"Add"**.
`[CAPTURA: página Customize > Plugins]`

**Passo 5.** Clique em **"Add"**. Depois em **"Add marketplace"**.
*O que você vai ver:* uma janela pequena, pedindo um endereço.
`[CAPTURA: janela "Add marketplace" vazia]`

**Passo 6.** Escreva exatamente isto na janela, e confirme:

    marciocar/onion-plugins

*O que você vai ver:* a janela fecha. Os complementos do Onion passam a aparecer na lista.
`[CAPTURA: lista de plugins mostrando "Onion" e "Onion · Product"]`

**Passo 7.** Na lista, clique em **"Onion"**. Depois clique em **"Add"**.
*O que você vai ver:* a página do complemento, com abas. Ele passa a aparecer como instalado.
`[CAPTURA: página do plugin "Onion" depois de instalado]`

**Passo 8.** Volte para a lista. Clique em **"Onion · Product"**. Depois clique em **"Add"**.
*O que você vai ver:* o mesmo de antes. Agora os dois estão instalados.
`[CAPTURA: página do plugin "Onion · Product" depois de instalado]`
A lista mostra outros complementos do Onion (engenharia, design, conformidade). Eles são para equipes
técnicas. **Você não precisa deles.**

**Passo 9.** Volte para a conversa. Clique na caixa de mensagem e digite só uma barra: `/`
*O que você vai ver:* um menu com várias opções. Algumas mostram o nome **onion-product** ou **onion**.
Pronto: o Onion está instalado.
`[CAPTURA: menu da barra "/" mostrando opções do Onion]`

---

## Tarefa 2: guardar uma ideia sem perder nada

Para quando você tem uma ideia e quer deixá-la clara, com título e descrição.
Exemplo: um projeto de horta comunitária no prédio.

**Passo 1.** Comece uma conversa nova. Escreva a sua ideia do seu jeito. Por exemplo:

    Tenho uma ideia e quero organizar: fazer uma horta comunitária no meu prédio.

Se preferir escolher você mesmo: digite `/` e escolha **onion-product:collect**.
*O que você vai ver:* o Claude responde com perguntas. Por exemplo: para quem é, onde fica, o que você espera.
`[CAPTURA: primeira resposta do Claude, com perguntas sobre a ideia]`

**Passo 2.** Responda às perguntas com calma. Frases curtas bastam.
*O que você vai ver:* um **título** e uma **descrição** da sua ideia, escritos pelo Claude.
`[CAPTURA: título e descrição propostos]`

**Passo 3.** Leia. Se algo não estiver certo, diga. Por exemplo:

    Troque o título. E a horta é no terraço, não no jardim.

*O que você vai ver:* o texto corrigido.

**Passo 4.** O Claude pode perguntar sobre um "gerenciador de tarefas". Se você não usa um, responda:

    Não uso. Deixe o texto final aqui na conversa.

*O que você vai ver:* o texto final da sua ideia, pronto para copiar ou guardar.
`[CAPTURA: texto final da ideia]`

---

## Tarefa 3: dividir um projeto grande em passos pequenos

Para quando algo parece grande demais para começar.
Exemplo: organizar a festa de 70 anos de alguém da família.

**Passo 1.** Comece uma conversa nova. Escreva:

    Quero organizar a festa de 70 anos da minha irmã. Divida em etapas e passos pequenos.

Se preferir escolher você mesmo: digite `/` e escolha **onion-product:create-task-structure**.
*O que você vai ver:* o Claude pode fazer algumas perguntas primeiro. Por exemplo: a data, o número de convidados.

**Passo 2.** Responda às perguntas.
*O que você vai ver:* uma lista em etapas. Cada etapa tem passos menores dentro. Às vezes, também uma
ordem: o que fazer antes e o que fazer depois.
`[CAPTURA: lista de etapas e passos]`

**Passo 3.** Peça o que quiser mudar. Por exemplo:

    Está muito longo. Deixe só o essencial, em no máximo 10 passos.

*O que você vai ver:* uma lista mais curta.

**Passo 4.** Para guardar no papel, peça:

    Faça uma lista para eu imprimir, com um quadradinho para marcar cada passo.

*O que você vai ver:* a lista com quadradinhos. Você pode copiar ou imprimir.
`[CAPTURA: lista de passos com quadradinhos]`

---

## Tarefa 4: resumir uma conversa ou reunião

Para quando você tem anotações de uma reunião e quer saber o que foi decidido e quem ficou de fazer o
quê. Exemplo: a reunião de condomínio.

**Passo 1.** Tenha as anotações à mão. Pode ser um texto que você digitou, ou um arquivo no computador.

**Passo 2.** Comece uma conversa nova. Cole o texto na caixa de mensagem, ou anexe o arquivo com o
clipe ou o botão **"+"**. Antes do texto, escreva:

    Estas são as anotações da reunião de condomínio. Quero saber as decisões, as tarefas e o que ficou pendente.

Se preferir escolher você mesmo: digite `/` e escolha **onion-product:extract-meeting**.
`[CAPTURA: mensagem com as anotações coladas ou o arquivo anexado]`

**Passo 3.** Envie e aguarde.
*O que você vai ver:* um resumo separado em partes: o que foi **decidido**, as **tarefas** (com quem
ficou responsável, se as anotações dizem) e o que ficou **em aberto**.
`[CAPTURA: resumo com decisões, tarefas e pendências]`

**Passo 4.** Confira o resumo com as suas anotações. Se faltou algo, diga o que faltou.

> **Confira antes de enviar para outras pessoas.** O resumo é uma ajuda, não a palavra final. O Claude
> só sabe o que está nas anotações.

---

## Tarefa 5: criar um caderno para um assunto

Uma conversa comum **não lembra** das outras conversas. Para guardar tudo de um assunto num lugar só,
use um **Projeto**. Pense nele como um caderno: cada conversa é uma página, e o que você guarda no
caderno vale para todas as páginas.

**Passo 1.** Na barra da esquerda, clique em **"Projects"**. Depois, no botão para criar um projeto novo.
*O que você vai ver:* um espaço para dar nome e descrição ao projeto.
`[CAPTURA: tela de criar projeto]`

**Passo 2.** Dê um nome simples. Por exemplo: **Horta do prédio**.

**Passo 3.** Guarde no projeto o que é importante: o texto da ideia (tarefa 2), a lista de passos
(tarefa 3), o resumo da reunião (tarefa 4). Use a área de conhecimento do projeto, ou anexe arquivos.
*O que você vai ver:* os textos e arquivos listados dentro do projeto.
`[CAPTURA: projeto com textos e arquivos guardados]`

**Passo 4.** Daqui para frente, comece as conversas sobre esse assunto **dentro do projeto**.
Pergunte, por exemplo:

    O que falta fazer na horta?

*O que você vai ver:* uma resposta que usa o que você guardou no projeto.
`[CAPTURA: resposta dentro do projeto, usando o que foi guardado]`

---

## Dicas para tirar o melhor

- **Escreva como você fala.** Não precisa de palavras técnicas.
- **Uma coisa de cada vez.** Uma ideia ou um projeto por conversa.
- **Peça para mudar.** "Mais curto", "mais simples", "em tópicos": o Claude refaz.
- **Peça letra maior para imprimir.** "Faça em letras grandes, para imprimir."
- **Confira o que importa.** Datas, valores e nomes: sempre leia antes de usar.
- **Não compartilhe senhas** nem dados de banco nas conversas.

---

## O que é o Onion, em uma página

**O Onion é um jeito de trabalhar com o Claude.** Ele ensina ao Claude um método: o passo a passo que
pessoas organizadas usam para tirar uma ideia da cabeça e levá-la até o fim.

**Sem o Onion**, você conversa com o Claude e ele responde. Funciona, mas cada vez é de um jeito.

**Com o Onion**, o Claude segue sempre o mesmo caminho:

1. **Entender** a ideia, fazendo perguntas.
2. **Escrever** a ideia de forma clara, com título e descrição.
3. **Dividir** em passos pequenos, em ordem.
4. **Guardar** o que foi decidido, para não se perder.

**O nome vem da cebola** (em inglês, *onion*): camadas. Você começa pelo de fora, a ideia, e vai
descendo até o detalhe.

**Para quem é.** Para quem quer organizar projetos, ideias e conhecimento: um evento, uma reforma, um
livro de memórias, a associação do bairro. O Onion também tem partes para equipes que fazem programas
de computador. Este guia mostra só a parte de organizar, que é para todo mundo.

**O que ele não é.** Não é um programa separado. É um complemento que você instala dentro do Claude.
E não decide por você: ajuda a pensar, mas a palavra final é sua.

---

## Palavras novas, explicadas

- **Claude**: o assistente com quem você conversa por escrito. É uma inteligência artificial.
- **Inteligência artificial (IA)**: um programa que entende o que você escreve e responde com texto. Pode errar, por isso confira.
- **Conversa**: uma troca de mensagens com o Claude. Cada conversa nova começa do zero.
- **Caixa de mensagem**: o espaço onde você escreve, embaixo ou no meio da tela.
- **Onion**: um método de organização que você instala no Claude.
- **Plugin (complemento)**: um pacote que acrescenta habilidades ao Claude. O Onion chega como plugin.
- **Marketplace (loja de complementos)**: o lugar de onde o Claude busca os complementos. O do Onion se chama **onion-plugins**.
- **Skill (habilidade)**: uma instrução que ensina ao Claude a fazer uma tarefa de um jeito certo.
- **Barra "/"**: digitar `/` na caixa de mensagem abre o menu das habilidades instaladas.
- **Projeto (caderno)**: um lugar para juntar conversas e arquivos de um mesmo assunto.
- **Anexar**: enviar um arquivo do computador junto com a mensagem.
- **Plano pago**: a assinatura do Claude (Pro, Max, Team ou Enterprise). O Onion precisa de um.

---

## Quando algo não funciona

**Digito "/" e não aparece nada do Onion**
- Confira se a opção "Code execution and file creation" está ligada (Tarefa 1, passo 3).
- Confira se "Onion" e "Onion · Product" aparecem como instalados em "Customize" > "Plugins".
- Feche e abra o Claude de novo.

**Não encontro "Plugins" nem "Add marketplace"**
- Confira se o seu plano é pago.
- Se a conta é da empresa, o responsável pode ter limitado os complementos. Peça ajuda a ele.

**O Claude responde com palavras técnicas**
- Escreva: `Explique de forma simples, sem palavras técnicas.`

**O Claude fala de "gerenciador de tarefas", "arquivos do projeto" ou "repositório"**
- Partes do Onion foram feitas para equipes técnicas. Escreva: `Não tenho isso. Faça tudo aqui na conversa.`

**A resposta ficou longa demais**
- Escreva: `Resuma em 5 linhas.`

---

*Onion: guia fácil. Rascunho de 12 de outubro de 2026. Os nomes de botões seguem a documentação
oficial do Claude nesta data e podem mudar.*

---

<!--
NOTA PARA O REVISOR (não é para o leitor final) — espelho do comentário no topo do HTML.

VERIFICADO em 2026-10-12, na documentação oficial:
- Plugins de marketplace funcionam no app do Claude (web, desktop, celular), não só no Claude Code:
  https://claude.com/docs/plugins/overview e https://claude.com/docs/plugins/platform-support
- No chat carregam só SKILLS e COMANDOS (o comando vira skill); AGENTES e HOOKS são ignorados no chat.
- Skills exigem plano Pro/Max/Team/Enterprise e "Code execution and file creation" ligado em
  Settings > Capabilities: https://claude.com/docs/skills/overview
- O que viaja nos plugins "Onion" e "Onion · Product": lido da árvore publicada do repo público
  onion-plugins (collect, create-task-structure e extract-meeting em plugins/onion-product/commands/).

NÃO VERIFICADO (fica para o teste humano):
- Rótulos da tela vêm da documentação em inglês; tela real e tradução pt-BR não foram vistas
  (doutrina de material para cliente, cláusula 3).
- As tarefas 2 a 4 não foram rodadas no chat do app. Os comandos foram escritos para o Claude Code
  com arquivos de projeto; no chat, o Claude os recebe como instrução e precisa adaptar
  (cláusula 4: exemplo é promessa).
- A skill "onion" usa injeção de shell (!`...`) que o chat pode não executar; ficou fora das tarefas.

FALTA, E É HUMANO (com o maestro):
1. Perfil de público por entrevista/observação de 2-3 pessoas 60+.
2. Teste de uso com 2+ pessoas, com o guia impresso; anotar travas e tempo; tirar as [CAPTURA: ...].
3. Conferir os rótulos na tela real e corrigir este texto.

Contraste WCAG (calculado, todos os pares de texto >= 7:1): ver o comentário no topo do HTML.
-->
