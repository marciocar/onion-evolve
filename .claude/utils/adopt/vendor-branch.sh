#!/usr/bin/env bash
# =============================================================================
# vendor-branch.sh — /meta:adopt --update via MERGE de vendor-branch (never-clobber ESTRUTURAL).
#
# Achado #2 do /meta:evolve (../../../docs/knowledge-base/decisions/onion-adr-adopt-vendor-branch-merge-2026-07.md).
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
# O PAPEL entra por ONION_ROLE (default adopted). O merge de vendor-branch é o caminho do `--update`,
# e desde 2026-09-15 o papel CORTA de verdade — um vendor semeado sem papel republicaria a meta-fábrica
# num alvo standalone a cada atualização, desfazendo o corte da instalação.
# ⚠️ NEM TODO CONSUMIDOR DO MANIFESTO ACEITA MAGIA DE PATHSPEC — e ignorar isso clobou uma
# customização na bancada (vendor-branch §8, 2026-09-17). O manifesto passou a carregar
# `:(exclude)…jwks/*.pem` (a chave privada não viaja). `git archive` aceita essa magia e DEVE
# recebê-la — é o transporte. Mas `git ls-tree` a RECUSA: ele erra, o `2>/dev/null` engole o erro,
# a variável volta vazia, e `_clean_baseline` lê esse vazio como "não existe baseline limpo" —
# então ramifica do HEAD e o merge sobrescreve a customização do adotante EM SILÊNCIO. Uma linha
# de segurança desligou a guarda never-clobber, pelo caminho mais banal: saída vazia com rc
# escondido ([[exit-code-nao-e-a-verificacao]]).
# Quem COMPARA árvores usa só os positivos; quem TRANSPORTA usa o manifesto inteiro.
_manifest_positivo() {  # $1=SOURCE_ROOT → só as raízes positivas (sem `:(magia)`)
  _manifest "$1" | grep -v '^:(' || true
}

_manifest() {  # $1=SOURCE_ROOT → imprime pathspecs existentes, um por linha
  # .claude/workflows: a skill onion-research instrui Workflow({scriptPath:'.claude/workflows/onion-research.js'}) —
  # sem o dir o comando NASCE MORTO no adotante (sinal de campo de um adotante, 2026-09-04).
  # A lista vive UMA vez, em vendor-manifest.sh (SSOT). Quatro cópias eram três a mais, e duas já
  # tinham driftado (medido 2026-09-13).
  bash "${HERE}/vendor-manifest.sh" --role "${ONION_ROLE:-adopted}" --repo "$1"
}

# `--print-manifest <SOURCE_ROOT>` — expõe a decisão de transporte que este helper toma, para que
# ela possa ser MEDIDA em vez de inferida. Nasceu porque a bancada "provava" a propagação do papel
# com três `grep` de string literal, e a passada adversarial (2026-09-15) mostrou que ela aprovava um
# caminho quebrado: 106 arquivos da meta-fábrica caindo num alvo `role: standalone`, tudo verde.
# Guarda `behavior-over-declaration` que testa declaração não é guarda.
if [ "${1:-}" = "--print-manifest" ]; then
  [ -n "${2:-}" ] || { echo "uso: vendor-branch.sh --print-manifest <SOURCE_ROOT>" >&2; exit 2; }
  _manifest "$2"
  exit 0
fi

