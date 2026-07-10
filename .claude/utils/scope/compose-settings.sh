#!/usr/bin/env bash
# =============================================================================
# compose-settings.sh — compõe um settings.json EFETIVO de N camadas de escopo.
#
# RFC-0005 (herança de escopo), PLANO 2 (configuração): o `settings.json` do Claude Code NÃO herda
# pela árvore de diretórios (é self-contained por diretório) — é o único gap de engenharia real. Este
# helper generaliza o merge 2-camadas do `merge-onion-hooks.sh` para N camadas de escopo:
#     framework → empresa → time → pessoa   (base → mais específico)
#
# Semântica de merge por-chave (never-clobber, type-aware — modelo strategic-merge):
#   - objetos  : recursam (merge profundo)
#   - arrays   : unem + dedup preservando ordem (hooks, permissions.allow/deny)
#   - escalares: last-wins (a camada mais específica sobrepõe — polimorfismo)
#
# Proveniência-por-chave (RFC-0005 §2/§5 — paridade `git config --show-scope`): o modo --show-scope
# responde, POR CHAVE do composto, qual camada setou o valor, quem foi sobreposto e a origem de cada
# elemento de array. Implementado como merge anotado ESPELHO (PROVMERGE) do DEEPMERGE; a cada execução
# o script verifica a invariante strip(provtree) == compose (declarado≠verificado) — divergência = exit 4.
#
# Uso:
#   compose-settings.sh <layer1.json> ... <layerN.json>            → settings.json composto (stdout)
#   compose-settings.sh --show-scope [--json] [--role <source|adopted>] [--form <full|docs-only|in-place>] \
#                       [label=]<layer1.json> ... [label=]<layerN.json>
#     → proveniência por chave. Camadas aceitam rótulo `label=path` (ex.: empresa=.claude/settings.json);
#       sem rótulo, usa o basename. --role/--form anotam a dimensão papel/forma-de-adoção (§4.1) no
#       cabeçalho/meta — não alteram o merge. --provenance é alias de --show-scope.
#
# Saída --show-scope (texto): `<scope>\t<dotted.path>=<valor>` (+ `# sobrepõe: ...` / `# merged`).
# Saída --show-scope --json : {meta:{layers,role,form}, keys:{<path>:{value,scope,status,overrides}}}
#   status: set (1 camada) · overridden (redefinido; vencedor + overrides[]) · merged (array união).
#
# Gracioso: sem jq → exit 3 (como merge-onion-hooks.sh — não corrompe). JSON inválido/ausente/uso → exit 2.
# Invariante de proveniência violada → exit 4. Determinístico (ordem de descoberta, nunca sort de locale).
# Exercitado por lint-selftest.sh (run_compose_settings_selftests + run_show_scope_selftests).
# =============================================================================
set -uo pipefail

usage() {
  echo "uso: compose-settings.sh [--show-scope|--provenance] [--json] [--role <source|adopted>] [--form <full|docs-only|in-place>] [label=]<layer1.json> ... [label=]<layerN.json>" >&2
}

MODE=""; JSON=""; ROLE=""; FORM=""
SPECS=()
while [ "$#" -gt 0 ]; do case "$1" in
  --show-scope|--provenance) MODE="scope"; shift ;;
  --json) JSON=1; shift ;;
  --role) ROLE="${2:-}"; shift 2 ;;
  --form) FORM="${2:-}"; shift 2 ;;
  -*) usage; exit 2 ;;
  *) SPECS+=("$1"); shift ;;
esac; done

[ "${#SPECS[@]}" -ge 1 ] || { usage; exit 2; }
[ -n "${JSON}" ] && [ "${MODE}" != "scope" ] && { echo "ERRO: --json requer --show-scope." >&2; usage; exit 2; }
case "${ROLE}" in ""|source|adopted) ;; *) echo "ERRO: --role inválido: '${ROLE}' (source|adopted)." >&2; exit 2 ;; esac
case "${FORM}" in ""|full|docs-only|in-place) ;; *) echo "ERRO: --form inválido: '${FORM}' (full|docs-only|in-place)." >&2; exit 2 ;; esac
command -v jq >/dev/null 2>&1 || { echo "compose-settings: jq ausente — não é possível compor (exit 3)." >&2; exit 3; }

