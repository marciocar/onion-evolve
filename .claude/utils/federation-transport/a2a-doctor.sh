#!/usr/bin/env bash
# =============================================================================
# a2a-doctor.sh — diagnóstico da fiação A2A de um membro, com CAUSA e PRÓXIMO PASSO por checagem.
#
# Graduado do spike F0 do configurador A2A (SAC-121, teste S3 = SAC-128; evidência no grafo
# docs/evolution/research/a2a-configurator-2026-10/, nós E_SPIKE_S3_DOCTOR e C_PINO_SO_SE_MEDE_NO_RECEPTOR).
# Moldes: a classificação pura testável e o "não sei nunca vira saudável" do medidor de saúde do
# revisor do core, e a conferência por NOME e permissão do env-check do task-manager (segredo nunca
# sai). O gate julgado é a2a-verify.sh (irmão deste arquivo), e o relógio usa os MESMOS sinais dele.
#
# DOIS LADOS, porque o spike mediu que a pergunta "minha chave está pinada?" só se responde com o
# registro do RECEPTOR (C_PINO_SO_SE_MEDE_NO_RECEPTOR):
#   --side member   (default) roda na máquina do membro: chave, permissão, impressão, credencial do
#                   canal, relógio, alcance e, se houver o registro e o gate, o pino e um envio sintético.
#                   Sem o registro, o pino e o envio saem "não medido" (rc 2): peça ao receptor o lado dele.
#   --side receiver roda no receptor (core): registro válido, kid pinado com pública RSA legível,
#                   impressão conferida contra a que o membro mandou, topologia de confiança e relógio.
#
# USO
#   a2a-doctor.sh --member <id> [--side member|receiver] [--dir <dir de chaves>] [--kid <kid>]
#                 [--members <members.yaml>] [--jwks <dir>] [--receiver <id>] [--token-file <f>]
#                 [--invite <descritor>] [--invites <arquivo de convites>] [--fingerprint sha256:<hex>]
#                 [--endpoint <url>] [--json]
#   a2a-doctor.sh --selftest      # só a classificação pura (sem chave, sem rede)
#
#   --dir         default ${XDG_CONFIG_HOME:-~/.config}/onion/a2a (o layout do a2a-keygen.sh:
#                 <kid>.key.pem e <kid>.pem)
#   --kid         default: o único <member>-N.key.pem do dir (ou, entre vários, o único pinado)
#   --members     default <raiz>/docs/evolution/federation/members.yaml, se existir
#   --jwks        default ${A2A_JWKS_DIR:-<este dir>/jwks}
#   --receiver    default members.yaml[member].a2a.sends_to; senão, o membro kind: source
#   --token-file  default <dir>/bridge-token (o bearer; o conteúdo NUNCA é lido para a saída)
#   --invite      o descritor do convite por membro (F2), sem segredo, que o a2a-invite.sh create gera ao
#                 lado do token: {member, receiver, expires_at (ISO 8601 com hora e fuso), revoked,
#                 token_sha256}. Julgado pelas regras do bridge (revoked só vale como false literal)
#   --invites     lado receptor: o arquivo de convites do seu bridge (A2A_INVITES_FILE). Rode como a
#                 conta do serviço do bridge (o arquivo é 0600 dela). O token NUNCA é lido: a sonda usa
#                 o hash do descritor (--invite) ou as entradas do membro
#   --fingerprint a impressão que o membro mandou por canal fora de banda (lado receptor)
#
# CHECAGENS (cada uma: ok | falha | nao-medido, com causa em pt-BR e próximo passo)
#   membro:   a chave · b permissão · c impressão · d pino no registro · e credencial do canal ·
#             f relógio · g endpoint · h envio sintético
#   receptor: r registro · d pino · c impressão conferida · t topologia · i convite por membro ·
#             f relógio · g endpoint
#   Críticas: todas, exceto g sem --endpoint e, no receptor, c sem --fingerprint e i sem --invites (saem não medidas e
#   NÃO críticas, declarado na saída: não informado não é saudável, é não perguntado).
#
# EXIT: 0 tudo ok · 1 alguma falha · 2 alguma crítica não medida (e nenhuma falha) · 3 uso inválido
# Exercitado por lint-selftest.sh (run_federation_a2a_selftests).
# =============================================================================
set -uo pipefail
umask 077

# ── classificação PURA: TSV de resultados (id status critical causa proximo) → rc ─────────────
# Separada da medição para ser testável sem chave nem rede (--selftest). "não sei" nunca vira 0.
classify() {  # $1 = arquivo TSV → imprime o rc (0|1|2)
  awk -F'\t' '
    $2=="falha" { f=1 }
    $2=="nao-medido" && $3=="1" { n=1 }
    $2!="ok" && $2!="falha" && $2!="nao-medido" { f=1 }   # status desconhecido: errar para o veto
    END { if (f) print 1; else if (n) print 2; else if (NR==0) print 2; else print 0 }' "$1"
}

if [ "${1:-}" = "--selftest" ]; then
  T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
  fails=0; total=0
  _case() {  # nome · rc esperado · linhas (status:critical separadas por espaço)
    local name="$1" exp="$2" spec got; shift 2
    : > "${T}/r.tsv"
    for spec in "$@"; do printf 'x\t%s\t%s\tc\tn\n' "${spec%%:*}" "${spec##*:}" >> "${T}/r.tsv"; done
    got="$(classify "${T}/r.tsv")"; total=$((total+1))
    if [ "${got}" = "${exp}" ]; then printf '  ✓ %s → rc %s\n' "${name}" "${got}"
    else printf '  ✗ %s → esperava rc %s, veio %s\n' "${name}" "${exp}" "${got}"; fails=$((fails+1)); fi
  }
  _case "tudo ok" 0 ok:1 ok:1 ok:0
  _case "uma falha crítica" 1 ok:1 falha:1
  _case "falha não crítica também reprova" 1 ok:1 falha:0
  _case "falha vence não medido" 1 nao-medido:1 falha:1
  _case "crítica não medida → não sei" 2 ok:1 nao-medido:1
  _case "não crítica não medida não derruba" 0 ok:1 nao-medido:0
  _case "status desconhecido erra para o veto" 1 ok:1 talvez:1
  _case "nenhuma checagem → não sei, nunca saudável" 2
  printf 'a2a-doctor --selftest: %s/%s\n' "$((total-fails))" "${total}"
  [ "${fails}" -eq 0 ]; exit $?
fi

