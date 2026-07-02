---
name: diary
description: |
  Gerencia o diário de aprendizado da instância Onion — sistema de breadcrumbs para o Transformer.
  Cria, lista e exporta entradas estruturadas (learning/decision/error/innovation/observation) que
  orientam a absorção correta do contexto em sessões futuras e entre instâncias federadas.
  O diário é autobiografia viva: não registra o passado, orienta o futuro. Relacionado: /meta:co-relay,
  /meta:personality-sync (Fase 2, gated), RFC-0003.
model: sonnet
allowed-tools: Read Write Edit Glob Grep Bash(git *) Bash(bash *) Bash(ls *) Bash(cat *) Bash(mkdir *) Bash(touch *) Bash(date *) Bash(find *) Bash(awk *) Bash(grep *) Bash(sort *)
argument-hint: "create | list [--classification <c>] [--type <t>] [--sharable] | export-sharable [--dry-run] | index"
category: meta
version: "1.0.0"
updated: "2026-07-01"
---

# 🧅 /meta:diary — Diário de Aprendizado Onion

## Propósito

O diário é o **sistema de breadcrumbs da instância** — cada entrada é um sinal explícito que força
o Transformer a **absorver** a intenção correta, não *acomodar* o mais provável.

Distinção crítica (`breadcrumb-patterns.md`):
- **Acomodação**: modelo infere contexto do corpus (default perigoso)
- **Absorção**: modelo lê frontmatter YAML estruturado e o segue — mesmo contra o padrão esperado

Canal de maior absorção: **Frontmatter YAML** (chega proeminente antes de qualquer prosa).

---

## Sub-comandos

### `create` — Criar nova entrada

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIARY_DIR="$REPO/.claude/diary"
mkdir -p "$DIARY_DIR"
TODAY="$(date +%F)"
INSTANCE_ID="$(awk '/^instance:/{print $2}' "$REPO/.claude/.onion-version" 2>/dev/null || basename "$REPO")"
```

**Coleta guiada** (perguntar ao maestro o que não pode ser auto-detectado):

1. **Tipo** — qual categoria melhor descreve este aprendizado?
   - `learning` — algo novo aprendido do uso
   - `decision` — decisão arquitetural ou de processo tomada
   - `error` — erro cometido e como foi resolvido (+ como evitar)
   - `innovation` — algo novo criado aqui que pode beneficiar a rede
   - `observation` — observação de mercado, comunidade ou padrão externo

2. **Classification** — quem deve poder ler isto?
   - `private` — só esta instância (default para `error` com contexto de negócio)
   - `protected` — instância + core
   - `peer` — instância + peers autorizados em `trust.diary_readable_by`
   - `downstream` — instância + seus adotados (T2)
   - `public` — qualquer instância federada (default para `innovation` e `observation`)
   - `collective` — candidato à síntese coletiva co-autorada pelo core

3. **Tags** — 1-5 tags descritivas (ex: `[oauth, session, co-evolution]`)
4. **Affects** — quais dimensões esta entrada afeta: `engineering`, `product`, `compliance`, `design`, `meta`
5. **Slug** — nome curto para o arquivo (ex: `oauth-session-learning`)

**Gerar arquivo:**

```bash
SLUG="<slug-coletado>"
FILENAME="${TODAY}-${SLUG}.md"
FILEPATH="$DIARY_DIR/$FILENAME"

# Calcular review_after (90 dias por padrão)
REVIEW_DATE="$(date -d "$TODAY + 90 days" +%F 2>/dev/null || date -v +90d +%F 2>/dev/null || echo "$(echo $TODAY | awk -F- '{printf "%s-%02d-%s", $1, ($2%12)+1, $3}')")"

cat > "$FILEPATH" <<EOF
---
date: ${TODAY}
instance: ${INSTANCE_ID}
type: <tipo>
classification: <classification>
tags: [<tags>]
affects: [<affects>]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: ${REVIEW_DATE}
---

## Signal
[≤3 linhas — o que o Transformer DEVE absorver desta entrada]

## Evidence
[bullets — o que aconteceu de concreto]
-

