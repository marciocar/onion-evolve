---
title: "Padrão — Trabalho paralelo em worktrees independentes"
category: concepts
tags: [worktree, paralelismo, work-model, sessions, worklog, tmux, gitflow]
status: candidato
date: 2026-07-11
---

# Padrão — Trabalho paralelo em worktrees independentes

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Categoria** | Concepts |
| **Aplicação** | Tocar N questões do Onion em paralelo, cada uma isolada, sem colisão de escopo |
| **SSOT de layout** | `worktree-convention-2026.md` (interno do core). *Dimensão:* a convenção que fixa localização e nomenclatura (`~/worktrees/<repo>/<branch-slug>`, umbrella dir), a doutrina W3 (um-escritor-por-escopo, handoff commitado) e o caveat do farol por-working-tree. |
| **KBs irmãs** | [agent-orchestration.md](agent-orchestration.md) · [worklog-protocol.md](worklog-protocol.md) · [federation-usage-modes.md](federation-usage-modes.md) |

> Esta KB é o **padrão operacional** (o passo-a-passo reutilizável). A **estrutura** (onde a worktree vive, como
> se chama, a doutrina de um-escritor-por-escopo) é da SSOT `worktree-convention-2026.md` (interno do core) —
> **não duplicada aqui**. Esta KB cobre o **como fazer**; a convenção cobre o **contrato**.

## 1. Quando usar (e quando NÃO)

**Use** quando há **N questões independentes** do Onion (uma feature, um veredito, um seed de contexto, um
sinal de co-evolução) que tocam **escopos de arquivo disjuntos** e você quer tocá-las **em paralelo**, cada uma
retomável por conta própria.

**NÃO use** (serialize ou use handoff) quando as frentes tocam os **mesmos arquivos** — o guard-rail automático
não pega colisão entre worktrees irmãs (ver §5). Trabalho sequencial ou com muitas dependências: uma sessão só.

## 2. O modelo em uma frase

**1 questão = 1 branch = 1 worktree = 1 sessão Claude (com worklog próprio) = 1 tela.** Todas compartilham o
mesmo `.git`; o maestro rotaciona a atenção entre elas.

## 3. Passo a passo

### 3.1 Criar a worktree (cortada da branch de integração resolvida)
```bash
cd ~/<repo>                                   # o clone principal
git worktree add -b <tipo>/<slug> \
  ~/worktrees/<repo>/<tipo>-<slug> \
  "$(bash .claude/validation/resolve-branch-role.sh integration 2>/dev/null \
     || bash .claude/validation/resolve-integration-branch.sh)"
```
- `<tipo>/<slug>` = branch em kebab (`docs/veredito-x`, `feat/y`, `chore/z`); o slug do path troca `/`→`-`.
- A **base** é a branch de integração **resolvida** (não hardcode `main`/`develop`) — ver
  `onion-adr-branching-base-agnostic-2026-06.md` (ADR interno do core): a base de integração é **dado
  resolvido, agnóstico** (`.onion-version` → `git config` → detecção), aplicação do princípio "adota não
  impõe" ao eixo branching. Layout `~/worktrees/<repo>/<slug>`:
  convenção SSOT.

### 3.2 Abrir a sessão (uma tela por worktree)
```bash
cd ~/worktrees/<repo>/<tipo>-<slug> && claude
```
- Rode **`claude` puro** — **não** `claude --worktree` (esse cria worktree efêmera tool-managed; a sua já é a
  durável do maestro — ver convenção §Escopo).
- Cada worktree tem seu **transcript nativo** E seu **worklog** (`.claude/sessions/<slug>/STATE.md`) próprios →
  isolamento real, resume frio independente ([worklog-protocol.md](worklog-protocol.md)).
- Acesso remoto (VPS): a sessão precisa sobreviver a queda de SSH. Opções — **tmux/zellij** (multiplexer leve,
  persistente) ou **VS Code/Cursor Remote-SSH** (server persiste os terminais). Detalhe operacional fica no
  runbook de acesso, não nesta KB.

### 3.3 Trabalhar, entregar, sincronizar
```bash
# ... trabalho na worktree (handoff commitado antes de trocar de ponta) ...
# entregar: gate + PR pela vertical de engenharia
/engineer:pr                                  # ou: bash gate + gh pr create via forge adapter
# após o merge do PR:
/git:sync                                      # FF da branch protegida + atualiza worktrees
```

### 3.4 Remover quando fechar (higiene)
```bash
git -C ~/<repo> worktree remove ~/worktrees/<repo>/<tipo>-<slug>
git -C ~/<repo> worktree prune                 # higiene periódica
```

### 3.5 Sessão de serviço longo: tmux ou fundo nativo? (medido em 2026-11-24)

O Claude Code tem fundo **nativo**: a tecla `←` (ou `claude --bg`) põe a sessão num daemon, e `claude agents`,
`attach`, `stop` e `rm` a operam. A escolha, para quem segura uma peça ou uma batuta por dias:

| Uso | Onde | Por quê |
|---|---|---|
| Serviço longo (dona de peça, batuta, sessão do core) | **tmux** (um servidor por sessão), reaberto no boot pelo systemd do usuário | sobrevive a reboot e mantém a flag do canal de mensagens com que foi aberta |
| Tarefa curta, ou trocar de terminal | **fundo nativo** | é para isso que ele existe: entra e sai com `claude attach` |