SIDE="member"; MEMBER=""; DIR=""; KID=""; MEMBERS=""; JWKS=""; RECEIVER=""; TOKEN_FILE=""
INVITE=""; INVITES=""; EXPECT_FP=""; ENDPOINT=""; JSON=""
usage() { sed -n '/^# USO/,/^# EXIT/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 3; }
need() { [ $# -ge 2 ] && [ -n "$2" ] && [ "${2#--}" = "$2" ] || { printf 'a2a-doctor: %s exige valor\n' "$1" >&2; exit 3; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --side)        need "$@"; SIDE="$2"; shift 2 ;;
    --member)      need "$@"; MEMBER="$2"; shift 2 ;;
    --dir)         need "$@"; DIR="$2"; shift 2 ;;
    --kid)         need "$@"; KID="$2"; shift 2 ;;
    --members)     need "$@"; MEMBERS="$2"; shift 2 ;;
    --jwks)        need "$@"; JWKS="$2"; shift 2 ;;
    --receiver)    need "$@"; RECEIVER="$2"; shift 2 ;;
    --token-file)  need "$@"; TOKEN_FILE="$2"; shift 2 ;;
    --invite)      need "$@"; INVITE="$2"; shift 2 ;;
    --invites)     need "$@"; INVITES="$2"; shift 2 ;;
    --fingerprint) need "$@"; EXPECT_FP="$2"; shift 2 ;;
    --endpoint)    need "$@"; ENDPOINT="$2"; shift 2 ;;
    --json)        JSON=1; shift ;;
    -h|--help)     usage ;;
    *) printf 'a2a-doctor: argumento desconhecido %s\n' "$1" >&2; exit 3 ;;
  esac
done
[ -n "${MEMBER}" ] || usage
case "${SIDE}" in member|receiver) ;; *) printf 'a2a-doctor: --side é member ou receiver\n' >&2; exit 3 ;; esac
# o id e o kid viram nome de arquivo: forma fechada (a mesma régua do keygen e do gate)
case "${MEMBER}" in *[!A-Za-z0-9._-]*|.*) printf 'a2a-doctor: --member fora de [A-Za-z0-9._-]\n' >&2; exit 3 ;; esac
case "${KID}" in *[!A-Za-z0-9._-]*|.*) printf 'a2a-doctor: --kid fora de [A-Za-z0-9._-]\n' >&2; exit 3 ;; esac
case "${RECEIVER}" in *[!A-Za-z0-9._-]*|.*) printf 'a2a-doctor: --receiver fora de [A-Za-z0-9._-]\n' >&2; exit 3 ;; esac
if [ -n "${ENDPOINT}" ]; then case "${ENDPOINT}" in http://*|https://*) ;; *) printf 'a2a-doctor: --endpoint precisa ser http(s)://\n' >&2; exit 3 ;; esac; fi
if [ -n "${EXPECT_FP}" ]; then
  EXPECT_FP="$(printf '%s' "${EXPECT_FP}" | tr 'A-Z' 'a-z')"; EXPECT_FP="${EXPECT_FP#sha256:}"
  case "${EXPECT_FP}" in *[!0-9a-f]*) printf 'a2a-doctor: --fingerprint precisa ser sha256:<64 hex>\n' >&2; exit 3 ;; esac
  [ "${#EXPECT_FP}" -eq 64 ] || { printf 'a2a-doctor: --fingerprint precisa ter 64 hex\n' >&2; exit 3; }
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../.." && pwd))"
GATE="${A2A_VERIFY:-${HERE}/a2a-verify.sh}"
INVITE_MOTOR="${A2A_INVITE:-${HERE}/a2a-invite.sh}"
TRUST_CHECK="${A2A_TRUST_CHECK:-${ROOT}/.claude/validation/trust-topology-check.sh}"
VALIDATOR="${A2A_MEMBERS_VALIDATE:-${ROOT}/.claude/validation/members-validate.sh}"
[ -n "${DIR}" ] || DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/onion/a2a"
[ -n "${MEMBERS}" ] || { [ -f "${ROOT}/docs/evolution/federation/members.yaml" ] && MEMBERS="${ROOT}/docs/evolution/federation/members.yaml"; }
[ -n "${JWKS}" ] || JWKS="${A2A_JWKS_DIR:-${HERE}/jwks}"
[ -n "${TOKEN_FILE}" ] || TOKEN_FILE="${DIR}/bridge-token"
TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

RES="${TMP}/res.tsv"; : > "${RES}"
put() { # id status critical causa proximo — tab e quebra de linha viram espaço (o TSV é a fonte)
  local c="${4//$'\t'/ }" n="${5//$'\t'/ }"; c="${c//$'\n'/ }"; n="${n//$'\n'/ }"
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${c}" "${n}" >> "${RES}"
}
have_yaml() { command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; }
# modo do ALVO (segue symlink): stat GNU (-c) ou BSD (-f); vazio quando nenhum responde (→ não medido)
_mode() { stat -L -c '%a' "$1" 2>/dev/null || stat -L -f '%Lp' "$1" 2>/dev/null; }
fp_of_pub() { openssl pkey -pubin -in "$1" -outform DER 2>/dev/null | openssl dgst -sha256 | awk '{print $NF}'; }
# RSA se reconhece pelo módulo: o openssl 3 imprime "Private-Key: (N bit…)" para RSA E para EC (o spike
# aprovou chave EC na 1ª versão por ler essa linha; o gate, só RS256, a recusaria). → "<bits>" ou "nao-rsa"
# Na privada, os bits se medem sobre a PÚBLICA derivada (-pubout): o texto da privada traz os expoentes
# secretos, e passá-lo por here-string o poria num arquivo temporário no bash 3.2 (achado do refutador).
rsa_bits() {  # $1 = arquivo · $2 = "pub" ou "priv"
  local t; if [ "$2" = pub ]; then t="$(openssl pkey -pubin -in "$1" -noout -text 2>/dev/null)"
  else t="$(openssl pkey -in "$1" -pubout 2>/dev/null | openssl pkey -pubin -noout -text 2>/dev/null)"; fi
  [ -n "${t}" ] || { echo ilegivel; return; }
  if grep -qiE '^(modulus|Modulus):' <<< "${t}"; then sed -n '1s/.*(\([0-9]*\) bit.*/\1/p' <<< "${t}"; else echo nao-rsa; fi
}

