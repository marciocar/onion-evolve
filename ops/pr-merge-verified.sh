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
#  3. Confere o RC do `gh pr merge` (o defeito de origem). O merge vai SEMPRE amarrado ao head
#     julgado (`--match-head-commit`, 2026-10-27): push que cai entre o julgamento e o merge faz o
#     forge recusar, e a recusa sai nomeada ("o head mudou depois do julgamento (X → Y)").
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
#           REPO ALHEIO (2026-10-25): worktree da branch SEM ops/pr-finalize.sh (adotante chamando com --repo)
#           ⇒ rebase próprio: só docs/backlog.md e docs/onion/kg-read-index.tsv se resolvem, pelo gerador do
#           alvo; outro conflito aborta com a branch intacta; lint do alvo antes do push --force-with-lease.
#           E avisa (sem bloquear) quando outro PR aberto toca a mesma projeção: serialize.
#           RASTRO NO PR (H5 de D_MERGE_PROCESS_ONION_2026_10, 2026-10-13): cada auto-rebase — o que
#           deu certo e o recusado por conflito de fonte — deixa um COMENTÁRIO no PR com head antigo →
#           novo, a causa (projeção gerada ou fonte) e a tentativa N/MAX. Antes eram ≥14 rebases
#           invisíveis. Comentário que falha vira AVISO nomeado (o rebase já aconteceu; calar é o defeito).
#   --no-wait-after-rebase: depois de UM auto-rebase bem-sucedido, sai rc=4 SEM esperar o CI do head
#           novo. É o modo do `ops/merge-serial.sh` (core-only): ele segura o lock só no rebase e no merge e
#           espera o CI FORA do lock. ONION_MERGE_REBASE_DONE=<n> diz quantos rebases já houve na série
#           (o limite ONION_MERGE_REBASE_MAX vale para a série inteira, não por chamada).
#   MERGE SEM O CI DO HEAD NOVO (sem flag, D_MERGE_SEM_CI_APOS_REBASE_LIMPO, 2026-10-13, "A agora, B se
#           precisar"): depois de um auto-rebase LIMPO, o merge NÃO espera o CI do head novo quando TODAS
#           as condições valem — (1) sem --wait-ci-after-rebase; (2) a worktree estava no head que o PR
#           mostrava (nada de verde de um head que não é o rebaseado: force-push no meio); (3) nenhum
#           alarme de main quebrado aberto; (4) no head ANTERIOR, os checks exigidos pelo ruleset
#           (ops/github-ruleset-main.json) verdes e nenhum outro falho não dispensado; (5) o que a main
#           trouxe entre o merge-base velho e o novo não toca arquivo do PR (projeção gerada fora da
#           conta: é ela que conflita, e o pr-finalize a regenera); (6) o head novo MERGEABLE; (7) o ruleset sem regra além dos checks (o --admin contorna o ruleset INTEIRO). Os gates
#           de sempre rodam contra o head ANTERIOR, e o merge vai por `--admin --match-head-commit
#           <head novo>`: o ruleset exige os checks no head do PR, e o bypass (admin, modo pull_request)
#           é a única porta para um head sem checks. Forge recusou ⇒ volta a esperar (rc 4 na série).
#           A decisão é impressa e vai no comentário do auto-rebase. Rede: a bancada completa no push ao
#           main + o alarme (ops/testing/main-bench-alarm.sh). JANELA DECLARADA: quebra SEMÂNTICA entre
#           dois PRs que mudam arquivos diferentes passa e só a completa do main pega.
#           CONDIÇÃO (8), FASE 0 de D_POSTMERGE_PROJECTION_WRITER_2026_10 (2026-10-14): as projeções geradas do
#           head novo (regeneradas na árvore COMBINADA pelo pr-finalize) têm de ser BYTE-IDÊNTICAS às que o
#           head anterior trazia. Mudou alguma ⇒ o CI nunca viu aquela projeção, e não há caminho rápido.
#   STRICT LOCAL (sem flag, FASE 0 de D_POSTMERGE_PROJECTION_WRITER_2026_10, 2026-10-14): o ruleset do main
#           tem strict_required_status_checks_policy: false (medido), então o forge aceita PR ATRÁS do main
#           e mergeia uma árvore combinada que o CI nunca viu (o 478/479 do backlog: dois PRs fazem o mesmo
#           477→478 no cabeçalho, o merge textual soma os itens). Aqui a base do PR tem de ser a PONTA da
#           base: lido no forge (compare <base>...<head>, behind_by), que é o merge-base do head com a base
#           ≠ ponta da base. Atrás ⇒ o MESMO auto-rebase do CONFLICTING (pr-finalize --rebase --push, que
#           regenera as projeções na árvore combinada e as commita no head), com o MESMO teto de tentativas,
#           e o head novo espera o CI salvo a condição (8). Ilegível ⇒ não mergeio (fail-closed). Com
#           --merge-commit, PR atrás é RECUSADO: o rebase linearizaria o merge que é o conteúdo.
#   --wait-ci-after-rebase: opt-out — depois do auto-rebase, espera o CI do head novo como antes.
#   PROVENANCE DA BRANCH (sem flag, SAC-80, 2026-10-09): se o PR ADICIONA em `*.kg.yaml` um `source:`
#           com `@<sha>` de commit que NÃO é ancestral da base (commit da própria branch), o rebase o
#           reescreveria e a provenance ficaria fora da main. Sem --merge-commit, RECUSA antes do
#           merge nomeando sha e arquivo; com --merge-commit, mergeia e confere depois que cada sha
#           é ancestral de origin/<base> (rc 3 se não for, como o --assert-ancestor).
#   RASCUNHO (sem flag, 2026-10-25): PR em rascunho (isDraft) é RECUSADO antes de qualquer efeito —
#           rebase, push, comentário, merge —, rc 1, nomeando o rascunho. Rascunho é o autor dizendo
#           "ainda não"; mergear por cima disso é decidir por ele. Leitura ilegível do isDraft = recusa.
#   --allow-draft: opt-in explícito, para a bancada (e para quem decidiu mergear o rascunho de propósito).
set -uo pipefail

PR="${1:?uso: $0 <numero-do-PR> [--repo owner/nome] [--keep-branch] [--allow-draft] [--dispensa <check> --motivo <texto>]}"; shift || true
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
MERGE_COMMIT=0; ASSERT_ANCESTOR=""; NO_WAIT_AFTER_REBASE=0; WAIT_CI_AFTER_REBASE=0; ALLOW_DRAFT=0
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
    --no-wait-after-rebase) NO_WAIT_AFTER_REBASE=1; shift ;;
    --wait-ci-after-rebase) WAIT_CI_AFTER_REBASE=1; shift ;;
    --allow-draft) ALLOW_DRAFT=1; shift ;;
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
# ── RASCUNHO É RECUSADO ANTES DE QUALQUER EFEITO (2026-10-25, observação do par na bancada do #1355) ──
# O auto-rebase reescreve a branch, empurra e comenta ANTES do merge: num rascunho, isso é mexer no
# trabalho que o autor declarou não pronto. Por isso o gate mora aqui, junto da âncora de estado, antes
# da guarda de provenance, do aviso de serialização, do rebase, do comentário e do merge. A leitura é
# fail-closed como a âncora: ilegível não é "não é rascunho".
if [ "${ALLOW_DRAFT}" -ne 1 ]; then
  _is_draft="$(gh pr view "$PR" "${REPO_ARG[@]}" --json isDraft --jq '.isDraft' 2>/dev/null)"
  case "${_is_draft}" in
    false) : ;;
    true) die "PR #${PR} é RASCUNHO (isDraft) — não rebaseio, não empurro, não comento, não mergeio. Tire do rascunho (gh pr ready ${PR}) ou, de propósito, rode com --allow-draft." ;;
    *) die "não consegui LER se o PR #${PR} é rascunho (isDraft='${_is_draft}') — não prossigo: rascunho ilegível não é rascunho ausente" ;;
  esac