# Camadas: `label=path` explícito ou basename como rótulo (compat com a chamada posicional).
LABELS=(); PATHS=()
for s in "${SPECS[@]}"; do
  if [[ "$s" == *=* ]] && [[ "${s%%=*}" =~ ^[A-Za-z0-9_.-]+$ ]]; then
    LABELS+=("${s%%=*}"); PATHS+=("${s#*=}")
  else
    LABELS+=("$(basename "$s")"); PATHS+=("$s")
  fi
done

for f in "${PATHS[@]}"; do
  [ -f "$f" ] || { echo "ERRO: camada ausente: $f" >&2; exit 2; }
  jq empty "$f" 2>/dev/null || { echo "ERRO: JSON inválido: $f" >&2; exit 2; }
done

# Deep-merge type-aware (dedup preserva ordem — arrays de hooks/permissions).
DEEPMERGE='
def dedup: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
def deepmerge(a; b):
  if   (a|type)=="object" and (b|type)=="object"
  then reduce (b|keys_unsorted[]) as $k (a; .[$k] = (if (a|has($k)) then deepmerge(a[$k]; b[$k]) else b[$k] end))
  elif (a|type)=="array"  and (b|type)=="array"  then (a + b) | dedup
  else b end;
'

# Fold da base (mais genérica) p/ a mais específica.
compose() {
  local acc f
  acc="$(cat "${PATHS[0]}")"
  for f in "${PATHS[@]:1}"; do
    acc="$(jq -n "${DEEPMERGE} deepmerge(\$a; \$b)" --argjson a "$acc" --argjson b "$(cat "$f")")" \
      || { echo "ERRO: falha ao compor camada $f" >&2; exit 2; }
  done
  printf '%s\n' "$acc"
}

if [ "${MODE}" != "scope" ]; then compose; exit $?; fi

# ---------------------------------------------------------------------------
# --show-scope: merge anotado ESPELHO do DEEPMERGE. Árvore anotada:
#   leaf {t,v,src[]} (último src = vencedor; anteriores = sombreados) ·
#   arr  {t,items:[{v,src}]} (src = 1ª camada que trouxe o elemento) ·
#   obj  {t,c:{...}}. `strip` reconstrói o composto — invariante checada abaixo.
# ---------------------------------------------------------------------------
PROVLIB='
def dedupv: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
def annotate($L):
  if type=="object" then {t:"obj", c: with_entries(.value |= annotate($L))}
  elif type=="array" then {t:"arr", items: [.[] | {v:., src:$L}]}
  else {t:"leaf", v:., src:[$L]} end;