# registro: found/keys/sends_to/source, sem imprimir nada sensível (o registro não guarda segredo)
REG_ERR=""; FOUND=""; KEYS=""; SENDS=""; SRC=""
if [ -n "${MEMBERS}" ] && [ -f "${MEMBERS}" ] && have_yaml; then
  INFO="$(python3 - "${MEMBERS}" "${MEMBER}" <<'PY'
import sys, yaml
try: ms = (yaml.safe_load(open(sys.argv[1])) or {}).get('members') or []
except Exception: print("err=unparseable"); sys.exit(0)
src = [m.get('id') for m in ms if isinstance(m, dict) and m.get('kind') == 'source']
me = [m for m in ms if isinstance(m, dict) and m.get('id') == sys.argv[2]]
print("found=" + ("1" if me else "0"))
a = (me[0].get('a2a') or {}) if me else {}
a = a if isinstance(a, dict) else {}
print("keys=" + ",".join(str(k) for k in (a.get('keys') or [])))
print("sends_to=" + str(a.get('sends_to') or ''))
print("source=" + (str(src[0] or '') if src else ''))
PY
)"
  REG_ERR="$(sed -n 's/^err=//p' <<< "${INFO}")"
  FOUND="$(sed -n 's/^found=//p' <<< "${INFO}")"; KEYS="$(sed -n 's/^keys=//p' <<< "${INFO}")"
  SENDS="$(sed -n 's/^sends_to=//p' <<< "${INFO}")"; SRC="$(sed -n 's/^source=//p' <<< "${INFO}")"
fi
REG_OK=""; [ -n "${MEMBERS}" ] && [ -f "${MEMBERS}" ] && have_yaml && [ -z "${REG_ERR}" ] && REG_OK=1
[ -n "${RECEIVER}" ] || RECEIVER="${SENDS:-${SRC}}"
key_pinned() { case ",${KEYS}," in *",$1,"*) return 0 ;; esac; return 1; }   # sem pipe (pipefail + grep -q é corrida)

# ── (f) relógio confiável: os MESMOS sinais do gate, separando "disse não" (rc 1) de "sem sinal" (rc 2)
# O gate colapsa os dois em clock-untrusted (veto: certo para um gate). O doctor os separa porque o
# próximo passo é diferente: ligar o NTP não é instalar ou atestar uma fonte.
# SAC-150 N8: a MEDIÇÃO vem antes do atestado, como no gate — um A2A_CLOCK_TRUST=attested não cala uma fonte
# que disse "não sincronizado" (o env só aperta). O atestado vale só onde nada mediu.
check_clock() {
  local ok="" sig="" no="" v t r
  if :; then
    if command -v timedatectl >/dev/null 2>&1; then
      v="$(timedatectl show -p NTPSynchronized --value 2>/dev/null)"
      case "${v}" in yes) ok=1; sig="timedatectl NTPSynchronized=yes" ;; no) no="timedatectl NTPSynchronized=no" ;; esac
    fi
    if [ -z "${ok}" ] && command -v chronyc >/dev/null 2>&1; then
      t="$(chronyc tracking 2>/dev/null)"
      if grep -qE '^Leap status.*(Normal|Insert second|Delete second)' <<< "${t}"; then ok=1; sig="chronyc Leap status sincronizado"
      elif grep -q '^Leap status.*Not synchronised' <<< "${t}"; then no="${no:+${no}; }chronyc Leap status Not synchronised"; fi
    fi
    if [ -z "${ok}" ] && command -v ntpstat >/dev/null 2>&1; then
      ntpstat >/dev/null 2>&1; r=$?
      if [ "${r}" -eq 0 ]; then ok=1; sig="ntpstat sincronizado"; elif [ "${r}" -eq 1 ]; then no="${no:+${no}; }ntpstat não sincronizado"; fi
    fi
  fi
  if [ -z "${ok}" ] && [ -z "${no}" ] && [ "${A2A_CLOCK_TRUST:-}" = "attested" ]; then
    ok=1; sig="A2A_CLOCK_TRUST=attested (atestado do operador: declaração, não medição; nenhuma fonte mediu dessincronia)"
  fi
  if [ -n "${ok}" ]; then CLOCK=ok; put f ok 1 "${sig}" "—"
  elif [ -n "${no}" ]; then CLOCK=no
    put f falha 1 "a fonte de tempo DISSE que não está sincronizada (${no}); o gate veta clock-untrusted, e o atestado A2A_CLOCK_TRUST não vence a medição" \
      "ligue o NTP (timedatectl set-ntp true, ou chronyd) e espere sincronizar"
  else CLOCK=unk
    put f nao-medido 1 "nenhum sinal de relógio (timedatectl, chronyc e ntpstat ausentes ou mudos, e sem A2A_CLOCK_TRUST); o gate veta clock-untrusted" \
      "instale chrony ou systemd-timesyncd; num host sem nenhum, o operador atesta com A2A_CLOCK_TRUST=attested por decisão declarada"
  fi
}

