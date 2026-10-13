#!/usr/bin/env bash
# =============================================================================
# main-bench-alarm.sh — o ALARME do nível main da bancada em dois níveis (core-only)
#
# POR QUE EXISTE (passo D de D_MERGE_PROCESS_ONION_2026_10, selado pelo maestro em 2026-10-13):
# no PR a bancada roda só as famílias que o diff toca (selftest-pr-selection.sh). O que o PR deixou de
# exercer é exercido no push ao main, pela bancada COMPLETA — e o main pode estar quebrado no intervalo.
# Essa janela é ACEITA E DECLARADA (o Elenxo da decisão: os achados de defeito sem detecção automática e
# de quebra semântica sem conflito pedem verificar no main de qualquer jeito). Este script é o que faz
# a janela ter fim: quando a bancada do main reprova, ele
#   1. abre (ou atualiza) UMA issue de título fixo, nomeando o commit culpado e o run;
#   2. prepara o revert do commit do merge numa branch `revert/<sha12>` e tenta abrir o PR;
#   3. dispara os workflows do CI na branch do revert (PR aberto por GITHUB_TOKEN não dispara CI);
# e quando a bancada do main volta a passar, comenta e fecha a issue, e fecha os PRs de revert que ela
# preparou e ninguém mergeou (ficaram superados).
#
# ⚠️ O MAIN VERMELHO NÃO TEM UM CULPADO POR COMMIT (defeito medido em 2026-10-13, e a cura é esta
# versão). A completa reprovou em ff5abe51 (merge do #1081): issue #1086 e revert #1085, correto. O
# commit seguinte, 825e93f6 (só projeções regeneradas, #1084), HERDOU o mesmo defeito, reprovou de novo
# e a versão anterior abriu um SEGUNDO revert (#1087) contra um commit inocente. A causa real era
# docs/backlog.md fora de sincronia depois da combinação dos merges (REGRA 62 (Projeção GERADA em
# sincronia com a fonte (docs/backlog.md))); o conserto para a frente foi o #1088. A REGRA DESTA VERSÃO:
#   • ASSINATURA DA QUEBRA = o conjunto de FAMÍLIAS com falha>0, somado dos relatórios TSV das faixas
#     (`--reports-dir`, os artefatos `selftest-report.tsv`). Família, não caso: o rótulo do caso carrega
#     sha e caminho que mudam de commit para commit sem a quebra mudar. Ela só é LEGÍVEL com os
#     `--expect-reports` relatórios, cada um com cabeçalho e TOTAL, e ao menos uma família reprovada.
#   • A issue guarda a assinatura num MARCADOR (`<!-- onion-alarm v1 … -->`) em cada post; as
#     famílias CONHECIDAS são a união dos marcadores das reprovações (`result=failure`) da issue.
#   • 1º vermelho (sem issue aberta) ⇒ issue + revert, como antes.
#   • vermelho com a issue JÁ ABERTA e nenhuma família fora das conhecidas ⇒ só COMENTA (commit novo,
#     resultado, famílias iguais ou subconjunto). NÃO abre revert: o commit herdou a quebra.
#   • vermelho com família NOVA (fora das conhecidas) ⇒ quebra sobre a quebra: comenta, nomeia o
#     commit como SUSPEITO NOVO e PREPARA o revert dele. Escolhido com evidência, e não "só nomear":
#     (1) preparar é reversível e nunca mergeia (a branch é só objeto; o merge é do caminho
#     verificado); (2) quando a 1ª quebra sair, a 2ª continua e o revert dela já está pronto;
#     (3) no 2026-10-13 o PR do revert abriu sozinho (#1085, author app/github-actions), então o custo
#     de preparar é zero de mão humana. Exceção: se o commit é o MERGE DE UM REVERT, só nomeia
#     (reverter o revert seria a máquina desfazendo o próprio conserto).
#   • commit MAIS VELHO que o culpado registrado (dois pushes concorrentes, a bancada do mais velho
#     terminou depois) com as mesmas famílias ⇒ a quebra é dele: é nomeado culpado e o revert dele é
#     preparado. Ordem medida por `git merge-base --is-ancestor` contra o origin/main buscado.
#   • issue ILEGÍVEL (gh falhou ao ler, nenhum marcador — aberta por versão anterior ou editada —,
#     ou o 1º alarme sem assinatura) ou ASSINATURA ATUAL ILEGÍVEL ⇒ comenta declarando o porquê e
#     NÃO abre revert às cegas.
#   • issue FECHADA À MÃO com o main ainda vermelho: a última issue fechada de título fixo sem o
#     marcador de verde vale como a issue do alarme para a comparação — a nova nasce herdando as
#     famílias dela, e o revert só sai para família nova. O verde seguinte carimba a fechada à mão
#     (um comentário, uma vez) para ela não envenenar o próximo 1º vermelho.
#   • dois 1ºs vermelhos concorrentes (o push ao main tem grupo por sha, sem cancelamento) ⇒ cada um
#     abre a sua; depois de criar, a de número maior se declara duplicata na menor e se fecha.
#   • VERDE ⇒ comenta e fecha a issue (com o marcador de verde); DEPOIS fecha, com comentário, os PRs
#     ABERTOS de revert superados: head `revert/<sha12>` (12 hex exatos), autor `app/github-actions`
#     E o sha12 citado na issue (marcador, `revert/<sha12>` ou o sha do commit culpado). Os três
#     juntos: a branch sozinha seria de qualquer um; o autor sozinho pegaria revert de outro ciclo.
#
# ⚠️ NUNCA MERGEIA. O merge do revert é pelo caminho verificado (ops/pr-merge-verified.sh, o único que o
# hook de veto exit 2 deixa mergear no main). Um alarme que mergeasse sozinho tiraria o merge do caminho
# que o hook vigia — o mesmo motivo que deixou a fila de terceiro (opção F) gated.
#
# ⚠️ LIMITE MEDIDO (2026-10-13, de manhã): `can_approve_pull_request_reviews: false` impedia o
# GITHUB_TOKEN de abrir PR. Re-medido na mesma data, à tarde: `true` (gh api
# repos/marciocar/onion-evolve/actions/permissions/workflow), e os PRs #1085 e #1087 nasceram com autor
# app/github-actions. O script continua tratando a recusa: empurra a branch, tenta o PR e, se recusado,
# escreve na issue o comando exato.
#
# Uso  : bash ops/testing/main-bench-alarm.sh --result <resultado> --sha <sha> --run-url <url>
#          [--repo dono/nome] [--reports-dir DIR --expect-reports N]
#        <resultado> = o `needs.selftest.result` do run (success · failure · cancelled · skipped) ou
#        `plano-<resultado>` quando nem o plano saiu. Revert SÓ em `failure` (uma faixa REPROVOU);
#        cancelado/plano quebrado abre o alarme sem revert, porque o culpado não está provado.
#        --reports-dir: onde estão os `selftest-report.tsv` das faixas (busca recursiva);
#        --expect-reports: quantas faixas o plano criou (relatório faltando = assinatura ilegível).
# Exit : 0 alarme entregue (ou nada a fazer) · 1 não consegui ler/abrir/atualizar a issue · 2 uso inválido.
# =============================================================================
set -uo pipefail

