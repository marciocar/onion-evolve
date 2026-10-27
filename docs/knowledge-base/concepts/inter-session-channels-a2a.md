---
title: "Canais entre sessões e A2A — o manual de qual canal usar, com o estado de hoje"
date: 2026-10-27
type: concept
status: active
verified_at: 2026-10-27
source: "SendMessage do Claude Code 2.1.311 (descrição da ferramenta lida em 2026-10-27); /run/user/<uid>/cc-socks medido na VPS do core em 2026-10-27; os comandos /meta:federation-a2a, /meta:co-relay, /meta:co-deliver e /meta:co-announce e os grafos do core citados em §9"
related:
  - federation-usage-modes.md
  - multi-repo-federation.md
  - onion-federation-and-adoption.md
---

# Canais entre sessões e A2A

> **Para quem é:** o maestro e as pessoas das empresas adotantes que querem que duas sessões do Claude
> Code conversem. **O que resolve:** existem três situações bem diferentes (mesma máquina, máquinas da
> mesma pessoa, pessoas e empresas diferentes), e cada uma tem um canal, uma garantia e um limite. Este
> manual diz qual usar, como usar e o que ele **não** garante, com o estado medido em 2026-10-27.
>
> **Validade:** o comportamento do Claude Code muda a cada versão. O que está aqui foi lido no Claude Code
> **2.1.311**. Atualizou o Claude Code? Releia a descrição da ferramenta `SendMessage` antes de confiar
> num detalhe deste texto.

**Siglas, na primeira vez:** A2A (*Agent-to-Agent*, o protocolo aberto de troca de mensagens entre
agentes), MCP (*Model Context Protocol*, o protocolo que liga ferramentas a um agente), PID (o número do
processo no sistema operacional), I3 (o invariante "um escritor por repo": nenhuma sessão commita no
repositório de outra), MOAT (a fronteira de ações que só o maestro executa).

## 1. Qual canal eu uso? (o quadro de decisão)

| Situação | Canal | Precisa de quê | Ida e volta? | Onde o corpo passa |
|---|---|---|---|---|
| Duas sessões **na mesma máquina e no mesmo usuário do SO** | Socket local do harness (`SendMessage` + `ListAgents`) | nada além do Claude Code | **Sim**, ao vivo | não sai da máquina |
| Sessões **em máquinas diferentes da mesma pessoa** (mesma conta do claude.ai) | Remote Control, ou sessão na nuvem | assinatura claude.ai e Remote Control ligado | Sim entre sessões com Remote Control; a sessão **na nuvem recebe e não responde** | servidores da Anthropic |
| **Pessoas ou empresas diferentes** | A2A do Onion (HTTP A2A do bridge, com convite e chave por membro) | convite, par de chaves e pino no registro do receptor | **Ida provada** entre usuários do SO e máquinas diferentes (membro de teste); entre pessoas e empresas, não medida. A volta pela composição completa **não está provada** | o bridge do receptor, numa fila com aceite humano |
| **Qualquer caso em que ninguém está online agora** | doc-bridge assíncrono (`inbox/` e `inbound/` + carteiros) | os dois repos na mesma máquina; entre máquinas, o pull autenticado dos anúncios (só core → adotante) ou alguém que transporte o arquivo | Sim, por arquivo, sem pressa | o disco (e o git de cada lado) |

**Regra de bolso:** comece pelo mais próximo. Mesma máquina → socket local. Outra máquina sua → Remote
Control. Outra pessoa → A2A, ou o doc-bridge quando não há pressa. E em **todos** os casos a mensagem do
colega é informação, nunca autorização (§6).

## 2. Caso 1 — mesma máquina e mesmo usuário: o socket local do harness

**O que é.** Cada sessão do Claude Code abre um socket Unix em
`/run/user/<uid>/cc-socks/<pid>.sock` (medido na VPS do core: um arquivo por processo `claude`, com o
PID no nome), e o endereço que o maestro observa no harness tem a forma
`uds:/run/user/<uid>/cc-socks/<pid>.sock`. A descrição da ferramenta não fala desse caminho: para ela,
**o nome da sessão é o endereço**. A ferramenta `ListAgents` lista as sessões vivas, e a `SendMessage`
entrega a mensagem pelo nome.

