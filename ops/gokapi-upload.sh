#!/usr/bin/env bash
# ops/gokapi-upload.sh — sobe um arquivo ao Gokapi do Onion (transfer.onionevolve.com) e imprime o link de download.
#
# POR QUÊ (2026-11-23): o maestro pediu que arquivo para ele chegue por link do Gokapi, peça do ecossistema Onion
# VPS, e não por anexo ou página. O core opera o upload; a chave de API foi criada uma vez pelo maestro (login de
# administrador) e guardada no pass em onion/vps-gokapi/api-upload.
#
# Segredo: a chave é lida só por dentro, por `pass show`, e vai ao curl pelo stdin (`-H @-`), nunca em argv, em
# variável exportada ou na saída. Nada do retorno é impresso além do link.
#
# Uso: ops/gokapi-upload.sh <arquivo> [--days N] [--downloads N]   (padrão: 7 dias, 10 downloads)
# Saída: o link na stdout. rc 0 ok · 2 uso · 3 chave ausente · 4 upload recusado ou resposta sem link.
set -uo pipefail
BASE="${GOKAPI_URL:-https://transfer.onionevolve.com}"
PASS_ENTRY="${GOKAPI_PASS_ENTRY:-onion/vps-gokapi/api-upload}"
DAYS=7; DOWNLOADS=10; FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS="${2:-}"; shift ;;
    --downloads) DOWNLOADS="${2:-}"; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    -*) echo "gokapi-upload: opção desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "$FILE" ] || { echo "gokapi-upload: um arquivo por vez" >&2; exit 2; }; FILE="$1" ;;
  esac
  shift
done
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "gokapi-upload: arquivo ausente: ${FILE:-<nenhum>}" >&2; exit 2; }
[[ "$DAYS" =~ ^[0-9]+$ && "$DOWNLOADS" =~ ^[0-9]+$ ]] || { echo "gokapi-upload: --days e --downloads são inteiros" >&2; exit 2; }
command -v pass >/dev/null && command -v curl >/dev/null && command -v jq >/dev/null \
  || { echo "gokapi-upload: preciso de pass, curl e jq" >&2; exit 2; }

resp="$(
  { printf 'apikey: '; pass show "$PASS_ENTRY" 2>/dev/null | head -n1 | tr -d '\r\n'; printf '\n'; } \
  | curl -sS --max-time 120 -H @- \
      -F "file=@${FILE}" -F "allowedDownloads=${DOWNLOADS}" -F "expiryDays=${DAYS}" \
      "${BASE}/api/files/add" 2>/dev/null
)" || { echo "gokapi-upload: a requisição falhou (rede ou chave ausente em ${PASS_ENTRY})" >&2; exit 4; }
url="$(jq -r '.FileInfo.UrlDownload // .FileInfo.UrlHotlink // empty' <<< "$resp" 2>/dev/null)"
if [ -z "$url" ]; then
  # nunca imprime o corpo inteiro: só o campo de erro, se houver
  err="$(jq -r '.ErrorMessage // .Result // "resposta sem link"' <<< "$resp" 2>/dev/null || echo 'resposta não é JSON')"
  echo "gokapi-upload: upload recusado: ${err}" >&2; exit 4
fi
printf '%s\n' "$url"