fi

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
_PR_FILES=""        # os arquivos do PR, um por linha (lidos uma vez, no _kg_guard_pre)
_kg_base=""
_kg_guard_pre() {
  local _slug="${OWNER_REPO:-}"; [ "${#REPO_ARG[@]}" -ge 2 ] && _slug="${REPO_ARG[1]}"
  local _files
  _files="$(gh api "repos/${_slug}/pulls/${PR}/files?per_page=100" --paginate --jq '.[].filename' 2>/dev/null)" \
    || die "não consegui LER os arquivos do PR #${PR} — sem eles não sei se o .kg.yaml cita commit da branch (SAC-80). Não prossigo."
  _PR_FILES="${_files}"   # o aviso de serialização (repo alheio) reusa esta leitura, sem 2ª chamada
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
# ══ AUTO-REBASE EM REPO ALHEIO: o adotante NÃO tem ops/pr-finalize.sh (medido 2026-10-25) ════════════════
# Adotantes sem `ops/` (onion-kg-ssot, onion-curation) mergeiam por ESTE script, chamado do core com
# `--repo`, de dentro do repo deles. O auto-rebase abaixo rodava `bash ops/pr-finalize.sh --rebase --push` na
# worktree da branch — e o motor não existe lá: rc 127 (PR #227 do kg-ssot). Sem worktree, a mensagem mandava
# rodar o mesmo motor ausente (#230). Medido 4 vezes num dia (#225, #227, #229, #230), e o conflito típico era
# SÓ de projeção gerada e commitada: docs/backlog.md e docs/onion/kg-read-index.tsv.
# Decisão do maestro (opções (a) + (c) da proposta do kg-ssot). A (b), `merge=ours` no .gitattributes, foi
# RECUSADA: o merge do GitHub ignora o driver, e o "nosso lado vence" esconderia projeção defasada.
#   (a) worktree da branch sem o motor ⇒ rebase PRÓPRIO, estreito de propósito: só as duas projeções acima
#       se resolvem sozinhas, cada uma regenerada pelo gerador do PRÓPRIO alvo (nunca o do core: o alvo
#       projeta os grafos dele, com o vendor dele). Qualquer outro arquivo em conflito ⇒ `rebase --abort`, a
#       branch fica no head de antes, e o rc≠0 nomeia o arquivo. Gerador ausente ou que falha ⇒ o mesmo.
#       Depois do rebase limpo as projeções são regeneradas de novo na árvore COMBINADA (o merge textual
#       limpo também soma itens — o 478/479 do backlog), o lint do alvo julga (0 HARD), e só então o push,
#       com --force-with-lease AMARRADO ao head que o PR mostrava. Com --merge-commit, recusa: o rebase
#       linearizaria o merge que é o conteúdo. Sem o caminho rápido do CI: o head novo espera o CI dele.
#   (c) antes de qualquer efeito, AVISO (não bloqueia) quando outro PR aberto do mesmo repo toca a mesma
#       projeção: o merge de um deixa o outro em conflito nela, e serializar é o que evita a volta.
# Repo alheio = a raiz de onde o script roda não tem ops/pr-finalize.sh (o aviso e a mensagem sem worktree);
# o rebase olha a worktree da BRANCH, que é onde o motor teria de rodar.
_FOREIGN_PROJ="docs/backlog.md docs/onion/kg-read-index.tsv"
_foreign_is_proj() { case " ${_FOREIGN_PROJ} " in *" $1 "*) return 0 ;; esac; return 1; }
_FOREIGN_REPO=0
_top="$(git rev-parse --show-toplevel 2>/dev/null)"
# fora de qualquer repo (`_top` vazio) também é alheio: o motor do core não está ao alcance de quem chamou
[ -f "${_top:-/nonexistent}/ops/pr-finalize.sh" ] || _FOREIGN_REPO=1
_FR_MSG=""; _FR_OUT=""; _FR_BASE=""
# _FR_OUTCOME: o desfecho CURTO da recusa ("recusado: <o quê>"), que vai para a linha do head e para o
# desfecho do rastro no PR. Antes o rastro dizia só "head → —", e quem lia o PR não sabia por que parou
# (observação do par que rodou a bancada do #1355). Cada sítio de recusa o escreve; o _FR_MSG segue longo.
_FR_OUTCOME=""
_foreign_gen() { # $1=worktree $2=projeção → regenera no lugar pelo gerador do alvo; rc≠0 com _FR_MSG
  local _w="$1" _p="$2" _g _tmp _rc=0 _empty_ok=0
  case "${_p}" in
    docs/onion/kg-read-index.tsv) _g=.claude/validation/kg-trace.sh ;;
    docs/backlog.md)              _g=.claude/validation/kg-backlog-project.sh ;;
    *) _FR_MSG="${_p} não é projeção conhecida"; _FR_OUTCOME="recusado: ${_p} não é projeção conhecida"; return 1 ;;
  esac
  [ -f "${_w}/${_g}" ] || { _FR_MSG="gerador ausente para ${_p}: ${_g} não existe no repo alvo"; _FR_OUTCOME="recusado: gerador ausente para ${_p}"; return 1; }
  _tmp="$(mktemp)"
  if [ "${_p}" = docs/onion/kg-read-index.tsv ]; then
    local _err; _err="$(mktemp)"
    ( cd "${_w}" && bash "${_g}" . --emit-index ) > "${_tmp}" 2>"${_err}" || _rc=$?
    # rc 3 = índice VAZIO (nenhum nó com trace resolvível): legítimo no dia 1 do adotante. Mas o rc é DECLARAÇÃO:
    # grafo ILEGÍVEL também sai rc 3 (medido na passada adversarial, com o kg-trace e o vendor reais), e aí o
    # índice povoado viraria vazio com rc 0. Só aceito o vazio quando a base também o tem vazio (ou não o tem),
    # e nunca com "ilegível" no stderr do gerador.
    if [ "${_rc}" -eq 3 ]; then
      if LC_ALL=C grep -qi 'ileg' "${_err}"; then
        _FR_MSG="o gerador de ${_p} disse índice vazio (rc 3) com grafo ILEGÍVEL — não troco o índice por um vazio"
      elif [ -n "$(git -C "${_w}" show "origin/${_FR_BASE}:${_p}" 2>/dev/null)" ]; then
        _FR_MSG="o gerador de ${_p} disse índice vazio (rc 3), e origin/${_FR_BASE} tem o índice povoado — vazio aqui é perda, não projeção"
      else _rc=0; _empty_ok=1; fi
    fi
    rm -f "${_err}"
    [ -z "${_FR_MSG}" ] || { rm -f "${_tmp}"; _FR_OUTCOME="recusado: índice vazio do gerador de ${_p} não provado"; return 1; }
  else
    ( cd "${_w}" && bash "${_g}" --markdown ) > "${_tmp}" 2>/dev/null || _rc=$?
  fi
  [ "${_rc}" -eq 0 ] || { rm -f "${_tmp}"; _FR_MSG="o gerador de ${_p} falhou (${_g}, rc=${_rc})"; _FR_OUTCOME="recusado: gerador de ${_p} falhou (rc=${_rc})"; return 1; }
  # vazio sem o rc 3 não é projeção: é gerador mudo, e sobrescrever o vivo com nada é pior que a defasagem
  [ -s "${_tmp}" ] || [ "${_empty_ok}" -eq 1 ] \
    || { rm -f "${_tmp}"; _FR_MSG="o gerador de ${_p} saiu VAZIO (${_g}) — não sobrescrevo o vivo"; _FR_OUTCOME="recusado: gerador de ${_p} saiu vazio"; return 1; }
  # `cat >`, não `mv`: o mktemp nasce 0600, e o mv levaria esse modo para a árvore do alvo
  cat "${_tmp}" > "${_w}/${_p}"; rm -f "${_tmp}"
}
_foreign_rb_busy() { ( cd "$1" && { [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]; } ); }
_foreign_rebase() { # $1=worktree $2=base $3=head que o PR mostra → rc 0 = rebaseado, regenerado, julgado e ENVIADO
  local _w="$1" _b="$2" _exp="$3" _before _c _f _i _lint _lrc _wn
  _FR_MSG=""; _FR_OUT=""; _FR_BASE="${_b}"; _FR_OUTCOME=""
  # o _FR_MSG vai para o comentário do PR, e o repo pode ser público: o nome da worktree, nunca o caminho da máquina
  _wn="worktree '$(basename "${_w}")'"
  _before="$(git -C "${_w}" rev-parse HEAD 2>/dev/null)"
  # a worktree tem de estar NO head do PR: atrás dele, o push com lease no head do PR descartaria commits do
  # remoto; à frente, publicaria commits que ninguém julgou. Nos dois casos, quem decide é o dono da branch.
  [ -n "${_before}" ] && [ "${_before}" = "${_exp}" ] \
    || { _FR_MSG="a ${_wn} está em ${_before:0:8} e o PR em ${_exp:0:8} — sincronize a worktree com a branch do PR antes"; _FR_OUTCOME="recusado: worktree fora do head do PR"; return 1; }
  { git -C "${_w}" diff --quiet && git -C "${_w}" diff --cached --quiet; } \
    || { _FR_MSG="a ${_wn} tem mudança não commitada — não rebaseio por cima de trabalho em curso"; _FR_OUTCOME="recusado: worktree com mudança não commitada"; return 1; }
  git -C "${_w}" fetch -q origin "+refs/heads/${_b}:refs/remotes/origin/${_b}" 2>/dev/null \
    || { _FR_MSG="não consegui buscar origin/${_b} na ${_wn}"; _FR_OUTCOME="recusado: fetch de origin/${_b} falhou"; return 1; }
  # MERGE COMMIT NA BRANCH: o rebase simples lineariza e DESCARTA o que mora só no merge (a resolução, ou a
  # mudança de um "evil merge") — com lint verde e rc 0 (medido na passada adversarial: src/evil.sh sumiu do
  # head enviado). E as mensagens deste script mandam fazer exatamente `git merge origin/<base>` na branch.
  [ -z "$(git -C "${_w}" rev-list --merges "origin/${_b}..HEAD" 2>/dev/null)" ] \
    || { _FR_MSG="a branch carrega commit de MERGE — o rebase o linearizaria e descartaria o que mora só nele; rebaseie à mão, decidindo o que o merge carrega (ou, se o merge é o conteúdo, rode com --merge-commit depois de mergear a base na branch e esperar o CI)"; _FR_OUTCOME="recusado: a branch carrega commit de merge"; return 1; }
  # daqui em diante, toda saída de falha devolve a branch ao head de antes: "recusado" quer dizer "nada mudou".
  # A exceção é o push que CHEGOU (rc mentindo, ou morte logo depois): aí o fato é o ref remoto, e desfazer o
  # local deixaria o rastro dizendo "nada mudou" sobre uma branch reescrita (o mesmo princípio do SAC-85 abaixo).
  _fr_pushed() { local _r; _r="$(git -C "${_w}" ls-remote origin "refs/heads/${HEAD_REF}" 2>/dev/null)"; _r="${_r%%[[:space:]]*}"
                 [ -n "${_r}" ] && [ "${_r}" != "${_before}" ] && [ "${_r}" = "$(git -C "${_w}" rev-parse HEAD 2>/dev/null)" ]; }
  _undo() { _foreign_rb_busy "${_w}" && git -C "${_w}" rebase --abort >/dev/null 2>&1; git -C "${_w}" reset -q --hard "${_before}" >/dev/null 2>&1; }
  # MORTE NO MEIO (SAC-136 do pr-finalize: o Claude Code mata comando de fundo): sem trap, a worktree ficava em
  # rebase, ou reescrita e não enviada, e a rodada seguinte recusava por "suja"/"fora do head" (medido com SIGTERM
  # no lint e no gerador). Armado até o fim da função; o que já chegou ao remoto não se desfaz.
  _fr_on_death() { _fr_pushed || _undo; }
  trap '_fr_on_death' EXIT
  trap '_fr_on_death; trap - EXIT; exit 143' TERM
  trap '_fr_on_death; trap - EXIT; exit 130' INT
  trap '_fr_on_death; trap - EXIT; exit 129' HUP
  _fr_off() { trap - EXIT TERM INT HUP; }   # desarma; o `return` fica no chamador (return numa função aninhada só sai dela)
  if ! git -C "${_w}" rebase "origin/${_b}" >/dev/null 2>&1; then
    for _i in $(seq 1 200); do
      _foreign_rb_busy "${_w}" || break
      _c="$(git -C "${_w}" -c core.quotepath=off diff --name-only --diff-filter=U)"
      [ -n "${_c}" ] || { _undo; _FR_MSG="o rebase parou sem conflito nomeável — abortado, a branch segue em ${_before:0:8}"; _FR_OUTCOME="recusado: rebase parou sem conflito nomeável"; _fr_off; return 1; }
      for _f in ${_c}; do
        _foreign_is_proj "${_f}" \
          || { _undo; _FR_MSG="conflito REAL em ${_f} — só ${_FOREIGN_PROJ// /, } se resolvem sozinhas; rebase abortado, a branch segue em ${_before:0:8}"; _FR_OUTCOME="recusado: conflito de fonte em ${_f}"; _fr_off; return 1; }
      done
      for _f in ${_c}; do
        _foreign_gen "${_w}" "${_f}" || { _undo; _FR_MSG="${_FR_MSG} — rebase abortado, a branch segue em ${_before:0:8}"; _fr_off; return 1; }
        git -C "${_w}" add -- "${_f}"
        # a mesma forma de linha do pr-finalize: a causa do rastro no PR é lida dela
        _FR_OUT="${_FR_OUT}conflito de projeção resolvido em ${_f} (regenerado pelo gerador do alvo)"$'\n'
      done
      # a projeção regenerada pode igualar o commit à base (o commit só mexia nela): aí ele some, por --skip
      if git -C "${_w}" diff --cached --quiet; then
        GIT_EDITOR=true git -C "${_w}" rebase --skip >/dev/null 2>&1 && ! _foreign_rb_busy "${_w}" && break
      else
        GIT_EDITOR=true git -C "${_w}" rebase --continue >/dev/null 2>&1 && ! _foreign_rb_busy "${_w}" && break
      fi
    done
    _foreign_rb_busy "${_w}" && { _undo; _FR_MSG="o rebase não terminou — abortado, a branch segue em ${_before:0:8}"; _FR_OUTCOME="recusado: o rebase não terminou"; _fr_off; return 1; }
  fi
  # a prova é a ancestralidade, não o rc (o rebase pode falhar sem deixar estado)
  git -C "${_w}" merge-base --is-ancestor "origin/${_b}" HEAD \
    || { _undo; _FR_MSG="o rebase NÃO pôs origin/${_b} debaixo do HEAD — nada enviado"; _FR_OUTCOME="recusado: origin/${_b} não ficou debaixo do HEAD"; _fr_off; return 1; }
  # a árvore COMBINADA: regenera as projeções que o alvo versiona, e o que mudou vira commit próprio
  for _f in ${_FOREIGN_PROJ}; do
    git -C "${_w}" ls-files --error-unmatch -- "${_f}" >/dev/null 2>&1 || continue
    _foreign_gen "${_w}" "${_f}" || { _undo; _FR_MSG="${_FR_MSG} (na árvore combinada) — nada enviado, a branch segue em ${_before:0:8}"; _fr_off; return 1; }
    git -C "${_w}" add -- "${_f}"
  done
  if ! git -C "${_w}" diff --cached --quiet; then
    # --no-verify: o gate deste commit é o lint do alvo, logo abaixo, sobre a árvore inteira — uma passada, não duas
    git -C "${_w}" commit -q --no-verify -m "docs: projeções geradas regeneradas na árvore combinada" >/dev/null 2>&1 \
      || { _undo; _FR_MSG="não consegui commitar as projeções regeneradas na ${_wn} — nada enviado"; _FR_OUTCOME="recusado: commit das projeções regeneradas falhou"; _fr_off; return 1; }
    _FR_OUT="${_FR_OUT}projeções regeneradas na árvore combinada e commitadas"$'\n'
  fi
  if [ -f "${_w}/.claude/validation/lint-artifacts.sh" ]; then
    _lint="$(cd "${_w}" && LC_ALL=C bash .claude/validation/lint-artifacts.sh 2>&1)"; _lrc=$?
    if grep -qF 'MORREU' <<< "${_lint}" || [ "${_lrc}" -ne 0 ]; then
      # N HARD lido da linha do sumário do lint do alvo; sem ela (lint morto ou de outra forma), diz o rc
      local _nh; _nh="$(LC_ALL=C grep -m1 -oE 'Violações HARD *: *[0-9]+' <<< "${_lint}" | LC_ALL=C grep -oE '[0-9]+$')" || _nh=""
      if grep -qF 'MORREU' <<< "${_lint}"; then _FR_OUTCOME="recusado: lint do alvo morreu (rc=${_lrc})"
      elif [ -n "${_nh}" ]; then _FR_OUTCOME="recusado: lint do alvo com ${_nh} HARD"
      else _FR_OUTCOME="recusado: lint do alvo reprovou (rc=${_lrc})"; fi
      _undo; _FR_MSG="o lint do alvo reprovou o head rebaseado (rc=${_lrc}): $(grep -m1 -E 'Violações HARD|MORREU' <<< "${_lint}") — nada enviado, a branch segue em ${_before:0:8}"; _fr_off; return 1
    fi
    _FR_OUT="${_FR_OUT}gate do alvo: lint-artifacts.sh rc 0 (0 HARD)"$'\n'
  else
    _FR_OUT="${_FR_OUT}o alvo não tem .claude/validation/lint-artifacts.sh — gate local não rodou; o CI do head novo é a cobertura"$'\n'
  fi
  if ! git -C "${_w}" push -q --force-with-lease="refs/heads/${HEAD_REF}:${_exp}" origin "HEAD:refs/heads/${HEAD_REF}" >/dev/null 2>&1; then
    # o rc do push é declaração: se o ref remoto JÁ é o head novo, o push chegou e o fluxo segue por ele
    if _fr_pushed; then _FR_OUT="${_FR_OUT}o push saiu rc≠0, mas o ref remoto já é o head novo — sigo pelo ref"$'\n'
    else _undo; _FR_MSG="o push --force-with-lease (amarrado a ${_exp:0:8}) foi recusado — alguém empurrou na branch? Nada enviado"; _FR_OUTCOME="recusado: push com lease recusado"; _fr_off; return 1; fi
  fi
  _FR_OUT="${_FR_OUT}enviado ${HEAD_REF} @ $(git -C "${_w}" rev-parse --short HEAD)"$'\n'
  _fr_off; return 0
}
_warn_serialize() { # (c): aviso, nunca bloqueio — leitura que falha vira linha ℹ️, e o fluxo segue
  [ "${_FOREIGN_REPO}" -eq 1 ] || return 0
  local _mine="" _f _n _open _theirs
  for _f in ${_FOREIGN_PROJ}; do grep -qxF -- "${_f}" <<< "${_PR_FILES}" && _mine="${_mine} ${_f}"; done
  [ -n "${_mine}" ] || return 0
  _open="$(gh pr list "${REPO_ARG[@]}" --state open --limit 50 --json number --jq '.[].number' 2>/dev/null)" \
    || { say "ℹ️  não li os PRs abertos — não sei se outro PR toca${_mine} (aviso de serialização desligado)"; return 0; }
  while IFS= read -r _n; do
    case "${_n}" in ''|*[!0-9]*) continue ;; esac
    [ "${_n}" = "${PR}" ] && continue
    _theirs="$(gh pr view "${_n}" "${REPO_ARG[@]}" --json files --jq '.files[].path' 2>/dev/null)" \
      || { say "ℹ️  não li os arquivos do PR #${_n} — não sei se ele toca${_mine}"; continue; }
    for _f in ${_mine}; do
      grep -qxF -- "${_f}" <<< "${_theirs}" && say "⚠️  PR #${_n} também toca ${_f}: serialize (o merge de um deixa o outro em conflito nessa projeção)"
    done
  done <<< "${_open}"
  return 0
}
_warn_serialize
# ══ AUTO-REBASE: PR em CONFLICTING não dispara CI ══════════════════════════════════════════════
# Defeito medido em 2026-10-07/08: 25 PRs, 33 commits de "projeções geradas regeneradas". Todo PR
# commita as projeções (backlog, testing-state, kg-read-index; plugins/ até a F4 das portas), então cada merge deixa os
# PRs abertos CONFLICTING — e o GitHub NÃO dispara CI em PR em conflito. A espera ficava parada em
# "no checks reported" (#957 duas vezes, #959, #960, #975) até alguém rodar o rebase à mão. Desde o
# #973 o `pr-finalize --rebase --push` resolve com segurança o conflito SÓ de projeção (regenera
# as projeções) e RECUSA conflito de fonte. Aqui ele é DISPARADO sozinho:
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
# ══ RASTRO DO AUTO-REBASE NO PR (H5, D_MERGE_PROCESS_ONION_2026_10, 2026-10-13) ════════════════
# Medido: ≥14 auto-rebases sem rastro nenhum no PR — quem lia o PR via um head trocado sem saber por
# quê. O rebase É um efeito sobre o PR (reescreve a branch), então o registro mora no PR. Diferente da
# dispensa, aqui o registro NÃO é precondição: quando o comentário é postado o rebase já aconteceu, e
# morrer depois dele deixaria o PR rebaseado e o merge parado pelo motivo errado. Falha ⇒ AVISO
# NOMEADO no terminal (nunca falha calada), e o merge segue os gates de sempre.
_rebase_trail() { # $1=head antigo $2=head novo (ou "—") $3=causa $4=N/MAX $5=desfecho [$6=desfecho curto, sem head novo]
  local _body _hd="\`${2:0:12}\`"
  # sem head novo, a seta sozinha ("→ —") não dizia nada: o desfecho curto vai na própria linha do head
  [ "$2" = "—" ] && _hd="— (${6:-sem head novo})"
  _body="$(printf '%s\n' \
    "## 🔁 Auto-rebase de \`ops/pr-merge-verified.sh\`" \
    "" \
    "| | |" \
    "|---|---|" \
    "| head | \`${1:0:12}\` → ${_hd} |" \
    "| causa | ${3} |" \
    "| tentativa | ${4} |" \
    "| desfecho | ${5} |" \
    "" \
    "${_RB_REASON_TEXT}" \
    "${_RB_ENGINE_TEXT}")"
  if ! command -v gh >/dev/null 2>&1; then
    say "⚠️  auto-rebase SEM RASTRO no PR #${PR}: \`gh\` indisponível — head ${1:0:8} → ${2:0:8}, causa: ${3} (${4})"
    return 0
  fi
  if gh pr comment "$PR" "${REPO_ARG[@]}" --body "${_body}" >/dev/null 2>&1; then
    say "✓ auto-rebase registrado no PR #${PR} (comentário: ${1:0:8} → ${2:0:8}, ${4})"
  else
    say "⚠️  auto-rebase SEM RASTRO no PR #${PR}: \`gh pr comment\` falhou — head ${1:0:8} → ${2:0:8}, causa: ${3} (${4}). Registre à mão."
  fi
}
# ══ PULAR A ESPERA DO CI DO HEAD NOVO? (D_MERGE_SEM_CI_APOS_REBASE_LIMPO, 2026-10-13) ═══════════════════
# Medido: cada merge da fila levava 20–25 min, quase tudo esperando o CI do head NOVO depois do
# auto-rebase — e o head novo só difere do verificado pelo que a main trouxe e pelas projeções
# regeneradas. O ruleset do main é LOOSE (strict_required_status_checks_policy: false), mas exige os
# checks NO HEAD DO PR: um head recém-empurrado não tem nenhum, e o merge normal é recusado (o `gh pr
# merge` sem --admin ainda LIGARIA o auto-merge em vez de mergear). A porta que mantém o head verificado
# é o bypass do ruleset (admin, `bypass_mode: pull_request`, lido ao vivo como current_user_can_bypass =
# pull_requests_only) com `--match-head-commit`: o forge só mergeia SE o head ainda é o que eu julguei.
# O GitHub rebasear no merge (sem push de head novo) não serve aqui: o auto-rebase roda em PR
# CONFLICTING (que o forge não rebaseia) e, desde a FASE 0 de D_POSTMERGE_PROJECTION_WRITER_2026_10, em PR
# ATRÁS da base — e o rebase do forge no merge é justamente a árvore combinada que o CI nunca viu.
# Cada condição falha para o lado de ESPERAR, nunca para o de pular. Projeção gerada não conta no
# cruzamento de arquivos porque É ela que conflita (medido no #1071: testing-inventory.md) — sem isso a
# regra nunca valeria; a regeneração é determinística, e o pr-finalize roda o lint (0 HARD) no head novo.
SKIP_CI=0; SKIP_DECISION=""; GATE_SHA=""
# uma linha por nome, a check-run mais recente (ver "UMA LINHA POR NOME" adiante, no gate)
_LATEST_PER_NAME_JQ='[.check_runs[]] | group_by(.name) | map(max_by(.id)) | .[] | .name + "\t" + .status + "\t" + (.conclusion // "-")'
_SKIP_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_ALARM_TITLE="🚨 main quebrado — a bancada completa reprovou no push ao main"   # o TITLE de ops/testing/main-bench-alarm.sh
_skip_ci_decide() { # $1=head julgado (antes do rebase) $2=head novo $3=worktree $4=HEAD da worktree antes do rebase
  local _old="$1" _new="$2" _w="$3" _wb="$4" _slug _req _runs _r _bad _al _omb _nmb _bd _pf _x _hit=""
  SKIP_DECISION=""
  [ "${WAIT_CI_AFTER_REBASE}" -eq 1 ] && { SKIP_DECISION="espera: opt-out --wait-ci-after-rebase"; return 1; }
  [ -n "${_old}" ] && [ "${_wb}" = "${_old}" ] \
    || { SKIP_DECISION="espera: a worktree estava em ${_wb:0:8} e o PR em ${_old:0:8} — o verde lido não seria do head rebaseado"; return 1; }
  _slug="${OWNER_REPO:-}"; [ "${#REPO_ARG[@]}" -ge 2 ] && _slug="${REPO_ARG[1]}"
  _al="$(gh issue list "${REPO_ARG[@]}" --state open --limit 100 --json number,title \
         --jq ".[] | select(.title == \"${_ALARM_TITLE}\") | .number" 2>/dev/null)" \
    || { SKIP_DECISION="espera: não consegui LER as issues de alarme do main — não pulo o CI sem saber se o main está quebrado"; return 1; }
  [ -z "${_al}" ] || { SKIP_DECISION="espera: alarme de main quebrado ABERTO (issue #${_al%%$'\n'*}) — com o main quebrado só o conserto entra, e nunca sem CI"; return 1; }
  _req="$(python3 -I -c 'import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
for r in d.get("rules",[]):
    if r.get("type")=="required_status_checks":
        for c in r["parameters"]["required_status_checks"]: print(c["context"])
    else: print("__REGRA__ " + str(r.get("type")))' "${_SKIP_HERE}/github-ruleset-main.json" 2>/dev/null)"
  [ -n "${_req}" ] || { SKIP_DECISION="espera: não li os checks exigidos de ${_SKIP_HERE}/github-ruleset-main.json"; return 1; }
  # o --admin contorna o ruleset INTEIRO, não só os checks: com outra regra no ruleset (review obrigatório,
  # histórico linear…) o pulo a contornaria calado. Só pulo enquanto a única regra é a dos checks.
  if grep -q '^__REGRA__ ' <<< "${_req}"; then
    SKIP_DECISION="espera: o ruleset tem regra além dos checks ($(grep '^__REGRA__ ' <<< "${_req}" | cut -d' ' -f2 | paste -sd, -)) — o bypass a contornaria junto"; return 1
  fi
  _runs="$(gh api "repos/${_slug}/commits/${_old}/check-runs?per_page=100" --jq "${_LATEST_PER_NAME_JQ}" 2>/dev/null)" \
    || { SKIP_DECISION="espera: não li os check-runs do head anterior ${_old:0:8}"; return 1; }
  # ZERO check-runs (total_count: 0) não é "vermelho": é o PR que nasceu ou foi empurrado JÁ em conflito, e
  # o GitHub não roda CI de pull_request em PR em conflito (medido no #1092, 2026-10-13). A decisão é a
  # mesma (espera), mas a mensagem antiga dizia "não está verde" para os dois casos e mandava procurar
  # um check vermelho que não existe. A mensagem diz "caso típico", não "a causa": zero check-runs é o
  # SINAL, e outro motivo (workflow filtrado, CI ainda não criado) dá o mesmo zero.
  grep -q . <<< "${_runs}" \
    || { SKIP_DECISION="espera: o head anterior ${_old:0:8} não tem check-run nenhum — o caso típico é o PR aberto/empurrado já em conflito (o GitHub não roda CI de pull_request em PR em conflito), então nunca houve verde para ler; espera o CI do head novo"; return 1; }
  for _r in ${_req}; do
    awk -F'\t' -v n="${_r}" '$1==n && $2=="completed" && $3=="success"{f=1} END{exit !f}' <<< "${_runs}" \
      || { SKIP_DECISION="espera: o check exigido '${_r}' não está verde no head anterior ${_old:0:8}"; return 1; }
  done
  awk -F'\t' 'NF && $2!="completed"{f=1} END{exit !f}' <<< "${_runs}" \
    && { SKIP_DECISION="espera: há check-run não completo no head anterior ${_old:0:8}"; return 1; }
  _bad=""
  while IFS=$'\t' read -r _x _ _r; do
    case "${_r}" in failure|cancelled|timed_out|action_required|stale) _dispensado "${_x}" || _bad="${_bad}${_x} " ;; esac
  done <<< "${_runs}"
  [ -z "${_bad}" ] || { SKIP_DECISION="espera: check falho não dispensado no head anterior ${_old:0:8}: ${_bad% }"; return 1; }
  # o que a main trouxe (merge-base velho → novo) × os arquivos do PR (antes e depois do rebase)
  _nmb="$(git -C "${_w}" merge-base "${_new}" origin/main 2>/dev/null)"
  _omb="$(git -C "${_w}" merge-base "${_old}" "${_nmb:-x}" 2>/dev/null)"
  [ -n "${_omb}" ] && [ -n "${_nmb}" ] || { SKIP_DECISION="espera: não calculei os merge-bases velho/novo na worktree"; return 1; }
  _bd="$(git -C "${_w}" -c core.quotepath=off diff --no-ext-diff --no-textconv --name-only "${_omb}" "${_nmb}" 2>/dev/null)" \
    || { SKIP_DECISION="espera: não li o diff do rebase (${_omb:0:8}..${_nmb:0:8})"; return 1; }
  _pf="$( { git -C "${_w}" -c core.quotepath=off diff --no-ext-diff --no-textconv --name-only "${_omb}" "${_old}" \
           && git -C "${_w}" -c core.quotepath=off diff --no-ext-diff --no-textconv --name-only "${_nmb}" "${_new}"; } 2>/dev/null)" \
    || { SKIP_DECISION="espera: não li os arquivos do PR na worktree"; return 1; }
  local _lib="${_SKIP_HERE}/../.claude/validation/onion-regen-lib.sh"
  [ -r "${_lib}" ] && ( . "${_lib}" >/dev/null 2>&1; declare -F onion_is_generated >/dev/null ) \
    || { SKIP_DECISION="espera: sem onion-regen-lib.sh não sei o que é projeção gerada"; return 1; }
  _hit="$(. "${_lib}" >/dev/null 2>&1; while IFS= read -r _x; do
            [ -n "${_x}" ] || continue
            grep -qxF -- "${_x}" <<< "${_pf}" || continue
            onion_is_generated "${_x}" || printf '%s\n' "${_x}"
          done <<< "${_bd}")"
  [ -z "${_hit}" ] || { SKIP_DECISION="espera: o rebase trouxe mudança em arquivo(s) do PR: $(printf '%s\n' "${_hit}" | head -5 | paste -sd' ' -)"; return 1; }
  # (8) FASE 0 de D_POSTMERGE_PROJECTION_WRITER_2026_10: o pr-finalize regenerou as projeções na árvore
  # COMBINADA e as commitou no head novo. Se alguma ficou diferente do que o head anterior (o que o CI julgou)
  # trazia, o CI nunca viu essa projeção — e foi exatamente assim que o 478/479 entrou no main. Byte a byte,
  # pelo git; a lista é a da FONTE ÚNICA (onion-regen-lib.sh). Ler falhou ⇒ espera.
  local _gen _pd
  _gen="$(. "${_lib}" >/dev/null 2>&1; printf '%s %s' "${ONION_GENERATED:-}" "${ONION_GENERATED_DIRS:-}")"
  [ -n "${_gen// /}" ] || { SKIP_DECISION="espera: a lista de projeções geradas saiu vazia — não sei comparar as projeções"; return 1; }
  # shellcheck disable=SC2086  # a lista é de caminhos sem espaço, separados por espaço (a forma da lib)
  _pd="$(git -C "${_w}" -c core.quotepath=off diff --no-ext-diff --no-textconv --name-only "${_old}" "${_new}" -- ${_gen} 2>/dev/null)" \
    || { SKIP_DECISION="espera: não comparei as projeções do head anterior com as do head novo"; return 1; }
  [ -z "${_pd}" ] || { SKIP_DECISION="espera: a regeneração na árvore combinada mudou projeção(ões) que o head anterior trazia: $(printf '%s\n' "${_pd}" | head -5 | paste -sd' ' -) — o CI nunca viu essa projeção"; return 1; }
  # (9) o head novo AINDA na ponta: o main pode ter andado entre o rebase e esta decisão, e aí o forge
  # rebasearia no merge — a combinação que o CI não viu, de novo. (A última leitura antes do merge cobre o
  # resto da janela; esta existe para o rastro no PR não anunciar um merge sem CI que não vai acontecer.)
  local _bh; _bh="$(_behind_base)" || { SKIP_DECISION="espera: não li a distância do head novo até a ponta de '${_BASE_REF}'"; return 1; }
  [ "${_bh}" -eq 0 ] || { SKIP_DECISION="espera: o main andou ${_bh} commit(s) depois do rebase — o head novo não está mais na ponta de '${_BASE_REF}'"; return 1; }
  local _m _k=0; _m="$(pr_mergeable)"
  while [ "${_m}" = UNKNOWN ] && [ "${_k}" -lt 6 ]; do sleep "${_POLL_SECS}"; _m="$(pr_mergeable)"; _k=$((_k+1)); done
  [ "${_m}" = MERGEABLE ] || { SKIP_DECISION="espera: o head novo está '${_m:-ilegível}', não MERGEABLE"; return 1; }
  SKIP_DECISION="SEM esperar o CI do head novo: rebase limpo, checks exigidos ($(printf '%s\n' "${_req}" | paste -sd, -)) verdes no head anterior ${_old:0:8}, o rebase não tocou arquivo do PR, projeções regeneradas na árvore combinada idênticas às do head anterior, sem alarme de main aberto"
  return 0
}
_mg="$(pr_mergeable)"
_n=0; while [ "$_mg" = UNKNOWN ] && [ "$_n" -lt 6 ]; do sleep "${_POLL_SECS}"; _mg="$(pr_mergeable)"; _n=$((_n+1)); done
# ONION_MERGE_REBASE_DONE: rebases que a SÉRIE já fez neste PR (o ops/merge-serial.sh (core-only) chama este
# script uma vez por rodada) — sem ele o limite valeria por chamada e o laço voltaria pela porta da série.
_rebases="${ONION_MERGE_REBASE_DONE:-0}"
case "${_rebases}" in ''|*[!0-9]*) die "ONION_MERGE_REBASE_DONE='${_rebases}' não é inteiro — não sei quantos rebases já houve" ;; esac
# ══ STRICT LOCAL: a base do PR tem de ser a PONTA da base (FASE 0 de D_POSTMERGE_PROJECTION_WRITER_2026_10) ══
# O ruleset do main tem strict_required_status_checks_policy: false (medido, ops/github-ruleset-main.json):
# o forge mergeia PR ATRÁS do main, e a árvore que entra é a COMBINADA, que o CI nunca viu. Foi assim que o
# backlog entrou com 479 itens e o cabeçalho de 478 (E_OBJECAO_PER_PR_GATE_BLIND_STRICT_FALSE,
# E_OBJECAO_INCIDENT_ACCUSES_MERGE_WITHOUT_CI). Ligar o strict no ruleset curaria o mesmo no forge, mas ele
# barra o PR atrás sem rebaseá-lo; aqui o PR atrás é REBASEADO pelo mesmo auto-rebase do CONFLICTING (o
# pr-finalize regenera as projeções na árvore combinada e as commita no head), e o head novo espera o CI,
# salvo a condição (8) do caminho rápido (projeções byte-idênticas às do head anterior).
# A leitura é do FORGE (compare <base>...<head>: behind_by = commits da base que o head não tem, isto é,
# merge-base(head, base) ≠ ponta da base): é a base que o forge vai usar no merge, não a minha cópia local.
# Ilegível ⇒ não mergeio: sem saber se a base é a ponta, o merge pode ser exatamente o do 478/479.
# a base é lida UMA vez, aqui fora: _behind_base roda em $(…), e o que ela atribuísse morreria no subshell
_BASE_REF="$(gh pr view "$PR" "${REPO_ARG[@]}" --json baseRefName --jq '.baseRefName' 2>/dev/null)"
_behind_base() { # imprime quantos commits a base tem que o head não tem; rc≠0 = não consegui medir
  local _slug="${OWNER_REPO:-}" _b; [ "${#REPO_ARG[@]}" -ge 2 ] && _slug="${REPO_ARG[1]}"
  [ -n "${_BASE_REF}" ] || return 1
  _b="$(gh api "repos/${_slug}/compare/${_BASE_REF}...${HEAD_SHA}" --jq '.behind_by' 2>/dev/null)" || return 1
  case "${_b}" in ''|*[!0-9]*) return 1 ;; esac
  printf '%s' "${_b}"
}
_behind="$(_behind_base)" \
  || die "não consegui medir se a base do PR #${PR} é a ponta de '${_BASE_REF:-?}' (compare do forge ilegível) — não mergeio sem saber: o ruleset tem strict=false, e um PR atrás entraria com a árvore combinada que o CI nunca viu"
