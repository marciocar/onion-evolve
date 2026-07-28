#!/usr/bin/env bash
# =============================================================================
# logto-provision.sh — provisiona o tenant `default` do Logto para o gate de
#                      identidade do onion-bridge, SEM console e SEM exposição.
#
# Por quê existe: o runbook do M2 (docs/analysis/onion-m2-bridge-logto-integration-2026-07.md,
# P1-P3) assume que o maestro clica no console admin. Medido em 2026-07-26, isso custa
# expor o painel do provedor de identidade que estamos endurecendo (o vhost
# console.onionevolve.com está DESLIGADO por desenho e o sign_up está ABERTO), ou um
# túnel SSH inviável do celular — que é como o maestro opera. A Management API dissolve
# o obstáculo e é melhor pelos critérios da casa: reproduzível, auditável, versionado,
# idempotente, sem superfície nova. Nó do KG: C_console_not_the_path.
#
# Uso : bash .claude/utils/bridge-auth/logto-provision.sh [--apply] [--user <username>]
#       Sem --apply é DRY-RUN: mostra o que faria e não muta nada.
#
# Segredos: o client_secret é lido do banco para a memória e NUNCA impresso. A senha do
#           usuário é gerada aqui e escrita SÓ em ${PASS_FILE} (root, 0600) — nunca em
#           stdout, nunca no transcript de uma sessão de agente.
#
# Idempotente: cada passo consulta antes de criar. Re-rodar não duplica.
# =============================================================================

set -euo pipefail

APPLY=0
BRIDGE_USER="marcio"
RESOURCE_INDICATOR="https://bridge.onionevolve.com"
SCOPE_NAME="bridge:invoke"
ADMIN_SCOPE="bridge:admin"       # P9 — admin por IDENTIDADE, nao por segredo compartilhado
# ADR onion-adr-logto-as-projection-2026-07 D3 — UM app M2M POR CHAMADOR, nunca um
# compartilhado: revogar um compartilhado derruba todos de uma vez, e o log nao distingue
# quem chamou. Adicione chamadores aqui (separados por espaco); o script e idempotente.
M2M_CALLERS="${M2M_CALLERS:-onion-bridge-service}"
WRITE_SCOPE="bridge:write"       # P10 — CAPACIDADE por identidade (escrever/executar vs so ler)
ROLE_NAME="bridge-operator"      # M2M — o chamador SERVIÇO
USER_ROLE_NAME="bridge-user"     # User — a PESSOA (tipo diferente no Logto; a M2M não serve)
PASS_FILE="/root/.onion-logto-bootstrap"
PG_CONTAINER="onion-logto-postgres"
# BOOTSTRAP CIRCULAR, e como se quebra (medido 2026-07-26):
#   O app M2M `m-default` — o único que concede a Management API do tenant `default` —
#   vive no tenant `admin`. E o Logto só RESOLVE o tenant admin quando a requisição chega
#   com origem exatamente igual ao ADMIN_ENDPOINT (https://console.onionevolve.com).
#   Batendo em 127.0.0.1:3011 OU :3012 por HTTP, as duas portas devolvem
#   `issuer: https://auth.onionevolve.com/oidc` e `tenantId: default` — logo o cliente do
#   tenant admin é desconhecido ali e o token endpoint responde `invalid_client`, sem dizer
#   por quê. Com a origem certa: `issuer: https://console.onionevolve.com/oidc`, tenant admin.
#   Por isso o vhost do console existe LOOPBACK-ONLY (bind 127.0.0.1 + tls internal) e o
#   alcance é por --resolve: origem correta para o Logto, zero exposição pública.
#   SEGUNDA metade do no (medida logo depois): o token SAI pelo console (onde o cliente
#   vive) mas as chamadas VAO para o endpoint do tenant default (auth.onionevolve.com).
#   Apresentar no console um token com aud=https://default.logto.app/api devolve
#   ERR_JWT_CLAIM_VALIDATION_FAILED/aud — o binding de audiencia e REAL e rejeitou o uso
#   errado. Isso e, de quebra, a prova do P4.1 (RFC 8707 honrado => plano A).
TOKEN_ORIGIN="https://console.onionevolve.com"   # tenant admin — onde m-default existe
RESOLVE="console.onionevolve.com:443:127.0.0.1"  # loopback-only, sem exposicao publica
API_ORIGIN="https://auth.onionevolve.com"        # tenant default — onde se provisiona
MAPI_DEFAULT="https://default.logto.app/api"

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --user)  BRIDGE_USER="${2:?--user precisa de valor}"; shift ;;
    # ADR D3 — revogar UM chamador sem tocar nos outros. Pela API do Logto, nunca por
    # SQL direto no Postgres: escrita crua no store de identidade contorna a API E o
    # proprio script, e o que contorna o mecanismo nao e repetivel nem auditavel.
    --revoke) REVOKE_APP="${2:?--revoke precisa do nome do app M2M}"; shift ;;
    # ADR D1/D2 — projeta a federacao (members.yaml) em Organizations. Sempre repo->Logto.
    --project-federation) PROJECT_FED=1 ;;
    # ADR fatia 3 — convite RASTREAVEL no lugar do segredo compartilhado.
    --invite)      INVITE_EMAIL="${2:?--invite precisa do e-mail do convidado}"; shift ;;
    --invite-org)  INVITE_ORG="${2:?--invite-org precisa do id da organizacao}"; shift ;;
    --invite-role) INVITE_ROLE="${2:?--invite-role precisa do tier}"; shift ;;
    --invite-days) INVITE_DAYS="${2:?--invite-days precisa de numero}"; shift ;;
    --invites)     LIST_INVITES=1 ;;
    --uninvite)    UNINVITE_ID="${2:?--uninvite precisa do id do convite}"; shift ;;
    --drop-org)    DROP_ORG="${2:?--drop-org precisa do nome da organizacao}"; shift ;;
    --drop-user)   DROP_USER="${2:?--drop-user precisa do username}"; shift ;;
    # Fatia 3 REDESENHADA: convite por e-mail nao funciona aqui (0 conectores + sign_up
    # fechado, e a doc do Logto diz que convite de organizacao NAO e o desvio p/ registro
    # fechado — o desvio documentado e magic link). Pre-provisionar cabe melhor: membro da
    # federacao nao e estranho, ja esta no members.yaml.
    --enroll)      ENROLL_USER="${2:?--enroll precisa do username ou e-mail}"; shift ;;
    --enroll-org)  ENROLL_ORG="${2:?--enroll-org precisa do id da organizacao}"; shift ;;
    --enroll-role) ENROLL_ROLE="${2:?--enroll-role precisa do tier}"; shift ;;
    *) echo "argumento desconhecido: $1" >&2; exit 2 ;;
  esac
  shift
