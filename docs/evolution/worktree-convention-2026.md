# Convenção de worktrees Onion (`~/worktrees/<repo>/<branch-slug>`)

> **Codifica a prática de campo do metagamify** (crédito: o adotante adotou `~/worktrees/**` por conta
> própria e o layout provou-se melhor que o exemplo ad-hoc do manual). O **comportamento** de worktrees
> já era doutrina (topologia W3, um-escritor-por-escopo, handoff commitado — [ADR work-models](../analysis/onion-adr-work-models-session-topologies-2026-07.md),
> [fluxo Handoff](README.md#handoff--dentro-de-um-repo-sessões-paralelas)); o que faltava era decidir
> **localização e nomenclatura**. Fundamentação de mercado (julho/2026) ao final.

## Escopo — a quem esta convenção se aplica

**Só aos worktrees DURÁVEIS do maestro** — checkouts paralelos humanos que vivem dias/semanas
(desenvolvimento em 2 branches, sessão paralela de outro repo da federação na mesma máquina).

**Fora do escopo (efêmeros tool-managed — ficam como estão):**

| Criador | Path | Ciclo de vida |
|---|---|---|
| `vendor-branch.sh` (update do framework) | `$(mktemp -d)/onion-vendor-wt` | removido logo após o commit |
| `/meta:adopt` legacy (Fase 2a) | `<pai-do-alvo>/onion-adopt-<basename>` | vive só durante a adoção |
| `Workflow isolation:'worktree'` (orquestração) | gerenciado pela ferramenta | auto-removido se intocado |
| Harness Claude Code (`--worktree`/Desktop) | `.claude/worktrees/<name>` | auto-cleanup ao sair limpo |

(A doutrina de orquestração já veda `EnterWorktree`/`ExitWorktree` manual — a ferramenta gerencia;
ver [agent-orchestration §7](../knowledge-base/concepts/agent-orchestration.md).)

## Layout canônico

```
~/worktrees/
├── rhilo-metagamify/
│   ├── develop/            ← worktree da branch develop
│   └── feat-xyz/           ← worktree de feature
├── rhilo-app/
│   └── develop/
└── onion-evolve/
    └── docs-worktree-convention/
```

**Regra:** `~/worktrees/<repo>/<branch-slug>/`, onde:
- `<repo>` = basename do clone principal (ex.: `rhilo-metagamify`);
- `<branch-slug>` = nome da branch em kebab, com `/` → `-` (`feat/xyz` → `feat-xyz`).

**Criar / remover:**

```bash
git -C ~/<repo> worktree add ~/worktrees/<repo>/<branch-slug> <branch>
# ... trabalho ... (handoff commitado antes de sair)
git -C ~/<repo> worktree remove ~/worktrees/<repo>/<branch-slug>
git -C ~/<repo> worktree prune   # higiene periódica
```

**Por que umbrella (e não irmãos soltos na home):** agrupa todos os checkouts de todos os repos da
federação num lugar descobrível, mantém a home limpa, escala N repos × M branches, e é o padrão que
ferramentas de mercado (gwq) assumem — o maestro acha qualquer worktree com um `ls ~/worktrees/`.

## Comportamento (já doutrina — esta convenção NÃO redefine)

- **W3 — duas sessões, mesmo repo**: handoff por worktree, **um escritor por escopo**, handoff
  **commitado** antes de trocar de ponta ([ADR work-models](../analysis/onion-adr-work-models-session-topologies-2026-07.md) ·
  [federation-usage-modes §1.0](../knowledge-base/concepts/federation-usage-modes.md)).
- **Um único `.git`**: worktrees compartilham o repositório; a branch fica presa ao worktree que a
  tem em checkout. O maestro rotaciona — não os agentes.

## ⚠️ Caveat técnico registrado — o farol de sessão é por working-tree

O `session-beacon` usa `git rev-parse --show-toplevel` como chave: cada worktree tem seu próprio
`.claude/beacons/`. Consequência: **worktrees irmãs NÃO veem o farol uma da outra** — o beacon flagra
duas sessões na MESMA working tree (W1×W2), não duas sessões em worktrees distintas do mesmo repo.
O handoff entre worktrees confia na **convenção + commit**, não no farol. Slice futuro possível
(farol compartilhado via `.git` comum, ex. `$git_common_dir/onion-beacons/`) fica **anotado, não
implementado** — abre se um incidente real de colisão entre worktrees irmãs aparecer.

## Fronteiras explícitas

- **Worktree ≠ escopo.** Branch/worktree é o eixo **versão/paralelismo**; escopo
  (framework→empresa→time→pessoa) é a [scope-convention](scope-convention-2026.md) (RFC-0005 §3:
  branch não compõe).
- **Worktrees NÃO viram lineages** no `members.yaml` — são estado de trabalho do maestro, não
  membros da federação. O registro da federação aponta o clone principal (`local_path:`).

## Grandfather

Os worktrees pré-convenção (`~/metagamify-rhilo-atual`, `~/rhilo-app-atual`) **ficam onde estão** até
serem naturalmente removidos/recriados. A convenção vale para todo worktree novo.

## Fundamentação (mercado, julho/2026)

| Padrão | Exemplo | Veredito p/ Onion |
|---|---|---|
| **Umbrella dir** (gwq) | `~/worktrees/<repo>/<branch>` | ✅ **adotado** — descobrível, multi-repo, padrão de fluxos paralelos com agentes IA |
| Sibling dirs | `~/projects/myapp-feature-auth` | era o nosso exemplo informal; não agrupa nem escala N×M |
| URL-hierárquico (gwq puro) | `~/worktrees/github.com/owner/repo/` | profundidade extra sem ganho numa federação de 1 host |
| In-repo tool-managed | `.claude/worktrees/<name>` | correto para efêmeros do harness; inadequado p/ duráveis do maestro |

Fontes: [gwq — git worktree manager](https://github.com/d-kuro/gwq) ·
[GitWorktree.org — best practices](https://www.gitworktree.org/guides/best-practices) ·
[Claude Code — parallel sessions with worktrees](https://code.claude.com/docs/en/worktrees) ·
[Ultimate guide to git worktrees (AI agents)](https://medium.com/@pererikbergman/the-ultimate-guide-to-git-worktrees-from-daily-dev-to-ai-agents-2b39e63a359d) ·
[ghq × gwq × fzf](https://shunk031.me/post/ghq-gwq-fzf-worktree/)
