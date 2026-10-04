#!/usr/bin/env bash
# injected-cut-check.sh — REGRA 96: diretiva de contexto INJETADO não corta listagem em silêncio.
#
# ── O DEFEITO, MEDIDO E DATADO (cláusula 1 da guard-doctrine) ──────────────────────────────────
# 2026-10-03, três sítios no mesmo dia, e um deles foi pago em afirmação falsa selada:
#   · `.claude/commands/meta/forge.md` injetava `forge-census --markdown`, cuja projeção cortava
#     12 de 59 candidatos EM SILÊNCIO. Uma sessão leu a projeção, não viu o `/meta:evolve` nela, e
#     selou numa migalha que ele tinha "0 de 7 peças, ausente do censo inteiro". O `--tsv` dizia
#     2/7, empatado com 12 outros, com 37 ABAIXO dele. Ausência-por-CORTE é indistinguível de
#     ausência-por-ZERO — e o leitor concluiu zero, que é a conclusão errada.
#   · `.claude/skills/onion-research/SKILL.md` injetava `kg-corpus-grep … | head -40` sobre 298
#     achados: 259 caíam sem uma palavra, e a sessão lia "o corpus sabe estas 39 coisas".
#   · `.claude/commands/meta/kg.md` prometia "FILA COMPLETA / CORPUS INTEIRO" antes de `head -20`
#     sobre ~312 itens abertos — promessa explícita de completude com corte literal.
# Os três curados na mesma leva; o selo do maestro para guardar a CLASSE veio em 2026-10-04, depois
# de o passivo ser MEDIDO EM ZERO. Guarda que nasce em zero não precisa de catraca e não tolera
# dívida: o próximo corte entra REPROVANDO em vez de entrar num baseline.
#
# ── POR QUE A SUPERFÍCIE INJETADA, e não todo `head` do repo ───────────────────────────────────
# A diretiva de injeção é executada pelo HARNESS na carga e o resultado vira CONTEXTO. A sessão lê
# aquilo como se fosse o conjunto — não há rolagem, não há "ver mais", não há pergunta a fazer. Um
# `head -N` ali não é formatação: é uma afirmação implícita de completude, e ela é falsa. Fora da
# injeção (num passo de procedimento que a sessão roda e vê rodar) o corte é visível e negociável.
#
# ── TETO DECLARADO (cláusula 7) ────────────────────────────────────────────────────────────────
#  · Mede a FORMA do corte na diretiva, não se o comando por trás corta por conta própria. Um
#    script que trunca internamente passa por aqui — foi exatamente o caso do `forge-census`, e a
#    cura dele foi outra (declarar o próprio corte). Esta guarda pega o corte NO PIPELINE.
#  · Não sabe se o total é declarado numa linha vizinha em prosa. Prosa não é mecanismo, e o
#    caminho certo é o cortador contar antes de cortar (`--top N`, `FORGE_CENSUS_TOP`).
#  · ⚠️ `N<=2` É ISENTO POR **SINTAXE**, e a 1ª redação deste teto afirmava o oposto ("por
#    propósito, nunca por sintaxe") — era FALSO, e o Elenxo provou com o pior caso possível: no
#    MESMO cortador do dano de 2026-10-03, `kg-corpus-grep … | head -1` apaga **297 de 298**
#    achados e passa CALADO, enquanto `| head -3` sobre o mesmo corpus reprova. Propósito idêntico,
#    veredito oposto, decidido pelo DÍGITO. O mecanismo não tem como saber se o que entra no pipe
#    é um valor único ou uma listagem — isso exige conhecer o produtor. O buraco fica DECLARADO em
#    vez de disfarçado: `head -1`/`head -2` passam, e é dívida aceita para não vetar
#    `claude --version | head -1`, que existe em 2 sítios legítimos. Fechá-lo exige um
#    discriminante do PRODUTOR (allowlist de comandos de valor único), e isso é leva própria.
#  · **Só o corte com `|`, com crase, ou precedido de espaço** é visto. Corte dentro de uma
#    substituição de comando aninhada, ou montado em variável, escapa.
#  · **Só diretiva de UMA LINHA.** Diretiva multi-linha não é julgada — e não foi medido se o
#    harness do Claude Code sequer a executa (lacuna declarada, não resolvida).
#  · **`head -c N`** (corte por BYTES) não é cobrado: é questão de doutrina se pertence à classe.
#  · O **pathspec** é `.claude/commands/**` + `.claude/skills/**`. Medido pelo Elenxo: há diretiva
#    VIVA com corte em `plugins/onion/skills/onion/SKILL.md` (o que os adotantes INSTALAM) e
#    **60 arquivos** em `.claude/agents/**` que o harness carrega e esta guarda não varre.
#  · Busca é LEXICAL. Um corte escrito por um alias, uma função ou um python inline não é visto.
set -euo pipefail

