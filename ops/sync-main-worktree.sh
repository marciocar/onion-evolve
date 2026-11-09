#!/usr/bin/env bash
# =============================================================================
# sync-main-worktree.sh — traz para o origin/main a worktree que tem `main` em uso (fast-forward, nunca mais)
#
# POR QUÊ (SAC-143, 2026-10-15): o harness lê `.claude/settings.json` e os hooks de $CLAUDE_PROJECT_DIR, que é o
#   checkout principal, em `main`. Os merges saem de worktrees pelo ops/merge-serial.sh, e nada trazia esse checkout
#   junto: medido em 2026-10-15, ele estava 36 commits atrás, e o hook Stop aposentado no #1129 ainda disparou na
#   sessão ~1h20 depois do merge, enquanto a sonda nova não valia. O `--sync` do pr-merge-verified não resolvia:
#   ele faz `checkout main` na worktree ATUAL, que falha justamente quando `main` está tomada pelo checkout principal.
#
# O QUE FAZ: acha pela `git worktree list --porcelain` a worktree com `branch refs/heads/main` e roda nela
#   `git fetch origin main` + `git merge --ff-only origin/main`. Nunca faz checkout, reset, stash nem merge de verdade.
#   Árvore suja: o ff-only recusa sozinho se um arquivo sujo for tocado, e o que não for tocado fica como estava.
#
# ÁRVORE SEM ESCRITA (SAC-372, 2026-11-09): sob o sandbox do Claude Code os arquivos do deny viram bind mount em
#   leitura. Medido pela curadoria e reproduzido em bwrap: o ff-only dá `unable to unlink old '…': Device or resource
#   busy`, escreve o resto (72 de 77 arquivos), deixa o HEAD onde estava e sai 1, e o ff-only seguinte recusa, porque
#   os arquivos já escritos parecem sujos. Por isso, ANTES de avançar, cada alvo passa por abertura real: o arquivo
#   é aberto em append sem escrever nada (não muda conteúdo nem mtime) e o diretório recebe e perde um arquivo de sonda
#   com ponto na frente. `[ -w ]` e access(2) mentem sob sandbox. Um alvo sem escrita pula o avanço inteiro, com aviso.
#   Limite conservador: arquivo 444 num diretório gravável o git trocaria, e aqui ele pula; o aviso nomeia o arquivo.
#   A falha no meio continua possível (o alvo perde a escrita entre a sonda e o merge, ou o bind é de escrita e só o
#   unlink falha), e aí o script mede o que ficou e diz. Ele não desfaz: quem decide é quem lê.
#   Só conta como parcial o arquivo que está na versão nova com o ÍNDICE ainda na antiga: é o rastro de um ff-only
#   que quebrou, que não grava o índice. Com index.lock presente ou HEAD que andou, o autor pode ser outro processo,
#   e o aviso diz concorrência, sem sugerir reset. O sync seguinte reconhece o mesmo rastro e diz que há parcial.
#
# CONTRATO: sempre exit 0 (é cortesia depois de um merge PROVADO; o rc de quem chama responde pelo merge).
#   Uma linha no stdout: "sync-main: <worktree> <antes>→<depois>" · "já em dia" · "sem worktree em main" · "⚠️ …".
# Bancada: run_sync_main_worktree_selftests.
# =============================================================================
set -uo pipefail

wt="$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{w=substr($0,10)} /^branch refs\/heads\/main$/{print w; exit}')"
if [ -z "${wt}" ]; then echo "sync-main: nenhuma worktree com main em uso — nada a sincronizar"; exit 0; fi
git -C "${wt}" fetch -q origin main 2>/dev/null || { echo "sync-main: ⚠️ fetch de origin/main falhou em ${wt} — não sincronizei"; exit 0; }
before="$(git -C "${wt}" rev-parse --short HEAD 2>/dev/null)"
behind="$(git -C "${wt}" rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
if [ "${behind}" = 0 ]; then echo "sync-main: ${wt} já em dia (${before})"; exit 0; fi
target="$(git -C "${wt}" rev-parse origin/main 2>/dev/null)"

declare -A dir_ok=() pre_dirty=()
blocked=() targets=()
while IFS= read -r -d '' dirty; do pre_dirty["${dirty}"]=1; done < <(git -C "${wt}" diff --name-only --no-renames -z HEAD 2>/dev/null)

can_create_in() {  # $1 = diretório existente → 0 se um arquivo nasce e morre nele de verdade (resultado guardado por diretório)
  local dir="$1" probe
  if [ -z "${dir_ok["${dir}"]+x}" ]; then
    if probe="$(mktemp "${dir}/.onion-sync-probe.XXXXXX" 2>/dev/null)"; then rm -f "${probe}"; dir_ok["${dir}"]=0; else dir_ok["${dir}"]=1; fi
  fi
  return "${dir_ok["${dir}"]}"
}

