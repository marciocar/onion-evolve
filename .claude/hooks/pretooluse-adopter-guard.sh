#!/usr/bin/env bash
# PreToolUse(Bash|Write|Edit|NotebookEdit) — o veto de ESCRITA EM REPO ALHEIO no ADOTANTE (2026-11-05, REGRA 118).
#
# ── O BURACO QUE FECHA (medido, não suposto) ──────────────────────────────────────────────────────────
# A invariante I3 diz que cada sessão escreve só no próprio repo. No core ela é o ramo `alheio` do
# pretooluse-moat-gate.sh, que lê ops/moat-targets.tsv (core-only) e o members.yaml (core-only) — e sai cedo
# sem eles. Nenhum dos dois viaja na adoção, então no adotante NADA julgava escrita fora do projeto. Medido
# pela curadoria em 2026-11-05 (31 formas, os 5 hooks, cwd no repo dela): `git -C <core> commit -m x`,
# `git -C <core> push origin main`, `echo x > <core>/NOTE.md`, `git -C <outro adotante> push …` e o Write e o
# Edit no core e em outro adotante passaram todos com exit 0. E nenhum veto tinha Write ou Edit no matcher.
#
# ── O QUE VETA (exit 2 = antes de executar) ───────────────────────────────────────────────────────────
#  Bash  · git que escreve (commit, push, merge, reset, rebase, checkout, stash, tag, branch, config…) num
#          repo REGISTRADO que não é este projeto, e escrita de shell (redirecionamento, tee, cp, mv, rm, touch,
#          sed -i…) num caminho dentro dele. O juiz é lib/adopter-judge.py, dentro do tokenizador dos vetos
#          (lib/invocation-lines.sh): heredoc, echo e prosa que CITAM o caminho não vetam; `bash -c`, `$(…)`,
#          `cd` literal, `git -C`, `--git-dir` e invólucros são seguidos.
#  Write/Edit/NotebookEdit · o arquivo dentro de um repo registrado alheio (o mesmo git-common-dir, então as
#          worktrees dele também).
#  E os arquivos que ARMAM a guarda: a lista (.claude/adopter-guard.tsv) e o carimbo (.claude/.onion-version, cujo
#  `role:` arma os dois vetos). Quem os escreve é o maestro, fora da sessão, ou o update do Onion (git merge e o
#  write-stamp.sh, que o hook não julga). Apagar ou mover o pai deles (`rm -rf .claude`, `mv .claude …`) e o
#  `git rm`/`git mv`/`git checkout -- <carimbo>` também vetam; `git clean -fdx .claude` não é visto (teto).
#  "Registrado" e "este projeto" vêm da lib/adopter-scope.sh: o core local, os `local_path` do members.yaml
#  dele e as linhas `repo` do arquivo local; o próprio projeto e as worktrees dele nunca são alheios.
#
# ── O QUE NÃO VETA (fronteira declarada) ──────────────────────────────────────────────────────────────
#  · Fora do adotante (sem carimbo `role: adopted|hub|standalone`, ou com `kind: door`): o core tem o moat-gate, e porta ou repo
#    sem carimbo não têm lista. O hook sai 0 sem ler nada.
#  · Adotante sem lista resolvida (nem `core` no arquivo local, nem `adopted_from` local, nem `repo`): cala; a
#    REGRA 118 avisa que o veto está sem lista. Calar é o lado certo (cláusula 4 da guard-doctrine).
#  · Leitura em repo alheio (git log/show/diff/fetch/status, cat, grep, Read).
#  · Script em arquivo: `bash .claude/utils/co-evolution/co-relay.sh` entrega no inbox do core SEM commit, e
#    `bash <core>/ops/pr-merge-verified.sh` (core-only) é o merge verificado do adotante — os dois passam.
#  · A camada nativa vem primeiro: o `permissions.deny` do adotante (a curadoria instalou o dela em 2026-11-05, com
#    o selo do maestro) barra por prefixo `git -C <alheio>`, `--git-dir=`, `--work-tree=` e o push na main por refspec.
#    Este hook é a SEGUNDA linha e cobre o que o deny não alcança: `cd <alheio> && git …`, `GIT_DIR=` no prefixo,
#    `sh -c`/`bash -c`, python -c, a worktree do repo alheio fora do diretório dele, o redirecionamento e a escrita
#    de shell (o `gh api …/merge` é do merge-gate). A sobreposição em `git -C` é de propósito: o deny é por adotante,
#    e quem não o instalou fica só com o hook.
#  · Teto de vocabulário (refutador, 2026-11-05): tar -C/-x, unzip -d, perl -pi, sort -o, curl -o, wget -O, patch -d,
#    awk -i inplace, rsync --remove-source-files, mktemp em repo alheio e find -delete passam; repo registrado com
#    nome de menos de 4 letras por caminho relativo (`cd ../abc`) escapa do pré-filtro; leitura em python -c com
#    `.replace(`/`.remove(` de string fecha como opaco (falso positivo raro: 0 no replay).
#  · Teto da 2ª passada (refutador independente, 2026-11-06): brace e glob no caminho (`cor[e]`, `rep{o,}a`, `co*`),
#    variável e substituição no NOME do repo (`R=co; …${R}re`, `"$(ls -d …)"`) — o pré-filtro procura o nome
#    literal e não o acha —, `find … -exec sh -c '…"$1"' _ {}`, python em ARQUIVO, e a remoção do próprio hook ou a
#    edição do settings.json do adotante passam. O python -c que cita um repo registrado com um verbo de escrita do
#    git (`subprocess.run(['git','-C',<core>,'commit'])`, `os.chdir(<core>); os.system('git commit')`) FECHA. O heredoc sem terminador que cita push ou merge FECHA (era aviso; no adotante, veto).
#  · Escape = o maestro roda fora da sessão (`!` no prompt). Não há variável de bypass por desenho.
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
here="$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=lib/adopter-scope.sh
. "${here}/lib/adopter-scope.sh"
onion_adopter_role "$root" >/dev/null || exit 0
repos="$(onion_adopter_repos "$root")"
selftsv="${root%/}/${ONION_ADOPTER_TSV_REL}"
stamp="${root%/}/.claude/.onion-version"   # o carimbo arma as duas guardas: uma edição no `role:` desarmava tudo
# shellcheck source=lib/invocation-lines.sh
. "${here}/lib/invocation-lines.sh"

