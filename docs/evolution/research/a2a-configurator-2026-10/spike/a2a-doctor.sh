#!/usr/bin/env bash
# a2a-doctor.sh — SPIKE F0 do configurador A2A (SAC-121, teste S3 / SAC-128). PROTÓTIPO, não produção.
#
# Pergunta que o spike mede: dá para um membro (ou o receptor) diagnosticar a própria fiação A2A com
# CAUSA NOMEADA e PRÓXIMO PASSO concreto, sem rede externa e sem nunca imprimir um segredo?
#
# Moldes: ops/review-gate-health.sh ("não sei" nunca vira saudável; rc 2 = não pude medir) e
# .claude/utils/task-manager/env-check.sh (confere por NOME e permissão; segredo nunca sai).
# O gate julgado é .claude/utils/federation-transport/a2a-verify.sh, e o relógio usa os MESMOS sinais dele.
#
# USO
#   a2a-doctor.sh --member <id> [--dir <dir de chaves>] [--kid <kid>] [--members <members.yaml>]
#                 [--jwks <dir>] [--receiver <id>] [--invite <convite.json>] [--endpoint <url>] [--json]
#
#   --dir      default: ${XDG_CONFIG_HOME:-$HOME/.config}/onion/a2a/<member>; contém private.pem e (opcional) kid
#   --kid      default: conteúdo de <dir>/kid; senão, o único kid de members.yaml[member].a2a.keys
#   --members  default: <raiz do repo>/docs/evolution/federation/members.yaml (se existir)
#   --jwks     default: ${A2A_JWKS_DIR:-<raiz>/.claude/utils/federation-transport/jwks}
#   --receiver default: members.yaml[member].a2a.sends_to; senão, o membro de kind: source
#   convite    JSON {member, expires_at (epoch ou ISO-8601), revoked}
#
# CHECAGENS (cada uma: ok | falha | nao-medido, causa em pt-BR, próximo passo)
#   a chave · b permissao · c impressao · d registro · e convite · f relogio · g endpoint · h envio
#   Críticas sempre: a b c d f h. e/g são críticas SÓ quando o insumo foi informado (sem --invite/--endpoint
#   saem nao-medido NÃO-crítico, declarado na saída — não informado não é saudável, é não perguntado).
#
# EXIT: 0 tudo ok · 1 alguma falha · 2 alguma crítica nao-medido (e nenhuma falha) · 3 uso inválido
set -uo pipefail
umask 077

MEMBER=""; DIR=""; KID=""; MEMBERS=""; JWKS=""; RECEIVER=""; INVITE=""; ENDPOINT=""; JSON=""
usage() { printf 'uso: a2a-doctor.sh --member <id> [--dir d] [--kid k] [--members f] [--jwks d] [--receiver id] [--invite f] [--endpoint url] [--json]\n' >&2; exit 3; }
need() { [ $# -ge 2 ] && [ -n "$2" ] && [ "${2#--}" = "$2" ] || { printf 'a2a-doctor: %s exige valor\n' "$1" >&2; exit 3; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --member)   need "$@"; MEMBER="$2"; shift 2 ;;
    --dir)      need "$@"; DIR="$2"; shift 2 ;;
    --kid)      need "$@"; KID="$2"; shift 2 ;;
    --members)  need "$@"; MEMBERS="$2"; shift 2 ;;
    --jwks)     need "$@"; JWKS="$2"; shift 2 ;;
    --receiver) need "$@"; RECEIVER="$2"; shift 2 ;;
    --invite)   need "$@"; INVITE="$2"; shift 2 ;;
    --endpoint) need "$@"; ENDPOINT="$2"; shift 2 ;;
    --json)     JSON=1; shift ;;
    -h|--help)  usage ;;
    *) printf 'a2a-doctor: argumento desconhecido %s\n' "$1" >&2; exit 3 ;;
  esac