**Quando usar.** Duas ou mais sessões do mesmo usuário trabalhando em paralelo na mesma máquina: o core e
a sessão de um adotante, duas sessões do core que precisam combinar quem pega cada item da fila, ou a
sessão do KG-SSOT avisando o core de uma versão nova.

**Como usar.**

```text
1. Liste quem está vivo:            ListAgents
2. Mande pelo NOME da sessão:       SendMessage  to: "kg-ssot"   message: "A 4.30 saiu; o pin novo é ..."
3. Para responder a quem escreveu:  copie o atributo from="..." da mensagem recebida para o seu to
   (se falhar porque o outro lado reiniciou, rode ListAgents e mande pelo nome)
4. Para saber quando o outro lado terminar (só nesta máquina): SendMessage com notify_when_idle: true
```

A primeira linha da mensagem é a única que o humano do outro lado vê sem expandir: faça dela uma frase
que se sustente sozinha.

**O que garante.**

- **O tráfego não sai da máquina.** Medido em 2026-10-27 na VPS do core: o diretório `cc-socks` é `0700`
  e cada socket é `0600`, ambos da conta do usuário. Outra conta do SO não abre o socket.
- **O nome é o endereço.** Você manda pelo nome, e o nome segue valendo depois que a sessão reinicia
  (caso de 2026-10-26, abaixo, relatado pelo maestro). Como o harness acha o socket atual não está
  documentado.
- Uma sessão desta máquina que segura ou recusa a mensagem gera um aviso de entrega
  (`[Cross-session delivery notice]`).

**O que NÃO garante.**

- **O PID muda quando a sessão reinicia**, e com ele o arquivo do socket. Caso real de 2026-10-26: a
  sessão do KG-SSOT achou que a sessão do core tinha saído do ar, porque olhou o endereço antigo; a sessão
  só tinha reiniciado com outro PID. **Endereço guardado envelhece; nome não.** Antes de concluir que o
  outro lado caiu, rode `ListAgents` de novo e mande pelo nome.
- **Não atravessa usuários do SO**, nem com a mesma conta do Claude. Medido em 2026-10-21 num notebook com
  dois usuários do SO e o Remote Control **desligado**: cada usuário só enxergou as próprias sessões. Com o
  Remote Control ligado nos dois, não foi medido. Entre usuários, o caminho garantido é o A2A (§4).
- **Entregue não é lido.** Um envio com sucesso diz que a mensagem chegou à sessão, não que o Claude dela a
  leu. Uma sessão em outro modo de permissão segura a mensagem para o humano dela aprovar, e pode deixá-la
  expirar. Na máquina do core, o settings do usuário está com `crossSessionInbound: "accept"`; em outra
  máquina pode não estar.
- **`@arquivo` não anexa nada do outro lado.** Mande o texto, ou um arquivo pela ferramenta própria.

## 3. Caso 2 — máquinas ou contas diferentes da mesma pessoa: Remote Control e nuvem

**O que é.** A mesma `SendMessage`, mas o alvo está noutra máquina sua ou numa sessão na nuvem. Entre
máquinas, a mensagem passa pelos servidores da Anthropic e chega pela conexão de Remote Control da máquina
de destino; para a nuvem, vai direto à sessão na nuvem.

**Quando usar.** O maestro na VPS falando com a sessão do próprio notebook, ou disparando um trabalho
numa sessão na nuvem.

**Como usar.**

```text
1. Ligue o Remote Control nas duas pontas (no core: remoteControlAtStartup: true no settings do usuário)
2. ListAgents mostra as sessões de outras máquinas com o rótulo Remote Control
3. SendMessage pelo nome, como no caso 1
```

**O que garante.** Que a mensagem chega a sessões **da sua própria conta**. O alcance listado pela
documentação oficial (lida em 2026-10-07) são as suas sessões na nuvem e as suas sessões de Remote Control
em outras máquinas.

**O que NÃO garante.**

- **A sessão na nuvem recebe, mas não responde por mensagem.** É o que o próprio runtime declara (descrição
  do `ListAgents` lida em 2026-10-07: a sessão na nuvem recebe e ainda não consegue mandar mensagem de
  volta) e é o estado que o maestro reporta em 2026-10-27. Não peça resposta a ela; peça um artefato (PR,
  arquivo, comentário).
