---
name: recover
description: |
  Recupera a identidade Onion de um repo adotado que perdeu contato com o framework:
  regenera .onion-version ausente/incompleto e o skeleton do CLAUDE.md. Nunca sobrescreve
  customizações locais (never-clobber). Use quando Claude Code abre "cego" ao Onion mesmo
  com .claude/ instalado. Para repos sem .claude/ algum, usar docs/applying/rescue-prompt.md.
  Relacionado: /meta:adopt --update, docs/applying/rescue-prompt.md.
model: sonnet
allowed-tools: Read Write Edit Glob Grep Bash(git *) Bash(bash *) Bash(awk *) Bash(grep *) Bash(ls *) Bash(cat *) Bash(mkdir *) Bash(touch *) Bash(date *)
argument-hint: "[--dry-run]"
category: meta
version: "1.2.0"
updated: "2026-07-03"
---

# 🧅 /meta:recover — Recuperação de Identidade Onion

## Objetivo

Restaurar o "saber de si" de um repo adotado que perdeu contexto Onion sem precisar de acesso à
fonte. Cobre dois sintomas:

- `.claude/.onion-version` ausente ou incompleto → Claude Code não reconhece o papel do repo
- `CLAUDE.md` sem skeleton Onion → nenhum roteamento de task manager, idioma ou branches

> **Pré-requisito:** `.claude/` com agents/commands/skills deve existir. Se não existe, o repo está
> totalmente orphaned — use [`docs/applying/rescue-prompt.md`](../../../docs/applying/rescue-prompt.md)
> (funciona sem Onion instalado).

---

## ⚡ Detecção de role — execute ANTES de qualquer outra etapa

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROLE="$(bash "$REPO/.claude/validation/onion-version.sh" 2>/dev/null | awk '/^role:/{print $2}')"
echo "Role detectado: ${ROLE:-desconhecido}"
```

**Se `role: source`** → este é o **core (onion-evolve)**. O fluxo de recuperação de adotante
**não se aplica**. O core não tem stamp commitado nem skeleton no CLAUDE.md — sua identidade vem
do git. Siga o [Health-check do core](#-health-check-do-core-role-source) abaixo e pare por aí.

**Se `role: adopted`** ou stamp ausente → continue com o [Diagnóstico automático](#diagnóstico-automático).

---

## 🏗️ Health-check do core (role: source)

Quando este comando é rodado no `onion-evolve` (ou qualquer repo com `role: source`):

### O que NÃO fazer
- Não regenerar stamp (é gerado ao vivo por `onion-version.sh` a partir do git)
- Não prepend skeleton no CLAUDE.md (o CLAUDE.md do core é a constituição do framework, não um skeleton)
- Não criar `docs/evolution/inbox` como se fosse um adotante (o core tem o canal, mas não é consumidor)

### O que fazer: validação determinística

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "=== Health-check do core Onion ==="

# 1. Stamp ao vivo
bash "$REPO/.claude/validation/onion-version.sh" 2>/dev/null \
  && echo "✅ onion-version.sh OK" || echo "❌ onion-version.sh falhou"

# 2. Gate determinístico: selftest + lint
echo ""
echo "--- lint-selftest ---"
bash "$REPO/.claude/validation/lint-selftest.sh" 2>&1 | tail -5

echo ""
echo "--- lint-artifacts (HARD only) ---"
bash "$REPO/.claude/validation/lint-artifacts.sh" 2>&1 | grep -E "HARD|OK ✓|FALHOU" | tail -3

# 3. Inventory sync
echo ""
echo "--- inventory sync ---"
bash "$REPO/.claude/validation/inventory.sh" 2>/dev/null | head -5
```

### Se encontrar arquivos corrompidos ou ausentes

Todos os arquivos do core estão versionados no git. Restaure com:

```bash
# Restaurar arquivo específico
git restore CLAUDE.md
git restore .claude/commands/meta/recover.md
# etc.

# Ou restaurar .claude/ inteiro (CUIDADO: descarta mudanças não commitadas)
git restore .claude/
```

### Se o problema for só contexto de sessão

