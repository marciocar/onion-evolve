#!/usr/bin/env bash
# PreToolUse(Bash) — o 2º veto REAL da casa (auditoria D_AUDITAR_GATES_TEXTUAIS, 2026-09-02).
#
# ── O BURACO QUE FECHA (medido, não suposto) ─────────────────────────────────────────────
# Este repo é PRIVADO sem GitHub Pro: branch protection/rulesets devolvem 403. Logo TODO check de
# CI (lint HARD, selftest, onion-review-verdict) é ADVISORY no host — `gh pr merge` com CI vermelho
# MERGEIA. O único lugar onde o CI vira veto é o `ops/pr-merge-verified.sh` (core-only), que lê check-runs do head
# + a linha onion-review-verdict e recusa. Mas ele é VOLUNTÁRIO: nada impedia o modelo de digitar
# `gh pr merge N` direto — e o /meta:drive só diz "PARE" em prosa. O System Card do 5.1 mede o
# modelo fabricando aprovação para passar gate textual (<0,01%). Gate em prosa não é gate.
#
# ── O QUE VETA (exit 2 = antes de executar) ─────────────────────────────────────────────
#  (a) `gh pr merge …` digitado na string do modelo (qualquer flag) → usar ops/pr-merge-verified.sh (core-only)
#  (b) `gh api … pulls/<n>/merge` (o mesmo merge pela REST, bypass do gh)
#  (c) `git push` NÃO-force cujo alvo seja main: refspec explícito (`origin main`, `HEAD:main`,
#      `x:main`) ou push NU sentado em main. Main desta casa só muda por merge de PR no forge;
#      um push de main pela sessão é bypass de PR/CI inteiro (o force já é vetado pelo hook irmão).
#
# ── O QUE NÃO VETA (fronteira declarada) ─────────────────────────────────────────────────
#  · O script `ops/pr-merge-verified.sh` (core-only) chama `gh pr merge` POR DENTRO — o hook só vê a string do
#    modelo, não subprocessos. É exatamente o que se quer: o caminho verificado passa, o nu não.
#  · Sem `ops/pr-merge-verified.sh` (core-only) no projeto (adotante via /meta:adopt copia .claude/, não ops/)
#    o hook não VETA: não se veta o único caminho de merge de uma casa que não tem o verificado. Mas
#    desde 2026-10-17 ele também não CALA (E_MERGE_GATE_INERTE_NO_ADOTANTE, medido na adoção de um
#    adotante): cada caso que vetaria no core vira AVISO injetado no contexto (additionalContext,
#    exit 0), dizendo que nada conferiu o CI antes do merge. Antes, a sessão do adotante mergeava sem
#    saber que a trava que ela via citada na doutrina não existia ali.
#  · Julga POR LINHA DE INVOCAÇÃO, nunca a string inteira (heredoc/prosa que CITA `gh pr merge`
#    não veta — a classe guarda-por-vocabulário, falso-positivo medido no hook irmão em 09-01).
#  · Escape deliberado = o maestro roda fora da sessão. Não há flag de bypass por desenho.
input=$(cat)
# `cwd` do JSON é o diretório ONDE o comando roda — numa worktree de agente é a worktree, não a raiz
# (`CLAUDE_PROJECT_DIR`). Julgar pela raiz vetava `git push -u origin HEAD` de agente e deixava passar
# force-push de um checkout sentado na main (Elenxo, 2ª passada, 2026-10-05).
# `errors=backslashreplace` e `tool_input` não-dict (passada adversarial, 2026-10-11): um surrogate solto no JSON
# (`\ud800`) derrubava o print, e o hook caía no modo sem python — vetando um push honesto.
parsed=$(printf '%s' "$input" | python3 -c 'import json,sys
sys.stdout.reconfigure(errors="backslashreplace")
try: d=json.load(sys.stdin)
except Exception: d={}
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
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
ADVISE=0; [ -f "${root}/ops/pr-merge-verified.sh" ] || ADVISE=1   # adotante: avisa em vez de vetar
# O aviso do adotante: JSON de PreToolUse com additionalContext (o mesmo canal do kg-read-leg.sh), exit 0.
# Não cita o caminho do script do core: ele não viaja, e a frase seria um ponteiro para o que não existe.
advise() {
  local _r; _r="$(printf '%s' "$1" | sed -E 's/ negad[oa]( |$)/\1/; s/ +$//')"   # no adotante nada é negado
  local _m="TRAVA DE MERGE (aviso, não veto) — no core isto seria vetado: ${_r}. Este repo não tem o caminho verificado de merge do core (ele não viaja na adoção), então NADA conferiu o CI antes deste comando, e o host pode não proteger a main. Antes de seguir, rode 'gh pr checks <N>' e confira que todos os checks passaram."
  if [ "$nopy" = 0 ]; then
    M="$_m" python3 -c 'import json,os; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":os.environ["M"]}}, ensure_ascii=False))'
  else
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"TRAVA DE MERGE (aviso, não veto): comando com forma de merge ou push e sem python3 para analisá-lo. Este repo não tem o caminho verificado de merge do core, então nada conferiu o CI antes dele. Antes de seguir, rode gh pr checks <N> e confira que todos os checks passaram."}}'
  fi
  exit 0
}
# SEM python3 não há tokenizador: fecha SÓ o que pode tocar a main (recorte medido, ver a lib).
if [ "$nopy" = 1 ]; then
  onion_nopy_touches merge-gate "$cmd" || exit 0
  [ "$ADVISE" = 1 ] && advise "sem python3"
  echo "GUARDA-PRETOOLUSE: python3 ausente ou quebrado — o veto não consegue analisar este comando, que tem forma de merge ou push (git push, gh pr merge, gh api com rota de merge/contents/refs/graphql, gh repo sync). Fechado por segurança: o host não protege a main neste repo. Instale python3 (o tokenizador dos vetos); o merge segue pelo caminho verificado, bash ops/pr-merge-verified.sh <PR> --sync (core-only)." >&2
  exit 2
