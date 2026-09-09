#!/usr/bin/env bash
# =============================================================================
# collect-selftest.sh — a série histórica da bancada (ONDA 0.6, 2026-09-09)
#
# Propósito : a bancada sabia tudo e não contava para ninguém. O passo 0.2 lhe deu `--report`
#             (TSV família⇥pass⇥fail⇥skip⇥segundos); este coletor transforma cada relatório num
#             ENVELOPE por execução em `docs/onion/metrics/selftest-runs.jsonl`. Sem série não
#             há detector de flaky, não há tendência de duração e não há painel — só o log do
#             job, que ninguém lê depois que o job passa.
#
# Uso       : bash ops/testing/collect-selftest.sh --report <ABS.tsv> [--source local|ci|precommit]
#                                                  [--jobs N] [--strict 0|1] [--run-url URL]
#             bash ops/testing/collect-selftest.sh --resumo    # leitura agregada
#             bash ops/testing/collect-selftest.sh --flaky     # o detector: quem falhou em que dia
#
# ELE NÃO RODA A BANCADA, E ISSO É O DESENHO INTEIRO
#   O molde `ops/gtm/collect-metrics.sh` invoca seus medidores porque cada um custa segundos. A
#   bancada custa ~11 minutos e JÁ RODA todo dia na main (`onion-selftest.yml`, `schedule: 17 4
#   * * *`), além de rodar em cada pre-commit. Um coletor que a invocasse de novo seria o
#   instrumento mais caro que o instrumentado — e nesta máquina, medido em 2026-09-08, a
#   concorrência de memória MATOU um worker no meio de uma família duas vezes. Ingerir o
#   relatório de quem já rodou custa milissegundos e mede o MESMO run que o gate julgou.
#
# QUEM APERTA O BOTÃO — herdado do molde GTM, literalmente
#   O CI **não commita**. Este script só ESCREVE o arquivo; o commit é do humano (ou da rotina
#   de PR). É a mesma fronteira que faz o ledger GTM funcionar há meses nesta casa.
#
# O QUE ELE GUARDA, E POR QUE TUDO
#   O envelope carrega TODAS as linhas de família, não só a soma. A soma responde "a bancada
#   ficou mais lenta"; só a linha por família responde "a família X ficou mais lenta" e "a
#   família Y falha às terças" — que é o detector de flaky pedido. Custo MEDIDO no 1º envelope
#   real (1148 asserções, 165 linhas de família): **11,9 KB**, ~4,3 MB/ano em execução diária.
#   A 1ª redação deste comentário dizia "~6 KB, ~2 MB/ano" — número que eu ESTIMEI e apresentei
#   como medido, num arquivo cuja razão de existir é não fazer isso. Corrigido contra o
#   arquivo real. O ledger GTM já guarda payload inteiro pelo mesmo motivo.
#
# O QUE ELE RECUSA A INVENTAR
#   `source`, `jobs` e `strict` NÃO são deriváveis do TSV. Sem a flag, cada um vira o literal
#   `"nao-declarado"` — nunca um palpite. Um envelope que ADIVINHA a procedência corrompe
#   justamente a comparação CI × local que a série existe para permitir.
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${ROOT}/docs/onion/metrics"
LEDGER="${OUT}/selftest-runs.jsonl"

_die() { echo "collect-selftest: $*" >&2; exit 2; }

# ---------------------------------------------------------------------------
# Modos de LEITURA. Vêm primeiro porque são read-only e não devem exigir --report.
# ---------------------------------------------------------------------------
if [ "${1:-}" = "--resumo" ]; then
  [ -f "${LEDGER}" ] || _die "ledger ausente (${LEDGER}) — nenhuma execução coletada ainda. Isto é ⊘ NÃO MEDIDO, não 'zero falhas'."
  python3 - "${LEDGER}" <<'PY'
import json, sys
linhas = [json.loads(l) for l in open(sys.argv[1], encoding='utf-8') if l.strip().startswith('{')]
if not linhas:
    sys.stderr.write("collect-selftest: ledger existe e esta VAZIO — quebra, nao 'zero execucoes'.\n")
    sys.exit(2)
print(f"═══ SÉRIE DA BANCADA — {len(linhas)} execução(ões) coletada(s)\n")
print(f"  {'dia':<12} {'origem':<11} {'pass':>6} {'fail':>5} {'skip':>5} {'famílias':>9} {'seg':>6}")
for e in linhas[-20:]:
    print(f"  {e['dia']:<12} {e['source']:<11} {e['pass']:>6} {e['fail']:>5} {e['skip']:>5} "
          f"{e['familias']:>9} {e['segundos']:>6}")
if len(linhas) > 20:
    print(f"  … {len(linhas)-20} execução(ões) anterior(es) omitida(s) desta VISTA (o ledger tem todas)")
