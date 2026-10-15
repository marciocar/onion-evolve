# Manual da Rede A2A do Sistema Onion

> *"Confiança não se declara. Mede-se do lado de quem recebe."*

---

## Como ler este manual

Ele tem três leitores, e cada um pode pular o que não é dele:

| Você é | O que faz na rede | Leia |
|---|---|---|
| **Operador do core** (o maestro, na sessão do `onion-evolve`) | prepara o receptor, convida, pina a chave, aceita a fila, revoga | Partes I, II, V e VI |
| **Operador de um hub** (adotante que coordena filhos) | hoje entra na rede como membro; amanhã convida os próprios filhos | Partes I, III, IV e V |
| **Membro que entra** (adotante, porta ou máquina de teste) | gera a chave, recebe o convite, envia sinais | Partes I, IV e V |

**De onde vêm as saídas.** Toda saída de terminal deste manual foi **gerada rodando os motores de verdade**
em 2026-10-15, num sandbox descartável: HOME temporário para o membro, um core de fixture com registro
próprio, um arquivo de convites de fixture e um bridge local (o `main` do `onion-bridge` com a F2) em
`127.0.0.1`. Nada tocou produção. Para a página não carregar nada que pareça segredo, os caminhos do
sandbox aparecem como `<sb>`, a porta como `<porta>`, toda impressão e todo hash como `<64 hex>`, o JWS
como `<JWS assinado>` e o id curto de convite como `<id>`. O resto é a saída literal, com o código de
saída (`[rc=N]`) que o motor devolveu. Como as saídas foram montadas está no Apêndice C.

**Onde mora.** Este manual vive em `docs/applying/`, que **não viaja** para adotante nem porta (é
core-only). Quem está fora do core lê a versão publicada no repositório público do core:
<https://github.com/marciocar/onion-evolve/blob/main/docs/applying/onion-a2a-manual.md>. O resumo de
cada trilha viaja dentro do próprio wizard, o `/meta:federation-a2a`.

---

## Prólogo — Por que um canal ao vivo

Desde junho de 2026 eu converso com quem me adotou por arquivos. O adotante deixa um Markdown no
`inbox/`, eu trio, corrijo e anuncio de volta no `inbound/`. É lento de propósito: cada sinal passa
pelo git, tem autor, data e revisão. Esse caminho, o **git-async**, continua sendo o meu sistema de
registro, e nada neste manual o substitui.

O canal A2A existe para **acelerar** o mesmo sinal. Em vez de esperar alguém copiar um arquivo, o
membro assina o sinal com a chave dele e o entrega no meu endpoint, pela internet. Do meu lado, o
sinal passa por duas barreiras (o convite e o gate), entra numa fila e **espera um humano aceitar**.
Nada é aplicado sozinho.

Montar uma conexão dessas custava **11 passos manuais** em 2026-10-14: gerar a chave à mão, forçar a
pública no git, escrever o `kid` no registro, fazer merge, deployar o bridge, pôr um bearer no ambiente
do serviço e reiniciá-lo, entregar o bearer, cada membro escrever o próprio remetente, aceitar a fila
com acesso de administrador e revogar à mão. O maestro pediu um configurador que fizesse tudo isso em
forma de wizard, explicando cada passo. Ele virou o `/meta:federation-a2a`, com seis trilhas por papel,
e este manual conta cada uma delas com a saída real de cada erro.

---

## Parte I — Como a rede funciona

### 1.1 As quatro peças

| Peça | O que é | Onde mora | Quem escreve |
|---|---|---|---|
| **A chave** | par RSA (RS256) do membro, 3072 bits no keygen. O `kid` é `<membro>-<N>` | privada em `~/.config/onion/a2a/` da conta do membro (0700/0600); a pública vai ao receptor | o membro, pelo `a2a-keygen.sh` |
| **O pino** | a pública aceita pelo receptor: o `kid` em `members.yaml[<membro>].a2a.keys` e o arquivo `jwks/<kid>.pem` | no repo do receptor, e só vale no **clone que o bridge serve** | o operador do receptor, por PR |
| **O convite** | o bearer do canal, com **dono** (um membro), **receptor** e **validade** | o token fica com o membro (0600); no arquivo de convites do bridge fica só o SHA-256 dele | o operador do receptor, pelo `a2a-invite.sh` |
| **O gate** | o `a2a-verify.sh`, camadas que vetam na dúvida, da mais barata à mais cara: forma do envelope, topologia de confiança, replay, relógio e janela de tempo, SSRF, assinatura JWS com `kid` pinado, hash do corpo e, por fim, o modo do receptor regulado (`propose-only`) | no core, chamado pelo bridge a cada envio | ninguém escreve: ele só julga |

### 1.2 O caminho de um sinal

```
 máquina do membro                                     máquina do core
 ─────────────────                                     ───────────────
 a2a-send.sh  ── HTTPS + bearer ──►  bridge: guard do convite   (401 se o bearer não serve)
   assina com a privada                    │
   body_sha256 = sha256(corpo)             ▼
                                    gate a2a-verify.sh           (403 se o sinal não serve)
                                           │ verified, gated
                                           ▼
                                    fila do bridge (input_required, nada aplicado)
                                           │ o maestro lê e aceita, um por vez
                                           ▼
                                    a2a-accept.sh → docs/evolution/inbox/ → /meta:co-evolve
```

Repare nas duas barreiras e nos dois códigos. O **guard do convite** responde **401** e fala da
credencial (o bearer). O **gate** responde **403** e fala do sinal (a assinatura, o corpo, o relógio).
O guard roda **antes** do gate de propósito: um bearer de outro membro é recusado sem gastar o `jti`
do envelope, e o dono verdadeiro ainda consegue enviar o mesmo envelope depois. Isso foi medido no
protótipo do spike S4; no bridge da F2 este manual mediu a recusa (401 `convite-de-outro-membro`), não o
reenvio pelo dono, que segue pela ordem do código (o guard antes do gate).

### 1.3 Três desentendimentos comuns

| # | O que parece | O que é |
|---|---|---|
| 1 | O doctor saiu `rc 2`, então está quase tudo certo | `rc 2` quer dizer "**não pude medir** o que é crítico". Não sei não é saudável, e o wizard nunca resume rc 2 como "tudo certo" |
| 2 | Tirei o `kid` do registro e fiz merge, então a chave está revogada | A chave só deixa de valer quando o **clone que o bridge serve** recebe o merge, pelo caminho de deploy do bridge. Já o **convite** revogado vale no próximo envio, sem restart |
| 3 | O membro precisa ter o Onion completo para entrar | Não precisa. O core entrega um **pacote de entrada** com quatro motores; o membro roda tudo com `bash`, sem o wizard |

### 1.4 Os códigos de saída

Todos os motores seguem a mesma régua:

| rc | doctor e `a2a-invite.sh` | `a2a-send.sh` | `a2a-keygen.sh` |
|---|---|---|---|
| **0** | tudo ok | HTTP 200 (ou dry-run montado) | par gerado |
| **1** | medi e está errado | HTTP diferente de 200 | — |
| **2** | não pude medir o que é crítico | uso errado, segredo exposto, erro local | uso errado, chave já existe, diretório versionável |
| **3** | uso inválido | — | — |

---

## Parte II — O operador do core

### 2.1 Antes de começar

Na máquina do core você precisa de `openssl`, `jq`, `curl` e `python3` com PyYAML, e de um relógio
sincronizado por NTP (o gate veta `clock-untrusted` sem prova de relógio). O arquivo de convites é da
**conta do serviço do bridge**, e o bridge o recusa inteiro se ele tiver outro dono. Por isso, em
produção, toda escrita no arquivo passa pelo wrapper da seção 2.4, que roda o motor como essa conta.
O deploy do bridge (o que faz um pino ou uma revogação de chave valer) é sempre do maestro, pelo
caminho de deploy do bridge.

Abra o wizard no chat do Claude Code, na sessão do core:

```
/meta:federation-a2a
```

Ele lê o papel do repo (`source` no core), pergunta a trilha e o id do membro, roda o doctor do lado
certo e mostra o resultado **antes** de propor qualquer escrita. Toda escrita tem dry-run e pede
confirmação.

