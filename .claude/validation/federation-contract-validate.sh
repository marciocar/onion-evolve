#!/usr/bin/env bash
# =============================================================================
# federation-contract-validate.sh — valida um contrato de federação (spec-as-code)
#
# Propósito : O "teste que falha se o contrato quebrar". Verifica que um arquivo
#             contracts/<id>.md tem TODAS as seções obrigatórias do formato
#             (ver docs/knowledge-base/concepts/multi-repo-federation.md §2),
#             com ênfase em `tests:` (≥1 path) e `fixtures` (≥1 payload) — os
#             campos que tornam o gate comportamental, não só sintático.
#
# Uso       : bash .claude/validation/federation-contract-validate.sh <path-do-contrato> [--json]
#               <path-do-contrato> : caminho (relativo ou absoluto) PASSADO COMO ARGUMENTO
#                                    — o script NÃO embute nenhum caminho (ajuste 2a).
#               --json             : saída JSON {valid, contract, errors[]} para o comando consumir
#
# Saída     : exit 0 = válido · exit 1 = inválido (erros listados) · exit 2 = uso incorreto
#
# Determinístico, sem LLM. É a peça de validação do par
# /meta:federation-register (orquestra) ↔ este script (valida) — ajuste 6a:
# a validação vive aqui, NUNCA num agente.
# =============================================================================

set -euo pipefail

JSON=0
CONTRACT=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON=1 ;;
    -*) echo "uso: $0 <path-do-contrato> [--json]" >&2; exit 2 ;;
    *) CONTRACT="$arg" ;;
  esac
done

if [[ -z "$CONTRACT" ]]; then
  echo "uso: $0 <path-do-contrato> [--json]" >&2
  exit 2
fi
if [[ ! -f "$CONTRACT" ]]; then
  echo "erro: contrato não encontrado: $CONTRACT" >&2
  exit 2
fi

errors=()

# --- campos obrigatórios (linhas "- **campo:**") ------------------------------
for field in id version producer consumers; do
  if ! grep -qiE "^\s*-\s*\*\*${field}:\*\*" "$CONTRACT"; then
    errors+=("campo obrigatório ausente: **${field}:**")
  fi
done

# --- version deve ser semver --------------------------------------------------
version_val="$(grep -iE "^\s*-\s*\*\*version:\*\*" "$CONTRACT" | head -1 | sed -E 's/.*\*\*version:\*\*\s*//; s/\s.*$//' || true)"
if [[ -n "$version_val" ]] && ! [[ "$version_val" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  errors+=("version não é semver válido (MAJOR.MINOR.PATCH): '${version_val}'")
fi

# --- seções obrigatórias (headers "## secao") --------------------------------
for section in interface types tests fixtures; do
  if ! grep -qiE "^##\s+${section}\b" "$CONTRACT"; then
    errors+=("seção obrigatória ausente: ## ${section}")
  fi
done

# --- helper: extrai o bloco de uma seção (até o próximo "## " ou EOF) ---------
section_block() {
  awk -v sec="$1" '
    BEGIN { inblk=0 }   # POSIX awk: casamento case-insensitive via tolower() abaixo (sem gawk IGNORECASE)
    /^##[ \t]+/ {
      if (inblk) exit
      if (tolower($0) ~ "^##[ \t]+" sec "([ \t]|$)") { inblk=1; next }
    }
    inblk { print }
  ' "$CONTRACT"
}

# --- tests: ≥1 item de lista (path) ------------------------------------------
if grep -qiE "^##\s+tests\b" "$CONTRACT"; then
  tests_count="$(section_block tests | grep -cE '^\s*-\s+\S' || true)"
  if [[ "${tests_count:-0}" -lt 1 ]]; then
    errors+=("## tests não lista nenhum path (≥1 obrigatório — sem teste = blocker)")
  fi
fi

# --- fixtures: ≥1 payload (bloco de código cercado) --------------------------
if grep -qiE "^##\s+fixtures\b" "$CONTRACT"; then
  fences="$(section_block fixtures | grep -cE '^\s*```' || true)"
  if [[ "${fences:-0}" -lt 2 ]]; then
    errors+=("## fixtures não tem nenhum payload em bloco de código (≥1 obrigatório — contrato comportamental)")
  fi
fi

# --- relatório ----------------------------------------------------------------
if [[ "$JSON" -eq 1 ]]; then
  printf '{"valid":%s,"contract":"%s","errors":[' \
    "$([[ ${#errors[@]} -eq 0 ]] && echo true || echo false)" "$CONTRACT"
  for i in "${!errors[@]}"; do
    [[ "$i" -gt 0 ]] && printf ','
    printf '"%s"' "${errors[$i]//\"/\\\"}"
  done
  printf ']}\n'
else
  if [[ ${#errors[@]} -eq 0 ]]; then
    echo "✅ contrato válido: $CONTRACT"
  else
    echo "❌ contrato inválido: $CONTRACT"
    for e in "${errors[@]}"; do echo "   ∟ $e"; done
  fi
fi

[[ ${#errors[@]} -eq 0 ]]
