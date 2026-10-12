#!/usr/bin/env bash
# =============================================================================
# merge-onion-hooks.sh — Merge IDEMPOTENTE dos hooks Onion no settings.json do alvo
#
# Propósito : Levar os hooks Onion (SessionStart "you have mail" + worklog;
#             PreCompact breadcrumb) ao settings.json de um repo ADOTADO **sem
#             clobbar** hooks/permissions próprios do alvo. Resolve o gap do
#             /meta:adopt --update (sinal de campo
#             docs/evolution/inbox/2026-06-18-adopt-update-skips-phase3-steps.md):
#             um adotante com settings.json próprio recebia os SCRIPTS dos hooks
#             mas não o REGISTRO → o aviso 📬 não disparava.
#
# Mecânica  : Para cada evento COM HOOKS NA FONTE (derivado de $src.hooks|keys —
#             não hardcoded; regressão 2026-07-02: a lista fixa [SessionStart,
#             PreCompact] deixaria UserPromptSubmit/SessionEnd do farol de sessão
#             fora da distribuição), garante que cada
#             entrada de hook da FONTE esteja presente no ALVO. "Presente" =
#             existe no alvo um hook com o MESMO .command (os commands Onion são
#             canônicos e idênticos após a cópia do manifesto — bash .claude/
#             hooks/X.sh / detector inline). Ausentes são ANEXADOS como grupo
#             próprio ({matcher?, hooks:[obj]}, com o matcher do grupo de origem); e os PRESENTES
#             recebem as chaves da fonte por cima (refresh do que é do Onion: onFailure, timeout…).
#             Hook próprio do alvo (command que a fonte não tem) e chave extra do alvo ficam.
#             IDEMPOTENTE: rodar 2× = no-op na 2ª.
#
# Uso       : merge-onion-hooks.sh <source-settings.json> <target-settings.json>
#             Emite o JSON merjado em STDOUT (não escreve no lugar — o chamador
#             redireciona). Exit 0 em sucesso.
#
# Fallback  : sem jq → emite o target inalterado em STDOUT + aviso em STDERR +
#             exit 3 (o chamador decide; mesma doutrina graciosa dos worklog-*.sh).
#
# Determinístico, sem LLM. Consumido por /meta:adopt (Fase 3 + --update) e
# exercitado pelo lint-selftest.sh (kind=merge).
# =============================================================================
set -euo pipefail

SRC="${1:-}"
TGT="${2:-}"

if [ -z "${SRC}" ] || [ -z "${TGT}" ]; then
  echo "uso: merge-onion-hooks.sh <source-settings.json> <target-settings.json>" >&2
  exit 2
fi
[ -f "${SRC}" ] || { echo "ERRO: source não encontrado: ${SRC}" >&2; exit 2; }
[ -f "${TGT}" ] || { echo "ERRO: target não encontrado: ${TGT}" >&2; exit 2; }

# Fallback gracioso (padrão dos hooks de worklog): sem jq, não muta — devolve o
# alvo como está e sinaliza, em vez de corromper o settings.json.
if ! command -v jq >/dev/null 2>&1; then
  echo "AVISO: jq ausente — settings.json do alvo NÃO merjado (registre os hooks Onion à mão)." >&2
  cat "${TGT}"
  exit 3
fi

# Para cada evento, anexa ao alvo os hooks da fonte cujo .command ainda não
# aparece no alvo (índice por .command). Preserva matchers/permissions/outros.
# alvo JÁ tem attribution diferente da fonte: preserva (é dele) e AVISA — sinal de que o padrão da família mudou
_div="$(jq -nr --slurpfile s "${SRC}" --slurpfile t "${TGT}" \
  'if ($s[0].attribution != null) and ($t[0].attribution != null) and ($s[0].attribution != $t[0].attribution)
   then "diverge" else "" end' 2>/dev/null || true)"
[ "${_div}" = diverge ] && echo "AVISO: o attribution do alvo difere do da fonte — preservado o do alvo; confira se o padrão de assinatura da família mudou." >&2

