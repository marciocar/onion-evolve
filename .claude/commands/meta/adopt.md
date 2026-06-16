---
name: adopt
description: |
  Adota um repositório/pasta no Sistema Onion: recebe um caminho local ou URL git
  e instala o framework (modelo durável) ou opera in-place (efêmero), faseado e
  retomável. Greenfield-first. NÃO é CLI — roda dentro do Claude Code.
  Relacionado: /docs:reverse-consolidate, /meta:setup-integration, /docs:build-tech-docs.
model: sonnet
allowed-tools: Bash Read Write Edit Glob Grep
argument-hint: "<path-local | git-url> [--mode greenfield|legacy|regulated] [--in-place] [--dry-run]"
category: meta
version: "1.1.0"
updated: "2026-06-16"
---

# 🧅 /meta:adopt — Adoção de Repositório

## Objetivo

Operacionalizar a doutrina [`docs/applying/`](../../../docs/applying/README.md) como **comando
faseado**: apontar o Onion para um repo/pasta e "assumir o controle" — **instalar** o framework
(durável) ou **operar in-place** (efêmero), reusando atuadores existentes. Greenfield-first.

> **Decisão de design:** [ADR de Adoção](../../../docs/analysis/onion-adr-repo-adoption-2026-06.md).

## Identidade e fronteiras (do ADR — inegociável)

- **NÃO é CLI standalone** (invariante `architecture.md §5/§7`). Roda **dentro** de uma sessão
  Claude Code que **já tem** o framework Onion (a *fonte*); o alvo é o argumento.
- **"Controle" = um de dois modelos:**
  - **Instalar** (default) — copia o framework **para dentro** do alvo → vira **Onion soberano**.
  - **Operar in-place** (`--in-place`) — monta o alvo como working directory auxiliar e opera
    **sem instalar nada** (controle efêmero).