prim, ult = linhas[0], linhas[-1]
print(f"\n  primeira {prim['dia']} ({prim['pass']} pass) → última {ult['dia']} ({ult['pass']} pass)")
d = ult['pass'] - prim['pass']
print(f"  a bancada {'cresceu' if d > 0 else 'encolheu' if d < 0 else 'ficou igual'} em {abs(d)} asserção(ões)")
PY
  exit 0
fi

if [ "${1:-}" = "--flaky" ]; then
  [ -f "${LEDGER}" ] || _die "ledger ausente (${LEDGER}) — sem série não há detector de flaky. ⊘ NÃO MEDIDO."
  python3 - "${LEDGER}" <<'PY'
import json, sys
linhas = [json.loads(l) for l in open(sys.argv[1], encoding='utf-8') if l.strip().startswith('{')]
if not linhas:
    sys.stderr.write("collect-selftest: ledger VAZIO — quebra, nao 'zero flaky'.\n")
    sys.exit(2)

# Uma família é FLAKY quando falhou em ALGUMA execução e passou em outra. Falhar SEMPRE não é
# flaky — é defeito, e chamá-lo de flaky é como o mecanismo aprende a ignorar o vermelho.
falhou_em, apareceu_em = {}, {}
for e in linhas:
    for f in e['familias_detalhe']:
        apareceu_em.setdefault(f['familia'], []).append(e['dia'])
        if f['fail'] > 0:
            falhou_em.setdefault(f['familia'], []).append(e['dia'])

print(f"═══ DETECTOR DE FLAKY — sobre {len(linhas)} execução(ões)\n")
if not falhou_em:
    print("  nenhuma família falhou em nenhuma execução coletada.")
    print(f"  ⚠ com {len(linhas)} execução(ões) isto ainda NÃO é evidência de estabilidade —")
    print("    é ausência de observação. Flaky se mede em dezenas de runs, não em unidades.")
    sys.exit(0)

for fam, dias in sorted(falhou_em.items(), key=lambda x: -len(x[1])):
    tot = len(apareceu_em[fam])
    cls = "FLAKY" if len(dias) < tot else "SEMPRE VERMELHA (defeito, não flaky)"
    print(f"  {fam:<34} falhou {len(dias):>3}/{tot:<3} → {cls}")
    print(f"     dias: {', '.join(dias[:8])}{' …' if len(dias) > 8 else ''}")
PY
  exit 0
fi

# ---------------------------------------------------------------------------
# Modo COLETA
# ---------------------------------------------------------------------------
REPORT=""; SOURCE="nao-declarado"; JOBS="nao-declarado"; STRICT="nao-declarado"; RUN_URL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --report)   shift; REPORT="${1:-}" ;;
    --report=*) REPORT="${1#*=}" ;;
    --source)   shift; SOURCE="${1:-}" ;;
    --source=*) SOURCE="${1#*=}" ;;
    --jobs)     shift; JOBS="${1:-}" ;;
    --jobs=*)   JOBS="${1#*=}" ;;
    --strict)   shift; STRICT="${1:-}" ;;
    --strict=*) STRICT="${1#*=}" ;;
    --run-url)  shift; RUN_URL="${1:-}" ;;
    --run-url=*) RUN_URL="${1#*=}" ;;
    *) _die "arg desconhecido: $1 (use --report <ABS.tsv> [--source|--jobs|--strict|--run-url] | --resumo | --flaky)" ;;
  esac
  shift
done

