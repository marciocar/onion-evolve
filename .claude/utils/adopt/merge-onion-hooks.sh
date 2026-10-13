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

# ── MODO --diff <antes.json> <depois.json>: o diff de hooks que o RELATÓRIO do --update cola ─────────
# Por que existe (2026-10-13, update de um adotante): o relatório comparava só evento, matcher e
# command, então NÃO via propriedade nova — o `onFailure: block` acrescentado pelo refresh a 4 hooks
# que já existiam — e afirmou "as outras chaves estão idênticas" em falso. Aqui a identidade do hook é
# (evento, matcher, command — ou type+prompt para hook sem command) e a comparação é da ENTRADA INTEIRA,
# por valor: o `==` do jq é estrutural, então ordem de chaves não gera "mudou" falso. Cada hook alterado
# lista as chaves que mudaram (antes→depois). Chave de topo diferente (permissions, attribution…) é
# comparada com as listas ORDENADAS (ordem da allowlist não é mudança) e
# nomeada numa linha à parte. Somente leitura; rc 0 = diff impresso (com ou sem mudança), 2 = uso, 3 = sem jq.
if [ "${1:-}" = "--diff" ]; then
  A="${2:-}"; B="${3:-}"
  [ -f "${A}" ] && [ -f "${B}" ] || { echo "uso: merge-onion-hooks.sh --diff <antes.json> <depois.json>" >&2; exit 2; }
  command -v jq >/dev/null 2>&1 || { echo "AVISO: jq ausente — diff de hooks NÃO MEDIDO." >&2; exit 3; }
  jq -nr --slurpfile a "${A}" --slurpfile b "${B}" '
    def flat($s): [ ($s.hooks // {}) | to_entries[] | .key as $ev | .value[]? | (.matcher // null) as $mt
                    | .hooks[]? | {k: ([$ev, $mt, (.command // ((.type // "?") + ":" + ((.prompt // "") | tostring)))] | tojson),
                                   ev: $ev, mt: $mt, h: .} ];
    def hlabel($x): "\($x.ev)\(if $x.mt == null then "" else " [" + $x.mt + "]" end) \($x.h.command // ($x.h.type // "?"))";
    def show($v): if $v == null then "ausente" else ($v | tojson) end;
    ($a[0]) as $A | ($b[0]) as $B | flat($A) as $fa | flat($B) as $fb
    | ($fa | map({key: .k, value: .}) | from_entries) as $ma
    | ($fb | map({key: .k, value: .}) | from_entries) as $mb
    | ([ $fb[] | select($ma[.k] == null) ]) as $add
    | ([ $fa[] | select($mb[.k] == null) ]) as $del
    | ([ $fb[] | select($ma[.k] != null and $ma[.k].h != .h) ]) as $chg
    | ([ $fb[] | select($ma[.k] != null and $ma[.k].h == .h) ] | length) as $same
    | ([ ($A | keys[]), ($B | keys[]) ] | unique | map(select(. != "hooks" and ($A[.] | walk(if type == "array" then sort else . end)) != ($B[.] | walk(if type == "array" then sort else . end))))) as $top
    | ( [ $add[] | "+ \(hlabel(.))" ]
      + [ $del[] | "- \(hlabel(.))" ]
      + [ $chg[] | . as $x | $ma[$x.k].h as $o
          | "~ \(hlabel($x)): " + ([ ([($o | keys[]), ($x.h | keys[])] | unique)[] | select($o[.] != $x.h[.])
                                    | "\(.) \(show($o[.]))→\(show($x.h[.]))" ] | join(", ")) ]
      + (if ($top | length) > 0 then [ "≠ chaves de topo diferentes: \($top | join(", "))" ] else [] end)
      + [ "── hooks: \($fa | length) → \($fb | length) · \($add | length) adicionado(s) · \($del | length) removido(s) · \($chg | length) alterado(s) · \($same) idêntico(s) (entrada inteira)" ]
      )[]' || { echo "ERRO: diff de hooks falhou (JSON inválido?) — NÃO MEDIDO; não escreva 'idêntico' no relatório." >&2; exit 3; }
  exit 0
fi

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
    # hook Onion do alvo FORA do grupo certo (2026-10-12, --update do adotante KG-SSOT: o veto direct-provider-api
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
