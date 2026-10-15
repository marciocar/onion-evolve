#!/usr/bin/env bash
# =============================================================================
# background-task-probe.sh — hook UserPromptSubmit: MEDE cada tarefa de fundo viva
# desta sessão e INJETA o estado como additionalContext. Nunca veta.
#
# POR QUÊ (decisão do maestro de 2026-10-14, nó D_VETO_DE_PROSA_APOSENTADO_PELA_SONDA em
#   docs/evolution/research/guard-forge-2026-10/guard-forge-2026-10.kg.yaml): esta sonda SUBSTITUI o
#   hook Stop `background-state-needs-evidence.sh`, que vetava a PROSA ("está rodando" sem `ps` no
#   turno). Medido em 1.191 paradas reais: 17 de 20 vetos caíram sobre afirmação CERTA e nenhum pegou
#   o defeito de origem — um `git commit -F -` travado 31 min em 2026-10-02, esperando stdin, dado
#   como "rodando (saída vazia)". O que separa travado de progredindo não é a frase: é tempo, CPU e
#   saída parada. Então em vez de julgar o que eu ESCREVO, a casa mede o processo e me entrega o dado
#   antes de eu escrever.
#
# COMO (tudo derivado do payload, nenhum caminho de máquina):
#   1. `transcript_path` do stdin → as tarefas LANÇADAS nesta sessão são as linhas do harness
#      "Output is being written to: <dir>/tasks/<id>.output" cujo <id> aparece no campo harness-only
#      `"backgroundTaskId":"<id>"` (citação em saída de ferramenta não conta). O diretório de tarefas é o `tasks/` cujo
#      pai tem o nome da sessão (basename do transcript); sem nenhum, o do ÚLTIMO lançamento.
#   2. tarefa com `<task-notification>` de término (status completed|failed|killed|stopped) para o
#      MESMO <output-file>, ou parada por TaskStop, sai da conta. Agente (o .output é symlink para o
#      jsonl do subagente) também.
#   3. as restantes: UM `find /proc/[0-9]*/fd -lname '<dir>/*.output'` acha quem escreve cada arquivo
#      (o processo herda o stdout que o harness redirecionou). O PID mostrado é o MAIS NOVO entre os
#      escritores (a folha: o wrapper `bash` fica em do_wait, quem trava é o filho).
#   4. uma linha por tarefa: id, PID, etime, CPU (fração da vida da folha), minutos desde a última
#      escrita no .output, estado/wchan. SUSPEITO = saída parada há ≥ STALE_MIN min E NENHUM tique de CPU
#      (soma de todos os escritores) desde a medição anterior, feita há ≥ MIN_GAP_S. A sonda guarda
#      `id pid_folha cpu epoch` por tarefa num arquivo da sessão (STATE_DIR) e só o reescreve quando a CPU
#      ou a folha mudam: o epoch guardado é "a última vez que vi progresso". Nenhum NOME de kernel decide
#      (decisão do maestro de 2026-10-15): a 1ª versão exigia o wchan numa lista de leitura, e o 1º CI do
#      #1129 mostrou que o nome muda com o kernel (`pipe_read` aqui, `anon_pipe_read` no runner) — a mesma
#      classe do veto de prosa aposentado, lista fechada de vocabulário. O wchan fica só como informação.
#      Sem medição anterior a linha diz "progresso ainda não medido", nunca SUSPEITO. Tarefa sem processo e sem
#      notificação vira "sem processo nem notificação" — mas só se o varrimento de /proc MEDIU: find
#      que estoura o teto ou não existe vira "NÃO MEDIDO", nunca "sem processo".
#
# TETO DECLARADO (o que ela NÃO vê):
#   · SUBAGENTE — tarefa de fundo lançada por um subagente vive no transcript DELE; aqui só entra o que
#     este transcript lançou. E o próprio agente de fundo (symlink) não é medido.
#   · PROCESSO QUE REDIRECIONA A PRÓPRIA SAÍDA (`cmd > outro.log` dentro da tarefa) não segura o fd do
#     .output: o escritor medido vira o wrapper, cuja CPU não anda enquanto o filho trabalha → pode marcar
#     SUSPEITO uma tarefa que progride. Por isso SUSPEITO não é veredito, e a sonda nunca veta.
#   · ESPERA LEGÍTIMA (`sleep`, rede lenta) também não gasta CPU: SUSPEITO diz "sem progresso medido",
#     não "travado". Quem lê confere o processo.
#   · O progresso só se mede ENTRE mensagens: duas mensagens a menos de MIN_GAP_S não comparam.
#   · processo de outro usuário (fd ilegível) conta como "sem processo".
# TEMPO: medido em 2026-10-14 nesta casa (transcript de 46 MB, ~840 processos): ver o resíduo da
#   branch feat/background-probe-replaces-prose-veto. O `find` tem teto de FIND_TIMEOUT; a sonda inteira
#   fica bem abaixo de 1 s, e o registro em settings.json tem timeout 5.
# CONTRATO: sempre exit 0 · silenciosa quando não há tarefa sem término · nunca lê .env · LC_ALL=C.
# Bancada: run_background_task_probe_selftests em .claude/validation/lint-selftest.sh.
# =============================================================================
set -uo pipefail
export LC_ALL=C

