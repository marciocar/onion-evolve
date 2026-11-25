#!/usr/bin/env bash
# PreToolUse(Bash) — ESPELHO DO DENY: os atos irreversíveis que só o `permissions.deny` cobria passam a ter veto por hook
# (exit 2 = antes de executar), independente do deny. SAC-551, Q_DENY_SEGURA_EM_BYPASS_1125 (radar E3, rodada 28).
#
# ── O DEFEITO MEDIDO (2026-11-25) ─────────────────────────────────────────────────────────────────────────
# O deny da casa não segura em `bypassPermissions` sob certas formas de comando Bash (medido no motor real em 2.1.330,
# 2.1.331 e 2.1.332; a reprodução fica no registro privado do core). Um push de sonda chegou ao origin. A medição desta
# forja, com todos os hooks PreToolUse de Bash do settings.json contra as formas do deny, achou ABERTO por hook:
# `git filter-branch`/`filter-repo`, `rm -r` da raiz, da home e do `.git`, `gh repo delete` (o MOAT cobre release e
# visibilidade só no core), e, por `eval` literal, o force-push fora da main e o `git clean -fdx`. O force-push e o
# clean seguem com o dono deles (pretooluse-protect-main.sh); o `eval` literal foi curado na lib, uma vez para todos.
#
# ── O QUE VETA ────────────────────────────────────────────────────────────────────────────────────────────
#  · `git filter-branch` e `git filter-repo` (reescrevem a história inteira), em qualquer pasta;
#  · `rm` recursivo (`-r`, `-R`, `--recursive`, em qualquer cluster) cujo alvo é `/`, `/*`, a home (`~`, `$HOME`,
#    `${HOME:?}`, `~user`, o caminho, normalizado) com ou sem `/*`, ou o `.git` do projeto ou do diretório onde a sessão
#    está (o cwd do hook, o CLAUDE_PROJECT_DIR, o topo git). Depois de um `cd` que a lib não segue, o `.git` só passa
#    quando a própria string cria a pasta (mkdir, git init/clone, cp -r, tar -x: a fixture de rascunho);
#  · `gh repo delete`, `gh release delete` e `gh repo edit … --visibility`;
#  · o que a lib não prova (`eval` com variável, função opaca) e tem a FORMA de um desses atos com alvo literal.
# Vale pela linha de invocação da lib (lib/invocation-lines.sh): heredoc sem aspas, crase, `$(…)`, `eval` literal,
# `bash -c`, `env`, `command` e afins são seguidos; heredoc com aspas e texto que só CITA o vocabulário passam.
#
# ── O QUE NÃO VETA (fronteira declarada, guard-doctrine «A camada nativa») ──────────────────────────────────
#  · o que a casa faz todo dia: `reset --hard`, `branch -D`, `--force-with-lease` de branch de trabalho, `rm -rf` de
#    pasta de trabalho, `rm -rf "$tmp"` (alvo dinâmico não se prova perigoso: passa);
#  · apagar branch remota de trabalho (`git push origin --delete feat/x`: o merge verificado manda fazê-lo); apagar a
#    MAIN remota já é vetado pelo merge-gate (push com alvo main);
#  · `eval "$X"` com o texto inteiro opaco, script em arquivo (`bash x.sh`), outra linguagem (python/perl): análise
#    estática não fecha indireção arbitrária. Não é fronteira de segurança: é camada de conformidade.
# Escape: o maestro roda fora da sessão (`!` no prompt). Não há variável de bypass por desenho.
input=$(cat)
parsed=$(printf '%s' "$input" | python3 -I -c 'import json,sys
sys.stdout.reconfigure(errors="backslashreplace")
d=json.load(sys.stdin)
d=d if isinstance(d,dict) else {}
ti=d.get("tool_input"); ti=ti if isinstance(ti,dict) else {}
print(str(d.get("cwd") or "").replace("\n"," ")); print(str(ti.get("command") or ""))' 2>/dev/null) && nopy=0 || nopy=1
hcwd=${parsed%%$'\n'*}; cmd=${parsed#*$'\n'}; [ "$cmd" = "$parsed" ] && cmd=""
# shellcheck source=lib/invocation-lines.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/invocation-lines.sh"
if [ "$nopy" = 1 ]; then
  hcwd=$(printf '%s' "$input" | onion_json_string_field cwd) || hcwd=""
  cmd=$(printf '%s' "$input" | onion_json_string_field command) || cmd="$input"
fi
[ -d "$hcwd" ] || hcwd=$PWD
[ -z "$cmd" ] && exit 0
MSG="GUARDA-PRETOOLUSE (espelho do deny): ato irreversível negado — reescrever a história (filter-branch/filter-repo), apagar a raiz, a home ou um .git com rm recursivo, apagar repo ou release, ou mudar a visibilidade do repo. O deny nativo não segura toda forma em bypassPermissions (SAC-551); se for deliberado, o maestro roda fora da sessão."
# SEM python3 não há tokenizador: fecha pela FORMA do texto cru (aspas e `\` tiradas). Errar aqui só pode fechar.
if [ "$nopy" = 1 ]; then
  flat=$(printf '%s' "$cmd" | tr -d "\"'\\\\")
  if grep -qE '(^|[^[:alnum:]_-])git([[:space:]]+[^;&|[:space:]]+)*[[:space:]]+filter-(branch|repo)([^[:alnum:]-]|$)|(^|[^[:alnum:]_-])gh[[:space:]]+(repo[[:space:]]+delete|release[[:space:]]+delete|repo[[:space:]]+edit[^;&|]*--visibility)|(^|[^[:alnum:]_-])rm[[:space:]][^;&|]*(-[[:alnum:]]*[rR]|--recursive)[^;&|]*[[:space:]](/|/\*|~/?\*?|\$\{?HOME\}?/?\*?|[^[:space:];&|]*\.git/?)([[:space:];&|]|$)' <<< "$flat"; then
    echo "$MSG A análise não rodou (python3 ausente ou JSON ilegível): fechado pela forma." >&2
    exit 2
  fi
  exit 0
fi
inv=$(ONION_DENY_MIRROR=1 ONION_CWD="$hcwd" onion_invocation_lines "$cmd")
top=$(git -C "$hcwd" rev-parse --show-toplevel 2>/dev/null || true)
[ -z "$inv" ] && exit 0
# o juiz lê as linhas canônicas da lib; o inanalisável é re-partido em comandos e julgado com os alvos LITERAIS que tiver
if printf '%s\n' "$inv" | HOME_DIR="${HOME:-}" RAW_CMD="$cmd" ROOTS="${CLAUDE_PROJECT_DIR:-}"$'\n'"$hcwd"$'\n'"$top" python3 -I -c '
import os, re, shlex, sys
home = os.environ.get("HOME_DIR", "").rstrip("/")
# o .git que o deny guarda é o do PROJETO (raiz do CLAUDE_PROJECT_DIR, cwd do hook e o topo git dele); o .git de uma cópia
# de trabalho num rascunho (`cd $S/fixture && rm -rf .git`, `rm -rf repo/.git`) é rotina honesta (corpus, 2026-11-25)
ROOTS = {os.path.realpath(r) for r in os.environ.get("ROOTS", "").split("\n") if r.strip()}
UNKNOWN = "__ONION_UNKNOWN_DIR__"
CREATES = bool(re.search(r"(^|[\s;&|(])(mkdir|git\s+(-[^\s]+\s+)*(init|clone)|cp\s+-[A-Za-z]*[rRa]|tar\s+-?[A-Za-z]*x|unzip|rsync)\b",
                         os.environ.get("RAW_CMD", "")))
DANGER = {"/", "/*", "~", "~/", "~/*", "$HOME", "${HOME}", "$HOME/", "${HOME}/", "$HOME/*", "${HOME}/*"}
def norm(t):
    """`${HOME:?…}`/`${HOME:-…}` são $HOME; `~user` e `~` expandem; `//x//y`, `/./`, `..` normalizam (refutador, L1)."""
    t = re.sub(r"\$\{HOME:[?=+-][^}]*\}", "$HOME", t)
    t = re.sub(r"^(\$HOME|\$\{HOME\})(?=/|$)", home or "$HOME", t)
    if t.startswith("~"):
        t = os.path.expanduser(t)
    if t.startswith("/"):
        star = t.endswith("/*")
        b = os.path.normpath(t[:-2] if star else t)
        b = "/" + b.lstrip("/")
        return (b.rstrip("/") + "/*") if star else b
    return t
def rm_bad(w, where=""):
    rec, end, targets = False, False, []
    for t in w[1:]:
        if not end and t == "--":
            end = True; continue
        if not end and t.startswith("--"):
            rec = rec or t == "--recursive"; continue
        if not end and t.startswith("-") and len(t) > 1:
            rec = rec or bool(re.search(r"[rR]", t[1:])); continue
        targets.append(t)
    if not rec:
        return False
    for t in targets:
        n = t if t in ("/", "/*") else t.rstrip("/") or "/"
        m = norm(t)
        if t in DANGER or n in DANGER or m in ("/", "/*") or (home and m in (home, home + "/*")):
            return True
        if n == ".git" or n.endswith("/.git"):
            # `cd` que a lib não segue (variável, pasta criada na própria string: `mkdir -p w && cd w`) ou caminho dinâmico:
            # não se prova que é o .git do projeto, e o corpus mostrou que é a cópia de trabalho de um rascunho. Passa (teto)
            if re.search(r"[$`]", n):
                continue
            if where == UNKNOWN:
                # `cd` que a lib não segue: só passa se a própria string CRIA a pasta antes (fixture de rascunho:
                # mkdir, git init/clone, cp -r, tar -x). `ls && cd . && rm -rf .git` vetava pelo deny e escapava aqui
                # (refutador isolado, B1)
                if not CREATES:
                    return True
                continue
            if not where and not os.path.isabs(n):
                return True
            full = n if os.path.isabs(n) else os.path.join(where, n)
            if os.path.realpath(os.path.dirname(os.path.normpath(full))) in ROOTS:
                return True
    return False
def bad(w, where=""):
    if not w:
        return False
    b = os.path.basename(w[0])
    if b == "git":
        # o SUBCOMANDO é a 1ª palavra depois das opções globais: `filter-repo` dentro da mensagem de um commit é texto
        k = 1
        while k < len(w) and w[k].startswith("-"):
            k += 2 if w[k] in ("-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix") else 1
        return k < len(w) and w[k] in ("filter-branch", "filter-repo") and not any(x in ("--help", "-h") for x in w[k + 1:])
    if b == "gh":
        r = [x for x in w[1:] if not x.startswith("-")]
        return r[:2] in (["repo", "delete"], ["release", "delete"]) or (r[:2] == ["repo", "edit"] and any(x.startswith("--visibility") for x in w))
    if b == "rm":
        return rm_bad(w, where)
    return False
hit = False
for line in sys.stdin:
    line = line.rstrip("\n")
    if line.startswith("__ONION_UNANALYZABLE__"):
        text = line.split(" :: ", 1)[1] if " :: " in line else ""
        for part in re.split(r"[;&|\n]+", text):
            try:
                w = shlex.split(part)
            except ValueError:
                w = part.split()
            while w and w[0] in ("eval", "command", "builtin", "exec", "env", "sudo", "nohup", "time"):
                w = w[1:]
            if bad(w):
                hit = True
        continue
    where = ""
    if line.startswith("rm ") and " #ONION_DIR=" in line:
        line, d = line.rsplit(" #ONION_DIR=", 1)
        try:
            where = (shlex.split(d) or [""])[0]
        except ValueError:
            where = UNKNOWN
    try:
        w = shlex.split(line)
    except ValueError:
        w = line.split()
    if bad(w, where):
        hit = True
sys.exit(0 if hit else 1)
'; then
  echo "$MSG" >&2
  exit 2
fi
exit 0
