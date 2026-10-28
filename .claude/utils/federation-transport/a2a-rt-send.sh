#!/usr/bin/env bash
# =============================================================================
# a2a-rt-send.sh — o ENVIO HUMANO de um rascunho do a2a-rt. Roda no TERMINAL do humano, nunca como ferramenta.
#
# Par da peça de rascunho (a2a-rt-mcp.py): a sessão só GRAVA rascunho; este script mostra o rascunho, pede
# uma confirmação DIGITADA no terminal (/dev/tty) e só então assina e envia, reusando o remetente canônico
# (a2a-send.sh). Sem terminal, sem a palavra certa ou com rascunho já enviado: RECUSA, e nada sai.
# Não há flag que pule a confirmação, de propósito: a ação explícita do humano É o ato de envio.
#
# Dois lados (PRE-REGISTRO.md §5, item 6, docs/evolution/research/a2a-ida-e-volta-vps-notebook-2026-10/):
#   --side core    (VPS) assina com o kid do core e GRAVA o envelope no outbox que a retirada do membro lê
#                  por ssh; nada vai à rede daqui. Defaults: --from onion-evolve, --kid onion-evolve-spike-1,
#                  kind question, exp de 3600 s, outbox ~/.local/state/onion/a2a-spike/outbox
#   --side member  (notebook) envia ao /a2a do receptor pelo a2a-send.sh, com o --thread do rascunho (ou o
#                  --thread dado). Exige --endpoint (sem default: nada sai por acidente)
#
# Uso: a2a-rt-send.sh --side core|member --draft <id> [--state D] [--from ID] [--kid K] [--key F]
#                     [--endpoint URL] [--token-file F] [--thread T] [--outbox D] [--exp-offset S]
#   --state D   o estado do a2a-rt (default ~/.local/state/onion/a2a-rt): lê drafts/<id>.json
# A chave privada e o token só são lidos pelo a2a-send.sh, por arquivo 0600 (nunca argv, nunca log).
# Depois do envio, o rascunho vai para drafts/sent/ e o par (rascunho, jti) entra em sent.tsv: o mesmo
# rascunho não sai duas vezes.
# Exit: 0 enviado (ou gravado no outbox) · 1 envio falhou (HTTP != 200) · 2 uso, rascunho inválido ou ferramenta
#       ausente · 4 RECUSADO: sem terminal ou sem a confirmação digitada
# Exercitado por lint-selftest.sh (run_a2a_rt_selftests).
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEND="${HERE}/a2a-send.sh"
STATE="${HOME}/.local/state/onion/a2a-rt"
SIDE=""; DRAFT=""; FROM=""; KID=""; KEY=""; ENDPOINT=""; TOKEN_FILE=""; THREAD=""
OUTBOX="${HOME}/.local/state/onion/a2a-spike/outbox"; EXP_OFF=3600

die() { echo "a2a-rt-send: $*" >&2; exit 2; }
refuse() { echo "a2a-rt-send: RECUSADO — $* Nada foi enviado." >&2; exit 4; }
need() { [ "$#" -ge 2 ] && [ -n "$2" ] || die "$1 exige valor"; }
while [ "$#" -gt 0 ]; do case "$1" in
  --side) need "$@"; SIDE="$2"; shift 2 ;;
  --draft) need "$@"; DRAFT="$2"; shift 2 ;;
  --state) need "$@"; STATE="$2"; shift 2 ;;
  --from) need "$@"; FROM="$2"; shift 2 ;;
  --kid) need "$@"; KID="$2"; shift 2 ;;
  --key) need "$@"; KEY="$2"; shift 2 ;;
  --endpoint) need "$@"; ENDPOINT="$2"; shift 2 ;;
  --token-file) need "$@"; TOKEN_FILE="$2"; shift 2 ;;
  --thread) need "$@"; THREAD="$2"; shift 2 ;;
  --outbox) need "$@"; OUTBOX="$2"; shift 2 ;;
  --exp-offset) need "$@"; EXP_OFF="$2"; shift 2 ;;
  -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
  *) die "argumento desconhecido: $1 (não existe flag que pule a confirmação)" ;;
esac; done

