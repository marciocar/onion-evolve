#!/usr/bin/env bash
# session-beacon.sh — FAROL DE SESSÃO: sessões declaram presença/branch num repo.
#
# Motivação (incidente 2026-07-02, colisão W1×W2): uma sessão operando cross-repo (W1)
# fez checkout na working tree de um repo onde OUTRA sessão estava viva (W2) — "um
# escritor por repo" (I3) inclui SESSÕES, não só commits. O farol torna a presença
# detectável: antes de checkout/escrita em repo alheio, `check` revela quem está lá.
#
# Doutrina: o farol é SINAL, não trava (human-gated — o maestro decide; ADR work-models,
# adendo 2026-07-02). Beacons são estado de runtime: NUNCA commitados (ignorados via
# .git/info/exclude, local ao clone — não toca o .gitignore do repo).
#
# Uso:
#   session-beacon.sh up      <repo> <session_id> [hat]     # cria/refresca o farol
#   session-beacon.sh down    <repo> <session_id>           # apaga o farol
#   session-beacon.sh check   <repo> [--ignore <session_id>]# lista faróis; exit 1 se há FRESCO alheio
#   session-beacon.sh sweep   <repo>                        # remove faróis stale/órfãos
#   session-beacon.sh verdict <arquivo.beacon>              # live|orphan|declared|stale (SSOT do veredito)
#
# DECLARADO ≠ VERIFICADO (correção do maestro 2026-08-28, medida). Até aqui "viva" era
# só `refreshed_at` dentro do TTL — um CARIMBO que a própria sessão escreveu. Mas
# `refreshed_at` só avança no UserPromptSubmit, então toda sessão que nasce e some sem
# SessionEnd (crash, kill, conexão de Remote Control, resume abortado) lia como VIVA por
# até 8h. Medido no core: 2 faróis anunciados como VIVOS tinham `started_at == refreshed_at`
# (jamais receberam um prompt) e NENHUM processo correspondente — o aviso de colisão I3
# disparou contra fantasmas. Cura: medir o DONO (behavior-over-declaration), não o carimbo.
#
# Vereditos (o `check` os rotula; `verdict` os expõe como SSOT p/ outros leitores):
#   live     — dono registrado E ainda vivo (pid existe com o MESMO starttime). Bloqueia.
#   declared — sem dono registrado (harness sem /proc, beacon antigo, dono não identificável):
#              cai no frescor por TTL. Bloqueia — conservador por desenho, ver abaixo.
#   orphan   — dono registrado e MORTO. NÃO bloqueia; `sweep` remove.
#   stale    — sem dono e refreshed_at fora do TTL. NÃO bloqueia; `sweep` remove.
#
# Direção do erro (escolha deliberada): um falso "órfã" (diz morta, está viva) reabre
# exatamente o incidente W1×W2 que criou o farol; um falso "declarada" só custa uma
# verificação. Por isso o dono só é registrado quando IDENTIFICADO com confiança, e a
# ausência de prova cai no comportamento antigo, nunca em "pode escrever".
#
# Frescor: refreshed_at dentro de ONION_BEACON_TTL_MIN (default 480 min).
set -euo pipefail

CMD="${1:?uso: session-beacon.sh <up|down|check|sweep|verdict> <repo|beacon> ...}"
REPO="${2:?uso: session-beacon.sh <up|down|check|sweep|verdict> <repo|beacon> ...}"
TTL_MIN="${ONION_BEACON_TTL_MIN:-480}"
# Janela de GRAÇA do veredito `orphan`: mesmo com o dono medido morto, um heartbeat
# recente desmente a morte (a sessão pode ter trocado de processo). Ver beacon_verdict.
GRACE_MIN="${ONION_BEACON_ORPHAN_GRACE_MIN:-30}"
BEACON_DIR="$REPO/.claude/beacons"

