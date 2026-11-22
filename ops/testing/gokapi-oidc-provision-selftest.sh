#!/usr/bin/env bash
# gokapi-oidc-provision-selftest.sh — a bancada do ops/bridge-auth/gokapi-oidc-provision.sh (core-only).
#
# O ato roda no MODO DE TESTE do logto-mapi.sh contra um Logto SIMULADO (um servidor HTTP local em Python, só em
# 127.0.0.1, com o contrato da Management API do Logto 1.46 medido no código da imagem: o secret vem de
# /applications/{id}/secrets, o PATCH com appLevelAccessControlEnabled=true exige regra, o GET /applications sem
# paginação devolve todos). O credstore cai numa raiz em /tmp; docker e curl são falsos no PATH: o docker devolve
# um secret de m-default de mentira, e o curl registra o próprio argv e chama o curl real.
#
# Prova: o dry-run não muta nem grava; o --apply cria o app com o tipo e os redirects certos, põe o operador nas
# regras e liga o controle de acesso, grava os 2 arquivos em 600 com o valor do Logto; nenhum segredo (m-default,
# Bearer, client secret) aparece na saída nem em argv; re-rodar não muta nada nem reescreve arquivo; deriva é
# corrigida; dois apps com o nome, app de outro tipo e operador ausente são recusa sem mutação; falha da API não
# deixa arquivo nem temporário; --check acusa divergência; --undo apaga e é idempotente; variável de teste fora do
# modo de teste é rc 2; --apply sem root fora do teste é rc 11; e o molde (logto-provision.sh) segue rodando o
# dry-run sobre a biblioteca extraída.
#
# Uso: bash ops/testing/gokapi-oidc-provision-selftest.sh   (rc 0 = verde)
set -uo pipefail
export LC_ALL=C
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACT="${HERE}/bridge-auth/gokapi-oidc-provision.sh"
MOLDE="${HERE}/bridge-auth/logto-provision.sh"
t="$(mktemp -d /tmp/gokapi-oidc-selftest.XXXXXX)"
STUB_PID=""
trap '[ -n "${STUB_PID}" ] && kill "${STUB_PID}" 2>/dev/null; rm -rf "${t}"' EXIT
fails=0; ok=0
chk() { if [ "$2" = 0 ]; then ok=$((ok + 1)); echo "  ✓ $1"; else fails=$((fails + 1)); echo "  ✗ $1"; sed 's/^/      /' "${t}/out" 2>/dev/null | tail -6; fi; }

MDEF_SECRET="MDEFSECRET0123456789abcdef"
TOKEN="TOKSTUB0123456789abcdef"
REAL_CURL="$(command -v curl)"
mkdir -p "${t}/bin" "${t}/root"

# docker falso: no modo de teste o ato NUNCA deve chamá-lo (o secret de mentira vem do ambiente); se chamar, fica
# registrado e o caso 13 reprova. Existe só para o pré-requisito `command -v docker` do ato.
printf '#!/usr/bin/env bash\necho "$*" >> "%s/docker.log"\nexit 1\n' "${t}" > "${t}/bin/docker"
# chmod falso: com ${t}/fail-chmod, falha (o caso do temporário que tem de sumir); sem ele, o chmod real
printf '#!/usr/bin/env bash\n[ -e "%s/fail-chmod" ] && exit 1\nPATH="${PATH#*:}" exec chmod "$@"\n' "${t}" > "${t}/bin/chmod"
# curl falso: registra o argv (uma linha por chamada) e chama o real
cat > "${t}/bin/curl" <<F
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "${t}/argv.log"
exec "${REAL_CURL}" "\$@"
F
# sudo falso: a bancada nunca alcança o docker real (o caso «m-default ilegível» chegou lá pelo fallback do sudo)
printf '#!/usr/bin/env bash\necho "$*" >> "%s/sudo.log"\nexit 1\n' "${t}" > "${t}/bin/sudo"
chmod +x "${t}/bin/"*

# ── o Logto simulado ────────────────────────────────────────────────────────────────────────────────────────────
cat > "${t}/stub.py" <<'PY'
import base64, json, os, secrets, sys, urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer
D = sys.argv[1]; MDEF = sys.argv[2]; TOK = sys.argv[3]
SF = os.path.join(D, "state.json"); LOG = os.path.join(D, "requests.log")
def load():
    with open(SF) as f: return json.load(f)
