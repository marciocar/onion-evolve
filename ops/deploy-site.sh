#!/usr/bin/env bash
# Deploy do site onionevolve.com — fonte (repo) → webroot (derivação).
#
# POR QUE EXISTE (medido 2026-08-25): o deploy era prosa de README (cp/rsync à mão) e o
# vivo driftou por UM MÊS — a home no ar anunciava 98 comandos/8 skills/82 KBs enquanto a
# fonte commitada (42825bd6, 24/ago) já dizia 104/12/91. O grafo de identidade tem o nó
# (C_SITE_LAG_E_DEPLOY_NAO_AUTORIA_0804): a doença é deploy, não autoria. Procedimento
# que fica "temporário" evapora e volta como incidente — vira artefato versionado com
# guardas (mesma doutrina do gpg-protect-key.sh desta pasta).
#
# GUARDAS POR CONSTRUÇÃO (não por disciplina) — as 3 originais + as que a revisão
# adversarial de 2026-08-25 forjou refutando as promessas por execução (R1/R2 do
# resíduo docs/evolution/review/feat-site-reform-f0-deploy.md):
#  1. ALLOWLIST de entradas — o script só toca o que está em DEPLOY_ENTRIES. `mini/` e
#     `pulse-mais/` têm fonte em OUTROS repos: jamais entram aqui. Não existe modo
#     "raiz inteira".
#  2. `--check` compara fonte×vivo por hash e sai ≠0 em drift. Desde o cutover ele
#     BUILDA por dentro (efeito colateral deliberado e único: escrever site/dist, que é
#     derivação gitignored) — comparar um dist velho daria verde com a fonte adiantada.
#     O que segue read-only é o WEBROOT: --check jamais o toca.
#  3. Derivação não guarda backup: `*.bak*` no webroot é lixo servido publicamente
#     (14 encontrados em 2026-08-25) e o `--check` os acusa; o deploy os remove.
#  4. SYMLINK no topo de uma entrada (fonte OU webroot) = recusa. A revisão provou que
#     `rsync --delete` segue o link e destrói o alvo — inclusive `mini/` ou a PRÓPRIA
#     FONTE. Link no topo nunca é estado legítimo desta derivação.
#  5. Fonte VAZIA nunca deploya nem passa verde: hash de vazio dos dois lados era
#     indistinguível de sucesso — um build quebrado (F1: fonte vira site/dist) apagaria
#     o site no ar com veredito ✓. Entrada sem arquivo = EMPTY = erro.
#  6. O hash cobre conteúdo de arquivo E estrutura (symlinks/dirs), com LC_ALL=C —
#     estável entre locales e cego a nada.
#
# Uso:
#   ops/deploy-site.sh             # deploya a allowlist (local, na KVM 8)
#   ops/deploy-site.sh --check     # builda e verifica drift dist×webroot (exit 1 se houver)
#   ops/deploy-site.sh --selftest  # bancada em sandbox (nunca toca fonte/webroot reais)
#
# Fonte: o OUTPUT DO BUILD Astro (site/dist) — cutover F2 da reforma (2026-08-25).
# O build roda AQUI DENTRO (deploy E --check): comparar um dist velho contra o webroot
# recém-deployado dele mesmo daria verde com a fonte adiantada — a doença da F0 num
# nível acima. Mecanismo, não disciplina: quem chama nunca precisa lembrar de buildar.
set -euo pipefail
set -f  # a allowlist é fronteira de segurança: nada de pathname expansion contra o CWD
export LC_ALL=C

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="${REPO}/site/dist"
WEBROOT="/var/www/onion-landing"
SUDO_CMD="sudo"
# O selftest troca por ":" (sandbox não builda); fora dele, é sempre o build real.
BUILD_CMD=(npm --prefix "${REPO}/site" run build)

# Allowlist: TUDO que o deploy gerencia. Entrada nova no site = linha nova aqui
# (é o ponto único de decisão do-que-se-publica, como o manifesto dos plugins).
# /convite/ e /historia/grafo/ saíram no cutover → redirects 301 no Caddy.
DEPLOY_ENTRIES=(
  index.html
  _astro
  fonts
  images
  historia
  federacao
  grafo
  doutrinas
  maquinaria
  estado
  en
)

