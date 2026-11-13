#!/usr/bin/env bash
# delegated-ops.sh — as CÓPIAS DE ROOT e a regra de sudoers dos atos de VPS delegados à sessão (core-only).
#
# POR QUE EXISTE (2026-11-13, selo D_DELEGATE_VPS_SERVICE_SCRIPTS_1113 do maestro): a sessão passa a rodar o update do
# bridge e a persona do Slack (install, start, verify) por sudoers sem senha. Apontar a regra para ops/ do checkout seria
# root completo para quem edita o script (o operador escreve o checkout), e liberar os comandos internos não fecha a conta
# (o desenho e a medição estão no cabeçalho de ops/sudoers/onion-delegated-ops). Então a regra aponta CÓPIAS do root em
# /usr/local/lib/onion-ops, e este script é quem as instala da origin/main e as confere por sha256.
#
# USO
#   ops/delegated-ops.sh verify    só leitura (padrão): cada cópia é byte a byte a da origin/main? dono root, 0755, sem
#                                  symlink? O sudoers instalado é o da origin/main (quando legível)? O operador ainda tem
#                                  NOPASSWD: ALL (que tornaria a regra inútil)? rc 0 = em dia · 1 = defasada ou ausente
#   ops/delegated-ops.sh install   do MAESTRO, pelo `!` num terminal com TTY (o sudo pede a senha dele): copia da
#                                  origin/main recém-buscada, valida o sudoers com `visudo -cf`, instala as cópias
#                                  (root:root 0755) e a regra (0440) e roda o verify. A sessão não o roda: a linha
#                                  `ato script ops/delegated-ops.sh install` do ops/moat-targets.tsv veta.
#   ops/delegated-ops.sh --selftest  a bancada do verify, em sandbox (sem sudo, sem tocar no sistema)
#
# QUANDO REINSTALAR: toda vez que um dos arquivos do fecho mudar na main. A cópia defasada não roda o ato: o veto do hook
# só aceita a cópia byte a byte igual ao ops/ do checkout, e o update-bridge só aceita o verify da cópia que é o do clone
# servido. O verify aponta qual arquivo mudou.
#
# EXIT: 0 ok · 1 defasado/recusado · 2 não pude medir · 3 uso inválido
set -uo pipefail

NAME=delegated-ops
DIR=/usr/local/lib/onion-ops
SUDOERS_REL=ops/sudoers/onion-delegated-ops
SUDOERS_DST=/etc/sudoers.d/onion-delegated-ops
# o FECHO: os scripts que a regra aponta e os que eles executam como root a partir do próprio diretório
FILES=(update-bridge.sh bridge-backup.sh bridge-hardening.sh chat-runner.sh slack-persona.sh)
CORE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say() { printf '[%s] %s\n' "${NAME}" "$*"; }
die() { local rc="$1"; shift; printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2; exit "${rc}"; }

# _verify <dir> <git-dir> <ref> → imprime uma linha por achado; rc 0 = em dia, 1 = algo defasado ou fora do lugar
_verify() {
  local dir="$1" g="$2" ref="$3" bad=0 f want have st
  if [ -L "${dir}" ] || [ ! -d "${dir}" ]; then
    say "✗ ${dir} ausente ou symlink: as cópias não estão instaladas (o maestro roda: ops/delegated-ops.sh install)"; return 1
  fi
  st="$(stat -c '%u %A' "${dir}")"
  [ "${st%% *}" = 0 ] && [ "${st:7:1}" = - ] && [ "${st:10:1}" = - ] || { say "✗ ${dir} não é do root sem escrita de grupo/outros (${st}): a regra viraria root para quem escreve ali"; bad=1; }
  for f in "${FILES[@]}"; do
    want="$(git -C "${g}" show "${ref}:ops/${f}" 2>/dev/null | sha256sum | cut -d' ' -f1)"
    git -C "${g}" cat-file -e "${ref}:ops/${f}" 2>/dev/null || { say "✗ ${ref} não tem ops/${f}"; bad=1; continue; }
    if [ -L "${dir}/${f}" ] || [ ! -f "${dir}/${f}" ]; then say "✗ ${dir}/${f} ausente ou symlink"; bad=1; continue; fi
    st="$(stat -c '%u %A' "${dir}/${f}")"
    [ "${st%% *}" = 0 ] && [ "${st:7:1}" = - ] && [ "${st:10:1}" = - ] || { say "✗ ${dir}/${f} não é do root sem escrita de grupo/outros (${st})"; bad=1; }
    have="$(sha256sum < "${dir}/${f}" | cut -d' ' -f1)"
    if [ "${have}" = "${want}" ]; then say "✓ ${f} = ${ref} (${want:0:12})"
    else say "✗ ${f} DEFASADO: cópia ${have:0:12} ≠ ${ref} ${want:0:12} (reinstale: ops/delegated-ops.sh install)"; bad=1; fi
  done
  return "${bad}"
}

