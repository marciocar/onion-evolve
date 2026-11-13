#!/usr/bin/env bash
# slack-persona-selftest.sh — a bancada do ops/slack-persona.sh (core-only): o wrapper roda no MODO DE TESTE contra uma
# raiz falsa em /tmp, com systemctl, systemd-creds, systemd-analyze, journalctl e sleep falsos no PATH. Nada passa por
# sudo e nada toca /etc. Prova: o segredo vai do terminal ao systemd-creds pelo stdin e nunca aparece na saída; prefixo
# trocado recusa sem gravar; credencial existente só troca com confirmação; o kg-token sai do conf do MCP dentro do
# root; o install é ensaio por padrão; o start recusa config de exemplo e credencial faltando; o verify espera a conexão
# até o teto; variável de teste fora do modo de teste é rc 3.
# Uso: bash ops/testing/slack-persona-selftest.sh   (rc 0 = verde)
set -uo pipefail
UNIT=onion-slack-persona
me="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/slack-persona.sh"
t="$(mktemp -d /tmp/slack-persona-selftest.XXXXXX)"; trap 'rm -rf "${t}"' EXIT
fails=0; ok=0
chk() { if [ "$2" = 0 ]; then ok=$((ok + 1)); echo "  ✓ $1"; else fails=$((fails + 1)); echo "  ✗ $1"; sed 's/^/      /' "${t}/out" 2>/dev/null | tail -4; fi; }
mkdir -p "${t}/bin" "${t}/root/home/onion/onion-bridge/deploy/slack-persona" "${t}/root/etc"
# falsos: o systemd-creds "cifra" com um marcador e o tamanho (nunca o segredo em claro no arquivo)
cat > "${t}/bin/systemd-creds" <<'F'
#!/usr/bin/env bash
[ "$1" = encrypt ] || exit 9; n="${2#--name=}"; s="$(cat)"; printf 'ENC:%s:%s\n' "$n" "${#s}" > "$4"; printf '%s' "$s" > "$4.plain-for-test"
F
# systemctl falso: ativa só com o marcador ${t}/active; o show responde DynamicUser=yes ou a InvocationID
printf '#!/usr/bin/env bash\necho "systemctl $*" >> "%s/calls"\ncase "$1" in show) case "$*" in *DynamicUser*) echo yes ;; *) echo inv-1 ;; esac ;; is-active) [ -e "%s/active" ] ;; is-failed) exit 1 ;; esac\n' "${t}" "${t}" > "${t}/bin/systemctl"
printf '#!/usr/bin/env bash\nexit 0\n' > "${t}/bin/systemd-analyze"
# journalctl falso: conta as leituras; com ${t}/jdelay = N, a linha de conexão só sai a partir da leitura N+1 (o atraso
# real entre o restart e a conexão)
printf '#!/usr/bin/env bash\nc=$(( $(cat "%s/jcount" 2>/dev/null || echo 0) + 1 )); echo "$c" > "%s/jcount"\nif [ -e "%s/jdelay" ] && [ "$c" -le "$(cat "%s/jdelay")" ]; then exit 0; fi\necho "{\\"msg\\":\\"slack persona connected\\"}"\n' "${t}" "${t}" "${t}" "${t}" > "${t}/bin/journalctl"
printf '#!/usr/bin/env bash\nexit 0\n' > "${t}/bin/sleep"
chmod +x "${t}/bin/"*
S="${t}/root/home/onion/onion-bridge/deploy/slack-persona"
# a unit mínima que cabe na allowlist do install (as diretivas obrigatórias, com os valores fixos)
UNIT_OK='[Service]
DynamicUser=yes
User=onion-slack-persona
WorkingDirectory=/run/onion-slack-persona-app
BindReadOnlyPaths=/home/onion/onion-bridge:/run/onion-slack-persona-app
ExecStart=/usr/bin/node /run/onion-slack-persona-app/node_modules/tsx/dist/cli.mjs src/slack-persona/main.ts
CapabilityBoundingSet=
[Install]
WantedBy=multi-user.target'
printf '%s\n' "${UNIT_OK}" > "${S}/${UNIT}.service"
printf '{"approverUserId":"U0000MAESTRO","allowedChannels":["C0000PILOTO"]}\n' > "${S}/config.example.json"
printf 'ONION_KG_TOKEN=kg-segredo-do-conf\nMCP_PORT=3033\n' > "${t}/root/etc/onion-vps-mcp-kg-granaai.conf"
run() { PATH="${t}/bin:${PATH}" ONION_SLACK_PERSONA_TEST=1 ONION_SLACK_PERSONA_ROOT="${t}/root" ONION_SLACK_PERSONA_TTY="${t}/tty" bash "${me}" "$@" > "${t}/out" 2>&1; }
CS="${t}/root/etc/credstore.encrypted"

