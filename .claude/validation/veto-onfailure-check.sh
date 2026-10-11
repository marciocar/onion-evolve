#!/usr/bin/env bash
# =============================================================================
# veto-onfailure-check.sh — REGRA 101: veto PreToolUse por exit 2 declara `onFailure: "block"`
#
# O QUE   : todo hook `command` registrado em PreToolUse no `.claude/settings.json` cujo script
#           (`.claude/hooks/<x>.sh`) é um VETO — tem `exit 2` em linha de código, não em comentário —
#           declara `"onFailure": "block"`. Sem o campo, o hook que NÃO RODA (script ausente ou
#           renomeado, interpretador que não sobe, timeout, crash com código fora de 0/2) deixa a ação
#           passar: o veto falha ABERTO justamente quando quebra.
#
# DEFEITO DATADO (SAC-83, medido ao vivo em 2026-10-11, Claude Code 2.1.296, `claude -p` num sandbox
#           com `--setting-sources project,local`): um PreToolUse(Bash) apontando para um script que não
#           existe saiu 127 e o `touch` RODOU (arquivo criado); o mesmo hook com `onFailure: "block"`
#           barrou a chamada ("failed; blocking because onFailure is \"block\"") e o arquivo não nasceu.
#           Os três vetos do core estavam no primeiro regime desde que existem. O campo chegou no 2.1.295.
#
# O QUE ELA NÃO EXIGE, de propósito:
#   · hook de AVISO (sem `exit 2`, ex.: kg-read-leg.sh, que só injeta contexto) — `block` num aviso
#     transforma um índice quebrado em sessão travada; ali o desenho é falhar aberto. Um aviso COM
#     `block` sai como SOFT `aviso-com-block` (pede decisão, não reprova);
#   · hook `async`/`asyncRewake` — a doc diz que o campo não tem efeito em hook de fundo;
#   · outros eventos (UserPromptSubmit, PermissionRequest…) — só o PreToolUse e o PreModelSwitch foram
#     MEDIDOS. Teto declarado. O PostModelSwitch não veta nada (a troca já aconteceu) e fica de fora.
#
# EXTENSÃO AO PreModelSwitch (fix/vetos-fail-closed, medido ao vivo em 2026-10-11, Claude Code 2.1.296,
#           `claude -p "/model sonnet"` num sandbox com `--setting-sources project,local`): um PreModelSwitch
#           apontando para script inexistente saiu 127 e a troca FOI aplicada (o PostModelSwitch gravou o
#           marcador); com `onFailure: "block"` a troca foi barrada ("failed; blocking (onFailure: block)") e
#           o PostModelSwitch não rodou. A doc de hooks não lista o PreModelSwitch entre os eventos em que o
#           campo não tem efeito. O título da regra segue dizendo PreToolUse: é o nome que os documentos citam.
#   · script que o settings cita e não existe — é outro defeito, de outra guarda; aqui cala.
#   TETO DECLARADO (passada adversarial de 2026-10-11): não enxerga veto que sai por `exit "$rc"`, por
#   função de lib sourced, por `sys.exit(2)` de interpretador embutido, nem por JSON `permissionDecision:
#   deny` com exit 0; não varre settings.local.json nem hook fora de `.claude/hooks/*.sh`. Nenhum hook do
#   core cai nesses casos hoje; o detector é textual, não executa o script.
#
# COMPATIBILIDADE MEDIDA: o Claude Code 2.1.294 (anterior ao campo) IGNORA a chave em silêncio — o veto
# honesto (exit 2) continua barrando e o hook quebrado continua passando, como antes. Adotante com harness
# antigo não regride; só não ganha a proteção.
#
# USO     : veto-onfailure-check.sh [REPO] [--format text|tsv] | --selftest
#           ONION_SETTINGS_JSON=<arquivo> troca o settings lido (bancada).
# SAÍDA   : <SEV>\t<classe>\t<rel-settings>\t<msg>   classes: veto-sem-onfailure (HARD) ·
#           onfailure-invalido (HARD) · aviso-com-block (SOFT) · vazio = limpo
# RC      : 0 sempre que julgou (as linhas dizem o resto) · 2 = não pôde julgar (≠ aprovação)
# =============================================================================
set -uo pipefail
MODE="check"; FORMAT="text"; REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,36p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done

