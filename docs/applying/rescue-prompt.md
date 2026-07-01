# 🧅 Onion Rescue Prompt

> **Como usar:** Abra este arquivo em qualquer sessão Claude Code — mesmo sem Onion instalado.
> Cole o conteúdo da seção **"Prompt para Claude"** no chat, ou simplesmente abra este arquivo
> como contexto. Claude detectará o modo correto e executará a recuperação.

---

## Prompt para Claude

```
Você está em um repo que pode ter perdido o contato com o framework Onion, ou nunca o teve.
Execute este processo de recuperação/adoção em etapas — sem pular o diagnóstico.

---

## ETAPA 1 — Diagnóstico (sempre primeiro)

Leia o estado atual do repo:

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "Repo: $REPO"
echo ""
echo "--- .claude/ ---"
ls "$REPO/.claude/" 2>/dev/null || echo "AUSENTE"
echo ""
echo "--- .onion-version ---"
cat "$REPO/.claude/.onion-version" 2>/dev/null || echo "AUSENTE"
echo ""
echo "--- CLAUDE.md (linha 1) ---"
head -3 "$REPO/CLAUDE.md" 2>/dev/null || echo "AUSENTE"
echo ""
echo "--- .env (task manager) ---"
grep "TASK_MANAGER" "$REPO/.env" 2>/dev/null || echo "AUSENTE ou sem TASK_MANAGER"
echo ""
echo "--- branches remotas ---"
git -C "$REPO" branch -r 2>/dev/null | grep -E "develop|main" | head -5
```

Com base na saída, determine o MODO:

| Condição | Modo |
|---|---|
| `.claude/` tem `agents/`, `commands/`, `skills/` | **RECOVERY** — framework presente, identidade perdida |
| `.claude/` existe mas com estrutura diferente (sem agents/commands/skills Onion) | **RECOVERY PARCIAL** — só identity + co-evolução |
| `.claude/` ausente ou vazio | **ADOPTION REQUEST** — repo virgem |

Reporte o modo detectado antes de continuar.

---

## ETAPA 2 — Coleta de informações

Independentemente do modo, colete:

1. **Nome do projeto** (ler README.md linha 1 ou package.json `name`)
2. **Task Manager** — ler `.env`: `TASK_MANAGER_PROVIDER` e `TASK_MANAGER_TRANSPORT`
   - Se ausente, perguntar: qual provider? (jira / clickup / asana / linear / none)
   - Transport default: `api`
3. **Integration branch** — auto-detectar:
   ```bash
   git -C "$REPO" ls-remote --heads origin develop 2>/dev/null | grep -q develop \
     && echo "develop" \
     || git -C "$REPO" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' \
     || echo "main"
   ```
4. **Stack principal** (ler package.json ou Gemfile ou requirements.txt — 1 linha)
5. **adopted_from** (só nos modos RECOVERY): ler campo do stamp ou perguntar

Reporte os valores coletados. Pergunte ao usuário APENAS o que não pôde ser detectado.

---

## ETAPA 3A — RECOVERY (framework Onion presente)

Use este bloco se o modo for RECOVERY ou RECOVERY PARCIAL.

### 3A.1 Regenerar stamp `.claude/.onion-version`

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STAMP="$REPO/.claude/.onion-version"
TODAY="$(date +%F)"

# Preservar campos existentes
OLD_SOURCE_COMMIT="$(awk '/^source_commit:/{print $2}' "$STAMP" 2>/dev/null)"
OLD_ADOPTED_FROM="$(awk '/^adopted_from:/{print $2}' "$STAMP" 2>/dev/null)"
OLD_ADOPTED_AT="$(awk '/^adopted_at:/{print $2}' "$STAMP" 2>/dev/null)"
OLD_MODE="$(awk '/^mode:/{print $2}' "$STAMP" 2>/dev/null)"
OLD_INT="$(awk '/^integration_branch:/{print $2}' "$STAMP" 2>/dev/null)"

# Usar coletado ou preservar
cat > "$STAMP" <<EOF
framework: onion
source_commit: ${OLD_SOURCE_COMMIT:-unknown}
source_commit_date: ${OLD_SOURCE_DATE:-$TODAY}
role: adopted
adopted_from: ${OLD_ADOPTED_FROM:-<PREENCHER: path ou URL do onion-evolve>}
adopted_at: ${OLD_ADOPTED_AT:-$TODAY}
mode: ${OLD_MODE:-legacy}
EOF
[ -n "${OLD_INT:-$INT_BRANCH_COLETADO}" ] \
  && printf 'integration_branch: %s\n' "${OLD_INT:-$INT_BRANCH_COLETADO}" >> "$STAMP"
echo "recovered_at: $TODAY" >> "$STAMP"
echo "stamp regenerado."
```

### 3A.2 Regenerar skeleton no CLAUDE.md (never-clobber)

Verificar se CLAUDE.md tem o marker `instância adotada`:

- **Tem marker** → nada a fazer, pular.
- **Sem marker + conteúdo é template genérico** (ex.: "Claude AI Configuration for Nx Workspace") → **prepend** o skeleton abaixo.
- **Sem marker + conteúdo rico/custom** → criar `CLAUDE.onion.md` com o skeleton e avisar o usuário para mergear manualmente.

Skeleton a prepend/criar (substituindo `<...>` com valores coletados):

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

## 🌿 Estratégia de Branches

| Branch | Papel |
|---|---|
| `<integration_branch>` | integração / base dos PRs Onion |
| `main` | produção |

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

### 3A.3 Provisionar canais de co-evolução (idempotente)

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
for ch in inbox inbound; do
  mkdir -p "$REPO/docs/evolution/$ch/_processed"
  touch "$REPO/docs/evolution/$ch/_processed/.gitkeep" 2>/dev/null || true
done
[ -f "$REPO/docs/evolution/README.md" ] || cat > "$REPO/docs/evolution/README.md" <<'PTR'
# Co-evolução (consumidor)

Canais: `inbox/` para sinalizar o core (upstream) e `inbound/` para receber relatórios do core.
Rode `/meta:co-evolve` para ler/gerenciar.
PTR
echo "co-evolução provisionada."
```

