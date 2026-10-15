# 🔐 Doutrina do /meta:federation-a2a — montar a rede A2A sem passo manual de shell, e sem confiança de graça

Fragmento canônico do [`/meta:federation-a2a`](../../meta/federation-a2a.md). A superfície **referencia**,
não copia. A lente que carrega ao tocar os motores é [`federation-a2a-lens.md`](../../../rules/federation-a2a-lens.md).

**Por que existe (pedido do maestro, 2026-10-14):** um configurador completo que *"cria, instala,
configura, confere, testa e ajuda em todo o processo de A2A"*, como wizard de onboarding fácil e
explicativo, para o próprio computador do core e para os membros. Montar uma conexão eram **11 passos
manuais** (keygen à mão, `.pem` por `git add -f`, `kid` no registro, merge, deploy do bridge, bearer no
ambiente do bridge com restart, entrega fora de banda, remetente próprio de cada membro, aceite com
acesso de administrador, revogação à mão). O plano e as decisões vivem no grafo do programa, que é
core-only: `docs/evolution/research/a2a-configurator-2026-10/` (no adotante não existe).

## As cláusulas

### 1. Na dúvida, VETA — e "não pude medir" nunca vira saudável
O gate do receptor (`a2a-verify.sh`) degrada para veto, nunca para pular. O doctor herda a mesma régua
com uma distinção a mais, porque o próximo passo é diferente: **rc 1** é "medi e está errado", **rc 2**
é "não pude medir o que é crítico". Uma checagem não informada (endpoint, impressão do membro) sai
não medida e NÃO crítica, **declarada na saída**: não informado não é saudável, é não perguntado.
O wizard nunca resume um rc 2 como "tudo certo".

### 2. Nenhum segredo no chat, em argv ou no git
- A **chave privada** nasce 0600 num diretório 0700 da conta do membro (`a2a-keygen.sh`) e **nunca sai
  da máquina**: o que viaja é a pública e a impressão SHA-256.
- O **bearer do canal** vive num arquivo 0600 e chega ao `curl` por arquivo de cabeçalho; o remetente
  **recusa** token ou chave legível por grupo/outros (segredo que outra conta lê é segredo vazado).
- O **token do convite** nasce de `/dev/urandom` direto no arquivo 0600 do `a2a-invite.sh create`
  (sem sobrescrever, sem seguir symlink) e nunca passa por stdout, stderr, argv ou log. No arquivo de
  convites do bridge mora só o hash. Quando a escrita é como a conta do serviço, o token chega por
  redirecionamento (`--token-stdin`): quem abre o arquivo é o shell do operador.
- O wizard **nunca pede** o token ou a chave no chat, nunca os coloca num argumento de comando e nunca
  os imprime. Quando o membro precisa gravar o token, a instrução é gravar por arquivo, com `umask 077`.
- As `.pem` públicas são versionadas no JWKS do receptor por adição deliberada; a privada nunca entra
  no repo (o `.gitignore` do JWKS ignora todo `.pem`).

### 3. A confiança nasce no MERGE que chega ao clone SERVIDO, conferida fora de banda
Pinar é escrever `a2a.keys` e `jwks/<kid>.pem` no registro do receptor, e isso só vale depois do merge
pelo caminho verificado **e** da atualização do clone que o bridge serve, pelo caminho de deploy dele: o
bridge lê o registro e o JWKS desse clone, e o doctor mede o repo onde roda. O mesmo vale ao contrário
para a revogação: até o clone servido receber o merge, o `kid` revogado segue aceito no bridge (achado
do refutador da F1b, 2026-10-15). Antes do pino, a impressão que o membro leu do keygen é conferida **por outro
canal** (voz, mensagem assinada, presença) contra a do arquivo recebido — o doctor do lado receptor
faz essa conta com `--fingerprint`. Pública que chegou por um canal só e não foi conferida não é pinada.

### 4. O aceite da fila é ATO HUMANO
O endpoint só enfileira; nada é aplicado. Promover um registro da fila para o inbox é `a2a-accept.sh`,
um registro de cada vez, depois de o operador ler o sinal. O wizard lista e prepara; não aceita em lote
e não aceita sem a confirmação explícita de cada um. Membro regulado continua `propose-only`.

### 5. I3: cada repo tem um escritor
O core nunca commita no repo do membro, e o membro nunca commita no do core. A pública do membro chega
ao core pelo carteiro upstream (`/meta:co-relay`, entrega sem commit no inbox) ou pelo canal combinado; o
pino é commit do core, no core. O pacote de entrada que o core prepara é entregue, não instalado.