Se os arquivos estão íntegros mas Claude Code abriu sem saber que é o Onion source:

```
/warm-up
```

O `/warm-up` carrega o contexto completo (README, docs, meta-specs, inventário). É o caminho
padrão para re-orientar uma sessão no core.

---

## Diagnóstico automático

Execute este bloco antes de qualquer alteração:

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "=== REPO: $REPO ==="

# Check 1: stamp
echo ""
echo "--- .onion-version ---"
if [ -f "$REPO/.claude/.onion-version" ]; then
  cat "$REPO/.claude/.onion-version"
else
  echo "AUSENTE"
fi

# Check 2: CLAUDE.md
echo ""
echo "--- CLAUDE.md (marker) ---"
if grep -q "instância adotada\|adopted" "$REPO/CLAUDE.md" 2>/dev/null; then
  echo "✅ Tem skeleton Onion"
else
  echo "❌ Sem skeleton Onion ($(head -1 "$REPO/CLAUDE.md" 2>/dev/null || echo 'ausente'))"
fi

# Check 3: .claude/ core
echo ""
echo "--- .claude/ core ---"
for d in agents commands skills utils validation; do
  [ -d "$REPO/.claude/$d" ] && echo "✅ $d" || echo "❌ $d AUSENTE"
done

# Check 4: task manager
echo ""
echo "--- Task Manager ---"
if [ -f "$REPO/.env" ]; then
  grep "TASK_MANAGER_PROVIDER" "$REPO/.env" 2>/dev/null || echo "TASK_MANAGER_PROVIDER não encontrado no .env"
else
  echo ".env AUSENTE"
fi

# Check 5: integration branch
echo ""
echo "--- Integration branch ---"
git -C "$REPO" branch -r 2>/dev/null | grep -E "develop|main" | head -5
```

Analisar a saída antes de prosseguir. Se todos os 5 checks passaram, o repo não precisa de recuperação.

---

## Coleta interativa

Com base no diagnóstico, coletar o que não foi auto-detectado:

### Task Manager (se ausente no .env)

Ler `.env` do repo: `TASK_MANAGER_PROVIDER` e `TASK_MANAGER_TRANSPORT`. Se ausente, perguntar:

- Qual o provider? (`jira` / `clickup` / `asana` / `linear` / `none`)
- Transport: `api` (padrão) ou `mcp`

### Integration branch

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Auto-detect: develop se existir, senão main/origin/HEAD
git -C "$REPO" ls-remote --heads origin develop 2>/dev/null | grep -q develop \
  && echo "develop" \
  || git -C "$REPO" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' \
  || echo "main"
```

Se o stamp antigo tiver `integration_branch`, reusar. Perguntar só se ambíguo.

### adopted_from

Ordem de prioridade:
1. Campo `adopted_from` do stamp existente
2. `git -C "$REPO" remote get-url origin` (se o repo tiver remote)
3. Perguntar ao maestro (caminho local ou URL git do core)

---

## Regeneração (never-clobber)

### 1. Stamp `.claude/.onion-version`

Preservar campos existentes se o stamp existir; sobrescrever só campos ausentes ou explicitamente corrigidos.

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STAMP="$REPO/.claude/.onion-version"
TODAY="$(date +%F)"

# Ler valores existentes (se stamp presente)
OLD_SOURCE_COMMIT="$(awk '/^source_commit:/{print $2}' "$STAMP" 2>/dev/null)"
OLD_SOURCE_DATE="$(awk '/^source_commit_date:/{print $2}' "$STAMP" 2>/dev/null)"
OLD_ADOPTED_FROM="$(awk '/^adopted_from:/{print $2}' "$STAMP" 2>/dev/null)"
OLD_ADOPTED_AT="$(awk '/^adopted_at:/{print $2}' "$STAMP" 2>/dev/null)"
OLD_MODE="$(awk '/^mode:/{print $2}' "$STAMP" 2>/dev/null)"
OLD_INTBRANCH="$(awk '/^integration_branch:/{print $2}' "$STAMP" 2>/dev/null)"

