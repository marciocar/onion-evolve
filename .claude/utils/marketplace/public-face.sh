#!/usr/bin/env bash
# ===========================================================================
# public-face.sh — a FACE PÚBLICA do Onion, numa costura só (SSOT sourceável)
# ===========================================================================
# POR QUE EXISTE (medido 2026-09-07, decisão do maestro no grafo
# plugins-en-compliance-2026-09, nó D_CONTATO_DESACOPLADO):
#   O repo-fonte `marciocar/onion-evolve` é PRIVADO. Até aqui, `assemble-plugin.sh`
#   derivava UMA variável (`repository`, de `git remote get-url origin`) e a usava em
#   TRÊS papéis diferentes — proveniência, `homepage` e `repository` do manifesto —
#   o que publicava um endereço 404 como se fosse a casa e o suporte do projeto.
#   O desacoplamento separa os três papéis; esta lib é a costura onde eles vivem,
#   para que `plugin-readme.sh`, `marketplace-readme.sh` e `generate-marketplace.sh`
#   leiam o MESMO valor em vez de cada um hardcodar o seu (era o resíduo (3)).
#
# OS TRÊS PAPÉIS, que não se confundem:
#   ONION_PUBLIC_HOMEPAGE   — a CASA pública do projeto (site).
#   ONION_PUBLIC_REPOSITORY — o repo PÚBLICO de instalação/issues (canal de suporte).
#   ONION_SOURCE_IS_PRIVATE — se a origem em `provenance.repository` é privada. Quando
#                             é, nenhum gerador pode emiti-la como LINK; no máximo como
#                             marca de origem, e dizendo que é privada.
#
# Todas são sobrescrevíveis por ambiente — quem forkar o Onion troca sem editar script.
# ===========================================================================
: "${ONION_PUBLIC_HOMEPAGE:=https://onionevolve.com}"
: "${ONION_PUBLIC_REPOSITORY:=https://github.com/marciocar/onion-plugins}"
: "${ONION_SOURCE_IS_PRIVATE:=1}"
# Nome do marketplace público — mesmo default que assemble-plugin.sh já usava.
: "${ONION_MARKETPLACE_NAME:=onion-plugins}"

# onion_source_label <repository-slug>
#   Como a ORIGEM pode aparecer num artefato público. Fonte privada NUNCA vira link.
onion_source_label() {
  local slug="${1:-}"
  [ -n "${slug}" ] || { printf '(desconhecida)'; return 0; }
  if [ "${ONION_SOURCE_IS_PRIVATE}" = "1" ]; then
    printf '`%s` (repositório privado)' "${slug}"
  else
    printf 'https://github.com/%s' "${slug}"
  fi
}