cmd_verify() {
  local bad=0 want l
  git -C "${CORE}" fetch -q origin main 2>/dev/null || say "ℹ️  não busquei origin/main: confiro contra a cópia local dela"
  git -C "${CORE}" rev-parse -q --verify origin/main >/dev/null || die 2 "sem origin/main neste checkout"
  _verify "${DIR}" "${CORE}" origin/main || bad=1
  want="$(git -C "${CORE}" show "origin/main:${SUDOERS_REL}" 2>/dev/null | sha256sum | cut -d' ' -f1)"
  if [ -r "${SUDOERS_DST}" ]; then
    [ "$(sha256sum < "${SUDOERS_DST}" | cut -d' ' -f1)" = "${want}" ] && say "✓ ${SUDOERS_DST} = origin/main" \
      || { say "✗ ${SUDOERS_DST} difere de origin/main:${SUDOERS_REL}"; bad=1; }
  else
    say "· ${SUDOERS_DST} não é legível pelo operador (0440 root): o maestro confere com 'sudo sha256sum ${SUDOERS_DST}' = ${want:0:12}"
  fi
  # a regra só limita se for tudo o que o operador tem: NOPASSWD: ALL a anula (medido em 2026-11-13)
  l="$(sudo -n -l 2>/dev/null || true)"
  if grep -qE 'NOPASSWD:[[:space:]]*ALL[[:space:]]*$' <<< "${l}"; then
    say "⚠️ o operador ainda tem NOPASSWD: ALL — a regra delegada não reduz nada enquanto isso valer (o card do maestro tem o passo)"
  fi
  [ "${bad}" = 0 ] && say "em dia" || say "DEFASADO: o ato delegado recusa até o maestro reinstalar"
  return "${bad}"
}

cmd_install() {
  [ "$(id -u)" != 0 ] || die 3 "rode como o operador (o script chama sudo onde precisa), não como root"
  [ -t 0 ] || die 3 "sem terminal: o install pede a senha do sudo do maestro (rode num terminal SSH/mosh, ou pelo \`!\` com TTY)"
  git -C "${CORE}" fetch -q origin main || die 2 "não busquei origin/main: as cópias saem dela, não do checkout"
  # o instalador que roda tem de ser o revisado: o desta árvore igual ao da origin/main
  [ "$(sha256sum < "${BASH_SOURCE[0]}" | cut -d' ' -f1)" = "$(git -C "${CORE}" show origin/main:ops/delegated-ops.sh | sha256sum | cut -d' ' -f1)" ] \
    || die 1 "este ops/delegated-ops.sh difere do da origin/main: rode o da main (git checkout origin/main -- ops/delegated-ops.sh, ou de uma worktree dela)"
  local tmp f
  tmp="$(mktemp -d)" || die 2 "mktemp falhou"
  trap 'rm -rf -- "${tmp}"' EXIT
  for f in "${FILES[@]}"; do
    git -C "${CORE}" show "origin/main:ops/${f}" > "${tmp}/${f}" || die 2 "origin/main sem ops/${f}"
  done
  git -C "${CORE}" show "origin/main:${SUDOERS_REL}" > "${tmp}/sudoers" || die 2 "origin/main sem ${SUDOERS_REL}"
  sudo visudo -cf "${tmp}/sudoers" || die 1 "visudo reprova ${SUDOERS_REL}: nada foi instalado"
  if sudo test -L "${DIR}"; then die 1 "${DIR} é symlink: recusado"; fi
  sudo install -d -o root -g root -m 0755 "${DIR}" || die 2 "não criei ${DIR}"
  for f in "${FILES[@]}"; do
    sudo install -o root -g root -m 0755 "${tmp}/${f}" "${DIR}/${f}" || die 2 "não instalei ${DIR}/${f}"
  done
  # o nome com ponto o sudo IGNORA (sudoers.d pula arquivo com '.'): instala ao lado, confere o conjunto, e só então troca
  sudo install -o root -g root -m 0440 "${tmp}/sudoers" "${SUDOERS_DST}.new" || die 2 "não instalei ${SUDOERS_DST}.new"
  sudo visudo -cf "${SUDOERS_DST}.new" && sudo mv -f "${SUDOERS_DST}.new" "${SUDOERS_DST}" && sudo visudo -c >/dev/null \
    || { sudo rm -f "${SUDOERS_DST}.new"; die 1 "o sudoers instalado não passou no visudo -c: confira já com 'sudo visudo -c' (o arquivo novo foi removido)"; }
  say "instalado: ${DIR} (${#FILES[@]} cópias, root:root 0755) e ${SUDOERS_DST} (0440)"
  say "ROLLBACK: sudo rm ${SUDOERS_DST} && sudo rm ${DIR}/*.sh && sudo rmdir ${DIR}"
  cmd_verify
}

