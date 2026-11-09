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
#             Hook próprio do alvo (command que a fonte não tem) e chave extra do alvo ficam — EXCETO o
#             hook que o core APOSENTOU (forma do Onion + script ausente na fonte e no alvo), que é
#             podado e anunciado no stderr (SAC-145, 2026-10-15; ver o bloco antes do jq).
#             O `permissions.deny` da fonte é somado ao do alvo (só soma, 2026-11-08); o resto de permissions é do alvo.
#             Alvo com permissions ou deny fora da forma de lista: os hooks chegam, o deny não soma, e o stderr avisa.
#             O `--diff` nomeia cada regra de deny nova e os allow do alvo que ela anula (comparação de texto).
#             Regra listada em deny-retired.tsv sai do alvo, avisada no stderr e nomeada no `--diff`. LIMITE: é por texto,
#             então regra que o adotante escreveu idêntica à aposentada também sai.
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

# Regras de deny que o core aposentou (2026-11-09): saem do alvo, só as exatas da lista. Sem isto o deny só somava, e
# regra errada nunca mais saía do adotante. A lista e o leitor dela moram ao lado deste script, sem variável que os troque.
_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_retired_json() {
  [ -f "${_HERE}/deny-retired-list.sh" ] || { echo "AVISO: leitor da lista de regras aposentadas ausente — nada foi retirado." >&2; echo '[]'; return 0; }
  bash "${_HERE}/deny-retired-list.sh" "${_HERE}/deny-retired.tsv" | jq -R . | jq -sc .
}

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
  jq -nr --slurpfile a "${A}" --slurpfile b "${B}" --argjson retired "$(_retired_json)" '
    def flat($s): [ ($s.hooks // {}) | to_entries[] | .key as $ev | .value[]? | (.matcher // null) as $mt
                    | .hooks[]? | {k: ([$ev, $mt, (.command // ((.type // "?") + ":" + ((.prompt // "") | tostring)))] | tojson),
                                   ev: $ev, mt: $mt, h: .} ];
    def hlabel($x): "\($x.ev)\(if $x.mt == null then "" else " [" + $x.mt + "]" end) \($x.h.command // ($x.h.type // "?"))";
    def show($v): if $v == null then "ausente" else ($v | tojson) end;
    # permissions.deny e allow como lista, ou vazio quando estão fora da forma (o merge recusa somar nesse caso)
    def plist($s; $k): ($s.permissions? // {}) | if type == "object" and (.[$k] | type) == "array" then .[$k] else [] end;
    def rx: gsub("(?<c>[.+?^${}()|\\[\\]\\\\])"; "\\\(.c)") | gsub("\\*"; ".*");
    def rule: (capture("^(?<t>[A-Za-z]+)\\((?<p>.*)\\)$")? // null);
    # um allow que o deny novo anula. Bash: o texto do allow casa o padrão do deny. Read: o allow nomeia o mesmo arquivo.
    # TETO: é comparação de texto; allow com curinga que só em parte se sobrepõe ao deny não aparece.
    def annuls($d; $a): ($d | rule) as $dr | ($a | rule) as $ar
      | if $dr == null or $ar == null then false
        elif $dr.t == "Bash" then $ar.t == "Bash" and ($ar.p | test("^" + ($dr.p | rx) + "$"))
        elif $dr.t == "Read" then
          ($dr.p | sub("^//\\*\\*/"; "") | sub("^~/"; "") | sub("/\\*\\*$"; "")) as $f
          | ($ar.t | IN("Read", "Edit", "Bash")) and ($ar.p | test("(^|[/ ~*])" + ($f | rx) + "($|[ /*])"))
        else false end;
    ($a[0]) as $A | ($b[0]) as $B | flat($A) as $fa | flat($B) as $fb
    | (plist($B; "deny") - plist($A; "deny")) as $newd | plist($B; "allow") as $alw
    | (plist($A; "deny") - plist($B; "deny")) as $lostd
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
      + [ $newd[] | "+ deny: \(.)" ]
      + [ $lostd[] | . as $r | if ($retired | index($r)) != null then "- deny (retirada declarada): \($r)" else "- deny (PERDIDA): \($r)" end ]
      + [ $alw[] as $al | $newd[] as $d | select(annuls($d; $al)) | "! allow anulado: \($al) (o deny vence: \($d))" ]
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
_dshape="$(jq -r 'if ((.permissions // {}) | type) != "object" then "permissions" elif (((.permissions // {}).deny // []) | type) != "array" then "permissions.deny" else "" end' "${TGT}" 2>/dev/null || true)"
[ -n "${_dshape}" ] && echo "AVISO: ${_dshape} do alvo não está na forma esperada — o deny da fonte NÃO foi somado; os hooks foram. Corrija o settings do alvo e rode de novo." >&2
[ "${_div}" = diverge ] && echo "AVISO: o attribution do alvo difere do da fonte — preservado o do alvo; confira se o padrão de assinatura da família mudou." >&2

# HOOK APOSENTADO PELO CORE (SAC-145, 2026-10-15): o refresh trata "command que a fonte não tem" como hook PRÓPRIO
# do alvo, e um hook que o core retirou tem exatamente essa forma. Medido no 1º update depois do #1129 (que
# aposentou o Stop background-state-needs-evidence.sh): o vendor apagou o script, a entrada ficou, e o adotante
# passou a ter rc 127 em TODO Stop, com o relatório dizendo "0 removidos". Poda só o que é do Onion e está
# morto: forma canônica do Onion (bash [aspas]$CLAUDE_PROJECT_DIR/.claude/hooks/X ou bash .claude/hooks/X) E
# script ausente na fonte E no alvo. Entrada morta em outra forma é do alvo: só aviso, nunca poda.
_sdir="$(cd "$(dirname "${SRC}")" && pwd)/hooks"; _tdir="$(cd "$(dirname "${TGT}")" && pwd)/hooks"
_dead='[]'
while IFS= read -r _c; do
  [ -n "${_c}" ] || continue
  _f="$(sed -n 's|.*\.claude/hooks/\([A-Za-z0-9._-]*\).*|\1|p' <<< "${_c}")"
  [ -n "${_f}" ] || continue
  { [ -e "${_sdir}/${_f}" ] || [ -e "${_tdir}/${_f}" ]; } && continue
  if grep -qE '^bash ("\$CLAUDE_PROJECT_DIR/|\$CLAUDE_PROJECT_DIR/)?\.claude/hooks/[A-Za-z0-9._-]+"?$' <<< "${_c}"; then
    _dead="$(jq -c --arg c "${_c}" '. + [$c]' <<< "${_dead}")"
    echo "PODADO: hook aposentado pelo core (script ${_f} ausente na fonte e no alvo): ${_c}" >&2
  else
    echo "AVISO: hook do alvo aponta para script ausente (${_f}) — não é da forma do Onion, NÃO podei: ${_c}" >&2
  fi
done < <(jq -r '[.hooks // {} | .[][]? | .hooks[]? | .command? | select(type == "string")] | unique[]' "${TGT}" 2>/dev/null)

_retired="$(_retired_json)"
# regra listada que a fonte ainda traz é contradição do core: fica, e o aviso diz
while IFS= read -r _r; do
  case "${_r}" in
    keep:*) echo "AVISO: regra na lista de aposentadas e ainda na fonte, mantida no alvo: ${_r#keep:}" >&2 ;;
    drop:*) echo "RETIRADA: regra de deny aposentada pelo core, removida do alvo: ${_r#drop:}" >&2 ;;
  esac
done < <(jq -r --argjson r "${_retired}" --slurpfile s "${SRC}" '(($s[0].permissions.deny? // []) | if type == "array" then . else [] end) as $sd | (.permissions.deny? // []) | if type == "array" then .[] | select(. as $x | $r | index($x) != null) | (. as $x | if ($sd | index($x)) != null then "keep:" else "drop:" end) + . else empty end' "${TGT}" 2>/dev/null || true)

jq -n \
  --argjson dead "${_dead}" \
  --argjson retired "${_retired}" \
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
  # permissions.deny (2026-11-08): a lista portátil da fonte SOMA à do alvo, sem duplicar nem apagar (deny é monotônico,
  # ver deny-monotonic.sh). Só o deny viaja: allow, sandbox e o resto de permissions seguem sendo do alvo.
  # Alvo com permissions ou deny fora da forma (texto, objeto): não mexe, para os hooks chegarem assim mesmo; o aviso sai antes do jq.
  | if (($src.permissions.deny // []) | length) > 0
       and (((.permissions // {}) | type) == "object")
       and (((.permissions // {}).deny // []) | type) == "array" then
      .permissions = (.permissions // {})
      | .permissions.deny = (((.permissions.deny // []) + $src.permissions.deny)
                             | reduce .[] as $r ([]; if index($r) == null then . + [$r] else . end))
    else . end
  # a retirada declarada: só a regra idêntica à da lista sai, inclusive se o adotante a escreveu com o mesmo texto
  | if ((.permissions | type) == "object") and ((.permissions.deny | type) == "array") then .permissions.deny -= ($retired - (($src.permissions.deny? // []) | if type == "array" then . else [] end)) else . end
  # poda do aposentado, em TODO evento do alvo (o evento pode nem existir mais na fonte); grupo que esvazia sai
  | if ($dead | length) > 0 and (.hooks | type) == "object" then
      .hooks |= with_entries(.value |= map(
        if (.hooks | type) == "array"
        then (.hooks |= map(select(((.command | type) == "string" and (.command as $c | $dead | index($c))) | not)))
             | if (.hooks | length) == 0 then empty else . end
        else . end))
    else . end
'
