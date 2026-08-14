#!/usr/bin/env bash
# Backup do estado NÃO-VERSIONÁVEL do onion-bridge.
#
# POR QUE EXISTE (medido 2026-08-01, Elenxo wf_798e1172): o código-fonte do bridge
# JÁ está salvo — os 5 .ts de auth em origin/main do core, os outros 6 em
# marciocar/onion-bridge (main == origin/main). Se a VPS morrer, ZERO fonte se perde.
# O que NÃO tem cópia em lugar nenhum é o ESTADO: `data/tokens.json` (identidades
# vivas + fila a2a) e `.env` — gitignorados por desenho, e por isso invisíveis a
# qualquer git. Este é o único risco IRREVERSÍVEL medido no serviço.
#
# Molde: /home/marcio/onion-vps-logto/backup.sh (mesmo autor, mesma casa, mesma cron).
# Diferença declarada: este script vive VERSIONADO em ops/ — o do Logto não vive em
# repo nenhum, o que é a anomalia, não este. (ops/ = código de serviço, fora do
# allow-list do /meta:adopt; ver PR #508.)
#
# Uso     : ./bridge-backup.sh [rótulo]
# Retenção: 14 diários + todos os rotulados (pré-upgrade não se apaga).
# Destino : fora do repo — o dump contém SEGREDO (.env) e jamais pode ser commitado.
set -euo pipefail

SRC=/home/onion/onion-bridge
DEST=/home/marcio/backups/bridge
LABEL="${1:-diario}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${DEST}/bridge-${LABEL}-${STAMP}.tar.gz"

# A origem vive sob /home/onion (não atravessável por outro usuário), então o teste
# TAMBÉM passa por sudo — senão o guard falha por permissão e mente "origem ausente".
# (Rodando como root pela cron, o sudo é no-op.)
sudo test -d "$SRC" || { echo "ERRO: origem ausente ou inacessível: $SRC" >&2; exit 1; }

# 700 no diretório: o conteúdo carrega credencial viva.
mkdir -p "$DEST"; chmod 700 "$DEST"

# `data/` + `.env` — e SÓ isso. Nada de node_modules, nada de fonte (já versionada).
# --ignore-failed-read: um .env ausente não deve derrubar o backup do data/.
sudo tar --ignore-failed-read -czf "$OUT" -C "$SRC" data .env 2>/dev/null || true
# O tar roda por sudo, então o dump nasce de root — o chmod TAMBÉM precisa de sudo,
# senão falha em silêncio e o arquivo com segredo fica legível por todo o host.
sudo chmod 600 "$OUT"
[ "$(id -u)" -eq 0 ] && chown marcio:marcio "$OUT"

# ── cifra em repouso (2026-08-11) ────────────────────────────────────────────────────────────
# ⚠️ ESTE TAR CARREGA O `.env` DO BRIDGE — `ANTHROPIC_API_KEY` e tokens de convite. Ficava EM CLARO
#    em disco: 17 arquivos no destino, um deles em 644. Foi achado pela passada adversarial contra a
#    própria guarda que eu tinha acabado de escrever, cujo escopo não cobria este diretório.
#    Cifra para a mesma chave GPG que é raiz do `pass`, como os outros dois backups da casa.
# ⚠️ `sudo -u marcio` porque como root o `gpg` usa o chaveiro de /root, que é VAZIO — ele cria
#    /root/.gnupg do zero e falha com "No public key" (medido).
_KEYOWNER_HOME=/home/marcio
GPGID="$(cat "${_KEYOWNER_HOME}/.password-store/.gpg-id" 2>/dev/null || true)"
[ -n "${GPGID}" ] || { echo "✗ sem gpg-id do pass — NAO deixo o .env do bridge em claro"; sudo shred -u "$OUT"; exit 1; }
if [ "$(id -u)" -eq 0 ]; then
  sudo -u marcio gpg --batch --yes --trust-model always -r "${GPGID}" -o "${OUT}.gpg" -e "$OUT"
else
  gpg --batch --yes --trust-model always -r "${GPGID}" -o "${OUT}.gpg" -e "$OUT"
fi
[ -s "${OUT}.gpg" ] || { echo "✗ a cifra falhou — apagando o claro e abortando"; sudo shred -u "$OUT"; exit 1; }
# a verificação NÃO pode exigir a chave privada (ela tem passphrase): olha o CONTEÚDO, não o exit
if [ "$(id -u)" -eq 0 ]; then
  _pkts="$(sudo -u marcio gpg --batch --list-packets "${OUT}.gpg" 2>/dev/null || true)"
else
  _pkts="$(gpg --batch --list-packets "${OUT}.gpg" 2>/dev/null || true)"
fi
case "${_pkts}" in
  *"pubkey enc packet"*) : ;;
  *) echo "✗ o .gpg nao parece OpenPGP valido — abortando"; sudo shred -u "$OUT" "${OUT}.gpg"; exit 1 ;;
esac
sudo shred -u "$OUT"
chmod 600 "${OUT}.gpg" 2>/dev/null || sudo chmod 600 "${OUT}.gpg"
OUT="${OUT}.gpg"
sudo chown "$(id -un)":"$(id -gn)" "$OUT" 2>/dev/null || true

# FAIL-LOUD: backup vazio é pior que backup ausente — dá falsa sensação de proteção.
SIZE=$(stat -c%s "$OUT" 2>/dev/null || echo 0)
if [ "$SIZE" -lt 200 ]; then
  echo "ERRO: dump suspeito (${SIZE}b) — verifique permissões de ${SRC}" >&2
  exit 1
fi

# Retenção: só os DIÁRIOS envelhecem; rotulados (pré-upgrade, pré-flip) ficam.
# O padrão SEGUE o formato vivo (.gpg desde 2026-08-11 — a retenção ficou 3 dias
# morrendo em rc=2 DEPOIS do backup pronto: glob sem match vira literal, ls sai 2,
# set -e mata; o cron engolia e o update-bridge.sh pegou no 1º uso do ramo cheio).
# `|| true`: retenção vazia não é falha.
ls -1t "${DEST}"/bridge-diario-*.tar.gz.gpg 2>/dev/null | tail -n +15 | xargs -r rm -f || true

# ⚠️ O SIZE E RECALCULADO AQUI, depois da cifra. Antes ele media o `.tar` em claro — que o `shred`
#    ja tinha destruido — e o relato descrevia um arquivo que nao existe mais. Relato que nomeia o
#    artefato errado e pior que relato ausente: quem le procura o arquivo e nao acha.
SIZE=$(stat -c%s "${OUT}" 2>/dev/null || echo 0)
echo "ok: ${OUT} (${SIZE} bytes)"
