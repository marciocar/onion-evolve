#!/usr/bin/env bash
# door-published-stamp.sh — a LEITURA ÚNICA do carimbo PUBLICADO de uma porta, no REMOTO.
#
# Biblioteca para `source`, sem efeito ao ser carregada. Dois consumidores:
#   · ops/publish-door.sh --status   (a tabela de defasagem das portas)
#   · ops/door-seal-pin.sh           (o cache `onion_version` do members.yaml)
#
# ══ POR QUE É UMA LIB (defeito medido em 2026-10-14, PR #1100) ════════════════════════════════
# O `door-seal-pin.sh` lia o carimbo do CLONE LOCAL da porta, e o `--status` lia do REMOTO. Duas
# leituras do mesmo fato, e a do clone apodreceu sozinha: desde a F3 o motor publica a partir de um
# clone DESCARTÁVEL e não toca os clones locais (publish-doctrine, "O que esta doutrina NÃO promete").
# Medido nas 4 portas em `--dry-run`: o onion-mini tinha arquivo não commitado, o standalone e o core
# estavam atrás do remoto e o plugins não tinha carimbo nenhum no clone. O `--status` dizia "em dia" e
# o carimbador recusava as quatro, e o cache acabou carimbado à mão com o pin que o `--status` leu.
# Uma leitura, um lugar: as duas pontas passam a perguntar aqui.
#
# ══ COMO LÊ ═══════════════════════════════════════════════════════════════════════════════════
# Git puro, sem `gh` e sem credencial (as portas são públicas, e um bare local serve na bancada):
# `git ls-remote --symref <url> HEAD` dá o ramo padrão; um clone raso sem checkout dá o objeto; o
# carimbo vem de `git show HEAD:.claude/.onion-version` (dialeto novo `source_commit`, legado
# `onion_version`) ou, na porta de marketplace, do `ref` do `provenance.json` do plugin.
# `GIT_TERMINAL_PROMPT=0`: url https inexistente ou privada faz o git PEDIR credencial; numa sessão de
# agente sem TTY isso trava em vez de falhar. Aqui falha, e vira `unreadable`.

# url clonável a partir do `remote:` do registro. github.com/x/y → https; caminho absoluto ou url
# completa ficam como estão; `n/a` e texto livre não têm url.
_url_of() {
  local r="$1"
  case "${r}" in
    ""|n/a|"("*) printf '' ;;
    http://*|https://*|git@*|file://*|/*) printf '%s' "${r}" ;;
    github.com/*) printf 'https://%s.git' "${r%.git}" ;;
    *) printf '' ;;
  esac
}

# Lê um campo do carimbo de porta (`write-stamp.sh --kind door`), com o dialeto antigo como fallback.
_stamp_field() { printf '%s\n' "$1" | grep -m1 "^$2:" | sed "s/^$2:[[:space:]]*//; s/[[:space:]]*#.*\$//; s/[[:space:]]*\$//"; }
_stamp_pin() {
  local p; p="$(_stamp_field "$1" source_commit)"
  [ -n "${p}" ] || p="$(_stamp_field "$1" onion_version)"
  printf '%s' "${p}"
}

# door_read_published <url> <dir-de-trabalho-descartável>
# Preenche DPS_STATE · DPS_BRANCH · DPS_PIN · DPS_ROLE · DPS_RELEASE. DPS_STATE é um de:
#   ok            carimbo lido (DPS_PIN não vazio; DPS_ROLE = `plugins*` na porta de marketplace)
#   no-url        o registro não dá url clonável
#   unreadable    `ls-remote` falhou ou não devolveu ramo padrão
#   clone-failed  o clone raso falhou
#   no-stamp      o remoto foi lido e NÃO traz carimbo (porta nunca materializada pelo motor)
# rc: 0 em `ok`, 1 em `no-stamp`, 2 nos demais (não pude medir). Quem chama decide o que cada um vale;
# nenhum deles vira "em dia" aqui dentro.
door_read_published() {
  local url="$1" work="$2" prov
  DPS_STATE=""; DPS_BRANCH=""; DPS_PIN=""; DPS_ROLE=""; DPS_RELEASE=""
  [ -n "${url}" ] || { DPS_STATE="no-url"; return 2; }
  if ! DPS_BRANCH="$(GIT_TERMINAL_PROMPT=0 git ls-remote --symref "${url}" HEAD 2>/dev/null | awk '/^ref:/{sub("refs/heads/","",$2); print $2; exit}')" \
     || [ -z "${DPS_BRANCH}" ]; then
    DPS_BRANCH=""; DPS_STATE="unreadable"; return 2
  fi
  # `work` tem de ser filho de um diretório que EXISTE: com `mktemp -d` falho no chamador ele viraria
  # `/<id>` e o `rm -rf` mirava a raiz (passada adversarial, 2026-10-14)
  [ -d "$(dirname "${work}")" ] || { DPS_STATE="clone-failed"; return 2; }
  rm -rf "${work:?}"
  if ! GIT_TERMINAL_PROMPT=0 git clone -q --depth 1 --no-checkout --branch "${DPS_BRANCH}" "${url}" "${work}" >/dev/null 2>&1; then
    DPS_STATE="clone-failed"; return 2
  fi
  local stamp; stamp="$(git -C "${work}" show "HEAD:.claude/.onion-version" 2>/dev/null || true)"
  if [ -n "${stamp}" ]; then
    DPS_PIN="$(_stamp_pin "${stamp}")"; DPS_ROLE="$(_stamp_field "${stamp}" role)"
    DPS_RELEASE="$(_stamp_field "${stamp}" release)"
  else
    # porta de MARKETPLACE: o carimbo é o provenance.json do plugin (campo `ref`), sem `role:`
    prov="$(git -C "${work}" ls-tree -r --name-only HEAD -- plugins 2>/dev/null | grep -m1 '/\.claude-plugin/provenance\.json$' || true)"
    if [ -n "${prov}" ]; then
      DPS_PIN="$(git -C "${work}" show "HEAD:${prov}" 2>/dev/null | sed -n 's/.*"ref"[[:space:]]*:[[:space:]]*"\([0-9a-f]*\)".*/\1/p' | head -1)"
      DPS_ROLE="plugins*"
      DPS_RELEASE="$(git -C "${work}" show "HEAD:${prov}" 2>/dev/null | sed -n 's/.*"onion_release"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | sed -n '1p')"
    fi
  fi
  if [ -z "${DPS_PIN}" ]; then DPS_STATE="no-stamp"; return 1; fi
  DPS_STATE="ok"; return 0
}