STALE_MIN=10          # minutos sem escrita no .output para contar como saída PARADA
MIN_GAP_S=60          # janela mínima entre duas medições para "CPU não andou" valer
FIND_TIMEOUT=0.5      # teto do varrimento de /proc (s)
STATE_DIR="${BG_PROBE_STATE_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/onion-bg-probe-$(id -u)}"

input="$(cat 2>/dev/null)" || input=""
if command -v jq >/dev/null 2>&1; then
  tp="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)"
else
  tp="$(printf '%s' "$input" | grep -o '"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')"
fi
[ -n "${tp:-}" ] && [ -f "$tp" ] || exit 0

sid="$(basename "$tp" .jsonl)"
# LANÇAMENTO só conta com o campo que SÓ o harness escreve: `"backgroundTaskId":"<id>"` no toolUseResult.
# A linha "Output is being written to:" sozinha não basta — medido no 2º dogfood (2026-10-14): uma
# saída de ferramenta que IMPRIMIA linhas de lançamento de outro transcript (um grep meu) virou duas
# tarefas fantasmas "sem processo nem notificação". Citada em conteúdo, a chave sai escapada
# (`\"backgroundTaskId\":\"…`) e não casa.
launched="$(awk 'NR==FNR {id[$0]=1; next} { q=$0; sub(/^.*\//, "", q); sub(/\.output$/, "", q); if ((q in id) && !s[$0]++) print }' \
  <(grep -o '"backgroundTaskId":"[A-Za-z0-9_-]*"' "$tp" 2>/dev/null | sed 's/^"backgroundTaskId":"//; s/"$//') \
  <(grep -o 'Output is being written to: [^ "\\]*/tasks/[A-Za-z0-9_-]*\.output' "$tp" 2>/dev/null | sed 's/^Output is being written to: //'))"
[ -n "$launched" ] || exit 0

tdir=""
while IFS= read -r p; do
  d="${p%/*}"; parent="${d%/tasks}"; parent="${parent##*/}"
  [ "$parent" = "$sid" ] && { tdir="$d"; break; }
done <<< "$launched"
[ -n "$tdir" ] || { last="$(tail -n 1 <<< "$launched")"; tdir="${last%/*}"; }

# término = notificação do harness para o MESMO <output-file>, ou o TaskStop ("Successfully stopped
# task: <id>" — o harness NÃO notifica tarefa parada à mão; medido no 1º dogfood, 2026-10-14: as duas
# únicas "sem processo nem notificação" da sessão real eram TaskStop). Diferença de conjuntos em awk:
# o `while read` sobre ~1.400 notificações custava ~250 ms em bash.
pending=()
while IFS= read -r p; do
  [ -L "$p" ] && continue
  [ -f "$p" ] && pending+=("$p")
