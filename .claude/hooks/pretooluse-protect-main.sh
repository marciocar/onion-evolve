#!/usr/bin/env bash
# PreToolUse(Bash) — o 1º uso REAL da capacidade que compra o acoplamento (Onda 7, 2026-09-01).
# Nega force-push para o ramo de PRODUÇÃO (main, ou o resolvido do repo): a ação irreversível mais barata de barrar. exit 2 = veto ANTES de executar.
# Escopo: na produção, todo force (com lease inclusive). Fora dela, desde 2026-11-24, a força DURA (`-f`, `--force`,
# `+ref`, `--mirror`) também cai, como no deny, e EM QUALQUER PROJETO: a lib não isenta a força dura nem o
# `git clean` pelo projeto de destino, porque destruir é destruir em qualquer pasta (revisão isolada do
# fix/deny-field-notes-1124). O `--force-with-lease` de branch de trabalho segue livre (o fluxo de stack e o
# rebase dependem dele), e o de outro projeto também.
# TETOS declarados: `--force --no-force` é vetado (a lib não lê o `--no-force`; falso positivo antigo); `eval`,
# `script -qc` e alias de shell (`-c alias.x=!cmd`) não são vistos no clean.
# ── git clean que apaga IGNORADO (desde 2026-11-20, fix/deny-force-refspec-1120) ─────────────────────────
# Também nega `git clean` com -x/-X (apaga o ignorado: o .env some) SEM simulação (-n/--dry-run). Mora aqui
# porque o deny nativo não sabe dizer "exceto -n": o glob não tem negação, e as regras `git clean* -x*`
# barravam `git clean -n -x`, que só lista (falso positivo medido no motor real, 2.1.329). O deny ficou só
# com o grupo destrutivo como 1º argumento (`git clean -fdx*`); a ordem livre (`-f -d -x`, `-e keep -fdx`)
# é julgada aqui, por token. Vale em qualquer pasta (`git -C /outra clean -fdx` também cai), como o deny.
# Desde 2026-11-24 (fix/deny-field-notes-1124) o deny guarda só o grupo EXATO (`git clean -fdx`, sem nada depois): o
# `-n` depois do grupo (`git clean -fdx -n`, `-x --dry-run`) e grudado no fim dele (`-xn`, `-fdxn`) passa, e todo o
# resto (grupo seguido de caminho ou de outra flag, ordem livre) é julgado aqui.
# TETO: `eval "git clean -fdx"` não é visto aqui (a lib só marca inanalisável o que cita push ou merge).
input=$(cat)
# `cwd` do JSON é o diretório ONDE o comando roda — numa worktree de agente é a worktree, não a raiz
# (`CLAUDE_PROJECT_DIR`). Julgar pela raiz vetava `git push -u origin HEAD` de agente e deixava passar
# force-push de um checkout sentado na main (Elenxo, 2ª passada, 2026-10-05).
# `errors=backslashreplace` e `tool_input` não-dict (passada adversarial, 2026-10-11): um surrogate solto no JSON
# (`\ud800`) derrubava o print, e o hook caía no modo sem python — vetando um push honesto.
# JSON ilegível NÃO vira `{}` (hooks em modo isolado, 2026-11-04): `{}` é comando vazio, e comando vazio é exit 0,
# a falha de análise virando permissão. Agora a leitura falha, e o caminho é o mesmo do python ausente: julga pela forma.
parsed=$(printf '%s' "$input" | python3 -I -c 'import json,sys
sys.stdout.reconfigure(errors="backslashreplace")
d=json.load(sys.stdin)
d=d if isinstance(d,dict) else {}
ti=d.get("tool_input"); ti=ti if isinstance(ti,dict) else {}
print(str(d.get("cwd") or "").replace("\n"," ")); print(str(ti.get("command") or ""))' 2>/dev/null) && nopy=0 || nopy=1
hcwd=${parsed%%$'\n'*}; cmd=${parsed#*$'\n'}; [ "$cmd" = "$parsed" ] && cmd=""
# shellcheck source=lib/invocation-lines.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/invocation-lines.sh"
# SEM python3 (ausente ou morto) o comando saía vazio e o veto ABRIA por dentro — exit 0, que o
# `onFailure: block` não cobre. Agora o JSON é lido sem python e, se o campo nem for achado, julga-se o
# JSON cru: errar aqui só pode fechar, nunca abrir (fix/vetos-fail-closed, 2026-10-11).
if [ "$nopy" = 1 ]; then
  hcwd=$(printf '%s' "$input" | onion_json_string_field cwd) || hcwd=""
  cmd=$(printf '%s' "$input" | onion_json_string_field command) || cmd="$input"
fi
[ -d "$hcwd" ] || hcwd=$PWD
[ -z "$cmd" ] && exit 0
CLEAN_MSG="GUARDA-PRETOOLUSE: git clean com -x/-X apaga o que o .gitignore protege (o .env some) e não volta. Simule antes com -n (ou --dry-run); para apagar, o maestro roda fora da sessão."
# clean_destroys_ignored — lê linhas canônicas no stdin; rc 0 se alguma é `git clean` com x/X e sem simulação.
# Por token: cluster curto (-fdx), `-e <padrão>` e `-e<padrão>` (o resto é argumento, não flag), `--exclude`,
# `--` (dali em diante é caminho) e longa abreviada (`--dry` é `--dry-run`, como o git aceita).
clean_destroys_ignored() {
  awk '
  /^git[ \t]+clean([ \t]|$)/ {
    x = 0; n = 0; skip = 0; endopt = 0
    for (i = 3; i <= NF; i++) {
      t = $i
      if (skip) { skip = 0; continue }
      if (endopt) continue
      if (t == "--") { endopt = 1; continue }
      # flag que vem de expansão (`$F`, `${F:--fdx}`) ou de substituição (`$(…)`, crase) não se lê aqui: conta como
      # destrutiva (fix/deny-field-notes-1124, revisão isolada). O -n literal ao lado ainda simula.
      if (t ~ /\$|__ONION_SUBST__|`/) { x = 1; continue }
      # expansão por chaves (`{-x,}`, `{-fdx,}`) também não se lê aqui: conta como destrutiva, igual ao `$F`
      if (t ~ /\{.*,.*\}/) { x = 1; continue }
      if (t ~ /^--/) {
        nm = t; sub(/=.*/, "", nm)
        if (length(nm) >= 3 && index("--dry-run", nm) == 1) n = 1
        else if (length(nm) >= 6 && index("--no-dry-run", nm) == 1) n = 0
        else if (length(nm) >= 3 && index("--exclude", nm) == 1 && t !~ /=/) skip = 1
        continue
      }
      if (t ~ /^-./) {
        for (j = 2; j <= length(t); j++) {
          c = substr(t, j, 1)
          if (c == "e") { if (j == length(t)) skip = 1; break }
          if (c == "n") n = 1
          if (c == "x" || c == "X") x = 1
        }
      }
    }
    if (x && !n) found = 1
  }
  END { exit found ? 0 : 1 }'
}
# clean_by_shape <texto> — sem tokenizador (python ausente, ou linha inanalisável): corta por ; & | e quebra de
# linha, tira aspas e `\`, e leva ao juiz o que vem depois do 1º token `clean` que segue um `git` (o `clean` de
# um comentário ou de um caminho, mais adiante, não rouba o lugar do verbo).
clean_by_shape() {
  printf '%s\n' "$1" | tr -d "\"'\\\\" | tr ';&|' '\n\n\n' \
    | awk '{ g = 0
        for (i = 1; i <= NF; i++) {
          if (!g && ($i == "git" || $i ~ /\/git$/)) g = 1
          else if (g && $i == "clean") { s = "git clean"; for (j = i + 1; j <= NF; j++) s = s " " $j; print s; next }
        } }' | clean_destroys_ignored
}
# Julga POR LINHA DE INVOCAÇÃO, nunca a string inteira: heredoc/prosa num comando composto que
# apenas CITA o vocabulário não pode vetar (falso-positivo medido no 1º dogfood, 2026-09-01 —
# a classe guarda-por-vocabulário; o veto pegou o próprio commit desta feature). A redução mora na
# lib partilhada com o merge-gate desde a auditoria de 2026-09-02, que mediu `command git push -f
# origin main`, `\git push`, `env git push`, `bash -c "…"` e `git -C . push` passando rc=0 aqui.
# SEM python3 não há tokenizador: fecha SÓ o que tem forma de force-push (recorte medido, ver a lib).
if [ "$nopy" = 1 ]; then
  if clean_by_shape "$cmd"; then echo "$CLEAN_MSG" >&2; exit 2; fi
  onion_nopy_touches force-main "$cmd" || exit 0
  echo "GUARDA-PRETOOLUSE: a análise não rodou (python3 ausente ou quebrado, ou JSON do hook ilegível) — o veto não consegue analisar este comando, que tem forma de force-push (git push com --force, -f, +ref ou --mirror). Fechado por segurança: force-push na main é irreversível. Instale python3 (o tokenizador dos vetos); se for deliberado, o maestro roda fora da sessão." >&2
  exit 2
fi
inv=$(ONION_CWD="$hcwd" onion_invocation_lines "$cmd")
if clean_destroys_ignored <<< "$inv" \
   || clean_by_shape "$(printf '%s\n' "$inv" | sed -n 's/^__ONION_UNANALYZABLE__ [^:]*:: //p')"; then
  echo "$CLEAN_MSG" >&2; exit 2
fi
# INANALISÁVEL que cita push → FECHADO: não se prova que não é force-push na main (radar E3, 2026-10-05).
if printf '%s\n' "$inv" | grep -E '^__ONION_UNANALYZABLE__ merge=[01] main=1 ::' | grep -qE '\bpush\b|updateRef|git/refs'; then
  echo "GUARDA-PRETOOLUSE: comando que cita push e NÃO pode ser analisado com certeza — reescreva sem eval, nome de comando em variável, xargs ou brace expansion (force-push na main é irreversível)." >&2
  exit 2
fi
# INANALISÁVEL com FORÇA DURA em qualquer alvo → FECHADO (SAC-551, 2026-11-25): `eval "git push -f origin $B"` saía
# `main=0` e passava com rc 0, embora a força dura caia em qualquer branch desde 2026-11-24. O lease segue livre.
# A força se procura só nos tokens DEPOIS do PRIMEIRO `push`, no mesmo segmento: `eval "git push origin $1; tail -f x"`
# era vetado pelo `-f` do tail (refutador isolado, B2), e o corte guloso no ÚLTIMO `push` escondia a força em
# `eval "git push -f origin feat/push-$N"` e em `--push-option` (2º refutador isolado).
if printf '%s\n' "$inv" | sed -n 's/^__ONION_UNANALYZABLE__ [^:]*:: //p' | tr ';&|' '\n\n\n' \
   | sed -n 's/\bpush\b/\x01/;s/^[^\x01]*\x01//p' \
   | grep -qE '(^|[[:space:]])(--force([[:space:]]|$)|--mirror([[:space:]]|$)|-[a-eg-z]*f[a-z]*([[:space:]]|$)|\+[^[:space:]])'; then
  echo "GUARDA-PRETOOLUSE: comando com forma de force-push (-f, --force, refspec com + ou --mirror) que NÃO pode ser analisado com certeza — reescreva sem eval, nome de comando em variável ou xargs. Force-push reescreve a história do remoto em qualquer branch; se for deliberado, o maestro roda fora da sessão." >&2
  exit 2
fi
push_lines=$(printf '%s\n' "$inv" | grep -E '^git[[:space:]]+push([[:space:]]|$)' || true)
[ -z "$push_lines" ] && exit 0
# FORÇA DURA EM QUALQUER BRANCH (desde 2026-11-24, fix/deny-field-notes-1124). A linha canônica diz `--force` para
# `-f`, `--force`, `+ref` e `--mirror`, depois de tirar `FOO=1`, `env`, `command`, `nice` e afins. O `+` só chega
# aqui quando abre um refspec do próprio push: o `+` do título de um PR no mesmo comando é de outra linha, e
# o `v1+build` não abre o argumento. Por isso a cobertura do refspec com `+` saiu do deny (o glob `git push* +*`
# casava o `+` de qualquer ponto do comando quando o motor o julgava inteiro, com `$(…)` ou pipe) e mora aqui.
# O `--force-with-lease` segue a regra antiga, só na produção: o git o recusa se o remoto andou.
if grep -qE '^git[[:space:]]+push[[:space:]]+--force([[:space:]]|$)' <<< "$push_lines"; then
  echo "GUARDA-PRETOOLUSE: force-push negado (-f, --force, refspec com + ou --mirror reescrevem a história do remoto em qualquer branch). Para atualizar a sua branch depois de um rebase, use --force-with-lease; se o force for deliberado, o maestro roda fora da sessão." >&2
  exit 2
fi
grep -qE '(--force([^-]|$)|--force-with-lease|[[:space:]]-[a-eg-z]*f[a-z]*([[:space:]]|$))' <<< "$push_lines" || exit 0
main_target=0
# `main` na linha canônica é o NOME do ramo protegido: a lib já converte nele o ramo de produção
# resolvido (`master` num gitflow clássico — Q_VETO_DE_FORCE_PUSH_SO_PROTEGE_O_LITERAL_MAIN, 2026-10-12).
# `HEAD:main` / `x:main` / `refs/heads/main` também são alvo main — a v1 exigia ESPAÇO antes de
# `main` e deixava passar o refspec com dois-pontos (buraco achado pela bancada da auditoria
# D_AUDITAR_GATES_TEXTUAIS, 2026-09-02: `git push -f origin HEAD:main` saía rc=0).
grep -qE '([[:space:]]|:)(refs/heads/)?main([[:space:]]|$|:)' <<< "$push_lines" && main_target=1
if [ "$main_target" -eq 0 ]; then
  # Fallback branch-corrente SÓ para push NU (flags apenas, sem remote/refspec): um push com alvo
  # explícito que não cita main não pode herdar o veto da branch onde a sessão está SENTADA —
  # o 2º falso-positivo de produção (2026-09-01): loop de merge parado em main pushava "$br" de
  # feature e era vetado. Push nu = a linha termina após push+flags.
  if grep -qE 'git[[:space:]]+push([[:space:]]+-[^[:space:]]+)*[[:space:]]*$' <<< "$push_lines"; then
    onion_on_protected_branch "$hcwd" && main_target=1
  fi
fi
if [ "$main_target" -eq 1 ]; then
  echo "GUARDA-PRETOOLUSE: force-push para o ramo de PRODUÇÃO negado (main, ou o resolvido do repo: gitflow.branch.master ou a branch padrão do remoto; hook de produção, Onda 7) — reescrever a história da produção é irreversível; se for deliberado, o maestro roda fora da sessão." >&2
  exit 2
fi
exit 0
