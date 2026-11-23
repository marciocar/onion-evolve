#!/usr/bin/env bash
# egress-uid-fence.sh — cerca de SAÍDA por uid na frente do Gokapi (onion-vps-gokapi): só a conta do Caddy e a do
# túnel SSH do maestro abrem conexão para 127.0.0.1:3050, e só o root (o docker-proxy) abre para a porta interna
# do container (53842). As demais contas locais da VPS levam RST.
#
# POR QUE EXISTE (pedido da vps-ops, ato tools/acts/gokapi-spike.sh e o resíduo feat-act-gokapi-spike, achado M1, 2026-11-21):
#   o Gokapi v2.2.4 não se configura só por variável: o 1º start sem config.json abre o assistente /setup, SEM
#   autenticação. O vhost devolve 404 em /setup e o container só escuta no loopback, mas QUALQUER conta local da
#   VPS alcança 127.0.0.1:3050 e pode tomar a configuração (apontar o OIDC para um provedor dela) antes do maestro.
#   A vps-ops mitigou por ordem de passos (up e setup em seguida) e deixou o fechamento de fato ao core, dono do
#   firewall: uma regra de saída por uid.
#
# O QUE O CORE MEDIU A MAIS (2026-11-22, nesta máquina) e por que a cerca tem DUAS portas, não uma:
#   · o host alcança o IP do container direto: `curl http://172.22.0.2:80/alive` como conta comum devolveu 200 no
#     vaultwarden. Fechar só 127.0.0.1:3050 deixaria o /setup aberto em <ip-do-container>:53842. Por isso a 2ª
#     porta: a interna do Gokapi (53842, fixa, o healthcheck da imagem depende dela), e ali só o root passa;
#   · o loopback publicado é servido pelo docker-proxy (userland-proxy ligado; o nat OUTPUT do Docker exclui
#     127.0.0.0/8), que roda como root e abre a conexão para o container: é por isso que o root passa na 53842;
#   · as regras casam o DESTINO ORIGINAL da conexão (conntrack --ctorigdst/--ctorigdstport), não o destino do
#     pacote: se um dia o userland-proxy for desligado e o Docker passar a fazer DNAT no loopback, a cerca segue
#     valendo (o filtro do OUTPUT vê o pacote já traduzido, o conntrack guarda o original);
#   · o salto fica na 1ª posição do OUTPUT, ANTES do ufw-before-output, que aceita todo o tráfego de `lo`;
#   · o ufw (MANAGE_BUILTINS=no, medido) re-anexa os saltos dele com -A e não esvazia o OUTPUT, então um
#     `ufw reload` não derruba a cerca. Um `iptables -F OUTPUT` derruba: o `verify` acusa, e o `up` repõe.
#   · IPv6 fica de fora de propósito: o compose publica só 127.0.0.1, e o verify reprova qualquer escuta na porta
#     que não seja 127.0.0.1:3050 (inclusive [::1], [::] e IP externo).
#
# A REDE DOS CONTAINERS (2026-11-23, medição da vps-ops, só leitura): da conta comum, quase todas as portas de
#   container abriam pelo IP do container (bancos, busca, o cofre de senhas), e quem precisa abrir conexão para lá
#   é só o docker-proxy (root): nenhum vhost aponta para IP de container. Por isso uma 3ª parte na mesma chain:
#   conexão NOVA cujo destino ORIGINAL está em 172.16.0.0/12 (as redes do Docker), que NÃO sofreu DNAT
#   (! --ctstate DNAT: a porta publicada que o Docker traduz no nat OUTPUT para o container fica fora, porque o
#   destino original dela é do host) e cujo destino não é endereço do host (addrtype ! LOCAL: o gateway da bridge e
#   os serviços do host que escutam nele ficam fora). O root passa (RETURN), e com ele QUALQUER processo uid 0, não
#   só o docker-proxy: a liberação é por conta. As demais contas dependem do MODO (--docker-mode, gravado na unit):
#     · log (padrão do 1º install): não barra, só registra no kernel quem SERIA barrado (prefixo onion-fence-docker:,
#       com o uid), com limite POR DESTINO (hashlimit por IP e porta, 6 por minuto cada): um cliente barulhento num
#       container não cala o registro de outro destino. O contador da regra (`iptables -L ONION-EGRESS-FENCE -v`)
#       é a prova de volume, à parte do log. Uma semana de ensaio antes de barrar: quem aparecer é quem precisa de
#       liberação;
#     · reject: as demais contas levam RST. Só depois do ensaio, por decisão do maestro;
#     · off: sem a 3ª parte (só o Gokapi, como era).
#   Só TCP, como o resto da cerca (o salto do OUTPUT é -p tcp): UDP para container segue sem cerca, declarado.
#   Não cobre porta publicada acessada pelo loopback ou pelo IP público (o destino original fica fora da faixa):
#   essas passam pelo docker-proxy, que é root. E a faixa tem de conter TODA rede do Docker: o pool padrão manda a
#   rede nova para 192.168.0.0/16 quando a 172.16/12 enche (hoje quase cheia), e ela ficaria fora sem aviso; por
#   isso o `verify` confere cada rota de bridge (docker*, br-*) contra a faixa e reprova a que estiver fora.
#
# O QUE A CERCA NÃO FAZ (teto declarado):
#   · não barra as contas que passam: o túnel é da conta do maestro, e qualquer processo dessa conta (inclusive as
#     sessões de agente que rodam com ela) alcança o /setup. Fechar isso pediria conta dedicada ao túnel;
#   · não barra o root, que manda no firewall. Na porta interna o root PASSA (é o docker-proxy), e com ele qualquer
#     processo uid 0, inclusive um container `--network host` como root: quem está no grupo docker chega lá;
#   · não vê tráfego que não sai do host (container para container na mesma rede do compose: o Gokapi está só);
#   · a regra da porta interna não tem destino (as redes do Docker mudam de faixa): conta comum leva RST em qualquer
#     TCP para a porta 53842 de qualquer host. O efeito colateral foi aceito por ser uma porta sem outro uso aqui;
#   · NÃO falha fechada no boot: se o `up` falhar, o Docker sobe mesmo assim (amarrar o Docker à cerca derrubaria
#     todos os containers por causa de um). O `verify` acusa; o `status` do Gokapi deve vir depois dele;
#   · `systemctl restart` da unit roda o down antes do up e abre uma janela: para repor, use `systemctl reload`
#     (ExecReload = up, sem janela) ou o `up` direto;
#   · o veto do MOAT barra este script (install/undo com --apply, up, down) e a unit, mas NÃO a cópia de root em
#     /usr/local/sbin nem o iptables cru pelo sudo (medido pelo refutador em 2026-11-22): o firewall vivo segue sendo
#     do maestro por disciplina, não por catraca.
#
# Uso (o maestro roda os atos pelo `!`; SEM --apply é ensaio):
#   ops/egress-uid-fence.sh plan [--tunnel-user U] [--docker-mode log|reject|off]  # ENSAIO (padrão)
#   ops/egress-uid-fence.sh install --apply [--tunnel-user U] [--docker-mode M]    # cópia de root, unit, liga e verifica
#   ops/egress-uid-fence.sh undo --apply                      # o DESFAZER: desliga a unit, tira as regras, apaga unit e cópia
#   ops/egress-uid-fence.sh verify                            # leitura + sonda: regras no lugar e o RST para quem não passa
#   ops/egress-uid-fence.sh up | down                         # o que a unit chama (root); idempotentes
#   ops/egress-uid-fence.sh --selftest                        # bancada em sandbox com iptables de mentira
set -euo pipefail
set -f
export LC_ALL=C

