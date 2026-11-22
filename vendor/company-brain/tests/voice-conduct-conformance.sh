#!/usr/bin/env bash
# Conformidade do validador de voz e conduta.
#   valid/        → rc 0 (respeitando «# Flags: ...» na 2ª linha)
#   invalid/      → rc 1 e o CONJUNTO de códigos achados é exatamente o da 1ª linha («# Mutante: CÓD [CÓD...]»)
#   unjudgeable/  → rc 2 (não deu para julgar; nunca verde nem achado)
#   template      → legível (rc 1 pelos marcadores, nunca rc 2)
#   cobertura     → todo código do esquema (semantic_rules + structural_codes) tem ao menos um mutante
#   --if-present  → arquivo ausente sai 0 (o produto é opcional)
# Data fixa, para a revisão periódica não virar falso vermelho com o tempo.
# A raiz é a pasta do motor, achada pelo próprio script (tests/..), nunca pelo git: vendorizado em outro repo,
# a raiz do git é a do hospedeiro e os caminhos relativos cairiam fora do motor.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2
dir=spec/conformance/voice-conduct
check=(python3 -I tools/voice_conduct_check.py)
today=2026-11-22
fail=0; n=0; seen_codes=""
shopt -s nullglob

flags_of() { sed -n '2s/^# Flags: //p' "$1"; }

for f in "${dir}"/valid/*.y*ml; do
  n=$((n+1)); read -r -a fl <<< "$(flags_of "${f}")"
  out="$("${check[@]}" "${f}" --today "${today}" --format tsv "${fl[@]}" 2>&1)"; rc=$?
  if [ "${rc}" -eq 0 ]; then echo "  ✓ válido ${f##*/}"; else echo "  ✗ válido ${f##*/} rc=${rc}: ${out}"; fail=1; fi
done

for f in "${dir}"/invalid/*.y*ml; do
  n=$((n+1))
  want="$(sed -n '1s/^# Mutante: //p' "${f}" | tr ' ' '\n' | grep '^VC-' | sort -u | tr '\n' ' ')"
  [ -n "${want}" ] || { echo "  ✗ ${f##*/}: sem código declarado na 1ª linha"; fail=1; continue; }
  read -r -a fl <<< "$(flags_of "${f}")"
  out="$("${check[@]}" "${f}" --today "${today}" --format tsv "${fl[@]}" 2>&1)"; rc=$?
  got="$(cut -f1 <<< "${out}" | grep '^VC-' | sort -u | tr '\n' ' ')"
  if [ "${rc}" -eq 1 ] && [ "${got}" = "${want}" ]; then echo "  ✓ mutante ${f##*/} → ${want}"; seen_codes+=" ${want}"
  else echo "  ✗ mutante ${f##*/}: esperado rc 1 e {${want}}, veio rc=${rc} e {${got}}"; fail=1; fi
done

for f in "${dir}"/unjudgeable/*.y*ml; do
  n=$((n+1))
  "${check[@]}" "${f}" --today "${today}" > /dev/null 2>&1; rc=$?
  if [ "${rc}" -eq 2 ]; then echo "  ✓ não julgável ${f##*/} → rc 2"; else echo "  ✗ não julgável ${f##*/}: esperado rc 2, veio ${rc}"; fail=1; fi
done

n=$((n+1))
out="$("${check[@]}" templates/company-brain-context/voice-conduct.yaml --today "${today}" --format tsv --allow-draft 2>&1)"; rc=$?
if [ "${rc}" -eq 1 ] && grep -q $'^VC-PLACEHOLDER\t' <<< "${out}"; then echo "  ✓ template legível e reprovado pelos marcadores"
else echo "  ✗ template: esperado rc 1 com VC-PLACEHOLDER, veio rc=${rc}"; fail=1; fi

n=$((n+1))
"${check[@]}" "${dir}/nao-existe.yaml" --if-present > /dev/null 2>&1; rc=$?
if [ "${rc}" -eq 0 ]; then echo "  ✓ --if-present sem arquivo → rc 0"; else echo "  ✗ --if-present sem arquivo: veio ${rc}"; fail=1; fi
"${check[@]}" "${dir}/nao-existe.yaml" > /dev/null 2>&1; rc=$?
if [ "${rc}" -eq 2 ]; then echo "  ✓ sem --if-present, arquivo ausente → rc 2"; else echo "  ✗ arquivo ausente sem --if-present: veio ${rc}"; fail=1; fi

declared="$(grep -oE 'VC-[A-Z-]+[A-Z]' spec/voice-conduct/v2.schema.yaml | sort -u)"
for code in ${declared}; do
  hit=0; for c in ${seen_codes}; do [ "${c}" = "${code}" ] && { hit=1; break; }; done
  [ "${hit}" -eq 1 ] || { echo "  ✗ cobertura: ${code} não tem mutante"; fail=1; }
done

if [ "${fail}" -ne 0 ]; then echo "✗ conformidade de voz e conduta VERMELHA (${n} casos)"; exit 1; fi
echo "✓ conformidade de voz e conduta verde: ${n} casos, $(wc -w <<< "${declared}") códigos cobertos"
