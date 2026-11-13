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
#   ops/deploy-site.sh deploy --verified-pr <N>   # o deploy DELEGADO à sessão (ver abaixo)
#
# DEPLOY DELEGADO (D_DELEGATE_SITE_DEPLOY_AFTER_VERIFIED_MERGE_1113, selado pelo maestro em 2026-11-13): a sessão pode
# deployar só com a main verde e o PR revisado por refutador independente, com --check antes e depois. O veto do MOAT
# (pretooluse-moat-gate.sh, core-only) só deixa a sessão rodar o deploy com --verified-pr; as condições moram AQUI e
# recusam (rc 2) antes de buildar ou tocar o webroot:
#   1. este checkout está em origin/main (buscada agora), e site/ e este script sem mudança nem arquivo não rastreado;
#   2. a main VERDE: os check-runs do commit de origin/main existem, terminaram, e nenhum falhou;
#   3. o PR <N> está MERGED na main, tocou site/, e a árvore site/ de origin/main é a mesma do commit de merge dele
#      (o que vai ao ar é exatamente o que o PR deixou; outro PR que mexeu em site/ depois exige o número dele);
#   4. REFUTADOR INDEPENDENTE, medido pelo resíduo da REGRA 56 do PR (docs/evolution/review/<branch>.md, lido no
#      commit de merge): `elenxo: true` E `elenxo_isolado: true` (a passada adversarial por agente separado, a mesma
#      régua do AUTOMATE do /meta:drive), verdict aprovado e reviewed_diff_sha256 carimbado.
#   Depois: --check ANTES (o drift esperado é impresso, não recusa), o deploy, e o --check DEPOIS decide o rc.
#   TETO: `elenxo_isolado: true` é auto-atestado no resíduo; o script exige a declaração, não prova o isolamento.
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
# o forge do deploy delegado: o selftest troca por uma função de stub
GH_CMD=(gh)

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
  backbone
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

# ── deploy delegado: as quatro condições do selo, medidas antes de qualquer efeito ───
# rc 0 = todas valem; die (rc 2) nomeia a que falta. Lê: git deste checkout, o forge (check-runs da main e o PR).
VERIFIED_PR=""
vp_slug() { git -C "$REPO" remote get-url origin 2>/dev/null \
  | sed -E 's#^(git@[^:]+:|ssh://git@[^/]+/|https?://([^@/]+@)?[^/]+/)##; s#\.git$##; s#/+$##'; }