CHAIN="ONION-EGRESS-FENCE"
HOST_ADDR="127.0.0.1"
HOST_PORT=3050          # o loopback publicado do Gokapi (docker-compose.yml do onion-vps-gokapi)
CTR_PORT=53842          # a porta interna do Gokapi no container (fixa na imagem)
CTR_ALLOW="root"        # quem abre conexão para a porta interna: o docker-proxy
DOCKER_NET="172.16.0.0/12"   # as redes do Docker (bridge e redes do compose)
DOCKER_ALLOW="root"          # quem abre conexão para IP de container: o docker-proxy
UNIT_NAME="onion-vps-egress-fence"
UNIT_DEST="/etc/systemd/system/${UNIT_NAME}.service"
SBIN_DEST="/usr/local/sbin/${UNIT_NAME}.sh"
BACKUP_DIR="/var/backups/onion-egress-fence"
SUDO_CMD="sudo -n"
IPT="iptables"
IPT_RESTORE="iptables-restore"
SYSTEMCTL="systemctl"
PROBE=1                 # o selftest desliga a sonda (não há rede de verdade no sandbox)
[[ "$(id -u)" == 0 ]] && SUDO_CMD=""   # a unit roda como root: sem sudo

die() { echo "✗ RESULTADO: $*" >&2; exit 2; }
usage() { sed -n 's/^# \?//p' "${BASH_SOURCE[0]}" | sed -n '/^Uso/,/^$/p'; }

# Quem passa no loopback: a conta do Caddy (o proxy do vhost) e a do túnel SSH do maestro. A do túnel vem de
# --tunnel-user, da unit (FENCE_TUNNEL_USER) ou de quem invoca (SUDO_USER, depois o usuário corrente).
tunnel_user() { echo "${FENCE_TUNNEL_USER:-${SUDO_USER:-$(id -un)}}"; }
host_allow() { echo "caddy $(tunnel_user)"; }
# O modo da rede dos containers: --docker-mode, a unit (FENCE_DOCKER_MODE) ou o padrão log (ensaio sem barrar).
docker_mode() {
  # sem --docker-mode nem ambiente, vale o modo GRAVADO na unit instalada (um verify ou reinstall pelo shell não
  # pode voltar ao log em silêncio depois de um install em reject); sem unit, o padrão log
  local m="${FENCE_DOCKER_MODE:-}"
  [[ -n "$m" ]] || m="$(sed -n 's/^Environment=FENCE_DOCKER_MODE=//p' "$UNIT_DEST" 2>/dev/null | head -n1)"
  m="${m:-log}"
  case "$m" in log|reject|off) echo "$m" ;; *) echo "modo inválido para a rede dos containers: «$m» (log, reject ou off)" >&2; return 1 ;; esac
}

uid_of() {  # uid de uma conta; vazio se não existe
  id -u "$1" 2>/dev/null || true
}

# As regras da chain, uma especificação por linha (sem o `-A CHAIN`). Cada uma leva um comentário curto do iptables
# (sem espaço, para a forma ser a mesma no restore e no -C) e o porquê fica no comentário do shell ao lado.
# Falha (rc 1) se alguma conta não resolve: a cerca não sobe pela metade.
fence_rules() {
  local u uid
  for u in $(host_allow); do
    uid="$(uid_of "$u")"; [[ -n "$uid" ]] || { echo "conta «$u» não existe" >&2; return 1; }
    # loopback do Gokapi: esta conta PASSA (RETURN devolve ao OUTPUT, que segue para o ufw)
    echo "-p tcp -m conntrack --ctorigdst $HOST_ADDR --ctorigdstport $HOST_PORT -m owner --uid-owner $uid -m comment --comment gokapi-loopback-allow-$u -j RETURN"
  done
  # loopback do Gokapi: qualquer outra conta leva RST (o /setup sem autenticação não fica ao alcance dela)
  echo "-p tcp -m conntrack --ctorigdst $HOST_ADDR --ctorigdstport $HOST_PORT -m comment --comment gokapi-loopback-deny-others -j REJECT --reject-with tcp-reset"
  for u in $CTR_ALLOW; do
    uid="$(uid_of "$u")"; [[ -n "$uid" ]] || { echo "conta «$u» não existe" >&2; return 1; }
    # porta interna do container: só o docker-proxy (root) abre conexão até ela
    echo "-p tcp -m conntrack --ctorigdstport $CTR_PORT -m owner --uid-owner $uid -m comment --comment gokapi-ctr-allow-$u -j RETURN"
  done
  # porta interna do container: as demais contas, que chegariam pelo IP do container sem passar pelo 3050, levam RST
  echo "-p tcp -m conntrack --ctorigdstport $CTR_PORT -m comment --comment gokapi-ctr-deny-others -j REJECT --reject-with tcp-reset"
  # a rede dos containers: destino original em $DOCKER_NET que não é endereço do host
  local mode match="-p tcp -m conntrack --ctorigdst $DOCKER_NET ! --ctstate DNAT -m addrtype ! --dst-type LOCAL"
  mode="$(docker_mode)" || return 1
  [[ "$mode" == off ]] && return 0
  for u in $DOCKER_ALLOW; do
    uid="$(uid_of "$u")"; [[ -n "$uid" ]] || { echo "conta «$u» não existe" >&2; return 1; }
    # o docker-proxy (root) passa: é ele que entrega o loopback publicado ao container
    echo "$match -m owner --uid-owner $uid -m comment --comment docker-net-allow-$u -j RETURN"
  done
  if [[ "$mode" == log ]]; then
    # ensaio: só registra quem SERIA barrado, com o uid, no máximo 6 por minuto POR DESTINO; a conexão segue
    echo "$match -m hashlimit --hashlimit-upto 6/min --hashlimit-burst 6 --hashlimit-mode dstip,dstport --hashlimit-name onion-fence-docker -m comment --comment docker-net-log-others -j LOG --log-prefix onion-fence-docker: --log-uid"
  else
    # barrando: as demais contas levam RST
    echo "$match -m comment --comment docker-net-deny-others -j REJECT --reject-with tcp-reset"
  fi
}