ensure_exclude() {
  # ignore local ao clone (não commitável) — não clobba .gitignore de ninguém.
  # Usa o COMMON-dir (não o git-dir por-worktree): em worktree ligada o git lê o exclude do
  # common-dir, então escrever no per-worktree deixaria os beacons visíveis (?? no status).
  local git_dir
  git_dir="$(git -C "$REPO" rev-parse --git-common-dir 2>/dev/null)" \
    || git_dir="$(git -C "$REPO" rev-parse --git-dir 2>/dev/null)" || return 0
  case "$git_dir" in /*) ;; *) git_dir="$REPO/$git_dir" ;; esac
  local excl="$git_dir/info/exclude"
  mkdir -p "$(dirname "$excl")"
  grep -qx '.claude/beacons/' "$excl" 2>/dev/null || echo '.claude/beacons/' >> "$excl"
}

# árvore de trabalho canônica deste beacon (key-by-worktree): o toplevel realpath.
# Fallback gracioso p/ dir não-git. A coluna PRESENÇA do mapa da constelação lê isto.
worktree_of() {
  local wt
# GIT_DIR neutralizado: sob hook do git em worktree o GIT_DIR e ABSOLUTO, e com ele
# setado `git -C <subdir> rev-parse --show-toplevel` devolve o SUBDIR, nao a raiz —
# o script passa a procurar tudo no lugar errado e emite vazio (medido 2026-08-04).
  wt="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "$REPO" rev-parse --show-toplevel 2>/dev/null)" || wt="$REPO"
  realpath "$wt" 2>/dev/null || echo "$wt"
}

now_epoch() { date +%s; }

# Ledger de CICLO-DE-VIDA (tracked) — só timestamps de sessão, NUNCA conteúdo.
# O conteúdo de sessão (.claude/sessions/) segue LOCAL por desenho; aqui vira
# durável apenas o que o sinal de VELOCIDADE precisa: session_id + branch +
# started_at/ended_at/duração. Apendado em `down` (fim limpo) e `sweep` (a sessão
# morreu sem cleanup — ended_at = último refresh). merge=union no .gitattributes
# evita conflito entre sessões concorrentes.
# ── DONO DO FAROL (a metade VERIFICÁVEL) ────────────────────────────────────
# starttime do processo (campo 22 de /proc/<pid>/stat), a defesa contra REUSO DE PID:
# pid sozinho volta a mentir quando o kernel recicla o número. O `comm` do stat pode
# conter espaços e parênteses, então corta-se tudo até o ÚLTIMO ')' e conta-se dali
# (campos 3..N viram 1..N-2, logo o 22 vira o 20).
proc_starttime() { # $1 = pid → starttime em jiffies, ou vazio
  local pid="$1"
  case "$pid" in ''|*[!0-9]*) return 0 ;; esac
  [ -r "/proc/$pid/stat" ] || return 0
  sed 's/.*) //' "/proc/$pid/stat" 2>/dev/null | awk '{print $20}' 2>/dev/null || true
}

# /proc é legível AQUI? Sem isto, `proc_starttime` vazio colapsa três coisas diferentes:
# (a) /proc não montado, (b) o processo não existe, (c) stat ilegível. Só (b) é PROVA DE
# MORTE; (a) e (c) são AUSÊNCIA DE PROVA — e ausência de prova nunca pode virar `orphan`.
proc_available() { [ -r /proc/self/stat ]; }

# Sobe a árvore de processos procurando o DONO real da sessão (o processo `claude`).
# Por que subir: o hook roda dentro de um bash filho, cujo pid morre em segundos — gravá-lo
# como dono produziria "órfã" instantânea, o erro na direção PERIGOSA (diz morta, está viva).
# Não achou claude em até 6 saltos → devolve vazio, e o beacon fica `declared` (conservador).
owner_probe() { # $1 = pid inicial → "pid starttime", ou vazio
  local pid="${1:-}" hops=0 comm argv0 st
  while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null && [ "$hops" -lt 6 ]; do
    # IDENTIDADE do executável, NUNCA substring do cmdline. Medido no dogfood
    # 2026-08-28: casar `*claude*` no cmdline elegia o SHELL TRANSITÓRIO do próprio
    # hook como dono — o cmdline dele carrega `/home/<user>/.claude/shell-snapshots/…`,
    # que contém "claude". Esse shell morre em segundos e o farol viraria `orphan` com
    # a sessão VIVA: exatamente o erro na direção perigosa que este desenho proíbe.
    comm="$(cat "/proc/$pid/comm" 2>/dev/null || true)"
    argv0="$(tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null | head -1 || true)"
    if [ "$comm" = "claude" ] || [ "${argv0##*/}" = "claude" ]; then
      st="$(proc_starttime "$pid")"
      [ -n "$st" ] && { printf '%s %s' "$pid" "$st"; return 0; }
    fi
    # ppid = campo 4 do stat → campo 2 depois do corte do comm
    pid="$(sed 's/.*) //' "/proc/$pid/stat" 2>/dev/null | awk '{print $2}' 2>/dev/null || true)"
    case "$pid" in ''|*[!0-9]*) return 0 ;; esac
    hops=$((hops + 1))
  done
  return 0
}