printf 'xoxb-bot-secreto\n' > "${t}/tty"; run creds slack-bot-token; chk "creds: guarda o bot token" $?
grep -q '^ENC:slack-bot-token:16$' "${CS}/${UNIT}.slack-bot-token" 2>/dev/null; chk "creds: o arquivo é o cifrado, com o nome da credencial" $?
[ "$(cat "${CS}/${UNIT}.slack-bot-token.new.plain-for-test" 2>/dev/null)" = xoxb-bot-secreto ]; chk "creds: o segredo chegou ao systemd-creds pelo stdin, inteiro" $?
! grep -q 'bot-secreto' "${t}/out"; chk "creds: o segredo não aparece na saída" $?
printf 'xapp-no-lugar-errado\n' > "${t}/tty"; run creds slack-bot-token-x; [ $? = 3 ]; chk "creds: nome desconhecido é uso inválido" $?
printf 'xapp-trocado\n' > "${t}/tty"; run creds anthropic-api-key; [ $? = 1 ] && [ ! -e "${CS}/${UNIT}.anthropic-api-key" ]; chk "creds: prefixo errado recusa e não grava" $?
printf 'n\n' > "${t}/tty"; run creds slack-bot-token; rc=$?
[ "${rc}" = 0 ] && grep -q 'mantida' "${t}/out" && grep -q '^ENC:slack-bot-token:16$' "${CS}/${UNIT}.slack-bot-token"; chk "creds: existente sem confirmação fica, sem pedir o segredo" $?
mv "${t}/root/etc/onion-vps-mcp-kg-granaai.conf" "${t}/conf.bak"; printf 'MCP_PORT=3033\n' > "${t}/root/etc/onion-vps-mcp-kg-granaai.conf"
run creds --kg-from-mcp-conf kg-token; [ $? = 1 ] && [ ! -e "${CS}/${UNIT}.kg-token" ]; chk "creds: conf do MCP sem o token recusa e não grava" $?
mv "${t}/conf.bak" "${t}/root/etc/onion-vps-mcp-kg-granaai.conf"
run creds --kg-from-mcp-conf kg-token; chk "creds: kg-token do conf do MCP" $?
[ "$(cat "${CS}/${UNIT}.kg-token.new.plain-for-test" 2>/dev/null)" = kg-segredo-do-conf ] && ! grep -q 'kg-segredo' "${t}/out"; chk "creds: o kg-token do conf, inteiro e fora da saída" $?

PATH="${t}/bin:${PATH}" ONION_SLACK_PERSONA_TEST=1 ONION_SLACK_PERSONA_ROOT="${t}/root" ONION_SLACK_PERSONA_TTY="${t}/sem-tty" bash "${me}" creds slack-app-token > "${t}/out" 2>&1
[ $? = 2 ] && grep -q 'sem terminal' "${t}/out" && [ ! -e "${CS}/${UNIT}.slack-app-token" ]; chk "creds: sem terminal recusa antes de gravar" $?
# a unit servida trocada por SYMLINK (2026-11-13): o root copiaria o alvo do link; o install recusa, ensaio ou não
mv "${S}/${UNIT}.service" "${t}/unit.real"; printf 'segredo-do-root\n' > "${t}/alvo"; ln -s "${t}/alvo" "${S}/${UNIT}.service"
run install --apply; [ $? = 1 ] && grep -q 'symlink' "${t}/out" && [ ! -e "${t}/root/etc/systemd/system/${UNIT}.service" ]; chk "install: unit servida que é symlink recusa e não escreve" $?
rm "${S}/${UNIT}.service"; mv "${t}/unit.real" "${S}/${UNIT}.service"
# B5 do refutador do #1647: quem escreve a unit no bridge servido não escolhe o usuário nem o que roda como root
printf '%s\n' "${UNIT_OK}" | sed 's/^User=.*/User=root/' > "${S}/${UNIT}.service"
run install --apply; [ $? = 1 ] && grep -q 'allowlist' "${t}/out" && [ ! -e "${t}/root/etc/systemd/system/${UNIT}.service" ]; chk "install: unit servida com User=root recusa e não escreve" $?
printf '%s\n' "${UNIT_OK}" | sed 's#^\[Install\]#ExecStartPre=+/bin/sh -c id\n[Install]#' > "${S}/${UNIT}.service"
run install --apply; [ $? = 1 ] && grep -q 'ExecStartPre' "${t}/out" && [ ! -e "${t}/root/etc/systemd/system/${UNIT}.service" ]; chk "install: unit servida com ExecStartPre=+ (roda como root) recusa e não escreve" $?
printf '%s\n' "${UNIT_OK}" | grep -v '^DynamicUser' > "${S}/${UNIT}.service"
run install --apply; [ $? = 1 ] && grep -q 'falta DynamicUser' "${t}/out" && [ ! -e "${t}/root/etc/systemd/system/${UNIT}.service" ]; chk "install: unit servida sem DynamicUser=yes recusa e não escreve" $?
# N3 da re-refutação do #1647: o systemd parte linha em \r; um Description com "\r[Service]\rExecStartPre=+…" virava
# três linhas lá e uma só na allowlist (root). Recusa, e o MUTANTE (a allowlist de antes: sem a recusa de controle,
# partindo só em \n e com o Description livre) aceitaria
CR_UNIT="$(printf '[Unit]\nDescription=x\r[Service]\rExecStartPre=+/bin/true\r[Unit]\n%s' "${UNIT_OK}")"
printf '%s\n' "${CR_UNIT}" > "${S}/${UNIT}.service"
run install --apply; [ $? = 1 ] && grep -q 'caractere de controle' "${t}/out" && [ ! -e "${t}/root/etc/systemd/system/${UNIT}.service" ]; chk "install: Description com \\r que o systemd partiria em diretivas (ExecStartPre=+) recusa e não escreve" $?
python3 -I - "${me}" "${t}/mut.sh" <<'PYM'
import sys
s = open(sys.argv[1]).read()
for a, b in (("if ctl:", "if False:"), (r're.split(r"[\r\n]", txt)', r'txt.split("\n")'),
             (r'r"[ -Z\]-~]{1,200}"', r'r"[^\n]{1,200}"')):
    assert s.count(a) == 1, a
    s = s.replace(a, b)
