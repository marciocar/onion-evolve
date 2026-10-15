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

## O que este comando NÃO promete

- **Não faz deploy** do bridge, não edita o ambiente do serviço e não reinicia nada. A F1 usa o pool de
  convites que o bridge já tem; o convite por membro com validade, sem restart, é a F2 (no repo do
  bridge, por sessão própria).
- **Não roda na máquina do membro por conta própria:** a trilha 3 é executada pelo membro, no
  computador dele. O core prepara o pacote; o membro instala.
- **Não aceita sinal sozinho** nem em lote (cláusula 4), e não rotaciona chave sem pedido.
- **Hub como receptor** (rotas `/a2a/<hub>`, filhos com `parent: <hub>`) é a F3; hub com servidor
  próprio é a F4, gated até o primeiro hub pedir.
- **Não garante entrega:** o canal ao vivo acelera; o `git-async` continua o sistema de registro e o
  fallback.