while IFS= read -r -d '' status && IFS= read -r -d '' rel; do
  targets+=("${rel}")
  abs="${wt}/${rel}"
  if [ "${status}" = A ] && { [ -e "${abs}" ] || [ -L "${abs}" ]; }; then pre_dirty["${rel}"]=1; fi
  if [ -f "${abs}" ] && [ ! -L "${abs}" ] && ! ( : >> "${abs}" ) 2>/dev/null; then blocked+=("${rel}"); continue; fi
  dir="${abs%/*}"
  while [ ! -d "${dir}" ]; do dir="${dir%/*}"; done
  can_create_in "${dir}" || blocked+=("${rel}")
done < <(git -C "${wt}" diff --name-status --no-renames -z HEAD "${target}" 2>/dev/null)

left_by_failed_ff() {  # $1 = caminho → 0 se a árvore tem a versão do alvo e o índice ainda não (arquivo ausente conta quando o alvo o apagou)
  local rel="$1" abs="${wt}/$1" want idx have
  want="$(git -C "${wt}" rev-parse -q --verify "${target}:${rel}" 2>/dev/null)"
  idx="$(git -C "${wt}" rev-parse -q --verify ":${rel}" 2>/dev/null)"
  [ "${idx}" != "${want}" ] || return 1
  if [ ! -e "${abs}" ] && [ ! -L "${abs}" ]; then [ -z "${want}" ]; return; fi
  [ -n "${want}" ] || return 1
  if [ -L "${abs}" ]; then have="$(printf '%s' "$(readlink "${abs}")" | git -C "${wt}" hash-object --stdin)"
  else have="$(git -C "${wt}" hash-object --path="${rel}" -- "${abs}" 2>/dev/null)"; fi
  [ "${have}" = "${want}" ]
}

someone_else_here() {  # 0 se outro processo pode estar mexendo: index.lock presente ou HEAD fora de onde o encontramos
  local lock; lock="$(git -C "${wt}" rev-parse --path-format=absolute --git-path index.lock 2>/dev/null)"
  [ -e "${lock}" ] || [ "$(git -C "${wt}" rev-parse --short HEAD 2>/dev/null)" != "${before}" ]
}
say_concurrent() { echo "sync-main: ⚠️ ${wt}: outro processo está nesta worktree (index.lock presente ou HEAD que andou), então não julgo a árvore. Rode de novo quando ele terminar: bash ops/sync-main-worktree.sh"; }

prior=0
for rel in "${targets[@]}"; do
  [ -n "${pre_dirty["${rel}"]+x}" ] || continue
  left_by_failed_ff "${rel}" && prior=$((prior + 1))
done
if [ "${prior}" -gt 0 ]; then
  if someone_else_here; then say_concurrent; exit 0; fi
  echo "sync-main: ⚠️ ÁRVORE PARCIAL DE ANTES em ${wt}: ${prior} de ${#targets[@]} arquivo(s) já estão na versão nova com o HEAD em ${before}, rastro de um avanço que quebrou, e o ff-only não retoma sozinho. Confira com git -C \"${wt}\" status e, sem mudança local a guardar, git -C \"${wt}\" reset --hard origin/main conclui."
  exit 0
fi

if [ "${#blocked[@]}" -gt 0 ]; then
  echo "sync-main: ⚠️ ${wt} ficou em ${before}, ${behind} commit(s) atrás, sem tocar na árvore — ${#blocked[@]} de ${#targets[@]} alvo(s) sem escrita a partir daqui (ex.: ${blocked[*]:0:3}). Sob sandbox é o esperado; rode fora dele: git -C \"${wt}\" merge --ff-only origin/main"
  exit 0
fi

if out="$(git -C "${wt}" merge --ff-only -q "${target}" 2>&1)"; then
  after="$(git -C "${wt}" rev-parse HEAD 2>/dev/null)"
  if [ "${after}" = "${target}" ]; then
    echo "sync-main: ${wt} ${before}→$(git -C "${wt}" rev-parse --short HEAD) (${behind} commit(s); hooks e settings mergeados passam a valer)"
  else
    echo "sync-main: ⚠️ ${wt}: o ff-only disse sucesso, mas o HEAD está em ${after:0:9}, e não no origin/main ${target:0:9} — confira com git -C \"${wt}\" status"
  fi
else
  moved=0
  for rel in "${targets[@]}"; do
    [ -z "${pre_dirty["${rel}"]+x}" ] || continue
    left_by_failed_ff "${rel}" && moved=$((moved + 1))
  done
  if someone_else_here; then
    say_concurrent
  elif [ "${moved}" -gt 0 ]; then
    echo "sync-main: ⚠️ ÁRVORE PARCIAL em ${wt}: o ff-only falhou no meio ($(head -1 <<< "${out}")); o HEAD segue em ${before} e ${moved} de ${#targets[@]} arquivo(s) já estão na versão nova. O ff-only não retoma sozinho: confira com git -C \"${wt}\" status e, sem mudança local a guardar, git -C \"${wt}\" reset --hard origin/main conclui."
  else
    echo "sync-main: ⚠️ ${wt} ficou em ${before}, ${behind} commit(s) atrás — o ff-only recusou: $(head -1 <<< "${out}")"
  fi
fi
exit 0
