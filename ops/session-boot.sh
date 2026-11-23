#!/usr/bin/env bash
# ===========================================================================
# session-boot.sh — reabre as sessões donas depois de um reboot, pelo systemd do USUÁRIO (core-only).
#
# Uso:
#   bash ops/session-boot.sh plan       mostra a unidade que seria instalada e onde (não escreve nada)
#   bash ops/session-boot.sh install    grava ~/.config/systemd/user/onion-sessions.service e a habilita no boot
#   bash ops/session-boot.sh status     diz se está instalada, habilitada, e se o linger do usuário está ligado
#   bash ops/session-boot.sh remove     desabilita e apaga a unidade
#
# Por quê (2026-11-22): o servidor tmux caiu e levou as cinco sessões de uma vez, e ninguém as reabriu. A 1ª cura é
# um servidor por sessão (ops/session-open.sh, `tmux -L <nome>`). Esta é a 2ª: no boot, o systemd do usuário roda
# `ops/session-open.sh --all`, que reabre cada sessão dona do registro de posse pelo id exato e nunca duplica.
#
# O que NÃO faz, por desenho:
#   · não reabre a cada queda (timer): uma sessão que o maestro fechou com /exit ficaria morta-viva. Fora do boot,
#     a reabertura é da batuta ou do maestro (`session-open.sh --all`), que sabem se o fechamento foi de propósito;
#   · não abre o core: o `--all` deixa o core fora (ele é quem roda o abridor); abre-se à mão;
#   · não liga o linger (`loginctl enable-linger`): sem ele a unidade só sobe quando o usuário entra. O `status` diz;
#   · não lê segredo nem mexe em serviço do sistema: só a unidade do próprio usuário.
#
# Saída: 0 ok · 2 uso · 4 systemctl ausente ou falhou.
# ===========================================================================
set -uo pipefail

UNIT_NAME="onion-sessions.service"
UNIT_DIR="${SESSION_BOOT_UNIT_DIR:-${HOME}/.config/systemd/user}"
SYSTEMCTL="${SESSION_BOOT_SYSTEMCTL:-systemctl}"
OPENER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-open.sh"

die() { printf 'session-boot: %s\n' "$1" >&2; exit "${2:-2}"; }

unit_text() {
  cat <<EOF
[Unit]
Description=Onion: reabre as sessões donas no tmux, uma por servidor, pelo id exato (ops/session-open.sh --all)
After=default.target

[Service]
Type=oneshot
RemainAfterExit=yes
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/bin/bash ${OPENER} --all

[Install]
WantedBy=default.target
EOF
}

[ -f "${OPENER}" ] || die "abridor ausente (${OPENER})"
case "${1:-}" in
  plan)
    printf 'session-boot: ensaio — gravaria %s/%s com:\n\n' "${UNIT_DIR}" "${UNIT_NAME}"
    unit_text
    printf '\nsession-boot: e habilitaria no boot (%s --user enable %s). Nada foi escrito.\n' "${SYSTEMCTL}" "${UNIT_NAME}" ;;
  install)
    command -v "${SYSTEMCTL}" >/dev/null 2>&1 || die "systemctl ausente" 4
    mkdir -p "${UNIT_DIR}" || die "não criei ${UNIT_DIR}" 4
    unit_text > "${UNIT_DIR}/${UNIT_NAME}" || die "não gravei a unidade" 4
    "${SYSTEMCTL}" --user daemon-reload || die "daemon-reload falhou" 4
    "${SYSTEMCTL}" --user enable "${UNIT_NAME}" || die "enable falhou" 4
    printf 'session-boot: instalada e habilitada (%s/%s). Ela roda no próximo boot; agora não roda nada.\n' "${UNIT_DIR}" "${UNIT_NAME}" ;;
  status)
    if [ -f "${UNIT_DIR}/${UNIT_NAME}" ]; then printf 'unidade: instalada (%s/%s)\n' "${UNIT_DIR}" "${UNIT_NAME}"; else printf 'unidade: ausente\n'; fi
    printf 'habilitada no boot: %s\n' "$("${SYSTEMCTL}" --user is-enabled "${UNIT_NAME}" 2>/dev/null || echo não)"
    printf 'linger do usuário: %s\n' "$(loginctl show-user "$(id -un)" -p Linger --value 2>/dev/null || echo 'NÃO MEDIDO')" ;;
  remove)
    command -v "${SYSTEMCTL}" >/dev/null 2>&1 || die "systemctl ausente" 4
    "${SYSTEMCTL}" --user disable "${UNIT_NAME}" 2>/dev/null || true
    rm -f "${UNIT_DIR}/${UNIT_NAME}"
    "${SYSTEMCTL}" --user daemon-reload || die "daemon-reload falhou" 4
    printf 'session-boot: removida.\n' ;;
  *) die "uso: session-boot.sh plan|install|status|remove" ;;
esac
