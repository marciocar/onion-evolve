#!/usr/bin/env bash
# Puxa do core os anúncios deste membro — ADR onion-adr-federation-transport-pull D1.
#
# Por que SYNC e não fila: o endpoint serve TUDO que já foi anunciado a este membro, e
# aqui se baixa só o que falta (por sha256). Idempotente e AUTO-CURATIVO — um clone novo
# recupera o histórico inteiro. Rodar duas vezes seguidas não baixa nada na segunda.
#
# Credenciais em .env do adotante: ONION_FED_CLIENT_ID / _SECRET / _ORG_ID / (_ISSUER, _CORE)
set -euo pipefail
DRY=1; [ "${1:-}" = "--apply" ] && DRY=0
say() { printf '%s\n' "$*"; }

: "${ONION_FED_CLIENT_ID:?falta ONION_FED_CLIENT_ID no .env}"
: "${ONION_FED_CLIENT_SECRET:?falta ONION_FED_CLIENT_SECRET no .env}"
: "${ONION_FED_ORG_ID:?falta ONION_FED_ORG_ID no .env}"
ISSUER="${ONION_FED_ISSUER:-https://auth.onionevolve.com}"
CORE="${ONION_FED_CORE:-https://app.onionevolve.com}"
MEMBER="${ONION_FED_MEMBER:?falta ONION_FED_MEMBER (o id deste membro no members.yaml)}"
DEST="docs/evolution/inbound"

for t in curl jq sha256sum; do command -v "$t" >/dev/null || { echo "ERRO: '$t' ausente" >&2; exit 3; }; done

TOK="$(curl -sS -X POST "${ISSUER}/oidc/token" \
  --data-urlencode grant_type=client_credentials \
  --data-urlencode "organization_id=${ONION_FED_ORG_ID}" \
  -u "${ONION_FED_CLIENT_ID}:${ONION_FED_CLIENT_SECRET}" | jq -r '.access_token // empty')"
[ -n "${TOK}" ] || { echo "ERRO: não obtive token de organização" >&2; exit 4; }

MAN="$(curl -sS -m 30 -H "Authorization: Bearer ${TOK}" "${CORE}/federation/inbox/${MEMBER}")"
printf '%s' "${MAN}" | jq -e '.items' >/dev/null 2>&1 || {
  echo "ERRO do core: $(printf '%s' "${MAN}" | jq -r '.error // .' | head -c 200)" >&2; exit 5; }

mkdir -p "${DEST}/_processed"
new_items=0; ja=0
while IFS=$'\t' read -r name sha; do
  [ -n "${name}" ] || continue
  # Já tenho? Conta o _processed/ também — senão o puxador re-entrega o que já foi lido.
  for p in "${DEST}/${name}" "${DEST}/_processed/${name}"; do
    if [ -f "$p" ] && [ "$(sha256sum "$p" | cut -d' ' -f1)" = "${sha}" ]; then ja=$((ja+1)); continue 2; fi
  done
  if [ "${DRY}" = "0" ]; then
    curl -sS -m 30 -H "Authorization: Bearer ${TOK}" "${CORE}/federation/inbox/${MEMBER}?file=${name}" -o "${DEST}/${name}"
    got="$(sha256sum "${DEST}/${name}" | cut -d' ' -f1)"
    # Integridade não é opcional: conteúdo que não bate com o manifesto é DESCARTADO.
    [ "${got}" = "${sha}" ] || { rm -f "${DEST}/${name}"; echo "  ✗ ${name}: sha divergente — descartado" >&2; continue; }
    say "  ↓ ${name}"
  else
    say "  [DRY-RUN] baixaria ${name}"
  fi
  new_items=$((new_items+1))
done < <(printf '%s' "${MAN}" | jq -r '.items[] | "\(.name)\t\(.sha256)"')

say ""
say "📥 ${MEMBER}: ${new_items} novo(s), ${ja} já tinha$([ "${DRY}" = "1" ] && echo '  [DRY-RUN — use --apply]')"