- **Modelo de execução (importante):** o comando roda na **sessão da FONTE** (este repo). As fases
  de **cópia** (2) e **carimbo** (5) operam sobre `<TARGET>` **por path, a partir da fonte**; as fases
  que rodam **dentro do alvo** (4 e os próximos passos) exigem **abrir o alvo** — ver
  [🔁 Transição de Contexto](#-transição-de-contexto-fonte--alvo).
- **Alto impacto:** escreve em repo alheio → o **Contrato de Segurança** abaixo é obrigatório.

## Quando usar

- Trazer um projeto novo/legado/regulado para o ciclo Onion (produto + engenharia + compliance).
- Preparar um repo para virar **membro soberano da federação** (rampa de entrada).
- Rodar uma análise Onion pontual sobre um repo externo (`--in-place`).

---

## 🛡️ Contrato de Segurança (OBRIGATÓRIO)

1. **Dry-run primeiro.** Listar o que seria clonado/copiado/criado (`git archive … | tar -t`) **sem
   escrever**. Só aplicar após **confirmação explícita**.
2. **Branch dedicada.** Aplicar em `onion/adopt` no alvo — **nunca** na branch default sem consentimento.
3. **Never-clobber.** Se o alvo **já tem** `.claude/`, é **re-adoção**: extrair para tmp, **diff**,
   aplicar só o delta. **Nunca** sobrescrever cego.
4. **Idempotente.** Re-adotar = atualizar a superfície + re-carimbar o stamp, não duplicar.

---

## ⚡ Fluxo de Execução (faseado, retomável)

> Sessão `<SOURCE_ROOT>/.claude/sessions/adopt-<slug>/STATE.md` — **cada fase atualiza o ponteiro
> `NEXT`** (checkpoint), permitindo retomar. Protocolo: [worklog-protocol.md](../../../docs/knowledge-base/concepts/worklog-protocol.md).
>
> ⚠️ **Modelo de execução — leia antes de rodar:** cada fase é um **shell novo** (estado Bash **NÃO
> persiste** entre chamadas no Claude Code). `$SOURCE_ROOT`, `$SRC_*`, `$TARGET`, `$MODE`, `$IN_PLACE`
> nos snippets são valores que o **orquestrador carrega entre fases via `STATE.md`** — em cada fase,
> **substitua o valor concreto** (não confie em env persistido). Persistir esses valores no `STATE.md`
> no PASSO 0 é o que torna a retomada (e o stamp da Fase 5) possível.

### PASSO 0 — Precondições, identidade da fonte e resolução do alvo

```bash
# 0a. FONTE: capturar ROOT + IDENTIDADE AGORA — antes de qualquer cd/cópia.
#     Crítico p/ o stamp (Fase 5): a identidade tem de vir da FONTE, não do alvo.
SOURCE_ROOT="$(git rev-parse --show-toplevel)"
SRC_ID="$(bash "$SOURCE_ROOT/.claude/validation/onion-version.sh")"   # yaml
echo "$SRC_ID" | grep -q '^role: source' \
  || { echo "Abortar: a sessão atual não é a fonte Onion."; exit 1; }
SRC_FRAMEWORK="$(awk '/^framework:/{print $2}'   <<<"$SRC_ID")"
SRC_COMMIT="$(awk '/^commit:/{print $2}'         <<<"$SRC_ID")"
SRC_COMMIT_DATE="$(awk '/^commit_date:/{print $2}' <<<"$SRC_ID")"

# 0b. Resolver o alvo ($1):
#   - caminho local existente → TARGET="$1"
#   - URL git                 → TARGET="${dest:-$(dirname "$SOURCE_ROOT")/<repo-name>}"
#                               git clone "$1" "$TARGET"   # NUNCA dentro de $SOURCE_ROOT

# 0c. Garantir git no alvo (greenfield pode não ter) — APENAS no modelo "instalar".
#     NUNCA no --in-place: ele "não copia nada / efêmero", não pode modificar o alvo.
if [ -z "$IN_PLACE" ] && [ ! -d "$TARGET/.git" ]; then git -C "$TARGET" init -q; fi

# 0d. Detectar MODO (ou --mode): greenfield (sem código) | legacy (tem) | regulated (marcadores/flag)
```

- Criar a sessão `adopt-<slug>/STATE.md` com `TARGET`, `MODE`, `SRC_*` capturados e `NEXT: Fase 1`.

### Fase 1 — Engenharia reversa (se houver código)

- **greenfield:** pular (nada a reverter).
- **legacy/regulated:** rodar o fluxo de `/docs:reverse-consolidate <TARGET>` (que **internamente**
  delega a `@docs-reverse-engineer` — **não** invocar o agente em paralelo) → alimenta `technical-context`.
- Checkpoint: `STATE.md NEXT: Fase 2`.

### Fase 2 — Instalar o framework  _(modelo "instalar"; PULAR se `--in-place`)_

```bash
cd "$TARGET"
git checkout -b onion/adopt 2>/dev/null || git checkout onion/adopt

# MANIFESTO = os pathspecs do git archive. git archive arquiva só a árvore de HEAD (TRACKED),
# então .claude/settings.local.json (gitignored), .claude/sessions/, .claude/.onion-version,
# docs/{analysis,materials,applying} e o INDEX.md da fonte ficam AUTOMATICAMENTE de fora.
manifest=(.claude/agents .claude/commands .claude/skills .claude/utils .claude/validation
          docs/meta-specs docs/knowledge-base docs/sdaal .env.example)

# DRY-RUN (sempre 1º): listar SEM extrair → apresentar ao usuário → aguardar confirmação.
git -C "$SOURCE_ROOT" archive HEAD -- "${manifest[@]}" | tar -t

# NEVER-CLOBBER: se "$TARGET/.claude" já existe → re-adoção (extrair p/ tmp + diff antes de aplicar).
# APLICAR (após confirmação):
git -C "$SOURCE_ROOT" archive HEAD -- "${manifest[@]}" | tar -x -C "$TARGET"
```

- Checkpoint: `NEXT: Fase 3`.

### Fase 3 — Scaffold de contextos + `CLAUDE.md` do alvo

- Criar `docs/{business,technical,compliance}-context/` (templates vazios). **Estes são a governança
  L1+ do ALVO** (domínio); as meta-specs copiadas são o **L0 do framework** (regras de operação do
  `.claude/`). O `@metaspec-gate-keeper` **dual-mode** valida artefatos do alvo contra o L1+.
- **Gerar** `<TARGET>/CLAUDE.md` (NÃO copiar o da fonte — o da fonte descreve *o framework*). Skeleton:
  ```markdown
  # <Nome do Projeto> — Claude Code Rules
  > Projeto sob o Sistema Onion (framework instalado em `.claude/`). Entrada: `/onion` · `/warm-up`.
  ## Task Manager
  Detectar `TASK_MANAGER_PROVIDER` no `.env` antes de operar com tasks (ver `.claude/utils/task-manager/`).
  ## Idioma
  Chat/docs/comentários: pt-BR · código/commits/branches: inglês (skill `language-standards`).
  ## Contextos (L1+)
  Negócio: `docs/business-context/` · Técnico: `docs/technical-context/` · Compliance: `docs/compliance-context/`
  ```
- Regenerar `docs/INDEX.md` do alvo (`/docs:build-index`). Checkpoint: `NEXT: Fase 4`.

### Fase 4 — Configurar integrações (`.env`) — **RODA NO ALVO**

Ver [🔁 Transição de Contexto](#-transição-de-contexto-fonte--alvo). No alvo: `cp .env.example .env`
+ `/meta:setup-integration`. Fallback gracioso se pulado. Checkpoint: `NEXT: Fase 5`.

### Fase 5 — Carimbar versão (da identidade da FONTE capturada no PASSO 0)

```bash
# USAR os SRC_* do PASSO 0 (carregados via STATE.md — shell não persiste; substitua os valores
# concretos). NÃO re-rodar onion-version.sh a partir do alvo (daria a identidade errada).
cat > "$TARGET/.claude/.onion-version" <<EOF
framework: ${SRC_FRAMEWORK}
source_commit: ${SRC_COMMIT}
source_commit_date: ${SRC_COMMIT_DATE}
role: adopted
adopted_from: $(git -C "$SOURCE_ROOT" remote get-url origin 2>/dev/null || echo "$SOURCE_ROOT")
adopted_at: $(date +%F)
mode: ${MODE}
EOF
```

- Se o alvo versiona `.claude/`, **committar** `.onion-version` (proveniência durável). `NEXT: Fase 6`.

### Fase 6 — Relatório + próximos passos

- Resumo: superfície instalada, modo, stamp, branch `onion/adopt`.
- **Próximos NO ALVO:** `/warm-up` → `/onion` → `/docs:build-tech-docs`.
- **Rampa da federação:** oferecer registrar o alvo como membro (`members.yaml`) — ver
  [multi-repo-federation.md](../../../docs/knowledge-base/concepts/multi-repo-federation.md).

---

## 🔁 Transição de Contexto (fonte → alvo)

Fases **2** e **5** operam sobre `<TARGET>` **por path, a partir da sessão-fonte** (cópia + escrita do
stamp). Fase **4** e os **próximos passos** rodam **dentro** do alvo — para isso, **abra o `<TARGET>`
no Claude Code** (working directory nativo; ex.: `/add-dir <TARGET>` ou nova sessão na pasta) e
continue lá. O comando **não** executa comandos "no alvo" a partir da fonte — ele os **indica**.

## Modos

| Modo | Diferença | Status |
|---|---|---|
| **greenfield** | scaffold + instalação; reverse-eng mínima | ✅ MVP (este comando) |
| **legacy** | reverse-eng pesada, migração gradual, **worktree obrigatório**, never-clobber reforçado | 🔜 iteração 2 |
| **regulated** | + `compliance-context` populado + agentes de compliance (ISO/SOC2/PMBOK) | 🔜 iteração 2 |

## Operar in-place (`--in-place`)

Não copia nada. **Fases que rodam:** PASSO 0 (resolver + adicionar working dir) → Fase 1 (reverse-eng,
opcional) → Fase 6 (relatório). **PULA Fases 2–5** (sem instalação → sem scaffold, sem stamp).
**Mecanismo:** adicionar `<target>` como *additional working directory* da sessão (recurso nativo —
ex.: `/add-dir <target>`). Controle **efêmero** — o repo **não** vira Onion. Ideal para análise one-off.

## Idempotência / re-adoção

Alvo com `.claude/` existente → **re-adoção**: extrair a superfície nova para tmp, **diff** vs o alvo,
aplicar só o delta, re-carimbar `.onion-version` (novo `source_commit`/`adopted_at`). **Nunca**
duplicar nem clobrar.

---

## 🔗 Referências

- **Decisão:** [ADR de Adoção](../../../docs/analysis/onion-adr-repo-adoption-2026-06.md)
- **Doutrina:** [`applying/`](../../../docs/applying/README.md) (greenfield/legacy/regulated)
- **Stamp:** `.claude/validation/onion-version.sh` · `architecture.md §6.1`
- **Atuadores reusados:** `/docs:reverse-consolidate` · `/meta:setup-integration` · `/docs:build-*-docs` · `/docs:build-index`
- **Rampa a jusante:** [federação multi-repo](../../../docs/knowledge-base/concepts/multi-repo-federation.md)
