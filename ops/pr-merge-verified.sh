#!/usr/bin/env bash
# Merge de PR que NÃO CONSEGUE declarar sucesso falso.
#
# ── POR QUE EXISTE (defeito medido, 2026-08-16) ─────────────────────────────────────────
# Eu escrevia, a cada PR, uma linha de merge seguida de `echo "MERGED <n>"`. No PR #618 o
# `gh pr merge` falhou (o PR estava CONFLICTING porque outro merge tocara o mesmo arquivo)
# e o `echo` imprimiu **MERGED** assim mesmo — porque estava ENCADEADO, não CONDICIONADO.
# Só não virou relato falso ao maestro porque eu reparei, de passagem, numa frase do `gh`
# ("add the --auto flag") que só aparece quando o merge não acontece. Sinal fraco lido por
# acaso é o oposto de verificação.
# Corrigir aquele script seria nota. O que reincide é o PADRÃO de escrever o cuidado à mão
# em cada sessão — então o cuidado vira ARTEFATO, e o caminho do merge passa a ser um só.
#
# ── O QUE ELE GARANTE (e a ordem importa) ───────────────────────────────────────────────
#  1. LÊ A FONTE do veredito de revisão — a linha `onion-review-verdict` — nunca o `pass`
#     do `onion-review`, que sai VERDE POR DESENHO quando o revisor falha (soft-pass).
#  2. Recusa se qualquer check falhou, ou se ainda há check pendente.
#  3. Confere o RC do `gh pr merge` (o defeito de origem).
#  4. PROVA INDEPENDENTE: relê o estado do PR na API; só declara sucesso se `state=MERGED`
#     e `mergedAt` não for nulo. O sucesso é afirmado pelo ESTADO, nunca pelo comando.
#
# Uso: bash ops/pr-merge-verified.sh <numero> [--repo owner/nome] [--keep-branch] [--sync]
#   --sync: após PROVAR o merge pelo estado, faz `git checkout main + pull --ff-only` — o sync
#           gated que substitui o `checkout main` encadeado à mão (que me deixou em main após um
#           merge recusado, 2026-08-26). Superação de sync-only-after-merge-succeeds, virada mecanismo.
#   --merge-commit: mergeia com `gh pr merge --merge` (merge commit) em vez de --rebase/--squash, com
#           os MESMOS gates (checks, veredito, dispensa, prova pelo estado). Para o PR de UPDATE de um
#           adotante: ele traz um merge real com `onion/vendor`, e rebase ou squash o linearizam — a
#           `onion/vendor` deixa de ser ancestral da main e o update seguinte acusa conflito espúrio
#           (medido 2026-10-08 num adotante: PR por rebase → conflito em lint-selftest.sh no update
#           seguinte; o PR que preservou a ancestralidade teve de ser mergeado à mão).
#   --assert-ancestor <ref>: depois do merge PROVADO, confere `merge-base --is-ancestor <ref>
#           origin/<base>`; se não for ancestral, sai rc=3 nomeando a ref (o merge aconteceu — o que
#           falhou foi a ancestralidade pedida). Use com --merge-commit: --assert-ancestor onion/vendor.
#   AUTO-REBASE (sem flag, 2026-10-08): PR CONFLICTING (que o GitHub não testa) é rebaseado sozinho
#           pelo `pr-finalize --rebase --push` na worktree local da branch, até ONION_MERGE_REBASE_MAX
#           (2) vezes; conflito de fonte para nomeado; sem worktree local, diz o comando e para. Depois
#           espera as runs do head novo nascerem e terminarem (ONION_MERGE_WAIT_SECS, 1800).
#   PROVENANCE DA BRANCH (sem flag, SAC-80, 2026-10-09): se o PR ADICIONA em `*.kg.yaml` um `source:`
#           com `@<sha>` de commit que NÃO é ancestral da base (commit da própria branch), o rebase o
#           reescreveria e a provenance ficaria fora da main. Sem --merge-commit, RECUSA antes do
#           merge nomeando sha e arquivo; com --merge-commit, mergeia e confere depois que cada sha
#           é ancestral de origin/<base> (rc 3 se não for, como o --assert-ancestor).
set -uo pipefail

PR="${1:?uso: $0 <numero-do-PR> [--repo owner/nome] [--keep-branch] [--dispensa <check> --motivo <texto>]}"; shift || true
REPO_ARG=()
DEL=(--delete-branch)
DO_SYNC=0   # --sync: o script faz `checkout main + pull`, mas SÓ dentro do ramo do merge PROVADO

# ── ESCAPE NOMEADO: dispensar UM check, com registro (2026-09-17) ────────────────────────
# O maestro autorizou mergear sem a revisão semântica quando o gate DETERMINÍSTICO está
# verde — "com o escape registrando qual check foi dispensado". O desenho abaixo existe para
# que isso NÃO vire override geral, que é como toda válvula dessas morre:
#   · só dispensa check que se DECLARA informativo (a lista abaixo, não qualquer nome);
#   · o check dispensado tem de estar de fato FALHANDO — dispensa preventiva é recusada;
#   · qualquer OUTRO check falho continua matando o merge;
#   · `--motivo` é obrigatório, e o registro vai para o PR (comentário) ANTES do merge —
#     se o registro falhar, o merge não acontece. Registro é precondição, não cortesia:
#     dispensa que só existe no terminal de quem mergeou é dispensa que ninguém audita.
# A lista é curta DE PROPÓSITO. Ampliá-la é ato deliberado, com o porquê escrito aqui.
#   onion-review-verdict → o critério de entrada MUDOU em 2026-09-20 e a justificativa antiga
#   caiu junto. Ele dizia de si "não bloqueia o merge — informa", e a dispensa se apoiava nessa
#   auto-declaração. Agora ele BLOQUEIA em dois casos distintos, e o escape cobre os dois por
#   razões diferentes:
#     (1) NÃO revisou (revisor morreu/sem saldo) — mergear sem revisão semântica é decisão
#         humana e deve ser consciente; o escape é a forma consciente dela.
#     (2) revisou e APONTOU violação — o revisor é LLM e erra. A saída para o falso-positivo
#         tem de ser dispensa NOMEADA E REGISTRADA, nunca gate mudo nem merge por fora.
#   Ou seja: a lista continua com um membro só, mas agora por um critério declarado aqui em vez
#   de herdado de uma frase que o próprio check deixou de dizer.
_DISPENSAVEIS=(onion-review-verdict)
DISPENSA=(); REASON=""; CI_INOPERANTE=0; CI_INOPERANTE_PROVADO=""
MERGE_COMMIT=0; ASSERT_ANCESTOR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO_ARG=(--repo "$2"); shift 2 ;;
    --dispensa) DISPENSA+=("${2:?--dispensa exige o NOME do check}"); shift 2 ;;
    --ci-inoperante) CI_INOPERANTE=1; shift ;;
    --motivo) REASON="${2:?--motivo exige texto}"; shift 2 ;;
    # BASE DE STACK: apagar a branch da base FECHA o PR filho (não re-aponta) — está
    # registrado como mecânica de stack desde 2026-07. Ao mergear uma base com PR
    # empilhado em cima, use --keep-branch; o GitHub re-aponta o filho, e a branch se
    # apaga à mão depois. Sem esta opção o mecanismo teria destruído um PR ao "acertar".
    --keep-branch) DEL=(); shift ;;
    --sync) DO_SYNC=1; shift ;;
    --merge-commit) MERGE_COMMIT=1; shift ;;
    --assert-ancestor) ASSERT_ANCESTOR="${2:?--assert-ancestor exige a ref (ex.: onion/vendor)}"; shift 2 ;;
    *) shift ;;
  esac
done

say() { printf '  %s\n' "$*"; }
die() { printf '✗ %s\n' "$*"; exit 1; }

