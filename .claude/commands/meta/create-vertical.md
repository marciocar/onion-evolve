---
name: create-vertical
description: |
  Scaffolda uma VERTICAL (hub homônimo + help contextual + resolver de SSOT/book +
  bootstrap) para qualquer sujeito — uma dimensão do framework ou um projeto-cliente.
  Orquestrador fino que compõe os helpers F1 + os create-* + fecha com /meta:inventory.
allowed-tools: Read Write Bash(bash .claude/utils/vertical/*) Bash(bash .claude/utils/marketplace/*) Bash(bash .claude/validation/*) Bash(ls *) Bash(grep *) Bash(git *)

parameters:
  - name: vertical_slug
    description: Nome da vertical em kebab-case (vira o namespace do hub)
    required: true
  - name: title
    description: Título legível (default derivado do slug)
    required: false
  - name: mode
    description: "in-place (default, repo existente) | greenfield (--new <path>)"
    required: false
  - name: plugin
    description: "--plugin materializa manifesto + assemble + marketplace.json + roles.yaml"
    required: false

category: meta
tags:
  - vertical
  - scaffolding
  - vertical-hub
  - meta
  - automation

version: "0.1.0"
updated: "2026-07-15"

related_commands:
  - /meta/create-command
  - /meta/create-agent
  - /meta/create-skill
  - /meta/create-knowledge-base
  - /meta/adopt
  - /meta/inventory

related_agents:
  - command-creator-specialist
  - agent-skills-specialist
  - onion
---

# 🧭 Criar Vertical

Generaliza o **DNA do `onion`** (hub-skill + help contextual + resolver de SSOT/book +
bootstrap) para scaffoldar uma **vertical** de 1ª classe — o padrão que todo adotante
hoje reinventa à mão (sinal de um adotante de campo A1). Orquestrador **fino-delega**
(mesmo espírito de `create-command`/`create-skill`): **compõe** os helpers testáveis da
F1 e os `create-*`, não reimplementa.

## 🎯 Objetivo

Gerar o esqueleto de uma vertical — `hub + help + book + bootstrap` — para **qualquer
sujeito**, e deixar o repo em estado válido (SSOT sincronizada, lint verde).

> **Duas acepções de "vertical", uma só máquina** (ADR `onion-adr-create-vertical-2026-07`,
> Decisão 1): o padrão vale tanto para uma **dimensão do framework** (engineering) quanto
> para um **projeto-cliente** (um cliente real). As verticais do Onion são as instâncias-dogfood.

## 🧩 Modos (Decisão 2 — ambos)

| Modo | Quando | Como |
|------|--------|------|
| **in-place** (default) | scaffoldar a vertical num repo que já existe | `--dir <repo>` (default `.`) |
| **greenfield** | começar um projeto novo do zero | `--new <path>` → cria o dir (+ `git init`) e escreve nele |

`--plugin` (Decisão 3, **opcional**): por padrão gera só a estrutura (hub+help+book+
bootstrap); com `--plugin`, materializa manifesto + `assemble-plugin.sh` + `marketplace.json`
+ registro em `roles.yaml`. Sem a flag, **não** impõe o Capability Contract (Regras 19/20).

## ⚡ Fluxo de Execução

### Passo 0 — Parse & modo

```bash
# entrada: <vertical-slug> [--title "T"] [--dir <repo> | --new <path>] [--plugin] [--dry-run]
SLUG="{{vertical_slug}}"
```

- SE `--new <path>` → **greenfield**: criar `<path>` (`mkdir -p` + `git init` se ainda não for repo); `REPO=<path>`.
- SENÃO → **in-place**: `REPO=` `--dir` (default `.`).
- Título default = slug capitalizado (os helpers já derivam se `--title` ausente).

### Passo 1 — Validações (antes de escrever)

```bash
# 1. kebab-case
case "$SLUG" in *[!a-z0-9-]*|-*|*-|"") echo "❌ slug deve ser kebab-case"; exit 1 ;; esac

# 2. colisão de namespace — hub/skill/comando já existentes no repo alvo
ls "$REPO/.claude/skills/$SLUG" 2>/dev/null && echo "⚠️ skill '$SLUG' já existe (never-clobber vai preservar)"
grep -rl "^name: $SLUG$" "$REPO/.claude/commands/" 2>/dev/null

# 3. não colidir com uma dimensão-vertical reservada do core
grep -q "onion-$SLUG" .claude/utils/marketplace/roles.yaml 2>/dev/null && echo "⚠️ 'onion-$SLUG' é dimensão do core — confirme o sujeito"
```

Os helpers herdam o **Contrato de Segurança** (never-clobber, `--dry-run`, idempotente):
uma re-execução nunca sobrescreve — só avisa. **Sempre** rodar `--dry-run` primeiro e
mostrar o plano antes de escrever de fato.

### Passo 2 — Scaffold do núcleo (o NOVO da F1) via helpers

Compor os **3 helpers testáveis** (cobertos por `lint-selftest.sh`), nesta ordem:

```bash
# 2a. hub homônimo + help contextual + resolver de SSOT/book (substitui {{PROJECT}}/{{PROJECT_TITLE}})
bash .claude/utils/vertical/bootstrap-new-project.sh "$SLUG" ${TITLE:+--title "$TITLE"} --dir "$REPO" --dry-run
#     → confirmar → repetir sem --dry-run

# 2b. diretório do book/SSOT: docs/<slug>-context/README.md (contrato mínimo)
bash .claude/utils/vertical/scaffold-book-dir.sh "$SLUG" ${TITLE:+--title "$TITLE"} --dir "$REPO" --dry-run
#     → confirmar → repetir sem --dry-run
```

Isso entrega:
- `.claude/skills/<slug>/SKILL.md` — hub-roteador homônimo (deriva da SSOT viva, **nunca hardcoda**).
- `.claude/commands/<slug>/help.md` — ajuda contextual (entrega + próximos passos do estado vivo).
- `.claude/skills/<slug>-context/SKILL.md` — resolver de book/SSOT (cadeia de resolução + bootstrap gated).
- `docs/<slug>-context/README.md` — o book, com o contrato de SSOT mínimo.

> **Decisão 3 do ADR (anti-hardcoding):** o hub gerado deriva o roteamento do inventário
> escaneado + `/<slug>:help` — nunca embute contagens/listas (corrige o débito do agente `onion.md`).

### Passo 3 — Artefatos do domínio (opcional, delega aos create-*)

O núcleo é o esqueleto; os **comandos/agentes/KB reais** da vertical são gerados pelos
`create-*` (reuso, não reimplementação). Oferecer, conforme a intenção:

| Precisa de… | Delegar a |
|-------------|-----------|
| um comando da vertical | `/meta:create-command <nome> --category <slug>` |
| um agente especialista | `/meta:create-agent` (ou `-express`) → `@agent-creator-specialist` |
| outra skill | `/meta:create-skill` → `@agent-skills-specialist` |
| uma KB de referência | `/meta:create-knowledge-base` |

Preencher as seções `_(...)_` dos esqueletos gerados com o domínio real da vertical.

### Passo 4 — Empacotar como plugin (opcional, só com `--plugin`)

```bash
# 4a. manifesto da vertical (SSOT de montagem) — modelar pelos existentes
ls .claude/utils/marketplace/verticals/*.manifest.sh   # ex.: onion-design.manifest.sh
#     escrever verticals/<slug>.manifest.sh (PLUGIN_NAME/VERSION/DESC, COMMANDS/AGENTS/SKILLS/...)

# 4b. montar o plugin a partir do manifesto
bash .claude/utils/marketplace/assemble-plugin.sh .claude/utils/marketplace/verticals/<slug>.manifest.sh

# 4c. regenerar o registro do marketplace (fecha o sinal A3 — derivado dos plugin.json)
bash .claude/utils/marketplace/generate-marketplace.sh > .claude-plugin/marketplace.json

# 4d. registrar a vertical no bundle de papel (roles.yaml) conforme o sujeito
#     editar roles.yaml → adicionar onion-<slug> ao(s) role(s) certo(s)
```

O lint (`check_role_bundle_sync`) exige: todo vertical em `roles.yaml` tem manifesto **e**
está no `marketplace.json`. Sem `--plugin`, este passo é pulado por completo.

### Passo 5 — Fechar: sincronizar SSOT + lint

**Obrigatório** quando escreveu no **próprio core** (criou skill/comando contados pela SSOT):

```bash
bash .claude/validation/inventory.sh --markdown > docs/onion/inventory.md
bash .claude/validation/lint-artifacts.sh --fix      # propaga contagens (Regra 16)
bash .claude/validation/lint-artifacts.sh            # confirma 0 HARD / 0 SOFT
```

Equivalente canônico: **`/meta:inventory`**. Mecanismo: `common:prompts:inventory-sync-after-create`.

> **Escopo do Passo 5:** só quando o alvo é o **core** (`--dir .` neste repo). Ao scaffoldar
> num repo-cliente (`--new`/`--dir <outro>`), a SSOT a sincronizar é a **daquele** repo —
> rodar o `inventory.sh`/lint de lá (se o repo tiver o framework), não a do core.
>
> **Greenfield sem framework (o caso comum do `--new`):** um repo novo nasce **sem** as
> ferramentas do core (`inventory.sh`/lint), então o Passo 5 **não tem o que rodar** — e
> tudo bem: o skeleton gerado (hub + help + resolver + book) é válido por si. Para ganhar o
> gate mecânico (lint/inventory) e o resto do framework, **adote** depois com
> `/meta:adopt <path>`; o esqueleto da vertical convive com a adoção (never-clobber).
> Sinal de campo (dogfood F3, 2026-07-30): sem esta nota, o greenfield ficava sem close acionável.

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ VERTICAL CRIADA — <slug>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 Hub:      .claude/skills/<slug>/SKILL.md
🧭 Help:     .claude/commands/<slug>/help.md
📚 Book:     .claude/skills/<slug>-context/SKILL.md + docs/<slug>-context/README.md
📦 Plugin:   <materializado | pulado (sem --plugin)>
🔄 SSOT:     <sincronizada via /meta:inventory | N/A (repo-cliente)>

🚀 Próximo: preencher os esqueletos `_(...)_` com o domínio real;
            adicionar comandos via /meta:create-command --category <slug>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- ADR: `../../../docs/knowledge-base/decisions/onion-adr-create-vertical-2026-07.md` (4 decisões + mapa COMPOR vs NOVO)
- Helpers F1: `.claude/utils/vertical/{bootstrap-new-project,scaffold-book-dir}.sh` · `.claude/utils/marketplace/generate-marketplace.sh`
- Plugin: `.claude/utils/marketplace/{assemble-plugin.sh,roles.yaml,verticals/*.manifest.sh}`
- Fragmento de sync: `common:prompts:inventory-sync-after-create`

## ⚠️ Notas

- **Fino-delega**: este comando **coordena**; a geração contextualizada vive nos helpers +
  specialists. Para o esqueleto cru sem orquestração, rode os helpers direto.
- **Never-clobber sempre**: rodar `--dry-run` e mostrar o plano antes de escrever.
- **Face de design (sinal B3)** é **F4 gated** — fora do núcleo (F1–F3).
- Limites da meta-spec `commands.md`: 500 linhas recomendado, 800 hard.