done < <({
  grep -oE '<output-file>[^<]*</output-file>[^<]*<status>(completed|failed|killed|stopped)</status>' "$tp" 2>/dev/null \
    | sed 's/^<output-file>//; s/<\/output-file>.*//'
  grep -oE 'Successfully stopped task: [A-Za-z0-9_-]+' "$tp" 2>/dev/null \
    | sed "s|^Successfully stopped task: |${tdir}/|; s|\$|.output|"
} | awk -v d="$tdir" 'NR==FNR {done[$0]=1; next} { q=$0; sub(/\/[^\/]*$/, "", q); if (q==d && !($0 in done)) print }' - <(printf '%s\n' "$launched"))
[ "${#pending[@]}" -gt 0 ] || exit 0

# última medição com progresso, por tarefa: id → "pid cpu epoch"
declare -A prev=() next=()
sfile="${STATE_DIR}/${sid}.tsv"
if [ -f "$sfile" ]; then
  while IFS=$'\t' read -r k v; do [ -n "$k" ] && prev["$k"]="$v"; done < "$sfile" 2>/dev/null
fi

# quem escreve o quê: /proc/<pid>/fd/<n> → <dir>/<id>.output
# rc do find: 1 é o normal aqui (processo que some no meio, fd de outro usuário); 124 (estourou o teto)
# e 126/127 (sem `timeout`/`find`) NÃO são "ninguém escreve" — viram NÃO MEDIDO, nunca "sem processo".
# (2º dogfood, 2026-10-14: com o `find` fora do PATH a sonda afirmou "sem processo" de tarefa viva.)
declare -A writers=()
fdmap="$(timeout "$FIND_TIMEOUT" find /proc/[0-9]*/fd -maxdepth 1 -lname "${tdir}/*.output" -printf '%h\t%l\n' 2>/dev/null)"
frc=$?
unmeasured=""
case "$frc" in 0|1) ;; *) unmeasured="varrimento de /proc NÃO MEDIDO (rc=${frc}: teto de ${FIND_TIMEOUT}s estourado ou find/timeout ausente)" ;; esac
while IFS=$'\t' read -r fdd tgt; do
  [ -n "$tgt" ] || continue
  pid="${fdd#/proc/}"; pid="${pid%/fd}"
  case " ${writers[$tgt]:-} " in *" $pid "*) ;; *) writers["$tgt"]="${writers[$tgt]:-}${writers[$tgt]:+ }$pid" ;; esac
done <<< "$fdmap"

hz="$(getconf CLK_TCK 2>/dev/null)"; [ -n "$hz" ] || hz=100
read -r up _ < /proc/uptime; up="${up%%.*}"
printf -v now '%(%s)T' -1

_dur() {   # segundos → 1h02m / 3m05s / 42s
  local s="$1"
  if [ "$s" -ge 3600 ]; then printf '%dh%02dm' $((s/3600)) $((s%3600/60))
  elif [ "$s" -ge 60 ]; then printf '%dm%02ds' $((s/60)) $((s%60))
  else printf '%ds' "$s"; fi
}

lines=() nsusp=0
for p in "${pending[@]}"; do
  id="${p##*/}"; id="${id%.output}"
  mt="$(stat -c %Y "$p" 2>/dev/null)" || mt="$now"
  idle=$(( (now - mt) / 60 )); [ "$idle" -ge 0 ] || idle=0
  ws="${writers[$p]:-}"
  if [ -z "$ws" ] && [ -n "$unmeasured" ]; then
    lines+=("· tarefa ${id}: ${unmeasured} — saída parada há ${idle} min; o estado do processo é DESCONHECIDO")
    continue
  fi
  if [ -z "$ws" ]; then
    lines+=("· tarefa ${id}: sem processo nem notificação — saída parada há ${idle} min (morreu sem aviso, ou o processo é de outro usuário)")
    continue
  fi
  leaf="" leaf_st=-1 oldest_st="" n=0 cpu_all=0
  for w in $ws; do
    { s="$(< "/proc/$w/stat")"; } 2>/dev/null || continue
    r="${s##*) }"; read -r -a f <<< "$r"
    st="${f[19]:-0}"; n=$((n+1)); cpu_all=$(( cpu_all + f[11] + f[12] ))
    # empate no tique de início (wrapper e filho nascem no mesmo jiffy — medido no dogfood de 2026-10-15,
    # bash e sleep com o mesmo starttime): desempata pelo PID maior, o filho
    if [ "$st" -gt "$leaf_st" ] || { [ "$st" -eq "$leaf_st" ] && [ "$w" -gt "$leaf" ]; }; then
      leaf="$w"; leaf_st="$st"; lf=("${f[@]}")
    fi
    { [ -z "$oldest_st" ] || [ "$st" -lt "$oldest_st" ]; } && oldest_st="$st"
  done
  if [ -z "$leaf" ]; then
    lines+=("· tarefa ${id}: sem processo nem notificação — saída parada há ${idle} min (o escritor saiu durante a medição)")
    continue
  fi
  state="${lf[0]}"; cpu_t=$(( lf[11] + lf[12] ))
  { wchan="$(< "/proc/$leaf/wchan")"; } 2>/dev/null; [ -n "$wchan" ] && [ "$wchan" != "0" ] || wchan="-"
  { comm="$(< "/proc/$leaf/comm")"; } 2>/dev/null
  run_s=$(( up - oldest_st / hz )); [ "$run_s" -ge 0 ] || run_s=0
  leaf_s=$(( up - leaf_st / hz )); [ "$leaf_s" -ge 1 ] || leaf_s=1
  pct_x10=$(( cpu_t * 1000 / (leaf_s * hz) ))
  line="· tarefa ${id}: PID ${leaf} (${comm:-?}; ${n} processo(s) escrevendo) · rodando há $(_dur "$run_s") · CPU $((pct_x10/10)).$((pct_x10%10))% · saída parada há ${idle} min · estado ${state}/${wchan}"
  # progresso = a folha mudou ou a CPU somada andou; só então o epoch guardado avança
  read -r ppid pcpu pt <<< "${prev[$id]:-}"
  if [ -z "${pt:-}" ] || [ "$ppid" != "$leaf" ] || [ "$pcpu" != "$cpu_all" ]; then
    next["$id"]="$leaf ${cpu_all} ${now}"
    if [ -z "${pt:-}" ]; then line="${line} · progresso ainda não medido (1ª medição)"
    else line="${line} · CPU andou desde a medição anterior"; fi
  else
    next["$id"]="${prev[$id]}"
    gap=$(( now - pt ))
    if [ "$gap" -lt "$MIN_GAP_S" ]; then
      line="${line} · CPU parada numa janela de ${gap}s (curta demais para julgar)"
    elif [ "$idle" -ge "$STALE_MIN" ]; then
      line="${line} · ⚠️ SUSPEITO: saída parada há ≥ ${STALE_MIN} min e nenhum tique de CPU há $(_dur "$gap") (travado, stdin preso ou esperando algo)"
      nsusp=$((nsusp+1))
    else
      line="${line} · CPU parada há $(_dur "$gap"), mas a saída andou há ${idle} min"
    fi
  fi
  lines+=("$line")
done

if [ "${#next[@]}" -gt 0 ] && mkdir -p -m 700 "$STATE_DIR" 2>/dev/null; then
  tmp="$(mktemp "${sfile}.XXXXXX" 2>/dev/null)" && {
    for k in "${!next[@]}"; do printf '%s\t%s\n' "$k" "${next[$k]}"; done > "$tmp" && mv -f "$tmp" "$sfile"
  } 2>/dev/null || rm -f "${tmp:-}" 2>/dev/null
fi

ctx="🔎 Sonda de fundo (Onion) — ${#lines[@]} tarefa(s) de fundo desta sessão sem notificação de término, MEDIDAS agora (não afirme estado além disto):"
for l in "${lines[@]}"; do ctx="${ctx}"$'\n'"${l}"; done
[ "$nsusp" -gt 0 ] && ctx="${ctx}"$'\n'"SUSPEITO não é veredito: confira (\`cat /proc/<PID>/fd/0\`, \`ps -o pid,stat,etime,time,wchan,args\`) antes de afirmar travado ou rodando."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg ctx "$ctx" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
else
  esc="$(printf '%s' "$ctx" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'BEGIN{ORS=""} NR>1{print "\\n"} {print}')"
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