# ── leitura do JSON (python; sem ele, o leitor de forma da lib) ─────────────────────────────────────────
# JSON ilegível NÃO vira `{}`: comando vazio é exit 0, e a falha de análise viraria permissão.
parsed=$(printf '%s' "$input" | python3 -I -c 'import json,sys
sys.stdout.reconfigure(errors="backslashreplace")
d=json.load(sys.stdin)
d=d if isinstance(d,dict) else {}
ti=d.get("tool_input"); ti=ti if isinstance(ti,dict) else {}
one=lambda v: str(v or "").replace("\n"," ")
print(one(d.get("tool_name"))); print(one(d.get("cwd"))); print(one(ti.get("file_path") or ti.get("notebook_path")))
print(str(ti.get("command") or ""))' 2>/dev/null) && nopy=0 || nopy=1
if [ "$nopy" = 0 ]; then
  tool=${parsed%%$'\n'*}; parsed=${parsed#*$'\n'}
  hcwd=${parsed%%$'\n'*}; parsed=${parsed#*$'\n'}
  fpath=${parsed%%$'\n'*}; cmd=${parsed#*$'\n'}; [ "$cmd" = "$fpath" ] && cmd=""
else
  tool=$(printf '%s' "$input" | onion_json_string_field tool_name) || tool=""
  hcwd=$(printf '%s' "$input" | onion_json_string_field cwd) || hcwd=""
  fpath=$(printf '%s' "$input" | onion_json_string_field file_path) \
    || fpath=$(printf '%s' "$input" | onion_json_string_field notebook_path) || fpath=""
  cmd=$(printf '%s' "$input" | onion_json_string_field command) || cmd=""
  [ -z "$tool" ] && [ -z "$fpath" ] && [ -z "$cmd" ] && cmd="$input"   # nem o campo: julga o JSON cru
fi
[ -d "$hcwd" ] || hcwd=$PWD

deny() {
  echo "GUARDA-PRETOOLUSE (adotante/repo alheio): $2 — ${1} é um repo registrado e não é este projeto (I3: a sessão do adotante escreve só no próprio repo; o host não protege a main dele). Negado. O que deve mudar no core vai como sinal pelo /meta:co-relay (entrega no inbox dele, sem commit); o resto é da sessão daquele repo, ou do maestro, fora da sessão (\`!\` no prompt)." >&2
  exit 2
}
deny_list() {
  echo "GUARDA-PRETOOLUSE (adotante/lista de repos): $1 — ${ONION_ADOPTER_TSV_REL} (a lista do que é repo alheio) e .claude/.onion-version (o carimbo, cujo papel arma os vetos) são escritos pelo maestro, fora da sessão (\`!\` no prompt), ou pelo update do Onion (git merge, write-stamp.sh). Negado." >&2
  exit 2
}
_common() {  # <caminho> → git-common-dir real do repo que o contém (ancestral existente mais próximo), ou vazio
  local d="$1" c
  while [ -n "$d" ] && [ ! -d "$d" ]; do d="${d%/*}"; done
  [ -n "$d" ] || return 0
  c="$(git -c core.fsmonitor=false -C "$d" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
  [ -n "$c" ] && realpath -m -- "$c" 2>/dev/null
}

# ── Write / Edit / NotebookEdit: o caminho ─────────────────────────────────────────────────────────────
case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    [ -n "$fpath" ] || exit 0
    case "$fpath" in /*) p="$fpath" ;; "~/"*) p="${HOME}/${fpath#"~/"}" ;; *) p="${hcwd%/}/${fpath}" ;; esac
    p="$(realpath -m -- "$p" 2>/dev/null)" || p=""
    [ -n "$p" ] || exit 0
    [ "$p" = "$(realpath -m -- "$selftsv" 2>/dev/null)" ] && deny_list "${tool} em ${fpath}"
    [ "$p" = "$(realpath -m -- "$stamp" 2>/dev/null)" ] && deny_list "${tool} em ${fpath}"
    [ -n "$repos" ] || exit 0
    rr="$(realpath -m -- "$root" 2>/dev/null)"
    case "$p" in "$rr"|"$rr"/*) exit 0 ;; esac          # o próprio projeto: o caminho quente, sem git
    while IFS= read -r a; do
      [ -n "$a" ] || continue; a="$(realpath -m -- "$a" 2>/dev/null)"
      case "$p" in "$a"|"$a"/*) exit 0 ;; esac
    done < <(onion_adopter_allows "$root")
    c="$(_common "$p")"; [ -n "$c" ] || exit 0
    [ "$c" = "$(_common "$rr")" ] && exit 0               # worktree deste projeto fora da raiz
    while IFS= read -r r; do
      [ -d "$r" ] || continue
      if [ "$(_common "$(realpath -m -- "$r")")" = "$c" ]; then   # nomeia o repo pelo caminho (a worktree, o clone)
        d="$p"; while [ -n "$d" ] && [ ! -d "$d" ]; do d="${d%/*}"; done
        deny "$(git -c core.fsmonitor=false -C "$d" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$r")" "${tool} em ${fpath}"
      fi
    done <<< "$repos"
    exit 0 ;;
esac
[ -z "$cmd" ] && exit 0

# ── Bash: pré-filtro sem python (o caminho quente) ─────────────────────────────────────────────────────
# SUPERCONJUNTO do que o juiz pode vetar: o comando cita um repo registrado (caminho, `~/…` ou o nome do
# diretório, que pega `cd ../x` e `$HOME/x`), roda num cwd FORA do projeto, troca o repositório por
# `--git-dir`/`GIT_DIR`, ou cita o arquivo da lista. Fora disso o juiz não teria o que ver.
flat=$(printf '%s' "$cmd" | tr -d "\"'\\\\")
rr="$(realpath -m -- "$root" 2>/dev/null)"
allows="$(onion_adopter_allows "$root")"
# o próprio projeto (o registro o lista) e os `allow` não entram no sinal: o nome do próprio repo está em todo comando
# um awk só: a 1ª redação abria um grep por repo registrado (28 nesta máquina) e custava ~60 ms a mais por comando
signal=$(RR="$rr" ROOT="$root" ALLOWS="$allows" awk '
    BEGIN { n = split(ENVIRON["ALLOWS"], A, "\n"); for (i = 1; i <= n; i++) al[A[i]] = 1
            print "adopter-guard.tsv"; print ".onion-version"; print "GIT_DIR"; print "--git-dir"; print "GIT_WORK_TREE"; print "--work-tree" }
    NF && $0 != ENVIRON["RR"] && $0 != ENVIRON["ROOT"] && !($0 in al) {
            print; b = $0; sub(/.*\//, "", b); if (length(b) >= 4) print b }' <<< "$repos" \
          | sed 's/[][\.*^$+?(){}|/]/\\&/g' | sort -u | paste -sd'|' -)
hit=0
grep -qE -- "$signal" <<< "$flat" && hit=1
if [ "$hit" = 0 ] && [ -n "$repos" ]; then
  hc="$(realpath -m -- "$hcwd" 2>/dev/null)"
  case "$hc" in "$rr"|"$rr"/*) : ;; *) hit=1 ;; esac
fi
# apagar ou mover o .claude (o pai do carimbo) derruba as duas guardas: vai ao juiz sem citar o carimbo (B3)
[ "$hit" = 0 ] && grep -qE '(^|[^[:alnum:]_-])(rm|rmdir|mv|unlink)([^[:alnum:]_-]).*\.claude/?([[:space:];&|)]|$)' <<< "$flat" && hit=1
[ "$hit" = 0 ] && exit 0
write_verb='(^|[^[:alnum:]_-])(git|rm|rmdir|touch|mkdir|truncate|chmod|chown|chgrp|unlink|shred|tee|cp|mv|install|rsync|scp|ln|sed|dd|eval|xargs)([^[:alnum:]_-]|$)|>'

closed() {  # SEM tokenizador: fecha SÓ o que cita um repo registrado E um verbo de escrita
  grep -qE -- "$signal" <<< "$flat" && grep -qE "$write_verb" <<< "$flat" || exit 0
  echo "GUARDA-PRETOOLUSE (adotante/repo alheio): $1 — o comando cita um repo registrado (ou a lista ${ONION_ADOPTER_TSV_REL}) junto de um verbo de escrita, e o veto não consegue analisá-lo. Fechado por segurança. Instale python3 (o tokenizador dos vetos); se for deliberado, o maestro roda fora da sessão (\`!\` no prompt)." >&2
  exit 2
}
[ "$nopy" = 1 ] && closed "a análise não rodou (python3 ausente ou quebrado, ou JSON do hook ilegível)"
out=$(ONION_CWD="$hcwd" ONION_MOAT_JUDGE="${here}/lib/adopter-judge.py" ONION_ADOPTER_REPOS="$repos" \
      ONION_ADOPTER_ALLOWS="$allows" ONION_ADOPTER_SELF_TSV="${selftsv}"$'\n'"${stamp}" onion_invocation_lines "$cmd")
grep -qx '__ONION_MOAT_OK__' <<< "$out" || closed "a análise não chegou ao fim"
line=$(printf '%s\n' "$out" | grep -m1 '^__ONION_ADOPTER__' || true)
[ -z "$line" ] && exit 0
IFS=$'\t' read -r _ cls target detail <<< "$line"
case "$cls" in
  lista)  deny_list "$detail" ;;
  alheio) deny "$target" "$detail" ;;
  *) echo "GUARDA-PRETOOLUSE (adotante/repo alheio): ${detail} — o repositório ou o caminho só se conhece em runtime, e o comando cita ${target}. Fechado: reescreva com o caminho literal (sem eval, nome de comando em variável ou xargs); se for deliberado, o maestro roda fora da sessão (\`!\` no prompt)." >&2
     exit 2 ;;
esac
