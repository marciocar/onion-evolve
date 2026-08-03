#!/usr/bin/env bash
# review-verdict.sh — o onion-review REVISOU de fato, ou só saiu verde?
#
# A PERGUNTA: dado o arquivo de execução da `claude-code-action`, houve revisão SEMÂNTICA
# ou o agente morreu antes de produzir veredito?
#
# ═══ POR QUE EXISTE (o incidente medido em 2026-08-03) ═══
# O `onion-review.yml` JÁ tinha máquina de resiliência completa — retry na 2ª tentativa e
# aviso visível (annotation + comentário no PR) quando ambas crashavam. Ela **nunca disparou
# uma única vez**. Medido em 4 runs do dia (03:34, 12:10, 17:11, 19:17): forma idêntica em
# todas — `is_error: true`, `num_turns: 1`, `total_cost_usd: 0` — e **zero** comentários em
# qualquer PR. Os 11 PRs daquela sessão mergearam sob um revisor que não leu nada.
#
# A CAUSA não era o token nem o pin: o retry e o aviso eram condicionados a
# `steps.review.outcome == 'failure'`, e a action sai com **exit 0 mesmo com is_error true**
# (o log registra `outcome=success;conclusion=success` numa run que custou 0 e deu 1 turno).
# A condição lia o EXIT CODE do wrapper; o fato vive DENTRO do JSON. Enquanto a leitura fosse
# do sinal errado, nenhuma quantidade de retry consertaria — o gatilho jamais era satisfeito.
#
# É a doutrina `behavior-over-declaration` na própria casa: o workflow DECLARAVA resiliência
# em 3 blocos de comentário e não a EXECUTAVA. Só o comportamento conta.
#
# ═══ POR QUE UM SCRIPT, E NÃO jq NO YAML ═══
# YAML de workflow não tem selftest: só se prova em produção, um PR por vez, e foi exatamente
# assim que a máquina quebrada sobreviveu meses parecendo sã. Aqui a classificação é um
# artefato testável — `lint-selftest.sh` exerce os 5 desfechos, inclusive o (MUT) que prova
# que a distinção é load-bearing.
#
# ═══ CRITÉRIO (deliberadamente ESTREITO) ═══
# `is_error` é o sinal, mais arquivo ausente/ilegível. **NÃO** se reprova por `num_turns<=1`
# nem por `total_cost_usd == 0` sozinhos: uma revisão legítima que não acha nada pode fechar
# em 1 turno, e custo 0 é esperado sob assinatura/OAuth. Um falso "não revisou" ensinaria a
# ignorar o aviso — que é precisamente como um alarme morre. O critério estreito bastaria
# para pegar o incidente de 2026-08-03 (lá `is_error` era true).
#
# USO
#   bash review-verdict.sh <execution_file>      # key=value p/ $GITHUB_OUTPUT (stdout)
#   bash review-verdict.sh --selftest            # roda os casos e sai 0/1
#
# CONTRATO
#   stdout: SÓ as linhas `chave=valor` (revisou, motivo, turnos, custo) — colável em
#           $GITHUB_OUTPUT sem filtro. Diagnóstico humano vai para stderr.
#   exit  : 0 sempre que classificou (inclusive `revisou=false`). Este script CLASSIFICA;
#           quem decide bloquear/avisar é o workflow. Exit != 0 só em erro de uso.
set -uo pipefail

emit() { # $1=revisou $2=motivo $3=turnos $4=custo
  printf 'revisou=%s\nmotivo=%s\nturnos=%s\ncusto=%s\n' "$1" "$2" "$3" "$4"
}

# Traduz o `subtype` do resultado para um motivo que DIZ O QUE FAZER. Nasceu em 2026-08-03,
# quando o revisor voltou a funcionar após a troca da chave e passou a falhar por outro
# motivo: `error_max_turns` após 9 turnos e US$ 0,34 — trabalho REAL interrompido por
# orçamento. Classificar isso como `is-error` genérico, igual a "morreu sem fazer nada",
# apaga a diferença que decide o conserto (subir `--max-turns` × investigar a origem).
motivo_do_subtipo() { # $1=subtype
  case "${1}" in
    error_max_turns)     printf 'orcamento-de-turnos' ;;
    error_during_execution) printf 'erro-na-execucao' ;;
    # `subtype: success` COM `is_error: true` é a contradição do caso de 07-14→08-03: o wrapper
    # se declarava bem-sucedido enquanto o agente morria. É o balde genérico por direito — a
    # própria ausência de subtipo útil É o sintoma.
    success | '' | null) printf 'is-error' ;;
    *)                   printf 'is-error:%s' "${1}" ;;
  esac
}

