#!/usr/bin/env bash
# PreToolUse(Bash) — o 2º veto REAL da casa (auditoria D_AUDITAR_GATES_TEXTUAIS, 2026-09-02).
#
# ── O BURACO QUE FECHA (medido, não suposto) ─────────────────────────────────────────────
# Este repo é PRIVADO sem GitHub Pro: branch protection/rulesets devolvem 403. Logo TODO check de
# CI (lint HARD, selftest, onion-review-verdict) é ADVISORY no host — `gh pr merge` com CI vermelho
# MERGEIA. O único lugar onde o CI vira veto é o `ops/pr-merge-verified.sh` (lê check-runs do head
# + a linha onion-review-verdict e recusa). Mas ele é VOLUNTÁRIO: nada impedia o modelo de digitar
# `gh pr merge N` direto — e o /meta:drive só diz "PARE" em prosa. O System Card do 5.1 mede o
# modelo fabricando aprovação para passar gate textual (<0,01%). Gate em prosa não é gate.
#
# ── O QUE VETA (exit 2 = antes de executar) ─────────────────────────────────────────────
#  (a) `gh pr merge …` digitado na string do modelo (qualquer flag) → usar ops/pr-merge-verified.sh
#  (b) `gh api … pulls/<n>/merge` (o mesmo merge pela REST, bypass do gh)
#  (c) `git push` NÃO-force cujo alvo seja main: refspec explícito (`origin main`, `HEAD:main`,
#      `x:main`) ou push NU sentado em main. Main desta casa só muda por merge de PR no forge;
#      um push de main pela sessão é bypass de PR/CI inteiro (o force já é vetado pelo hook irmão).
#
# ── O QUE NÃO VETA (fronteira declarada) ─────────────────────────────────────────────────
#  · O script `ops/pr-merge-verified.sh` chama `gh pr merge` POR DENTRO — o hook só vê a string do
#    modelo, não subprocessos. É exatamente o que se quer: o caminho verificado passa, o nu não.
#  · Sem `ops/pr-merge-verified.sh` no projeto (adotante via /meta:adopt copia .claude/, não ops/)
#    o hook se DESARMA: não se veta o único caminho de merge de uma casa que não tem o verificado.
#  · Julga POR LINHA DE INVOCAÇÃO, nunca a string inteira (heredoc/prosa que CITA `gh pr merge`
#    não veta — a classe guarda-por-vocabulário, falso-positivo medido no hook irmão em 09-01).
#  · Escape deliberado = o maestro roda fora da sessão. Não há flag de bypass por desenho.
input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")' 2>/dev/null)
[ -z "$cmd" ] && exit 0
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -f "${root}/ops/pr-merge-verified.sh" ] || exit 0

# Reduz a string do modelo a linhas de invocação (heredoc fora, operadores partidos, invólucros
# `command`/`\`/`env`/`exec`/`sh -c` e opções globais do git removidos). A normalização mora na lib
# porque o buraco foi medido nos DOIS vetos ao mesmo tempo (auditoria 2026-09-02): `command gh pr
# merge 1` e `bash -c "git push -f origin main"` passavam com rc=0 em ambos.
# shellcheck source=lib/invocation-lines.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/invocation-lines.sh"
inv=$(onion_invocation_lines "$cmd")
[ -z "$inv" ] && exit 0

deny() { echo "GUARDA-PRETOOLUSE: $1 — merge/push em MAIN só pelo caminho verificado: bash ops/pr-merge-verified.sh <PR> --sync (lê CI + onion-review-verdict e recusa vermelho; o host não protege main neste repo). Se for deliberado, o maestro roda fora da sessão." >&2; exit 2; }

# (a) gh pr merge
printf '%s\n' "$inv" | grep -qE '^gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)' && deny "'gh pr merge' direto negado"
# (b) gh api …/pulls/<n>/merge
printf '%s\n' "$inv" | grep -E '^gh[[:space:]]+api[[:space:]]' | grep -qE 'pulls/[0-9]+/merge' && deny "'gh api …/pulls/N/merge' negado"
# (c) git push não-force com alvo main
push_lines=$(printf '%s\n' "$inv" | grep -E '^git[[:space:]]+push([[:space:]]|$)')
[ -z "$push_lines" ] && exit 0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  # refspec explícito: `main` como token final, `HEAD:main`, `algo:main`, `refs/heads/main`
  if printf '%s' "$line" | grep -qE '([[:space:]]|:)(refs/heads/)?main([[:space:]]|$)'; then
    deny "'git push' com alvo MAIN negado ($line)"
  fi
  # push NU (só flags) sentado em main
  if printf '%s' "$line" | grep -qE '^git[[:space:]]+push([[:space:]]+-[^[:space:]]+)*[[:space:]]*$'; then
    cur=$(git -C "$root" branch --show-current 2>/dev/null)
    [ "$cur" = "main" ] && deny "'git push' nu sentado em MAIN negado"
  fi
done <<< "$push_lines"
exit 0
