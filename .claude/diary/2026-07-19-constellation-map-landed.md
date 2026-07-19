---
date: 2026-07-19
instance: onion-evolve
type: innovation
classification: collective
tags: [constellation, map, farol, beacon, worktree, presence, scope-collision, objective-convergence, macro]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Fase 2 da Constelação (🔬 radar cross-study, `kg-constellation-radar.sh`) permanece GATED pelo gatilho do ADR: duas estrelas colidirem/divergirem DE FATO ≥1× E ≥2 estrelas terem `.kg.yaml`. O mapa já expõe as colisões candidatas (hoje: `docs/onion/graph/` em 3 estrelas — behavior-mapping-kg, interface, pessoal-marcio; NS1 em 3). Quando o gatilho bater, o radar reconcilia via overlay `constellation.kg.yaml` (REFUTES/SUPERSEDES), NÃO git merge. Fase 3 (📬 carteiro, `study-deliver.sh`) fica gated por: maestro copiar um estudo pro core à mão ≥2×."
review_after: 2026-10-19
conflict_class: static
---

## Signal
**A Fase 1 da Constelação de Estudos aterrissou executável: o 🗺️ MAPA existe e roda contra
as estrelas reais.** O #1 (farol-organizador) foi reenquadrado — não era ajuste isolado do
beacon, era a 1ª fatia do observatório. O farol key-by-worktree **dobrou** como a COLUNA
PRESENÇA do mapa: o beacon deixou de só perguntar "quem está aqui?" e virou o sinal de "qual
estrela tem sessão viva agora?" dentro do painel macro das N frentes.

## A inovação (entregue)
- **`constellation-map.sh`** (molde `federation-status-scan.sh`): lê SÓ o frontmatter+Tier-0 de
  `docs/discussions/*/SEED.md` (fronteira estrutural via `fm_of` — awk sai no 2º `---`; o corpo
  NUNCA é lido) e emite o painel: phase · next_action · **colisão de `scope_globs`** ·
  **convergência de `objective_tags`** · **presença** (🕯️ por worktree). `--json` p/ compor.
- **`/meta:constellation`** — o comando fino que superfície o mapa pro maestro, com os
  invariantes (read-only, só-metadados, sob-convite) explícitos.
- **Beacon key-by-worktree:** `up` grava `worktree:` (a árvore a que o farol pertence); a coluna
  presença resolve `branch:` da estrela → worktree (via `git worktree list`) → beacon fresco.
- **Bug do hook corrigido no MOTOR:** `up` sem arg de hat preserva o hat declarado (o `refresh`
  do hook zerava a intenção de escrita a cada UserPromptSubmit). Espelha a preservação de `started_at`.

## Evidence
- **Dogfood real (6 estrelas):** o mapa mostra colisão `docs/onion/graph/` em 3 estrelas +
  `authorization-layers` em 2; convergência NS1 em 3 + intake-execucao em 2; presença 🕯️ para
  onion-pessoal-app (beacon vivo na worktree locked). Anti-divergência **antes** do post-hoc,
  exatamente a promessa do KB.
- **Disciplina motor-soberano (classe kg-radar) cumprida com negative checks:**
  - Fix do hat: hook `refresh` real preserva; motor antigo simulado → `hat: —` (o teste pega a regressão).
  - `ensure_exclude` → common-dir: **descoberta git 2.43** — o `info/exclude` por-worktree NÃO é
    lido; só o do common-dir esconde o beacon. Com `--git-dir` o teste (ii) FALHA (beacon vaza).
  - Corpo-nunca-lido: o decoy tem `objective_tags` só no CORPO; parser lendo o arquivo inteiro
    vaza SECRETTAG → o teste (f) discrimina o LIMITE, não só o first-match-exit.
  - Armadilha pipefail em `collisions()` (`for…done | sort`) corrigida (`:` no fim do lado esquerdo).
- **Gate integral verde:** `lint-selftest.sh` 316/0; beacon 12/12; constellation-map 7/7; `lint-artifacts.sh` 0/0.

## Next crumb
Ver `next_recommended`. É a continuação natural do observatório: 🔬 radar (Fase 2) e 📬 carteiro
(Fase 3), ambos **gated** pelos gatilhos do ADR. O mapa (Fase 1) é o que destrava a leitura macro
que os dois consomem. Origem: reenquadramento do maestro nesta sessão (o #1 é a 1ª fatia da
constelação, não um ajuste de beacon). Aterra em [[2026-07-19-farol-organizer-key-by-worktree]].