# Veredito de UM beacon — a SSOT que `check`, `sweep` e leitores externos (mapa da
# constelação) consomem, para que a regra de "vivo" exista num lugar só.
beacon_verdict() { # $1 = arquivo .beacon → live|orphan|declared|stale
  local B="$1" opid ost ref age now
  [ -f "$B" ] || { echo stale; return 0; }
  opid="$(awk -F': ' '/^owner_pid:/{print $2; exit}' "$B" 2>/dev/null || true)"
  ost="$(awk -F': ' '/^owner_start:/{print $2; exit}' "$B" 2>/dev/null || true)"
  bhost="$(awk -F': ' '/^host:/{print $2; exit}' "$B" 2>/dev/null || true)"
  now="$(now_epoch)"
  ref="$(awk -F': ' '/^refreshed_at:/{print $2; exit}' "$B" 2>/dev/null || true)"
  case "${ref:-}" in ''|*[!0-9]*) ref=0 ;; esac   # carimbo corrompido não derruba o script (set -u)
  age=$(( (now - ref) / 60 ))

  if [ -n "$opid" ] && [ -n "$ost" ]; then
    if [ "$(proc_starttime "$opid")" = "$ost" ]; then echo live; return 0; fi
    # ── O DONO NÃO FOI ENCONTRADO. Isso AINDA NÃO É PROVA DE MORTE DA SESSÃO. ──
    # Achado da revisão adversarial (2026-08-28): o curto-circuito por dono, sozinho,
    # REABRIA o incidente W1×W2 — uma sessão que bateu heartbeat HÁ SEGUNDOS saía
    # `orphan`, `check` devolvia 0 e outra sessão era autorizada a escrever por cima.
    # Três coisas produzem "dono não encontrado" sem a sessão ter morrido:
    #   (a) /proc indisponível/ilegível aqui (container, hidepid, macOS lendo beacon alheio);
    #   (b) o beacon veio de OUTRA máquina — o pid nem é deste kernel;
    #   (c) a sessão trocou de processo (resume/restart com o mesmo sid) e o refresh
    #       preservou o dono velho.
    # Contra (a) e (b): não há o que medir → `declared`. Contra (c): o HEARTBEAT desmente
    # a morte — quem digitou agora não está morto. Só depois da janela de graça o
    # veredito vira `orphan`. O poder de matar fantasma sobrevive quase inteiro
    # (8h → 30min), e passa a ser IMPOSSÍVEL declarar morta uma sessão que acabou de agir.
    proc_available || { echo declared; return 0; }
    if [ -n "$bhost" ] && [ "$bhost" != "$(hostname 2>/dev/null || echo unknown)" ]; then
      echo declared; return 0
    fi
    if [ "$age" -le "$GRACE_MIN" ]; then echo declared; return 0; fi
    echo orphan; return 0
  fi

  # Sem dono registrado: só resta o carimbo — declarado, não verificado.
  if [ "$age" -le "$TTL_MIN" ]; then echo declared; else echo stale; fi
}