[ -n "${REPORT}" ] || _die "--report <ABS.tsv> é obrigatório no modo coleta. Produza-o com: ONION_SELFTEST_STRICT=1 bash .claude/validation/lint-selftest.sh --jobs auto --report <ABS.tsv>"
case "${REPORT}" in /*) : ;; *) _die "--report exige caminho ABSOLUTO (veio '${REPORT}') — o mesmo contrato da flag na bancada, e pela mesma razão: relativo a QUÊ, se o coletor roda de cron?" ;; esac
[ -f "${REPORT}" ] || _die "relatório inexistente: ${REPORT}"

case "${SOURCE}" in
  local|ci|precommit|cron|nao-declarado) : ;;
  *) _die "--source aceita local|ci|precommit|cron (veio '${SOURCE}'). Vocabulário fechado de propósito: a comparação CI × local é o que a série existe para permitir, e texto livre a destrói — a lição dos 262 resíduos, aplicada antes de doer." ;;
esac

HOJE="$(date +%F)"
AGORA="$(date -Is)"
SHA="$(git -C "${ROOT}" rev-parse HEAD 2>/dev/null || echo 'nao-declarado')"
BRANCH="$(git -C "${ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'nao-declarado')"

mkdir -p "${OUT}"

# IDEMPOTÊNCIA por (dia, source, sha). O molde GTM usa (dia, medidor) porque mede o mundo uma
# vez ao dia; aqui um mesmo dia legitimamente tem várias execuções — pre-commit, CI, local — e
# colapsá-las por dia APAGARIA justamente o par que revela flaky (a mesma árvore, dois
# resultados). O sha entra na chave por isso.
if [ -f "${LEDGER}" ] && grep -q "\"dia\":\"${HOJE}\",\"source\":\"${SOURCE}\",\"sha\":\"${SHA}\"" "${LEDGER}"; then
  echo "collect-selftest: (${HOJE}, ${SOURCE}, ${SHA:0:8}) já coletado — idempotente, nada a fazer."
  exit 0
fi

python3 - "${REPORT}" "${LEDGER}" "${HOJE}" "${AGORA}" "${SOURCE}" "${SHA}" "${BRANCH}" \
         "${JOBS}" "${STRICT}" "${RUN_URL}" <<'PY'
import json, sys

rep, ledger, hoje, agora, source, sha, branch, jobs, strict, run_url = sys.argv[1:11]

fams, total = [], None
with open(rep, encoding='utf-8') as fh:
    for i, line in enumerate(fh):
        line = line.rstrip('\n')
        if not line or (i == 0 and line.startswith('familia\t')):
            continue
        c = line.split('\t')
        if len(c) < 5:
            sys.stderr.write(f"collect-selftest: linha {i+1} do relatorio tem {len(c)} coluna(s), esperava 5.\n")
            sys.exit(2)
        reg = {"familia": c[0], "pass": int(c[1]), "fail": int(c[2]),
               "skip": int(c[3]), "segundos": int(c[4])}
        if c[0] == 'TOTAL':
            total = reg
        else:
            fams.append(reg)

if total is None:
    sys.stderr.write("collect-selftest: relatorio SEM linha TOTAL — a bancada abortou antes da soma, "
                     "ou o arquivo esta truncado. Coletar isso registraria como execucao o que nao foi "
                     "uma. Recusa.\n")
    sys.exit(2)
if not fams:
    sys.stderr.write("collect-selftest: relatorio com TOTAL e ZERO familias — quebra, nao 'bancada vazia'.\n")
    sys.exit(2)

# A PARTIÇÃO TEM DE FECHAR. É a mesma asserção que o ledger dos resíduos carrega, e existe pela
# mesma razão: um total que não bate com as partes é um número que parece medido e não é.
soma = sum(f['pass'] for f in fams)
if soma != total['pass']:
    sys.stderr.write(f"collect-selftest: soma das familias ({soma}) != TOTAL ({total['pass']}). "
                     "O relatorio nao fecha — nao se coleta um total que nao bate com as partes.\n")
    sys.exit(2)

env = {
    "dia": hoje, "source": source, "sha": sha,          # a chave de idempotência, nesta ordem
    "ts": agora, "branch": branch,
    "jobs": jobs, "strict": strict, "run_url": run_url or "nao-declarado",
    "pass": total['pass'], "fail": total['fail'], "skip": total['skip'],
    "segundos": total['segundos'],
    # DOIS NÚMEROS, PORQUE SÃO DUAS COISAS. A família `fixtures` é FATIADA em shards e cada
    # shard emite a sua linha: medido em 2026-09-09, 165 linhas para 158 famílias (as 8 fatias
    # somam 12×6+11×2 = 94, exatamente as 94 fixtures do manifesto). A 1ª versão deste coletor
    # gravava `"familias": len(fams)` — contava LINHAS e se chamava famílias. Campo cujo NOME
    # não é o que ele conta é a classe que esta onda inteira persegue, cometida dentro dela.
    "familias": len({f['familia'] for f in fams}),
    "linhas_relatorio": len(fams),
    "familias_com_falha": [f['familia'] for f in fams if f['fail'] > 0],
    "familias_detalhe": fams,
}
# COMPACTO, e não por estética: a guarda de idempotência lá em cima procura a chave
# `"dia":"…","source":"…","sha":"…"` SEM espaços. O `json.dumps` default escreve `"dia": "…"`,
# e o grep nunca casava — medido no primeiro dogfood deste script, que gravou o MESMO envelope
# duas vezes seguidas. Guarda que checa um formato que o escritor não produz é guarda nenhuma,
# e é a classe exata que esta onda persegue: a verificação e o verificado tinham de se falar.
with open(ledger, 'a', encoding='utf-8') as fh:
    fh.write(json.dumps(env, ensure_ascii=False, separators=(',', ':')) + "\n")

print(f"collect-selftest: envelope gravado — {total['pass']} pass · {total['fail']} fail · "
      f"{total['skip']} skip em {env['familias']} famílias / {env['linhas_relatorio']} linhas "
      f"({total['segundos']}s), origem={source}, sha={sha[:8]}")
if env['familias_com_falha']:
    print(f"  famílias com falha: {', '.join(env['familias_com_falha'])}")
PY