open(sys.argv[2], "w").write(s)
PYM
PATH="${t}/bin:${PATH}" ONION_SLACK_PERSONA_TEST=1 ONION_SLACK_PERSONA_ROOT="${t}/root" ONION_SLACK_PERSONA_TTY="${t}/tty" bash "${t}/mut.sh" install > "${t}/out" 2>&1
[ $? = 0 ] && ! grep -q 'allowlist' "${t}/out"; chk "install: o MUTANTE (a allowlist de antes) aceitaria a unit com \\r — a recusa é a causa" $?
printf '%s\n' "${UNIT_OK}" > "${S}/${UNIT}.service"
run install; chk "install: ensaio sai 0" $?
[ ! -e "${t}/root/etc/systemd/system/${UNIT}.service" ]; chk "install: ensaio não escreve" $?
run install --apply; chk "install --apply" $?
cmp -s "${S}/${UNIT}.service" "${t}/root/etc/systemd/system/${UNIT}.service"; chk "install --apply: a unit instalada é a servida" $?
grep -q 'U0000' "${t}/root/etc/onion-slack-persona/config.json"; chk "install --apply: config de exemplo no lugar" $?

printf 'xapp-app\n' > "${t}/tty"; run creds slack-app-token
printf 'sk-ant-chave\n' > "${t}/tty"; run creds anthropic-api-key
run start; [ $? = 1 ] && grep -q 'IDs de exemplo' "${t}/out"; chk "start: recusa a config de exemplo" $?
! grep -q 'restart' "${t}/calls" 2>/dev/null; chk "start: recusado não religou nada" $?
printf '{"approverUserId":"UMARCIO01","allowedChannels":["CPILOTO01"]}\n' > "${t}/root/etc/onion-slack-persona/config.json"
run start; chk "start: com tudo no lugar, liga e vê a conexão" $?
grep -q "systemctl restart ${UNIT}" "${t}/calls"; chk "start: religou a unit" $?
# verify logo após o restart (medido em 2026-11-07): a conexão que sai depois de algumas leituras passa; a que não sai
# até o teto reprova, depois de ler o teto inteiro, e a falha diz o teto
touch "${t}/active"; echo 5 > "${t}/jdelay"; rm -f "${t}/jcount"
run verify; rc=$?; [ "${rc}" = 0 ] && grep -q '✓ ativa e conectada' "${t}/out" && [ "$(cat "${t}/jcount")" = 6 ]; chk "verify: conexão que aparece depois de 5 leituras passa" $?
echo 999 > "${t}/jdelay"; rm -f "${t}/jcount"
run verify; rc=$?; [ "${rc}" = 1 ] && grep -q 'sem a linha de conexão desta invocação em 45 s' "${t}/out" && [ "$(cat "${t}/jcount")" -ge 45 ]; chk "verify: conexão ausente até o teto reprova e diz o teto" $?
rm -f "${t}/active" "${t}/jdelay" "${t}/jcount"
B="${t}/root/home/onion/onion-bridge"; mkdir -p "${B}/src/slack-persona"; printf 'x\n' > "${B}/src/slack-persona/main.ts"; chmod 0600 "${B}/src/slack-persona/main.ts"
run start; [ $? = 1 ] && grep -q 'sem leitura para outros' "${t}/out"; chk "start: recusa código que o UID dinâmico não lê" $?
chmod 0644 "${B}/src/slack-persona/main.ts"
rm -f "${CS}/${UNIT}.kg-token"; run start; [ $? = 1 ] && grep -q 'kg-token' "${t}/out"; chk "start: recusa sem uma credencial" $?

ONION_SLACK_PERSONA_ROOT=/tmp/x bash "${me}" verify > "${t}/out" 2>&1; [ $? = 3 ]; chk "variável de teste sem o modo de teste: rc 3" $?

echo; echo "selftest: ${ok} ok · ${fails} falha(s)"; [ "${fails}" = 0 ]
