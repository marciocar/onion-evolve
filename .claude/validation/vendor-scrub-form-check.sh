#!/usr/bin/env bash
# vendor-scrub-form-check.sh — nome comercial na superfície vendorizada, detectado por FORMA.
#
# Uso : vendor-scrub-form-check.sh [REPO] | --emit-baseline | --selftest
# Saída: <rel>|<termo> por candidato, um por linha. Exit 0 sempre (quem julga é a REGRA 36).
#
# ══ O BURACO QUE ESTE SCRIPT FECHA ════════════════════════════════════════════════════════════
# A REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) deriva os termos do
# `members.yaml` — e isso é certo, porque nome hardcoded num script É o próprio vazamento. Mas tem
# um preço medido: **cliente que nunca foi registrado é invisível para ela**. Em 2026-09-14 a
# medição achou o nome de um cliente real de PoC em DOIS arquivos que viajam para todo adotante, e a guarda
# nunca cobrou — o termo jamais foi derivado porque o cliente não está no `members.yaml`.
# É a classe `guarda-por-lista-falha-pelo-vocabulário`: em guarda de lista, o defeito dominante é o
# VOCABULÁRIO, não a lógica. A cura é a mesma de sempre — **assere a FORMA, não a lista**.
#
# ══ AS DUAS FORMAS, E POR QUE SÓ ESTAS ════════════════════════════════════════════════════════
# (A) AMPERSAND CORPORATIVO: `Acme&Co`, `Baker&Sons`. Empresa usa `&` no nome; prosa técnica quase não.
#     As siglas legítimas do ofício (M&A, Q&A, V&V, R&D) são 1 letra de cada lado — o padrão exige
#     pelo menos um lado com 2+ caracteres, e isso sozinho elimina o grosso do ruído.
# (B) ÂNCORA DE CONTEXTO: `PoC <Nome>`, `cliente <Nome>`, `adotante <Nome>`. A palavra que antecede
#     é que denuncia — nome próprio ali é quase sempre cliente real.
# Fora daqui é campo aberto demais: qualquer palavra capitalizada viraria candidata e a guarda
# morreria de falso-positivo. Teto declarado: nome comercial SEM `&` e SEM âncora não é visto.
#
# ══ CATRACA, PORQUE FORMA GERA CANDIDATO, NÃO VEREDITO ════════════════════════════════════════
# Candidato legítimo existe (sigla do ofício, nome fictício de exemplo, citação acadêmica). Vai para
# o baseline, que SÓ ENCOLHE. Candidato novo = HARD. É o mesmo idioma das REGRAS 45 e 49.
set -uo pipefail

MODE="${1:-scan}"
case "${MODE}" in --emit-baseline|--selftest) ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)" ;;
  *) ROOT="$([ -d "${MODE}" ] && (cd "${MODE}" && pwd) || (git rev-parse --show-toplevel 2>/dev/null || pwd))"; MODE=scan ;; esac

_vm="${ROOT}/.claude/utils/adopt/vendor-manifest.sh"
_roots=()
if [ -f "${_vm}" ]; then
  while IFS= read -r _r; do [ -n "${_r}" ] && _roots+=("${_r}"); done < <(bash "${_vm}" --emit-scrub-roots 2>/dev/null || true)
fi
[ "${#_roots[@]}" -gt 0 ] || { echo "ERRO: superfície vendorizada não resolvida (vendor-manifest.sh)" >&2; exit 2; }

_targets=(); for _r in "${_roots[@]}"; do [ -e "${ROOT}/${_r}" ] && _targets+=("${ROOT}/${_r}"); done
[ "${#_targets[@]}" -gt 0 ] || exit 0

