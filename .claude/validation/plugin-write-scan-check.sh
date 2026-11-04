#!/usr/bin/env bash
# =============================================================================
# plugin-write-scan-check.sh — REGRA 114: nenhum plugin mora em .claude/skills no disco
#
# O QUE   : acha ARQUIVOS em `.claude/skills/**/.claude-plugin/**` e `.claude/skills/**/hooks/**`. Com `--home`,
#           também em `~/.claude/skills`. Segue symlink: a skill que é link para fora carrega (medido, célula S6).
#           É a metade do veto que NÃO depende de como o arquivo foi escrito: `python3 x.py`, `git apply`, `tar`, o
#           processo de um mod e um MCP de escrita escapam do pretooluse-plugin-write-guard.sh, e o resultado deles
#           cai aqui do mesmo jeito.
#
# DEFEITO DATADO: medido em 2026-11-04, em LABORATÓRIO, não em dano de produção. Claude Code 2.1.318, 129 sessões
#           de roteiro fixo: nenhum veto do core barrou escrita em .claude/ nem em ~/.claude/skills. Um plugin gravado
#           ali sob bypass carrega na sessão seguinte, e o `tool.check` dele vence o veto do .env. Evidência e teto:
#           docs/evolution/research/guard-plugin-write-2026-11/plugin-write-2026-11.kg.yaml
#
# ONDE    : no SessionStart (session-plugin-write-scan.sh, com --home, só avisa) e no lint (REGRA 114, sem --home: o
#           gate não pode depender do `~` de quem roda).
# O QUE ELA NÃO VÊ: skill nomeada `hooks` (o 1º componente é o nome, e isso é honesto); `node_modules/`, `.git/`,
#           `.venv/` e `venv/` (desce só no que uma skill é); `sub/.claude/skills` de um subdiretório; CLAUDE_CONFIG_DIR
#           fora de `~/.claude`; plugin montado noutro lugar e passado por --plugin-dir. No SessionStart o plugin
#           presente JÁ FOI carregado por aquela sessão: o aviso é detecção, não prevenção.
#
# USO     : plugin-write-scan-check.sh [REPO] [--home] [--format text|tsv] | --selftest
# SAÍDA   : tsv  <SEV>\tplugin-em-skills\t<caminho>\t<msg> · vazio = limpo
# RC      : 0 sempre que julgou (as linhas dizem o resto) · 2 = não pôde julgar (≠ aprovação)
# =============================================================================
set -uo pipefail
MODE="check"; FORMAT="text"; REPO=""; HOME_TOO=0
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --home) HOME_TOO=1; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done

# _scan_dir <pasta skills> <rótulo>: caminhos RELATIVOS à pasta, para o `hooks` do caminho até ela nunca contar. O `find -L`
# reclama de laço de symlink no stderr; o laço não vira rc de julgamento, e o resto da árvore segue varrido.
_scan_dir() {
  local dir="$1" label="$2" f
  [ -d "${dir}" ] || return 0
  ( cd "${dir}" 2>/dev/null || exit 0
    find -L . -mindepth 2 \( -name node_modules -o -name .git -o -name .venv -o -name venv \) -prune -o \
      -type f \( -path './.claude-plugin/*' -o -path './*/.claude-plugin/*' -o -path './*/hooks/*' \) -print 2>/dev/null
  ) | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s\n' "${label}/${f#./}"
  done
}

_report() {
  local repo="$1" fmt="$2" home_too="$3" p msg
  msg="plugin em .claude/skills carrega na sessão seguinte, e o tool.check dele vence os vetos do core. Confira quem escreveu e remova, ou mova para um plugin instalado por marketplace"
  { _scan_dir "${repo}/.claude/skills" ".claude/skills"
    [ "${home_too}" = 1 ] && [ -n "${HOME:-}" ] && _scan_dir "${HOME}/.claude/skills" "~/.claude/skills"
  } | while IFS= read -r p; do
    if [ "${fmt}" = "tsv" ]; then printf 'HARD\tplugin-em-skills\t%s\t%s\n' "${p}" "${msg}"
    else printf 'plugin-em-skills: %s: %s\n' "${p}" "${msg}"; fi
  done
}