# Usar valor coletado ou preservar o antigo ou usar fallback
# ⚠️ NUNCA "adivinhar" o pin com o HEAD atual do core (incidente 2026-06-30/um adotante: um restore manual
#    carimbou o HEAD da fonte sem copiar os arquivos correspondentes → o anúncio downstream "você já
#    tem o fix" saiu falso). `unknown` é honesto e resolvível: o /meta:adopt --update tem guard
#    pin-integrity que detecta pin não confiável e re-sincroniza via cópia segura completa.
SOURCE_COMMIT="${OLD_SOURCE_COMMIT:-unknown}"
SOURCE_DATE="${OLD_SOURCE_DATE:-$TODAY}"
ADOPTED_FROM="${OLD_ADOPTED_FROM:-$ADOPTED_FROM_COLLECTED}"  # de Coleta
ADOPTED_AT="${OLD_ADOPTED_AT:-$TODAY}"
MODE="${OLD_MODE:-legacy}"
INT_BRANCH="${OLD_INTBRANCH:-$INT_BRANCH_COLLECTED}"        # de Coleta

cat > "$STAMP" <<EOF
framework: onion
source_commit: ${SOURCE_COMMIT}
source_commit_date: ${SOURCE_DATE}
role: adopted
adopted_from: ${ADOPTED_FROM}
adopted_at: ${ADOPTED_AT}
mode: ${MODE}
EOF
[ -n "${INT_BRANCH}" ] && printf 'integration_branch: %s\n' "${INT_BRANCH}" >> "$STAMP"
echo "recovered_at: ${TODAY}" >> "$STAMP"
```

### 2. CLAUDE.md — skeleton Onion

**Regra never-clobber:**
- Marker `instância adotada` presente → nada a fazer
- `CLAUDE.md` sem marker **e** sem conteúdo rico (só template padrão) → prepend skeleton
- `CLAUDE.md` sem marker **e** com conteúdo rico (doc custom, não-Onion) → criar `CLAUDE.onion.md` e avisar

Skeleton a prepend (adaptar com valores coletados):

```markdown
# 🧅 Sistema Onion — <NomeDoProjeto>

> Este repo é uma **instância adotada** do Onion (consumidor/standalone).
> Framework instalado em `.claude/`. Rode `/warm-up` para carregar contexto
> ou `/onion` para navegação inteligente.

## 🔌 Task Manager

| Variável | Valor |
|---|---|
| `TASK_MANAGER_PROVIDER` | `<provider>` |
| `TASK_MANAGER_TRANSPORT` | `<transport>` |

Antes de operar com tasks: **`@task-specialist`** (decomposição agnóstica).
Adapter: `.claude/utils/task-manager/adapters/<provider>.md`.

## 🌿 Estratégia de Branches (tabela de linhagens)

| Branch | Papel | É produção? | PRs de quê miram aqui |
|---|---|---|---|
| `<integration_branch>` | integração / base dos PRs Onion | não | framework, docs, co-evolução |
| `main` | produção | **sim** (verificar deploy real) | release |

> ⚠️ **Regra de linhagem** (sinal de campo um adotante 2026-07-03): se o repo tem MAIS de uma linhagem
> longa (ex.: trilho de produto ≠ trilho de integração), declare TODAS aqui com papel + regra de
> PR por trilho — e **nunca** infira produção do nome da branch: produção = commit deployado
> (registry/ECS) + config viva, não a branch que a doc aponta.

## 📝 Idioma

- **Chat, docs, comentários**: Português brasileiro (pt-BR)
- **Código, variáveis, branches, commits**: Inglês (Conventional Commits)

## 🏛️ Contextos de domínio (Spec-as-Code)

- `docs/business-context/` — negócio, produto, estratégia
- `docs/technical-context/` — arquitetura, C4, ADRs
- `docs/compliance-context/` — regulatório, governança
- `docs/knowledge-base/` — conceitos e frameworks reutilizáveis

## 📬 Co-evolução

Canal upstream (sinal→core): `docs/evolution/inbox/`
Canal downstream (update/anúncio do core): `docs/evolution/inbound/`
Rode `/meta:co-evolve` para ler/gerenciar.

