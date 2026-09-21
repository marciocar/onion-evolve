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
#   bash review-verdict.sh --gate <achados> [pr] # DECIDE bloquear; corpo em stdout, veredito no rc
#   bash review-verdict.sh --texto <exec_file>   # imprime só o parecer do revisor
#   bash review-verdict.sh --corpo <marca> <json> <exec_file>   # corpo do comentário do PR
#   bash review-verdict.sh --selftest            # roda os casos e sai 0/1
#
# CONTRATO
#   stdout: SÓ as linhas `chave=valor` (revisou, motivo, turnos, custo, texto_chars, achados) —
#           colável em $GITHUB_OUTPUT sem filtro. Diagnóstico humano vai para stderr.
#   exit  : 0 sempre que classificou (inclusive `revisou=false`). Este script CLASSIFICA;
#           quem decide bloquear/avisar é o workflow. Exit != 0 só em erro de uso.
#           EXCEÇÃO DECLARADA: o modo `--gate` DECIDE, e é o único cujo rc significa veredito
#           (1 = bloqueia). Ele existe aqui, e não no YAML, porque o YAML não tem bancada.
#
# `achados` (desde 2026-09-20): quantos a linha `VEREDITO:` do parecer declara. `-1` significa
#           NÃO CONSEGUI CONTAR e nunca bloqueia — "não revisou" já é o campo `revisou`, e
#           transformar ignorância em bloqueio é a classe que esta casa mais persegue.
set -uo pipefail

emit() { # $1=revisou $2=motivo $3=turnos $4=custo $5=chars-do-texto (opcional) $6=achados (opcional)
  printf 'revisou=%s\nmotivo=%s\nturnos=%s\ncusto=%s\ntexto_chars=%s\nachados=%s\n' "$1" "$2" "$3" "$4" "${5:-0}" "${6:--1}"
}

# ── CONTAGEM DE ACHADOS — o que transforma parecer ADVISORY em gate ───────────────────────────
# POR QUE EXISTE (medido 2026-09-20, ordem do maestro): em 33 pareceres do `onion-review`, DEZ
# apontaram violacao — e o parecer nao bloqueia, entao o defeito era apontado, mergeado, e FICAVA.
# Conferi tres deles no vivo: `_viaja`, `_PAPEL_DESTE_REPO` e `_base_nome` seguiam em main depois
# de acusados. Pagava-se ~US$ 0,80 por PR pela descoberta e nao se recolhia a entrega.
#
# A FONTE E A LINHA `VEREDITO:`, que o prompt do revisor CONTRATA ("TERMINE a resposta com o
# parecer no formato abaixo"). Le-se a ULTIMA ocorrencia, porque o contrato e sobre o FIM da
# resposta e o corpo pode citar o formato ao explicar um achado.
#
# ⚠️ TRES DESFECHOS, e o terceiro e o que impede a guarda de virar fail-open OU fail-closed cego:
#   · N >= 0  → contagem confiavel (0 = conforme; N>0 = bloqueia)
#   · -1      → NAO PUDE CONTAR (texto ausente, ou `VEREDITO:` em forma que nao reconheco).
#               NUNCA bloqueia: "nao revisou" ja e coberto pelo campo `revisou`, e inventar
#               bloqueio a partir de ignorancia e a classe que esta casa mais persegue.
# `LC_ALL=C` no grep: o numero e ASCII, e casar acento (`violações`) depende de locale — o do
# runner nao e o meu ([[bancada-mede-no-locale-do-hook]]). Por isso so o NUMERO e lido.
count_findings() { # $1=texto do parecer
  local t="$1" defenced anchored line v num vals="" distinct
  [ -n "${t}" ] || { printf '%s' -1; return 0; }
  # (1) FORA OS BLOCOS CERCADOS. Fence remove a indentacao, entao uma citacao de
  #     `VEREDITO: conforme` dentro de ``` chega na COLUNA 0 e discorda do veredito real — medido:
  #     parecer com 2 violacoes citando o formato em fence virava `-1` e deixava de bloquear.
  #     Descartar o conteudo cercado e o que devolve a indentacao como defesa.
  # (2) FORA O BOM UTF-8, que antecede `VEREDITO` e quebra a ancora de coluna 0 em silencio.
  defenced="$(printf '%s\n' "${t}" | tr -d '\r' | sed '1s/^\xEF\xBB\xBF//' \
    | awk '/^[[:space:]]*```/ { fence = !fence; next } !fence { print }')"
  # (3) ANCORA NA COLUNA 0, tolerando decoracao markdown (`**`, `#`, `>`, `- `) mas NUNCA
  #     indentacao: a lista de evidencias vem DEPOIS do veredito no formato contratado, e uma
  #     evidencia que cite a palavra e sempre indentada. Coluna 0 e o discriminante.
  #    `>` FICA FORA: `**`/`#`/`- ` sao como um modelo formata o PROPRIO veredito; `>` e como
  #    ele CITA o de outro. Aceitar `>` deixava um eco citado discordar do veredito real e
  #    derrubar tudo para -1 — sequestro por citacao. Preco declarado: veredito UNICO em
  #    blockquote sai -1. Achado por refutador adversarial.
  anchored="$(printf '%s\n' "${defenced}" | LC_ALL=C grep -iE '^(\*\*|#{1,6}[[:space:]]*|-[[:space:]]+)*VEREDITO:' || true)"
  [ -n "${anchored}" ] || { printf '%s' -1; return 0; }
  while IFS= read -r line; do
    [ -n "${line}" ] || continue
    v=-1
    # `conforme` e LINHA INTEIRA, nunca prefixo: "conforme, exceto por 2 violacoes" saia ZERO.
    # ⚠️ PRECEDENCIA: CONTAGEM primeiro, `conforme` depois, -1 por ultimo. Resolve os tres de
    #    uma vez: `conforme, exceto por 2 violacoes`→2 · `conforme, mas veja 3 pontos`→0 ·
    #    `conforme (REGRA 36)`→0 · `NAO CONFORME — 4 violacoes`→4. O numero SO e contagem com
    #    `viola…` colado: antes pegava qualquer digito e `conforme (REGRA 36)` saia 36 — o gate
    #    REPROVAVA anunciando '36 violacoes', falso-positivo que bloqueia com numero fabricado.
    num="$(LC_ALL=C grep -oiE '[0-9]+[[:space:]]*viola' <<< "${line}" | LC_ALL=C grep -oE '[0-9]+' | head -1)"
    if [ -n "${num}" ] && [ "${#num}" -le 4 ]; then
      v="${num}"
    elif [ -z "${num}" ] && LC_ALL=C grep -qiE 'VEREDITO:\*{0,2}[[:space:]]*conforme' <<< "${line}"; then
      v=0
    fi
    # ⚠️ TETO DE SANEAMENTO (4 digitos): numero absurdo e texto corrompido/truncado, nao contagem.
    #    Sem ele, parecer corrompido viraria bloqueio com contagem sem sentido; `-1` e a resposta
    #    honesta para entrada que nao se parece com a do contrato.
    vals="${vals}${v}
"
  done <<< "${anchored}"
  # (4) ANCORAS QUE DISCORDAM ⇒ -1. Escolher em silencio entre vereditos contraditorios e inventar
  #     um; `-1` nao bloqueia, entao o pior caso e verde-com-aviso, nunca verde que AFIRMA
  #     conformidade falsa nem vermelho com contagem inventada.
  distinct="$(printf '%s' "${vals}" | LC_ALL=C grep -v '^$' | LC_ALL=C sort -u)"
  if [ "$(printf '%s\n' "${distinct}" | LC_ALL=C grep -c .)" -ne 1 ]; then printf '%s' -1; return 0; fi
  printf '%s' "${distinct}"
}