SELFTEST=0; FORMAT=human; ROOT=""
while [ "$#" -gt 0 ]; do case "$1" in
  --selftest) SELFTEST=1 ;;
  --format)   shift; FORMAT="${1:-human}" ;;
  --tsv)      FORMAT=tsv ;;
  -h|--help)  sed -n '2,4p' "$0"; exit 0 ;;
  # ⚠️ `${1:-.}` engolindo flag como caminho foi defeito REAL do molde (`consumed-mode-check.sh`,
  #    comentado na l.67 dele): `cd --selftest` dava "repo_root invalido". Caminho só se não-flag.
  --*)        printf 'injected-cut-check: flag desconhecida: %s\n' "$1" >&2; exit 2 ;;
  *)          ROOT="$1" ;;
esac; shift; done
ROOT="${ROOT:-.}"
REPO="$(cd "${ROOT}" 2>/dev/null && pwd)" || { printf 'injected-cut-check: repo_root inválido: %s\n' "${ROOT}" >&2; exit 2; }

# ── O PREDICADO ───────────────────────────────────────────────────────────────────────────────
# ⚠️ O RISCO AQUI É O VOCABULÁRIO, não a lógica — três guardas de lista desta casa caíram por isso
#    num único dia ([[guarda-por-lista-falha-pelo-vocabulario]]). Por isso as SEIS formas de
#    truncar entram, e as duas piores são as que não têm número: `| head` e `| tail` nus cortam em
#    10 por default, e não há número nenhum para o leitor estranhar.
# ⚠️ A CRASE VIVE NUMA VARIAVEL, e isso nao e estilo: crase dentro de ASPAS DUPLAS abre
#    substituicao de comando e come o resto do arquivo — foi `syntax error: unexpected end of file`
#    na l.273 ao aplicar a cura do Elenxo, e a MESMA classe me pegou no `echo` do terminal no mesmo
#    minuto. Padrao que precisa casar crase usa `${_BT}`, nunca a crase literal entre aspas duplas.
_BT='`'
_cuts_in() {   # $1 = o texto da diretiva; imprime o corte achado, ou nada
  local d="$1"
  # ⚠️ `# top-N` ISENTA, e e ESCOLHA DE DESENHO contra heuristica (FP-6 do Elenxo). Ha cortes em
  #    que o corte E A PERGUNTA — "os 5 commits mais recentes", "os 10 de maior atencao" — e nao
  #    existe total a declarar. A tentacao e adivinhar pelo pipeline (tem `sort`? tem `git log`?),
  #    e isso REPROVA: `forge-census | sort | head -12` seria isentado, e esse e exatamente o dano
  #    de 2026-10-03. Entao o autor DECLARA, com uma palavra audidavel no diff, e a guarda para de
  #    adivinhar. Quem escreve `# top-N` sobre uma projecao de conjunto esta mentindo por escrito,
  #    que e outra classe de problema e tem outro remedio.
  case "${d}" in *'# top-N'*|*'# top-n'*) return 1 ;; esac
  # ⚠️ COMENTARIO DENTRO DA DIRETIVA NAO CORTA NADA (FP-5 do Elenxo): `!`censo.sh --tsv  # antes
  #    era | head -40, curado`` era vetado, isto e, registrar a cura na propria diretiva ficava
  #    proibido. O ` #` descarta o resto, como o shell faz.
  d="${d%% #*}"
  # ⚠️ E O PADRAO ENTRE ASPAS E DADO, NAO PIPELINE (FP-3/FP-4): a diretiva que AUDITA cortes —
  #    `grep -rc "| head -40" .claude/` — era acusada de cortar. Ela e exatamente a diretiva
  #    natural para medir o passivo desta regra, e a guarda a proibia. Remove o conteudo entre
  #    aspas antes de julgar o pipeline.
  #    ⚠️ SO ASPAS DUPLAS, e isto nasceu de CONFLITO ENTRE DUAS CURAS MINHAS: a 1a redacao
  #    esvaziava tambem o conteudo entre aspas SIMPLES, e com isso comia o argumento legitimo do
  #    `sed -n '1,40p'` — o caso (a) do sed passou a reprovar enquanto o padrao, sondado isolado,
  #    casava. Duas curas certas que se anulam e pior que uma errada, porque o sintoma aponta para
  #    o lugar errado. BURACO DECLARADO: um padrao-de-corte citado entre aspas SIMPLES dentro de
  #    uma diretiva segue sendo acusado. A crase dupla e isenta por ESTE varredor antes de chegar
  #    aqui — mas o harness a EXECUTA, e a REGRA 98 acusa (nao e forma de citar).
  d="$(printf '%s' "${d}" | sed 's/"[^"]*"/""/g')"
  # ⚠️ `\|?` E NAO `\|`: o pipe deixou de ser OBRIGATORIO porque `!`head -40 censo.tsv`` — a forma
  #    mais curta e natural de uma diretiva — era INVISIVEL (FN-B do Elenxo, o pior do grupo), e
  #    `sed -n '1,40p' arquivo` sem pipe e a redacao USUAL, logo a cobertura da 6a forma era falsa.
  printf '%s' "${d}" | grep -oE '(\||`| )(head|tail) +-n ?([3-9]|[0-9]{2,})\b' | head -1 && return 0
  printf '%s' "${d}" | grep -oE '(\||`| )(head|tail) +-([3-9]|[0-9]{2,})\b'    | head -1 && return 0
  # a MESMA ferramenta, sintaxe GNU trivial, que escapava: `-n40` junto e `--lines=40`
  printf '%s' "${d}" | grep -oE '(\||`| )(head|tail) +-n([3-9]|[0-9]{2,})\b'   | head -1 && return 0
  printf '%s' "${d}" | grep -oE '(\||`| )(head|tail) +--lines=([3-9]|[0-9]{2,})' | head -1 && return 0
  # outras ferramentas que truncam listagem, e nenhuma delas estava no teto
  printf '%s' "${d}" | grep -oE "awk +'NR ?<=? ?([3-9]|[0-9]{2,})"                | head -1 && return 0
  printf '%s' "${d}" | grep -oE 'grep +-m ?([3-9]|[0-9]{2,})\b'                   | head -1 && return 0
  printf '%s' "${d}" | grep -oE 'sed +([3-9]|[0-9]{2,})q\b'                       | head -1 && return 0
  # a aspa de FECHAMENTO entra no padrao: sem ela o fragmento sai truncado (`sed -n '1,40p`) e a
  # mensagem do veto mostra um comando que nao existe — e foi o unico caso que reprovou na 1a
  # execucao deste selftest, pelo lado da ASSERCAO, nao da deteccao.
  printf '%s' "${d}" | grep -oE "(\||${_BT}| )sed +-n +'?[0-9]+,([3-9]|[0-9]{2,})p'?" | head -1 && return 0
  # `head`/`tail` sem número: seguido de fim-de-diretiva, de outro pipe, ou de redirecionamento
  # ⚠️ HERE-STRING, NAO PIPE: `printf | grep -q` e a classe EPIPE do early-closer que esta casa ja
  #    mediu — o leitor fecha na 1a casada, o escritor toma EPIPE, e sob `pipefail` o veredito
  #    REPROVA com o padrao PRESENTE. A bancada (catraca `shell-pipefail`) pegou este sitio como
  #    NOVO acima da catraca, o que e o unico jeito honesto de descobrir: o defeito e uma CORRIDA
  #    e so aparece sob carga ou em maquina de poucos nucleos.
  grep -qE '(\||`| )(head|tail) *(`|\||>|$)' <<< "${d}" && { printf '| head/tail SEM numero (corta em 10)'; return 0; }
  return 1
}