def save(s):
    with open(SF + ".tmp", "w") as f: json.dump(s, f)
    os.replace(SF + ".tmp", SF)
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def send(self, code, obj=None):
        body = b"" if obj is None else json.dumps(obj).encode()
        self.send_response(code); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        return self.rfile.read(n) if n else b""
    def handle_any(self, m):
        u = urllib.parse.urlsplit(self.path); p = u.path; q = urllib.parse.parse_qs(u.query)
        raw = self.body()
        with open(LOG, "a") as f: f.write(f"{m} {p}\n")
        s = load()
        for k, code in s.get("fail", {}).items():
            if f"{m} {p}".startswith(k): return self.send(code, {"code": "stub.fail", "message": "falha plantada"})
        if p == "/oidc/.well-known/openid-configuration":
            return self.send(200, {"issuer": "https://console.onionevolve.com/oidc", "scopes_supported": s["scopes"]})
        if p == "/oidc/token" and m == "POST":
            want = "Basic " + base64.b64encode(f"m-default:{MDEF}".encode()).decode()
            if self.headers.get("Authorization") != want: return self.send(400, {"error": "invalid_client"})
            return self.send(200, {"access_token": TOK, "token_type": "Bearer"})
        if not p.startswith("/api/"): return self.send(404, {"code": "not_found"})
        if self.headers.get("Authorization") != f"Bearer {TOK}": return self.send(401, {"code": "auth.unauthorized"})
        parts = p[len("/api/"):].strip("/").split("/")
        data = json.loads(raw) if raw else {}
        apps = s["apps"]
        def app(i): return next((a for a in apps if a["id"] == i), None)
        if parts == ["sign-in-exp"] and m == "GET": return self.send(200, {"signInMode": s["signInMode"]})
        if parts == ["users"] and m == "GET":
            term = (q.get("search") or [""])[0]
            return self.send(200, [x for x in s["users"] if term in x["username"]])
        if parts == ["applications"]:
            if m == "GET": return self.send(200, apps)
            if m == "POST":
                i = "app" + secrets.token_hex(4)
                a = {"id": i, "name": data["name"], "type": data["type"], "description": data.get("description"),
                     "oidcClientMetadata": data.get("oidcClientMetadata", {}), "appLevelAccessControlEnabled": False}
                apps.append(a)
                s["secrets"][i] = [{"name": "Default secret", "value": "APPSECRET" + secrets.token_hex(16), "expiresAt": None}]
                save(s); return self.send(200, a)
        if len(parts) >= 2 and parts[0] == "applications":
            a = app(parts[1])
            if a is None: return self.send(404, {"code": "entity.not_exists"})
            acl = s["acl"].setdefault(a["id"], {"userIds": [], "userRoleIds": [], "organizationIds": [], "organizationRoleRules": []})
            if len(parts) == 2:
                if m == "GET": return self.send(200, a)
                if m == "PATCH":
                    if data.get("appLevelAccessControlEnabled") is True and not any([acl["userIds"], acl["userRoleIds"], acl["organizationIds"]]):
                        return self.send(422, {"code": "request.invalid_input", "message": "Application access control must include at least one rule"})
                    a.update(data); save(s); return self.send(200, a)
                if m == "DELETE":
                    s["apps"] = [x for x in apps if x["id"] != a["id"]]; s["secrets"].pop(a["id"], None); s["acl"].pop(a["id"], None)
                    save(s); return self.send(204)
            if parts[2:] == ["secrets"] and m == "GET": return self.send(200, s["secrets"].get(a["id"], []))
            if parts[2:] == ["access-control"]:
                if m == "GET": save(s); return self.send(200, acl)
                if m == "PUT": s["acl"][a["id"]] = data; save(s); return self.send(200, data)
        if m == "GET": return self.send(200, [])   # o resto (o molde lê /resources, /roles…): vazio
        return self.send(404, {"code": "not_found"})
    def do_GET(self): self.handle_any("GET")
    def do_POST(self): self.handle_any("POST")
    def do_PATCH(self): self.handle_any("PATCH")
    def do_PUT(self): self.handle_any("PUT")
    def do_DELETE(self): self.handle_any("DELETE")
