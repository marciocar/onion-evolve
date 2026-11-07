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
#       integração. Bootstrapa o vendor se ausente (legado). Exit: 0 merge limpo (ou conflito SÓ em
#       projeção gerada, resolvido por regeneração e declarado) · 10 CONFLITO (humano resolve) · 11 BASE CRUZADA · 12 arquivo do core não chegou à vendor (nada mergeado) · 13 onion/vendor
#       REMOTA não é ancestral da local, ou push recusado por não-ff (nada mergeado, nada forçado) · 14 remota
#       ilegível, push que falha ou conferência por ls-remote que não bate (nada mergeado) · 2 precondição.
#       A remota anda por fast-forward junto com a local SÓ com `vendor_push: true` no membro do registro do core
#       (lido de origin/main do core, ONION_CORE_ROOT; sem ele nada é tocado, e é dito); ONION_VENDOR_PUSH=0 desliga, e é dito.
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
  # o DESTINO (2026-10-11): quem usa o vendor-branch é a ADOÇÃO, e o adotado standalone mantém o canal
  # upstream que a porta standalone perde. O `--update` do adopt.md exporta ONION_KIND=door se o carimbo
  # do alvo tiver `kind: door`.
  bash "${HERE}/vendor-manifest.sh" --role "${ONION_ROLE:-adopted}" --kind "${ONION_KIND:-adoption}" --repo "$1"
}

# O PAPEL E O DESTINO SÃO DO ALVO, e o env é só um atalho (passada adversarial de 2026-10-11): o
# `--update` do adopt.md exporta ONION_ROLE/ONION_KIND num bloco e chama o `update` noutro, e a shell de
# um agente não persiste entre chamadas. Env perdido = papel `adopted` (não corta nada) e destino
# `adoption` (o canal upstream iria para uma porta). Quando o env veio vazio, lê-se o carimbo do alvo,
# o mesmo predicado do adopt.md (`role:` e `kind: door`). Env presente vence: é a escolha de quem chama.
_from_target_stamp() {  # $1=TARGET → preenche ONION_ROLE/ONION_KIND vazios a partir do carimbo dele
  local _st="$1/.claude/.onion-version"
  [ -f "${_st}" ] || return 0
  [ -n "${ONION_ROLE:-}" ] || ONION_ROLE="$(awk '/^role:/{print $2; exit}' "${_st}")"
  if [ -z "${ONION_KIND:-}" ]; then
    if [ "$(awk '/^kind:/{print $2; exit}' "${_st}")" = door ]; then ONION_KIND=door; else ONION_KIND=adoption; fi
  fi
}

# `--print-manifest <SOURCE_ROOT> [<TARGET>]` — expõe a decisão de transporte que este helper toma, para que
# ela possa ser MEDIDA em vez de inferida. Nasceu porque a bancada "provava" a propagação do papel
# com três `grep` de string literal, e a passada adversarial (2026-09-15) mostrou que ela aprovava um
# caminho quebrado: 106 arquivos da meta-fábrica caindo num alvo `role: standalone`, tudo verde.
# Guarda `behavior-over-declaration` que testa declaração não é guarda.
if [ "${1:-}" = "--print-manifest" ]; then
  [ -n "${2:-}" ] || { echo "uso: vendor-branch.sh --print-manifest <SOURCE_ROOT> [<TARGET>]" >&2; exit 2; }
  [ -n "${3:-}" ] && { _from_target_stamp "$3"; export ONION_TARGET="${ONION_TARGET:-$3}"; }   # o mesmo caminho do `update`, para a bancada medir
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
  # `core.quotePath=false`: com o default, nome acentuado sai ENTRE ASPAS e escapado, não casa com
  # `^<raiz>/` e vira "arquivo alheio" — BASE CRUZADA falsa (rc=11) no 1º arquivo acentuado do core.
  # Achado ao curar a mesma classe no transporte (2026-10-05): o bug era anterior e estava latente.
  changed="$(git -c core.quotePath=false -C "$T" diff --name-only "$mb" "$VENDOR" 2>/dev/null)" || return 0
  [ -n "$changed" ] || return 0
  # Remove do diff tudo que está sob o manifesto de framework; o que sobrar é produto alheio.
  local p keep="$changed"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    keep="$(printf '%s\n' "$keep" | grep -v "^${p}/" || true)"
  done <<< "$mf"
  # .claude/.onion-version é carimbo do framework, não produto.
  keep="$(printf '%s\n' "$keep" | grep -vE '^\.claude/\.onion-version$|^$' || true)"
  # As PROJEÇÕES GERADAS (docs/onion/inventory.md, graph.md, testing-*.md, kg-read-index.tsv) também são
  # framework: o próprio commit da onion/vendor as regenera, e fora do manifesto elas viravam "produto
  # alheio" → BASE CRUZADA falsa (rc=11), medida no --update de um hub em 2026-10-14. A lista vem do
  # GERADOR (--list-outputs), nunca copiada aqui. Gerador ausente ou mudo = nada a tirar: falha
  # fechada, a recusa segue como antes.
  local gen_out
  gen_out="$(bash "${HERE}/regen-ssot-projections.sh" --list-outputs 2>/dev/null)" || gen_out=""
  [ -n "$gen_out" ] && keep="$(printf '%s\n' "$keep" | grep -vxF -f <(printf '%s\n' "$gen_out") || true)"
  [ -z "$keep" ] && return 0
  printf '%s\n' "$keep" | head -8
  return 1
}