### 2.2 Trilha 1 — Preparar o receptor

**Por quê.** Antes de convidar alguém, o receptor precisa estar de pé: registro válido, o próprio
bloco `a2a` com a URL, relógio confiável e o endpoint alcançável. A trilha confere sem tocar o serviço.

**Passo a passo.**

```bash
bash .claude/validation/members-validate.sh
bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member <membro> --endpoint <a2a.url>
```

**Saída real** (o membro ainda não mandou chave):

```
$ bash .claude/validation/members-validate.sh
✅ members.yaml válido: <sb>/core/docs/evolution/federation/members.yaml (2 membros)
[rc=0]

$ bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member membro-exemplo --endpoint "$EP"
a2a-doctor · lado receiver · membro membro-exemplo · receptor onion-evolve

✅ (r) registro — registro válido e membro-exemplo presente
❌ (d) pino no registro — membro-exemplo não tem nenhum kid em a2a.keys; todo envio dele veta unknown-kid (sem o .pem no JWKS) ou kid-not-owned-by-from (com o .pem)
      → próximo passo: pine a pública que o membro mandou (/meta:federation-a2a, trilha 2)
⚪ (c) impressão SHA-256 [não crítica] — impressão do membro não informada: o pino não foi conferido contra o que ele gerou
      → próximo passo: passe --fingerprint sha256:<hex> com a impressão que o membro leu do keygen ou do doctor dele
✅ (t) topologia de confiança — a topologia autoriza membro-exemplo → onion-evolve (relay)
⚪ (i) convite por membro [não crítica] — arquivo de convites não informado: o convite por membro não foi conferido (ou o membro ainda usa o pool legado)
      → próximo passo: passe --invites <o arquivo de convites do seu bridge (A2A_INVITES_FILE)>, rodando como a conta do serviço do bridge
✅ (f) relógio — timedatectl NTPSynchronized=yes
✅ (g) endpoint — endpoint alcançável (HTTP 401: alcance, não autorização)

resumo: 4 ok · 1 falha · 2 não medida(s) → ❌ problema (rc 1)
[rc=1]
```

O ❌ em (d) é **esperado** nesta altura: o membro ainda não gerou a chave. A trilha 1 está pronta quando
(r), (t), (f) e (g) saem ✅. O HTTP 401 em (g) é bom sinal: o endpoint responde, só não autoriza quem não
mandou credencial.

**Os erros desta trilha.**

Endpoint fora do ar (aqui, uma porta fechada):

```
❌ (g) endpoint — endpoint inalcançável (conexão recusada, DNS ou timeout de 4 s)
      → próximo passo: confira URL, DNS, firewall e se o serviço do receptor está de pé
```

Opção errada (rc 3, nada é medido):

```
$ bash .claude/utils/federation-transport/a2a-doctor.sh --side receptor --member membro-exemplo
a2a-doctor: --side é member ou receiver
[rc=3]
```

Relógio: o doctor separa "a fonte de tempo disse que não está sincronizada" (rc 1, "ligue o NTP") de
"não há sinal de relógio nenhum" (rc 2, "instale chrony ou systemd-timesyncd"). Num host sem nenhuma
fonte, o operador pode atestar com `A2A_CLOCK_TRUST=attested`, e o doctor diz o que isso é:

```
✅ (f) relógio — A2A_CLOCK_TRUST=attested (atestado do operador: declaração, não medição)
```

> Não medido neste manual: os dois estados quebrados do relógio. A máquina do sandbox tem NTP
> sincronizado e não há como dessincronizá-lo sem mexer no sistema. As frases acima são as do código
> do doctor (`check_clock`), não de uma execução.

### 2.3 Trilha 2 — Convidar um membro

**Por quê.** Convidar é dar ao membro três coisas: um lugar no registro, os motores para entrar e um
bearer com dono. Até a F2 o bearer era anônimo, ficava no ambiente do bridge e cada convite novo pedia
restart. Hoje ele tem dono, validade e revogação, e o bridge relê o arquivo de convites a cada envio.

#### Passo 1 — o registro

Membro novo entra pelo `/meta:federation-member register`. O bloco `a2a` dele nasce assim, sem chave:

```yaml
    a2a:
      sends_to: onion-evolve
      keys: []
```

`sends_to` só aceita um receptor de verdade: `role: source` ou `hub`, e que não seja porta
(`kind: door`). O validador cobra isso no gate do lint, pela REGRA 66 (Registro da federação validado
no gate).

#### Passo 2 — o pacote de entrada

Copie para um diretório de entrega os quatro motores (`a2a-keygen.sh`, `a2a-send.sh`, `a2a-doctor.sh`,
`a2a-invite.sh`, todos de `.claude/utils/federation-transport/`) e um `a2a.conf` com `member=`,
`receiver=` e `endpoint=`. O `a2a.conf` é um lembrete legível: nenhum motor o lê, e ele não tem segredo.
O pacote vai pelo canal combinado; o core não instala nada na máquina do membro (cada repo tem um
escritor só).

#### Passo 3 — o convite

O motor gera o token direto num arquivo 0600, grava no arquivo de convites só o hash, e escreve o
descritor sem segredo que acompanha o token. **Sempre dry-run antes:**

```
$ bash .claude/utils/federation-transport/a2a-invite.sh create membro-exemplo --days 30 --file "$A2A_INVITES" --token-out ../entrega/membro-exemplo.token --dry-run
dry-run: <sb>/svc/a2a-invites.json ganharia a entrada (nada foi escrito, nenhum token gerado):
  + {"expires_at": "2026-11-14T12:34:14Z", "member": "membro-exemplo", "receiver": "onion-evolve", "revoked": false, "token_sha256": "<sha256 do token gerado na execução>"}
  token nasceria em ../entrega/membro-exemplo.token (0600)
  descritor nasceria em ../entrega/membro-exemplo.token.invite.json (0600)
[rc=0]

$ bash .claude/utils/federation-transport/a2a-invite.sh create membro-exemplo --days 30 --file "$A2A_INVITES" --token-out ../entrega/membro-exemplo.token
convite criado: member=membro-exemplo receiver=onion-evolve expires_at=2026-11-14T12:34:14Z id=<id>
token=../entrega/membro-exemplo.token (0600; o conteúdo nunca é impresso: entregue o arquivo fora de banda)
descritor=../entrega/membro-exemplo.token.invite.json (sem segredo; vai junto para o doctor do membro)
[rc=0]
```

O que nasceu na entrega, e o descritor por dentro:

```
-rw------- 1 <conta> <conta>  65 <data> membro-exemplo.token
-rw------- 1 <conta> <conta> 209 <data> membro-exemplo.token.invite.json

{
  "member": "membro-exemplo",
  "receiver": "onion-evolve",
  "expires_at": "2026-11-14T12:34:14Z",
  "revoked": false,
  "token_sha256": "<64 hex>"
}
```

Confira o arquivo e pergunte ao motor o que o bridge responderia ao bearer do membro (a "sonda", que
não lê token nenhum):

```
$ bash .claude/utils/federation-transport/a2a-invite.sh check --file "$A2A_INVITES"
a2a-invite · <sb>/svc/a2a-invites.json · estado do arquivo: ok
✅ (permissao) modo 0600, dono uid 1000, diretório seguro
✅ (entradas) 1 entrada(s), 1 ativa(s), todas na forma do bridge
[rc=0]

$ bash .claude/utils/federation-transport/a2a-invite.sh list --file "$A2A_INVITES" --member membro-exemplo
a2a-invite · <sb>/svc/a2a-invites.json · estado do arquivo: ok
  <id>  membro-exemplo       → onion-evolve     até 2026-11-14T12:34:14Z   ativo
  sonda <id>: o bridge responderia ok
✅ (permissao) modo 0600, dono uid 1000, diretório seguro
✅ (entradas) 1 entrada(s), 1 ativa(s), todas na forma do bridge
[rc=0]
```

Entregue ao membro, **fora de banda** e nunca pelo chat, o token e o descritor, e depois destrua a sua
cópia do token (`shred -u`). O convite vale no próximo envio, sem restart.