- **Remetente sem Remote Control manda sem endereço de resposta.** A mensagem sai, mas o Claude que
  recebe não consegue responder.
- **Silêncio não é concordância.** Para Remote Control, nuvem e Claude Desktop, nada volta dizendo que a
  mensagem foi segurada ou recusada (descrição da `SendMessage`, 2.1.311).
- **Não é canal entre contas.** Entre contas diferentes a documentação é silenciosa: não está escrito que é
  impossível, mas também não há transporte documentado. Não monte processo de empresa em cima disso.
- **Exige assinatura do claude.ai** (Pro, Max, Team ou Enterprise); chave de API não serve, e em Team e
  Enterprise um Owner precisa ligar o Remote Control. Em organização com ZDR (*Zero Data Retention*) ou
  configuração HIPAA, o Remote Control fica indisponível. **O corpo da mensagem passa pelos servidores da
  Anthropic**, o que pesa para adotante regulado.
- **Portão de saída:** `isolatePeerMachines: true` no settings do projeto obriga aprovação humana antes de
  qualquer `SendMessage` sair da máquina, mesmo em `bypassPermissions`. O projeto pode ligar, não
  desligar. É a trava recomendada para quem não quer mensagem saindo sem um humano ver.

## 4. Caso 3 — pessoas e empresas diferentes: o A2A do Onion

**O que é.** Um canal com identidade e porteiro. Cada membro tem um par de chaves (a privada nunca sai da
máquina dele), um convite com dono, validade e revogação, e a chave pública **pinada** no registro do
receptor. O remetente assina o envelope (JWS, com o hash do corpo dentro da assinatura), manda por HTTP
para o bridge do receptor, e o gate do bridge confere assinatura, validade, anti-replay e topologia. Nada é
aplicado na chegada: o sinal vai para uma **fila**, e passar da fila ao inbox é ato humano, um por vez, que
**reverifica** o envelope.

**Quando usar.** Sempre que remetente e destinatário são pessoas, contas do SO ou empresas diferentes, e a
mensagem precisa provar de quem veio.

**Como usar.** O configurador em wizard é o `/meta:federation-a2a` (roda no core e no hub). Ele tem seis
trilhas, com dry-run antes de toda escrita e o doctor no fim:

```text
/meta:federation-a2a preparar  --member <id>   # o receptor confere a própria fiação
/meta:federation-a2a convidar  --member <id>   # registro, pacote de entrada, convite por membro, pino da chave
/meta:federation-a2a entrar    --member <id>   # o membro, na máquina dele: chaves, token, doctor, envio de teste
/meta:federation-a2a conferir  --member <id>   # o doctor do lado certo
/meta:federation-a2a aceitar                   # a fila: um registro por vez, com confirmação do maestro
/meta:federation-a2a revogar   --member <id>   # o convite primeiro (vale na hora), depois a chave
```

Do lado do membro, depois do pino, o envio de teste é:

```bash
bash a2a-send.sh --dry-run --from <id> --to <receptor> --body "olá do <id>"
bash a2a-send.sh --from <id> --to <receptor> --endpoint <url> --body "olá do <id>"
```

A doutrina inteira (as dez cláusulas) está no fragmento `common:prompts:federation-a2a-doctrine`; este
manual não a repete.

**O que está provado (medido em produção).**

- **A ida entre usuários do SO e máquinas diferentes.** Em 2026-10-21, um sinal assinado por um membro de
  teste, num usuário descartável do SO no notebook do maestro (outra máquina, mas a mesma pessoa), passou pelo gate do bridge, entrou na fila e foi aceito no inbox
  do core, reverificado no aceite.
- **Os seis negativos do gate no HTTP vivo** (replay, chave não pinada, expirado, emitido no futuro,
  validade além do teto, corpo trocado): todos recusados, cada um com o motivo certo.
- **Uma volta ponta a ponta, pelo bridge de produção com o roteiro do spike** (2026-10-22): o envio do notebook e a resposta assinada
  de volta, conferidos. Mas a régua de "o receptor não agiu sozinho" **reprovou** as duas réplicas, porque
  o harness rodou sem diálogo um comando de leitura composto. Funciona como transporte; não passou como
  conversa segura.

