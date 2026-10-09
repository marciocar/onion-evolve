# Identidade e Acesso na VPS do Onion — arquitetura e doutrina

> **Versão** 1.0.0 · **2026-08-10** · **SSOT**: [`graph/identidade-onion-vps-2026-08.kg.yaml`](graph/identidade-onion-vps-2026-08.kg.yaml)
> Este documento é **projeção** do grafo. Quando divergirem, **o grafo é a fonte** — e o vivo derruba os dois.

---

## A fronteira que organiza tudo

**O Logto responde *quem é você*. Ele não responde *o que você pode decifrar*.**

Essa frase decide quase todas as perguntas que seguem, e ela inverte a expectativa ingênua de que
integrar tudo ao IdP "centraliza a segurança". Não centraliza: **integrar não tira um segredo do
mundo, adiciona um sistema ao caminho.**

Consequências medidas, não deduzidas:

- No **cofre**, a chave de cifra deriva da senha mestra **no cliente**. Comprometer o Logto — console
  incluso — permite *tentar* logar; não abre o cofre.
- No **bridge**, a identidade autoriza a chamada. `ANTHROPIC_API_KEY` e `PERMISSION_MODE` são do
  **serviço**, não do usuário.

É por isso que o **console admin público é decisão defensável e não brecha**: o raio dele é o plano
de **controle** da identidade (criar apps, usuários, conectores), não os segredos das ferramentas. O
que ele exige em troca é tratar a senha de admin do Logto como **credencial de fronteira** — hoje ela
é o item de maior alcance da caixa.

---

## O desenho real, medido

```
                    ┌──────────────────────────────────────────┐
   internet ──443──▶│  Caddy — TLS automático, 5 vhosts        │
                    │  ZERO autenticação própria em todos      │
                    └──┬────────┬────────┬────────┬────────────┘
                  auth.│   app. │  vault.│console.│
                       ▼        ▼        ▼        ▼
                    :3011    :8787    :3020    :3012
                   ┌─────┐ ┌───────┐ ┌──────┐ ┌───────┐
                   │LOGTO│ │BRIDGE │ │COFRE │ │console│
                   └──┬──┘ └───┬───┘ └───┬──┘ └───────┘
                      │  ◀─────┘ JWKS local (1h)
                      │  ◀───────────────┘ redirect OIDC
                   ┌──▼──┐
                   │ PG  │ sem porta publicada
                   └─────┘

   WAHA :3999 ── ilha: sem vhost, sem consumidor, sem relação com o Logto
```

**Cada stack tem rede Docker própria e não há rede compartilhada.** Nenhum container fala com outro
por dentro do Docker: tudo sai pelo host e volta pelo Caddy, como se fossem serviços de terceiros.
Isolamento por construção — comprometer um container não dá alcance lateral.

### Três ferramentas, três modelos de confiança — e nenhum é redundante

| | como autentica | onde mora a conta | se o Logto cair |
|---|---|---|---|
| **bridge** | JWT + **JWKS local** (cache 1h) | não guarda — delega ao Logto | segue validando até o token expirar |
| **cofre** | **redirect** OIDC pelo navegador | `db.sqlite3` próprio | botão de SSO quebra; senha mestra funciona |
| **WAHA** | `X-Api-Key` (hash sha512) | par único no env | indiferente |

O bridge **nunca chama o Logto** para validar — medido: `conexões na 3011 = 0` com o bridge ativo. O
cofre resolve `auth.onionevolve.com` pelo **IP público**: sai e volta pela internet. Observamos isso
ao vivo quando o Logto reiniciou durante o upgrade — o `authorize` respondeu `400` até ele voltar.
**`SSO_ONLY=false` é resiliência, não só doutrina.**

**O custo desse desenho, e ele é consciente:** não há ponto único cuja queda derrube tudo — e também
não há lugar único onde auditar acesso. A política de acesso vive **N vezes**, uma por ferramenta.

---

## As perguntas que você fez, respondidas com medição

### Um usuário novo se cadastra sozinho?

| superfície | resposta |
|---|---|
| **Logto** | **Sim, e de propósito, desde 2026-10-09.** Por decisão do maestro, o tenant `default` está com `signInMode: SignInAndRegister`, `signUp` por `username` + `password` e `verify: false`, segundo a medição da sessão do maestro daquele dia (relato, não remedido por quem escreveu esta linha). Até então a resposta era **não** (`signInMode: SignIn`, com o portão em `POST /api/experience/identification` respondendo `403`). **Revisita** (`Q_LOGTO_QUANDO_FECHAR_O_CADASTRO`): fechar de novo quando o propósito do cadastro aberto acabar, quando surgir conta que ninguém reconhece, quando for ligado login social ou quando algum serviço passar a autorizar qualquer identidade do tenant |
| **Vaultwarden** | **Não.** `SIGNUPS_ALLOWED=false`, registro responde `400` |
| **bridge** | **Não.** Sem rota de signup; emissão é `POST /admin/tokens`, atrás do escopo `bridge:admin` |
| **WAHA** | **Não tem noção de usuário** — um par de credenciais global |