TITLE="🚨 main quebrado — a bancada completa reprovou no push ao main"
BOT_LOGIN="app/github-actions"
RESULT=""; SHA=""; RUN_URL=""; REPO="${GITHUB_REPOSITORY:-}"; REPORTS_DIR=""; EXPECT_REPORTS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --result) shift; RESULT="${1:-}" ;;
    --sha) shift; SHA="${1:-}" ;;
    --run-url) shift; RUN_URL="${1:-}" ;;
    --repo) shift; REPO="${1:-}" ;;
    --reports-dir) shift; REPORTS_DIR="${1:-}" ;;
    --expect-reports) shift; EXPECT_REPORTS="${1:-}" ;;
    -h|--help) sed -n '/^# Uso  :/,/^# Exit :/p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "main-bench-alarm: argumento desconhecido '$1'" >&2; exit 2 ;;
  esac
  shift
done
[ -n "${RESULT}" ] && [ -n "${REPO}" ] || { echo "main-bench-alarm: --result e --repo (ou GITHUB_REPOSITORY) obrigatórios" >&2; exit 2; }
case "${SHA}" in *[!0-9a-f]*|"") echo "main-bench-alarm: --sha precisa ser um sha hexadecimal" >&2; exit 2 ;; esac
[ "${#SHA}" -ge 12 ] || { echo "main-bench-alarm: --sha curto demais (${SHA})" >&2; exit 2; }
case "${EXPECT_REPORTS}" in ""|*[!0-9]*) [ -z "${EXPECT_REPORTS}" ] || { echo "main-bench-alarm: --expect-reports precisa ser inteiro" >&2; exit 2; } ;; esac
SHA12="${SHA:0:12}"

