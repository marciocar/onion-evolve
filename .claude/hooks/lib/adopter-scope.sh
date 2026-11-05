#!/usr/bin/env bash
# lib do MODO DE ADOTANTE dos vetos (2026-11-05, REGRA 118) — sourced por pretooluse-merge-gate.sh e
# pretooluse-adopter-guard.sh; nunca executado só.
#
# ── POR QUE EXISTE (medido, não suposto) ──────────────────────────────────────────────────────────────
# Em 2026-11-05 a curadoria rodou 31 formas de ato com os 5 hooks e o cwd no repo dela, e 27 passaram. O
# merge-gate virava AVISO sem `ops/pr-merge-verified.sh` (core-only) no projeto, e o moat-gate saía cedo sem
# `ops/moat-targets.tsv` (core-only): `git push origin main`, `gh pr merge N` e `git -C <core> commit` passavam
# todos com exit 0. E a proteção de branch no host dá 403 nos repos dos adotantes (plano gratuito). Os
# adotantes desta máquina mergeiam pelo script do core chamado por CAMINHO ABSOLUTO (`bash
# /home/<u>/onion-evolve/ops/pr-merge-verified.sh N --repo <dono>/<repo>`, medido nos transcritos de
# curadoria e kg-ssot), e o kg-ssot digitou `gh pr merge` direto duas vezes em 2026-10-08.
#
# ── O QUE RESOLVE ─────────────────────────────────────────────────────────────────────────────────────
#  · o PAPEL do projeto pelo carimbo `.claude/.onion-version` (`role: adopted|hub|standalone`); sem carimbo,
#    ou com outro papel, não é adotante e nada aqui se arma;
#  · o CHECKOUT LOCAL DO CORE: a linha `core` do arquivo local, ou o `adopted_from:` do carimbo quando ele é um
#    diretório (a adoção por caminho local grava o caminho; a por URL grava a URL, e aí só o arquivo resolve);
#  · os REPOS REGISTRADOS: o core, os `local_path` do `docs/evolution/federation/members.yaml` (core-only) dele, e as
#    linhas `repo` do arquivo local. As linhas `allow` isentam um caminho (o hub que adota para baixo).
#
# ── O ARQUIVO LOCAL DO ADOTANTE: .claude/adopter-guard.tsv ────────────────────────────────────────────
#   # comentário
#   core	/home/<u>/onion-evolve        ← o checkout local do core (lê o members.yaml e acha o merge verificado)
#   repo	/home/<u>/outro-repo          ← repo alheio a mais, além dos do members.yaml
#   allow	/home/<u>/filho-do-hub        ← caminho que a sessão PODE escrever, mesmo registrado
# Uma diretiva por linha, separada por TAB ou espaço; caminho ABSOLUTO (ou `~/…`), sem espaço no nome. Linha
# fora disto é ignorada aqui e acusada pela REGRA 118 (adopter-veto-check.sh). O arquivo é do adotante: o
# /meta:adopt não o traz nem o apaga.
#
# TETO: só lê o members.yaml do core NESTA máquina, pelo caminho; clone que nenhuma das três fontes nomeia não
# é registrado (o veto de repo alheio cala para ele). Caminho com espaço não se declara.

ONION_ADOPTER_TSV_REL=".claude/adopter-guard.tsv"

# onion_adopter_role <raiz> — imprime o papel de adoção e sai 0; sai 1 fora de adopted|hub|standalone
onion_adopter_role() {
  local f="${1:-.}/.claude/.onion-version" r
  [ -f "$f" ] || return 1
  r="$(sed -nE 's/^role:[[:space:]]*([A-Za-z_-]+).*$/\1/p' "$f" 2>/dev/null | head -n 1)"
  case "$r" in adopted|hub|standalone) printf '%s\n' "$r" ;; *) return 1 ;; esac
}

# _onion_adopter_tsv <raiz> <diretiva> — os caminhos da diretiva no arquivo local, com `~/` expandido
_onion_adopter_tsv() {
  local t="${1:-.}/${ONION_ADOPTER_TSV_REL}"
  [ -f "$t" ] || return 0
  awk -v k="$2" '!/^[[:space:]]*#/ && $1 == k && NF >= 2 { print $2 }' "$t" 2>/dev/null \
    | while IFS= read -r p; do
        case "$p" in "~/"*) p="${HOME}/${p#"~/"}" ;; esac
        case "$p" in /*) printf '%s\n' "${p%/}" ;; esac
      done
}

# onion_adopter_core <raiz> — o checkout local do core (diretório existente); sai 1 quando não se resolve
onion_adopter_core() {
  local root="${1:-.}" c
  c="$(_onion_adopter_tsv "$root" core | head -n 1)"
  if [ -z "$c" ]; then
    c="$(sed -nE 's/^adopted_from:[[:space:]]*"?([^"[:space:]]+)"?.*$/\1/p' "${root}/.claude/.onion-version" 2>/dev/null | head -n 1)"
    case "$c" in "~/"*) c="${HOME}/${c#"~/"}" ;; /*) : ;; *) c="" ;; esac
  fi
  [ -n "$c" ] && [ -d "$c" ] || return 1
  printf '%s\n' "${c%/}"
}

# onion_adopter_repos <raiz> — um caminho registrado por linha (o core, os local_path do members.yaml dele, as
# linhas `repo`). Inclui o próprio projeto quando o registro o lista: quem julga exclui o próprio pelo
# git-common-dir, que também cobre as worktrees dele.
onion_adopter_repos() {
  local root="${1:-.}" core m
  core="$(onion_adopter_core "$root")" || core=""
  {
    [ -n "$core" ] && printf '%s\n' "$core"
    m="${core}/docs/evolution/federation/members.yaml"
    [ -n "$core" ] && [ -f "$m" ] && awk '
        /^[[:space:]]+local_path:/ { v = $0; sub(/^[[:space:]]+local_path:[[:space:]]*"?/, "", v); sub(/["#[:space:]].*$/, "", v); if (v ~ /^\//) print v }' "$m"
    _onion_adopter_tsv "$root" repo
  } | sed 's#/*$##' | awk 'NF && !seen[$0]++'
}

# onion_adopter_allows <raiz> — os caminhos `allow` do arquivo local
onion_adopter_allows() { _onion_adopter_tsv "${1:-.}" allow | awk 'NF && !seen[$0]++'; }