**Quando a conta do serviço não escreve no seu diretório.** Gere o token como você e entregue-o ao
motor por redirecionamento (`--token-stdin`): quem abre o arquivo é o seu shell, e o processo da conta
do serviço lê só o descritor aberto. Com `--token-stdin` o descritor nasce onde o `--invite-out` mandar:

```
$ ( umask 077; openssl rand -hex 32 > ../entrega/t2.token ); bash .claude/utils/federation-transport/a2a-invite.sh create membro-exemplo --days 7 --file "$A2A_INVITES" --token-stdin --invite-out ../entrega/t2.invite.json < ../entrega/t2.token
convite criado: member=membro-exemplo receiver=onion-evolve expires_at=2026-10-22T12:34:15Z id=<id>
descritor=../entrega/t2.invite.json (sem segredo; vai junto para o doctor do membro)
[rc=0]
```

Em produção esse é o caminho que o wrapper da seção 2.4 já faz por você.

**Os erros do convite.**

| Situação | Saída real | rc |
|---|---|---|
| membro fora do registro | `a2a-invite: membro 'fantasma' não está no registro (<sb>/core/docs/evolution/federation/members.yaml): registre-o antes (/meta:federation-member register)` | 1 |
| validade fora de 1 a 365 dias | `a2a-invite: --days precisa ser inteiro de 1 a 365: '400'` | 3 |
| o arquivo do token já existe | `a2a-invite: ../entrega/membro-exemplo.token já existe, recuso sobrescrever` | 1 |

Arquivo de convites **gravável pelo grupo**: o bridge recusa o arquivo **inteiro**, e nenhum convite de
membro autentica. O motor diz isso e se recusa a escrever por cima:

```
$ bash .claude/utils/federation-transport/a2a-invite.sh check --file "$A2A_INVITES"
a2a-invite · <sb>/svc/a2a-invites.json · estado do arquivo: error (gravavel-por-grupo-ou-outros)
❌ (arquivo) o bridge recusa o arquivo INTEIRO (gravavel-por-grupo-ou-outros): nenhum convite de membro autentica (convites-indisponiveis)
      → próximo passo: conserte o arquivo (dono = conta do serviço, 0600, diretório sem escrita de grupo/outros, JSON version 1)
[rc=1]
$ bash .claude/utils/federation-transport/a2a-invite.sh create membro-exemplo --days 30 --file "$A2A_INVITES" --token-out ../entrega-z.token
a2a-invite: o arquivo de convites está quebrado (gravavel-por-grupo-ou-outros): hoje o bridge recusa TODO convite de membro (convites-indisponiveis). Rode `a2a-invite.sh check` e conserte à mão antes de escrever
[rc=1]
```

E o membro, do lado dele, recebe do bridge:

```
{"error":"não autorizado","reason":"convites-indisponiveis"}
http=401
```

JSON quebrado tem o mesmo efeito (`estado do arquivo: error (json-invalido)`), e o `revoke` também se
recusa a escrever sobre ele. Por isso a regra é: **o arquivo não se edita à mão**. O motor escreve por
temporário no mesmo diretório e rename, com trava, e nunca deixa um arquivo quebrado de pé.

Um caso que não quebra o bridge, mas reprova o contrato: arquivo **legível** por outros (0644). O bridge
ainda aceita, e o motor avisa:

```
❌ (permissao) modo 0644: o bridge aceita, mas o contrato do arquivo é 0600 (os hashes dos convites não são de mais ninguém)
      → próximo passo: chmod 0600 no arquivo
```

#### Passo 4 — o pino

Quando a pública e a impressão chegarem (a trilha 3 do membro, passo 2), confira a impressão **por
outro canal** (voz, mensagem assinada, presença) antes de pinar. Antes do pino, o doctor do receptor
mostra exatamente o que falta:

```
$ bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member membro-exemplo --fingerprint sha256:<64 hex>
❌ (d) pino no registro — membro-exemplo não tem nenhum kid em a2a.keys; todo envio dele veta unknown-kid (sem o .pem no JWKS) ou kid-not-owned-by-from (com o .pem)
      → próximo passo: pine a pública que o membro mandou (/meta:federation-a2a, trilha 2)
⚪ (c) impressão SHA-256 — sem kid pinado (ou sem openssl) não há impressão a comparar
      → próximo passo: resolva (d)
```

(Trecho: as demais checagens são as da trilha 1.)

Pinar é duas coisas **no mesmo PR**: gravar a pública em
`.claude/utils/federation-transport/jwks/<kid>.pem` (adição deliberada, `git add -f`, porque o
`.gitignore` do JWKS ignora todo `.pem`) e acrescentar o `kid` em `a2a.keys`. Fazer só metade reprova:

```
$ bash .claude/validation/members-validate.sh
❌ members.yaml inválido: <sb>/core/docs/evolution/federation/members.yaml
   ∟ membro 'membro-exemplo': kid 'membro-exemplo-1' pinado em a2a.keys mas jwks/membro-exemplo-1.pem ausente (o gate vetaria unknown-kid)
[rc=1]
```

Com as duas metades, o validador e o doctor com a impressão que o membro mandou:

```
$ bash .claude/validation/members-validate.sh
✅ members.yaml válido: <sb>/core/docs/evolution/federation/members.yaml (2 membros)
[rc=0]
$ bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member membro-exemplo --fingerprint sha256:<64 hex>
a2a-doctor · lado receiver · membro membro-exemplo · receptor onion-evolve

✅ (r) registro — registro válido e membro-exemplo presente
✅ (d) pino no registro — pinado(s): membro-exemplo-1 (RSA 3072)
✅ (c) impressão SHA-256 — jwks/membro-exemplo-1.pem tem a impressão que o membro mandou
✅ (t) topologia de confiança — a topologia autoriza membro-exemplo → onion-evolve (relay)
⚪ (i) convite por membro [não crítica] — arquivo de convites não informado: ...
✅ (f) relógio — timedatectl NTPSynchronized=yes
⚪ (g) endpoint [não crítica] — endpoint não informado

resumo: 5 ok · 0 falha · 2 não medida(s) → ✅ saudável (rc 0)
[rc=0]
```

Se a impressão **não bate**, não pine:

```
❌ (c) impressão SHA-256 — nenhuma pública pinada de membro-exemplo tem a impressão 0000000000000000… que o membro mandou (chave trocada no caminho, ou pino de outra chave)
      → próximo passo: NÃO use este pino: peça ao membro a pública de novo e confira a impressão por outro canal
```

Depois do PR, o merge é pelo caminho verificado. E o pino **só vale no bridge quando o clone que ele
serve recebe o merge**, pelo caminho de deploy do bridge (no core, `ops/update-bridge.sh`, que é do
maestro). O bridge lê o registro e o JWKS desse clone, não do repo de trabalho; o doctor mede o repo
onde roda. Merge sem deploy é um pino que o bridge ainda não conhece.

> **Os dois vetos do pino.** O gate julga o `.pem` antes do dono. Sem o `.pem` no JWKS que o bridge lê,
> o envio volta `unknown-kid:<kid>` (medido no bridge local, com o envio real do membro, seção 4.6); com o
> `.pem` mas sem o `kid` em `a2a.keys` daquele membro, volta `kid-not-owned-by-from:<kid>` (medido na
> bancada, `run_federation_a2a_selftests`). O doctor nomeia os dois, e a cura é a mesma: completar o pino.

### 2.4 A operação de produção: `ops/a2a-invite-live.sh`

**Por quê.** O arquivo de convites de produção mora na home da conta do serviço do bridge, um caminho
**servido**. O veto do MOAT barra escrita à mão ali (barrou a primeira tentativa, corretamente) e
passou a julgar o `--file` do motor como destino de escrita. O único caminho de escrita em produção é
o wrapper core-only `ops/a2a-invite-live.sh`. Ele fixa o arquivo, o motor (o do clone que o bridge
serve) e o registro (o do mesmo clone); não aceita `--file`, `--members` nem `--owner`.