_scan() {   # emite uma linha TSV por achado: path<TAB>linha<TAB>corte
  local f n line dir cut
  while IFS= read -r f; do
    [ -f "${REPO}/${f}" ] || continue
    # ⚠️ O FAIL-LOUD SAI POR STDOUT EM TSV, e nao so por stderr+exit 2 (Achado A do Elenxo, de 1a
    #    classe): o dispatcher invoca `… --tsv 2>/dev/null || true`, logo o stderr era DESCARTADO e
    #    o rc APAGADO — arquivo ilegivel dava ZERO violacoes e o lint seguia. Eu escrevi o
    #    fail-loud, provei no CLI, mutei contra ele, e o CONSUMIDOR o anulava: em producao a guarda
    #    ja era fail-open nesse caminho. Guarda so e fail-closed no canal que o consumidor LE.
    # ⚠️ SENTINELA, NAO `exit` AQUI: `_scan` roda DENTRO de `$( )`, onde `exit 2` encerra apenas o
    #    SUBSHELL — o rc morre no `|| true` do chamador e o TSV do fail-loud vira TEXTO na variavel,
    #    reprocessado como se fosse um achado (com os campos trocados). Medido pelo caso (e) na 1a
    #    execucao da cura: rc=2 com saida VAZIA. Quem imprime e sai e o CHAMADOR, fora da captura.
    [ -r "${REPO}/${f}" ] || { printf '#ILEGIVEL\t%s\n' "${f}"; return 0; }
    n=0; _fence=0
    while IFS= read -r line; do
      n=$((n + 1))
      # ── DIRETIVA VIVA vs DIRETIVA CITADA ────────────────────────────────────────────────────
      # ⚠️ ESTE BLOCO NASCEU DE REPROVACAO (Elenxo da forja, 2026-10-04), e o achado era FATAL: a
      #    1a versao da guarda PROIBIA DOCUMENTAR A PROPRIA REGRA 96. O refutador acrescentou ao
      #    `/meta:forge-guard` a secao que qualquer autor de doutrina escreveria — um exemplo do
      #    anti-padrao — e o lint REAL foi a `HARD: 1 / FALHOU`. O comando que FORJA guardas nao
      #    podia conter o exemplo do anti-padrao da guarda que ele forja, e a unica saida era
      #    `--no-verify`. E a clausula 4 (falso positivo treina a sessao a ignorar o veto)
      #    realizada contra o proprio artefato — a pior falha possivel para uma guarda.
      #    Tres formas de CITAR do ponto de vista DESTA regra (o corte), e todas antes vetadas aqui.
      #    ⚠️ Para o HARNESS nenhuma delas e citacao — ele EXECUTA as tres (medido 2026-10-04). Esta
      #    regra as isenta porque a pergunta dela e o corte; a REGRA 98 (Diretiva de injeção escrita
      #    como CITAÇÃO não pode estar VIVA) e quem as acusa por estarem vivas:
      #      (i)  bloco cercado (```), que parece exemplo ao leitor e e EXECUTADO pelo harness;
      #      (ii) inline-code de crase DUPLA, que esta redacao chamava de "a forma canonica de citar
      #           uma diretiva em prosa" — ⚠️ FALSO PARA O HARNESS (medido 2026-10-04): ele NAO
      #           mascara crase dupla nem pula bloco cercado, e EXECUTA o que esta guarda chama de
      #           citado. Esta isencao segue certa para a pergunta DESTA regra (o corte), mas citar
      #           assim roda o comando: a REGRA 98 (Diretiva de injeção escrita como CITAÇÃO não pode
      #           estar VIVA) acusa. Descreva a forma, nunca a escreva;
      #      (iii) comentario DENTRO da diretiva (`# antes era | head -40, curado em …`), onde o
      #           corte nao corta nada: registrar a cura ficava vetado.
      case "${line}" in '```'*) _fence=$((1 - _fence)); continue ;; esac
      [ "${_fence}" -eq 0 ] || continue
      case "${line}" in *'!`'*) : ;; *) continue ;; esac
      # crase DUPLA na linha: esta regra nao julga o corte ali. NAO e verdade que "a diretiva viva
      # nunca e escrita assim" (redacao anterior): o harness a executa, e a REGRA 98 acusa
      case "${line}" in *'``'*) continue ;; esac
      # pode haver mais de uma diretiva na linha; julga cada uma
      while IFS= read -r dir; do
        [ -n "${dir}" ] || continue
        if cut="$(_cuts_in "${dir}")" && [ -n "${cut}" ]; then
          printf '%s\t%s\t%s\n' "${f}" "${n}" "${cut}"
        fi
      done < <(printf '%s' "${line}" | grep -oE '!`[^`]*`' || true)
    done < "${REPO}/${f}"
  done < <(cd "${REPO}" && git ls-files '.claude/commands/*.md' '.claude/commands/**/*.md' '.claude/skills/**/*.md' 2>/dev/null)
}