# ── leitura do forge (cru em JSON; o filtro é daqui, para a bancada exercitá-lo de verdade) ──────
_issues_by_state() {  # <open|closed> → números de título exato, do MENOR para o maior; rc≠0 se o gh falhou
  local raw; raw="$(gh issue list --repo "${REPO}" --state "$1" --limit 100 --json number,title 2>/dev/null)" || return 1
  TITLE="${TITLE}" python3 -I -c '
import json, os, sys
t = os.environ["TITLE"]
for n in sorted(i["number"] for i in json.load(sys.stdin) if i.get("title") == t): print(n)
' <<< "${raw}" 2>/dev/null
}
# _issue_text <n> → corpo + comentários DO ACTIONS, separados por linha em branco; rc≠0 se ilegível.
# ⚠️ SÓ POSTS DO BOT (achado adversarial de 2026-10-13): o repo é público e qualquer conta comenta na
# issue. Um marcador colado por terceiro com `families=<todas>` calaria todo revert; um que citasse
# sha12 poria PR na lista de fechamento. A autoria vem do forge (author.login), não do texto. Medido em
# #1086: a issue tem autor `app/github-actions` e o comentário do Actions, `github-actions`.
_issue_text() {
  local raw; raw="$(gh issue view "$1" --repo "${REPO}" --json author,body,comments 2>/dev/null)" || return 1
  python3 -I -c '
import json, sys
BOTS = {"app/github-actions", "github-actions"}
d = json.load(sys.stdin)
if (d.get("author") or {}).get("login") in BOTS: print(d.get("body") or "")
for c in d.get("comments") or []:
    if (c.get("author") or {}).get("login") in BOTS: print("\n" + (c.get("body") or ""))
' <<< "${raw}" 2>/dev/null
}
# _thread_state <texto> → linhas chave=valor: markers= · known= · incomplete= · culprits= · reverts= · green=
_thread_state() {
  python3 -I -c '
import re, sys
t = sys.stdin.read()
ms = [dict(kv.split("=", 1) for kv in m.split()) for m in re.findall(r"<!-- onion-alarm v1 ([^>]*?) -->", t)]
fails = [m for m in ms if m.get("result") == "failure" and m.get("mode") in ("first", "new", "older")]
known, incomplete = set(), False
for m in ms:
    if m.get("result") != "failure": continue
    f = m.get("families", "?")
    if f == "?":
        if m in fails: incomplete = True
        continue
    known.update(x for x in f.split(",") if x)
reverts = {m["revert"] for m in ms if m.get("revert", "-") not in ("-", "")}
reverts.update(re.findall(r"revert/([0-9a-f]{12})\b", t))
reverts.update(s[:12] for s in re.findall(r"Commit culpado:\*\* `([0-9a-f]{40})`", t))
green = bool(re.search(r"<!-- onion-alarm v1 [^>]*mode=(green|dup)", t)) or "A bancada completa voltou a passar no main" in t
print("markers=%d" % len(ms)); print("failmarkers=%d" % len(fails))
print("known=" + ",".join(sorted(known))); print("incomplete=%d" % incomplete)
print("culprits=" + ",".join(m["sha"] for m in fails if "sha" in m))
print("reverts=" + ",".join(sorted(reverts))); print("green=%d" % green)
print("sticky=%d" % any(m.get("mode") == "illegible" for m in ms))
' <<< "$1"
}
_kv() { sed -n "s/^$1=//p" <<< "$2" | head -n1; }
_marker() {  # <mode> <families|?> <revert sha12|->
  printf '<!-- onion-alarm v1 mode=%s result=%s sha=%s families=%s revert=%s -->' "$1" "${RESULT}" "${SHA}" "$2" "$3"
}

