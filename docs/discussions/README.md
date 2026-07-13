# 🌌 docs/discussions/ — as estrelas da Constelação de Estudos

> O lar do padrão [discussion-worktrees](../knowledge-base/concepts/discussion-worktrees-pattern.md), operado
> sob o modelo [Constelação de Estudos](../knowledge-base/concepts/constellation-of-studies.md).

Cada **estudo isolado** (uma "estrela") vive numa worktree `discuss/<slug>` **local, não-pushada**, e guarda seu
enquadramento + estado em `docs/discussions/<slug>/SEED.md`. O `SEED.md` é o **Tier-0 público** da estrela — o
core lê **só o frontmatter + o bloco Tier-0** (metadados) para a visão macro; o corpo (Tier-1→3) é privado da
estrela, tocado só sob convite do maestro (linha do [authorization-layers](../knowledge-base/concepts/authorization-layers-intake-vs-execution.md)).

## Estrutura

```
docs/discussions/
├── README.md              # este arquivo
├── _template/SEED.md      # copie para começar uma estrela nova
└── <slug>/                # (nas branches discuss/<slug>, não em main)
    ├── SEED.md            # enquadramento + bloco Tier-0 (o ponteiro de resume)
    ├── NOTE-*.md          # notas da exploração (Tier-1→3)
    └── <slug>.kg.yaml     # (opcional) o grafo da estrela — insumo do radar cross-study
```

## Começar uma estrela

```bash
cd ~/onion-evolve
git worktree add -b discuss/<slug> ~/worktrees/onion-evolve/discuss-<slug> main
cp docs/discussions/_template/SEED.md ~/worktrees/onion-evolve/discuss-<slug>/docs/discussions/<slug>/SEED.md
# preencha o SEED (enquadramento + bloco Tier-0) e commite NA branch (não pusha)
cd ~/worktrees/onion-evolve/discuss-<slug> && claude
```

## Contrato de isolamento (resumo — SSOT no padrão)
- Branch `discuss/*` **não-pushada** → invisível para `main`, remote e sessão-core.
- O core **não lê** uma estrela sem **convite explícito** do maestro. Assuntos não se misturam.
- **Nada promove sozinho** — vira `feat/*`/PR só quando o maestro promove.
- **Recolher = atualizar o bloco Tier-0 do SEED** (o `next_action:` é o ponteiro de resume) antes de rotacionar.