_em() { # $1=agulha, resto=palheiro → 0 se presente
  local a="$1"; shift
  local x; for x in "$@"; do [ "$x" = "$a" ] && return 0; done; return 1
}
_dispensado() { [ "${#DISPENSA[@]}" -eq 0 ] && return 1; _em "$1" "${DISPENSA[@]}"; }



if [ "${#DISPENSA[@]}" -gt 0 ]; then
  [ -n "$REASON" ] || die "--dispensa exige --motivo: dispensa sem razão escrita é override, e override não se audita"
  for _d in "${DISPENSA[@]}"; do
    _em "$_d" "${_DISPENSAVEIS[@]}" \
      || die "check '${_d}' NÃO é dispensável — a lista é [${_DISPENSAVEIS[*]}], e só entra nela check que se declara informativo. Ampliar é ato deliberado: edite _DISPENSAVEIS com o porquê."
  done
fi

# 1+2 — checks e a FONTE do veredito
# ⚠️ `gh pr checks` sai NÃO-ZERO quando algum check FALHOU (e 8 quando há pendente) — não só
# quando não consegue ler. A v1 traduzia qualquer rc≠0 como "não consegui ler os checks", e
# no PR #623 isso ESCONDEU a verdade (o lint tinha reprovado): mensagem errada é diagnóstico
# errado, e mandou o autor procurar problema de acesso onde havia regressão. Agora a saída é
# capturada SEM matar o script, e quem decide é o conteúdo — não o código de saída do gh.
# ⚠️ ANCORAGEM NO HEAD (defeito medido no PR #634, 2026-08-19): entre um push novo e o GitHub
# REGISTRAR os checks dele há uma janela em que `gh pr checks` ainda mostra os checks do commit
# ANTERIOR — e o merge saiu 1 SEGUNDO depois de os runs novos nascerem, lendo verde velho. A cura:
# amarrar a leitura ao SHA do head e exigir que os check-runs DESSE SHA existam e estejam completos.
# (Sem check-run algum para o head = a janela da corrida → recusar e mandar esperar, nunca assumir.)
# ── ÂNCORA DE ESTADO (topo, antes de qualquer gate) ───────────────────────────────────
# Ler o estado DEPOIS de um `gh` que falhou só prova algo se soubermos que o PR não estava
# mergeado ANTES. Reprovada pelo Elenxo em 2026-09-07 na 1a versao: a leitura engolia o erro
# do `gh` e devolvia string vazia, nenhum `case` a barrava, e o ramo "mergeou mas a limpeza
# falhou" declarava sucesso para um merge de OUTRA PESSOA, feito dias antes. Cura: LER VAZIO
# E ERRO SAO A MESMA COISA AQUI — nao consigo saber, entao nao prossigo (fail-closed).
# Fica no TOPO porque a mensagem certa ("ja estava mergeado") tem de ser alcancavel; atras dos
# gates de check, um PR ja mergeado morria dizendo "check-run concluiu em falha", diagnostico errado.
pr_state() { gh pr view "$PR" "${REPO_ARG[@]}" --json state,mergedAt --jq '"\(.state)|\(.mergedAt)"' 2>/dev/null; }
state_before="$(pr_state)"
[ -z "$state_before" ] && die "não consegui LER o estado do PR #${PR} antes do merge (gh falhou/sem auth?) — não prossigo: sem a âncora, qualquer falha adiante viraria falso positivo"
case "$state_before" in
  MERGED\|*) die "PR #${PR} JÁ ESTAVA MERGED antes desta execução (mergedAt=${state_before#*|}) — não declaro merge que não foi meu" ;;
esac

HEAD_SHA="$(gh pr view "$PR" "${REPO_ARG[@]}" --json headRefOid --jq '.headRefOid' 2>/dev/null)"
[ -z "$HEAD_SHA" ] && die "não consegui ler o headRefOid do PR #${PR}"
OWNER_REPO="$(gh pr view "$PR" "${REPO_ARG[@]}" --json headRepository,headRepositoryOwner \
  --jq '.headRepositoryOwner.login + "/" + .headRepository.name' 2>/dev/null)"