LEDGER="$REPO/.claude/session-lifecycle.jsonl"
ledger_append() { # $1 = arquivo .beacon · $2 = ended_at (epoch)
  local B="$1" ended="$2" sid br started dur
  # CI não é sessão de trabalho: registrar aqui SUJA a árvore do runner (arquivo TRACKED —
  # falso-positivo em 100% das runs da guarda dirty-tree do onion-review) e polui o sinal de
  # velocidade com sessões de minutos em branch "unknown". Medido 2026-08-13 (Elenxo #590).
  [ -z "${GITHUB_ACTIONS:-}" ] || return 0
  [ -f "$B" ] || return 0
  [ -f "$LEDGER" ] || return 0   # só apenda se o ledger existe (opt-in por trackear o arquivo)
  sid="$(awk -F': ' '/^session_id:/{print $2; exit}' "$B" 2>/dev/null || true)"
  br="$(awk -F': ' '/^branch:/{print $2; exit}' "$B" 2>/dev/null || true)"
  started="$(awk -F': ' '/^started_at:/{print $2; exit}' "$B" 2>/dev/null || true)"
  [ -n "$sid" ] && [ -n "$started" ] || return 0
  case "$started$ended" in *[!0-9]*) return 0 ;; esac  # ambos numéricos, ou aborta
  dur=$(( ended - started )); [ "$dur" -lt 0 ] && dur=0
  printf '{"session_id":"%s","branch":"%s","started_at":%s,"ended_at":%s,"duration_s":%s}\n' \
    "$sid" "${br:-unknown}" "$started" "$ended" "$dur" >> "$LEDGER" 2>/dev/null || true
}

