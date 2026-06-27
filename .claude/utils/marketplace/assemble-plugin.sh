#!/usr/bin/env bash
# =============================================================================
# assemble-plugin.sh — Monta UMA vertical Onion como plugin Claude Code (genérico)
#
# Propósito : Materializar qualquer "vertical-skill" (ADR onion-adr-exchange-unit-2026-06)
#             no layout de plugin Claude Code, a partir de um MANIFESTO que lista as
#             fontes canônicas em .claude/. SSOT continua .claude/; o dir do plugin é
#             ARTEFATO GERADO (à la docs/onion/inventory.md). Distribui SÓ a camada 1
#             (capacidade); a camada 2 (docs/*-context/) fica do consumidor e o
#             SDAAL+transformer adapta (separação de camadas).
#
# Generaliza o antigo assemble-design-plugin.sh: dirigido por manifesto (shell),
# dependency-free (sem jq). Prova de que o padrão vale p/ N verticais (design,
# compliance, …) sem duplicar o assembler.
#
# Manifesto (shell, em verticals/<plugin>.manifest.sh) define:
#   PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_DESC, KEYWORDS=()
#   COMMANDS=()   # dirs (copia *.md de dentro) ou arquivos → commands/
#   AGENTS=()     # arquivos → agents/
#   UTILS=()      # dirs → utils/        (vazio = sem SDAAL utils, ok)
#   VALIDATION=() # arquivos → validation/ (vazio = sem gate, ok)
#
# Uso       : assemble-plugin.sh <manifest> [source-root] [dest-dir]
#             source-root default = git toplevel; dest default = <root>/plugins/<PLUGIN_NAME>
#             Determinístico + idempotente: mesmo HEAD → mesmo output.
#
# Gracioso  : manifesto/source inválido ou componente-fonte ausente → exit 2.
#             Falha de I/O → aviso STDERR + exit 0. Sem set -e p/ controlar o exit.
#
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_assemble_plugin_selftests).
# =============================================================================
set -uo pipefail

MANIFEST="${1:-}"
[ -n "${MANIFEST}" ] && [ -f "${MANIFEST}" ] || { echo "ERRO: manifesto inválido: '${MANIFEST}'" >&2; exit 2; }

SRC="${2:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
[ -n "${SRC}" ] && [ -d "${SRC}" ] || { echo "ERRO: source-root inválido: '${SRC}'" >&2; exit 2; }
git -C "${SRC}" rev-parse --git-dir >/dev/null 2>&1 || { echo "ERRO: source não é repo git: ${SRC}" >&2; exit 2; }

# Defaults antes do source (manifesto pode sobrescrever).
PLUGIN_NAME=""; PLUGIN_VERSION="0.1.0"; PLUGIN_DESC=""; KEYWORDS=()
COMMANDS=(); AGENTS=(); UTILS=(); VALIDATION=()
# shellcheck disable=SC1090
. "${MANIFEST}"
[ -n "${PLUGIN_NAME}" ] || { echo "ERRO: manifesto sem PLUGIN_NAME: ${MANIFEST}" >&2; exit 2; }

DEST="${3:-${SRC}/plugins/${PLUGIN_NAME}}"

# Valida fontes (todas as listadas devem existir).
for c in "${COMMANDS[@]}"; do [ -e "${SRC}/${c}" ] || { echo "ERRO: command fonte ausente: ${c}" >&2; exit 2; }; done
for a in "${AGENTS[@]}"; do [ -f "${SRC}/${a}" ] || { echo "ERRO: agente fonte ausente: ${a}" >&2; exit 2; }; done
for u in "${UTILS[@]}"; do [ -d "${SRC}/${u}" ] || { echo "ERRO: util fonte ausente: ${u}" >&2; exit 2; }; done
for v in "${VALIDATION[@]}"; do [ -f "${SRC}/${v}" ] || { echo "ERRO: validation fonte ausente: ${v}" >&2; exit 2; }; done