done
[ -n "${MEMBER}" ] || usage
# o id vira nome de arquivo/caminho: forma fechada (a mesma régua de rótulo do gate)
case "${MEMBER}" in *[!A-Za-z0-9._:-]*|.*) printf 'a2a-doctor: --member com caractere fora de [A-Za-z0-9._:-]\n' >&2; exit 3 ;; esac
case "${KID}" in *[!A-Za-z0-9._-]*|.*) printf 'a2a-doctor: --kid com caractere fora de [A-Za-z0-9._-]\n' >&2; exit 3 ;; esac
if [ -n "${ENDPOINT}" ]; then case "${ENDPOINT}" in http://*|https://*) ;; *) printf 'a2a-doctor: --endpoint precisa ser http(s)://\n' >&2; exit 3 ;; esac; fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../../../.." && pwd))"
GATE="${A2A_VERIFY:-${ROOT}/.claude/utils/federation-transport/a2a-verify.sh}"
[ -n "${DIR}" ] || DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/onion/a2a/${MEMBER}"
[ -n "${MEMBERS}" ] || MEMBERS="${ROOT}/docs/evolution/federation/members.yaml"
[ -n "${JWKS}" ] || JWKS="${A2A_JWKS_DIR:-${ROOT}/.claude/utils/federation-transport/jwks}"
PRIV="${DIR}/private.pem"
TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# ── registro dos resultados: id \t status \t critical \t causa \t proximo ──────────────────────
RES="${TMP}/res.tsv"; : > "${RES}"
put() { # id status critical causa proximo
  local c="${4//$'\t'/ }" n="${5//$'\t'/ }"; c="${c//$'\n'/ }"; n="${n//$'\n'/ }"
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${c}" "${n}" >> "${RES}"
}
st() { awk -F'\t' -v id="$1" '$1==id{print $2}' "${RES}"; }
have_yaml() { command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; }
# membro do registro: devolve "keys=<k1,k2>\nsends_to=<id>\nsource=<id>" (sem imprimir nada sensível)
member_info() {
  python3 - "${MEMBERS}" "${MEMBER}" <<'PY'
import sys, yaml
try: ms = (yaml.safe_load(open(sys.argv[1])) or {}).get('members') or []
except Exception: print("err=unparseable"); sys.exit(0)
src = [m.get('id') for m in ms if isinstance(m, dict) and m.get('kind') == 'source']
me = [m for m in ms if isinstance(m, dict) and m.get('id') == sys.argv[2]]
print("found=" + ("1" if me else "0"))
a = ((me[0].get('a2a') or {}) if me else {})
print("keys=" + ",".join(str(k) for k in (a.get('keys') or [])))
print("sends_to=" + str(a.get('sends_to') or ''))
print("source=" + (src[0] or '' if src else ''))
PY
}

# ── (a) chave privada existe ─────────────────────────────────────────────────────────────────
KEY_OK=""
if [ ! -e "${PRIV}" ]; then
  put a falha 1 "chave privada ausente em <dir>/private.pem (dir: ${DIR})" \
    "gere o par RS256: openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out <dir>/private.pem (umask 077) e mande SÓ a pública ao core"
elif ! command -v openssl >/dev/null 2>&1; then
  put a nao-medido 1 "openssl ausente — não sei ler a chave" "instale openssl e rode o doctor de novo"
elif ! openssl pkey -in "${PRIV}" -noout >/dev/null 2>&1; then
  put a falha 1 "o arquivo existe mas não é chave privada legível (corrompido, cifrado ou outra coisa)" \
    "regere o par RS256 em <dir>/private.pem e re-pine a pública no core"
else
  # RSA se reconhece pelo módulo: o openssl 3 imprime "Private-Key: (N bit…)" para RSA E para EC — a 1ª
  # versão deste spike lia essa linha e aprovava chave EC, que o gate (só RS256) recusaria.
  _ktext="$(openssl pkey -in "${PRIV}" -noout -text 2>/dev/null)"
  _bits="$(printf '%s\n' "${_ktext}" | sed -n '1s/.*(\([0-9]*\) bit.*/\1/p')"
  if printf '%s\n' "${_ktext}" | grep -q '^modulus:'; then
    if [ "${_bits:-0}" -ge 2048 ]; then KEY_OK=1; put a ok 1 "chave privada RSA ${_bits} bits presente e legível" "—"
    else put a falha 1 "chave RSA de ${_bits:-?} bits — curta demais" "regere com rsa_keygen_bits:2048 (ou mais)"; fi
  else
    put a falha 1 "chave não-RSA: o gate só aceita RS256" "regere com -algorithm RSA"
  fi