HEAD_REF="$(gh pr view "$PR" "${REPO_ARG[@]}" --json headRefName --jq '.headRefName' 2>/dev/null)"
# ══ PROVENANCE QUE CITA A PRÓPRIA BRANCH × REBASE (SAC-80, 2026-10-09) ══════════════════════════
# Defeito medido num adotante (sinal 2026-10-08-rebase-merge-breaks-kg-provenance): o contrato do
# .kg.yaml pede `provenance.source: "<caminho>@<sha>"`, e este script mergeia por REBASE por padrão.
# O rebase reescreve os SHAs da branch; o grafo que citava um commit da própria branch entrou na main
# apontando para commit FORA da main — 6 provenance quebradas, com radar, lint e CI verdes.
# A guarda olha só o que o PR ADICIONA em `*.kg.yaml`, e só o VALOR de uma chave `source:` (em bloco,
# ou dentro de um mapa em fluxo `{…source: …}`): `@<hex>` em label/narrative/locator é prosa, não
# proveniência, e não dispara. O sha é classificado pelo GIT, nunca pela forma:
#   · não resolve como commit neste repo (outro repo da família, hex que não é sha, sha curto
#     ambíguo) → fora do escopo, contado e dito;
#   · resolve e É ancestral da base → nada a fazer (o rebase não o toca);
#   · resolve e NÃO é ancestral da base → é commit da branch: o rebase o tira da main.
# Sem --merge-commit, RECUSA antes de qualquer efeito (comentário, rebase, merge). Com --merge-commit,
# segue, e depois do merge PROVADO confere a ancestralidade de cada um (o mecanismo do --assert-ancestor).
# PR que não toca .kg.yaml não faz leitura nenhuma de git — o comportamento antigo fica intacto.
# Ler é fail-closed SÓ quando há .kg.yaml no PR: sem os commits locais não sei classificar, e não
# classificar seria deixar passar exatamente o caso que esta guarda existe para pegar.
KG_BRANCH_SHAS=""   # "sha<TAB>arquivo", um por linha
_kg_base=""
_kg_guard_pre() {
  local _slug="${OWNER_REPO:-}"; [ "${#REPO_ARG[@]}" -ge 2 ] && _slug="${REPO_ARG[1]}"
  local _files
  _files="$(gh api "repos/${_slug}/pulls/${PR}/files?per_page=100" --paginate --jq '.[].filename' 2>/dev/null)" \
    || die "não consegui LER os arquivos do PR #${PR} — sem eles não sei se o .kg.yaml cita commit da branch (SAC-80). Não prossigo."
  grep -qE '\.kg\.yaml$' <<< "${_files}" || return 0
  _kg_base="$(gh pr view "$PR" "${REPO_ARG[@]}" --json baseRefName --jq '.baseRefName' 2>/dev/null)"
  [ -n "${_kg_base}" ] || die "o PR #${PR} toca .kg.yaml e eu não li a base — não consigo checar a provenance (SAC-80). Não prossigo."
  git fetch -q origin "${_kg_base}" 2>/dev/null \
    || die "o PR #${PR} toca .kg.yaml e não consegui buscar origin/${_kg_base} — rode a partir de um clone deste repo (SAC-80). Não prossigo."
  local _base_sha; _base_sha="$(git rev-parse -q --verify 'FETCH_HEAD^{commit}' 2>/dev/null)"
  [ -n "${_base_sha}" ] || die "o PR #${PR} toca .kg.yaml e a base buscada não resolve como commit (SAC-80). Não prossigo."
  if ! git cat-file -e "${HEAD_SHA}^{commit}" 2>/dev/null; then
    git fetch -q origin "pull/${PR}/head" 2>/dev/null || { [ -n "${HEAD_REF}" ] && git fetch -q origin "${HEAD_REF}" 2>/dev/null; }
  fi
  git cat-file -e "${HEAD_SHA}^{commit}" 2>/dev/null \
    || die "o PR #${PR} toca .kg.yaml e não tenho o head ${HEAD_SHA:0:8} localmente — sem ele não sei se a provenance cita a branch (SAC-80). Rode a partir de um clone deste repo. Não prossigo."
  # flags canônicas: sem cor, sem textconv/diff externo da config pessoal ([[r56-sha-canonical-flags]])
  local _diff
  _diff="$(git -c core.quotepath=off diff --no-color --no-ext-diff --no-textconv --unified=0 \
           "${_base_sha}...${HEAD_SHA}" -- '*.kg.yaml' 2>/dev/null)" \
    || die "o PR #${PR} toca .kg.yaml e o git diff da base ao head falhou (SAC-80). Não prossigo."
  # arquivo<TAB>valor-do-source, das linhas ADICIONADAS. O valor é cortado no fim da string citada
  # (ou no `,`/`}`/` #` se não for citado): o `method:` ao lado, num mapa em fluxo, não entra.
  local _pairs
  _pairs="$(LC_ALL=C awk -v sq="'" '
    /^\+\+\+ /{ f=substr($0,5); sub(/^b\//,"",f); next }
    /^\+/ {
      l=substr($0,2)
      if (l ~ /^[ \t]*(-[ \t]+)?source:/ || l ~ /\{[^}]*source:/) {
        v=l; sub(/^[^{]*\{[^}]*source:|^[ \t]*(-[ \t]+)?source:/,"",v); sub(/^[ \t]+/,"",v)
        q=substr(v,1,1)
        if (q=="\"" || q==sq) { v=substr(v,2); i=index(v,q); if (i>0) v=substr(v,1,i-1) }
        else { sub(/[,}].*$/,"",v); sub(/[ \t]+#.*$/,"",v) }
        print f "\t" v
      }
    }' <<< "${_diff}")"
  local _f _v _sha _full _n_anc=0 _n_out=0 _seen=""
  while IFS=$'\t' read -r _f _v; do
    [ -n "${_f}" ] || continue
    for _sha in $(LC_ALL=C grep -oE '@[0-9a-f]{7,40}([^0-9A-Za-z_]|$)' <<< "${_v}" | LC_ALL=C grep -oE '[0-9a-f]{7,40}'); do
      case " ${_seen} " in *" ${_sha}|${_f} "*) continue ;; esac
      _seen="${_seen} ${_sha}|${_f}"
      _full="$(git rev-parse -q --verify "${_sha}^{commit}" 2>/dev/null)" || { _n_out=$((_n_out+1)); continue; }
      if git merge-base --is-ancestor "${_full}" "${_base_sha}" 2>/dev/null; then
        _n_anc=$((_n_anc+1))
      else
        KG_BRANCH_SHAS="${KG_BRANCH_SHAS}${_sha}"$'\t'"${_f}"$'\n'
      fi
    done
  done <<< "${_pairs}"
  [ "${_n_out}" -gt 0 ] && say "ℹ️  provenance: ${_n_out} @sha no .kg.yaml não resolve(m) como commit neste repo (outro repo, ou não é sha) — fora do escopo desta guarda"
  if [ -z "${KG_BRANCH_SHAS}" ]; then
    say "✓ provenance: .kg.yaml do PR com ${_n_anc} @sha ancestral(is) da base e nenhum commit da branch — o modo de merge não importa"
    return 0
  fi
  local _lst; _lst="$(printf '%s' "${KG_BRANCH_SHAS}" | awk -F'\t' 'NF{printf "%s%s em %s", (n++?"; ":""), $1, $2}')"
  if [ "${MERGE_COMMIT}" -ne 1 ]; then
    die "o .kg.yaml do PR cita commit da PRÓPRIA BRANCH em provenance.source (${_lst}) — o --rebase reescreveria esse SHA e a provenance ficaria fora da main (SAC-80). Nada foi mergeado. Rode de novo com --merge-commit, que preserva o SHA."
  fi
  say "✓ provenance cita commit da branch (${_lst}); --merge-commit preserva o SHA — confiro a ancestralidade depois do merge"
}
_kg_guard_post() { # depois do merge PROVADO: cada sha da branch tem de ser ancestral de origin/<base>
  [ -n "${KG_BRANCH_SHAS}" ] || return 0
  if ! git fetch -q origin "${_kg_base}" 2>/dev/null; then
    printf '✗ merge PROVADO, mas não consegui ler origin/%s para conferir a provenance da branch — NÃO afirmo que ela vale\n' "${_kg_base:-?}"; exit 3
  fi
  local _sha _f _bad=""
  while IFS=$'\t' read -r _sha _f; do
    [ -n "${_sha}" ] || continue
    git merge-base --is-ancestor "${_sha}" FETCH_HEAD 2>/dev/null || _bad="${_bad}${_bad:+; }${_sha} em ${_f}"
  done <<< "${KG_BRANCH_SHAS}"
  if [ -n "${_bad}" ]; then
    printf '✗ merge PROVADO, mas a provenance cita commit que NÃO é ancestral de origin/%s: %s — o PR entrou linearizado?\n' "${_kg_base}" "${_bad}"; exit 3
  fi
  say "✓ provenance: os commits da branch citados pelo .kg.yaml são ancestrais de origin/${_kg_base}"
}
_kg_guard_pre
# ══ AUTO-REBASE: PR em CONFLICTING não dispara CI ══════════════════════════════════════════════
# Defeito medido em 2026-10-07/08: 25 PRs, 33 commits de "projeções geradas regeneradas". Todo PR
# commita as projeções (backlog, testing-state, kg-read-index, plugins/), então cada merge deixa os
# PRs abertos CONFLICTING — e o GitHub NÃO dispara CI em PR em conflito. A espera ficava parada em
# "no checks reported" (#957 duas vezes, #959, #960, #975) até alguém rodar o rebase à mão. Desde o
# #973 o `pr-finalize --rebase --push` resolve com segurança o conflito SÓ de projeção (remonta
# plugins/ das fontes, regenera o resto) e RECUSA conflito de fonte. Aqui ele é DISPARADO sozinho:
#   · só na worktree LOCAL da branch do PR (achada por `git worktree list`), nunca às cegas: sem
#     worktree, digo o comando exato e paro (fail-loud — esperar em silêncio era o defeito);
#   · conflito de FONTE para com rc≠0 nomeando o arquivo — o rebase nunca esconde conflito real;
#   · LIMITE de tentativas (ONION_MERGE_REBASE_MAX, default 2): conflito que volta não vira laço;
#   · depois do rebase, as runs do head NOVO têm de NASCER e terminar (check presente, não só
#     "sem vermelho"), com prazo (ONION_MERGE_WAIT_SECS); prazo vencido = paro e digo.
# Leitura vazia de `mergeable` não é CONFLICTING: só o literal dispara; o resto segue os gates de sempre.
pr_mergeable() { gh pr view "$PR" "${REPO_ARG[@]}" --json mergeable --jq '.mergeable' 2>/dev/null; }
_wt_of_branch() { # $1=branch → caminho da worktree que a tem em checkout (vazio se nenhuma)
  git worktree list --porcelain 2>/dev/null \
    | awk -v b="branch refs/heads/$1" '/^worktree /{w=substr($0,10)} $0==b{print w; exit}'
}
_REBASE_MAX="${ONION_MERGE_REBASE_MAX:-2}"
_WAIT_SECS="${ONION_MERGE_WAIT_SECS:-1800}"
_POLL_SECS="${ONION_MERGE_POLL_SECS:-30}"
_mg="$(pr_mergeable)"
_n=0; while [ "$_mg" = UNKNOWN ] && [ "$_n" -lt 6 ]; do sleep "${_POLL_SECS}"; _mg="$(pr_mergeable)"; _n=$((_n+1)); done
_rebases=0
while [ "$_mg" = CONFLICTING ]; do
  _rebases=$((_rebases+1))
  [ "$_rebases" -le "$_REBASE_MAX" ] \
    || die "PR #${PR} segue CONFLICTING depois de ${_REBASE_MAX} rebase(s) automático(s) — algo volta a conflitar a cada vez; não entro em laço. Investigue a branch '${HEAD_REF}'."
  # SAC-80: o rebase da branch reescreveria os commits que o .kg.yaml cita — e aí nem o --merge-commit
  # os salva (a citação passa a apontar para o commit velho, órfão). Conflito assim se resolve à mão.
  [ -z "${KG_BRANCH_SHAS}" ] \
    || die "PR #${PR} está CONFLICTING e o .kg.yaml cita commit da própria branch ($(printf '%s' "${KG_BRANCH_SHAS}" | awk -F'\t' 'NF{printf "%s%s", (n++?" ":""), $1}')) — o auto-rebase reescreveria esses SHAs e a citação ficaria órfã (SAC-80). Resolva o conflito mergeando a base na branch, à mão, e rode de novo."
  _wt="$(_wt_of_branch "${HEAD_REF}")"
  [ -n "$_wt" ] \
    || die "PR #${PR} está CONFLICTING (o GitHub não dispara CI em PR em conflito) e a branch '${HEAD_REF}' não está em nenhuma worktree deste repo — não rebaseio às cegas. Rode na worktree da branch: bash ops/pr-finalize.sh --rebase --push ; depois rode este comando de novo."
  say "PR #${PR} CONFLICTING — auto-rebase ${_rebases}/${_REBASE_MAX} na worktree ${_wt} (pr-finalize --rebase --push)"
  _rb_out="$(cd "$_wt" && bash ops/pr-finalize.sh --rebase --push 2>&1)"; _rb_rc=$?
  if [ "$_rb_rc" -ne 0 ]; then
    _real="$(printf '%s\n' "$_rb_out" | grep -o 'conflito REAL em [^ ]*' | head -1)"
    die "auto-rebase RECUSADO (${_real:-rc=${_rb_rc}}) — conflito de FONTE não se resolve sozinho e não escondo conflito real; resolva à mão na worktree ${_wt}. pr-finalize disse: $(printf '%s\n' "$_rb_out" | tail -2 | tr '\n' ' ')"
  fi
  _new="$(git -C "$_wt" rev-parse HEAD 2>/dev/null)"
  HEAD_SHA="$(gh pr view "$PR" "${REPO_ARG[@]}" --json headRefOid --jq '.headRefOid' 2>/dev/null)"
  [ -n "$_new" ] && [ "$HEAD_SHA" != "$_new" ] \
    && die "depois do auto-rebase o head do PR (${HEAD_SHA:0:8}) não é o HEAD da worktree (${_new:0:8}) — a branch rebaseada não é a do PR; paro."
  _mg="$(pr_mergeable)"
  _n=0; while [ "$_mg" = UNKNOWN ] && [ "$_n" -lt 6 ]; do sleep "${_POLL_SECS}"; _mg="$(pr_mergeable)"; _n=$((_n+1)); done
done
if [ "$_rebases" -gt 0 ]; then
  say "auto-rebase feito — esperando as runs do head ${HEAD_SHA:0:8} NASCEREM e terminarem (prazo ${_WAIT_SECS}s)"
  _t0w="$(date +%s)"
  while :; do
    _runs="$(gh api "repos/${OWNER_REPO}/commits/${HEAD_SHA}/check-runs?per_page=100" \
      --jq '.check_runs[] | .name + "\t" + .status' 2>/dev/null)"
    if [ -n "$_runs" ] && printf '%s\n' "$_runs" | awk -F'\t' '$2!="completed"{exit 1}'; then break; fi
    [ $(( $(date +%s) - _t0w )) -ge "$_WAIT_SECS" ] \
      && die "as runs do head ${HEAD_SHA:0:8} não nasceram/terminaram em ${_WAIT_SECS}s depois do auto-rebase — rode este comando de novo quando o CI terminar."
    sleep "${_POLL_SECS}"
  done
fi
# ══ API DE CHECKS EM FALHA ≠ ZERO CHECK-RUNS ═════════════════════════════════════════════════
# Defeito medido em 2026-10-07 (sinal de um adotante): a API de check-runs do GitHub devolveu HTTP
# 500 para QUALQUER commit por ~7 minutos. Com `2>/dev/null` o erro virava saída vazia, e a saída
# vazia caía no ramo de ZERO check-runs, que mandava esperar os checks nascerem e oferecia o escape
# `--ci-inoperante`. A direção (não mergear) estava certa; o diagnóstico mandava esperar a coisa
# errada e apontava um escape que ali seria o erro. O rc do `gh api` é lido à parte, e o erro dele
# é dito pelo nome.
_cr_err="$(mktemp)"
head_runs="$(gh api "repos/${OWNER_REPO}/commits/${HEAD_SHA}/check-runs?per_page=100" \
  --jq '.check_runs[] | .name + "\t" + .status + "\t" + (.conclusion // "-")' 2>"${_cr_err}")"
_cr_rc=$?
if [ "${_cr_rc}" -ne 0 ]; then
  _cr_http="$(grep -oE 'HTTP [0-9]{3}' "${_cr_err}" | head -1)"
  _cr_msg="$(head -c 300 "${_cr_err}" | tr '\n' ' ')"
  rm -f "${_cr_err}"
  # 5xx é a API fora (esperar resolve); 4xx é a LEITURA recusada (repo/sha/credencial — esperar não resolve)
  case "${_cr_http}" in
    "HTTP 4"*) _cr_acao="a leitura foi RECUSADA — confira repo, head e credencial do gh; esperar não resolve" ;;
    *)         _cr_acao="tente de novo quando a API voltar" ;;
  esac
  die "API de checks indisponível (${_cr_http:-rc=${_cr_rc}}) ao ler os check-runs do head ${HEAD_SHA:0:8} — não é janela pós-push nem CI morto; NÃO use --ci-inoperante. ${_cr_acao}. gh disse: ${_cr_msg}"
fi
rm -f "${_cr_err}"
# ══ ZERO CHECK-RUNS: janela pós-push, ou CI MORTO? ═══════════════════════════════════════════
# A v1 tratava os dois casos como um só e mandava esperar. Em 2026-09-28 o segundo aconteceu: o CI
# do repositório entrou em `startup_failure` em TODAS as branches (inclusive main), com zero jobs
# criados e runs não re-executáveis. Os checks NUNCA iam nascer, e a mensagem "espere" virou uma
# instrução impossível de cumprir — o gate deixou de ser guarda e passou a ser impasse.
# O escape `--ci-inoperante` existe para esse caso e SÓ para ele. Ele não acredita em quem o invoca:
#   (1) PROVA a inoperância lendo o FORGE — os runs recentes do repo têm de ser `startup_failure`.
#       Se houver run bem-sucedido recente, é janela pós-push e o escape RECUSA (espere, como antes).
#       Se existirem check-runs para o head, o caso é `--dispensa` nome-a-nome, não este.
#   (2) RODA o gate determinístico local AQUI DENTRO — lint (0 HARD) e bancada (0 falhas). Não aceita
#       número que eu diga: mede. É a diferença entre cobertura declarada e cobertura exercida, e é
#       a razão de este escape não ser um `--force` com nome bonito.
#   (3) Exige `--motivo` e REGISTRA no PR antes do merge, dizendo que a cobertura é LOCAL e que a
#       semântica e o CI não foram medidos.
if [ -z "$head_runs" ]; then
  if [ "${CI_INOPERANTE:-0}" -ne 1 ]; then
    die "ZERO check-runs registrados para o head ${HEAD_SHA:0:8} — provável janela pós-push; espere os checks nascerem (a corrida do #634). Se o CI do repositório estiver MORTO (startup_failure repo-wide, checks que nunca nascem), use --ci-inoperante --motivo \"…\": ele PROVA a inoperância no forge e RODA o gate local antes de deixar passar."
  fi
  say "⚠️  ZERO check-runs no head — avaliando o escape --ci-inoperante (que PROVA antes de permitir)"

  # (1) PROVA DE INOPERÂNCIA, lida do forge — nunca da minha afirmação.
  # ⚠️ O PREDICADO LÊ A SEQUÊNCIA NO TOPO, NÃO A JANELA — e a 1ª versão errava justamente isso.
  # Ela contava `success` em qualquer lugar dos últimos 12 runs e recusava se houvesse algum. Medido
  # em 2026-09-28: havia 2, de 26/09 23:32 e 23:46 — os ÚLTIMOS VERDES ANTES da quebra, com os 7
  # `startup_failure` todos DEPOIS. Ou seja, a guarda leu história antiga como prova de CI vivo e
  # recusou pelo motivo errado. (Errou para o lado seguro, e ainda assim errou — que é exatamente o
  # que a casa diz sobre falso negativo: mais seguro que o inverso, e ainda engana.)
  # A pergunta certa é "a sequência MAIS RECENTE é de falha?". `gh run list` devolve do mais novo para
  # o mais velho, então a resposta é o comprimento da RAJADA inicial de `startup_failure`.
  _recentes="$(gh run list "${REPO_ARG[@]}" --limit 12 --json conclusion --jq '.[].conclusion' 2>/dev/null || true)"
  [ -n "${_recentes}" ] || die "--ci-inoperante: não consegui LER os runs recentes no forge — sem essa leitura eu não afirmo que o CI está morto. Recusa (fail-closed)."
  _streak="$(printf '%s\n' "${_recentes}" | awk '$0!="startup_failure"{exit} {n++} END{print n+0}')"
  _topo="$(printf '%s\n' "${_recentes}" | head -1)"
  say "    forge: rajada inicial de ${_streak} startup_failure (run mais recente: ${_topo})"
  [ "${_topo}" = "startup_failure" ] \
    || die "--ci-inoperante: o run MAIS RECENTE é '${_topo}', não startup_failure — o CI está respondendo. Se os checks deste head só estão atrasados, espere; o escape não cobre impaciência."
  [ "${_streak}" -ge 3 ] \
    || die "--ci-inoperante: rajada de apenas ${_streak} startup_failure no topo (esperado >= 3). Uma ou duas falhas de startup podem ser transitórias — o escape exige padrão, não episódio."

  # (2) O GATE LOCAL É EXERCIDO AQUI, não citado. Sem isto o escape seria um --force com nome bonito.
  say "    rodando o gate determinístico LOCAL (é ele que substitui o CI; não aceito número citado)"
  _lint_out="$(LC_ALL=C bash "${REPO_ROOT:-$(git rev-parse --show-toplevel)}/.claude/validation/lint-artifacts.sh" 2>&1)"; _lint_rc=$?
  printf '%s\n' "${_lint_out}" | grep -qF 'MORREU' \
    && die "--ci-inoperante: o lint MORREU antes do sumário — não pude julgar, logo não libero."
  [ "${_lint_rc}" -eq 0 ] \
    || die "--ci-inoperante: lint local rc=${_lint_rc} (há HARD). A cobertura que substituiria o CI está VERMELHA — recusa. $(printf '%s\n' "${_lint_out}" | grep -m1 'Violações HARD')"
  _bench_out="$(LC_ALL=C bash "${REPO_ROOT:-$(git rev-parse --show-toplevel)}/.claude/validation/lint-selftest.sh" --jobs auto 2>&1)"; _bench_rc=$?
  printf '%s\n' "${_bench_out}" | grep -qF 'ABORTOU' \
    && die "--ci-inoperante: a bancada ABORTOU antes da soma — o verde parcial não vale. Recusa."
  [ "${_bench_rc}" -eq 0 ] \
    || die "--ci-inoperante: bancada local rc=${_bench_rc}. $(printf '%s\n' "${_bench_out}" | grep -m1 'Falharam')"
  # ⚠️ ÂNCORA NO SUMÁRIO, NÃO NA PRIMEIRA OCORRÊNCIA DA PALAVRA. A 1ª versão era
  # `awk '/Passaram/{print $3; exit}'` e casou o NOME DE UM CASO — existe um caso chamado
  # `selftest-lanes: (h) --jobs 2 agrega 2 workers ⇒ Passaram 2, exit 0`, que aparece na linha 61 de
  # uma corrida de 1516 linhas. O `exit` garantiu que o sumário real (linha 1516) nunca fosse lido, e
  # o registro do PR #881 saiu com `bancada (h) casos`. O VEREDITO estava certo (veio do rc), o
  # NÚMERO do rastro de auditoria estava errado — e rastro com número errado é a classe que este
  # script existe para combater. Ancorado na FORMA do sumário (`Passaram : <n>` no início da linha,
  # com dois-pontos) e tomando a ÚLTIMA ocorrência, que é a agregada.
  _bench_pass="$(printf '%s\n' "${_bench_out}" | awk '/^[[:space:]]*Passaram[[:space:]]*:[[:space:]]*[0-9]+[[:space:]]*$/{v=$3} END{print v}')"
  printf '%s' "${_bench_pass}" | grep -qE '^[0-9]+$' \
    || die "--ci-inoperante: não consegui LER a contagem da bancada do sumário (li '${_bench_pass}'). O veredito seria correto pelo rc, mas eu não registro no PR um número que não sei — e registro sem número não audita. Recusa."
  say "    ✓ gate local EXERCIDO: lint 0 HARD · bancada ${_bench_pass:-?} casos, 0 falhas"
  CI_INOPERANTE_PROVADO="rajada de ${_streak} startup_failure no topo do forge · lint 0 HARD · bancada ${_bench_pass:-?} casos/0 falhas"
else
printf '%s\n' "$head_runs" | awk -F'\t' '$2!="completed"{exit 1}' \
  || die "check-run do head ${HEAD_SHA:0:8} ainda não-completo — merge recusado (esperar não é opcional)"
fi
# Falhos do head, um por linha — e a dispensa é aplicada NOME A NOME, nunca em bloco.
_falhos="$(printf '%s\n' "$head_runs" | awk -F'\t' '$3=="failure"||$3=="cancelled"||$3=="timed_out"{print $1}')"
_not_waived=""
while IFS= read -r _f; do
  [ -n "$_f" ] || continue
  _dispensado "$_f" || _not_waived="${_not_waived}${_f} "
done <<< "$_falhos"
[ -n "${_not_waived// /}" ] \
  && die "check-run do head ${HEAD_SHA:0:8} concluiu em falha e NÃO foi dispensado: ${_not_waived}— merge recusado"
# Dispensa PREVENTIVA é recusada: só se dispensa o que de fato está falhando agora.
for _d in "${DISPENSA[@]:-}"; do
  [ -n "$_d" ] || continue
  printf '%s\n' "$_falhos" | grep -qxF "$_d" \
    || die "'--dispensa ${_d}' recusada: esse check NÃO está falhando no head ${HEAD_SHA:0:8}. Dispensa preventiva é cheque em branco para a próxima vez que ele falhar."
done
if [ "${#DISPENSA[@]}" -gt 0 ]; then
  say "⚠️  check(s) DISPENSADO(S) por decisão humana: ${DISPENSA[*]}"
  say "    motivo: ${REASON}"
else
  say "✓ check-runs ancorados no head ${HEAD_SHA:0:8}: todos completos, nenhum falho"
fi

checks="$(gh pr checks "$PR" "${REPO_ARG[@]}" 2>&1)"
GHRC=$?
[ -z "$checks" ] && die "não consegui ler os checks do PR #${PR} (saída vazia, rc=${GHRC})"
printf '%s\n' "$checks" | sed 's/^/  /'
printf '%s\n' "$checks" | awk '{print $2}' | grep -q pending && die "há check PENDENTE — merge recusado (esperar não é opcional)"
# mesma leitura pelo 2º ângulo (`gh pr checks`), com a MESMA dispensa nome-a-nome
_f2="$(printf '%s\n' "$checks" | awk '$2=="fail"{print $1}')"
_n2=""
while IFS= read -r _f; do
  [ -n "$_f" ] || continue
  _dispensado "$_f" || _n2="${_n2}${_f} "
done <<< "$_f2"
[ -n "${_n2// /}" ] && die "há check FALHO não dispensado: ${_n2}— merge recusado"

verdict="$(gh pr view "$PR" "${REPO_ARG[@]}" --json statusCheckRollup \
  --jq '.statusCheckRollup[] | select(.name=="onion-review-verdict") | (.conclusion // .state)' 2>/dev/null)"
if [ -z "$verdict" ]; then
  say "⚠️  sem linha 'onion-review-verdict' neste repo — a revisão adversarial NÃO foi medida aqui."
  say "    (repos sem o gate: o resíduo da REGRA 56 e a passada humana são a única cobertura)"
elif [ "$verdict" != "SUCCESS" ] && _dispensado onion-review-verdict; then
  say "⚠️  onion-review-verdict = ${verdict} — DISPENSADO por decisão humana, não aprovado."
  say "    O gate determinístico (lint + bancada) é a cobertura que sobra; a semântica NÃO foi medida."
elif [ "$verdict" != "SUCCESS" ]; then
  die "onion-review-verdict = ${verdict} — o revisor NÃO aprovou (o 'pass' do onion-review é soft e não vale)"
else
  say "✓ onion-review-verdict = SUCCESS (fonte lida, não inferida)"
fi

# 3 — o RC do merge, que é o defeito de origem
# ESTRATÉGIA COM FALLBACK (defeito medido 2026-08-21, PR #645): --rebase falha em stack
# RE-APONTADA ("This branch can't be rebased") — o topo, cujo GitHub re-apontou p/ main após
# o merge da base. O helper conhece a stack (--keep-branch) mas cravava --rebase e recusava um
# merge legítimo (4/4 verdes, CLEAN). Agora: tenta --rebase; se a saída disser "can't be
# rebased", degrada p/ --squash com os MESMOS gates já validados (checks+veredito lidos acima).
# NÃO afrouxa nada: o squash só muda como o histórico entra, não SE os gates passaram.
# t0 — instante ANTES do merge. A âncora cobre só o "antes"; a janela âncora→merge é onde a
# corrida vive (outra pessoa, --auto, merge queue). Um mergedAt ANTERIOR a t0 nao pode ser deste
# run. Tolerancia de 300s para desvio de relogio entre esta maquina e o GitHub — e se a data nao
# for parseavel, FAIL-CLOSED (nao declaro o que nao consigo datar).
# ── REGISTRO DA DISPENSA — PRECONDIÇÃO DO MERGE, não cortesia ────────────────────────────
# A dispensa vive no PR, onde qualquer um a lê depois, e não no terminal de quem mergeou. Se o
# comentário não for postado, o merge NÃO acontece: uma dispensa que ninguém consegue auditar é
# indistinguível de um merge por fora do gate — que é exatamente o que este escape existe para
# evitar. O comentário nomeia O CHECK, o MOTIVO e o HEAD, porque "dispensei um check" sem dizer
# qual é a mesma classe de declaração vazia que este script inteiro combate.
# ── REGISTRO DO ESCAPE DE CI MORTO — mesma precondição do --dispensa, e pelo mesmo motivo ───────
# Um merge sem CI que não deixe rastro no PR é indistinguível de um merge por fora do gate. Aqui o
# registro carrega o que foi PROVADO (a leitura do forge) e o que foi EXERCIDO (o gate local), mais o
# que continua NÃO MEDIDO — o CI e a semântica. O corpo é CONTADO antes de postar, como no --dispensa:
# um `gh pr comment` bem-sucedido com corpo vazio é o modo-de-falha que custou o registro do #874.
if [ "${CI_INOPERANTE:-0}" -eq 1 ]; then
  [ -n "$(printf '%s' "${REASON}" | tr -d '[:space:]')" ] \
    || die "--ci-inoperante exige --motivo com conteúdo — merge sem CI e sem justificativa escrita não se audita."
  _reg_ci="$(printf '%s\n' \
    "## ⚠️ Merge SEM CI — escape \`--ci-inoperante\`" \
    "" \
    "O CI do repositório está inoperante e este merge passou por um escape **nomeado**, que" \
    "**provou** a inoperância e **exerceu** a cobertura local antes de permitir." \
    "" \
    "| | |" \
    "|---|---|" \
    "| head | \`${HEAD_SHA}\`" \
    "| provado no forge + exercido localmente | ${CI_INOPERANTE_PROVADO:-<não registrado>} |" \
    "| motivo | ${REASON} |" \
    "" \
    "**O que NÃO foi medido:** o CI (está morto) e a revisão semântica. A cobertura deste merge é o" \
    "gate determinístico rodado nesta máquina — lint sem HARD e bancada sem falhas, ambos executados" \
    "pelo próprio script, não citados por quem mergeou." )"
  for _ex in "Merge SEM CI" "${REASON}"; do
    grep -qF -- "${_ex}" <<< "${_reg_ci}" \
      || die "o corpo do registro de CI-inoperante saiu INCOMPLETO (falta: ${_ex}) — merge abortado antes de postar."
  done
  gh pr comment "$PR" "${REPO_ARG[@]}" --body "$_reg_ci" >/dev/null 2>&1 \
    || die "não consegui REGISTRAR o escape de CI-inoperante no PR #${PR} — merge abortado. O registro é precondição."
  say "✓ escape de CI-inoperante registrado no PR #${PR}, antes do merge"