jq -n \
  --slurpfile s "${SRC}" \
  --slurpfile t "${TGT}" '
  ($s[0]) as $src | ($t[0]) as $tgt |
  reduce (($src.hooks // {}) | keys[]) as $ev ($tgt;
    # mapa command -> objeto do hook na FONTE, e command -> matcher do grupo de origem (null = sem matcher)
    ([ ($src.hooks[$ev] // [])[].hooks[]? | select((.command | type) == "string") | {key: .command, value: .} ]
       | from_entries) as $srcmap
    | ([ ($src.hooks[$ev] // [])[] | . as $g | .hooks[]? | select((.command | type) == "string")
         | {key: .command, value: ($g.matcher // null)} ] | from_entries) as $srcmt
    # commands Onion já no alvo NO GRUPO CERTO (o matcher do grupo é o da fonte)
    | ([ (.hooks[$ev] // [])[] | . as $g | .hooks[]? | select((.command | type) == "string")
         | select(.command as $c | $srcmt | has($c)) | select(($g.matcher // null) == $srcmt[.command]) | .command ]) as $placed
    # hook Onion do alvo FORA do grupo certo (2026-10-12, --update do onion-kg-ssot: o veto direct-provider-api
    # ficou num grupo sem matcher porque o update anterior o anexou assim, e o refresh casava por command sem
    # mudar de grupo). Sai do grupo onde está e volta no grupo com o matcher da fonte, levando as chaves extras.
    | ([ (.hooks[$ev] // [])[] | . as $g | .hooks[]? | select((.command | type) == "string")
         | select(.command as $c | $srcmt | has($c)) | select(($g.matcher // null) != $srcmt[.command]) ]) as $misplaced
    | .hooks = (.hooks // {})
    | .hooks[$ev] = ((.hooks[$ev] // []) | map(
        if (.hooks | type) == "array" and (.hooks | length) > 0
        then . as $g
          | .hooks |= map(select(
              ((.command | type) != "string") or ((.command as $c | $srcmt | has($c)) | not)
              or (($g.matcher // null) == $srcmt[.command])))
          | if (.hooks | length) == 0 then empty else . end
        else . end))
    # REFRESH do que é do Onion (2026-10-12): hook do alvo com o MESMO .command de um hook da fonte é do Onion;
    # as chaves da FONTE sobrepõem as do alvo (onFailure, timeout…), e chave extra que só o alvo tem fica.
    # Hook próprio do alvo (command que a fonte não tem) não é tocado, nem hook sem .command (type prompt/agent).
    | .hooks[$ev] = (.hooks[$ev] | map(
        if (.hooks | type) == "array"
        then .hooks |= map(. as $h | if (($h.command | type) == "string" and $srcmap[$h.command] != null)
                                     then ($h + $srcmap[$h.command]) else $h end)
        else . end))
    # ausentes (nem no grupo certo) entram como grupo próprio com o matcher de origem; o realocado leva as
    # chaves extras do alvo e as da fonte por cima. Duplicata realocada de um command já no grupo certo some.
    | ([ $misplaced[] | select(.command as $c | ($placed | index($c)) == null) ]
       | group_by(.command) | map({key: .[0].command, value: (reduce .[] as $x ({}; . + $x))}) | from_entries) as $moved
    | ([ ($src.hooks[$ev] // [])[] | . as $g | .hooks[]? | select((.command | type) == "string")
         | select(.command as $c | ($placed | index($c)) == null)
         | (($moved[.command] // {}) + .) as $obj
         | if ($g.matcher != null) then {matcher: $g.matcher, hooks: [$obj]} else {hooks: [$obj]} end ]) as $missing
    | .hooks[$ev] = (.hooks[$ev] + $missing)
  )
  # attribution (a SSOT da assinatura de commit/PR) viaja NEVER-CLOBBER: só entra se o alvo não tem o
  # campo. Até 2026-10-05 este merge levava só hooks, e o pr.md do adotante dizia que a assinatura vinha de
  # um campo que o settings.json dele nunca recebia (sinal de campo de um hub).
  | if ($src.attribution != null) and (.attribution == null) then .attribution = $src.attribution else . end
'
