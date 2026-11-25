#!/usr/bin/env bash
# ops/gokapi-fetch.sh — PONTE DE IMAGEM, lado VPS: baixa uma imagem do Gokapi do Onion pela API e imprime só o caminho.
#
# POR QUÊ (2026-11-25): o maestro trabalha no Windows (Windows Terminal + mosh + tmux) e a sessão do Claude Code roda na
# VPS. O Ctrl+V do terminal lê o clipboard da VPS, e o OSC 52 não leva imagem (anthropics/claude-code#42712, not
# planned). O Claude Code aceita imagem pelo CAMINHO do arquivo no disco onde ele roda (doc oficial, «Work with
# images»). Fluxo 2 da ponte: o maestro cola a imagem no painel do Gokapi (navegador ou celular), manda o link à sessão,
# e a sessão roda este script e lê o caminho com Read. O fluxo 1 (principal) é o atalho do Windows por sftp:
# ops/windows/onion-paste-image.ps1. KB: docs/knowledge-base/concepts/send-image-to-session.md.
#
# Segredo: a chave de API (precisa da permissão DOWNLOAD) é lida só por dentro, por `pass show`, e vai ao curl por
# descritor (`-H @<(...)`), nunca em argv, variável exportada ou na saída. Por padrão é a mesma entrada do pass que o
# ops/gokapi-upload.sh usa: o nome diz «upload», mas a chave tem todas as permissões (maestro, 2026-11-25).
# O curl roda com -q (ignora o ~/.curlrc: um `location` lá levaria o cabeçalho apikey a outro host no redirect, achado do
# refutador em 2026-11-25) e com --max-redirs 0: a chave não vai a outro host. Só https, salvo loopback (a bancada).
# A imagem baixada é DADO não confiável (R15.2): o script confere o tipo pelos bytes mágicos, não pelo nome nem pelo
# cabeçalho, e grava com nome próprio (data + id), nunca o nome que veio do servidor.
#
# Uso:
#   ops/gokapi-fetch.sh [--] <id | link de download>   baixa e imprime o caminho absoluto da imagem
#   ops/gokapi-fetch.sh --check [--offline]            mede a configuração e faz UMA chamada só-leitura autenticada:
#                                                      imprime o HTTP e se a permissão de download está presente
#                                                      (nunca a chave nem dado do servidor); --offline não usa a rede
#   ops/gokapi-fetch.sh --prune [--days N] [--dry-run] apaga imagens recebidas há N dias ou mais (padrão 7), só na pasta
#   ops/gokapi-fetch.sh --dir                          imprime a pasta de imagens recebidas
# Ambiente: GOKAPI_URL (padrão https://transfer.onionevolve.com) · GOKAPI_FETCH_PASS_ENTRY (padrão
#   onion/vps-gokapi/api-upload, a MESMA chave do gokapi-upload.sh, que tem todas as permissões) · ONION_IMAGE_INBOX (padrão ~/.local/share/onion/inbox-images) ·
#   ONION_IMAGE_MAX_BYTES (padrão 20971520 = 20 MiB) · ONION_IMAGE_KEEP_DAYS (padrão 7, a limpeza automática).
# Saída: rc 0 ok · 2 uso, configuração ou chave ausente · 3 HTTP, rede ou arquivo cifrado · 4 não é imagem ou grande demais
#        · 5 (só --check) sonda inconclusiva: a resposta não é o erro de «arquivo não encontrado» do Gokapi.
set -uo pipefail
{ set +x; } 2>/dev/null   # rastreio herdado (bash -x, SHELLOPTS) mostraria a chave
umask 077

BASE="${GOKAPI_URL:-https://transfer.onionevolve.com}"
PASS_ENTRY="${GOKAPI_FETCH_PASS_ENTRY:-onion/vps-gokapi/api-upload}"
INBOX="${ONION_IMAGE_INBOX:-${XDG_DATA_HOME:-${HOME}/.local/share}/onion/inbox-images}"
MAX_BYTES="${ONION_IMAGE_MAX_BYTES:-20971520}"
KEEP_DAYS="${ONION_IMAGE_KEEP_DAYS:-7}"
# nome que a ponte grava (este script e o .ps1 do Windows): AAAAMMDD-HHMMSS-<resto>.<ext>; a limpeza só toca nisto
NAME_GLOB='[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]-*'

die() { local rc="$1"; shift; printf 'gokapi-fetch: %s\n' "$*" >&2; exit "${rc}"; }

