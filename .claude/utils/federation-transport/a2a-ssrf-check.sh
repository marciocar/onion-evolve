#!/usr/bin/env bash
# =============================================================================
# a2a-ssrf-check.sh — valida a URL de um PushNotificationConfig (webhook A2A) contra SSRF.
#
# F2.2 do roadmap de federação (RFC-0004), FUNDAÇÃO SEGURA no core (endpoint vivo fica no repo da VPS).
# Camada 4 do gate a2a-verify.sh: a spec A2A exige anti-SSRF do receptor (não confiar cegamente na URL do
# cliente). Duas camadas:
#   (a) DENY-LIST dependency-free (regex/case) — SEMPRE avaliável, NUNCA derrubável por dependência ausente:
#       localhost, loopback, faixas privadas (RFC-1918), link-local + metadata de nuvem (169.254.169.254),
#       ULA/link-local IPv6, esquemas não-http(s). Fail-safe estrutural: o bloqueio crítico não depende de nada.
#   (b) ALLOW-LIST positiva — host ∈ hosts conhecidos dos membros (campo `remote:` do members.yaml).
#       python3+yaml ausente → NÃO consigo estabelecer a allowlist → `deny tooling-absent:python-yaml`.
#
# ⚠️ DIVERGÊNCIA DE IDIOMA DECLARADA (espelha factory.md): geradores de artefato degradam GRACIOSO (skip);
#    um gate de SEGURANÇA degrada para VETO/DENY (RFC-0004 §4: "sem output válido = veto; ausência nunca é
#    aprovação"). Skip aqui seria fail-open — o antipadrão que a RFC proíbe.
#
# Uso : a2a-ssrf-check.sh <url>            → imprime "allow" | "deny <motivo>"
# Exit: 0 = allow · 1 = deny · 2 = uso incorreto
# Override p/ teste: A2A_MEMBERS_FILE=<path> (default: <git-root>/docs/evolution/federation/members.yaml)
# Offline: NÃO faz rede (não resolve DNS, não conecta) — só análise léxica da URL + leitura local do SSOT.
# Exercitado por lint-selftest.sh (run_a2a_ssrf_selftests).
# =============================================================================
set -uo pipefail

URL="${1:-}"; [ -n "${URL}" ] || { echo "uso: a2a-ssrf-check.sh <url>" >&2; exit 2; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../.." && pwd))"
MEMBERS="${A2A_MEMBERS_FILE:-${ROOT}/docs/evolution/federation/members.yaml}"

deny() { echo "deny $1"; exit 1; }

# --- (a) DENY-LIST estrutural (sem dependências) ------------------------------
# esquema: só http(s)
case "${URL}" in
  http://*|https://*) ;;
  *) deny "scheme:non-http" ;;
esac

# extrai a autoridade (host[:port]) sem scheme, userinfo, path, query
rest="${URL#*://}"
authority="${rest%%/*}"        # antes da 1ª '/'
authority="${authority%%\?*}"  # antes de '?' (query sem path)
authority="${authority%%#*}"   # antes de '#'
authority="${authority##*@}"   # remove userinfo user:pass@

# host: trata [ipv6]:port vs host:port
if [ "${authority#\[}" != "${authority}" ]; then      # começa com '['
  host="${authority%%]*}"; host="${host#\[}"          # ipv6 sem colchetes
else
  host="${authority%%:*}"                              # remove :port
fi
host="$(printf '%s' "${host}" | tr 'A-Z' 'a-z')"
[ -n "${host}" ] || deny "empty-host"

# IPv6 (contém ':') — loopback / link-local / ULA
case "${host}" in
  ::1|::|0:*|:*) deny "ipv6-loopback" ;;
  fe8*:*|fe9*:*|fea*:*|feb*:*) deny "ipv6-link-local" ;;   # fe80::/10
  fc*:*|fd*:*) deny "ipv6-ula" ;;                          # fc00::/7
esac

# IPv4 loopback / this-network / RFC-1918 / link-local+metadata
case "${host}" in
  localhost|*.localhost|ip6-localhost) deny "localhost" ;;
  127.*|0.*|0.0.0.0) deny "loopback" ;;
  10.*) deny "rfc1918-10" ;;
  192.168.*) deny "rfc1918-192" ;;
  169.254.*) deny "link-local-metadata" ;;                # inclui 169.254.169.254 (cloud metadata)
  172.*)                                                  # 172.16.0.0/12 = 172.16..172.31
    o2="${host#172.}"; o2="${o2%%.*}"
    case "${o2}" in
      1[6-9]|2[0-9]|3[01])
        [ "${o2}" -ge 16 ] 2>/dev/null && [ "${o2}" -le 31 ] 2>/dev/null && deny "rfc1918-172" ;;
    esac ;;
esac

# --- (b) ALLOW-LIST positiva (hosts conhecidos do members.yaml) ---------------
# python3+yaml é OBRIGATÓRIO p/ estabelecer a allowlist → ausente = deny (fail-safe, não skip).
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || deny "tooling-absent:python-yaml"
[ -f "${MEMBERS}" ] || deny "members-absent"

known="$(python3 - "${MEMBERS}" <<'PY'
import sys, yaml
try: ms=(yaml.safe_load(open(sys.argv[1])) or {}).get('members') or []
except Exception: sys.exit(0)
hosts=set()
for m in ms:
    r=(m.get('remote') or '').strip()
    if not r: continue
    if '://' in r: r=r.split('://',1)[1]
    r=r.split('/',1)[0].split('@',1)[-1].split(':',1)[0].lower()  # host puro
    if r: hosts.add(r)
for h in sorted(hosts): print(h)
PY
)"

for k in ${known}; do
  [ "${host}" = "${k}" ] && { echo "allow"; exit 0; }
done
deny "not-in-allowlist:${host}"
