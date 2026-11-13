#!/usr/bin/env bash
# PreToolUse(Bash) — o MOAT do /meta:drive vira veto POR ALVO (decisão D_MOAT_DEPLOY_E_RELOGIO_VIRAM_MECANISMO,
# selada pelo maestro em 2026-10-12 por /meta:decide: «Forjar na próxima leva»).
#
# ── O BURACO QUE FECHA (medido, não suposto) ─────────────────────────────────────────────────────────
# Dos quatro itens do MOAT (merge no main · deploy · escrever repo alheio · agendar por relógio) só o merge
# tinha veto (pretooluse-merge-gate.sh). Os outros três eram PROSA no drive.md. Em 2026-10-13 a sessão
# principal publicou o MCP onion-kg-writer com um script de scratchpad que fazia `sudo systemctl restart
# onion-vps-mcp-kg-writer` e `git -C <worktree-de-produção-do-writer> checkout --detach <sha>`: deploy fora
# de wrapper, sem backup, sem conferência, e nenhum aviso. É o gatilho (a) da decisão, observado.
#
# ── O QUE VETA (exit 2 = antes de executar) ─────────────────────────────────────────────────────────────
# Por ALVO, nunca por vocabulário (rsync/systemctl/git commit são legítimos fora de deploy). Os alvos são
# DADO versionado: ops/moat-targets.tsv (core-only) — unidades e caminhos servidos, cada um com o wrapper
# certo — e docs/evolution/federation/members.yaml (core-only), cujo `local_path` lista os clones alheios.
#  deploy  · systemctl/service/docker que muda unidade servida; escrita em caminho servido; escrita git
#            numa árvore servida — fora de um wrapper versionado do projeto.
#  alheio  · `git push` que muda o ramo de PRODUÇÃO, força ou apaga, num clone de membro registrado ou
#            num destino PROVADAMENTE de outro repositório. Branch de tópico e commit local passam: viram
#            PR lá (o /meta:adopt --update e o desenvolvimento do bridge fazem isso da sessão do core).
#  relogio · crontab que instala/edita; at/batch; systemd-run com timer; systemctl que liga .timer;
#            escrita em /etc/cron*, /var/spool/cron ou num .timer.
#  ato     · (2026-11-05, REGRA 117) invocar pela sessão um script de ops/ cujo uso É o deploy ou a publicação, com a
#            assinatura do ato nos argumentos (`--apply`, `--push`, `apply`, sem argumento…): as linhas `ato script` do
#            tsv. Medido: o wrapper versionado era fronteira para tudo, e `bash ops/<wrapper>.sh --apply` e (core-only)
#            `ops/publish-door.sh --push` passavam com exit 0. A cerca barrava a FORMA, não o ATO. Ensaio e leitura (core-only)
#            do mesmo script passam. `ops/pr-merge-verified.sh` no repo do core fica fora (é o caminho verificado de merge) (core-only);
#            com `--repo` de outro repositório (`@foreign`) é merge alheio.
#  delegado· (2026-11-13, selos D_DELEGATE_*_1113) o ato que o maestro delegou à sessão passa numa FORMA exata (linhas
#            `delega` do tsv): o merge alheio com --foreign-repo, o deploy do site com --verified-pr, o update do bridge
#            e a persona do Slack (install, start) pela cópia de root do sudoers. As condições que o hook não mede (CI
#            verde, conflito, resíduo, refutador independente) o próprio script confere e recusa. O push de porta não se
#            delega (D_DOOR_PUBLISH_STAYS_WITH_MAESTRO_1113), nem o creds da persona.
# O juiz mora em lib/moat-judge.py e roda DENTRO do tokenizador de lib/invocation-lines.sh (linhas de
# invocação: heredoc inerte, echo e prosa que CITAM o alvo não vetam; `bash -c`, `sudo -u`, `$(…)`,
# variável literal, `cd`, symlink, script fora do projeto e função definida na própria string — a chamada é
# emulada com os argumentos dela, SAC-148 — são seguidos).
#
# ── O QUE NÃO VETA (fronteira declarada) ─────────────────────────────────────────────────────────────────
#  · Wrapper versionado é fronteira para o ALVO: o que ele escreve por dentro não é julgado. Script fora do projeto, ou
#    não rastreado, é lido e julgado. O ATO do wrapper (linhas `ato`) é julgado mesmo assim, versionado ou não.
#  · Leitura: systemctl status/show/cat, journalctl, rsync para /tmp, git log/status/fetch num clone alheio.
#  · Entrega sem commit num adotante (/meta:co-deliver copia para o inbound/ dele): cópia não é escrita git.
#  · Sem ops/moat-targets.tsv (core-only) — adotante via /meta:adopt copia .claude/, não ops/ — o hook entra no MODO
#    DERIVADO (2026-11-05, medido na curadoria: num adotante 27 de 31 formas de ato passavam por todos os hooks, e a
#    saída antecipada derrubava também o relógio, que não depende do tsv). No derivado: o RELÓGIO veta (crontab,
#    at/batch, systemd-run com timer, systemctl que liga .timer, escrita em /etc/cron* e num .timer sob systemd/);
#    a PUBLICAÇÃO só AVISA (aprovação de ambiente, push de tag, visibilidade/descrição/tópicos do repo: decisão do
#    maestro pelo kg-ssot, que veta isso com hook local próprio e as provas dele); deploy, repo alheio e ato ficam
#    desarmados (os alvos são desta máquina, e o merge no adotante é outra forja).
#  · Escape = o maestro roda o comando fora da sessão (`!` no prompt). Não há variável de bypass por
#    desenho: escape que o modelo escreve na própria string é gate textual com outro nome. O `!` não passa
#    pelos hooks de ferramenta: medido no corpus de transcripts em 2026-11-05, `! sudo systemctl restart
#    onion-vps-bridge` (2026-10-22, CC 2.1.308) rodou com este hook registrado desde 2026-10-13, e ele o veta.
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
tsv="${root}/ops/moat-targets.tsv"
derived=0
[ -f "$tsv" ] || { derived=1; tsv=/dev/null; }     # modo derivado: ver a fronteira acima
members="${root}/docs/evolution/federation/members.yaml"
[ "$derived" = 1 ] && members=/dev/null
here="$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=lib/invocation-lines.sh
. "${here}/lib/invocation-lines.sh"

