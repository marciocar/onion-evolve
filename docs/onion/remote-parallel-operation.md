# 🧭 Operação remota e paralela do Onion — transporte × persistência

> Guia de operação do core para rodar o Onion numa **máquina remota** (VPS/servidor) com **frentes
> paralelas** e **teammates**. Genérico — vale para qualquer operador. A mecânica de frentes está na KB
> [parallel-work-worktrees-pattern](../knowledge-base/concepts/parallel-work-worktrees-pattern.md); aqui é o
> **como conectar e persistir**.

---

## 1. O modelo mental — duas camadas que não competem

| Camada | Quem faz | O que garante | Se cair… |
|---|---|---|---|
| **Transporte** | `mosh` **ou** `ssh` | te conecta à máquina | você reconecta |
| **Persistência** | **`tmux`** (na máquina remota) | a sessão sobrevive a queda/sleep/reboot-do-cliente | o trabalho **continua** |

**Invariante:** o `tmux` é o que importa e é **constante**. `mosh` vs `ssh` é só *como você chega* — ambos
funcionam com `tmux`. **Nunca opere o Onion remoto sem `tmux`**: sem ele, uma queda de conexão mata a sessão
Claude e o trabalho em voo.

## 2. mosh + tmux — recomendado para conexão que oscila

`mosh` (Mobile Shell) é o transporte resiliente: sobrevive a **roaming, sleep, latência alta** e **reconecta
sozinho** (fecha o notebook, reabre, já está lá). Eco local instantâneo.

- **Windows:** `mosh` roda bem via **WSL** (não há cliente nativo decente no PowerShell). WSL Ubuntu → `mosh`
  é o caminho **correto**, não improviso.
- ⚠️ **`mosh` não tem scrollback próprio** (é full-screen) — por isso **exige** `tmux` (scroll: `Ctrl-b [`,
  `q` sai). É a razão nº1 de sempre parear `mosh` com `tmux`.
- Requer **UDP 60000–61000** aberto no firewall da máquina remota.
- Com porta SSH alternativa: `mosh --ssh="ssh -p <porta>" <user>@<host>` (o `mosh` faz o SSH primeiro, depois
  troca para UDP).

## 3. ssh + tmux — alternativa mais simples (conexão estável)

`ssh` é universal, TCP, sem camada extra, sem UDP. Se o SSH cai, o `tmux` na máquina remota **mantém tudo**;
você re-conecta e `tmux attach`. Diferença vs `mosh`: **você reconecta na mão** (o `mosh` reconecta sozinho).
Nativo no PowerShell (OpenSSH) e no WSL.

## 4. O decisor

| Sua situação | Use |
|---|---|
| Conexão oscila · notebook dorme · troca de rede | **`mosh` + `tmux`** |
| Conexão estável · quer menos peças · nativo Windows | **`ssh` + `tmux`** |
| **Sempre** | **`tmux`** — `mosh` persiste a *conexão*; `tmux` persiste a *sessão* (e sobrevive a reboot da máquina, que o `mosh` não) |

São **complementares, não substitutos**: `mosh` reconecta o transporte; `tmux` guarda a sessão.

## 5. tmux — o mínimo para operar

```bash
tmux new -s <tarefa>        # sessão nomeada pela TAREFA (nunca session1/2/3)
tmux ls                     # sessões vivas   ·   tmux attach -t <nome>  = reconectar
```
| Ação | Tecla (prefixo `Ctrl-b`) |
|---|---|
| Desanexar (deixa rodando) | `d` |
| Nova janela / ir p/ Nª / listar | `c` / `<número>` / `w` |
| Dividir painel / navegar painéis | `%` `"` / `<setas>` |
| Scrollback (essencial com mosh) | `[` (sai com `q`) |

## 6. Frentes paralelas e teammates

- **Frentes diferentes em paralelo:** uma **worktree** por tema, uma **janela tmux** por worktree — ver
  [parallel-work-worktrees-pattern](../knowledge-base/concepts/parallel-work-worktrees-pattern.md). Rode
  `claude` **puro** na worktree durável (nunca `claude --worktree` por cima).
- **Um problema, N cabeças interativas (Agent Teams / teammates):** aparecem em **painéis** e **exigem
  `tmux`** para o modo split-pane (`teammateMode: auto`). Rode-os numa **sessão tmux dedicada** (os painéis
  dividem a janela atual; numa sessão de trabalho isso corromperia o layout). O transporte (`mosh`/`ssh`) é
  indiferente aqui — quem habilita o split-pane é o `tmux`.
- **Fan-out headless (varredura/review massivo):** ferramenta **Workflow** — não precisa de tela nem tmux.

## 7. Resumo executável

| Faça | Não faça |
|---|---|
| `tmux` **sempre** na máquina remota | operar remoto sem multiplexer (perde a sessão na queda) |
| `mosh` (via WSL no Windows) se a conexão oscila | esperar cliente `mosh` nativo no PowerShell (não há bom) |
| parear `mosh` **com** `tmux` (scrollback + reboot) | usar `mosh` sozinho (sem scrollback, não sobrevive a reboot) |
| Agent Teams em **sessão tmux dedicada** | spawnar teammates na sua janela de trabalho (corrompe layout) |
| escolher transporte pela **estabilidade da conexão** | achar que `mosh`/`ssh` substituem o `tmux` (não substituem) |
