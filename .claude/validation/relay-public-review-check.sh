#!/usr/bin/env bash
# =============================================================================
# relay-public-review-check.sh — REGRA 113: sinal relayado a destino público só se commita revisado
#
# O QUE   : todo `.md` sob `docs/evolution/inbox/` (o 1º nível e o `_processed/`) que está no ÍNDICE do
#           git e traz no frontmatter a chave `reviewed_for_public:` com valor diferente de `true` é HARD.
#           Quem grava `reviewed_for_public: false` é o carteiro upstream (co-relay.sh) ao entregar a um
#           destino público ou de visibilidade não medida; quem grava `true` é a sessão do destino, depois
#           de reler o sinal como se fosse publicado e reduzi-lo à forma. A trava fica no lado que PUBLICA.
#
# DEFEITO DATADO (2 casos em 3 dias, os dois segurados só pela revisão do core, sem mecanismo):
#           · 2026-10-27/28: um sinal chegou ao inbox do core (repo público) verbatim, com nome de cliente,
#             plano, administradores, uma chave e achados de teste de invasão; o core commitou só um resumo;
#           · 2026-10-29: uma resposta chegou numa v1 com incidente e exposição, e uma v2 que ainda permitia
#             reconstruir setor, postura de segurança, vínculo, canais e comitês. A v1 saiu sem commit.
#
# POR QUE O ÍNDICE, E NÃO A ÁRVORE (cláusula 5 da doutrina da guarda: quem controla a entrada?): o carteiro
#           escreve o sinal UNTRACKED no inbox do destino. Se a guarda lesse a árvore, qualquer remetente
#           deixaria o gate do destino vermelho só por entregar. Lendo o índice, só o commit do PRÓPRIO destino
#           a aciona, e é o conteúdo do índice (o que vai ser commitado) que ela julga, não o da árvore.
#
# O QUE ELA NÃO PEGA (teto declarado):
#   · paráfrase e detalhe reconstruível: a guarda vê a MARCA, não o conteúdo. Ela cobra que a revisão
#     aconteceu, nunca que foi boa — `true` gravado sem reler passa, e APAGAR a linha da marca também
#     (sinal sem a chave cala, pelo item abaixo);
#   · um `---` na linha 1 usado como régua horizontal é lido como abertura de frontmatter, aqui e no
#     carteiro (a marca entra antes do 2º `---`); raro, e as duas metades leem igual;
#   · sinal que não passou pelo carteiro (cópia à mão, A2A, colado na sessão): chega sem a marca e cala;
#   · marca fora do frontmatter, ou aninhada (indentada): cala;
#   · `docs/evolution/inbound/` (o canal downstream) e qualquer caminho fora do inbox: fora do escopo;
#   · o histórico: um commit antigo com a marca não é reescrito; ela julga só o índice de agora.
#
# USO     : relay-public-review-check.sh [REPO] [--format text|tsv] | --selftest
# SAÍDA   : <SEV>\t<classe>\t<caminho-relativo>\t<msg>   classe: sem-revisao (HARD) · vazio = limpo
# RC      : 0 julgou (as linhas dizem o resto) · 2 = erro, não julgou · 3 = sem índice git, não julgou
# =============================================================================
set -uo pipefail
MODE="check"; FORMAT="text"; REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,37p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done

KEY_RE='^[[:space:]]*reviewed_for_public[[:space:]]*:'