verified_gate() {
  local pr="$1" why="o deploy delegado exige a main verde e o PR revisado por refutador independente (D_DELEGATE_SITE_DEPLOY_AFTER_VERIFIED_MERGE_1113)"
  [[ "$pr" =~ ^[0-9]+$ ]] || die "--verified-pr exige o NÚMERO do PR, não '${pr}'"
  local slug head main dirty runs bad pr_tsv state base merge files ref rel body fm k v dup
  slug="$(vp_slug)"; [[ -n "$slug" ]] || die "não li o remote origin deste checkout — sem ele não sei de que repo medir o CI"
  # 1. o checkout é a origin/main recém-buscada, e o que o build lê está limpo
  git -C "$REPO" fetch -q origin main 2>/dev/null || die "não busquei origin/main — sem a ponta da main não há deploy delegado"
  head="$(git -C "$REPO" rev-parse HEAD 2>/dev/null)"; main="$(git -C "$REPO" rev-parse origin/main 2>/dev/null)"
  [[ -n "$head" && "$head" == "$main" ]] || die "este checkout está em ${head:0:12}, não em origin/main ${main:0:12}: ${why}. Rode de uma worktree de origin/main."
  dirty="$(git -C "$REPO" status --porcelain -- site ops/deploy-site.sh 2>/dev/null)" || die "não li o estado de site/ neste checkout"
  [[ -z "$dirty" ]] || die "site/ ou ops/deploy-site.sh com mudança ou arquivo não rastreado neste checkout — o build publicaria o que não está na main: $(head -3 <<< "$dirty" | tr '\n' ' ')"
  # 2. a main verde: os check-runs do commit existem, terminaram e nenhum falhou
  runs="$("${GH_CMD[@]}" api "repos/${slug}/commits/${main}/check-runs?per_page=100" --paginate \
          --jq '.check_runs[] | [.name, .status, (.conclusion // "")] | @tsv' 2>/dev/null)" \
    || die "não li os check-runs de origin/main ${main:0:12} — sem ler o CI não há main verde"
  [[ -n "$runs" ]] || die "origin/main ${main:0:12} não tem check-run nenhum (o CI ainda não nasceu?): ${why}"
  bad="$(awk -F'\t' '$2 != "completed" || ($3 != "success" && $3 != "skipped" && $3 != "neutral") { print $1 " (" $2 "/" $3 ")" }' <<< "$runs")"
  [[ -z "$bad" ]] || die "a main ${main:0:12} não está verde: $(head -5 <<< "$bad" | tr '\n' ' ')— ${why}"
  # 3. o PR mergeado, que tocou site/, e cuja árvore site/ é a que vai ao ar
  pr_tsv="$("${GH_CMD[@]}" pr view "$pr" --repo "$slug" --json state,baseRefName,headRefName,mergeCommit \
            --jq '[.state, .baseRefName, .headRefName, (.mergeCommit.oid // "")] | @tsv' 2>/dev/null)" \
    || die "não li o PR #${pr} no forge"
  IFS=$'\t' read -r state base ref merge <<< "$pr_tsv"
  [[ "$state" == MERGED && "$base" == main ]] || die "o PR #${pr} está '${state:-?}' na base '${base:-?}', não MERGED na main: ${why}"
  [[ -n "$merge" ]] && git -C "$REPO" merge-base --is-ancestor "$merge" "$main" 2>/dev/null \
    || die "o commit de merge do PR #${pr} (${merge:0:12}) não está na origin/main deste checkout"
  files="$("${GH_CMD[@]}" api "repos/${slug}/pulls/${pr}/files?per_page=100" --paginate --jq '.[].filename' 2>/dev/null)" \
    || die "não li os arquivos do PR #${pr}"
  grep -q '^site/' <<< "$files" || die "o PR #${pr} não tocou site/: ele não revisou o que vai ao ar. Use o número do PR que mudou o site."
  [[ "$(git -C "$REPO" rev-parse "${main}:site" 2>/dev/null)" == "$(git -C "$REPO" rev-parse "${merge}:site" 2>/dev/null)" ]] \
    || die "site/ mudou na main depois do PR #${pr} (outro PR mexeu no site): o que iria ao ar não é o que ele revisou. Use o número do último PR que tocou site/."
  # 4. o refutador independente, pelo resíduo do PR
  rel="docs/evolution/review/${ref//\//-}.md"
  body="$(git -C "$REPO" show "${merge}:${rel}" 2>/dev/null)" || die "o PR #${pr} não deixou o resíduo ${rel} na main (REGRA 56): ${why}"
  fm="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1' <<< "$body")"
  [[ -n "$fm" ]] || die "${rel} sem frontmatter"
  dup="$(awk '/^[A-Za-z_][A-Za-z0-9_]*:/{k=$0; sub(/:.*/,"",k); if (c[k]++==1) printf "%s ", k}' <<< "$fm")"
  [[ -z "$dup" ]] || die "${rel} repete chave no frontmatter (${dup}): o bash lê a 1ª e o YAML a última"
  fmv() { sed -n "s/^$1:[[:space:]]*//p" <<< "$fm" | head -1 | tr -d "\"' " | tr '[:upper:]' '[:lower:]'; }
  for k in elenxo elenxo_isolado; do
    v="$(fmv "$k")"
    [[ "$v" == true ]] || die "${rel} declara ${k}: '${v:-ausente}' — refutador independente é elenxo: true E elenxo_isolado: true (a passada por agente separado): ${why}"
  done
  v="$(fmv verdict | tr 'a-z-' 'A-Z_')"
  case "$v" in APPROVED|FIXED|REJECTED_AND_FIXED|NO_FINDINGS) ;; *) die "${rel} tem verdict '${v:-ausente}': o refutador não aprovou" ;; esac
  v="$(fmv reviewed_diff_sha256)"
  [[ "$v" =~ ^[0-9a-f]{64}$ ]] || die "${rel} tem reviewed_diff_sha256 '${v:-ausente}': o resíduo não foi carimbado"
  echo "✓ deploy delegado: origin/main ${main:0:12} verde ($(wc -l <<< "$runs") check-runs), PR #${pr} mergeado com site/ intacto desde ele, resíduo ${rel} com Elenxo isolado (${v:0:12})"
}

