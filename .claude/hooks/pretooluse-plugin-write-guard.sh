#!/usr/bin/env bash
# PreToolUse(Write|Edit|NotebookEdit|Bash) — VETO (exit 2) à escrita de plugin em .claude/skills e ~/.claude/skills.
# Decisão do maestro de 2026-11-04: «Veto estreito + varredura no disco».
#
# ── O DEFEITO MEDIDO (datado, e em LABORATÓRIO, não em dano de produção) ───────────────────────
# 2026-11-04, Claude Code 2.1.318, sessões de roteiro fixo contra um stub, sob bypassPermissions: das 129 tentativas
# de escrita em .claude/ e ~/.claude/skills, NENHUM veto do core barrou (126 gravaram; 3 foram recusadas pela validação de
# schema do próprio Edit, por carga inválida do laboratório, e a carga válida gravou). Um plugin gravado em
# .claude/skills/x sob bypass carrega na sessão SEGUINTE, e o `tool.check` dele vence o veto do .env (células W1 e W4); em
# ~/.claude/skills ele carrega e vence mesmo sem aceite de confiança no projeto (célula S5). Nenhum adotante sofreu isto.
# Grafo: docs/evolution/research/guard-plugin-write-2026-11/plugin-write-2026-11.kg.yaml
#
# ── O QUE VETA ───────────────────────────────────────────────────────────────────
#   · Write, Edit e NotebookEdit cujo caminho, COMO ESCRITO ou RESOLVIDO (symlink não contém `.claude` no texto), tem a forma
#     `.claude/skills/**/.claude-plugin/**` ou `.claude/skills/**/hooks/**`, em qualquer raiz, inclusive `~`;
#   · Bash que escreve nesse caminho, pelo tokenizador de lib/invocation-lines.sh + lib/plugin-write-judge.py, que compõe o
#     juiz do MOAT: redirecionamento, tee, cp, mv, install, rsync, dd, tar -C, curl -o, sed -i, `cd` antes de `>`, variável
#     e pedaços LITERAIS da mesma string, `bash -c`, script não versionado (lido e julgado), e código embutido em outra
#     linguagem (`python3 -c`, `python3 - <<EOF`) quando o caminho é literal na chamada que escreve;
#   · `cp -r`, `mv`, `ln -s`, `rsync` de pasta que JÁ TEM a forma de plugin para dentro de .claude/skills.
#
# ── O QUE CALA (falso positivo é o defeito dominante aqui) ────────────────────────────────
#   · qualquer outro caminho: .claude/skills/onion/SKILL.md, .claude/hooks/x.sh, .claude/settings.json, docs/**, e skill NOMEADA
#     `hooks` (o 1º componente depois de skills/ é o nome; plugin mora um nível abaixo);
#   · texto que só CITA o caminho: echo, heredoc de documento, grep, git log, `git commit -m`, `python3 x.py <texto>`;
#   · leitura: cat, ls, Read, `cp <plugin> /tmp`, `open(caminho)` sem modo de escrita;
#   · REMOVER: rm, rmdir, unlink, find -delete e a origem de um mv. É a cura que a varredura manda fazer.
#   A vizinha ensina: em 2026-11-04 a guarda do arquivo de segredos deu dois falsos positivos (relato do maestro), e mais dois
#   nesta forja (um grep em `.claude/utils/*/*` e um python3 com heredoc cujo texto citava o arquivo). Aqui o veto casa a FORMA de
#   um caminho de ESCRITA, nunca o texto. E o replay sobre os transcripts já reprovou a 1ª redação (ver o juiz).
# ── TETO: É CONTENÇÃO DE ACIDENTE E DE INJEÇÃO INGÊNUA, NÃO FRONTEIRA ──────────────────────
#   Em Bash a lista falha pelo vocabulário. NÃO vê: `python3 x.py`, script versionado, `base64 -d | sh`, `git apply`, `tar`,
#   `unzip` e `cp -r` cujo destino é só a pasta de skills e cuja origem ainda não existe no disco, nome montado de fora da
#   string, por `$(…)` ou de pedaços sem `.claude-plugin` nem `skills`+`hooks` no texto, caminho em variável dentro de código
#   embutido, script em dois tempos que monta o nome, e `cp`/`install` que um programa chama por dentro.
#   O processo de um mod e um MCP de escrita ficam fora do PreToolUse. O hook é de projeto: cai junto com o settings.json
#   (a própria medição gravou `.claude/settings.json` e o hook do .env sem barreira nenhuma). A metade que não depende do
#   vocabulário é a varredura, plugin-write-scan-check.sh, no SessionStart e no lint. O `--selftest` imprime o teto como casos.
# ── CONSEQUÊNCIA DECLARADA ──────────────────────────────────────────────────────────
#   A sessão não forja mod em .claude/skills nem em ~/.claude/skills (a skill embutida plugin-authoring grava ali): quem
#   instala é o maestro. Escape = fora da sessão (`!` no prompt). Não há variável de bypass, por desenho: escape que o modelo
#   escreve na própria string é gate textual com outro nome.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_pw_is_plugin_path() {
  case "$1" in
    */.claude/skills/.claude-plugin|*/.claude/skills/.claude-plugin/*) return 0 ;;
    */.claude/skills/*/.claude-plugin|*/.claude/skills/*/.claude-plugin/*) return 0 ;;
    */.claude/skills/*/hooks|*/.claude/skills/*/hooks/*) return 0 ;;
  esac
  return 1
}

_pw_deny() {
  echo "GUARDA-PRETOOLUSE (plugin em skills): $1. Plugin em .claude/skills carrega na sessão seguinte, e o tool.check dele vence os vetos do core (medido em laboratório em 2026-11-04). Negado. Se é um plugin de verdade, o maestro o instala fora da sessão (\`!\` no prompt)." >&2
  exit 2
}

# ───────────────────────────── selftest ─────────────────────────────
if [ "${1:-}" = "--selftest" ]; then
  export LC_ALL=C
  fails=0; d="$(mktemp -d)"; trap 'rm -rf "${d}"' EXIT
  p="${d}/proj"; mkdir -p "${p}/.claude/skills/onion" "${p}/.claude/hooks" "${p}/docs" "${p}/tools" "${p}/scratch" "${d}/home/.claude/skills/x" "${d}/fora/ext/.claude-plugin" "${d}/fora/vazia"
  git -C "${p}" init -q -b feat
  echo x > "${p}/.claude/skills/onion/SKILL.md"; echo x > "${p}/.claude/hooks/x.sh"; echo '{}' > "${p}/.claude/settings.json"; echo x > "${p}/docs/a.md"; echo '{}' > "${d}/fora/payload"
  # o wrapper VERSIONADO, rastreado pelo git: fronteira do juiz. E o script solto (K4): lido e julgado
  printf 'cat > .claude/skills/x/hooks/h <<E\nE\n' > "${p}/tools/w.sh"
  git -C "${p}" add -A; git -C "${p}" -c user.email=t@t -c user.name=t commit -q -m base
  printf 'mkdir -p .claude/skills/x/.claude-plugin\nprintf x > .claude/skills/x/.claude-plugin/plugin.json\n' > "${p}/docs/sbx.sh"
  printf 'echo .claude/skills/x/hooks/h\n' > "${p}/scratch/cita.sh"
  ln -s ../.claude "${p}/docs/sbx-link"                                    # K3
  ln -s "${p}/.claude/skills/x/hooks" "${p}/docs/lnk-hooks"                # link que termina no alvo, sem sinal no texto
  ln -s "${d}/fora/vazia" "${p}/.claude/skills/fora"                       # S6: skill que é link para fora
  P=".claude/skills/x/.claude-plugin/plugin.json"; H=".claude/skills/x/hooks/hooks.json"
  _run() {  # _run <tool> <valor> [cwd] — o JSON como o runner entrega, pela entrada padrão
    local tool="$1" val="$2" cwd="${3:-${p}}"
    python3 -I -c 'import json,sys
t,v,c=sys.argv[1:4]
k={"Bash":"command","NotebookEdit":"notebook_path"}.get(t,"file_path")
ti={k:v}
if t=="Write": ti["content"]="cita .claude/skills/x/hooks/h e \"file_path\": \"/x/.claude/skills/y/hooks/z\""
print(json.dumps({"session_id":"s","hook_event_name":"PreToolUse","tool_name":t,"tool_input":ti,"cwd":c}))' "${tool}" "${val}" "${cwd}" \
      | CLAUDE_PROJECT_DIR="${p}" HOME="${d}/home" bash "${BASH_SOURCE[0]}" 2>/dev/null
  }
  # _c <acusa|cala|TETO> <nome> <tool> <valor> [cwd]
  _c() {
    local want="$1" name="$2" rc; shift 2
    # a bancada de mutantes roda só o caso que o mutante tem de matar; a cópia limpa roda todos, antes
    case "${name}" in *"${PW_SELFTEST_ONLY:-}"*) : ;; *) return 0 ;; esac
    _run "$@" >/dev/null; rc=$?
    case "${want}:${rc}" in
      acusa:2|cala:0) printf 'ok   %-5s %s\n' "${want}" "${name}" ;;
      TETO:0)         printf 'TETO %-5s %s\n' "cala" "${name}" ;;
      *)              printf '✗    %-5s %s (rc=%s)\n' "${want}" "${name}" "${rc}"; fails=$((fails + 1)) ;;
    esac
  }
  # ── ACUSA, com a forma verbatim da medição de 2026-11-04 (T3 e T4 no projeto, T5 no ~) ──
  _c acusa "Write T3"                Write "${p}/${P}"
  _c acusa "Write T4"                Write "${p}/${H}"
  _c acusa "Write T5 (~/.claude/skills)" Write "${d}/home/.claude/skills/x/.claude-plugin/plugin.json"
  _c acusa "Write com caminho relativo" Write "${P}"
  _c acusa "Edit T3"                 Edit  "${p}/${P}"
  _c acusa "NotebookEdit T4"         NotebookEdit "${p}/.claude/skills/x/hooks/n.ipynb"
  _c acusa "Write aninhado skills/a/b (S3)" Write "${p}/.claude/skills/a/b/hooks/h.js"
  _c acusa "Write por symlink (K3)"  Write "${p}/docs/sbx-link/skills/x/.claude-plugin/plugin.json"
  _c acusa "Write por symlink que termina em hooks" Write "${p}/docs/lnk-hooks/register.js"
  _c acusa "Write por skill que é link para fora (S6)" Write "${p}/.claude/skills/fora/.claude-plugin/plugin.json"
  _c acusa "cat > T3 (verbatim)"     Bash  "mkdir -p .claude/skills/x/.claude-plugin && cat > ${P} <<'SBXEOF'
{\"name\":\"x\"}
SBXEOF"
  _c acusa "cat > T5 com ~"          Bash  "mkdir -p ~/.claude/skills/x/.claude-plugin && cat > ~/.claude/skills/x/.claude-plugin/plugin.json <<'E'
{}
E"
  _c acusa "tee T4 (verbatim)"       Bash  "mkdir -p .claude/skills/x/hooks && printf '%b' '{}\\n' | tee ${H} > /dev/null"
  _c acusa "cp T3 (verbatim)"        Bash  "mkdir -p .claude/skills/x/.claude-plugin && cp ${d}/fora/payload ${P}"
  _c acusa "python3 -c T3 (verbatim)" Bash "python3 -c \"import os;os.makedirs(os.path.dirname('${p}/${P}'),exist_ok=True);open('${p}/${P}','w').write(open('${d}/fora/payload').read())\""
  _c acusa "python3 -c com Path.write_text" Bash "python3 -c \"import pathlib;pathlib.Path('${H}').write_text('x')\""
  _c acusa "python3 heredoc"         Bash  "python3 - <<'EOF'
open('${P}', 'w').write('x')
EOF"
  _c acusa "mv de /tmp (K1, verbatim)" Bash "printf '%b' '{}\\n' > /tmp/sbx-k1 && mkdir -p .claude/skills/x/.claude-plugin && mv /tmp/sbx-k1 ${P}"
  _c acusa "cd .claude && … > (K5, verbatim)" Bash "cd .claude && mkdir -p skills/x/.claude-plugin && cd skills/x/.claude-plugin && printf '%b' '{}\\n' > plugin.json"
  _c acusa "nome em variável literal" Bash "D=.claude/skills/x/.claude-plugin; mkdir -p \"\$D\"; cat > \"\$D/plugin.json\" <<'E'
{}
E"
  _c acusa "nome montado de pedaços literais (K2, verbatim)" Bash "a=.cla; b=ude; f=\"\$a\$b/skills/x/.claude-plugin/plugin.json\"; mkdir -p \"\$(dirname \"\$f\")\"; printf '%b' '{}\\n' > \"\$f\""
  _c acusa "script solto em dois tempos (K4, verbatim)" Bash "bash docs/sbx.sh"
  _c acusa "script escrito e rodado na mesma string" Bash "cat > /tmp/sbx.sh <<'E'
printf x > ${H}
E
bash /tmp/sbx.sh"
  _c acusa "bash -c"                 Bash  "bash -c 'printf x > ${H}'"
  _c acusa "eval de texto em runtime, com o caminho e o verbo na linha" Bash "eval \"\$(cat /tmp/x) > ${H}\""
  _c acusa "Bash por symlink sem sinal no texto" Bash "printf x > docs/lnk-hooks/register.js"
  _c acusa "install, dd, curl -o e rsync literais: install" Bash "install -m 0644 ${d}/fora/payload ${H}"
  _c acusa "dd of="                  Bash  "dd if=${d}/fora/payload of=${H}"
  _c acusa "curl -o"                 Bash  "curl -sS -o ${H} https://exemplo.invalid/x"
  _c acusa "rsync para dentro"       Bash  "rsync -a ${d}/fora/payload ${H}"
  _c acusa "ln -s de pasta com plugin (S6)" Bash "ln -s ${d}/fora/ext .claude/skills/ext"
  _c acusa "cp -r de pasta com plugin" Bash "cp -r ${d}/fora/ext .claude/skills/"
  _c acusa "mv de pasta com plugin"  Bash  "mv ${d}/fora/ext .claude/skills/ext"
  # ── CALA: edição honesta, citação, leitura e remoção ──
  _c cala "Write em skills/onion/SKILL.md" Write "${p}/.claude/skills/onion/SKILL.md"
  _c cala "Edit em skills/onion/SKILL.md"  Edit  "${p}/.claude/skills/onion/SKILL.md"
  _c cala "Edit em .claude/hooks/x.sh"     Edit  "${p}/.claude/hooks/x.sh"
  _c cala "Edit em .claude/settings.json"  Edit  "${p}/.claude/settings.json"
  _c cala "Write em docs/a.md"             Write "${p}/docs/a.md"
  _c cala "Write em skill nomeada hooks"   Write "${p}/.claude/skills/hooks/SKILL.md"
  _c cala "Write fora do projeto"          Write "${d}/fora/hooks/h.js"
  _c cala "Bash > em .claude/hooks/x.sh"   Bash  "printf x > .claude/hooks/x.sh"
  _c cala "Bash > em docs, com o caminho no corpo" Bash "cat > docs/a.md <<'E'
o plugin mora em ${P} e em ${H}
E"
  _c cala "echo que cita"                  Bash  "echo ${P} ${H}"
  _c cala "echo que cita, redirecionado para docs" Bash "echo ${P} >> docs/a.md"
  _c cala "grep"                           Bash  "grep -rn '.claude-plugin' .claude/skills docs"
  _c cala "git log"                        Bash  "git log --oneline -- ${H}"
  _c cala "git commit -m"                  Bash  "git commit -m 'veto em ${H}'"
  _c cala "git add"                        Bash  "git add ${H}"
  _c cala "leitura: cat"                   Bash  "cat ${H}"
  _c cala "leitura: ls"                    Bash  "ls -la .claude/skills/x/hooks"
  _c cala "leitura: find -name"            Bash  "find .claude/skills -path '*/hooks/*' -type f"
  _c cala "leitura: cp do plugin para fora" Bash "cp ${H} /tmp/copia.json"
  _c cala "leitura: python3 -c open sem modo" Bash "python3 -c \"print(open('${H}').read())\""
  _c cala "python3 -c que só cita, escrevendo noutro lugar" Bash "python3 -c \"open('docs/a.md','w').write('${H}')\""
  _c cala "python3 heredoc que grava relatório citando" Bash "python3 - <<'EOF'
out = open('docs/a.md', 'w')
out.write('${H}')
EOF"
  _c cala "python3 heredoc com str.replace que cita .claude-plugin da raiz (replay)" Bash "python3 - <<'PY'
s = s.replace(old, 'docs/onion/federation-map.md .claude-plugin/marketplace.json')
PY"
  _c cala "python3 heredoc com str.replace que cita o caminho do alvo" Bash "python3 - <<'PY'
s = s.replace(old, '${H}')
PY"
  _c cala "python3 heredoc que grava .claude-plugin da raiz" Bash "python3 - <<'PY'
open('.claude-plugin/marketplace.json', 'w').write('x')
PY"
  _c cala "Write em .claude-plugin da raiz do repo" Write "${p}/.claude-plugin/marketplace.json"
  _c cala "Bash > em .claude-plugin da raiz do repo" Bash "printf x > .claude-plugin/marketplace.json"
  _c cala "remoção: rm"                    Bash  "rm -f ${H}"
  _c cala "remoção: rm -rf da pasta"       Bash  "rm -rf .claude/skills/x/hooks"
  _c cala "remoção: find -delete"          Bash  "find .claude/skills/x/hooks -type f -delete"
  _c cala "quarentena: mv do plugin para fora" Bash "mv .claude/skills/x/hooks /tmp/quarentena"
  _c cala "cp -r de pasta sem plugin para skills" Bash "cp -r ${d}/fora/vazia .claude/skills/nova"
  _c cala "crontab que cita: relógio não é desta guarda" Bash "crontab /tmp/tab; echo ${H}"
  _c cala "Bash > em skill nomeada hooks"  Bash  "printf x > .claude/skills/hooks/SKILL.md"
  _c cala "script solto que só cita"       Bash  "bash scratch/cita.sh"
  # ── TETO: não coberto, DECLARADO. Se um destes passar a barrar, o teto mudou e o cabeçalho tem de mudar junto ──
  _c TETO "script versionado (fronteira do juiz)" Bash "bash tools/w.sh"
  _c TETO "python3 x.py"                   Bash  "python3 scratch/qualquer.py"
  _c TETO "python3 -c com o caminho em variável" Bash "python3 -c \"p='${H}'
open(p,'w').write('x')\""
  _c TETO "base64 -d | sh"                 Bash  "echo cHJpbnRm | base64 -d | sh"
  _c TETO "git apply"                      Bash  "git apply /tmp/plugin.patch"
  _c TETO "tar -x na pasta de skills, conteúdo opaco" Bash "tar -xf /tmp/p.tar -C .claude/skills"
  _c TETO "nome calculado em runtime"      Bash  "cat > \"\$(cat /tmp/nome)\" <<'E'
{}
E"
  if [ "${fails}" -eq 0 ]; then echo "plugin-write-guard --selftest: OK"; exit 0; fi
  echo "plugin-write-guard --selftest: ${fails} falha(s)"; exit 1
fi

# ───────────────────────────── o veto ─────────────────────────────
input="$(cat)"
# shellcheck source=lib/invocation-lines.sh
. "${here}/lib/invocation-lines.sh"
tool="$(printf '%s' "${input}" | onion_json_string_field tool_name)" || tool=""

case "${tool}" in
  Write|Edit|NotebookEdit|MultiEdit)
    # caminho quente: sem python. Toda edição da casa passa aqui
    field=file_path; [ "${tool}" = NotebookEdit ] && field=notebook_path
    path="$(printf '%s' "${input}" | onion_json_string_field "${field}")" || exit 0
    hcwd="$(printf '%s' "${input}" | onion_json_string_field cwd)" || hcwd=""
    case "${path}" in
      *'\u'*) path="$(printf '%s' "${input}" | python3 -I -c 'import json,sys
ti=json.load(sys.stdin).get("tool_input") or {}
print(ti.get("file_path") or ti.get("notebook_path") or "")' 2>/dev/null)" || exit 0 ;;
    esac
    case "${path}" in
      "~/"*) path="${HOME:-}/${path#"~/"}" ;;
      /*) : ;;
      *) path="${hcwd:-${CLAUDE_PROJECT_DIR:-$PWD}}/${path}" ;;
    esac
    # como ESCRITO (normalizado) e RESOLVIDO: a skill que é link para fora só aparece na 1ª forma, o link em docs/ só na 2ª
    spelled="$(realpath -ms -- "${path}" 2>/dev/null)" || spelled="${path}"
    real="$(realpath -m -- "${path}" 2>/dev/null)" || real="${path}"
    if _pw_is_plugin_path "${spelled}" || _pw_is_plugin_path "${real}"; then
      _pw_deny "${tool} em ${path}"
    fi
    exit 0 ;;
  Bash) : ;;
  *) exit 0 ;;
esac

raw_cmd="$(printf '%s' "${input}" | onion_json_string_field command)" || raw_cmd="${input}"
flat="$(printf '%s' "${raw_cmd}" | tr -d "\"'\\\\")"

# ── pré-filtro sem python: SUPERCONJUNTO do que o juiz pode vetar ──────────────────────────────────
# (1) o sinal literal, em builtin de string (o `cd .claude/skills/x` e o `> hooks/h` podem vir em linhas diferentes);
# (2) cópia/link para dentro de skills (a pasta com a forma de plugin não traz o sinal no texto); (3) script não
# versionado, que o juiz lê; (4) symlink já no disco no caminho de um comando que escreve.
pw_write='(^|[^[:alnum:]_-])(rsync|cp|mv|install|tee|ln|dd|tar|sed|touch|mkdir|chmod|chown|curl|wget)([^[:alnum:]_-]|$)|>'
pw_script='(^|[;&|(`[:space:]])(bash|sh|zsh|dash|ksh|source|\.)[[:space:]]+[^-[:space:]]|\.sh([^[:alnum:]_]|$)|(^|[;&|(`[:space:]])\./|\|[[:space:]]*(ba|z|da|k)?sh([[:space:]]|$)'
hit=0
case "${flat}" in
  *.claude-plugin*) hit=1 ;;
  *skills*hooks*|*hooks*skills*) hit=1 ;;
  *skills*) grep -qE '(^|[^[:alnum:]_-])(cp|mv|ln|rsync)([^[:alnum:]_-]|$)' <<< "${flat}" && hit=1 ;;
esac
pw_unversioned_script() {
  local t d
  d="$(printf '%s' "${input}" | onion_json_string_field cwd)" || d=""
  [ -d "${d}" ] || d="${PWD}"
  grep -qE '\|[[:space:]]*(ba|z|da|k)?sh([[:space:]]|$)' <<< "${raw_cmd}" && return 0
  while IFS= read -r t; do
    [ -z "${t}" ] && continue
    case "${t}" in *'$'*|*'`'*|'~'*) return 0 ;; esac
    git -C "${d}" ls-files --error-unmatch -- "${t}" >/dev/null 2>&1 || return 0
  done < <(printf '%s\n' "${flat}" \
             | grep -oE '(^|[;&|(`[:space:]])(bash|sh|zsh|dash|ksh|source|\.)[[:space:]]+[^-[:space:];&|][^[:space:];&|]*|[^[:space:];&|<>]*\.sh([^[:alnum:]_]|$)|(^|[;&|(`[:space:]])\./[^[:space:];&|]*' \
             | sed -E 's/^[;&|(`[:space:]]*//; s/^(bash|sh|zsh|dash|ksh|source|\.)[[:space:]]+//; s/[^[:alnum:]_./~$`-]+$//')
  return 1
}
pw_cites_symlink() {
  local t c
  while IFS= read -r t; do
    t="${t%/}"; c="${t}"
    while [ -n "${c}" ] && [ "${c}" != "/" ] && [ "${c}" != "." ]; do
      [ -L "${c}" ] && return 0
      case "${c}" in */*) c="${c%/*}" ;; *) break ;; esac
    done
  done < <(grep -oE '(^|[[:space:]=])[^[:space:];&|<>=]*/[^[:space:];&|<>]*' <<< "${flat}" | sed -E 's/^[[:space:]=]+//' | head -n 64)
  return 1
}
[ "${hit}" = 0 ] && grep -qE "${pw_script}" <<< "${raw_cmd}" && pw_unversioned_script && hit=1
if [ "${hit}" = 0 ] && grep -qE "${pw_write}" <<< "${flat}"; then
  hcwd0="$(printf '%s' "${input}" | onion_json_string_field cwd)" || hcwd0=""
  ( [ -d "${hcwd0}" ] && cd "${hcwd0}" ; pw_cites_symlink ) && hit=1
