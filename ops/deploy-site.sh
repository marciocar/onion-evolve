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
#  2. `--check` compara fonte×vivo por hash e sai ≠0 em drift — read-only de verdade,
#     chamável pela bancada sem efeito colateral.
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
#   ops/deploy-site.sh --check     # só verifica drift (exit 1 se houver)
#   ops/deploy-site.sh --selftest  # bancada em sandbox (nunca toca fonte/webroot reais)
#
# Fonte: SRC_ROOT abaixo. Quando a fundação Astro entrar (F1 da reforma 2026-08), a
# fonte passa a ser o output do build (site/dist) — trocar SÓ esta variável (a guarda 5
# é o que torna essa troca segura).
set -euo pipefail
set -f  # a allowlist é fronteira de segurança: nada de pathname expansion contra o CWD
export LC_ALL=C

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="${REPO}/site"
WEBROOT="/var/www/onion-landing"
SUDO_CMD="sudo"

# Allowlist: TUDO que o deploy gerencia. Entrada nova no site = linha nova aqui
# (é o ponto único de decisão do-que-se-publica, como o manifesto dos plugins).
DEPLOY_ENTRIES=(
  index.html
  fonts
  images
  historia
  convite
  federacao
)

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
  echo "── ${verified}/${total} entradas verificadas ──"
  return "$drift"
}

deploy() {
  local entry h_src
  # Pré-voo: TODAS as entradas validadas ANTES de tocar o vivo (deploy meio-aplicado
  # com mensagem críptica foi achado R4/R11 da revisão).
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
  SRC_ROOT="$sb/src"; WEBROOT="$sb/web"; SUDO_CMD=""
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

  echo "── selftest: ${pass} pass / ${fail} fail ──"
  [[ "$fail" -eq 0 ]]
}

MODE="${1:-deploy}"
case "$MODE" in
  --help|-h) usage; exit 0 ;;
  --selftest) selftest ;;
  --check)
    [[ -d "$SRC_ROOT" ]] || die "fonte ausente: $SRC_ROOT"
    [[ -d "$WEBROOT" ]] || die "webroot ausente: $WEBROOT (este script roda NA KVM 8)"
    check ;;
  deploy)
    [[ -d "$SRC_ROOT" ]] || die "fonte ausente: $SRC_ROOT"
    [[ -d "$WEBROOT" ]] || die "webroot ausente: $WEBROOT (este script roda NA KVM 8)"
    deploy ;;
  *) die "modo desconhecido: $MODE (use --help)" ;;
esac
