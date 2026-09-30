#!/usr/bin/env bash
# ===========================================================================
# kb-applies-to-check.sh — KB que documenta artefato de TERCEIRO declara a QUE VERSÃO se aplica.
#
# ── POR QUE EXISTE (reforço do maestro, 2026-09-30, com o campo e o escopo selados por ele) ──
# "Documentações devem seguir versões." A casa já tinha `verified_at` — QUANDO alguém olhou — e não
# tinha como dizer A QUE o documento se aplica. As duas dimensões são independentes e as duas são
# necessárias: carimbo de data sem versão não responde "isto vale para a MINHA instalação?", e é
# justamente a pergunta que faz alguém abrir uma KB de plataforma.
#
# O par bi-temporal já existia no corpus de PESQUISA (`valid_from` × `verified_at`, 132 usos medidos)
# e quase não chegou às KBs de ferramenta — medido em 2026-09-30: **1 das 10** KBs de tools/+platforms
# declarava a versão do que documentava (`tools/librechat-agent-mcp.md`, que já trazia `applies_to`).
# A 1ª redação desta linha dizia ZERO; corrigida por passada adversarial. O número menor não fragiliza
# a regra — mostra que a convenção nasceu no uso antes de virar guarda, que é o melhor caso.
#
# ── A AMBIGUIDADE QUE ISTO DESFAZ NÃO É HIPOTÉTICA ───────────────────────────────────────
# `version:` em KB significava duas coisas diferentes em arquivos diferentes: na maioria é a versão
# DA PRÓPRIA KB (`versao: 1.0.0`), mas a KB do Runflow usava `version: "@runflow-ai/sdk 1.6.2"` para a
# versão do ALVO. Reusar `version:` gravaria a ambiguidade; `applies_to:` a desfaz.
#
# ── COBRA AS DUAS COISAS, e a razão é o defeito que originou tudo ─────────────────────────
# Uma passada adversarial de 2026-09-30 provou que um `verified_at` escrito SEM o bloco `---` é PROSA:
# o extrator do `doctrine-freshness.sh` devolve vazio, e o carimbo fica invisível ao gate que a própria
# KB invocava. Logo exigir só o campo seria fail-open: um `applies_to` solto passaria como cumprido e
# voltaria a ser invisível. A guarda exige bloco `---` presente E o campo DENTRO dele.
#
# ── ESCOPO, selado: `tools/` + `platforms/` ──────────────────────────────────────────────
# São as pastas cujo PROPÓSITO é documentar artefato de terceiro. O escopo "por forma" (a KB que cita
# versão no corpo declara o campo) foi medido e REJEITADO: 55 das 109 KBs citam versão no corpo, e a
# maioria é menção incidental — um ADR que cita uma versão de passagem, exemplos de padrão. Cobrar
# delas seria falso positivo em massa. KB fora dessas pastas entra por DECISÃO, não por varredura.
#
# ── O QUE FICA DE FORA, dito em voz alta (achado da passada adversarial de 2026-09-30) ────
# `patterns/glpi-zoho-ticket-to-task.md` documenta DOIS produtos de terceiro e vive em `patterns/` —
# ou seja, o mesmo commit que criou esta regra entregou, dentro da letra dela, o artefato que ela
# descreve. O campo foi escrito lá de qualquer forma (é o certo), mas a VARREDURA segue nas duas
# pastas seladas: expandir por pasta cobraria dezenas de KBs de padrão da casa e o passivo explodiria.
# GATILHO nomeado para expandir: uma KB fora de tools/+platforms caducar em uso real por falta do
# campo. Até lá, quem escreve KB de terceiro em outra pasta declara o campo por convenção, não por gate.
#
# ── CATRACA, no idioma das REGRAS 42/45/49 ───────────────────────────────────────────────
# Isenção legítima existe (KB que documenta padrão DA CASA, não software de terceiro) e vai para o
# baseline com a razão escrita. O baseline SÓ ENCOLHE; KB nova nessas pastas sem o campo é HARD.
#
# Saída: uma linha por achado, prefixada por `REGRA 93: `. Exit: 0 ok · 1 achado · 3 não pude julgar.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_kb_applies_to_selftests).
# ===========================================================================
set -uo pipefail

REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
MODE="${2:-scan}"
[ "${1:-}" = "--emit-baseline" ] && { REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; MODE=--emit-baseline; }
BASELINE="${REPO}/.claude/validation/kb-applies-to-baseline.txt"
KBDIR="${REPO}/docs/knowledge-base"
[ -d "${KBDIR}" ] || { echo "kb-applies-to: docs/knowledge-base ausente em ${REPO} — nada a medir." >&2; exit 3; }

# O extrator É O DO GATE: lê só DENTRO do primeiro bloco `---`. Campo fora dele não conta, porque é
# exatamente isso que o gate de frescor não vê.
_field_in_fm() {
  awk -v k="$2" '
    NR==1 && $0 != "---" { exit }        # sem bloco na 1a linha, não há frontmatter
    NR>1 && $0 == "---"  { exit }        # fim do bloco
    NR>1 && index($0, k ":") == 1 { sub("^" k ":[[:space:]]*", ""); print; exit }
  ' "$1"
}