# ── POR QUE `texto_chars` NASCE COMO MEDICAO, E NAO COMO EXIGENCIA ────────────────────────────
# `revisou=true` hoje significa "o revisor EXECUTOU sem erro" (is_error + subtype). Isso e
# estritamente mais fraco que "a revisao EXISTE e e legivel" — e a diferenca foi MEDIDA em
# 2026-08-07: nove PRs seguidos com revisou=true, ~US$1,27 cada, e `comments=0 reviews=0` em
# todos. E behavior-over-declaration mordendo o gate que existe para revisar.
#
# A tentacao e exigir texto agora. NAO FACO — mas a razao MUDOU, e a versao anterior deste
# comentario era preguica vestida de prudencia. Ela dizia "nao tenho um execution_file real em
# maos para confirmar sob qual chave o texto vem". FALSO: `sdk.d.ts` v0.3.220 (a mesma do pin
# be7b93b) declara `SDKResultSuccess.result: string` OBRIGATORIO — a fonte estava no disco, e o
# que faltava era VERIFICACAO NAO PAGA, nao informacao. Elenxo 2026-08-07.
#
# A razao VERDADEIRA de nao endurecer: `SDKResultError` NAO TEM campo `result` nenhum
# (sdk.d.ts:4269-4288) — tem `errors: string[]`. Logo `texto_chars == 0` e o estado NORMAL de
# qualquer run que falhou, e exigir texto transformaria toda falha em "nao revisou" por um motivo
# errado. O criterio de `revisou` e sobre EXECUCAO; o texto e outra dimensao e merece campo proprio.
# Por isso `texto_chars` MEDE e nao exige — e a decisao agora tem fundamento, nao hedge.

# Traduz o `subtype` do resultado para um motivo que DIZ O QUE FAZER. Nasceu em 2026-08-03,
# quando o revisor voltou a funcionar após a troca da chave e passou a falhar por outro
# motivo: `error_max_turns` após 9 turnos e US$ 0,34 — trabalho REAL interrompido por
# orçamento. Classificar isso como `is-error` genérico, igual a "morreu sem fazer nada",
# apaga a diferença que decide o conserto (subir `--max-turns` × investigar a origem).
reason_for_subtype() { # $1=subtype
  case "${1}" in
    # Os QUATRO subtypes de erro que o SDK declara (sdk.d.ts:4269-4271, v0.3.220 — a mesma do pin
    # be7b93b). Nomear so dois deixava dois cairem no balde generico `is-error:<subtype>`, apagando
    # a diferenca que decide o conserto — que e a razao de esta funcao existir.
    error_max_turns)     printf 'orcamento-de-turnos' ;;
    error_during_execution) printf 'erro-na-execucao' ;;
    error_max_budget_usd) printf 'orcamento-de-dolar' ;;
    error_max_structured_output_retries) printf 'schema-nao-atendido' ;;
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
  # O TEXTO do revisor. Vem no objeto `result` sob `.result` (schema do SDK); as entradas
  # `type: "assistant"` do array carregam o mesmo em `.message.content[].text`. Nenhum parser do
  # repo jamais leu qualquer um dos dois: o arquivo e gerado, consumido por 4 campos, descartado.
  # Aqui so se MEDE o tamanho — imprimir e trabalho do modo --texto.
  local text chars
  text="$(printf '%s' "${res}" | jq -r '.result // empty' 2>/dev/null || true)"
  chars="${#text}"

  if [ "${is_err}" = "true" ]; then
    local reason; reason="$(reason_for_subtype "${subtype}")"
    printf 'review-verdict: is_error=true subtype=%s (turnos=%s, custo=%s) — NÃO houve revisão\n' \
      "${subtype:-—}" "${turns}" "${cost}" >&2
    emit false "${reason}" "${turns}" "${cost}" "${chars}" -1
    return 0
  fi

  printf 'review-verdict: revisão real (turnos=%s, custo=%s)\n' "${turns}" "${cost}" >&2
  local findings; findings="$(count_findings "${text}")"
  emit true ok "${turns}" "${cost}" "${chars}" "${findings}"
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

  # (e) caminho empty → mesma postura.
  _case 'review-verdict: execution_file empty → NÃO revisou' '' false sem-arquivo

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

  # ── O TEXTO DO REVISOR (2026-08-07) ──────────────────────────────────────────────────────────
  # Ate aqui, NENHUMA fixture deste arquivo tinha uma entrada `type: assistant` nem um campo
  # `.result` — a existencia do texto nunca fora exercitada por nada no repo, e era exatamente por
  # isso que ninguem sabia que o parecer estava sendo pago e descartado.
  cat > "${d}/comtexto.json" <<'JSON'