case "${SIDE}" in core|member) ;; *) die "--side core|member obrigatório" ;; esac
case "${DRAFT}" in ''|*[!A-Za-z0-9._-]*|.*) die "--draft <id> obrigatório, na forma [A-Za-z0-9._-]" ;; esac
case "${EXP_OFF}" in ''|*[!0-9]*) die "--exp-offset inteiro positivo" ;; esac
for t in jq openssl python3; do command -v "$t" >/dev/null 2>&1 || die "ferramenta ausente: $t"; done
# LOMBADA, não portão (passada adversarial de 2026-10-27): o Bash de uma sessão do Claude Code exporta CLAUDECODE.
# Quem roda no mesmo usuário e abre um pty (script -qec) contorna o /dev/tty; esta recusa só torna o contorno um ato
# deliberado e visível. O limite real (pty prova terminal, não humano) está declarado no PRE-REGISTRO.md, Emenda 1.
[ -z "${CLAUDECODE:-}" ] && [ -z "${CLAUDE_CODE_ENTRYPOINT:-}" ] \
  || refuse "rodando dentro de uma sessão do Claude Code (CLAUDECODE no ambiente): o envio é do humano, no terminal dele."
[ -f "${SEND}" ] || die "remetente canônico ausente: ${SEND}"

DF="${STATE}/drafts/${DRAFT}.json"
[ -f "${DF}" ] && [ ! -L "${DF}" ] || die "rascunho inexistente: ${DF}"
SENT_TSV="${STATE}/sent.tsv"
if [ -f "${SENT_TSV}" ] && awk -F'\t' -v d="${DRAFT}" '$1==d {f=1} END {exit !f}' "${SENT_TSV}"; then
  die "o rascunho ${DRAFT} já foi enviado (sent.tsv): o mesmo rascunho não sai duas vezes"
fi
jq -e 'type=="object" and (.to|type=="string") and (.text|type=="string") and (.body_sha256|type=="string")' "${DF}" >/dev/null 2>&1 \
  || die "rascunho malformado: ${DF}"
TO="$(jq -r '.to' "${DF}")"
case "${TO}" in ''|*[!A-Za-z0-9._-]*|.*) die "destinatário fora da forma no rascunho: ${TO}" ;; esac
[ -n "${THREAD}" ] || THREAD="$(jq -r '.thread // ""' "${DF}")"
case "${THREAD}" in *[!A-Za-z0-9._-]*) die "thread fora da forma: ${THREAD}" ;; esac

WORK="$(mktemp -d)"; trap 'rm -rf "${WORK}"' EXIT; chmod 700 "${WORK}"
jq -j '.text' "${DF}" > "${WORK}/body"
SHA="$(openssl dgst -sha256 < "${WORK}/body" | awk '{print $NF}')"
[ "${SHA}" = "$(jq -r '.body_sha256' "${DF}")" ] || die "o corpo do rascunho não bate com o sha256 gravado nele (rascunho adulterado?)"
BYTES="$(LC_ALL=C wc -c < "${WORK}/body" | tr -d ' ')"
CODE="${SHA: -6}"

# ── mostrar e pedir confirmação no TERMINAL (não no stdin: um pipe não é humano) ─────────────────────────
# a sonda roda num SUBSHELL: um `exec` com redirecionamento que falha não pode derrubar o script antes da recusa
( exec 3<>/dev/tty ) 2>/dev/null || refuse "sem terminal (/dev/tty): o envio exige um humano no terminal."
exec 3<>/dev/tty
{
  echo "──────── rascunho ${DRAFT} (lado ${SIDE}) ────────"
  echo "para:   ${TO}"
  echo "thread: ${THREAD:-(nova)}"
  echo "bytes:  ${BYTES} · sha256 ${SHA}"
  echo "──────── corpo ────────"
  # na TELA (o corpo assinado não muda), todo caractere de controle, de formato ou separador de linha vira '?',
  # por CODEPOINT: C0, C1 (o CSI de 8 bits), bidi (U+202E), largura zero, U+2028. Um texto do modelo não pode
  # apagar linha, mover o cursor, inverter a leitura nem desenhar um rascunho falso por cima do verdadeiro.
  python3 -I -c 'import sys, unicodedata as u
t = open(sys.argv[1], encoding="utf-8").read()
c = "".join(ch if ch in "\n\t" or u.category(ch) not in ("Cc", "Cf", "Co", "Cs", "Zl", "Zp") else "?" for ch in t)
ls = c.split("\n")
print("\n".join("  │ " + x for x in ls))
print(f"  └── fim do corpo: {len(ls)} linha(s)")' "${WORK}/body"
  echo "────────────────────────"
  printf 'Para ASSINAR e ENVIAR, digite exatamente:  ENVIAR %s\n> ' "${CODE}"
} >&3
ANS=""; IFS= read -r ANS <&3 || true
exec 3>&-
[ "${ANS}" = "ENVIAR ${CODE}" ] || refuse "a confirmação digitada não confere."