# O salto: só conexão NOVA entra na chain (a resposta de uma já aceita não é reavaliada).
JUMP="-p tcp -m conntrack --ctstate NEW -m comment --comment onion-egress-fence -j $CHAIN"

chain_exists() { $SUDO_CMD $IPT -w -S "$CHAIN" >/dev/null 2>&1; }
# Antes de concluir "sem chain" ou "sem salto": a listagem do OUTPUT tem de funcionar. Sem isso, um sudo sem
# credencial ou um xtables travado dariam o mesmo vazio que "nada instalado" (refutador, 2026-11-22).
need_fw() {
  if [[ -n "$SUDO_CMD" ]]; then sudo -n true 2>/dev/null || die "sudo sem senha falhou; nada mudou"; fi
  $SUDO_CMD $IPT -w -S OUTPUT >/dev/null 2>&1 || die "não consegui ler o OUTPUT do iptables; nada mudou"
}
# Números (no OUTPUT, 1 = 1ª regra) das regras que saltam para a chain. Pelo ALVO, não pelo texto do -S: a forma
# canônica que o iptables imprime pode diferir da que se escreveu, e casar texto deixaria cópia sem apagar.
jump_lines() {
  $SUDO_CMD $IPT -w -L OUTPUT -n --line-numbers | awk -v c="$CHAIN" '$2==c {print $1}'
}
jump_is_first() {  # a 1ª regra do OUTPUT salta para a chain, e com a especificação esperada
  [[ "$(jump_lines | head -n1)" == 1 ]] && $SUDO_CMD $IPT -w -C OUTPUT $JUMP 2>/dev/null
}

# up: monta a chain de uma vez (iptables-restore --noflush: declarar a chain a esvazia e o conjunto entra numa
# transação só, sem janela com a chain vazia) e garante o salto na 1ª posição do OUTPUT.
up() {
  local rules spec first others n
  need_fw
  rules="$(fence_rules)" || die "conta da lista não resolve; nada mudou"
  { echo "*filter"; echo ":$CHAIN - [0:0]"
    while IFS= read -r spec; do echo "-A $CHAIN $spec"; done <<< "$rules"
    echo "COMMIT"; } | $SUDO_CMD $IPT_RESTORE -w 5 --noflush || die "iptables-restore recusou a chain; o salto não foi tocado"
  if ! jump_is_first; then
    # entra na 1ª posição ANTES de tirar as cópias de baixo: nunca há instante sem salto
    $SUDO_CMD $IPT -w -I OUTPUT 1 $JUMP || die "não consegui pôr o salto no topo do OUTPUT"
  fi
  others="$(jump_lines | awk 'NR>1' | sort -rn)"
  for n in $others; do $SUDO_CMD $IPT -w -D OUTPUT "$n"; done
  echo "✓ cerca de pé: $CHAIN com $(wc -l <<< "$rules") regra(s), salto na 1ª posição do OUTPUT"
}

# down: tira o salto (todas as cópias) e depois a chain. Idempotente: sem nada, não falha.
down() {
  local n
  need_fw
  for n in $(jump_lines | sort -rn); do $SUDO_CMD $IPT -w -D OUTPUT "$n"; done
  if chain_exists; then $SUDO_CMD $IPT -w -F "$CHAIN"; $SUDO_CMD $IPT -w -X "$CHAIN"; fi
  echo "✓ cerca removida: sem salto no OUTPUT e sem a chain $CHAIN"
}

render_unit() {
  cat <<EOF
# Gerado por ops/egress-uid-fence.sh do core (não edite à mão: o desfazer é \`egress-uid-fence.sh undo --apply\`).
# Cerca de saída por uid na frente do Gokapi: 127.0.0.1:$HOST_PORT só para $(host_allow); a porta $CTR_PORT só para $CTR_ALLOW.
[Unit]
Description=onion-vps: cerca de saída por uid para o Gokapi (127.0.0.1:$HOST_PORT e :$CTR_PORT)
# antes do Docker: o container nunca escuta sem a cerca de pé; depois do ufw, que não esvazia o OUTPUT
After=ufw.service
Before=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
Environment=FENCE_TUNNEL_USER=$(tunnel_user)
Environment=FENCE_DOCKER_MODE=$(docker_mode)
ExecStart=$SBIN_DEST up
ExecReload=$SBIN_DEST up
ExecStop=$SBIN_DEST down

[Install]
WantedBy=multi-user.target
EOF
}

# As redes de bridge do Docker fora de $DOCKER_NET (uma por linha). rc 2 = não medido (o `ip` falhou): o verify
# reprova, nunca lê o vazio como "todas dentro". Pega as interfaces docker*, br-* e as de nome próprio que o
# `docker network` declara (com.docker.network.bridge.name), quando o docker responde.
IP_CMD="ip"
DOCKER_CMD="docker"
bridges_outside() {
  local routes names net pfx a
  routes="$($IP_CMD -4 route show proto kernel 2>/dev/null)" || return 2
  names="$($DOCKER_CMD network ls -q --filter driver=bridge 2>/dev/null | while read -r id; do
    $DOCKER_CMD network inspect -f '{{index .Options "com.docker.network.bridge.name"}}' "$id" 2>/dev/null; done | grep -v '^$' || true)"
  net="${DOCKER_NET%/*}"; pfx="${DOCKER_NET#*/}"
  awk -v names=" $(tr '\n' ' ' <<< "$names")" '$3 ~ /^(docker|br-)/ || index(names, " " $3 " ") {print $1}' <<< "$routes" \
    | while IFS=/ read -r a _; do
        python3 -I -c 'import ipaddress,sys; sys.exit(0 if ipaddress.ip_address(sys.argv[1]) in ipaddress.ip_network(sys.argv[2]) else 1)' "$a" "$net/$pfx" || echo "$a"
      done
}