done

for t in curl jq python3 docker; do
  command -v "$t" >/dev/null 2>&1 || { echo "ERRO: '$t' ausente — pré-requisito." >&2; exit 3; }
done

say() { printf '%s\n' "$*"; }
step() { printf '\n── %s\n' "$*"; }

# --- 0. token M2M (client_credentials) -------------------------------------
# O app `m-default` vive no tenant `admin` e carrega o papel machine:mapi:default,
# que concede a Management API do tenant `default`. O issuer do tenant admin só
# escuta em 127.0.0.1:3012 (vhost público desligado) — daí o Host forjado.
# PRÉ-FLIGHT do nó circular. Sem isto, a ausência do vhost loopback aparece lá embaixo como
# `invalid_client` — erro que não diz NADA sobre a causa e custou uma sessão inteira para
# diagnosticar. O andaime é removido de propósito depois de cada uso (o estado seguro é o
# estado SEM configuração); então a falta dele é o caso NORMAL, não a exceção. Falhe cedo,
# falhe explicando, e entregue o comando exato. [[fix-must-become-mechanism]]
step "pré-flight: o issuer do tenant admin está alcançável?"
if ! curl -sS -k --max-time 5 --resolve "${RESOLVE}" \
     "${TOKEN_ORIGIN}/oidc/.well-known/openid-configuration" 2>/dev/null \
     | grep -q "console.onionevolve.com/oidc"; then
  cat >&2 <<'HELP'