**O que ainda NÃO está provado (e por isso não se promete).**

- **A ida e volta viva pela composição do Onion**: o HTTP A2A do bridge entre máquinas **mais** um MCP local
  na ponta, cuja ferramenta de envio **só grava rascunho** (quem envia é um script que o humano roda). Essa
  composição está **desenhada e não construída**. O que se mediu em 2026-10-25 foi outra peça, o
  interlink-mcp entre Claude e Codex, e ele mostrou o buraco que a composição precisa fechar: com o Claude
  Code em `bypassPermissions`, a ferramenta de envio manda **sem diálogo**.
- O critério de aceite dessa ida e volta: com bypass fechando, sem envio automático, o *Always allow* sem
  abrir o envio, nenhuma ferramenta de aceitar exposta ao modelo e a identidade do remetente estável. Ela
  será medida entre a VPS do core e o notebook local do maestro, em máquinas diferentes (§8).
- **Conversa com fidelidade de conversa.** Com aceite humano a cada mensagem, o humano fica dentro do ciclo.
  A tese do spike, ainda aberta, é que "igual ao canal nativo" é impossível por construção até haver
  consentimento por conversa com expiração.
- **Entrega.** O canal ao vivo acelera; não garante. O doc-bridge (§5) segue sendo o sistema de registro e
  o plano B.

**O que garante, quando está montado.** Remetente provado pela assinatura e pela chave pinada; corpo
íntegro pelo hash assinado; convite revogável na hora, sem restart; nada aplicado sem humano; o corpo
chega à sessão como **dado** dentro da moldura de conteúdo não confiável, nunca como instrução.

## 5. O canal assíncrono: o doc-bridge

**O que é.** Mensagem como arquivo. É o canal mais antigo, o mais lento e o mais robusto: não depende de
ninguém online, e cada lado commita só no próprio repo (I3).

| Direção | Quem escreve | Pasta | Carteiro (mesma máquina) | Aviso do hook |
|---|---|---|---|---|
| **Upstream** (adotante → core) | a sessão do adotante | `docs/evolution/inbox/` do adotante | `/meta:co-relay` entrega no `inbox/` do core | 📬 na próxima sessão do core |
| **Downstream** (core → adotante) | `/meta:co-announce` na staging do core (`federation/outbox/<id>/`) | `docs/evolution/inbound/` do adotante | `/meta:co-deliver` entrega no `inbound/` do adotante | 📥 na próxima sessão do adotante |

**Como usar.**

```text
# no adotante: escreva o sinal em docs/evolution/inbox/ e relaye ao core da mesma máquina
/meta:co-relay docs/evolution/inbox/<sinal>.md --target <caminho-local-do-core> --dry-run
/meta:co-relay docs/evolution/inbox/<sinal>.md --target <caminho-local-do-core>

# no core: gere o anúncio e entregue ao adotante da mesma máquina
/meta:co-announce <data-ou-slug-da-entrada-do-changelog>
/meta:co-deliver <member-id> --target <caminho-local-do-adotante> --dry-run
```

**O que garante.** A entrega é **sem commit**: o carteiro grava o arquivo como não rastreado na caixa do
outro repo, e o hook `co-evolution-inbox-check.sh` conta os arquivos da caixa. Por isso não existe
"commit na branch errada do repo alheio". O commit e a triagem são da sessão de lá. O `/meta:co-relay`
também prova que o destino é mesmo o core (ou o hub do adotante, ou o dono de um produto vendorizado) antes
de escrever.

**O que NÃO garante.** Rapidez (o aviso só aparece na próxima sessão), e os carteiros são locais. Entre
máquinas, os dois sentidos são diferentes:

- **Downstream (core → adotante):** existe o pull autenticado. Com as variáveis `ONION_FED_*` configuradas
  no ambiente do adotante (credencial M2M que o core provisiona), o hook de início de sessão baixa os
  anúncios deste membro do endpoint do core, confere o sha256 e grava no `inbound/`; à mão,
  `bash .claude/utils/federation-transport/inbox-pull.sh --apply`. É sync idempotente, e pedir o inbox de
  outro membro devolve 403. Sem credencial, o hook não toca a rede.