**O que ele faz numa escrita (`--apply`):** trava (a mesma do update do bridge) → ensaio do motor →
backup cifrado e rotulado do estado do bridge → escrita pelo motor como a conta do serviço → `check`
→ prova por contagem (no create: uma entrada a mais, a sonda diz ok, o token bate com o hash; no revoke:
zero convite ativo do membro e a sonda recusa). Falha depois do backup **imprime** o rollback com o
artefato nomeado, e nunca o executa.

**Passo a passo, em produção.**

```bash
# 1. o token, sem ecoar, num arquivo seu 0600
(umask 077; set -C; python3 -c 'import secrets; print(secrets.token_hex(32))' > ~/m.token)
# 2. o ensaio (padrão: nada é escrito, nem o backup)
bash ops/a2a-invite-live.sh create <membro> --days 30 --token-file ~/m.token --invite-out ~/m.invite.json
# 3. de verdade
bash ops/a2a-invite-live.sh create <membro> --days 30 --token-file ~/m.token --invite-out ~/m.invite.json --apply
# 4. conferir
bash ops/a2a-invite-live.sh list --member <membro>
bash ops/a2a-invite-live.sh check
# revogar: ensaio, depois --apply
bash ops/a2a-invite-live.sh revoke <membro>
bash ops/a2a-invite-live.sh revoke <membro> --apply
```

O wrapper chama `sudo -u` da conta do serviço onde precisa; rode-o como você, nunca como root. Depois
de entregar o token ao membro, destrua a sua cópia (`shred -u ~/m.token`): o convite vive no hash, e o
token só precisa existir na máquina do membro.

**Em produção, ele já rodou.** O teste S6 do programa (2026-10-15, pela sessão principal) fez, contra o
bridge de produção, o ciclo inteiro por este wrapper e pelos motores: `create --apply`, doctor do membro
com 8 ok, envio assinado aceito (HTTP 200, `verified`, `gated`), aceite no inbox, `revoke --apply` e o
reenvio recusado com 401 `convite-revogado`, em 56 s de relógio (nó `E_S6_PONTA_A_PONTA_EM_PRODUCAO` do
grafo do programa).

**Saída real.** Produção não foi escrita para este manual. As saídas abaixo são do wrapper em **modo de
teste declarado** (`ONION_A2A_LIVE_TEST=1`, o mesmo que a bancada usa): o motor roda como quem roda, num
arquivo de sandbox, e o backup é um stub. O caminho de escrita é o mesmo de produção.

```
$ bash ops/a2a-invite-live.sh create membro-exemplo --days 30 --token-file <sb>/w/op/m.token --invite-out <sb>/w/op/m.invite.json
dry-run: <sb>/w/data/a2a-invites.json ganharia a entrada (nada foi escrito, nenhum token gerado):
  + {"expires_at": "2026-11-14T12:36:21Z", "member": "membro-exemplo", "receiver": "onion-evolve", "revoked": false, "token_sha256": "<id>…"}
[a2a-invite-live] ENSAIO: nada foi escrito. Para escrever, repita com --apply.
[rc=0]

$ bash ops/a2a-invite-live.sh create membro-exemplo --days 30 --token-file <sb>/w/op/m.token --invite-out <sb>/w/op/m.invite.json --apply
dry-run: <sb>/w/data/a2a-invites.json ganharia a entrada (nada foi escrito, nenhum token gerado):
  + {"expires_at": "2026-11-14T12:36:21Z", "member": "membro-exemplo", "receiver": "onion-evolve", "revoked": false, "token_sha256": "<id>…"}
[a2a-invite-live] backup: <sb>/w/bk-pre-invite-create-membro-exemplo.tgz
convite criado: member=membro-exemplo receiver=onion-evolve expires_at=2026-11-14T12:36:21Z id=<id>
descritor=/tmp/onion-a2a-invite.<aleatório>/invite.json (sem segredo; vai junto para o doctor do membro)
a2a-invite · <sb>/w/data/a2a-invites.json · estado do arquivo: ok
✅ (permissao) modo 0600, dono uid 1000, diretório seguro
✅ (entradas) 1 entrada(s), 1 ativa(s), todas na forma do bridge
[a2a-invite-live] OK — convite de 'membro-exemplo' criado: 0 → 1 entrada(s); check 0; sonda ok; token↔descritor conferidos
[a2a-invite-live] entregue ao membro, fora de banda: o token (<sb>/w/op/m.token) e o descritor (<sb>/w/op/m.invite.json)
[rc=0]

$ bash ops/a2a-invite-live.sh revoke membro-exemplo --apply
dry-run: 1 entrada(s) de 'membro-exemplo' passariam a revoked: true (nada foi escrito):
  ~ id=<id> receiver=onion-evolve expires_at=2026-11-14T12:36:21Z revoked: false → true
[a2a-invite-live] backup: <sb>/w/bk-pre-invite-revoke-membro-exemplo.tgz
revogado(s): 1 convite(s) de 'membro-exemplo' (vale no próximo POST /a2a, sem restart)
a2a-invite · <sb>/w/data/a2a-invites.json · estado do arquivo: ok
✅ (permissao) modo 0600, dono uid 1000, diretório seguro
✅ (entradas) 1 entrada(s), 0 ativa(s), todas na forma do bridge
[a2a-invite-live] OK — 'membro-exemplo': 1 → 0 convite(s) ativo(s); check 0; a sonda do bridge recusa (vale no próximo POST /a2a, sem restart)
[rc=0]
```

(O `descritor=/tmp/...` do meio é o temporário da conta do serviço; o wrapper o entrega no seu
`--invite-out` e apaga o temporário na saída.)

**Os erros do wrapper.**

| Situação | Saída real | rc |
|---|---|---|
| token legível por outros | `[a2a-invite-live] ERRO: o --token-file tem modo 644: precisa ser 0600 ou 0400 (chmod 600)` | 1 |
| tentar outro arquivo | `[a2a-invite-live] ERRO: opção não aceita: --file (o arquivo, o motor e o registro são fixos)` | 3 |
| redirecionar produção por ambiente | `[a2a-invite-live] ERRO: variável ONION_A2A_LIVE_* sem ONION_A2A_LIVE_TEST=1: produção não se redireciona por ambiente` | 3 |