[
  { "type": "assistant", "message": { "content": [ { "type": "text", "text": "lendo as meta-specs" } ] } },
  { "type": "result", "subtype": "success", "is_error": false, "num_turns": 46,
    "total_cost_usd": 2.15, "result": "## Parecer\n\nO diff esta conforme." }
]
JSON
  out="$(verdict "${d}/comtexto.json" 2>/dev/null)"
  local chars; chars="$(printf '%s' "${out}" | awk -F= '/^texto_chars=/{print $2}')"
  if [ "${chars:-0}" -gt 0 ]; then
    printf '  ✓ review-verdict: texto_chars MEDE o parecer (%s chars) — a existencia do texto deixa de ser suposicao\n' "${chars}"
  else printf '  ✗ review-verdict: texto_chars=%s com .result presente — a chave do texto esta errada\n' "${chars:-empty}"; rc=1; fi

  # --texto imprime o parecer, e e a fonte que NAO depende do posting funcionar.
  local t; t="$(reviewer_text "${d}/comtexto.json")"
  if printf '%s' "${t}" | grep -q 'O diff esta conforme'; then
    printf '  ✓ review-verdict: --texto imprime o parecer integro (fonte independente do github_token)\n'
  else printf '  ✗ review-verdict: --texto nao trouxe o parecer: %s\n' "${t}"; rc=1; fi

  # ── OS TRES DEGRAUS DE DEGRADACAO ────────────────────────────────────────────────────────────
  # A versao anterior deste caso usava `ok.json` (subtype success SEM `.result`) para provar a
  # degradacao — um estado IMPOSSIVEL: `sdk.d.ts` declara `SDKResultSuccess.result: string`
  # OBRIGATORIO. Validava o que nao pode ocorrer, e deixava sem teste os dois estados que OCORREM.
  # Elenxo 2026-08-07.

  # (degrau 2) erro COM `errors[]` — o estado real de `error_max_turns`, o incidente de 08-03 que
  # motivou o --max-turns 60. `SDKResultError` nao tem `.result`; tem `errors`.
  cat > "${d}/comerros.json" <<'JSON'
[
  { "type": "result", "subtype": "error_max_turns", "is_error": true, "num_turns": 60,
    "total_cost_usd": 3.1, "errors": ["max turns (60) reached"] }
]
JSON
  t="$(reviewer_text "${d}/comerros.json")"
  if printf '%s' "${t}" | grep -q 'max turns (60) reached'; then
    printf '  ✓ review-verdict: erro com errors[] → imprime o DIAGNOSTICO do SDK (nao manda cacar mudanca de schema)\n'
  else printf '  ✗ review-verdict: errors[] nao chegou a saida: %s\n' "${t}"; rc=1; fi

  # (degrau 3) erro SEM `errors[]`, mas com texto parcial em `assistant` — e ali que o veredito
  # sobrevive quando o run morre no meio. Sem este degrau, o parecer parcial some.
  cat > "${d}/parcial.json" <<'JSON'
[
  { "type": "assistant", "message": { "content": [ { "type": "text", "text": "VEREDITO: 2 violacoes" } ] } },
  { "type": "result", "subtype": "error_during_execution", "is_error": true, "num_turns": 9,
    "total_cost_usd": 0.3 }
]
JSON
  t="$(reviewer_text "${d}/parcial.json")"
  if printf '%s' "${t}" | grep -q 'VEREDITO: 2 violacoes'; then
    printf '  ✓ review-verdict: erro sem errors[] → salva o texto PARCIAL do assistant (o veredito sobrevive)\n'
  else printf '  ✗ review-verdict: texto parcial perdido: %s\n' "${t}"; rc=1; fi

  # (piso) nem `.result`, nem `errors[]`, nem `assistant` — a unica ausencia REAL de parecer.
  cat > "${d}/mudo.json" <<'JSON'