fi

if [ "${#DISPENSA[@]}" -gt 0 ]; then
  # A NOTA DE AUDITORIA NAO PODE AFIRMAR O QUE NAO MEDIU. Ate 2026-09-20 ela dizia, fixa, "o que
  # este check mediria NAO foi medido" — verdade enquanto o `onion-review-verdict` so reprovava
  # por ausencia de revisao. Com o gate de achados, existe o caso oposto: ele MEDIU e ACHOU, e
  # ali a frase antiga registraria mentira no rastro de auditoria. Achado por passada adversarial.
  # Deriva-se do `output` do proprio check; se nao der para ler, DECLARA que nao deu — nunca
  # escolhe um dos dois lados por conveniencia.
  _out_check="$(gh api "repos/${OWNER_REPO}/commits/${HEAD_SHA}/check-runs?per_page=100" \
    --jq '.check_runs[] | select(.name=="onion-review-verdict") | ((.output.title // "") + " " + (.output.summary // ""))' 2>/dev/null || true)"
  if LC_ALL=C grep -qiE 'apontou[^0-9]*[0-9]+|violaç|violac' <<< "${_out_check}"; then
    _NOTA_DISPENSA="Este check **mediu e apontou** — a dispensa afirma que o achado **não procede**, e o parecer está no comentário do PR para quem quiser conferir."
  elif [ -n "${_out_check}" ]; then
    _NOTA_DISPENSA="O que este check mediria **não foi medido**."
  else
    _NOTA_DISPENSA="Não consegui ler o \`output\` do check para dizer se ele mediu ou não — **a nota não afirma nenhum dos dois**; leia o check no PR."
  fi
  _reg="$(printf '%s\n' \
    "## ⚠️ Merge com check DISPENSADO" \
    "" \
    "Este PR foi mergeado por \`ops/pr-merge-verified.sh\` com dispensa **nomeada** de check." \
    "" \
    "| | |" \
    "|---|---|" \
    "| check(s) dispensado(s) | \`${DISPENSA[*]}\` |" \
    "| motivo | ${REASON} |" \
    "| head | \`${HEAD_SHA}\` |" \
    "" \
    "Os demais checks do head passaram — a dispensa é **nome a nome**, e qualquer outro check falho teria recusado o merge. ${_NOTA_DISPENSA}" )"
  # ── O CORPO É CONTADO, NUNCA PRESUMIDO (defeito medido 2026-09-25, PR #874) ────────────
  # A v1 montava o corpo com `printf '%s\n' \\` — dois contra-barras. O primeiro escapava o
  # segundo, então o `printf` recebia UM argumento (o contra-barra literal) e a linha TERMINAVA
  # ali; as linhas seguintes viraram um comando novo, que o bash tentou EXECUTAR
  # (`## ⚠️ Merge com check DISPENSADO: command not found`). Resultado: o `gh pr comment`
  # postou `\` e saiu 0 — o `die` nunca disparou, o script disse "✓ dispensa registrada", e o
  # registro que ele mesmo chama de *precondição de auditoria* não registrou NADA.
  # É a classe que mais mordeu esta casa: o rc do comando é DECLARAÇÃO sobre si; verificar é
  # CONTAR o que ele produziu. Então: o corpo tem de conter o cabeçalho, o nome de cada check
  # dispensado e o motivo — senão não se posta, e não se mergeia.
  # ⚠️ DUAS CORREÇÕES DE UMA PASSADA ADVERSARIAL, ambas medidas (2026-09-25):
  #
  # (i) NADA DE `printf | grep -q` AQUI. Sob `pipefail`, `grep -q` casa no começo e SAI; o `printf`
  #     morre com SIGPIPE e o pipeline devolve 141, que esta guarda leria como "corpo INCOMPLETO" —
  #     recusando um corpo que CONTÉM o termo. Medido com um `--motivo` de 70 KB: 10 de 12 execuções
  #     falharam espuriamente (`rc=141`, `contem=SIM`). É a classe já curada em 489 sítios desta casa
  #     ([[pipefail-epipe-early-closer-class]]), reintroduzida por mim no gate de MERGE — e eu não
  #     tinha caso de bancada nesse tamanho. `<<<` não tem escritor para morrer.
  #
  # (ii) O MOTIVO TEM DE TER CONTEÚDO. `--motivo ""` já era barrado no parse, mas `--motivo " "`
  #      passava, e aí `grep -qF -- " "` casa com qualquer corpo: o elemento que existe para garantir
  #      que a dispensa diga POR QUÊ media zero. Registro cuja justificativa é um espaço não se audita
  #      melhor do que registro nenhum.
  if [ -z "$(printf '%s' "${REASON}" | tr -d '[:space:]')" ]; then
    die "--motivo está em branco (só espaços) — merge abortado. A dispensa precisa dizer POR QUÊ; um motivo vazio faz a própria verificação do registro passar a medir nada."
  fi
  for _exigido in "## ⚠️ Merge com check DISPENSADO" "${DISPENSA[*]}" "${REASON}"; do
    grep -qF -- "$_exigido" <<< "$_reg" \
      || die "o corpo do registro de dispensa saiu INCOMPLETO (falta: ${_exigido}) — merge abortado antes de postar. Registro que não carrega o motivo não se audita, e um \`gh pr comment\` bem-sucedido com corpo vazio é o modo-de-falha que este check existe para barrar."
  done
  gh pr comment "$PR" "${REPO_ARG[@]}" --body "$_reg" >/dev/null 2>&1 \
    || die "não consegui REGISTRAR a dispensa no PR #${PR} — merge abortado. O registro é precondição: dispensa que só existe no meu terminal não se audita."
  say "✓ dispensa registrada no PR #${PR} (comentário), antes do merge"