---

```

### 3. `docs/evolution/` — canais de co-evolução (idempotente)

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
for ch in inbox inbound; do
  mkdir -p "$REPO/docs/evolution/$ch/_processed"
  [ -f "$REPO/docs/evolution/$ch/_processed/.gitkeep" ] \
    || touch "$REPO/docs/evolution/$ch/_processed/.gitkeep"
done
if [ ! -f "$REPO/docs/evolution/README.md" ]; then
  cat > "$REPO/docs/evolution/README.md" <<'PTR'
# Co-evolução (consumidor)

Este repo é **CONSUMIDOR** do Onion. Canais: `inbox/` para sinalizar o core (upstream) e `inbound/`
para receber relatórios de update/anúncios do core (downstream). Rode `/meta:co-evolve` para ler/gerenciar.
PTR
fi
```

---

## Validação 5-pontos

Execute após a regeneração. Cada check deve retornar ✅:

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "--- Validação de recuperação ---"

# 1. Stamp legível com role: adopted
bash "$REPO/.claude/validation/onion-version.sh" 2>/dev/null | grep -q "^role: adopted" \
  && echo "✅ stamp: role adopted" || echo "❌ stamp: inválido ou ausente"

# 2. CLAUDE.md tem marker
grep -q "instância adotada\|adopted" "$REPO/CLAUDE.md" 2>/dev/null \
  && echo "✅ CLAUDE.md: tem skeleton" || echo "⚠️  CLAUDE.md: CLAUDE.onion.md gerado — merge pendente"

# 3. .claude/ core presente
[ -d "$REPO/.claude/agents" ] && [ -d "$REPO/.claude/commands" ] \
  && echo "✅ .claude/: core presente" || echo "❌ .claude/: incompleto — usar rescue-prompt.md"

# 4. Adapter do task manager existe
TM="$(grep "^TASK_MANAGER_PROVIDER" "$REPO/.env" 2>/dev/null | cut -d= -f2 | tr -d ' ')"
[ -f "$REPO/.claude/utils/task-manager/adapters/${TM}.md" ] \
  && echo "✅ task-manager: adapter $TM presente" \
  || echo "⚠️  task-manager: adapter '$TM' não encontrado (ou provider não configurado)"

# 5. Integration branch resolvível
INT="$(awk '/^integration_branch:/{print $2}' "$REPO/.claude/.onion-version" 2>/dev/null)"
[ -n "$INT" ] \
  && echo "✅ integration_branch: $INT" \
  || echo "⚠️  integration_branch: não definido (PRs mirarão main por padrão)"
```

---

## Commit

Após validação bem-sucedida, commitar as alterações:

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO"
git add .claude/.onion-version CLAUDE.md CLAUDE.onion.md docs/evolution/ 2>/dev/null
# Se o repo usar husky sem node_modules na worktree, adicionar --no-verify:
git commit --no-verify -m "chore(onion): recover Onion identity

Regenerated .onion-version stamp and CLAUDE.md Onion skeleton after
context loss. .claude/ framework files were intact; only identity
metadata was missing. Ran /meta:recover to restore.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

> Se o repo usa husky + lint-staged **sem** `node_modules` na worktree: `--no-verify` é seguro
> (ENOENT = binário ausente, não violação de lint; CLAUDE.md está no `.prettierignore` Onion).
> Cura de raiz: migrar para hook nativo Onion (ver ADR native-githooks-standard).

---

## Quando usar recovery vs. update vs. rescue

| Situação | Caminho certo |
|---|---|
| `.claude/` intacto, stamp/CLAUDE.md quebrados | **Este comando** (`/meta:recover`) |
| `.claude/` desatualizado (nova versão do core) | `/meta:adopt --update <path>` (da sessão do core) |
| `.claude/` parcialmente ausente (utils/, hooks/) | `/meta:adopt --update <path>` (da sessão do core) |
| Sem `.claude/` algum | [`docs/applying/rescue-prompt.md`](../../../docs/applying/rescue-prompt.md) |
| Quer adoção inicial | `/meta:adopt <path>` (da sessão do core) |
