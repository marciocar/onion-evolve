#!/usr/bin/env bash
# resolve-manifest.sh — resolve o manifesto de transporte de um papel, LENDO O rc.
#
# Uso: resolve-manifest.sh <SOURCE_ROOT> [<papel>]   → um pathspec por linha
#
# ══ POR QUE EXISTE ════════════════════════════════════════════════════════════════════════════
# Porque `mapfile -t manifest < <(vendor-manifest.sh …)` ENGOLE O rc DO PRODUTOR, e esse é o caminho
# por onde o repositório INTEIRO vaza. Medido 2026-09-15, na passada adversarial do PR #833: com o
# manifesto saindo ≠0 (papel desconhecido, repo sem superfície) o array fica VAZIO — e pathspec
# AUSENTE significa TODOS para o git, não NENHUM. `git archive HEAD --` devolveu 2222 arquivos,
# 353 de biografia, o diário inteiro, com rc=0.
#
# A lição é maior que o bug: as guardas `exit 2/3` que o `vendor-manifest.sh` ganhou AUMENTARAM as
# portas para esse estado sem que ninguém do outro lado as lesse. Guarda que o consumidor não lê é
# decoração — a mesma classe do `--role` decorativo, uma camada adiante.
#
# Duas asserções, e as duas são de FORMA, não de conteúdo: o rc do produtor é 0, e o manifesto tem
# ao menos um pathspec. Nenhuma das duas sabe o que deveria viajar — isso é do manifesto.
set -uo pipefail

SRC="${1:?uso: resolve-manifest.sh <SOURCE_ROOT> [<papel>]}"
ROLE="${2:-${ONION_ROLE:-adopted}}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_rc=0
_out="$(bash "${HERE}/vendor-manifest.sh" --role "${ROLE}" --repo "${SRC}")" || _rc=$?
if [ "${_rc}" -ne 0 ]; then
  echo "ERRO: o manifesto de transporte falhou (rc=${_rc}) para o papel '${ROLE}' — seguir daqui copiaria o repositório inteiro." >&2
  exit 3
fi
if [ -z "${_out}" ]; then
  echo "ERRO: manifesto VAZIO para o papel '${ROLE}' — pathspec ausente é TODOS para o git, não NENHUM." >&2
  exit 3
fi
printf '%s\n' "${_out}"
