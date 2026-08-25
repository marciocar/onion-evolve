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
# GUARDAS POR CONSTRUÇÃO (não por disciplina):
#  1. ALLOWLIST de entradas — o script só toca o que está em DEPLOY_ENTRIES. `mini/` e
#     `pulse-mais/` têm fonte em OUTROS repos: jamais entram aqui, e nenhuma flag os
#     alcança. Um `--delete` na raiz do webroot os apagaria — por isso não existe modo
#     "raiz inteira".
#  2. `--check` compara fonte×vivo por hash e sai ≠0 em drift — é o mesmo contrato do
#     `migalhas-generate.sh --check`: a bancada/CI pode chamar sem efeito colateral.
#  3. Derivação não guarda backup: o webroot é projeção de fonte versionada; backup é o
#     git. `*.bak*` no webroot é lixo servido publicamente (14 encontrados em 2026-08-25)
#     e o `--check` os acusa.
#
# Uso:
#   ops/deploy-site.sh            # deploya a allowlist (local, na KVM 8)
#   ops/deploy-site.sh --check    # só verifica drift (exit 1 se houver)
#
# Fonte: SRC_ROOT abaixo. Quando a fundação Astro entrar (F1 da reforma 2026-08), a
# fonte passa a ser o output do build (site/dist) — trocar SÓ esta variável.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="${REPO}/site"
WEBROOT="/var/www/onion-landing"

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

MODE="${1:-deploy}"

die() { echo "ERRO: $*" >&2; exit 2; }

[[ -d "$SRC_ROOT" ]] || die "fonte ausente: $SRC_ROOT"
[[ -d "$WEBROOT" ]] || die "webroot ausente: $WEBROOT (este script roda NA KVM 8)"

# Hash recursivo de uma entrada (arquivo ou dir), estável por conteúdo+caminho relativo.
hash_entry() {
  local root="$1" entry="$2"
  if [[ -f "$root/$entry" ]]; then
    sha256sum "$root/$entry" | awk '{print $1}'
  elif [[ -d "$root/$entry" ]]; then
    (cd "$root" && find "$entry" -type f -print0 | sort -z \
      | xargs -0 sha256sum | sha256sum | awk '{print $1}')
  else
    echo "ABSENT"
  fi
}

check() {
  local drift=0
  for entry in "${DEPLOY_ENTRIES[@]}"; do
    local h_src h_web
    h_src="$(hash_entry "$SRC_ROOT" "$entry")"
    h_web="$(hash_entry "$WEBROOT" "$entry")"
    if [[ "$h_src" == "ABSENT" ]]; then
      echo "⚠ fonte sem a entrada '$entry' (webroot: $h_web)" >&2; drift=1
    elif [[ "$h_src" != "$h_web" ]]; then
      echo "✗ DRIFT: $entry (fonte ${h_src:0:12} ≠ vivo ${h_web:0:12})" >&2; drift=1
    else
      echo "✓ $entry"
    fi
  done
  # Lixo de backup na derivação: acusa, não tolera (guarda 3 do cabeçalho).
  local baks
  baks="$(find "$WEBROOT" -name '*.bak*' -not -path "$WEBROOT/mini/*" -not -path "$WEBROOT/pulse-mais/*")"
  if [[ -n "$baks" ]]; then
    echo "✗ backup servido publicamente na derivação:" >&2
    echo "$baks" >&2
    drift=1
  fi
  return "$drift"
}

deploy() {
  for entry in "${DEPLOY_ENTRIES[@]}"; do
    [[ -e "$SRC_ROOT/$entry" ]] || die "allowlist cita '$entry' mas a fonte não o tem"
    if [[ -d "$SRC_ROOT/$entry" ]]; then
      # --delete é seguro AQUI: escopado à entrada da allowlist, nunca à raiz.
      sudo rsync -a --delete "$SRC_ROOT/$entry/" "$WEBROOT/$entry/"
    else
      sudo rsync -a "$SRC_ROOT/$entry" "$WEBROOT/$entry"
    fi
  done
  # Remove lixo de backup da derivação (fora de mini/ e pulse-mais/, que não são nossos).
  sudo find "$WEBROOT" -name '*.bak*' -not -path "$WEBROOT/mini/*" -not -path "$WEBROOT/pulse-mais/*" -delete
  # Dono uniforme: a derivação é operada por marcio (federacao/ nasceu root em jul/26).
  for entry in "${DEPLOY_ENTRIES[@]}"; do
    sudo chown -R marcio:marcio "$WEBROOT/$entry"
  done
  echo "── deploy aplicado; verificando ──"
  check
}

case "$MODE" in
  --check) check ;;
  deploy)  deploy ;;
  *) die "modo desconhecido: $MODE (use sem argumento para deploy, ou --check)" ;;
esac