_scan() {
  local repo="$1" fmt="$2"
  local st="${ONION_SETTINGS_JSON:-${repo}/.claude/settings.json}"
  [ -f "${st}" ] || return 0
  command -v python3 >/dev/null 2>&1 || { echo "veto-onfailure-check: python3 ausente — não pude julgar" >&2; return 2; }
  python3 -I -B - "${repo}" "${st}" "${fmt}" <<'PY'
import json, os, re, sys
repo, st, fmt = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    d = json.load(open(st, encoding="utf-8"))
except Exception as e:
    sys.stderr.write(f"veto-onfailure-check: settings não parseia: {e}\n"); sys.exit(2)
rel = os.path.relpath(st, repo) if os.path.abspath(st).startswith(os.path.abspath(repo) + os.sep) else os.path.basename(st)
# `exit 2` como COMANDO: precedido de início, espaço, `;`, `&`, `|`, `{` ou `(`; seguido de fim ou separador.
VETO = re.compile(r'(?:^|[\s;&|{(])exit[ \t]+2(?=$|[\s;&|})#])')
def is_veto(path):
    try:
        txt = open(path, encoding="utf-8", errors="surrogateescape").read()
    except Exception:
        return None
    for line in txt.splitlines():
        s = line.lstrip()
        if not s or s.startswith("#"):
            continue
        # aspas fora ANTES do corte: `echo 'use exit 2'` não é veto, e `echo "a #b"; exit 2` é (passada adversarial)
        code = re.sub(r"'[^']*'|\"(?:\\.|[^\"\\])*\"", "''", line)
        code = re.split(r'\s#', code, maxsplit=1)[0]   # corta comentário de fim de linha (aproximação)
        if VETO.search(code):
            return True
    return False
rows = []
hooks = d.get("hooks") if isinstance(d, dict) else None
EVENTS = ("PreToolUse", "PreModelSwitch")   # os dois MEDIDOS ao vivo; o resto é teto declarado
for ev, grp in [(e, g) for e in EVENTS for g in ((hooks or {}).get(e) or [])]:
    for hk in (grp.get("hooks") or []) if isinstance(grp, dict) else []:
        if not isinstance(hk, dict) or hk.get("type", "command") != "command":
            continue
        cmd = str(hk.get("command") or "")
        m = re.search(r'\.claude/hooks/([A-Za-z0-9_.-]+\.sh)', cmd)
        if not m:
            continue
        name = m.group(1)
        of = hk.get("onFailure")
        if of is not None and of not in ("continue", "block"):
            rows.append(("HARD", "onfailure-invalido", rel, f"{ev}/{name}: onFailure={of!r} — a doc aceita só \"continue\" ou \"block\""))
            continue
        if hk.get("async") or hk.get("asyncRewake"):
            continue
        v = is_veto(os.path.join(repo, ".claude", "hooks", name))
        if v is None:
            continue
        if v and of != "block":
            rows.append(("HARD", "veto-sem-onfailure", rel, f"{ev}/{name} veta por exit 2 e não declara \"onFailure\": \"block\" — se o hook não rodar (script ausente, timeout, crash), a ação PASSA; acrescente \"onFailure\": \"block\" ao hook"))
        elif (not v) and of == "block":
            rows.append(("SOFT", "aviso-com-block", rel, f"{ev}/{name} não veta (sem exit 2) e declara onFailure: block — se ele quebrar, TODA chamada do matcher fica barrada; confirme que é isso que se quer"))
for r in rows:
    print("\t".join(r) if fmt == "tsv" else f"{r[0]} [{r[1]}] {r[2]}: {r[3]}")
PY
}

