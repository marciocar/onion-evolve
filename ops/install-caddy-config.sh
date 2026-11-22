#!/usr/bin/env bash
# install-caddy-config.sh — instala a config versionada do Caddy (ops/caddy/Caddyfile e os
# vhosts GERIDOS em ops/caddy/conf.d/*.caddy) em /etc/caddy, com validação, backup, reload
# gracioso e rollback.
#
# POR QUE EXISTE (medido 2026-08-26): o Caddyfile do onionevolve.com vivia SÓ na VPS,
# com backups à mão em /root/Caddyfile.bak-* — a mesma anomalia que bridge-backup.sh
# declara e que a doutrina de gpg-protect-key.sh condena ("temporário evapora vira
# incidente"). Nesta sessão isso já custou um bug de cache invisível. Agora o git é a
# SSOT e este script é a única porta de /etc/caddy — derivação, não edição à mão.
#
# CONF.D GERIDO (2026-10-08, 1º vhost de conf.d versionado): os vhosts de /etc/caddy/conf.d/ nasceram fora do git
# (vault, waha, chat…). A partir daqui, um vhost NOVO nasce versionado em ops/caddy/conf.d/ e é
# instalado por este script. Os que já estão no vivo sem fonte no repo são NÃO GERIDOS: este script
# não os lê para escrever, não os altera e não os remove — só os copia para a validação em estágio.
#   · Marcadores @@NOME@@ no conf.d versionado são resolvidos de /etc/caddy/secrets/<site>.env
#     (root 0600, escrito por ops/caddy-site-secrets.sh). Marcador sem valor, ou valor vazio,
#     RECUSA a instalação: um cookie vazio viraria `*cookie=*` e abriria a API (fail-open).
#   · O arquivo instalado leva na 1ª linha o carimbo MANAGED_MARK. É por ele que o script sabe o
#     que é dele: um vivo carimbado cuja fonte saiu do repo é removido (com backup).
#   · O vivo renderizado fica 0640 root:caddy, porque carrega segredo.
#   · Linhas `# verify: <url> <código>` no conf.d versionado entram na verificação comportamental.
#
# VHOSTS DOS REPOS DE SERVIÇO (2026-11-22, cards SAC-465 e #70 do core): librechat, vault, waha e gokapi moram no
# repo do próprio serviço (`caddy/<nome>.caddy`), e o core segue dono do Caddy. A lista é ops/caddy/service-vhosts.tsv
# (nome no conf.d · clone local · ref · caminho · hosts permitidos). O que muda para esses vhosts:
#   · a fonte é o BLOB COMMITADO na ref (`git show <ref>:<caminho>`), nunca a árvore de trabalho do clone: mudança
#     local sem commit não vai para o ar. O script não faz fetch nem escreve no clone, só lê;
#   · o carimbo é OUTRO, SERVICE_MARK, com a fonte `<repo>:<caminho>`, e de propósito não contém o MANAGED_MARK: a
#     versão anterior deste script remove todo vivo com MANAGED_MARK sem fonte em ops/caddy/conf.d, e um revert ou
#     um checkout velho derrubaria os vhosts de serviço como órfãos (refutador, 2026-11-22). Os arquivos dos repos
#     NÃO trazem carimbo (medido em 2026-11-22: a 1ª linha é comentário livre). Conferir a deriva à mão:
#     `tail -n +2 <vivo> | cmp <fonte> -` (vale com a fonte terminando numa quebra de linha só: o install normaliza o fim);
#   · ADOÇÃO: o vivo não gerido de mesmo nome só é adotado se for byte a byte igual à fonte (a cópia que os PRs dos
#     repos mediram). Diferente, recusa: alguém mexeu à mão ou o repo divergiu, e a decisão é do maestro;
#   · todo site do arquivo tem de estar na coluna de hosts: um repo de serviço não declara o domínio de outro;
#   · fonte ausente na ref (PR ainda aberto) é PENDENTE: o vivo fica como está, e nada se remove por isso. Só é
#     órfão o carimbado cujo nome não está nem em ops/caddy/conf.d nem na lista;
#   · sem `# verify:` na fonte, a verificação cobra que cada host responda (código ≠ 000) depois do reload.
#
# GUARDAS POR CONSTRUÇÃO (não por disciplina), fundadas na pesquisa de estado da arte 2026:
#  1. PRÉ-VOO: `caddy validate` num ESTÁGIO (Caddyfile + conf.d final) antes de tocar o vivo.
#  2. BACKUP timestamped do Caddyfile e de cada conf.d gerido ANTES do cp.
#  3. RELOAD, nunca restart (gracioso, zero-downtime); se o reload falhar, ROLLBACK do backup.
#  4. Verificação por COMPORTAMENTO (curl nos vhosts + no header), não por grep no arquivo.
#  5. --check é read-only e ACUSA drift (Caddyfile e conf.d gerido); FORA da VPS, CALA.
#  6. --selftest roda em sandbox com stubs de caddy/systemctl — sem sudo, sem tocar o real.
#
# Uso:
#   ops/install-caddy-config.sh             # valida, faz backup, instala e recarrega (na KVM 8)
#   ops/install-caddy-config.sh --plan      # ENSAIO: o que o install mudaria + validação do estágio; não toca o vivo
#   ops/install-caddy-config.sh --check     # read-only: acusa drift fonte×/etc/caddy (exit 1 se houver)
#   ops/install-caddy-config.sh --selftest  # bancada em sandbox (nunca toca /etc nem recarrega)
set -euo pipefail
set -f
export LC_ALL=C

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO}/ops/caddy/Caddyfile"
DEST="/etc/caddy/Caddyfile"
CONF_SRC_DIR="${REPO}/ops/caddy/conf.d"
SERVICE_TSV="${REPO}/ops/caddy/service-vhosts.tsv"   # vhosts que moram nos repos de serviço
CONF_DEST_DIR="/etc/caddy/conf.d"
SECRETS_DIR="/etc/caddy/secrets"
CONF_OWNER="root:caddy"               # o selftest esvazia (sandbox sem root)
BACKUP_DIR="/etc/caddy/backups"
SUDO_CMD="sudo"
CADDY_BIN="caddy"                     # o selftest troca por um stub no sandbox
RELOAD_CMD=(sudo systemctl reload caddy)   # idem
MANAGED_MARK="# GERIDO por ops/install-caddy-config.sh — fonte versionada:"
SERVICE_MARK="# VHOST DE SERVIÇO, instalado pelo install-caddy-config do core a partir do repo:"   # sem o MANAGED_MARK dentro

die() { echo "ERRO: $*" >&2; exit 2; }
usage() { sed -n 's/^# \?//p' "${BASH_SOURCE[0]}" | sed -n '/^Uso:/,/^$/p'; }