# Um campo presente e VAZIO (ou `TBD`, ou `?`) cumpre a letra e nega o propósito: o leitor continua
# sem saber para que versão a KB vale. Medido em 2026-09-30 por passada adversarial: `applies_to: ""`,
# `applies_to: TBD` e `applies_to: ?` passavam todos. Exigir a presença do campo sem exigir CONTEÚDO é
# a mesma brecha um nível adiante — o defeito que o bloco "COBRA AS DUAS COISAS" acima persegue.
# PREDICADO, não lista de placeholders: versão tem DÍGITO. A única saída sem dígito é declarar a
# não-medição em voz alta ("versão NÃO MEDIDA"), que é desfecho de 1ª classe nesta casa e já é o que
# `tools/whisper.md` faz honestamente. Lista de placeholders envelheceria no vocabulário (`N/A`,
# `pendente`, `—`); o predicado não.
_value_is_substantive() {
  local v="$1"
  v="${v#\"}"; v="${v%\"}"; v="${v#\'}"; v="${v%\'}"   # tira aspas da forma YAML
  v="$(printf '%s' "${v}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ -n "${v}" ] || return 1
  # here-string, NÃO `printf | grep -q`: sob `pipefail` o leitor fecha cedo, o escritor toma EPIPE e
  # o pipeline reprova COM o padrão presente. A guarda `shell-pipefail` cobra esta forma por catraca.
  grep -q '[0-9]' <<< "${v}" && return 0
  grep -qiE 'n(A|Ã|A)?O[[:space:]]+MEDID[AO]' <<< "${v}" && return 0
  return 1
}

_baseline_has() { [ -f "${BASELINE}" ] && grep -qxF "$1" <(grep -v '^[[:space:]]*#' "${BASELINE}" | sed 's/[[:space:]]*#.*//; s/[[:space:]]*$//') ; }

found=0; missing=()
while IFS= read -r f; do
  rel="${f#"${REPO}/"}"
  # frontmatter presente?
  if [ "$(head -1 "${f}")" != "---" ]; then
    missing+=("${rel}")
    _baseline_has "${rel}" || { echo "REGRA 93: [kb-applies-to/SEM-FRONTMATTER] ${rel} não abre com bloco \`---\`, então NENHUM carimbo dele é legível pelo gate (verified_at escrito assim é prosa — medido em 2026-09-30). Crie o bloco e declare \`applies_to:\` dentro"; found=1; }
    continue
  fi
  _v="$(_field_in_fm "${f}" applies_to)"
  if [ -z "${_v}" ]; then
    missing+=("${rel}")
    _baseline_has "${rel}" || { echo "REGRA 93: [kb-applies-to/SEM-CAMPO] ${rel} não declara \`applies_to:\` no frontmatter — sem ele o leitor não sabe se a KB vale para a versão que ele tem. Se for KB de padrão DA CASA e não de software de terceiro, isente no baseline COM a razão escrita"; found=1; }
  elif ! _value_is_substantive "${_v}"; then
    missing+=("${rel}")
    _baseline_has "${rel}" || { echo "REGRA 93: [kb-applies-to/VALOR-VAZIO] ${rel} tem \`applies_to:\` sem conteúdo útil (\`${_v}\`) — campo presente e vazio cumpre a letra e nega o propósito. Declare a versão (com dígito) ou diga em voz alta que ela NÃO FOI MEDIDA"; found=1; }
  fi
# SEM -maxdepth: uma subpasta futura (`tools/vendor/…`) escaparia da varredura e a regra ficaria
# cega exatamente onde alguém organizou melhor. Hoje não existe subpasta nenhuma nas duas — então
# isto NÃO muda um byte do resultado atual; fecha uma porta antes de alguém entrar por ela.
done < <(find "${KBDIR}/tools" "${KBDIR}/platforms" -name '*.md' -type f 2>/dev/null | sort)

if [ "${MODE}" = "--emit-baseline" ]; then
  {
    echo "# kb-applies-to-baseline — isenções da REGRA 93, cada uma COM RAZÃO ESCRITA."
    echo "# SÓ ENCOLHE. KB nova em tools/ ou platforms/ sem \`applies_to:\` no frontmatter é HARD."
    echo "# Gerado por: bash .claude/validation/kb-applies-to-check.sh --emit-baseline"
    # `printf '%s\n' "${array[@]}"` com array VAZIO imprime UMA LINHA VAZIA — e o contador
    # abaixo (`grep -cv '^#'`) a conta como isenção. Sem esta guarda o passivo nunca chegaria a
    # zero e a "métrica de saúde é esta lista ENCOLHENDO" seria mentira no último passo dela.
    # Medido por passada adversarial em 2026-09-30.
    [ "${#missing[@]}" -gt 0 ] && printf '%s\n' "${missing[@]}"
  } > "${BASELINE}"
  echo "kb-applies-to: baseline com ${#missing[@]} isenção(ões) em ${BASELINE}" >&2
  exit 0
fi

# PASSIVO declarado: silêncio sobre o que o baseline tolera seria a catraca mentindo sobre si.
if [ -f "${BASELINE}" ]; then
  n_b="$(grep -cve '^[[:space:]]*#' -e '^[[:space:]]*$' "${BASELINE}" 2>/dev/null || echo 0)"
  [ "${n_b}" -gt 0 ] && echo "REGRA 93: [kb-applies-to/PASSIVO] ${n_b} KB(s) de tools/platforms sem \`applies_to:\` toleradas pelo baseline — a métrica de saúde é esta lista ENCOLHENDO"
fi
exit "${found}"
