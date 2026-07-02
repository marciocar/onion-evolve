#!/usr/bin/env bash
# diary-index.sh — Regenera .claude/diary/index.md a partir dos arquivos de entrada
# Parte do gate mecânico do Onion (Economy of Motors: Shell = determinístico)
# Uso: bash .claude/validation/diary-index.sh [<repo-root>]
set -euo pipefail

REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DIARY_DIR="$REPO/.claude/diary"
INDEX="$DIARY_DIR/index.md"
TODAY="$(date +%F)"

# Criar diretório se não existir
mkdir -p "$DIARY_DIR"

# Verificar se há entradas
ENTRIES=$(find "$DIARY_DIR" -maxdepth 1 -name "*.md" ! -name "index.md" 2>/dev/null | sort -r)

if [ -z "$ENTRIES" ]; then
  cat > "$INDEX" <<EOF
# Diário — $(basename "$REPO")

> Nenhuma entrada ainda. Use \`/meta:diary create\` para criar a primeira migalha.

Gerado em: ${TODAY}
EOF
  echo "index.md criado (vazio)."
  exit 0
fi

# Contar entradas
TOTAL=$(echo "$ENTRIES" | wc -l | tr -d ' ')
STALE=0
SHARABLE=0

# Gerar linhas da tabela
TABLE_ROWS=""
while IFS= read -r f; do
  [ -f "$f" ] || continue

  DATE=$(awk '/^date:/{print $2; exit}' "$f" 2>/dev/null || echo "?")
  TYPE=$(awk '/^type:/{print $2; exit}' "$f" 2>/dev/null || echo "?")
  CLASS=$(awk '/^classification:/{print $2; exit}' "$f" 2>/dev/null || echo "?")
  SHARE=$(awk '/^share_with:/{print; exit}' "$f" 2>/dev/null | grep -v '\[\]' | wc -l | tr -d ' ')
  REVIEW=$(awk '/^review_after:/{print $2; exit}' "$f" 2>/dev/null || echo "")
  SLUG=$(basename "$f" .md | cut -d- -f4-)

  # Marcar stale
  STALE_MARKER=""
  if [ -n "$REVIEW" ] && [ "$REVIEW" != '""' ] && [ "$REVIEW" \< "$TODAY" ] 2>/dev/null; then
    STALE_MARKER=" ⏰"
    STALE=$((STALE + 1))
  fi

  # Marcar compartilhável
  SHARE_MARKER=""
  if [ "$SHARE" -gt 0 ] || echo "$CLASS" | grep -qE "^(peer|downstream|public|collective)$" 2>/dev/null; then
    SHARE_MARKER=" 📤"
    SHARABLE=$((SHARABLE + 1))
  fi

  REVIEW_DISPLAY="${REVIEW:-—}"
  TABLE_ROWS="${TABLE_ROWS}| ${DATE} | ${TYPE} | ${CLASS}${STALE_MARKER}${SHARE_MARKER} | ${SLUG} | ${REVIEW_DISPLAY} |
"
done <<< "$ENTRIES"

# Instância
INSTANCE_ID=$(awk '/^instance:/{print $2; exit}' "$REPO/.claude/.onion-version" 2>/dev/null || basename "$REPO")

# Escrever index.md
cat > "$INDEX" <<EOF
# Diário — ${INSTANCE_ID}

> Tier-0 pointer do diário de aprendizado desta instância Onion.
> Leia este índice para se orientar — não releia o diário inteiro.
> Entradas ⏰ têm \`review_after\` vencido. Entradas 📤 são compartilháveis via co-relay.

**Total:** ${TOTAL} entradas · **Stale:** ${STALE} · **Compartilháveis:** ${SHARABLE}

Gerado em: ${TODAY}

---

| Data | Tipo | Classificação | Slug | Revisar em |
|---|---|---|---|---|
${TABLE_ROWS}
---

*Gerenciado por \`/meta:diary\`. Para criar uma entrada: \`/meta:diary create\`.*
*Para exportar compartilháveis: \`/meta:diary export-sharable\`.*
*Para regenerar este índice: \`bash .claude/validation/diary-index.sh\`.*
EOF

echo "index.md regenerado: ${TOTAL} entradas (${STALE} stale, ${SHARABLE} compartilháveis)."
if [ "$STALE" -gt 0 ]; then
  echo "⏰ ${STALE} entrada(s) com review_after vencido — revisar e atualizar ou marcar como obsoleto."
fi