ERRO: o issuer do tenant `admin` não responde no loopback.

  POR QUÊ: o app M2M `m-default` (o único que concede a Management API do tenant
  `default`) vive no tenant `admin`, e o Logto só RESOLVE esse tenant quando a
  requisição chega com origem exatamente igual ao ADMIN_ENDPOINT
  (https://console.onionevolve.com). Sem o vhost, tudo cai no OIDC do tenant
  `default` e o token endpoint responde `invalid_client` — sem dizer o motivo.

  CONSERTO — USE O MECANISMO QUE JA EXISTE, nao erga um vhost paralelo:

    bash ~/onion-logto/console.sh on      # liga o vhost do console (publico, cert real)
    bash ~/onion-logto/console.sh status  # confere
    bash ~/onion-logto/console.sh off     # DESLIGUE ao terminar

  O maestro construiu esse liga/desliga de proposito: o console fica FORA do ar por
  padrao e so sobe na janela de configuracao. Ate 2026-07-28 este bloco mandava
  escrever um vhost loopback proprio — o autor ergueu e derrubou SEIS vezes num dia
  sem procurar o mecanismo que ja existia. Conselho nao se repete sozinho; ponteiro sim.

  ANTES DE DEIXAR LIGADO ALEM DA JANELA: o tenant `admin` esta com registro ABERTO
  (sign_up identifiers ["username"], password). Fechar antes de publicar de vez.

  NOTA: mexer no Caddy de produção é mudança que o maestro precisa AUTORIZAR NOMEANDO
  — não é inferível de um "pode seguir" genérico.
HELP
  exit 6
fi
say "   issuer do tenant admin OK (loopback)"

step "0. token M2M para a Management API do tenant default"
_secret="$(docker exec "${PG_CONTAINER}" psql -U logto -d logto -tAc \
  "select secret from applications where id='m-default';" 2>/dev/null | tr -d ' \r\n')"
[ -n "${_secret}" ] || { echo "ERRO: secret de m-default não encontrado." >&2; exit 4; }

_tok_resp="$(curl -sS -k --resolve "${RESOLVE}" -X POST "${TOKEN_ORIGIN}/oidc/token" \
  --data-urlencode grant_type=client_credentials \
  --data-urlencode "resource=${MAPI_DEFAULT}" \
  --data-urlencode scope=all \
  -u "m-default:${_secret}")"
unset _secret
TOKEN="$(printf '%s' "${_tok_resp}" | jq -r '.access_token // empty')"
[ -n "${TOKEN}" ] || {
  echo "ERRO no token endpoint. Corpo (sem segredo):" >&2
  printf '%s\n' "${_tok_resp}" | jq -c 'del(.access_token)' >&2 || printf '%s\n' "${_tok_resp}" >&2
  exit 5
}
say "   token obtido (len=${#TOKEN})"

api() { # api <METHOD> <PATH> [json-body]
  local m="$1" p="$2" b="${3:-}"
  if [ -n "$b" ]; then
    curl -sS -X "$m" "${API_ORIGIN}/api${p}" \
      -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" -d "$b"
  else
    curl -sS -X "$m" "${API_ORIGIN}/api${p}" \
      -H "Authorization: Bearer ${TOKEN}"
  fi
}

mutate() { # mutate <descrição> <METHOD> <PATH> <json>
  # A mensagem humana vai para STDERR de propósito: o STDOUT desta função é DADO
  # (JSON que o chamador parseia com jq). Misturar os dois faz o dry-run quebrar com
  # "Invalid numeric literal" — canal de log poluindo canal de dados.
  if [ "${APPLY}" = "1" ]; then api "$2" "$3" "$4"
  else printf '   [DRY-RUN] %s\n' "$1" >&2; printf '%s' '{}'; fi
}

# --- 1. usuário do maestro no tenant default -------------------------------
# --- MODO --drop-user: remove conta DORMENTE (guarda: nunca logou) ------------
# Conta privilegiada que ninguem usa e superficie de ataque sem contrapartida. A guarda
# nao e conselho: se a conta JA LOGOU alguma vez, o modo recusa — apagar identidade viva
# nao pode ser efeito colateral de uma limpeza.
if [ -n "${DROP_USER:-}" ]; then
  step "remover conta dormente '${DROP_USER}'"
  _du="$(api GET "/users?search=${DROP_USER}" | jq -c --arg u "${DROP_USER}" '[.[]? | select(.username==$u)] | .[0] // {}')"
  _duid="$(printf '%s' "${_du}" | jq -r '.id // empty')"
  [ -n "${_duid}" ] || { say "   nao existe — nada a fazer"; exit 0; }
  _last="$(printf '%s' "${_du}" | jq -r '.lastSignInAt // "null"')"
  if [ "${_last}" != "null" ] && [ -n "${_last}" ]; then
    say "   RECUSADO: '${DROP_USER}' JA LOGOU (lastSignInAt=${_last}) — nao e conta dormente."; exit 9
  fi
  if [ "${APPLY}" = "1" ]; then
    api DELETE "/users/${_duid}" >/dev/null 2>&1 || true
    say "   removida (id=${_duid}, nunca logou)"
  else say "   [DRY-RUN] removeria ${DROP_USER} (id=${_duid}, nunca logou)"; fi
  exit 0
fi

# --- MODO --drop-org: remove uma organizacao (pela API) -----------------------
if [ -n "${DROP_ORG:-}" ]; then
  step "remover organizacao ${DROP_ORG}"
  _did="$(api GET "/organizations" | jq -r --arg n "${DROP_ORG}" '.[]? | select(.name==$n or .id==$n) | .id' | head -1)"
  [ -n "${_did}" ] || { say "   nao existe — nada a fazer"; exit 0; }
  _mem="$(api GET "/organizations/${_did}/users" | jq -r 'length')"
  if [ "${_mem:-0}" != "0" ]; then say "   RECUSADO: org tem ${_mem} membro(s). Retire-os antes."; exit 8; fi
  if [ "${APPLY}" = "1" ]; then
    api DELETE "/organizations/${_did}" >/dev/null 2>&1 || true
    say "   removida (id=${_did})"
  else say "   [DRY-RUN] removeria ${DROP_ORG} (id=${_did}, 0 membros)"; fi
  exit 0
fi

# --- MODO --uninvite: retira um convite (pela API, nunca por SQL) -------------
if [ -n "${UNINVITE_ID:-}" ]; then
  step "retirar convite ${UNINVITE_ID}"
  if [ "${APPLY}" = "1" ]; then
    api DELETE "/organization-invitations/${UNINVITE_ID}" >/dev/null 2>&1 || true
    say "   removido"
  else say "   [DRY-RUN] removeria ${UNINVITE_ID}"; fi
  exit 0
fi

# --- MODO --enroll: por um usuario JA EXISTENTE dentro de uma organizacao -----
# Fecha a lacuna declarada na fatia 2 (orgs vazias = estrutura, nao funcao). Nao cria
# usuario: exige que ele exista, porque criar identidade humana e ato do maestro.
if [ -n "${ENROLL_USER:-}" ]; then
  : "${ENROLL_ORG:?--enroll exige --enroll-org <organizacao>}"
  step "matricular '${ENROLL_USER}' na org ${ENROLL_ORG}"
  _uid_e="$(api GET "/users?search=${ENROLL_USER}" 2>/dev/null \
    | jq -r --arg u "${ENROLL_USER}" '.[]? | select(.username==$u or .primaryEmail==$u) | .id' | head -1)"
  [ -n "${_uid_e}" ] || { say "   ERRO: usuario '${ENROLL_USER}' nao existe. Criar identidade humana e ato do maestro."; exit 7; }
  _oid_e="$(api GET "/organizations" | jq -r --arg n "${ENROLL_ORG}" '.[]? | select(.name==$n or .id==$n) | .id' | head -1)"
  # ORG NASCE SOB DEMANDA (decisao do maestro 2026-07-28): criar as 8 de uma vez produziu
  # 7 organizacoes que ninguem autenticava — esqueleto que envelhece. `kind: adopter`
  # responde "vendoriza?", nao "alguem autentica como isso?" — sao perguntas diferentes.
  if [ -z "${_oid_e}" ]; then
    _in_ssot="$(grep -c "id: ${ENROLL_ORG}\$" "${MEMBERS_YAML:-docs/evolution/federation/members.yaml}" 2>/dev/null || echo 0)"
    [ "${_in_ssot}" != "0" ] || { say "   ERRO: '${ENROLL_ORG}' nao existe no members.yaml (SSOT). Registre la primeiro."; exit 7; }
    if [ "${APPLY}" = "1" ]; then
      _oid_e="$(api POST "/organizations" "$(jq -nc --arg n "${ENROLL_ORG}" '{name:$n, description:"Membro da federacao Onion — criada sob demanda na 1a matricula"}')" | jq -r '.id // empty')"
      say "   org '${ENROLL_ORG}' criada sob demanda (id=${_oid_e})"
    else say "   [DRY-RUN] criaria a org '${ENROLL_ORG}' sob demanda"; fi
  fi
  [ -n "${_oid_e}" ] || { say "   [DRY-RUN] sem org, parando aqui"; exit 0; }

  if [ "${APPLY}" = "1" ]; then
    if api GET "/organizations/${_oid_e}/users" | jq -e --arg u "${_uid_e}" '.[]? | select(.id==$u)' >/dev/null 2>&1; then
      say "   já era membro"
    else
      api POST "/organizations/${_oid_e}/users" "$(jq -nc --arg u "${_uid_e}" '{userIds:[$u]}')" >/dev/null
      say "   membro adicionado (user=${_uid_e} org=${_oid_e})"
    fi
    if [ -n "${ENROLL_ROLE:-}" ]; then
      _orid="$(api GET "/organization-roles" | jq -r --arg n "${ENROLL_ROLE}" '.[]? | select(.name==$n) | .id' | head -1)"
      if [ -n "${_orid}" ]; then
        api POST "/organizations/${_oid_e}/users/${_uid_e}/roles" "$(jq -nc --arg r "${_orid}" '{organizationRoleIds:[$r]}')" >/dev/null 2>&1
        say "   org-role '${ENROLL_ROLE}' atribuida"
      else
        say "   ⚠ org-role '${ENROLL_ROLE}' nao existe — membro sem papel"
      fi
    fi
  else
    say "   [DRY-RUN] matricularia user=${_uid_e} na org=${_oid_e} com papel ${ENROLL_ROLE:-—}"
  fi
  exit 0
fi

# --- MODO --invites: lista convites com estado e validade (ADR fatia 3) -------
if [ "${LIST_INVITES:-0}" = "1" ]; then
  step "convites de organizacao"
  api GET "/organization-invitations" 2>/dev/null \
    | jq -r '.[]? | "   \(.invitee)  org=\(.organizationId)  status=\(.status)  expira=\(.expiresAt)"' \
    | sed 's/^/  /' || say "   (nenhum)"
  exit 0
fi

# --- MODO --invite: convite rastreavel no lugar do segredo compartilhado ------
# O que se aposenta aqui: INVITE_TOKENS_COURTESY/BYOK eram strings no .env, coladas no
# chat. Ninguem sabia quem tinha qual, nem quando parava de valer — e quando o flip do P7
# as matou, NINGUEM NOTOU (nem gate, nem humano). Um convite tem inviter, invitee, status
# e expires_at: some quando expira, e o sumico e visivel.
if [ -n "${INVITE_EMAIL:-}" ]; then
  : "${INVITE_ORG:?--invite exige --invite-org <id-da-organizacao>}"
  _days="${INVITE_DAYS:-7}"
  step "convidar ${INVITE_EMAIL} para a org ${INVITE_ORG} (validade ${_days}d)"

  _oid="$(api GET "/organizations" | jq -r --arg n "${INVITE_ORG}" '.[]? | select(.name==$n or .id==$n) | .id' | head -1)"
  [ -n "${_oid}" ] || { say "   ERRO: organizacao '${INVITE_ORG}' nao existe. Rode --project-federation antes."; exit 6; }

  _rids="[]"
  if [ -n "${INVITE_ROLE:-}" ]; then
    _rid_o="$(api GET "/organization-roles" | jq -r --arg n "${INVITE_ROLE}" '.[]? | select(.name==$n) | .id' | head -1)"
    [ -n "${_rid_o}" ] || { say "   ERRO: org-role '${INVITE_ROLE}' nao existe"; exit 6; }
    _rids="$(jq -nc --arg r "${_rid_o}" '[$r]')"
  fi

  _exp="$(( ($(date +%s) + _days*86400) * 1000 ))"
  if [ "${APPLY}" = "1" ]; then
    _resp="$(api POST "/organization-invitations" "$(jq -nc \
      --arg o "${_oid}" --arg e "${INVITE_EMAIL}" --argjson x "${_exp}" --argjson r "${_rids}" \
      '{organizationId:$o, invitee:$e, expiresAt:$x} + (if ($r|length)>0 then {organizationRoleIds:$r} else {} end)')")"
    _iid="$(printf '%s' "${_resp}" | jq -r '.id // empty')"
    if [ -n "${_iid}" ]; then
      say "   convite criado: id=${_iid} status=$(printf '%s' "${_resp}" | jq -r '.status // "?"')"
      say "   ⚠ o convidado precisa conseguir ENTRAR: o sign_up do tenant default esta fechado."
      say "     Verifique se o convite dispensa registro aberto ANTES de prometer acesso a alguem."
    else
      say "   FALHOU: $(printf '%s' "${_resp}" | jq -r '.message // .code // .' | head -c 200)"; exit 6
    fi
  else
    say "   [DRY-RUN] criaria convite para ${INVITE_EMAIL} na org ${_oid} (expira em ${_days}d)"
  fi
  exit 0
fi

# --- MODO --project-federation: members.yaml -> Organizations (ADR D1/D2) -----
# O members.yaml e o SSOT; o Logto e PROJECAO dele. Sentido unico, sempre. So `kind: adopter`
# vira Organization — `source` e o emissor, e distillation/door/method nao pedem identidade
# (D4: sem o campo `kind:` isto projetaria estrutura errada SEM ERRO).
if [ "${PROJECT_FED:-0}" = "1" ]; then
  MEMBERS="${MEMBERS_YAML:-docs/evolution/federation/members.yaml}"
  [ -f "${MEMBERS}" ] || { echo "ERRO: ${MEMBERS} nao encontrado (rode da raiz do core)" >&2; exit 5; }
  step "projetar federacao: ${MEMBERS} -> Organizations"

  _rows="$(python3 - "${MEMBERS}" <<'PYEOF'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
for m in d.get("members", []):
    k = m.get("kind", "?")
    print(f"{m['id']}\t{m.get('role','?')}\t{k}")
PYEOF
)"
  [ -n "${_rows}" ] || { echo "ERRO: nenhum membro lido" >&2; exit 5; }

  _adopters="$(printf '%s\n' "${_rows}" | awk -F'\t' '$3=="adopter"{print $1}')"
  _tiers="$(printf '%s\n' "${_rows}" | awk -F'\t' '$3=="adopter"{print $2}' | sort -u)"
  # `printf '%s' | wc -l` conta QUEBRAS, nao linhas — sem \n final, 8 itens viram "7".
  # Numero plausivel e errado e pior que erro: passa despercebido. Usa -c com regex.
  say "   adotantes (kind=adopter): $(printf '%s\n' "${_adopters}" | grep -c '[^[:space:]]') · tiers: $(printf '%s' "${_tiers}" | tr '\n' ' ')"
  say "   ignorados por natureza  : $(printf '%s\n' "${_rows}" | awk -F'\t' '$3!="adopter"{printf "%s(%s) ", $1, $3}')"

  # org roles = tiers
  _existing_roles="$(api GET "/organization-roles" 2>/dev/null || echo '[]')"
  for _t in ${_tiers}; do
    _has="$(printf '%s' "${_existing_roles}" | jq -r --arg n "${_t}" '.[]? | select(.name==$n) | .id' | head -1)"
    if [ -n "${_has}" ]; then say "   org-role ${_t}: já existe"
    elif [ "${APPLY}" = "1" ]; then
      api POST "/organization-roles" "$(jq -nc --arg n "${_t}" '{name:$n, description:"Tier RFC-0003 projetado do members.yaml"}')" >/dev/null 2>&1
      say "   org-role ${_t}: criada"
    else say "   [DRY-RUN] criaria org-role ${_t}"; fi
  done

  # ORGS NAO SAO MAIS CRIADAS EM MASSA (decisao 2026-07-28). Criar as 8 de uma vez deu
  # 7 organizacoes vazias que ninguem autenticava — esqueleto que envelhece e faz o D5
  # ficar verde sobre estrutura inutil. A org nasce na 1a matricula (--enroll). Aqui so
  # se RELATA quem do SSOT ainda nao tem org, para a lacuna ficar visivel sem virar lixo.
  _existing_orgs="$(api GET "/organizations" 2>/dev/null || echo '[]')"
  _sem_org=""
  for _a in ${_adopters}; do
    printf '%s' "${_existing_orgs}" | jq -e --arg n "${_a}" '.[]? | select(.name==$n)' >/dev/null 2>&1 \
      || _sem_org="${_sem_org} ${_a}"
  done
  if [ -n "${_sem_org}" ]; then
    say "   sem org (nasce na 1a matricula):${_sem_org}"
  else
    say "   todos os adotantes do SSOT ja tem org"
  fi

  # D5 — DIVERGENCIA: org no Logto que nao esta no SSOT. Reporta, NUNCA absorve: absorver
  # deixaria o plano de execucao redefinir o SSOT pelas costas.
  _orphans="$(printf '%s' "$(api GET "/organizations" 2>/dev/null || echo '[]')" \
    | jq -r '.[]?.name' | sort -u | comm -23 - <(printf '%s\n' "${_adopters}" | sort -u))"
  if [ -n "${_orphans}" ]; then
    say ""
    say "   ⚠ DIVERGENCIA (D5) — org no Logto sem entrada kind=adopter no SSOT:"
    printf '%s\n' "${_orphans}" | while read -r o; do [ -n "$o" ] && say "       ${o}"; done
    say "     NAO absorvida de proposito. Ou vira entrada no members.yaml, ou sai do Logto."
  else
    say "   ✅ sem divergencia: Logto == SSOT"
  fi
  exit 0