# ── --selftest: as DUAS POLARIDADES (cláusula 4) ──────────────────────────────────────────────
if [ "${SELFTEST}" = "1" ]; then
  _p=0; _f=0
  _ok()  { _p=$((_p+1)); printf '  ✓ injected-cut: %s\n' "$1"; }
  _bad() { _f=$((_f+1)); printf '  ✗ injected-cut: %s — %s\n' "$1" "$2"; }

  # (a) ACUSA as seis formas de truncar, VERBATIM como apareceram no dano de 2026-10-03.
  #     A forma `head -40` é a do sítio real (onion-research/SKILL.md); as outras são o vocabulário.
  for _case in 'head -40:head -40' 'head -n 40:head -n 40' 'tail -20:tail -20' \
               'tail -n 20:tail -n 20' "sed -n '1,40p':sed -n '1,40p'" 'head:SEM numero'; do
    _frag="${_case%%:*}"; _want="${_case##*:}"
    _got="$(_cuts_in '!`bash algo.sh | '"${_frag}"'`' || true)"
    case "${_got}" in *"${_want}"*) _ok "(a) acusa \`${_frag}\`" ;;
      *) _bad "(a) \`${_frag}\`" "nao foi detectado (devolveu: [${_got}])" ;; esac
  done

  # (b) CALA no caso honesto — e este é o caso que impede a guarda de treinar a sessão a ignorá-la.
  #     `head -1`/`head -2` são extração de valor único: ali o corte É o dado, não uma projeção.
  #     Esta é a isenção POR PROPÓSITO, e sem ela a guarda acusaria `claude --version | head -1`,
  #     que existe em 2 sítios legítimos hoje.
  for _honesto in 'head -1' 'head -2' 'head -n 1' 'head -n 2'; do
    if _cuts_in '!`claude --version | '"${_honesto}"'`' >/dev/null 2>&1; then
      _bad "(b) \`${_honesto}\`" "acusou extracao de valor unico — falso positivo treina a sessao a ignorar o veto"
    else _ok "(b) cala em \`${_honesto}\` (extracao de valor unico)"; fi
  done

  # (c) CALA fora da diretiva de injeção: um `head -40` num bloco de procedimento que a sessão roda
  #     e VÊ rodar não é a classe — o corte ali é visível e negociável. Sem este caso a guarda
  #     cobraria todo snippet de documentação do repo.
  _tmpd="$(mktemp -d)"; mkdir -p "${_tmpd}/.claude/commands/meta"
  # ⚠️ O SANDBOX CARREGA UMA DIRETIVA LEGITIMA DE PROPOSITO: sem ela `_DIRS` e 0, a guarda de
  #    VACUIDADE dispara ANTES do varredor, e o caso passa sem nunca julgar o bloco de
  #    procedimento — incapaz de reprovar o que afirma reprovar. Descoberto por mutante (remover o
  #    filtro de diretiva nao fazia este caso cair), e e a classe "caso verde pelo motivo errado".
  # ⚠️ A DIRETIVA MORA DENTRO DA CERCA, e isso e o cenario REAL do FP-1: documentacao que MOSTRA
  #    o anti-padrao como diretiva. A 1a redacao punha um comando NU na cerca, e ai o filtro de
  #    diretiva ja o descartava — dois mecanismos cobrindo o mesmo caso, logo NENHUM mutante
  #    isolado podia falsifica-lo (M4 e M9 nao morderam). Caso que dois mecanismos protegem nao
  #    fixa nenhum dos dois; cada mecanismo precisa do seu caso.
  printf '# doc\n\n**V:** !`echo ok`\n\n```markdown\n**X:** !`bash algo.sh | head -40`\n```\n' > "${_tmpd}/.claude/commands/meta/zz.md"
  ( cd "${_tmpd}" && git init -q . && git add -A ) >/dev/null 2>&1
  _out="$(REPO="${_tmpd}" bash "$0" "${_tmpd}" --tsv 2>&1 || true)"
  if grep -q 'zz.md' <<< "${_out}"; then
    _bad '(c) bloco de procedimento' "acusou corte FORA de diretiva injetada: [${_out}]"
  else _ok '(c) cala em diretiva DENTRO de bloco cercado (documentacao do anti-padrao)'; fi

  # (d) ACUSA o mesmo corte DENTRO da diretiva, no mesmo sandbox — é o PAR de (c), e sem ele (c)
  #     provaria o nada (um parser morto cala em tudo).
  printf '# doc\n\n**V:** !`echo ok`\n\n**X:** !`bash algo.sh | head -40`\n' > "${_tmpd}/.claude/commands/meta/zz.md"
  ( cd "${_tmpd}" && git add -A ) >/dev/null 2>&1
  _out="$(bash "$0" "${_tmpd}" --tsv 2>&1 || true)"
  if grep -q 'zz.md' <<< "${_out}" && grep -q 'head -40' <<< "${_out}"; then
    _ok '(d) acusa o MESMO corte dentro da diretiva (o par de (c), contra parser morto)'
  else _bad '(d) par de (c)' "nao acusou dentro da diretiva: [${_out}]"; fi
  rm -rf "${_tmpd}"

  # (e) FAIL-LOUD: fonte ilegível é exit 2, nunca "nenhum corte encontrado". Guarda que não lê e
  #     diz OK é pior que guarda nenhuma — a lição do kg-trace-resolve, citada no molde.
  _tmpd2="$(mktemp -d)"; mkdir -p "${_tmpd2}/.claude/commands/meta"
  printf '**X:** !`algo | head -40`\n' > "${_tmpd2}/.claude/commands/meta/zz.md"
  ( cd "${_tmpd2}" && git init -q . && git add -A ) >/dev/null 2>&1
  chmod 000 "${_tmpd2}/.claude/commands/meta/zz.md"
  _rc=0; _out="$(bash "$0" "${_tmpd2}" --tsv 2>&1)" || _rc=$?
  chmod 644 "${_tmpd2}/.claude/commands/meta/zz.md" 2>/dev/null || true
  # cobra o CANAL, nao so o rc: o dispatcher descarta stderr, logo o fail-loud tem de estar no TSV
  if [ "${_rc}" -eq 2 ] && grep -q 'ILEGIVEL' <<< "${_out}" && grep -q '^HARD	ILEGIVEL	' <<< "${_out}"; then
    _ok '(e) fonte ilegivel -> exit 2 nomeando o arquivo (fail-loud, nunca aprovacao)'
  elif [ "$(id -u)" = "0" ]; then
    printf '  ⊘ injected-cut: (e) NAO VERIFICADO — rodando como root, chmod 000 nao barra leitura\n'
  else _bad '(e) fail-loud' "rc=${_rc}; saida=[${_out}]"; fi
  rm -rf "${_tmpd2}"

  # (f) VACUIDADE: repo SEM nenhuma diretiva de injecao nao e "limpo", e o varredor cego. Este caso
  #     nasceu de um MUTANTE: ao apagar a guarda de vacuidade, nenhum caso reprovou — a protecao
  #     existia e nao era exercitada, que e a definicao de guarda meio-morta. O mutante fez o
  #     trabalho que o olho nao faz.
  _tmpd3="$(mktemp -d)"; mkdir -p "${_tmpd3}/.claude/commands/meta"
  printf '# doc sem diretiva nenhuma\n' > "${_tmpd3}/.claude/commands/meta/zz.md"
  ( cd "${_tmpd3}" && git init -q . && git add -A ) >/dev/null 2>&1
  _rc=0; _out="$(bash "$0" "${_tmpd3}" --tsv 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 1 ] && grep -q 'VACUIDADE' <<< "${_out}"; then
    _ok '(f) repo sem diretiva -> VACUIDADE, exit 1 (varredor cego nunca vira aprovacao)'
  else _bad '(f) vacuidade' "rc=${_rc}; saida=[${_out}]"; fi
  rm -rf "${_tmpd3}"

  # (g) O MARCADOR `# top-N` isenta, e o PAR prova que ele nao e desculpa universal: o MESMO
  #     corte SEM o marcador segue acusado. Sem o par, o marcador poderia estar desligando a
  #     guarda inteira e ninguem veria.
  if _cuts_in '!`git log --oneline | head -5  # top-N`' >/dev/null 2>&1; then
    _bad '(g) marcador top-N' 'acusou um corte DECLARADO como top-N'
  elif _cuts_in '!`git log --oneline | head -5`' >/dev/null 2>&1; then
    _ok '(g) `# top-N` isenta, e o MESMO corte sem o marcador segue acusado (o par)'
  else
    _bad '(g) par do marcador' 'o corte SEM marcador tambem calou — o marcador desligou a guarda'
  fi

  # (h) CRASE DUPLA isenta — e este e o caso do achado FATAL (FP-1 do Elenxo): a guarda PROIBIA
  #     documentar a propria REGRA 96, porque citar uma diretiva em prosa usa crase dupla e ela
  #     era lida como diretiva viva. O lint real ia a HARD:1/FALHOU sobre uma linha de doutrina,
  #     e a unica saida era --no-verify. O PAR (sem a crase dupla, acusa) impede que a isencao
  #     tenha desligado a guarda.
  _tmpd4="$(mktemp -d)"; mkdir -p "${_tmpd4}/.claude/commands/meta"
  printf '# doc\n\n**V:** !`echo ok`\n\nEm prosa: `` !`bash x.sh | head -40` `` marca citacao.\n' > "${_tmpd4}/.claude/commands/meta/zz.md"
  ( cd "${_tmpd4}" && git init -q . && git add -A ) >/dev/null 2>&1
  _o4="$(bash "$0" "${_tmpd4}" --tsv 2>&1 || true)"
  printf '# doc\n\n**V:** !`echo ok`\n\nViva: !`bash x.sh | head -40`\n' > "${_tmpd4}/.claude/commands/meta/zz.md"
  ( cd "${_tmpd4}" && git add -A ) >/dev/null 2>&1
  _o4b="$(bash "$0" "${_tmpd4}" --tsv 2>&1 || true)"
  if [ -z "${_o4}" ] && grep -q 'head -40' <<< "${_o4b}"; then
    _ok '(h) crase DUPLA isenta a citacao, e a MESMA diretiva viva e acusada (o par)'
  else _bad '(h) citacao inline' "citada=[${_o4}] viva=[${_o4b}]"; fi
  rm -rf "${_tmpd4}"

  # (i) PADRAO ENTRE ASPAS e DADO, nao pipeline (FP-3/FP-4): a diretiva que AUDITA cortes era
  #     acusada de cortar — e ela e justamente a diretiva natural para medir o passivo desta
  #     regra. O PAR garante que esvaziar aspas nao cegou o varredor.
  _tmpd5="$(mktemp -d)"; mkdir -p "${_tmpd5}/.claude/commands/meta"
  printf '# doc\n\n**V:** !`echo ok`\n\n**A:** !`grep -rc "| head -40" .claude/`\n' > "${_tmpd5}/.claude/commands/meta/zz.md"
  ( cd "${_tmpd5}" && git init -q . && git add -A ) >/dev/null 2>&1
  _o5="$(bash "$0" "${_tmpd5}" --tsv 2>&1 || true)"
  printf '# doc\n\n**V:** !`echo ok`\n\n**A:** !`grep -rc algo .claude/ | head -40`\n' > "${_tmpd5}/.claude/commands/meta/zz.md"
  ( cd "${_tmpd5}" && git add -A ) >/dev/null 2>&1
  _o5b="$(bash "$0" "${_tmpd5}" --tsv 2>&1 || true)"
  if [ -z "${_o5}" ] && grep -q 'head -40' <<< "${_o5b}"; then
    _ok '(i) padrao entre aspas e DADO, e o corte REAL fora das aspas e acusado (o par)'
  else _bad '(i) padrao como dado' "dado=[${_o5}] real=[${_o5b}]"; fi
  rm -rf "${_tmpd5}"

  # (j) FILTRO DE DIRETIVA, fixado sozinho: comando NU com corte, FORA de cerca e SEM diretiva —
  #     um passo de procedimento que a sessao roda e VE rodar, onde o corte e visivel e negociavel.
  #     Este caso existe porque o (c) sozinho era protegido por DOIS mecanismos e nao fixava nenhum.
  _tmpd6="$(mktemp -d)"; mkdir -p "${_tmpd6}/.claude/commands/meta"
  printf '# doc\n\n**V:** !`echo ok`\n\nRode: bash algo.sh | head -40 para ver os primeiros.\n' > "${_tmpd6}/.claude/commands/meta/zz.md"
  ( cd "${_tmpd6}" && git init -q . && git add -A ) >/dev/null 2>&1
  _o6="$(bash "$0" "${_tmpd6}" --tsv 2>&1 || true)"
  if [ -z "${_o6}" ]; then
    _ok '(j) cala em comando NU com corte, fora de cerca e sem diretiva (passo de procedimento)'
  else _bad '(j) filtro de diretiva' "acusou comando nu: [${_o6}]"; fi
  rm -rf "${_tmpd6}"

  printf '  injected-cut --selftest: %d passaram, %d falharam\n' "${_p}" "${_f}"
  [ "${_f}" -eq 0 ] || exit 1
  exit 0