> ⚠️ **Os `204` intermediários enganam.** Eles são a API de interação aceitando escrita de campo; **o
> portão está no `submit`**. Quem medir só os passos do meio conclui que o cadastro está aberto — foi
> o que aconteceu nesta sessão, e eu repassei como fato.

### Onde fica criação de usuário e recuperação de senha?

| | criação | recuperação |
|---|---|---|
| **Logto `default`** | admin, pela Management API | **Postmark ligado** — `smtp.postmarkapp.com:587`, 5 templates (inclui `ForgotPassword`), SPF e Return-Path publicados |
| **Logto `admin`** (console) | fixa, 1 conta | **NENHUMA** — sem conector SMTP nesse tenant e o usuário **não tem e-mail** |
| **Vaultwarden** | convite do admin | **NENHUMA** — zero `SMTP_*`; `INVITATIONS_ALLOWED=true` é letra morta; `password-hint` → `400` |
| **bridge** | `POST /admin/tokens` | não existe — admin cunha outro token |

**O que SMTP cura e o que não cura.** SMTP resolve **convite** e **reset de senha do IdP**. Ele **não
resolve o cofre**: a senha mestra não é recuperável **por desenho** — é zero-knowledge. Quem espera
que ligar SMTP "resolva o acesso ao cofre" descobre tarde.

**O buraco mais afiado é o tenant `admin`**: console público, uma conta, sem e-mail, sem conector.
Perdeu a senha, não há caminho de volta.

### 2FA / MFA / login social

- **Logto `default`**: `factors: []` — não há o que ativar, nem querendo.
- **Logto `admin`**: fatores disponíveis (TOTP, WebAuthn, BackupCode) com política **`NoPrompt`** —
  nunca oferecidos.
- **Cofre**: TOTP e WebAuthn/passkey **disponíveis sem configuração de servidor**; Duo e YubiKey
  exigiriam chaves que não existem; 2FA por e-mail é inútil sem SMTP.
- **Bridge**: não inspeciona `amr`/`acr` — **não teria como exigir MFA** nem se o Logto a fizesse.
- **Login social**: **nenhum**. Zero conectores sociais, zero SSO empresarial.

**A ordem correta importa mais que a urgência.** O consenso de 2026 é que o modo de falha real não é
perder o dispositivo — é o **fallback fraco**. Ligar MFA sem desenhar recuperação junto **troca risco
de invasão por risco de lockout**, e aqui, com admin único e sem e-mail no tenant `admin`, o lockout é
o mais provável dos dois. Logo:

> **e-mail no tenant `admin` → códigos de recuperação → só então MFA.**

### Como o Caddy fica nessa história

Cinco vhosts, **zero autenticação própria**: nenhum `basic_auth`, nenhum `forward_auth`, nenhum
`log`. Todos delegam 100% ao backend.

Isso é coerente — cada ferramenta é a autoridade sobre suas contas — mas significa que **a borda não
é ponto de política**. Quem quiser regra transversal (ex.: exigir MFA em tudo) escolhe entre pôr um
`forward_auth` no Caddy ou aceitar que a política vive N vezes.

O WAHA **não tem vhost**: só loopback, alcançável por túnel SSH. É a superfície mais bem contida.

### Novos entrantes têm área separada?

**Existe separação, e ela está chaveada na coisa errada.**

`workspace.ts` faz `slug(bearer) = sha256(token)[:16]` e o `cwd` deriva disso. Com OIDC o bearer é um
JWT que **rotaciona** — então cada refresh gera **workspace novo para a mesma pessoa**. Medido: **23
diretórios** para um punhado de pessoas, nenhum coletado. O mesmo defeito atinge o rate limit
(chaveado por `Authorization`): a cota de 20/min **zera a cada renovação**.

**A cura é chavear em `sub` — a identidade — e não no portador.**

E há um agravante que ainda não tem dano demonstrado: cada workspace tem symlink para `.claude/` e
`docs/` do core, o serviço roda como **dono** do checkout, e `PERMISSION_MODE=bypassPermissions`. O
código chama de "read-only"; **nada no filesystem impõe isso**.

---

## O que o mercado ensinou, e o que isso muda aqui

**Organização lógica não é fronteira de segurança.** O CVE-2026-43912 (CVSS 8.7, corrigido na 1.35.5
— rodamos 1.37.1) foi controle de acesso quebrado entre organizações no Vaultwarden: um admin de uma
org **lia o cofre de outra**. É exatamente o cenário "um cofre por cliente na mesma instância". A
lição sobrevive ao patch: fronteira **lógica** depende de o código acertar toda vez; fronteira de
**container/rede** não tem o que acertar. Para cliente com dado sensível, instância separada compra a
remoção de uma **classe** de bug, não de um bug.