fi

# ── (b) permissão 0600 (sem bit de grupo/outros) e diretório 0700 ─────────────────────────────
if [ ! -e "${PRIV}" ]; then
  put b nao-medido 1 "sem chave não há permissão a medir (depende de a)" "resolva (a) primeiro"
else
  fm="$(stat -c '%a' "${PRIV}" 2>/dev/null)"; dm="$(stat -c '%a' "${DIR}" 2>/dev/null)"
  if [ -z "${fm}" ] || [ -z "${dm}" ]; then
    put b nao-medido 1 "stat não devolveu o modo (stat não-GNU?)" "confira à mão: ls -ld <dir> <dir>/private.pem"
  else
    bad=""
    [ $(( 8#${fm} & 8#077 )) -eq 0 ] || bad="private.pem está ${fm} (grupo/outros leem a chave)"
    [ $(( 8#${dm} & 8#077 )) -eq 0 ] || bad="${bad:+${bad}; }diretório está ${dm} (grupo/outros listam/trocam a chave)"
    if [ -n "${bad}" ]; then
      put b falha 1 "${bad}" "chmod 0700 <dir> && chmod 0600 <dir>/private.pem — e trate a chave como VAZADA se a máquina tem outras contas: regere e re-pine"
    else
      put b ok 1 "private.pem ${fm} · diretório ${dm}" "—"
    fi
  fi
fi

# ── (c) impressão SHA-256 da pública (DER SubjectPublicKeyInfo) ───────────────────────────────
FP=""
fp_of_pub() { openssl pkey -pubin -in "$1" -outform DER 2>/dev/null | openssl dgst -sha256 | awk '{print $NF}'; }
if [ -z "${KEY_OK}" ]; then
  put c nao-medido 1 "sem chave legível não há impressão (depende de a)" "resolva (a) primeiro"
else
  FP="$(openssl pkey -in "${PRIV}" -pubout -outform DER 2>/dev/null | openssl dgst -sha256 | awk '{print $NF}')"
  if [ "${#FP}" -eq 64 ]; then put c ok 1 "SHA256:${FP}" "confira esta impressão com o core por canal FORA de banda antes do pino"
  else FP=""; put c nao-medido 1 "openssl não devolveu a impressão" "rode: openssl pkey -in <dir>/private.pem -pubout -outform DER | openssl dgst -sha256"; fi
fi

# ── (d) kid pinado no registro + jwks/<kid>.pem com a MESMA impressão ─────────────────────────
INFO=""; KEYS=""; SENDS=""; SRC=""; FOUND=""
if [ ! -f "${MEMBERS}" ]; then
  put d nao-medido 1 "registro members.yaml inacessível daqui (${MEMBERS##*/} não encontrado) — o pino vive no repo do receptor" \
    "passe --members com uma cópia ATUAL do registro do core, ou peça ao core para rodar o doctor do lado receptor"
elif ! have_yaml; then
  put d nao-medido 1 "python3+PyYAML ausentes — não sei ler o registro (o gate também veta sem eles)" "instale python3-yaml"
else
  INFO="$(member_info)"
  FOUND="$(printf '%s\n' "${INFO}" | sed -n 's/^found=//p')"
  KEYS="$(printf '%s\n' "${INFO}" | sed -n 's/^keys=//p')"
  SENDS="$(printf '%s\n' "${INFO}" | sed -n 's/^sends_to=//p')"
  SRC="$(printf '%s\n' "${INFO}" | sed -n 's/^source=//p')"
  if printf '%s\n' "${INFO}" | grep -q '^err='; then
    put d falha 1 "members.yaml ilegível (YAML quebrado)" "corrija o YAML; o gate também veta com ele assim"
  elif [ "${FOUND}" != "1" ]; then
    put d falha 1 "membro '${MEMBER}' não está no registro" "registre pelo caminho do core: /meta:federation-member register"
  else
    [ -n "${KID}" ] || { [ -f "${DIR}/kid" ] && KID="$(head -1 "${DIR}/kid" | tr -d '[:space:]')"; }
    if [ -z "${KID}" ]; then case "${KEYS}" in *,*|'') ;; *) KID="${KEYS}" ;; esac; fi
    case "${KID}" in *[!A-Za-z0-9._-]*|.*) KID="" ;; esac
    if [ -z "${KID}" ]; then
      put d nao-medido 1 "não sei qual kid é o desta chave (sem --kid, sem <dir>/kid, e o registro tem ${KEYS:-zero} kid(s))" \
        "grave o kid em <dir>/kid (uma linha) ou passe --kid"
    elif ! printf '%s\n' "${KEYS}" | tr ',' '\n' | grep -qxF "${KID}"; then
      put d falha 1 "kid '${KID}' NÃO está pinado em members.yaml[${MEMBER}].a2a.keys (${KEYS:-vazio}) — o gate veta kid-not-owned-by-from" \
        "peça ao core o pino sob gate humano: adicionar ${KID} em a2a.keys e jwks/${KID}.pem (impressão de c)"
    elif [ ! -f "${JWKS}/${KID}.pem" ]; then
      put d falha 1 "kid '${KID}' pinado no registro mas jwks/${KID}.pem ausente — o gate veta unknown-kid" \
        "o core precisa gravar a pública em jwks/${KID}.pem (impressão de c)"
    elif [ -z "${FP}" ]; then
      put d nao-medido 1 "kid pinado, mas sem impressão local para comparar (depende de c)" "resolva (a)/(c)"
    else
      PFP="$(fp_of_pub "${JWKS}/${KID}.pem")"
      if [ "${PFP}" = "${FP}" ]; then put d ok 1 "kid '${KID}' pinado e jwks/${KID}.pem tem a mesma impressão" "—"
      else put d falha 1 "jwks/${KID}.pem tem impressão ${PFP:0:16}… ≠ a local ${FP:0:16}… (chave trocada ou pino velho) — o gate veta bad-signature" \
        "re-pine a pública atual (impressão de c) ou volte a usar a privada pinada"; fi
    fi
  fi
fi
[ -n "${RECEIVER}" ] || RECEIVER="${SENDS:-${SRC}}"

# ── (f) relógio confiável — os MESMOS sinais do gate, mas separando "disse não" de "não há sinal" ──
# O gate colapsa os dois em clock-untrusted (veto: certo para um gate). Um DOCTOR precisa separá-los,
# porque o próximo passo é diferente: ligar o NTP ≠ instalar/atestar uma fonte.
CLOCK=""; csig=""; cno=""
if [ "${A2A_CLOCK_TRUST:-}" = "attested" ]; then CLOCK=ok; csig="A2A_CLOCK_TRUST=attested (atestado do operador — declaração, não medição)"
else
  if command -v timedatectl >/dev/null 2>&1; then
    v="$(timedatectl show -p NTPSynchronized --value 2>/dev/null)"
    case "${v}" in yes) CLOCK=ok; csig="timedatectl NTPSynchronized=yes" ;; no) cno="timedatectl NTPSynchronized=no" ;; *) : ;; esac
  fi
  if [ -z "${CLOCK}" ] && command -v chronyc >/dev/null 2>&1; then
    t="$(chronyc tracking 2>/dev/null)"
    if printf '%s\n' "${t}" | grep -q '^Leap status.*Normal'; then CLOCK=ok; csig="chronyc Leap status Normal"
    elif [ -n "${t}" ]; then cno="${cno:+${cno}; }chronyc sem Leap Normal"; fi
  fi
  if [ -z "${CLOCK}" ] && command -v ntpstat >/dev/null 2>&1; then
    ntpstat >/dev/null 2>&1; r=$?
    if [ "${r}" -eq 0 ]; then CLOCK=ok; csig="ntpstat sincronizado"; elif [ "${r}" -eq 1 ]; then cno="${cno:+${cno}; }ntpstat não sincronizado"; fi
  fi