[ { "type": "result", "subtype": "error_during_execution", "is_error": true, "num_turns": 0, "total_cost_usd": 0 } ]
JSON
  t="$(reviewer_text "${d}/mudo.json")"
  if printf '%s' "${t}" | grep -q 'nao chegou a falar'; then
    printf '  ✓ review-verdict: sem NENHUMA das tres fontes → diz que o revisor nao falou (ausencia real, nomeada)\n'
  else printf '  ✗ review-verdict: piso de degradacao errado: %s\n' "${t}"; rc=1; fi

  # (MUT) sem a leitura de `.result`, texto_chars fica 0 mesmo com parecer presente — prova que a
  # medicao e load-bearing e nao decorativa.
  local mut; mut="$(mktemp -d)"; cp "$0" "${mut}/m.sh"
  sed -i "s|jq -r '.result // empty' 2>/dev/null|jq -r '.inexistente // empty' 2>/dev/null|" "${mut}/m.sh"
  # `cmp`, NAO `grep`: o padrao procurado aparecia no ARQUIVO INTACTO (na propria linha do sed), e
  # um sed no-op "passava" a guarda. Medido no Elenxo 2026-08-07 — duas das tres guardas-da-guarda
  # deste arquivo eram VACUAS. Comparar os arquivos nao tem como ser vacuo: ou mudou, ou nao mudou.
  if ! cmp -s "$0" "${mut}/m.sh"; then
    local mc; mc="$(bash "${mut}/m.sh" "${d}/comtexto.json" 2>/dev/null | awk -F= '/^texto_chars=/{print $2}')"
    if [ "${mc:-0}" -eq 0 ]; then
      printf '  ✓ review-verdict: (MUT) sem a leitura de `.result` o texto some — a medicao e load-bearing\n'
    else printf '  ✗ review-verdict: (MUT) texto_chars=%s mesmo sem ler .result\n' "${mc}"; rc=1; fi
  else printf '  ✗ review-verdict: (MUT) mutacao NAO aplicada — o teste nao prova nada\n'; rc=1; fi
  rm -rf "${mut}"

  # ── O CORPO DO COMENTARIO (--corpo) ──────────────────────────────────────────────────────────
  # O revisor DEVOLVE; quem posta e o Onion. Estes casos guardam a ponte.
  local c
  c="$(comment_body '<!-- m -->' '{"veredito":"1 violacao","achados":[{"arquivo":"a.sh","linha":7,"regra":"commands.md:88","evidencia":"orq em agente"}]}' '')"
  if printf '%s' "${c}" | grep -q '| `a.sh:7` | commands.md:88 |' \
     && printf '%s' "${c}" | grep -q '<!-- m -->'; then
    printf '  ✓ review-verdict: --corpo renderiza a tabela com arquivo:linha e carrega a marca sticky\n'
  else printf '  ✗ review-verdict: --corpo nao renderizou: %s\n' "${c}"; rc=1; fi

  # achado SEM linha — o schema torna `linha` opcional, e a tabela nao pode imprimir "a.sh:"
  c="$(comment_body '<!-- m -->' '{"veredito":"x","achados":[{"arquivo":"b.md","regra":"r","evidencia":"e"}]}' '')"
  if printf '%s' "${c}" | grep -q '| `b.md` |'; then
    printf '  ✓ review-verdict: --corpo omite o `:linha` quando o achado nao tem linha\n'
  else printf '  ✗ review-verdict: --corpo com linha ausente saiu errado: %s\n' "${c}"; rc=1; fi

  # `achados: []` e CONFORME, nao "sem parecer" — a distincao que o array empty existe para fazer
  c="$(comment_body '<!-- m -->' '{"veredito":"conforme","achados":[]}' '')"
  if printf '%s' "${c}" | grep -q 'nenhum achado'; then
    printf '  ✓ review-verdict: --corpo com achados vazios diz CONFORME (array empty != ausencia)\n'
  else printf '  ✗ review-verdict: --corpo nao distinguiu conforme de empty: %s\n' "${c}"; rc=1; fi

  # FALLBACK: sem structured_output, o corpo cai para a PROSA. O parecer aparece de um jeito ou de
  # outro; o que nao pode e sumir — que era o estado ate 2026-08-07.
  local empty=0
  for so in '' 'lixo-nao-json' '{"sem":"achados"}'; do
    c="$(comment_body '<!-- m -->' "${so}" "${d}/comtexto.json")"
    printf '%s' "${c}" | grep -q 'O diff esta conforme' || empty=$((empty + 1))
  done
  if [ "${empty}" -eq 0 ]; then
    printf '  ✓ review-verdict: --corpo cai para PROSA nos 3 casos degenerados (empty/lixo/sem-achados) — nunca corpo empty\n'
  else printf '  ✗ review-verdict: --corpo perdeu o parecer em %s dos 3 casos degenerados\n' "${empty}"; rc=1; fi

  # (MUT) sem o ramo de fallback, structured_output empty produz corpo SEM parecer — prova que o
  # fallback e load-bearing e nao decorativo.
  local mut5; mut5="$(mktemp -d)"; cp "$0" "${mut5}/m.sh"
  sed -i 's|    reviewer_text "${f}"|    :|' "${mut5}/m.sh"
  if ! cmp -s "$0" "${mut5}/m.sh"; then
    c="$(bash "${mut5}/m.sh" --corpo '<!-- m -->' '' "${d}/comtexto.json")"
    if ! printf '%s' "${c}" | grep -q 'O diff esta conforme'; then
      printf '  ✓ review-verdict: (MUT) sem o fallback o parecer SOME do corpo — o fallback e load-bearing\n'
    else printf '  ✗ review-verdict: (MUT) parecer sobreviveu sem o fallback\n'; rc=1; fi
  else printf '  ✗ review-verdict: (MUT) mutacao do fallback NAO aplicada — o teste nao prova nada\n'; rc=1; fi
  rm -rf "${mut5}"

  # ── CONTAGEM DE ACHADOS + GATE (2026-09-20) ────────────────────────────────────────────────
  # O parecer deixou de ser advisory, entao erro de CONTAGEM agora bloqueia merge — ou, pior,
  # DEIXA passar defeito. Os dois lados precisam de caso, e os casos precisam poder FALHAR.
  _mkres() { # $1=arquivo  $2=texto do parecer
    printf '{"type":"result","subtype":"success","is_error":false,"num_turns":5,"total_cost_usd":0.5,"result":%s}\n' \
      "$(printf '%s' "$2" | jq -Rs .)" > "${d}/$1.json"
  }
  _ach() { bash "$0" "${d}/$1.json" 2>/dev/null | awk -F= '/^achados=/{print $2}'; }
  _chk() { # $1=arquivo $2=esperado $3=rotulo
    local got; got="$(_ach "$1")"
    [ "${got}" = "$2" ] && return 0
    printf '  ✗ review-verdict: (ACH) %s — veio %s, esperado %s\n' "$3" "${got}" "$2"; rc=1
  }

  _mkres conf 'VEREDITO: conforme';                              _chk conf 0   'conforme puro conta ZERO'
  _mkres tres 'VEREDITO: 3 violacoes';                           _chk tres 3   'N violacoes conta N'
  _mkres zero 'VEREDITO: 0 violacoes';                           _chk zero 0   'zero explicito e zero'
  _mkres neg  '**VEREDITO: 5 violacoes**';                       _chk neg  5   'negrito/decoracao nao cega a ancora'
  _mkres head '## VEREDITO: 5 violacoes';                        _chk head 5   'heading nao cega a ancora'
  _mkres minu 'Veredito: 3 violacoes';                           _chk minu 3   'minuscula nao cega a ancora'
  printf '  ✓ review-verdict: (ACH-1) conta conforme/N/zero, e decoracao e caixa nao cegam a ancora\n'

  # ⚠️ O HIJACK QUE EXISTIA: parecer que lista 3 achados e TERMINA com um bloco de codigo contendo
  #    `VEREDITO: conforme` contava ZERO — a ultima ocorrencia mandava, e ela estava no exemplo.
  _mkres fence 'achei