### 6. O pino só se mede no RECEPTOR (medido no spike)
A pergunta "minha chave está pinada?" só tem resposta com o registro do receptor. Na máquina do
membro, o doctor sai rc 2 nessa checagem e diz o próximo passo ("peça ao receptor o lado dele"); a
resposta definitiva é o doctor com `--side receiver` rodando no core. Não se responde de memória.

### 7. Conferir não pode gastar o sinal (medido no spike)
O `--dry-run` do gate **consome o jti**: conferir um envelope real o inutiliza. Por isso o doctor e o
wizard só testam com **envelope sintético de jti novo**, num estado de replay descartável. Envio real é
envio real: o teste ao vivo da trilha 3 é um sinal de verdade, e entra na fila como qualquer outro.

### 8. Receptor se reconhece pela natureza, não só pelo papel (medido no spike)
`sends_to` só aponta membro com `role: source` ou `hub` **e** que não seja porta (`kind: door`). Olhar só
o `role` deixava a porta pública passar por receptor. O `members-validate.sh` cobra isso no gate do lint.

### 9. O bearer tem DONO, e o arquivo de convites se julga como o bridge o julga (F2)
O convite amarra o hash do token a **um** membro e a **um** receptor, com validade ISO 8601 com hora e
fuso, e o guard do bridge exige que esse membro seja o `from` do envelope antes do gate (o gate prova o
mesmo `from` pela assinatura). Três regras do bridge que um editor à mão quebra sem perceber, e que o
`a2a-invite.sh` aplica:
- **O arquivo é recusado INTEIRO** (`convites-indisponiveis`) quando tem outro dono, é symlink, é
  gravável por grupo/outros, mora em diretório inseguro, ou não é JSON `version: 1`. Uma revogação
  gravada com defeito nunca deixa o convite revogado de pé, e por isso o motor **não escreve** sobre
  arquivo quebrado: ele manda conferir.
- **`revoked` só vale como `false` literal**: `null`, ausente ou `0` é revogado. E um hash repetido com
  uma entrada revogada derruba o token.
- **A escrita é atômica** (temporário no mesmo diretório + rename, 0600) e **travada** no diretório,
  e nunca como root, porque o arquivo nasceria de root e o bridge o recusaria. A trava só vale entre
  motores. Contra um escritor de fora, o motor relê metadados (com o ctime) e conteúdo antes do rename
  e recusa se algo mudou. Isso **estreita** a janela, mas não a fecha: medido, 1 escrita perdida em 300
  corridas, contra 14 sem a releitura. Por isso o arquivo não se edita à mão.

A paridade com o bridge foi **medida**, não suposta: os veredictos do motor batem com os do módulo real
do bridge em 25 arquivos de teste e em 5002 datas aleatórias (2026-10-15). A primeira medição não
bastou. O refutador achou mais quatro divergências, todas curadas: o `$` do Python casa antes de um
`\n` final, a fração de `24:00` era truncada antes do teste, uma surrogate sozinha derrubava a escrita,
e um JSON fundo demais era dado como quebrado (agora sai "não medido"). Revogar o convite vale no
próximo envio, sem restart e sem deploy. É o contrário da revogação do `kid` (cláusula 3), que só vale
quando o clone servido recebe o merge. Por isso a trilha 6 revoga o convite **primeiro**.

## O que este comando NÃO promete

- **Não faz deploy** do bridge, não edita o ambiente do serviço e não reinicia nada. O convite por
  membro (F2) dispensa restart. O pool anônimo do ambiente do bridge (`INVITE_TOKENS_A2A`) é o caminho
  legado, depreciado, e tirar um bearer dele continua sendo do caminho de deploy do bridge. Um bridge
  anterior à F2 ignora o arquivo de convites, e o sintoma é o 401 `credencial-desconhecida`.
- **Não roda na máquina do membro por conta própria:** a trilha 3 é executada pelo membro, no
  computador dele. O core prepara o pacote; o membro instala.
- **Não aceita sinal sozinho** nem em lote (cláusula 4), e não rotaciona chave sem pedido.
- **Hub como receptor** (rotas `/a2a/<hub>`, filhos com `parent: <hub>`) é a F3; hub com servidor
  próprio é a F4, gated até o primeiro hub pedir.
- **Não garante entrega:** o canal ao vivo acelera; o `git-async` continua o sistema de registro e o
  fallback.
