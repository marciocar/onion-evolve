#!/usr/bin/env bash
# =============================================================================
# progress.sh — o % de progresso de uma task-mãe a partir das subtasks, ponderado por STORY POINTS
#
# A REGRA (SSOT: interface.md §Derivação `progress`; este helper é a execução dela):
#   · entra a lista de subtasks JÁ NORMALIZADA pelo adapter: id, status canônico (TaskStatus) e
#     storyPoints (vazio ou `-` = sem pontos). Nada de forma de provedor aqui.
#   · `done` e `closed` contam como feitas; `canceled` sai do total (numerador E denominador);
#     `backlog`, `todo`, `in_progress` e `review` estão no total e não feitas.
#   · TODAS as subtasks do total com pontos, e soma > 0  → método `story_points`:
#         % = soma dos pontos das feitas / soma dos pontos do total
#   · NENHUMA com pontos                                → método `count`: % = feitas / total
#   · ALGUMAS com pontos e outras sem                   → método `mixed`: % pela CONTAGEM, e os ids
#     sem pontos saem declarados. Ponderar só as pontuadas daria peso zero a trabalho real; imputar
#     a média inventaria pontos. A contagem é a base neutra, e o rótulo diz que os pontos ficaram de fora.
#   · todas com pontos e soma 0                         → método `count`, com o motivo declarado
#     (não há o que ponderar; dividir por zero não é resposta).
#   · nenhuma subtask no total (sem subtasks, ou todas canceladas) → `percent=n/a`, método `none`:
#     o progresso é o status da própria task, e este helper não o inventa.
#   · arredondamento para BAIXO; e 100 só quando TODAS as do total estão feitas — subtask aberta de
#     0 ponto não deixa a task-mãe em 100 (fica em 99). Chão simétrico não existe: 0 é 0.
#
# DEFEITO DATADO (SAC-64, nó E_TM_PERCENTUAL_IGNORA_STORY_POINTS, medido em 2026-10-07): o % gravado
#   (zoho.md, `completion_percentage` "proporcional às fases do plano") pesava todas as fases igual e
#   ignorava os pontos; e a task-mãe não tinha % calculado em adapter nenhum. Pior que o peso igual era
#   o silêncio: ninguém dizia por qual método o número saiu.
#
# Uso    : progress.sh [ARQUIVO]        (sem arquivo: lê a entrada padrão)
#          progress.sh --selftest
#   entrada: uma linha por subtask, separada por TAB — id<TAB>status<TAB>storyPoints
#            linhas vazias e as que começam por `#` são ignoradas.
# Saída  : linha 1 (máquina), campos `chave=valor` separados por TAB, nesta ordem:
#            percent · method · done · total · excluded · done_points · total_points · unpointed
#          linha 2: `declared: <frase em pt-BR>` — o método e o porquê, para ir no comentário de progresso.
# Exit   : 0 = calculado (inclusive `none`) · 2 = entrada inválida (status fora do vocabulário, pontos
#          não numéricos ou negativos, id vazio ou repetido, linha sem 3 colunas) — fail-closed: entrada
#          que não se entende NÃO vira 0% calado.
#
# TETO (declarado): o status é binário por subtask — uma subtask meio feita conta como não feita
#   (sem crédito fracionário); numa task-mãe de task-mãe, cada filha entra com os PRÓPRIOS pontos e o
#   próprio status, não com o % dela. E o helper só pondera o que recebe: hoje nenhum adapter devolve
#   storyPoints na leitura (capacidade `estimate.points_read`, not_implemented nos 5), então na prática
#   ele cai em `count` — e diz isso.
# =============================================================================
set -uo pipefail
export LC_ALL=C

