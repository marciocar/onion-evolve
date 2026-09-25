#!/usr/bin/env bash
# command-role-parity-check.sh — REGRA 90: a PROSA do comando conhece os papéis que o SCRIPT aceita.
#
# Uso: bash .claude/validation/command-role-parity-check.sh [<repo-root>]
# Saída: uma linha por divergência, em stdout. rc 0 = paridade · 1 = divergência · 3 = não pude julgar.
#
# ═══ POR QUE ESTA GUARDA EXISTE (duas ocorrências da MESMA classe, em sentidos OPOSTOS) ═══
#
# O par script×prosa dos comandos de co-evolução desencontrou duas vezes, e cada vez para um lado:
#
#   2026-09-17 — o SCRIPT era estreito e a PROSA larga. `co-relay.sh` testava `!= "adopted"` enquanto
#     a mensagem dele já prometia "adopted ou hub" e o espelho `co-deliver.sh` entregava a `hub`. O
#     core ENTREGAVA anúncios à porta por desenho declarado, e a porta não podia responder. Custou um
#     sinal entregue à mão.
#   2026-09-25 — o SCRIPT largo e a PROSA estreita. Os helpers já aceitavam `adopted|hub|standalone`,
#     mas `co-evolve.md` mapeava só `source` e `adopted`, e `co-relay.md`, lido ao pé da letra,
#     mandava um `hub` PARAR. A primeira sessão de um adotante `hub` teve de inferir onde se encaixava
#     — e foi ELE quem reportou, não o core.
#
# A assimetria é o ponto: **a sessão lê a prosa primeiro e o script nunca**. Um script correto com
# prosa errada produz um agente que se recusa a fazer o que a máquina permite — e isso não aparece em
# nenhum gate, porque a máquina está certa. Por isso a guarda compara os DOIS e não confia em nenhum
# como autoridade: divergência em qualquer sentido é achado.
#
# ⚠️ FRONTEIRA DECLARADA, para não prometer o que não mede: esta guarda casa o `case`/`grep -qE` de
# PAPÉIS (`source|adopted|hub|standalone`) no helper contra a menção literal de cada papel na prosa do
# comando irmão. Ela NÃO julga se a prosa descreve o papel CORRETAMENTE — só que ela o menciona.
# Prosa que cita `hub` e diz uma bobagem sobre ele passa aqui. O que ela mata é o silêncio, que foi o
# modo-de-falha real das duas vezes.
set -uo pipefail
ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "${ROOT}" 2>/dev/null || { echo "REGRA 90: nao pude entrar em ${ROOT}" >&2; exit 3; }