# A sonda: tenta conectar como <conta> e diz se o REJECT da regra <comentário> contou o pacote. Independe de o
# Gokapi estar de pé (sem ninguém escutando, a conexão de quem passa leva RST do kernel, e o contador não mexe).
rule_count() {  # pacotes da regra de comentário $1
  $SUDO_CMD $IPT -w -L "$CHAIN" -v -x -n | awk -v c="/* $1 */" 'index($0, c) {print $1; exit}'
}
# probe <conta> <comentário da regra que TEM de contar> → "contou" ou "não contou". Para quem passa, a regra é o
# RETURN dela: "não mexeu no REJECT" sozinho ficaria verde até com a sonda sem rodar (refutador, 2026-11-22).
# Limite: o contador é da regra, não da sonda. Uma conexão real do Caddy (ou um RST de outra conta) na mesma janela
# de 3 s também conta e pode deixar o item verde sem a sonda; o risco foi aceito como baixo.
probe() {
  local before after
  before="$(rule_count "$2")"
  sudo -n -u "$1" timeout 3 bash -c "exec 3<>/dev/tcp/$HOST_ADDR/$HOST_PORT" >/dev/null 2>&1 || true
  after="$(rule_count "$2")"
  if [[ -n "$before" && -n "$after" && "$after" -gt "$before" ]]; then echo contou; else echo "não contou"; fi
}

verify() {
  local fail=0 rules spec count want first out
  need_fw
  rules="$(fence_rules)" || die "conta da lista não resolve"
  if ! chain_exists; then echo "  ✗ chain $CHAIN ausente"; fail=1
  else
    while IFS= read -r spec; do
      $SUDO_CMD $IPT -w -C "$CHAIN" $spec 2>/dev/null || { echo "  ✗ regra ausente: $spec"; fail=1; }
    done <<< "$rules"
    count="$($SUDO_CMD $IPT -w -S "$CHAIN" | grep -c '^-A ' || true)"; want="$(wc -l <<< "$rules")"
    [[ "$count" == "$want" ]] && echo "  ✓ chain $CHAIN com as $want regras esperadas" \
      || { echo "  ✗ chain $CHAIN com $count regras (esperado $want): sobra ou falta"; fail=1; }
  fi
  if [[ "$(docker_mode)" != off ]]; then
    local outside rcb=0
    outside="$(bridges_outside)" || rcb=$?
    if [[ "$rcb" -ne 0 ]]; then echo "  ✗ não medi as rotas das bridges do Docker (\`$IP_CMD -4 route\` falhou)"; fail=1
    elif [[ -z "$outside" ]]; then echo "  ✓ toda rede de bridge do Docker está dentro de $DOCKER_NET"
    else echo "  ✗ rede do Docker FORA de $DOCKER_NET (sem cerca): $(tr '\n' ' ' <<< "$outside")"; fail=1; fi
  fi
  if jump_is_first && [[ "$(jump_lines | wc -l)" == 1 ]]; then echo "  ✓ salto único, na 1ª posição do OUTPUT (antes do ufw, que aceita lo)"
  else echo "  ✗ o salto NÃO é a 1ª regra do OUTPUT, ou há cópias (posições: $(jump_lines | tr '\n' ' '))"; fail=1; fi
  if [[ "$PROBE" == 1 ]]; then
    local other; other="$(ss -ltnH | awk '{print $4}' | grep -E ":$HOST_PORT\$" | grep -vxF "$HOST_ADDR:$HOST_PORT" || true)"
    [[ -z "$other" ]] && echo "  ✓ a porta $HOST_PORT só escuta em $HOST_ADDR" \
      || { echo "  ✗ a porta $HOST_PORT escuta também em: $(tr '\n' ' ' <<< "$other")(a cerca não cobre)"; fail=1; }
    out="$(probe nobody gokapi-loopback-deny-others)"
    [[ "$out" == contou ]] && echo "  ✓ sonda: nobody → 127.0.0.1:$HOST_PORT levou RST da cerca" \
      || { echo "  ✗ sonda: nobody → 127.0.0.1:$HOST_PORT NÃO foi barrado pela cerca"; fail=1; }
    out="$(probe caddy gokapi-loopback-allow-caddy)"
    [[ "$out" == contou ]] && echo "  ✓ sonda: caddy → 127.0.0.1:$HOST_PORT passou pela regra de liberação dele" \
      || { echo "  ✗ sonda: caddy não passou pela regra de liberação (barrado, ou a sonda não rodou)"; fail=1; }
    [[ "$($SYSTEMCTL is-enabled "$UNIT_NAME" 2>/dev/null)" == enabled ]] && echo "  ✓ unit $UNIT_NAME habilitada (volta no boot)" \
      || { echo "  ✗ unit $UNIT_NAME não habilitada: a cerca some no próximo boot"; fail=1; }
  fi
  return "$fail"
}