fi

# --- MODO --revoke: tira UM app M2M da role, deixando os demais intactos ------
if [ -n "${REVOKE_APP:-}" ]; then
  step "revogar '${REVOKE_APP}' da role ${ROLE_NAME}"
  _rid_r="$(api GET "/roles" | jq -r --arg n "${ROLE_NAME}" '.[]? | select(.name==$n) | .id' | head -1)"
  _aid_r="$(api GET "/applications" | jq -r --arg n "${REVOKE_APP}" '.[]? | select(.name==$n) | .id' | head -1)"
  if [ -z "${_rid_r}" ] || [ -z "${_aid_r}" ]; then
    say "   ERRO: role ou app nao encontrado (role=${_rid_r:-—} app=${_aid_r:-—})"; exit 4
  fi
  if [ "${APPLY}" = "1" ]; then
    api DELETE "/roles/${_rid_r}/applications/${_aid_r}" >/dev/null 2>&1 || true
    say "   ${REVOKE_APP} (${_aid_r}) removido da role — os demais chamadores seguem intactos"
  else
    say "   [DRY-RUN] removeria ${REVOKE_APP} (${_aid_r}) da role ${_rid_r}"
  fi
  exit 0
fi

step "1. usuário '${BRIDGE_USER}' no tenant default"
_users="$(api GET "/users?search=${BRIDGE_USER}")"
_uid="$(printf '%s' "${_users}" | jq -r --arg u "${BRIDGE_USER}" '.[]? | select(.username==$u) | .id' | head -1)"
if [ -n "${_uid}" ]; then
  say "   já existe (id=${_uid}) — nada a fazer"