fi
if [ "${CLOCK}" = ok ]; then put f ok 1 "${csig}" "—"
elif [ -n "${cno}" ]; then CLOCK=no
  put f falha 1 "a fonte de tempo DISSE que não está sincronizada (${cno}) — o gate veta clock-untrusted" \
    "ligue o NTP (sudo timedatectl set-ntp true, ou chronyd) e espere sincronizar"
else CLOCK=unk
  put f nao-medido 1 "nenhum sinal de relógio: timedatectl/chronyc/ntpstat ausentes ou mudos, e sem A2A_CLOCK_TRUST — o gate veta clock-untrusted" \
    "instale chrony (ou systemd-timesyncd); em host sem nenhum, o operador atesta com A2A_CLOCK_TRUST=attested por decisão declarada"
fi

# ── (e) convite: presente, do membro certo, não vencido, não revogado ─────────────────────────
if [ -z "${INVITE}" ]; then
  put e nao-medido 0 "convite não informado (só se mede no onboarding)" "passe --invite <convite.json> durante o onboarding"
elif [ ! -f "${INVITE}" ]; then
  put e falha 1 "convite não encontrado no caminho informado" "baixe o convite que o core emitiu e passe o caminho certo"
elif ! command -v jq >/dev/null 2>&1; then
  put e nao-medido 1 "jq ausente — não sei ler o convite" "instale jq"