srv = HTTPServer(("127.0.0.1", 0), H)
with open(os.path.join(D, "port"), "w") as f: f.write(str(srv.server_address[1]))
srv.serve_forever()
PY

reset_state() { # reset_state [json-extra-jq]
  jq -n --arg e "${1:-.}" '{signInMode:"SignIn", scopes:["openid","profile","email","offline_access"],
    users:[{id:"uop000000001", username:"marcio"}], apps:[], secrets:{}, acl:{}, fail:{}}' | jq "${1:-.}" > "${t}/state.json"
  : > "${t}/requests.log"; : > "${t}/argv.log"
}
reset_state
python3 -I "${t}/stub.py" "${t}" "${MDEF_SECRET}" "${TOKEN}" > "${t}/stub.log" 2>&1 &
STUB_PID=$!
for _ in $(seq 1 50); do [ -s "${t}/port" ] && break; sleep 0.1; done
[ -s "${t}/port" ] || { echo "selftest: o Logto simulado não subiu"; cat "${t}/stub.log"; exit 1; }
BASE="http://127.0.0.1:$(cat "${t}/port")"
CS="${t}/root/etc/credstore"; FID="${CS}/onion-vps-gokapi.oidc-client-id"; FSEC="${CS}/onion-vps-gokapi.oidc-client-secret"

run() { # run <script> [args…] → rc em ${t}/rc, saída em ${t}/out
  env PATH="${t}/bin:${PATH}" ONION_LOGTO_MAPI_TEST=1 ONION_LOGTO_MAPI_BASE="${BASE}" ONION_LOGTO_MAPI_ROOT="${t}/root" \
    ONION_LOGTO_MAPI_MDEF_SECRET="${MDEF-${MDEF_SECRET}}" bash "$@" > "${t}/out" 2>&1
  echo $? > "${t}/rc"
}
rc() { cat "${t}/rc"; }
mutations() { grep -cE '^(POST /api|PUT|PATCH|DELETE)' "${t}/requests.log" || true; }
app_json() { jq -c '.apps[] | select(.name=="onion-vps-gokapi")' "${t}/state.json"; }
app_secret() { jq -r --arg i "$(app_json | jq -r .id)" '.secrets[$i][0].value' "${t}/state.json"; }
no_leak() { # nenhum segredo na saída nem no argv do curl
  ! grep -qE "${MDEF_SECRET}|${TOKEN}|APPSECRET" "${t}/out" && ! grep -qE "${MDEF_SECRET}|${TOKEN}|APPSECRET" "${t}/argv.log"
}

echo "── gokapi-oidc-provision: bancada (Logto simulado em ${BASE})"

# 1. dry-run num tenant sem o app: só lê
run "${ACT}"
chk "dry-run: rc 0, nenhuma mutação na API, nenhum arquivo no credstore" \
  "$([ "$(rc)" = 0 ] && [ "$(mutations)" = 0 ] && [ ! -e "${FID}" ] && [ ! -e "${FSEC}" ] && grep -q 'DRY-RUN' "${t}/out"; echo $?)"

# 2. --apply: cria o app certo, liga o controle de acesso e grava os dois arquivos
run "${ACT}" --apply
A="$(app_json)"
chk "--apply: app Traditional com redirect e post sign-out exatos" \
  "$([ "$(rc)" = 0 ] && [ "$(jq -r .type <<< "${A}")" = Traditional ] \
     && [ "$(jq -c .oidcClientMetadata.redirectUris <<< "${A}")" = '["https://transfer.onionevolve.com/oauth-callback"]' ] \
     && [ "$(jq -c .oidcClientMetadata.postLogoutRedirectUris <<< "${A}")" = '["https://transfer.onionevolve.com/"]' ]; echo $?)"
chk "--apply: o operador está nas regras do app e o controle de acesso está ligado" \
  "$(jq -e --arg i "$(jq -r .id <<< "${A}")" '.acl[$i].userIds == ["uop000000001"]' "${t}/state.json" >/dev/null \
     && [ "$(jq -r .appLevelAccessControlEnabled <<< "${A}")" = true ]; echo $?)"
