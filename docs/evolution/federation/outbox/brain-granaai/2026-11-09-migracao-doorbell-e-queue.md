---
title: "Update do Onion no PR #1779 e a migração do hub para doorbell e queue"
date: 2026-11-09
type: announcement
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - PR GranaAi/granaai#1779 (update do Onion para o pin a86b65f35ec7)
  - README da raiz do onion-messaging, seções "Migração dos nomes em português" e "Rollback"
---

# O update está no PR #1779

O PR **#1779** leva o hub ao pin `a86b65f35ec7`, com o kg-ssot 4.47.0. O merge é seu, por **merge commit**
(`--assert-ancestor onion/vendor`). O relatório está na própria branch, em
`docs/evolution/inbound/2026-11-09-update-a86b65f35ec7.md`.

Três coisas para olhar nele:

1. **`settings.json`:** o deny vai de 0 para 74 regras, e o `--diff` diz
   `! allow anulado: Bash(grep * .env) (o deny vence: Read(//**/.env))`. É comparação de texto; o core não mediu se
   esse `grep` pelo Bash cai de fato. São 5 hooks novos. Se o seu `settings.json` local tiver alteração sem commit
   (o core não o leu), guarde antes de trazer a branch.
2. **Depois do merge, no seu checkout:** `git fetch origin onion/vendor` e
   `git branch -f onion/vendor origin/onion/vendor`. O update rodou de um clone novo, e sem isso o próximo `--update`
   a partir daí sai rc 13.
3. **Sessão nova:** deny e hooks só valem nela.

# A migração para `doorbell` e `queue`

A `main` do `onion-messaging` (`b9b7f5c` ou posterior) trocou os nomes em português pelos em inglês. O passo a passo
abaixo é o do README da raiz, com os valores do hub. É **ato do maestro**: sessão de agente não mexe em daemon vivo,
`.mcp.json`, flag nem systemd.

Leia a seção Reversão antes de começar: a **migração do banco acontece na subida do daemon novo**, e o caminho de volta
passa pelo backup que ela cria.

`<checkout>` é o checkout de onde o daemon e a campainha rodam. `<estado>` é o `--state-dir` de hoje
(`~/.local/state/onion-fila/brain-granaai`). `<core>` é o checkout do core nesta máquina.

## 1. Preparar o checkout

Os processos vivos seguem de pé, com o código que já carregaram.

```bash
git -C <checkout> fetch origin main
git -C <checkout> checkout origin/main     # b9b7f5c ou posterior
bash <checkout>/queue/install.sh
(cd <checkout>/doorbell && bun install --frozen-lockfile --ignore-scripts)
```

Anote o commit de antes (`git -C <checkout> rev-parse HEAD`): é o da reversão.

## 2. Guardar a linha de comando e parar o daemon antigo

A sua unidade é **transitória** (criada por `systemd-run`) e some no reboot, por isso ela vira arquivo no passo 3.

```bash
systemctl --user cat onion-fila-brain-granaai     # guarde o ExecStart: os argumentos vão para a unidade nova
systemctl --user stop onion-fila-brain-granaai
flock -n <estado>/daemon.lock true && echo livre
```

Sem o `livre`, o daemon novo sai com código 3 e **não migra**. Nunca `pkill` por nome: há um daemon por membro na
máquina.

## 3. Subir a unidade em arquivo

Crie `~/.config/systemd/user/onion-queue-brain-granaai.service`, com os argumentos guardados no passo 2 e só o
executável trocado de `<checkout>/fila/fila` para `<checkout>/queue/queue` (variáveis `FILA_*` viram `QUEUE_*`):

```ini
[Unit]
Description=onion-messaging: queue daemon, member brain-granaai

[Service]
ExecStart=<checkout>/queue/queue daemon --member brain-granaai --state-dir <estado> --members-yaml <core>/docs/evolution/federation/members.yaml --jwks-dir <core>/.claude/utils/federation-transport/jwks --ft-dir <core>/.claude/utils/federation-transport --key <chave-0600> --kid brain-granaai-1
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now onion-queue-brain-granaai
```

Use o **mesmo `--state-dir`**: o estado, o `fila.db` e o `fila.sock` continuam onde estão, e os pares não precisam ser
regravados.

**Reboot:** unidade de usuário só sobe sozinha com *linger*, e nesta máquina ele está ligado (`Linger=yes`, medido em
09/11). Com a unidade em arquivo e o `enable`, ela volta depois do reboot.

## 4. Conferir a migração

```bash
journalctl --user -u onion-queue-brain-granaai | grep 'schema migrated to v1'
ls <estado>/fila.db.pre-schema-v1-*.bak
<checkout>/queue/queue --state-dir <estado> status     # ok, com as mesmas contagens de antes
```

`database is locked` ou código 3 no journal: outro processo segura o banco ou a trava; volte ao passo 2.

## 5. `.mcp.json` do hub

A chave `campainha` vira `doorbell`:

```json
{
  "mcpServers": {
    "doorbell": {
      "command": "bun",
      "args": ["<checkout>/doorbell/server.ts"],
      "env": { "DOORBELL_QUEUE_SOCK": "<estado>/fila.sock" }
    }
  }
}
```

No `env`, `CAMPAINHA_FILA_SOCK` vira `DOORBELL_QUEUE_SOCK`; o valor, o caminho do socket, não muda.

## 6. Abrir a sessão

Numa sessão nova, na pasta do hub:

```bash
claude --dangerously-load-development-channels server:doorbell
```

O Claude Code pede de novo o consentimento do servidor MCP, agora para `doorbell`, e as tools passam a se chamar
`mcp__doorbell__pending_signals`, `mcp__doorbell__read_signal` e `mcp__doorbell__ack_signal`. Permissão, allowlist ou
hook que cite o nome antigo troca junto.

## 7. Conferir a sessão

`/mcp` mostra `doorbell` conectado, `pending_signals` traz o campo `queue` com `status: "ok"`, e o stderr do servidor
não tem linha `deprecated:`. Se tiver, sobrou nome antigo no `.mcp.json` ou na unidade.

Quando estiver de pé, avise pelo inbox do core: ele manda um sinal de teste pela fila, e o hub responde com o ack.

# Reversão

**Sempre nesta ordem: parar o novo, restaurar o backup, subir o velho. Nunca só trocar a unidade.** O daemon velho não
conhece o banco migrado e cai na subida com `there is already an index named fila_seen`; essa linha quer dizer que o
backup não foi restaurado.

```bash
systemctl --user stop onion-queue-brain-granaai
flock -n <estado>/daemon.lock true && echo livre     # restaurar com o daemon vivo corrompe o banco
cp <estado>/fila.db.pre-schema-v1-<carimbo>.bak <estado>/fila.db
rm -f <estado>/fila.db-wal <estado>/fila.db-shm
git -C <checkout> checkout <commit anotado no passo 1>
systemctl --user disable --now onion-queue-brain-granaai
```

Depois suba o velho com a linha de comando guardada no passo 2. Em `.mcp.json`, volte à chave `campainha` com `args` em
`<checkout>/campainha/server.ts`, e abra com `server:campainha`.

O banco volta ao instante anterior à migração: mensagem aceita depois dela não volta sozinha, porque o remetente já a
deu por entregue.

Orquestrado com 🧅 Onion Evolve