# (A) ampersand corporativo — pelo menos um lado com 2+ caracteres
_PAT_AMP='[A-Za-z0-9]{2,}&[A-Za-z0-9]+|[A-Za-z0-9]+&[A-Za-z0-9]{2,}'
# (B) âncora de contexto seguida de nome próprio. O nome tem de ter forma de NOME — inicial
#     maiúscula seguida de minúscula (Acme, StartupXYZ, TechStartup). Palavra TODA em maiúscula é
#     ênfase de prosa nesta casa (NUNCA, SEMPRE, PRE) e produziria só ruído.
_PAT_CTX='(PoC|POC|[Cc]liente|[Aa]dotante|[Ee]mpresa)[[:space:]]+[A-Z][a-z][A-Za-z0-9]*'

_scan() {
  # entidade HTML, URL e operador de shell NÃO são nome de empresa — e o `docs/sdaal/index.html`
  # sozinho traria centenas de `&quot;` se isto faltasse.
  # O PRÓPRIO BASELINE está sob .claude/validation e, portanto, dentro da superfície varrida — sem
  # esta exclusão ele se cita e todo termo tolerado renasce como candidato NOVO num caminho diferente
  # (medido na 1ª execução: 8 HARD, todas o baseline acusando a si mesmo).
  LC_ALL=C grep -rInIE "${_PAT_AMP}|${_PAT_CTX}" "${_targets[@]}" 2>/dev/null \
    | grep -v '/vendor-scrub-form-baseline\.txt:' \
    | grep -vE '&(quot|amp|lt|gt|nbsp|apos|#[0-9]+);|https?://|&&|\|\||\$\{' \
    | while IFS= read -r line; do
        local_file="${line%%:*}"; rest="${line#*:}"; rest="${rest#*:}"
        for t in $(LC_ALL=C grep -oE "${_PAT_AMP}" <<< "${rest}" || true); do
          printf '%s|%s\n' "${local_file#${ROOT}/}" "${t}"
        done
        # só o NOME, nunca a âncora: `cliente Acme` reporta `Acme`.
        while IFS= read -r t; do
          [ -n "${t}" ] || continue
          printf '%s|%s\n' "${local_file#${ROOT}/}" "${t}"
        done < <(LC_ALL=C grep -oE "${_PAT_CTX}" <<< "${rest}" 2>/dev/null \
                 | sed -E 's/^(PoC|POC|[Cc]liente|[Aa]dotante|[Ee]mpresa)[[:space:]]+//' || true)
      done | sort -u
}

if [ "${MODE}" = "--selftest" ]; then
  d="$(mktemp -d)"; mkdir -p "${d}/x"
  printf 'nada aqui\nM&A e Q&A sao siglas\n' > "${d}/x/ok.md"
  printf 'a PoC Acme&Co foi medida\n' > "${d}/x/leak.md"
  out="$(LC_ALL=C grep -rInIE "${_PAT_AMP}|${_PAT_CTX}" "${d}/x" 2>/dev/null | grep -vE '&(quot|amp|lt|gt);' || true)"
  rm -rf "${d}"
  if grep -q 'leak.md' <<< "${out}" && ! grep -q 'ok.md' <<< "${out}"; then
    echo "vendor-scrub-form selftest: OK (pega Acme&Co, cala em M&A/Q&A)"; exit 0
  fi
  echo "vendor-scrub-form selftest: FALHOU — out=[${out}]" >&2; exit 1
fi

if [ "${MODE}" = "--emit-baseline" ]; then
  printf '# Baseline de CANDIDATOS por forma na superfície vendorizada — PASSIVO TOLERADO.\n'
  printf '# Gerado por: bash .claude/validation/vendor-scrub-form-check.sh --emit-baseline > .claude/validation/vendor-scrub-form-baseline.txt\n'
  printf '# formato: <rel>|<termo>. SÓ PODE ENCOLHER. Candidato NOVO = HARD.\n'
  printf '# Legítimos aqui: sigla do ofício (M&A, Q&A, V&V), nome FICTÍCIO de exemplo, citação acadêmica.\n'
  printf '# Nome de cliente REAL não se tolera: remove-se do texto.\n'
  _scan
  exit 0
fi

_scan