fi

# Reduz a string do modelo a linhas de invocação (heredoc fora, operadores partidos, invólucros
# `command`/`\`/`env`/`exec`/`sh -c` e opções globais do git removidos). A normalização mora na lib
# porque o buraco foi medido nos DOIS vetos ao mesmo tempo (auditoria 2026-09-02): `command gh pr
# merge 1` e `bash -c "git push -f origin main"` passavam com rc=0 em ambos.
inv=$(ONION_CWD="$hcwd" onion_invocation_lines "$cmd")
[ -z "$inv" ] && exit 0

deny() { [ "$ADVISE" = 1 ] && advise "$1"; echo "GUARDA-PRETOOLUSE: $1 — merge/push em MAIN só pelo caminho verificado: bash ops/pr-merge-verified.sh <PR> --sync (lê CI + onion-review-verdict e recusa vermelho; o host não protege main neste repo). Se for deliberado, o maestro roda fora da sessão." >&2; exit 2; }  # (core-only): só alcançável depois do teste de presença acima

# (0) INANALISÁVEL que tem a forma de merge, ou de push que pode tocar a main → FECHADO. A lib só emite
#     isto quando não consegue PROVAR o que o shell vai executar; supor que era inofensivo é exatamente
#     o que deixou 15 formas passarem (radar E3, 2026-10-05).
un=$(printf '%s\n' "$inv" | grep -m1 -E '^__ONION_UNANALYZABLE__ (merge=1|merge=0 main=1)' || true)
[ -n "$un" ] && deny "comando que cita merge/push e NÃO pode ser analisado com certeza (${un#*:: }) — reescreva sem eval, nome de comando em variável, xargs, shell lendo stdin ou brace expansion"
# (a) gh pr merge
grep -qE '^gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)' <<< "$inv" && deny "'gh pr merge' direto negado"
# (b) mutações do forge pela API — a lib entrega `gh api --method <efetivo> …` (POST quando há -f/-F).
#     Achadas pelo Elenxo da forja de 2026-10-05: além de pulls/N/merge, o merge direto na base
#     (`…/merges`), o force-update da ref (`git/refs/heads/main`) e as mutações GraphQL equivalentes.
api=$(printf '%s\n' "$inv" | grep -E '^gh[[:space:]]+api[[:space:]]+--method[[:space:]]' || true)
if [ -n "$api" ]; then
  while IFS= read -r a; do
    [ -z "$a" ] && continue
    # `gh api --method <M> <endpoint> <campos…>`: as rotas se julgam SÓ no endpoint — texto de um campo
    # (`-f body='… /merges …'`) não é rota (Elenxo, 3ª passada, M5). Campo dinâmico conta como main.
    m=$(printf '%s' "$a" | awk '{print $4}'); ep=$(printf '%s' "$a" | awk '{print $5}')
    dynv='(main|__DYN__|__ONION_SUBST__[^[:space:]]*|[^[:space:]]*\$[^[:space:]]*)([[:space:]]|$)'
    grep -qE '(^|/)pulls/[^/]+/merge$' <<< "$ep" && [ "$m" != GET ] && deny "'gh api …/pulls/N/merge' negado"
    # `…/merges` só é merge NA MAIN com base=main (ou base dinâmica/ausente — fechado); base=feat é
    # merge numa branch de trabalho (falso positivo medido pelo Elenxo)
    if grep -qE '/merges$' <<< "$ep" && [ "$m" = POST ]; then
      grep -qE '(^|[[:space:]])base=' <<< "$a" && ! grep -qE "(^|[[:space:]])base=${dynv}" <<< "$a" \
        || deny "'gh api …/merges' (merge direto na base main) negado"
    fi
    # `…/merge-upstream` e `…/contents/<arq>` (PUT/DELETE) escrevem NA branch dada — sem `branch=`, na
    # PADRÃO, que é a main: commit direto na main sem PR (Elenxo, 2ª passada, B8)
    if grep -qE '/(merge-upstream|contents(/.*)?)$' <<< "$ep" && [ "$m" != GET ]; then
      grep -qE '(^|[[:space:]])branch=' <<< "$a" && ! grep -qE "(^|[[:space:]])branch=${dynv}" <<< "$a" \
        || deny "'gh api …/merge-upstream|contents' escrevendo na main negado"
    fi
    grep -qE '(^|/)git/refs/heads/main$' <<< "$ep" && [ "$m" != GET ] && deny "'gh api … git/refs/heads/main' (mexe na ref da main) negado"
    if [ "$ep" = graphql ]; then
      grep -q '__GRAPHQL_OPACO__' <<< "$a" && deny "'gh api graphql' com query de arquivo/variável — o conteúdo não pode ser verificado"
      grep -qE 'mergePullRequest|enablePullRequestAutoMerge|mergeBranch|updateRefs?\b|deleteRef' <<< "$a" && deny "mutação GraphQL de merge/ref negada"
    fi
  done <<< "$api"