fi

# ── MERGE INTERNO NA BRANCH × MODO DE MERGE (SAC-76, 2026-10-08) ─────────────────────────────────
# Rebase e squash linearizam um merge que a branch do PR carrega. Quando esse merge É o conteúdo (o
# PR de update de um adotante, que mergeia `onion/vendor`), linearizar destrói a ancestralidade e o
# próximo update conflita em falso. Sem --merge-commit, AVISO — nunca troco o modo em silêncio: uma
# branch com main mergeada por cima (stack, "update branch") também tem merge interno e pode querer
# rebase. Os pais são lidos do FORGE; se a leitura falhar, digo que não sei, e não aviso nada falso.
if [ "${MERGE_COMMIT}" -eq 0 ]; then
  _slug="${OWNER_REPO:-}"; [ "${#REPO_ARG[@]}" -ge 2 ] && _slug="${REPO_ARG[1]}"
  if [ -n "${_slug}" ] && _pais="$(gh api "repos/${_slug}/pulls/${PR}/commits?per_page=100" --jq '.[] | (.parents | length)' 2>/dev/null)"; then
    if grep -qx '[2-9]' <<< "${_pais}"; then
      say "⚠️  a branch do PR carrega commit de MERGE, e este run vai linearizar (--rebase/--squash)."
      say "⚠️  se o merge é o conteúdo (ex.: PR de update de adotante com onion/vendor), interrompa e"
      say "⚠️  rode de novo com --merge-commit — senão a ancestralidade se perde e o próximo update conflita."
    fi
  else
    say "ℹ️  não li os pais dos commits do PR — não sei se a branch carrega merge interno (aviso desligado)."
  fi