_selftest() {
  local tmp total=0 fails=0 out rc
  tmp="$(mktemp -d)"; mkdir -p "${tmp}/.claude/hooks"
  printf '#!/usr/bin/env bash\n# comentário: exit 2 aqui não conta\n[ -n "$x" ] && { echo no >&2; exit 2; }\nexit 0\n' > "${tmp}/.claude/hooks/veto.sh"
  printf '#!/usr/bin/env bash\n# aviso: nunca exit 2\necho "{}"\ntrue  # o bloco abaixo não faz exit 2\nexit 0\n' > "${tmp}/.claude/hooks/aviso.sh"
  printf '#!/usr/bin/env bash\ndeny() { echo x >&2; exit 2; }  # (core-only)\ndeny\n' > "${tmp}/.claude/hooks/fn.sh"
  printf '#!/usr/bin/env bash\necho "exit 20 é outro código"; exit 20\n' > "${tmp}/.claude/hooks/vinte.sh"
  _w() { printf '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[%s]}]}}\n' "$1" > "${tmp}/.claude/settings.json"; }
  _h() { printf '{"type":"command","command":"bash \\"$CLAUDE_PROJECT_DIR/.claude/hooks/%s\\""%s}' "$1" "${2:-}"; }
  _run() { total=$((total+1)); out="$(bash "$0" "${tmp}" --format tsv 2>&1)"; rc=$?; }
  _ok() { echo "  ✅ $1"; }
  _ko() { echo "  ✗ $1"; fails=$((fails+1)); }

  # (i) o defeito do SAC-83: veto sem onFailure => HARD
  _w "$(_h veto.sh)"; _run
  if [ "${rc}" -eq 0 ] && grep -q $'^HARD\tveto-sem-onfailure\t.*veto.sh' <<< "${out}"; then _ok "(i) veto sem onFailure acusa"; else _ko "(i) veto sem onFailure acusa"; fi
  # (ii) a cura: veto com onFailure block => limpo
  _w "$(_h veto.sh ',"onFailure":"block"')"; _run
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "(ii) veto com block cala"; else _ko "(ii) veto com block cala"; fi
  # (iii) aviso sem block => limpo; exit 2 SÓ em comentário não faz veto
  _w "$(_h aviso.sh)"; _run
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "(iii) aviso sem block cala (exit 2 em comentário, de linha ou de fim de linha, não conta)"; else _ko "(iii) aviso sem block cala (exit 2 em comentário, de linha ou de fim de linha, não conta)"; fi
  # (iv) aviso com block => SOFT, nunca HARD
  _w "$(_h aviso.sh ',"onFailure":"block"')"; _run
  if grep -q $'^SOFT\taviso-com-block' <<< "${out}" && ! grep -q '^HARD' <<< "${out}"; then _ok "(iv) aviso com block é SOFT"; else _ko "(iv) aviso com block é SOFT"; fi
  # (v) exit 2 dentro de função com comentário de fim de linha (forma do merge-gate) => veto
  _w "$(_h fn.sh ',"onFailure":"continue"')"; _run
  if grep -q $'^HARD\tveto-sem-onfailure\t.*fn.sh' <<< "${out}"; then _ok "(v) exit 2 em função + continue explícito acusa"; else _ko "(v) exit 2 em função + continue explícito acusa"; fi
  # (vi) `exit 20` não é exit 2
  _w "$(_h vinte.sh)"; _run
  if [ -z "${out}" ]; then _ok "(vi) exit 20 não é veto"; else _ko "(vi) exit 20 não é veto"; fi
  # (vii) valor inválido => HARD
  _w "$(_h veto.sh ',"onFailure":"deny"')"; _run
  if grep -q $'^HARD\tonfailure-invalido' <<< "${out}"; then _ok "(vii) onFailure inválido acusa"; else _ko "(vii) onFailure inválido acusa"; fi
  # (viii) hook async é isento (a doc: sem efeito em hook de fundo)
  _w "$(_h veto.sh ',"async":true')"; _run
  if [ -z "${out}" ]; then _ok "(viii) hook async isento"; else _ko "(viii) hook async isento"; fi
  # (ix) script ausente cala aqui (outra guarda); settings que não parseia => rc 2, nunca aprovação
  _w "$(_h nao-existe.sh)"; _run
  if [ -z "${out}" ]; then _ok "(ix) script ausente cala"; else _ko "(ix) script ausente cala"; fi
  printf '{nao json' > "${tmp}/.claude/settings.json"; _run
  if [ "${rc}" -eq 2 ]; then _ok "(x) settings ilegível sai 2 (não julgou)"; else _ko "(x) settings ilegível sai 2 (não julgou)"; fi
  # (xi) veto em OUTRO evento não é cobrado (teto declarado: só PreToolUse e PreModelSwitch foram medidos)
  printf '{"hooks":{"UserPromptSubmit":[{"hooks":[%s]}]}}\n' "$(_h veto.sh)" > "${tmp}/.claude/settings.json"; _run
  if [ -z "${out}" ]; then _ok "(xi) fora do PreToolUse cala"; else _ko "(xi) fora do PreToolUse cala"; fi
  # (xii) `exit 2` dentro de aspas num aviso não é veto (falso positivo achado na passada adversarial)
  printf '#!/usr/bin/env bash\necho '"'"'use exit 2 para vetar'"'"'\necho "ou exit 2"\nexit 0\n' > "${tmp}/.claude/hooks/aspas.sh"
  _w "$(_h aspas.sh)"; _run
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "(xii) exit 2 entre aspas não é veto"; else _ko "(xii) exit 2 entre aspas não é veto"; fi
  # (xiii) `#` dentro de aspas não esconde o exit 2 que vem depois (falso negativo achado na mesma passada)
  printf '#!/usr/bin/env bash\necho "a #b"; exit 2\n' > "${tmp}/.claude/hooks/hash.sh"
  _w "$(_h hash.sh)"; _run
  if grep -q $'^HARD\tveto-sem-onfailure\t.*hash.sh' <<< "${out}"; then _ok "(xiii) # entre aspas não esconde o exit 2"; else _ko "(xiii) # entre aspas não esconde o exit 2"; fi

  # (xiv) veto no PreModelSwitch sem block acusa; com block cala (extensão medida em 2026-10-11)
  printf '{"hooks":{"PreModelSwitch":[{"hooks":[%s]}],"PostModelSwitch":[{"hooks":[%s]}]}}\n' "$(_h veto.sh)" "$(_h veto.sh)" > "${tmp}/.claude/settings.json"; _run
  if [ "${rc}" -eq 0 ] && grep -q $'^HARD\tveto-sem-onfailure\t.*PreModelSwitch/veto.sh' <<< "${out}" && [ "$(grep -c . <<< "${out}")" -eq 1 ]; then
    printf '{"hooks":{"PreModelSwitch":[{"hooks":[%s]}]}}\n' "$(_h veto.sh ',"onFailure":"block"')" > "${tmp}/.claude/settings.json"; _run
    if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "(xiv) PreModelSwitch: veto sem block acusa, com block cala, PostModelSwitch fora"; else _ko "(xiv) PreModelSwitch: veto sem block acusa, com block cala, PostModelSwitch fora"; fi
  else _ko "(xiv) PreModelSwitch: veto sem block acusa, com block cala, PostModelSwitch fora"; fi

  rm -rf "${tmp}"; echo "  selftest: $((total-fails))/${total} verdes"
  [ "${fails}" -eq 0 ] && return 0 || return 1
}

case "${MODE}" in
  selftest) _selftest ;;
  *) [ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; _scan "${REPO}" "${FORMAT}" ;;
esac