_compute() {
  # $1 = arquivo de entrada. Imprime as 2 linhas; rc 2 em entrada inválida (mensagem em stderr).
  awk -F'\t' '
    function num(x) { return (x == int(x)) ? sprintf("%d", x) : sprintf("%.10g", x) }
    function fail(msg) { printf "progress: linha %d: %s\n", NR, msg > "/dev/stderr"; bad = 1; exit 2 }
    /^[[:space:]]*$/ || /^#[^\t]*$/ { next }   # comentário = linha que começa por # e NÃO tem TAB: id "#123" é dado
    {
      if (NF != 3) fail("esperava exatamente 3 colunas (id, status, storyPoints) separadas por TAB, veio " NF)
      id = $1; st = $2; pt = $3
      gsub(/^[ \t]+|[ \t\r]+$/, "", id); gsub(/^[ \t]+|[ \t\r]+$/, "", st); gsub(/^[ \t]+|[ \t\r]+$/, "", pt)
      if (id == "") fail("id vazio")
      if (id in seen) fail("id repetido: " id)
      seen[id] = 1
      if (st !~ /^(backlog|todo|in_progress|review|done|closed|canceled)$/) fail("status fora do vocabulário canônico: \"" st "\"")
      if (pt != "" && pt != "-" && pt !~ /^[0-9]{1,6}(\.[0-9]{1,6})?$/) fail("storyPoints inválido (número >= 0 até 999999, ponto decimal): \"" pt "\"")
      if (st == "canceled") { excluded++; next }
      total++
      isdone = (st == "done" || st == "closed")
      if (isdone) done++
      if (pt == "" || pt == "-") { unpointed++; if (unp_ids == "") unp_ids = id; else if (unpointed <= 5) unp_ids = unp_ids ", " id; next }
      pointed++; tp += pt; if (isdone) dp += pt
    }
    END {
      if (bad) exit 2
      done += 0; total += 0; excluded += 0; unpointed += 0; pointed += 0; tp += 0; dp += 0
      exc = (excluded > 0) ? sprintf("; %d cancelada(s) fora do total", excluded) : ""
      if (total == 0) {
        method = "none"; pct = "n/a"
        decl = sprintf("sem subtasks no total (%s) — o progresso é o status da própria task", (excluded > 0) ? excluded " cancelada(s)" : "nenhuma subtask")
      } else if (pointed == total && tp > 0) {
        method = "story_points"; pct = int(100 * dp / tp + 1e-9)
        decl = sprintf("progresso por story points: %s de %s pontos (%d de %d subtasks feitas%s)", num(dp), num(tp), done, total, exc)
      } else if (pointed == 0) {
        method = "count"; pct = int(100 * done / total + 1e-9)
        decl = sprintf("progresso por CONTAGEM, sem story points: %d de %d subtasks feitas%s — estime as subtasks para ponderar", done, total, exc)
      } else if (pointed == total && tp == 0) {
        method = "count"; pct = int(100 * done / total + 1e-9)
        decl = sprintf("progresso por CONTAGEM: todas as subtasks têm 0 ponto, nada a ponderar; %d de %d feitas%s", done, total, exc)
      } else {  # 0 < pointed < total
        method = "mixed"; pct = int(100 * done / total + 1e-9)
        more = (unpointed > 5) ? sprintf(" e mais %d", unpointed - 5) : ""
        decl = sprintf("progresso por CONTAGEM (pontos incompletos): %d de %d subtasks sem story points (%s%s); %d de %d feitas%s", unpointed, total, unp_ids, more, done, total, exc)
      }
      if (pct != "n/a" && done < total && pct >= 100) { pct = 99; decl = decl " — 99, não 100: há subtask aberta de 0 ponto" }
      printf "percent=%s\tmethod=%s\tdone=%d\ttotal=%d\texcluded=%d\tdone_points=%s\ttotal_points=%s\tunpointed=%d\n", pct, method, done, total, excluded, num(dp), num(tp), unpointed
      printf "declared: %s\n", decl
    }
  ' "$1"
}