case "$CMD" in
  up)
    SID="${3:?uso: session-beacon.sh up <repo> <session_id> [hat]}"
    HAT="${4:-}"
    mkdir -p "$BEACON_DIR"; ensure_exclude
    B="$BEACON_DIR/$SID.beacon"
    STARTED="$(awk -F': ' '/^started_at:/{print $2; exit}' "$B" 2>/dev/null || true)"
    [ -n "$STARTED" ] || STARTED="$(now_epoch)"
    # Preservar a intenção declarada (hat) através de refreshes sem-arg: o hook 'refresh'
    # (UserPromptSubmit) chama 'up' SEM hat — não o conhece. Sem isto, cada prompt apagaria
    # o hat declarado de volta para '—'. Espelha a preservação de started_at acima. Um hat
    # explícito (arg não-vazio) sempre vence — declarar de novo re-escreve a intenção.
    if [ -z "$HAT" ]; then
      HAT="$(awk -F': ' '/^hat:/{print $2; exit}' "$B" 2>/dev/null || true)"
      [ "$HAT" = "—" ] && HAT=""
    fi
    # DONO: quem sustenta esta sessão. O chamador informa o pid de partida
    # (ONION_BEACON_OWNER_PID; o hook passa o seu $PPID) e a sonda SOBE até achar o
    # processo `claude`. Preservado entre refreshes como started_at/hat: se a sonda
    # falhar num refresh, o dono já medido NÃO é perdido (perdê-lo degradaria um
    # veredito verificado de volta para declarado).
    OWNER="$(owner_probe "${ONION_BEACON_OWNER_PID:-$PPID}")"
    OWNER_PID="${OWNER%% *}"; OWNER_START="${OWNER##* }"
    if [ -z "$OWNER" ]; then
      OWNER_PID="$(awk -F': ' '/^owner_pid:/{print $2; exit}' "$B" 2>/dev/null || true)"
      OWNER_START="$(awk -F': ' '/^owner_start:/{print $2; exit}' "$B" 2>/dev/null || true)"
    fi
    {
      echo "session_id: $SID"
      echo "branch: $(git -C "$REPO" branch --show-current 2>/dev/null || echo unknown)"
      echo "worktree: $(worktree_of)"
      echo "hat: ${HAT:-—}"
      echo "host: $(hostname 2>/dev/null || echo unknown)"
      echo "started_at: $STARTED"
      echo "refreshed_at: $(now_epoch)"
      # if-block, NÃO um `a && b && { }`: sob `set -e` uma cadeia && falha como ÚLTIMA
      # instrução do grupo faz o `up` inteiro sair 1 — e sem dono elegível (todo CI, todo
      # host sem /proc) isso é o caso NORMAL, não o excepcional. Medido: exit 1 com o
      # beacon escrito corretamente. O hook mascarava com `|| true`; a bancada, não.
      if [ -n "${OWNER_PID:-}" ] && [ -n "${OWNER_START:-}" ]; then
        echo "owner_pid: $OWNER_PID"
        echo "owner_start: $OWNER_START"
      fi
    } > "$B"
    ;;
  down)
    SID="${3:?uso: session-beacon.sh down <repo> <session_id>}"
    ledger_append "$BEACON_DIR/$SID.beacon" "$(now_epoch)"   # fim limpo → carimba a duração
    rm -f "$BEACON_DIR/$SID.beacon"
    ;;
  check)
    IGNORE=""
    [ "${3:-}" = "--ignore" ] && IGNORE="${4:-}"
    FRESH=0
    if [ -d "$BEACON_DIR" ]; then
      NOW="$(now_epoch)"
      for B in "$BEACON_DIR"/*.beacon; do
        [ -f "$B" ] || continue
        SID="$(awk -F': ' '/^session_id:/{print $2; exit}' "$B")"
        [ -n "$IGNORE" ] && [ "$SID" = "$IGNORE" ] && continue
        REF="$(awk -F': ' '/^refreshed_at:/{print $2; exit}' "$B")"
        BR="$(awk -F': ' '/^branch:/{print $2; exit}' "$B")"
        HAT="$(awk -F': ' '/^hat:/{print $2; exit}' "$B")"
        STA="$(awk -F': ' '/^started_at:/{print $2; exit}' "$B")"
        # carimbo corrompido derrubava o script inteiro sob `set -u` — e com ele a
        # listagem toda, inclusive o beacon VIVO do mesmo diretório (achado adversarial)
        case "${REF:-}" in ''|*[!0-9]*) REF=0 ;; esac
        AGE_MIN=$(( (NOW - REF) / 60 ))
        # `started_at == refreshed_at` = a sessão NUNCA recebeu um UserPromptSubmit.
        # Presença sem escritor: ninguém digitou nada nela. Foi esta pista que revelou
        # os dois faróis-fantasma de 2026-08-28 — por isso ela vai impressa, não inferida.
        NEVER=""; [ -n "${STA:-}" ] && [ "$STA" = "${REF:-}" ] && NEVER=" ⚠️ ainda sem prompt"
        VERD="$(beacon_verdict "$B")"
        # Num veredito `live` a pista não vale como suspeita: TODA sessão recém-nascida
        # tem started_at == refreshed_at entre o SessionStart e o 1º prompt, e o texto do
        # hook ensina a ler a pista como "fantasma" — empurraria a descartar uma sessão
        # MEDIDA VIVA (achado da revisão adversarial 2026-08-28).
        [ "$VERD" = "live" ] && NEVER=""
        case "$VERD" in
          live)
            echo "🕯️ VIVA (dono verificado): $SID branch=$BR hat=$HAT age=${AGE_MIN}min"
            FRESH=$((FRESH + 1)) ;;
          declared)
            echo "🕯️ DECLARADA (dono NÃO verificado): $SID branch=$BR hat=$HAT age=${AGE_MIN}min${NEVER}"
            FRESH=$((FRESH + 1)) ;;
          orphan)
            echo "(órfã) $SID branch=$BR age=${AGE_MIN}min — dono MEDIDO morto; sweep remove${NEVER}" ;;
          *)
            echo "(stale) $SID branch=$BR age=${AGE_MIN}min — sweep remove" ;;
        esac
      done
    fi
    # exit 1 = há sessão viva alheia → NÃO opere na working tree sem falar com o maestro
    [ "$FRESH" -eq 0 ] || exit 1
    ;;
  sweep)
    if [ -d "$BEACON_DIR" ]; then
      NOW="$(now_epoch)"
      for B in "$BEACON_DIR"/*.beacon; do
        [ -f "$B" ] || continue
        REF="$(awk -F': ' '/^refreshed_at:/{print $2; exit}' "$B")"
        case "${REF:-}" in ''|*[!0-9]*) REF=0 ;; esac
        # Órfão sai JUNTO com o stale: o dono foi medido morto, não há o que esperar do TTL.
        # É o que impede o fantasma de bloquear o repo por 8h depois de a sessão sumir.
        case "$(beacon_verdict "$B")" in
          orphan|stale)
            ledger_append "$B" "${REF:-$NOW}"   # morreu sem cleanup → ended_at = último refresh
            rm -f "$B" ;;
        esac
      done
    fi
    ;;
  verdict)
    # SSOT do veredito p/ leitores externos (mapa da constelação). $2 é o ARQUIVO .beacon
    # aqui — não o repo — porque o leitor já o localizou na worktree que estava varrendo.
    beacon_verdict "$REPO"
    ;;
  *)
    echo "ERROR: subcomando desconhecido '$CMD' (up|down|check|sweep|verdict)" >&2
    exit 2
    ;;
esac