selftest() {
  local t pass=0 fail=0 g out
  t="$(mktemp -d)"; trap 'rm -rf -- "${t}"' RETURN
  ck() { if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "  ✓ $1"; else fail=$((fail+1)); echo "  ✗ $1 (rc=$3, esperado=$2)"; printf '%s\n' "${out}" | sed 's/^/      | /'; fi; }
  g="${t}/core"; git init -q -b main "${g}"; mkdir -p "${g}/ops"
  for f in "${FILES[@]}"; do printf '#!/usr/bin/env bash\necho %s\n' "${f}" > "${g}/ops/${f}"; done
  git -C "${g}" add -A; git -C "${g}" -c user.email=t@t -c user.name=t commit -qm base
  # sem root não há cópia do root: a bancada prova o lado que REPROVA (o dono não é root) e a comparação por sha256
  mkdir -p "${t}/dir"; for f in "${FILES[@]}"; do cp "${g}/ops/${f}" "${t}/dir/${f}"; done; chmod 0755 "${t}/dir" "${t}/dir/"*
  out="$(_verify "${t}/dir" "${g}" HEAD 2>&1)"; ck "cópias do operador (não do root) reprovam" 1 $?
  grep -q "não é do root" <<< "${out}" && grep -q '✓ update-bridge.sh = HEAD' <<< "${out}"; ck "o motivo é o dono, e o conteúdo igual é reconhecido" 0 $?
  echo mudou >> "${t}/dir/chat-runner.sh"
  out="$(_verify "${t}/dir" "${g}" HEAD 2>&1)"; grep -q 'chat-runner.sh DEFASADO' <<< "${out}"; ck "cópia que difere da ref é DEFASADA" 0 $?
  rm "${t}/dir/slack-persona.sh"; ln -s "${g}/ops/slack-persona.sh" "${t}/dir/slack-persona.sh"
  out="$(_verify "${t}/dir" "${g}" HEAD 2>&1)"; grep -q 'slack-persona.sh ausente ou symlink' <<< "${out}"; ck "cópia que é symlink reprova" 0 $?
  out="$(_verify "${t}/nada" "${g}" HEAD 2>&1)"; ck "diretório ausente reprova" 1 $?
  echo "selftest: ${pass} ok · ${fail} falha(s)"
  [ "${fail}" = 0 ]
}

case "${1:-verify}" in
  verify) cmd_verify ;;
  install) cmd_install ;;
  --selftest) selftest ;;
  -h|--help) sed -n '/^# USO/,/^# EXIT/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) die 3 "uso: ops/delegated-ops.sh [verify|install|--selftest]" ;;
esac
