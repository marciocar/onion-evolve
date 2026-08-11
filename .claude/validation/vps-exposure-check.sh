#!/usr/bin/env bash
# vps-exposure-check.sh — as duas condições que armam risco na VPS, e que nada hoje vigia.
#
# ⚠️ ESTE SCRIPT NÃO CHECA CÓDIGO. Ele checa o ESTADO VIVO da máquina — por isso não é uma REGRA do
#    lint de artefatos, e por isso ele CALA (exit 0) quando não está na VPS. Guarda que reprova por
#    estar no lugar errado vira ruído e é desligada.
#
# ── POR QUE (1): PORTA PUBLICADA EM 0.0.0.0 ────────────────────────────────────────────────────
# Medido 2026-08-10, e o contraste é a prova:
#     docker exec onion-vps-waha curl http://172.17.0.1:3022/  → 302      (bind 0.0.0.0)
#     docker exec onion-vps-waha curl http://172.17.0.1:3011/  → timeout  (bind 127.0.0.1)
# Porta PUBLICADA PELO DOCKER escapa do `ufw INPUT DROP` — o caminho é DNAT/FORWARD, e a regra
# `DOCKER-USER -i eth0` só cobre a internet. Processo do HOST em 0.0.0.0 (o bridge em :8787) NÃO
# escapa, porque aí o INPUT morde. **O perigo é específico de porta publicada por container.**
# O que isso custou: um IdP de adotante com tenant `admin` em modo `Register` e ZERO usuários ficou
# alcançável de qualquer container — quem chegasse criava o PRIMEIRO ADMINISTRADOR dele.
#
# ── POR QUE (2): CONECTOR UPSTREAM NO LOGTO ────────────────────────────────────────────────────
# O CERT/CC publicou SEIS CVEs no Logto (VU#492466, 23/07/2026), incluindo account-linking por
# e-mail não verificado. Todos exigem, textualmente, conector federado/SSO/SAML upstream. Hoje há
# ZERO — só o SMTP. **E NÃO HÁ PATCH**: a CERT registra que a mantenedora não foi alcançada para
# coordenação. Subir de versão não compra proteção nenhuma contra eles.
# Logo a proteção é uma CONDIÇÃO, não uma cura: "zero conectores upstream". Ligar login social
# ARMA OS SEIS de uma vez — e é por isso que isto precisa de guarda, não de memória.
#
# Uso: bash vps-exposure-check.sh [--format tsv]
# Saída: HARD por achado. exit 1 se houver HARD, 0 se limpo, 0 (com aviso) se não for a VPS.
set -uo pipefail

FORMAT=text
for a in "$@"; do case "$a" in --format=tsv|--format) FORMAT=tsv ;; tsv) FORMAT=tsv ;; esac; done

_hard=0
_say() { if [ "${FORMAT}" = tsv ]; then printf 'HARD\t%s\t%s\t%s\n' "$1" "$2" "$3"; else printf '  ✗ %s: %s — %s\n' "$1" "$2" "$3"; fi; _hard=$((_hard + 1)); }

# ── fora da VPS a guarda declara que NÃO SABE, em vez de aprovar por ausência ────────────────
if ! command -v docker >/dev/null 2>&1; then
  [ "${FORMAT}" = tsv ] || echo "  ⊘ sem docker — fora do escopo (a guarda cala, não aprova)"
  exit 0
fi
_dk() { docker "$@" 2>/dev/null || sudo -n docker "$@" 2>/dev/null; }
if ! _dk ps -q >/dev/null 2>&1; then
  [ "${FORMAT}" = tsv ] || echo "  ⊘ docker inacessível — fora do escopo (a guarda cala, não aprova)"
  exit 0
fi

# ── (1) portas publicadas fora do loopback ──────────────────────────────────────────────────
# `0.0.0.0`/`[::]` é o que importa; a ausência de host_ip no formato do docker também significa
# todas as interfaces, e por isso os dois padrões são checados.
_ports="$(_dk ps --format '{{.Names}}\t{{.Ports}}' || true)"
if [ -n "${_ports}" ]; then
  while IFS=$'\t' read -r _name _p; do
    [ -n "${_name}" ] || continue
    case "${_p}" in
      *0.0.0.0:*|*'[::]:'*)
        _bad="$(printf '%s' "${_p}" | grep -oE '(0\.0\.0\.0|\[::\]):[0-9]+' | tr '\n' ' ')"
        _say "BIND-PUBLICO" "${_name}" "publica em ${_bad}— alcançável de outro container (DNAT escapa do ufw INPUT). Use '127.0.0.1:<porta>:<alvo>'"
        ;;
    esac
  done <<< "${_ports}"
fi