else
  # Senha aleatória forte. Vai para arquivo root-only; o maestro troca no 1º login.
  _pw="$(python3 -c 'import secrets,string; a=string.ascii_letters+string.digits+"!@#%^*-_=+"; print("".join(secrets.choice(a) for _ in range(28)))')"
  _body="$(jq -nc --arg u "${BRIDGE_USER}" --arg p "${_pw}" '{username:$u, password:$p}')"
  _created="$(mutate "criaria usuário '${BRIDGE_USER}' com senha aleatória" POST "/users" "${_body}")"
  _uid="$(printf '%s' "${_created}" | jq -r '.id // empty')"
  if [ "${APPLY}" = "1" ] && [ -n "${_uid}" ]; then
    umask 077
    printf 'onion-bridge / Logto tenant default\nusername: %s\npassword: %s\ncriado_em: %s\nTROCAR NO 1o LOGIN. Apagar este arquivo depois.\n' \
      "${BRIDGE_USER}" "${_pw}" "$(date -u +%FT%TZ)" > "${PASS_FILE}"
    chmod 600 "${PASS_FILE}"
    say "   criado (id=${_uid}); senha em ${PASS_FILE} (0600) — NUNCA impressa aqui"
  fi
  unset _pw
fi

# --- 2. API Resource do bridge ---------------------------------------------
step "2. API Resource ${RESOURCE_INDICATOR}"
_res="$(api GET "/resources")"
_rid="$(printf '%s' "${_res}" | jq -r --arg i "${RESOURCE_INDICATOR}" '.[]? | select(.indicator==$i) | .id' | head -1)"
if [ -n "${_rid}" ]; then
  say "   já existe (id=${_rid})"
