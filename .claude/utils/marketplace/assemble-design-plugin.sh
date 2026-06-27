#!/usr/bin/env bash
# =============================================================================
# assemble-design-plugin.sh — Monta a vertical Design como PLUGIN Claude Code
#
# Propósito : Materializar a "vertical-skill" Design (ADR onion-adr-exchange-unit-2026-06)
#             no layout de plugin Claude Code, a partir das fontes CANÔNICAS em
#             .claude/. A SSOT continua sendo .claude/ — o dir do plugin é
#             ARTEFATO GERADO (mesma doutrina de docs/onion/inventory.md): commitado,
#             regenerável, drift-guard estilo check_inventory_sync = follow-up.
#             Distribui SÓ a camada 1 (capacidade); a camada 2 (docs/design-context/)
#             fica do consumidor e o SDAAL+transformer adapta (separação de camadas).
#
# Componentes (camada 1 da vertical Design):
#   commands/ ← .claude/commands/design/*.md
#   agents/   ← design-system-specialist, brand-generator, branding-positioning-specialist
#   utils/    ← .claude/utils/design-source/ + design-sink/ (SDAAL — a adaptação)
#   .claude-plugin/plugin.json     (manifest, 8 campos; additionalProperties REJEITADO)
#   .claude-plugin/provenance.json (repository + ref + tree_sha content-addressed, à la gh skill)
#
# Uso       : assemble-design-plugin.sh [source-root] [dest-dir]
#             source-root default = git toplevel; dest default = <root>/plugins/onion-design
#             Determinístico + idempotente: mesmo HEAD → mesmo output (regenera = no-op de conteúdo).
#
# Gracioso  : source não-repo / componente-fonte ausente → exit 2 (erro de uso).
#             Falha de I/O → aviso STDERR + exit 0 (não aborta pipeline). Sem set -e p/
#             controlar o exit nos pontos de I/O.
#
# Determinístico, sem LLM. Exercitado pelo lint-selftest.sh (run_assemble_plugin_selftests).
# =============================================================================
set -uo pipefail

PLUGIN_NAME="onion-design"
PLUGIN_VERSION="0.1.0"

SRC="${1:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
[ -n "${SRC}" ] && [ -d "${SRC}" ] || { echo "ERRO: source-root inválido: '${SRC}'" >&2; exit 2; }
git -C "${SRC}" rev-parse --git-dir >/dev/null 2>&1 || { echo "ERRO: source não é repo git: ${SRC}" >&2; exit 2; }

DEST="${2:-${SRC}/plugins/${PLUGIN_NAME}}"

# Fontes canônicas (camada 1).
CMD_DIR="${SRC}/.claude/commands/design"
AGENTS=(
  ".claude/agents/development/design-system-specialist.md"
  ".claude/agents/development/brand-generator.md"
  ".claude/agents/product/branding-positioning-specialist.md"
)
UTILS=(".claude/utils/design-source" ".claude/utils/design-sink")
GATE=".claude/validation/lint-design-tokens.sh"   # gate WCAG da vertical (opera na camada 2 do consumidor)

[ -d "${CMD_DIR}" ] || { echo "ERRO: fonte ausente: ${CMD_DIR}" >&2; exit 2; }
for a in "${AGENTS[@]}"; do [ -f "${SRC}/${a}" ] || { echo "ERRO: agente fonte ausente: ${a}" >&2; exit 2; }; done
for u in "${UTILS[@]}"; do [ -d "${SRC}/${u}" ] || { echo "ERRO: util fonte ausente: ${u}" >&2; exit 2; }; done
[ -f "${SRC}/${GATE}" ] || { echo "ERRO: gate fonte ausente: ${GATE}" >&2; exit 2; }

# Montagem limpa (idempotente): zera o dir gerado e recompõe.
rm -rf "${DEST}" 2>/dev/null
mkdir -p "${DEST}/.claude-plugin" "${DEST}/commands" "${DEST}/agents" "${DEST}/utils" "${DEST}/validation" 2>/dev/null \
  || { echo "AVISO: não criou ${DEST} (permissão?) — plugin não montado." >&2; exit 0; }

# commands/ + agents/ + utils/ + validation/ (camada 1).
cp "${CMD_DIR}"/*.md "${DEST}/commands/" 2>/dev/null
for a in "${AGENTS[@]}"; do cp "${SRC}/${a}" "${DEST}/agents/" 2>/dev/null; done
for u in "${UTILS[@]}"; do cp -R "${SRC}/${u}" "${DEST}/utils/" 2>/dev/null; done
cp "${SRC}/${GATE}" "${DEST}/validation/" 2>/dev/null && chmod +x "${DEST}/validation/$(basename "${GATE}")" 2>/dev/null

# Proveniência content-addressed (padrão gh skill: repository + ref + tree_sha).
# repository em OWNER/REPO; ref = commit HEAD; tree_sha = hash do ls-tree de TODAS as fontes
# (determinístico — inclui o blob-sha de cada componente; muda só quando o conteúdo muda).
url="$(git -C "${SRC}" remote get-url origin 2>/dev/null || true)"
repository="$(printf '%s' "${url}" | sed -E 's#(git@|https://)([^/:]+)[/:]##; s#\.git$##')"
[ -n "${repository}" ] || repository="local/${PLUGIN_NAME}"
ref="$(git -C "${SRC}" rev-parse HEAD 2>/dev/null || echo unknown)"
commit_date="$(git -C "${SRC}" show -s --format=%cI HEAD 2>/dev/null || echo unknown)"
tree_sha="$(git -C "${SRC}" ls-tree -r HEAD -- \
  .claude/commands/design "${AGENTS[@]}" "${UTILS[@]}" "${GATE}" 2>/dev/null \
  | git hash-object --stdin 2>/dev/null || echo unknown)"

cat > "${DEST}/.claude-plugin/provenance.json" <<EOF
{
  "repository": "${repository}",
  "ref": "${ref}",
  "tree_sha": "${tree_sha}",
  "commit_date": "${commit_date}",
  "note": "Proveniência content-addressed (padrão gh skill). tree_sha = hash do ls-tree das fontes canônicas em .claude/. SSOT = .claude/; este plugin é artefato gerado por assemble-design-plugin.sh."
}
EOF

# plugin.json — EXATAMENTE os 8 campos permitidos (additionalProperties é rejeitado no validador).
cat > "${DEST}/.claude-plugin/plugin.json" <<EOF
{
  "name": "${PLUGIN_NAME}",
  "version": "${PLUGIN_VERSION}",
  "description": "Vertical de design do Onion: identidade visual como spec-as-code (tokens W3C/DTCG), gate WCAG e materializacao via design-sink. Auto-adapta ao design-context do consumidor (SDAAL).",
  "author": { "name": "Onion - Marcio Carvalho" },
  "homepage": "https://github.com/${repository}",
  "repository": "https://github.com/${repository}",
  "license": "MIT",
  "keywords": ["design", "design-tokens", "wcag", "dtcg", "onion", "sdaal"]
}
EOF

echo "Onion: plugin '${PLUGIN_NAME}' montado em ${DEST} (commands+agents+utils; tree_sha=${tree_sha:0:12})." >&2
exit 0