# ── GUARDA DE BASE CRUZADA ──────────────────────────────────────────────────────────────────
# Um `onion/vendor` só é fonte-de-merge legítima para uma integração se, em relação à BASE do
# merge com ela, ele mudou APENAS framework. Quando o seed cai no fallback (_seed do HEAD da
# integração — o caso "legado entrelaçado"), o vendor passa a carregar o SNAPSHOT DE PRODUTO
# daquela branch e fica casado com ela. Pedi-lo para uma SEGUNDA integração arrasta a
# divergência de produto para dentro do 3-way: conflito CONTÁBIL, em código de aplicação.
#
# Sinal de campo 2026-07-27 (adotante com duas integration branches divergentes): ~110 arquivos
# em conflito, incluindo serviços da API. REPRODUZIDO no core em 3 tentativas — e a reprodução
# derrubou a hipótese inicial: `merge-base --is-ancestor` dá SIM nos DOIS casos, então
# ANCESTRALIDADE NÃO DISCRIMINA. O que discrimina é o conteúdo NÃO-framework:
#     seguro  → tree(vendor) == tree(base) fora do manifesto
#     cruzado → tree(vendor) != tree(base) fora do manifesto
# Vantagem sobre registrar a origem na semeadura: funciona no vendor LEGADO, que é justamente
# quem tem o problema (nasceu antes de qualquer registro existir).
_vendor_is_framework_pure() {  # <TARGET> <SOURCE_ROOT> <INTEGRATION_BRANCH> → 0 puro · 1 cruzado
  local T="$1" SRC="$2" IB="$3" mb mf changed
  mb="$(git -C "$T" merge-base "$VENDOR" "$IB" 2>/dev/null)" || return 0
  [ -n "$mb" ] || return 0
  mf="$(_manifest_positivo "$SRC")"; [ -n "$mf" ] || return 0   # aqui se COMPARA, não se transporta
  changed="$(git -C "$T" diff --name-only "$mb" "$VENDOR" 2>/dev/null)" || return 0
  [ -n "$changed" ] || return 0
  # Remove do diff tudo que está sob o manifesto de framework; o que sobrar é produto alheio.
  local p keep="$changed"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    keep="$(printf '%s\n' "$keep" | grep -v "^${p}/" || true)"
  done <<< "$mf"
  # .claude/.onion-version é carimbo do framework, não produto.
  keep="$(printf '%s\n' "$keep" | grep -vE '^\.claude/\.onion-version$|^$' || true)"
  [ -z "$keep" ] && return 0
  printf '%s\n' "$keep" | head -8
  return 1
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
  fw="$(_manifest_positivo "$SRC")"; [ -n "$fw" ] || return 0
  # shellcheck disable=SC2086
  local _lt_err; _lt_err="$(mktemp)"
  ref="$(git -C "$SRC" ls-tree -r "$PIN" -- $fw 2>"${_lt_err}" | awk '{print $3" "$4}' | LC_ALL=C sort)"
  # FALA quando o comando falhou: "sem baseline" e "não consegui olhar" não podem soar igual — a
  # diferença entre os dois é um merge que preserva a customização e um que a apaga.
  if [ -s "${_lt_err}" ]; then
    echo "⚠️  Onion: ls-tree recusou o manifesto ao procurar o baseline limpo — NÃO é 'sem baseline':" >&2
    sed 's/^/      /' "${_lt_err}" >&2
  fi
  rm -f "${_lt_err}"
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
  # CURA (D_CURE, 2026-08-24): o baseline de catraca é LEDGER LOCAL do adotante — só encolhe por
  # medição e é a memória da dívida DELE. Não é framework, e o update NUNCA deve ADIANTAR nem ADICIONAR
  # o baseline do core ao vendor. O manifest inclui `.claude/validation/` inteiro, então o `tar -x`
  # acima traz os `*-baseline.txt` do core (que cobrem grafos core-only — docs/discussions/…). Se
  # deixados, o `durable-commit` os grava no onion/vendor, o merge os leva ao HEAD do adotante e a
  # catraca o cobra por passivo alheio (`REMOVIDO` HARD) no ato de filtrá-los. Medido no campo
  # (2026-08-24): há DOIS estados de vendor e a cura tem de cobrir os dois —
  #   (A) baseline JÁ RASTREADO no vendor (adotantes contaminados por updates PRÉ-cura): `checkout`
  #       restaura o do vendor a HEAD, o merge 3-way toma *ours* (vendor==merge-base), o veneno fica
  #       INERTE (congelado — o scrub do histórico é follow-up separado, ver grafo M2);
  #   (B) SEM baseline rastreado no vendor (adotante PRÉ-catraca — o ESTADO DO ORÁCULO): o do core chega
  #       como UNTRACKED; `checkout` é no-op; sem removê-lo o `durable-commit` o grava e o bug volta.
  # Logo: restaura o rastreado E remove o untracked que o tar-x trouxe → o vendor fica EXATAMENTE no seu
  # estado de HEAD, robusto contra qual regra de `_baseline_ref` dispara (a Regra 2 percorre para dentro
  # do onion/vendor). Baseline de catraca GENUINAMENTE novo do core segue via `regen-baselines.sh --auto`
  # do update, que o (re)emite do corpus do ALVO (novo → emit) — nunca herdado do core.
  # >>> D_CURE-baseline-preserve (run_vendor_baseline_removido_selftests remove ESTE bloco p/ provar load-bearing) >>>
  for _bl in "$wt"/.claude/validation/*-baseline.txt; do
    [ -e "$_bl" ] || continue                      # nullglob off: sem match, o literal não existe
    _rel="${_bl#"$wt"/}"
    if git -C "$wt" cat-file -e "HEAD:$_rel" 2>/dev/null; then
      git -C "$wt" checkout HEAD -- "$_rel" 2>/dev/null || true   # (A) rastreado → restaura ao HEAD do vendor
    else
      rm -f "$_bl"                                                # (B) untracked (veio do core no tar-x) → remove
    fi
  done
  # <<< D_CURE-baseline-preserve <<<
  bash "$HERE/durable-commit.sh" "$wt" update "$PIN" "$VENDOR" >/dev/null 2>&1
  git -C "$T" worktree remove --force "$wt" 2>/dev/null

  # BASE CRUZADA — recusa ANTES de mergear. Um despejo de N conflitos contábeis não é veredito,
  # é o maestro descobrindo sozinho o que a ferramenta já podia ter dito.
  local alien
  if ! alien="$(_vendor_is_framework_pure "$T" "$SRC" "$IB")"; then
    echo "ERRO: BASE CRUZADA — '$VENDOR' não é fonte-de-merge legítima para '$IB'." >&2
    echo "  Ele difere da base do merge em arquivos que NÃO são framework, ou seja: carrega o" >&2
    echo "  snapshot de PRODUTO de outra integration branch (seed pelo fallback do HEAD). Mergear" >&2
    echo "  arrastaria essa divergência para dentro do 3-way — conflito contábil, não real." >&2
    echo "  Arquivos alheios (amostra):" >&2
    printf '%s\n' "$alien" | sed 's/^/    /' >&2
    echo "  CONSERTO — um vendor por integration branch:" >&2
    echo "    git -C '$T' branch -m $VENDOR ${VENDOR}-<branch-de-origem>" >&2
    echo "    # depois re-rode este update; ele semeia do baseline LIMPO de '$IB'." >&2
    echo "    # Se a saída disser '⚠️ legado entrelaçado', PARE: '$IB' também está entrelaçada." >&2
    return 11
  fi

  # Merge do onion/vendor na integração (3-way; base comum). Conflito = never-clobber estrutural.
  if git -C "$T" merge "$VENDOR" -m "chore(onion): atualizar o Onion para o pin ${PIN}" >/dev/null 2>&1; then
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