run_selftest() {
  local tmp; tmp="$(mktemp -d)"; local fails=0 total=0 out rc
  _case() { # $1 rótulo · $2 entrada (printf) · $3 regex esperada na saída (ou RC2)
    total=$((total+1))
    printf "$2" > "${tmp}/in.tsv"
    if out="$(_compute "${tmp}/in.tsv" 2>&1)"; then rc=0; else rc=$?; fi
    if [ "$3" = "RC2" ]; then
      if [ "${rc}" -eq 2 ]; then echo "  ✅ $1"; else echo "  ✗ $1 (rc=${rc}: ${out})"; fails=$((fails+1)); fi
    elif [ "${rc}" -eq 0 ] && command grep -qE -- "$3" <<< "${out}"; then echo "  ✅ $1"
    else echo "  ✗ $1 (rc=${rc}: ${out})"; fails=$((fails+1)); fi
  }
  # (a) todas com pontos: 5 de 8 pontos feitos -> 62 (a contagem daria 66)
  _case "(a) todas pontuadas pondera: 5/8 pontos = 62, não 2/3 = 66" 'a\tdone\t3\nb\tclosed\t2\nc\ttodo\t3\n' \
        '^percent=62	method=story_points	done=2	total=3	excluded=0	done_points=5	total_points=8	unpointed=0$'
  # (b) nenhuma com pontos: contagem, e o rótulo diz
  _case "(b) nenhuma pontuada cai na contagem e DECLARA" 'a\tdone\t\nb\ttodo\t-\nc\ttodo\t\n' \
        '^percent=33	method=count	.*unpointed=3$'
  _case "(b2) a frase declarada nomeia a CONTAGEM" 'a\tdone\t\nb\ttodo\t\n' '^declared: progresso por CONTAGEM, sem story points'
  # (c) misturada: contagem, rótulo mixed, ids sem pontos nomeados
  _case "(c) misturada: mixed pela contagem, nomeando quem não tem pontos" 'a\tdone\t8\nb\ttodo\t\nc\ttodo\t1\n' \
        '^percent=33	method=mixed	.*unpointed=1$'
  _case "(c2) mixed nomeia o id sem pontos" 'a\tdone\t8\nb\ttodo\t\nc\ttodo\t1\n' '^declared: .*sem story points \(b\)'
  # (d) pontos 0: todas com 0 -> contagem com motivo; e 0 ponto aberto não deixa em 100
  _case "(d) todas com 0 ponto: contagem, motivo declarado" 'a\tdone\t0\nb\ttodo\t0\n' '^percent=50	method=count	'
  _case "(d2) a frase de 0 ponto diz o motivo" 'a\tdone\t0\nb\ttodo\t0\n' 'todas as subtasks têm 0 ponto'
  _case "(d3) subtask aberta de 0 ponto segura em 99, não 100" 'a\tdone\t5\nb\ttodo\t0\n' '^percent=99	method=story_points	'
  _case "(d4) só as de 0 ponto feitas = 0 por pontos" 'a\tdone\t0\nb\ttodo\t5\n' '^percent=0	method=story_points	'
  # (e) canceladas fora do total
  _case "(e) cancelada sai do total (e dos pontos)" 'a\tdone\t3\nb\tcanceled\t13\nc\ttodo\t3\n' \
        '^percent=50	method=story_points	done=1	total=2	excluded=1	done_points=3	total_points=6	'
  _case "(e2) todas canceladas = none, não 0 nem 100" 'a\tcanceled\t3\n' '^percent=n/a	method=none	'
  # (f) sem subtasks
  _case "(f) lista vazia = none (o status da própria task decide)" '# só comentário\n\n' '^percent=n/a	method=none	done=0	total=0'
  # (g) tudo feito = 100; review não conta como feita
  _case "(g) todas feitas = 100" 'a\tdone\t1\nb\tclosed\t2\n' '^percent=100	method=story_points	'
  _case "(g2) review e in_progress não contam como feitas" 'a\treview\t5\nb\tin_progress\t5\n' '^percent=0	method=story_points	'
  # (h) arredondamento para baixo: 2/3 = 66, não 67; decimais aceitos
  _case "(h2) total grande sai inteiro, não em notação científica" 'a\tdone\t900000\nb\ttodo\t900000\nc\ttodo\t900000\nd\ttodo\t900000\n' '^percent=25	method=story_points	.*done_points=900000	total_points=3600000	'
  _case "(h3) 0,57 de 1 ponto = 57 (o épsilon do arredondamento)" 'a\tdone\t0.57\nb\ttodo\t0.43\n' '^percent=57	method=story_points	'
  _case "(h4) pontos acima de 999999 reprovam (estouro não vira nan calado)" 'a\tdone\t1000000\n' RC2
  _case "(h) arredonda para baixo e aceita meio ponto" 'a\tdone\t0.5\nb\ttodo\t0.5\nc\ttodo\t0.5\n' '^percent=33	method=story_points	.*done_points=0.5	total_points=1.5	'
  # (i) entradas inválidas: fail-closed
  _case "(i) status fora do vocabulário reprova (rc 2)" 'a\tfeito\t3\n' RC2
  _case "(i2) pontos negativos reprovam" 'a\tdone\t-3\n' RC2
  _case "(i3) pontos com vírgula reprovam" 'a\tdone\t1,5\n' RC2
  _case "(i4) id repetido reprova" 'a\tdone\t1\na\ttodo\t1\n' RC2
  _case "(i5) linha sem 3 colunas reprova" 'a\tdone\n' RC2
  _case "(i6) coluna a mais reprova (pondera pelo campo errado)" 'a\tdone\t3\textra\n' RC2
  _case "(i7) id vazio reprova" '\tdone\t3\n' RC2
  # (j) id que começa por # é DADO, não comentário (ids no formato #123)
  _case "(j) id #13 conta: 5 de 8 pontos = 62" 'a\ttodo\t3\n#13\tdone\t5\n' '^percent=62	method=story_points	done=1	total=2	'
  # (k) as frases que o consumidor copia para o comentário
  _case "(k) a frase diz quantas canceladas ficaram fora" 'a\tdone\t3\nb\tcanceled\t3\nc\tcanceled\t1\n' '^declared: .*2 cancelada\(s\) fora do total'
  _case "(k2) mixed com mais de 5 sem pontos diz quantos sobraram" 'a\tdone\t1\nb\ttodo\t\nc\ttodo\t\nd\ttodo\t\ne\ttodo\t\nf\ttodo\t\ng\ttodo\t\n' '^declared: .*\(b, c, d, e, f e mais 1\)'
  _case "(k3) o 99 forçado se explica na frase" 'a\tdone\t5\nb\ttodo\t0\n' '^declared: .*99, não 100: há subtask aberta de 0 ponto'
  _case "(k4) CRLF não quebra a leitura" 'a\tdone\t3\r\nb\ttodo\t1\r\n' '^percent=75	method=story_points	'
  rm -rf "${tmp}"; echo "  selftest: $((total-fails))/${total} verdes"
  [ "${fails}" -eq 0 ]
}

case "${1:-}" in
  --selftest) run_selftest; exit $? ;;
  -h|--help) sed -n '2,50p' "$0"; exit 0 ;;
  -*) echo "uso: $0 [ARQUIVO] | --selftest" >&2; exit 2 ;;
esac
if [ $# -gt 0 ]; then
  [ -n "$1" ] || { echo "progress: argumento vazio (variável não preenchida?) — passe o arquivo ou nada, para ler a entrada padrão" >&2; exit 2; }
  [ -f "$1" ] || { echo "progress: arquivo inexistente: $1" >&2; exit 2; }
  _compute "$1"; exit $?
fi
_in="$(mktemp)"; trap 'rm -f "${_in}"' EXIT
cat > "${_in}"
_compute "${_in}"