else
  _created="$(mutate "criaria resource ${RESOURCE_INDICATOR}" POST "/resources" \
    "$(jq -nc --arg i "${RESOURCE_INDICATOR}" '{name:"Onion Bridge", indicator:$i, accessTokenTtl:3600}')")"
  _rid="$(printf '%s' "${_created}" | jq -r '.id // empty')"
  say "   criado (id=${_rid:-DRY-RUN})"
fi

# --- 3. scope bridge:invoke no resource ------------------------------------
step "3. scope ${SCOPE_NAME}"
if [ -n "${_rid}" ] && [ "${APPLY}" = "1" ]; then
  _scopes="$(api GET "/resources/${_rid}/scopes")"
  _sid="$(printf '%s' "${_scopes}" | jq -r --arg s "${SCOPE_NAME}" '.[]? | select(.name==$s) | .id' | head -1)"
  if [ -n "${_sid}" ]; then say "   já existe (id=${_sid})"
  else
    _sid="$(api POST "/resources/${_rid}/scopes" \
      "$(jq -nc --arg s "${SCOPE_NAME}" '{name:$s, description:"Invocar o Agent SDK via onion-bridge"}')" \
      | jq -r '.id // empty')"
    say "   criado (id=${_sid})"
  fi
else
  say "   [DRY-RUN] criaria scope ${SCOPE_NAME}"
fi

# --- 4. app M2M (o chamador SERVIÇO) ---------------------------------------
step "4. apps M2M (um por chamador): ${M2M_CALLERS}"
_m2m_ids=""
for _caller in ${M2M_CALLERS}; do
  _apps="$(api GET "/applications")"
  _one="$(printf '%s' "${_apps}" | jq -r --arg n "${_caller}" '.[]? | select(.name==$n) | .id' | head -1)"
  if [ -n "${_one}" ]; then
    say "   ${_caller}: já existe (id=${_one})"
  else
    _one="$(mutate "criaria app M2M ${_caller}" POST "/applications" \
      "$(jq -nc --arg n "${_caller}" '{name:$n, type:"MachineToMachine", description:"Chamador de servico do onion-bridge (client_credentials)"}')" \
      | jq -r '.id // empty')"
    say "   ${_caller}: criado (id=${_one:-DRY-RUN})"
  fi
  [ -n "${_one}" ] && _m2m_ids="${_m2m_ids} ${_one}"
done
_m2m="$(printf '%s' "${_m2m_ids}" | awk '{print $1}')"   # compat: resumo/passos citam o 1o

# --- 5. app SPA público com PKCE (o chamador HUMANO) -----------------------
# Client PÚBLICO: zero client_secret distribuído no device (o risco que o §3.10 nomeia).
step "5. app SPA 'onion-bridge-pwa' (Authorization Code + PKCE)"
_spa="$(printf '%s' "${_apps}" | jq -r '.[]? | select(.name=="onion-bridge-pwa") | .id' | head -1)"
if [ -n "${_spa}" ]; then say "   já existe (id=${_spa})"
else
  _spa="$(mutate "criaria app SPA onion-bridge-pwa" POST "/applications" \
    '{"name":"onion-bridge-pwa","type":"SPA","description":"PWA do onion-bridge — client publico, PKCE","oidcClientMetadata":{"redirectUris":["https://app.onionevolve.com/callback"],"postLogoutRedirectUris":["https://app.onionevolve.com/"]}}' \
    | jq -r '.id // empty')"
  say "   criado (id=${_spa:-DRY-RUN})"
fi