verdict() {
  local f="${1:-}"

  # Sem caminho: a action nem chegou a expor o output (step pulado, ou morreu antes).
  if [ -z "${f}" ]; then
    printf 'review-verdict: execution_file VAZIO — a action não expôs o arquivo\n' >&2
    emit false sem-arquivo 0 0
    return 0
  fi
  if [ ! -f "${f}" ]; then
    printf 'review-verdict: execution_file AUSENTE: %s\n' "${f}" >&2
    emit false sem-arquivo 0 0
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    # Sem jq NÃO se declara "revisou" — declarar-por-falta-de-ferramenta é o fail-open que
    # esta casa persegue. Assume-se o pior e o aviso dispara.
    printf 'review-verdict: jq ausente — não dá para ler o veredito; assumindo NÃO revisou\n' >&2
    emit false sem-jq 0 0
    return 0
  fi

  # FORMATO — verificado na fonte da action no pin e90deca (base-action/src/execution-file.ts):
  # `writeFile(executionFile, JSON.stringify(messages, null, 2))` → **array JSON** indentado,
  # NÃO JSONL. A 1ª versão deste script assumiu JSONL e o `jq -s` teria devolvido vazio em
  # TODA run — alarme falso permanente, que é como um alarme morre. O selftest não pegou
  # porque as fixtures foram escritas na mesma suposição errada: fixture derivada de premissa
  # CONFIRMA a premissa. Só a leitura da fonte desfez.
  # A expressão abaixo aceita as três formas (array — a real; objeto solto; JSONL) para que
  # uma mudança de formato a montante degrade para um caso já coberto, não para silêncio.
  local res
  res="$(jq -c 'if type == "array" then . else [.] end
                | map(select(.type? == "result")) | last // empty' "${f}" 2>/dev/null | tail -1)"
  if [ -z "${res}" ] || [ "${res}" = "null" ]; then
    printf 'review-verdict: sem objeto `type: result` em %s — execução truncada\n' "${f}" >&2
    emit false json-ilegivel 0 0
    return 0
  fi

  local is_err turns cost subtype
  is_err="$(printf '%s' "${res}" | jq -r '.is_error // false')"
  turns="$(printf '%s' "${res}" | jq -r '.num_turns // 0')"
  cost="$(printf '%s' "${res}" | jq -r '.total_cost_usd // 0')"
  subtype="$(printf '%s' "${res}" | jq -r '.subtype // empty')"

  if [ "${is_err}" = "true" ]; then
    local motivo; motivo="$(motivo_do_subtipo "${subtype}")"
    printf 'review-verdict: is_error=true subtype=%s (turnos=%s, custo=%s) — NÃO houve revisão\n' \
      "${subtype:-—}" "${turns}" "${cost}" >&2
    emit false "${motivo}" "${turns}" "${cost}"
    return 0
  fi

  printf 'review-verdict: revisão real (turnos=%s, custo=%s)\n' "${turns}" "${cost}" >&2
  emit true ok "${turns}" "${cost}"
  return 0
}