key_missing_msg() {
  printf 'falta a chave de API do Gokapi: a entrada do pass %s (variável GOKAPI_FETCH_PASS_ENTRY) não existe, não abriu ou está vazia.\n' "${PASS_ENTRY}"
  printf '  É a mesma chave do ops/gokapi-upload.sh (com permissão de download). Aponte a variável para a entrada certa\n'
  printf '  e confira com: ops/gokapi-fetch.sh --check. Guia de integrações: /meta:setup-integration.\n'
}

check_base() {
  # a chave só viaja por https; http só para loopback (servidor falso da bancada), nunca pela rede
  [[ "${BASE}" =~ ^https://[^/@?#]+$ || "${BASE}" =~ ^http://(127\.0\.0\.1|localhost|\[::1\])(:[0-9]+)?$ ]] \
    || die 2 "GOKAPI_URL tem de ser https://<host> sem caminho (http só em loopback): ${BASE}"
}

# a pasta privada: criada 0700, nunca um link simbólico, nunca a raiz nem o HOME
inbox_guard() {
  [ -n "${INBOX}" ] || die 2 "ONION_IMAGE_INBOX vazio"
  while [ "${INBOX}" != "/" ] && [ "${INBOX%/}" != "${INBOX}" ]; do INBOX="${INBOX%/}"; done   # «lnk/» furava o -L
  case "${INBOX}" in /*) ;; *) die 2 "ONION_IMAGE_INBOX tem de ser caminho absoluto: ${INBOX}" ;; esac
  case "${INBOX}/" in */./*|*/../*|*//*) die 2 "ONION_IMAGE_INBOX com «.», «..» ou «//», recuso: ${INBOX}" ;; esac
  [ -L "${INBOX}" ] && die 2 "a pasta de imagens é um link simbólico, recuso: ${INBOX}"
  local home_real real; home_real="$(cd "${HOME}" 2>/dev/null && pwd -P)" || die 2 "HOME ilegível: ${HOME}"
  # dentro do HOME e abaixo dele (nunca o HOME, a raiz ou outra pasta do sistema)
  case "$(expected_real "${INBOX}" "${home_real}")" in "${home_real}"/?*) ;; *) die 2 "a pasta de imagens tem de ficar dentro do HOME (${home_real}): ${INBOX}" ;; esac
  # nenhum link simbólico no MEIO do caminho: o ancestral mais fundo que existe resolve para onde o texto diz
  # (HOME/lnk/inbox com lnk → fora do HOME fazia o mkdir criar a pasta lá fora; revisão isolada, 2026-11-25)
  local anc="${INBOX}"; while [ ! -e "${anc}" ] && [ "${anc}" != "/" ]; do anc="$(dirname -- "${anc}")"; done
  real="$(cd "${anc}" 2>/dev/null && pwd -P)" || die 2 "não li a pasta ${anc}"
  [ "${real}" = "$(expected_real "${anc}" "${home_real}")" ] \
    || die 2 "há um link simbólico no caminho da pasta de imagens (${anc} → ${real}), recuso: ${INBOX}"
}

# o caminho real esperado: o texto, com o prefixo do HOME trocado pelo HOME resolvido (o HOME pode ser um link legítimo)
expected_real() {  # $1=caminho absoluto, $2=HOME resolvido
  case "$1" in "${HOME%/}"/*) printf '%s/%s' "$2" "${1#"${HOME%/}"/}" ;; "${HOME%/}") printf '%s' "$2" ;; *) printf '%s' "$1" ;; esac
}

inbox_make() {
  inbox_guard
  mkdir -p -- "${INBOX}" || die 2 "não criei a pasta de imagens: ${INBOX}"
  [ -L "${INBOX}" ] && die 2 "a pasta de imagens é um link simbólico, recuso: ${INBOX}"
  # refaz a contenção DEPOIS do mkdir, pelo caminho resolvido (corrida entre a conferência e a criação)
  local hr; hr="$(cd "${HOME}" 2>/dev/null && pwd -P)" || die 2 "HOME ilegível: ${HOME}"
  [ "$(cd "${INBOX}" 2>/dev/null && pwd -P)" = "$(expected_real "${INBOX}" "${hr}")" ] \
    || die 2 "a pasta de imagens resolveu para fora do caminho esperado, recuso: ${INBOX}"
  [ -O "${INBOX}" ] || die 2 "a pasta de imagens não é desta conta: ${INBOX}"
  chmod 700 -- "${INBOX}" || die 2 "não consegui fechar a pasta em 0700: ${INBOX}"
}

prune() {  # $1 = dias, $2 = 1 para ensaio; só arquivos comuns da ponte, só no 1º nível da pasta, sem seguir link
  local days="$1" dry="${2:-0}" n=0 f
  [[ "${days}" =~ ^[1-9][0-9]*$ ]] || die 2 "--days é um inteiro >= 1: ${days}"
  inbox_guard
  [ -d "${INBOX}" ] || { printf 'gokapi-fetch: pasta ainda não existe, nada a limpar: %s\n' "${INBOX}" >&2; return 0; }
  while IFS= read -r -d '' f; do
    if [ "${dry}" = 1 ]; then printf 'ensaio: apagaria %s\n' "${f}" >&2
    else rm -f -- "${f}" && n=$((n + 1)); fi
  done < <(find "${INBOX}" -mindepth 1 -maxdepth 1 -type f \( -name "${NAME_GLOB}" -mtime "+$((days - 1))" -o -name '.part-*' -mmin +60 \) -print0 2>/dev/null)
  [ "${dry}" = 1 ] || [ "${n}" -eq 0 ] || printf 'gokapi-fetch: %s imagem(ns) com mais de %s dia(s) apagada(s) de %s\n' "${n}" "${days}" "${INBOX}" >&2
  return 0
}

# id: o próprio id, ou o link de download (…?id=<id>). Link de hotlink não traz o id do arquivo.
extract_id() {
  local in="$1" id="" host
  if [[ "${in,,}" =~ ^https?:// ]]; then
    host="${in#*://}"; host="${host%%[/?#]*}"; host="${host,,}"
    [ "${host}" = "$(printf '%s' "${BASE#*://}" | tr '[:upper:]' '[:lower:]')" ] || die 2 "o link é de outro servidor (${host}), não do Gokapi configurado (${BASE#*://})"
    if [[ "${in}" =~ [?\&]id=([A-Za-z0-9_-]+)(&|#|$) ]]; then id="${BASH_REMATCH[1]}"
    elif [[ "${in}" =~ /(h|hotlink)/ ]]; then die 2 "link de hotlink não traz o id do arquivo: copie o link de DOWNLOAD (o que tem ?id=)"
    else die 2 "não achei ?id= no link: ${in}"; fi
  else
    id="${in}"
  fi
  [[ "${id}" =~ ^[A-Za-z0-9][A-Za-z0-9_-]{3,63}$ ]] || die 2 "id inválido (letras, dígitos, _ e -, de 4 a 64, sem começar por -): ${id}"
  printf '%s' "${id}"
}

# tipo pelos bytes mágicos → extensão; vazio = não é imagem da allowlist
magic_ext() {
  local h; h="$(head -c 12 -- "$1" | od -An -tx1 | tr -d ' \n')"
  case "${h}" in
    89504e470d0a1a0a*) echo png ;;
    ffd8ff*) echo jpg ;;
    474946383761*|474946383961*) echo gif ;;
    52494646????????57454250) echo webp ;;
    *) echo "" ;;
  esac
}

ctype_ext() {  # content-type → extensão; "any" = genérico (decide o magic); "" = tipo que não é imagem
  local ct; ct="$(printf '%s' "${1%%;*}" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  case "${ct}" in
    image/png) echo png ;;
    image/jpeg|image/jpg) echo jpg ;;
    image/gif) echo gif ;;
    image/webp) echo webp ;;
    ""|application/octet-stream|binary/octet-stream) echo any ;;
    *) echo "" ;;
  esac
}

MODE="fetch"; ARG=""; DAYS="${KEEP_DAYS}"; DRY=0; OFFLINE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check" ;;
    --prune) MODE="prune" ;;
    --dir) MODE="dir" ;;
    --days) [ $# -ge 2 ] || die 2 "--days pede um valor"; DAYS="$2"; shift ;;
    --dry-run) DRY=1 ;;
    --offline) OFFLINE=1 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    --) shift; [ -z "${ARG}" ] && [ $# -eq 1 ] || die 2 "um id ou link por vez"; ARG="$1"; shift; break ;;
    -*) die 2 "opção desconhecida: $1 (id começando com '-'? use --)" ;;
    *) [ -z "${ARG}" ] || die 2 "um id ou link por vez"; ARG="$1" ;;
  esac
  shift
done

case "${MODE}" in
  dir) inbox_guard; printf '%s\n' "${INBOX}"; exit 0 ;;
  prune) [ -z "${ARG}" ] || die 2 "--prune não leva id"; prune "${DAYS}" "${DRY}"; exit 0 ;;
  check)
    bad=0; check_base
    for c in pass curl od; do command -v "${c}" >/dev/null || { printf 'gokapi-fetch: falta o comando %s\n' "${c}" >&2; bad=1; }; done
    [[ "${MAX_BYTES}" =~ ^[1-9][0-9]*$ ]] || { printf 'gokapi-fetch: ONION_IMAGE_MAX_BYTES inválido: %s\n' "${MAX_BYTES}" >&2; bad=1; }
    [[ "${KEEP_DAYS}" =~ ^[1-9][0-9]*$ ]] || { printf 'gokapi-fetch: ONION_IMAGE_KEEP_DAYS inválido (inteiro >= 1): %s\n' "${KEEP_DAYS}" >&2; bad=1; }
    inbox_guard
    # existência da entrada pelo arquivo cifrado (stat, sem decifrar nem ler o conteúdo)
    store="${PASSWORD_STORE_DIR:-${HOME}/.password-store}"
    if [ -f "${store}/${PASS_ENTRY}.gpg" ]; then key_state="presente"
    else key_state="AUSENTE"; key_missing_msg >&2; fi
    printf 'servidor: %s\nchave (pass): %s → %s\npasta: %s%s\nteto: %s bytes · limpeza: %s dia(s)\n' \
      "${BASE}" "${PASS_ENTRY}" "${key_state}" "${INBOX}" "$([ -d "${INBOX}" ] && echo '' || echo ' (criada no 1º uso)')" "${MAX_BYTES}" "${KEEP_DAYS}"
    [ "${key_state}" = "presente" ] || exit 2
    [ "${bad}" -eq 0 ] || exit 2
    [ "${OFFLINE}" -eq 1 ] && { printf 'download: não medido (--offline)\n'; exit 0; }
    # UMA chamada só-leitura: download de um id de sonda que não existe. INFERÊNCIA até a 1ª medida contra o servidor
    # real: o Gokapi confere a permissão antes de procurar o arquivo. Então 404 COM o erro JSON de arquivo não encontrado
    # = a chave passou e tem DOWNLOAD; 401/403 = falta a permissão; qualquer outra resposta (404 de proxy, página HTML)
    # = inconclusiva, rc 5. Do corpo nada é impresso: só se lê se ele é aquele erro.
    key="$(pass show "${PASS_ENTRY}" 2>/dev/null)" || { key_missing_msg >&2; exit 2; }
    key="${key%%$'\n'*}"; key="${key%$'\r'}"
    [ -n "${key}" ] || { key_missing_msg >&2; exit 2; }
    pbody="$(mktemp)" || die 2 "não criei o arquivo temporário da sonda"
    pcode="$(curl -q -sS --max-time 30 --proto '=https,http' --max-redirs 0 --max-filesize 65536 -o "${pbody}" -w '%{http_code}' \
               -H @<(printf 'apikey: %s\n' "${key}") "${BASE}/api/files/download/onionprobe000" 2>/dev/null)"; pcrc=$?
    unset key
    pjson="$(head -c 2000 -- "${pbody}" | tr -d '\000-\037')"; rm -f -- "${pbody}"
    gokapi_404=0
    [[ "${pjson}" =~ ^[[:space:]]*\{.*\"(ErrorMessage|Result)\"[[:space:]]*:.*[Nn]ot[[:space:]]+[Ff]ound ]] && gokapi_404=1
    [ "${pcrc}" -eq 0 ] || { printf 'download: não medido (curl rc %s: rede, DNS, TLS ou tempo)\n' "${pcrc}"; exit 3; }
    case "${pcode}" in
      404) if [ "${gokapi_404}" -eq 1 ]; then
             printf 'download: presente (HTTP 404 com o erro de arquivo não encontrado do Gokapi: inferência, a chave passou)\n'; exit 0
           fi
           printf 'download: inconclusivo (HTTP 404 sem o erro JSON do Gokapi: proxy ou outro servidor?)\n'; exit 5 ;;
      401|403) printf 'download: AUSENTE (HTTP %s: a chave não tem permissão de download ou foi revogada)\n' "${pcode}"; exit 3 ;;
      *) printf 'download: inconclusivo (HTTP %s na sonda)\n' "${pcode}"; exit 5 ;;
    esac ;;
esac

[ -n "${ARG}" ] || die 2 "uso: ops/gokapi-fetch.sh <id | link de download>   (ou --check, --prune, --dir, --help)"
check_base
[[ "${MAX_BYTES}" =~ ^[1-9][0-9]*$ ]] || die 2 "ONION_IMAGE_MAX_BYTES inválido: ${MAX_BYTES}"
[[ "${KEEP_DAYS}" =~ ^[1-9][0-9]*$ ]] || die 2 "ONION_IMAGE_KEEP_DAYS é um inteiro >= 1 (dias até a limpeza): ${KEEP_DAYS}"
ID="$(extract_id "${ARG}")" || exit $?
command -v pass >/dev/null && command -v curl >/dev/null && command -v od >/dev/null || die 2 "preciso de pass, curl e od"

key="$(pass show "${PASS_ENTRY}" 2>/dev/null)" || { key_missing_msg >&2; exit 2; }
key="${key%%$'\n'*}"; key="${key%$'\r'}"
[ -n "${key}" ] || { key_missing_msg >&2; exit 2; }

inbox_make
tmp="$(mktemp "${INBOX}/.part-XXXXXX")" || die 2 "não criei o arquivo temporário em ${INBOX}"
trap 'rm -f -- "${tmp}"' EXIT
trap 'exit 129' HUP; trap 'exit 130' INT; trap 'exit 143' TERM   # o EXIT apaga o .part também quando o processo é morto
meta="$(curl -q -sS --max-time 120 --proto '=https,http' --max-redirs 0 --max-filesize "${MAX_BYTES}" -o "${tmp}" \
          -w '%{http_code}\t%{content_type}' -H @<(printf 'apikey: %s\n' "${key}") \
          "${BASE}/api/files/download/${ID}" 2>/dev/null)"; crc=$?
unset key
code="${meta%%$'\t'*}"; ctype="${meta#*$'\t'}"
[ "${crc}" -eq 63 ] && die 4 "a imagem passa do teto de ${MAX_BYTES} bytes (ONION_IMAGE_MAX_BYTES)"
[ "${crc}" -eq 0 ] || die 3 "a requisição não chegou ao fim (curl rc ${crc}: rede, DNS, TLS ou tempo)"
if [ "${code}" != "200" ]; then
  # nunca o corpo inteiro: só o campo de erro, curto e sem caracteres de controle
  err="$(head -c 400 -- "${tmp}" | tr -d '\000-\037' | sed -n 's/.*"\(ErrorMessage\|Result\|error\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p' | head -c 200)"
  case "${code}" in
    401|403) die 3 "HTTP ${code}: a chave em ${PASS_ENTRY} não tem permissão de download (ou foi revogada)${err:+: ${err}}" ;;
    404) die 3 "HTTP 404: o arquivo ${ID} não existe ou expirou no Gokapi${err:+: ${err}}" ;;
  esac
  if grep -qi 'encrypt' <<< "${err}"; then
    die 3 "HTTP ${code}: o arquivo está cifrado de ponta a ponta e a API não o entrega; suba de novo sem cifra E2E${err:+ (${err})}"
  fi
  die 3 "HTTP ${code}: o Gokapi recusou o download${err:+: ${err}}"
fi
size="$(wc -c < "${tmp}" | tr -d ' ')"
[ "${size}" -gt 0 ] || die 4 "o servidor devolveu um arquivo vazio"
[ "${size}" -le "${MAX_BYTES}" ] || die 4 "a imagem passa do teto de ${MAX_BYTES} bytes (ONION_IMAGE_MAX_BYTES)"
ext="$(magic_ext "${tmp}")"
cext="$(ctype_ext "${ctype}")"
[ -n "${ext}" ] || die 4 "não é imagem png, jpeg, webp ou gif (pelos bytes; content-type ${ctype:-ausente})"
[ -n "${cext}" ] || die 4 "o servidor diz que não é imagem (content-type ${ctype})"
[ "${cext}" = "any" ] || [ "${cext}" = "${ext}" ] || die 4 "o content-type (${ctype}) não bate com os bytes (${ext})"

dest="${INBOX}/$(date +%Y%m%d-%H%M%S)-${ID}.${ext}"
[ -e "${dest}" ] && dest="${INBOX}/$(date +%Y%m%d-%H%M%S)-${ID}-$$.${ext}"
chmod 600 -- "${tmp}" && mv -f -- "${tmp}" "${dest}" || die 2 "não gravei a imagem em ${dest}"
trap - EXIT HUP INT TERM
# limpeza oportunista: o que passou do prazo sai a cada imagem recebida; num subshell, para um erro dela nunca
# derrubar o recebimento já gravado (o die dela sairia do script antes de imprimir o caminho)
( prune "${KEEP_DAYS}" 0 ) 2>/dev/null || true
printf '%s\n' "$(cd "$(dirname -- "${dest}")" && pwd -P)/$(basename -- "${dest}")"
