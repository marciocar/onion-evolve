---
date: 2026-07-19
instance: onion-evolve
type: innovation
classification: collective
tags: [farol, beacon, worktree, session-coordination, i3, concurrency, key-by-worktree]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Desenhar o farol-organizador: (1) beacon grava `worktree:` e o `check` compara por ÁRVORE, não por clone — alarme só quando é a MESMA árvore (muito menos ruído); (2) verbo de coordenação com 3 saídas human-gated: 🌿 isolar em worktree (default), 🤝 ceder/read-only, 🧹 sweep; (3) BUG a corrigir junto: o hook periódico de beacon reescreve o hat como `—`, perdendo a intenção de escrita declarada. Candidato de backlog delicado-core (mexe no farol soberano — fixture + selftest + re-dogfood)."
review_after: 2026-10-15
conflict_class: static
---

## Signal
**A colisão I3 ("um escritor por repo") é por WORKING TREE, não por clone — e a resolução natural
de sessões concorrentes é dar a cada uma sua ÁRVORE, não eleger quem escreve.** O farol hoje
(`session-beacon.sh check`) responde *"quem está aqui?"* e para — lista beacons vivos, exit 1 se há
sessão alheia fresca, e a skill só avisa *"coordene com o maestro"*. Falta a segunda metade:
*"e o que a gente faz sobre isso?"*.

## A inovação (proposta)
- **Beacon key-by-worktree:** gravar `worktree:` no beacon e o `check` comparar por árvore. Duas
  sessões em worktrees DIFERENTES nem precisam coordenar — sem árvore compartilhada, sem colisão.
  O farol vira "alarme só-quando-há-conflito-real", não "alarme sempre-que-há-alguém".
- **Verbo de coordenação (3 saídas, human-gated — fiel a "farol é sinal, não trava"):**
  🌿 **isolar em worktree** (default; dissolve o I3 fisicamente) · 🤝 **ceder** (baixa o beacon,
  vira read-only) · 🧹 **sweep** (higiene de beacons stale — já existe, falta superfície).
- **Fronteira honesta:** "consolidar duas sessões numa" no sentido de fundir dois PROCESSOS Claude
  vivos NÃO dá — contexto vivo não se mescla. Só dá *uma cede* ou *cada uma isola*. Não prometer o
  impossível.

## Evidence
- **Vivido nesta sessão (2026-07-19):** duas sessões em `main` dividindo UMA árvore (colisão I3
  latente). Depois **dogfoodamos a isolação**: a sessão de "resgate de adotantes" foi aberta numa
  worktree própria (`/home/marcio/worktrees/onion-evolve/rescue-adopters-core-vs-hub`,
  branch `docs/rescue-adopters-core-vs-hub`). Como o beacon-dir resolve para o toplevel da árvore,
  os faróis das duas caíram em `.claude/beacons/` de PATHS distintos → **não se viram, não colidiram**.
  A ideia "key-by-worktree" já acontece por acidente do path — falta torná-la deliberada e legível.
- **Bug de campo achado no caminho:** o hook periódico de beacon (`session-beacon-hook.sh`) refresca
  o beacon SEM o arg de hat → sobrescreve `hat: item2-...` de volta para `hat: —`, perdendo a
  intenção de escrita que a sessão tinha declarado. A superfície de "declarar o que estou fazendo"
  existe (`up <repo> <sid> [hat]`) mas é apagada pelo próprio refresh.

## Next crumb
Ver `next_recommended`. É mudança no farol SOBERANO (mesma classe de cautela do `kg-radar`): pegar
FRESCO, com fixture + selftest + re-dogfood antes/depois. Origem: pergunta do maestro nesta sessão
("quando já tem beacons/sessões abertas, dá pra saber se quer organizar, trazer p/ uma só, ou levar
p/ worktree?") — a resposta virou esta doutrina de coordenação por árvore.
