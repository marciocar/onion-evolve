#!/usr/bin/env bash
# =============================================================================
# sandbox-deny-advice.sh — a linha "sandbox" do relatório do /meta:adopt --update: quais regras Read do deny viram bloqueio
# do sistema no alvo, e qual exceção `allowRead` falta. SÓ AVISA: o bloco `sandbox` é do adotante e nada aqui escreve nele.
#
# Uso : sandbox-deny-advice.sh <WORK>        (WORK = a branch do update, lida na ÁRVORE)
# rc  : 0 aviso impresso (com ou sem falta) · 2 uso · 3 NÃO MEDIDO (sem jq, JSON inválido, não é repo git)
#
# ══ POR QUE EXISTE (2026-11-09, medido na curadoria e em fixture com bwrap real) ═════════════════════════
# Sob sandbox, `Read(~/...)` em permissions.deny vira negação de leitura do Bash. Com `Read(~/.config/gh/hosts.yml)`, `gh auth
# status` deu rc 1 e o credential helper do git rc 128. A exceção `sandbox.filesystem.allowRead` no mesmo caminho curou: gh, ls-remote,
# push e merge passaram com a regra ainda no deny. Decisão do maestro: manter as regras e avisar quem tem sandbox.
#
# O QUE NÃO VÊ: regra Read com glob (`//**/.env`) fica de fora, porque não mostrou efeito na medida. Só o remote `origin` e a
# configuração git legível por quem roda o script. Quem lê um caminho negado sem ser gh, git ou gpg (uma ferramenta própria do
# adotante, a CLI da AWS) não é detectado: a regra aparece listada, sem dizer quem depende dela. Lê o settings e o settings.local do
# alvo; sandbox ligado no settings do usuário (fora do repo) ou por política gerenciada não é visto.
# =============================================================================
set -uo pipefail
W="${1:-}"
[ -n "${W}" ] || { echo "uso: sandbox-deny-advice.sh <WORK>" >&2; exit 2; }
nm() { echo "sandbox: NÃO MEDIDO — $*"; exit 3; }
command -v jq >/dev/null 2>&1 || nm "jq ausente."
git -C "${W}" rev-parse --git-dir >/dev/null 2>&1 || nm "${W} não é um repo git."
# o local vale por cima do projeto, e o sandbox pode estar só nele
FILES=()
for f in "${W}/.claude/settings.json" "${W}/.claude/settings.local.json"; do
  [ -f "${f}" ] || continue
  jq -e . "${f}" >/dev/null 2>&1 || nm "$(basename "${f}") do alvo não é JSON válido."
  FILES+=("${f}")
done
[ "${#FILES[@]}" -gt 0 ] || { echo "sandbox: alvo sem settings.json; nada a avisar"; exit 0; }

if [ "$(jq -rs 'map(.sandbox.enabled? // null) | map(select(. != null)) | (last // false)' "${FILES[@]}")" != true ]; then echo "sandbox: desligado no alvo; nada a avisar"; exit 0; fi

mapfile -t HOME_RULES < <(jq -r '(.permissions.deny? // []) | if type == "array" then .[] else empty end | select(type == "string") | select(test("^Read\\(~/")) | sub("^Read\\("; "") | sub("\\)$"; "")' "${FILES[@]}" | sort -u)
mapfile -t ALLOWED < <(jq -r '(.sandbox.filesystem.allowRead? // []) | if type == "array" then .[] else empty end | select(type == "string")' "${FILES[@]}")

echo "sandbox: LIGADO no alvo; este relatório só avisa, o bloco sandbox é do adotante"
if [ "${#HOME_RULES[@]}" -eq 0 ]; then echo "  nenhuma regra Read de caminho do home no deny"; exit 0; fi
echo "  viram bloqueio do sistema para o Bash (${#HOME_RULES[@]}):"
printf '    %s\n' "${HOME_RULES[@]}"

has_rule() { local r; for r in "${HOME_RULES[@]}"; do [ "${r}" = "$1" ] && return 0; done; return 1; }
# a exceção vale se cobre o caminho exato ou uma pasta acima dele
is_allowed() {
  local a h="${HOME:-/nonexistent}"
  for a in "${ALLOWED[@]+"${ALLOWED[@]}"}"; do
    case "${a}" in "${h}"|"${h}"/*) a="~${a#"${h}"}" ;; esac   # allowRead com o caminho do home expandido
    a="${a%/\*\*}"; a="${a%/}"
    case "$1" in "${a}"|"${a}"/*) return 0 ;; esac
  done
  return 1
}

remote="$(git -C "${W}" remote get-url origin 2>/dev/null || true)"
helpers="$(git -C "${W}" config --get-regexp '^credential\..*helper$' 2>/dev/null || true)"
gpgsign="$(git -C "${W}" config --get commit.gpgsign 2>/dev/null || true)"
case "${remote}" in
  "") kind=nenhum ;;
  ssh://*|git+ssh://*|ssh+git://*) kind=ssh ;;
  http://*|https://*) kind=https ;;
  *://*|/*|./*|../*|~*) kind=outro ;;
  *:*) kind=ssh ;;      # forma scp: [usuario@]host:caminho, inclusive alias do ~/.ssh/config
  *) kind=outro ;;
esac
echo "  remote origin: ${kind} · credential helper: $(grep -q 'gh auth git-credential' <<< "${helpers}" && echo 'gh' || { [ -n "${helpers}" ] && echo outro || echo nenhum; })"

missing=0
miss() { missing=$((missing + 1)); printf '  FALTA allowRead: %s — %s\n' "$1" "$2"; }

H="~/.config/gh/hosts.yml"
if has_rule "${H}" && ! is_allowed "${H}"; then
  if grep -q 'gh auth git-credential' <<< "${helpers}"; then
    miss "${H}" "o credential helper é o gh: git push e ls-remote por https quebram (medido), e o gh também"
  else
    miss "${H}" "o gh lê este arquivo: gh auth status e gh pr view quebram (medido); o forge padrão do Onion é o gh"
  fi
fi
if [ "${kind}" = ssh ] && has_rule "~/.ssh/**" && ! is_allowed "~/.ssh/config"; then
  miss "~/.ssh/**" "o remote é ssh: a chave fica ilegível e o push deve falhar (ssh -i acusou chave inacessível; push de ponta a ponta NÃO medido). A exceção expõe a chave ao Bash: avalie antes de abrir"
fi
if [ "${gpgsign}" = true ] && has_rule "~/.gnupg/**" && ! is_allowed "~/.gnupg/pubring.kbx"; then
  echo "  ATENÇÃO: commit.gpgsign=true e ~/.gnupg negado. A assinatura falhou sob sandbox com e sem o deny (o processo não grava no home); uma exceção de leitura não basta."
fi
[ "${missing}" -gt 0 ] || echo "  nenhuma exceção allowRead faltando para o que este alvo usa"
exit 0
