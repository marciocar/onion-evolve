#!/usr/bin/env bash
# Veto gerenciado: chama uma copia da guarda real do Onion e falha fechado se ela nao decidir.
input="$(cat)"
out="$(printf '%s' "$input" | bash /etc/claude-code/hooks/pretooluse-env-guard.sh 2>&1)"; rc=$?
# So no laboratorio: prova de que o hook gerenciado rodou.
[ -n "${LAB_DIR:-}" ] && printf 'rc=%s\n' "$rc" >> "$LAB_DIR/managed-hook.log"
[ "$rc" -eq 0 ] && exit 0
echo "GERENCIADO: ${out:-guarda sem decisao, rc=$rc}" >&2
exit 2