VEREDITO: 3 violacoes
```
VEREDITO: conforme
```'; _chk fence 3 'eco em FENCE nao sequestra o veredito'
  # ⚠️ E A PODA SO VALE COM FENCE BALANCEADA: aberta-e-nunca-fechada engoliria o veredito REAL.
  _mkres aberta 'VEREDITO: 3 violacoes
```
fence aberta e nunca fechada'; _chk aberta 3 'fence DESBALANCEADA nao engole o veredito'
  _mkres quote 'VEREDITO: 3 violacoes
> VEREDITO: conforme';                                           _chk quote 3 'eco em QUOTE nao sequestra (por isso `>` fica FORA da ancora)'
  _mkres ultima 'cito VEREDITO: 9 violacoes no meio
VEREDITO: conforme';                                             _chk ultima 0 'ultima ocorrencia manda'
  printf '  ✓ review-verdict: (ACH-2) fence/quote/citacao nao sequestram — e a poda exige fence par\n'

  _mkres ncf 'VEREDITO: NAO CONFORME — 4 violacoes';             _chk ncf 4  'NAO CONFORME com numero conta o NUMERO'
  _mkres pts 'VEREDITO: conforme, mas veja 3 pontos';            _chk pts 0  'numero que nao e de achado nao vira contagem'
  _mkres big 'VEREDITO: 99999999999999999999 violacoes';         _chk big -1 'numero absurdo nao estoura para "nao sei" calado'
  printf '  ✓ review-verdict: (ACH-3) o numero se reconhece pelo SUBSTANTIVO que o segue, com saneamento estrito\n'

  # ⚠️ CASO DISCRIMINANTE (a 1a versao deste caso NAO era). Afirmar `-1` sozinho fica VERDE com o
  #    contador MORTO, porque -1 e o default de `emit` — a passada adversarial provou apagando
  #    `count_findings` inteira e vendo este caso sobreviver. Agora ele exige as DUAS metades: o
  #    texto sem veredito da -1 E um controle com veredito da um numero. Contador morto quebra.
  _mkres mudo 'revisei tudo e nao uso o formato contratado'
  local _m _c; _m="$(_ach mudo)"; _c="$(_ach tres)"
  if [ "${_m}" = "-1" ] && [ "${_c}" = "3" ]; then
    printf '  ✓ review-verdict: (ACH-4) sem VEREDITO da -1 E o controle ainda conta 3 — o caso morre se o contador morrer\n'
  else printf '  ✗ review-verdict: (ACH-4) mudo=%s controle=%s (esperado -1 e 3)\n' "${_m}" "${_c}"; rc=1; fi

  # ⚠️ OS DOIS ABAIXO SAO DEFEITOS QUE A PRIMEIRA CURA INTRODUZIU — casos existem justamente
  #    porque "curei e piorei" e so o refutador viu. Cura sem caso de regressao e cura por sorte.
  #
  # (ACH-h) O NUMERO VINHA DE QUALQUER LUGAR DA LINHA: `VEREDITO: conforme (REGRA 36)` saia 36 e
  #    o gate REPROVAVA anunciando "36 violacoes". Falso-positivo que bloqueia, com numero
  #    fabricado — pior que o fail-open que a cura veio resolver, porque tem cara de diligencia.
  #    Agora o numero exige a palavra `viola…` ao lado, e sem ela o veredito e -1 (nao sei).
  _mkres regra 'VEREDITO: conforme (REGRA 36)'
  [ "$(_ach regra)" = "0" ] \
    && printf '  ✓ review-verdict: (ACH-h) numero SEM `viola…` ao lado nao vira contagem — `conforme (REGRA 36)` conta ZERO, nao 36\n' \
    || { printf '  ✗ review-verdict: (ACH-h) contagem fabricada: deu %s, esperado 0\n' "$(_ach regra)"; rc=1; }

  # (ACH-i) FENCE REMOVE A INDENTACAO, que era a unica defesa da ancora de coluna 0: uma citacao
  #    dentro de ``` chegava na coluna 0, discordava do veredito real e derrubava tudo para -1.
  #    Exposicao maxima nos PRs DESTA maquinaria, cujo diff carrega a string em fence.
  _mkres fence '```
