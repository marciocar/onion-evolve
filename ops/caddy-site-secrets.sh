#!/usr/bin/env bash
# caddy-site-secrets.sh — gera os segredos de um vhost protegido por Basic + cookie, sem nunca
# mostrá-los: a senha em claro e o cookie vão para o `pass`; o hash bcrypt e o cookie vão para
# /etc/caddy/secrets/<site>.env (root, 0600), que o ops/install-caddy-config.sh lê ao renderizar
# os marcadores @@<PREFIXO>_BASIC_HASH@@ e @@<PREFIXO>_COOKIE@@ do conf.d versionado.
#
# POR QUE EXISTE (2026-10-08, vhost gmill): segredo gerado "à mão, só desta vez" é o que volta como
# incidente (senha 0644 por 1h15 numa máquina de 5 contas). Gerar, guardar e derivar num só processo,
# sem arquivo temporário e sem eco, é a forma de não depender de disciplina.
#
# Escrever no `pass` só CIFRA (chave pública): funciona com o gpg-agent travado. Ler exige destravar.
#
# Uso:
#   ops/caddy-site-secrets.sh <site> <prefixo-pass> <PREFIXO_ENV> [--rotate]
#   ex.: ops/caddy-site-secrets.sh gmill onion/gmill-demo GMILL_DEMO
#        → pass onion/gmill-demo-basic-auth (senha) · pass onion/gmill-demo-cookie (cookie)
#        → /etc/caddy/secrets/gmill.env com GMILL_DEMO_BASIC_HASH e GMILL_DEMO_COOKIE
#   Sem --rotate, RECUSA se as entradas do pass já existirem (nunca sobrescreve um segredo vivo).
set -euo pipefail
export LC_ALL=C
umask 077

die() { echo "ERRO: $*" >&2; exit 2; }
SITE="${1:-}"; PASS_PREFIX="${2:-}"; ENV_PREFIX="${3:-}"; ROTATE="${4:-}"
[[ "$SITE" =~ ^[a-z0-9-]+$ ]] || die "site inválido: '$SITE' (use [a-z0-9-])"
[[ "$PASS_PREFIX" =~ ^[a-z0-9/_-]+$ ]] || die "prefixo do pass inválido: '$PASS_PREFIX'"
[[ "$ENV_PREFIX" =~ ^[A-Z0-9_]+$ ]] || die "prefixo de ambiente inválido: '$ENV_PREFIX'"
[[ -z "$ROTATE" || "$ROTATE" == "--rotate" ]] || die "4º argumento só pode ser --rotate"

STORE="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
SECRETS_DIR="/etc/caddy/secrets"
ENV_FILE="${SECRETS_DIR}/${SITE}.env"
PW_ENTRY="${PASS_PREFIX}-basic-auth"; CK_ENTRY="${PASS_PREFIX}-cookie"

command -v pass >/dev/null || die "pass ausente"
command -v caddy >/dev/null || die "caddy ausente"
if [[ -z "$ROTATE" ]]; then
  for e in "$PW_ENTRY" "$CK_ENTRY"; do
    [[ -e "${STORE}/${e}.gpg" ]] && die "pass ${e} já existe — recuso sobrescrever (use --rotate de propósito)"
  done
fi

# Tudo em variável de processo: nada em disco fora do pass (cifrado) e do env root 0600.
pw="$(openssl rand -base64 33 | tr -d '/+=\n' | cut -c1-32)"
ck="$(openssl rand -hex 32)"
[[ ${#pw} -eq 32 && ${#ck} -eq 64 ]] || die "geração de segredo falhou (tamanho inesperado)"
hash="$(printf '%s\n' "$pw" | caddy hash-password)"
[[ "$hash" =~ ^\$2[aby]\$[0-9]{2}\$[./A-Za-z0-9]{53}$ ]] || die "hash bcrypt com forma inesperada"

printf '%s\n' "$pw" | pass insert -m -f "$PW_ENTRY" >/dev/null || die "pass insert ${PW_ENTRY} falhou"
printf '%s\n' "$ck" | pass insert -m -f "$CK_ENTRY" >/dev/null || die "pass insert ${CK_ENTRY} falhou"

sudo install -d -m 0700 -o root -g root "$SECRETS_DIR"
printf '%s_BASIC_HASH=%s\n%s_COOKIE=%s\n' "$ENV_PREFIX" "$hash" "$ENV_PREFIX" "$ck" \
  | sudo sh -c "umask 077; cat > '${ENV_FILE}.new' && chown root:root '${ENV_FILE}.new' && mv '${ENV_FILE}.new' '${ENV_FILE}'"
unset pw ck hash

perm="$(sudo stat -c '%a %U:%G' "$ENV_FILE")"
[[ "$perm" == "600 root:root" ]] || die "permissão inesperada em ${ENV_FILE}: ${perm}"
echo "ok: pass ${PW_ENTRY} · pass ${CK_ENTRY} · ${ENV_FILE} (${perm})"
echo "próximo passo: ops/install-caddy-config.sh (renderiza o conf.d e recarrega)"