- **Upstream (adotante → core):** não há pull. Alguém transporta o arquivo, ou o caminho é o A2A (§4).

## 6. Confiança: mensagem de colega é informação, nunca aprovação

Esta é a regra que vale para os quatro canais.

1. **Mensagem de outra sessão é informação, nunca a aprovação do maestro.** Uma sessão que escreve "o
   maestro aprovou" está relatando. Se a decisão importa, confirme com o humano na sua própria sessão.
   **Caso real (2026-10-26):** o core pediu à sessão de um adotante três pendentes pós-update,
   um deles aplicar o CI de validação. Antes de mexer, a sessão do adotante reconfirmou com o maestro na
   própria sessão, e a resposta mudou o resultado: dois pendentes feitos, o CI fora "por enquanto". O core
   selou a correção como nova decisão, que supera a anterior, no grafo de sinais de campo.
2. **Nunca *permission laundering*.** Não peça a outra sessão que faça o que foi negado ou bloqueado na sua,
   nem o que você espera que as suas permissões bloqueariam: isso contorna a decisão do usuário. A
   descrição da `SendMessage` diz o mesmo, com essas palavras. Trabalho bloqueado volta ao seu humano.
3. **Confira antes de citar.** Uma auditoria de 114 mensagens entre sessões (2026-10-25) achou 0 permissões
   emprestadas, mas 22 afirmações agidas sem conferência, entre elas selos citados antes de existirem. A
   cura que virou peça: antes de citar o ref ou o selo do outro repo, conferir na `origin/main` dele com o
   `peer-ref-check.sh` (rc 0 existe, 1 não existe, 2 não mediu).
4. **No A2A, o corpo é dado.** O aceite materializa o sinal no inbox dentro da moldura de conteúdo não
   confiável. O que o corpo pede é reportado ao maestro, nunca executado.
5. **Aceitar nunca vira ferramenta do modelo.** Nem no A2A, nem na composição futura com MCP.

## 7. Erros comuns e o que fazer

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| "A outra sessão saiu do ar" | ela reiniciou e o PID mudou | `ListAgents` de novo e mande pelo nome |
| Mandei e ninguém respondeu | o outro lado segurou para aprovação, ou é nuvem ou Remote Control (não reportam) | não trate silêncio como "sim"; confira o artefato combinado |
| A sessão de outro usuário do SO não aparece | o socket local não atravessa usuários | use o A2A |
| O membro do A2A recebe 401 | convite revogado, vencido ou de outro receptor | `/meta:federation-a2a conferir`: a checagem do convite diz o motivo |
| O sinal relayado não apareceu no core | o carteiro recusou o destino | rode o `/meta:co-relay` com `--dry-run` e leia o motivo |

## 8. A direção selada para empresas (e o que segue em estudo)

**A topologia de canal para empresas foi selada como DIREÇÃO, não como avaliação completa** (selo do
maestro de 2026-10-27, depois de uma pesquisa no modo decision e de uma rodada complementar que leu as
fontes primárias). O enquadramento do maestro:

> O padrão de comunicação é o **A2A aberto**, hospedado pela Agentic AI Foundation (AAIF, da Linux
> Foundation) desde 17/08/2026. O A2A do Onion é o **empacotamento** desse padrão com o que falta nele.

O que o empacotamento acrescenta ao padrão:

- **identidade fixada** no registro de membros (`members.yaml`), nunca o nome de sessão;
- **card assinado e verificado como obrigatório**: a especificação A2A 1.0 deixa a assinatura do Agent
  Card como opcional (MAY) e a verificação como recomendada (SHOULD); o Onion as endurece;
- **corpo da mensagem assinado**, porque o card assinado autentica o agente, não a mensagem;
- **envio só em rascunho**: a ferramenta de envio grava rascunho, e quem envia é a pessoa;
- **caixa de entrada durável no receptor**;
- **mensagem de colega tratada como dado**, como na seção 6.

As pernas da direção:

