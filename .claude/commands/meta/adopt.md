---
name: adopt
description: |
  Adota um repositório/pasta no Sistema Onion: recebe um caminho local ou URL git
  e instala o framework (modelo durável) ou opera in-place (efêmero), faseado e
  retomável. Greenfield-first. NÃO é CLI — roda dentro do Claude Code.
  Relacionado: /docs:reverse-consolidate, /meta:setup-integration, /docs:build-tech-docs.
model: sonnet
allowed-tools: Bash Read Write Edit Glob Grep
argument-hint: "<path-local | git-url> [--mode greenfield|legacy|regulated] [--in-place] [--update] [--dry-run]"
category: meta
version: "1.3.0"
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
- **"Controle" = um de dois modelos:** **instalar** (default, copia o framework → Onion soberano) ou
  **operar in-place** (`--in-place`, working dir auxiliar, sem instalar).
- **Modelo de execução (importante):** o comando roda na **sessão da FONTE**. Cópia (2) e carimbo (5)
  operam sobre `<TARGET>` **por path**; fases que rodam **dentro do alvo** (4 + próximos) exigem
  **abrir o alvo** — ver [🔁 Transição de Contexto](#-transição-de-contexto-fonte--alvo).
- **Alto impacto:** escreve em repo alheio → o **Contrato de Segurança** abaixo é obrigatório.

## Quando usar

- Trazer um projeto novo/legado/regulado para o ciclo Onion (produto + engenharia + compliance).
- Preparar um repo para virar **membro soberano da federação** (rampa de entrada).
- Rodar uma análise Onion pontual sobre um repo externo (`--in-place`).

---

## 🛡️ Contrato de Segurança (OBRIGATÓRIO)

1. **Dry-run primeiro.** O [Procedimento de cópia segura](#-procedimento-de-cópia-segura-never-clobber)
   sempre **mostra o diff** antes de escrever. Só aplica após **confirmação explícita**.
2. **Branch dedicada.** Instalar em `onion/adopt` — **nunca** na branch default sem consentimento.
3. **Never-clobber — IMPLEMENTADO, não só prometido.** Extrair p/ tmp, **diff** vs o alvo, aplicar só
   após revisão. Customizações locais aparecem no diff (o maestro decide) — ver o Procedimento.
4. **Idempotente.** Re-adotar/atualizar = aplicar o delta + re-carimbar, não duplicar.

---

## 🧩 Procedimento de cópia segura (never-clobber)

Usado pela **Fase 2** e pelo **`--update`**. Snippet self-contained (shell novo a cada fase).

```bash
SOURCE_ROOT="$(git rev-parse --show-toplevel)"
DEST="<INSTALL_DIR — ver Fase 2>"

# (a) MANIFESTO filtrado: só pathspecs que EXISTEM em HEAD — git archive aborta (exit 128) se um
#     pathspec não casa nada. Filtrar evita o erro críptico de tar.
want=(.claude/agents .claude/commands .claude/skills .claude/utils .claude/validation
      docs/meta-specs docs/knowledge-base docs/sdaal .env.example)
manifest=(); for p in "${want[@]}"; do
  git -C "$SOURCE_ROOT" ls-tree HEAD -- "$p" | grep -q . && manifest+=("$p")
done

# (b) Extrair para TMP (git archive = só a árvore TRACKED de HEAD → settings.local.json, sessions/,
#     .onion-version, docs/{analysis,materials,applying} ficam AUTOMATICAMENTE de fora).
TMP="$(mktemp -d)"
git -C "$SOURCE_ROOT" archive HEAD -- "${manifest[@]}" | tar -x -C "$TMP"

# (c) DIFF vs o alvo (dry-run): novos, alterados e CONFLITOS (customização local) aparecem aqui.
diff -rq "$TMP" "$DEST" 2>/dev/null || true

# (d) Após confirmação do maestro: aplicar (cp preserva o que NÃO está no manifesto).
cp -R "$TMP"/. "$DEST"/ && rm -rf "$TMP"
```

> Hoje o apply é cópia-por-cima após revisão do diff (conflitos **surgem**, o maestro decide). Merge
> 3-way automático (preservar customização local sem revisão) é melhoria futura.

---

## ⚡ Fluxo de Execução (faseado, retomável)

> Sessão `<SOURCE_ROOT>/.claude/sessions/adopt-<slug>/STATE.md` — **cada fase atualiza o ponteiro
> `NEXT`** (checkpoint), permitindo retomar. Protocolo: [worklog-protocol.md](../../../docs/knowledge-base/concepts/worklog-protocol.md).
>
> ⚠️ **Modelo de execução — leia antes de rodar:** cada fase é um **shell novo** (estado Bash **NÃO
> persiste** entre chamadas no Claude Code). `$SOURCE_ROOT`, `$SRC_*`, `$TARGET`, `$MODE`, `$IN_PLACE`,
> `$INSTALL_DIR` nos snippets são valores que o **orquestrador carrega entre fases via `STATE.md`** —
> em cada fase, **substitua o valor concreto** (não confie em env persistido).

### PASSO 0 — Precondições, identidade da fonte e resolução do alvo

```bash
# 0a. FONTE: capturar ROOT + IDENTIDADE AGORA — antes de qualquer cd/cópia (crítico p/ o stamp da Fase 5).
SOURCE_ROOT="$(git rev-parse --show-toplevel)"
SRC_ID="$(bash "$SOURCE_ROOT/.claude/validation/onion-version.sh")"   # yaml
echo "$SRC_ID" | grep -q '^role: source' || { echo "Abortar: sessão não é a fonte Onion."; exit 1; }
SRC_FRAMEWORK="$(awk '/^framework:/{print $2}'     <<<"$SRC_ID")"
SRC_COMMIT="$(awk '/^commit:/{print $2}'           <<<"$SRC_ID")"
SRC_COMMIT_DATE="$(awk '/^commit_date:/{print $2}' <<<"$SRC_ID")"

# 0b. Resolver o alvo ($1): caminho local → TARGET="$1"; URL git → git clone p/ TARGET (NUNCA dentro de $SOURCE_ROOT).
# 0c. Garantir git no alvo — APENAS no modelo "instalar" (NUNCA no --in-place, que não toca o alvo):
if [ -z "$IN_PLACE" ] && [ ! -d "$TARGET/.git" ]; then git -C "$TARGET" init -q; fi
# 0d. Detectar MODO (ou --mode): greenfield (sem código) | legacy (tem) | regulated (marcadores/flag).
```

- Persistir `TARGET`, `MODE`, `SRC_*` no `STATE.md`. `NEXT: Fase 1`.

### Fase 1 — Engenharia reversa (se houver código)

- **greenfield:** pular.
- **legacy/regulated:** rodar o fluxo de `/docs:reverse-consolidate <TARGET>` (que **internamente**
  delega a `@docs-reverse-engineer` — não invocar o agente em paralelo) → alimenta `technical-context`.
- Checkpoint: `NEXT: Fase 2`.

### Fase 2 — Instalar o framework  _(PULAR se `--in-place`)_

```bash
# 2a. Branch + INSTALL_DIR conforme o MODO. No legacy a WORKTREE SUBSTITUI o checkout em $TARGET
#     (não rodar o checkout abaixo no legacy) — isola a árvore de trabalho do legado.
if [ "$MODE" = legacy ]; then
  INSTALL_DIR="$(dirname "$TARGET")/onion-adopt-$(basename "$TARGET")"
  # [retomável/idempotente] cria worktree+branch; numa retomada, reusa a worktree/branch já existentes.
  git -C "$TARGET" worktree add "$INSTALL_DIR" -b onion/adopt 2>/dev/null \
    || git -C "$TARGET" worktree add "$INSTALL_DIR" onion/adopt 2>/dev/null || true
else
  git -C "$TARGET" checkout -b onion/adopt 2>/dev/null || git -C "$TARGET" checkout onion/adopt
  INSTALL_DIR="$TARGET"
fi
# 2b. Rodar o «Procedimento de cópia segura» com DEST="$INSTALL_DIR" (filtra manifesto, tmp, diff, aplica).
```

- Checkpoint: `NEXT: Fase 3`.

### Fase 3 — Scaffold de contextos + `CLAUDE.md` do alvo

- Criar `docs/{business,technical,compliance}-context/` em `$INSTALL_DIR` (templates vazios). **Estes são
  a governança L1+ do ALVO** (domínio); as meta-specs copiadas são o **L0 do framework**. O
  `@metaspec-gate-keeper` dual-mode valida o alvo contra o L1+.
- **Gerar o CLAUDE.md — com never-clobber** (NÃO sobrescrever o do alvo, se houver):
  ```bash
  [ -f "$INSTALL_DIR/CLAUDE.md" ] && OUT="$INSTALL_DIR/CLAUDE.onion.md" || OUT="$INSTALL_DIR/CLAUDE.md"
  # escrever o skeleton em "$OUT" (merge de CLAUDE.onion.md → CLAUDE.md fica a cargo do maestro)
  ```
  Skeleton mínimo: identidade do projeto + roteamento Task Manager + idioma (skill `language-standards`)
  + contextos L1+ + entrada `/onion`·`/warm-up`.
- Regenerar `docs/INDEX.md` do alvo (`/docs:build-index`). Checkpoint: `NEXT: Fase 4`.

### Fase 4 — Configurar integrações (`.env`) — **RODA NO ALVO**

Ver [🔁 Transição de Contexto](#-transição-de-contexto-fonte--alvo). No alvo: `cp .env.example .env`
+ `/meta:setup-integration`. Fallback gracioso se pulado. `NEXT: Fase 5`.

### Fase 5 — Carimbar versão (da identidade da FONTE capturada no PASSO 0)

```bash
# USAR os SRC_* do PASSO 0 (carregados via STATE.md — shell não persiste). NÃO re-rodar
# onion-version.sh a partir do alvo (daria a identidade errada).
cat > "$INSTALL_DIR/.claude/.onion-version" <<EOF
framework: ${SRC_FRAMEWORK}
source_commit: ${SRC_COMMIT}
source_commit_date: ${SRC_COMMIT_DATE}
role: adopted
adopted_from: $(git -C "$SOURCE_ROOT" remote get-url origin 2>/dev/null || echo "$SOURCE_ROOT")
adopted_at: $(date +%F)
mode: ${MODE}
EOF
```

- Se o alvo versiona `.claude/`, **committar** `.onion-version`. `NEXT: Fase 6`.

### Fase 6 — Relatório + próximos passos

- Resumo: superfície instalada, modo, `INSTALL_DIR`, stamp, branch `onion/adopt`.
- **Próximos NO ALVO:** `/warm-up` → `/onion` → `/docs:build-tech-docs`.
- **Rampa da federação:** oferecer registrar o alvo como membro (`members.yaml`).

---

## 🔁 Transição de Contexto (fonte → alvo)

Fases **2** e **5** operam sobre `<INSTALL_DIR>` **por path, a partir da sessão-fonte**. Fase **4** e os
**próximos passos** rodam **dentro** do alvo — **abra o alvo no Claude Code** (working dir nativo; ex.:
`/add-dir <INSTALL_DIR>` ou nova sessão na pasta) e continue lá. O comando **não** executa comandos "no
alvo" a partir da fonte — ele os **indica**.

## Modos

| Modo | Diferença | Status |
|---|---|---|
| **greenfield** | scaffold + instalação; reverse-eng mínima | ✅ |
| **legacy** | reverse-eng obrigatória; **install em worktree** (Fase 2a); never-clobber de `CLAUDE.md`→`CLAUDE.onion.md` (Fase 3) | ✅ |
| **regulated** | + `compliance-context` populado + frameworks (ISO/SOC2/PMBOK) | ✅ |

As diferenças de modo estão **embutidas nas fases** (Fase 1 reverse-eng; Fase 2a branch/worktree; Fase 3
CLAUDE.md). **regulated** = o modo aplicável **+**: detectar ISO 27001/22301/SOC2/PMBOK (marcadores ou
`--mode`); na Fase 3 popular `docs/compliance-context/` via `/docs:build-compliance-docs` (no alvo); os
agentes de compliance já vêm no manifesto; coordenação compliance↔engenharia via `meta/`/docs (`§4.3`).

## Operar in-place (`--in-place`)

Não copia nada. **Fases que rodam:** PASSO 0 (resolver + adicionar working dir) → Fase 1 (reverse-eng,
opcional) → Fase 6 (relatório). **PULA Fases 2–5.** Mecanismo: adicionar `<target>` como *additional
working directory* (ex.: `/add-dir <target>`). Controle **efêmero** — o repo **não** vira Onion.

## Idempotência / re-adoção

Alvo com `.claude/` existente → **re-adoção**: o [Procedimento de cópia segura](#-procedimento-de-cópia-segura-never-clobber)
já faz tmp→diff→aplicar (o diff mostra o que muda), e re-carimba `.onion-version`. **Nunca** duplicar.

## Atualizar um repo adotado (`--update`)

Repo já adotado → trazer atualizações do framework. **Reusa o stamp** (self-contained):

```bash
SOURCE_ROOT="$(git rev-parse --show-toplevel)"; TARGET="<path do alvo>"
# GUARD: precisa de stamp (senão não foi adotado).
[ -f "$TARGET/.claude/.onion-version" ] || { echo "Repo não adotado: rode a adoção primeiro."; exit 1; }
ADOPTED_COMMIT="$(awk '/^source_commit:/{print $2}' "$TARGET/.claude/.onion-version")"
NOW="$(git -C "$SOURCE_ROOT" rev-parse --short=12 HEAD)"
[ "$ADOPTED_COMMIT" = "$NOW" ] && { echo "Já atualizado ($NOW)."; exit 0; }

# DELTA do framework desde a adoção (manifesto filtrado, como no Procedimento):
want=(.claude/agents .claude/commands .claude/skills .claude/utils .claude/validation
      docs/meta-specs docs/knowledge-base docs/sdaal .env.example)
manifest=(); for p in "${want[@]}"; do git -C "$SOURCE_ROOT" ls-tree HEAD -- "$p" | grep -q . && manifest+=("$p"); done
git -C "$SOURCE_ROOT" diff --stat "$ADOPTED_COMMIT"..HEAD -- "${manifest[@]}"
```

- Aplicar via o **Procedimento de cópia segura** (`DEST="$TARGET"`) — diff revela customizações locais.
- **Re-carimbar** com a identidade NOVA da fonte (re-derivar — não há PASSO 0 aqui):
  ```bash
  SRC_ID="$(bash "$SOURCE_ROOT/.claude/validation/onion-version.sh")"   # novo commit/date
  # Reusar o heredoc da Fase 5 mapeando commit→source_commit e commit_date→source_commit_date,
  # PRESERVANDO adopted_from/mode do stamp antigo; atualizar source_commit/date + adopted_at=$(date +%F).
  ```
- **Tie com a federação:** o `source_commit` do stamp **é** a versão de cada membro (member-version
  awareness — [multi-repo-federation.md](../../../docs/knowledge-base/concepts/multi-repo-federation.md)).

---

## 🔗 Referências

- **Decisão:** [ADR de Adoção](../../../docs/analysis/onion-adr-repo-adoption-2026-06.md)
- **Doutrina:** [`applying/`](../../../docs/applying/README.md) (greenfield/legacy/regulated)
- **Stamp:** `.claude/validation/onion-version.sh` · `architecture.md §6.1`
- **Atuadores reusados:** `/docs:reverse-consolidate` · `/meta:setup-integration` · `/docs:build-*-docs` · `/docs:build-index`
- **Rampa a jusante:** [federação multi-repo](../../../docs/knowledge-base/concepts/multi-repo-federation.md)
