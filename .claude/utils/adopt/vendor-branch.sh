#!/usr/bin/env bash
# =============================================================================
# vendor-branch.sh — /meta:adopt --update via MERGE de vendor-branch (never-clobber ESTRUTURAL).
#
# Achado #2 do /meta:evolve (docs/analysis/onion-adr-adopt-vendor-branch-merge-2026-07.md).
# Migra o apply de copy-over (cp -R + diff a revisar, clobável) para um 3-way merge git: a customização
# local do adotante vira CONFLITO git de verdade (resolvível), não some silenciosamente.
#
# Topologia (verificada por experimento 2026-07-09): onion/vendor é RAMIFICADA da integração (base comum),
# NÃO órfã — órfã sem base comum dá conflito add/add em TODO arquivo. Ramificada → conflito só onde há
# customização real; os demais atualizam limpo; produto (snapshot intocado no vendor) merge limpo.
#
# Uso:
#   vendor-branch.sh seed   <TARGET> <INTEGRATION_BRANCH>
#       Ramifica onion/vendor do HEAD da integração (framework LIMPO recém-instalado). Idempotente.
#   vendor-branch.sh update <TARGET> <SOURCE_ROOT> <PIN> <INTEGRATION_BRANCH>
#       Aplica o framework NOVO do core no onion/vendor (worktree) + durable-commit, depois mergeia na
#       integração. Bootstrapa o vendor se ausente (legado). Exit: 0 merge limpo · 10 CONFLITO (humano
#       resolve) · 2 erro de precondição.
#
# Reusa: durable-commit.sh (commit no vendor) · o manifest L1+L2 (mesma superfície do adopt).
# Determinístico, sem jq. Exercitado por lint-selftest.sh (run_vendor_branch_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR="onion/vendor"

# Superfície L1+L2 (mesma do adopt.md; filtrada pelo que existe no core em HEAD).
_manifest() {  # $1=SOURCE_ROOT → imprime pathspecs existentes, um por linha
  local want=(.claude/agents .claude/commands .claude/skills .claude/utils .claude/validation .claude/hooks \
              docs/meta-specs docs/knowledge-base docs/sdaal) p
  for p in "${want[@]}"; do git -C "$1" ls-tree HEAD -- "$p" | grep -q . && printf '%s\n' "$p"; done
}

_seed() {  # <TARGET> <INTEGRATION_BRANCH>
  local T="$1" IB="$2"
  git -C "$T" rev-parse --git-dir >/dev/null 2>&1 || { echo "⚠️  $T não é repo git — seed pulado." >&2; return 0; }
  if git -C "$T" rev-parse --verify "$VENDOR" >/dev/null 2>&1; then
    echo "Onion: $VENDOR já existe — seed pulado (idempotente)."; return 0
  fi
  git -C "$T" rev-parse --verify "$IB" >/dev/null 2>&1 || { echo "ERRO: integration branch '$IB' inexistente." >&2; return 2; }
  git -C "$T" branch "$VENDOR" "$IB" \
    && echo "Onion: $VENDOR ramificada de '$IB' (fonte-de-merge; base comum p/ o 3-way)." \
    || { echo "ERRO: falhou ao ramificar $VENDOR." >&2; return 2; }
}