fi

# ── produção ──────────────────────────────────────────────────────────────────────────────────
_HITS="$(_scan || true)"

# o fail-loud, decidido FORA da captura — e por isso capaz de encerrar o script de verdade
_ILEG="$(grep '^#ILEGIVEL' <<< "${_HITS}" | cut -f2- || true)"
if [ -n "${_ILEG}" ]; then
  while IFS= read -r _bad_f; do
    [ -n "${_bad_f}" ] || continue
    if [ "${FORMAT}" = tsv ]; then
      printf 'HARD\tILEGIVEL\t%s\tfonte ilegivel: a guarda NAO pode julgar este arquivo (fail-loud por STDOUT, porque o dispatcher descarta stderr e apaga o rc; nunca aprovacao por silencio)\n' "${_bad_f}"
    else
      printf '  ✗ injected-cut-check: ilegível: %s\n' "${_bad_f}" >&2
    fi
  done <<< "${_ILEG}"
  exit 2
fi
_HITS="$(grep -v '^#ILEGIVEL' <<< "${_HITS}" || true)"

# GUARDA DE VACUIDADE — zero diretiva LIDA não é "nenhum corte", é o parser morto. O repo tem
# dezenas de diretivas de injeção; se o varredor não vê nenhuma, ele está cego e cala em tudo.
# ⚠️ `|| true` NO FIM, e isto NAO e ruido defensivo: `xargs grep -l` devolve 123 quando o grep nao
#    casa nada, e sob `set -euo pipefail` isso MATA O SCRIPT — exatamente no caso para o qual a
#    guarda de vacuidade existe. Medido pelo caso (f) na 1a execucao dele (rc=123, saida VAZIA), e
#    a consequencia era pior do que parece: o caso (c) ficava VERDE PELO MOTIVO ERRADO (o script
#    morria, nada era achado, e o caso lia isso como "calou corretamente"). Dois mutantes (M4 e M5)
#    apontavam para "caso decorativo" quando a causa real era esta linha. Guarda inalcancavel e
#    guarda ausente — com o agravante de parecer presente.
_DIRS="$( (cd "${REPO}" && git ls-files '.claude/commands/*.md' '.claude/commands/**/*.md' '.claude/skills/**/*.md' 2>/dev/null | xargs -r grep -l '!`' 2>/dev/null || true) | wc -l )"
if [ "${_DIRS}" -eq 0 ]; then
  if [ "${FORMAT}" = tsv ]; then
    printf 'HARD\tVACUIDADE\t.claude/validation/injected-cut-check.sh\tnenhum arquivo com diretiva de injecao foi encontrado — o varredor esta cego, nao o repo limpo\n'
  else printf '  ✗ VACUIDADE: nenhuma diretiva de injecao encontrada — o varredor esta cego.\n'; fi
  exit 1