| Quem fala com quem | Canal |
|---|---|
| Pessoas diferentes (colegas, empresas) | receptor A2A 1.0 em **self-host da empresa** (VPS ou serverless com armazenamento durável) |
| A mesma pessoa em várias máquinas | o canal nativo (seção 3) com **`isolatePeerMachines`** ligado no `.claude/settings.json` do projeto: a aprovação antes de a mensagem sair vale até sob `bypassPermissions`, e o arquivo de projeto liga, mas não desliga |

**Fica de fora:**

- **Channels entre pessoas.** A autenticação é uma lista de IDs da plataforma de chat, o relay de
  permissão faz do colega um aprovador de ferramenta, e não está provado que o evento acorda uma sessão
  ociosa.
- **Nuvem e Managed Agents para adotante regulado.** As sessões na nuvem ficam fora de ZDR, HIPAA e
  CMEK, e o Managed Agents não tem ZDR nem BAA. Para adotante não regulado, eles ainda não foram avaliados.

**Condição de produção:** a ida e volta medida entre a VPS e o notebook, **incluindo a entrega a uma
sessão que estava fechada**. Até essa medida, a direção orienta o desenho e o piloto, e o recomendado em
uso continua sendo o das seções 2 a 5, com os limites que elas declaram. O onion-bridge hospedado do core
fica para onboarding e piloto, não para produção.

Os dados e as lacunas que seguem abertas estão no grafo da pesquisa, no repositório público do core:
<https://github.com/marciocar/onion-evolve/tree/main/docs/evolution/research/a2a-empresa-adotante-2026-10>
(nó `D_A2A_EMPRESA_ADOTANTE_TOPOLOGIA_1027`).

Também parqueados, com gatilho: a extração do A2A como projeto próprio (reabre quando a identidade sair do
registro de membros **e** a fronteira MOAT sair do nome do motor, com a dissecação refeita depois disso,
ou quando surgir consumidor fora do Onion) e o transporte entre agentes de fornecedores
diferentes (reabre com a ida e volta viva da composição).

## 9. Fontes (o que este manual reusa, sem duplicar)

- Matriz de tipos de uso e topologias de sessão: [federation-usage-modes.md](federation-usage-modes.md).
- Federação por contratos e ledger git: [multi-repo-federation.md](multi-repo-federation.md). Ela descreve a
  federação assíncrona como "sem conexão viva"; o A2A deste manual é a camada de sinais vivos, gated, que
  veio depois e não substitui o ledger.
- Adoção e federação no ciclo do Onion: [onion-federation-and-adoption.md](onion-federation-and-adoption.md).
- Os comandos: `/meta:federation-a2a` e a doutrina `common:prompts:federation-a2a-doctrine`;
  `/meta:co-relay`, `/meta:co-deliver` e `/meta:co-announce`.
- O Manual da Rede A2A (três leitores, saída real de cada erro), nos guias de aplicação do repositório
  público do core: <https://github.com/marciocar/onion-evolve/tree/main/docs/applying>.
- **Core-only** (não viajam com esta KB; existem no repositório do core): o grafo de sinais de campo
  `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml` (nós `Q_COMPOSICAO_IDA_E_VOLTA_VIVA_1025`,
  `E_N2_VIVO_INTERLINK_MEDIU_O_ENVIO_SEM_DIALOGO_1025`, `E_GATILHO_DO_CANAL_NEUTRO_DISPAROU_E_O_CORE_REOLHOU_1025`,
  `D_A2A_PRODUTO_PARQUEADO_COM_GATILHO_1025`, `D_TRANSPORTE_ENTRE_AGENTES_PARQUEADO_COM_GATILHO_1025`,
  `D_PROTOCOLO_ENTRE_SESSOES_COSTURA_PEER_REF_CHECK_1025`, `D_A2A_EMPRESA_PESQUISA_DECISION_1027` e
  `D_MANUAL_CANAIS_A2A_AGORA_1027`); a pesquisa do canal vivo entre sessões
  `docs/evolution/research/canal-vivo-sessoes-2026-10/`; o spike A2A entre usuários
  `docs/evolution/research/a2a-cross-user-spike-2026-10/`; e a pesquisa da topologia para empresas, com
  a direção selada em 2026-10-27, `docs/evolution/research/a2a-empresa-adotante-2026-10/`.
