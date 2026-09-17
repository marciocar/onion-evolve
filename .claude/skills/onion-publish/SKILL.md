---
description: >
  Conduz o maestro a PUBLICAR o Onion como plugin+marketplace num repo público (ex.: onion-plugins) —
  materializa todos os plugins do source, gera o marketplace.json self-contained e para no push
  (human-gated por I3). Ative quando o maestro quer publicar/gerar o marketplace de plugins ou o repo
  público de instalação (ex.: "publica o marketplace", "gera o repo de plugins", "materializa o
  onion-plugins", "quero distribuir o Onion como plugin"), mesmo sem dizer "wizard". NÃO é adoção
  (/meta:adopt vendoriza; isto é o canal de INSTALAÇÃO, sem linkage). Só roda na FONTE (role: source).
allowed-tools: AskUserQuestion Read Bash(bash .claude/utils/marketplace/*) Bash(bash .claude/validation/onion-version.sh*) Bash(git -C * rev-parse*) Bash(git rev-parse*) Bash(claude plugin validate*)
---

# Onion Publish — a Condução da publicação do marketplace (ajuda a FAZER)

Front-end conversacional da publicação do Onion como **plugin do Claude Code**. Colhe a intenção, mostra
o preview e roteia para o **procedimento determinístico** (`materialize-marketplace-repo.sh`) — nunca
reimplementa o que o helper faz. É o par de `onion-wizard` para o movimento "publicar marketplace".

## A lei (o que esta skill NÃO faz)

- **Não faz push.** O helper materializa e comita NO dir-alvo (repo do maestro, escritor único), mas o
  `git push` é **do maestro** (I3: a sessão do source nunca pusha repo alheio). Você para no checkpoint.
- **Não publica o moat.** A REGRA 61 (`check_moat_boundary`) já reprova qualquer manifesto que arraste
  meta-fábrica ou grafo privado; o helper tem a 2ª guarda por arquivo. Você **confirma a fronteira** antes,
  em voz alta — não assume.
- **Só na FONTE.** `role: source`. Num adotante, pare e explique que a publicação é ato do core.

## O fluxo (progressive disclosure)

### 1. Orient (contexto — sem perguntar ainda)
- Papel: `bash .claude/validation/onion-version.sh | grep '^role:'`. Se não for `source` → **pare**:
  "A publicação do marketplace é ato da FONTE (o core). Aqui o papel é `<role>`."
- Diga o que vai acontecer: materializar TODOS os plugins publicáveis (os `verticals/*.manifest.sh`) num
  repo-alvo self-contained, gerar o `marketplace.json` (name `onion-plugins`, sources relative-path) +
  README do marketplace e um README por plugin — ambos GERADOS (marketplace-readme.sh / plugin-readme.sh, padrão de referência
  do Claude Code: quick start, catálogo, manter em dia, proveniência) — e **parar antes do push**.

### 2. Confirmar a fronteira de MOAT (em voz alta)
Diga o que **NÃO** vai no repo público (por desenho): a meta-fábrica (create-*/adopt/marketplace/
decouple/evolve/absorb-skill/federação) e os **grafos privados** do core (o SSOT é do adotante —
KG-SSOT-First). Quem instala ganha a **capacidade operacional**; atualiza pelo plugin manager, sem merge.

### 3. Colher o alvo (AskUserQuestion)
Pergunte o **dir-alvo** (o repo `onion-plugins` que o maestro criou/vai criar — vazio ou já-git) e o
**nome** do marketplace (default `onion-plugins`). Não invente o caminho.

### 4. Materializar (o procedimento real)
```
bash .claude/utils/marketplace/materialize-marketplace-repo.sh <TARGET> [--name <n>]
```
- exit 0 → materializou (o helper reporta os plugins + o commit no alvo, SEM push).
- exit 3 → **vazamento de moat** (a 2ª guarda abortou): NÃO force; mostre o arquivo e reporte que um
  manifesto arrasta fonte de moat (corrigir o manifesto, não o helper).
- exit 2 → precondição (papel errado, alvo inválido): explique e pare.

### 5. Validar (se a CLI estiver disponível)
Para cada plugin materializado, sugira `claude plugin validate <TARGET>/plugins/<nome> --strict` (valida
plugin.json/frontmatter). Se a CLI não existir no ambiente, diga que o passo é opcional/manual.

### 6. Checkpoint do push (human-gated — W6)
**Pare aqui.** Apresente:
- o path do repo materializado + o nº de plugins;
- o comando que o **maestro** roda para publicar (você NÃO roda):
  ```
  cd <TARGET> && gh repo create marciocar/onion-plugins --public --source=. --push
  # ou, se o repo já existe: git -C <TARGET> push
  ```
- lembre: depois do push, usuários instalam com `/plugin marketplace add marciocar/onion-plugins` +
  `/plugin install onion@onion-plugins`.

## Referências
- Helper determinístico: `.claude/utils/marketplace/materialize-marketplace-repo.sh`
- Guarda de moat: REGRA 61 (`.claude/validation/lint-artifacts.sh` → `check_moat_boundary`)
- Doutrina: `onion-distribution-strategy-2026-06` (core-only) (L1 distribui / L2-L3 moat),
  `onion-plugin-marketplace-runbook-2026-07` (core-only) (Fase 5 publicação)
- Grafo: `docs/onion/graph/onion-plugin-publication-2026-08.kg.yaml`
- Par: `onion-wizard` (movimentos da família), `onion-onboarding` (ajuda a CONHECER)