elif ! jq -e 'type=="object"' "${INVITE}" >/dev/null 2>&1; then
  put e falha 1 "convite ilegível (não é objeto JSON)" "peça ao core um convite novo"
else
  im="$(jq -r '.member // empty' "${INVITE}")"; ie="$(jq -r '.expires_at // empty' "${INVITE}")"
  ir="$(jq -r 'if .revoked == true then "true" elif (.revoked == false or .revoked == null) then "false" else "BAD" end' "${INVITE}")"
  case "${ie}" in ''|*[!0-9]*) iep="$(date -d "${ie}" +%s 2>/dev/null)" ;; *) iep="${ie}" ;; esac
  now="$(date +%s)"
  if [ "${im}" != "${MEMBER}" ]; then put e falha 1 "convite é de '${im:-ninguém}', não de '${MEMBER}'" "use o convite emitido para este membro"
  elif [ "${ir}" = "BAD" ]; then put e falha 1 "campo revoked com tipo inválido (nem true nem false)" "peça ao core um convite novo"
  elif [ "${ir}" = "true" ]; then put e falha 1 "convite REVOGADO pelo core" "peça um convite novo ao core (o revogado não volta)"
  elif [ -z "${iep}" ]; then put e falha 1 "expires_at ausente ou ilegível (${ie:-vazio})" "peça ao core um convite com expires_at (epoch ou ISO-8601)"
  elif [ "${iep}" -le "${now}" ]; then put e falha 1 "convite VENCIDO em $(date -u -d "@${iep}" +%FT%TZ)$([ "${CLOCK}" = ok ] || printf ' (julgado num relógio NÃO confiável — ver f)')" "peça ao core um convite novo"
  elif [ "${CLOCK}" != ok ]; then put e nao-medido 1 "convite parece válido até $(date -u -d "@${iep}" +%FT%TZ), mas julgado num relógio não confiável (ver f)" "resolva (f) e rode de novo"
  else put e ok 1 "convite de '${MEMBER}', válido até $(date -u -d "@${iep}" +%FT%TZ), não revogado" "—"; fi
fi