chk "--apply: client id e client secret no credstore, iguais ao Logto, sem quebra de linha" \
  "$(cmp -s <(printf '%s' "$(jq -r .id <<< "${A}")") "${FID}" && cmp -s <(printf '%s' "$(app_secret)") "${FSEC}"; echo $?)"
chk "--apply: os dois arquivos em 600 e o diretório em 700; nenhum temporário sobrou" \
  "$([ "$(stat -c %a "${FID}")" = 600 ] && [ "$(stat -c %a "${FSEC}")" = 600 ] && [ "$(stat -c %a "${CS}")" = 700 ] \
     && [ -z "$(find "${CS}" -name '.onion-vps-gokapi.*')" ]; echo $?)"
chk "--apply: nenhum segredo (m-default, Bearer, client secret) na saída nem no argv do curl" "$(no_leak; echo $?)"
chk "--apply: a saída mostra o client id público" "$(grep -q "client id=$(jq -r .id <<< "${A}")" "${t}/out"; echo $?)"

# 3. re-rodar: nada muda, nada é reescrito
ino1="$(stat -c '%i %Y' "${FID}" "${FSEC}")"; : > "${t}/requests.log"
sleep 1
run "${ACT}" --apply
chk "re-rodar --apply: rc 0, zero mutação, um app só, arquivos não reescritos (mesmo inode e mtime)" \
  "$([ "$(rc)" = 0 ] && [ "$(mutations)" = 0 ] && [ "$(jq '[.apps[]|select(.name=="onion-vps-gokapi")]|length' "${t}/state.json")" = 1 ] \
     && [ "$(stat -c '%i %Y' "${FID}" "${FSEC}")" = "${ino1}" ] && grep -q 'não reescrito' "${t}/out"; echo $?)"

# 3b. dry-run com o app existente e um arquivo faltando: diz o que faria e não grava
mv "${FSEC}" "${t}/fsec.bak"; : > "${t}/requests.log"
run "${ACT}"
chk "dry-run com app existente e secret ausente: anuncia, não grava, zero mutação" \
  "$([ "$(rc)" = 0 ] && [ ! -e "${FSEC}" ] && [ "$(mutations)" = 0 ] && grep -q 'DRY-RUN\] client secret: seria criado' "${t}/out" && no_leak; echo $?)"
mv "${t}/fsec.bak" "${FSEC}"

# 4. --check bate; depois o arquivo diverge e o --check acusa (rc 10) sem mostrar o valor
run "${ACT}" --check
chk "--check: credstore == Logto, rc 0" "$([ "$(rc)" = 0 ] && grep -q 'credstore == Logto' "${t}/out"; echo $?)"
printf 'outro-valor\n' > "${FSEC}"
run "${ACT}" --check
chk "--check: secret divergente é rc 10, sem segredo na saída" "$([ "$(rc)" = 10 ] && no_leak; echo $?)"

# 5. deriva: redirect mexido no Logto e secret divergente no arquivo → --apply corrige os dois
jq '(.apps[] | select(.name=="onion-vps-gokapi") | .oidcClientMetadata) = {redirectUris:["https://evil.example/cb"], postLogoutRedirectUris:[], logoUri:"https://x/logo.png"}' \
  "${t}/state.json" > "${t}/s2" && mv "${t}/s2" "${t}/state.json"
: > "${t}/requests.log"
run "${ACT}" --apply
chk "deriva: o PATCH devolve os redirects ao estado exato e o secret é regravado do Logto" \
  "$([ "$(rc)" = 0 ] && grep -q '^PATCH /api/applications/' "${t}/requests.log" \
     && [ "$(app_json | jq -c .oidcClientMetadata.redirectUris)" = '["https://transfer.onionevolve.com/oauth-callback"]' ] \
     && cmp -s <(printf '%s' "$(app_secret)") "${FSEC}" && [ "$(stat -c %a "${FSEC}")" = 600 ] && no_leak; echo $?)"
chk "deriva: o PATCH preserva o resto do oidcClientMetadata (o Logto substitui o objeto inteiro)" \
  "$([ "$(app_json | jq -r .oidcClientMetadata.logoUri)" = "https://x/logo.png" ]; echo $?)"