# ── assinatura da quebra: famílias com falha>0, dos relatórios das faixas ─────────────────────────
SIG_OK=0; SIG_FAMS=""; SIG_CASES=""; SIG_WHY=""
_bench_signature() {
  [ -n "${REPORTS_DIR}" ] || { SIG_WHY="sem --reports-dir (os relatórios das faixas não foram entregues ao alarme)"; return; }
  [ -d "${REPORTS_DIR}" ] || { SIG_WHY="--reports-dir ${REPORTS_DIR} não existe (o download dos artefatos falhou?)"; return; }
  local out
  out="$(EXPECT="${EXPECT_REPORTS}" python3 -I -c '
import os, sys
root, exp = sys.argv[1], os.environ.get("EXPECT", "")
files = sorted(os.path.join(d, f) for d, _, fs in os.walk(root) for f in fs if f == "selftest-report.tsv")
if exp and len(files) != int(exp): print("ERR %d relatório(s) para %s faixa(s): faixa sem relatório é faixa que morreu antes da soma" % (len(files), exp)); sys.exit()
if not files: print("ERR nenhum selftest-report.tsv em %s" % root); sys.exit()
fams, cases = set(), []
for p in files:
    rows = [l.rstrip("\n").split("\t") for l in open(p, encoding="utf-8", errors="replace")]
    if not rows or rows[0][:1] != ["familia"] or not any(r[:1] == ["TOTAL"] for r in rows):
        print("ERR %s sem cabeçalho ou sem TOTAL (a bancada da faixa morreu antes da soma)" % os.path.relpath(p, root)); sys.exit()
    for r in rows[1:]:
        if r[0] == "FAIL" and len(r) > 1: cases.append(r[1])
        elif r[0] not in ("SKIP", "TOTAL") and len(r) >= 3 and r[2].isdigit() and int(r[2]) > 0: fams.add(r[0])
if not fams: print("ERR resultado failure, mas nenhum relatório tem família com falha (timeout ou faixa cancelada?)"); sys.exit()
print("OK " + ",".join(sorted(fams)))
for c in cases[:20]: print("CASE " + c)
' "${REPORTS_DIR}" 2>&1)"
  case "${out}" in
    OK*) SIG_OK=1; SIG_FAMS="$(head -n1 <<< "${out}")"; SIG_FAMS="${SIG_FAMS#OK }"; SIG_CASES="$(sed -n 's/^CASE /  - /p' <<< "${out}")" ;;
    *) SIG_WHY="$(head -n1 <<< "${out}")"; SIG_WHY="${SIG_WHY#ERR }"; [ -n "${SIG_WHY}" ] || SIG_WHY="leitura dos relatórios falhou sem mensagem" ;;
  esac
}

# ── fecho dos reverts superados ─────────────────────────────────────────────────────────────────
_close_superseded_reverts() {  # <issue n> <sha12s citados, vírgula>
  local raw nums n
  [ -n "$2" ] || { echo "main-bench-alarm: nenhum revert citado na issue #$1 — nenhum PR a fechar"; return 0; }
  raw="$(gh pr list --repo "${REPO}" --state open --limit 100 --json number,headRefName,author 2>/dev/null)" \
    || { echo "main-bench-alarm: ⚠ não consegui listar os PRs de revert — os superados ficam abertos" >&2; return 0; }
  nums="$(CITED="$2" BOT="${BOT_LOGIN}" python3 -I -c '
import json, os, re, sys
cited = set(x for x in os.environ["CITED"].split(",") if x)
for p in json.load(sys.stdin):
    m = re.fullmatch(r"revert/([0-9a-f]{12})", p.get("headRefName") or "")
    if m and (p.get("author") or {}).get("login") == os.environ["BOT"] and m.group(1) in cited: print(p["number"])
' <<< "${raw}" 2>/dev/null)"
  for n in ${nums}; do
    if gh pr close "${n}" --repo "${REPO}" --comment "Superado: a bancada completa voltou a passar no main em \`${SHA12}\` (${RUN_URL}) e o alarme #$1 fechou. Este revert foi preparado pelo alarme e não foi mergeado — fecho sem mergear. A branch fica para auditoria." >/dev/null 2>&1; then
      echo "main-bench-alarm: PR de revert #${n} superado — comentado e fechado"
    else echo "main-bench-alarm: ⚠ não consegui fechar o PR de revert #${n}" >&2; fi
  done
}