# ── pré-filtro sem python (o caminho quente) ──────────────────────────────────────────────────────────
# O tokenizador custa ~130 ms por chamada nesta VPS; a maioria dos comandos nem cita um alvo. O filtro é um
# SUPERCONJUNTO do que o juiz pode vetar: (1) um sinal de alvo; (2) construção dinâmica junto de um verbo
# de escrita (a concatenação `A=onion-v; B=ps-x` não deixa o sinal literal); (3) invocação de script por
# arquivo (o juiz o lê); (4) at/batch e push. Fora disso, não há o que o juiz veja.
raw_cmd=$(printf '%s' "$input" | onion_json_string_field command) || raw_cmd="$input"
signal=$(
  # cada alvo entra como escrito, com `~/` no lugar do HOME (o juiz expande o til) e pelo último componente
  # (`cd /var && rsync x www/onion-landing/` não traz o caminho inteiro); `onion` sozinho casaria tudo
  { awk -F'\t' '!/^[[:space:]]*#/ && NF>=3 { p=$3; g=sub(/[*?\[].*$/, "", p); if (p != "") print $1 "\t" g "\t" p }' "$tsv" \
      | while IFS=$'\t' read -r c g p; do
          printf '%s\n' "$p"
          case "$p" in "$HOME"/*) printf '%s\n' "~/${p#"$HOME"/}" ;; esac
          # o componente só de padrão SEM glob: `onion-` (de /usr/local/sbin/onion-*) casaria a casa inteira
          # e `system` (de /run/systemd/system) casaria todo `systemctl`: o caminho inteiro já está no sinal
          b="${p%/}"; b="${b##*/}"; [ "$c" = deploy ] && [ "$g" = 0 ] && [ "${#b}" -ge 4 ] && [ "$b" != onion ] && [ "$b" != system ] && printf '%s\n' "$b"
          # o script de ATO pelo nome (`cd ops && ./x.sh`, o clone servido, a cópia em /tmp): versionado, ele não
          # chegaria ao juiz pelo ramo (3), que só manda o que NÃO é rastreado
          [ "$c" = ato ] && printf '%s\n' "$b"
        done
    # o membro `kind: source` é ESTE projeto: no sinal, ele mandava ao python 15.837 dos 35.092 comandos do corpus
    [ -f "$members" ] && awk '
        function flush() { if (path != "" && kind != "source") print path; path = ""; kind = "" }
        /^[[:space:]]*-[[:space:]]+id:/ { flush() }
        /^[[:space:]]+kind:/ { k = $0; sub(/^[[:space:]]+kind:[[:space:]]*/, "", k); sub(/[[:space:]#].*$/, "", k); kind = k }
        /^[[:space:]]+local_path:/ { v = $0; sub(/^[[:space:]]+local_path:[[:space:]]*"?/, "", v); sub(/["#[:space:]].*$/, "", v); path = v }
        END { flush() }' "$members" \
      | while IFS= read -r m; do printf '%s\n' "$m" "${m##*/}"; done
    printf '%s\n' crontab systemd-run '.timer' /etc/cron /var/spool/cron
    # o modo de teste do wrapper de convites: só a bancada o liga; na linha de comando, o juiz fecha
    printf '%s\n' ONION_A2A_LIVE_TEST
    # idem para o modo de teste do wrapper da fila A2A (ops/a2a-queue-live.sh) (core-only)
    printf '%s\n' ONION_A2A_QUEUE_TEST
    # e do wrapper do drop-in de integridade do bridge (ops/bridge-hardening.sh) (core-only)
    printf '%s\n' ONION_BRIDGE_HARDENING_TEST
    # e do wrapper do runner do convidado (ops/chat-runner.sh) (core-only)
    printf '%s\n' ONION_CHAT_RUNNER_TEST
    # e do wrapper do STT em lote (ops/stt-service.sh) (core-only)
    printf '%s\n' ONION_STT_SERVICE_TEST
    # e do wrapper da persona do Slack (ops/slack-persona.sh) (core-only)
    printf '%s\n' ONION_SLACK_PERSONA_TEST
  } | grep -v '^$' | sed 's/[][\.*^$+?(){}|/]/\\&/g' | sort -u | paste -sd'|' -)
moat_action='(^|[^[:alnum:]_-])(systemctl|service|docker|rsync|cp|mv|install|tee|ln|rm|mkdir|touch|chmod|chown|dd|tar|unzip|crontab|systemd-run|at|batch|git|eval|xargs|sed|curl|wget)([^[:alnum:]_-]|$)|>'
# rota dinâmica: SÓ os programas cujo alvo é um NOME (unidade, container, crontab) ou que tornam o texto opaco
# (eval, xargs). Escrita em caminho por variável já traz o caminho literal na atribuição (sinal); o que escapa é a
# CONCATENAÇÃO de pedaços, que a rota `concat` pega. A 1ª redação usava a lista de ação inteira (git, cp, `>`)
# e mandava 90% do corpus ao python (31.474 de 35.092 comandos, medido em 2026-10-13).
moat_dyn='(^|[^[:alnum:]_-])(systemctl|service|docker|crontab|systemd-run|eval|xargs|at|batch)([^[:alnum:]_-]|$)'
moat_concat='\$\{?[A-Za-z_][A-Za-z0-9_]*\}?\$|\}[A-Za-z0-9._-]'
moat_write='(^|[^[:alnum:]_-])(rsync|cp|mv|install|tee|ln|rm|dd|tar|git|sed|touch|mkdir|chmod|chown)([^[:alnum:]_-]|$)|>'
moat_script='(^|[;&|(`[:space:]])(bash|sh|zsh|dash|ksh|source|\.)[[:space:]]+[^-[:space:]]|\.sh([^[:alnum:]_]|$)|(^|[;&|(`[:space:]])\./|\|[[:space:]]*(ba|z|da|k)?sh([[:space:]]|$)'
flat=$(printf '%s' "$raw_cmd" | tr -d "\"'\\\\")
hit=0
grep -qE "$signal" <<< "$flat" && hit=1
[ "$hit" = 0 ] && grep -qE '\$|`|\\u00|[*?{]' <<< "$raw_cmd" && grep -qE "$moat_dyn" <<< "$flat" && hit=1
[ "$hit" = 0 ] && grep -qE "$moat_concat" <<< "$raw_cmd" && grep -qE "$moat_write" <<< "$flat" && hit=1
# (3) script por arquivo: só vai ao juiz o que NÃO é versionado. A 1ª redação mandava todo `bash <x>.sh`, e esta
#     casa roda `bash .claude/validation/…` o dia inteiro (14.148 dos 35.092 comandos do corpus, 2026-10-13). O
#     mesmo predicado do juiz (rastreado pelo git do diretório onde roda), perguntado só quando a forma aparece;
#     shell lendo PIPE (`… | bash`) e caminho com variável vão sempre ao juiz.
moat_unversioned_script() {
  local t d
  d=$(printf '%s' "$input" | onion_json_string_field cwd) || d=""
  [ -d "$d" ] || d=$PWD
  grep -qE '\|[[:space:]]*(ba|z|da|k)?sh([[:space:]]|$)' <<< "$raw_cmd" && return 0
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    case "$t" in *'$'*|*'`'*|'~'*|*'*'*|*'?'*|*'['*) return 0 ;; esac   # glob: o ls-files o casaria como pathspec
    git -c core.fsmonitor=false -C "$d" ls-files --error-unmatch -- "$t" >/dev/null 2>&1 || return 0
  done < <(printf '%s\n' "$flat" \
             | grep -oE '(^|[;&|(`[:space:]])(bash|sh|zsh|dash|ksh|source|\.)[[:space:]]+[^-[:space:];&|][^[:space:];&|]*|[^[:space:];&|<>]*\.sh([^[:alnum:]_]|$)|(^|[;&|(`[:space:]])\./[^[:space:];&|]+' \
             | sed -E 's/^[;&|(`[:space:]]*//; s/^(bash|sh|zsh|dash|ksh|source|\.)[[:space:]]+//; s/[^[:alnum:]_./~$`-]+$//')
  return 1
}
[ "$hit" = 0 ] && grep -qE "$moat_script" <<< "$raw_cmd" && moat_unversioned_script && hit=1
# (5) symlink JÁ no disco (`rsync x /tmp/lw/` com lw → o docroot): o texto não traz o alvo. Com verbo de escrita,
#     cada caminho citado tem os componentes testados com `[ -L ]` (builtin, sem processo); achou link, vai ao juiz,
#     que resolve pelo realpath
moat_cites_symlink() {
  local t c
  while IFS= read -r t; do
    t="${t%/}"; c="$t"
    while [ -n "$c" ] && [ "$c" != "/" ] && [ "$c" != "." ]; do
      [ -L "$c" ] && return 0
      case "$c" in */*) c="${c%/*}" ;; *) break ;; esac
    done
  done < <(grep -oE '(^|[[:space:]=])[^[:space:];&|<>=]*/[^[:space:];&|<>]*' <<< "$flat" | sed -E 's/^[[:space:]=]+//' | head -n 64)
  return 1
}
[ "$hit" = 0 ] && grep -qE "$moat_write" <<< "$flat" && moat_cites_symlink && hit=1
[ "$hit" = 0 ] && grep -qE '(^|[;&|(`[:space:]])(at|batch)([[:space:]]|$)' <<< "$flat" && hit=1
# (4) push: o destino estrangeiro é uma URL ou um remoto, que nenhum sinal literal da lista alcança
[ "$hit" = 0 ] && grep -qE '(^|[^[:alnum:]_-])(push|send-pack)([^[:alnum:]_-]|$)' <<< "$flat" && hit=1
# (6) publicação pela API do forge: aprovação de ambiente, visibilidade, descrição e tópicos do repo
[ "$hit" = 0 ] && grep -qE '(^|[^[:alnum:]_-])(gh|curl)([^[:alnum:]_-]|$)' <<< "$flat" \
  && grep -qE 'pending_deployments|repo[[:space:]]+edit|release[[:space:]]+(create|edit|delete|upload)|/releases|/topics|visibility|description|private' <<< "$flat" && hit=1
# (7) o alvo do forge por outra porta (re-refutação do #1647, N1): remotes, `remote.*` no git config e o default do gh
[ "$hit" = 0 ] && grep -qE '(^|[^[:alnum:]_-])(remote[[:space:]]+(add|set-url|rename)|repo[[:space:]]+set-default|config([[:space:]]+[^[:space:]]+)*[[:space:]]+([Rr]emote|[Uu]rl|[Ii]nclude([Ii]f)?)\.)' <<< "$flat" && hit=1
[ "$hit" = 0 ] && exit 0

# ── leitura exata do JSON + juiz ──────────────────────────────────────────────────────────────────────────
# JSON ilegível NÃO vira `{}` (hooks em modo isolado, 2026-11-04): `{}` é comando vazio, e comando vazio é exit 0,
# a falha de análise virando permissão. Agora a leitura falha, e o caminho é o mesmo do python ausente: julga pela forma.
parsed=$(printf '%s' "$input" | python3 -I -c 'import json,sys
sys.stdout.reconfigure(errors="backslashreplace")
d=json.load(sys.stdin)
d=d if isinstance(d,dict) else {}
ti=d.get("tool_input"); ti=ti if isinstance(ti,dict) else {}
print(str(d.get("cwd") or "").replace("\n"," ")); print(str(ti.get("command") or ""))' 2>/dev/null) && nopy=0 || nopy=1
hcwd=${parsed%%$'\n'*}; cmd=${parsed#*$'\n'}; [ "$cmd" = "$parsed" ] && cmd=""
if [ "$nopy" = 1 ]; then
  hcwd=$(printf '%s' "$input" | onion_json_string_field cwd) || hcwd=""
  cmd="$raw_cmd"
fi
[ -d "$hcwd" ] || hcwd=$PWD
[ -z "$cmd" ] && exit 0

closed() {  # SEM tokenizador (python ausente/morto): fecha SÓ o que cita alvo E verbo de escrita
  grep -qE "$signal" <<< "$flat" && grep -qE "$moat_action" <<< "$flat" || exit 0
  echo "GUARDA-PRETOOLUSE (MOAT): $1 — o comando cita um alvo do MOAT (deploy, repo alheio ou relógio) e o veto não consegue analisá-lo. Fechado por segurança. Instale python3 (o tokenizador dos vetos); o deploy segue pelos wrappers de ops/ (core-only), e o resto é do maestro, fora da sessão." >&2
  exit 2
}
[ "$nopy" = 1 ] && closed "a análise não rodou (python3 ausente ou quebrado, ou JSON do hook ilegível)"
out=$(ONION_CWD="$hcwd" ONION_MOAT_JUDGE="${here}/lib/moat-judge.py" ONION_MOAT_TARGETS="$tsv" \
      ONION_MOAT_MEMBERS="$members" onion_invocation_lines "$cmd")
grep -qx '__ONION_MOAT_OK__' <<< "$out" || closed "a análise não chegou ao fim"
if [ "$derived" = 1 ]; then   # no derivado só o relógio, a publicação e o inanalisável (que só o relógio torna relevante)
  line=$(printf '%s\n' "$out" | grep -m1 -E $'^__ONION_MOAT__\t(relogio|publicacao|inanalisavel)\t' || true)
else
  line=$(printf '%s\n' "$out" | grep -m1 '^__ONION_MOAT__' || true)
fi
[ -z "$line" ] && exit 0
IFS=$'\t' read -r _ cls target wrapper detail <<< "$line"
if [ "$cls" = publicacao ] && [ "$derived" = 1 ]; then
  # AVISO, não veto (decisão do maestro de 2026-11-05 pelo kg-ssot): additionalContext e exit 0, o canal do merge-gate
  M="PUBLICAÇÃO (aviso do veto do MOAT, não veto): ${detail}. Isto é ato voltado ao público (${wrapper}). Neste repo derivado o core não barra; confira que o maestro autorizou e que as provas do próprio repo valem (PR mergeado, release declarada, verificação do espelho) antes de seguir." \
    python3 -I -c 'import json,os; print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":os.environ["M"]}}, ensure_ascii=False))'
  exit 0
fi
case "$cls" in
  publicacao)
    echo "GUARDA-PRETOOLUSE (MOAT/publicação): ${detail} — ato voltado ao público (${wrapper}: aprovação de ambiente, push de tag ou o que o público vê do repo) é do maestro. Negado pela sessão; peça ao maestro que rode pelo \`!\` no prompt, que não passa pelos hooks. A release do core sai por /meta:publish, que empurra a tag por dentro." >&2 ;;  # (core-only)
  deploy)
    if [ "$wrapper" != "-" ]; then
      how="o deploy deste alvo tem wrapper: bash ${wrapper} (core-only) — backup antes, conferência depois, rollback impresso"
    else
      how="este alvo NÃO tem wrapper: a mudança é do maestro, fora da sessão (\`!\` no prompt), ou nasce um ops/<wrapper>.sh (core-only) para ela"
    fi
    echo "GUARDA-PRETOOLUSE (MOAT/deploy): ${detail} — o alvo ${target} é SERVIDO (ops/moat-targets.tsv, core-only). Deploy fora de wrapper negado; ${how}." >&2 ;;
  alheio)
    case "$wrapper" in
      door) how="porta se publica por /meta:publish <porta>, que roda o ops/publish-door.sh" ;;  # (core-only)
      *)    how="empurre uma branch de tópico e abra PR lá (o PR é o gate do repo alheio), ou o maestro roda fora da sessão (\`!\` no prompt)" ;;
    esac
    echo "GUARDA-PRETOOLUSE (MOAT/repo alheio): ${detail} — ${target} não é este projeto (I3: a sessão do core não escreve repo alheio). Negado; ${how}." >&2 ;;
  ato)
    case "$wrapper" in
      --maestro) how="--maestro é o escape do MAESTRO (terminal dele, ou o \`!\`), nunca da sessão" ;;
      @foreign) how="merge em repo da família pela sessão só com --foreign-repo, que confere registro, CI verde, conflito e resíduo" ;;
      @any)  how="este script roda o ato em qualquer invocação" ;;
      @none) how="sem argumento ele roda o modo padrão, que é o ato; o ensaio ou a leitura dele (--help, --check, plan, verify) passa" ;;
      *)     how="sem ${wrapper} é ensaio ou leitura, e isso passa" ;;
    esac
    echo "GUARDA-PRETOOLUSE (MOAT/ato): ${detail} — deploy, publicação e push de porta são do maestro, salvo os atos delegados na forma exata (linhas delega), e o wrapper versionado não os torna da sessão (REGRA 117; alvos em ops/moat-targets.tsv, core-only). Negado pela sessão; ${how}. Peça ao maestro que rode pelo \`!\` no prompt, que não passa pelos hooks: \`! <o mesmo comando>\` (o deploy do site e o merge alheio, chamados de dentro da sessão, pedem também --maestro). Porta se publica por /meta:publish, que pergunta antes do --push." >&2 ;;  # (core-only)
  forja)
    echo "GUARDA-PRETOOLUSE (MOAT/forja): ${detail} — ${target} redireciona o forge (o gh e o merge verificado passam a mirar outro repositório). Negado pela sessão; o alvo de um merge se diz com --repo, e mudar remotes ou o default do gh é do maestro (\`!\` no prompt)." >&2 ;;
  relogio)
    echo "GUARDA-PRETOOLUSE (MOAT/relógio): ${detail} — agendar por relógio (${target}) é W7: o Onion é maestro-invocado, nunca cron/timer sobre si. Negado; agendamento é do maestro, fora da sessão (\`!\` no prompt)." >&2 ;;
  *)
    echo "GUARDA-PRETOOLUSE (MOAT): ${detail} — comando que cita um alvo do MOAT e NÃO pode ser analisado com certeza (${target}). Fechado: reescreva sem eval, nome de comando em variável, xargs ou código embutido noutra linguagem; o deploy segue pelos wrappers de ops/ (core-only)." >&2 ;;
esac
exit 2