### 3A.4 Validação

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "=== Validação pós-recovery ==="
grep -q "^role: adopted" "$REPO/.claude/.onion-version" 2>/dev/null \
  && echo "✅ stamp OK" || echo "❌ stamp inválido"
grep -q "instância adotada\|adopted" "$REPO/CLAUDE.md" 2>/dev/null \
  && echo "✅ CLAUDE.md OK" || echo "⚠️  CLAUDE.onion.md gerado — merge pendente"
[ -d "$REPO/.claude/agents" ] && [ -d "$REPO/.claude/commands" ] \
  && echo "✅ .claude/ core OK" || echo "❌ .claude/ incompleto — solicitar update ao core"
[ -d "$REPO/docs/evolution/inbox" ] \
  && echo "✅ co-evolução OK" || echo "❌ docs/evolution/ ausente"
```

### 3A.5 Commit

```bash
cd "$(git rev-parse --show-toplevel)"
git add .claude/.onion-version CLAUDE.md CLAUDE.onion.md docs/evolution/ 2>/dev/null || true
# --no-verify se worktree sem node_modules (husky/ENOENT — não é violação de lint)
git commit --no-verify -m "chore(onion): recover Onion identity via rescue-prompt

Regenerated .onion-version and CLAUDE.md Onion skeleton after context
loss. Framework files in .claude/ were intact; only identity metadata
was missing.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

Reportar: o que foi recuperado, o que ficou pendente (ex.: CLAUDE.onion.md para merge manual).

---

## ETAPA 3B — ADOPTION REQUEST (repo virgem, sem Onion)

Use este bloco se o modo for ADOPTION REQUEST.

> **Por que não instalar Onion aqui?** A cópia do framework requer acesso à fonte (onion-evolve).
> Este prompt gera um **sinal de pedido** que o maestro leva à sessão do core para processar.

### 3B.1 Gerar arquivo de pedido de adoção

Criar `onion-adoption-request.md` na raiz do repo (substituindo `<...>` com valores coletados):

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PROJ_NAME="<nome_coletado>"
TASK_PROVIDER="<provider_coletado>"
TASK_TRANSPORT="<transport_coletado>"
INT_BRANCH="<branch_coletada>"
STACK="<stack_coletada>"
REMOTE="$(git -C "$REPO" remote get-url origin 2>/dev/null || echo "$REPO")"
TODAY="$(date +%F)"

cat > "$REPO/onion-adoption-request.md" <<EOF
---
title: 'Pedido de adoção Onion — ${PROJ_NAME}'
date: ${TODAY}
from: ${PROJ_NAME} (${REPO})
to: onion-evolve (core)
type: adoption-request
status: pending
task_manager_provider: ${TASK_PROVIDER}
task_manager_transport: ${TASK_TRANSPORT}
integration_branch: ${INT_BRANCH}
stack: ${STACK}
remote: ${REMOTE}
---

# Pedido de adoção — ${PROJ_NAME}

## O que é este arquivo

Este repo não tem o Onion instalado e está solicitando adoção formal.
Gerado pelo processo de resgate autônomo (\`docs/applying/rescue-prompt.md\`).

## Projeto

| Campo | Valor |
|---|---|
| Nome | ${PROJ_NAME} |
| Caminho | ${REPO} |
| Remote | ${REMOTE} |
| Stack | ${STACK} |
| Task Manager | ${TASK_PROVIDER} / ${TASK_TRANSPORT} |
| Integration branch | ${INT_BRANCH} |
| .claude/ existente | $([ -d "$REPO/.claude" ] && echo "sim (estrutura própria)" || echo "não") |

## Próximo passo (para o maestro)

1. Copie este arquivo para \`docs/evolution/inbox/\` do core (\`onion-evolve\`).
2. Na sessão do core, rode \`/meta:co-evolve\` para triagem.
3. Para adotar: \`/meta:adopt ${REPO}\` (ou \`/meta:adopt ${REMOTE}\`).

EOF
echo "Arquivo gerado: $REPO/onion-adoption-request.md"
```

### 3B.2 Instrução final ao usuário

Reporte:

> **Arquivo `onion-adoption-request.md` gerado.** Para completar a adoção:
>
> 1. Abra a sessão do `onion-evolve` (core) no Claude Code.
> 2. Copie `onion-adoption-request.md` para `docs/evolution/inbox/` do core.
> 3. Rode `/meta:co-evolve` na sessão do core para triagem.
> 4. O core processará rodando `/meta:adopt <caminho_deste_repo>`.
>
> Enquanto isso, você já pode trabalhar neste repo — o Claude Code tem o contexto
> coletado nesta sessão mesmo sem o framework completo.

---

## Referências

- Comando formal: `/meta:recover` (disponível se `.claude/commands/` existir)
- Adoção completa: `/meta:adopt <path>` (na sessão do core)
- Update do framework: `/meta:adopt --update <path>` (na sessão do core)
- Protocolo de co-evolução: `docs/evolution/README.md`
```
