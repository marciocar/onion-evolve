#!/usr/bin/env bash
# PostToolUse(Bash) — a guarda anti-fail-open do SHELL.
#
# POR QUE EXISTE (3 falhas medidas na mesma sessão, 2026-08-02):
#   1. `ls -d <path-errado>` → vazio → concluí "o workflow não sobreviveu". Estava vivo; o path
#      é que omitia um segmento. Relancei em duplicata.
#   2. `bash script > /tmp/x 2>&1; RC=$?` … `tail x | ...; echo $?` → li o exit do `tail`, não do script.
#   3. `sudo -n ls /home/onion/.../.env.bak-*` → o glob expande no MEU shell (sem acesso a /home/onion),
#      não sob sudo; `2>/dev/null` engoliu o erro; `wc -l` deu 0 → "a dívida sumiu". Eram 7.
#
# O PADRÃO COMUM, e é UM só: resultado VAZIO/ZERO por motivo OPERACIONAL (sem acesso, path errado,
# pipe comendo o exit code) lido como FATO SOBRE O MUNDO ("não existe", "falhou", "são zero").
#
# O PRECEDENTE QUE ESTA GUARDA GENERALIZA: `kg-radar.sh:162` — quando o parse extrai 0 nós, o radar
# ABORTA SEM OPINAR em vez de dizer "nenhum problema encontrado" (guarda anti-fail-open, nascida de
# um falso-verde de campo em 2026-07-17). A casa já resolveu isto PARA O RADAR e nunca generalizou.
#
# POR QUE HOOK, e por que este caso é diferente do que reprovou no KG (research/kg-read-leg-2026-08,
# curas 1/9 e 3/7): lá se pedia ao hook que me fizesse FAZER algo (ir ler o grafo) — depende do meu
# julgamento, e é o desenho do Letta que o corpus mediu falhando. Aqui o hook ANOTA UM FATO sobre um
# evento que JÁ ocorreu ("o exit que você leu é do último elemento do pipe"). Não é instrução, é
# MEDIÇÃO — desacoplada do ator, que é a única propriedade que funcionou 4× nesta casa.
#
# CONTRATO: silencioso quando nada dispara (exit 0). Quando dispara, exit 2 — a ÚNICA via MEDIDA em
# que o stderr de um PostToolUse chega ao modelo. Não bloqueia nem desfaz: PostToolUse é posterior ao
# comando por definição; o "blocking error" só injeta o texto. Dogfood 2026-08-02: com exit 0 a guarda
# comprovadamente EXECUTA (marcador confirmou 2 execuções) e o aviso EVAPORA — seria cerimônia perfeita.
set -uo pipefail

input=$(cat 2>/dev/null) || exit 0

if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
  out=$(printf '%s' "$input" | jq -r '(.tool_response.stdout // .tool_response.output // "")' 2>/dev/null)
else
  # Sem jq a guarda se cala — declarar que NÃO SABE é o comportamento correto (certeza é campo, não tom).
  exit 0
fi
[ -n "${cmd:-}" ] || exit 0