# $1 = conteúdo do índice num arquivo → stdout: os valores da chave no frontmatter (um por linha; vazio = sem chave)
_frontmatter_values() {
  awk 'NR == 1 { if ($0 !~ /^---\r?$/) exit; fm = 1; next }
       fm == 1 && /^---\r?$/ { exit }
       fm == 1 && /^reviewed_for_public[ \t]*:/ {
         v = $0; sub(/^reviewed_for_public[ \t]*:[ \t]*/, "", v); sub(/\r$/, "", v)
         sub(/[ \t]+#.*$/, "", v); sub(/[ \t]+$/, "", v); gsub(/["\047]/, "", v)
         print (v == "" ? "(vazio)" : v) }' "$1"
}

_scan() {
  local repo="$1" fmt="$2"
  git -C "${repo}" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { echo "relay-public-review-check: ${repo} não é uma árvore git — sem índice, não julguei" >&2; return 3; }
  local tmp list rc=0 p v bad
  tmp="$(mktemp)" || return 2
  list="$(mktemp)" || { rm -f "${tmp}"; return 2; }
  # >>> le-o-indice
  LC_ALL=C git -C "${repo}" grep --cached -z -l -I -E "${KEY_RE}" -- 'docs/evolution/inbox/' > "${list}" 2>/dev/null || rc=$?
  # <<< le-o-indice
  if [ "${rc}" -gt 1 ]; then rm -f "${tmp}" "${list}"; echo "relay-public-review-check: git grep falhou (rc=${rc})" >&2; return 2; fi
  while IFS= read -r -d '' p; do
    case "${p}" in *.md) : ;; *) continue ;; esac
    git -C "${repo}" show ":${p}" > "${tmp}" 2>/dev/null || continue
    bad=""
    while IFS= read -r v; do
      case "$(printf '%s' "${v}" | tr '[:upper:]' '[:lower:]')" in true) : ;; *) bad="${v}" ;; esac
    done < <(_frontmatter_values "${tmp}")
    [ -n "${bad}" ] || continue
    if [ "${fmt}" = tsv ]; then
      printf 'HARD\tsem-revisao\t%s\t%s\n' "${p}" "sinal relayado a destino possivelmente público está no índice com reviewed_for_public: ${bad} — releia-o como se já estivesse publicado, commite só a forma (um resumo sem cliente, pessoas, segredo, incidente nem postura de segurança), grave reviewed_for_public: true e re-adicione; ou tire-o do índice (git restore --staged). O comentário da marca diz a visibilidade que o carteiro mediu: se diz unknown e este repo é privado, basta gravar true"
    else
      printf 'HARD [sem-revisao] %s: reviewed_for_public: %s — revise antes do commit e grave true\n' "${p}" "${bad}"
    fi
  done < "${list}"
  rm -f "${tmp}" "${list}"
  return 0
}