# --- 5b. redirect URIs do app SPA ------------------------------------------
# A PWA usa a RAIZ como redirect, não /callback: o bridge serve a PWA com um catch-all
# estático SEM fallback de SPA, então /callback daria 404 e exigiria mudar o roteamento do
# servidor. Na raiz o `?code=` chega e o app limpa a URL — zero mudança no servidor.
# /callback fica registrado também, para não quebrar nada que já aponte para lá.
step "5b. redirect URIs do app SPA (raiz + /callback)"
if [ "${APPLY}" = "1" ] && [ -n "${_spa:-}" ]; then
  _cur="$(api GET "/applications/${_spa}" | jq -c '.oidcClientMetadata.redirectUris // []')"
  if printf '%s' "${_cur}" | jq -e 'index("https://app.onionevolve.com/")' >/dev/null 2>&1; then
    say "   raiz já registrada"
  else
    api PATCH "/applications/${_spa}" \
      '{"oidcClientMetadata":{"redirectUris":["https://app.onionevolve.com/","https://app.onionevolve.com/callback"],"postLogoutRedirectUris":["https://app.onionevolve.com/"]}}' >/dev/null
    say "   raiz adicionada aos redirect URIs"
  fi
  # Refresh token: sem isto o humano re-loga a cada hora (accessTokenTtl=3600).
  if api GET "/applications/${_spa}" | jq -e '.customClientMetadata.alwaysIssueRefreshToken == true' >/dev/null 2>&1; then
    say "   refresh token já habilitado"
  else
    api PATCH "/applications/${_spa}" \
      '{"customClientMetadata":{"alwaysIssueRefreshToken":true,"refreshTokenTtlInDays":14}}' >/dev/null
    say "   refresh token habilitado (14 dias)"
  fi
else
  say "   [DRY-RUN ou app ausente] registraria a raiz e habilitaria refresh token"
fi

# --- 6. role bridge-operator + scope + atribuicao ao app M2M ---------------
# Sem role o app M2M NAO recebe bridge:invoke — o token sai sem scope e o gate do §3.3
# (que exige scope, nao so audiencia) recusa. Este passo faltou na 1a versao do script:
# o plano listava "role + scope atribuida" e o codigo parava no scope do resource.
step "6. role ${ROLE_NAME} (M2M) + scope + atribuição ao app de serviço"
if [ "${APPLY}" = "1" ] && [ -n "${_sid:-}" ] && [ -n "${_m2m:-}" ]; then
  _roles="$(api GET "/roles")"
  _rlid="$(printf '%s' "${_roles}" | jq -r --arg n "${ROLE_NAME}" '.[]? | select(.name==$n) | .id' | head -1)"
  if [ -n "${_rlid}" ]; then
    say "   role já existe (id=${_rlid})"
  else
    _rlid="$(api POST "/roles" "$(jq -nc --arg n "${ROLE_NAME}" --arg s "${_sid}" \
      '{name:$n, description:"Invocar o onion-bridge", type:"MachineToMachine", scopeIds:[$s]}')" \
      | jq -r '.id // empty')"
    say "   role criada (id=${_rlid:-FALHOU})"
  fi
  if [ -n "${_rlid}" ]; then
      _apps_of_role="$(api GET "/roles/${_rlid}/applications")"
      for _aid in ${_m2m_ids}; do
        if printf '%s' "${_apps_of_role}" | jq -e --arg a "${_aid}" '.[]? | select(.id==$a)' >/dev/null 2>&1; then
          say "   app ${_aid}: já atribuído à role"
        else
          api POST "/roles/${_rlid}/applications" "$(jq -nc --arg a "${_aid}" '{applicationIds:[$a]}')" >/dev/null
          say "   app ${_aid}: atribuído à role"
        fi
      done
    fi
else
  say "   [DRY-RUN ou pré-requisito ausente] criaria role ${ROLE_NAME} e atribuiria ao app M2M"
fi

# --- 7. role de USUÁRIO + atribuição ao humano -----------------------------
# BURACO FECHADO 2026-07-27: o passo 6 criava só a role M2M. Um usuário humano SEM role sai com
# token sem `bridge:invoke`, e o requireScope do bridge recusa — o login funcionaria e o acesso
# não, que é o pior desfecho possível (parece configurado, não é). Role de usuário é OUTRO tipo
# no Logto (`type: User`); a M2M não serve para pessoa.
step "7. role ${USER_ROLE_NAME} (User) + scope + atribuição a '${BRIDGE_USER}'"
if [ "${APPLY}" = "1" ] && [ -n "${_sid:-}" ] && [ -n "${_uid:-}" ]; then
  _roles="$(api GET "/roles")"
  _urid="$(printf '%s' "${_roles}" | jq -r --arg n "${USER_ROLE_NAME}" '.[]? | select(.name==$n) | .id' | head -1)"
  if [ -n "${_urid}" ]; then
    say "   role já existe (id=${_urid})"
  else
    _urid="$(api POST "/roles" "$(jq -nc --arg n "${USER_ROLE_NAME}" --arg s "${_sid}" \
      '{name:$n, description:"Humano que opera o onion-bridge pela PWA", type:"User", scopeIds:[$s]}')" \
      | jq -r '.id // empty')"
    say "   role criada (id=${_urid:-FALHOU})"
  fi
  if [ -n "${_urid}" ]; then
    _users_of_role="$(api GET "/roles/${_urid}/users")"
    if printf '%s' "${_users_of_role}" | jq -e --arg u "${_uid}" '.[]? | select(.id==$u)' >/dev/null 2>&1; then
      say "   usuário já atribuído à role"
    else
      api POST "/roles/${_urid}/users" "$(jq -nc --arg u "${_uid}" '{userIds:[$u]}')" >/dev/null
      say "   usuário atribuído à role"
    fi
  fi
else
  say "   [DRY-RUN ou pré-requisito ausente] criaria role ${USER_ROLE_NAME} e atribuiria ao usuário"
fi

