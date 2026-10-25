#!/usr/bin/env bash
# =============================================================================
# assert-dest.sh — confere que o DEST da adoção é a RAIZ de um repositório git próprio
#
# POR QUÊ : incidente medido em 2026-10-25, num `/meta:adopt --update`. O agente extraiu o bloco
#           "Procedimento de Configuração pós-cópia" do adopt.md e deixou o placeholder sem
#           preencher: `DEST="<INSTALL_DIR (Fase 3) | WORK (--update)>"`. Na 1ª execução:
#             · um helper fez `mkdir -p "$DEST/..."` e criou um diretório-lixo com esse nome
#               LITERAL na raiz do core;
#             · como o diretório-lixo estava DENTRO do core, `git -C "$DEST" config
#               gitflow.branch.develop main` (e o do master) subiu até o repo que o contém e gravou
#               no .git/config DO CORE;
#             · o instalador do githook só não trocou o `core.hooksPath` do core porque ele já
#               estava setado. Isso foi sorte, não guarda.
#           A classe de defeito: `git -C <dir>` não pergunta se <dir> é um repo, ele procura o repo
#           MAIS PRÓXIMO para cima. Um DEST que não é a raiz de um repo próprio faz toda escrita de
#           config cair no repo pai, em silêncio. `rev-parse --git-dir` (o que os helpers checavam)
#           responde SIM num subdiretório qualquer, então não protege; a pergunta certa é se o
#           toplevel resolvido é o próprio DEST.
#
# COMO    : recusa (rc=2, nomeando o motivo no stderr) quando o DEST:
#             (1) está vazio;
#             (2) contém `<` ou `>` (placeholder não preenchido);
#             (3) não existe;
#             (4) não é diretório;
#             (5) não está num repo git;
#             (6) não é a raiz do repo: o toplevel resolvido, em caminho físico, difere do caminho
#                 físico do DEST. Worktree passa, porque o toplevel dela é ela mesma.
#           Não cria nada e não escreve nada: só lê. Sai 0 e não imprime nada quando o DEST serve.
#           O irmão `offer-onion-ci.sh` já fazia a mesma checagem de raiz, inline; esta é a
#           versão única que o bloco pós-cópia e os helpers que escrevem fora de arquivo chamam.
#
# USO     : assert-dest.sh <DEST>
#           No bloco:  bash "$SOURCE_ROOT/.claude/utils/adopt/assert-dest.sh" "$DEST" || exit 1
#           No helper: bash "$(dirname "${BASH_SOURCE[0]}")/assert-dest.sh" "${DEST}" || exit 2
# =============================================================================
set -u

_no() { echo "RECUSADO (assert-dest): $1" >&2; exit 2; }

DEST="${1-}"
[ -n "${DEST}" ] || _no "DEST vazio — preencha o caminho do repo alvo antes de rodar o bloco."
case "${DEST}" in
  *'<'*|*'>'*) _no "DEST com placeholder não preenchido: '${DEST}' — troque pelo caminho real do repo alvo." ;;
esac
[ -e "${DEST}" ] || _no "DEST não existe: '${DEST}' — nada foi criado."
[ -d "${DEST}" ] || _no "DEST não é diretório: '${DEST}'."

_top="$(git -C "${DEST}" rev-parse --show-toplevel 2>/dev/null)" \
  || _no "DEST não está num repositório git: '${DEST}'."
_top_p="$(cd "${_top}" 2>/dev/null && pwd -P)" || _no "toplevel '${_top}' não resolvido."
_dest_p="$(cd "${DEST}" 2>/dev/null && pwd -P)" || _no "DEST '${DEST}' não resolvido."
[ "${_top_p}" = "${_dest_p}" ] \
  || _no "DEST não é a raiz de um repo próprio: '${_dest_p}' está dentro do repo '${_top_p}', e todo 'git -C DEST config' gravaria no .git/config DELE."
exit 0