# ── (2) conector upstream no Logto (arma os 6 CVEs sem patch) ───────────────────────────────
# Percorre TODOS os Postgres de Logto da máquina, não só o do core: o achado que fundou esta regra
# foi num IdP de ADOTANTE, que ninguém estava olhando.
for _pg in $(_dk ps --format '{{.Names}}' | grep -iE 'logto.*(postgres|db)|postgres.*logto' || true); do
  _conn="$(_dk exec "${_pg}" psql -U logto -d logto -tAc \
    "select coalesce(count(*),0) from connectors where connector_id not like '%mail%';" 2>/dev/null | tr -d ' \r\n')"
  _sso="$(_dk exec "${_pg}" psql -U logto -d logto -tAc \
    "select coalesce(count(*),0) from sso_connectors;" 2>/dev/null | tr -d ' \r\n')"
  # consulta que falha devolve vazio; vazio NÃO é zero — declarar ignorância é o comportamento certo
  if [ -z "${_conn}" ] || [ -z "${_sso}" ]; then
    [ "${FORMAT}" = tsv ] || printf '  ⊘ %s: não consegui ler os conectores (vazio ≠ zero — não afirmo conformidade)\n' "${_pg}"
    continue
  fi
  if [ "${_conn}" -gt 0 ] || [ "${_sso}" -gt 0 ]; then
    _say "CONECTOR-UPSTREAM" "${_pg}" "há ${_conn} conector(es) social e ${_sso} SSO — isso ARMA os 6 CVEs do VU#492466, que NÃO TÊM PATCH. Se for deliberado, declare na allowlist"
  fi
done

# ── (3) artefato de backup EM CLARO ─────────────────────────────────────────────────────────
# Classe achada em 2026-08-11: 19 dumps do Logto viviam `root:root 644` em disco — o banco de
# IDENTIDADES (hashes de senha, aplicacoes, segredos de cliente), legivel por qualquer uma das 5
# contas com shell desta maquina. O backup do cofre ja cifrava; este nao, e a assimetria nao tinha
# razao — so nunca tinha sido feita.
# E o modo de falha e SILENCIOSO por natureza: um `.sql` a mais no diretorio nao chama atencao.
# ⚠️ O ESCOPO E DECLARADO, nao adivinhado: so os diretorios `backups/` das ferramentas da casa.
#    Varrer o disco atras de "coisa que parece backup" produziria falso-positivo em massa.
# ⚠️ O ESCOPO JA FOI ESTREITO DEMAIS UMA VEZ. A 1a versao olhava so `/home/marcio/onion-vps-*/backups`
#    e a passada adversarial contra ela achou DOIS diretorios de fora: `/home/marcio/backups/bridge`
#    (17 arquivos sem cifra, incluindo os `bridge-diario-*.tar.gz` que carregam o `.env` do bridge —
#    ANTHROPIC_API_KEY e tokens de convite — e um deles em 644) e `/home/onion/.claude/backups`.
#    Guarda com escopo menor que a classe e verde-vazia onde nao olha.
#    O escopo agora e DECLARADO E EXPLICITO, um caminho por linha: acrescentar diretorio de backup
#    novo exige acrescentar aqui, e essa friccao e o ponto — o alternativo (varrer o disco atras de
#    "coisa que parece backup") produz falso-positivo em massa e vira ruido ignorado.
# `BACKUP_DIRS_OVERRIDE` existe SO para a bancada poder testar o DETECTOR num diretorio proprio,
# em vez de depender do estado do disco — teste que depende do vivo passa a mentir quando o vivo muda.
for _bdir in ${BACKUP_DIRS_OVERRIDE:-/home/marcio/onion-vps-*/backups /home/marcio/backups/* /home/onion/.claude/backups}; do
  [ -d "${_bdir}" ] || continue
  # `find` (nao glob) porque o glob expande no shell do chamador e devolve vazio sem acesso —
  # e vazio lido como ausencia e exatamente o fail-open que este arquivo existe para impedir.
  _plain="$(find "${_bdir}" -maxdepth 1 -type f ! -name '*.gpg' 2>/dev/null | wc -l)"
  if [ "${_plain}" -gt 0 ]; then
    _say "BACKUP-EM-CLARO" "${_bdir}" "${_plain} arquivo(s) sem .gpg — backup nao cifrado e dado sensivel em repouso"
  fi
done

if [ "${FORMAT}" != tsv ]; then
  if [ "${_hard}" -eq 0 ]; then echo "  ✓ nenhuma porta publica, nenhum conector upstream, nenhum backup em claro"
  else echo "  ── ${_hard} achado(s) HARD"; fi
fi
[ "${_hard}" -eq 0 ] || exit 1
exit 0