fi

if [ -z "${_HITS}" ]; then
  [ "${FORMAT}" = tsv ] || printf '  ✅ REGRA 96: nenhuma diretiva injetada corta listagem em silencio (%s arquivo(s) com diretiva lidos)\n' "${_DIRS}"
  exit 0
fi

while IFS=$'\t' read -r _f _n _cut; do
  [ -n "${_f}" ] || continue
  _msg="l.${_n}: a diretiva injetada corta a listagem (\`${_cut}\`) sem que o cortador declare o total — a sessao le a projecao como se fosse o CONJUNTO, e ausencia-por-corte e indistinguivel de ausencia-por-zero (dano medido 2026-10-03: uma migalha selou \"0 de 7 pecas\" lendo 12 de 59). Corte com um flag que CONTE antes de cortar (\`--top N\` do kg-corpus-grep, \`FORGE_CENSUS_TOP\` do forge-census) ou imprima o total ao lado. N<=2 e extracao de valor unico e nao e cobrado."
  if [ "${FORMAT}" = tsv ]; then printf 'HARD\tREGRA96\t%s\t%s\n' "${_f}" "${_msg}"
  else printf '  ✗ REGRA 96 — %s: %s\n' "${_f}" "${_msg}"; fi
done <<< "${_HITS}"
exit 1