# --- 8. scope bridge:admin + role de admin humano (P9) ---------------------
# O flip (P7) fechou o authGuard, mas adminGuard e a2aGuard eram guards SEPARADOS que
# comparavam direto com AUTH_TOKEN — logo o segredo compartilhado seguia abrindo /admin/*
# (incluindo POST /admin/tokens, que CUNHA convites) enquanto o token OIDC do humano NÃO
# abria. Estado invertido: o velho entrava, o novo não. Este passo cria a autorização de
# admin como IDENTIDADE, pré-requisito para aposentar o AUTH_TOKEN de vez.
step "8. scope ${ADMIN_SCOPE} + admin por identidade (P9)"
if [ "${APPLY}" = "1" ] && [ -n "${_rid:-}" ] && [ -n "${_urid:-}" ]; then
  _scopes="$(api GET "/resources/${_rid}/scopes")"
  _asid="$(printf '%s' "${_scopes}" | jq -r --arg s "${ADMIN_SCOPE}" '.[]? | select(.name==$s) | .id' | head -1)"
  if [ -n "${_asid}" ]; then
    say "   scope já existe (id=${_asid})"
  else
    _asid="$(api POST "/resources/${_rid}/scopes" \
      "$(jq -nc --arg s "${ADMIN_SCOPE}" '{name:$s, description:"Administrar o onion-bridge (stats, cunhar/revogar convites)"}')" \
      | jq -r '.id // empty')"
    say "   scope criado (id=${_asid:-FALHOU})"
  fi
  # Só a role HUMANA recebe admin. O app de serviço NÃO — um chamador M2M não precisa
  # cunhar convites, e conceder por conveniência é como o menor privilégio morre.
  if [ -n "${_asid}" ]; then
    _rs="$(api GET "/roles/${_urid}/scopes")"
    if printf '%s' "${_rs}" | jq -e --arg s "${_asid}" '.[]? | select(.id==$s)' >/dev/null 2>&1; then
      say "   role humana já tem ${ADMIN_SCOPE}"
    else
      api POST "/roles/${_urid}/scopes" "$(jq -nc --arg s "${_asid}" '{scopeIds:[$s]}')" >/dev/null
      say "   ${ADMIN_SCOPE} concedido à role humana (serviço NÃO recebe — menor privilégio)"
    fi
  fi
else
  say "   [DRY-RUN ou pré-requisito ausente] criaria ${ADMIN_SCOPE} e concederia à role humana"
fi

# --- 9. scope bridge:write + capacidade por identidade (P10) ----------------
# P0-P9 fecharam QUEM entra. Nao tocaram O QUE se pode fazer: `bridge:invoke` era
# tudo-ou-nada e todo chamador autenticado executava irrestrito (PERMISSION_MODE=
# bypassPermissions). O ganho real da identidade e poder DIFERENCIAR — sem isto,
# trocamos "quem tem o segredo faz tudo" por "quem tem identidade faz tudo".
# Sem este scope o chamador LE e PROPOE (Read/Grep/Glob/WebFetch/WebSearch/TodoWrite);
# com ele, o conjunto completo. A restricao vive em `tools` do Agent SDK — NAO em
# `allowedTools`, que a doc do pacote diz explicitamente que so AUTO-APROVA, nao limita.
step "9. scope ${WRITE_SCOPE} + capacidade por identidade (P10)"
if [ "${APPLY}" = "1" ] && [ -n "${_rid:-}" ] && [ -n "${_urid:-}" ]; then
  _scopes2="$(api GET "/resources/${_rid}/scopes")"
  _wsid="$(printf '%s' "${_scopes2}" | jq -r --arg s "${WRITE_SCOPE}" '.[]? | select(.name==$s) | .id' | head -1)"
  if [ -n "${_wsid}" ]; then
    say "   scope já existe (id=${_wsid})"
  else
    _wsid="$(api POST "/resources/${_rid}/scopes" \
      "$(jq -nc --arg s "${WRITE_SCOPE}" '{name:$s, description:"Escrever e executar (Bash, Write, Edit). Sem ele: so leitura e proposta"}')" \
      | jq -r '.id // empty')"
    say "   scope criado (id=${_wsid:-FALHOU})"
  fi
  # Mesma regra do admin: só a role HUMANA. Um chamador M2M que so precisa consultar
  # nao recebe execucao — e a diferenca fica VISIVEL na medicao, nao afirmada.
  if [ -n "${_wsid}" ]; then
    _rs2="$(api GET "/roles/${_urid}/scopes")"
    if printf '%s' "${_rs2}" | jq -e --arg s "${_wsid}" '.[]? | select(.id==$s)' >/dev/null 2>&1; then
      say "   role humana já tem ${WRITE_SCOPE}"
    else
      api POST "/roles/${_urid}/scopes" "$(jq -nc --arg s "${_wsid}" '{scopeIds:[$s]}')" >/dev/null
      say "   ${WRITE_SCOPE} concedido à role humana (serviço NÃO recebe)"
    fi
  fi
else
  say "   [DRY-RUN ou pré-requisito ausente] criaria ${WRITE_SCOPE} e concederia à role humana"
fi

step "RESUMO"
say "   modo        : $([ "${APPLY}" = 1 ] && echo APPLY || echo DRY-RUN)"
say "   usuário     : ${BRIDGE_USER} ${_uid:+(id=${_uid})}"
say "   resource    : ${RESOURCE_INDICATOR} ${_rid:+(id=${_rid})}"
say "   app M2M     : ${_m2m:-—}"
say "   app SPA     : ${_spa:-—}"
say ""
say "   NAO FEITO de proposito: desligar o sign_up do tenant DEFAULT (é o P3.4 —"
say "   so depois que o usuario existir, senao tranca o maestro fora)."
