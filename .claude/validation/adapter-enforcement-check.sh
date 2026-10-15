#!/usr/bin/env bash
# =============================================================================
# adapter-enforcement-check.sh — cada adapter SDAAL declara ONDE o seu contrato é cobrado (REGRA 107)
#
# POR QUÊ (SAC-142, parte D; decisão do maestro de 2026-10-15, D_COBRAR_NA_SAIDA_E_NO_TRANSPORTE em
#   docs/evolution/research/machinery-enforcement-2026-10/): "comandos, skills, maquinaria foram feitos para serem
#   EXECUTADOS e não interpretados", e "isso tem que ser uma obrigação em adapters". Medido no mesmo dia: das 5 raízes
#   SDAAL só o task-manager declarava contrato legível por máquina; o forge não cobrava a criação de PR, e trust e
#   de-identification não tinham cobrança nenhuma no ponto de uso. Adapter em prosa sem ponto de cobrança é contrato
#   que só vale se a sessão lembrar — o modo de falha que a casa mede há meses.
#
# O QUE CONFERE (a lista é DERIVADA, nunca digitada):
#   · raiz = `.claude/utils/<r>/` com `interface.md` E `adapters/`;
#   · adapter = `adapters/*.md` sem o marcador `<!-- adapter-auxiliar: <adapter> -->` nas 5 primeiras linhas;
#   · o arquivo irmão `.claude/utils/<r>/enforcement.tsv` (no molde do capabilities.tsv; dentro da interface.md
#     estourava o teto da REGRA 5 do núcleo SDAAL) tem uma linha `<adapter><TAB><forma>:<valor>` por adapter,
#     comentários com '#', e forma no enum fechado exe | hook | validator | none:
#       exe:<caminho>        o arquivo existe;
#       hook:<caminho>       existe E está registrado no .claude/settings.json;
#       validator:<caminho>  existe E o lint-artifacts.sh o chama (ou é o próprio lint);
#       none:<motivo>        traz "gatilho:" — a ausência é DECLARADA e datável, nunca silenciosa.
#   HARD: raiz sem bloco, adapter sem linha, linha de adapter que não existe, forma fora do enum, caminho que não
#   existe, hook não registrado, validador fora do lint, none sem gatilho, marcador auxiliar apontando para adapter
#   inexistente. SOFT: o passivo de `none:` (a saúde é este número diminuindo).
#   Em repo DERIVADO (.claude/.onion-version presente), hook não registrado e validador fora do lint descem a SOFT: o
#   settings.json e o lint de lá são do adotante.
#
# USO  : adapter-enforcement-check.sh [<repo_root>] [--format tsv]
# SAÍDA: TSV severidade·código·caminho·mensagem (ou humano) · EXIT 0 julgou (com ou sem achado) · 2 uso inválido
# Bancada: run_adapter_enforcement_selftests.
# =============================================================================
set -uo pipefail
ROOT="."; FMT=human
for a in "$@"; do case "$a" in --format) ;; tsv|--format=tsv) FMT=tsv ;; -*) echo "uso: adapter-enforcement-check.sh [<repo_root>] [--format tsv]" >&2; exit 2 ;; *) ROOT="$a" ;; esac; done
cd "${ROOT}" 2>/dev/null || { echo "adapter-enforcement-check: repo_root inválido: ${ROOT}" >&2; exit 2; }

