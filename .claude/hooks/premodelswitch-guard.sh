#!/usr/bin/env bash
# PreModelSwitch + PostModelSwitch — guarda do modelo da SESSÃO (Onion, selada pelo maestro 2026-09-02:
# "1 + 3": VETA downgrade, LOGA sempre). 2026-09-03: escada com PISO (session_floor) — piso so por fallback; campo ladder no log.
#
# ── O QUE MEDE (não o que declara) ────────────────────────────────────────────────────────────
# O evento existe e dispara (E_PREMODELSWITCH_DISPARO_MEDIDO_0902, Claude Code >= 2.1.251): payload
# com from_model/to_model/requested_model/source e o custo de cache da troca; exit 2 no Pre = a
# troca é BLOQUEADA ("model switch blocked by a PreModelSwitch hook"). É o único gatilho de
# plataforma que dispara POR MODELO — a diretriz permanente "sempre latest, máximo do modelo"
# (always-latest-max-model) tinha só prosa até aqui.
#
# ── BASELINE (dado, não prosa) ────────────────────────────────────────────────────────────────
# `session_models:` no eixo E6-fronteira-modelos de docs/onion/radar-baselines.yaml — a saída DATADA
# do radar de modelos, atualizada por rodada (/meta:radar E6), nunca à mão. to_model fora da lista =
# downgrade = VETO com a rota de escape na mensagem. Sufixo de contexto (`[1m]`) é ignorado no match.
#
# ── FRONTEIRAS DECLARADAS ─────────────────────────────────────────────────────────────────────
#  · Sem o arquivo de baselines (adotante via /meta:adopt não o carrega) a guarda se DESARMA e loga
#    `disarmed` — não se veta o /model de uma casa que não declarou lineup. Arquivo presente SEM
#    `session_models:` legível = fail-loud (VETO + mensagem): guarda que não sabe o que cobrar nunca
#    afirma conformidade (P0 da REGRA 30); o lint (REGRA 65) cobra a chave no arquivo real.
#  · Só a sessão principal emite o evento (subagentes herdam por env, não por /model).
#  · Em processo < 2.1.251 o hook NÃO É CHAMADO — fail-open por ausência; é exatamente o buraco que
#    session-version-drift.sh (UserPromptSubmit) denuncia. As duas guardas são um par.
#  · Log em .claude/sessions/model-switch.jsonl (gitignorado por default): Pre grava a decisão
#    (allow|block|disarmed|unreadable), Post grava `applied` — a série por modelo que a REGRA 65
#    não tinha (re-medição de estratégia por modelo, não só por cc_version).
set -uo pipefail
input="$(cat 2>/dev/null)" || input=""
[ -n "${input}" ] || exit 0
read -r ev from to req src ctx usd < <(printf '%s' "${input}" | python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception: d={}
g=lambda k: str(d.get(k,"") or "").replace(" ","_") or "-"
print(g("hook_event_name"),g("from_model"),g("to_model"),g("requested_model"),g("source"),g("context_tokens"),g("estimated_cache_write_usd"))' 2>/dev/null) || exit 0
[ -n "${ev:-}" ] && [ "${ev}" != "-" ] || exit 0
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
bl="${ONION_RADAR_BASELINES:-${root}/docs/onion/radar-baselines.yaml}"
log="${ONION_MODEL_SWITCH_LOG:-${root}/.claude/sessions/model-switch.jsonl}"
_log() {  # <decision>
  mkdir -p "$(dirname "${log}")" 2>/dev/null || return 0
  printf '{"ts":"%s","event":"%s","from":"%s","to":"%s","requested":"%s","source":"%s","context_tokens":"%s","cache_write_usd":"%s","decision":"%s","ladder":"%s","session":"%s"}\n' \
    "$(date -Is 2>/dev/null || date)" "${ev}" "${from}" "${to}" "${req}" "${src}" "${ctx}" "${usd}" "$1" "${ladder:-}" "${CLAUDE_CODE_SESSION_ID:-}" >> "${log}" 2>/dev/null || true
}
if [ "${ev}" = "PostModelSwitch" ]; then _log applied; exit 0; fi
[ "${ev}" = "PreModelSwitch" ] || exit 0
if [ ! -f "${bl}" ]; then _log disarmed; exit 0; fi
# lista sob `session_models:` (uma chave por linha; o radar é awk, e esta guarda também)
allowed="$(awk '
  /^[[:space:]]*session_models:[[:space:]]*(#.*)?$/ {f=1; next}
  f && /^[[:space:]]*-[[:space:]]*/ { sub(/^[[:space:]]*-[[:space:]]*/,""); sub(/[[:space:]]*#.*$/,""); gsub(/"/,""); if ($0!="") print; next }
  f { f=0 }' "${bl}" 2>/dev/null)"
if [ -z "${allowed}" ]; then
  _log unreadable
  echo "GUARDA-PREMODELSWITCH: ${bl} existe mas não tem 'session_models:' legível — a guarda não sabe o que cobrar e por isso NÃO libera a troca (fail-loud). Corrija o eixo E6 do baseline (/meta:radar E6-fronteira-modelos)." >&2
  exit 2
fi
to_base="${to%%\[*}"      # claude-fable-5-1[1m] → claude-fable-5-1
from_base="${from%%\[*}"
# PISO (2026-09-03): session_floor e alcancavel so por fallback (source != picker) — nunca pelo /model.
floor="$(awk '/^[[:space:]]*session_floor:[[:space:]]*/ { sub(/^[[:space:]]*session_floor:[[:space:]]*/,""); sub(/[[:space:]]*#.*$/,""); gsub(/"/,""); print; exit }' "${bl}" 2>/dev/null)"
# posicao na escada (0 = primario … n = piso): sobe = restored, desce = degraded, igual = same
_pos() { local i=0 m; while IFS= read -r m; do [ "$m" = "$1" ] && { echo "$i"; return; }; i=$((i+1)); done < <(printf '%s\n' "${allowed}"; [ -n "${floor}" ] && printf '%s\n' "${floor}"); echo "-1"; }
pf="$(_pos "${from_base}")"; pt="$(_pos "${to_base}")"
ladder=same; [ "${pt}" -gt "${pf}" ] && [ "${pf}" -ge 0 ] && ladder=degraded; [ "${pt}" -lt "${pf}" ] && [ "${pt}" -ge 0 ] && ladder=restored
if [ -n "${floor}" ] && [ "${to_base}" = "${floor}" ]; then
  if [ "${src}" = "picker" ]; then
    _log block
    echo "GUARDA-PREMODELSWITCH: troca ${from} → ${to} NEGADA — '${floor}' é o PISO da escada (session_floor): só por fallback automático (sobrecarga/cota), nunca pelo /model. Para trabalhar abaixo do lineup de propósito, edite session_floor/session_models na rodada E6." >&2
    exit 2
  fi
  _log allow
  echo "GUARDA-PREMODELSWITCH: sessão DEGRADADA ao piso '${floor}' por fallback (${src}). Volte ao primário com /model assim que houver capacidade; o aviso repete a cada prompt." >&2
  exit 0
fi
if printf '%s\n' "${allowed}" | grep -qxF "${to_base}"; then _log allow; exit 0; fi
_log block
echo "GUARDA-PREMODELSWITCH: troca ${from} → ${to} NEGADA — '${to_base}' não está em session_models do eixo E6 de docs/onion/radar-baselines.yaml ($(printf '%s' "${allowed}" | tr '\n' ' ')). Diretriz da casa: sempre o latest/máximo do lineup; downgrade só por rodada do radar (/meta:radar E6-fronteira-modelos) que atualize o baseline — nunca por /model." >&2
exit 2