[ "${_behind}" -gt 0 ] && say "PR #${PR} está ${_behind} commit(s) atrás de '${_BASE_REF}' — strict local: o merge exige a base na ponta (rebase antes)"
# PR atrás com --merge-commit: o rebase linearizaria o merge que É o conteúdo (o PR de update de adotante
# com onion/vendor). Recusa e diz o caminho; o CONFLICTING com --merge-commit segue como antes (declarado).
if [ "${_behind}" -gt 0 ] && [ "$_mg" != CONFLICTING ] && [ "${MERGE_COMMIT}" -eq 1 ]; then
  die "PR #${PR} está ${_behind} commit(s) atrás de '${_BASE_REF}' e o modo é --merge-commit — o auto-rebase linearizaria o merge da branch. Mergeie a base na branch à mão (git merge origin/${_BASE_REF}), espere o CI e rode de novo. Nada foi mergeado."
fi
_RB_REASON_TEXT=""
_RB_ENGINE_TEXT="O rebase rodou na worktree local da branch por \`ops/pr-finalize.sh --rebase --push\`, que resolve só conflito de projeção gerada (e, pelo driver das famílias, o acréscimo lado a lado de famílias da bancada) e regenera as projeções na árvore combinada."
_FOREIGN_RB=0
while [ "$_mg" = CONFLICTING ] || [ "${_behind}" -gt 0 ]; do
  _rebases=$((_rebases+1))
  if [ "$_mg" = CONFLICTING ]; then
    _rb_state="CONFLICTING"
    _RB_REASON_TEXT="O PR estava CONFLICTING (o GitHub não dispara CI em PR em conflito)."
  else
    _rb_state="atrás de '${_BASE_REF}' (${_behind} commit(s), sem conflito)"
    _RB_REASON_TEXT="O PR estava ATRÁS de \`${_BASE_REF}\` (${_behind} commit(s)) sem conflito. O ruleset não exige branch atualizada (strict=false), então o merge entraria com uma árvore combinada que o CI nunca viu: strict local (FASE 0 de D_POSTMERGE_PROJECTION_WRITER_2026_10)."
  fi
  [ "$_rebases" -le "$_REBASE_MAX" ] \
    || die "PR #${PR} segue ${_rb_state} depois de ${_REBASE_MAX} rebase(s) automático(s) — algo volta a conflitar (ou o main não para de andar) a cada vez; não entro em laço. Investigue a branch '${HEAD_REF}' ou rode de novo com o main parado."
  # SAC-80: o rebase da branch reescreveria os commits que o .kg.yaml cita — e aí nem o --merge-commit
  # os salva (a citação passa a apontar para o commit velho, órfão). Conflito assim se resolve à mão.
  [ -z "${KG_BRANCH_SHAS}" ] \
    || die "PR #${PR} está ${_rb_state} e o .kg.yaml cita commit da própria branch ($(printf '%s' "${KG_BRANCH_SHAS}" | awk -F'\t' 'NF{printf "%s%s", (n++?" ":""), $1}')) — o auto-rebase reescreveria esses SHAs e a citação ficaria órfã (SAC-80). Resolva o conflito mergeando a base na branch, à mão, e rode de novo."
  _wt="$(_wt_of_branch "${HEAD_REF}")"
  if [ -z "$_wt" ] && [ "${_FOREIGN_REPO}" -eq 1 ]; then
    # o adotante não tem o motor: a mensagem diz o comando que ELE tem (o #230 do kg-ssot recebeu o do core)
    die "PR #${PR} está ${_rb_state} (o GitHub não dispara CI em PR em conflito, e não testa a árvore combinada de PR atrás) e a branch '${HEAD_REF}' não está em nenhuma worktree deste repo — não rebaseio às cegas. Este repo não tem ops/pr-finalize.sh; na worktree da branch: git fetch origin ${_BASE_REF} && git rebase origin/${_BASE_REF} — conflito só em ${_FOREIGN_PROJ// /, }: regenere (bash .claude/validation/kg-backlog-project.sh --write ; bash .claude/validation/kg-trace.sh . --emit-index > /tmp/idx.tsv && mv /tmp/idx.tsv docs/onion/kg-read-index.tsv, rc 3 = índice vazio só se a base também o tem vazio), git add, git rebase --continue; conflito em outro arquivo: resolva à mão. Depois rode o lint (bash .claude/validation/lint-artifacts.sh), git push --force-with-lease, e este comando de novo."
  fi
  [ -n "$_wt" ] \
    || die "PR #${PR} está ${_rb_state} (o GitHub não dispara CI em PR em conflito, e não testa a árvore combinada de PR atrás) e a branch '${HEAD_REF}' não está em nenhuma worktree deste repo — não rebaseio às cegas. Rode na worktree da branch: bash ops/pr-finalize.sh --rebase --push ; depois rode este comando de novo."
  _old_head="${HEAD_SHA}"
  _wt_before="$(git -C "$_wt" rev-parse HEAD 2>/dev/null)"
  if [ ! -f "${_wt}/ops/pr-finalize.sh" ]; then
    # (a) repo alheio: o rebase próprio do verificado (ver "AUTO-REBASE EM REPO ALHEIO", lá em cima)
    [ "${MERGE_COMMIT}" -eq 1 ] \
      && die "PR #${PR} está ${_rb_state}, o modo é --merge-commit e a worktree ${_wt} não tem ops/pr-finalize.sh — não rebaseio: o rebase linearizaria o merge que é o conteúdo da branch. Mergeie a base na branch à mão (git merge origin/${_BASE_REF}), espere o CI e rode de novo. Nada foi mergeado."
    _FOREIGN_RB=1
    # neutro: na recusa ele entra no rastro também, e não pode narrar o que não aconteceu
    _RB_ENGINE_TEXT="Caminho de repo alheio de \`ops/pr-merge-verified.sh\` (o repo não tem \`ops/pr-finalize.sh\`): só \`docs/backlog.md\` e \`docs/onion/kg-read-index.tsv\` se resolvem sozinhas, pelo gerador do próprio repo; qualquer outro conflito aborta com a branch no head anterior."
    say "PR #${PR} ${_rb_state} — auto-rebase ${_rebases}/${_REBASE_MAX} na worktree ${_wt} (repo sem ops/pr-finalize.sh: rebase próprio, só projeção conhecida se resolve)"
    if ! _foreign_rebase "${_wt}" "${_BASE_REF}" "${_old_head}"; then
      _rebase_trail "${_old_head}" "—" "${_FR_MSG}" "${_rebases}/${_REBASE_MAX}" "${_FR_OUTCOME:-recusado} — nada mudou na branch; resolver à mão" "${_FR_OUTCOME:-recusado}"
      die "auto-rebase RECUSADO (repo sem ops/pr-finalize.sh): ${_FR_MSG}. Nada foi mergeado."
    fi
    printf '%s' "${_FR_OUT}" | sed 's/^/  /'
    # o de sucesso sai do que a função DISSE que fez (o lint só é citado se rodou)
    _RB_ENGINE_TEXT="${_RB_ENGINE_TEXT} Nesta rodada: $(printf '%s' "${_FR_OUT}" | paste -sd ';' - | sed 's/;/; /g')."
    _rb_out="${_FR_OUT}"; _rb_rc=0
  else
  say "PR #${PR} ${_rb_state} — auto-rebase ${_rebases}/${_REBASE_MAX} na worktree ${_wt} (pr-finalize --rebase --push)"
  _rb_out="$(cd "$_wt" && bash ops/pr-finalize.sh --rebase --push 2>&1)"; _rb_rc=$?
  fi
  # o driver das famílias (SAC-146) RESOLVEU a fonte: a branch local ficou rebaseada, e o pr-finalize parou no
  # carimbo, porque o hash de código muda pelo contexto. Não é "conflito de FONTE", nem "nada mudou".
  _fam="$(LC_ALL=C grep -o 'conflito de famílias acrescentadas lado a lado resolvido em [^ ]*' <<< "$_rb_out" | sed 's/^.* resolvido em //' | sort -u | paste -sd, -)"
  if [ "$_rb_rc" -ne 0 ] && [ -n "${_fam}" ] && ! grep -q 'conflito REAL em ' <<< "$_rb_out"; then
    _rebase_trail "${_old_head}" "—" "famílias da bancada acrescentadas lado a lado: ${_fam} (resolvido pelo driver)" "${_rebases}/${_REBASE_MAX}" "PARADO — rebaseado só na worktree, NÃO enviado; o resíduo pede re-revisão" "parado: rebaseado só na worktree, o resíduo pede re-revisão"
    die "auto-rebase PARADO no carimbo do resíduo: o driver das famílias resolveu ${_fam}, a branch em ${_wt} está rebaseada e NÃO foi enviada, e o hash de código mudou pelo contexto — re-revise (reviewed_diff_sha256: pendente) e rode bash ops/pr-finalize.sh --push lá. pr-finalize disse: $(printf '%s\n' "$_rb_out" | tail -2 | tr '\n' ' ')"
  fi
  if [ "$_rb_rc" -ne 0 ]; then
    _real="$(grep -o 'conflito REAL em [^ ]*' <<< "$_rb_out" | head -1)"
    if [ -n "${_real}" ]; then _rb_outcome="recusado: conflito de fonte em ${_real#conflito REAL em }"
    else _rb_outcome="recusado: pr-finalize rc=${_rb_rc}"; fi
    _rebase_trail "${_old_head}" "—" "fonte: ${_real:-pr-finalize rc=${_rb_rc}}" "${_rebases}/${_REBASE_MAX}" "${_rb_outcome} — nada mudou na branch; resolver à mão" "${_rb_outcome}"
    die "auto-rebase RECUSADO (${_real:-rc=${_rb_rc}}) — conflito de FONTE não se resolve sozinho e não escondo conflito real; resolva à mão na worktree ${_wt}. pr-finalize disse: $(printf '%s\n' "$_rb_out" | tail -2 | tr '\n' ' ')"
  fi
  _new="$(git -C "$_wt" rev-parse HEAD 2>/dev/null)"
  # ══ A API DO PR ATRASA O PUSH (SAC-85, medido em 2026-10-09 no merge do #985) ══════════════════
  # O push da branch rebaseada já tinha chegado (remoto em 74f0441a), e a leitura do `headRefOid`,
  # feita logo depois, ainda devolveu o head VELHO (4f535a00). O script parou dizendo que "a branch
  # rebaseada não é a do PR" — diagnóstico errado: era só a API do PR que ainda não tinha refletido
  # o push. A cura separa as duas perguntas:
  #   · o FATO é o ref remoto da branch (`git ls-remote`), não a API do PR. Se ele é legível e NÃO é
  #     o HEAD da worktree, o push não chegou à branch do PR → paro na hora, sem esperar nada;
  #   · a API do PR é ESPERADA, com teto (ONION_MERGE_HEAD_SYNC_TRIES × ONION_MERGE_HEAD_SYNC_POLL),
  #     porque o `mergeable` e as runs lidas adiante dependem de o PR já enxergar o head novo.
  #     Teto vencido = paro e digo qual das duas coisas aconteceu, nunca sigo com o head velho.
  if [ -n "$_new" ]; then
    _ls="$(git -C "$_wt" ls-remote origin "refs/heads/${HEAD_REF}" 2>/dev/null)" || _ls=""
    _remote="${_ls%%[[:space:]]*}"
    [ -n "$_remote" ] && [ "$_remote" != "$_new" ] \
      && die "depois do auto-rebase a branch remota '${HEAD_REF}' está em ${_remote:0:8}, e o HEAD da worktree em ${_new:0:8} — o push não chegou à branch do PR; paro."
    _sync_max="${ONION_MERGE_HEAD_SYNC_TRIES:-24}"; _sync_poll="${ONION_MERGE_HEAD_SYNC_POLL:-5}"
    _s=0
    while :; do
      HEAD_SHA="$(gh pr view "$PR" "${REPO_ARG[@]}" --json headRefOid --jq '.headRefOid' 2>/dev/null)"
      [ "$HEAD_SHA" = "$_new" ] && break
      _s=$((_s+1))
      if [ "$_s" -ge "$_sync_max" ]; then
        [ -n "$_remote" ] \
          && die "depois do auto-rebase a branch remota já está em ${_new:0:8}, mas o PR #${PR} ainda mostra o head ${HEAD_SHA:0:8} após ${_sync_max} leituras — o GitHub não refletiu o push; rode este comando de novo em instantes."
        die "depois do auto-rebase o head do PR (${HEAD_SHA:0:8}) não virou o HEAD da worktree (${_new:0:8}) em ${_sync_max} leituras, e o ref remoto não foi legível — ou a branch rebaseada não é a do PR, ou o GitHub não refletiu o push; paro."
      fi
      sleep "${_sync_poll}"
    done
  else
    HEAD_SHA="$(gh pr view "$PR" "${REPO_ARG[@]}" --json headRefOid --jq '.headRefOid' 2>/dev/null)"
  fi
  # a causa vem do que o pr-finalize RESOLVEU (uma linha por projeção em conflito); sem nenhuma, o
  # rebase local foi limpo e quem disse CONFLICTING foi o forge — e isso também é dito, não inventado.
  _proj="$(LC_ALL=C grep -o 'conflito de projeção resolvido em [^ ]*' <<< "$_rb_out" | sed 's/^conflito de projeção resolvido em //' | LC_ALL=C sort -u | paste -sd, - | sed 's/,/, /g')"
  if [ -n "${_fam}" ]; then _causa="famílias da bancada acrescentadas lado a lado: ${_fam} (resolvido pelo driver)${_proj:+; projeção gerada: ${_proj}}"
  elif [ -n "${_proj}" ]; then _causa="projeção gerada: ${_proj}"
  elif [ "${_rb_state}" = CONFLICTING ]; then _causa="nenhum arquivo em conflito no rebase local (o forge marcou CONFLICTING)"
  else _causa="base atrás da ponta: ${_rb_state} — strict local"; fi
  # repo alheio: o caminho rápido lê o ruleset e a lib de projeções do CORE, que não descrevem o alvo — espera
  if [ "${_FOREIGN_RB}" -eq 1 ]; then
    SKIP_DECISION="espera: repo sem ops/pr-finalize.sh — o caminho rápido (merge sem o CI do head novo) não vale fora do core"
  elif _skip_ci_decide "${_old_head}" "${HEAD_SHA}" "${_wt}" "${_wt_before}"; then
    SKIP_CI=1; GATE_SHA="${_old_head}"
    say "decisão: merge ${SKIP_DECISION}"
    _rebase_trail "${_old_head}" "${HEAD_SHA}" "${_causa}" "${_rebases}/${_REBASE_MAX}" "rebaseado e enviado; merge ${SKIP_DECISION} (bypass do ruleset com --match-head-commit; rede: bancada completa no push ao main)"
    break
  fi
  say "decisão: ${SKIP_DECISION}"
  _rebase_trail "${_old_head}" "${HEAD_SHA}" "${_causa}" "${_rebases}/${_REBASE_MAX}" "rebaseado e enviado; o CI do head novo roda antes do merge (${SKIP_DECISION})"
  if [ "${NO_WAIT_AFTER_REBASE}" -eq 1 ]; then
    printf '↻ PR #%s rebaseado (%s → %s, %s/%s) — saio rc=4 SEM esperar o CI do head novo (--no-wait-after-rebase)\n' \
      "$PR" "${_old_head:0:8}" "${HEAD_SHA:0:8}" "${_rebases}" "${_REBASE_MAX}"
    exit 4
  fi
  _mg="$(pr_mergeable)"
  _n=0; while [ "$_mg" = UNKNOWN ] && [ "$_n" -lt 6 ]; do sleep "${_POLL_SECS}"; _mg="$(pr_mergeable)"; _n=$((_n+1)); done
  # o main pode ter andado DURANTE o rebase: relê a distância do head novo; ilegível ⇒ não mergeio
  _behind="$(_behind_base)" \
    || die "depois do auto-rebase não consegui medir se o head ${HEAD_SHA:0:8} está na ponta de '${_BASE_REF}' — não mergeio sem saber"