fi
# (b2) `gh repo sync <repo-remoto>` reescreve a branch do HOST (padrão: a main) — a lib só emite esta
#      linha quando há repo posicional; sem ele o sync é do clone local
grep -qE '^gh repo sync --remote [^[:space:]]+ --branch main([[:space:]]|$)' <<< "$inv" && deny "'gh repo sync' na main do repo remoto negado"
# (c) git push não-force com alvo main
push_lines=$(printf '%s\n' "$inv" | grep -E '^git[[:space:]]+push([[:space:]]|$)')
[ -z "$push_lines" ] && exit 0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  # refspec explícito: `main` como token final, `HEAD:main`, `algo:main`, `refs/heads/main` — `main` é o
  # NOME do ramo protegido: a lib converte nele o ramo de produção resolvido (paridade com o protect-main)
  if grep -qE '([[:space:]]|:)(refs/heads/)?main([[:space:]]|$)' <<< "$line"; then
    deny "'git push' com alvo MAIN negado ($line)"
  fi
  # push NU (só flags) sentado em main
  if grep -qE '^git[[:space:]]+push([[:space:]]+-[^[:space:]]+)*[[:space:]]*$' <<< "$line"; then
    onion_on_protected_branch "$hcwd" && deny "'git push' nu sentado no ramo de PRODUÇÃO negado"
  fi
done <<< "$push_lines"
exit 0