plan() {
  local rules spec u
  echo "── ensaio: a cerca de saída por uid do Gokapi (nada muda)"
  echo "   passam em $HOST_ADDR:$HOST_PORT: $(for u in $(host_allow); do printf '%s(uid %s) ' "$u" "$(uid_of "$u" | sed 's/^$/AUSENTE/')"; done)"
  echo "   passam na porta interna $CTR_PORT: $CTR_ALLOW (o docker-proxy); as demais contas levam RST"
  echo "   rede dos containers ($DOCKER_NET, fora os endereços do host e a porta publicada): modo $(docker_mode || echo INVÁLIDO) — $(case "$(docker_mode 2>/dev/null || echo x)" in log) echo "só registra quem seria barrado (journalctl -k | grep onion-fence-docker:)";; reject) echo "só $DOCKER_ALLOW passa, as demais contas levam RST";; off) echo "sem cerca";; *) echo "o install recusa";; esac)"
  rules="$(fence_rules)" || die "conta da lista não resolve; o install recusaria"
  echo "── as regras que o \`up\` monta (iptables-restore --noflush, numa transação):"
  echo "   *filter"; echo "   :$CHAIN - [0:0]"
  while IFS= read -r spec; do echo "   -A $CHAIN $spec"; done <<< "$rules"
  echo "   COMMIT"
  echo "   e o salto na 1ª posição: -I OUTPUT 1 $JUMP"
  echo "── a unit ($UNIT_DEST), com a cópia de root em $SBIN_DEST:"
  render_unit | sed 's/^/   | /'
  echo "── estado agora: chain $(chain_exists && echo presente || echo ausente) · salto $( [[ -n "$(jump_lines)" ]] && echo presente || echo ausente) · unit $( { $SYSTEMCTL is-enabled "$UNIT_NAME" 2>/dev/null || true; } | head -n1)"
  echo "── desfazer: ops/egress-uid-fence.sh undo --apply"
  echo "✓ RESULTADO: ensaio, nada mudou (o ato é: ops/egress-uid-fence.sh install --apply)"
}

install_fence() {
  local ts unit_tmp rc
  need_fw
  docker_mode >/dev/null || die "modo da rede dos containers inválido (na flag, no ambiente ou na unit instalada); nada mudou"
  fence_rules >/dev/null || die "conta da lista não resolve; nada mudou"
  # pré-voo: o iptables daqui entende as duas extensões? (-C de regra inexistente sai 1; extensão ausente sai 2)
  rc=0; $SUDO_CMD $IPT -w -C OUTPUT -p tcp -m conntrack --ctorigdstport 1 -m owner --uid-owner 0 -j RETURN 2>/dev/null || rc=$?
  [[ "$rc" == 1 || "$rc" == 0 ]] || die "o iptables não aceita conntrack --ctorigdstport + owner --uid-owner (rc $rc); nada mudou"
  if [[ "$(docker_mode)" != off ]]; then
    rc=0; $SUDO_CMD $IPT -w -C OUTPUT -p tcp -m conntrack --ctorigdst $DOCKER_NET ! --ctstate DNAT -m addrtype ! --dst-type LOCAL -m hashlimit --hashlimit-upto 6/min --hashlimit-mode dstip,dstport --hashlimit-name onion-fence-probe -j LOG --log-prefix onion-fence-probe: --log-uid 2>/dev/null || rc=$?
    [[ "$rc" == 1 || "$rc" == 0 ]] || die "o iptables não aceita conntrack ctorigdst/ctstate + addrtype + hashlimit + LOG --log-uid (rc $rc); nada mudou"
  fi
  ts="$(date +%Y%m%d-%H%M%S)"
  $SUDO_CMD install -d -m 0700 "$BACKUP_DIR"
  for f in "$UNIT_DEST" "$SBIN_DEST"; do
    if $SUDO_CMD test -e "$f"; then $SUDO_CMD cp -p "$f" "$BACKUP_DIR/$(basename "$f").$ts.bak" || die "backup de $f falhou; nada mudou"; fi
  done
  $SUDO_CMD install -m 0755 -o root -g root "${BASH_SOURCE[0]}" "$SBIN_DEST" || die "não instalei a cópia de root"
  unit_tmp="$(mktemp)"; render_unit > "$unit_tmp"
  $SUDO_CMD install -m 0644 -o root -g root "$unit_tmp" "$UNIT_DEST" || { rm -f "$unit_tmp"; die "não instalei a unit"; }
  rm -f "$unit_tmp"
  $SUDO_CMD $SYSTEMCTL daemon-reload
  if ! $SUDO_CMD $SYSTEMCTL enable --now "$UNIT_NAME"; then
    echo "a unit não subiu: desfazendo" >&2; undo_fence || true
    die "a unit $UNIT_NAME falhou ao subir; desfeito (veja journalctl -u $UNIT_NAME)"
  fi
  echo "── instalado; verificando"
  verify || die "instalado, mas a verificação reprovou (desfazer: ops/egress-uid-fence.sh undo --apply)"
  echo "✓ RESULTADO: cerca de pé e verificada; desfazer: ops/egress-uid-fence.sh undo --apply"
}

undo_fence() {
  need_fw
  $SUDO_CMD $SYSTEMCTL disable --now "$UNIT_NAME" 2>/dev/null || true   # o ExecStop roda o down
  $SUDO_CMD rm -f "$UNIT_DEST"
  $SUDO_CMD $SYSTEMCTL daemon-reload
  # a unit podia não existir (regras postas à mão, ou unit já apagada): o down direto garante
  down
  $SUDO_CMD rm -f "$SBIN_DEST"
  if chain_exists || [[ -n "$(jump_lines)" ]]; then die "a chain ou o salto ainda estão no ar"; fi
  echo "✓ RESULTADO: cerca desfeita (unit, cópia de root, salto e chain removidos; backups em $BACKUP_DIR)"
}