DERIVED=0; [ -f .claude/.onion-version ] && DERIVED=1
LINT=.claude/validation/lint-artifacts.sh
n_none=0 n_adapters=0 n_roots=0
_out() { if [ "${FMT}" = tsv ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"; else printf '  ✗ [%s] %s: %s\n' "$1" "$3" "$4"; fi; }
_soft_if_derived() { [ "${DERIVED}" = 1 ] && echo SOFT || echo HARD; }

for itf in .claude/utils/*/interface.md; do
  [ -f "${itf}" ] || continue
  rdir="${itf%/interface.md}"; [ -d "${rdir}/adapters" ] || continue
  n_roots=$((n_roots+1)); root="${rdir##*/}"
  declare -A have=() aux=()
  for f in "${rdir}"/adapters/*.md; do
    [ -f "${f}" ] || continue
    b="${f##*/}"; b="${b%.md}"
    m="$(head -5 "${f}" | sed -n 's/^<!-- adapter-auxiliar: *\([A-Za-z0-9_-]*\) *-->.*/\1/p' | head -1)"
    if [ -n "${m}" ]; then aux["${b}"]="${m}"; else have["${b}"]=0; n_adapters=$((n_adapters+1)); fi
  done
  for b in "${!aux[@]}"; do
    [ -n "${have[${aux[$b]}]+x}" ] || _out HARD AUXILIAR-ORFAO "${rdir}/adapters/${b}.md" "marcador adapter-auxiliar aponta para '${aux[$b]}', que não é adapter de ${root}"
  done
  etsv="${rdir}/enforcement.tsv"
  blk="$(grep -v '^[[:space:]]*#' "${etsv}" 2>/dev/null | grep -v '^[[:space:]]*$' || true)"
  if [ -z "${blk}" ]; then
    _out HARD SEM-DECLARACAO "${etsv}" "a raiz ${root} não tem ${etsv} (ou ele está vazio) — onde cada adapter é cobrado?"
    unset have aux; continue
  fi
  itf="${etsv}"
  while IFS=$'\t' read -r name decl; do
    [ -n "${name}" ] || continue
    if [ -z "${have[${name}]+x}" ]; then _out HARD ADAPTER-INEXISTENTE "${itf}" "linha para '${name}', que não existe em ${rdir}/adapters/"; continue; fi
    have["${name}"]=1
    form="${decl%%:*}"; val="${decl#*:}"
    case "${form}" in
      exe)       [ -f "${val}" ] || _out HARD CAMINHO-AUSENTE "${itf}" "${name}: exe:${val} não existe" ;;
      hook)      if [ ! -f "${val}" ]; then _out HARD CAMINHO-AUSENTE "${itf}" "${name}: hook:${val} não existe"
                 elif ! grep -qF "${val}" .claude/settings.json 2>/dev/null; then _out "$(_soft_if_derived)" HOOK-NAO-REGISTRADO "${itf}" "${name}: hook:${val} não está no .claude/settings.json — hook não registrado nunca dispara"; fi ;;
      validator) if [ ! -f "${val}" ]; then _out HARD CAMINHO-AUSENTE "${itf}" "${name}: validator:${val} não existe"
                 elif [ "${val}" != "${LINT}" ] && ! grep -qF "${val##*/}" "${LINT}" 2>/dev/null; then _out "$(_soft_if_derived)" VALIDADOR-FORA-DO-LINT "${itf}" "${name}: validator:${val} não é chamado pelo ${LINT}"; fi ;;
      none)      n_none=$((n_none+1)); grep -q 'gatilho:' <<< "${val}" || _out HARD NONE-SEM-GATILHO "${itf}" "${name}: none: sem 'gatilho:' — ausência de cobrança tem de dizer o que a pediria" ;;
      *)         _out HARD FORMA-FORA-DO-ENUM "${itf}" "${name}: forma '${form}' fora de exe|hook|validator|none" ;;
    esac
  done <<< "${blk}"
  for b in "${!have[@]}"; do
    [ "${have[$b]}" = 1 ] || _out HARD ADAPTER-SEM-COBRANCA "${rdir}/adapters/${b}.md" "o adapter ${root}/${b} não declara onde é cobrado em ${itf}"
  done
  unset have aux
done
[ "${n_none}" -gt 0 ] && _out SOFT PASSIVO "${LINT}" "${n_none} de ${n_adapters} adapter(s) em ${n_roots} raiz(es) SDAAL sem cobrança (none:, com gatilho) — a saúde é este número diminuindo"
[ "${FMT}" = tsv ] || echo "adapter-enforcement: ${n_roots} raiz(es), ${n_adapters} adapter(s), ${n_none} sem cobrança declarada"
exit 0