fi

t0="$(date -u +%s)"
if [ "${MERGE_COMMIT}" -eq 1 ]; then
  say "modo: --merge-commit (gh pr merge --merge) — mesmos gates, só muda como o histórico entra"
  merge_out="$(gh pr merge "$PR" "${REPO_ARG[@]}" --merge "${DEL[@]}" 2>&1)"; rc=$?
else
  merge_out="$(gh pr merge "$PR" "${REPO_ARG[@]}" --rebase "${DEL[@]}" 2>&1)"; rc=$?
fi
if [ "$rc" -ne 0 ] && [ "${MERGE_COMMIT}" -eq 0 ]; then
  if printf '%s' "$merge_out" | grep -qi "can't be rebased\|cannot be rebased"; then
    say "⚠️  --rebase recusado (stack re-apontada); degradando p/ --squash com os mesmos gates"
    merge_out="$(gh pr merge "$PR" "${REPO_ARG[@]}" --squash "${DEL[@]}" 2>&1)"; rc=$?
  fi
fi
# ── rc != 0 NÃO É, SOZINHO, "não mergeou" (defeito medido 2026-09-07, PR #814) ─────────
# A v1 morria aqui e NUNCA chegava ao passo 4 — a prova pelo ESTADO. Resultado: no merge do
# #814 o `gh` mergeou, apagou a branch e SÓ ENTÃO falhou (`could not determine current branch`,
# HEAD destacado); o script declarou "NÃO declaro merge" para um merge que aconteceu. Falso
# NEGATIVO é mais seguro que o inverso, mas ainda engana: a sessão seguinte tenta re-mergear.
# A cura é a própria filosofia do script — o sucesso é afirmado pelo ESTADO, nunca pelo comando;
# então o FRACASSO também não pode ser afirmado pelo comando sem consultar o estado.
# Isto NÃO afrouxa a guarda: só um estado MERGED **que não existia antes** conta como sucesso,
# e o passo 4 continua sendo quem declara. O que muda é a via do meio, que faltava:
#   não mergeou → die  ·  mergeou e limpou → sucesso  ·  mergeou, limpeza falhou → sucesso + aviso
if [ "$rc" -ne 0 ]; then
  state_after="$(pr_state)"
  # Vazio NAO e "nao mergeou": e "nao consegui ler". Direcao segura e a mesma (die), mas a
  # MENSAGEM tem de dizer qual das duas — afirmar estado='' e inventar um estado que ninguem leu,
  # que e a reincidencia do defeito do #623 documentado acima, so que com o sinal invertido.
  [ -z "$state_after" ] && die "gh pr merge saiu com rc=${rc} e eu NÃO CONSEGUI LER o estado do PR depois (gh falhou?) — não declaro nem merge nem não-merge. Saída do gh: $(printf '%s' "$merge_out" | tail -1)"
  # O `gh` dizendo que o PR JÁ estava mergeado nunca pode virar sucesso deste run — barra antes
  # de qualquer aritmética de data, e sem depender de relógio nenhum.
  if printf '%s' "$merge_out" | grep -qi "already been merged\|not mergeable"; then
    die "gh pr merge saiu com rc=${rc} dizendo que o PR já estava mergeado/não-mergeável — o merge NÃO foi deste run. Saída: $(printf '%s' "$merge_out" | tail -1)"
  fi
  case "$state_after" in
    MERGED\|null|MERGED\|"")
      die "gh pr merge saiu com rc=${rc} e o estado diz MERGED com mergedAt nulo — inconsistente, não declaro. Saída: $(printf '%s' "$merge_out" | tail -1)" ;;
    MERGED\|*)
      _ma="${state_after#*|}"
      _mts="$(date -u -d "${_ma}" +%s 2>/dev/null || true)"
      [ -z "${_mts}" ] && die "o PR está MERGED (mergedAt=${_ma}) mas não consegui DATAR esse carimbo — não atribuo a este run sem poder compará-lo com t0"
      if [ "${_mts}" -lt $(( t0 - 300 )) ]; then
        die "o PR está MERGED, mas mergedAt=${_ma} é ANTERIOR ao início deste merge — o merge foi de outra execução/pessoa (corrida ou --auto). NÃO declaro merge que não foi meu"
      fi
      say "⚠️  o \`gh pr merge\` saiu com rc=${rc}, MAS o merge ACONTECEU (mergedAt=${_ma}, posterior a t0)."
      say "⚠️  o que falhou foi um passo PÓS-merge (tipicamente apagar a branch — exige branch atual)."
      say "⚠️  saída do gh: $(printf '%s' "$merge_out" | tail -1)"
      if [ -n "${HEAD_REF}" ]; then
        if git ls-remote --exit-code origin "refs/heads/${HEAD_REF}" >/dev/null 2>&1; then
          say "⚠️  a branch remota SOBROU. Apague com:  git push origin --delete ${HEAD_REF}"
        else
          say "✓  a branch remota ${HEAD_REF} já não existe — nada a limpar."
        fi
      else
        say "⚠️  não li o headRefName; confira a branch remota à mão: git ls-remote origin"
      fi
      ;;
    *)
      die "gh pr merge saiu com rc=${rc} e o PR NÃO está MERGED (estado lido='${state_after%%|*}') — NÃO declaro merge (foi assim que o #618 'mergeou' sem mergear). Saída: $(printf '%s' "$merge_out" | tail -1)" ;;
  esac