O que se mediu no Claude Code 2.1.331, e decide a escolha:

- **A tecla `←` cria uma CÓPIA com id novo**, e o processo antigo morre. O transcript da cópia abre com
  `{"type":"history-suppression","cause":"fork_inherit"}`, **sem** o id de origem, e todo `sessionId` do histórico é
  reescrito. O que liga as duas é o `uuid` das mensagens: o **último** `uuid` herdado (a última mensagem com
  `timestamp` anterior ao `ts` da linha `history-suppression`) está, idêntico, no transcript da origem. O **primeiro**
  não serve: é a fronteira da compactação e se repete em **irmãs** (duas cópias da mesma origem). Retomar o id antigo
  abre uma **segunda** cópia da conversa que já vive. Cópia recém-criada, só com a linha `history-suppression`, ainda
  não tem o que casar: a origem fica **não medida**, as peças dizem isso e não barram por palpite.
- **A cópia nasce de um `claude bg-spare` genérico**, sem as flags da sessão original: a sessão aberta com um canal de
  desenvolvimento (a campainha de mensagens) volta **muda**. `claude --bg --resume <id>` continua a sessão no fundo
  com o **mesmo** id, mas flag a mais na retomada abre cópia.
- **O daemon é transitório**: sai sem clientes, e a sessão ociosa é aposentada depois de um tempo (no log do daemon:
  `retire … idle 8h`). O registro dela continua na lista (`kind: background`, `state: blocked`), **sem pid**.
- **«Viva» tem uma regra só**: interativa listada, ou de fundo **com** pid vivo (`kill -0`). O `state` é o último que o
  harness gravou e sobrevive ao processo; quem o lê como vida barra a reabertura por causa de um registro morto (foi o
  que aconteceu no core, com um registro de dias antes).

Como as peças do Onion convivem com o nativo: **leem-no e não brigam com ele**. A regra única de «viva» mora em
`.claude/utils/orchestration/session-liveness.sh`, e o abridor de sessões do core, o pulso da batuta
(`/meta:baton`) e o reinício gracioso (`/meta:restart`) a usam. O abridor recusa abrir a 2ª cópia e dá a receita de
volta ao tmux (`claude stop <id>`, depois reabrir pelo id no tmux); o pulso avisa a sessão de dever longo que está no
fundo (`SESSION_NATIVE_BG_LONG_DUTY`) e oferece a limpeza do registro morto há mais de 24 h
(`SESSION_STALE_BG_RECORD`, com `claude rm <id>`, que é ato do humano); o `/meta:restart` imprime a receita pelo modo
da sessão e faz o bilhete de retomada seguir a cópia. Nenhuma delas roda `stop`, `attach` ou `rm`. Ficou sem medir,
porque nada aqui roda esses comandos: que a retomada depois do `stop` mantém o mesmo id, e que a janela `attach` fecha
sozinha depois dele.

## 4. Invariantes (da convenção — repetidos porque mordem)

- **Um escritor por escopo (W3):** paralelo só é seguro se as frentes tocam arquivos disjuntos. Sobreposição →
  serialize ou handoff **commitado** antes de trocar de ponta.
- **A branch fica presa ao worktree** que a tem em checkout — o maestro rotaciona, não os agentes.
- **`claude` puro** na worktree durável; nunca `claude --worktree` por cima.

## 5. ⚠️ Caveat técnico (não contornável hoje)

O **`session-beacon` é por working-tree** (`git rev-parse --show-toplevel` é a chave). **Worktrees irmãs NÃO
veem o farol uma da outra** — o beacon flagra 2 sessões na MESMA working tree, não em worktrees distintas. O
handoff entre worktrees confia em **convenção + commit**, não no farol. Por isso o §1 exige **escopos de
arquivo disjuntos**: o guard-rail automático não cobre esse cruzamento. (Farol compartilhado via `.git` comum é
slice futuro anotado, não implementado.)

## 6. Custo real

- **Disco/git:** barato — um só `.git`; só os arquivos de trabalho duplicam.
- **O teto real é cognitivo:** N linhas de raciocínio paralelas. A worktree resolve o *isolamento técnico*, não
  a *atenção humana*. **3–4 frentes** é o teto saudável; acima disso vira troca-de-contexto cara.

## 7. Evolução gated (o que ainda não é)

Este padrão é hoje **manual + convenção**. Um comando `/git:worktree <create|list|remove>` que encapsula os
passos §3 (resolvendo a base, aplicando o layout, semeando o worklog) é **candidato gated** — abre quando o uso
manual repetido justificar (doutrina helper-testável-primeiro + gated-until-trigger). Não construir à frente do
gatilho.

## 8. Resumo executável

| Faça | Não faça |
|---|---|
| 1 questão = 1 worktree = 1 sessão = 1 worklog | 1 checkout alternando temas com `git checkout` |
| Base = branch de integração **resolvida** | Hardcode `main`/`develop` como base |
| `claude` puro na worktree durável | `claude --worktree` por cima da durável |
| Escopos de arquivo **disjuntos** entre frentes | Duas worktrees mexendo no mesmo arquivo (beacon não pega) |
| Handoff **commitado** antes de trocar de ponta | Confiar no farol entre worktrees irmãs |
| Remover + `prune` ao fechar a frente | Deixar worktree órfã acumulando |