record_sent() {  # $1 = jti
  ( umask 077; printf '%s\t%s\t%s\t%s\t%s\n' "${DRAFT}" "$1" "${THREAD}" "$(date +%s)" "${SIDE}" >> "${SENT_TSV}" )
  ( umask 077; mkdir -p "${STATE}/drafts/sent" ); mv -f "${DF}" "${STATE}/drafts/sent/${DRAFT}.json"
}
TARGS=(); [ -z "${THREAD}" ] || TARGS=(--thread "${THREAD}")

if [ "${SIDE}" = core ]; then
  [ -n "${FROM}" ] || FROM="onion-evolve"; [ -n "${KID}" ] || KID="onion-evolve-spike-1"
  KARGS=(); [ -z "${KEY}" ] || KARGS=(--key "${KEY}")
  # o a2a-send monta e assina SEM rede (--dry-run) e grava o envelope 0600 (--out); daqui ele vai ao outbox.
  # O stderr dessa etapa INTERNA fica num arquivo: a linha "(dry-run: …)" dela é sobre a montagem, não sobre este
  # envio, e impressa aqui contradizia o "gravado no outbox" logo abaixo (achado e, 2026-10-28). Só a saída muda:
  # se a montagem falhar, o stderr inteiro aparece.
  bash "${SEND}" --from "${FROM}" --to "${TO}" --kid "${KID}" "${KARGS[@]}" --kind question \
    --exp-offset "${EXP_OFF}" "${TARGS[@]}" --body-file "${WORK}/body" --dry-run --out "${WORK}/env.json" >/dev/null 2> "${WORK}/build.err" \
    || { cat "${WORK}/build.err" >&2; die "o a2a-send.sh não montou o envelope"; }
  grep -v '^(dry-run: ' "${WORK}/build.err" >&2 || true
  JTI="$(jq -r '.jws' "${WORK}/env.json" | cut -d. -f2 | tr '_-' '/+' | { s="$(cat)"; case $(( ${#s} % 4 )) in 2) s="${s}==";; 3) s="${s}=";; esac; printf '%s' "$s"; } | openssl base64 -d -A | jq -r '.jti')"
  TH="$(jq -r '.signal.thread' "${WORK}/env.json")"
  ( umask 077; mkdir -p "${OUTBOX}" )
  MS="$(python3 -c 'import time;print(int(time.time()*1000))' 2>/dev/null || echo "$(( $(date +%s) * 1000 ))")"
  ( umask 077; cp "${WORK}/env.json" "${OUTBOX}/${MS}-question-${JTI}.json" )
  THREAD="${TH}"; record_sent "${JTI}"
  echo "gravado no outbox: ${OUTBOX}/${MS}-question-${JTI}.json · kid ${KID} · aud ${TO} · jti ${JTI} · thread ${TH} · iat ${MS%???}"
  exit 0
fi

# member: o a2a-send.sh envia (bearer só por arquivo 0600; ele recusa segredo legível por outros)
[ -n "${FROM}" ] || die "--from <seu id> obrigatório no lado member"
[ -n "${ENDPOINT}" ] || die "--endpoint obrigatório no lado member (sem default: nada sai por acidente)"
KARGS=(); [ -z "${KID}" ] || KARGS+=(--kid "${KID}"); [ -z "${KEY}" ] || KARGS+=(--key "${KEY}")
[ -z "${TOKEN_FILE}" ] || KARGS+=(--token-file "${TOKEN_FILE}")
rc=0
bash "${SEND}" --from "${FROM}" --to "${TO}" --endpoint "${ENDPOINT}" "${KARGS[@]}" "${TARGS[@]}" \
  --body-file "${WORK}/body" --out "${WORK}/env.json" 2> "${WORK}/send.err" || rc=$?
cat "${WORK}/send.err" >&2
JTI="$(sed -n 's/.*http=[0-9]* jti=\([A-Za-z0-9._-]*\) .*/\1/p' "${WORK}/send.err" | tail -n1)"
if [ "${rc}" -eq 0 ]; then record_sent "${JTI:-?}"; exit 0; fi
[ "${rc}" -eq 1 ] && exit 1
exit 2
