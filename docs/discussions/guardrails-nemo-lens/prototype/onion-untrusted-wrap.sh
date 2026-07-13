#!/usr/bin/env bash
# onion-untrusted-wrap.sh — R15.1 (ONION-R15): cerca de proveniência para conteúdo NÃO-CONFIÁVEL.
#
# PROTÓTIPO isolado (discuss/guardrails-nemo-lens). NÃO é o core — dogfood em quarentena.
#
# Propósito: todo conteúdo externo (federação a2a, doc-bridge inbound, repo adotado) entra no
# contexto de um agente APENAS cercado — nunca cru. A cerca torna as duas confianças visualmente
# distintas: `verified-crypto` (o a2a-verify já provou o envelope) vs `verified-semantic` (o CORPO
# pode ser adversário). É o modo ESTRUTURAL: o conteúdo não *consegue* entrar sem cerca.
#
# Invariante-chave: `verified-semantic` é SEMPRE "false". NÃO há flag para torná-la true — é o
# ponto inteiro de R15 (crypto-verificado ≠ semanticamente confiável). Ver r15-untrusted-content-provenance.md §3.
#
# Defesa de fence-breakout (o que faz a cerca ser confiável, não decorativa):
#   1. NONCE nos marcadores de abertura E fechamento — o corpo não conhece o nonce, logo não
#      consegue forjar `<<<END UNTRUSTED nonce="…">>>`. (pinável via ONION_WRAP_NONCE p/ teste.)
#   2. DEFANG do corpo — qualquer sentinela ASCII `<<<`/`>>>` no corpo vira unicode `‹‹‹`/`›››`,
#      então o corpo literalmente não pode conter um marcador de fence.
#   3. SANITIZE da origin — origin é reduzida a [A-Za-z0-9._/-], não pode injetar atributos/quebra.
#
# Uso : onion-untrusted-wrap.sh --origin <id> --channel <a2a-federation|doc-bridge|adopted-repo> \
#                               [--verified-crypto true|false] [--file <path>]
#       (conteúdo via --file OU stdin)
# Exit: 0 ok · 2 uso inválido.
# Limitação: TEXTO apenas. Bytes NUL no corpo são descartados por bash na substituição de comando
#            (o defang de <<< />>> permanece íntegro; não há fence-breakout, mas o corpo não é byte-exato).

set -uo pipefail

ORIGIN=""; CHANNEL=""; VCRYPTO="false"; FILE=""
# guarda contra flag-sem-valor: `shift 2` com 1 só argumento falha (rc=1) e, sem `set -e`,
# o loop reprocessaria $1 para sempre (loop infinito). Exige o valor ANTES de deslocar.
while [ $# -gt 0 ]; do
  case "$1" in
    --origin)          [ $# -ge 2 ] || { echo "ERRO: --origin requer valor" >&2; exit 2; }; ORIGIN="$2"; shift 2 ;;
    --channel)         [ $# -ge 2 ] || { echo "ERRO: --channel requer valor" >&2; exit 2; }; CHANNEL="$2"; shift 2 ;;
    --verified-crypto) [ $# -ge 2 ] || { echo "ERRO: --verified-crypto requer valor" >&2; exit 2; }; VCRYPTO="$2"; shift 2 ;;
    --file)            [ $# -ge 2 ] || { echo "ERRO: --file requer valor" >&2; exit 2; }; FILE="$2"; shift 2 ;;
    -h|--help)         echo "uso: onion-untrusted-wrap.sh --origin <id> --channel <canal> [--verified-crypto true|false] [--file <path>]"; exit 0 ;;
    *)                 echo "ERRO: argumento desconhecido: $1 (verified-semantic NÃO é setável — é sempre false por design)" >&2; exit 2 ;;
  esac
done

[ -n "$ORIGIN" ]  || { echo "ERRO: --origin obrigatório" >&2; exit 2; }
[ -n "$CHANNEL" ] || { echo "ERRO: --channel obrigatório" >&2; exit 2; }
case "$CHANNEL" in
  a2a-federation|doc-bridge|adopted-repo) ;;
  *) echo "ERRO: --channel inválido: '$CHANNEL' (use a2a-federation|doc-bridge|adopted-repo)" >&2; exit 2 ;;
esac
case "$VCRYPTO" in
  true|false) ;;
  *) echo "ERRO: --verified-crypto deve ser true|false (veio '$VCRYPTO')" >&2; exit 2 ;;
esac

# conteúdo: --file ou stdin
if [ -n "$FILE" ]; then
  [ -f "$FILE" ] || { echo "ERRO: arquivo inexistente: $FILE" >&2; exit 2; }
  BODY="$(cat -- "$FILE")"
else
  BODY="$(cat)"
fi

# (3) sanitize origin — sem injeção de atributo/quebra de marcador
ORIGIN_SAFE="$(printf '%s' "$ORIGIN" | tr -cd 'A-Za-z0-9._/-')"
[ -n "$ORIGIN_SAFE" ] || { echo "ERRO: --origin sem caracteres válidos após sanitização" >&2; exit 2; }

# (1) nonce — pinável p/ teste, senão aleatório
NONCE="${ONION_WRAP_NONCE:-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')}"
# fail-alto: nonce vazio (ex.: /dev/urandom inacessível) degradaria a defesa #1 em silêncio
[ -n "$NONCE" ] || { echo "ERRO: falha ao gerar nonce (defesa anti-fence-breakout indisponível)" >&2; exit 2; }

# (2) defang — o corpo não pode conter sentinela ASCII de fence
SAFE_BODY="$(printf '%s' "$BODY" | sed 's/<<</‹‹‹/g; s/>>>/›››/g')"

# emite a cerca
printf '<<<UNTRUSTED origin="%s" channel="%s" verified-crypto="%s" verified-semantic="false" nonce="%s">>>\n' \
  "$ORIGIN_SAFE" "$CHANNEL" "$VCRYPTO" "$NONCE"
printf '%s\n' "$SAFE_BODY"
printf '<<<END UNTRUSTED nonce="%s">>>\n' "$NONCE"
