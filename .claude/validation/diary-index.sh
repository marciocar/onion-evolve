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
INVALID=0

# Gerar linhas da tabela
TABLE_ROWS=""
while IFS= read -r f; do
  [ -f "$f" ] || continue

  DATE=$(awk '/^date:/{print $2; exit}' "$f" 2>/dev/null || echo "?")
  TYPE=$(awk '/^type:/{print $2; exit}' "$f" 2>/dev/null || echo "?")
  CLASS=$(awk '/^classification:/{print $2; exit}' "$f" 2>/dev/null || echo "?")
  # `|| true` no grep: sob pipefail, entrada sem share_with (ou com []) fazia o pipeline sair 1
  # e o set -e matava o script silenciosamente — bug latente exposto pelo selftest diary-crumbs.
  SHARE=$(awk '/^share_with:/{print; exit}' "$f" 2>/dev/null | { grep -v '\[\]' || true; } | wc -l | tr -d ' ')
  REVIEW=$(awk '/^review_after:/{print $2; exit}' "$f" 2>/dev/null || echo "")
  SLUG=$(basename "$f" .md | cut -d- -f4-)

  # Estrutura de decisão da migalha (pesquisa breadcrumbs 2026-07; vocabulário MemConflict).
  # Campos OPCIONAIS (retrocompat: entrada sem eles cai no protocolo genérico do review), mas
  # quando presentes são validados — classe fora do vocabulário ou `conditional` sem `valid_when`
  # é migalha DESONESTA (promete um re-teste dirigido que não pode cumprir) → erro, exit 1.
  # `type` fora do vocabulário é desonesto pelo mesmo critério: o índice promete ao Transformer um
  # tipo que o /meta:diary não sabe processar. Enum: RFC-0003 §2.3 + /meta:diary (`reflection`
  # promovido em 2026-07-17 — o campo o inventou antes do vocabulário ter casa p/ síntese
  # retrospectiva). Diferente de conflict_class, `type` NÃO é opcional (sempre existiu no schema).
  case "$TYPE" in
    learning|decision|error|innovation|observation|reflection) : ;;
    *)
      echo "ERRO: $(basename "$f"): type '$TYPE' inválido (learning|decision|error|innovation|observation|reflection)" >&2
      INVALID=$((INVALID + 1))
      ;;
  esac

  CCLASS=$(awk '/^conflict_class:/{print $2; exit}' "$f" 2>/dev/null || echo "")
  VWHEN=$(awk '/^valid_when:/{sub(/^valid_when:[ ]*/, ""); print; exit}' "$f" 2>/dev/null || echo "")
  if [ -n "$CCLASS" ]; then
    case "$CCLASS" in
      dynamic|static|conditional) : ;;
      *)
        echo "ERRO: $(basename "$f"): conflict_class '$CCLASS' inválida (dynamic|static|conditional)" >&2
        INVALID=$((INVALID + 1))
        ;;
    esac
    if [ "$CCLASS" = "conditional" ] && { [ -z "$VWHEN" ] || [ "$VWHEN" = '""' ]; }; then
      echo "ERRO: $(basename "$f"): conflict_class 'conditional' exige valid_when (condição testável)" >&2
      INVALID=$((INVALID + 1))
    fi
  fi

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
  CCLASS_DISPLAY="${CCLASS:-—}"
  TABLE_ROWS="${TABLE_ROWS}| ${DATE} | ${TYPE} | ${CLASS}${STALE_MARKER}${SHARE_MARKER} | ${SLUG} | ${REVIEW_DISPLAY} | ${CCLASS_DISPLAY} |
"
done <<< "$ENTRIES"

# Migalha estruturalmente inválida não pode virar índice são — falha alto (consumido pelo selftest).
if [ "$INVALID" -gt 0 ]; then
  echo "FALHOU: ${INVALID} violação(ões) de estrutura de migalha — corrigir antes de regenerar." >&2
  exit 1
fi

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

| Data | Tipo | Classificação | Slug | Revisar em | Classe |
|---|---|---|---|---|---|
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