# ── CONFLITO SÓ EM PROJEÇÃO GERADA SE RESOLVE POR REGENERAÇÃO (SAC-139, 2026-10-14) ──────────────
# Medido nos dois `--update` reais do dia (um hub com integração onion/develop, outro com main): o merge
# deu rc=10 SÓ em `docs/onion/{inventory,testing-inventory,testing-state}.md` e `kg-read-index.tsv`,
# porque as DUAS pontas as regeneram. Nenhuma das duas versões é a certa (a certa é a que o gerador
# escreve sobre a árvore mergeada), e a resolução manual era sempre a mesma: `checkout --theirs`,
# regenerar, `git add`, commitar. Aqui ela vira mecanismo, com três travas:
#   1. TODO arquivo em conflito tem de estar na lista do GERADOR (`--list-outputs`), por linha inteira
#      (`grep -vxF`). Um único arquivo fora dela (customização de framework) → nada é tocado, rc=10.
#   2. Gerador ausente/mudo ou que falha → rc=10, e os marcadores VOLTAM (`checkout -m`): falha fechada.
#   3. A resolução é DECLARADA no stdout (quantos e quais), nunca calada.
_autoresolve_projections() {  # <TARGET> <CONFLITOS, um por linha> <args -m do merge...> → 0 resolvido · 1 não
  local T="$1" conf="$2" gen_out outside n f; shift 2
  gen_out="$(bash "${HERE}/regen-ssot-projections.sh" --list-outputs 2>/dev/null)" || gen_out=""
  [ -n "${gen_out}" ] || return 1
  outside="$(grep -vxF -f <(printf '%s\n' "${gen_out}") <<< "${conf}" || true)"
  [ -z "${outside}" ] || return 1
  n="$(grep -c . <<< "${conf}")"
  local -a files=(); while IFS= read -r f; do [ -n "$f" ] && files+=("$f"); done <<< "${conf}"
  # (modify/delete: o lado deles não existe e o `--theirs` recusa — os marcadores voltam, rc=10)
  if ! git --literal-pathspecs -C "$T" checkout --theirs -- "${files[@]}" 2>/dev/null; then
    git --literal-pathspecs -C "$T" checkout -m -- "${files[@]}" 2>/dev/null || true; return 1
  fi
  if ! bash "${HERE}/regen-ssot-projections.sh" "$T" >/dev/null 2>&1; then
    git --literal-pathspecs -C "$T" checkout -m -- "${files[@]}" 2>/dev/null || true   # os marcadores voltam
    echo "⚠️  Onion: ${n} conflito(s) só de projeção gerada, mas o gerador FALHOU no alvo — não resolvo às cegas." >&2
    return 1
  fi
  # Stageia os arquivos em conflito (agora regenerados) e as projeções que o gerador reescreveu ao lado.
  # (É a trava 1 que protege a customização: daqui em diante, o que estava em conflito é dado por resolvido.)
  git --literal-pathspecs -C "$T" add -A -- "${files[@]}" 2>/dev/null || true
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ -e "$T/$f" ] || git --literal-pathspecs -C "$T" ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
      git --literal-pathspecs -C "$T" add -A -- "$f" 2>/dev/null || true
    fi
  done <<< "${gen_out}"
  if [ -n "$(git -C "$T" diff --name-only --diff-filter=U 2>/dev/null)" ]; then
    echo "⚠️  Onion: regenerei as projeções, mas ainda há conflito no índice — não concluo o merge." >&2
    return 1
  fi
  local -a msg=("$@"); [ "${#msg[@]}" -ge 2 ] || msg=(-m "chore(onion): atualizar o Onion")
  # A nota entra ANTES da assinatura (o último -m), para o trailer do adotante seguir no fim.
  local -a full=("${msg[@]:0:2}" -m "Conflito só em projeção gerada (${n}), resolvido por regeneração: $(tr '\n' ' ' <<< "${conf}")" "${msg[@]:2}")
  if ! git -C "$T" commit -q "${full[@]}" >/dev/null 2>&1; then
    echo "⚠️  Onion: projeções regeneradas e stageadas, mas o commit do merge foi RECUSADO em $T — conclua com 'git commit'." >&2
    return 1
  fi
  echo "Onion: resolvi ${n} conflito(s) de projeção gerada por regeneração (checkout --theirs + regen-ssot-projections.sh):"
  printf '%s\n' "${conf}" | sed 's/^/    /'
  echo "Onion: framework atualizado via merge de $VENDOR (pin ${PIN:-?})."
  return 0
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