# ── selftest: sandbox com iptables, iptables-restore, systemctl e install de mentira; nunca toca o firewall ──
selftest() {
  local pass=0 fail=0 out rc
  SB="$(mktemp -d)"; trap 'rm -rf -- "${SB:-}"' EXIT
  mkdir -p "$SB/bin"
  SUDO_CMD=""; PROBE=0; UNIT_DEST="$SB/unit.service"; SBIN_DEST="$SB/sbin.sh"; BACKUP_DIR="$SB/backups"
  export FW="$SB/fw"
  printf -- '-P OUTPUT ACCEPT\n-A OUTPUT -j ufw-before-logging-output\n-A OUTPUT -j ufw-before-output\n' > "$FW"
  # iptables de mentira: guarda as regras em linhas «-A CHAIN spec» / «-N CHAIN», na ordem
  cat > "$SB/bin/iptables" <<'STUB'
#!/usr/bin/env bash
set -f
[ "$1" = -w ] && shift
op="$1"; ch="$2"; shift 2
has_chain() { [ "$1" = OUTPUT ] || grep -qxF -- "-N $1" "$FW"; }
case "$op" in
  -S) [ -n "${STUB_S_FAIL:-}" ] && exit 4; has_chain "$ch" || exit 1
      if [ "$ch" = OUTPUT ]; then echo "-P OUTPUT ACCEPT"; else echo "-N $ch"; fi
      grep -F -- "-A $ch " "$FW" | grep -E -- "^-A $ch " || true ;;
  -L) has_chain "$ch" || exit 1; echo "Chain $ch"; echo "num target prot opt source destination"
      grep -E -- "^-A $ch " "$FW" | awk '{k++; t="-"; for(i=1;i<NF;i++) if($i=="-j") t=$(i+1); print k, t, "all", "--", "0.0.0.0/0", "0.0.0.0/0"}' ;;
  -C) has_chain "$ch" || exit 1; case "$*" in *--ctorigdstport*) [ -n "${STUB_NO_EXT:-}" ] && exit 2;; esac
      case "$*" in *hashlimit*) [ -n "${STUB_NO_EXT2:-}" ] && exit 2;; esac
      grep -qxF -- "-A $ch $*" "$FW" ;;
  -I) shift; line="-A $ch $*"; awk -v l="$line" -v c="-A $ch " 'BEGIN{d=0} !d && index($0,c)==1 {print l; d=1} {print} END{if(!d) print l}' "$FW" > "$FW.t" && mv "$FW.t" "$FW" ;;
  -D) if [[ "$1" =~ ^[0-9]+$ ]]; then awk -v c="-A $ch " -v n="$1" 'index($0,c)==1 {k++; if(k==n) next} {print}' "$FW" > "$FW.t"
      else awk -v l="-A $ch $*" 'BEGIN{d=0} !d && $0==l {d=1; next} {print}' "$FW" > "$FW.t"; fi; mv "$FW.t" "$FW" ;;
  -F) grep -v -F -- "-A $ch " "$FW" > "$FW.t" || true; mv "$FW.t" "$FW" ;;
  -X) grep -q -F -- "-j $ch" "$FW" && { echo "chain em uso" >&2; exit 1; }; grep -vxF -- "-N $ch" "$FW" > "$FW.t" || true; mv "$FW.t" "$FW" ;;
  *) exit 2 ;;
esac
STUB
  cat > "$SB/bin/iptables-restore" <<'STUB'
#!/usr/bin/env bash
[ -n "${STUB_RESTORE_RC:-}" ] && exit "$STUB_RESTORE_RC"
while IFS= read -r l; do
  case "$l" in
    :*) c="${l#:}"; c="${c%% *}"; grep -v -F -- "-A $c " "$FW" > "$FW.t" || true; mv "$FW.t" "$FW"
        grep -qxF -- "-N $c" "$FW" || echo "-N $c" >> "$FW" ;;
    -A*) echo "$l" >> "$FW" ;;
  esac