VEREDITO: conforme
```
VEREDITO: 2 violacoes
- a.sh:1 — r — e'
  [ "$(_ach fence)" = "2" ] \
    && printf '  ✓ review-verdict: (ACH-i) citacao dentro de ``` e descartada — o veredito real sobrevive\n' \
    || { printf '  ✗ review-verdict: (ACH-i) fence anulou o veredito: deu %s, esperado 2\n' "$(_ach fence)"; rc=1; }

  # (ACH-j) DECORACAO E BOM nao podem apagar o gate em silencio: todos caiam em -1, e `-1` pinta
  #    o check de VERDE com um aviso. Deriva de fraseado do revisor viraria gate inerte.
  local _dec _dec_ok=1
  # ⚠️ `>` NAO ENTRA nesta lista: blockquote e CITACAO do veredito de outro, e aceita-lo deixava
  #    um eco sequestrar o veredito real. O caso (ACH-2) cobre esse lado.
  for _dec in '- VEREDITO: 3 violacoes' '## VEREDITO: 3 violacoes' '**VEREDITO: 3 violacoes**'; do
    _mkres dec "${_dec}"
    [ "$(_ach dec)" = "3" ] || { printf '  ✗ review-verdict: (ACH-j) `%s` deu %s, esperado 3\n' "${_dec}" "$(_ach dec)"; rc=1; _dec_ok=0; }
  done
  _mkres bom "$(printf '\xEF\xBB\xBFVEREDITO: 3 violacoes')"
  [ "$(_ach bom)" = "3" ] || { printf '  ✗ review-verdict: (ACH-j) BOM UTF-8 deu %s, esperado 3\n' "$(_ach bom)"; rc=1; _dec_ok=0; }
  [ "${_dec_ok}" = "1" ] \
    && printf '  ✓ review-verdict: (ACH-j) decoracao markdown (- > ##) e BOM nao apagam o gate\n'

  # GATE: o exit code e o que o CI consome.
  # ⚠️ O ✓ SO SAI SE TODAS PASSARAM. A 1a versao imprimia esta linha FORA do laco: mutando o gate
  #    para `if false`, a bancada emitia dois ✗ e, logo abaixo, o ✓ AFIRMANDO como provado o que
  #    acabara de medir falso. Num repo cujo lema e `exit-code-nao-e-a-verificacao`, ✓ fora da
  #    condicao e a mesma classe — o rc global segurava, a PROSA mentia. Achado por refutador.
  local g _gate_ok=1
  for g in "3:1" "1:1" "0:0" "-1:0" ":0" "lixo:0"; do
    local _in="${g%%:*}" _want="${g##*:}" _got=0
    bash "$0" --gate "${_in}" 99 >/dev/null 2>&1 || _got=$?
    [ "${_got}" = "${_want}" ] \
      || { printf '  ✗ review-verdict: (GATE) achados=%s deu rc=%s, esperado %s\n' "${_in:-vazio}" "${_got}" "${_want}"; rc=1; _gate_ok=0; }
  done
  [ "${_gate_ok}" = "1" ] \
    && printf '  ✓ review-verdict: (GATE) 6 entradas — >=1 bloqueia; 0, -1, vazio e lixo NAO bloqueiam\n'

  # (MUT) A PROPRIEDADE DE SEGURANCA E "`-1` NAO BLOQUEIA" — entao o mutante tem de fazer `-1`
  # BLOQUEAR, e o caso so vale se o rc MUDAR. A 1a versao mutava apenas a MENSAGEM (⚠️ virava ✅):
  # rc=0 no original E no mutante, e a etiqueta dizia "load-bearing" sobre algo que nao mudava
  # comportamento nenhum. Vacuo como rotulado — achado por refutador, nao por leitura minha.
  local mut6; mut6="$(mktemp -d)"; cp "$0" "${mut6}/m.sh"
  sed -i 's/^  if \[ "${n}" -ge 1 \] 2>\/dev\/null; then$/  if [ "${n}" -ge 1 ] 2>\/dev\/null || [ "${n}" = "-1" ]; then/' "${mut6}/m.sh"
  if ! cmp -s "$0" "${mut6}/m.sh"; then
    local _mrc=0; bash "${mut6}/m.sh" --gate -1 99 >/dev/null 2>&1 || _mrc=$?
    [ "${_mrc}" = "1" ] \
      && printf '  ✓ review-verdict: (MUT) fazendo `-1` bloquear, o rc MUDA (0→1) — "nao sei nao bloqueia" e load-bearing\n' \
      || { printf '  ✗ review-verdict: (MUT) mutante fez `-1` bloquear e o rc ficou %s — o caso nao prova a propriedade\n' "${_mrc}"; rc=1; }
  else printf '  ✗ review-verdict: (MUT) mutacao do ramo -1 NAO aplicada — o teste nao prova nada\n'; rc=1; fi
  rm -rf "${mut6}"

  rm -rf "${d}"
  return "${rc}"
}