# Rotas APOSENTADAS no cutover: o deploy só roda se o Caddy já responder 301 nelas
# (checagem COMPORTAMENTAL por curl — grep no Caddyfile provaria o texto, não o
# serviço). "Escrever o redir antes do deploy" deixa de ser disciplina: o deploy
# não roda de outro jeito. (Formulação da re-revisão adversarial, adotada.)
RETIRED_ROUTES=(
  https://onionevolve.com/convite/
  https://onionevolve.com/historia/grafo/
)
# Entradas APOSENTADAS no topo do webroot: o deploy as REMOVE e o --check ACUSA se
# reaparecerem — sem isto, /convite/ ficaria servido para sempre com a fonte apagada
# do repo (a doença fonte≠derivação, invisível a uma allowlist).
RETIRED_ENTRIES=(
  convite
)

run_build() {
  "${BUILD_CMD[@]}" >/dev/null 2>&1 || die "build Astro FALHOU — nada foi tocado (rode '${BUILD_CMD[*]}' para ver o erro)"
  [[ -d "$SRC_ROOT" ]] || die "build passou mas não produziu ${SRC_ROOT} — investigue"
}

usage() {
  sed -n 's/^# \?//p' "${BASH_SOURCE[0]}" | sed -n '/^Uso:/,/^$/p'
}

die() { echo "ERRO: $*" >&2; exit 2; }

# ── hash de entrada ─────────────────────────────────────────────────────────────────
# Devolve: <sha256> | ABSENT | EMPTY. rc≠0 = erro de leitura (o chamador ACUSA, não
# engole — guarda 6/R5: check parcial que morre mudo é indistinguível de drift).
hash_entry() {
  local root="$1" entry="$2" files links nfiles
  if [[ -L "$root/$entry" ]]; then echo "SYMLINK"; return 0; fi
  [[ -e "$root/$entry" ]] || { echo "ABSENT"; return 0; }
  if [[ -f "$root/$entry" ]]; then
    sha256sum "$root/$entry" | awk '{print $1}'; return 0
  fi
  # Diretório: conteúdo dos arquivos + estrutura (dirs e symlinks com alvo).
  files="$(cd "$root" && find "$entry" -type f -print0 | sort -z | xargs -0 -r sha256sum)" || return 1
  links="$(cd "$root" && find "$entry" -mindepth 1 \( -type l -o -type d \) -printf '%y %p -> %l\n' | sort)" || return 1
  nfiles="$(cd "$root" && find "$entry" \( -type f -o -type l \) | wc -l)" || return 1
  if [[ "$nfiles" -eq 0 ]]; then echo "EMPTY"; return 0; fi
  printf '%s\n%s\n' "$files" "$links" | sha256sum | awk '{print $1}'
}

# Lista de *.bak* na derivação, fora de mini/ e pulse-mais/ (que não são nossos).
list_baks() {
  find "$WEBROOT" \( -path "$WEBROOT/mini" -o -path "$WEBROOT/pulse-mais" \) -prune \
    -o -name '*.bak*' -print
}