# ── (g) endpoint alcançável: só o http_code, timeout curto, sem autenticação (alcance, não autorização)
check_endpoint() {
  if [ -z "${ENDPOINT}" ]; then put g nao-medido 0 "endpoint não informado" "passe --endpoint <url do receptor>"; return; fi
  command -v curl >/dev/null 2>&1 || { put g nao-medido 1 "curl ausente: não sei medir o alcance" "instale curl"; return; }
  case "${ENDPOINT}" in *://*@*) put g falha 1 "a URL do endpoint carrega credencial embutida (user:token@)" "tire a credencial da URL: ela vaza em /proc e no histórico"; return ;; esac
  # ROTA DO RECEPTOR (F3): o bridge do core atende `/a2a` (o core) e `/a2a/<receptor>` (um hub). A rota
  # decide o receptor, e o convite e o aud têm de casar com ela: endpoint de outro receptor sai
  # convite-de-outro-receptor (401) ou claim-aud-mismatch, com a chave e o convite certos.
  local upath="${ENDPOINT#*://}"; upath="/${upath#*/}"; [ "${upath}" = "/${ENDPOINT#*://}" ] && upath="/"
  # a barra final NÃO se tira, nem a caixa se normaliza: o bridge (Hono, estrito) responde 404 a
  # `/a2a/<hub>/` e a `/A2A/<hub>` (medido pelo refutador da F3), e o doctor julga a rota que o bridge vê
  upath="${upath%%[?#]*}"
  local route_note=""
  if [ -n "${RECEIVER}" ]; then
    case "${upath}" in
      */a2a/"${RECEIVER}") ;;
      */a2a)
        if [ -n "${SRC}" ] && [ "${RECEIVER}" != "${SRC}" ]; then
          put g falha 1 "o endpoint é a rota do receptor padrão (/a2a = ${SRC}), mas o receptor é ${RECEIVER}: o bridge recusaria o convite (convite-de-outro-receptor)" "use a rota do receptor: .../a2a/${RECEIVER}"; return
        fi
        [ -n "${SRC}" ] || route_note="; /a2a é o receptor padrão do bridge (o core): se ${RECEIVER} é um hub, use .../a2a/${RECEIVER}" ;;
      */a2a/|*/a2a/*[!A-Za-z0-9._-]*)
        put g falha 1 "rota malformada (${upath}): o bridge só atende /a2a e /a2a/<receptor>, sem barra final nem segmento a mais, e responde 404" "use a rota do receptor: .../a2a/${RECEIVER}"; return ;;
      */a2a/*)
        put g falha 1 "o endpoint é a rota de outro receptor (${upath##*/}), não de ${RECEIVER}" "use a rota do receptor: .../a2a/${RECEIVER}"; return ;;
      *)
        put g falha 1 "o caminho (${upath}) não é uma rota do /a2a do bridge (só /a2a e /a2a/<receptor>, em minúsculas): o bridge responde 404" "use a rota do receptor: .../a2a/${RECEIVER}"; return ;;
    esac
  fi
  # Sonda por POST sem credencial e corpo vazio: numa rota que existe o guard do bridge responde 401 (o
  # alcance), e numa que não existe o roteador responde 404. GET não separa os dois (o /a2a não tem GET).
  local code; code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 4 --proto '=http,https' \
    -X POST -H 'Content-Type: application/json' --data '{}' "${ENDPOINT}" 2>/dev/null)"; code="${code:-000}"
  case "${code}" in
    000) put g falha 1 "endpoint inalcançável (conexão recusada, DNS ou timeout de 4 s)" "confira URL, DNS, firewall e se o serviço do receptor está de pé" ;;
    404) put g falha 1 "o servidor respondeu 404: esta rota não existe nele (o bridge do core atende POST em /a2a e /a2a/<receptor>)" "confira o caminho do endpoint e se o bridge servido já tem o receptor múltiplo" ;;
    5*)  put g falha 1 "endpoint respondeu HTTP ${code} (servidor de pé, mas quebrado)" "o receptor precisa olhar o log do serviço" ;;
    *)   put g ok 1 "endpoint alcançável (HTTP ${code}: alcance, não autorização)${route_note}" "—" ;;
  esac
}

# ── (i) convite por membro no arquivo do bridge: o guard dele aceitaria o bearer deste membro? ──────
# Sonda pelo a2a-invite.sh list (as regras do bridge, sem ler token): pelo hash do descritor, quando há
# --invite; senão, por todas as entradas do membro. Sem --invites: não medida e NÃO crítica, declarado.
check_invites() {
  if [ -z "${INVITES}" ]; then
    put i nao-medido 0 "arquivo de convites não informado: o convite por membro não foi conferido" \
      "passe --invites <o arquivo de convites do seu bridge (A2A_INVITES_FILE)>, rodando como a conta do serviço do bridge"; return
  fi
  [ -f "${INVITE_MOTOR}" ] || { put i nao-medido 1 "a2a-invite.sh ausente: não sei julgar o arquivo de convites" "rode de uma instalação com o motor"; return; }
  command -v jq >/dev/null 2>&1 || { put i nao-medido 1 "jq ausente" "instale jq"; return; }
  if [ -n "${INVITE}" ] && [ ! -f "${INVITE}" ]; then put i falha 1 "o descritor do convite não é um arquivo regular no caminho informado" "passe --invite com o <token>.invite.json que o create gerou"; return; fi
  local out lrc=0 st det oks bad
  out="$(bash "${INVITE_MOTOR}" list --file "${INVITES}" --member "${MEMBER}" ${RECEIVER:+--receiver "${RECEIVER}"} \
        ${INVITE:+--invite "${INVITE}"} --json 2>/dev/null)" || lrc=$?
  st="$(jq -r '.state // empty' <<< "${out}" 2>/dev/null)"; det="$(jq -r '.detail // empty' <<< "${out}" 2>/dev/null)"
  case "${st}" in
    unreadable) put i nao-medido 1 "esta conta não lê o arquivo de convites (ele é 0600 da conta do serviço)" "rode o doctor como a conta do serviço do bridge (sudo -u <conta>)" ;;
    unmeasured) put i nao-medido 1 "não consegui interpretar o arquivo de convites (${det}); o bridge pode estar lendo, não sei" "confira o arquivo à mão" ;;
    absent) put i falha 1 "o arquivo de convites não existe: o bridge vê ZERO convites de membro" "crie o convite (/meta:federation-a2a, trilha 2): a2a-invite.sh create ${MEMBER} …" ;;
    error) put i falha 1 "o bridge recusa o arquivo de convites INTEIRO (${det}): nenhum convite de membro autentica (convites-indisponiveis)" "rode a2a-invite.sh check --file <arquivo> e conserte dono, modo, diretório ou JSON" ;;
    ok)
      oks="$(jq -r '[.probe[]? | select(.bridge=="ok") | .id] | join(", ")' <<< "${out}" 2>/dev/null)"
      bad="$(jq -r '[.probe[]? | select(.bridge!="ok") | "\(.id) \(.bridge)"] | join("; ")' <<< "${out}" 2>/dev/null)"
      if [ -n "${oks}" ]; then put i ok 1 "o guard do bridge aceitaria o convite de ${MEMBER} para ${RECEIVER:-o receptor} (${oks})" "—"
      elif [ -n "${bad}" ]; then
        local nx="crie um convite novo (a2a-invite.sh create ${MEMBER} …) e entregue o token fora de banda"
        case "${bad}" in *convite-de-outro-membro*|*convite-de-outro-receptor*) nx="o token deste descritor é de outro membro ou receptor: confira o descritor, e crie o convite certo" ;; *credencial-desconhecida*) nx="o convite do descritor não está neste arquivo: confira se é o arquivo que o bridge lê (A2A_INVITES_FILE)" ;; esac
        put i falha 1 "nenhum convite de ${MEMBER} passaria no guard do bridge: ${bad}" "${nx}"
      else put i falha 1 "nenhum convite de ${MEMBER} no arquivo" "crie o convite (/meta:federation-a2a, trilha 2): a2a-invite.sh create ${MEMBER} …"; fi ;;
    *) put i nao-medido 1 "o a2a-invite.sh não devolveu veredito legível (rc ${lrc})" "rode a2a-invite.sh check à mão e leia a saída" ;;
  esac
}