delegated_deploy() {
  local pre=0
  verified_gate "$VERIFIED_PR"
  [[ -d "$WEBROOT" ]] || die "webroot ausente: $WEBROOT (este script roda NA KVM 8)"
  run_build
  echo "── --check ANTES do deploy delegado ──"
  check || pre=$?
  [[ "$pre" -eq 0 ]] && echo "── antes: nada a mudar (o deploy é idempotente) ──" || echo "── antes: drift acima (é o que o deploy vai levar ao ar) ──"
  echo "── deploy + --check DEPOIS ──"
  deploy
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

  # DEPLOY DELEGADO (D_DELEGATE_SITE_DEPLOY_AFTER_VERIFIED_MERGE_1113): cada condição do selo recusa sozinha. O REPO vira
  # um clone de sandbox com origin num bare local; o forge é a função _gh_stub (STUB_RUNS e STUB_PR por caso)
  local gb="$sb/origin.git" gr="$sb/repo" mrg
  git init -q --bare -b main "$gb"
  git init -q -b main "$gr"; git -C "$gr" remote add origin "$gb"
  mkdir -p "$gr/site" "$gr/docs/evolution/review" "$gr/ops"; echo v1 > "$gr/site/index.md"; echo x > "$gr/ops/deploy-site.sh"
  vp_residue() { printf -- '---\nverdict: %s\nelenxo: %s\nelenxo_isolado: %s\nreviewed_diff_sha256: %s\n---\n' "$1" "$2" "$3" "${4:-$(printf 'a%.0s' {1..64})}"; }
  vp_residue APPROVED true true > "$gr/docs/evolution/review/feat-site.md"
  git -C "$gr" add -A; git -C "$gr" -c user.email=t@t -c user.name=t commit -qm pr; git -C "$gr" push -q origin main
  mrg="$(git -C "$gr" rev-parse HEAD)"
  REPO="$gr"
  STUB_RUNS=$'lint\tcompleted\tsuccess\nselftest\tcompleted\tskipped'; STUB_PR="MERGED	main	feat/site	${mrg}"; STUB_FILES="site/index.md"
  _gh_stub() {
    case "$*" in
      *check-runs*) [[ -n "$STUB_RUNS" ]] && printf '%s\n' "$STUB_RUNS"; return 0 ;;
      *"pr view"*)  printf '%s\n' "$STUB_PR"; return 0 ;;
      *"/files"*)   printf '%s\n' "$STUB_FILES"; return 0 ;;
    esac
    return 1
  }
  GH_CMD=(_gh_stub)
  t "delegado: todas as condições valem → passa"                     0 verified_gate 7
  t "delegado: --verified-pr sem número → recusa"                    2 verified_gate abc
  STUB_RUNS=$'lint\tin_progress\t'
  t "delegado: check-run da main ainda rodando → recusa"             2 verified_gate 7
  STUB_RUNS=$'lint\tcompleted\tfailure'
  t "delegado: main VERMELHA → recusa"                               2 verified_gate 7
  STUB_RUNS=""
  t "delegado: main sem check-run nenhum → recusa"                   2 verified_gate 7
  STUB_RUNS=$'lint\tcompleted\tsuccess'
  STUB_PR="OPEN	main	feat/site	"
  t "delegado: PR não mergeado → recusa"                             2 verified_gate 7
  STUB_PR="MERGED	main	feat/site	${mrg}"; STUB_FILES="docs/x.md"
  t "delegado: PR que não tocou site/ → recusa"                      2 verified_gate 7
  STUB_FILES="site/index.md"
  vp_residue APPROVED true false > "$gr/docs/evolution/review/feat-site.md"
  git -C "$gr" -c user.email=t@t -c user.name=t commit -qam r2; git -C "$gr" push -q origin main
  # o resíduo se lê no commit de MERGE do PR: reescrevê-lo depois, na main, não muda o que o PR teve
  t "delegado: resíduo reescrito DEPOIS do merge não conta → passa"  0 verified_gate 7
  STUB_PR="MERGED	main	feat/site	$(git -C "$gr" rev-parse HEAD)"
  t "delegado: resíduo sem elenxo_isolado (uma voz só) → recusa"     2 verified_gate 7
  vp_residue REJECTED true true > "$gr/docs/evolution/review/feat-site.md"
  git -C "$gr" -c user.email=t@t -c user.name=t commit -qam r3; git -C "$gr" push -q origin main
  STUB_PR="MERGED	main	feat/site	$(git -C "$gr" rev-parse HEAD)"
  t "delegado: refutador REPROVOU (verdict REJECTED) → recusa"       2 verified_gate 7
  vp_residue FIXED true true pendente > "$gr/docs/evolution/review/feat-site.md"
  git -C "$gr" -c user.email=t@t -c user.name=t commit -qam r4; git -C "$gr" push -q origin main
  STUB_PR="MERGED	main	feat/site	$(git -C "$gr" rev-parse HEAD)"
  t "delegado: resíduo sem carimbo (pendente) → recusa"              2 verified_gate 7
  vp_residue FIXED true true > "$gr/docs/evolution/review/feat-site.md"
  git -C "$gr" -c user.email=t@t -c user.name=t commit -qam r5; git -C "$gr" push -q origin main
  mrg="$(git -C "$gr" rev-parse HEAD)"; STUB_PR="MERGED	main	feat/site	${mrg}"
  t "delegado: resíduo refeito e aprovado → passa"                   0 verified_gate 7
  echo v2 > "$gr/site/index.md"; git -C "$gr" -c user.email=t@t -c user.name=t commit -qam outro; git -C "$gr" push -q origin main
  t "delegado: outro PR mexeu em site/ depois → recusa"              2 verified_gate 7
  STUB_PR="MERGED	main	feat/site	$(git -C "$gr" rev-parse HEAD)"
  echo sujo > "$gr/site/novo.md"
  t "delegado: arquivo não rastreado em site/ → recusa"              2 verified_gate 7
  rm "$gr/site/novo.md"
  git -C "$gr" -c user.email=t@t -c user.name=t commit -q --allow-empty -m local
  t "delegado: checkout à frente de origin/main → recusa"            2 verified_gate 7
  git -C "$gr" reset -q --hard origin/main
  t "delegado: de volta à ponta → passa"                             0 verified_gate 7
  # a linha de comando: `deploy` com argumento que não é --verified-pr recusa (antes, o resto da linha era ignorado)
  t "delegado: 'deploy --qualquer' → recusa (o argumento não some)"  2 bash "${BASH_SOURCE[0]}" deploy --qualquer
  t "delegado: 'deploy --verified-pr' sem número → recusa"           2 bash "${BASH_SOURCE[0]}" deploy --verified-pr

  # REFUTADOR DO #1647 (2026-11-13): as entradas exatas que passavam. A cópia da bancada tem o WEBROOT num caminho que não
  # existe: se a recusa regredir, o caso cai em "webroot ausente" e nunca deploya de verdade. O ancestral "claude" é um
  # bash copiado para .../bin/claude (o /proc/<pid>/exe dele casa), o que faz a bancada valer igual no CI e aqui.
  local ds="$sb/ds.sh" fcl="$sb/fakeclaude/bin/claude" o rc
  sed 's#^WEBROOT=.*#WEBROOT="/nonexistent-onion-webroot-bancada"#' "${BASH_SOURCE[0]}" > "$ds"
  mkdir -p "$(dirname "$fcl")" "$sb/fakegh"; cp "$(command -v bash)" "$fcl"
  printf '#!/bin/sh\necho fake\n' > "$sb/fakegh/gh"; chmod +x "$sb/fakegh/gh"
  tm() { # tm <nome> <rc> <trecho> <cmd...>: rc E a mensagem (rc 2 sozinho também é "webroot ausente")
    local name="$1" want="$2" txt="$3"; shift 3; rc=0; o="$( ( "$@" ) 2>&1 )" || rc=$?
    if [[ "$rc" -eq "$want" ]] && grep -qF -- "$txt" <<< "$o"; then pass=$((pass+1)); echo "  ✓ $name"
    else fail=$((fail+1)); echo "  ✗ $name (rc=$rc, esperado=$want com '$txt')"; printf '%s\n' "$o" | tail -3 | sed 's/^/      | /'; fi
  }
  tm "B2: sessão + 'bash deploy-site.sh <<< --verified-pr' (stdin, sem argv) → recusa o deploy do maestro" 2 "chamado pela sessão" \
    "$fcl" -c "bash '$ds' <<< --verified-pr"
  tm "B2: sessão + 'deploy <<< --verified-pr' → recusa" 2 "chamado pela sessão" "$fcl" -c "bash '$ds' deploy <<< --verified-pr"
  tm "B2: '\"\" --verified-pr 3' (1º argumento vazio) → recusa" 2 "1º argumento vazio" bash "$ds" "" --verified-pr 3
  tm "B2: 'deploy --verified-pr=' (forma com =) → recusa" 2 "argumento desconhecido" bash "$ds" deploy --verified-pr=
  tm "B2: 'deploy --verified-pr 3 extra' → recusa" 2 "uso:" bash "$ds" deploy --verified-pr 3 extra
  tm "B2: o maestro com --maestro passa da recusa da sessão (para no webroot da bancada)" 2 "webroot ausente" \
    "$fcl" -c "bash '$ds' deploy --maestro"
  tm "B4: GIT_CONFIG_* no deploy delegado → recusa antes de ler o forge" 2 "GIT_CONFIG_COUNT" \
    env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=remote.origin.url GIT_CONFIG_VALUE_0=https://github.com/x/y bash "$ds" deploy --verified-pr 3
  tm "B4: GH_REPO no deploy delegado → recusa" 2 "GH_REPO" env GH_REPO=x/y bash "$ds" deploy --verified-pr 3
  # N2 da re-refutação do #1647: o HOME (o ~/.gitconfig com insteadOf, o config.yml do gh com http_unix_socket) e as
  # variáveis de proxy e de CA desviam o que o git e o gh leem
  tm "N2: HTTPS_PROXY no deploy delegado → recusa" 2 "HTTPS_PROXY" env HTTPS_PROXY=http://127.0.0.1:9 bash "$ds" deploy --verified-pr 3
  tm "N2: SSL_CERT_FILE no deploy delegado → recusa" 2 "SSL_CERT_FILE" env SSL_CERT_FILE=/tmp/ca.pem bash "$ds" deploy --verified-pr 3
  local home_pw; home_pw="$(getent passwd "$(id -un)" | cut -d: -f6)"
  mkdir -p "$sb/fakehome"
  tm "N2: HOME falso vira o HOME do passwd no deploy delegado (e o config do gh dentro dele)" 0 "${home_pw}|${home_pw}/.config/gh" \
    env -i HOME="$sb/fakehome" PATH="$PATH" bash -c "source <(sed -n '/^delegated_env_guard() {/,/^}/p' '$ds'); die() { echo \"\$*\"; exit 2; }; delegated_env_guard; echo \"\$HOME|\$GH_CONFIG_DIR\""
  # MUTANTE dos N2: a guarda sem o HOME fixo e sem a recusa de proxy/CA deixa os dois passarem
  sed -e 's/^      \*_PROXY|\*_proxy) bad+=" \$v" ;;$/      __nunca__) ;;/' -e 's/^  HOME="\$h"; GH_CONFIG_DIR=.*$/  :/' \
      -e 's/|GIT_SSL_\*|XDG_CONFIG_HOME|XDG_CONFIG_DIRS|SSL_CERT_\*|CURL_CA_BUNDLE|REQUESTS_CA_BUNDLE|NODE_EXTRA_CA_CERTS)/|XDG_CONFIG_HOME)/' "$ds" > "$sb/ds-mut.sh"
  local mo; mo="$(env HTTPS_PROXY=http://127.0.0.1:9 SSL_CERT_FILE=/tmp/ca.pem env -i HOME="$sb/fakehome" PATH="$PATH" HTTPS_PROXY=x SSL_CERT_FILE=y bash -c "source <(sed -n '/^delegated_env_guard() {/,/^}/p' '$sb/ds-mut.sh'); die() { echo \"MORREU \$*\"; exit 2; }; delegated_env_guard; echo \"HOME=\$HOME\"" 2>&1)"
  if ! cmp -s "$ds" "$sb/ds-mut.sh" && grep -qF "HOME=$sb/fakehome" <<< "$mo" && ! grep -q MORREU <<< "$mo"; then
    pass=$((pass+1)); echo "  ✓ N2 (MUT): sem o HOME fixo e a recusa de proxy/CA, o HOME falso e o proxy passam — a cura é a causa"
  else fail=$((fail+1)); echo "  ✗ N2 (MUT): o mutante não mudou nada (âncora sumiu?) ou também recusou: $mo"; fi
  tm "B4: um gh falso no PATH não é o gh do deploy delegado (PATH fixo)" 0 "/usr/" \
    env -i HOME="$HOME" PATH="$sb/fakegh:$PATH" bash -c "source <(sed -n '/^delegated_env_guard() {/,/^}/p' '$ds'); die() { echo \"\$*\"; exit 2; }; delegated_env_guard; echo \"\${GH_CMD[0]}\"; [[ \"\${GH_CMD[0]}\" != '$sb/fakegh/gh' ]]"

  echo "── selftest: ${pass} pass / ${fail} fail ──"
  [[ "$fail" -eq 0 ]]
}

