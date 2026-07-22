#!/usr/bin/env bash
# =============================================================================
# merge-prettierignore.sh — Provisiona proteção de FORMATADOR no repo adotado
#
# Propósito : Levar ao .prettierignore do alvo os paths de artefatos Onion que
#             NÃO devem ser reformatados pelo formatador do adotante (ex.:
#             prettier + lint-staged). Crítico: docs/onion/inventory.md é SSOT
#             gerado por máquina (inventory.sh) e o lint Onion o compara
#             byte-a-byte (check_inventory_sync) — prettier reformata → violação
#             HARD em laço vicioso. Resolve o backlog #7 / sinal de campo do
#             um adotante multi-linhagem (sinal de vendor-prettier quebrando SSOT, jun/2026).
#
# Mecânica  : Lê a lista curada de paths de prettierignore-onion.tpl (irmão).
#             - Alvo SEM .prettierignore → cria com o template inteiro (paths +
#               comentários + cabeçalho de auto-doc).
#             - Alvo COM .prettierignore → append never-clobber SÓ das linhas de
#               PATH faltantes (grep -qxF whole-line). NÃO emite cabeçalho/coment.
#               no append (o adotante já organiza o arquivo do jeito dele;
#               cabeçalho órfão = poluição). Garante newline final antes do 1º
#               append; normaliza CRLF na comparação.
#             IDEMPOTENTE: rodar 2× = no-op na 2ª (todos os paths já presentes).
#
# Uso       : merge-prettierignore.sh <dest-dir>   (PATH do repo alvo)
#             Escreve in-place em <dest-dir>/.prettierignore — divergência
#             consciente vs merge-onion-hooks.sh (que emite STDOUT): aqui é texto
#             append-only, não JSON quebrável.
#
# Cobertura : prettier e ferramentas que respeitam .prettierignore. dprint
#             (dprint.json) e biome (biome.json) NÃO o leem — se detectados,
#             AVISA em STDERR (cobertura ativa deles = follow-up).
#
# Gracioso  : <dest> inválido / template ausente → exit 2 (erro de uso). Falha de
#             I/O / permissão → aviso STDERR + exit 0 (não aborta a adoção). Sem
#             `set -e` de propósito, p/ controlar o exit gracioso nos pontos de I/O.
#
# Determinístico, sem LLM. Consumido por /meta:adopt (Fase 3 + --update) e
# exercitado pelo lint-selftest.sh (run_prettierignore_selftests).
# =============================================================================
set -uo pipefail

DEST="${1:-}"

if [ -z "${DEST}" ]; then
  echo "uso: merge-prettierignore.sh <dest-dir>" >&2
  exit 2
fi
[ -d "${DEST}" ] || { echo "ERRO: dest não é diretório: ${DEST}" >&2; exit 2; }

TPL="$(dirname "$0")/prettierignore-onion.tpl"
[ -f "${TPL}" ] || { echo "ERRO: template não encontrado: ${TPL}" >&2; exit 2; }

PI="${DEST}/.prettierignore"

# Aviso de cobertura honesta: formatadores que NÃO leem .prettierignore.
for other in dprint.json biome.json; do
  if [ -f "${DEST}/${other}" ]; then
    echo "AVISO: ${DEST}/${other} presente — esse formatador NÃO lê .prettierignore;" \
         "o SSOT docs/onion/inventory.md segue desprotegido (cobertura = follow-up)." >&2
  fi
done

# Caso 1: alvo SEM .prettierignore → cria com o template inteiro (auto-doc incluído).
if [ ! -f "${PI}" ]; then
  if cp "${TPL}" "${PI}" 2>/dev/null; then
    echo "Onion: .prettierignore criado em ${DEST} (proteção de vendor + SSOT)." >&2
  else
    echo "AVISO: não foi possível criar ${PI} (permissão?) — proteção NÃO provisionada." >&2
  fi
  exit 0
fi

# Caso 2: alvo COM .prettierignore → append never-clobber dos PATHS faltantes.
# Linhas de PATH do template = não-comentário (#) e não-vazias.
paths="$(grep -vE '^[[:space:]]*(#|$)' "${TPL}" || true)"

# Conteúdo do alvo normalizado (strip CRLF) p/ comparação whole-line CRLF-safe.
existing_norm="$(tr -d '\r' < "${PI}" 2>/dev/null || true)"

missing=()
while IFS= read -r p; do
  [ -n "${p}" ] || continue
  if ! printf '%s\n' "${existing_norm}" | grep -qxF "${p}"; then
    missing+=("${p}")
  fi
done <<< "${paths}"

if [ "${#missing[@]}" -eq 0 ]; then
  echo "Onion: .prettierignore já protegido em ${DEST} (no-op)." >&2
  exit 0
fi

# Garante newline final antes do 1º append (senão a 1ª linha gruda na última).
# tail -c1 numa linha terminada em \n → command-subst strip → vazio → não age.
if [ -s "${PI}" ] && [ -n "$(tail -c1 "${PI}" 2>/dev/null)" ]; then
  printf '\n' >> "${PI}" 2>/dev/null \
    || { echo "AVISO: sem permissão de escrita em ${PI} — proteção parcial." >&2; exit 0; }
fi

added=0
for p in "${missing[@]}"; do
  printf '%s\n' "${p}" >> "${PI}" 2>/dev/null \
    || { echo "AVISO: falha ao escrever em ${PI} — proteção parcial." >&2; exit 0; }
  added=$((added + 1))
done

echo "Onion: .prettierignore — ${added} path(s) adicionado(s) em ${DEST}." >&2
exit 0