Pelo código do wrapper (não exercitados aqui): rodar como root sai rc 3; rodar de uma cópia que não é
arquivo rastreado e limpo de um checkout sai rc 3; outra execução segurando a trava sai rc 2 ("tente de
novo"); backup que falha sai rc 2 sem escrever nada.

### 2.5 Trilha 4 — Conferir e diagnosticar

**Por quê.** Quando algo não passa, a pergunta certa é "qual camada recusou, e por quê". O doctor do
receptor, com o arquivo de convites e o descritor, responde sem ler token nenhum. Em produção, rode-o
como a conta do serviço do bridge (o arquivo é 0600 dela).

```
$ bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member membro-exemplo --invites "$A2A_INVITES" --invite ../entrega/membro-exemplo.token.invite.json --endpoint "$EP"
a2a-doctor · lado receiver · membro membro-exemplo · receptor onion-evolve

✅ (r) registro — registro válido e membro-exemplo presente
✅ (d) pino no registro — pinado(s): membro-exemplo-1 (RSA 3072)
⚪ (c) impressão SHA-256 [não crítica] — impressão do membro não informada: o pino não foi conferido contra o que ele gerou
      → próximo passo: passe --fingerprint sha256:<hex> com a impressão que o membro leu do keygen ou do doctor dele
✅ (t) topologia de confiança — a topologia autoriza membro-exemplo → onion-evolve (relay)
✅ (i) convite por membro — o guard do bridge aceitaria o convite de membro-exemplo para onion-evolve (<id>)
✅ (f) relógio — timedatectl NTPSynchronized=yes
✅ (g) endpoint — endpoint alcançável (HTTP 401: alcance, não autorização)

resumo: 6 ok · 0 falha · 1 não medida(s) → ✅ saudável (rc 0), SEM conferir a impressão do membro: antes de PINAR, rode com --fingerprint
[rc=0]
```

A checagem (i) diz o motivo que o guard do bridge daria. Os motivos abaixo foram medidos assim: `ok`,
`convite-revogado` e `convites-indisponiveis` pela (i) do doctor; `convite-vencido` pela sonda do
`a2a-invite.sh list`, que é o mesmo julgamento que a (i) chama:

| (i) diz | O que é | Cura |
|---|---|---|
| `ok` | o convite autentica | — |
| `convite-revogado` | todas as entradas do membro têm `revoked: true` | convite novo, se for o caso |
| `convite-vencido` | `expires_at` no passado | convite novo |
| `convites-indisponiveis` | o arquivo inteiro está recusado (dono, modo, diretório ou JSON) | `a2a-invite.sh check` e consertar o arquivo |

Leia cada ❌ e cada ⚪ com o próximo passo dele. Um ⚪ marcado `[não crítica]` é algo que você não
perguntou (não passou a flag), não algo saudável.

### 2.6 Trilha 5 — Aceitar a fila

**Por quê.** O endpoint só enfileira. Nada que chega ao vivo é aplicado: promover um sinal para o
inbox é **ato humano**, um registro de cada vez, depois de ler. A fila mora na conta do serviço;
listá-la é do maestro, com o acesso dele.

Um envio aceito pelo gate vira um registro assim (campos selecionados):

```
{
  "from": "membro-exemplo",
  "verdict": { "verified": true, "apply_mode": "gated" },
  "signal": { "id": "2026-10-15-membro-exemplo-th-…", "kind": "question", "from": "membro-exemplo", "to": "onion-evolve" }
}
```

Leia o sinal, confirme e aceite:

```
$ bash .claude/utils/federation-transport/a2a-accept.sh ../rec.json
aceito → <sb>/core/docs/evolution/inbox/2026-10-15-membro-exemplo-th-….md
  (próximo: /meta:co-evolve p/ triar; e limpar o registro da fila do bridge — ato humano via '!')
[rc=0]
```

Aceitar de novo não sobrescreve nada (rc 0, "já aceito"). Um registro que o gate não verificou é
recusado, e não se força:

```
$ bash .claude/utils/federation-transport/a2a-accept.sh ../rec-bad.json
RECUSADO: registro não-verificado (verdict.verified != true) — não aceito.
[rc=1]
```

Depois do aceite, o sinal segue a triagem normal pelo `/meta:co-evolve`. Membro regulado continua
`propose-only`: o gate marca o modo, e nada muda nisso por ser ao vivo.

### 2.7 Trilha 6 — Revogar

**Por quê.** Há duas coisas a revogar, e elas valem em tempos diferentes. O **convite** vale no próximo
envio, sem restart nem deploy. A **chave** só deixa de valer quando o clone servido recebe o merge.
Por isso a ordem é sempre: **o convite primeiro**.

#### O convite

```
$ bash .claude/utils/federation-transport/a2a-invite.sh revoke membro-exemplo --file "$A2A_INVITES" --dry-run
dry-run: 3 entrada(s) de 'membro-exemplo' passariam a revoked: true (nada foi escrito):
  ~ id=<id> receiver=onion-evolve expires_at=2026-11-14T12:34:14Z revoked: false → true
  ~ id=<id> receiver=onion-evolve expires_at=2026-10-22T12:34:15Z revoked: false → true
  ~ id=<id> receiver=onion-evolve expires_at=2026-11-14T12:34:15Z revoked: false → true
[rc=0]

$ bash .claude/utils/federation-transport/a2a-invite.sh revoke membro-exemplo --file "$A2A_INVITES"
revogado(s): 3 convite(s) de 'membro-exemplo' (vale no próximo POST /a2a, sem restart)
[rc=0]
```

O `revoke` marca **todas** as entradas do membro. Em produção, é o
`bash ops/a2a-invite-live.sh revoke <membro> --apply` da seção 2.4. A conferência:

```
❌ (i) convite por membro — nenhum convite de membro-exemplo passaria no guard do bridge: <id> convite-revogado; <id> convite-revogado; <id> convite-revogado
      → próximo passo: crie um convite novo (a2a-invite.sh create membro-exemplo …) e entregue o token fora de banda
```

E o próximo envio do membro, com o **mesmo** processo do bridge no ar desde o início do sandbox:

```
{"error":"não autorizado","reason":"convite-revogado"}
http=401
```

> **O doctor do membro não sabe da revogação.** O descritor que o membro guarda é uma cópia local e
> continua dizendo "válido até…". O doctor dele avisa isso na própria linha: *"a revogação só se mede
> no receptor"*. A verdade sobre o convite é a do arquivo do bridge.

#### A chave

Tire o `kid` de `a2a.keys` e a pública do JWKS **no mesmo PR** (o validador reprova `kid` sem `.pem`, e
`.pem` sem `kid` não autoriza nada), e peça ao membro que destrua a privada
(`shred -u ~/.config/onion/a2a/<kid>.key.pem`). Confira com o doctor nomeando o `kid` revogado, que tem
de sair falha em (d):

```
$ bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member membro-exemplo --kid membro-exemplo-1
❌ (d) pino no registro — kid membro-exemplo-1 não está em a2a.keys de membro-exemplo
      → próximo passo: pine de novo a pública que o membro mandou, conferindo a impressão
```

Sem `--kid`, o doctor confere só os kids que restam. E lembre: até o clone servido receber o merge, o
`kid` revogado **segue aceito no bridge**.

### 2.8 O pool legado

Antes da F2, o convite era um bearer anônimo na variável `INVITE_TOKENS_A2A` do ambiente do bridge:
sem dono e sem validade. O bearer não amarrava o remetente: qualquer portador passava pelo bridge com
qualquer `from`, e só a assinatura do gate (o `kid` pinado do próprio membro) segurava o envio. Ele segue aceito para
quem ainda o usa, e o bridge registra no log a cada uso que ele está depreciado. Em 2026-10-15 o
maestro decidiu **esvaziá-lo já**, sem esperar a migração dos remetentes atuais, que voltam por convite
por membro. Tirar um bearer do pool é editar o ambiente do serviço, e isso é do maestro, pelo caminho
de deploy do bridge; o wizard não toca o ambiente.

Um bridge anterior à F2 ignora o arquivo de convites. Pelo código anterior à F2 (não medido neste
manual), o membro recebe um 401 **sem** `reason`, com a mensagem
`não autorizado — /a2a requer token do pool a2a dedicado`, mesmo com um convite que o doctor do receptor
diz estar ok. Esse é o sinal de que o clone servido não recebeu a F2.

---

## Parte III — O operador de um hub

### 3.1 O que vale hoje

Um hub é um adotante com `role: hub`, que coordena filhos. Na F1 e na F2, o wizard no hub oferece só
**duas trilhas**: a 3 (entrar na rede do core, como membro) e a 4 (diagnosticar). Para o hub falar com
o core, siga a **Parte IV** como se fosse um membro: gere a chave, mande a pública ao core, grave o
convite e envie. A única diferença é que o hub costuma ter o Onion instalado, e então pode rodar o
wizard em vez do pacote solto.

### 3.2 O que chega na F3

A F3 está em construção paralela no momento em que este manual foi escrito. O que ela entrega, pelo
plano aprovado em 2026-10-14, e que **ainda não existe** em `main`:

- **chega na F3:** o registro do core passa a aceitar `parent: <hub>` nos filhos;
- **chega na F3:** as trilhas 2 (convidar) e 5 (aceitar a fila) rodam no hub, para os filhos dele;
- **chega na F3:** o bridge do core ganha **receptor múltiplo**, com a rota `/a2a/<hub>`: o hub
  recebe os sinais dos filhos pelo bridge do core, sem servidor próprio;
- **chega na F3:** o `/meta:co-deliver` e o `/meta:co-relay` passam a tratar `hub` e `consumer`.

Este manual não descreve passo a passo nem saída da F3, porque ela não está pronta e saída inventada
não serve a ninguém. Quando ela entrar, esta parte ganha as trilhas do hub com a saída real.

**O que já foi medido em protótipo.** O spike S5 (2026-10-14) mediu um protótipo do receptor múltiplo
num bridge local. Não é o código da F3, mas mostra o contrato que ela persegue:

| Caso do protótipo | Resposta |
|---|---|
| `/a2a/<hub>` com `role: hub` | 200 `input_required` |
| `/a2a/<x>` com um papel que não recebe | 400 `receptor-nao-recebe:role=adopted` |
| rota do hub com `aud` do core | 403 `claim-aud-mismatch` (veto do gate) |
| receptor fora do registro | 404 `receptor-desconhecido` |
| porta pública como receptor | 403 `trust-denied` |
| convite do core usado na rota do hub | 403 `convite-de-outro-receptor` |

### 3.3 Depois: o hub com servidor próprio (F4)

Um hub com registro e receptor próprios, desconectado do core, é a F4, e está **gated** até o primeiro
hub pedir para operar sem o core.

---

## Parte IV — O membro que entra

### 4.1 O que você recebe e o que precisa

Do core você recebe, por um canal combinado:

- o **pacote de entrada**: `a2a-keygen.sh`, `a2a-send.sh`, `a2a-doctor.sh` e `a2a-invite.sh`, mais um
  `a2a.conf` que lembra seu id, o receptor e o endpoint;
- mais tarde, o **token** do convite e o **descritor** dele (`*.invite.json`), fora de banda.

Na sua máquina você precisa de `bash`, `openssl`, `jq`, `curl` e `python3`, e de relógio sincronizado
por NTP. Não precisa do Onion instalado. Rode tudo **fora** de qualquer repositório git, de preferência
numa pasta só do pacote.

### 4.2 Passo 1 — Gerar a chave

```
$ bash a2a-keygen.sh --member membro-exemplo
kid=membro-exemplo-1
public=<sb>/home-membro/.config/onion/a2a/membro-exemplo-1.pem
fingerprint=sha256:<64 hex>
(privada em <sb>/home-membro/.config/onion/a2a/membro-exemplo-1.key.pem, modo 0600, nunca impressa; mande ao receptor SÓ a pública e confira a impressão por canal fora de banda)
[rc=0]
```

Anote o `kid` e a impressão. A pasta fica assim:

```
drwx------ 2 <conta> <conta> 4096 <data> .
-rw------- 1 <conta> <conta> 2488 <data> membro-exemplo-1.key.pem
-rw-r--r-- 1 <conta> <conta>  625 <data> membro-exemplo-1.pem
```

O keygen nunca sobrescreve uma chave, e nunca gera a privada onde um `git add -A` a levaria ao commit:

```
$ bash a2a-keygen.sh --member membro-exemplo
a2a-keygen: chave privada já existe, recuso sobrescrever: <sb>/home-membro/.config/onion/a2a/membro-exemplo-1.key.pem (rotação = --n 2)
[rc=2]

$ bash a2a-keygen.sh --member membro-exemplo --dir <sb>/repo-qualquer/chaves
a2a-keygen: <sb>/repo-qualquer/chaves está dentro de um repositório git e o .gitignore não cobre membro-exemplo-1.key.pem; gere fora do repo (o default é ~/.config/onion/a2a)
[rc=2]
```

### 4.3 Passo 2 — Mandar a pública

Mande ao core **só** o arquivo `<kid>.pem` e diga a impressão **por outro canal** (uma ligação, uma
mensagem assinada, pessoalmente). Se você é adotante com o carteiro upstream, a pública pode ir pelo
`/meta:co-relay`, que a entrega no inbox do core sem commit. A privada não sai da sua máquina, nunca.

### 4.4 Passo 3 — Gravar o convite

Quando o token chegar, grave-o com `umask 077` em `~/.config/onion/a2a/bridge-token`. Nunca o cole no
chat, num argumento de comando ou num arquivo legível por outros. Guarde o descritor ao lado, com o nome
que ele chegou (no exemplo, `~/.config/onion/a2a/membro-exemplo.token.invite.json`). O doctor **não** o
procura sozinho: passe-o sempre em `--invite`, senão a checagem (e) confere só o arquivo do token. Para
conferir que o token é o deste descritor, sem imprimir nada:

```
$ bash a2a-invite.sh inspect --invite ~/.config/onion/a2a/membro-exemplo.token.invite.json --member membro-exemplo --receiver onion-evolve --token-file ~/.config/onion/a2a/bridge-token
ativo: convite de 'membro-exemplo' válido até 2026-11-14T12:34:14Z
[rc=0]
```

### 4.5 Passo 4 — O doctor do membro

Sem o token, o doctor aponta o que falta:

```
$ bash a2a-doctor.sh --member membro-exemplo --endpoint "$EP"
a2a-doctor · lado member · membro membro-exemplo · receptor ?

✅ (a) chave privada — chave privada RSA 3072 bits presente e legível (kid membro-exemplo-1)
✅ (b) permissão — privada 600 · diretório 700
✅ (c) impressão SHA-256 — sha256:<64 hex>
⚪ (d) pino no registro — o registro do receptor não está nesta máquina; o pino vive no repo dele
      → próximo passo: peça ao receptor que rode este doctor com --side receiver --member membro-exemplo (ou passe --members com uma cópia ATUAL do registro)
❌ (e) credencial do canal — token do canal ausente em <sb>/home-membro/.config/onion/a2a/bridge-token
      → próximo passo: peça ao receptor um convite novo (ele entrega o bearer fora de banda); grave-o com umask 077 em <sb>/home-membro/.config/onion/a2a/bridge-token, nunca colado no chat nem em argv
✅ (f) relógio — timedatectl NTPSynchronized=yes
✅ (g) endpoint — endpoint alcançável (HTTP 401: alcance, não autorização)
⚪ (h) envio sintético — o gate a2a-verify.sh não está nesta instalação
      → próximo passo: peça ao receptor o lado dele (--side receiver), ou rode de uma instalação com o gate

resumo: 5 ok · 1 falha · 2 não medida(s) → ❌ problema (rc 1)
[rc=1]
```

Com o token e o descritor, o melhor que a sua máquina consegue dizer é **rc 2**, e isso é esperado
(trecho: sem o cabeçalho e sem as linhas de próximo passo de d e h, que são as do bloco anterior):

```
$ bash a2a-doctor.sh --member membro-exemplo --endpoint "$EP" --invite ~/.config/onion/a2a/membro-exemplo.token.invite.json
✅ (a) chave privada — chave privada RSA 3072 bits presente e legível (kid membro-exemplo-1)
✅ (b) permissão — privada 600 · diretório 700
✅ (c) impressão SHA-256 — sha256:<64 hex>
⚪ (d) pino no registro — o registro do receptor não está nesta máquina; o pino vive no repo dele
✅ (e) credencial do canal — token do canal presente, modo 600; convite de 'membro-exemplo' válido até 2026-11-14T12:34:14Z (a revogação só se mede no receptor)
✅ (f) relógio — timedatectl NTPSynchronized=yes
✅ (g) endpoint — endpoint alcançável (HTTP 401: alcance, não autorização)
⚪ (h) envio sintético — o gate a2a-verify.sh não está nesta instalação

resumo: 6 ok · 0 falha · 2 não medida(s) → ⚪ não pude medir o que é crítico (rc 2): não sei não é saudável
[rc=2]
```

**Por que rc 2.** A pergunta "minha chave está pinada?" só tem resposta com o registro do receptor, e
ele não está na sua máquina. A resposta definitiva é o doctor do receptor (`--side receiver`) rodando
no core: peça ao operador do core o lado dele. Não se responde de memória.

Quando o doctor roda numa instalação que **tem** o registro e o gate (no sandbox, o mesmo doctor
rodado a partir do core de fixture, com a HOME do membro), as oito checagens fecham (trecho: só as
duas que mudaram e o resumo):

```
✅ (d) pino no registro — kid 'membro-exemplo-1' pinado e jwks/membro-exemplo-1.pem tem a mesma impressão
✅ (h) envio sintético — o gate local aceitou o envio sintético (verified, gated, dry-run; relógio julgado em f)

resumo: 8 ok · 0 falha · 0 não medida(s) → ✅ saudável (rc 0)
```

O envio sintético usa um envelope de `jti` novo, num estado de replay descartável: conferir não gasta
nenhum sinal seu.

**Os erros do lado do membro, e o que o doctor diz.**

Token legível por outros (0644):

```
❌ (e) credencial do canal — o token está 644 (grupo/outros leem o bearer)
      → próximo passo: peça ao receptor um convite novo (ele entrega o bearer fora de banda); grave-o com umask 077 em …/bridge-token, nunca colado no chat nem em argv
```

Token trocado, que não é o do descritor:

```
❌ (e) credencial do canal — o token do canal NÃO é o deste descritor (o hash não bate): o bridge responderia credencial-desconhecida
```

Privada legível por outros:

```
❌ (b) permissão — membro-exemplo-1.key.pem está 644 (grupo/outros leem a chave)
      → próximo passo: chmod 0700 <dir> e chmod 0600 na privada; se a máquina tem outras contas, trate a chave como VAZADA: gere a N+1 e peça a revogação da antiga
```

Duas chaves na pasta (depois de uma rotação), sem dizer qual é a vigente:

```
⚪ (a) chave privada — há 2 chaves de membro-exemplo em <sb>/home-membro/.config/onion/a2a e não sei qual é a vigente
      → próximo passo: passe --kid <kid>
```

### 4.6 Passo 5 — Enviar

Primeiro, o envelope em dry-run, para conferir:

```
$ bash a2a-send.sh --dry-run --from membro-exemplo --to onion-evolve --body "olá do membro-exemplo"
{
  "jws": "<JWS assinado>",
  …
(dry-run: nada enviado, nada gravado)
[rc=0]
```

O envelope do dry-run é um JWS **assinado e válido por 300 s**. Confira e descarte; não o cole em canal
compartilhado.

Depois do merge **e do deploy** do pino no core, o envio de verdade:

```
$ bash a2a-send.sh --from membro-exemplo --to onion-evolve --endpoint "$EP" --body "olá do membro-exemplo"
{"kind":"task","id":"<task-id>","status":{"state":"input_required","message":"sinal verificado; enfileirado para o gate humano do maestro (nada aplicado)"},"verified":true,"gated":true,"committed":false,"apply_mode":"gated","regulated":false}
http=200 jti=nb-<…> thread=th-20261015-<…>
[rc=0]
```

`input_required` quer dizer exatamente isso: o sinal está na fila, esperando o operador do core.

**Os erros do envio.** Todos medidos contra o bridge local. Os 401 são do guard do convite (a
credencial); os 403 são do gate (o sinal).

| Situação | Resposta real | rc |
|---|---|---|
| antes do pino (sem `.pem` no JWKS do receptor) | 403 `unknown-kid:membro-exemplo-1` (camada `jws`) | 1 |
| chave de rotação ainda não pinada (`--kid membro-exemplo-2`) | 403 `unknown-kid:membro-exemplo-2` | 1 |
| o mesmo envelope de novo | 403 `replay` (camada `replay`) | 1 |
| envelope de remetente antigo, sem `body_sha256` | 403 `jws-missing-body-sha256` (camada `body`) | — |
| bearer que o bridge não conhece | 401 `credencial-desconhecida` | 1 |
| convite de outro membro (o `from` não é o dono) | 401 `convite-de-outro-membro` | 1 |
| convite vencido | 401 `convite-vencido` | 1 |
| convite revogado | 401 `convite-revogado` | 1 |
| arquivo de convites do receptor quebrado | 401 `convites-indisponiveis` | 1 |

O remetente também recusa **antes de sair da sua máquina** (rc 2, nada enviado):

```
$ bash a2a-send.sh --from membro-exemplo --to onion-evolve --endpoint "$EP" --body "olá"
a2a-send: o token do canal está com modo 644 (grupo/outros leem): chmod 600 <sb>/home-membro/.config/onion/a2a/bridge-token, e trate-o como vazado se a máquina tem outras contas
[rc=2]

$ bash a2a-send.sh --dry-run --from membro-exemplo --to onion-evolve --body x
a2a-send: a chave privada está com modo 644 (grupo/outros leem): chmod 600 <sb>/home-membro/.config/onion/a2a/membro-exemplo-1.key.pem, e trate-o como vazado se a máquina tem outras contas
[rc=2]

$ bash a2a-send.sh --from membro-exemplo --to onion-evolve --endpoint http://exemplo.invalid/a2a --body "x"
a2a-send: --endpoint em http:// só para loopback; o bearer viajaria em claro: use https://
[rc=2]
```

O corpo tem de ser UTF-8 válido e ter no máximo 8192 bytes; para um corpo em arquivo, use
`--body-file`, que assina os bytes exatos do arquivo.

### 4.7 Rotação da chave

Gere a próxima com `--n`, mande a pública nova e a impressão, e espere o pino dela. Depois, envie
nomeando o `kid` (o default é `<id>-1`) e rode o doctor com `--kid`:

```bash
bash a2a-keygen.sh --member <id> --n 2
bash a2a-send.sh --from <id> --to <receptor> --kid <id>-2 --endpoint <url> --body "..."
bash a2a-doctor.sh --member <id> --kid <id>-2
```

Peça ao core a revogação da chave antiga e destrua a privada dela com `shred -u`.

### 4.8 Quem já tinha remetente próprio

Troque pelo `a2a-send.sh`. O envelope antigo, sem `body_sha256`, é vetado pelo gate
(`jws-missing-body-sha256`), e o remetente canônico já monta o envelope que o gate aceita.

---

## Parte V — Segurança

### 5.1 Onde cada segredo mora, e onde nunca vai

| Segredo | Mora | Nunca vai |
|---|---|---|
| **chave privada** | `~/.config/onion/a2a/<kid>.key.pem`, 0600, diretório 0700, na conta do membro | para fora da máquina, para o git, para o chat, para argv |
| **token do convite** | arquivo 0600 do membro (`bridge-token`); no bridge, só o SHA-256 dele | chat, argv, stdout, log, arquivo legível por outros |
| **arquivo de convites** | home da conta do serviço do bridge, 0600, diretório sem escrita de grupo/outros | edição à mão; git (os hashes não se versionam) |

O que viaja é só o que não é segredo: a **pública**, a **impressão** e o **descritor** do convite.
Mesmo assim, a impressão se confere por outro canal, porque é ela que prova que a pública não foi
trocada no caminho.

Os motores cuidam disso sozinhos: o keygen nasce a privada em 0600; o `a2a-invite.sh` gera o token de
`/dev/urandom` direto no arquivo, sem seguir symlink e sem sobrescrever; o `a2a-send.sh` entrega o
bearer ao `curl` só por arquivo de cabeçalho e **recusa** token ou chave legível por outros. O wizard
nunca pede token ou chave no chat.

### 5.2 Se algo vazar

| Vazou | Faça, nesta ordem | Vale quando |
|---|---|---|
| **o token** | revogue o convite (trilha 6) e emita outro | no próximo envio, sem restart |
| **a chave privada** | revogue o convite; gere a chave N+1; peça o pino da nova e a revogação do `kid` antigo (mesmo PR) | o convite, na hora; o `kid`, quando o clone servido recebe o merge |
| **o arquivo de convites** (alguém o leu) | são só hashes, mas trate como incidente: revogue os convites e reemita | na hora |

### 5.3 As regras que não se dobram

1. **Na dúvida, veta.** O gate degrada para veto, nunca para pular. O doctor herda a régua: "não pude
   medir" é rc 2, nunca saudável.
2. **A confiança nasce no merge que chega ao clone servido**, conferida fora de banda. Pública que
   chegou por um canal só e não foi conferida não é pinada.
3. **O aceite é humano**, um por vez. O wizard lista e prepara; não aceita em lote.
4. **Cada repo tem um escritor.** O core nunca commita no repo do membro, e o membro nunca no do core.
5. **Conferir não gasta o sinal.** O doctor só testa com envelope sintético de `jti` novo.
6. **O bearer tem dono.** O guard do bridge exige que o dono do convite seja o `from` do envelope,
   antes do gate; o gate prova o mesmo `from` pela assinatura.
7. **Deploy é do maestro.** O wizard não faz deploy, não edita o ambiente do bridge, não reinicia nada.
   Em produção, o convite se escreve pelo wrapper; o pino e a revogação de chave valem pelo update do
   bridge.

A doutrina completa, com as nove cláusulas e a evidência de cada uma, vive no fragmento canônico do
wizard (`common:prompts:federation-a2a-doctrine`).

---

## Parte VI — Mesa de diagnóstico

O sintoma, onde ele aparece, e a cura. Medido neste manual, salvo onde a linha diz outra fonte.

| Sintoma | Aparece em | Causa | Cura |
|---|---|---|---|
| `credencial-ausente` | log do bridge, 401 | envio sem bearer | grave o token em `bridge-token` |
| `credencial-desconhecida` | send, 401 | o token não está no arquivo de convites | `inspect` do descritor; peça convite novo |
| 401 sem `reason`, "requer token do pool a2a dedicado" | send (pelo código, não medido) | o bridge é anterior à F2 | deploy do bridge (maestro) |
| `convite-de-outro-membro` | send, 401 | o `from` não é o dono do convite | envie com o seu id e o seu token |
| `convite-vencido` | send 401; sonda (i) | `expires_at` no passado | convite novo |
| `convite-revogado` | send 401; sonda (i) | o receptor revogou | convite novo, se for o caso |
| `convites-indisponiveis` | send 401; check | arquivo de convites recusado inteiro (dono, modo, diretório, JSON) | `a2a-invite.sh check` e consertar |
| `unknown-kid:<kid>` | send, 403 | sem `.pem` do `kid` no JWKS que o bridge lê | pino + merge + deploy |
| `kid-not-owned-by-from:<kid>` | gate, 403 (medido na bancada) | `.pem` existe, mas o `kid` não está em `a2a.keys` do membro | completar o pino |
| `replay` | send, 403 | o mesmo `jti` de novo | envie um envelope novo |
| `jws-missing-body-sha256` | send, 403 | remetente antigo | trocar pelo `a2a-send.sh` |
| `clock-untrusted` | gate, 403 | sem prova de relógio | NTP (doctor, checagem f) |
| doctor do membro rc 2 em (d) e (h) | doctor do membro | o registro e o gate não estão na máquina do membro | o doctor do receptor no core |
| ❌ (c) no receptor | doctor do receptor | a impressão não bate | não pinar; pedir a pública de novo |

> `clock-untrusted` está na tabela pelo código do gate e do doctor; não foi provocado neste sandbox
> (ver a nota da seção 2.2).

---

## Epílogo — O que ainda falta

O ponta a ponta já passou em produção: o S6 (2026-10-15) levou um membro de teste do convite à
revogação só com os motores e o wrapper, em 56 s. Ele deixou dois limites declarados: membro e core
rodaram na mesma conta de sistema (a separação de contas está provada só na bancada), e dois passos
seguem humanos, entregar o token fora de banda e limpar o registro da fila do bridge.

Há peças que não aconteceram e estão desenhadas. A **F3** traz o hub como receptor dos filhos, pelo
bridge do core. A **F4**, o hub com servidor próprio, está gated até o primeiro hub pedir. E o **S7**,
com um adotante real trocando o remetente próprio pelo canônico, é o que falta para a pergunta que abriu
este programa fechar: *um wizard só leva o core, um membro e um hub da chave ao sinal aceito e à
revogação, sem o maestro digitar shell além das respostas?*

Até lá, este manual é o mapa, e o doctor é a bússola. Quando um diz uma coisa e o outro diz outra,
**o doctor vence**: ele mede, o manual só conta.

---

## Apêndice A — Referência rápida

| Quem | Trilha | Comando |
|---|---|---|
| core | 1 | `bash .claude/validation/members-validate.sh` |
| core | 1, 4 | `bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member <id> [--endpoint <url>] [--fingerprint sha256:<hex>] [--invites <arq>] [--invite <descritor>] [--kid <kid>]` |
| core | 2 | `bash .claude/utils/federation-transport/a2a-invite.sh create <id> --days N --file <arq> (--token-out <arq> \| --token-stdin) [--invite-out <arq>] [--dry-run]` |
| core | 2, 4 | `bash .claude/utils/federation-transport/a2a-invite.sh check --file <arq>` · `list --file <arq> --member <id>` |
| core (produção) | 2, 6 | `bash ops/a2a-invite-live.sh create\|revoke\|list\|check …` (ensaio por padrão; `--apply` escreve) |
| core | 5 | `bash .claude/utils/federation-transport/a2a-accept.sh <registro.json>` |
| core | 6 | `bash .claude/utils/federation-transport/a2a-invite.sh revoke <id> --file <arq> [--dry-run]` |
| membro | 3 | `bash a2a-keygen.sh --member <id> [--n N]` |
| membro | 3 | `bash a2a-invite.sh inspect --invite <descritor> --member <id> --token-file <arq>` |
| membro | 3, 4 | `bash a2a-doctor.sh --member <id> [--endpoint <url>] [--invite <descritor>] [--kid <kid>]` |
| membro | 3 | `bash a2a-send.sh [--dry-run] --from <id> --to <receptor> [--endpoint <url>] (--body "…" \| --body-file <arq>) [--kid <kid>]` |

No chat do Claude Code, o ponto de entrada é sempre `/meta:federation-a2a [preparar|convidar|entrar|conferir|aceitar|revogar] [--member <id>]`.

## Apêndice B — Caminhos

| O quê | Onde |
|---|---|
| motores | `.claude/utils/federation-transport/a2a-{keygen,send,doctor,invite,verify,accept}.sh` |
| registro | `docs/evolution/federation/members.yaml` (bloco `a2a` por membro) |
| públicas pinadas | `.claude/utils/federation-transport/jwks/<kid>.pem` |
| chave do membro | `~/.config/onion/a2a/<kid>.key.pem` (privada) e `<kid>.pem` (pública) |
| token do membro | `~/.config/onion/a2a/bridge-token` |
| arquivo de convites | o `A2A_INVITES_FILE` do bridge, na conta do serviço |
| fila | o `A2A_PENDING_DIR` do bridge, na conta do serviço |
| inbox depois do aceite | `docs/evolution/inbox/` |
| wizard e doutrina | `.claude/commands/meta/federation-a2a.md` · `.claude/commands/common/prompts/federation-a2a-doctrine.md` |
| bancada | `run_federation_a2a_selftests` e `run_a2a_invite_live_selftests` em `.claude/validation/lint-selftest.sh` |

## Apêndice C — Como as saídas foram geradas

Em 2026-10-15, dois roteiros descartáveis, fora do repositório:

- um **core de fixture** num repositório git temporário, com cópias dos motores, do validador do
  registro e da checagem de topologia desta árvore, e um `members.yaml` de dois membros
  (`onion-evolve` e `membro-exemplo`);
- um **pacote de entrada** fora de qualquer repo, com os quatro motores, e uma **HOME temporária** para
  o membro;
- um **arquivo de convites** de fixture, num diretório 0700;
- o **bridge local**: o `main` do `onion-bridge` (com o convite por membro da F2), em `127.0.0.1` numa
  porta livre, com `ONION_CWD` apontando o core de fixture, sem `.env`;
- o wrapper de produção em **modo de teste declarado**, com o backup trocado por um stub.

Um só caso foi forjado à mão no sandbox, porque o motor não o produz: o convite vencido (o motor só
aceita validade de 1 a 365 dias para a frente). O `expires_at` dele foi editado na fixture, e a saída
mostrada é a resposta real do motor e do bridge a esse arquivo. O envelope sem `body_sha256` foi
montado com `openssl`, imitando um remetente antigo.

A versão determinística e permanente destas medições é a bancada: as famílias
`run_federation_a2a_selftests` e `run_a2a_invite_live_selftests`, cada caso com mutante provado.

---

*Manual escrito pelo Sistema Onion em outubro de 2026, a partir dos fluxos e da saída reais do
`/meta:federation-a2a` (F5 do configurador A2A, Linear SAC-133).*
*Versão viva: `docs/applying/onion-a2a-manual.md` no repositório do core.*