done
if [ "$_rebases" -gt 0 ] && [ "${SKIP_CI}" -eq 0 ]; then
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
# ⚠️ UMA LINHA POR NOME, A MAIS RECENTE (medido no PR #1076, 2026-10-13): um 2º run do workflow no MESMO
# head (label posta/tirada, re-disparo) cria OUTRA suíte, e a API devolve as DUAS check-runs de mesmo nome
# mesmo sem `filter=all` — e o `statusCheckRollup` também. Sem dedupe, um veredito velho em falha bloquearia
# para sempre o verde novo, e dois verdes viravam "SUCCESS\nSUCCESS" ≠ SUCCESS. O id cresce no tempo, então
# o maior id do nome é o run vigente (o mesmo que o GitHub mostra no `gh pr checks`).
# (o _LATEST_PER_NAME_JQ mora lá em cima, junto da decisão de pular o CI, que também o usa)
# o head JULGADO: o do PR, ou — no merge sem o CI do head novo — o head ANTERIOR, cujo verde foi lido
GATE_SHA="${GATE_SHA:-${HEAD_SHA}}"
[ "${SKIP_CI}" -eq 1 ] && say "gates de checks ancorados no head ANTERIOR ${GATE_SHA:0:8} (o merge vai no head ${HEAD_SHA:0:8} por --match-head-commit)"
_cr_err="$(mktemp)"
head_runs="$(gh api "repos/${OWNER_REPO}/commits/${GATE_SHA}/check-runs?per_page=100" \
  --jq "${_LATEST_PER_NAME_JQ}" 2>"${_cr_err}")"
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
  grep -qF 'MORREU' <<< "${_lint_out}" \
    && die "--ci-inoperante: o lint MORREU antes do sumário — não pude julgar, logo não libero."
  [ "${_lint_rc}" -eq 0 ] \
    || die "--ci-inoperante: lint local rc=${_lint_rc} (há HARD). A cobertura que substituiria o CI está VERMELHA — recusa. $(printf '%s\n' "${_lint_out}" | grep -m1 'Violações HARD')"
  _bench_out="$(LC_ALL=C bash "${REPO_ROOT:-$(git rev-parse --show-toplevel)}/.claude/validation/lint-selftest.sh" --jobs auto 2>&1)"; _bench_rc=$?
  grep -qF 'ABORTOU' <<< "${_bench_out}" \
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
  grep -qE '^[0-9]+$' <<< "${_bench_pass}" \
    || die "--ci-inoperante: não consegui LER a contagem da bancada do sumário (li '${_bench_pass}'). O veredito seria correto pelo rc, mas eu não registro no PR um número que não sei — e registro sem número não audita. Recusa."
  say "    ✓ gate local EXERCIDO: lint 0 HARD · bancada ${_bench_pass:-?} casos, 0 falhas"
  CI_INOPERANTE_PROVADO="rajada de ${_streak} startup_failure no topo do forge · lint 0 HARD · bancada ${_bench_pass:-?} casos/0 falhas"
