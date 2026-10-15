#!/usr/bin/env bash
# =============================================================================
# a2a-keygen.sh — gera o par RS256 de um membro da rede A2A do Onion.
#
# Graduado do spike F0 do configurador A2A (SAC-121, teste S1 = SAC-126; evidência no grafo
# docs/evolution/research/a2a-configurator-2026-10/, nó E_SPIKE_S1_S2_KEYGEN_E_REMETENTE).
# Produz o par no formato que o gate do receptor (a2a-verify.sh, camada 5) consome:
#   kid       = <member>-<N>
#   privada   = <dir>/<kid>.key.pem   (PKCS#8, modo 0600 desde o nascimento: umask 077)
#   pública   = <dir>/<kid>.pem       (SPKI PEM; é o arquivo que o receptor pina como jwks/<kid>.pem)
#   diretório = <dir>                 (default ${XDG_CONFIG_HOME:-~/.config}/onion/a2a, forçado a 0700)
#
# Imprime kid, caminho da pública e a impressão SHA-256 da pública (sobre o DER SPKI). NUNCA imprime
# a privada. Recusa sobrescrever chave existente (rc 2): a publicação é por `ln` (hard link), que
# falha atomicamente se o destino existe, sem janela entre conferir e escrever. Nenhum segredo passa
# por argv: o openssl recebe CAMINHOS, nunca conteúdo de chave. A privada nunca sai desta máquina:
# o que viaja ao receptor é só a pública e a impressão, conferida por canal fora de banda.
#
# Uso: a2a-keygen.sh --member <id> [--n N] [--dir <dir>] [--bits B]
#   --n     índice da chave (default 1; rotação = N+1, nunca sobrescrever)
#   --bits  tamanho do módulo RSA (default 3072; mínimo 3072)
# Recusa também gerar dentro de uma árvore git quando o .gitignore não cobre a privada: um `git add -A`
# a levaria ao commit (achado do refutador da F1a, 2026-10-15).
# Exit: 0 = gerado · 2 = uso incorreto, chave já existe, diretório alheio ou versionável, ou ferramenta ausente
# Exercitado por lint-selftest.sh (run_federation_a2a_selftests).
# =============================================================================
set -euo pipefail

MEMBER=""; N="1"; DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/onion/a2a"; BITS="3072"
die() { echo "a2a-keygen: $*" >&2; exit 2; }
need() { [ "$#" -ge 2 ] && [ -n "$2" ] || die "$1 exige valor"; }
while [ "$#" -gt 0 ]; do case "$1" in
  --member) need "$@"; MEMBER="$2"; shift 2 ;;
  --n)      need "$@"; N="$2"; shift 2 ;;
  --dir)    need "$@"; DIR="$2"; shift 2 ;;
  --bits)   need "$@"; BITS="$2"; shift 2 ;;
  -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
  *) die "argumento desconhecido: $1" ;;
esac; done

command -v openssl >/dev/null 2>&1 || die "ferramenta ausente: openssl"
[ -n "${MEMBER}" ] || die "uso: a2a-keygen.sh --member <id> [--n N] [--dir <dir>] [--bits B]"
# o kid vira NOME DE ARQUIVO no receptor (jwks/<kid>.pem) e o gate veta '/' e '..': a mesma régua aqui
case "${MEMBER}" in *[!A-Za-z0-9._-]*|.*) die "member inválido (use [A-Za-z0-9._-], sem '.' inicial): ${MEMBER}" ;; esac
case "${N}" in ''|*[!0-9]*|0*) die "--n deve ser inteiro positivo sem zero à esquerda: ${N}" ;; esac
case "${BITS}" in ''|*[!0-9]*) die "--bits deve ser inteiro: ${BITS}" ;; esac
[ "${BITS}" -ge 3072 ] || die "--bits ${BITS} abaixo do mínimo 3072"
[ -n "${DIR}" ] || die "--dir vazio"

KID="${MEMBER}-${N}"
PRIV="${DIR}/${KID}.key.pem"
PUB="${DIR}/${KID}.pem"

umask 077
mkdir -p "${DIR}" 2>/dev/null || die "não consegui criar o diretório ${DIR}"
# diretório de OUTRA conta: quem o possui troca a chave depois de gerada (o 0700 não protege do dono)
[ -O "${DIR}" ] || die "o diretório ${DIR} não pertence a esta conta; recuso gerar chave nele"
chmod 700 "${DIR}" || die "não consegui pôr ${DIR} em 0700"
# dentro de uma árvore git, a privada só nasce se o .gitignore a cobrir (senão um `git add -A` a commita)
if command -v git >/dev/null 2>&1 && git -C "${DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "${DIR}" check-ignore -q "${PRIV}" 2>/dev/null \
    || die "${DIR} está dentro de um repositório git e o .gitignore não cobre ${KID}.key.pem; gere fora do repo (o default é ~/.config/onion/a2a)"
fi
[ -e "${PRIV}" ] && die "chave privada já existe, recuso sobrescrever: ${PRIV} (rotação = --n $(( N + 1 )))"
[ -e "${PUB}" ]  && die "chave pública já existe, recuso sobrescrever: ${PUB} (rotação = --n $(( N + 1 )))"

TMPD="$(mktemp -d "${DIR}/.keygen.XXXXXX")"
trap 'rm -rf "${TMPD}"' EXIT
openssl genpkey -algorithm RSA -pkeyopt "rsa_keygen_bits:${BITS}" -out "${TMPD}/priv.pem" 2>/dev/null \
  || die "openssl genpkey falhou"
chmod 600 "${TMPD}/priv.pem"
openssl pkey -in "${TMPD}/priv.pem" -pubout -out "${TMPD}/pub.pem" 2>/dev/null || die "extração da pública falhou"
chmod 644 "${TMPD}/pub.pem"
FP="$(openssl pkey -pubin -in "${TMPD}/pub.pem" -outform DER 2>/dev/null | openssl dgst -sha256 | awk '{print $NF}')"
[ "${#FP}" -eq 64 ] || die "impressão SHA-256 da pública não calculada"

# publicação atômica e sem sobrescrita: ln falha se o destino já existe (corrida entre dois keygen)
ln "${TMPD}/priv.pem" "${PRIV}" 2>/dev/null || die "chave privada surgiu durante a geração, recuso sobrescrever: ${PRIV}"
if ! ln "${TMPD}/pub.pem" "${PUB}" 2>/dev/null; then
  rm -f "${PRIV}"; die "chave pública surgiu durante a geração, recuso sobrescrever: ${PUB}"
fi

printf 'kid=%s\n' "${KID}"
printf 'public=%s\n' "${PUB}"
printf 'fingerprint=sha256:%s\n' "${FP}"
echo "(privada em ${PRIV}, modo 0600, nunca impressa; mande ao receptor SÓ a pública e confira a impressão por canal fora de banda)" >&2