# ── MODO --texto: imprime SO o texto do revisor ───────────────────────────────────────────────
# Existe porque a revisao custa ~US$1,27 por PR e ate 2026-08-07 nao era legivel em lugar nenhum:
# nem no PR (sem github_token a action nao postava), nem no log (a action nao ecoa), nem no
# GITHUB_OUTPUT (o verdict le 4 campos e descarta o resto). Pagava-se por trabalho invisivel.
# Custo desta captura: ZERO — o texto ja esta no arquivo. E funciona MESMO SE o posting falhar,
# que e por isso que ela nao e redundante com o `github_token` ligado no mesmo commit.
# O parsing fica AQUI e nao no YAML de proposito: um 2o parser do execution_file seria a divida
# que kg-view.sh ja escreveu em letra grande ("DOIS PARSERS, DUAS VERDADES").
# ── MODO --gate: a DECISAO de bloquear, em script TESTAVEL ────────────────────────────────────
# POR QUE NAO NO YAML: o proprio `onion-review.yml` adverte que "o YAML nao tem selftest — foi
# assim que a maquina quebrada sobreviveu meses parecendo sa". Ligar um gate NOVO dentro dele
# repetiria exatamente o defeito que aquele comentario registra. Aqui a decisao tem bancada.
#
# Contrato: imprime o CORPO do resumo em stdout e decide pelo exit code.
#   exit 1 = bloqueia (achados >= 1)   ·   exit 0 = passa (0 achados, ou contagem indisponivel)
# `-1`/vazio/lixo NUNCA bloqueiam: "nao consegui contar" nao e "achei defeito", e a guarda diz
# isso em voz alta em vez de inventar veredito.
gate_findings() { # $1=achados  $2=numero do PR (opcional, so para a mensagem)
  local n="${1:--1}" pr="${2:-<pr>}"
  case "${n}" in ''|*[!0-9-]*|-*[!0-9]*) n=-1 ;; esac
  [ "${n}" = "-" ] && n=-1
  if [ "${n}" -ge 1 ] 2>/dev/null; then
    printf '## ❌ O revisor apontou %s violação(ões)\n\n' "${n}"
    printf 'O parecer está no comentário do PR, com `arquivo:linha — regra — evidência`.\n\n'
    printf '**Corrija, ou dispense de forma registrada:**\n\n'
    printf '```\nops/pr-merge-verified.sh %s --dispensa onion-review-verdict --motivo "<por quê o achado não procede>"\n```\n\n' "${pr}"
    printf 'Até 2026-09-20 este parecer era advisory. Medimos o custo: em 33 pareceres, 10 acharam\n'
    printf 'violação real e três delas ainda estavam em `main` depois — apontadas, mergeadas, esquecidas.\n'
    return 1
  fi
  if [ "${n}" = "0" ]; then
    printf '✅ revisão semântica CONFIRMADA neste PR — veredito CONFORME (0 achados).\n'
    return 0
  fi
  printf '⚠️ **Revisado, achados NÃO contabilizáveis**\n\n'
  printf 'A linha `VEREDITO:` não veio na forma contratada (achados=%s). Leia o parecer no\n' "${n}"
  printf 'comentário do PR — este check não bloqueia sobre o que não conseguiu medir.\n'
  return 0
}