# PARES declarados: <helper> <comando>. Ampliar a lista é o jeito de cobrir mais superfície.
PAIRS=(
  ".claude/utils/co-evolution/co-relay.sh|.claude/commands/meta/co-relay.md"
  ".claude/utils/co-evolution/co-deliver.sh|.claude/commands/meta/co-deliver.md"
  # `co-evolve.md` é o doc de ORIENTAÇÃO e não tem helper próprio — mas foi exatamente a tabela de
  # papéis DELE que derivou em 2026-09-25. Deixá-lo fora seria curar a prosa e não proteger a cura,
  # que é o defeito que esta guarda persegue. Ele pareia contra os dois helpers do doc-bridge: se
  # QUALQUER um aceita um papel, a orientação tem de mencioná-lo.
  ".claude/utils/co-evolution/co-relay.sh+.claude/utils/co-evolution/co-deliver.sh|.claude/commands/meta/co-evolve.md"
)
_ROLES="source adopted hub standalone"
divergences=0; judged=0; unjudgeable=0
for par in "${PAIRS[@]}"; do
  helper="${par%%|*}"; doc="${par##*|}"
  # `a+b` = UNIÃO de helpers (um doc de orientação que descreve mais de um script).
  helper_list="${helper//+/ }"
  for _h in ${helper_list}; do [ -f "${_h}" ] || { helper_list=""; break; }; done
  [ -n "${helper_list}" ] || continue
  [ -f "${doc}" ]        || continue
  judged=$((judged+1))
  # Papéis que o helper ACEITA: só das lines de decisão de papel (case/grep sobre role), nunca de
  # prosa de comentário — senão o próprio comentário desta guarda se contaria como aceitação.
  accepted=""
  # A extração lê SÓ linhas de DECISÃO de papel (um `case` alternando papéis, ou um `grep -qE` sobre
  # `role:`), nunca comentário — senão o próprio cabeçalho desta guarda, que cita os quatro papéis em
  # prosa, se contaria como aceitação e ela passaria verde por se auto-satisfazer.
  lines="$(for _h in ${helper_list}; do
             grep -hE '^[[:space:]]*(adopted|hub|standalone|source)[|)]' "${_h}" 2>/dev/null || true
             # `grep -v '^[[:space:]]*#'` PRIMEIRO: sem ele, `# role: (adopted|hub|standalone)` num
             # comentário contava como aceitação — e isso não é hipotético, o `co-relay.sh` REAL tem
             # essa linha em comentário (l.87). Medido: estreitando o `case` de verdade para
             # `adopted)`, a guarda continuava exigindo `hub` na prosa, sustentada só pelo comentário.
             # Era prosa comparada contra prosa, com o cabeçalho desta guarda afirmando o contrário.
             grep -v '^[[:space:]]*#' "${_h}" 2>/dev/null \
               | grep -hE "role:[^#]*\((adopted|hub|standalone|source)(\|[a-z]+)*\)" 2>/dev/null || true
           done)"
  for r in ${_ROLES}; do
    # Alternância EXPLÍCITA em vez da classe `[|(^[:space:]]` da 1ª versão: ali o `^` era literal
    # (não-primeiro na classe) e ninguém que leia rápido acerta o que ela casa. Regex que o autor não
    # consegue ler é regex que ninguém revisa.
    if LC_ALL=C grep -qE "(^|\||\(|[[:space:]])${r}(\||\)|[[:space:]]|$)" <<< "${lines}"; then
      accepted="${accepted}${r} "
    fi
  done
  if [ -z "${accepted// /}" ]; then
    # ⚠️ Isto é rc 3 (NÃO PUDE JULGAR), não rc 1 (divergência) — e a 1ª versão contava como
    # divergência enquanto o cabeçalho DECLARAVA um rc 3 que nenhum caminho alcançava. Guarda que
    # promete um código de saída e nunca o emite é a mesma classe de declarado≠verificado que ela
    # existe para caçar; e a diferença é consequente, porque o lint reage diferente aos dois.
    echo "REGRA 90: NAO PUDE JULGAR ${helper} — nenhuma decisao de papel reconhecida (o formato do \`case\` mudou?); paridade NAO medida para ${doc}"
    unjudgeable=$((unjudgeable+1))
    continue
  fi
  missing=""
  for r in ${accepted}; do
    # ⚠️ FRONTEIRA DE PALAVRA, e não substring. A 1ª versão usava `grep -qiF -- "hub"`, que casa
    # DENTRO de `GitHub` — medido por passada adversarial: uma prosa sem o papel `hub` mas com
    # "Abra o PR no GitHub" satisfazia a guarda. `source` casava dentro de "open source". Ou seja: a
    # regra escrita para matar o silêncio sobre `hub` ficava silenciosa por causa da palavra mais
    # provável de aparecer num comando de co-evolução. Estava viva por sorte, não por desenho.
    # CONTEXTO DE PAPEL, não só fronteira de palavra — e a diferença foi medida, não imaginada.
    # A 1ª versão usava `grep -qiF` (substring): `hub` casava dentro de `GitHub`. A 2ª usou fronteira
    # de palavra e curou `hub`, mas NÃO curou `source`: em "projeto open source", `source` É palavra
    # com fronteira, então uma prosa que nunca fala do papel `source` continuava satisfazendo a
    # guarda. Fronteira de palavra resolve colisão de SUBSTRING; não resolve HOMONÍMIA.
    # O que separa o papel do homônimo é o CONTEXTO em que a prosa real escreve papel — sempre em
    # crase (\`hub\`, \`role: adopted\`) ou na mesma linha da palavra `role`. É isso que se exige.
    # Conferido contra os três documentos de produção: os três passam.
    # SÓ EM CRASE, e a restrição é fruto de duas medições, não de gosto:
    #   1ª versão `grep -qiF` (substring): `hub` casava dentro de `GitHub`.
    #   2ª versão fronteira de palavra: curou `hub`, NÃO curou `source` — "projeto open source" tem
    #      `source` com fronteira dos dois lados.
    #   3ª versão aceitava também "papel na mesma linha que a palavra `role`": a MESMA linha que diz
    #      `role: adopted` também dizia "open source", então a homonímia voltou pela terceira porta.
    # O que separa o papel do homônimo é a NOTAÇÃO: nesta casa papel se escreve em crase
    # (\`hub\`, \`role: adopted\`, \`standalone\`), e prosa corrida não. Exigir crase é exigir que o
    # documento fale do papel COMO papel. Conferido: os três documentos de produção passam.
    # Custo declarado: uma prosa que mencione o papel sem crase é acusada — falso positivo que se
    # resolve pondo a crase, e que empurra na direção certa. Fail-closed é o lado a errar aqui.
    LC_ALL=C grep -qiE "\`[^\`]*(^|[^a-z])${r}([^a-z][^\`]*)?\`" "${doc}" \
      || missing="${missing}${r} "
  done
  if [ -n "${missing// /}" ]; then
    echo "REGRA 90: ${doc} nao menciona papel(is) que ${helper} ACEITA: ${missing}— a sessao le a prosa primeiro e o script nunca, entao prosa estreita faz o agente recusar o que a maquina permite (ocorreu 2026-09-25 com \`hub\`; o inverso ocorreu 2026-09-17)"
    divergences=$((divergences+1))
  fi
done
[ "${judged}" -gt 0 ] || { echo "REGRA 90: nenhum par helper/comando presente (adotante sem co-evolucao?) — SEM OBJETO"; exit 0; }
# Ordem deliberada: divergência REAL tem precedência sobre "não pude julgar". Um par medido e
# divergente é achado acionável; degradá-lo a rc 3 por causa de OUTRO par ilegível esconderia o que
# se sabe atrás do que não se sabe.
[ "${divergences}" -gt 0 ] && exit 1
[ "${unjudgeable}" -gt 0 ] && exit 3
exit 0
