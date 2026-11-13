# Card do maestro: a regra de sudoers dos atos de VPS delegados

> Selo: `D_DELEGATE_VPS_SERVICE_SCRIPTS_1113` (maestro, 2026-11-13). A sessão roda o update do bridge e a persona
> do Slack (`install`, `start`, `verify`) por sudoers sem senha. A config com segredo e o `creds` seguem com o
> maestro. Este card é **seu**: a sessão não instala nada (o veto `ato script ops/delegated-ops.sh install` barra).

## O desenho, em uma tela

| Opção | Por que sim ou não |
|---|---|
| NOPASSWD apontando `ops/update-bridge.sh` do checkout | **Não.** O operador escreve o checkout: quem edita o script vira root. |
| NOPASSWD nos comandos internos (`tee`, `install`, `mv`, `git`…) | **Não.** Os caminhos são variáveis e o `git -c core.sshCommand` executa qualquer coisa: cada um, liberado, é escrita ou execução arbitrária como root. |
| **NOPASSWD em CÓPIAS de root**, com argumentos fixos | **Sim.** `/usr/local/lib/onion-ops/` (root:root 0755), copiadas da `origin/main` e conferidas por sha256. O operador não as edita. |

O fecho das cópias: `update-bridge.sh`, `bridge-backup.sh`, `bridge-hardening.sh`, `chat-runner.sh` e
`slack-persona.sh`. Como root, cada script só aceita rodar a partir da cópia (dono root, sem escrita de grupo nem
de outros, sem symlink); `bridge-hardening` e `chat-runner` só rodam o `verify` por ela; a persona recusa o `creds`,
e o payload dela (a unit do bridge servido, que a conta `onion` escreve) é lido como `onion` e só se instala se couber
numa allowlist fechada de diretivas: `DynamicUser=yes`, `User` e `ExecStart` fixos, nenhuma outra `Exec*`;
o backup como root só lê a origem e entrega o tar por pipe ao operador, que cifra e grava no destino dele.

A regra (`ops/sudoers/onion-delegated-ops`) libera só estas linhas exatas, com `env_reset` e `!setenv`:

```
/usr/local/lib/onion-ops/update-bridge.sh ""            # sem argumento
/usr/local/lib/onion-ops/update-bridge.sh --restart
/usr/local/lib/onion-ops/slack-persona.sh install       # o ensaio
/usr/local/lib/onion-ops/slack-persona.sh install --apply
/usr/local/lib/onion-ops/slack-persona.sh start
/usr/local/lib/onion-ops/slack-persona.sh verify
```

## ⚠️ A fronteira real é outro usuário do sistema

A sessão do Claude Code roda como o **mesmo usuário do maestro** (`marcio`). Tudo o que esse usuário escreve, a sessão
escreve: o checkout e os scripts, a ref `origin/main` local, o `~/.gitconfig`, a config do gh e o próprio hook. Por isso
os hooks e as recusas dos scripts são **camada de conformidade, não fronteira de segurança**: eles barram o engano e o
atalho, não um adversário com a conta. A fronteira de verdade é rodar a sessão (ou os atos) como **outro usuário** do
sistema, sem escrita no checkout servido e sem sudo amplo. Decisão do maestro de 2026-11-13: fechar o barato e declarar
o resto.

## ⚠️ Antes: a regra só limita se for tudo o que o operador tem

Medido em 2026-11-13 com `sudo -n -l`: `marcio` tem `(ALL) NOPASSWD: ALL` e é do grupo `docker`, que dá root por
outro caminho. Enquanto isso valer, a regra não reduz nada, e a fronteira é só o veto do hook, que é camada de
conformidade e não de segurança. Tirar o `NOPASSWD: ALL` é decisão sua e muda o seu dia a dia (o sudo passa a
pedir senha). Este card não faz isso por você.

## Passo a passo · ~5 min (estimado)

Rode num terminal SSH com TTY (o `install` pede a senha do sudo), a partir de um checkout em `origin/main`
**depois** do merge deste PR:

1. `git -C ~/onion-evolve fetch origin main && git -C ~/onion-evolve worktree add /tmp/onion-ops-main origin/main`
2. Confira o arquivo antes: `sudo visudo -cf /tmp/onion-ops-main/ops/sudoers/onion-delegated-ops`
   → `parsed OK`
3. `bash /tmp/onion-ops-main/ops/delegated-ops.sh install`
   (copia da `origin/main`, valida com `visudo -cf`, instala as cópias 0755 e a regra 0440, e roda o `verify`)
4. Confira:
   - `bash /tmp/onion-ops-main/ops/delegated-ops.sh verify` → cada cópia `✓ … = origin/main` e `em dia`
   - `sudo visudo -c` → `parsed OK` em todos os arquivos
   - `sudo -l -U marcio | grep onion-ops` → as seis linhas acima
5. `git -C ~/onion-evolve worktree remove /tmp/onion-ops-main`

**Rollback:** `sudo rm /etc/sudoers.d/onion-delegated-ops && sudo rm /usr/local/lib/onion-ops/*.sh && sudo rmdir /usr/local/lib/onion-ops`

**Quando repetir:** sempre que um dos cinco scripts do fecho mudar na main. A cópia defasada não roda o ato: o veto
do hook só aceita a cópia byte a byte igual ao `ops/` do checkout, e o `verify` aponta qual arquivo mudou.

**Depois, a sessão:** roda `sudo /usr/local/lib/onion-ops/update-bridge.sh` e a persona pela cópia, sem pedir.
