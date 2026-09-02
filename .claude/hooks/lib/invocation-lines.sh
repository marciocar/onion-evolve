#!/usr/bin/env bash
# lib dos vetos PreToolUse — reduz a string do modelo a LINHAS DE INVOCAÇÃO julgáveis.
# Sourced por pretooluse-protect-main.sh e pretooluse-merge-gate.sh; nunca executado só.
#
# POR QUE EXISTE (auditoria D_AUDITAR_GATES_TEXTUAIS, 2026-09-02, medido): os dois vetos casavam
# `^git push` / `^gh pr merge` no INÍCIO da linha — e `command git push -f origin main`, `\git push`,
# `env git push`, `exec gh pr merge`, `bash -c "git push -f origin main"` e `git -C . push` passavam
# todos com rc=0. É a classe guarda-por-vocabulário do lado de fora: a guarda por lista falha pelo
# VOCABULÁRIO, não pela lógica ([[guarda-por-lista-falha-pelo-vocabulario]]). A cura é NORMALIZAR
# antes de julgar, num lugar só — dois hooks com duas regexes divergem de novo.
#
# O QUE FAZ, em ordem:
#  1. remove corpo de heredoc (`<<[-]['"]TERM … TERM`) — prosa que CITA o vocabulário não é invocação
#     (1º falso-positivo do merge-gate, 2026-09-02; o do protect-main, 2026-09-01);
#  2. parte por `&&` `||` `;` `|` `$(` `` ` `` `<(` `>(` e quebra de linha; tira `(`, `{` iniciais
#     (a bancada pegou `out=$(gh pr merge 1)` passando na 1ª versão desta lib);
#  3. desembrulha UM nível de `sh|bash|zsh|dash -c "<string>"` e re-parte a string;
#  4. tira prefixos-invólucro: `\`, `command`, `exec`, `env`, `nohup`, `time`, `sudo` (com `-u user`
#     e afins — `sudo -u x git push` passou na 1ª versão), `builtin` e atribuições `VAR=val` — repetidamente;
#  5. colapsa opções globais do git (`git -C dir -c k=v push` → `git push`).
#
# FRONTEIRA DECLARADA (o que continua CONFIANÇA-NO-MODELO, por desenho): 2º nível de aninhamento de
# `-c`, `eval`, script em arquivo (`bash x.sh`), função/alias, subprocess de outra linguagem. O hook
# só vê a string do modelo — o que nasce fora dela é invisível a qualquer PreToolUse.

onion_invocation_lines() {
  local cmd="$1"
  local pass lines
  lines=$(printf '%s\n' "$cmd" | awk '
    term!="" { if ($0==term) term=""; next }
    { print; if (match($0, /<<-?[[:space:]]*["'"'"']?[A-Za-z_][A-Za-z0-9_]*/)) { t=substr($0,RSTART,RLENGTH); sub(/^<<-?[[:space:]]*["'"'"']?/,"",t); term=t } }')
  # duas passadas: a 2ª re-parte o que o desembrulho do `-c` liberou
  for pass in 1 2; do
    lines=$(printf '%s\n' "$lines" \
      | sed -E 's/&&|[|][|]|;|[|]|\$\(|`|[<>]\(/\n/g' \
      | sed -E 's/^[[:space:]]+//; s/^(\$\(|\(|\{)[[:space:]]*//' \
      | sed -E 's/^(ba|z|da)?sh[[:space:]]+-[A-Za-z]*c[A-Za-z]*[[:space:]]+(["'"'"'])(.*)\2[[:space:]]*$/\3/')
  done
  # ESCOPO (falso-positivo medido 2026-09-02, adoção da um adotante greenfield): `git -C /outro/repo push origin main`
  # era vetado — a guarda julga a string sem saber que o alvo é OUTRO repositório. Uma linha cujo `-C <dir>`
  # / `--git-dir=` / `--work-tree=` resolve para fora da raiz deste projeto NÃO é assunto desta guarda: sai
  # aqui, antes do colapso das opções globais (que apagaria a evidência). `-C .` e `-C <raiz>` continuam.
  local root; root="$(cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" 2>/dev/null && pwd -P)"
  lines=$(printf '%s\n' "$lines" | while IFS= read -r ln; do
    tgt=""
    if printf '%s' "$ln" | grep -qE '^[[:space:]]*(\\|command[[:space:]]+|exec[[:space:]]+|env[[:space:]]+)?git[[:space:]]+(-c[[:space:]]+[^[:space:]]+[[:space:]]+)*-C[[:space:]]+[^[:space:]]+'; then
      tgt=$(printf '%s' "$ln" | sed -E 's/^[[:space:]]*(\\|command[[:space:]]+|exec[[:space:]]+|env[[:space:]]+)?git[[:space:]]+(-c[[:space:]]+[^[:space:]]+[[:space:]]+)*-C[[:space:]]+([^[:space:]]+).*/\3/')
    elif printf '%s' "$ln" | grep -qE '^[[:space:]]*git[[:space:]]+.*--(git-dir|work-tree)=[^[:space:]]+'; then
      tgt=$(printf '%s' "$ln" | sed -E 's/.*--(git-dir|work-tree)=([^[:space:]]+).*/\2/; s#/\.git$##')
    fi
    if [ -n "$tgt" ]; then
      tgt="${tgt%\"}"; tgt="${tgt#\"}"; tgt="${tgt%\'}"; tgt="${tgt#\'}"
      # só é "outro repo" se o alvo É um repositório git cuja raiz difere da nossa; `-C /tmp` (dir sem .git)
      # é truque de invólucro e continua vetado (caso da auditoria: `git -C /tmp -c a=b push --force origin HEAD:main`)
      top="$(git -C "$tgt" rev-parse --show-toplevel 2>/dev/null)"; top="${top:+$(cd "$top" 2>/dev/null && pwd -P)}"
      if [ -n "$top" ] && [ -n "$root" ] && [ "$top" != "$root" ]; then continue; fi   # outro repo: não é nosso veto
    fi
    printf '%s\n' "$ln"
  done)
  printf '%s\n' "$lines" | sed -E '
    :p
    s/^\\//
    s/^sudo([[:space:]]+-[ugpCDrtTU][[:space:]]+[^[:space:]]+|[[:space:]]+-[^[:space:]]+)*[[:space:]]+//
    s/^(command|exec|env|nohup|time|builtin)([[:space:]]+-[^[:space:]]+)*[[:space:]]+//
    s/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+//
    tp
    s/^git([[:space:]]+-(C|c)[[:space:]]+[^[:space:]]+)+/git/
    s/^git([[:space:]]+--(git-dir|work-tree)=[^[:space:]]+)+/git/
    s/[[:space:]]*[)}]*[[:space:]]*$//
  ' | grep -E '^(gh|git)([[:space:]]|$)' || true
}