# ── VERDE: a janela fecha ─────────────────────────────────────────────────────────────────────
if [ "${RESULT}" = "success" ]; then
  _opens="$(_issues_by_state open)" || { echo "main-bench-alarm: não consegui listar as issues de alarme" >&2; exit 1; }
  if [ -z "${_opens}" ]; then
    # fechada à mão sem o verde? carimba UMA vez, e fecha os reverts dela
    _last="$(_issues_by_state closed 2>/dev/null | tail -n1)"
    if [ -n "${_last}" ] && _t="$(_issue_text "${_last}")"; then
      _st="$(_thread_state "${_t}")"
      if [ "$(_kv green "${_st}")" = "0" ] && [ "$(_kv markers "${_st}")" != "0" ]; then
        gh issue comment "${_last}" --repo "${REPO}" --body "✅ A bancada completa passou no main em \`${SHA12}\` (${RUN_URL}). Esta issue tinha sido fechada à mão com o main vermelho; carimbo o verde para ela não valer mais como alarme. $(_marker green - -)" >/dev/null \
          || { echo "main-bench-alarm: não consegui carimbar o verde na issue fechada #${_last}" >&2; exit 1; }
        echo "main-bench-alarm: main verde em ${SHA12} — issue #${_last} (fechada à mão) carimbada"
        _close_superseded_reverts "${_last}" "$(_kv reverts "${_st}")"
        exit 0
      fi
    fi
    echo "main-bench-alarm: main verde em ${SHA12}, nenhum alarme aberto — nada a fazer"; exit 0
  fi
  for _n in ${_opens}; do
    _cited=""; if _t="$(_issue_text "${_n}")"; then _cited="$(_kv reverts "$(_thread_state "${_t}")")"; fi
    gh issue comment "${_n}" --repo "${REPO}" --body "✅ A bancada completa voltou a passar no main em \`${SHA12}\` (${RUN_URL}). Fecho o alarme e, em seguida, os PRs de revert que ele preparou e não foram mergeados (superados). $(_marker green - -)" >/dev/null \
      || { echo "main-bench-alarm: não consegui comentar na issue #${_n}" >&2; exit 1; }
    gh issue close "${_n}" --repo "${REPO}" >/dev/null || { echo "main-bench-alarm: não consegui fechar a issue #${_n}" >&2; exit 1; }
    echo "main-bench-alarm: main verde em ${SHA12} — issue #${_n} comentada e fechada"
    _close_superseded_reverts "${_n}" "${_cited}"
  done
  exit 0
fi

# ── VERMELHO ──────────────────────────────────────────────────────────────────────────────────
_subj="$(git log -1 --format=%s "${SHA}" 2>/dev/null || echo '<commit ilegível no checkout>')"
_parents="$(git rev-list --parents -n1 "${SHA}" 2>/dev/null | wc -w)"; _parents=$(( ${_parents:-1} - 1 ))
_pr="$(printf '%s' "${_subj}" | sed -n 's/.*Merge pull request #\([0-9][0-9]*\).*/\1/p')"
_is_revert_merge=0
case "${_subj}" in *"Merge pull request #"*" from "*"/revert/"*|"Revert \""*|"revert: "*) _is_revert_merge=1 ;; esac
BRANCH="revert/${SHA12}"
[ "${RESULT}" = "failure" ] && _bench_signature
git fetch -q origin main 2>/dev/null || true

_opens="$(_issues_by_state open)" || { echo "main-bench-alarm: não consegui listar as issues de alarme — não abro revert às cegas" >&2; exit 1; }
ISSUE="$(head -n1 <<< "${_opens}")"
REF_ISSUE="${ISSUE}"; REF_NOTE=""; REF_TEXT=""
if [ -z "${ISSUE}" ]; then  # issue fechada à mão com o main vermelho vale como referência
  _last="$(_issues_by_state closed 2>/dev/null | tail -n1)"
  if [ -n "${_last}" ] && _t="$(_issue_text "${_last}")"; then
    _st="$(_thread_state "${_t}")"
    if [ "$(_kv green "${_st}")" = "0" ] && [ "$(_kv markers "${_st}")" != "0" ]; then
      REF_ISSUE="${_last}"; REF_TEXT="${_t}"
      REF_NOTE="a issue #${_last} foi FECHADA À MÃO sem verde da bancada; ela vale como o 1º alarme para a comparação (os marcadores dela vêm herdados abaixo)"
    fi
  fi
fi

