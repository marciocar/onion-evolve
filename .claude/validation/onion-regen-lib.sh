#!/usr/bin/env bash
# ===========================================================================
# onion-regen-lib.sh — o motor do auto-fix de PROJEÇÃO GERADA (sourçado pelo .githooks/pre-commit)
#
# ── POR QUE É LIB, e não um bloco dentro do hook ───────────────────────────────────────────
# A 1ª versão vivia no hook e a bancada a extraía por `sed -n '/^_onion_regen/,/^}/p'`. A guarda
# `selftest-lanes: (0) âncora morta` reprovou na hora: ela cobra que símbolo citado por âncora de
# `sed` EXISTA em `.claude/validation/*.sh`, e o meu existia só no hook. A guarda estava certa — e a
# cura dela é melhor engenharia que o contorno: a função vira LIB, o hook fica fino, e a bancada
# sourça o artefato REAL em vez de uma cópia recortada ([[bancada-espelha-o-runner]]).
#
# ── O QUE ELE CURA ────────────────────────────────────────────────────────────────────────
# "Projeção gerada defasada no commit" barrou esta casa 3x num dia pelo painel (REGRA 81) e QUATRO
# vezes em 2026-10-01 por projeções DIFERENTES: `lint-rules.md` (REGRA 39, editado à MÃO num PR cujo
# tema era "o número sai da medição, nunca da prosa"), `inventory.md` (REGRA 16), 
# `testing-inventory.md` (REGRA 80) e as projeções de KG (REGRAS 62/84, regeneradas ANTES de
# estagiar e por isso nascidas obsoletas).
# O maestro nomeou o ponto: lição que se repete é problema de MECANISMO, não de atenção. A cura de
# disciplina ("lembrar de regenerar") é cura nula nesta casa.
# ===========================================================================

# ⚠️ ESTA LIB NÃO DECLARA `set -euo pipefail`, e é decisão, não esquecimento: ela é SOURÇADA pelo
# hook, e `set` num arquivo sourçado VAZA para o shell do chamador — endureceria o hook no meio da
# execução, que é mudança de comportamento por efeito colateral. Em vez disso, cada função é robusta
# INDEPENDENTE das opções do chamador: nenhum pipe com fechador precoce, nenhum rc descartado.
# (A guarda de shell acusou a ausência de `pipefail`; a cura certa era esta, não o cargo-cult.)

# onion_regen <target-relativo> <numero-da-regra> <gerador...>   (o gerador imprime em STDOUT)
onion_regen() {
  local _target="$1" _rule="$2"; shift 2
  local _tmp; _tmp="$(mktemp)"
  # temp+mv: redirecionar DIRETO no alvo o TRUNCA antes de o gerador falhar, e aí a projeção SOME em
  # vez de ficar defasada — e o que some é pior ([[generated-projection-needs-ratchet]]).
  # E o rc do gerador é LIDO: `[ -s ]` sozinho não basta ([[exit-code-nao-e-a-verificacao]]) — as
  # DUAS metades são load-bearing, e a bancada mata um mutante de cada.
  if "$@" > "${_tmp}" 2>/dev/null && [ -s "${_tmp}" ]; then
    if ! cmp -s "${_tmp}" "${REPO_ROOT}/${_target}"; then
      mv "${_tmp}" "${REPO_ROOT}/${_target}"
      echo "🔁 ${_target} regenerado (REGRA ${_rule}; auto-fix com rastro, a regra segue HARD no CI)"
      git add "${REPO_ROOT}/${_target}" || echo "⚠️  git add de ${_target} FALHOU — stagee à mão."
    else rm -f "${_tmp}"; fi
  else
    rm -f "${_tmp}"
    echo "⚠️  ${_target} NÃO regenerado (gerador falhou ou saiu vazio) — a REGRA ${_rule} vai acusar no CI."
  fi
}

# onion_staged <pathspec...> → imprime o 1º caminho staged que casa (vazio = nada tocado)
#
# ⚠️ SEM PIPE, e os dois motivos são defeitos medidos nesta casa. A 1ª versão era
# `git diff … 2>/dev/null | head -1`, e ela trazia DUAS classes de uma vez:
#   · `| head -1` é FECHADOR PRECOCE — sob o `pipefail` do chamador, o `git` leva EPIPE e a função
#     devolve não-zero com o caminho PRESENTE, invertendo o veredito ([[pipefail-epipe-early-closer-class]]);
#   · `2>/dev/null` faz git-que-FALHOU e nada-staged devolverem o MESMO vazio — erro engolido virando
#     dado ([[exit-code-nao-e-a-verificacao]]).
# A forma abaixo captura, LÊ o rc e corta a 1ª linha por expansão de parâmetro. Zero pipe.
onion_staged() {
  local _out
  if ! _out="$(git diff --cached --name-only --diff-filter=ACMR -- "$@")"; then
    echo "⚠️  onion_staged: git diff FALHOU — trato como NADA TOCADO, e isso pode mascarar" >&2
    return 1
  fi
  printf '%s' "${_out%%$'\n'*}"
}