else
printf '%s\n' "$head_runs" | awk -F'\t' '$2!="completed"{exit 1}' \
  || die "check-run do head ${HEAD_SHA:0:8} ainda não-completo — merge recusado (esperar não é opcional)"
fi
# ══ REVISÃO DESLIGADA ≠ REVISÃO APROVADA (2026-10-13, D_REVIEW_MODE_SWITCH_PADRAO_OFF) ══════════
# Com o interruptor (`vars.ONION_REVIEW_MODE`, padrão off), o `onion-review-verdict` sai VERDE quando
# a revisão foi desligada — e verde, sozinho, diria "aprovado". A distinção vem da ANOTAÇÃO-marca do
# check (`review-mode-decide.sh --print-marker`), lida aqui: desligada NÃO pede dispensa nem comenta,
# mas é DITA como "não medida", nunca como aprovação.
# ⚠️ E O DESLIGAMENTO NÃO APAGA UM ACHADO: se um run ANTERIOR do veredito NESTE MESMO head revisou e
# reprovou ("apontou N violação"), e o mais recente diz "desligada" (label review:ia removida depois,
# modo trocado para off), o achado continua de pé — o merge exige a mesma dispensa nomeada de sempre.
# Sem isto, tirar a label depois do parecer seria o jeito mudo de virar um vermelho em verde.
# Leitura que falha = recusa (fail-closed), como a dos check-runs acima.
_REVIEW_OFF=""; _REVIEW_PRIOR_REPROVOU=""
_rm_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/review/review-mode-decide.sh"
if [ -n "$head_runs" ] && [ -f "${_rm_script}" ]; then
  _rm_marker="$(bash "${_rm_script}" --print-marker)"
  _rv_runs="$(gh api "repos/${OWNER_REPO}/commits/${GATE_SHA}/check-runs?check_name=onion-review-verdict&filter=all&per_page=100" \
    --jq '[.check_runs[]] | sort_by(.id) | reverse | .[] | "\(.id)\t\(.conclusion // "-")"' 2>/dev/null)" \
    || die "não consegui LER o histórico do onion-review-verdict no head ${HEAD_SHA:0:8} — sem ele não sei se a revisão foi desligada ou se um achado anterior foi apagado. Tente de novo."
  _rv_first=1
  while IFS=$'\t' read -r _rv_id _rv_concl; do
    [ -n "${_rv_id}" ] || continue
    if [ "${_rv_first}" -eq 1 ]; then
      _rv_first=0
      [ "${_rv_concl}" = "success" ] || break       # o mais recente não é verde: o caminho de sempre decide
      _rv_ann="$(gh api "repos/${OWNER_REPO}/check-runs/${_rv_id}/annotations" --jq '.[].message' 2>/dev/null)" \
        || die "não consegui LER as anotações do onion-review-verdict (check-run ${_rv_id}) — não sei se o verde é aprovação ou desligamento."
      _REVIEW_OFF="$(LC_ALL=C grep -m1 -F -- "${_rm_marker}" <<< "${_rv_ann}" || true)"
      [ -n "${_REVIEW_OFF}" ] || break               # verde que não é desligamento: aprovação de verdade
      continue
    fi
    [ "${_rv_concl}" = "failure" ] || continue
    _rv_ann="$(gh api "repos/${OWNER_REPO}/check-runs/${_rv_id}/annotations" --jq '.[].message' 2>/dev/null)" \
      || die "não consegui LER as anotações do run anterior ${_rv_id} do onion-review-verdict — não sei se ele apontou violação."
    if LC_ALL=C grep -qE 'apontou [1-9]' <<< "${_rv_ann}"; then _REVIEW_PRIOR_REPROVOU="${_rv_id}"; break; fi
  done <<< "${_rv_runs}"
fi
if [ -n "${_REVIEW_PRIOR_REPROVOU}" ]; then
  _dispensado onion-review-verdict \
    || die "o onion-review-verdict mais recente diz revisão DESLIGADA, mas um run anterior NESTE head (check-run ${_REVIEW_PRIOR_REPROVOU}) REVISOU e APONTOU violação. Desligar depois não apaga o achado: corrija, ponha a label review:ia de volta, ou dispense nomeado (--dispensa onion-review-verdict --motivo \"<por que o achado não procede>\")."
  # entra na lista de falhos para a dispensa NÃO ser recusada como preventiva: o achado existe
  head_runs="${head_runs}"$'\n'"onion-review-verdict"$'\t'"completed"$'\t'"failure"
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
  grep -qxF "$_d" <<< "$_falhos" \
    || die "'--dispensa ${_d}' recusada: esse check NÃO está falhando no head ${HEAD_SHA:0:8}. Dispensa preventiva é cheque em branco para a próxima vez que ele falhar."
done
if [ "${#DISPENSA[@]}" -gt 0 ]; then
  say "⚠️  check(s) DISPENSADO(S) por decisão humana: ${DISPENSA[*]}"
  say "    motivo: ${REASON}"
else
  say "✓ check-runs ancorados no head ${HEAD_SHA:0:8}: todos completos, nenhum falho"
fi

if [ "${SKIP_CI}" -eq 1 ]; then
  # `gh pr checks` e o statusCheckRollup leem o head ATUAL do PR — o novo, ainda sem checks. Lê-los aqui
  # seria julgar o head errado; o ângulo ancorado por SHA (acima) é a leitura deste caminho.
  say "2º ângulo (gh pr checks) não lido: ele segue o head novo ${HEAD_SHA:0:8}, que não tem CI por desenho deste caminho"
  checks=""
else
checks="$(gh pr checks "$PR" "${REPO_ARG[@]}" 2>&1)"
GHRC=$?
[ -z "$checks" ] && die "não consegui ler os checks do PR #${PR} (saída vazia, rc=${GHRC})"
printf '%s\n' "$checks" | sed 's/^/  /'
printf '%s\n' "$checks" | awk '{print $2}' | grep -q pending && die "há check PENDENTE — merge recusado (esperar não é opcional)"
fi
# mesma leitura pelo 2º ângulo (`gh pr checks`), com a MESMA dispensa nome-a-nome
_f2="$(printf '%s\n' "$checks" | awk '$2=="fail"{print $1}')"
_n2=""
while IFS= read -r _f; do
  [ -n "$_f" ] || continue
  _dispensado "$_f" || _n2="${_n2}${_f} "
done <<< "$_f2"
[ -n "${_n2// /}" ] && die "há check FALHO não dispensado: ${_n2}— merge recusado"

if [ "${SKIP_CI}" -eq 1 ]; then
  verdict="$(awk -F'\t' '$1=="onion-review-verdict"{print toupper($3); exit}' <<< "${head_runs}")"
else
verdict="$(gh pr view "$PR" "${REPO_ARG[@]}" --json statusCheckRollup \
  --jq '[.statusCheckRollup[] | select(.name=="onion-review-verdict")] | sort_by(.startedAt // .completedAt // "") | last | select(. != null) | (.conclusion // .state)' 2>/dev/null)"
fi
if [ -z "$verdict" ]; then
  say "⚠️  sem linha 'onion-review-verdict' neste repo — a revisão adversarial NÃO foi medida aqui."
  say "    (repos sem o gate: o resíduo da REGRA 56 e a passada humana são a única cobertura)"
elif [ "$verdict" != "SUCCESS" ] && _dispensado onion-review-verdict; then
  say "⚠️  onion-review-verdict = ${verdict} — DISPENSADO por decisão humana, não aprovado."
  say "    O gate determinístico (lint + bancada) é a cobertura que sobra; a semântica NÃO foi medida."
elif [ "$verdict" != "SUCCESS" ]; then
  die "onion-review-verdict = ${verdict} — o revisor NÃO aprovou (o 'pass' do onion-review é soft e não vale)"
elif [ -n "${_REVIEW_PRIOR_REPROVOU}" ]; then
  say "⚠️  onion-review-verdict = SUCCESS por DESLIGAMENTO, sobre um achado anterior neste head (check-run ${_REVIEW_PRIOR_REPROVOU}) — DISPENSADO por decisão humana, não aprovado."
elif [ -n "${_REVIEW_OFF}" ]; then
  say "⊘ onion-review-verdict = SUCCESS por revisão DESLIGADA, não por aprovação — a semântica NÃO foi medida; sem dispensa, por desenho (D_REVIEW_MODE_SWITCH_PADRAO_OFF)."
  say "    anotação: ${_REVIEW_OFF}"
else
  say "✓ onion-review-verdict = SUCCESS (fonte lida, não inferida)"
fi

# STRICT LOCAL, ÚLTIMA LEITURA (FASE 0 de D_POSTMERGE_PROJECTION_WRITER_2026_10): entre o auto-rebase (ou a
# 1ª leitura) e este ponto pode ter passado a espera inteira do CI — e o main anda nesse meio-tempo. O
# --match-head-commit amarra o HEAD, não a BASE: se a base andou, o forge rebasearia no merge e a árvore
# combinada seria de novo uma que o CI não viu. Relê ANTES de qualquer registro no PR (dispensa, CI morto).
_behind="$(_behind_base)" \
  || die "não consegui medir, logo antes do merge, se o head ${HEAD_SHA:0:8} está na ponta de '${_BASE_REF}' — não mergeio sem saber. Nada foi mergeado."
if [ "${_behind}" -gt 0 ]; then
  if [ "${NO_WAIT_AFTER_REBASE}" -eq 1 ]; then
    printf '↻ PR #%s: o main andou %s commit(s) depois da leitura (head %s) — saio rc=4 sem mergear: a série o traz de novo e o auto-rebase o põe na ponta\n' \
      "$PR" "${_behind}" "${HEAD_SHA:0:8}"
    exit 4
  fi
  die "o main andou ${_behind} commit(s) desde a leitura, e o head ${HEAD_SHA:0:8} não está mais na ponta de '${_BASE_REF}' — o merge entraria com a árvore combinada que o CI não viu (strict local). Nada foi mergeado; rode de novo (o auto-rebase o traz para a ponta)."
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
  _out_check="$(gh api "repos/${OWNER_REPO}/commits/${GATE_SHA}/check-runs?per_page=100" \
    --jq '.check_runs[] | select(.name=="onion-review-verdict") | ((.output.title // "") + " " + (.output.summary // ""))' 2>/dev/null || true)"
  if [ -n "${_REVIEW_PRIOR_REPROVOU}" ]; then
    _NOTA_DISPENSA="Um run anterior deste check **neste head** (check-run ${_REVIEW_PRIOR_REPROVOU}) **mediu e apontou**, e o mais recente diz revisão **desligada** — a dispensa afirma que o achado **não procede**; desligar não o apagou."
  elif LC_ALL=C grep -qiE 'apontou[^0-9]*[0-9]+|violaç|violac' <<< "${_out_check}"; then
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
# HEAD AMARRADO EM TODO CAMINHO (TOCTOU curado em 2026-10-27, caso da curadoria nos PRs #117/#118 de
# 2026-10-26): os gates julgam os check-runs do HEAD_SHA lido (a cura do #634), mas até aqui só o caminho
# sem o CI do head novo passava `--match-head-commit`. Nos outros (rebase, squash, --merge-commit), um
# push que caísse entre a leitura do CI e o merge fazia o forge mergear um head que ninguém julgou — a
# curadoria teve de conferir à mão que o CI era do head novo. Agora o forge SEMPRE recebe o head julgado
# (depois de um auto-rebase, é o head novo cujo CI se esperou, ou o anterior cujo verde vale no caminho
# rápido) e recusa se ele andou; a recusa é lida pelo ESTADO e pelo head relido adiante, nunca pela prosa.
# O bypass do ruleset (--admin) continua SÓ no caminho sem o CI do head novo: nos demais o ruleset vale.
[ -n "${HEAD_SHA}" ] || die "não tenho o head julgado (HEAD_SHA vazio) logo antes do merge — sem ele o forge não pode amarrar o merge ao head que o CI julgou. Nada foi mergeado."
JUDGED_HEAD="${HEAD_SHA}"
MERGE_EXTRA=(--match-head-commit "${JUDGED_HEAD}")
[ "${SKIP_CI}" -eq 1 ] && MERGE_EXTRA=(--admin --match-head-commit "${JUDGED_HEAD}")
# o forge recusou e o head do PR já não é o julgado: um push caiu entre o julgamento e o merge.
# Lido pelo headRefOid (dado), não pela mensagem do forge. Ilegível = não afirmo que mudou.
_head_moved_die() {
  local _now
  _now="$(gh pr view "$PR" "${REPO_ARG[@]}" --json headRefOid --jq '.headRefOid' 2>/dev/null)" || return 0
  [ -n "${_now}" ] && [ "${_now}" != "${JUDGED_HEAD}" ] || return 0
  die "o head mudou depois do julgamento (${JUDGED_HEAD:0:8} → ${_now:0:8}); rode de novo. O forge recusou o merge (--match-head-commit) e nada foi mergeado: o head ${_now:0:8} não teve o CI julgado. Saída do gh: $(printf '%s' "$merge_out" | tail -1 | cut -c1-200)"
}
if [ "${MERGE_COMMIT}" -eq 1 ]; then
  say "modo: --merge-commit (gh pr merge --merge) — mesmos gates, só muda como o histórico entra"
  merge_out="$(gh pr merge "$PR" "${REPO_ARG[@]}" --merge "${MERGE_EXTRA[@]}" "${DEL[@]}" 2>&1)"; rc=$?
else
  merge_out="$(gh pr merge "$PR" "${REPO_ARG[@]}" --rebase "${MERGE_EXTRA[@]}" "${DEL[@]}" 2>&1)"; rc=$?
fi
if [ "$rc" -ne 0 ] && [ "${MERGE_COMMIT}" -eq 0 ]; then
  if grep -qi "can't be rebased\|cannot be rebased" <<< "$merge_out"; then
    say "⚠️  --rebase recusado (stack re-apontada); degradando p/ --squash com os mesmos gates"
    merge_out="$(gh pr merge "$PR" "${REPO_ARG[@]}" --squash "${MERGE_EXTRA[@]}" "${DEL[@]}" 2>&1)"; rc=$?
  fi
fi
# o forge RECUSOU o merge sem o CI do head novo (bypass negado, head andou): não é falha do PR — é voltar
# a ESPERAR. Na série, rc 4 (o CI do head novo é esperado fora do lock); direto, para dizendo o que fazer.
if [ "$rc" -ne 0 ] && [ "${SKIP_CI}" -eq 1 ]; then
  case "$(pr_state)" in
    MERGED\|*) : ;;   # mergeou e falhou depois (limpeza): o bloco abaixo prova pelo estado
    *)
      # na série (rc 4) o head que andou também volta à fila e é re-julgado; direto, a recusa diz qual foi
      if [ "${NO_WAIT_AFTER_REBASE}" -eq 1 ]; then
        printf '↻ PR #%s: o forge RECUSOU o merge sem o CI do head novo (%s) — saio rc=4: o head julgado era %s; o CI do head atual é esperado e o merge volta pelo caminho de sempre\n' \
          "$PR" "$(printf '%s' "$merge_out" | tail -1 | cut -c1-200)" "${HEAD_SHA:0:8}"
        exit 4
      fi
      _head_moved_die
      die "o forge RECUSOU o merge sem o CI do head novo ($(printf '%s' "$merge_out" | tail -1 | cut -c1-200)) — nada foi mergeado. Espere o CI do head ${HEAD_SHA:0:8} e rode de novo (ou use --wait-ci-after-rebase)." ;;
  esac
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
  # não mergeou e o head já não é o julgado: a recusa do --match-head-commit, nomeada antes de qualquer
  # leitura da prosa do gh (que muda de versão para versão)
  case "$state_after" in MERGED\|*) : ;; *) _head_moved_die ;; esac
  # O `gh` dizendo que o PR JÁ estava mergeado nunca pode virar sucesso deste run — barra antes
  # de qualquer aritmética de data, e sem depender de relógio nenhum.
  if grep -qi "already been merged\|not mergeable" <<< "$merge_out"; then
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
    # SEMPRE (SAC-143, 2026-10-15): a worktree que tem `main` em uso — o checkout principal, de onde o harness lê os
    # hooks — sobe por fast-forward. Sem isto, hook mergeado não valia na sessão (36 commits atrás, medido). É a
    # mesma cortesia do --sync: nunca muda o rc do merge.
    [ -f "$(dirname "${BASH_SOURCE[0]}")/sync-main-worktree.sh" ] && say "$(bash "$(dirname "${BASH_SOURCE[0]}")/sync-main-worktree.sh")"
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
