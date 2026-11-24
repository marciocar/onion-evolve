#!/usr/bin/env bash
# ops/gokapi-upload.sh — sobe um arquivo ao Gokapi do Onion (transfer.onionevolve.com) e imprime o link de download.
#
# POR QUÊ (2026-11-23): o maestro pediu que arquivo para ele chegue por link do Gokapi, peça do ecossistema Onion
# VPS, e não por anexo ou página. O core opera o upload; a chave de API foi criada uma vez pelo maestro (login de
# administrador) e guardada no pass em onion/vps-gokapi/api-upload.
#
# Segredo: a chave é lida só por dentro, por `pass show`, e vai ao curl por um descritor (`-H @<(...)`, printf
# embutido do bash), nunca em argv, em variável exportada ou na saída. Do retorno só sai o link ou o campo de erro.
# O arquivo vai pelo stdin com nome próprio entre aspas: `;` e `,` no caminho não viram diretiva do `-F` do curl.
# Com -F file=@- o curl pode ler o arquivo inteiro para a memória: feito para arquivos pequenos (fichas, relatórios).
# Este endpoint não cifra de ponta a ponta: se o servidor usar E2E, o arquivo fica em claro lá (openapi v2.2.4).
#
# Uso: ops/gokapi-upload.sh [--days N] [--downloads N] [--] <arquivo>   (padrão: 7 dias, 10 downloads; N >= 1)
# Saída: o link na stdout. rc 0 ok · 2 uso · 3 chave ausente · 4 upload recusado ou resposta sem link · 5 rede.
set -uo pipefail
{ set +x; } 2>/dev/null   # rastreio herdado (bash -x, SHELLOPTS) mostraria a chave
BASE="${GOKAPI_URL:-https://transfer.onionevolve.com}"
PASS_ENTRY="${GOKAPI_PASS_ENTRY:-onion/vps-gokapi/api-upload}"
DAYS=7; DOWNLOADS=10; FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --days) [ $# -ge 2 ] || { echo "gokapi-upload: --days pede um valor" >&2; exit 2; }; DAYS="$2"; shift ;;
    --downloads) [ $# -ge 2 ] || { echo "gokapi-upload: --downloads pede um valor" >&2; exit 2; }; DOWNLOADS="$2"; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    --) shift; [ -z "$FILE" ] && [ $# -eq 1 ] || { echo "gokapi-upload: um arquivo por vez" >&2; exit 2; }; FILE="$1"; shift; break ;;
    -*) echo "gokapi-upload: opção desconhecida: $1 (arquivo começando com '-'? use --)" >&2; exit 2 ;;
    *) [ -z "$FILE" ] || { echo "gokapi-upload: um arquivo por vez" >&2; exit 2; }; FILE="$1" ;;
  esac
  shift
done
[ -n "$FILE" ] && [ -f "$FILE" ] && [ -r "$FILE" ] || { echo "gokapi-upload: arquivo ausente ou ilegível: ${FILE:-<nenhum>}" >&2; exit 2; }
# 0 = sem limite no Gokapi: link perpétuo ao maestro não sai daqui por descuido
[[ "$DAYS" =~ ^[1-9][0-9]*$ && "$DOWNLOADS" =~ ^[1-9][0-9]*$ ]] \
  || { echo "gokapi-upload: --days e --downloads são inteiros >= 1 (0 = sem limite no Gokapi, recusado)" >&2; exit 2; }
# a chave só viaja por https (um GOKAPI_URL trocado não a leva a outro lugar em claro)
[[ "$BASE" =~ ^https://[^/@?#]+$ ]] || { echo "gokapi-upload: GOKAPI_URL tem de ser https://<host>, sem caminho: $BASE" >&2; exit 2; }
command -v pass >/dev/null && command -v curl >/dev/null && command -v jq >/dev/null \
  || { echo "gokapi-upload: preciso de pass, curl e jq" >&2; exit 2; }

key="$(pass show "$PASS_ENTRY")" || { echo "gokapi-upload: não li a chave em ${PASS_ENTRY} (pass saiu não-zero)" >&2; exit 3; }
key="${key%%$'\n'*}"; key="${key%$'\r'}"
[ -n "$key" ] || { echo "gokapi-upload: a chave em ${PASS_ENTRY} está vazia" >&2; exit 3; }

# nome enviado: o basename, sem aspas, barra invertida nem quebra de linha (vão entre aspas no -F)
name="$(basename -- "$FILE")"; name="${name//[\"\\$'\n'$'\r']/_}"

resp="$(curl -sS --max-time 120 --fail-with-body -H @<(printf 'apikey: %s\n' "$key") \
          -F "file=@-;filename=\"${name}\"" -F "allowedDownloads=${DOWNLOADS}" -F "expiryDays=${DAYS}" \
          "${BASE}/api/files/add" < "$FILE")"; crc=$?
unset key
if [ "$crc" -ne 0 ] && [ "$crc" -ne 22 ]; then
  echo "gokapi-upload: a requisição não chegou ao fim (curl rc ${crc}: rede, DNS, TLS ou tempo)" >&2; exit 5
fi
url="$(jq -r '.FileInfo.UrlDownload // empty' <<< "$resp" 2>/dev/null)"
if [ "$crc" -eq 0 ] && [ -z "$url" ] && jq -e '.FileInfo' <<< "$resp" >/dev/null 2>&1; then
  echo "gokapi-upload: o servidor guardou o arquivo mas não devolveu UrlDownload (versão do Gokapi mudou?); confira no painel" >&2; exit 4
fi
if [ "$crc" -ne 0 ] || [ -z "$url" ]; then
  # nunca imprime o corpo inteiro: só o campo de erro, se houver
  err="$(jq -r '.ErrorMessage // .Result // "resposta sem link"' <<< "$resp" 2>/dev/null)" || err="resposta não é JSON"
  echo "gokapi-upload: upload recusado (curl rc ${crc}): ${err}" >&2; exit 4
fi
printf '%s\n' "$url"