# Montagem limpa (idempotente).
rm -rf "${DEST}" 2>/dev/null
mkdir -p "${DEST}/.claude-plugin" "${DEST}/commands" "${DEST}/agents" 2>/dev/null \
  || { echo "AVISO: não criou ${DEST} (permissão?) — plugin não montado." >&2; exit 0; }

# commands/ — dir → *.md de dentro; arquivo → o arquivo.
for c in "${COMMANDS[@]}"; do
  if [ -d "${SRC}/${c}" ]; then cp "${SRC}/${c}"/*.md "${DEST}/commands/" 2>/dev/null
  else cp "${SRC}/${c}" "${DEST}/commands/" 2>/dev/null; fi
done
# agents/ — arquivos.
for a in "${AGENTS[@]}"; do cp "${SRC}/${a}" "${DEST}/agents/" 2>/dev/null; done
# utils/ — dirs (só cria a pasta se houver).
if [ "${#UTILS[@]}" -gt 0 ]; then
  mkdir -p "${DEST}/utils" 2>/dev/null
  for u in "${UTILS[@]}"; do cp -R "${SRC}/${u}" "${DEST}/utils/" 2>/dev/null; done
fi
# validation/ — arquivos (só cria a pasta se houver).
if [ "${#VALIDATION[@]}" -gt 0 ]; then
  mkdir -p "${DEST}/validation" 2>/dev/null
  for v in "${VALIDATION[@]}"; do
    cp "${SRC}/${v}" "${DEST}/validation/" 2>/dev/null && chmod +x "${DEST}/validation/$(basename "${v}")" 2>/dev/null
  done
fi

# Proveniência content-addressed (padrão gh skill): repository + ref + tree_sha.
# tree_sha = hash do ls-tree de TODAS as fontes listadas (determinístico; muda só com conteúdo).
url="$(git -C "${SRC}" remote get-url origin 2>/dev/null || true)"
repository="$(printf '%s' "${url}" | sed -E 's#(git@|https://)([^/:]+)[/:]##; s#\.git$##')"
[ -n "${repository}" ] || repository="local/${PLUGIN_NAME}"
ref="$(git -C "${SRC}" rev-parse HEAD 2>/dev/null || echo unknown)"
commit_date="$(git -C "${SRC}" show -s --format=%cI HEAD 2>/dev/null || echo unknown)"
tree_sha="$(git -C "${SRC}" ls-tree -r HEAD -- \
  "${COMMANDS[@]}" "${AGENTS[@]}" "${UTILS[@]}" "${VALIDATION[@]}" 2>/dev/null \
  | git hash-object --stdin 2>/dev/null || echo unknown)"

cat > "${DEST}/.claude-plugin/provenance.json" <<EOF
{
  "repository": "${repository}",
  "ref": "${ref}",
  "tree_sha": "${tree_sha}",
  "commit_date": "${commit_date}",
  "note": "Proveniência content-addressed (padrão gh skill). tree_sha = hash do ls-tree das fontes canônicas em .claude/. SSOT = .claude/; este plugin é artefato gerado por assemble-plugin.sh + verticals/${PLUGIN_NAME}.manifest.sh."
}
EOF

# KEYWORDS bash array → JSON array (sem jq).
kw_json=""; for k in "${KEYWORDS[@]}"; do kw_json="${kw_json}\"${k}\","; done; kw_json="[${kw_json%,}]"

# plugin.json — EXATAMENTE os 8 campos permitidos (additionalProperties REJEITADO).
cat > "${DEST}/.claude-plugin/plugin.json" <<EOF
{
  "name": "${PLUGIN_NAME}",
  "version": "${PLUGIN_VERSION}",
  "description": "${PLUGIN_DESC}",
  "author": { "name": "Onion - Marcio Carvalho" },
  "homepage": "https://github.com/${repository}",
  "repository": "https://github.com/${repository}",
  "license": "MIT",
  "keywords": ${kw_json}
}
EOF

echo "Onion: plugin '${PLUGIN_NAME}' montado em ${DEST} (tree_sha=${tree_sha:0:12})." >&2
exit 0