# ───────────────────────────── selftest ─────────────────────────────
run_selftest() {
  local d rc=0 out
  d="$(mktemp -d)"
  _case() { # $1=nome $2=arquivo $3=revisou-esperado $4=motivo-esperado
    out="$(verdict "$2" 2>/dev/null)"
    local got_r got_m
    got_r="$(printf '%s' "${out}" | awk -F= '/^revisou=/{print $2}')"
    got_m="$(printf '%s' "${out}" | awk -F= '/^motivo=/{print $2}')"
    if [ "${got_r}" = "$3" ] && [ "${got_m}" = "$4" ]; then
      printf '  ✓ %s\n' "$1"
    else
      printf '  ✗ %s — esperado revisou=%s motivo=%s, veio revisou=%s motivo=%s\n' \
        "$1" "$3" "$4" "${got_r}" "${got_m}"; rc=1
    fi
  }

  # (a) o INCIDENTE de 2026-08-03, no formato REAL (array indentado, como a action escreve):
  #     exit 0 do wrapper, `is_error` escondido dentro do JSON.
  cat > "${d}/crash.json" <<'JSON'
[
  { "type": "system", "subtype": "init", "model": "claude-sonnet-5" },
  { "type": "result", "subtype": "success", "is_error": true,
    "duration_ms": 186439, "num_turns": 1, "total_cost_usd": 0 }
]
JSON
  _case 'review-verdict: is_error=true → NÃO revisou (o caso real de 2026-08-03, formato array)' \
    "${d}/crash.json" false is-error

  # (b) revisão SÃ — o par que impede a guarda de virar "sempre reprova".
  cat > "${d}/ok.json" <<'JSON'
[
  { "type": "system", "subtype": "init" },
  { "type": "result", "subtype": "success", "is_error": false,
    "num_turns": 6, "total_cost_usd": 0.42 }
]
JSON
  _case 'review-verdict: is_error=false → revisou' "${d}/ok.json" true ok

  # (c) revisão sã que fecha em 1 TURNO e custo 0 — NÃO pode reprovar. É a fronteira
  #     deliberada do critério: sob assinatura o custo é 0, e "nada a apontar" cabe num turno.
  printf '[{"type":"result","is_error":false,"num_turns":1,"total_cost_usd":0}]\n' > "${d}/rapido.json"
  _case 'review-verdict: 1 turno + custo 0 SEM is_error → revisou (critério é estreito de propósito)' \
    "${d}/rapido.json" true ok

  # (d) arquivo ausente → assume o pior (fail-closed no aviso, nunca "revisou").
  _case 'review-verdict: execution_file ausente → NÃO revisou' "${d}/nao-existe.json" false sem-arquivo

  # (e) caminho vazio → mesma postura.
  _case 'review-verdict: execution_file vazio → NÃO revisou' '' false sem-arquivo

  # (f) execução truncada (sem objeto `result`) → não se declara revisão.
  printf '[{"type":"system","subtype":"init"}]\n' > "${d}/truncado.json"
  _case 'review-verdict: array sem `type: result` → NÃO revisou' "${d}/truncado.json" false json-ilegivel

  # (g) TOLERÂNCIA a JSONL: se a action mudar de formato a montante, o veredito degrada para
  #     um caso coberto em vez de silenciar. Este caso guarda a promessa do comentário acima —
  #     sem ele, a tolerância seria declarada e não testada (o defeito que este script existe
  #     para combater).
  printf '%s\n' \
    '{"type":"system","subtype":"init"}' \
    '{"type":"result","is_error":true,"num_turns":1,"total_cost_usd":0}' > "${d}/jsonl.jsonl"
  _case 'review-verdict: formato JSONL também classifica (tolerância testada, não só prometida)' \
    "${d}/jsonl.jsonl" false is-error

  # (h) ORÇAMENTO ESGOTADO — o caso real de 2026-08-03, DEPOIS da troca da chave: o revisor
  #     trabalhou 9 turnos e US$ 0,34 e bateu no `--max-turns`. Continua "não revisou" (não
  #     entregou veredito), mas o MOTIVO tem de separá-lo de "morreu sem fazer nada": o conserto
  #     de um é subir o orçamento, o do outro é investigar a origem.
  cat > "${d}/maxturns.json" <<'JSON'
[
  { "type": "result", "subtype": "error_max_turns", "is_error": true,
    "duration_ms": 35225, "num_turns": 9, "total_cost_usd": 0.3367 }
]
JSON
  _case 'review-verdict: error_max_turns → NÃO revisou, motivo `orcamento-de-turnos` (não `is-error` genérico)' \
    "${d}/maxturns.json" false orcamento-de-turnos

  # (i) subtype DESCONHECIDO não some — vira `is-error:<subtype>`, para que um modo de falha
  #     novo chegue NOMEADO em vez de cair no balde genérico e virar mistério (foi o balde
  #     genérico que escondeu um 401 por três semanas).
  printf '[{"type":"result","subtype":"error_coisa_nova","is_error":true,"num_turns":3,"total_cost_usd":0.1}]\n' \
    > "${d}/novo.json"
  _case 'review-verdict: subtype desconhecido chega NOMEADO (`is-error:error_coisa_nova`)' \
    "${d}/novo.json" false is-error:error_coisa_nova

  # (MUT) a distinção é LOAD-BEARING: se o critério ignorasse `is_error`, o caso (a) — o
  # incidente real — passaria como revisão. Prova que (a) e (b) não coincidem por acaso.
  local a b
  a="$(verdict "${d}/crash.json" 2>/dev/null | awk -F= '/^revisou=/{print $2}')"
  b="$(verdict "${d}/ok.json"    2>/dev/null | awk -F= '/^revisou=/{print $2}')"
  if [ "${a}" != "${b}" ]; then
    printf '  ✓ review-verdict: (MUT) crash e revisão-sã produzem vereditos OPOSTOS — a leitura é load-bearing\n'
  else
    printf '  ✗ review-verdict: (MUT) crash e revisão-sã deram o MESMO veredito (%s) — não distingue nada\n' "${a}"; rc=1
  fi

  rm -rf "${d}"
  return "${rc}"
}

case "${1:-}" in
  --selftest) run_selftest ;;
  -h|--help)  sed -n '2,40p' "$0"; exit 0 ;;
  *)          verdict "${1:-}" ;;
esac
