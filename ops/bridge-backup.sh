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
# Molde: /home/marcio/onion-logto/backup.sh (mesmo autor, mesma casa, mesma cron).
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
sudo chown "$(id -un)":"$(id -gn)" "$OUT" 2>/dev/null || true

# FAIL-LOUD: backup vazio é pior que backup ausente — dá falsa sensação de proteção.
SIZE=$(stat -c%s "$OUT" 2>/dev/null || echo 0)
if [ "$SIZE" -lt 200 ]; then
  echo "ERRO: dump suspeito (${SIZE}b) — verifique permissões de ${SRC}" >&2
  exit 1
fi

# Retenção: só os DIÁRIOS envelhecem; rotulados (pré-upgrade, pré-flip) ficam.
ls -1t "${DEST}"/bridge-diario-*.tar.gz 2>/dev/null | tail -n +15 | xargs -r rm -f

echo "ok: ${OUT} (${SIZE} bytes)"