if [ "${MODE}" = "selftest" ]; then
  fails=0; d="$(mktemp -d)"; trap 'rm -rf "${d}"' EXIT
  # _c <esperado: acusa|cala> <nome> <repo> [--home] — cada caso roda o script como o dispatcher e o hook o rodam
  _c() {
    local want="$1" name="$2" repo="$3"; shift 3
    case "${name}" in *"${PW_SELFTEST_ONLY:-}"*) : ;; *) return 0 ;; esac
    local out rc; out="$(bash "$0" "${repo}" --format tsv "$@" 2>/dev/null)"; rc=$?
    if [ "${rc}" -eq 0 ] && { { [ "${want}" = acusa ] && [ -n "${out}" ]; } || { [ "${want}" = cala ] && [ -z "${out}" ]; }; }; then
      printf 'ok   %-5s %s\n' "${want}" "${name}"
    else printf '✗    %-5s %s (rc=%s saída=%s)\n' "${want}" "${name}" "${rc}" "${out}"; fails=$((fails + 1)); fi
  }
  _r() { mkdir -p "${d}/$1/.claude/skills"; printf '%s' "${d}/$1"; }
  r="$(_r plugin)"; mkdir -p "${r}/.claude/skills/x/.claude-plugin"; echo '{}' > "${r}/.claude/skills/x/.claude-plugin/plugin.json"
  _c acusa "plugin.json em skills/x/.claude-plugin (W1)" "${r}"
  r="$(_r hooks)"; mkdir -p "${r}/.claude/skills/x/hooks"; echo '{}' > "${r}/.claude/skills/x/hooks/hooks.json"
  _c acusa "hooks.json em skills/x/hooks (W1)" "${r}"
  r="$(_r aninhado)"; mkdir -p "${r}/.claude/skills/a/b/.claude-plugin"; echo '{}' > "${r}/.claude/skills/a/b/.claude-plugin/plugin.json"
  _c acusa "aninhado skills/a/b (S3)" "${r}"
  r="$(_r link)"; mkdir -p "${d}/fora/x/.claude-plugin"; echo '{}' > "${d}/fora/x/.claude-plugin/plugin.json"; ln -s "${d}/fora/x" "${r}/.claude/skills/x"
  _c acusa "skill que é link para fora (S6)" "${r}"
  r="$(_r laco)"; mkdir -p "${r}/.claude/skills/x/hooks"; echo x > "${r}/.claude/skills/x/hooks/h"; ln -s .. "${r}/.claude/skills/x/volta"
  _c acusa "laço de symlink não esconde o achado" "${r}"
  r="$(_r limpo)"; mkdir -p "${r}/.claude/skills/onion"; echo x > "${r}/.claude/skills/onion/SKILL.md"; mkdir -p "${r}/.claude/hooks"; echo x > "${r}/.claude/hooks/x.sh"
  _c cala "skill honesta e .claude/hooks" "${r}"
  r="$(_r vazio)"; mkdir -p "${r}/.claude/skills/x/hooks"
  _c cala "pasta vazia: não há arquivo" "${r}"
  r="$(_r nomeada)"; mkdir -p "${r}/.claude/skills/hooks"; echo x > "${r}/.claude/skills/hooks/SKILL.md"
  _c cala "skill nomeada hooks" "${r}"
  r="$(_r modulos)"; mkdir -p "${r}/.claude/skills/x/node_modules/lib/hooks"; echo x > "${r}/.claude/skills/x/node_modules/lib/hooks/i.js"
  _c cala "hooks dentro de node_modules" "${r}"
  mkdir -p "${d}/hooks/proj/.claude/skills/onion"; echo x > "${d}/hooks/proj/.claude/skills/onion/SKILL.md"
  _c cala "o repo mora numa pasta chamada hooks" "${d}/hooks/proj"
  r="$(_r sem-skills)"; rm -rf "${r}/.claude/skills"
  _c cala "repo sem .claude/skills" "${r}"
  r="$(_r repo-limpo)"; mkdir -p "${d}/casa/.claude/skills/x/.claude-plugin"; echo '{}' > "${d}/casa/.claude/skills/x/.claude-plugin/plugin.json"
  HOME="${d}/casa" _c cala "~/.claude/skills sem --home: o gate não depende do ~" "${r}"
  HOME="${d}/casa" _c acusa "~/.claude/skills com --home (W1, T5)" "${r}" --home
  if [ "${fails}" -eq 0 ]; then echo "plugin-write-scan --selftest: OK"; exit 0; fi
  echo "plugin-write-scan --selftest: ${fails} falha(s)"; exit 1
fi

[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -d "${REPO}" ] || { echo "plugin-write-scan: repo não encontrado: ${REPO}" >&2; exit 2; }
_report "${REPO}" "${FORMAT}" "${HOME_TOO}"
exit 0