# ── A IDENTIDADE DO CÓDIGO REVISADO (2026-10-06) ────────────────────────────────────────────────────
# FONTE ÚNICA, usada pelo ops/pr-finalize.sh E pelo pre-commit. Antes ela vivia só no motor, e o
# pre-commit recarimbava o resíduo da REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)
# SEM conferi-la: código mudado depois da revisão saía com carimbo de revisado — o B1 que o motor
# curou seguia vivo no hook (provado em sandbox pela avaliação do pr-finalize).
# shellcheck disable=SC2034
ONION_GENERATED="docs/onion/inventory.md docs/onion/graph.md docs/onion/testing-state.md docs/onion/testing-inventory.md docs/onion/kg-read-index.tsv docs/onion/federation-console.html docs/backlog.md .claude/validation/lint-rules.md docs/onion/federation-map.md .claude-plugin/marketplace.json"
# Diretórios INTEIROS gerados (SAC-67, 2026-10-08): plugins/<vertical>/ é montado pelo assemble-plugin.sh
# a partir das fontes em .claude/ (REGRA 19). Medido: dois PRs paralelos que tocam fontes DIFERENTES
# conflitam SÓ aqui (provenance.json e README.md de cada plugin, 4 arquivos, 0 de fonte), e a lista
# exata acima não os conhecia — o --rebase do pr-finalize recusava como "conflito REAL" e o rebase
# virava trabalho à mão (3 vezes na leva de 2026-10-07/08). O mapa da federação (REGRA 38) entrou na
# lista pelo mesmo motivo: o motor não o regenerava e o lint do commit o cobrava depois.
# ⚠️ ESVAZIADO NA F4 DAS PORTAS (2026-10-10, SAC-93): o `plugins/` saiu do core — o bundle é montado na
# publicação, nunca versionado aqui —, e o conflito que motivou esta variável deixou de poder existir. Ela
# fica (vazia) porque o mecanismo é genérico: diretório gerado novo entra aqui. O catálogo da raiz
# (`.claude-plugin/marketplace.json`, REGRA 76 (marketplace.json da raiz aponta o repo PÚBLICO e é projeção dos manifestos)) virou projeção dos manifestos e entrou na lista exata acima.
ONION_GENERATED_DIRS=""

# onion_is_generated <caminho> → rc 0 = projeção gerada (lista exata ou dentro de um diretório gerado)
onion_is_generated() {
  local p="$1" d
  case " ${ONION_GENERATED} " in *" ${p} "*) return 0 ;; esac
  for d in ${ONION_GENERATED_DIRS}; do case "${p}" in "${d}"*) return 0 ;; esac; done
  return 1
}

# onion_codehash <resíduo> → patch-id estável do diff STAGEADO contra a base, sem o resíduo e sem as
# projeções geradas. `git patch-id --stable`: estável sob rebase limpo, muda quando o hunk muda.
onion_codehash() {
  local res="$1" base ex g
  base="$(git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD 2>/dev/null)" \
    || { echo "onion_codehash: sem merge-base com origin/main nem main" >&2; return 1; }
  ex=(":(exclude)${res}")
  for g in ${ONION_GENERATED}; do ex+=(":(exclude)${g}"); done
  for g in ${ONION_GENERATED_DIRS}; do ex+=(":(exclude)${g%/}"); done
  git -c core.abbrev=40 -c diff.noprefix=false diff --no-ext-diff --no-color --cached "${base}" -- . "${ex[@]}" \
    | git patch-id --stable | sort | sha256sum | cut -c1-64
}

# onion_r56_restamp <caminho do resíduo> <caminho relativo ao repo> <sha do diff> → rc 0 = recarimbou
# (o chamador STAGEIA), rc 1 = NÃO recarimbou (avisa por quê no stdout). Só recarimba o que a revisão VIU:
#   · `pendente`  → a declaração de quem revisou: carimba o diff E o código;
#   · hash de código IGUAL ao revisado → o caso legítimo (o auto-fix mexeu só em projeções): só o diff;
#   · qualquer outra coisa (código mudado, ou resíduo sem reviewed_code_sha256) → NÃO toca.
onion_r56_restamp() {
  local f="$1" rel="$2" sha="$3" decl rcode code
  decl="$(sed -n 's/^reviewed_diff_sha256:[[:space:]]*//p' "${f}" | head -1 | tr -d '"')"
  rcode="$(sed -n 's/^reviewed_code_sha256:[[:space:]]*//p' "${f}" | head -1 | tr -d '"')"
  if ! code="$(onion_codehash "${rel}")" || [ -z "${code}" ]; then
    echo "⚠️  ${rel}: hash de código indisponível — NÃO recarimbo (a REGRA 56 decide)"; return 1
  fi
  if [ "${decl}" = pendente ]; then
    LC_ALL=C sed -i "s|^reviewed_diff_sha256: .*|reviewed_diff_sha256: ${sha}|" "${f}"
    if LC_ALL=C grep -q '^reviewed_code_sha256:' "${f}"; then
      LC_ALL=C sed -i "s|^reviewed_code_sha256: .*|reviewed_code_sha256: ${code}|" "${f}"
    else LC_ALL=C sed -i "/^reviewed_diff_sha256:/a reviewed_code_sha256: ${code}" "${f}"; fi
    return 0
  fi
  if [ -n "${rcode}" ] && [ "${rcode}" = "${code}" ]; then
    LC_ALL=C sed -i "s|^reviewed_diff_sha256: .*|reviewed_diff_sha256: ${sha}|" "${f}"
    return 0
  fi
  echo "⚠️  ${rel}: o CÓDIGO mudou depois da revisão (ou o resíduo não tem reviewed_code_sha256) — NÃO recarimbo; re-revise e ponha 'reviewed_diff_sha256: pendente'"
  return 1
}