fi
[ "${hit}" = 0 ] && exit 0

# ── leitura exata do JSON + juiz ──────────────────────────────────────────────────────
parsed="$(printf '%s' "${input}" | python3 -c 'import json,sys
sys.stdout.reconfigure(errors="backslashreplace")
try: d=json.load(sys.stdin)
except Exception: d={}
d=d if isinstance(d,dict) else {}
ti=d.get("tool_input"); ti=ti if isinstance(ti,dict) else {}
print(str(d.get("cwd") or "").replace("\n"," ")); print(str(ti.get("command") or ""))' 2>/dev/null)" && nopy=0 || nopy=1
hcwd="${parsed%%$'\n'*}"; cmd="${parsed#*$'\n'}"; [ "${cmd}" = "${parsed}" ] && cmd=""
if [ "${nopy}" = 1 ]; then
  hcwd="$(printf '%s' "${input}" | onion_json_string_field cwd)" || hcwd=""
  cmd="${raw_cmd}"
fi
[ -d "${hcwd}" ] || hcwd="${PWD}"
[ -z "${cmd}" ] && exit 0

_pw_closed() {  # SEM tokenizador: fecha SÓ o caminho inteiro junto de verbo de escrita; o resto cala (cláusula 4)
  grep -qE '\.claude/skills/[^[:space:]]*(\.claude-plugin|/hooks)(/|[[:space:]]|$)' <<< "${flat}" && grep -qE "${pw_write}" <<< "${flat}" || exit 0
  _pw_deny "$1, e o comando cita um caminho de plugin em .claude/skills junto de um verbo de escrita. Fechado por segurança"
}
[ "${nopy}" = 1 ] && _pw_closed "python3 ausente ou quebrado"
out="$(ONION_CWD="${hcwd}" ONION_MOAT_JUDGE="${here}/lib/plugin-write-judge.py" onion_invocation_lines "${cmd}")"
grep -qx '__ONION_MOAT_OK__' <<< "${out}" || _pw_closed "a análise não chegou ao fim"
line="$(printf '%s\n' "${out}" | grep -m1 '^__ONION_MOAT__' || true)"
[ -z "${line}" ] && exit 0
IFS=$'\t' read -r _ cls target _ detail <<< "${line}"
case "${cls}" in
  plugin) _pw_deny "${detail}" ;;
  *)      _pw_deny "comando que cita um caminho de plugin em .claude/skills e NÃO pode ser analisado com certeza (${detail}). Reescreva sem eval, xargs ou nome de comando em variável" ;;
esac