# ══════════════════════════════════════ LADO DO MEMBRO ══════════════════════════════════════════
side_member() {
  local priv="" n
  # resolução do kid: --kid; senão o único <member>-N.key.pem do dir; entre vários, o único pinado
  if [ -z "${KID}" ] && [ -d "${DIR}" ]; then
    # glob do shell, não `find -printf` (GNU-only: no BSD a lista viria vazia e (a) acusaria a causa errada)
    _cands=()
    for _f in "${DIR}/${MEMBER}"-*.key.pem; do
      [ -e "${_f}" ] || continue
      _k="${_f##*/}"; _k="${_k%.key.pem}"
      case "${_k#"${MEMBER}"-}" in ''|0*|*[!0-9]*) continue ;; esac
      _cands+=("${_k}")
    done
    if [ "${#_cands[@]}" -eq 1 ]; then KID="${_cands[0]}"
    elif [ "${#_cands[@]}" -gt 1 ] && [ -n "${KEYS}" ]; then
      n=0; for k in "${_cands[@]}"; do key_pinned "${k}" && { KID="${k}"; n=$((n+1)); }; done
      [ "${n}" -eq 1 ] || KID=""
    fi
    KID_AMBIG=""; [ -z "${KID}" ] && [ "${#_cands[@]}" -gt 1 ] && KID_AMBIG="${#_cands[@]}"
  fi
  [ -n "${KID}" ] && priv="${DIR}/${KID}.key.pem"

  # (a) chave privada RSA legível, de tamanho que o receptor aceita
  KEY_OK=""
  if [ -n "${KID_AMBIG:-}" ]; then
    put a nao-medido 1 "há ${KID_AMBIG} chaves de ${MEMBER} em ${DIR} e não sei qual é a vigente" "passe --kid <kid>"
  elif [ -z "${priv}" ] || [ ! -e "${priv}" ]; then
    put a falha 1 "chave privada ausente em ${DIR} (esperado ${KID:-${MEMBER}-N}.key.pem)" \
      "gere o par: a2a-keygen.sh --member ${MEMBER} (e mande ao receptor SÓ a pública)"
  elif ! command -v openssl >/dev/null 2>&1; then
    put a nao-medido 1 "openssl ausente: não sei ler a chave" "instale openssl e rode o doctor de novo"
  else
    local bits; bits="$(rsa_bits "${priv}" priv)"
    case "${bits}" in
      ilegivel) put a falha 1 "o arquivo existe mas não é chave privada legível (corrompido, cifrado ou outra coisa)" "gere um par novo com a2a-keygen.sh --member ${MEMBER} --n <N+1> e peça o pino da nova pública" ;;
      nao-rsa)  put a falha 1 "chave não-RSA: o gate só aceita RS256" "gere um par RSA com a2a-keygen.sh" ;;
      *) if [ "${bits:-0}" -ge 2048 ]; then KEY_OK=1; put a ok 1 "chave privada RSA ${bits} bits presente e legível (kid ${KID})" "—"
         else put a falha 1 "chave RSA de ${bits:-?} bits: curta demais" "gere um par novo com a2a-keygen.sh (3072 bits)"; fi ;;
    esac
  fi

  # (b) permissão: privada sem bit de grupo/outros e diretório 0700
  if [ -z "${priv}" ] || [ ! -e "${priv}" ]; then
    put b nao-medido 1 "sem chave não há permissão a medir (depende de a)" "resolva (a) primeiro"
  else
    local fm dm bad=""
    fm="$(_mode "${priv}")"; dm="$(_mode "${DIR}")"
    if [ -z "${fm}" ] || [ -z "${dm}" ]; then
      put b nao-medido 1 "stat não devolveu o modo (nem GNU nem BSD)" "confira à mão: ls -ldL <dir> <dir>/<kid>.key.pem"
    else
      [ $(( 8#${fm} & 8#077 )) -eq 0 ] || bad="${KID}.key.pem está ${fm} (grupo/outros leem a chave)"
      [ $(( 8#${dm} & 8#077 )) -eq 0 ] || bad="${bad:+${bad}; }diretório está ${dm} (grupo/outros listam ou trocam a chave)"
      if [ -n "${bad}" ]; then
        put b falha 1 "${bad}" "chmod 0700 <dir> e chmod 0600 na privada; se a máquina tem outras contas, trate a chave como VAZADA: gere a N+1 e peça a revogação da antiga"
      else put b ok 1 "privada ${fm} · diretório ${dm}" "—"; fi
    fi
  fi

  # (c) impressão SHA-256 da pública (DER SPKI), para conferir com o receptor fora de banda
  FP=""
  if [ -z "${KEY_OK}" ]; then put c nao-medido 1 "sem chave legível não há impressão (depende de a)" "resolva (a) primeiro"
  else
    FP="$(openssl pkey -in "${priv}" -pubout -outform DER 2>/dev/null | openssl dgst -sha256 | awk '{print $NF}')"
    if [ "${#FP}" -eq 64 ]; then put c ok 1 "sha256:${FP}" "confira esta impressão com o receptor por canal FORA de banda antes do pino"
    else FP=""; put c nao-medido 1 "openssl não devolveu a impressão" "rode: openssl pkey -in <privada> -pubout -outform DER | openssl dgst -sha256"; fi
  fi

  # (d) kid pinado no registro + jwks/<kid>.pem com a MESMA impressão
  if [ -z "${MEMBERS}" ] || [ ! -f "${MEMBERS}" ]; then
    put d nao-medido 1 "o registro do receptor não está nesta máquina; o pino vive no repo dele" \
      "peça ao receptor que rode este doctor com --side receiver --member ${MEMBER} (ou passe --members com uma cópia ATUAL do registro)"
  elif ! have_yaml; then put d nao-medido 1 "python3 com PyYAML ausente: não sei ler o registro (o gate também veta sem eles)" "instale python3-yaml"
  elif [ -n "${REG_ERR}" ]; then put d falha 1 "registro ilegível (YAML quebrado)" "corrija o YAML; o gate também veta com ele assim"
  elif [ "${FOUND}" != 1 ]; then put d falha 1 "membro '${MEMBER}' não está no registro" "o receptor registra o membro (/meta:federation-member register)"
  elif [ -z "${KID}" ]; then put d nao-medido 1 "não sei qual kid é o desta chave" "resolva (a)"
  elif ! key_pinned "${KID}"; then
    # o gate julga o .pem ANTES do dono: sem o .pem o veto é unknown-kid, com ele é kid-not-owned-by-from
    # (medido contra o bridge local na F5, 2026-10-15: antes do pino o envio real voltou unknown-kid)
    local veto=unknown-kid; [ -f "${JWKS}/${KID}.pem" ] && veto=kid-not-owned-by-from
    put d falha 1 "kid '${KID}' NÃO está pinado em a2a.keys de ${MEMBER} (${KEYS:-vazio}); o gate veta ${veto}" \
      "mande a pública ao receptor e peça o pino (/meta:federation-a2a, trilha 2), conferindo a impressão de (c)"
  elif [ ! -f "${JWKS}/${KID}.pem" ]; then
    put d falha 1 "kid '${KID}' pinado no registro, mas jwks/${KID}.pem ausente; o gate veta unknown-kid" "o receptor grava a pública em jwks/${KID}.pem (impressão de c)"
  elif [ -z "${FP}" ]; then put d nao-medido 1 "kid pinado, mas sem impressão local para comparar (depende de c)" "resolva (a) e (c)"
  else
    local pfp; pfp="$(fp_of_pub "${JWKS}/${KID}.pem")"
    if [ "${pfp}" = "${FP}" ]; then put d ok 1 "kid '${KID}' pinado e jwks/${KID}.pem tem a mesma impressão" "—"
    else put d falha 1 "jwks/${KID}.pem tem impressão ${pfp:0:16}… diferente da local ${FP:0:16}… (chave trocada ou pino velho); o gate veta bad-signature" \
      "peça o pino da pública atual (impressão de c) ou volte a usar a privada pinada"; fi
  fi

  # (e) credencial do canal: o bearer existe, é privado e não é vazio (o conteúdo nunca é impresso);
  #     e, se houver o convite por membro (F2), do membro certo, não vencido e não revogado
  local ebad="" eok=""
  if [ ! -f "${TOKEN_FILE}" ]; then ebad="token do canal ausente em ${TOKEN_FILE}"
  else
    local tm; tm="$(_mode "${TOKEN_FILE}")"
    if [ -z "${tm}" ]; then ebad="não consegui ler o modo do token"
    elif [ $(( 8#${tm} & 8#077 )) -ne 0 ]; then ebad="o token está ${tm} (grupo/outros leem o bearer)"
    elif [ ! -s "${TOKEN_FILE}" ]; then ebad="o arquivo do token está vazio"
    else eok="token do canal presente, modo ${tm}"; fi
  fi
  if [ -z "${ebad}" ] && [ -n "${INVITE}" ]; then
    # o descritor se julga pelo a2a-invite.sh inspect, com as MESMAS regras do bridge (forma ISO com
    # fuso medida contra o Date.parse do V8; revoked só como false literal). Sem `date -d` (GNU-only).
    if [ ! -f "${INVITE}" ]; then ebad="convite não encontrado no caminho informado"
    elif [ ! -f "${INVITE_MOTOR}" ]; then put e nao-medido 1 "a2a-invite.sh ausente: não sei julgar o convite" "use o pacote de entrada com os quatro motores"; eok=""; ebad="-"
    elif ! command -v jq >/dev/null 2>&1; then put e nao-medido 1 "jq ausente: não sei ler o veredito do convite" "instale jq"; eok=""; ebad="-"
    else
      local iout irc=0 ist iwhy
      # --token-file: o motor confere, no processo dele, que o sha256 do token é o do descritor (só a
      # comparação sai; o doctor não lê o token). Sem isso, um token qualquer com um descritor válido era "ok".
      iout="$(bash "${INVITE_MOTOR}" inspect --invite "${INVITE}" --member "${MEMBER}" ${RECEIVER:+--receiver "${RECEIVER}"} --token-file "${TOKEN_FILE}" --json 2>/dev/null)" || irc=$?
      ist="$(jq -r '.state // empty' <<< "${iout}" 2>/dev/null)"; iwhy="$(jq -r '.why // empty' <<< "${iout}" 2>/dev/null)"
      if [ "${irc}" -eq 0 ] && [ "${ist}" = ativo ]; then eok="${eok}; ${iwhy} (a revogação só se mede no receptor)"
      elif [ "${irc}" -eq 1 ] && [ -n "${ist}" ]; then ebad="${iwhy}"
      else put e nao-medido 1 "o a2a-invite.sh não devolveu veredito legível do convite (rc ${irc})" "rode a2a-invite.sh inspect à mão"; eok=""; ebad="-"; fi
    fi
  fi
  if [ "${ebad}" = "-" ]; then :
  elif [ -n "${ebad}" ]; then
    put e falha 1 "${ebad}" "peça ao receptor um convite novo (ele entrega o bearer fora de banda); grave-o com umask 077 em ${TOKEN_FILE}, nunca colado no chat nem em argv"
  else put e ok 1 "${eok}" "—"; fi

  check_clock
  check_endpoint

  # (h) envio sintético contra o gate LOCAL em --dry-run, num repo temporário (o --dry-run do gate
  #     CONSOME o jti, nó C_DRY_RUN_DO_GATE_CONSOME_O_JTI: por isso o envelope é sintético e o estado é
  #     descartável). Relógio ISOLADO em attested: ele já foi julgado em (f), e o do gate local não é o
  #     do receptor. Assim (h) mede o que o membro controla: assinatura, kid, topologia e forma.
  if [ -z "${KEY_OK}" ]; then put h nao-medido 1 "sem chave não há o que assinar (depende de a)" "resolva (a)"
  elif [ ! -f "${GATE}" ]; then put h nao-medido 1 "o gate a2a-verify.sh não está nesta instalação" "peça ao receptor o lado dele (--side receiver), ou rode de uma instalação com o gate"
  elif [ -z "${REG_OK}" ] || [ -z "${KID}" ]; then put h nao-medido 1 "sem registro ou sem kid o gate nem chega à assinatura (depende de d)" "resolva (d)"
  elif [ -z "${RECEIVER}" ]; then put h nao-medido 1 "não sei para quem enviar (sem --receiver, sem a2a.sends_to, sem membro source)" "passe --receiver"
  elif ! command -v jq >/dev/null 2>&1; then put h nao-medido 1 "jq ausente" "instale jq"
  else
    local now jti bsha hd pl sig out grc reason layer nx
    b64u() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
    now="$(date +%s)"; jti="doctor-${now}-$$-$(openssl rand -hex 4)"
    bsha="$(printf '' | openssl dgst -sha256 | awk '{print $NF}')"
    hd="$(jq -cn --arg k "${KID}" '{alg:"RS256",kid:$k}' | b64u)"   # jq, nunca printf: o kid não é JSON-seguro por construção
    pl="$(jq -cn --arg i "${MEMBER}" --arg a "${RECEIVER}" --arg j "${jti}" --arg b "${bsha}" --argjson t "${now}" \
          '{iss:$i,aud:$a,iat:$t,exp:($t+300),jti:$j,body_sha256:$b}' | b64u)"
    sig="$(printf '%s' "${hd}.${pl}" | openssl dgst -sha256 -sign "${priv}" 2>/dev/null | b64u)"
    mkdir -p "${TMP}/repo/docs/evolution/federation"; cp "${MEMBERS}" "${TMP}/repo/docs/evolution/federation/members.yaml"
    jq -cn --arg j "${hd}.${pl}.${sig}" --arg f "${MEMBER}" --arg t "${RECEIVER}" \
       '{jws:$j,signal:{id:"doctor-synthetic",direction:"upstream",from:$f,to:$t,kind:"signal",classification:"internal"}}' > "${TMP}/env.json"
    out="$(A2A_CLOCK_TRUST=attested A2A_JWKS_DIR="${JWKS}" bash "${GATE}" --receiver "${RECEIVER}" --repo "${TMP}/repo" --dry-run --envelope "${TMP}/env.json" 2>/dev/null)"; grc=$?
    reason="$(jq -r '.reason // empty' <<< "${out}" 2>/dev/null)"; layer="$(jq -r '.layer_failed // empty' <<< "${out}" 2>/dev/null)"
    if [ "${grc}" -eq 0 ] && [ "$(jq -r '.verified' <<< "${out}" 2>/dev/null)" = true ]; then
      put h ok 1 "o gate local aceitou o envio sintético (verified, gated, dry-run; relógio julgado em f)" "—"
    elif [ "${grc}" -eq 1 ] && [ -n "${reason}" ]; then
      case "${reason}" in
        trust-denied) nx="a topologia não deixa ${MEMBER} falar com ${RECEIVER}: confira trust e kind no registro" ;;
        kid-not-owned-by-from:*|unknown-kid:*) nx="o pino do kid está errado: ver (d)" ;;
        bad-kid|jws-missing-kid) nx="o kid fora da forma do gate (1–160 de [A-Za-z0-9._-], sem '.' no início): gere outro com o a2a-keygen" ;;
        bad-signature) nx="a privada local não é a pinada: ver (c) e (d)" ;;
        tooling-absent:*) nx="instale ${reason#tooling-absent:}" ;;
        receiver-unknown) nx="${RECEIVER} não está no registro: confira o --receiver (ou o a2a.sends_to)" ;;
        receiver-not-a-receiver:*) nx="${RECEIVER} não recebe sinais (só role source ou hub, nunca porta): mande para o seu hub ou para o core" ;;
        *) nx="leia a camada '${layer}' do gate a2a-verify.sh" ;;
      esac
      put h falha 1 "o gate local VETOU: ${reason} (camada ${layer})" "${nx}"
    else put h nao-medido 1 "o gate não devolveu veredito legível (rc ${grc})" "rode o gate à mão com --dry-run e leia o stderr"; fi
  fi
}

