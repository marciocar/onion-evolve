#!/usr/bin/env bash
# load-manifest.sh — carrega o manifesto de transporte num array do CHAMADOR, lendo o rc do produtor.
#
# Uso (SOURCE, não execute — o array vive no shell de quem chama):
#   source "$SOURCE_ROOT/.claude/utils/adopt/load-manifest.sh"
#   onion_load_manifest "$SOURCE_ROOT" "$ROLE" || exit 1     # → preenche manifest[]
#
# ══ POR QUE EXISTE (F1 das portas, SAC-87, 2026-10-09) ═══════════════════════════════════════════
# O `resolve-manifest.sh` nasceu em 2026-09-15 para LER o rc do `vendor-manifest.sh` — e os dois
# sítios do adopt.md que o chamavam o embrulharam de novo no padrão que ele veio curar:
#     mapfile -t manifest < <(bash resolve-manifest.sh …) || { echo ABORTADO; exit 1; }
# O `||` pega o rc do MAPFILE, que é 0 sempre; o rc=3 do produtor some na substituição de processo.
# Resultado: manifesto falho → array VAZIO → `git archive HEAD --` sem pathspec = o repositório
# INTEIRO, com rc=0. O ABORTADO nunca disparou. E a bancada aprovava, porque procurava a STRING
# `resolve-manifest.sh" … \` no fim da linha — guarda de declaração, não de comportamento.
#
# A forma certa tem dois tempos e não cabe numa linha: (1) capturar a saída numa variável, onde o
# rc do `$(…)` É o do produtor; (2) só então virar array, e recusar o vazio — `<<<""` produz UM
# elemento vazio, e `[ ${#manifest[@]} -eq 0 ]` não pegaria. Duas cópias desse par no adopt.md
# eram duas chances de errar de novo; daí a função única.
#
# Retorno: 0 = manifest[] com ≥1 pathspec · 1 = produtor falhou OU manifesto vazio (manifest=() ).
# Exercitado por lint-selftest.sh (run_adopt_robust_selftests).

onion_load_manifest() {
  local _src="${1:?uso: onion_load_manifest <SOURCE_ROOT> <papel>}" _role="${2:?uso: onion_load_manifest <SOURCE_ROOT> <papel>}"
  local _out _rc=0
  manifest=()
  _out="$(bash "${_src}/.claude/utils/adopt/resolve-manifest.sh" "${_src}" "${_role}")" || _rc=$?
  if [ "${_rc}" -ne 0 ]; then
    echo "ABORTADO: manifesto de transporte não resolvido para o papel '${_role}' (rc=${_rc}) — seguir copiaria o repositório inteiro." >&2
    return 1
  fi
  mapfile -t manifest <<< "${_out}"
  # `<<<""` dá UM elemento vazio: conta pathspecs não-vazios, não elementos.
  local _p _n=0
  for _p in "${manifest[@]}"; do [ -n "${_p}" ] && _n=$((_n + 1)); done
  if [ "${_n}" -eq 0 ]; then
    manifest=()
    echo "ABORTADO: manifesto VAZIO para o papel '${_role}' — pathspec ausente é TODOS para o git, não NENHUM." >&2
    return 1
  fi
  return 0
}