# Fontes geridas do core: os *.caddy de ops/caddy/conf.d/ (nomes, um por linha).
core_names() {
  [[ -d "$CONF_SRC_DIR" ]] || return 0
  local f
  set +f
  for f in "$CONF_SRC_DIR"/*.caddy; do [[ -f "$f" ]] && basename "$f"; done
  set -f
}

# Linhas válidas da lista de serviço: nome · clone · ref · caminho · hosts · upstreams (TAB). Linha malformada = die:
# lista lida pela metade instalaria só parte dos vhosts sem ninguém ver. Saída: as 6 colunas, TAB, uma por vhost.
service_rows() {
  [[ -f "$SERVICE_TSV" ]] || return 0
  local n repo ref path hosts ups extra
  while IFS=$'\t' read -r n repo ref path hosts ups extra || [[ -n "$n" ]]; do
    [[ -z "${n//[[:space:]]/}" || "$n" == \#* ]] && continue
    [[ "$n" =~ ^[a-z0-9][a-z0-9-]*\.caddy$ ]] || die "service-vhosts.tsv: nome inválido «$n»"
    [[ "$repo" == /* ]] || die "service-vhosts.tsv: clone de $n não é caminho absoluto («$repo»)"
    [[ -n "$ref" && "$ref" != -* ]] || die "service-vhosts.tsv: ref de $n vazia ou com cara de flag"
    [[ "$path" =~ ^caddy/[a-z0-9][a-z0-9-]*\.caddy$ ]] || die "service-vhosts.tsv: caminho de $n fora de caddy/*.caddy («$path»)"
    [[ -n "$hosts" && -n "$ups" && -z "$extra" ]] || die "service-vhosts.tsv: linha de $n sem hosts, sem upstreams ou com coluna a mais"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$repo" "$ref" "$path" "$hosts" "$ups"
  done < "$SERVICE_TSV"
}

service_field() {  # service_field <nome> <coluna 1..6>; vazio se o nome não está na lista
  local rows; rows="$(service_rows)" || exit 2
  awk -F'\t' -v n="$1" -v c="$2" '$1==n {print $c; exit}' <<< "$rows"
}

service_names() { local rows; rows="$(service_rows)" || exit 2; [[ -z "$rows" ]] || cut -f1 <<< "$rows"; }

# Lê a fonte de um vhost para <arquivo>. Core: o arquivo de ops/caddy/conf.d/. Serviço: o BLOB commitado na ref
# (modo 100644; symlink e submódulo recusados). rc 1 = fonte ausente (pendente); die = fonte ilegítima.
fetch_source() {
  local n="$1" out="$2" repo ref path meta
  if [[ -e "$CONF_SRC_DIR/$n" ]]; then
    [[ -f "$CONF_SRC_DIR/$n" && ! -L "$CONF_SRC_DIR/$n" ]] || die "fonte gerida ausente ou symlink: $CONF_SRC_DIR/$n"
    cat "$CONF_SRC_DIR/$n" > "$out"; return 0
  fi
  repo="$(service_field "$n" 2)"; [[ -n "$repo" ]] || return 1
  ref="$(service_field "$n" 3)"; path="$(service_field "$n" 4)"
  [[ -e "$repo/.git" ]] || return 1
  meta="$(git -C "$repo" ls-tree "$ref" -- "$path" 2>/dev/null)" || return 1
  [[ -n "$meta" ]] || return 1
  [[ "$meta" == "100644 blob "* ]] || die "fonte de $n em $repo@$ref:$path não é arquivo comum ($meta)"
  git -C "$repo" show "$ref:$path" > "$out" 2>/dev/null || return 1
}

source_label() {  # o que vai no carimbo
  if [[ -f "$CONF_SRC_DIR/$1" ]]; then echo "ops/caddy/conf.d/$1"
  else echo "$(basename "$(service_field "$1" 2)"):$(service_field "$1" 4)"; fi
}

source_rev() {  # de onde a fonte de serviço foi lida (ref, sha curto e data), para o relatório
  local repo ref; repo="$(service_field "$1" 2)"; ref="$(service_field "$1" 3)"
  [[ -n "$repo" ]] || return 0
  git -C "$repo" log -1 --format="$ref=%h (%cs)" "$ref" 2>/dev/null || echo "$ref=?"
}

# As fontes lidas (templates, sem segredo) vão para um diretório privado criado UMA vez no topo (os subshells o
# herdam) e removido no EXIT. Sem cache: cada leitura é nova, então a fonte nunca sai velha dentro da execução.
SRC_CACHE=""
source_file() {  # imprime o caminho de uma cópia nova da fonte de <nome>; rc 1 se ausente
  local n="$1" f
  [[ -n "$SRC_CACHE" && -d "$SRC_CACHE" ]] || die "SRC_CACHE não inicializado (bug do script)"
  f="$(mktemp "$SRC_CACHE/src.XXXXXX")"
  fetch_source "$n" "$f" || { rm -f "$f"; return 1; }
  echo "$f"
}

# Geridos com fonte legível: core + serviço cuja fonte existe na ref. Serviço sem fonte = pendente.
# ⚠️ Chame SEMPRE como `x="$(managed_names)" || exit 2`, nunca em `< <(…)`: o die dentro de uma substituição de
# processo some calado, e a lista sairia pela metade (uma fonte ilegítima viraria "não listada").
managed_names() {
  local n names rc
  core_names
  names="$(service_names)" || exit 2
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    [[ -e "$CONF_SRC_DIR/$n" ]] && die "$n está em ops/caddy/conf.d/ E em service-vhosts.tsv: uma fonte só"
    rc=0; ( source_file "$n" >/dev/null ) || rc=$?
    case "$rc" in 0) echo "$n" ;; 1) ;; *) exit 2 ;; esac
  done <<< "$names"
}
pending_names() {
  local n names rc
  names="$(service_names)" || exit 2
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    rc=0; ( source_file "$n" >/dev/null ) || rc=$?
    case "$rc" in 0) ;; 1) echo "$n" ;; *) exit 2 ;; esac
  done <<< "$names"
}
is_known() { [[ -f "$CONF_SRC_DIR/$1" || -n "$(service_field "$1" 1)" ]]; }

# Vivos em conf.d (nomes *.caddy). Lidos com sudo: o gerido é 0640.
live_names() {
  set +f
  local f
  for f in "$CONF_DEST_DIR"/*.caddy; do [[ -e "$f" ]] && basename "$f"; done
  set -f
}

is_managed_live() {  # carimbo do core OU de serviço na 1ª linha
  local first; first="$($SUDO_CMD head -n1 "$1" 2>/dev/null)"
  grep -qF "$MANAGED_MARK" <<< "$first" || grep -qF "$SERVICE_MARK" <<< "$first"
}
mark_for() { if [[ -f "$CONF_SRC_DIR/$1" ]]; then echo "$MANAGED_MARK $(source_label "$1")"; else echo "$SERVICE_MARK $(source_label "$1")"; fi; }
has_markers() { local f; f="$(source_file "$1")" || return 1; grep -qE '@@[A-Z0-9_]+@@' "$f"; }

# Adoção: o vivo NÃO gerido é byte a byte a fonte de SERVIÇO (a cópia medida pelos PRs dos repos). O vhost do core
# segue recusando sobrescrever o escrito à mão.
adoptable() {
  local n="$1" f
  [[ -f "$CONF_SRC_DIR/$n" ]] && return 1
  f="$(source_file "$n")" || return 1
  $SUDO_CMD cmp -s "$f" "$CONF_DEST_DIR/$n"
}

# O LIMITE DO REPO, julgado pelo PRÓPRIO Caddy (refutador, 2026-11-22): a contagem de chaves no texto se contorna
# (chave em comentário depois de TAB, chave entre aspas), e um site de outro domínio passava. Aqui a fonte vira o
# JSON do `caddy adapt` (marcadores trocados por um valor neutro: o adapt não precisa de segredo) e se exige:
#   · só a app http (e tls, que a diretiva `tls` do site gera); nada de admin, storage ou logging;
#   · escuta só em :443/:80, e TODA rota de nível superior com host, todo host na coluna de hosts;
#   · todo reverse_proxy com upstream na coluna de upstreams (fecha a API admin :2019 e o loopback de outro serviço),
#     sem upstream dinâmico;
#   · handler só da ALLOWLIST (subroute, reverse_proxy, static_response, rewrite, headers, encode, request_body, vars,
#     error): file_server, templates, acme_server, metrics e o que vier depois ficam de fora;
#   · nenhuma string com `{file.` ou `{env.`: esses placeholders leem disco e ambiente do processo do Caddy EM TEMPO DE
#     EXECUÇÃO, e a conta do Caddy lê os vhosts geridos que carregam segredo (2ª passada do refutador, 2026-11-22);
#   · na app tls, só `automation.policies` com `subjects` dentro dos hosts e sem on_demand: `tls <cert> <key>` carregaria
#     arquivos arbitrários no cache de certificados, que é global ao Caddy.
# Limite declarado: o adapt roda sobre o arquivo isolado; fonte de serviço que importe snippet do Caddyfile do core é
# recusada (nenhuma das quatro medidas importa).
adapt_guard() {  # adapt_guard <nome> <arquivo-fonte>
  local name="$1" src="$2" tmp json
  tmp="$(mktemp "$SRC_CACHE/adapt.XXXXXX")"
  sed -E 's/@@[A-Z0-9_]+@@/onion-placeholder/g' "$src" > "$tmp"
  json="$("$CADDY_BIN" adapt --config "$tmp" --adapter caddyfile 2>/dev/null)" || die "caddy adapt recusou a fonte de $name ($(source_label "$name"))"
  HOSTS="$(service_field "$name" 5)" UPS="$(service_field "$name" 6)" python3 -I -c '
import json, os, re, sys
cfg = json.loads(sys.stdin.read() or "{}")
hosts = {h for h in re.split(r"[,\s]+", os.environ["HOSTS"]) if h}
ups = {u for u in re.split(r"[,\s]+", os.environ["UPS"]) if u}
def no(msg): sys.exit("limite do repo: " + msg)
if set(cfg) - {"apps"}: no("chave global fora de apps: %s" % sorted(set(cfg) - {"apps"}))
apps = cfg.get("apps", {})
if set(apps) - {"http", "tls"}: no("app fora de http/tls: %s" % sorted(set(apps) - {"http", "tls"}))
tls = apps.get("tls", {})
if set(tls) - {"automation"}: no("tls fora de automation: %s" % sorted(set(tls) - {"automation"}))
if set(tls.get("automation", {})) - {"policies"}: no("tls.automation fora de policies")
for pol in tls.get("automation", {}).get("policies", []):
    if pol.get("on_demand"): no("tls on_demand")
    out = [h for h in pol.get("subjects", []) if h not in hosts]
    if out or not pol.get("subjects"): no("política tls fora dos hosts: %s" % (out or "sem subjects"))
OK_HANDLERS = {"subroute", "reverse_proxy", "static_response", "rewrite", "headers", "encode", "request_body", "vars", "error"}
servers = apps.get("http", {}).get("servers", {})
if not servers: no("nenhum site")
for srv in servers.values():
    bad = [l for l in srv.get("listen", []) if l not in (":443", ":80")]
    if bad: no("escuta fora de :443/:80: %s" % bad)
    for r in srv.get("routes", []):
        ms = r.get("match") or []
        if not ms or any(not m.get("host") for m in ms): no("rota de nível superior sem host")
        for m in ms:
            out = [h for h in m["host"] if h not in hosts]
            if out: no("host fora da lista %s: %s" % (sorted(hosts), out))
def walk(x):
    if isinstance(x, dict):
        h = x.get("handler")
        if h is not None and h not in OK_HANDLERS: no("handler fora da allowlist: %s" % h)
        if h == "reverse_proxy":
            if "dynamic_upstreams" in x: no("upstream dinâmico")
            for u in x.get("upstreams", []):
                if u.get("dial") not in ups: no("upstream fora da lista %s: %s" % (sorted(ups), u.get("dial")))
        for v in x.values(): walk(v)
    elif isinstance(x, list):
        for v in x: walk(v)
    elif isinstance(x, str) and ("{file." in x or "{env." in x):
        no("placeholder que lê disco ou ambiente: %s" % x[:80])
walk(cfg)
' <<< "$json" || die "fonte de $name recusada pelo limite do repo (veja acima)"
}

# Renderiza um vhost gerido para a stdout: carimbo + fonte com @@NOME@@ resolvidos.
# Recusa (die) marcador sem valor, valor vazio, ou valor com espaço/aspas/quebra de linha. Fonte de serviço:
# recusa também site fora dos hosts declarados e conteúdo de nível superior que não seja bloco de site.
render() {
  local name="$1" src env="$SECRETS_DIR/${1%.caddy}.env" secrets="" hosts=""
  src="$(source_file "$name")" || die "fonte gerida ausente: $name"
  if [[ ! -f "$CONF_SRC_DIR/$name" ]]; then hosts="$(service_field "$name" 5)"; adapt_guard "$name" "$src"; fi
  if grep -qE '@@[A-Z0-9_]+@@' "$src"; then
    secrets="$($SUDO_CMD cat "$env" 2>/dev/null)" || die "segredos de $name ausentes em $env (rode ops/caddy-site-secrets.sh)"
  fi
  SECRETS="$secrets" HOSTS="$hosts" python3 -I - "$src" "$(mark_for "$name")" <<'PY' || die "render de $name recusado (veja acima)"
import os, re, sys
src, mark = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
hosts = os.environ.get("HOSTS", "")
if hosts:
    # 1º filtro, barato: só blocos de site no nível superior, e todo endereço deles na lista. A contagem de chaves é
    # ingênua (chave entre aspas conta) e SE CONTORNA: a autoridade é o adapt_guard, que lê o JSON do próprio Caddy.
    allowed = {h for h in re.split(r"[,\s]+", hosts) if h}
    depth = 0
    for ln, line in enumerate(text.splitlines(), 1):
        code = re.sub(r"(^|\s)#.*$", "", line).strip()   # comentário do Caddyfile: # no começo de token
        if not code:
            continue
        if depth == 0:
            if not code.endswith("{") or code == "{" or code.startswith("("):
                sys.exit(f"linha {ln}: no nível superior só cabe bloco de site com host da lista («{code}»)")
            addrs = [a for a in re.split(r"[,\s]+", code[:-1]) if a]
            bad = [a for a in addrs if a not in allowed]
            if not addrs or bad:
                sys.exit(f"linha {ln}: site fora dos hosts declarados {sorted(allowed)}: {bad or code}")
        depth += code.count("{") - code.count("}")
        if depth < 0:
            sys.exit(f"linha {ln}: chave fechada sem abrir")
    if depth != 0:
        sys.exit("chaves desbalanceadas no arquivo")
vals = {}
for line in os.environ.get("SECRETS", "").splitlines():
    if not line.strip() or line.startswith("#"):
        continue
    k, sep, v = line.partition("=")
    if not sep:
        sys.exit("linha de segredo sem '=': chave omitida")
    vals[k.strip()] = v
def sub(m):
    k = m.group(1)
    v = vals.get(k)
    if v is None:
        sys.exit(f"marcador @@{k}@@ sem valor")
    if not v or re.search(r'[\s"\'`{}]', v):
        sys.exit(f"valor de @@{k}@@ vazio ou com caractere proibido")
    return v
out = re.sub(r"@@([A-Z0-9_]+)@@", sub, text)
sys.stdout.write(mark + "\n" + out)
PY
}

# Pré-voo: monta um ESTÁGIO com o Caddyfile + conf.d final (não geridos do vivo + geridos
# renderizados) e roda `caddy validate` nele. Falha = die, nada tocado. Imprime o dir do estágio.
#   PLAN=1 (o ensaio): vhost do core com marcador de segredo NÃO é renderizado (o ensaio não lê segredo); entra no
#   estágio a cópia viva dele, e sem cópia viva fica de fora da validação, dito na saída.
stage_and_validate() {
  [[ -f "$SRC" ]] || die "fonte ausente: $SRC"
  [[ -L "$SRC" ]] && die "fonte é SYMLINK — recuso (estado ilegítimo desta derivação)"
  local stage n managed lives
  # a lista vem do chamador (MANAGED_LIST) quando ele já a calculou: estágio e apply instalam o MESMO conjunto, mesmo
  # que um fetch no clone mude a ref no meio (refutador, 2026-11-22)
  if [[ -n "${MANAGED_LIST+x}" ]]; then managed="$MANAGED_LIST"; else managed="$(managed_names)" || exit 2; fi
  lives="$(live_names)"
  stage="$($SUDO_CMD mktemp -d)" || die "mktemp do estágio falhou"
  $SUDO_CMD chmod 0700 "$stage"
  $SUDO_CMD mkdir -p "$stage/conf.d"
  sed "s#${CONF_DEST_DIR}/#${stage}/conf.d/#g" "$SRC" | $SUDO_CMD tee "$stage/Caddyfile" >/dev/null
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    grep -qxF "$n" <<< "$managed" && continue                    # gerido: entra renderizado abaixo
    if is_managed_live "$CONF_DEST_DIR/$n" && ! is_known "$n"; then continue; fi   # órfão: vai ser removido
    $SUDO_CMD cp -p "$CONF_DEST_DIR/$n" "$stage/conf.d/$n"       # não gerido ou pendente: só copia p/ validar
  done <<< "$lives"
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    # colisão: versionado com o nome de um vivo NÃO gerido → recusa no pré-voo, antes de tocar nada, salvo a
    # adoção da fonte de serviço byte a byte igual ao vivo
    if [[ -e "$CONF_DEST_DIR/$n" ]] && ! is_managed_live "$CONF_DEST_DIR/$n" && ! adoptable "$n"; then
      $SUDO_CMD rm -rf "$stage"
      if [[ -f "$CONF_SRC_DIR/$n" ]]; then die "$CONF_DEST_DIR/$n existe e NÃO é gerido — recuso sobrescrever um vhost escrito à mão"; fi
      die "$CONF_DEST_DIR/$n existe, NÃO é gerido e difere da fonte $(source_label "$n") — recuso adotar (compare: diff <(git -C $(service_field "$n" 2) show $(service_field "$n" 3):$(service_field "$n" 4)) $CONF_DEST_DIR/$n)"
    fi
    if [[ "${PLAN:-0}" == 1 ]] && has_markers "$n"; then
      if [[ -e "$CONF_DEST_DIR/$n" ]]; then $SUDO_CMD cp -p "$CONF_DEST_DIR/$n" "$stage/conf.d/$n"
      else echo "  ! $n tem segredo e não está no vivo: fora da validação do ensaio (o install valida)" >&2; fi
      continue
    fi
    local rendered; rendered="$(render "$n")" || { $SUDO_CMD rm -rf "$stage"; exit 2; }
    printf '%s\n' "$rendered" | $SUDO_CMD tee "$stage/conf.d/$n" >/dev/null
  done <<< "$managed"
  if ! $SUDO_CMD "$CADDY_BIN" validate --config "$stage/Caddyfile" --adapter caddyfile >/dev/null 2>&1; then
    $SUDO_CMD rm -rf "$stage"
    die "caddy validate FALHOU no estágio — nada foi tocado (rode: $CADDY_BIN validate --config $SRC --adapter caddyfile)"
  fi
  echo "$stage"
}

# Arquivo ausente → vazio (nunca rc≠0): sob pipefail+set -e, o `got=$(read_hash …)` de um conf.d ainda
# não instalado matava o --check em SILÊNCIO com rc 1 (medido no vivo, 2026-10-08).
read_hash() { { $SUDO_CMD sha256sum "$1" 2>/dev/null || true; } | awk '{print $1}'; }

backup_file() {   # backup_file <arquivo> <prefixo> → imprime o caminho do backup (ou nada)
  local f="$1" pfx="$2" ts bak
  [[ -f "$f" ]] || return 0
  $SUDO_CMD mkdir -p "$BACKUP_DIR"
  ts="$(date +%Y%m%d-%H%M%S)"; bak="$BACKUP_DIR/${pfx}.${ts}.bak"
  $SUDO_CMD cp -p "$f" "$bak" || die "backup de $f falhou — não instalo sem rede de segurança"
  [[ -n "$($SUDO_CMD find "$bak" -size +0c 2>/dev/null)" ]] || die "backup vazio ($bak) — pior que ausente; abortando"
  echo "$bak"
  # retenção: mantém os 10 mais recentes por prefixo
  $SUDO_CMD bash -c "ls -1t '$BACKUP_DIR'/'${pfx}'.*.bak 2>/dev/null | tail -n +11 | xargs -r rm -f" || true
}

verify_live() {
  local host code ct fail=0 n url want
  code="$(curl -sS -o /dev/null -w '%{http_code}' https://onionevolve.com/ 2>/dev/null || echo 000)"
  ct="$(curl -sSI https://onionevolve.com/ 2>/dev/null | tr -d '\r' | awk -F': ' 'tolower($1)=="cache-control"{print $2}')"
  [[ "$code" == 200 ]] || { echo "  ✗ onionevolve.com respondeu $code (esperado 200)"; fail=1; }
  [[ "$ct" == *no-cache* && "$ct" != *no-store* ]] || { echo "  ✗ cache-control em / = '$ct' (esperado no-cache, sem no-store)"; fail=1; }
  [[ "$code" == 200 ]] && echo "  ✓ onionevolve.com 200 · cache-control: $ct"
  for host in https://app.onionevolve.com/ https://auth.onionevolve.com/; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' "$host" 2>/dev/null || echo 000)"
    [[ "$code" =~ ^(200|301|302|308|401|403|404)$ ]] && echo "  ✓ $host responde ($code)" \
      || { echo "  ✗ $host = $code (proxy fora do ar?)"; fail=1; }
  done
  # conf.d gerido: cada `# verify: <url> <código>` é cobrado exatamente. Fonte de serviço sem `# verify:`: cada
  # host da lista tem de responder (qualquer código ≠ 000; o 502 de um serviço ainda parado conta como resposta).
  local managed src verifies h
  managed="$(managed_names)" || exit 2
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    src="$(source_file "$n")" || { echo "  ✗ fonte de $n sumiu durante a verificação"; fail=1; continue; }
    verifies="$(sed -n 's/^# verify: *\([^ ]*\) \([0-9][0-9][0-9]\) *$/\1 \2/p' "$src")"
    if [[ -z "$verifies" && ! -f "$CONF_SRC_DIR/$n" ]]; then
      for h in $(service_field "$n" 5 | tr ',' ' '); do verifies+="https://$h/ any"$'\n'; done
    fi
    while read -r url want; do
      [[ -n "$url" ]] || continue
      # vhost novo: o certificado ACME sai SEGUNDOS depois do reload (medido 2026-10-08: 000 logo
      # após o reload, 401 com cert válido ~20s depois). Espera até VERIFY_WAIT_S antes de reprovar.
      local waited=0
      while :; do
        code="$(curl -sS -o /dev/null -w '%{http_code}' "$url" 2>/dev/null)" || true
        code="${code:-000}"
        if [[ "$want" == any ]]; then [[ "$code" != 000 ]] && break; elif [[ "$code" == "$want" ]]; then break; fi
        [[ "$waited" -ge "${VERIFY_WAIT_S:-90}" ]] && break
        sleep 5; waited=$((waited+5))
      done
      if [[ "$code" == "$want" || ( "$want" == any && "$code" != 000 ) ]]; then echo "  ✓ $url = $code ($n)"
      else echo "  ✗ $url = $code (esperado $want, $n)"; fail=1; fi
    done <<< "$verifies"
  done <<< "$managed"
  return "$fail"
}

apply_config() {
  # `|| exit 2` explícito: dentro de um contexto testado (`f || …`) o `set -e` NÃO dispara, e a
  # falha do pré-voo seguia instalando (pego pela bancada, 2026-10-08).
  local managed; managed="$(managed_names)" || exit 2
  local stage; stage="$(MANAGED_LIST="$managed" stage_and_validate)" || exit 2
  local -a restore=() created=() removed=()
  local bak n lives
  lives="$(live_names)"
  bak="$(backup_file "$DEST" Caddyfile)"; [[ -n "$bak" ]] && restore+=("$bak|$DEST")
  [[ -z "$bak" ]] && echo "(sem $DEST a preservar — 1ª instalação)"
  $SUDO_CMD mkdir -p "$CONF_DEST_DIR"
  # geridos órfãos (carimbados no vivo, nome fora de ops/caddy/conf.d E da lista de serviço): backup + remoção.
  # Pendente (na lista, fonte ainda ausente na ref) NÃO é órfão: um clone sumido não derruba o vhost.
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    is_known "$n" && continue
    is_managed_live "$CONF_DEST_DIR/$n" || continue
    bak="$(backup_file "$CONF_DEST_DIR/$n" "conf.d-$n")"; restore+=("$bak|$CONF_DEST_DIR/$n")
    $SUDO_CMD rm -f "$CONF_DEST_DIR/$n"; removed+=("$n")
  done <<< "$lives"
  { $SUDO_CMD cp "$SRC" "$DEST" && $SUDO_CMD chmod 0644 "$DEST"; } || die "cp fonte→$DEST falhou"
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    if [[ -e "$CONF_DEST_DIR/$n" ]]; then
      bak="$(backup_file "$CONF_DEST_DIR/$n" "conf.d-$n")"; restore+=("$bak|$CONF_DEST_DIR/$n")
    else
      created+=("$CONF_DEST_DIR/$n")
    fi
    $SUDO_CMD cp "$stage/conf.d/$n" "$CONF_DEST_DIR/$n.new" || die "cp de conf.d/$n falhou"
    $SUDO_CMD chmod 0640 "$CONF_DEST_DIR/$n.new" || die "chmod de conf.d/$n falhou"
    if [[ -n "$CONF_OWNER" ]]; then $SUDO_CMD chown "$CONF_OWNER" "$CONF_DEST_DIR/$n.new" || die "chown de conf.d/$n falhou"; fi
    $SUDO_CMD mv -f "$CONF_DEST_DIR/$n.new" "$CONF_DEST_DIR/$n" || die "mv de conf.d/$n falhou"
  done <<< "$managed"
  $SUDO_CMD rm -rf "$stage"
  if ! "${RELOAD_CMD[@]}"; then
    echo "reload FALHOU — restaurando backup" >&2
    local r; for r in "${restore[@]}"; do $SUDO_CMD cp -p "${r%%|*}" "${r#*|}" || true; done
    for r in "${created[@]}"; do $SUDO_CMD rm -f "$r" || true; done
    "${RELOAD_CMD[@]}" || true
    die "reload do Caddy falhou; backup restaurado"
  fi
  [[ ${#removed[@]} -gt 0 ]] && echo "── geridos órfãos removidos: ${removed[*]}"
  echo "── instalado; verificando o serviço ──"
  verify_live || die "config instalada mas a verificação comportamental falhou — investigue (backups em $BACKUP_DIR)"
  echo "── ok: $DEST == fonte, conf.d gerido instalado, Caddy recarregado, vhosts no ar ──"
}

check() {
  if [[ ! -f "$DEST" ]]; then
    echo "não estou na VPS (sem $DEST) — nada a checar; abstenho (exit 0)"; return 0
  fi
  local hs hd rc=0 n want got
  hs="$(read_hash "$SRC")"; hd="$(read_hash "$DEST")"
  if [[ "$hs" == "$hd" ]]; then
    echo "✓ sem drift: $DEST == $SRC"
  else
    echo "✗ DRIFT: $DEST diverge da fonte versionada ($SRC)"
    echo "  fonte=$hs  vivo=$hd  — alguém editou /etc/caddy à mão, ou falta instalar."
    rc=1
  fi
  local managed pending lives
  managed="$(managed_names)" || die "lista de vhosts geridos ilegível no --check"
  pending="$(pending_names)" || die "lista de vhosts de serviço ilegível no --check"
  lives="$(live_names)"
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    want="$(render "$n")" || die "render de $n falhou no --check"
    want="$(printf '%s\n' "$want" | sha256sum | awk '{print $1}')"   # mesma forma do que o apply grava
    got="$(read_hash "$CONF_DEST_DIR/$n")"
    if [[ -z "$got" ]]; then echo "✗ DRIFT: conf.d/$n versionado e AUSENTE no vivo (falta instalar)"; rc=1
    elif [[ "$want" != "$got" ]]; then
      if ! is_managed_live "$CONF_DEST_DIR/$n" && adoptable "$n"; then
        echo "✗ DRIFT: conf.d/$n igual à fonte $(source_label "$n"), ainda sem carimbo (falta instalar: o install adota)"
      else echo "✗ DRIFT: conf.d/$n vivo diverge do render da fonte"; fi
      rc=1
    else echo "✓ sem drift: conf.d/$n == render da fonte"; fi
  done <<< "$managed"
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    if [[ -e "$CONF_DEST_DIR/$n" ]] && is_managed_live "$CONF_DEST_DIR/$n"; then
      echo "✗ DRIFT: conf.d/$n carimbado, e a fonte $(source_label "$n") sumiu da ref $(service_field "$n" 3) (o install não o remove)"; rc=1
    else echo "· conf.d/$n pendente: fonte $(source_label "$n") ainda ausente na ref $(service_field "$n" 3) — o vivo segue como está"; fi
  done <<< "$pending"
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    is_known "$n" && continue
    if is_managed_live "$CONF_DEST_DIR/$n"; then echo "✗ DRIFT: conf.d/$n carimbado como gerido, sem fonte no repo (órfão)"; rc=1
    else echo "· conf.d/$n não gerido (fora do repo) — ignorado"; fi
  done <<< "$lives"
  return "$rc"
}

# ENSAIO (--plan): o que o install faria em cada vhost, sem tocar o vivo nem ler segredo. Valida o estágio (que é
# um diretório temporário, nunca /etc/caddy). Saída: uma linha por vhost; rc 0 = o install passaria o pré-voo.
plan() {
  [[ -f "$DEST" ]] || { echo "não estou na VPS (sem $DEST) — nada a ensaiar; abstenho (exit 0)"; return 0; }
  local n managed pending lives f action
  managed="$(managed_names)" || exit 2
  pending="$(pending_names)" || exit 2
  lives="$(live_names)"
  echo "── ensaio: o que o install faria (nada foi tocado)"
  if [[ "$(read_hash "$SRC")" == "$(read_hash "$DEST")" ]]; then echo "  = Caddyfile: inalterado"
  else echo "  ~ Caddyfile: SUBSTITUÍDO pela fonte versionada (backup antes)"; fi
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    local origin="ops/caddy/conf.d"; [[ -f "$CONF_SRC_DIR/$n" ]] || origin="$(source_label "$n") @ $(source_rev "$n")"
    if [[ ! -e "$CONF_DEST_DIR/$n" ]]; then action="+ CRIAR (vhost novo; carimbado)"
    elif ! is_managed_live "$CONF_DEST_DIR/$n"; then
      if adoptable "$n"; then action="> ADOTAR (vivo não gerido é byte a byte a fonte; ganha o carimbo na 1ª linha, backup antes)"
      else action="✗ RECUSA (vivo não gerido difere da fonte, ou é vhost do core escrito à mão): o install para no pré-voo"; fi
    elif has_markers "$n"; then
      action="? com segredo: o ensaio não renderiza (o --check confere)"
    else
      # a mesma forma que o apply grava e o --check confere: printf '%s\n' do render
      f="$(render "$n")" || exit 2
      if [[ "$(printf '%s\n' "$f" | sha256sum | awk '{print $1}')" == "$(read_hash "$CONF_DEST_DIR/$n")" ]]; then
        action="= inalterado"
      else action="~ ATUALIZAR (fonte mudou; backup antes)"; fi
    fi
    echo "  $action · conf.d/$n ← $origin"
  done <<< "$managed"
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    echo "  · PENDENTE · conf.d/$n ← $(source_label "$n") ausente em $(service_field "$n" 3) ($(service_field "$n" 2)); o vivo fica como está"
  done <<< "$pending"
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    is_known "$n" && continue
    if is_managed_live "$CONF_DEST_DIR/$n"; then echo "  - REMOVER (órfão carimbado, backup antes) · conf.d/$n"
    else echo "  · não gerido, fica · conf.d/$n"; fi
  done <<< "$lives"
  echo "── pré-voo: caddy validate no estágio"
  local stage; stage="$(PLAN=1 MANAGED_LIST="$managed" stage_and_validate)" || { echo "✗ RESULTADO: o install pararia no pré-voo (veja acima)"; return 1; }
  $SUDO_CMD rm -rf "$stage"
  echo "✓ RESULTADO: ensaio verde; o install faria o que está acima (e recarregaria o Caddy)"
}

# ── selftest: sandbox com stubs; nunca toca /etc nem recarrega de verdade ──
selftest() {
  local pass=0 fail=0; SB="$(mktemp -d)"; trap 'rm -rf -- "${SB:-}" "${SRC_CACHE:-}"' EXIT   # SB global: o trap de EXIT o alcança
  SERVICE_TSV="$SB/service-vhosts.tsv"   # sem a lista real: a bancada nunca lê os clones da máquina
  SRC="$SB/src-Caddyfile"; DEST="$SB/etc/Caddyfile"; BACKUP_DIR="$SB/etc/backups"; SUDO_CMD=""
  CONF_SRC_DIR="$SB/src-conf.d"; CONF_DEST_DIR="$SB/etc/conf.d"; SECRETS_DIR="$SB/etc/secrets"; CONF_OWNER=""
  mkdir -p "$SB/etc" "$CONF_DEST_DIR" "$SECRETS_DIR"
  printf 'onionevolve.com {\n  file_server\n}\nimport %s/*.caddy\n' "$CONF_DEST_DIR" > "$SRC"
  printf 'antigo\n' > "$DEST"
  # stub de caddy: validate/fmt/adapt com rc configurável por env; o validate guarda o estágio visto
  cat > "$SB/caddy" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
  validate) [ -n "${STUB_SEEN:-}" ] && cp "$3" "$STUB_SEEN" 2>/dev/null; exit "${STUB_VALIDATE_RC:-0}" ;;
  fmt)      exit 0 ;;
  adapt)    # com caddy de verdade na máquina, o adapt é o dele (REAL_CADDY); sem ele (o CI), um dublê que monta o
            # JSON das linhas «site {», «reverse_proxy X» e «file_server» (não vê aspas nem comentário com TAB)
            if [ -n "${REAL_CADDY:-}" ]; then exec "$REAL_CADDY" "$@"; fi
            python3 -I - "$3" <<'EMU'
import json, re, sys
routes, depth, cur = [], 0, None
for line in open(sys.argv[1], encoding="utf-8"):
    code = re.sub(r"(^|\s)#.*$", "", line).strip()
    if not code: continue
    if depth == 0 and code.endswith("{"):
        cur = {"match": [{"host": [a for a in re.split(r"[,\s]+", code[:-1]) if a]}], "handle": []}; routes.append(cur)
    elif cur is not None and code.startswith("reverse_proxy "):
        cur["handle"].append({"handler": "reverse_proxy", "upstreams": [{"dial": code.split()[1]}]})
    elif cur is not None and code.split()[0] == "file_server":
        cur["handle"].append({"handler": "file_server"})
    depth += code.count("{") - code.count("}")
print(json.dumps({"apps": {"http": {"servers": {"srv0": {"listen": [":443"], "routes": routes}}}}}))
EMU
            ;;
  *)        exit 0 ;;
esac
STUB
  chmod +x "$SB/caddy"; CADDY_BIN="$SB/caddy"
  # stub de reload: rc por env; grava um marcador para provar que foi chamado
  RELOAD_CMD=(bash -c 'echo reloaded > "$0"; exit "${STUB_RELOAD_RC:-0}"' "$SB/reloaded")
  # stub de verify_live: o selftest não tem rede — sobrescreve por sucesso silencioso
  verify_live() { return 0; }

  # ESPELHA O RUNNER (2026-10-08): o `|| rc=$?` antigo punha a função num contexto TESTADO, onde o
  # bash desliga o `set -e` — a bancada rodava com errexit desligado e a produção com ele ligado.
  # Um `got=$(…)` que falhava matava o --check em produção e passava aqui. Agora errexit vale dentro.
  t() { local name="$1" want="$2"; shift 2; local rc out
    set +e; out="$( set -e; "$@" 2>&1 )"; rc=$?; set -e
    if [[ "$rc" -eq "$want" ]]; then pass=$((pass+1)); echo "  ✓ $name"
    else fail=$((fail+1)); echo "  ✗ $name (rc=$rc, esperado=$want)"; printf '%s\n' "$out" | sed 's/^/      | /'; fi
  }
  ok() { if eval "$2"; then pass=$((pass+1)); echo "  ✓ $1"; else fail=$((fail+1)); echo "  ✗ $1"; fi; }

  echo "── selftest (sandbox: $SB) ──"
  # 1. validate falha → NADA muda (DEST intocado)
  STUB_VALIDATE_RC=1 t "validate falha → apply RECUSA (die)" 2 apply_config
  ok "DEST intocado após validate falho" '[[ "$(cat "$DEST")" == antigo ]]'
  # 2. apply feliz → DEST vira a fonte + backup criado + reload chamado
  t "apply feliz" 0 apply_config
  ok "DEST == fonte" '[[ -f "$DEST" && "$(cat "$DEST")" == "$(cat "$SRC")" ]]'
  ok "backup criado" '[[ -n "$(find "$BACKUP_DIR" -name "Caddyfile.*.bak" 2>/dev/null)" ]]'
  ok "reload foi chamado" '[[ -f "$SB/reloaded" ]]'
  # 3. idempotência: re-apply → check verde
  t "apply idempotente" 0 apply_config
  t "check sem drift → verde" 0 check
  # 4. drift: editar o DEST à mão → check acusa
  printf 'editado-a-mao\n' > "$DEST"
  t "drift (DEST editado) → check acusa" 1 check
  # 5. reload falha → rollback restaura o backup e sai ≠0
  apply_config >/dev/null 2>&1 || true   # reinstala limpo
  STUB_VALIDATE_RC=0 STUB_RELOAD_RC=1 t "reload falha → apply faz rollback e sai ≠0" 2 apply_config
  # 6. fonte ausente → die
  local keep="$SRC"; SRC="$SB/inexistente"
  t "fonte ausente → die" 2 apply_config
  SRC="$keep"

  # ── conf.d gerido (2026-10-08) ──
  apply_config >/dev/null 2>&1 || true
  mkdir -p "$CONF_SRC_DIR"
  printf 'vault {\n  respond "a mao"\n}\n' > "$CONF_DEST_DIR/vault.caddy"           # não gerido, vivo
  printf 'demo.x {\n  basic_auth {\n    u @@DEMO_BASIC_HASH@@\n  }\n  @c header Cookie *k=@@DEMO_COOKIE@@*\n}\n' > "$CONF_SRC_DIR/demo.caddy"
  local vault_hash; vault_hash="$(sha256sum "$CONF_DEST_DIR/vault.caddy" | awk '{print $1}')"
  # 7. segredo ausente → RECUSA, nada instalado
  t "conf.d com marcador e sem segredos → apply RECUSA" 2 apply_config
  ok "conf.d gerido NÃO instalado sem segredo" '[[ ! -e "$CONF_DEST_DIR/demo.caddy" ]]'
  # 8. valor VAZIO (o fail-open do cookie) → RECUSA
  printf 'DEMO_BASIC_HASH=$2a$14$abc\nDEMO_COOKIE=\n' > "$SECRETS_DIR/demo.env"
  t "segredo com valor vazio → apply RECUSA (cookie vazio abriria a API)" 2 apply_config
  ok "conf.d gerido NÃO instalado com valor vazio" '[[ ! -e "$CONF_DEST_DIR/demo.caddy" ]]'
  # 9. feliz: renderiza, carimba, 0640, valida o ESTÁGIO com o render, não toca o não gerido
  printf 'DEMO_BASIC_HASH=$2a$14$abc\nDEMO_COOKIE=cafe1234\n' > "$SECRETS_DIR/demo.env"
  STUB_SEEN="$SB/seen" t "conf.d gerido com segredos → apply feliz" 0 apply_config
  ok "conf.d gerido instalado e renderizado" 'grep -qF "k=cafe1234*" "$CONF_DEST_DIR/demo.caddy" && grep -qF "u \$2a\$14\$abc" "$CONF_DEST_DIR/demo.caddy"'
  ok "conf.d gerido sem marcador residual" '! grep -qE "@@[A-Z0-9_]+@@" "$CONF_DEST_DIR/demo.caddy"'
  ok "conf.d gerido carimbado (1ª linha)" 'grep -qF "$MANAGED_MARK" <<< "$(head -n1 "$CONF_DEST_DIR/demo.caddy")"'
  ok "conf.d gerido em 0640" '[[ "$(stat -c %a "$CONF_DEST_DIR/demo.caddy")" == 640 ]]'
  ok "não gerido intocado (hash igual)" '[[ "$(sha256sum "$CONF_DEST_DIR/vault.caddy" | awk "{print \$1}")" == "$vault_hash" ]]'
  ok "validate viu o ESTÁGIO (import reescrito), não o vivo" '[[ -f "$SB/seen" ]] && ! grep -qF "$CONF_DEST_DIR/" "$SB/seen"'
  t "check: Caddyfile + conf.d gerido sem drift → verde" 0 check
  # 10. drift no conf.d gerido → check acusa
  cp "$CONF_DEST_DIR/demo.caddy" "$SB/demo.keep"; printf '# editado\n' >> "$CONF_DEST_DIR/demo.caddy"
  t "drift no conf.d gerido → check acusa" 1 check
  cp "$SB/demo.keep" "$CONF_DEST_DIR/demo.caddy"
  # 11. não gerido com o mesmo nome de um versionado → RECUSA sobrescrever
  printf 'outro.x {\n}\n' > "$CONF_SRC_DIR/vault.caddy"
  t "versionado colide com não gerido vivo → apply RECUSA" 2 apply_config
  ok "não gerido segue intocado após a colisão" '[[ "$(sha256sum "$CONF_DEST_DIR/vault.caddy" | awk "{print \$1}")" == "$vault_hash" ]]'
  rm -f "$CONF_SRC_DIR/vault.caddy"
  # 12. fonte removida do repo → o vivo carimbado é órfão: check acusa, apply remove (com backup)
  rm -f "$CONF_SRC_DIR/demo.caddy"
  t "gerido órfão → check acusa" 1 check
  t "gerido órfão → apply remove" 0 apply_config
  ok "órfão removido e não gerido preservado" '[[ ! -e "$CONF_DEST_DIR/demo.caddy" && -f "$CONF_DEST_DIR/vault.caddy" ]]'
  ok "backup do órfão criado" '[[ -n "$(find "$BACKUP_DIR" -name "conf.d-demo.caddy.*.bak" 2>/dev/null)" ]]'

  # 13. versionado ainda NÃO instalado → check acusa EM VOZ ALTA (antes morria mudo com rc 1)
  printf 'demo.x {\n  @c header Cookie *k=@@DEMO_COOKIE@@*\n}\n' > "$CONF_SRC_DIR/demo.caddy"
  ok "versionado ausente no vivo → check nomeia o drift" 'set +e; _o="$( set -e; check 2>&1 )"; set -e; [[ "$_o" == *"conf.d/demo.caddy versionado e AUSENTE"* ]]'   # errexit ligado, como no runner; sem `| grep -q` (EPIPE)
  rm -f "$CONF_SRC_DIR/demo.caddy"

  # ── vhosts dos repos de serviço (2026-11-22) ──
  # um repo de serviço em sandbox: o vivo de waha.caddy nasceu à mão e é a cópia exata do que o repo commitou
  local svc="$SB/svc-waha"; mkdir -p "$svc/caddy"
  git -C "$svc" init -q -b master
  printf '# WAHA — rota pública\nwaha.example {\n    reverse_proxy 127.0.0.1:3999\n}\n' > "$svc/caddy/waha.caddy"
  git -C "$svc" add caddy/waha.caddy
  git -C "$svc" -c user.name=t -c user.email=t@t -c core.hooksPath=/dev/null -c commit.gpgsign=false commit -qm vhost
  cp "$svc/caddy/waha.caddy" "$CONF_DEST_DIR/waha.caddy"
  printf '# nome\tclone\tref\tcaminho\thosts\tupstreams\nwaha.caddy\t%s\tmaster\tcaddy/waha.caddy\twaha.example\t127.0.0.1:3999\n' "$svc" > "$SERVICE_TSV"
  apply_config >/dev/null 2>&1 || true
  # 14. adoção: o não gerido igual à fonte ganha o carimbo, o corpo segue byte a byte
  ok "serviço: vivo igual à fonte é ADOTADO (carimbo com a fonte do repo)" '[[ "$(head -n1 "$CONF_DEST_DIR/waha.caddy")" == "$SERVICE_MARK svc-waha:caddy/waha.caddy" ]]'
  ok "serviço: o carimbo de serviço NÃO contém o do core (a versão anterior do script o removeria como órfão)" '! grep -qF "$MANAGED_MARK" <<< "$(head -n1 "$CONF_DEST_DIR/waha.caddy")"'
  ok "serviço: corpo adotado == blob do repo" 'tail -n +2 "$CONF_DEST_DIR/waha.caddy" | cmp -s "$svc/caddy/waha.caddy" -'
  t "serviço: check verde depois da adoção" 0 check
  # 15. a árvore de trabalho do clone NÃO vai para o ar: só o commit
  printf '# local\nwaha.example {\n    respond "sem commit"\n}\n' > "$svc/caddy/waha.caddy"
  t "serviço: mudança sem commit no clone não vira drift" 0 check
  git -C "$svc" checkout -q -- caddy/waha.caddy
  # 16. vivo não gerido DIFERENTE da fonte → recusa adotar e não toca o vivo
  cp "$CONF_DEST_DIR/waha.caddy" "$SB/waha.keep"
  printf '# a mao\nwaha.example {\n    reverse_proxy 127.0.0.1:4000\n}\n' > "$CONF_DEST_DIR/waha.caddy"
  t "serviço: vivo não gerido diferente da fonte → apply RECUSA" 2 apply_config
  ok "serviço: vivo diferente intocado após a recusa" 'grep -qF 127.0.0.1:4000 "$CONF_DEST_DIR/waha.caddy"'
  cp "$SB/waha.keep" "$CONF_DEST_DIR/waha.caddy"
  # 17. site fora dos hosts declarados (o repo tenta servir o domínio de outro) → recusa
  printf 'waha.example, onionevolve.com {\n    reverse_proxy 127.0.0.1:3999\n}\n' > "$svc/caddy/waha.caddy"
  git -C "$svc" -c user.name=t -c user.email=t@t -c core.hooksPath=/dev/null -c commit.gpgsign=false commit -qam hijack
  t "serviço: site fora dos hosts declarados → apply RECUSA" 2 apply_config
  ok "serviço: vivo intocado após o host recusado" 'cmp -s "$SB/waha.keep" "$CONF_DEST_DIR/waha.caddy"'
  # 18. conteúdo de nível superior que não é site (import/global) → recusa
  printf 'import /etc/caddy/secrets/*\nwaha.example {\n}\n' > "$svc/caddy/waha.caddy"
  git -C "$svc" -c user.name=t -c user.email=t@t -c core.hooksPath=/dev/null -c commit.gpgsign=false commit -qam import
  t "serviço: diretiva solta no nível superior → apply RECUSA" 2 apply_config
  ok "serviço: a recusa da diretiva solta é pela forma do nível superior (não só pelo host)" 'set +e; _o="$( set -e; apply_config 2>&1 )"; set -e; [[ "$_o" == *"no nível superior só cabe bloco de site"* ]]'
  git -C "$svc" reset -q --hard HEAD~2
  # 18b. dentro do bloco permitido: upstream fora da lista (a API admin) e file_server → recusa
  local gc=(-c user.name=t -c user.email=t@t -c core.hooksPath=/dev/null -c commit.gpgsign=false)
  printf 'waha.example {\n    reverse_proxy 127.0.0.1:2019\n}\n' > "$svc/caddy/waha.caddy"; git -C "$svc" "${gc[@]}" commit -qam admin
  t "serviço: upstream fora da lista (admin :2019) → apply RECUSA" 2 apply_config
  printf 'waha.example {\n    root * /etc/caddy/conf.d\n    file_server\n}\n' > "$svc/caddy/waha.caddy"; git -C "$svc" "${gc[@]}" commit -qam files
  t "serviço: file_server no bloco → apply RECUSA" 2 apply_config
  ok "serviço: vivo intocado após as recusas do bloco" 'cmp -s "$SB/waha.keep" "$CONF_DEST_DIR/waha.caddy"'
  # 18c. com o Caddy de verdade (o achado do refutador): chave em comentário depois de TAB e chave entre aspas
  #      enganam a contagem do texto; o adapt_guard pega. Sem caddy na máquina (o CI), o caso é pulado e DITO.
  local real; real="$(command -v caddy || true)"
  if [[ -n "$real" ]]; then
    printf 'waha.example {\n  reverse_proxy 127.0.0.1:3999\t# {\n}\nonionevolve.com {\n  respond x\t# }\n}\n' > "$svc/caddy/waha.caddy"; git -C "$svc" "${gc[@]}" commit -qam tab
    REAL_CADDY="$real" t "serviço (caddy real): host alheio escondido por comentário com TAB → apply RECUSA" 2 apply_config
    printf 'waha.example {\n  respond "a{b"\n}\nonionevolve.com {\n  respond "c}d"\n}\n' > "$svc/caddy/waha.caddy"; git -C "$svc" "${gc[@]}" commit -qam quote
    REAL_CADDY="$real" t "serviço (caddy real): host alheio escondido por chave entre aspas → apply RECUSA" 2 apply_config
    ok "serviço (caddy real): quem recusa as aspas é o adapt_guard (host fora da lista no JSON)" 'set +e; _o="$( set -e; REAL_CADDY="$real" apply_config 2>&1 )"; set -e; [[ "$_o" == *"limite do repo: host fora da lista"* ]]'
    printf 'waha.example {\n  respond "{file./etc/hostname}"\n}\n' > "$svc/caddy/waha.caddy"; git -C "$svc" "${gc[@]}" commit -qam file
    REAL_CADDY="$real" t "serviço (caddy real): placeholder {file.*} no corpo → apply RECUSA" 2 apply_config
    printf 'waha.example {\n  tls /etc/caddy/a.pem /etc/caddy/a.key\n  reverse_proxy 127.0.0.1:3999\n}\n' > "$svc/caddy/waha.caddy"; git -C "$svc" "${gc[@]}" commit -qam tlsfiles
    REAL_CADDY="$real" t "serviço (caddy real): tls carregando arquivo de certificado → apply RECUSA" 2 apply_config
    printf 'waha.example {\n  metrics\n}\n' > "$svc/caddy/waha.caddy"; git -C "$svc" "${gc[@]}" commit -qam metrics
    REAL_CADDY="$real" t "serviço (caddy real): handler fora da allowlist (metrics) → apply RECUSA" 2 apply_config
  else
    echo "  ⊘ casos com caddy real pulados: sem caddy nesta máquina (o dublê do adapt não vê aspas nem TAB)"
  fi
  # volta a fonte ao 1º commit (a cópia do vivo) e confere que ela passa, com o caddy real quando houver
  git -C "$svc" checkout -q "$(git -C "$svc" rev-list --max-parents=0 HEAD)" -- caddy/waha.caddy
  git -C "$svc" "${gc[@]}" commit -qam back
  REAL_CADDY="$real" t "serviço: a fonte legítima passa no limite do repo" 0 apply_config
  ok "serviço: vivo segue igual depois das recusas" 'cmp -s "$SB/waha.keep" "$CONF_DEST_DIR/waha.caddy"'
  # 19. symlink commitado no lugar do vhost → recusa (não segue link)
  local svl="$SB/svc-link"; mkdir -p "$svl/caddy"; git -C "$svl" init -q -b master
  ln -s /etc/passwd "$svl/caddy/link.caddy"; git -C "$svl" add caddy/link.caddy
  git -C "$svl" -c user.name=t -c user.email=t@t -c core.hooksPath=/dev/null -c commit.gpgsign=false commit -qm link
  printf 'link.caddy\t%s\tmaster\tcaddy/link.caddy\tlink.example\t127.0.0.1:1\n' "$svl" >> "$SERVICE_TSV"
  t "serviço: symlink commitado como vhost → apply RECUSA" 2 apply_config
  ok "serviço: a recusa do symlink é pelo modo do blob (não pelo conteúdo do link)" 'set +e; _o="$( set -e; apply_config 2>&1 )"; set -e; [[ "$_o" == *"não é arquivo comum"* ]]'
  sed -i '/^link\.caddy/d' "$SERVICE_TSV"
  # 20. vhost novo de serviço (o gokapi): fonte na ref, nada no vivo → criado e carimbado
  local svg="$SB/svc-gokapi"; mkdir -p "$svg/caddy"; git -C "$svg" init -q -b master
  printf '# transfer\ntransfer.example {\n\t@setup path /setup*\n\trespond @setup 404\n\treverse_proxy 127.0.0.1:3050\n}\n' > "$svg/caddy/gokapi.caddy"
  git -C "$svg" add caddy/gokapi.caddy; git -C "$svg" -c user.name=t -c user.email=t@t -c core.hooksPath=/dev/null -c commit.gpgsign=false commit -qm vhost
  printf 'gokapi.caddy\t%s\tmaster\tcaddy/gokapi.caddy\ttransfer.example\t127.0.0.1:3050\n' "$svg" >> "$SERVICE_TSV"
  ok "serviço: ensaio anuncia CRIAR e não toca o vivo" 'set +e; _o="$( set -e; plan 2>&1 )"; set -e; [[ "$_o" == *"CRIAR"*"conf.d/gokapi.caddy"* && ! -e "$CONF_DEST_DIR/gokapi.caddy" ]]'
  t "serviço: vhost novo do repo → apply cria" 0 apply_config
  ok "serviço: vhost novo carimbado com a fonte do repo" '[[ "$(head -n1 "$CONF_DEST_DIR/gokapi.caddy")" == "$SERVICE_MARK svc-gokapi:caddy/gokapi.caddy" ]]'
  ok "serviço: ensaio depois do apply diz inalterado" 'set +e; _o="$( set -e; plan 2>&1 )"; set -e; [[ "$_o" == *"= inalterado · conf.d/gokapi.caddy"* ]]'
  # 21. PENDENTE: a ref perde o arquivo (ou o clone some) → o vivo carimbado FICA; check acusa, apply não remove
  mv "$svg" "$SB/svc-gokapi.away"
  t "serviço: fonte sumida → check acusa" 1 check
  t "serviço: fonte sumida → apply segue" 0 apply_config
  ok "serviço: fonte sumida NÃO remove o vivo carimbado" '[[ -f "$CONF_DEST_DIR/gokapi.caddy" ]]'
  mv "$SB/svc-gokapi.away" "$svg"
  # 22. nome nas duas fontes (core e serviço) → recusa
  cp "$svg/caddy/gokapi.caddy" "$CONF_SRC_DIR/gokapi.caddy"
  t "serviço: mesmo nome no core e na lista → apply RECUSA" 2 apply_config
  rm -f "$CONF_SRC_DIR/gokapi.caddy"
  # 23. lista malformada (caminho fora de caddy/) → recusa, nada pela metade
  printf 'bad.caddy\t%s\tmaster\tdocker-compose.yml\tbad.example\t127.0.0.1:1\n' "$svg" >> "$SERVICE_TSV"
  t "serviço: linha da lista com caminho fora de caddy/ → apply RECUSA" 2 apply_config
  t "serviço: linha da lista com caminho fora de caddy/ → check RECUSA" 2 check
  sed -i '/^bad\.caddy/d' "$SERVICE_TSV"
  # 24. saiu da lista → vira órfão carimbado e é removido (com backup), como os do core
  sed -i '/^gokapi\.caddy/d' "$SERVICE_TSV"
  t "serviço: tirado da lista → apply remove o órfão" 0 apply_config
  ok "serviço: órfão de serviço removido e o adotado preservado" '[[ ! -e "$CONF_DEST_DIR/gokapi.caddy" && -f "$CONF_DEST_DIR/waha.caddy" ]]'

  echo "── selftest: ${pass} pass / ${fail} fail ──"
  [[ "$fail" -eq 0 ]]
}

SRC_CACHE="$(mktemp -d)"; trap 'rm -rf -- "${SRC_CACHE:-}"' EXIT   # fontes lidas (sem segredo); os subshells herdam
MODE="${1:-install}"
case "$MODE" in
  --help|-h)  usage; exit 0 ;;
  --selftest) selftest ;;
  --check)    check ;;
  --plan)     plan ;;
  install)    [[ -f "$DEST" || -d /etc/caddy ]] || die "sem /etc/caddy — este script roda NA KVM 8"
              apply_config ;;
  *) die "modo desconhecido: $MODE (use --help)" ;;
esac