# 5b. o chmod falha no meio da escrita: rc ≠ 0 e nenhum temporário (com o valor dentro) fica no credstore
rm -f "${FSEC}"; touch "${t}/fail-chmod"
run "${ACT}" --apply
rm -f "${t}/fail-chmod"
chk "falha no meio da escrita: rc ≠ 0, nenhum temporário sobra no credstore" \
  "$([ "$(rc)" != 0 ] && [ -z "$(find "${CS}" -name '.onion-vps-gokapi.*')" ] && [ ! -e "${FSEC}" ]; echo $?)"

# 6. dois apps com o mesmo nome: recusa (rc 8) sem mutar
reset_state '.apps = [{id:"a1",name:"onion-vps-gokapi",type:"Traditional",oidcClientMetadata:{}},{id:"a2",name:"onion-vps-gokapi",type:"Traditional",oidcClientMetadata:{}}] | .secrets = {a1:[{name:"Default secret",value:"APPSECRETa1",expiresAt:null}],a2:[{name:"Default secret",value:"APPSECRETa2",expiresAt:null}]}'
rm -rf "${CS}"
run "${ACT}" --apply
chk "dois apps com o nome: rc 8, zero mutação, nenhum arquivo" "$([ "$(rc)" = 8 ] && [ "$(mutations)" = 0 ] && [ ! -e "${FID}" ] && grep -q "há 2 apps" "${t}/out"; echo $?)"

# 7. app com o nome mas de outro tipo: recusa (rc 8) sem mutar
reset_state '.apps = [{id:"a3",name:"onion-vps-gokapi",type:"SPA",oidcClientMetadata:{}}] | .secrets = {a3:[{name:"Default secret",value:"APPSECRETa3",expiresAt:null}]}'
run "${ACT}" --apply
chk "app de outro tipo: rc 8, zero mutação" "$([ "$(rc)" = 8 ] && [ "$(mutations)" = 0 ] && grep -q "do tipo SPA" "${t}/out"; echo $?)"

# 8. operador ausente: recusa (rc 7) antes de criar o app
reset_state '.users = []'
run "${ACT}" --apply
chk "operador ausente: rc 7, nenhum app criado" "$([ "$(rc)" = 7 ] && [ "$(mutations)" = 0 ]; echo $?)"

# 9. a API recusa o POST do app: rc 9, nenhum arquivo nem temporário
reset_state '.fail = {"POST /api/applications": 500}'
run "${ACT}" --apply
chk "API recusa a criação: rc 9, credstore vazio" "$([ "$(rc)" = 9 ] && [ -z "$(find "${t}/root" -type f 2>/dev/null)" ]; echo $?)"

# 10. app sem secret inequívoco (dois válidos, nenhum «Default secret») e com deriva, ACL vazia e controle desligado:
#     rc 8 ANTES de qualquer mutação, nada gravado
reset_state '.apps = [{id:"a4",name:"onion-vps-gokapi",type:"Traditional",oidcClientMetadata:{redirectUris:["https://evil.example/cb"],postLogoutRedirectUris:[]},appLevelAccessControlEnabled:false}]
  | .secrets = {a4:[{name:"s1",value:"APPSECRETone",expiresAt:null},{name:"s2",value:"APPSECRETtwo",expiresAt:null}]}'
run "${ACT}" --apply
chk "secret ambíguo: rc 8 antes de mutar (zero PATCH/PUT), nenhum arquivo, nada vazado" "$([ "$(rc)" = 8 ] && [ "$(mutations)" = 0 ] && [ ! -e "${FSEC}" ] && no_leak; echo $?)"

# 11. tenant com cadastro aberto: avisa e segue (o controle de acesso do app segura)
reset_state '.signInMode = "SignInAndRegister"'
run "${ACT}" --apply
chk "tenant aberto: aviso explícito, app provisionado com o controle de acesso ligado" \
  "$([ "$(rc)" = 0 ] && grep -q 'ACEITA cadastro' "${t}/out" && [ "$(app_json | jq -r .appLevelAccessControlEnabled)" = true ]; echo $?)"

