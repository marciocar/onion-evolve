#!/usr/bin/env bash
# SessionStart (Onion) — lista os arquivos com FORMA de plugin (`<nome>/.claude-plugin/` e `<nome>/hooks/`, no 1º nível de cada skill)
# em .claude/skills e na pasta de skills do usuário. Só avisa: o SessionStart não barra nada, e a pasta de casa nunca barra. FORMA não é CARGA: as células medidas em 2026-11-04 mostram que pasta aninhada (S3) e projeto sem
# aceite de confiança (S2) não carregam, e que a pasta de skills do usuário carrega mesmo sem aceite (S5). Por isso o aviso não
# afirma que carregou e não manda desconfiar de tudo: ele dá os caminhos e diz o que o maestro confere. Silencioso quando limpo;
# nunca falha a sessão (exit 0 sempre). Lógica e teto em plugin-write-scan-check.sh; o veto é o pretooluse-plugin-write-guard.sh.
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
check="${root}/.claude/validation/plugin-write-scan-check.sh"
[ -f "${check}" ] || exit 0
out="$(ONION_PW_SCAN_TIMEOUT=3 timeout 4 bash "${check}" "${root}" --home --format tsv 2>/dev/null)"; rc=$?
if [ "${rc}" -ne 0 ]; then
  echo "🧩 A varredura de plugin em .claude/skills NÃO RODOU (rc=${rc}): isto não é aprovação."
  exit 0
fi
[ -n "${out}" ] || exit 0
n="$(printf '%s\n' "${out}" | wc -l | tr -d '[:space:]')"
echo "🧩 ${n} arquivo(s) com FORMA de plugin em .claude/skills. Forma não é carga: pode ter carregado nesta sessão, ou não. O maestro confere estes caminhos: quem escreveu cada um, e se há hooks/hooks.json com módulo. Plugin se instala pelo mecanismo próprio do Claude Code (/plugin, marketplace ou --plugin-dir), não escrevendo em skills: o que não for do maestro sai, fora da sessão ou por rm."
# o caminho já vem saneado pela varredura: um por linha, só imprimíveis
printf '%s\n' "${out}" | cut -f3 | head -n 20 | sed 's/^/  - /'
exit 0