fi

# 4 — prova independente: o ESTADO, não o comando
state="$(pr_state)"
# ASSIMETRIA CURADA (Elenxo 2026-09-07, risco 6): o bloco de rc!=0 acima matava em `MERGED|""`
# (mergedAt string VAZIA) e este aqui não tinha o padrão — `MERGED|` cairia em `MERGED|*` e
# declararia SUCESSO com mergedAt vazio. Apertar um lado e deixar o outro frouxo é como o
# defeito volta pela porta que ninguém olhou. E estado ILEGÍVEL (gh mudo) não é "não mergeou":
# é "não sei", e aqui isso também tem de matar, com a mensagem dizendo qual dos dois.
[ -z "$state" ] && die "o merge retornou 0 mas eu NÃO CONSEGUI LER o estado do PR (gh falhou?) — não declaro o que não li"
case "$state" in
  MERGED\|null|MERGED\|)
    die "estado diz MERGED mas mergedAt é nulo/vazio — inconsistente, não declaro" ;;
  MERGED\|*)
    printf '✓ PR #%s MERGED — provado pelo ESTADO (mergedAt=%s)\n' "$PR" "${state#*|}"
    # ANCESTRALIDADE PEDIDA (--assert-ancestor): o merge está provado; aqui confiro o que o modo de
    # merge prometia. Falha = rc 3 (distinto do 1 de "não mergeou"), nomeando a ref e a base.
    if [ -n "${ASSERT_ANCESTOR}" ]; then
      _base="$(gh pr view "$PR" "${REPO_ARG[@]}" --json baseRefName --jq '.baseRefName' 2>/dev/null)"
      if [ -z "${_base}" ] || ! git fetch -q origin "${_base}" 2>/dev/null; then
        printf '✗ merge PROVADO, mas não consegui ler a base (%s) para conferir a ancestralidade de %s — NÃO afirmo que ela vale\n' "${_base:-?}" "${ASSERT_ANCESTOR}"; exit 3
      fi
      if git merge-base --is-ancestor "${ASSERT_ANCESTOR}" FETCH_HEAD 2>/dev/null; then
        say "✓ ${ASSERT_ANCESTOR} é ancestral de origin/${_base} — a ancestralidade se manteve"
      else
        printf '✗ merge PROVADO, mas %s NÃO é ancestral de origin/%s — o próximo update vai conflitar em falso (o PR entrou linearizado?)\n' "${ASSERT_ANCESTOR}" "${_base}"; exit 3
      fi
    fi
    _kg_guard_post
    # SUPERAÇÃO (2026-08-26): o sync de main vive AQUI DENTRO — estruturalmente inacessível
    # sem o merge provado pelo estado. Cura o erro que me deixou em main após um merge RECUSADO
    # (o `checkout main` encadeado, não condicionado). Agora "não consigo" repetir, nem esquecendo.
    #
    # MAS NÃO MATA (Elenxo 2026-09-07, risco 5): o `die` aqui fazia o script sair rc=1 DEPOIS do
    # `✓ MERGED` — e `git checkout main` falha quando `main` está tomada por OUTRO worktree, que é
    # exatamente a família de cenário que gerou o #814. Um rc≠0 após um merge PROVADO é o falso
    # negativo que este PR inteiro existe para matar; reintroduzi-lo pelo sync seria circular.
    # O rc deste script responde pelo MERGE, que é o trabalho dele; sincronizar `main` é cortesia.
    if [ "${DO_SYNC:-0}" = 1 ]; then
      say "sync: merge provado — checkout main + pull"
      if git checkout main -q && git pull --ff-only origin main -q; then
        say "main sincronizada: $(git rev-parse --short HEAD)"
      else
        say "⚠️  o merge está PROVADO, mas o sync de main falhou (main tomada por outro worktree?)."
        say "⚠️  isto NÃO invalida o merge e NÃO muda o rc. Sincronize à mão quando puder:"
        say "⚠️     git checkout main && git pull --ff-only origin main"
      fi
    fi
    ;;
  *)            die "o merge retornou 0 mas o estado do PR é '${state%%|*}' — declaração ≠ verificação" ;;
esac