# ── A ONION/VENDOR REMOTA ANDA JUNTO COM A LOCAL (2026-11-07) ──────────────────────────────────────
# O merge sai da onion/vendor LOCAL, e nada a empurrava: medido no --update de um adotante, a remota
# estava 4 versões atrás da local (4.40.2 contra 4.44.0). Clone novo, outra máquina ou outra sessão
# ramificaria do que a remota diz, e a base do 3-way seria a errada. Daqui em diante:
#   · ANTES de mexer na vendor, lê a remota (ls-remote). Local ausente e remota presente → a local nasce
#     DELA (não de baseline nem do HEAD). Remota que não é ancestral da local → rc 13, nada tocado.
#   · DEPOIS do commit da vendor (e da guarda de BASE CRUZADA), empurra por fast-forward, sem force, e
#     confere no remoto: ls-remote tem de devolver o sha local. Push recusado por não-ff → rc 13; remoto
#     ilegível, push que falha por outro motivo ou conferência que não bate → rc 14.
#   · O que o update diz da remota é UMA linha, para o relatório downstream: de onde para onde ela foi.
# Tudo isso SÓ com consentimento registrado no core (bloco CONSENTIMENTO abaixo); sem ele, nada é tocado.
# Não cria a branch num remoto que não a tem (decisão do dono do repo: a linha diz o comando). Sem
# remoto, nada a empurrar, e é dito. ONION_VENDOR_PUSH=0 desliga, e também é dito.
_vendor_remote() {  # <TARGET> → nome do remoto da onion/vendor (upstream dela, senão origin), ou vazio
  local r; r="$(git -C "$1" config --get "branch.${VENDOR}.remote" 2>/dev/null)"
  [ -n "$r" ] || r=origin
  git -C "$1" remote get-url "$r" >/dev/null 2>&1 && printf '%s\n' "$r"
  return 0
}
# Lê pela URL de PUSH (`remote get-url --push`): é para lá que o push vai, e um `remote.<r>.pushurl` diferente
# da url faria a leitura e a conferência olharem outro repo (passada adversarial do PR, 2026-11-07).
_remote_vendor_sha() {  # <TARGET> <REMOTE> → sha da onion/vendor no remoto (vazio = ausente) · rc 1 = ilegível
  local out url
  url="$(git -C "$1" remote get-url --push "$2" 2>/dev/null)" || return 1
  out="$(GIT_TERMINAL_PROMPT=0 git -C "$1" ls-remote --heads "${url}" "refs/heads/${VENDOR}" 2>/dev/null)" || return 1
  awk '{print $1; exit}' <<< "${out}"
}
# CONSENTIMENTO REGISTRADO NO CORE, PRESO AO DESTINO (passadas adversariais do PR, 2026-11-07): empurrar
# para o remoto de um adotante é ato no repo DELE. O push só sai se o membro do registro do core que tem
# `vendor_push: true` for o DONO do destino real. Cinco portas, cada uma nascida de um ataque medido:
#   · REGISTRO = o que já passou por PR e merge: `git show origin/main:docs/evolution/federation/members.yaml`
#     do checkout do core (ONION_CORE_ROOT, senão a fonte), e só se esse checkout tem papel `source`
#     (onion-version.sh). Arquivo solto, ou commitado só localmente, fabricava consentimento.
#   · DESTINO = TODAS as URLs de push do remoto efetivo (`get-url --push --all` do mesmo `_vendor_remote` que o
#     ls-remote e o push usam): o `git push` empurra para todas, e conferir só a 1ª deixava a 2ª passar.
#   · URL ESTRITA: só https://, ssh:// e a forma scp `usuário@host:`; espaço ou tab, caminho local, file://,
#     git:// e ext:: são recusados (um caminho relativo "github.com/dono/repo" se passava pelo curador).
#   · MEMBRO: primeiro pelo `local_path` igual ao checkout principal do alvo, senão pelo `remote`. Em QUALQUER
#     dos dois, se outro membro divide o mesmo remote e não consentiu → recusa.
#   · ONION_MEMBER_ID só RESTRINGE: o membro achado acima tem de ser ele; nunca amplia.
# Sem consentimento, nada é lido nem empurrado: o update segue como antes, e a linha diz por quê.
# TETO declarado: quem controla o ambiente e o disco pode montar um checkout com `origin/main` próprio; o
# registro protege contra engano e configuração alheia, não contra quem já roda o push com as próprias mãos.
_norm_remote() {  # URL de git → host/dono/repo minúsculo (rc 0) · forma não aceita → vazio (rc 1)
  local u="$1" host path LC_ALL=C   # C: [A-Za-z] nunca casa letra de outro alfabeto (homóglifo)
  case "$u" in *[[:space:]]*) return 1 ;; esac
  if [[ "$u" =~ ^https://([^/@]+@)?([A-Za-z0-9.-]+)(:[0-9]+)?/(.+)$ ]] \
     || [[ "$u" =~ ^ssh://([^/@]+@)?([A-Za-z0-9.-]+)(:[0-9]+)?/(.+)$ ]]; then
    host="${BASH_REMATCH[2]}"; path="${BASH_REMATCH[4]}"
    # porta só a padrão do esquema: outra porta é OUTRO serviço, e normalizar as duas iguais as confundiria
    case "${u%%://*}:${BASH_REMATCH[3]}" in https:|https::443|ssh:|ssh::22) ;; *) return 1 ;; esac
  elif [[ "$u" =~ ^[A-Za-z0-9._-]+@([A-Za-z0-9.-]+):([^/].*)$ ]]; then
    host="${BASH_REMATCH[1]}"; path="${BASH_REMATCH[2]}"
  else return 1; fi
  case "$path" in */.[gG][iI][tT]|*/.[gG][iI][tT]/) return 1 ;; esac   # "repo/.git" não é "repo"
  path="${path%/}"; path="${path%.[gG][iI][tT]}"; path="${path%/}"
  # dono/repo de verdade: segmentos limpos, sem `..`, sem `%`, sem `@` nem `:` escondidos
  [[ "$path" =~ ^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)+$ ]] || return 1
  case "/$path/" in */../*|*/./*) return 1 ;; esac
  printf '%s/%s\n' "${host}" "${path}" | tr '[:upper:]' '[:lower:]'
}
# Do lado do REGISTRO também vale `host/dono/repo` SEM esquema: é a forma de 24 dos 31 membros, e
# normalizá-la para vazio tirava o irmão da conta do remote dividido (4ª refutação, 2026-11-07). Os
# segmentos seguem estritos. Do lado do ALVO (a URL de push) a forma sem esquema continua recusada:
# lá ela é caminho local.
_member_remote_norm() {  # `remote:` do registro → normalizado (a nota "(privado)" do registro sai antes)
  local m="$1" LC_ALL=C; m="${m%%[[:space:]](*}"
  _norm_remote "$m" && return 0
  # >>> D_CURE-registry-schemeless (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  case "$m" in *[[:space:]]*|*/.[gG][iI][tT]|*/.[gG][iI][tT]/) return 1 ;; esac
  m="${m%/}"; m="${m%.[gG][iI][tT]}"; m="${m%/}"
  [[ "$m" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+(/[A-Za-z0-9._-]+){2,}$ ]] || return 1
  case "/$m/" in */../*|*/./*) return 1 ;; esac
  printf '%s\n' "$m" | tr '[:upper:]' '[:lower:]'
  # <<< D_CURE-registry-schemeless <<<
}
_core_registry() {  # <CORE> → o members.yaml de origin/main no stdout · rc 1 com o motivo no stdout
  local core="$1" role
  [ -n "${core}" ] && [ -d "${core}" ] || { echo "checkout do core ausente (${core:-vazio})"; return 1; }
  role="$(bash "${core}/.claude/validation/onion-version.sh" 2>/dev/null | awk '/^role:/{print $2; exit}')"
  [ "${role}" = source ] || { echo "o checkout ${core} não tem papel source (role: ${role:-?})"; return 1; }
  # o origin/main LOCAL envelhece: um consentimento RETIRADO no remoto só valeria depois de um fetch. O fetch
  # é feito aqui, e falha fechada: sem conseguir atualizar, não há como saber se o consentimento segue de pé.
  # O fetch tem PRAZO (ressalva da 5ª refutação, 2026-11-07): um ssh que dorme prendia o update inteiro. O
  # `timeout -k` mata o grupo do git (e o ssh ou o upload-pack que ele chamou, inclusive um prompt de senha
  # parado), e o http desiste se ficar lento. O ssh do usuário (GIT_SSH_COMMAND, core.sshCommand) NÃO é
  # trocado: forçar BatchMode por cima dele sobrescreveria a chave que ele escolheu. Prazo vencido ou
  # `timeout` ausente = falha fechada, como o fetch que falha.
  # ONION_REGISTRY_FETCH_TIMEOUT (segundos, default 30) existe para a bancada encurtar o caso.
  # >>> D_CURE-registry-fetch (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  local _to="${ONION_REGISTRY_FETCH_TIMEOUT:-30}" _frc=0
  [[ "${_to}" =~ ^[1-9][0-9]*$ ]] || _to=30
  command -v timeout >/dev/null 2>&1 \
    || { echo "sem o comando timeout para dar prazo ao fetch do registro em ${core} — recuso ler sem prazo"; return 1; }
  GIT_TERMINAL_PROMPT=0 timeout -k 5 "${_to}" git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=15 -C "${core}" fetch -q origin main 2>/dev/null || _frc=$?
  if [ "${_frc}" -eq 124 ] || [ "${_frc}" -eq 137 ]; then
    echo "o fetch do registro em ${core} passou do prazo de ${_to}s — o consentimento pode ter sido retirado"; return 1
  fi
  [ "${_frc}" -eq 0 ] \
    || { echo "não consegui atualizar origin/main em ${core} (fetch falhou) — o consentimento pode ter sido retirado"; return 1; }
  # <<< D_CURE-registry-fetch <<<
  git -C "${core}" show origin/main:docs/evolution/federation/members.yaml 2>/dev/null \
    || { echo "sem docs/evolution/federation/members.yaml em origin/main de ${core}"; return 1; }
}
_vendor_push_consent() {  # <TARGET> <SOURCE_ROOT> <REMOTE> → rc 0 consentiu (ecoa o id) · 1 não (ecoa o motivo)
  local T="$1" R="$3" reg main purl="" u n rows by pick nok
  reg="$(_core_registry "${ONION_CORE_ROOT:-$2}")" || { echo "${reg}"; return 1; }
  main="$(cd "$(git -C "$T" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)/.." 2>/dev/null && pwd -P)"
  # >>> D_CURE-consent-all-pushurls (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  local urls; urls="$(git -C "$T" remote get-url --push --all "$R" 2>/dev/null)"
  [ -n "${urls}" ] || { echo "remoto '${R}' sem URL de push"; return 1; }
  purl=""
  while IFS= read -r u; do
    [ -n "$u" ] || continue
    n="$(_norm_remote "$u")" || { echo "URL de push fora das formas aceitas (https://, ssh://, usuário@host:): ${u}"; return 1; }
    [ -z "${purl}" ] || [ "${n}" = "${purl}" ] || { echo "o remoto '${R}' empurra para destinos diferentes (${purl} e ${n})"; return 1; }
    purl="${n}"
  done <<< "${urls}"
  # <<< D_CURE-consent-all-pushurls <<<
  [ -n "${purl}" ] || purl="$(_norm_remote "$(git -C "$T" remote get-url --push "$R" 2>/dev/null)")" \
    || { echo "URL de push fora das formas aceitas"; return 1; }
  # id␟local_path␟remote␟vendor_push (separador \037, NÃO tab: o `read` colapsa tabs vazios e um membro sem
  # local_path deslocava os campos — medido na bancada)
  rows="$(awk '
    function val(l) { sub(/^[^:]*:[ \t]*/, "", l); sub(/[ \t]+#.*$/, "", l); gsub(/^["\047]|["\047]$/, "", l); return l }
    function flush() { if (id != "") printf "%s\037%s\037%s\037%s\n", id, lp, rm, vp }
    /^  - id:/ { flush(); id = val($0); lp = ""; rm = ""; vp = "false"; next }
    /^    local_path:/ { lp = val($0); next }
    /^    remote:/ { rm = val($0); next }
    /^    vendor_push:/ { vp = val($0); next }
    END { flush() }' <<< "${reg}")"
  local id lp rm vp rn; local -a byp=() byr=()
  while IFS=$'\037' read -r id lp rm vp; do
    [ -n "${id}" ] || continue
    rn="$(_member_remote_norm "${rm}")" || rn=""
    [ -n "${lp}" ] && [ "${lp%/}" = "${main}" ] && byp+=("${id}"$'\t'"${rn}"$'\t'"${vp}")
    [ -n "${rn}" ] && [ "${rn}" = "${purl}" ] && byr+=("${id}"$'\t'"${rn}"$'\t'"${vp}")
  done <<< "${rows}"
  if [ "${#byp[@]}" -ge 1 ]; then
    [ "${#byp[@]}" -eq 1 ] || { echo "dois membros declaram o mesmo local_path"; return 1; }
    pick="${byp[0]}"; by="local_path"
    [ "$(cut -f2 <<< "${pick}")" = "${purl}" ] \
      || { echo "o push iria para ${purl}, que não é o remote do membro '$(cut -f1 <<< "${pick}")'"; return 1; }
  else
    [ "${#byr[@]}" -ge 1 ] || { echo "nenhum membro do registro tem o remote ${purl}"; return 1; }
    pick="${byr[0]}"; by="remote"
  fi
  # REMOTE DIVIDIDO: vale pelos dois caminhos — se algum membro com o mesmo remote não consentiu, recusa.
  # (Só com 2 membros ou mais: com um só, o motivo certo é o "sem vendor_push: true" logo abaixo.)
  # >>> D_CURE-consent-shared-remote (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  if [ "${#byr[@]}" -ge 2 ]; then
    nok="$(printf '%s\n' "${byr[@]}" | awk -F'\t' '$3!="true"{k++} END{print k+0}')"
    [ "${nok}" -eq 0 ] || { echo "o remote ${purl} é dividido por ${#byr[@]} membros e ${nok} não consentiu"; return 1; }
  fi
  # <<< D_CURE-consent-shared-remote <<<
  [ "$(cut -f3 <<< "${pick}")" = true ] || { echo "o membro '$(cut -f1 <<< "${pick}")' não tem vendor_push: true"; return 1; }
  if [ -n "${ONION_MEMBER_ID:-}" ] && [ "$(cut -f1 <<< "${pick}")" != "${ONION_MEMBER_ID}" ]; then
    echo "ONION_MEMBER_ID=${ONION_MEMBER_ID} não é o membro do alvo ('$(cut -f1 <<< "${pick}")')"; return 1
  fi
  printf '%s (casado pelo %s; destino %s)\n' "$(cut -f1 <<< "${pick}")" "${by}" "${purl}"
}