## Next crumb
[o que deve ser feito ou investigado depois de absorver esta entrada]
EOF
echo "Criado: $FILEPATH"
```

Abrir o arquivo para o maestro completar Signal, Evidence e Next crumb.

**Após preenchimento:** rodar `diary index` para atualizar o index.md.

---

### `list` — Listar entradas

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIARY_DIR="$REPO/.claude/diary"

# Filtros opcionais via argumento:
# --classification private|protected|peer|downstream|public|collective
# --type learning|decision|error|innovation|observation
# --sharable (só entradas com share_with != [] ou classification em [peer,public,collective])

find "$DIARY_DIR" -name "*.md" ! -name "index.md" | sort -r | while read f; do
  DATE=$(awk '/^date:/{print $2}' "$f")
  TYPE=$(awk '/^type:/{print $2}' "$f")
  CLASS=$(awk '/^classification:/{print $2}' "$f")
  SLUG=$(basename "$f" .md | cut -d- -f4-)
  REVIEW=$(awk '/^review_after:/{print $2}' "$f")
  printf "%-12s  %-12s  %-12s  %-30s  review: %s\n" "$DATE" "$TYPE" "$CLASS" "$SLUG" "$REVIEW"
done
```

Sinalizar entradas com `review_after` < hoje: `⏰ VENCIDO` ao lado.

---

### `export-sharable` — Empacotar entradas compartilháveis para co-relay

Identifica entradas com `share_with != []` OU `classification` em `[peer, downstream, public, collective]`
e as empacota para transporte via `/meta:co-relay`.

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIARY_DIR="$REPO/.claude/diary"
OUTBOX="$REPO/docs/evolution/outbox/diary"
mkdir -p "$OUTBOX"

find "$DIARY_DIR" -name "*.md" ! -name "index.md" | while read f; do
  SHARE=$(awk '/^share_with:/{print}' "$f" | grep -v '\[\]')
  CLASS=$(awk '/^classification:/{print $2}' "$f")
  
  if [ -n "$SHARE" ] || echo "$CLASS" | grep -qE "^(peer|downstream|public|collective)$"; then
    DEST="$OUTBOX/$(basename "$f")"
    if [ ! -f "$DEST" ]; then
      cp "$f" "$DEST"
      echo "📤 Empacotado: $(basename "$f") (class: $CLASS)"
    else
      echo "↩  Já empacotado: $(basename "$f") (sem mudança)"
    fi
  fi
done

echo ""
echo "Outbox: $OUTBOX"
echo "Próximo passo: /meta:co-relay --to core (ou --to peer:<peer-id>) para transportar"
```

Se `--dry-run`: listar sem copiar.

---

### `index` — Regenerar index.md

```bash
bash "$(git rev-parse --show-toplevel)/.claude/validation/diary-index.sh"
```

O index.md é o Tier-0 pointer do diário (~1KB). O Transformer lê o índice, não o diário inteiro.
Formato do índice: tabela com date, type, classification, slug, review_after — ordenada por data desc.

---

## Regras do diário

1. **Signal é o que o Transformer absorve** — não é título, não é prosa. É a instrução explícita.
2. **Evidence é bullet, não prosa** — o Transformer precisa de fatos, não narrativa.
3. **Next crumb é obrigatório** — o diário não termina numa entrada; termina numa ação.
4. **review_after sempre preenchido** — nada no diário é eterno. Padrão: 90 dias após `date`.
5. **Classification antes de share_with** — a classificação é a política; share_with é exceção explícita.
6. **Private é o default para erros com contexto de negócio** — não expor dados do adotante.
7. **Innovations são public por padrão** — se descobrimos algo útil, a rede deve poder absorver.

---

## Quando usar o diário

| Situação | Tipo recomendado | Classification padrão |
|---|---|---|
| Aprendi algo novo de um erro | `error` | `protected` |
| Tomei uma decisão arquitetural | `decision` | `protected` |
| Descobri uma pattern nova | `innovation` | `public` |
| Observei algo no mercado | `observation` | `public` |
| Entendi como algo funciona | `learning` | depende do conteúdo |
| Quero contribuir para KB coletiva | qualquer | `collective` |

---

## Estrutura de arquivos

```
.claude/diary/
├── index.md                      # Tier-0 pointer (~1KB) — gerado por diary-index.sh
├── 2026-07-01-oauth-learning.md
├── 2026-07-02-sdaal-decision.md
└── ...
```

---

## Relação com co-evolução

O diário é o **conteúdo** que o protocolo co-evolução **transporta**. A sequência canônica:

```
1. /meta:diary create            # cria a migalha localmente
2. /meta:diary export-sharable   # empacota para transporte
3. /meta:co-relay --to core      # (ou --to peer:<id> — Fase 3, gated)
4. Core: /meta:co-evolve         # tria o sinal recebido
5. Loop fecha: learning adotado, ajuste enviado de volta, ou knowledge base atualizada
```