**O CVE crítico do Logto não tem porta aqui — mas isso é condição, não cura.** Seis CVEs (CERT/CC
VU#492466), incluindo um 9.1 de account-linking por e-mail não verificado. Ele exige que o Logto
**receba** login de IdP externo; medimos zero conectores sociais e zero SSO empresarial. **No dia em
que alguém ligar login social, o vetor nasce junto.**

**Sobre o Onion como framework de desenvolvimento** — e aqui a correção foi sua: a busca por
`grep`/`read` **não é atraso**, é a escolha que o mercado convergiu. A Anthropic removeu o RAG
vetorial do Claude Code em maio/2025 por busca agentic pura; Cursor contratou os engenheiros da
decisão; Windsurf, Cline, Devin e **o próprio Amp do Sourcegraph** abandonaram vetores. E a lição
cara do Sourcegraph é **não construir indexador próprio**: o `search-based` sobreviveu ao `precise`
por ser **cobertura universal com custo zero de manutenção**.

**A lacuna que ninguém preencheu:** não existe sistema público que una **grafo de decisão** e **grafo
de código** na mesma estrutura. Os dois movimentos correm em paralelo — a comunidade redescobriu
ADR-como-grafo em 2026 com uma motivação que é quase paráfrase desta casa (*"um agente que não vê POR
QUE algo foi construído vai alegremente refatorar a razão para longe"*), enquanto o lado do código
modela símbolo sem `status`, `confidence` ou `REFUTES`. É **diferenciação, não débito** — e fica
*gated*: a evidência de ganho é estreita, e o gatilho é adotante de monorepo grande.

---

## Três correções de afirmações minhas

Ficam registradas porque **como um fato foi estabelecido decide quanto se pode confiar nele depois**.

1. **Declarei "SSO provado ponta a ponta" tendo testado só o front-channel.** O redirect usa apenas o
   `client_id`; o back-channel, onde o `client_secret` entra, eu nunca exercitei. Fiz depois: o Logto
   responde `grant type is not allowed` — o que **prova que a credencial foi aceita** (errada daria
   `invalid_client`). A conclusão estava certa; **a prova que apresentei, não.**

2. **Repassei achado de agente como fato.** Relatei que "um desconhecido chega a um POST de ter
   conta" — e o agente **parou antes desse POST**. A afirmação decisiva era a única não testada.
   Medida agora: `submit` recusado, contagem inalterada. E a segunda metade da honestidade: **também
   não sei se meu fechamento causou a recusa**, porque ninguém mediu antes.

3. **O upgrade derrubou o Logto por um pipe.** `deploy 2>&1 | tail -20 || exit 1` lia o exit do
   `tail`. A migração falhou, o `||` não disparou, a imagem trocou, restart loop. **Guarda que lê o
   exit errado é pior que guarda ausente: ela afirma ter verificado.** A hook desta casa pega
   exatamente essa classe — mas só protege chamadas da ferramenta Bash, **não alcança scripts do
   repo**.

---

## O que falta, em ordem de dependência

| # | o que | por que nesta ordem |
|---|---|---|
| 1 | **e-mail no tenant `admin`** | sem isso, qualquer MFA vira risco de lockout irreversível |
| 2 | **`workspace.ts` chavear em `sub`** | 23 workspaces órfãos e rate limit furado hoje; é pré-requisito de "novos entrantes" |
| 3 | **bridge para dentro do repo** | o mecanismo de isolamento não passa por review — nenhum gate desta casa o alcança |
| 4 | **backup fora da máquina** | cifrado e com prova de restauração, mas no mesmo disco; `restic` + destino imutável, regra **3-2-1-1-0** |
| 5 | **SMTP no cofre** | destrava convite; **não** destrava recuperação de cofre |
| 6 | **MFA** | só depois de 1 e de códigos de recuperação |

**A armadilha do item 4**: a senha do repositório de backup **não pode morar dentro do cofre que ele
protege**. Se o cofre corrompe, perdem-se o dado e a chave juntos.

---

## Doutrina, destilada

1. **O IdP autentica; ele não decifra.** Toda decisão de acoplamento passa por essa fronteira.
2. **Fronteira lógica não é fronteira de segurança.** Organização isola por código acertar; container
   isola por não haver o que acertar.
3. **MFA sem recuperação desenhada troca invasão por lockout.** A ordem é recuperação → códigos → MFA.
4. **A borda não é ponto de política.** O Caddy entrega TLS e roteamento; autenticação vive no
   backend, N vezes.
5. **Configuração não é comportamento.** `signInMode: SignIn` não prova cadastro fechado — o `submit`
   recusado prova.
6. **Guarda que lê o exit errado é pior que guarda ausente.**
7. **O que vive só em produção é invisível para os gates.** Código fora do repo não tem review, nem
   bancada, nem diff.