# Preenche VREMOTE/VREMOTE_OLD. rc 0 segue · 13 divergente · 14 ilegível.
_vendor_remote_precheck() {  # <TARGET> <SOURCE_ROOT>
  local T="$1" _mid
  VREMOTE=""; VREMOTE_OLD=""
  if [ "${ONION_VENDOR_PUSH:-1}" = 0 ]; then
    echo "Onion: push da $VENDOR DESLIGADO (ONION_VENDOR_PUSH=0) — a remota não é tocada nesta rodada."; return 0
  fi
  VREMOTE="$(_vendor_remote "$T")"
  if [ -z "${VREMOTE}" ]; then
    echo "Onion: $VENDOR sem remoto (nem upstream nem 'origin') — fica só local, nada a empurrar."; return 0
  fi
  # O consentimento se confere contra o DESTINO deste remoto (a URL de push dele), nunca contra o origin fixo.
  # >>> D_CURE-vendor-push-consent (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  if ! _mid="$(_vendor_push_consent "$T" "$2" "${VREMOTE}")"; then
    echo "Onion: $VENDOR remota não empurrada: sem consentimento registrado (${_mid}). Para empurrar à mão: git -C \"$T\" push ${VREMOTE} $VENDOR"
    VREMOTE=""; return 0
  fi
  echo "Onion: push da $VENDOR consentido pelo membro ${_mid} — vendor_push: true no registro do core."
  # <<< D_CURE-vendor-push-consent <<<
  if ! VREMOTE_OLD="$(_remote_vendor_sha "$T" "${VREMOTE}")"; then
    echo "ERRO: não consegui ler a $VENDOR em '${VREMOTE}' (ls-remote falhou) — nada foi tocado." >&2
    echo "      Sem ler a remota não sei se a local está à frente; re-rode com o remoto alcançável, ou ONION_VENDOR_PUSH=0 (declarado no relatório)." >&2
    return 14
  fi
  if [ -z "${VREMOTE_OLD}" ]; then
    echo "Onion: '${VREMOTE}' não tem a $VENDOR — não crio a branch no remoto do adotante; para publicá-la: git push ${VREMOTE} ${VENDOR}"
    VREMOTE=""; return 0
  fi
  if ! git -C "$T" cat-file -e "${VREMOTE_OLD}^{commit}" 2>/dev/null; then
    GIT_TERMINAL_PROMPT=0 git -C "$T" fetch -q "$(git -C "$T" remote get-url --push "${VREMOTE}")" "refs/heads/${VENDOR}" 2>/dev/null \
      || { echo "ERRO: a $VENDOR remota (${VREMOTE_OLD:0:12}) não veio no fetch de '${VREMOTE}' — nada foi tocado." >&2; return 14; }
  fi
  # >>> D_CURE-vendor-from-remote (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  if ! git -C "$T" rev-parse --verify -q "refs/heads/${VENDOR}" >/dev/null 2>&1; then
    git -C "$T" branch "$VENDOR" "${VREMOTE_OLD}" >/dev/null 2>&1 \
      || { echo "ERRO: falhou ao criar a $VENDOR local a partir da remota." >&2; return 14; }
    echo "Onion: $VENDOR local ausente — criada da remota '${VREMOTE}' (${VREMOTE_OLD:0:12}), a base que os outros clones também têm."
    return 0
  fi
  # <<< D_CURE-vendor-from-remote <<<
  # >>> D_CURE-vendor-remote-diverged (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  if ! git -C "$T" merge-base --is-ancestor "${VREMOTE_OLD}" "refs/heads/${VENDOR}" 2>/dev/null; then
    echo "ERRO: a $VENDOR remota (${VREMOTE}: ${VREMOTE_OLD:0:12}) NÃO é ancestral da local ($(git -C "$T" rev-parse --short=12 "refs/heads/${VENDOR}")) — nada foi tocado, e nada será forçado." >&2
    if git -C "$T" merge-base --is-ancestor "refs/heads/${VENDOR}" "${VREMOTE_OLD}" 2>/dev/null; then
      echo "      A remota está À FRENTE (outro clone atualizou). Traga-a: git -C '$T' branch -f $VENDOR ${VREMOTE_OLD}  — e re-rode." >&2
    else
      echo "      As duas DIVERGIRAM: compare: git -C "$T" log --oneline --left-right $VENDOR...${VREMOTE_OLD:0:12} — e decida qual é a vendor." >&2
    fi
    return 13
  fi
  # <<< D_CURE-vendor-remote-diverged <<<
  return 0
}
# Empurra por ff e confere. rc 0 · 13 recusado por não-ff · 14 outra falha ou conferência que não bate.
_vendor_remote_push() {  # <TARGET>
  local T="$1" new now out
  [ -n "${VREMOTE}" ] || return 0
  new="$(git -C "$T" rev-parse "refs/heads/${VENDOR}")"
  # >>> D_CURE-vendor-ffpush (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  if [ "${new}" != "${VREMOTE_OLD}" ]; then
    if ! out="$(GIT_TERMINAL_PROMPT=0 git -C "$T" push --porcelain "${VREMOTE}" "refs/heads/${VENDOR}:refs/heads/${VENDOR}" 2>&1)"; then
      echo "ERRO: o push da $VENDOR para '${VREMOTE}' foi recusado — sem force; o merge NÃO foi feito:" >&2
      printf '%s\n' "${out}" | tail -6 | sed 's/^/    /' >&2
      echo "      Re-rode quando a causa sumir, ou ONION_VENDOR_PUSH=0 para seguir sem tocar a remota (declarado no relatório)." >&2
      grep -qE 'non-fast-forward|fetch first|\[rejected\]|failed to update ref|cannot lock ref' <<< "${out}" && return 13
      return 14
    fi
  fi
  # <<< D_CURE-vendor-ffpush <<<
  # >>> D_CURE-vendor-verify (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  if ! now="$(_remote_vendor_sha "$T" "${VREMOTE}")" || [ "${now}" != "${new}" ]; then
    echo "ERRO: conferência no remoto falhou — ls-remote '${VREMOTE}' devolve '${now:-<nada>}', a local é ${new:0:12}. O merge NÃO foi feito." >&2
    echo "      Ou ONION_VENDOR_PUSH=0 para seguir sem tocar a remota (declarado no relatório)." >&2
    return 14
  fi
  # <<< D_CURE-vendor-verify <<<
  if [ "${new}" = "${VREMOTE_OLD}" ]; then
    echo "Onion: $VENDOR remota (${VREMOTE}) já em ${new:0:12}, igual à local (conferida por ls-remote)."
  else
    echo "Onion: $VENDOR remota (${VREMOTE}): ${VREMOTE_OLD:0:12} → ${new:0:12} (fast-forward, conferida por ls-remote)."
  fi
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
  # O PIN É O COMMIT TRANSPORTADO (SAC-144, 2026-10-15): o transporte abaixo sai do HEAD da fonte, e
  # o pin é o que se carimba. Pin ≠ HEAD = o adotante recebe um commit e registra outro — a escolha
  # da fonte vive no resolve-update-source.sh, que entrega um SOURCE_ROOT cujo HEAD É o pin.
  # Só compara o que resolve: lixo de pin é da guarda acima (o mutante dela tem de continuar mordendo).
  _pin_full="$(git -C "$SRC" rev-parse --verify -q "${PIN}^{commit}" 2>/dev/null)"
  if [ -n "${_pin_full}" ] && [ "${_pin_full}" != "$(git -C "$SRC" rev-parse HEAD)" ]; then
    echo "ERRO: pin '${PIN}' não é o HEAD da fonte ($SRC) — o transporte sairia de outro commit." >&2
    echo "      Resolva a fonte pelo resolve-update-source.sh (ele entrega a raiz cujo HEAD é o pin)." >&2
    return 2
  fi

  # A remota é lida ANTES de qualquer escrita na vendor (bloco "A ONION/VENDOR REMOTA" acima).
  local VREMOTE VREMOTE_OLD _rrc=0
  _vendor_remote_precheck "$T" "$SRC" || _rrc=$?
  [ "${_rrc}" -eq 0 ] || return "${_rrc}"
  # A sessão é resolvida uma vez: a nota de "desconhecida" sai aqui, uma só (o durable-commit a calaria).
  local _trailer=""; [ -f "${HERE}/session-trailer.sh" ] && _trailer="$(bash "${HERE}/session-trailer.sh" --note)"

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
  _from_target_stamp "$T"
  export ONION_TARGET="${ONION_TARGET:-$T}"   # o contrato do .kg.yaml que o alvo já tem não é sobrescrito (vendor-manifest.sh)
  local mf; mf="$(_manifest "$SRC")"
  [ -n "$mf" ] || { echo "ERRO: manifest vazio (core sem framework?)." >&2; git -C "$T" worktree remove --force "$wt" 2>/dev/null; return 2; }
  # O sha é resolvido UMA vez: transporte e lista de exigidos saem do MESMO commit (Elenxo: com dois
  # `git archive HEAD`, um commit no core entre eles divergia a lista do que de fato viajou).
  local sha; sha="$(git -C "$SRC" rev-parse HEAD)"
  # shellcheck disable=SC2046
  ( cd "$SRC" && git archive "$sha" -- $(printf '%s ' $mf) ) | tar -x -C "$wt" 2>/dev/null
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
  # ── O QUE VEIO DO CORE TEM DE CHEGAR À VENDOR (sinal de campo de um hub, 2026-10-04) ─────────────
  # A lista é a do PRÓPRIO transporte (`git archive … | tar -t`, que já respeita os `:(exclude)`), menos
  # os baselines de catraca que o bloco acima remove de propósito. Ela vai ao durable-commit, que a
  # staja com `-f`: um .gitignore da vendor que cubra `.claude/` fazia o `git add` pular todo arquivo
  # NOVO em silêncio, e o update dizia "merge limpo" (17 arquivos perdidos em dois updates no campo).
  # A LISTA sai de um índice TEMPORÁRIO do mesmo sha: `ls-files` aplica a semântica de pathspec do git
  # inteira (inclusive `:(exclude)`, que o `ls-tree` recusa) e, com `-z`, nunca escapa nome. A 1ª versão
  # usava `tar -t`, que escapa acento em octal sob LC_ALL=C: o 1º arquivo acentuado do core derrubaria o
  # update de TODO adotante com rc=12 falso (Elenxo, executado com `decisão-teste.md`).
  local req idx; req="$(mktemp)"; idx="$(mktemp)"; rm -f "$idx"
  # shellcheck disable=SC2046
  GIT_INDEX_FILE="$idx" git -C "$SRC" read-tree "$sha" 2>/dev/null \
    && GIT_INDEX_FILE="$idx" git -C "$SRC" ls-files -z -- $(printf '%s ' $mf) 2>/dev/null \
       | grep -zvE '^\.claude/validation/[^/]*-baseline\.txt$' | LC_ALL=C sort -zu > "$req"
  rm -f "$idx"
  [ -s "$req" ] || { echo "ERRO: a lista do que o core transporta saiu VAZIA (sha ${sha:0:12}) — recuso seguir sem ela." >&2
                     git -C "$T" worktree remove --force "$wt" 2>/dev/null; rm -f "$req"; return 12; }
  # ── O QUE O CORE PAROU DE TRANSPORTAR SAI DA VENDOR (rename do workflow do evolve, 2026-10-13) ────
  # O `tar -x` acima SOBREPÕE: escreve o que o core manda e nunca apaga o que ele deixou de mandar.
  # (Os nomes vão SEM extensão de propósito: este arquivo viaja e ANCORA peças por citação com extensão
  #  — `vendor-manifest.sh`, "_is_anchor" — e citar o workflow aqui o manteria vivo onde o evolve é cortado.)
  # MEDIDO numa fixture (core renomeia o workflow `evolve` → `meta-evolve-fanout`, update rc=0
  # "merge limpo"): o adotante ficava com OS DOIS — o antigo, órfão, seguia na lista de workflows dele
  # com o nome que o core aposentou. Todo rename e toda remoção do core vazavam assim, em silêncio.
  # O CRITÉRIO É O DELTA DO PRÓPRIO CORE, nunca "o que a vendor tem e o core não": a vendor nasce da
  # integração e carrega arquivo do ADOTANTE sob `.claude/` (comandos próprios, por exemplo). Sai só o
  # que o core TRANSPORTAVA no pin anterior (o `source_commit` do carimbo da integração, ainda não
  # re-carimbado) e NÃO transporta mais, com o mesmo manifesto dos dois lados. Adotante que editou o
  # arquivo removido recebe conflito modify/delete (exit 10): never-clobber continua estrutural.
  # RENAME (o caso que motivou): a vendor ganha delete+add do mesmo conteúdo, e a detecção de rename do
  # merge leva a edição do adotante para o nome novo, sem conflito (medido, caso (c) da bancada).
  # Pin anterior ausente ou que não é commit da fonte → NADA sai, e isso é DITO (status quo, declarado).
  # O LADO ANTIGO SE MEDE SEM AS EXCLUSÕES DE APOSENTADORIA (2026-10-17): com o manifesto inteiro, o
  # `:(exclude)` que APOSENTA um arquivo também filtrava o pin anterior, e ele nunca entrava no delta —
  # medido num clone descartável de adotante: a skill onion-publish, tirada da adoção, ficava nele depois
  # do --update rc=0. SÓ as de aposentadoria saem do lado antigo (`vendor-manifest.sh --retired-excludes`):
  # A 1ª cura tirava TODAS. Isso não apaga arquivo próprio do adotante (o lado antigo é a árvore do CORE
  # no pin anterior, e a bancada refutou essa objeção), mas estenderia a remoção aos CORTES DE PAPEL: um
  # adotante que trocou de papel perderia o que o corte novo tira, decisão que ninguém tomou. Estreito.
  # LIMITE DECLARADO: o manifesto só lista raiz que EXISTE no HEAD da fonte; se o core apagar uma raiz
  # INTEIRA (ex.: `.claude/workflows/` vazio), os arquivos dela não entram no delta e ficam.
  # >>> D_CURE-core-removed (run_vendor_core_removed_selftests remove ESTE bloco p/ provar load-bearing) >>>
  local _prev _pidx _pold _gone
  _prev="$(awk '/^source_commit:/{print $2; exit}' "$T/.claude/.onion-version" 2>/dev/null)"
  if [ -n "${_prev}" ] && git -C "$SRC" cat-file -e "${_prev}^{commit}" 2>/dev/null; then
    _pidx="$(mktemp)"; _pold="$(mktemp)"; rm -f "$_pidx"
    # shellcheck disable=SC2046
    GIT_INDEX_FILE="$_pidx" git -C "$SRC" read-tree "$_prev" 2>/dev/null \
      && GIT_INDEX_FILE="$_pidx" git -C "$SRC" ls-files -z -- $(printf '%s\n' $mf | grep -vxF -f <(bash "$HERE/vendor-manifest.sh" --retired-excludes) || true) 2>/dev/null \
         | grep -zvE '^\.claude/validation/[^/]*-baseline\.txt$' | LC_ALL=C sort -zu > "$_pold"
    rm -f "$_pidx"
    _gone="$(LC_ALL=C comm -z -23 "$_pold" "$req" | tr '\0' '\n')"
    rm -f "$_pold"
    while IFS= read -r _f; do
      [ -n "${_f}" ] || continue
      git -C "$wt" cat-file -e "HEAD:${_f}" 2>/dev/null || continue   # a vendor nunca o teve: nada a tirar
      # (a 1ª redação passava `--literal-pathspecs` ao `rm`, que o recusa: falhou calada e o arquivo
      #  ficou — por isso a falha agora é DITA, nunca engolida)
      if git --literal-pathspecs -C "$wt" rm -q -- "${_f}" >/dev/null 2>&1; then
        echo "Onion: '${_f}' saiu do core (pin ${_prev:0:12} → ${sha:0:12}) — removido da $VENDOR."
      else
        echo "⚠️  Onion: '${_f}' saiu do core mas NÃO consegui tirá-lo da $VENDOR — fica no adotante." >&2
      fi
    done <<< "${_gone}"
  else
    echo "⚠️  Onion: pin anterior '${_prev:-<sem source_commit>}' não é commit da fonte — arquivo que o core REMOVEU não sai da $VENDOR nesta rodada." >&2
  fi
  # <<< D_CURE-core-removed <<<
  local _dc=0
  # ONION_DURABLE_VERIFY=0 FIXO: o commit da onion/vendor é framework puro numa worktree temporária; um
  # VERIFY=1 exportado pelo operador para o commit final do --update vazaria até aqui, o hook recusaria
  # e o erro viraria rc=12 "não levou o framework inteiro" — mentira (Elenxo do PR da F1, O2).
  ONION_DURABLE_VERIFY=0 ONION_REQUIRED_LIST="$req" ONION_REQUIRED_NUL=1 bash "$HERE/durable-commit.sh" "$wt" update "$PIN" "$VENDOR" >/dev/null 2>"$req.err" || _dc=$?
  git -C "$T" worktree remove --force "$wt" 2>/dev/null
  if [ "$_dc" -ne 0 ]; then
    echo "ERRO: o commit durável do $VENDOR NÃO levou o framework inteiro (durable-commit rc=$_dc) — NADA foi mergeado." >&2
    sed 's/^/  /' "$req.err" >&2
    rm -f "$req" "$req.err"; return 12
  fi
  # PÓS-CONDIÇÃO na árvore COMMITADA (não no rc): todo arquivo transportado existe no $VENDOR.
  local _lost
  _lost="$(git -C "$T" ls-tree -r -z --name-only "$VENDOR" 2>/dev/null | LC_ALL=C sort -z \
           | LC_ALL=C comm -z -13 - "$req" | tr '\0' '\n')"
  rm -f "$req" "$req.err"
  if [ -n "$_lost" ]; then
    echo "ERRO: $(grep -c . <<< "$_lost") arquivo(s) do core@${sha:0:12} ausentes do $VENDOR depois do commit — NADA foi mergeado:" >&2
    printf '%s\n' "$_lost" | head -20 | sed 's/^/    /' >&2
    return 12
  fi

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

  # A vendor nova vai ao remoto ANTES do merge: push recusado ou conferência que falha param aqui, com a
  # integração intocada; re-rodar é seguro (a vendor já tem o commit, o durable-commit diz "nada novo").
  _rrc=0; _vendor_remote_push "$T" || _rrc=$?
  [ "${_rrc}" -eq 0 ] || return "${_rrc}"

  # Merge do onion/vendor na integração (3-way; base comum). Conflito = never-clobber estrutural.
  # ASSINATURA do adotante também no MERGE (2026-10-07): o durable-commit já assinava desde o #943, e
  # este commit, que é o do framework, seguia sem trailer — a sessão do adotante fazia amend à mão.
  # Vale o `attribution.commit` do settings.json DO ALVO; sem ele, sai sem assinatura (nunca inventa).
  local _sig="" _mmsg=(-m "chore(onion): atualizar o Onion para o pin ${PIN}")
  if [ -f "$T/.claude/settings.json" ] && command -v python3 >/dev/null 2>&1; then
    _sig="$(python3 -c 'import json,sys
try: print((json.load(open(sys.argv[1])).get("attribution") or {}).get("commit") or "")
except Exception: print("")' "$T/.claude/settings.json")"
  fi
  # A linha da sessão (2026-11-07) vai abaixo da assinatura, só quando conhecida (session-trailer.sh, que
  # nunca inventa; a nota de "sessão desconhecida" já saiu no início do update).
  # >>> D_CURE-session-trailer-merge (run_vendor_push_trailer_selftests remove ESTE bloco) >>>
  # A Claude-Session HERDADA da assinatura (de outra sessão) sai; a atual entra se conhecida.
  if [ -f "${HERE}/session-trailer.sh" ]; then
    _sig="$(grep -v '^Claude-Session:' <<< "${_sig}" || true)"
    [ -n "${_trailer}" ] && _sig="${_sig:+${_sig}$'\n'}${_trailer}"
  fi
  # <<< D_CURE-session-trailer-merge <<<
  [ -n "${_sig}" ] && _mmsg+=(-m "${_sig}")
  if git -C "$T" merge "$VENDOR" "${_mmsg[@]}" >/dev/null 2>&1; then
    echo "Onion: framework atualizado via merge limpo de $VENDOR (pin ${PIN})."
    return 0
  fi
  # Merge deixou conflito (ou nada a fazer). Distinga:
  local _conf; _conf="$(git -c core.quotePath=false -C "$T" diff --name-only --diff-filter=U 2>/dev/null)"
  if [ -n "${_conf}" ]; then
    # >>> D_CURE-projection-autoresolve (run_vendor_branch_selftests (g3-MUT) remove ESTE bloco) >>>
    _autoresolve_projections "$T" "${_conf}" "${_mmsg[@]}" && return 0
    # <<< D_CURE-projection-autoresolve <<<
    echo "Onion: CONFLITO no merge de $VENDOR — customização local vs framework novo (never-clobber estrutural)." >&2
    echo "  Resolva em $T: 'git mergetool' ou edite os marcadores; depois 'git commit'. Arquivos:" >&2
    printf '%s\n' "${_conf}" | sed 's/^/    /' >&2
    return 10
  fi
  # Sem conflito e merge não-zero → provavelmente nada a mergear (já atualizado).
  git -C "$T" merge --abort 2>/dev/null || true
  echo "Onion: nada a mergear (integração já em pin ${PIN})."
  return 0
}

case "${1:-}" in
  seed)   shift; [ "$#" -ge 2 ] || { echo "uso: vendor-branch.sh seed <TARGET> <INTEGRATION_BRANCH>" >&2; exit 2; }; _seed "$@" ;;
  # Expõe a normalização de URL que o consentimento usa, para ser MEDIDA pela bancada no helper real (rc 1 = recusada).
  --norm-remote) shift; _norm_remote "${1:-}" ;;
  update) shift; [ "$#" -ge 4 ] || { echo "uso: vendor-branch.sh update <TARGET> <SOURCE_ROOT> <PIN> <INTEGRATION_BRANCH>" >&2; exit 2; }; _update "$@" ;;
  *) echo "uso: vendor-branch.sh {seed|update|--norm-remote} ..." >&2; exit 2 ;;
esac