def labels_of:
  (if .t=="leaf" then .src
   elif .t=="arr" then [.items[].src]
   else [.c[] | labels_of] | add // [] end) | dedupv;
def pmerge(a; b):
  if a.t=="obj" and b.t=="obj" then
    {t:"obj", c: (reduce (b.c|keys_unsorted[]) as $k (a.c;
        .[$k] = (if (a.c|has($k)) then pmerge(a.c[$k]; b.c[$k]) else b.c[$k] end)))}
  elif a.t=="arr" and b.t=="arr" then
    {t:"arr", items: (reduce (a.items + b.items)[] as $x ([]; if any(.[]; .v == $x.v) then . else . + [$x] end))}
  elif b.t=="leaf" then {t:"leaf", v:b.v, src:(((a|labels_of) + b.src) | dedupv)}
  else b + {shadows: (a|labels_of)} end;
def strip:
  if .t=="leaf" then .v
  elif .t=="arr" then [.items[].v]
  else .c | with_entries(.value |= strip) end;
'

RENDER_TEXT='
def walk_lines($p):
  if .t=="obj" then
    .c | to_entries[] | .key as $k | .value | walk_lines(if $p=="" then $k else $p+"."+$k end)
  elif .t=="arr" then
    ([.items[].src] | dedupv) as $ls
    | (.shadows // []) as $sh
    | .items as $it
    | range(0; $it|length) as $i
    | $it[$i].src + "\t" + $p + "[" + ($i|tostring) + "]=" + ($it[$i].v|tojson)
      + (if ($ls|length)>1 and $it[$i].src != $ls[0] then "\t# merged" else "" end)
      + (if ($sh|length)>0 and $i==0 then "\t# sobrepõe: " + ($sh|join(", ")) else "" end)
  else
    .src[-1] + "\t" + $p + "=" + (.v|tojson)
    + (if (.src|length)>1 then "\t# sobrepõe: " + (.src[:-1]|join(", ")) else "" end)
  end;
'

RENDER_JSON='
def walk_json($p):
  if .t=="obj" then
    .c | to_entries[] | .key as $k | .value | walk_json(if $p=="" then $k else $p+"."+$k end)
  elif .t=="arr" then
    ([.items[].src] | dedupv) as $ls
    | {($p): ({status:(if ($ls|length)>1 then "merged" else "set" end),
               elements:[.items[] | {value:.v, scope:.src}]}
              + (if ($ls|length)==1 then {scope:$ls[0]} else {} end)
              + (if ((.shadows//[])|length)>0 then {overrides:.shadows} else {} end))}
  else
    {($p): ({value:.v, scope:.src[-1], status:(if (.src|length)>1 then "overridden" else "set" end)}
            + (if (.src|length)>1 then {overrides:.src[:-1]} else {} end))}
  end;
'

# Fold anotado (mesma ordem base→específico do compose).
prov="$(jq --arg L "${LABELS[0]}" "${PROVLIB} annotate(\$L)" "${PATHS[0]}")" || exit 2
i=1
while [ "$i" -lt "${#PATHS[@]}" ]; do
  layer="$(jq --arg L "${LABELS[$i]}" "${PROVLIB} annotate(\$L)" "${PATHS[$i]}")" || exit 2
  prov="$(jq -n "${PROVLIB} pmerge(\$a; \$b)" --argjson a "$prov" --argjson b "$layer")" \
    || { echo "ERRO: falha ao anotar camada ${PATHS[$i]}" >&2; exit 2; }
  i=$((i+1))
done

# Invariante auto-verificável: a proveniência NUNCA deriva do merge real (declarado≠verificado).
composed="$(compose)" || exit 2
stripped="$(printf '%s' "$prov" | jq "${PROVLIB} strip")"
if [ "$(printf '%s' "$composed" | jq -cS .)" != "$(printf '%s' "$stripped" | jq -cS .)" ]; then
  echo "ERRO: invariante de proveniência violada — strip(provtree) != compose (exit 4)." >&2
  exit 4
fi

# Meta das camadas (ordem de composição) + dimensão role/forma (§4.1).
layers_meta="[]"
i=0
while [ "$i" -lt "${#PATHS[@]}" ]; do
  layers_meta="$(jq -n --argjson acc "$layers_meta" --arg l "${LABELS[$i]}" --arg p "${PATHS[$i]}" '$acc + [{label:$l, path:$p}]')"
  i=$((i+1))
done

if [ -n "${JSON}" ]; then
  jq -n "${PROVLIB} ${RENDER_JSON}"' {meta: ({layers:$layers}
        + (if $role != "" then {role:$role} else {} end)
        + (if $form != "" then {form:$form} else {} end)),
     keys: ([$tree | walk_json("")] | add // {})}' \
    --argjson tree "$prov" --argjson layers "$layers_meta" --arg role "${ROLE}" --arg form "${FORM}"
else
  header="# layers: ${LABELS[*]}"
  [ -n "${ROLE}" ] && header="${header} · role: ${ROLE}"
  [ -n "${FORM}" ] && header="${header} · form: ${FORM}"
  printf '%s\n' "$header"
  printf '%s' "$prov" | jq -r "${PROVLIB} ${RENDER_TEXT} walk_lines(\"\")"
fi