# ── (g) endpoint alcançável: só o http_code, timeout curto, nenhum token na linha de comando ──
if [ -z "${ENDPOINT}" ]; then
  put g nao-medido 0 "endpoint não informado" "passe --endpoint <url do receptor>"
elif ! command -v curl >/dev/null 2>&1; then
  put g nao-medido 1 "curl ausente — não sei medir o alcance" "instale curl"
else
  # sem autenticação: a pergunta é ALCANCE, não autorização. A URL não carrega credencial (rejeitada abaixo).
  case "${ENDPOINT}" in *://*@*) put g falha 1 "a URL do endpoint carrega credencial embutida (user:token@)" "tire a credencial da URL; ela vaza em /proc e no histórico" ;;
  *)
    code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 4 --proto '=http,https' "${ENDPOINT}" 2>/dev/null)"; code="${code:-000}"
    case "${code}" in
      000) put g falha 1 "endpoint inalcançável (conexão recusada, DNS ou timeout de 4 s)" "confira URL, DNS, firewall e se o serviço do receptor está de pé" ;;
      5*)  put g falha 1 "endpoint respondeu HTTP ${code} (servidor de pé, mas quebrado)" "o receptor precisa olhar o log do serviço" ;;
      *)   put g ok 1 "endpoint alcançável (HTTP ${code} — alcance, não autorização)" "—" ;;
    esac ;;
  esac
fi

# ── (h) envio sintético contra o gate LOCAL em --dry-run ─────────────────────────────────────
# Relógio ISOLADO: o envio roda com A2A_CLOCK_TRUST=attested, porque o relógio já é julgado em (f) — e o
# do gate local NÃO é o do receptor de produção (o gate roda no host DELE). Assim (h) mede o que o
# membro controla: assinatura, kid, trust, forma do envelope. Estado do jti vai para um repo temporário.
if [ -z "${KEY_OK}" ]; then put h nao-medido 1 "sem chave não há o que assinar (depende de a)" "resolva (a)"
elif [ ! -f "${GATE}" ]; then put h nao-medido 1 "gate a2a-verify.sh não encontrado" "rode o doctor de dentro de uma instalação Onion ou exporte A2A_VERIFY"
elif [ ! -f "${MEMBERS}" ] || [ -z "${KID}" ]; then put h nao-medido 1 "sem registro ou sem kid o gate nem chega à assinatura (depende de d)" "resolva (d)"
elif [ -z "${RECEIVER}" ]; then put h nao-medido 1 "não sei para quem enviar (sem --receiver, sem a2a.sends_to, sem membro source)" "passe --receiver"
elif ! command -v jq >/dev/null 2>&1; then put h nao-medido 1 "jq ausente" "instale jq"
else
  b64u() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
  now="$(date +%s)"; jti="doctor-${now}-$$"
  bsha="$(printf '' | openssl dgst -sha256 | awk '{print $NF}')"
  hd="$(printf '{"alg":"RS256","kid":"%s"}' "${KID}" | b64u)"
  pl="$(jq -cn --arg i "${MEMBER}" --arg a "${RECEIVER}" --arg j "${jti}" --arg b "${bsha}" --argjson t "${now}" \
        '{iss:$i,aud:$a,iat:$t,exp:($t+300),jti:$j,body_sha256:$b}' | b64u)"
  sig="$(printf '%s' "${hd}.${pl}" | openssl dgst -sha256 -sign "${PRIV}" 2>/dev/null | b64u)"
  mkdir -p "${TMP}/repo/docs/evolution/federation"; cp "${MEMBERS}" "${TMP}/repo/docs/evolution/federation/members.yaml"
  jq -cn --arg j "${hd}.${pl}.${sig}" --arg f "${MEMBER}" --arg t "${RECEIVER}" \
     '{jws:$j,signal:{id:"doctor-synthetic",direction:"upstream",from:$f,to:$t,kind:"signal",classification:"internal"}}' > "${TMP}/env.json"
  out="$(A2A_CLOCK_TRUST=attested A2A_JWKS_DIR="${JWKS}" bash "${GATE}" --receiver "${RECEIVER}" --repo "${TMP}/repo" --dry-run --envelope "${TMP}/env.json" 2>/dev/null)"; grc=$?
  reason="$(printf '%s' "${out}" | jq -r '.reason // empty' 2>/dev/null)"; layer="$(printf '%s' "${out}" | jq -r '.layer_failed // empty' 2>/dev/null)"
  if [ "${grc}" -eq 0 ] && [ "${reason}" = ok ]; then
    put h ok 1 "gate local aceitou o envio sintético (verified, gated, dry-run; relógio isolado em f)" "—"
  elif [ "${grc}" -eq 1 ] && [ -n "${reason}" ]; then
    case "${reason}" in
      trust-denied) nx="a topologia não deixa ${MEMBER}→${RECEIVER}: confira trust/kind no registro" ;;
      kid-not-owned-by-from:*|unknown-kid:*) nx="o pino do kid está errado — ver (d)" ;;
      bad-signature) nx="a privada local não é a pinada — ver (c)/(d)" ;;
      tooling-absent:*) nx="instale ${reason#tooling-absent:}" ;;
      *) nx="leia a camada '${layer}' em a2a-verify.sh" ;;
    esac
    put h falha 1 "gate local VETOU: ${reason} (camada ${layer})" "${nx}"
  else
    put h nao-medido 1 "gate não devolveu veredito legível (rc ${grc})" "rode o gate à mão com --dry-run e leia o stderr"
  fi