# Acha o commit MAIS RECENTE da integração cujo framework é IDÊNTICO ao core@<pin> (blob-set via ls-tree,
# content-addressed → cross-repo confiável). É o baseline LIMPO p/ ramificar o onion/vendor num legado:
# ramificar do HEAD entraria com a customização já commitada NA BASE → o merge tomaria theirs = clobber
# silencioso (spec §8 / experimento 2026-07-09). Vazio = não achou (framework/customização entrelaçados).
_clean_baseline() {  # <SRC> <T> <PIN> <IB>
  local SRC="$1" T="$2" PIN="$3" IB="$4" fw ref c cur
  [ -n "$PIN" ] || return 0
  git -C "$SRC" rev-parse --verify "${PIN}^{commit}" >/dev/null 2>&1 || return 0
  fw="$(_manifest "$SRC")"; [ -n "$fw" ] || return 0
  # shellcheck disable=SC2086
  ref="$(git -C "$SRC" ls-tree -r "$PIN" -- $fw 2>/dev/null | awk '{print $3" "$4}' | LC_ALL=C sort)"
  [ -n "$ref" ] || return 0
  # shellcheck disable=SC2086
  for c in $(git -C "$T" rev-list "$IB" -- $fw 2>/dev/null); do
    # shellcheck disable=SC2086
    cur="$(git -C "$T" ls-tree -r "$c" -- $fw 2>/dev/null | awk '{print $3" "$4}' | LC_ALL=C sort)"
    [ "$cur" = "$ref" ] && { printf '%s\n' "$c"; return 0; }
  done
  return 0
}