# ═════════════════════════════════════ LADO DO RECEPTOR ═════════════════════════════════════════
side_receiver() {
  # (r) registro presente e válido pelo MESMO validador do gate do lint (REGRA 66)
  if [ -z "${MEMBERS}" ] || [ ! -f "${MEMBERS}" ]; then
    put r nao-medido 1 "registro members.yaml não encontrado" "rode no repo do receptor ou passe --members"
  elif ! have_yaml; then put r nao-medido 1 "python3 com PyYAML ausente: não sei ler o registro" "instale python3-yaml"
  elif [ -n "${REG_ERR}" ]; then put r falha 1 "registro ilegível (YAML quebrado)" "corrija o YAML"
  elif [ "${FOUND}" != 1 ]; then put r falha 1 "membro '${MEMBER}' não está no registro" "registre-o: /meta:federation-member register"
  elif [ ! -f "${VALIDATOR}" ]; then put r nao-medido 1 "members-validate.sh ausente: não sei validar o registro" "rode de uma instalação com o validador"
  else
    local vout vrc=0; vout="$(bash "${VALIDATOR}" "${MEMBERS}" --jwks "${JWKS}" 2>&1)" || vrc=$?
    case "${vrc}" in
      0) put r ok 1 "registro válido e ${MEMBER} presente" "—" ;;
      1) put r falha 1 "registro inválido: $(grep -m3 '∟' <<< "${vout}" | sed 's/^ *∟ *//' | tr '\n' ';' | cut -c1-220)" "corrija o registro antes de pinar (o lint barra o mesmo erro pela REGRA 66)" ;;
      *) put r nao-medido 1 "o validador não pôde medir (rc ${vrc})" "rode bash members-validate.sh à mão e leia a saída" ;;
    esac
  fi

  # (d) kid(s) pinado(s) e pública RSA legível e de tamanho aceito em jwks/<kid>.pem
  local kids=() k bits okk="" badk=""
  if [ -n "${KID}" ]; then kids=("${KID}"); elif [ -n "${KEYS}" ]; then IFS=',' read -ra kids <<< "${KEYS}"; fi
  if [ -z "${REG_OK}" ] || [ "${FOUND}" != 1 ]; then put d nao-medido 1 "sem registro legível com o membro não há pino a medir (depende de r)" "resolva (r)"
  elif [ "${#kids[@]}" -eq 0 ]; then put d falha 1 "${MEMBER} não tem nenhum kid em a2a.keys; todo envio dele veta unknown-kid (sem o .pem no JWKS) ou kid-not-owned-by-from (com o .pem)" "pine a pública que o membro mandou (/meta:federation-a2a, trilha 2)"
  elif ! command -v openssl >/dev/null 2>&1; then put d nao-medido 1 "openssl ausente: não sei ler a pública" "instale openssl"
  else
    for k in "${kids[@]}"; do
      if ! key_pinned "${k}"; then badk="${badk:+${badk}; }kid ${k} não está em a2a.keys de ${MEMBER}"
      elif [ ! -f "${JWKS}/${k}.pem" ]; then badk="${badk:+${badk}; }jwks/${k}.pem ausente (o gate veta unknown-kid)"
      else
        bits="$(rsa_bits "${JWKS}/${k}.pem" pub)"
        case "${bits}" in
          ilegivel) badk="${badk:+${badk}; }jwks/${k}.pem não é pública legível" ;;
          nao-rsa)  badk="${badk:+${badk}; }jwks/${k}.pem não é RSA (o gate só aceita RS256)" ;;
          *) if [ "${bits:-0}" -ge 2048 ]; then okk="${okk:+${okk}, }${k} (RSA ${bits})"; else badk="${badk:+${badk}; }jwks/${k}.pem tem ${bits} bits"; fi ;;
        esac
      fi
    done
    if [ -n "${badk}" ]; then put d falha 1 "${badk}" "pine de novo a pública que o membro mandou, conferindo a impressão"
    else put d ok 1 "pinado(s): ${okk}" "—"; fi
  fi

  # (c) impressão conferida contra a que o membro mandou por canal fora de banda
  if [ -z "${EXPECT_FP}" ]; then
    put c nao-medido 0 "impressão do membro não informada: o pino não foi conferido contra o que ele gerou" "passe --fingerprint sha256:<hex> com a impressão que o membro leu do keygen ou do doctor dele"
  elif [ "${#kids[@]}" -eq 0 ] || ! command -v openssl >/dev/null 2>&1; then
    put c nao-medido 1 "sem kid pinado (ou sem openssl) não há impressão a comparar" "resolva (d)"
  else
    local hit="" got=""
    for k in "${kids[@]}"; do [ -f "${JWKS}/${k}.pem" ] || continue; got="$(fp_of_pub "${JWKS}/${k}.pem")"; [ "${got}" = "${EXPECT_FP}" ] && hit="${k}"; done
    if [ -n "${hit}" ]; then put c ok 1 "jwks/${hit}.pem tem a impressão que o membro mandou" "—"
    else put c falha 1 "nenhuma pública pinada de ${MEMBER} tem a impressão ${EXPECT_FP:0:16}… que o membro mandou (chave trocada no caminho, ou pino de outra chave)" \
      "NÃO use este pino: peça ao membro a pública de novo e confira a impressão por outro canal"; fi
  fi

  # (t) topologia: o registro deixa o membro falar com o receptor (o mesmo trust-check da camada 1 do gate)
  if [ -z "${REG_OK}" ] || [ "${FOUND}" != 1 ]; then put t nao-medido 1 "sem registro com o membro não há topologia a medir (depende de r)" "resolva (r)"
  elif [ -z "${RECEIVER}" ]; then put t nao-medido 1 "não sei qual é o receptor (sem --receiver, sem a2a.sends_to, sem membro source)" "passe --receiver"
  elif [ ! -f "${TRUST_CHECK}" ]; then put t nao-medido 1 "trust-topology-check.sh ausente" "rode de uma instalação com o validador de topologia"
  else
    mkdir -p "${TMP}/trepo/docs/evolution/federation"; cp "${MEMBERS}" "${TMP}/trepo/docs/evolution/federation/members.yaml"
    local trc=0; bash "${TRUST_CHECK}" --from "${MEMBER}" --to "${RECEIVER}" --action relay --repo "${TMP}/trepo" --dry-run >/dev/null 2>&1 || trc=$?
    case "${trc}" in
      0) put t ok 1 "a topologia autoriza ${MEMBER} → ${RECEIVER} (relay)" "—" ;;
      1) put t falha 1 "a topologia NÃO autoriza ${MEMBER} → ${RECEIVER}; o gate veta trust-denied" "confira trust, role e kind de ${MEMBER} no registro" ;;
      *) put t nao-medido 1 "o validador de topologia não pôde medir (rc ${trc})" "rode trust-topology-check.sh à mão e leia o stderr" ;;
    esac
  fi

  check_invites
  check_clock
  check_endpoint
}