reviewer_text() { # $1=execution_file
  local f="${1:-}"
  [ -n "${f}" ] && [ -f "${f}" ] || { printf '_(sem execution_file — o revisor nao chegou a produzir saida)_\n'; return 0; }
  command -v jq >/dev/null 2>&1 || { printf '_(jq ausente — texto nao extraivel)_\n'; return 0; }
  local t
  t="$(jq -r 'if type == "array" then . else [.] end
              | map(select(.type? == "result")) | last // empty | .result // empty' "${f}" 2>/dev/null || true)"
  if [ -n "${t}" ]; then printf '%s\n' "${t}"; return 0; fi

  # SEM `.result` — e isto NAO e mistério: `SDKResultError` simplesmente NAO TEM esse campo
  # (sdk.d.ts:4269-4288). Ele tem `errors: string[]`. A versao anterior desta funcao dizia "a chave
  # pode ser outra neste pin", o que era FALSO no modo de falha MAIS PROVAVEL deste repo
  # (`error_max_turns` — o incidente de 2026-08-03 que motivou o --max-turns 60) e mentia na
  # direcao pior: mandava cacar mudanca de schema quando o diagnostico estava no arquivo, de graca.
  local errs
  errs="$(jq -r 'if type == "array" then . else [.] end
                 | map(select(.type? == "result")) | last // empty
                 | (.errors // []) | join("\n")' "${f}" 2>/dev/null || true)"
  if [ -n "${errs}" ]; then
    printf '_(o run NAO produziu parecer — terminou em erro. O que o SDK reportou:)_\n\n'
    printf '%s\n' "${errs}"
    return 0
  fi

  # Nem `.result` nem `errors[]`. Ultimo recurso: o texto parcial das entradas `assistant`, que e
  # onde o parecer sobrevive quando o run morre no meio.
  local parcial
  parcial="$(jq -r 'if type == "array" then . else [.] end
                    | map(select(.type? == "assistant"))
                    | map(.message.content // [] | map(select(.type? == "text") | .text) | join(""))
                    | join("\n") // empty' "${f}" 2>/dev/null || true)"
  if [ -n "${parcial}" ]; then
    printf '_(sem parecer final; abaixo o texto PARCIAL das mensagens do revisor)_\n\n'
    printf '%s\n' "${parcial}"
    return 0
  fi
  printf '_(o execution_file nao trouxe nem `.result`, nem `errors[]`, nem texto de `assistant` — o revisor nao chegou a falar)_\n'
}

# ── MODO --corpo: renderiza o COMENTARIO a partir do structured_output ────────────────────────
# O revisor DEVOLVE dado; quem posta e o Onion (post-review-comment.sh). Esta funcao e a ponte.
#
# POR QUE O RENDER MORA AQUI, e nao no bloco `run:` do YAML: `review-verdict.sh:298` ja escreveu a
# razao — "um 2o parser do execution_file seria a divida que kg-view.sh escreveu em letra grande
# (DOIS PARSERS, DUAS VERDADES)". O YAML chama; o parsing e sempre deste lado.
#
# ⚠️ O RAMO ESTRUTURADO ESTA INALCANCAVEL HOJE, e digo isso em vez de esconder: o `--json-schema`
# foi tentado e REVERTIDO neste mesmo PR — o parser da action passa `claude_args` por `shell-quote`,
# que come as aspas do JSON (medido: 371 bytes entram, 253 saem, JSON.parse falha). Sem ele,
# `structured_output` chega SEMPRE empty e o corpo cai SEMPRE na prosa. O ramo fica porque e o
# estado-alvo e esta coberto por 5 selftests; o gatilho para reativa-lo e passar o schema por
# ARQUIVO, que o input da action nao aceita neste pin.
#
# O FALLBACK, que hoje e o caminho unico: o parecer em PROSA, lido do execution_file. Ele sobrevive
# ate quando o run FALHA — verificado em /tmp/cca/src/entrypoints/run.ts:311
# (`executionFile ??= setExecutionFileOutputIfPresent()` no catch). NOTA DE CITACAO: a 1a versao
# citava `base-action/src/index.ts:72-73`, que NAO e o entrypoint — ele e guardado por
# `if (import.meta.main)` (index.ts:84) e a action roda `src/entrypoints/run.ts` (action.yml:276).
# Conclusao certa, fonte errada; e fonte errada num comentario e o que faz a proxima sessao
# re-medir ou, pior, confiar.
comment_body() { # $1=marca $2=structured_output(json, pode ser vazio) $3=execution_file
  local marca="${1:-}" so="${2:-}" f="${3:-}"
  printf '%s\n\n' "${marca}"
  printf '## 🧅 Revisão Onion\n\n'

  if [ -n "${so}" ] && command -v jq >/dev/null 2>&1 \
     && printf '%s' "${so}" | jq -e '(.achados | type) == "array"' >/dev/null 2>&1; then
    local ver n
    ver="$(printf '%s' "${so}" | jq -r '.veredito // "?"')"
    n="$(printf '%s' "${so}" | jq -r '(.achados // []) | length')"
    if [ "${n}" -eq 0 ]; then
      printf '**VEREDITO: conforme** — nenhum achado.\n\n'
    else
      printf '**VEREDITO: %s** — %s achado(s).\n\n' "${ver}" "${n}"
      printf '| arquivo:linha | regra | evidência |\n|---|---|---|\n'
      # ESCAPE DE CELULA — sem isto o conteudo QUEBRA a tabela, e o conteudo vem de um LLM lendo
      # diffs de shell. Medido 2026-08-07: `evidencia` com um `|` produziu 5 celulas contra
      # cabecalho de 3; com `\n`, a tabela TERMINA no meio. rc=0 e sem aviso nos dois casos.
      # `|` vira `\|` (escape de pipe em tabela markdown) e quebra de linha vira espaco.
      printf '%s' "${so}" | jq -r '
        def cel: tostring | gsub("\\|"; "\\|") | gsub("\n|\r"; " ");
        (.achados // [])[]
        | "| `\(.arquivo|cel)\(if .linha then ":" + (.linha|tostring) else "" end)` | \(.regra|cel) | \(.evidencia|cel) |"'
      printf '\n'
    fi
  else
    # Sem schema: o parecer em PROSA. Hoje este e o caminho UNICO (o `--json-schema` nao passa
    # neste pin — ver o bloco acima), entao a frase NAO pode sugerir falha do revisor: ele nunca
    # foi pedido a devolver estruturado. Dizer "nao devolveu" seria acusar quem obedeceu.
    printf '_(parecer em prosa — o formato que este pin da action entrega)_\n\n'
    reviewer_text "${f}"
    printf '\n'
  fi

  printf -- '---\n'
  # ⚠️ ESTE RODAPE DIZIA "advisory: nao bloqueia merge" — e virou MENTIRA em 2026-09-20, quando o
  # parecer passou a bloquear. Declaracao contradizendo comportamento no artefato MAIS VISIVEL da
  # mudanca: e o que o humano le em cada PR. Achado pela passada adversarial.
  printf '<sub>Esta revisão **bloqueia o merge** quando aponta violação. Falso-positivo se resolve com dispensa registrada (`--dispensa onion-review-verdict --motivo …`), nunca em silêncio. O gate determinístico é o `onion-validate`.</sub>\n'
}

case "${1:-}" in
  --selftest) run_selftest ;;
  --corpo)    comment_body "${2:-}" "${3:-}" "${4:-}" ;;
  --texto)    reviewer_text "${2:-}" ;;
  --gate)     gate_findings "${2:-}" "${3:-}" ;;
  -h|--help)  sed -n '2,40p' "$0"; exit 0 ;;
  *)          verdict "${1:-}" ;;
esac