check() {
  local drift=0 verified=0 total="${#DEPLOY_ENTRIES[@]}" entry h_src h_web
  for entry in "${DEPLOY_ENTRIES[@]}"; do
    if ! h_src="$(hash_entry "$SRC_ROOT" "$entry")"; then
      echo "✗ ERRO lendo a FONTE de '$entry' (permissão?) — entrada NÃO verificada" >&2
      drift=1; continue
    fi
    if ! h_web="$(hash_entry "$WEBROOT" "$entry")"; then
      echo "✗ ERRO lendo o WEBROOT de '$entry' (permissão?) — entrada NÃO verificada" >&2
      drift=1; continue
    fi
    verified=$((verified + 1))
    case "$h_src/$h_web" in
      SYMLINK/*|*/SYMLINK)
        echo "✗ SYMLINK no topo de '$entry' (fonte=$h_src, vivo=$h_web) — estado ilegítimo; NÃO rode o deploy, investigue" >&2
        drift=1 ;;
      ABSENT/*)
        echo "✗ fonte sem a entrada '$entry' (vivo: ${h_web:0:12})" >&2; drift=1 ;;
      EMPTY/*)
        echo "✗ fonte VAZIA em '$entry' — deploy apagaria o vivo; se intencional, remova da allowlist" >&2
        drift=1 ;;
      *)
        if [[ "$h_src" != "$h_web" ]]; then
          echo "✗ DRIFT: $entry (fonte ${h_src:0:12} ≠ vivo ${h_web:0:12})" >&2; drift=1
        else
          echo "✓ $entry"
        fi ;;
    esac
  done
  local baks
  if ! baks="$(list_baks)"; then
    echo "✗ ERRO na varredura de *.bak* — cobertura incompleta" >&2; drift=1
  elif [[ -n "$baks" ]]; then
    echo "✗ backup servido publicamente na derivação:" >&2
    echo "$baks" >&2
    drift=1
  fi
  # Entrada aposentada que REAPARECEU no webroot = fonte fantasma servida ao público.
  local retired
  for retired in "${RETIRED_ENTRIES[@]}"; do
    if [[ -e "$WEBROOT/$retired" ]]; then
      echo "✗ entrada APOSENTADA '$retired' presente no webroot — fonte apagada do repo, página fantasma no ar" >&2
      drift=1
    fi
  done
  echo "── ${verified}/${total} entradas verificadas ──"
  return "$drift"
}

# As rotas aposentadas devem responder 301 ANTES do deploy remover o conteúdo delas —
# senão o cutover abre 404. Comportamental: mede o serviço, não o arquivo de config.
# CURL_CMD é indireção (padrão do BUILD_CMD): o selftest troca por stub e prova os dois
# ramos sem Caddy — a guarda que decide SE o deploy roda não fica sem rede.
CURL_CMD=(curl -sI -o /dev/null -w '%{http_code}' --max-time 10)
check_retired_routes() {
  local url code
  for url in "${RETIRED_ROUTES[@]}"; do
    code="$("${CURL_CMD[@]}" "$url")" || die "não consegui medir $url — sem prova de redirect, sem deploy"
    case "$code" in
      301|308) : ;;
      *) die "rota aposentada $url responde $code (esperado 301) — escreva o redir no Caddy e recarregue ANTES do deploy" ;;
    esac
  done
}

deploy() {
  local entry h_src
  # Pré-voo: TODAS as entradas validadas ANTES de tocar o vivo (deploy meio-aplicado
  # com mensagem críptica foi achado R4/R11 da revisão).
  check_retired_routes
  for entry in "${DEPLOY_ENTRIES[@]}"; do
    [[ -L "$SRC_ROOT/$entry" ]] && die "fonte de '$entry' é SYMLINK — estado ilegítimo"
    [[ -L "$WEBROOT/$entry" ]] && die "webroot de '$entry' é SYMLINK — rsync seguiria o link e destruiria o alvo; investigue antes"
    [[ -e "$SRC_ROOT/$entry" ]] || die "allowlist cita '$entry' mas a fonte não o tem"
    if ! h_src="$(hash_entry "$SRC_ROOT" "$entry")"; then die "fonte de '$entry' ilegível"; fi
    [[ "$h_src" == "EMPTY" ]] && die "fonte VAZIA em '$entry' — deployar apagaria o vivo (build quebrado?)"
  done
  for entry in "${DEPLOY_ENTRIES[@]}"; do
    if [[ -d "$SRC_ROOT/$entry" ]]; then
      # --delete é seguro AQUI: escopado à entrada da allowlist (pré-validada acima),
      # nunca à raiz. --safe-links: link que aponte para fora da árvore não viaja.
      # --checksum: o quick-check padrão (tamanho+mtime, granularidade de 1s) PULOU
      # arquivo alterado no mesmo segundo com o mesmo tamanho — provado pela bancada;
      # é o cenário exato de um build (dist/ regenerado). O site é pequeno: correção
      # ganha de velocidade.
      $SUDO_CMD rsync -a --delete --safe-links --checksum "$SRC_ROOT/$entry/" "$WEBROOT/$entry/"
    else
      $SUDO_CMD rsync -a --checksum "$SRC_ROOT/$entry" "$WEBROOT/$entry"
    fi
  done
  # Remove lixo de backup (arquivo OU diretório) da derivação — SEM parsing de nomes:
  # a v2 coletava `find -print` e um nome com NEWLINE virava dois alvos (a re-revisão
  # provou `evil.bak\nmini` destruindo mini/). O -exec entrega o caminho intacto ao rm;
  # o -prune no nome casado evita descer em diretório já removido. Guardado (não `set -e`
  # cru): um find parcial entre o rsync e a verificação abortava mudo — o check abaixo é
  # quem acusa qualquer *.bak* remanescente.
  if ! $SUDO_CMD find "$WEBROOT" \( -path "$WEBROOT/mini" -o -path "$WEBROOT/pulse-mais" \) -prune \
    -o -name '*.bak*' -prune -exec rm -rf -- {} +; then
    echo "⚠ limpeza de *.bak* incompleta (find falhou) — a verificação abaixo decide" >&2
  fi
  # Entradas aposentadas saem do webroot (o redir já foi PROVADO no pré-voo).
  local retired
  for retired in "${RETIRED_ENTRIES[@]}"; do
    [[ -e "$WEBROOT/$retired" ]] && $SUDO_CMD rm -rf -- "$WEBROOT/$retired"
  done
  # Dono uniforme: a derivação é operada por marcio (federacao/ nasceu root em jul/26).
  for entry in "${DEPLOY_ENTRIES[@]}"; do
    $SUDO_CMD chown -R marcio:marcio "$WEBROOT/$entry"
  done
  echo "── deploy aplicado; verificando ──"
  check
}

# ── selftest: os ataques da revisão adversarial, congelados como bancada ────────────
# Roda em sandbox (mktemp), SEM sudo, SEM tocar fonte/webroot reais. Cada caso é um
# ataque que REFUTOU (ou tentou refutar) uma guarda — regressão de qualquer um deles
# volta a ser destruição de dado em produção.
selftest() {
  local pass=0 fail=0
  # SB é GLOBAL e o trap usa aspas simples (expande só no EXIT): a v2 expandia o valor
  # na montagem do trap e um TMPDIR com aspa injetava comando (provado pela re-revisão).
  SB="$(mktemp -d)"
  trap 'rm -rf "$SB"' EXIT
  local sb="$SB"
  SRC_ROOT="$sb/src"; WEBROOT="$sb/web"; SUDO_CMD=""; BUILD_CMD=(:)
  RETIRED_ROUTES=()  # zeradas para os casos gerais; os casos de rota usam stub abaixo
  RETIRED_ENTRIES=(aposentada)
  DEPLOY_ENTRIES=(index.html secao)
  mkdir -p "$SRC_ROOT/secao" "$WEBROOT/secao" "$WEBROOT/mini/assets"
  echo home > "$SRC_ROOT/index.html"; echo home > "$WEBROOT/index.html"
  echo a > "$SRC_ROOT/secao/a.txt";   echo a > "$WEBROOT/secao/a.txt"
  echo precioso > "$WEBROOT/mini/assets/site.html"

  t() { # t <nome> <esperado_rc> <cmd...> — subshell: um `die` (exit 2) do caso não
    local name="$1" want="$2"; shift 2; local rc=0 out   # pode matar a bancada inteira
    out="$( ( "$@" ) 2>&1 )" || rc=$?
    if [[ "$rc" -eq "$want" ]]; then pass=$((pass+1)); echo "  ✓ $name"
    else
      fail=$((fail+1)); echo "  ✗ $name (rc=$rc, esperado=$want)"
      printf '%s\n' "$out" | sed 's/^/      | /'
    fi
  }

  echo "── selftest (sandbox: $sb) ──"
  t "estado limpo: check verde"                    0 check
  t "estado limpo: deploy idempotente"             0 deploy
  echo b > "$SRC_ROOT/secao/a.txt"
  t "drift de conteúdo: check acusa"               1 check
  t "drift de conteúdo: deploy cura"               0 deploy
  ln -s alvo-inexistente "$SRC_ROOT/secao/quebrado"
  t "symlink DENTRO da entrada (fonte): check acusa" 1 check
  rm "$SRC_ROOT/secao/quebrado"
  # R1 — o ataque que derrubou a invariante 1: symlink no topo do webroot → mini/
  rm -rf "$WEBROOT/secao"; ln -s "$WEBROOT/mini" "$WEBROOT/secao"
  t "R1 symlink no topo do webroot: check acusa"   1 check
  t "R1 symlink no topo do webroot: deploy RECUSA" 2 deploy
  [[ -f "$WEBROOT/mini/assets/site.html" ]] && { pass=$((pass+1)); echo "  ✓ R1 mini/ intacto"; } \
    || { fail=$((fail+1)); echo "  ✗ R1 mini/ foi tocado"; }
  rm "$WEBROOT/secao"; mkdir -p "$WEBROOT/secao"; echo b > "$WEBROOT/secao/a.txt"
  # R1b — symlink no topo da FONTE (a guarda existia mas não tinha rede de regressão)
  mv "$SRC_ROOT/secao" "$SRC_ROOT/secao-real"; ln -s secao-real "$SRC_ROOT/secao"
  t "R1b symlink no topo da FONTE: check acusa"    1 check
  t "R1b symlink no topo da FONTE: deploy RECUSA"  2 deploy
  rm "$SRC_ROOT/secao"; mv "$SRC_ROOT/secao-real" "$SRC_ROOT/secao"
  # R2 — fonte vazia nunca sai verde nem deploya
  rm -rf "$SRC_ROOT/secao"; mkdir -p "$SRC_ROOT/secao"
  t "R2 fonte vazia: check acusa"                  1 check
  t "R2 fonte vazia: deploy RECUSA"                2 deploy
  [[ -f "$WEBROOT/secao/a.txt" ]] && { pass=$((pass+1)); echo "  ✓ R2 vivo preservado"; } \
    || { fail=$((fail+1)); echo "  ✗ R2 vivo apagado"; }
  echo a > "$SRC_ROOT/secao/a.txt"
  # R4 — .bak em arquivo E diretório somem; dentro de mini/ sobrevivem
  echo lixo > "$WEBROOT/secao/velho.bak"; mkdir -p "$WEBROOT/old.bak-dir"; echo x > "$WEBROOT/old.bak-dir/f"
  echo meu > "$WEBROOT/mini/legit.bak"
  t "R3/R4 .bak presentes: check acusa"            1 check
  t "R4 deploy limpa .bak (arquivo e dir)"         0 deploy
  { [[ ! -e "$WEBROOT/secao/velho.bak" && ! -e "$WEBROOT/old.bak-dir" && -f "$WEBROOT/mini/legit.bak" ]] \
    && { pass=$((pass+1)); echo "  ✓ R4 .bak fora somem, mini/ preservado"; } ; } \
    || { fail=$((fail+1)); echo "  ✗ R4 limpeza de .bak errada"; }
  # Caso 15 (re-revisão, NOVO-1): nome de .bak com NEWLINE, deploy invocado DE DENTRO
  # do webroot — o ataque que fez a limpeza-por-parsing destruir mini/ na v2.
  touch "$WEBROOT/"$'evil.bak\nmini'
  deploy_from_webroot() { cd "$WEBROOT" && deploy; }
  t "R4b .bak com newline no nome: deploy limpa sem parsing" 0 deploy_from_webroot
  { [[ ! -e "$WEBROOT/"$'evil.bak\nmini' && -f "$WEBROOT/mini/assets/site.html" && -f "$WEBROOT/mini/legit.bak" ]] \
    && { pass=$((pass+1)); echo "  ✓ R4b alvo único removido; mini/ intacto"; } ; } \
    || { fail=$((fail+1)); echo "  ✗ R4b parsing de nome voltou a alcançar mini/"; }

  # RETIRED — entrada aposentada reaparecendo no webroot é página fantasma
  mkdir -p "$WEBROOT/aposentada"; echo fantasma > "$WEBROOT/aposentada/index.html"
  t "retired: entrada aposentada no webroot → check acusa" 1 check
  t "retired: deploy a remove" 0 deploy
  { [[ ! -e "$WEBROOT/aposentada" ]] \
    && { pass=$((pass+1)); echo "  ✓ retired: fantasma removida"; } ; } \
    || { fail=$((fail+1)); echo "  ✗ retired: fantasma sobreviveu ao deploy"; }

  # RETIRED-ROUTES — o pré-voo comportamental, provado por stub (sem Caddy):
  # rota ainda 200 → deploy RECUSA; 301 → prossegue. (Ressalva (a) da re-revisão.)
  RETIRED_ROUTES=(https://exemplo.invalido/aposentada/)
  CURL_CMD=(bash -c 'echo 200' --)   # o stub recebe a URL como arg e devolve SÓ o código
  t "retired-route: rota ainda 200 → deploy RECUSA" 2 deploy
  CURL_CMD=(bash -c 'echo 301' --)
  t "retired-route: rota 301 → deploy prossegue" 0 deploy
  RETIRED_ROUTES=(); CURL_CMD=(curl)

  # CUTOVER — build que falha não toca NADA (o caminho que o dist inaugurou; a revisão
  # adversarial acusou run_build sem rede: o selftest chamava check/deploy direto e o
  # dispatcher nunca era exercitado).
  BUILD_CMD=(false)
  t "cutover: build falha → run_build RECUSA (die)" 2 run_build
  BUILD_CMD=(:)
  { [[ -f "$WEBROOT/secao/a.txt" && -f "$WEBROOT/mini/assets/site.html" ]] \
    && { pass=$((pass+1)); echo "  ✓ cutover: webroot intacto após build falho"; } ; } \
    || { fail=$((fail+1)); echo "  ✗ cutover: build falho tocou o webroot"; }

  echo "── selftest: ${pass} pass / ${fail} fail ──"
  [[ "$fail" -eq 0 ]]
}

MODE="${1:-deploy}"
case "$MODE" in
  --help|-h) usage; exit 0 ;;
  --selftest) selftest ;;
  --check)
    [[ -d "$WEBROOT" ]] || die "webroot ausente: $WEBROOT (este script roda NA KVM 8)"
    run_build
    check ;;
  deploy)
    [[ -d "$WEBROOT" ]] || die "webroot ausente: $WEBROOT (este script roda NA KVM 8)"
    run_build
    deploy ;;
  *) die "modo desconhecido: $MODE (use --help)" ;;
esac
