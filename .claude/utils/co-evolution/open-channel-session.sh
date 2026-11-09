#!/usr/bin/env bash
# Abre uma sessão interativa do Claude Code com o canal da campainha do repo em que o terminal está.
#
#   bash .claude/utils/co-evolution/open-channel-session.sh [--continue | --resume [id]]
#
# Por que existe: o Claude Code não tem chave de settings nem variável para ligar canal. O servidor de `.mcp.json`
# fora da allowlist só entra com `--dangerously-load-development-channels server:<nome>`, por sessão, e sem a flag o
# push é descartado em silêncio. Este é o único lugar versionado que escreve a linha.
#
# O que ele NÃO faz, de propósito: a lista de argumentos é fechada (só retomar conversa). Qualquer outra flag, inclusive
# de permissão, é recusada. Exige terminal nos dois lados, porque a tela de confirmação do Claude Code é para uma
# pessoa: entrada canalizada a responderia sozinha.
set -euo pipefail

die() { printf 'open-channel-session: %s\n' "$2" >&2; exit "$1"; }

args=()
safe_id='^[A-Za-z0-9][A-Za-z0-9._-]*$'
while [ "$#" -gt 0 ]; do
  case "$1" in
    -c|--continue) args+=(--continue); shift ;;
    -r|--resume)
      if [ "$#" -ge 2 ] && [[ "$2" != -* ]]; then
        [[ "$2" =~ $safe_id ]] || die 2 "identificador de sessão inválido em --resume."
        args+=(--resume "$2"); shift 2
      else
        args+=(--resume); shift
      fi
      ;;
    --resume=*)
      [[ "${1#--resume=}" =~ $safe_id ]] || die 2 "identificador de sessão inválido em --resume."
      args+=(--resume "${1#--resume=}"); shift
      ;;
    *) die 2 "argumento recusado: '$1'. Só --continue e --resume [id] passam por aqui; para o resto, chame o claude direto." ;;
  esac
done

[ -t 0 ] && [ -t 1 ] || die 2 "precisa de um terminal: a confirmação do canal é para uma pessoa responder."

command -v python3 >/dev/null 2>&1 || die 2 "python3 não encontrado: sem ele não dá para ler o .mcp.json."
command -v claude >/dev/null 2>&1 || die 127 "o comando claude não está no PATH."

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/channel-session.py"

rc=0
server="$(python3 -I -S "${helper}" server --repo "${root}")" || rc=$?
case "${rc}" in
  0) ;;
  3) die 2 "${root} não tem servidor de canal no .mcp.json (hoje: doorbell). A adesão é pelo /meta:federation-a2a." ;;
  *) die 2 "não deu para ler ${root}/.mcp.json." ;;
esac

cd "${root}"
# a forma com + porque array vazio sob `set -u` quebra no bash 3.2 do macOS
exec claude --dangerously-load-development-channels "server:${server}" ${args[@]+"${args[@]}"}
