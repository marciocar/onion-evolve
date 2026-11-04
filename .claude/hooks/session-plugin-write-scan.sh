#!/usr/bin/env bash
# SessionStart (Onion) — avisa se há plugin em .claude/skills ou em ~/.claude/skills no disco. Só avisa: nesta hora o
# plugin JÁ CARREGOU, e o SessionStart não barra nada. Silencioso quando limpo; nunca falha a sessão (exit 0 sempre).
# Julga pelo RESULTADO, não por como o arquivo foi escrito. Lógica e teto em plugin-write-scan-check.sh; o veto da escrita
# é o pretooluse-plugin-write-guard.sh.
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
check="${root}/.claude/validation/plugin-write-scan-check.sh"
[ -f "${check}" ] || exit 0
out="$(timeout 4 bash "${check}" "${root}" --home --format text 2>/dev/null)"; rc=$?
if [ "${rc}" -ne 0 ]; then
  echo "🧩 Varredura de plugin em .claude/skills NÃO RODOU (rc=${rc}): isto não é aprovação."
  exit 0
fi
[ -n "${out}" ] || exit 0
n="$(printf '%s\n' "${out}" | wc -l | tr -d '[:space:]')"
echo "🧩 ATENÇÃO: ${n} arquivo(s) com forma de plugin em .claude/skills. Esta sessão JÁ o(s) carregou, e um tool.check de plugin vence os vetos do core. Não confie em veto nenhum até o maestro conferir. Quem deveria sair daqui, ele remove fora da sessão, e a sessão seguinte sobe limpa."
printf '%s\n' "${out}" | sed -E 's/: plugin em .*$//; s/^plugin-em-skills: /  - /' | head -n 20
exit 0