# ── ANTI-RUÍDO: descarta o CORPO de heredoc antes de escanear ────────────────────────────────
# FALSO-POSITIVO MEDIDO no 1º dia da guarda (2026-08-02): a mensagem de commit que DESCREVIA os 4
# detectores disparou os 4 de uma vez — porque vinha num heredoc e o corpo entrou no escaneamento.
# Corpo de heredoc é TEXTO (mensagem de commit, documento, payload), não comando. A linha que ABRE
# o heredoc continua sendo escaneada — ela é comando de verdade.
# LIMITE DECLARADO: heredoc usado como SCRIPT (ex.: `bash <<EOF ... EOF`) deixa de ser inspecionado.
# Aceito conscientemente: heredoc-como-texto é a esmagadora maioria, e um alarme que grita em prosa
# vira fadiga — e alarme ignorado é pior que alarme ausente. A asserção (g) do selftest prova que o
# filtro NÃO cegou a guarda: padrão FORA do heredoc continua disparando.
cmd_scan=$(printf '%s\n' "$cmd" | awk '
  d != "" {                                  # dentro do corpo: descarta até o fechador
    line=$0; sub(/^[ \t]+/, "", line)
    if (line == d) d=""
    next
  }
  {
    print                                    # a linha que ABRE o heredoc É comando: mantém
    if (match($0, /<<-?[ \t]*['"'"'"]?[A-Za-z_][A-Za-z0-9_]*['"'"'"]?/)) {
      tok = substr($0, RSTART, RLENGTH)
      sub(/^<<-?[ \t]*/, "", tok); gsub(/['"'"'"]/, "", tok)
      d = tok
    }
  }')
cmd="${cmd_scan}"

warn=""
add() { warn="${warn}
  · $1"; }

# (1) $? lido depois de um pipe — o exit é do ÚLTIMO elemento, não do comando que importa.
#
# CORREÇÃO 2026-08-02 (2º falso-positivo achado POR USO, no mesmo dia): a versão anterior era
# `case "$cmd" in *'|'*'$?'*)` — casava um pipe em QUALQUER lugar com um `$?` em QUALQUER lugar,
# mesmo em instruções separadas por linhas. Disparou num comando onde o `$?` vinha logo após um
# `bash ... > arquivo 2>&1` (correto), só porque HAVIA um `find | sed` cinco linhas acima.
# Agora é POR PROXIMIDADE: o pipe tem de estar na MESMA linha do `$?` ou na linha imediatamente
# anterior. Cobre os dois casos reais (o pipe-e-$?-na-mesma-linha e o `cmd | tail` seguido de
# `echo $?` na linha de baixo) e mata o cross-statement.
# `set -o pipefail` em qualquer lugar do comando desarma — quem o declara já sabe do problema.
# CORREÇÃO 2026-08-09 (3ª classe de falso-positivo achada POR USO — CINCO disparos numa sessão):
# a proximidade contava `|` DENTRO DE ASPAS como pipe de shell. O caso real, repetido cinco vezes:
#     bash algo.sh > arquivo 2>&1
#     echo "rc=$?"; grep -E 'Passaram|Falharam|ABORTOU' arquivo
# O `$?` vem de um REDIRECT (correto) e o único `|` está no PADRÃO do grep — a guarda acusava assim
# mesmo.
#
# ⚠️ A 1a VERSAO DESTA CURA ABRIU TRES FAIL-OPENS, achados por passada adversarial no PR #563 e
# reproduzidos com medicao antes/depois. A premissa que escrevi — "entre aspas, `|` e TEXTO" — e
# FALSA em tres formas, e as tres sao justamente o que esta guarda existe para pegar:
#   1. `x="$(cmd | wc -l)"; echo $?`  — dentro de $( ) o pipe e REAL. Era o modo-de-falha nº2 que
#      FUNDOU a guarda, e a cura o cegou. (O proprio diff do PR #563 tinha tres linhas dessa forma.)
#   2. `sh -c 'a | b'; echo $?`       — em sh/bash/ssh/su/xargs/-exec, a string entre aspas E SHELL.
#   3. `echo "it's"; ls | wc -l; echo "don't"` — o gsub de apostrofo casava de "it's" ate "don't" e
#      apagava o miolo INTEIRO, pipe real junto.
#
# A regra passou a ser a inversa, e e ela que mantem a guarda honesta: SO remove trecho entre aspas
# quando da para AFIRMAR que ali e texto. Havendo substituicao de comando, wrapper que recebe
# comando como string, ou aspas nao fechadas, devolve a LINHA CRUA — a guarda erra para o lado de
# GRITAR, nunca para o lado de calar. E a varredura passou a ser por ESTADO, caractere a caractere,
# porque uma aspa dentro de aspa e literal (que e a regra real do bash), coisa que par-de-regex
# nao sabe.
# GUARDA QUE GRITA ERRADO ENSINA A IGNORAR A GUARDA — mas guarda que CALA ERRADO nao ensina nada,
# so mente. Entre os dois erros, este arquivo escolhe o primeiro, por desenho.
case "$cmd" in *pipefail*) : ;; *)
  if printf '%s\n' "$cmd" | awk '
        function unquoted(s,   i, c, q, o) {
          # inseguro afirmar que e texto -> linha CRUA (falha gritando)
          if (s ~ /[$]\(/ || s ~ /`/)                                      return s
          if (s ~ /(^|[ \t;&|(])(sh|bash|zsh|dash|ksh|busybox)[ \t]+-[a-z]*c([ \t]|$)/) return s
          if (s ~ /(^|[ \t;&|(])(ssh|eval|xargs|doas)([ \t]|$)/)           return s
          if (s ~ /(^|[ \t;&|(])su[ \t]+[^;|&]*-c([ \t]|$)/)               return s
          if (s ~ /-exec([ \t]|$)/)                                        return s
          if (s ~ /(docker|podman|kubectl)[ \t]+[a-z]+[ \t]/)              return s
          # varredura por ESTADO: aspa dentro de aspa e literal
          o = ""; q = ""
          for (i = 1; i <= length(s); i++) {
            c = substr(s, i, 1)
            if (q == "") { if (c == "'"'"'" || c == "\"") { q = c } else { o = o c } }
            else if (c == q) { q = "" }
          }
          if (q != "") return s        # aspas ABERTAS no fim da linha: indeterminado -> crua
          return o
        }
      function ultimoQ(s,   pos, off, ult) {
        off = 0; ult = 0
        while ((pos = index(substr(s, off + 1), "$?")) > 0) { ult = off + pos; off = ult + 1 }
        return ult
      }
      { cur = $0; nu = unquoted(cur)
        # ⚠️ NA MESMA LINHA, A ORDEM DECIDE — 4a classe de falso-positivo achada POR USO (2026-08-09).
        # O caso real: `echo "rc=$?"; grep ... arquivo | head -4`. O `$?` e do comando da linha
        # ANTERIOR e o pipe vem DEPOIS dele; a heuristica so via "ha $? e ha | na mesma linha" e
        # acusava. Agora o pipe da PROPRIA linha so conta se estiver ANTES do `$?`. O pipe da linha
        # anterior segue contando sempre — la ele e necessariamente anterior.
        # ⚠️ O `$?` QUE IMPORTA E O ULTIMO, NAO O PRIMEIRO — fail-open que eu introduzi com a
        # propria cura de ordem e achei medindo: em `echo $?; ls | wc -l; echo $?` o `index()`
        # pegava o PRIMEIRO `$?` (antes do pipe), concluia "ordem ok" e CALAVA — enquanto o
        # SEGUNDO `$?`, esse sim, le o exit do `wc`. A pergunta certa e "ALGUM `$?` vem depois de
        # ALGUM `|`", e ela se responde com o PRIMEIRO pipe contra o ULTIMO `$?`.
        # ⚠️ A ASSIMETRIA E O PONTO, e a 1a versao a errou: o PIPE se le em `nu` (entre aspas ele e
        # TEXTO — padrao de grep), mas o `$?` se le na linha CRUA, porque `echo "rc=$?"` LE o exit
        # de verdade. Lendo os dois em `nu`, `ls | wc -l; echo "rc=$?"` ficava sem `$?` nenhum e a
        # guarda CALAVA — o modo-de-falha nº2 que a FUNDOU, cegado pela cura de ordem. Achado por
        # passada adversarial, com main DISPARANDO e HEAD calado no mesmo comando.
        p_ord = index(nu, "|"); q_ord = ultimoQ(cur)
        mesmaLinha = (p_ord > 0 && q_ord > 0 && p_ord < q_ord)
        if (cur ~ /\$\?/ && (mesmaLinha || prevNu ~ /\|/)) { found = 1; exit }
        if (cur ~ /[^ \t]/) { prev = cur; prevNu = nu }       # linha em branco não quebra a vizinhança
      }
      END { exit(found ? 0 : 1) }'; then
    add 'EXIT-CODE-DE-PIPE: você leu `$?` logo depois de um pipe — ele é do ÚLTIMO elemento (o `tail`/`head`/`grep`), não do comando que interessa. Rode o comando sozinho e capture `$?` na linha seguinte, ou use `set -o pipefail`.'
  fi ;;
esac

# (2) glob dentro de path sob sudo — expande no shell do CHAMADOR, que pode não ter acesso.
case "$cmd" in
  *sudo*)
    if printf '%s' "$cmd" | grep -qE 'sudo[^|;]*(ls|cat|stat|head|tail|wc)[^|;]*/[^ ]*\*'; then
      add 'GLOB-SOB-SUDO: o `*` expande no SEU shell ANTES do sudo — se você não tem acesso ao diretório, ele não casa nada e o comando recebe o literal. Use `sudo find <dir> -name "<padrão>"`, que expande DENTRO do sudo.'
    fi ;;
esac

# (3) erro engolido alimentando contagem/decisão — zero indistinguível de falha.
if printf '%s' "$cmd" | grep -qE '2>/dev/null.*\|[[:space:]]*(wc[[:space:]]+-l|grep[[:space:]]+-c)'; then
  add 'ERRO-ENGOLIDO-VIRANDO-NÚMERO: há `2>/dev/null` a montante de uma contagem — um comando que FALHOU e um objeto que NÃO EXISTE produzem o mesmo `0`. Mostre o stderr, ou use o helper: `source .claude/utils/safe-count.sh` → `count_files <dir> <glob>` / `count_matches <padrão> <arquivos>` / `count_lines <arquivo>` (alvo ausente = exit 2 + stderr, nunca zero silencioso).'
fi

# (3b) `pgrep -f` / `pkill -f` que CASA A SI MESMO — o padrão está na linha de comando do próprio
# shell que o executa, então ele sempre se encontra. Custo medido em UMA sessão (2026-08-10), três
# vezes, com três danos DIFERENTES — que é o que prova ser classe e não descuido:
#   1. `pkill -f 'lint-selftest'` com verificação por OUTRO padrão → afirmei ter matado o que não
#      morreu, e quem viu foi o maestro na tela;
#   2. `pgrep -fc 'lint-selftest'` devolvendo 1 com a bancada morta — o sobrevivente era o meu shell;
#   3. `until ! pgrep -f 'git commit -F'` → a condição NUNCA podia virar falsa. Shell preso 1h06,
#      esperando por si mesmo, enquanto o commit tinha terminado havia muito.
# O (3) é o mais perigoso porque não erra: ele ESPERA para sempre, e esperar parece trabalhar.
#
# A cura é o idioma clássico do colchete: `pgrep -f '[l]int-selftest'` — o regex casa `lint-selftest`,
# mas a linha de comando literal contém `[l]int-selftest`, que o regex NÃO casa. Alternativa:
# excluir o próprio PID (`| grep -v "^$$\$"`) ou `--older` (o shell que roda o laço é NOVO). `-x`
# tambem esta a salvo: casa o NOME do executavel, nao a linha inteira.
#
# ⚠️ SEGUNDA VERSÃO — a primeira tinha QUATRO fail-opens, achados na passada adversarial contra ela
#    mesma, no PR que a introduziu. A raiz era UMA: as isenções valiam para o COMANDO INTEIRO.
#    Bastava um colchete num redirect (`pgrep -f alvo > /tmp/x[1].txt`), um `$$` presente por outro
#    motivo, ou um `-x` numa invocação IRMÃ para desarmar a regra sobre a invocação culpada.
#    É a mesma classe que eu já tinha aberto DUAS vezes nesta sessão curando outra coisa: cura de
#    fail-open que abre fail-open. Agora o julgamento é POR INVOCAÇÃO, com dois escopos distintos —
#    o colchete vale só dentro do ARGUMENTO (senão um redirect isenta), e `$$`/`--older` valem no
#    STATEMENT (senão o pipe que exclui o próprio PID ficaria fora do alcance).
# ⚠️ TERCEIRA VERSÃO — a segunda passada adversarial derrubou QUATRO coisas na 2ª, e três eram do
#    lado que mais custa. Todas medidas, nenhuma inferida do regex:
#      (i)  COBERTURA MENOR QUE A PROMESSA: o regex exigia que o cluster com `f` fosse o PRIMEIRO
#           token depois do comando. Escapavam `pkill -9 -f` (provavelmente a forma mais comum do
#           mundo real), `pgrep -a -f`, `pgrep -u root -f` e a opção longa `--full`. O texto do aviso
#           prometia cobrir a classe; o código cobria um dialeto dela.
#      (ii) FALSO-POSITIVO EM COMANDO DE LEITURA: `grep -rn "pgrep -f" .claude/` disparava, e a
#           mensagem de commit que DESCREVIA a regra também. E o meta-defeito é o que dói: quarenta
#           linhas abaixo, no detector (5), está escrito que ele sofreu EXATAMENTE isto e que a cura
#           foi ANCORAR EM INÍCIO DE COMANDO. Eu escrevi a (3b) no dia seguinte sem reusar a cura já
#           paga — a casa tinha o remédio no mesmo arquivo.
#      (iii) A CURA RECOMENDADA NÃO CURAVA, E A GUARDA A CERTIFICAVA: no idioma lança-e-espera
#           (`bash x.sh & until ! pgrep -f '[x]'`), a forma NUA do padrão está na linha por causa do
#           lançamento — o colchete não protege, o laço trava, e a guarda ficava MUDA porque via o
#           `[`. Fail-open com selo é pior que ausência de guarda.
#      (iv) `-A`/`--ignore-ancestors` (procps-ng >=4.0) — a cura de VERDADE, que exclui os ancestrais
#           do próprio shell — passava por acidente, caindo no buraco de cobertura de (i), não por
#           reconhecimento.
#
#    Agora: âncora em INÍCIO DE POSIÇÃO DE COMANDO (mata (ii)), modo-full lido de QUALQUER token de
#    opção da invocação (mata (i)), desarme por opção da PRÓPRIA invocação (`-A`/`-x`/`-O` e as
#    longas), e o colchete só isenta quando a forma NUA não co-ocorre no comando (mata (iii)).
_pg_self=0; _pg_pierced=0
while IFS= read -r _stmt; do
  case "${_stmt}" in *'$$'*) continue ;; esac    # exclui o próprio PID — escopo STATEMENT (o pipe)
  while IFS= read -r _pos; do
    # ÂNCORA: só conta se `pgrep`/`pkill` ABRE a posição de comando. Sem isto, qualquer comando que
    # apenas MENCIONE a string (grep, commit -m, comentário) é acusado — a lição do detector (5).
    _c="$(printf '%s' "${_pos}" | sed -E 's/^[[:space:]]*//
                                          :a
                                          s/^(!|until|while|do|then|else|if|elif|\(|\{)[[:space:]]+//; ta
                                          s/^[[:space:]]*//')"
    case "${_c}" in pgrep\ *|pkill\ *|pgrep|pkill) ;; *) continue ;; esac
    # MODO FULL por QUALQUER token de opção — cluster curto com `f`, ou a longa `--full`
    printf '%s' "${_c}" | grep -qE '(^|[[:space:]])(-[a-zA-Z]*f[a-zA-Z]*|--full)([[:space:]]|$)' || continue
    # DESARMES por opção da PRÓPRIA invocação: -A (ignora ancestrais, a cura real), -x (casa o NOME
    # do executável), -O/--older (o shell que roda o laço é NOVO)
    if printf '%s' "${_c}" | grep -qE '(^|[[:space:]])(-[a-zA-Z]*[AxO][a-zA-Z]*|--ignore-ancestors|--exact|--older)([[:space:]]|$)'; then continue; fi
    # COLCHETE: isenta só se a forma NUA não co-ocorrer. `bash x.sh & until ! pgrep -f '[x]'` tem o
    # `x` nu no lançamento, então o colchete não protege nada ali.
    # o ARGUMENTO termina no primeiro redirect — senão um `[` em `> /tmp/x[1].txt` isentaria a regra
    # (fail-open medido na 3ª passada: o colchete tem de estar no PADRÃO, não em qualquer lugar).
    _pg_arg="$(printf '%s' "${_c}" | sed -E 's/[<>].*$//; s/^(pgrep|pkill)//; s/(^|[[:space:]])(-[a-zA-Z-]+|--[a-z-]+=[^[:space:]]*)//g; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^["'"'"']//; s/["'"'"']$//')"
    case "${_pg_arg}" in
      *'['*)
        # A FORMA NUA CO-OCORRE? `[m]arcador` NÃO contém a substring `marcador`, então QUALQUER
        # ocorrência da nua no comando veio de outro lugar (o lançamento, um echo) e fura o colchete.
        # ⚠️ `grep -c` conta LINHAS, e o comando costuma ser UMA — foi assim que este caso passou
        #    despercebido na 1ª rodada da matriz. Contagem de OCORRÊNCIA exige `grep -o | wc -l`.
        _pg_bare="$(printf '%s' "${_pg_arg}" | tr -d '[]')"
        if [ -n "${_pg_bare}" ] \
           && [ "$(printf '%s' "$cmd" | grep -oF -- "${_pg_bare}" 2>/dev/null | wc -l)" -ge 1 ]; then
          _pg_pierced=1; _pg_self=1
        fi
        continue ;;
    esac
    _pg_self=1
  done <<PGPOS
$(printf '%s' "${_stmt}" | tr '|' '\n')
PGPOS
done <<PGSCAN
$(printf '%s' "$cmd" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g; s/\([^>\&]\)\&\([^\&>]\)/\1\n\2/g')
PGSCAN
if [ "${_pg_pierced}" -eq 1 ]; then
  add 'COLCHETE-FURADO: seu `pgrep -f "[x]…"` NÃO protege aqui — a forma NUA do padrão aparece na mesma linha de comando (o lançamento, o `echo`, o caminho do script), então o shell do laço se encontra do mesmo jeito e ele trava para sempre. Use `pgrep -A -f` (`--ignore-ancestors`, exclui o próprio shell) ou espere por PID: `while kill -0 "$PID" 2>/dev/null; do sleep 5; done`.'
elif [ "${_pg_self}" -eq 1 ]; then
  add 'PGREP-QUE-SE-ENCONTRA: `pgrep -f`/`pkill -f` casa a linha de comando do PRÓPRIO shell que o roda — o padrão está escrito ali. Num `until ! pgrep ...` isso trava PARA SEMPRE (medido: 1h06 esperando por si mesmo). Cura mais forte: `pgrep -A -f` (`--ignore-ancestors`). Alternativas: o idioma do colchete `pgrep -f "[l]int-selftest"` (só serve se a forma NUA não estiver na mesma linha) ou esperar por PID com `kill -0`. E nunca mate com um padrão e confira com outro: a conferência tem de usar EXATAMENTE o padrão do `pkill`.'
fi

# (4) comando de DESCOBERTA com saída vazia — o caso que mais custou (o falso "não sobreviveu").
# CALIBRAÇÃO ANTI-RUÍDO (o risco real de qualquer alarme é virar fadiga e ser ignorado):
#   · `grep -q`/`grep -c` são TESTE e CONTAGEM, não descoberta-para-ler — vazio ali é resposta, não sinal.
#   · comando que JÁ trata o ramo vazio (`|| echo`, `|| printf`, `|| true`, `else`) mostra que o autor
#     considerou a hipótese — a guarda não tem o que ensinar.
# Sobra exatamente a forma que me mordeu: descoberta nua cujo vazio eu ia ler como ausência.
if [ -z "${out//[[:space:]]/}" ] \
   && ! printf '%s' "$cmd" | grep -qE 'grep[[:space:]]+-[a-zA-Z]*[qc]' \
   && ! printf '%s' "$cmd" | grep -qE '\|\|[[:space:]]*(echo|printf|true)|[[:space:]]else[[:space:]]' \
   && printf '%s' "$cmd" | grep -qE '(^|[|;&[:space:]])(ls|find|git ls-files)([[:space:]]|$)'; then
  add 'VAZIO ≠ AUSÊNCIA: comando de descoberta devolveu NADA. Vazio pode ser (a) o objeto não existe, (b) o path/glob está errado, (c) você não tem acesso. São conclusões OPOSTAS. Confirme o caminho-pai antes de afirmar que algo não existe.'
fi

# (5) MERGE/PR SEM A FONTE LIDA — o caso que custou dois PRs mergeados hoje (2026-08-06).
#
# POR QUE EXISTE: mergeei os PRs #546 e #548 anunciando "verde", sem revisão semântica nenhuma.
# O `onion-review` sai VERDE POR DESENHO quando o revisor falha (soft-pass deliberado de 2026-07-14)
# — logo `gh pr checks` mostrando `pass` NÃO diz que houve revisão. O sinal existia (comentário no
# PR, nota no resumo do job) e nenhuma dessas superfícies é a que o fluxo de merge consulta.
#
# ESTE DETECTOR NÃO BLOQUEIA, E ISSO É DESENHO, NÃO LIMITAÇÃO: o soft-pass é decisão registrada
# (.github/workflows/onion-review.yml) e negar o merge a contradiria. O valor aqui não é impedir o
# merge — é impedir a DECLARAÇÃO FALSA ("mergeei, estava verde"). Mergear sem revisão continua
# possível; mergear sem revisão SEM SABER, não.
#
# EU DECLAREI "falso-positivo estruturalmente impossível" E ESTAVA ERRADO — a revisão adversarial
# fez o detector disparar TRÊS vezes nos próprios comandos de LEITURA dela (`grep -n "gh pr merge"`,
# `echo "...gh pr create..."`, mensagem de commit). O `case` casava a substring em QUALQUER posição,
# inclusive dentro de aspas. Num canal onde todo disparo interrompe, isso é fadiga — e o próprio
# arquivo já alerta contra ela. Agora o casamento é ANCORADO EM INÍCIO DE COMANDO (começo da linha
# ou depois de `;`/`&&`/`||`/`|`), como o detector (1) já fazia por proximidade.
#
# TETO DECLARADO: PostToolUse é posterior por definição — dispara DEPOIS do comando. Um PreToolUse
# que negasse antes foi PROJETADO E REFUTADO em 2026-08-06 (N pós-cura = 0; ~1 em 3 merges seria
# travado; e PreToolUse é substrato NÃO-VERIFICADO neste repo). Reabre só com um merge cego novo.
if printf '%s\n' "$cmd" | grep -qE '(^|[;&|][[:space:]]*|^[[:space:]]*)gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)'; then
    add 'MERGE-SEM-FONTE-LIDA: `onion-review` sai VERDE POR DESENHO quando o revisor falha (soft-pass) — `pass` ali NÃO significa que houve revisão. A fonte é a linha `onion-review-verdict` em `gh pr checks <N>`. Se você não leu ESSA linha, você não sabe se este PR foi revisado.'
fi
if printf '%s\n' "$cmd" | grep -qE '(^|[;&|][[:space:]]*|^[[:space:]]*)gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)'; then
    add 'PR-SEM-PASSADA-ADVERSARIAL: abrir PR sem a passada adversarial deixa a revisão para um CI que estoura turnos justamente nos PRs grandes. O artefato de revisão é exigido pela REGRA 56 (`docs/evolution/review/<branch>.md`) — se ele não existe, o gate vai acusar e você vai descobrir tarde.'
fi

# (6) BRANCH NOMEADA EM pt-BR — `code-standards.md:39` exige branch em INGLÊS, e eu nomeei DUAS em
# pt-BR numa única sessão (2026-08-10): `fix/fixture-nao-depende-do-vivo` e `docs/waha-rotacao-e-hash`.
# Levantamento do repo mostra que é sistêmico, não lapso: `docs/fios-abertos`,
# `fix/catraca-duas-portas`, `fix/catraca-separador-de-registro`, `fix/selo-m8-vereditos`.
#
# POR QUE AQUI, E NÃO NO LINT: o lint roda no commit — e aí renomear já custa caro (branch publicada,
# PR aberto, resíduo da REGRA 56 nomeado pela branch). Acusar no commit seria PUNIR QUEM JÁ NÃO PODE
# CORRIGIR BARATO, que é exatamente o erro da REGRA 56 que ensinou 23 bypasses. O momento em que a
# correção é grátis é a CRIAÇÃO — e é quando este hook dispara.
#
# Reusa a MESMA lista da REGRA 60 (`lib/pt-br-words.txt`): uma fonte de palavras, não duas. Quando um
# identificador pt-BR novo entra na lista, esta regra passa a cobri-lo de graça.
# TETO DECLARADO: detector por lista enumerada só vê o que foi enumerado (o mesmo teto da REGRA 60), e
# PostToolUse é posterior — a branch já foi criada. Mas renomear no ato é `git branch -m`, e é grátis.
# ⚠️ SEGUNDA VERSÃO. A primeira foi derrubada por passada adversarial no PR que a introduziu, com
#    QUATRO defeitos — e o extrator por `sed` era a raiz de três deles:
#      (a) `git branch -m <velho> <novo>`: o nome NOVO é o ÚLTIMO (`git branch --help`), e o captor
#          pegava o PRIMEIRO. Medido: renomear `fix/rotacao-de-chaves` → `rotate-keys` — que é
#          EXATAMENTE a cura que a mensagem manda — era ACUSADO pelo nome que estava sendo apagado; e
#          renomear inglês → pt-BR passava calado. A guarda punindo a obediência, de novo.
#      (b) COBERTURA: escapavam `-B`, `switch --create`/`-C`, `branch -M`, `git branch <nome>` (criação
#          nua), `worktree add -b`, `git -C <dir> checkout -b` e `checkout --track -b`.
#      (c) GULOSO: `.*git` no `sed` fazia a linha inteira ser julgada pela ÚLTIMA criação — criar a
#          branch pt-BR e emendar `&& git checkout -b feat/ok` desarmava a regra.
#    (b) e (c) são LITERALMENTE o defeito que o detector (3b), 130 linhas acima NESTE ARQUIVO, já
#    documenta ter sofrido e curado. Segunda vez no mesmo dia que a cura paga não foi reusada.
#
# Agora: tokeniza POR STATEMENT (o mesmo split da (3b)), entende as opções globais do git, e aplica a
# regra de posição CERTA para cada subcomando. Acentos são normalizados antes de segmentar — sem isso
# `fix/rotação-de-chaves` truncava no captor e passava.
if printf '%s\n' "$cmd" | grep -qE '(^|[;&|][[:space:]]*|^[[:space:]]*)git([[:space:]]+(-C|-c)[[:space:]]+[^[:space:]]+|[[:space:]]+--git-dir=[^[:space:]]+)*[[:space:]]+(checkout|switch|branch|worktree)([[:space:]]|$)'; then
  _wl="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/validation/lib/pt-br-words.txt"
  if [ -f "${_wl}" ]; then
    while IFS= read -r _bn; do
      [ -n "${_bn:-}" ] || continue
      # normaliza acento: `rotação` → `rotacao`. Sem iconv, degrada declarando (mesma doutrina do jq).
      _bn_ascii="$(printf '%s' "${_bn}" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || printf '%s' "${_bn}")"
      _hits="$(printf '%s' "${_bn_ascii}" | tr '/_.-' '\n\n\n\n' | tr '[:upper:]' '[:lower:]' | grep -Fxf "${_wl}" 2>/dev/null | sort -u | tr '\n' ' ')"
      if [ -n "${_hits% }" ]; then
        add "BRANCH-EM-PT-BR: \`${_bn}\` tem palavra(s) pt-BR: ${_hits% }. \`code-standards.md:39\` exige branch em INGLÊS (o prefixo Conventional e o nome são contrato de máquina; a narrativa em pt-BR vive no ASSUNTO do commit). Renomeie AGORA, enquanto é grátis: \`git branch -m <atual> <nome-em-ingles>\` — depois de publicar, a branch já nomeia o PR e o resíduo da REGRA 56."
      fi
    done <<PGBRANCH
$(printf '%s' "$cmd" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g' | awk '
  function unq(t) { gsub(/^["'"'"']|["'"'"']$/, "", t); return t }
  function isopt(t) { return substr(t, 1, 1) == "-" }
  {
    n = split($0, T, /[ \t]+/); i = 1
    while (i <= n && (T[i] == "" || T[i] ~ /^(!|until|while|do|then|else|elif|if|\(|\{)$/)) i++
    if (T[i] != "git") next
    i++
    while (i <= n && isopt(T[i])) { if (T[i] == "-C" || T[i] == "-c") i += 2; else i++ }
    sc = T[i]; i++
    if (sc == "worktree") { if (T[i] == "add") i++; else next; sc = "checkout" }
    # colhe as posições dos argumentos NÃO-opção e a que segue a flag de criação
    flagged = ""; last = ""
    for (j = i; j <= n; j++) {
      if (T[j] == "") continue
      if (isopt(T[j])) {
        if (sc == "checkout" && T[j] ~ /^-[bB]$/)                       { if (T[j+1] != "" && !isopt(T[j+1])) flagged = T[j+1] }
        else if (sc == "switch" && T[j] ~ /^(-[cC]|--create)$/)          { if (T[j+1] != "" && !isopt(T[j+1])) flagged = T[j+1] }
        else if (sc == "branch" && T[j] ~ /^(-[mMcC]|--move|--copy)$/)   { mv = 1 }
        # QUALQUER outra opção desliga a leitura de "criação nua": `git branch -d <x>` APAGA, não cria,
        # e acusar ali seria alarme sobre quem está justamente removendo a branch mal-nomeada.
        hasopt = 1
        continue
      }
      last = T[j]
      if (nonopt == "") nonopt = T[j]
      cnt++
    }
    # `branch -m [<velho>] <novo>`: o NOVO é o ULTIMO. `branch <nome>`: criação nua.
    if (sc == "branch") { if (mv == 1) print unq(last); else if (cnt == 1 && hasopt == 0) print unq(nonopt) }
    else if (flagged != "") print unq(flagged)
    mv = 0; cnt = 0; hasopt = 0; nonopt = ""; last = ""
  }')
PGBRANCH
  fi
fi

[ -n "$warn" ] || exit 0
printf '🔎 guarda anti-fail-open do shell — o que você acabou de rodar pode MENTIR:%s\n' "$warn" >&2
# exit 2 — a ÚNICA via MEDIDA em que o stderr de um PostToolUse chega ao modelo (dogfood 2026-08-02:
# com exit 0 o hook comprovadamente EXECUTA — marcador em /tmp confirmou 2 execuções — e o aviso
# EVAPORA). Não desfaz nada: o comando já rodou; PostToolUse é posterior por definição.
# Se um dia exit 2 passar a bloquear de fato, o teto é este arquivo — e o selftest pega.
exit 2