# ── A LINHA DE COMANDO (refutador do #1647, 2026-11-13) ─────────────────────────────────────────────────────────────
# Formas aceitas, e só elas: (nada) | deploy | --check | --selftest | --help | deploy --verified-pr <N> (o delegado, em
# posição exata) | deploy --maestro | --maestro. O 1º argumento VAZIO não vira deploy (`${1:-deploy}` o tratava como
# ausente, e `"" --verified-pr 3` passava pelo hook como outra coisa); `--verified-pr=<N>` saiu (a forma é uma só).
if [[ $# -ge 1 && -z "$1" ]]; then die "1º argumento vazio: modo desconhecido (use --help)"; fi
MODE="${1:-deploy}"
MAESTRO=0
if [[ "$MODE" == --maestro ]]; then
  [[ $# -eq 1 ]] || die "uso: ops/deploy-site.sh [deploy] --maestro"
  MODE=deploy; MAESTRO=1
elif [[ "$MODE" == deploy && $# -gt 1 ]]; then
  case "$2" in
    --verified-pr) [[ $# -eq 3 ]] || die "uso: ops/deploy-site.sh deploy --verified-pr <N>"; VERIFIED_PR="$3"; MODE=delegated ;;
    --maestro) [[ $# -eq 2 ]] || die "uso: ops/deploy-site.sh deploy --maestro"; MAESTRO=1 ;;
    *) die "argumento desconhecido depois de 'deploy': '$2' (use --help)" ;;
  esac
elif [[ $# -gt 1 ]]; then
  die "argumento a mais depois de '$MODE': '$2' (use --help)"
fi
# O DEPLOY DO MAESTRO recusa quando é a sessão que o chama: o hook lê a linha, e `bash ops/deploy-site.sh <<< --verified-pr`
# chega aqui sem argumento nenhum. Sessão = um processo do Claude Code entre os ancestrais (medido em /proc, não no
# ambiente). O maestro roda do terminal dele, ou pelo `!` com --maestro (palavra da assinatura do ato: a sessão é vetada).
_claude_ancestor() {
  local pid="$PPID" exe n=0
  while [[ -n "$pid" && "$pid" -gt 1 && "$n" -lt 64 ]]; do
    exe="$(readlink "/proc/${pid}/exe" 2>/dev/null)"
    case "$exe" in */claude/versions/*|*/bin/claude) return 0 ;; esac
    pid="$(awk '/^PPid:/{print $2}' "/proc/${pid}/status" 2>/dev/null)"; n=$((n+1))
  done
  return 1
}
if [[ "$MODE" == deploy && "$MAESTRO" -eq 0 ]] && _claude_ancestor; then
  die "o deploy do maestro chamado pela sessão do Claude Code: a sessão só deploya por 'deploy --verified-pr <N>' (D_DELEGATE_SITE_DEPLOY_AFTER_VERIFIED_MERGE_1113). O maestro: terminal dele, ou '! bash ops/deploy-site.sh deploy --maestro'."
fi
# B4: no deploy delegado o AMBIENTE não forja as condições (um gh falso no PATH mentiria CI e PR; GIT_CONFIG_* troca o
# origin). PATH fixo, gh absoluto, e recusa das variáveis que mudam o que o git e o gh leem.
delegated_env_guard() {
  local v bad=""
  for v in $(compgen -e); do
    case "$v" in
      GIT_CONFIG*|GIT_DIR|GIT_WORK_TREE|GIT_COMMON_DIR|GIT_EXEC_PATH|GIT_SSH|GIT_SSH_COMMAND|GIT_OBJECT_DIRECTORY|GIT_ALTERNATE_OBJECT_DIRECTORIES|GIT_INDEX_FILE|GIT_NAMESPACE|GIT_PROXY_COMMAND|GIT_CEILING_DIRECTORIES|GIT_SSL_*|XDG_CONFIG_HOME|XDG_CONFIG_DIRS|SSL_CERT_*|CURL_CA_BUNDLE|REQUESTS_CA_BUNDLE|NODE_EXTRA_CA_CERTS) bad+=" $v" ;;
      *_PROXY|*_proxy) bad+=" $v" ;;
      GH_TOKEN) ;;
      GH_*) bad+=" $v" ;;
    esac
  done
  [[ -z "$bad" ]] || die "o deploy delegado recusa estas variáveis de ambiente, que mudam o que o git e o gh leem:${bad}"
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; export PATH; hash -r
  # N2 da re-refutação do #1647: o HOME decide o ~/.gitconfig (insteadOf troca o origin) e o config.yml do gh
  # (http_unix_socket desvia o HTTP). HOME fixo pelo passwd, e o config do gh dentro dele
  local h; h="$(getent passwd "$(id -un)" | cut -d: -f6)"
  [[ -n "$h" && -d "$h" ]] || die "não li o HOME de $(id -un) no passwd"
  HOME="$h"; GH_CONFIG_DIR="$h/.config/gh"; export HOME GH_CONFIG_DIR
  GH_CMD=("$(command -v gh)"); [[ -x "${GH_CMD[0]}" ]] || die "gh ausente no PATH do sistema"
}
[[ "$MODE" == delegated ]] && delegated_env_guard
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
  delegated) delegated_deploy ;;
  *) die "modo desconhecido: $MODE (use --help)" ;;
esac