fi

# ── veredito ─────────────────────────────────────────────────────────────────────────────────
RC=0
awk -F'\t' '$2=="falha"' "${RES}" | grep -q . && RC=1
[ "${RC}" -eq 0 ] && awk -F'\t' '$2=="nao-medido" && $3=="1"' "${RES}" | grep -q . && RC=2
label() { case "$1" in a) echo "chave privada" ;; b) echo "permissão" ;; c) echo "impressão SHA-256" ;; d) echo "kid no registro" ;;
  e) echo "convite" ;; f) echo "relógio" ;; g) echo "endpoint" ;; h) echo "envio sintético" ;; esac; }

if [ -n "${JSON}" ]; then
  command -v jq >/dev/null 2>&1 || { printf 'a2a-doctor: --json exige jq\n' >&2; exit 2; }
  sort -k1,1 "${RES}" | jq -Rn --arg m "${MEMBER}" --argjson rc "${RC}" '
    [inputs | split("\t") | {id:.[0], status:.[1], critical:(.[2]=="1"), cause:.[3], next:.[4]}] as $c
    | {member:$m, rc:$rc, verdict:(["ok","falha","nao-medido"][$rc]), checks:$c}'
else
  printf 'a2a-doctor · membro %s · receptor %s\n\n' "${MEMBER}" "${RECEIVER:-?}"
  while IFS=$'\t' read -r id s crit cause nxt; do
    case "${s}" in ok) ic="✅" ;; falha) ic="❌" ;; *) ic="⚪" ;; esac
    printf '%s (%s) %s%s — %s\n' "${ic}" "${id}" "$(label "${id}")" "$([ "${crit}" = 1 ] || printf ' [não-crítica]')" "${cause}"
    [ "${s}" = ok ] || printf '      → próximo passo: %s\n' "${nxt}"
  done < <(sort -k1,1 "${RES}")
  nf="$(awk -F'\t' '$2=="falha"' "${RES}" | wc -l)"; nn="$(awk -F'\t' '$2=="nao-medido"' "${RES}" | wc -l)"; no="$(awk -F'\t' '$2=="ok"' "${RES}" | wc -l)"
  printf '\nresumo: %s ok · %s falha · %s não medida(s) → ' "${no}" "${nf}" "${nn}"
  case "${RC}" in 0) echo "✅ saudável (rc 0)" ;; 1) echo "❌ problema (rc 1)" ;; 2) echo "⚪ não pude medir o que é crítico (rc 2) — não sei ≠ saudável" ;; esac
fi
exit "${RC}"