done
STUB
  # systemctl de mentira como FUNÇÃO, no mesmo processo: o enable roda o `up` daqui (com os stubs), nunca a cópia
  # instalada, que como script novo voltaria ao iptables real
  fake_systemctl() {
    echo "$*" >> "$SB/systemctl.log"
    case "$1" in
      enable)     [[ -n "${STUB_ENABLE_RC:-}" ]] && return "$STUB_ENABLE_RC"; up >/dev/null ;;
      disable)    [[ -e "$UNIT_DEST" ]] && down >/dev/null; return 0 ;;
      is-enabled) [[ -e "$UNIT_DEST" ]] && echo enabled || return 1 ;;
    esac
    return 0
  }
  printf '#!/usr/bin/env bash\nargs=(); while [ $# -gt 0 ]; do case "$1" in -o|-g|-m) shift 2;; -d) shift; mkdir -p "$@"; exit 0;; *) args+=("$1"); shift;; esac; done; cp "${args[0]}" "${args[1]}"\n' > "$SB/bin/install"
  chmod +x "$SB/bin/iptables" "$SB/bin/iptables-restore" "$SB/bin/install"
  IPT="$SB/bin/iptables"; IPT_RESTORE="$SB/bin/iptables-restore"; SYSTEMCTL="fake_systemctl"
  # ip e docker de mentira: as rotas vêm de $SB/routes; STUB_IP_FAIL faz o ip falhar; a bridge de nome próprio vem do docker
  printf '#!/usr/bin/env bash\n[ -n "${STUB_IP_FAIL:-}" ] && exit 1\ncat "$SB/routes"\n' > "$SB/bin/ip"
  printf '#!/usr/bin/env bash\ncase "$1 $2" in "network ls") echo n1;; "network inspect") echo "${STUB_BRNAME:-}";; esac\n' > "$SB/bin/docker"
  chmod +x "$SB/bin/ip" "$SB/bin/docker"; IP_CMD="$SB/bin/ip"; DOCKER_CMD="$SB/bin/docker"
  printf '172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1\n172.23.0.0/16 dev br-abc proto kernel scope link src 172.23.0.1\n10.0.0.0/24 dev eth0 proto kernel scope link src 10.0.0.5\n' > "$SB/routes"
  export SB SBIN_DEST UNIT_DEST PATH="$SB/bin:$PATH"
  # a cópia de root, no sandbox, é este script apontado para os stubs
  export FENCE_TUNNEL_USER="$(id -un)"
  SELF_USER="$(id -un)"
  uid_of() { case "$1" in caddy) echo 999;; root) echo 0;; "$SELF_USER") id -u;; *) ;; esac; }

  t() { local name="$1" want="$2"; shift 2
    set +e; out="$( set -e; "$@" 2>&1 )"; rc=$?; set -e
    if [[ "$rc" -eq "$want" ]]; then pass=$((pass+1)); echo "  ✓ $name"
    else fail=$((fail+1)); echo "  ✗ $name (rc=$rc, esperado=$want)"; printf '%s\n' "$out" | sed 's/^/      | /'; fi
  }
  ok() { if eval "$2"; then pass=$((pass+1)); echo "  ✓ $1"; else fail=$((fail+1)); echo "  ✗ $1"; fi; }
  jump_first() { [[ "$(sed -n 2p "$FW")" == "-A OUTPUT $JUMP" ]]; }

  echo "── selftest (sandbox: $SB) ──"
  # 1. ensaio não muda nada
  cp "$FW" "$SB/fw.before"
  t "plan: ensaio sai 0" 0 plan
  ok "plan: firewall intocado" 'cmp -s "$FW" "$SB/fw.before"'
  ok "plan: mostra a REJECT do loopback e a da porta interna" '[[ "$out" == *"gokapi-loopback-deny-others -j REJECT"* && "$out" == *"--ctorigdstport 53842"*"REJECT"* ]]'
  # 2. up: chain com caddy e túnel passando, os outros com RST, salto no TOPO (antes do ufw)
  t "up: sobe" 0 up
  ok "up: salto na 1ª posição do OUTPUT, antes do ufw-before-output" 'jump_first'
  ok "up: caddy (999) passa no loopback" 'grep -qF -- "--ctorigdstport 3050 -m owner --uid-owner 999 -m comment --comment gokapi-loopback-allow-caddy -j RETURN" "$FW"'
  ok "up: o túnel passa no loopback" 'grep -qF -- "--uid-owner $(id -u) -m comment --comment gokapi-loopback-allow-$FENCE_TUNNEL_USER -j RETURN" "$FW"'
  ok "up: o REJECT do loopback vem DEPOIS das liberações" '[[ "$(grep -nF gokapi-loopback-deny-others "$FW" | cut -d: -f1)" -gt "$(grep -nF gokapi-loopback-allow-caddy "$FW" | cut -d: -f1)" ]]'
  ok "up (log, o padrão): root passa na rede dos containers e as demais contas só são registradas, nunca barradas" 'grep -qF -- "--ctorigdst 172.16.0.0/12 ! --ctstate DNAT -m addrtype ! --dst-type LOCAL -m owner --uid-owner 0 -m comment --comment docker-net-allow-root -j RETURN" "$FW" && grep -qF -- "-m hashlimit --hashlimit-upto 6/min --hashlimit-burst 6 --hashlimit-mode dstip,dstport --hashlimit-name onion-fence-docker -m comment --comment docker-net-log-others -j LOG --log-prefix onion-fence-docker: --log-uid" "$FW" && grep -qF -- "! --ctstate DNAT -m addrtype ! --dst-type LOCAL -m owner --uid-owner 0" "$FW" && ! grep -qF docker-net-deny-others "$FW"'
  ok "up (log): a rede dos containers vem DEPOIS das regras do Gokapi" '[[ "$(grep -nF docker-net-allow-root "$FW" | cut -d: -f1)" -gt "$(grep -nF gokapi-ctr-deny-others "$FW" | cut -d: -f1)" ]]'
  ok "up: só o root passa na porta interna 53842" 'grep -qF -- "--ctorigdstport 53842 -m owner --uid-owner 0 -m comment --comment gokapi-ctr-allow-root -j RETURN" "$FW" && grep -qF gokapi-ctr-deny-others "$FW"'
  t "verify: verde depois do up" 0 verify
  # 3. idempotência: up de novo não duplica salto nem regra
  t "up: idempotente" 0 up
  ok "up 2x: um salto só e 7 regras na chain (5 do Gokapi + 2 da rede dos containers em log)" '[[ "$(grep -c -- "-j $CHAIN" "$FW")" == 1 && "$(grep -c -- "^-A $CHAIN " "$FW")" == 7 ]]'
  # 4. o salto empurrado para baixo (alguém inseriu no topo) → verify acusa, up repõe sem janela
  "$IPT" -I OUTPUT 1 -o lo -j ACCEPT
  t "verify: salto fora do topo → acusa" 1 verify
  t "up: repõe o salto no topo" 0 up
  ok "up: salto de volta ao topo e sem cópia embaixo" 'jump_first && [[ "$(grep -c -- "-j $CHAIN" "$FW")" == 1 ]]'
  "$IPT" -D OUTPUT -o lo -j ACCEPT
  # 5. regra sumida da chain → verify acusa
  "$IPT" -D "$CHAIN" $(fence_rules | sed -n 1p)
  t "verify: regra de liberação sumida → acusa" 1 verify
  t "up: repõe a chain inteira" 0 up
  t "verify: verde de novo" 0 verify
  # 5b. os modos da rede dos containers: reject barra, off tira, modo inválido recusa sem mexer
  FENCE_DOCKER_MODE=reject t "up: modo reject" 0 up
  ok "reject: as demais contas levam RST na rede dos containers, e o LOG sai" 'grep -qF -- "docker-net-deny-others -j REJECT --reject-with tcp-reset" "$FW" && ! grep -qF docker-net-log-others "$FW"'
  ok "reject: a liberação do root vem ANTES do REJECT" '[[ "$(grep -nF docker-net-allow-root "$FW" | cut -d: -f1)" -lt "$(grep -nF docker-net-deny-others "$FW" | cut -d: -f1)" ]]'
  FENCE_DOCKER_MODE=off t "up: modo off" 0 up
  ok "off: sem nenhuma regra da rede dos containers, o Gokapi intacto" '! grep -qF docker-net- "$FW" && grep -qF gokapi-ctr-deny-others "$FW"'
  cp "$FW" "$SB/fw.mode"
  FENCE_DOCKER_MODE=barra-tudo t "up: modo inválido → recusa" 2 up
  ok "modo inválido: firewall intocado" 'cmp -s "$FW" "$SB/fw.mode"'
  t "main: --docker-mode inválido → recusa" 2 main plan --docker-mode barra-tudo
  t "up: de volta ao log" 0 up
  # 5c. as rotas das bridges: dentro da faixa → verde; uma fora (pool padrão em 192.168) → acusa; ip falhando → acusa
  t "verify: bridges dentro de 172.16/12 → verde" 0 verify
  ok "verify: não conta a eth0 (não é bridge do Docker)" '[[ "$out" == *"toda rede de bridge do Docker está dentro"* ]]'
  echo "192.168.0.0/20 dev br-new proto kernel scope link src 192.168.0.1" >> "$SB/routes"
  t "verify: bridge nova fora da faixa → acusa" 1 verify
  ok "verify: diz qual rede ficou fora" '[[ "$out" == *"FORA de 172.16.0.0/12"*"192.168.0.0"* ]]'
  sed -i "/br-new/d" "$SB/routes"
  echo "192.168.5.0/24 dev meubr proto kernel scope link src 192.168.5.1" >> "$SB/routes"
  STUB_BRNAME=meubr t "verify: bridge de nome próprio (docker network) fora da faixa → acusa" 1 verify
  sed -i "/meubr/d" "$SB/routes"
  STUB_IP_FAIL=1 t "verify: ip falha → acusa, nunca verde no escuro" 1 verify
  ok "verify com ip falhando: diz que não mediu" '[[ "$out" == *"não medi as rotas"* ]]'
  # 6. conta que não resolve → up recusa e não mexe
  cp "$FW" "$SB/fw.ok"
  FENCE_TUNNEL_USER=conta-que-nao-existe-xyz t "up: conta do túnel inexistente → recusa" 2 up
  ok "up recusado: firewall intocado" 'cmp -s "$FW" "$SB/fw.ok"'
  # 7. restore falha → up recusa e não põe o salto numa chain que não subiu
  down >/dev/null
  STUB_RESTORE_RC=1 t "up: iptables-restore falha → recusa" 2 up
  ok "restore falho: sem salto no OUTPUT" '! grep -qF -- "-j $CHAIN" "$FW"'
  # 8. down: tira tudo, idempotente
  up >/dev/null
  t "down: remove" 0 down
  ok "down: sem salto e sem chain" '! grep -qF -- "$CHAIN" "$FW"'
  t "down: idempotente sem nada" 0 down
  # 8b. listagem do iptables falha (sudo sem credencial, xtables travado) → recusa, nunca "removida" no escuro
  STUB_S_FAIL=1 t "down: listagem do OUTPUT falha → recusa" 2 down
  STUB_S_FAIL=1 t "verify: listagem do OUTPUT falha → recusa" 2 verify
  # 9. install --apply: cópia de root, unit, enable (que roda o up), verify; undo desfaz tudo
  t "install: instala, liga e verifica" 0 install_fence
  ok "install: unit escrita com ExecStart/ExecStop e o túnel" 'grep -qF "ExecStart=$SBIN_DEST up" "$UNIT_DEST" && grep -qF "ExecStop=$SBIN_DEST down" "$UNIT_DEST" && grep -qF "Environment=FENCE_TUNNEL_USER=$FENCE_TUNNEL_USER" "$UNIT_DEST"'
  ok "install: unit antes do Docker" 'grep -qx "Before=docker.service" "$UNIT_DEST"'
  ok "install: unit grava o modo da rede dos containers (log por padrão)" 'grep -qxF "Environment=FENCE_DOCKER_MODE=log" "$UNIT_DEST"'
  # o modo gravado na unit vale para o shell sem flag: install em reject, depois verify e install sem flag
  FENCE_DOCKER_MODE=reject t "install em reject" 0 install_fence
  t "verify sem flag depois do install em reject: verde (lê o modo da unit)" 0 verify
  t "install sem flag depois do reject: mantém reject" 0 install_fence
  ok "reinstall sem flag: a unit segue em reject e o REJECT segue de pé" 'grep -qxF "Environment=FENCE_DOCKER_MODE=reject" "$UNIT_DEST" && grep -qF docker-net-deny-others "$FW"'
  FENCE_DOCKER_MODE=log t "install de volta ao log (dito)" 0 install_fence
  ok "install: reload da unit é o up (repõe sem janela)" 'grep -qxF "ExecReload=$SBIN_DEST up" "$UNIT_DEST"'
  ok "install: cerca de pé" 'jump_first'
  t "install 2x: backup da unit anterior" 0 install_fence
  ok "install 2x: backup criado" '[[ -n "$(find "$BACKUP_DIR" -name "unit.service.*.bak")" ]]'
  t "undo: desfaz" 0 undo_fence
  ok "undo: sem unit, sem cópia, sem salto, sem chain" '[[ ! -e "$UNIT_DEST" && ! -e "$SBIN_DEST" ]] && ! grep -qF -- "$CHAIN" "$FW"'
  # 10. a unit não sobe → install desfaz sozinho
  STUB_ENABLE_RC=1 t "install: unit falha → desfaz e recusa" 2 install_fence
  ok "install falho: nada ficou" '[[ ! -e "$UNIT_DEST" ]] && ! grep -qF -- "$CHAIN" "$FW"'
  # 11. iptables sem a extensão → install recusa antes de tocar
  STUB_NO_EXT=1 t "install: iptables sem conntrack/owner → recusa" 2 install_fence
  ok "install sem extensão: nada instalado" '[[ ! -e "$UNIT_DEST" && ! -e "$SBIN_DEST" ]]'
  STUB_NO_EXT2=1 t "install: iptables sem hashlimit/LOG --log-uid → recusa" 2 install_fence
  ok "install sem hashlimit: nada instalado" '[[ ! -e "$UNIT_DEST" && ! -e "$SBIN_DEST" ]]'
  # 12. ato sem --apply é ensaio (gramática da linha de comando)
  t "install sem --apply → recusa" 2 main install
  t "undo sem --apply → recusa" 2 main undo

  echo "── selftest: ${pass} pass / ${fail} fail ──"
  [[ "$fail" -eq 0 ]]
}