# MODO: first · same · new · older · illegible · unreadable-sig · not-failure
MODE="first"; WHY=""; KNOWN=""; NEWF=""
if [ -n "${REF_ISSUE}" ]; then
  if ! _t="$(_issue_text "${REF_ISSUE}")"; then MODE="illegible"; WHY="não consegui ler a issue #${REF_ISSUE} (gh issue view falhou)"
  else
    _st="$(_thread_state "${_t}")"; KNOWN="$(_kv known "${_st}")"
    if [ "$(_kv markers "${_st}")" = "0" ]; then MODE="illegible"; WHY="a issue #${REF_ISSUE} não tem marcador do alarme (aberta por versão anterior ou editada à mão): não sei quais famílias o 1º alarme viu"
    elif [ "$(_kv sticky "${_st}")" = "1" ]; then MODE="illegible"; WHY="a issue #${REF_ISSUE} já foi declarada ilegível por um alarme anterior: a assinatura do 1º alarme continua desconhecida"
    elif [ "$(_kv incomplete "${_st}")" = "1" ]; then MODE="illegible"; WHY="o alarme registrado na issue #${REF_ISSUE} não teve assinatura legível: não sei quais famílias ele viu"
    elif [ "$(_kv failmarkers "${_st}")" = "0" ]; then MODE="first"   # só cancelamentos antes: esta é a 1ª reprovação
    elif [ "${RESULT}" != "failure" ]; then MODE="not-failure"
    elif [ "${SIG_OK}" != "1" ]; then MODE="unreadable-sig"; WHY="${SIG_WHY}"
    else
      NEWF="$(comm -23 <(tr ',' '\n' <<< "${SIG_FAMS}" | sed '/^$/d' | LC_ALL=C sort -u) <(tr ',' '\n' <<< "${KNOWN}" | sed '/^$/d' | LC_ALL=C sort -u) | paste -sd, -)"
      if [ -n "${NEWF}" ]; then MODE="new"
      else
        MODE="same"
        for _c in $(tr ',' ' ' <<< "$(_kv culprits "${_st}")"); do
          [ "${_c}" = "${SHA}" ] && { MODE="same"; break; }
          if git cat-file -e "${_c}^{commit}" 2>/dev/null; then
            git merge-base --is-ancestor "${SHA}" "${_c}" 2>/dev/null && { MODE="older"; WHY="\`${SHA12}\` é ANCESTRAL do culpado registrado \`${_c:0:12}\` (a bancada dele terminou depois): a quebra é mais velha"; }
          else WHY="${WHY:+${WHY}; }não consegui ler o culpado registrado \`${_c:0:12}\` para medir a ordem"; fi
        done
      fi
    fi
  fi
fi
[ "${MODE}" = "first" ] && [ "${RESULT}" = "failure" ] && [ "${SIG_OK}" != "1" ] && WHY="assinatura ilegível (${SIG_WHY}): os próximos vermelhos não poderão ser comparados com este"

# REVERT só em: first+failure · new (exceto merge de revert) · older
DO_REVERT=0
case "${MODE}" in
  first) [ "${RESULT}" = "failure" ] && DO_REVERT=1 ;;
  new|older) [ "${_is_revert_merge}" = "1" ] || DO_REVERT=1 ;;
esac
if [ "${DO_REVERT}" = "1" ]; then REVERT=""
else
  case "${MODE}" in
    first) REVERT="não tentado (resultado '${RESULT}': o culpado não está provado — só faixa REPROVADA dispara revert)" ;;
    same) REVERT="não tentado: as famílias que falharam já estavam no alarme — o commit HERDOU a quebra" ;;
    new|older) REVERT="não tentado: o commit é o merge de um revert — reverter o revert seria a máquina desfazendo o próprio conserto" ;;
    *) REVERT="não tentado: ${WHY:-sem comparação possível} — sem comparação, não abro revert às cegas" ;;
  esac
fi
REVERTED="-"