_selftest() {
  # chamado de dentro de um hook do git, estas variáveis apontariam os `add`/`rm --cached` da fixture para o
  # índice REAL (achado da passada adversarial de 2026-10-29)
  unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_PREFIX
  local tmp total=0 fails=0 out rc
  tmp="$(mktemp -d)"; git -C "${tmp}" init -q
  mkdir -p "${tmp}/docs/evolution/inbox/_processed" "${tmp}/docs/outro"
  _sig() { printf -- '---\ntitle: t\nreviewed_for_public: %s\n---\n\n# corpo\n' "$2" > "${tmp}/$1"; }
  _add() { git -C "${tmp}" add -- "$@" >/dev/null 2>&1; }
  _reset() { git -C "${tmp}" rm -rq --cached -- docs >/dev/null 2>&1; rm -rf "${tmp}/docs"; mkdir -p "${tmp}/docs/evolution/inbox/_processed" "${tmp}/docs/outro"; }
  _run() { total=$((total+1)); out="$(LC_ALL=C bash "$0" "${tmp}" --format tsv 2>&1)"; rc=$?; }
  _ok() { echo "  ✅ $1"; }
  _ko() { echo "  ✗ $1"; fails=$((fails+1)); }

  # (i) o defeito: sinal marcado false no índice → HARD
  _sig docs/evolution/inbox/s.md false; _add docs/evolution/inbox/s.md; _run
  if [ "${rc}" -eq 0 ] && grep -q $'^HARD\tsem-revisao\tdocs/evolution/inbox/s.md\t' <<< "${out}"; then _ok "(i) marcado false no índice acusa"; else _ko "(i) marcado false no índice acusa: ${out}"; fi
  # (ii) a cura: true → cala (e True, "true" entre aspas, com comentário)
  _reset; _sig docs/evolution/inbox/s.md true; _sig docs/evolution/inbox/t.md '"True"  # revisto'; _add docs; _run
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "(ii) revisado (true, \"True\", com comentário) cala"; else _ko "(ii) revisado cala: ${out}"; fi
  # (iii) cláusula 5: o mesmo sinal UNTRACKED (o carteiro acabou de entregar) → cala
  _reset; _sig docs/evolution/inbox/s.md false; _run
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then _ok "(iii) entregue e não adicionado (untracked) cala: o remetente não deixa o gate vermelho"; else _ko "(iii) untracked cala: ${out}"; fi
  # (iv) a árvore diz true e o ÍNDICE ainda diz false → acusa (o commit leva o índice)
  _reset; _sig docs/evolution/inbox/s.md false; _add docs; _sig docs/evolution/inbox/s.md true; _run
  if grep -q $'^HARD\tsem-revisao\tdocs/evolution/inbox/s.md' <<< "${out}"; then _ok "(iv) índice false com a árvore true acusa"; else _ko "(iv) índice false com a árvore true acusa: ${out}"; fi
  # (v) _processed/ também é julgado (a triagem é um git mv)
  _reset; _sig docs/evolution/inbox/_processed/p.md false; _add docs; _run
  if grep -q $'^HARD\tsem-revisao\tdocs/evolution/inbox/_processed/p.md' <<< "${out}"; then _ok "(v) _processed/ marcado false acusa"; else _ko "(v) _processed/ acusa: ${out}"; fi
  # (vi) a chave só no CORPO (um sinal que discute o mecanismo) → cala
  _reset; printf -- '---\ntitle: t\n---\n\nreviewed_for_public: false\n' > "${tmp}/docs/evolution/inbox/b.md"; _add docs; _run
  if [ -z "${out}" ]; then _ok "(vi) a chave no corpo, fora do frontmatter, cala"; else _ko "(vi) corpo cala: ${out}"; fi
  # (vii) fora do inbox → cala; sinal sem a chave → cala
  _reset; _sig docs/outro/x.md false; printf -- '---\ntitle: t\n---\n' > "${tmp}/docs/evolution/inbox/n.md"; _add docs; _run
  if [ -z "${out}" ]; then _ok "(vii) fora do inbox e sinal sem a marca calam"; else _ko "(vii) fora do escopo cala: ${out}"; fi
  # (viii) CRLF e valor vazio: false\r acusa; chave vazia acusa (só true é revisado)
  _reset; printf -- '---\r\nreviewed_for_public: false\r\n---\r\n' > "${tmp}/docs/evolution/inbox/c.md"
  printf -- '---\nreviewed_for_public:\n---\n' > "${tmp}/docs/evolution/inbox/e.md"; _add docs; _run
  if grep -q 'inbox/c.md' <<< "${out}" && grep -q 'inbox/e.md' <<< "${out}"; then _ok "(viii) CRLF e valor vazio acusam"; else _ko "(viii) CRLF e vazio: ${out}"; fi
  # (ix) chave duplicada (false e true): ambígua → acusa
  _reset; printf -- '---\nreviewed_for_public: false\nreviewed_for_public: true\n---\n' > "${tmp}/docs/evolution/inbox/d.md"; _add docs; _run
  if grep -q 'inbox/d.md' <<< "${out}"; then _ok "(ix) chave duplicada com um false acusa"; else _ko "(ix) duplicada: ${out}"; fi
  # (x) não é árvore git → rc 3, nunca aprovação
  total=$((total+1)); local ng; ng="$(mktemp -d)"; out="$(bash "$0" "${ng}" --format tsv 2>&1)"; rc=$?; rm -rf "${ng}"
  if [ "${rc}" -eq 3 ]; then _ok "(x) sem árvore git sai 3 (não julgou)"; else _ko "(x) sem árvore git: rc=${rc}"; fi

  rm -rf "${tmp}"; echo "  selftest: $((total-fails))/${total} verdes"
  [ "${fails}" -eq 0 ] && return 0 || return 1
}

case "${MODE}" in
  selftest) _selftest ;;
  *) [ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; _scan "${REPO}" "${FORMAT}" ;;
esac