# 12. --undo: ensaio não apaga; --apply apaga app e arquivos; 2ª vez é no-op
: > "${t}/requests.log"
run "${ACT}" --undo
chk "--undo sem --apply: nada apagado" "$([ "$(rc)" = 0 ] && [ "$(mutations)" = 0 ] && [ -e "${FSEC}" ]; echo $?)"
run "${ACT}" --undo --apply
chk "--undo --apply: app e os 2 arquivos apagados" "$([ "$(rc)" = 0 ] && [ -z "$(app_json)" ] && [ ! -e "${FID}" ] && [ ! -e "${FSEC}" ]; echo $?)"
: > "${t}/requests.log"
run "${ACT}" --undo --apply
chk "--undo de novo: rc 0, zero mutação" "$([ "$(rc)" = 0 ] && [ "$(mutations)" = 0 ]; echo $?)"

# 13. pré-flight e token: issuer errado é rc 6; m-default ilegível é rc 4
reset_state
MDEF="" run "${ACT}"
chk "m-default ilegível: rc 4, e o modo de teste nunca chama docker nem sudo (em nenhum caso até aqui)" \
  "$([ "$(rc)" = 4 ] && [ ! -e "${t}/sudo.log" ] && [ ! -e "${t}/docker.log" ]; echo $?)"
env PATH="${t}/bin:${PATH}" ONION_LOGTO_MAPI_TEST=1 ONION_LOGTO_MAPI_BASE="http://127.0.0.1:9" ONION_LOGTO_MAPI_ROOT="${t}/root" \
  bash "${ACT}" > "${t}/out" 2>&1; echo $? > "${t}/rc"
chk "issuer do tenant admin inalcançável: rc 6 com o ponteiro do console.sh" "$([ "$(rc)" = 6 ] && grep -q 'console.sh on' "${t}/out"; echo $?)"

# 14. variável de teste fora do modo de teste: rc 2, sem rede
: > "${t}/argv.log"
env PATH="${t}/bin:${PATH}" ONION_LOGTO_MAPI_BASE="${BASE}" bash "${ACT}" > "${t}/out" 2>&1; echo $? > "${t}/rc"
chk "ONION_LOGTO_MAPI_* sem o modo de teste: rc 2, nenhuma chamada de rede" "$([ "$(rc)" = 2 ] && [ ! -s "${t}/argv.log" ]; echo $?)"

# 15. base de teste fora do loopback: rc 2
env PATH="${t}/bin:${PATH}" ONION_LOGTO_MAPI_TEST=1 ONION_LOGTO_MAPI_BASE="http://example.com:80" ONION_LOGTO_MAPI_ROOT="${t}/root" \
  bash "${ACT}" > "${t}/out" 2>&1; echo $? > "${t}/rc"
chk "base de teste fora de 127.0.0.1: rc 2" "$([ "$(rc)" = 2 ]; echo $?)"
env PATH="${t}/bin:${PATH}" ONION_LOGTO_MAPI_TEST=1 ONION_LOGTO_MAPI_BASE="${BASE}" ONION_LOGTO_MAPI_ROOT="/tmp/.." \
  bash "${ACT}" > "${t}/out" 2>&1; echo $? > "${t}/rc"
chk "raiz de teste que escapa de /tmp por '..': rc 2" "$([ "$(rc)" = 2 ]; echo $?)"

# 16. --apply sem root e fora do teste: rc 11 antes de qualquer rede
if [ "$(id -u)" != 0 ]; then
  : > "${t}/argv.log"
  env PATH="${t}/bin:${PATH}" bash "${ACT}" --apply > "${t}/out" 2>&1; echo $? > "${t}/rc"
  chk "--apply sem root: rc 11, nenhuma chamada de rede" "$([ "$(rc)" = 11 ] && [ ! -s "${t}/argv.log" ]; echo $?)"
else
  ok=$((ok + 1)); echo "  ✓ --apply sem root: (rodando como root — o caso não se aplica, contado)"
fi

# 17. o molde segue de pé sobre a biblioteca extraída: dry-run rc 0, zero mutação, nada vazado
reset_state
run "${MOLDE}"
chk "molde logto-provision.sh: dry-run rc 0 sobre o logto-mapi.sh, zero mutação, nada vazado" \
  "$([ "$(rc)" = 0 ] && [ "$(mutations)" = 0 ] && grep -q 'token obtido' "${t}/out" && no_leak; echo $?)"

echo "selftest: ${ok} ok · ${fails} falha(s)"
[ "${fails}" = 0 ]