if [ "${DO_REVERT}" = "1" ]; then
  _gitbot=(-c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com")
  if git ls-remote --exit-code --heads origin "${BRANCH}" >/dev/null 2>&1; then
    REVERT="a branch \`${BRANCH}\` já existia (run repetido) — não refiz"; REVERTED="${SHA12}"
  elif ! git checkout -q -B "${BRANCH}" origin/main 2>/dev/null; then
    REVERT="FALHOU ao preparar a branch a partir de origin/main — revert manual"
  else
    _rv=(revert --no-edit); [ "${_parents}" -ge 2 ] && _rv+=(-m 1)
    if ! git "${_gitbot[@]}" "${_rv[@]}" "${SHA}" >/dev/null 2>&1; then
      git revert --abort >/dev/null 2>&1 || true
      REVERT="FALHOU: o revert de \`${SHA12}\` conflita com o main atual — revert manual"
    elif ! git push -q origin "HEAD:refs/heads/${BRANCH}" 2>/dev/null; then
      REVERT="FALHOU ao empurrar \`${BRANCH}\` — revert manual"
    else
      REVERTED="${SHA12}"
      _body="Revert automático de \`${SHA12}\` (${_subj}), preparado porque a bancada completa reprovou no push ao main: ${RUN_URL}

NÃO foi mergeado por automação, e não deve ser: o merge é pelo caminho verificado (\`bash ops/pr-merge-verified.sh <PR> --merge-commit\`)."
      [ "${MODE}" = "new" ] && _body="${_body}

⚠️ Quebra SOBRE a quebra: o main já estava vermelho (famílias ${KNOWN}); este commit trouxe família nova (${NEWF}). O CI deste revert fica vermelho enquanto a 1ª quebra não sair."
      if _url="$(gh pr create --repo "${REPO}" --base main --head "${BRANCH}" --title "revert: ${_subj} (main quebrado em ${SHA12})" --body "${_body}" 2>&1)"; then
        REVERT="PR de revert aberto: ${_url##*$'\n'}"
      else
        REVERT="branch \`${BRANCH}\` empurrada, mas o PR NÃO abriu ($(printf '%s' "${_url}" | head -n1 | head -c 160)). Abra: \`gh pr create --base main --head ${BRANCH} --fill\`"
      fi
      # PR/push feito por GITHUB_TOKEN não dispara workflow; workflow_dispatch dispara (exceção documentada)
      for _wf in onion-selftest.yml onion-validate.yml; do
        gh workflow run "${_wf}" --repo "${REPO}" --ref "${BRANCH}" >/dev/null 2>&1 \
          && REVERT="${REVERT} · CI disparado: ${_wf}" || REVERT="${REVERT} · CI NÃO disparado: ${_wf}"
      done
    fi
  fi
fi

_fams_line="${SIG_FAMS:-? (${SIG_WHY:-resultado não é failure — não há assinatura})}"
_f="$(mktemp)"
case "${MODE}" in
  first)
    cat > "${_f}" <<EOF
A bancada completa (nível main da bancada em dois níveis) **não passou** no push ao main.

- **Commit culpado:** \`${SHA}\` — ${_subj}${_pr:+ (PR #${_pr})}
- **Resultado:** \`${RESULT}\`
- **Famílias que falharam:** ${_fams_line}
${SIG_CASES:+- **Casos:**
${SIG_CASES}
}- **Run:** ${RUN_URL}
- **Revert:** ${REVERT}
${REF_NOTE:+- **Nota:** ${REF_NOTE}
}${WHY:+- **Atenção:** ${WHY}
}
**Janela declarada:** o main pode ficar quebrado entre o merge e o merge do revert (a bancada completa do
main leva da ordem de 25 min, mais o tempo do merge verificado). É o preço aceito do nível PR rodar só as
famílias tocadas — decisão D_MERGE_PROCESS_ONION_2026_10, passo D. Enquanto este alarme está aberto, não
mergeie nada que não seja o conserto: cada merge novo alarga a janela e complica o revert.

Enquanto esta issue está aberta, um vermelho novo com as **mesmas famílias** só comenta aqui (o commit
herdou a quebra); só família **nova** nomeia suspeito novo e prepara revert dele.
Esta issue fecha sozinha quando a bancada completa voltar a passar num push ao main.

$(_marker first "${SIG_FAMS:-?}" "${REVERTED}")
EOF
    ;;
  *)
    case "${MODE}" in
      same) _head="🔁 **Mesmas famílias**: o main continua vermelho e o commit novo herdou a quebra — **sem revert novo**." ;;
      new) _head="🆕 **Quebra SOBRE a quebra**: família nova (${NEWF}) fora das já conhecidas (${KNOWN}). **Suspeito novo:** \`${SHA}\`." ;;
      older) _head="⏪ **Culpado mais velho**: ${WHY}. **Culpado:** \`${SHA}\`." ;;
      not-failure) _head="⚠️ O main continua sem verde, mas o resultado (\`${RESULT}\`) não é reprovação de faixa — sem revert." ;;
      *) _head="❓ **Comparação impossível**: ${WHY} — **sem revert às cegas**." ;;
    esac
    _sub=""
    if [ "${MODE}" = "same" ]; then
      _sub="- **Famílias agora:** ${SIG_FAMS} · **conhecidas:** ${KNOWN}"
      [ "${SIG_FAMS}" != "${KNOWN}" ] && _sub="${_sub} (parte das conhecidas voltou a passar)"
      [ "${_is_revert_merge}" = "1" ] && _sub="${_sub}
- ⚠️ Este commit é o MERGE DE UM REVERT e o main segue vermelho nas mesmas famílias: a culpa do alarme está REFUTADA ou incompleta — o conserto é para a frente."
      [ -n "${WHY}" ] && _sub="${_sub}
- **Atenção:** ${WHY}"
    fi
    cat > "${_f}" <<EOF
${_head}

- **Commit:** \`${SHA}\` — ${_subj}${_pr:+ (PR #${_pr})}
- **Resultado:** \`${RESULT}\`
- **Famílias que falharam:** ${_fams_line}
${_sub:+${_sub}
}${SIG_CASES:+- **Casos:**
${SIG_CASES}
}${REF_NOTE:+- **Nota:** ${REF_NOTE}
}- **Run:** ${RUN_URL}
- **Revert:** ${REVERT}

$(_marker "${MODE}" "${SIG_FAMS:-?}" "${REVERTED}")
EOF
    ;;
esac

if [ -z "${ISSUE}" ] && [ -n "${REF_TEXT}" ]; then  # herda as famílias da fechada à mão
  { printf '\n_Herdado da #%s:_ ' "${REF_ISSUE}"; grep -o '<!-- onion-alarm v1 [^>]* -->' <<< "${REF_TEXT}" | tr '\n' ' '; echo; } >> "${_f}"
fi
if [ -n "${ISSUE}" ]; then
  gh issue comment "${ISSUE}" --repo "${REPO}" --body-file "${_f}" >/dev/null \
    || { echo "main-bench-alarm: não consegui comentar na issue #${ISSUE}" >&2; rm -f "${_f}"; exit 1; }
  echo "main-bench-alarm: alarme ATUALIZADO na issue #${ISSUE} — modo ${MODE} · ${SHA12} · ${REVERT}"
else
  _created="$(gh issue create --repo "${REPO}" --title "${TITLE}" --body-file "${_f}" 2>/dev/null)" \
    || { echo "main-bench-alarm: não consegui abrir a issue de alarme" >&2; rm -f "${_f}"; exit 1; }
  _mine="$(sed -n 's#.*/issues/\([0-9][0-9]*\).*#\1#p' <<< "${_created}" | tail -n1)"
  echo "main-bench-alarm: alarme ABERTO${_mine:+ (#${_mine})} — modo ${MODE} · ${SHA12} · ${REVERT}"
  # corrida de dois 1ºs vermelhos: a de número maior vira comentário na menor e se fecha
  _low="$(_issues_by_state open 2>/dev/null | head -n1)"
  if [ -n "${_mine}" ] && [ -n "${_low}" ] && [ "${_low}" -lt "${_mine}" ]; then
    { cat "${_f}"; printf '\n\n_(alarme concorrente: abri a #%s ao mesmo tempo; fechei-a como duplicata desta.)_\n' "${_mine}"; } > "${_f}.dup"
    gh issue comment "${_low}" --repo "${REPO}" --body-file "${_f}.dup" >/dev/null 2>&1 \
      && gh issue comment "${_mine}" --repo "${REPO}" --body "Duplicata concorrente da #${_low}: o conteúdo foi para lá. $(_marker dup "${SIG_FAMS:-?}" "${REVERTED}")" >/dev/null 2>&1 \
      && gh issue close "${_mine}" --repo "${REPO}" >/dev/null 2>&1 \
      && echo "main-bench-alarm: corrida — #${_mine} fechada como duplicata da #${_low}" \
      || echo "main-bench-alarm: ⚠ corrida detectada (#${_low} e #${_mine} abertas) e não consegui fundir" >&2
    rm -f "${_f}.dup"
  fi
fi
rm -f "${_f}"
exit 0