_update() {  # <TARGET> <SOURCE_ROOT> <PIN> <INTEGRATION_BRANCH>
  local T="$1" SRC="$2" PIN="$3" IB="$4"
  git -C "$T" rev-parse --git-dir >/dev/null 2>&1 || { echo "⚠️  $T não é repo git — update pulado." >&2; return 0; }
  git -C "$SRC" rev-parse --git-dir >/dev/null 2>&1 || { echo "ERRO: SOURCE_ROOT '$SRC' não é repo git." >&2; return 2; }

  # ── O PIN ENTRA PROVANDO QUE É COMMIT ──────────────────────────────────────
  # Este script gravava no histórico do adotante QUALQUER string recebida como
  # pin ("update to pin ${PIN}"). Achado de campo 2026-07-21, medindo os 3
  # adotantes locais: DOIS tinham lixo carimbado —
  #     · um adotante de campo : "vnextpin"     (placeholder digitado)
  #     · outro adotante: "2026-07-12" (uma DATA no lugar do commit)
  # O dano não aparece no dia: aparece semanas depois, quando o 3-way merge usa
  # o commit errado como base e transforma ANCESTRALIDADE em conflito. Foi
  # exatamente o que aconteceu no update de um adotante de campo (17 arquivos em
  # conflito, todos byte-idênticos ao core — conflito contábil, não de conteúdo).
  # É o mecanismo concreto do "drift silencioso de pin" que o grafo já registrava
  # em abstrato (REC_PIN_DRIFT_REAL_HEALTH_METRIC).
  # Regra: o pin tem de EXISTIR como commit na história da FONTE. Sem isso não
  # há como reconstruir a base, e escrever o registro seria registrar mentira.
  if [ -z "${PIN}" ]; then
    echo "ERRO: pin vazio — o registro do vendor não pode ser gravado sem pin." >&2; return 2
  fi
  if ! git -C "$SRC" cat-file -e "${PIN}^{commit}" 2>/dev/null; then
    echo "ERRO: pin '${PIN}' não é um commit da fonte ($SRC)." >&2
    echo "      O vendor grava esse valor no histórico do adotante; um pin inválido" >&2
    echo "      quebra a base do 3-way merge e vira conflito falso semanas depois." >&2
    echo "      Passe o commit real: git -C \"$SRC\" rev-parse --short=12 HEAD" >&2
    return 2
  fi

  # Bootstrap de legado (sem vendor): ramifica do commit LIMPO (framework == core@pin-ADOTADO), não do HEAD
  # (que pode ter customização commitada → clobber no 1º merge — spec §8). Fresh-adoption já tem vendor.
  if ! git -C "$T" rev-parse --verify "$VENDOR" >/dev/null 2>&1; then
    local ADOPTED base
    ADOPTED="$(awk '/^source_commit:/{print $2}' "$T/.claude/.onion-version" 2>/dev/null)"
    base="$(_clean_baseline "$SRC" "$T" "$ADOPTED" "$IB")"
    if [ -n "$base" ]; then
      git -C "$T" branch "$VENDOR" "$base" && echo "Onion: $VENDOR ramificada do baseline LIMPO ${base:0:12} (framework == pin ${ADOPTED}) — 3-way seguro."
    else
      echo "⚠️  Onion: sem commit de framework limpo == pin '${ADOPTED}' na história de '$IB' (legado entrelaçado)." >&2
      echo "    O 1º merge pode NÃO conflitar (risco de clobrar customização). Ramifico do HEAD; revise o merge." >&2
      _seed "$T" "$IB" || return $?
    fi
  fi

  # Working tree da integração precisa estar limpa p/ o merge (não força — never-clobber).
  git -C "$T" checkout -q "$IB" 2>/dev/null || { echo "ERRO: não consegui checar '$IB' em $T." >&2; return 2; }
  if ! git -C "$T" diff --quiet 2>/dev/null || ! git -C "$T" diff --cached --quiet 2>/dev/null; then
    echo "ERRO: working tree de $T ($IB) suja — commite/stash antes do --update (o merge exige árvore limpa)." >&2
    return 2
  fi

  # Aplica o framework NOVO no onion/vendor, num worktree (não sai da integração).
  local wt; wt="$(mktemp -d)/onion-vendor-wt"
  git -C "$T" worktree add -q "$wt" "$VENDOR" 2>/dev/null || { echo "ERRO: worktree do $VENDOR falhou." >&2; return 2; }
  local mf; mf="$(_manifest "$SRC")"
  [ -n "$mf" ] || { echo "ERRO: manifest vazio (core sem framework?)." >&2; git -C "$T" worktree remove --force "$wt" 2>/dev/null; return 2; }
  # shellcheck disable=SC2046
  ( cd "$SRC" && git archive HEAD -- $(printf '%s ' $mf) ) | tar -x -C "$wt" 2>/dev/null
  bash "$HERE/durable-commit.sh" "$wt" update "$PIN" "$VENDOR" >/dev/null 2>&1
  git -C "$T" worktree remove --force "$wt" 2>/dev/null

  # Merge do onion/vendor na integração (3-way; base comum). Conflito = never-clobber estrutural.
  if git -C "$T" merge "$VENDOR" -m "chore(onion): update to pin ${PIN}" >/dev/null 2>&1; then
    echo "Onion: framework atualizado via merge limpo de $VENDOR (pin ${PIN})."
    return 0
  fi
  # Merge deixou conflito (ou nada a fazer). Distinga:
  if git -C "$T" diff --name-only --diff-filter=U 2>/dev/null | grep -q .; then
    echo "Onion: CONFLITO no merge de $VENDOR — customização local vs framework novo (never-clobber estrutural)." >&2
    echo "  Resolva em $T: 'git mergetool' ou edite os marcadores; depois 'git commit'. Arquivos:" >&2
    git -C "$T" diff --name-only --diff-filter=U 2>/dev/null | sed 's/^/    /' >&2
    return 10
  fi
  # Sem conflito e merge não-zero → provavelmente nada a mergear (já atualizado).
  git -C "$T" merge --abort 2>/dev/null || true
  echo "Onion: nada a mergear (integração já em pin ${PIN})."
  return 0
}

case "${1:-}" in
  seed)   shift; [ "$#" -ge 2 ] || { echo "uso: vendor-branch.sh seed <TARGET> <INTEGRATION_BRANCH>" >&2; exit 2; }; _seed "$@" ;;
  update) shift; [ "$#" -ge 4 ] || { echo "uso: vendor-branch.sh update <TARGET> <SOURCE_ROOT> <PIN> <INTEGRATION_BRANCH>" >&2; exit 2; }; _update "$@" ;;
  *) echo "uso: vendor-branch.sh {seed|update} ..." >&2; exit 2 ;;
esac