CLOCK=""
if [ "${SIDE}" = member ]; then side_member; else side_receiver; fi

RC="$(classify "${RES}")"
label() { case "$1" in a) echo "chave privada" ;; b) echo "permissão" ;; c) echo "impressão SHA-256" ;; d) echo "pino no registro" ;;
  e) echo "credencial do canal" ;; f) echo "relógio" ;; g) echo "endpoint" ;; h) echo "envio sintético" ;;
  r) echo "registro" ;; t) echo "topologia de confiança" ;; i) echo "convite por membro" ;; *) echo "$1" ;; esac; }

if [ -n "${JSON}" ]; then
  command -v jq >/dev/null 2>&1 || { printf 'a2a-doctor: --json exige jq\n' >&2; exit 2; }
  jq -Rn --arg m "${MEMBER}" --arg s "${SIDE}" --arg r "${RECEIVER}" --argjson rc "${RC}" '
    [inputs | split("\t") | {id:.[0], status:.[1], critical:(.[2]=="1"), cause:.[3], next:.[4]}] as $c
    | {member:$m, side:$s, receiver:$r, rc:$rc, verdict:(["ok","falha","nao-medido"][$rc]), checks:$c}' < "${RES}"
else
  printf 'a2a-doctor · lado %s · membro %s · receptor %s\n\n' "${SIDE}" "${MEMBER}" "${RECEIVER:-?}"
  while IFS=$'\t' read -r id s crit cause nxt; do
    case "${s}" in ok) ic="✅" ;; falha) ic="❌" ;; *) ic="⚪" ;; esac
    printf '%s (%s) %s%s — %s\n' "${ic}" "${id}" "$(label "${id}")" "$([ "${crit}" = 1 ] || printf ' [não crítica]')" "${cause}"
    [ "${s}" = ok ] || printf '      → próximo passo: %s\n' "${nxt}"
  done < "${RES}"
  nf="$(awk -F'\t' '$2=="falha"' "${RES}" | wc -l)"; nn="$(awk -F'\t' '$2=="nao-medido"' "${RES}" | wc -l)"; no="$(awk -F'\t' '$2=="ok"' "${RES}" | wc -l)"
  printf '\nresumo: %s ok · %s falha · %s não medida(s) → ' "${no}" "${nf}" "${nn}"
  case "${RC}" in 0) if [ "${SIDE}" = receiver ] && [ -z "${EXPECT_FP}" ]; then echo "✅ saudável (rc 0), SEM conferir a impressão do membro: antes de PINAR, rode com --fingerprint"; else echo "✅ saudável (rc 0)"; fi ;; 1) echo "❌ problema (rc 1)" ;; 2) echo "⚪ não pude medir o que é crítico (rc 2): não sei não é saudável" ;; esac
fi
exit "${RC}"