main() {
  local cmd="${1:-plan}" apply=0 a
  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply) apply=1 ;;
      --tunnel-user) [[ -n "${2:-}" ]] || die "--tunnel-user pede uma conta"; export FENCE_TUNNEL_USER="$2"; shift ;;
      --docker-mode) [[ -n "${2:-}" ]] || die "--docker-mode pede log, reject ou off"; export FENCE_DOCKER_MODE="$2"; docker_mode >/dev/null || die "--docker-mode: use log, reject ou off"; shift ;;
      *) die "argumento desconhecido: $1 (use --help)" ;;
    esac
    shift
  done
  case "$cmd" in
    --help|-h) usage ;;
    --selftest) selftest ;;
    plan)    plan ;;
    verify)  verify ;;
    up)      [[ "$(id -u)" == 0 || -z "$SUDO_CMD" ]] || die "up é da unit (root)"; up ;;
    down)    [[ "$(id -u)" == 0 || -z "$SUDO_CMD" ]] || die "down é da unit (root)"; down ;;
    install) [[ "$apply" == 1 ]] || die "install sem --apply: rode o ensaio (plan) ou acrescente --apply"; install_fence ;;
    undo)    [[ "$apply" == 1 ]] || die "undo sem --apply: o ensaio é o plan; acrescente --apply para desfazer"; undo_fence ;;
    *) die "modo desconhecido: $cmd (use --help)" ;;
  esac
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
