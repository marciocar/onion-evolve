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
# Uso: bash ops/pr-merge-verified.sh <numero> [--repo owner/nome]
set -uo pipefail

PR="${1:?uso: $0 <numero-do-PR> [--repo owner/nome] [--keep-branch]}"; shift || true
REPO_ARG=()
DEL=(--delete-branch)
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO_ARG=(--repo "$2"); shift 2 ;;
    # BASE DE STACK: apagar a branch da base FECHA o PR filho (não re-aponta) — está
    # registrado como mecânica de stack desde 2026-07. Ao mergear uma base com PR
    # empilhado em cima, use --keep-branch; o GitHub re-aponta o filho, e a branch se
    # apaga à mão depois. Sem esta opção o mecanismo teria destruído um PR ao "acertar".
    --keep-branch) DEL=(); shift ;;
    *) shift ;;
  esac
done

say() { printf '  %s\n' "$*"; }
die() { printf '✗ %s\n' "$*"; exit 1; }

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
HEAD_SHA="$(gh pr view "$PR" "${REPO_ARG[@]}" --json headRefOid --jq '.headRefOid' 2>/dev/null)"
[ -z "$HEAD_SHA" ] && die "não consegui ler o headRefOid do PR #${PR}"
OWNER_REPO="$(gh pr view "$PR" "${REPO_ARG[@]}" --json headRepository,headRepositoryOwner \
  --jq '.headRepositoryOwner.login + "/" + .headRepository.name' 2>/dev/null)"
head_runs="$(gh api "repos/${OWNER_REPO}/commits/${HEAD_SHA}/check-runs?per_page=100" \
  --jq '.check_runs[] | .name + "\t" + .status + "\t" + (.conclusion // "-")' 2>/dev/null)"
[ -z "$head_runs" ] && die "ZERO check-runs registrados para o head ${HEAD_SHA:0:8} — provável janela pós-push; espere os checks nascerem (a corrida do #634)"
printf '%s\n' "$head_runs" | awk -F'\t' '$2!="completed"{exit 1}' \
  || die "check-run do head ${HEAD_SHA:0:8} ainda não-completo — merge recusado (esperar não é opcional)"
printf '%s\n' "$head_runs" | awk -F'\t' '$3=="failure"||$3=="cancelled"||$3=="timed_out"{exit 1}' \
  || die "check-run do head ${HEAD_SHA:0:8} concluiu em falha — merge recusado"
say "✓ check-runs ancorados no head ${HEAD_SHA:0:8}: todos completos, nenhum falho"

checks="$(gh pr checks "$PR" "${REPO_ARG[@]}" 2>&1)"
GHRC=$?
[ -z "$checks" ] && die "não consegui ler os checks do PR #${PR} (saída vazia, rc=${GHRC})"
printf '%s\n' "$checks" | sed 's/^/  /'
printf '%s\n' "$checks" | awk '{print $2}' | grep -q pending && die "há check PENDENTE — merge recusado (esperar não é opcional)"
printf '%s\n' "$checks" | awk '{print $2}' | grep -q fail && die "há check FALHO — merge recusado"

verdict="$(gh pr view "$PR" "${REPO_ARG[@]}" --json statusCheckRollup \
  --jq '.statusCheckRollup[] | select(.name=="onion-review-verdict") | (.conclusion // .state)' 2>/dev/null)"
if [ -z "$verdict" ]; then
  say "⚠️  sem linha 'onion-review-verdict' neste repo — a revisão adversarial NÃO foi medida aqui."
  say "    (repos sem o gate: o resíduo da REGRA 56 e a passada humana são a única cobertura)"
elif [ "$verdict" != "SUCCESS" ]; then
  die "onion-review-verdict = ${verdict} — o revisor NÃO aprovou (o 'pass' do onion-review é soft e não vale)"
else
  say "✓ onion-review-verdict = SUCCESS (fonte lida, não inferida)"
fi

# 3 — o RC do merge, que é o defeito de origem
gh pr merge "$PR" "${REPO_ARG[@]}" --rebase "${DEL[@]}"
rc=$?
[ "$rc" -ne 0 ] && die "gh pr merge saiu com rc=${rc} — NÃO declaro merge (foi exatamente assim que o #618 'mergeou' sem mergear)"

# 4 — prova independente: o ESTADO, não o comando
state="$(gh pr view "$PR" "${REPO_ARG[@]}" --json state,mergedAt --jq '"\(.state)|\(.mergedAt)"' 2>/dev/null)"
case "$state" in
  MERGED\|null) die "estado diz MERGED mas mergedAt é nulo — inconsistente, não declaro" ;;
  MERGED\|*)    printf '✓ PR #%s MERGED — provado pelo ESTADO (mergedAt=%s)\n' "$PR" "${state#*|}" ;;
  *)            die "o merge retornou 0 mas o estado do PR é '${state%%|*}' — declaração ≠ verificação" ;;
esac
