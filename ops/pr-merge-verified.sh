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
#   onion-review-verdict → ele próprio diz de si: "não bloqueia o merge — informa. A decisão
#   de mergear sem revisão semântica é humana e deve ser consciente". O escape é a forma
#   CONSCIENTE dessa decisão; sem ele, o caminho real vira mergear por fora do gate.
_DISPENSAVEIS=(onion-review-verdict)
DISPENSA=(); MOTIVO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO_ARG=(--repo "$2"); shift 2 ;;
    --dispensa) DISPENSA+=("${2:?--dispensa exige o NOME do check}"); shift 2 ;;
    --motivo) MOTIVO="${2:?--motivo exige texto}"; shift 2 ;;
    # BASE DE STACK: apagar a branch da base FECHA o PR filho (não re-aponta) — está
    # registrado como mecânica de stack desde 2026-07. Ao mergear uma base com PR
    # empilhado em cima, use --keep-branch; o GitHub re-aponta o filho, e a branch se
    # apaga à mão depois. Sem esta opção o mecanismo teria destruído um PR ao "acertar".
    --keep-branch) DEL=(); shift ;;
    --sync) DO_SYNC=1; shift ;;
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
  [ -n "$MOTIVO" ] || die "--dispensa exige --motivo: dispensa sem razão escrita é override, e override não se audita"
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
head_runs="$(gh api "repos/${OWNER_REPO}/commits/${HEAD_SHA}/check-runs?per_page=100" \
  --jq '.check_runs[] | .name + "\t" + .status + "\t" + (.conclusion // "-")' 2>/dev/null)"
[ -z "$head_runs" ] && die "ZERO check-runs registrados para o head ${HEAD_SHA:0:8} — provável janela pós-push; espere os checks nascerem (a corrida do #634)"
printf '%s\n' "$head_runs" | awk -F'\t' '$2!="completed"{exit 1}' \
  || die "check-run do head ${HEAD_SHA:0:8} ainda não-completo — merge recusado (esperar não é opcional)"
# Falhos do head, um por linha — e a dispensa é aplicada NOME A NOME, nunca em bloco.
_falhos="$(printf '%s\n' "$head_runs" | awk -F'\t' '$3=="failure"||$3=="cancelled"||$3=="timed_out"{print $1}')"
_nao_dispensados=""
while IFS= read -r _f; do
  [ -n "$_f" ] || continue
  _dispensado "$_f" || _nao_dispensados="${_nao_dispensados}${_f} "
done <<< "$_falhos"
[ -n "${_nao_dispensados// /}" ] \
  && die "check-run do head ${HEAD_SHA:0:8} concluiu em falha e NÃO foi dispensado: ${_nao_dispensados}— merge recusado"
# Dispensa PREVENTIVA é recusada: só se dispensa o que de fato está falhando agora.
for _d in "${DISPENSA[@]:-}"; do
  [ -n "$_d" ] || continue
  printf '%s\n' "$_falhos" | grep -qxF "$_d" \
    || die "'--dispensa ${_d}' recusada: esse check NÃO está falhando no head ${HEAD_SHA:0:8}. Dispensa preventiva é cheque em branco para a próxima vez que ele falhar."
done
if [ "${#DISPENSA[@]}" -gt 0 ]; then
  say "⚠️  check(s) DISPENSADO(S) por decisão humana: ${DISPENSA[*]}"
  say "    motivo: ${MOTIVO}"
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
if [ "${#DISPENSA[@]}" -gt 0 ]; then
  _reg="$(printf '%s\n' \
    "## ⚠️ Merge com check DISPENSADO" \
    "" \
    "Este PR foi mergeado por \`ops/pr-merge-verified.sh\` com dispensa **nomeada** de check." \
    "" \
    "| | |" \
    "|---|---|" \
    "| check(s) dispensado(s) | \`${DISPENSA[*]}\` |" \
    "| motivo | ${MOTIVO} |" \
    "| head | \`${HEAD_SHA}\` |" \
    "" \
    "Os demais checks do head passaram — a dispensa é **nome a nome**, e qualquer outro check falho teria recusado o merge. O que este check mediria **não foi medido**." )"
  gh pr comment "$PR" "${REPO_ARG[@]}" --body "$_reg" >/dev/null 2>&1 \
    || die "não consegui REGISTRAR a dispensa no PR #${PR} — merge abortado. O registro é precondição: dispensa que só existe no meu terminal não se audita."
  say "✓ dispensa registrada no PR #${PR} (comentário), antes do merge"
fi

t0="$(date -u +%s)"
merge_out="$(gh pr merge "$PR" "${REPO_ARG[@]}" --rebase "${DEL[@]}" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then
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
