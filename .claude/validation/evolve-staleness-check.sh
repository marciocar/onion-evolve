#!/usr/bin/env bash
# evolve-staleness-check.sh — REGRA 97: a auto-auditoria do framework tem GATILHO.
#
# ── O DEFEITO, MEDIDO E DATADO (cláusula 1 da guard-doctrine) ──────────────────────────────────
# 2026-10-04: o `/meta:evolve` estava há **66 dias** sem rodar, e a causa NÃO era custo — ele era o
# ÚNICO dos órgãos de auto-evolução **sem gatilho nenhum**:
#   · o radar tem a REGRA 65 (Radar de mundo com baseline DATADA por eixo) — SOFT por eixo vencido;
#   · o `/meta:dissect` tem censo de nível VENCIDO, que re-mede em vez de citar;
#   · o `/meta:kg` tem a REGRA 67 (Grafo de pesquisa com REVISITA carimbada) — SOFT por revisita;
#   · o `/meta:evolve` — nada. E o repo se chama Onion **Evolve**.
# O corpus já media a causa com `impact: 5` e Elenxo sustentada-com-emendas
# (`C_TESE_AUTO_EVOLUCAO`, maestro-vivo-2026-08): *"estamos à frente no PRODUTO do laço e atrás no
# GATILHO dele"*. Uma rodada anterior atribuiu os dias sem evolve a outra causa e o refutador a
# derrubou por **não-sequitur**: o que faltava era o gatilho, não o barateamento.
#
# ── O QUE ESTA GUARDA FAZ DE DIFERENTE DO MOLDE, e é escolha ───────────────────────────────────
# A REGRA 65 lê um `last_run:` que alguém **digita** no `radar-baselines.yaml`. Funciona, e tem um
# modo-de-falha conhecido desta casa: carimbo sem medição. Esta guarda NÃO cria SSOT nova — ela
# deriva de dois fatos que ninguém redige:
#   (1) a DATA do relatório que o próprio `/meta:evolve` produz (`docs/analysis/onion-evolution-*.md`);
#   (2) o DELTA POPULACIONAL desde essa data, medido no **git**, não numa contagem anotada.
# É `behavior-over-declaration` aplicado ao gatilho: confia no que o comando ENTREGOU, não no que
# alguém declarou ter rodado. E corta o drift pela raiz — não há campo para ficar desatualizado.
#
# ── O DESENHO SEGUE O PADRÃO (REGRA 62/65): a máquina DETECTA, o humano DISPARA ────────────────
# SOFT, nunca HARD por idade: auto-auditoria vencida é aviso, não bloqueio de merge. E nunca
# cron/auto-start — W7 é MOAT para o DRIVER que executa. ⚠️ Nota de precisão, porque eu mesmo errei
# nisto em 2026-10-03 e o Elenxo me corrigiu: relógio/cron **não é vedado ao evolve**, que é
# read-only e propõe; o W7 escopa quem EXECUTA. O refutador de 2026-08-31 chamou `schedule`/`loop`
# sobre o evolve de "resposta proporcional". Esta guarda não decide isso — ela avisa, e a escolha
# entre avisar e agendar é do maestro.
#
# ── TETO DECLARADO (cláusula 7) ────────────────────────────────────────────────────────────────
#  · ⚠️ AS DUAS PERNAS NÃO SÃO PEER, e a 1ª redação deste teto afirmava o oposto. Ela dizia que
#    um relatório à mão "engana a perna (1) mas NÃO a (2), e as duas juntas são mais difíceis de
#    simular que qualquer `last_run:`". FALSO, e medido pelo Elenxo em 2026-10-04:
#    `_population_delta "${_LAST}"` CONSOME a saída da perna (1) — corrompa uma e a outra cai.
#    Ele criou um arquivo de outro fluxo e a guarda passou a dizer "auto-auditoria fresca (0d) e
#    sem delta populacional": UM ARQUIVO CALOU AS DUAS. Um `last_run:` digitado NÃO é forjável
#    assim. O glob estrito (`onion-evolution-????-??-??.md`) fecha o caso medido, mas a
#    DEPENDÊNCIA estrutural permanece: a perna (2) é função da (1), e isso fica declarado em vez
#    de vendido como redundância. Pernas de fato independentes exigiriam a (2) medir contra um
#    marco próprio (ex.: o commit que tocou o relatório), e isso é leva própria.
#  · GRANULARIDADE DE DIA: `--since=<data>T00:00:00` não ordena antes/depois DENTRO do dia do
#    relatório, então um relatório escrito hoje às 11h é acusado pelos artefatos commitados hoje
#    às 09h, que ele já cobriu. Preferi errar para o lado de AVISAR num caso de borda de um dia a
#    deixar a perna cega ao dia inteiro, que era o defeito anterior.
#  · Ela não sabe se o relatório tem QUALIDADE, nem se cobriu todas as dimensões. Mede que houve
#    entrega e que o mundo andou desde então.
#  · O delta populacional conta artefato TOCADO, não artefato que PRECISA de auditoria. Um rename
#    em massa infla o número; o aviso diz quantos e manda olhar, não afirma que todos importam.
#  · Sem `git` alcançável, a perna (2) declara NÃO MEDIDA em vez de dizer zero.
#  · Opt-in pela presença de `docs/analysis/` — adotante sem a pasta não recebe a regra pelo gate,
#    e desde 2026-10-04 recebe a bancada com FIXTURE SINTETIZADA DE VERDADE (antes o caso (f)
#    afirmava sobre o repo vivo e fazia o adotante nascer vermelho — era o item deste teto que o
#    Elenxo refutou executando).
#  · ⚠️ `docs/analysis/` é opt-in GENÉRICO DEMAIS: um projeto que tenha a pasta por outro motivo
#    recebe `EVOLVE-SEM-RODADA`. Latente (nenhum adotante local tem a pasta), e a mensagem foi
#    reescrita para não afirmar nada sobre o repo de quem lê.
set -euo pipefail

SELFTEST=0; FORMAT=human; ROOT=""
while [ "$#" -gt 0 ]; do case "$1" in
  --selftest) SELFTEST=1 ;;
  --format)   shift; FORMAT="${1:-human}" ;;
  --tsv)      FORMAT=tsv ;;
  -h|--help)  sed -n '2,4p' "$0"; exit 0 ;;
  --*)        printf 'evolve-staleness-check: flag desconhecida: %s\n' "$1" >&2; exit 2 ;;
  *)          ROOT="$1" ;;
esac; shift; done
ROOT="${ROOT:-.}"
REPO="$(cd "${ROOT}" 2>/dev/null && pwd)" || { printf 'evolve-staleness-check: repo_root inválido: %s\n' "${ROOT}" >&2; exit 2; }

STALE_DAYS="${EVOLVE_STALE_DAYS:-45}"
DELTA_MIN="${EVOLVE_DELTA_MIN:-40}"
ANALYSIS="${EVOLVE_ANALYSIS_DIR:-${REPO}/docs/analysis}"

# ── a DATA do último relatório, derivada do nome e VALIDADA por regex (nunca confiada crua) ────
_last_report() {
  [ -d "${ANALYSIS}" ] || return 1
  # ⚠️ `ls | head -1` NAO: a REGRA 96 (Diretiva de contexto INJETADO nao corta listagem em
  #    silencio) e irma desta, e a licao vale aqui — ordenar e pegar o MAXIMO e diferente de
  #    cortar. `sort -r | head -1` sobre DATAS extraidas e selecao do maximo, nao projecao.
  # ⚠️ GLOB ESTRITO, e isto nasceu do achado que DERRUBOU A TESE desta guarda (Elenxo 2026-10-04):
  #    `onion-evolution-*.md` aceita relatorio de OUTRO FLUXO. Dois ja existem no repo
  #    (`...-adopt-update-hardening-2026-07-17`, `...-kg-sdaal-hardening-2026-07-18`) e sao
  #    TRIAGEM DE INBOX (`type: evolution-backlog`), nao rodadas do evolve. O refutador provou
  #    ponta-a-ponta: criou `onion-evolution-triagem-...-2026-10-04.md` e a guarda passou a dizer
  #    "auto-auditoria fresca (0d) e sem delta populacional". UM ARQUIVO calava AS DUAS PERNAS.
  #    O contrato canonico do comando e `onion-evolution-<YYYY-MM-DD>.md` (evolve.md l.198), e o
  #    glob agora o exige: data ANCORADA no fim, nada entre o prefixo e ela.
  local f d best=""
  for f in "${ANALYSIS}"/onion-evolution-????-??-??.md; do
    [ -f "${f}" ] || continue
    d="$(basename "${f}" .md)"; d="${d#onion-evolution-}"
    grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' <<< "${d}" || continue
    [ "${d}" \> "${best}" ] && best="${d}"
  done
  [ -n "${best}" ] || return 1
  printf '%s' "${best}"
}

# portabilidade do molde da REGRA 65: GNU date -d -> BSD date -j -> awk/mktime
_epoch_of() {
  LC_ALL=C date -d "$1" +%s 2>/dev/null \
    || LC_ALL=C date -j -f '%Y-%m-%d' "$1" +%s 2>/dev/null \
    || awk -v d="$1" 'BEGIN{split(d,a,"-"); print mktime(a[1]" "a[2]" "a[3]" 12 0 0")}' 2>/dev/null \
    || echo 0
}

# ── perna (2): o DELTA POPULACIONAL desde a data, medido no GIT ────────────────────────────────
_population_delta() {   # $1 = data ISO; imprime N ou a palavra NAO-MEDIDO
  local since="$1" n
  command -v git >/dev/null 2>&1 || { printf 'NAO-MEDIDO'; return 0; }
  ( cd "${REPO}" && git rev-parse --git-dir >/dev/null 2>&1 ) || { printf 'NAO-MEDIDO'; return 0; }
  # ⚠️ `T00:00:00` E OBRIGATORIO: `--since=2026-10-04` significa "essa data NA HORA ATUAL DO
  #    RELOGIO", nao "o inicio do dia" — medido pelo Elenxo: `--since=2026-10-04` devolvia 0 e
  #    `--since=2026-10-04T00:00:00` devolvia 5, com os 5 confirmados contando `%ct` a mao. Sem
  #    isto a perna 2 e CEGA ao dia do relatorio, e o numero de manchete que eu publiquei (289)
  #    estava errado: o correto e 291.
  n="$( (cd "${REPO}" && git log --since="${since}T00:00:00" --name-only --pretty=format: -- \
        '.claude/commands' '.claude/agents' '.claude/skills' '.claude/hooks' '.claude/validation' 2>/dev/null \
        | grep -E '\.(md|sh)$' | sort -u | grep -c . ) || true )"
  printf '%s' "${n:-0}"
}

_emit() {   # $1=sev $2=code $3=msg
  if [ "${FORMAT}" = tsv ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "docs/analysis" "$3"
  else printf '  %s %s — %s\n' "$([ "$1" = HARD ] && printf '✗' || printf '⚠')" "$2" "$3"; fi
}

# ── --selftest: as DUAS POLARIDADES (cláusula 4) ──────────────────────────────────────────────
if [ "${SELFTEST}" = "1" ]; then
  # ⚠️ `$0` RESOLVIDO EM ABSOLUTO ANTES DE QUALQUER `cd`: os casos entram em sandbox com `cd`, e
  #    `$0` chega relativo (`.claude/validation/...`) — ali ele deixa de existir e o caso falha com
  #    "No such file or directory", nao com o veredito. E preciso ser o MESMO arquivo em teste
  #    (nunca o caminho canonico do repo, que foi o defeito que o Elenxo achou no caso (g)): o
  #    absoluto preserva as duas coisas.
  SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  _p=0; _f=0
  _ok()  { _p=$((_p+1)); printf '  ✓ evolve-staleness: %s\n' "$1"; }
  _bad() { _f=$((_f+1)); printf '  ✗ evolve-staleness: %s — %s\n' "$1" "$2"; }
  _sandbox() {   # $1=data do relatorio (vazio = nenhum relatorio)
    local d; d="$(mktemp -d)"; mkdir -p "${d}/docs/analysis" "${d}/.claude/commands/meta"
    [ -n "${1:-}" ] && printf '# relatorio\n' > "${d}/docs/analysis/onion-evolution-$1.md"
    printf '%s' "${d}"
  }

  # (a) ACUSA a idade VERBATIM como ela apareceu no dano: relatorio de 2026-07-30, hoje vencido.
  _d="$(_sandbox 2026-07-30)"
  _o="$(EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1 || true)"
  if grep -q 'EVOLVE-VENCIDO' <<< "${_o}" && grep -qE '[0-9]+d > 45d' <<< "${_o}"; then
    _ok '(a) acusa auto-auditoria VENCIDA, com a idade e a cadencia na mensagem'
  else _bad '(a) idade' "saida=[${_o}]"; fi
  rm -rf "${_d}"

  # (b) CALA no caso honesto — relatorio de HOJE. Sem este caso a guarda treina a sessao a
  #     ignora-la, que e a clausula 4: falso positivo e pior que veto ausente.
  _hoje="$(LC_ALL=C date +%Y-%m-%d)"
  _d="$(_sandbox "${_hoje}")"
  _o="$(EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1 || true)"
  if ! grep -q 'EVOLVE-VENCIDO' <<< "${_o}"; then
    _ok '(b) cala com relatorio de HOJE (auto-auditoria fresca nao e acusada)'
  else _bad '(b) falso positivo' "acusou relatorio de hoje: [${_o}]"; fi
  rm -rf "${_d}"

  # (c) NUNCA RODOU e' desfecho PROPRIO, nao silencio: pasta existe, zero relatorio.
  _d="$(_sandbox '')"
  _o="$(EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1 || true)"
  if grep -q 'EVOLVE-SEM-RODADA' <<< "${_o}"; then
    _ok '(c) zero relatorio -> SEM-RODADA declarado (nunca rodou != esta fresco)'
  else _bad '(c) sem rodada' "saida=[${_o}]"; fi
  rm -rf "${_d}"

  # (d) OPT-IN: sem a pasta de analise, a guarda CALA (adotante nao nasce vermelho). O par de (c):
  #     pasta AUSENTE e silencio; pasta VAZIA e achado. Sem distinguir, a guarda gritaria em todo
  #     adotante que nunca teve docs/analysis.
  _d="$(mktemp -d)"
  _o="$(EVOLVE_ANALYSIS_DIR="${_d}/nao-existe" bash "${SELF}" "${_d}" --tsv 2>&1 || true)"
  if [ -z "${_o}" ]; then
    _ok '(d) pasta de analise AUSENTE -> silencio (opt-in; o par de (c))'
  else _bad '(d) opt-in' "acusou sem a pasta: [${_o}]"; fi
  rm -rf "${_d}"

  # (e) DATA ILEGIVEL no nome nao vira "fresco": nome que nao casa a regex e IGNORADO, e se nao
  #     sobrar nenhum legivel o desfecho e SEM-RODADA. Data invalida jamais aprova por silencio.
  _d="$(mktemp -d)"; mkdir -p "${_d}/docs/analysis"
  printf '# x\n' > "${_d}/docs/analysis/onion-evolution-sem-data.md"
  _o="$(EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1 || true)"
  if grep -q 'EVOLVE-SEM-RODADA' <<< "${_o}"; then
    _ok '(e) nome sem data legivel NAO vira fresco (cai em SEM-RODADA, nunca em silencio)'
  else _bad '(e) data ilegivel' "saida=[${_o}]"; fi
  rm -rf "${_d}"

  # (f) O DELTA POPULACIONAL e' perna PROPRIA: num repo git com artefato tocado depois do
  #     relatorio, a guarda nomeia o NUMERO. Este e o gatilho que a idade sozinha nao da —
  #     relatorio de ontem com 30 artefatos novos esta vencido na substancia, nao no calendario.
  # ⚠️ FIXTURE SINTETIZADA, nunca o REPO VIVO — e a 1a versao usava o repo vivo. O Elenxo provou
  #    o estrago: bastava RODAR o /meta:evolve para este caso FALHAR, logo a bancada PUNIA QUEM
  #    OBEDECIA ao conselho da guarda. E como o runner sai 1 com qualquer FAIL, o "SOFT por
  #    desenho" era FICCAO: ela bloqueava. Pior, nascia vermelha em TODO ADOTANTE, refutando o
  #    item do meu proprio teto que dizia "o adotante recebe a bancada, que sintetiza a fixture".
  #    Caso que depende do estado do repo nao e caso, e aposta.
  _fx="$(mktemp -d)"
  ( cd "${_fx}" && git init -q . \
    && git -c user.email=b@b -c user.name=b commit -q --allow-empty -m base ) >/dev/null 2>&1
  mkdir -p "${_fx}/docs/analysis" "${_fx}/.claude/commands/meta"
  printf '# r\n' > "${_fx}/docs/analysis/onion-evolution-2026-01-01.md"
  ( cd "${_fx}" && git add -A && git -c user.email=b@b -c user.name=b commit -q -m rel ) >/dev/null 2>&1
  for _i in 1 2 3; do printf '# a%s\n' "${_i}" > "${_fx}/.claude/commands/meta/a${_i}.md"; done
  ( cd "${_fx}" && git add -A && git -c user.email=b@b -c user.name=b commit -q -m art ) >/dev/null 2>&1
  _o="$( (cd "${_fx}" && EVOLVE_STALE_DAYS=99999 EVOLVE_DELTA_MIN=1 EVOLVE_ANALYSIS_DIR="${_fx}/docs/analysis" bash "${SELF}" "${_fx}" --tsv 2>&1) || true )"
  if grep -q 'EVOLVE-DELTA' <<< "${_o}" && grep -qE 'artefato\(s\)' <<< "${_o}" \
     && ! grep -q 'EVOLVE-VENCIDO' <<< "${_o}"; then
    _ok '(f) delta e perna PROPRIA (fixture git sintetizada): acusa com cadencia folgada, sem a idade'
  else _bad '(f) delta' "fixture com 3 artefatos pos-relatorio devia acusar SO o delta: [${_o}]"; fi
  rm -rf "${_fx}"

  # (g) GIT INALCANCAVEL declara NAO-MEDIDO, nunca ZERO. Caso ACHADO POR MUTANTE: ao trocar o
  #     `NAO-MEDIDO` por `0`, nenhum caso reprovou — a perna existia e nao era exercitada, e o
  #     modo-de-falha e o pior desta casa (`erro-engolido-virando-numero`: um comando que FALHOU e
  #     um objeto que NAO EXISTE produzem o mesmo zero). O sandbox nao e repo git, de proposito.
  _d="$(mktemp -d)"; mkdir -p "${_d}/docs/analysis"
  printf '# r\n' > "${_d}/docs/analysis/onion-evolution-2026-07-30.md"
  # ⚠️ `bash "${SELF}"` COMO OS OUTROS: a 1a versao usava o caminho FIXO do repo, e o Elenxo provou a
  #    consequencia — instalado o mutante `NAO-MEDIDO`->`0` na arvore, o caso (g) seguia VERDE,
  #    porque exercitava o artefato canonico em vez do que estava em teste.
  _o="$( (cd "${_d}" && EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1) || true )"
  if grep -q 'EVOLVE-DELTA-NAO-MEDIDO' <<< "${_o}"; then
    _ok '(g) git inalcancavel -> delta NAO MEDIDO declarado (nunca zero silencioso)'
  else _bad '(g) delta nao medido' "saida=[${_o}]"; fi
  rm -rf "${_d}"

  # (h) GLOB ESTRITO: relatorio de OUTRO FLUXO nao conta como rodada. Fixa a cura do achado que
  #     derrubou a tese desta guarda — `onion-evolution-triagem-...-<data>.md` calava AS DUAS
  #     pernas, e dois arquivos desse tipo JA existiam no repo (triagem de inbox, nao auditoria).
  _d="$(mktemp -d)"; mkdir -p "${_d}/docs/analysis"
  printf '# antiga\n' > "${_d}/docs/analysis/onion-evolution-2026-01-01.md"
  printf '# triagem\n' > "${_d}/docs/analysis/onion-evolution-triagem-sinal-$(LC_ALL=C date +%Y-%m-%d).md"
  _o="$( (cd "${_d}" && EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1) || true )"
  if grep -q 'EVOLVE-VENCIDO' <<< "${_o}" && grep -q 'desde 2026-01-01' <<< "${_o}"; then
    _ok '(h) relatorio de OUTRO fluxo NAO conta como rodada (glob estrito; a data vem do canonico)'
  else _bad '(h) glob estrito' "um arquivo de outro fluxo calou a guarda: [${_o}]"; fi
  rm -rf "${_d}"

  # (i) LIMIAR: delta ABAIXO do limiar CALA. Sem isto a perna disparava em 52 de 60 dias, e guarda
  #     que nunca cala e a definicao do veto que a sessao aprende a ignorar (clausula 4).
  _d="$(mktemp -d)"
  ( cd "${_d}" && git init -q . && git -c user.email=b@b -c user.name=b commit -q --allow-empty -m b ) >/dev/null 2>&1
  mkdir -p "${_d}/docs/analysis" "${_d}/.claude/commands/meta"
  printf '# r\n' > "${_d}/docs/analysis/onion-evolution-2026-01-01.md"
  ( cd "${_d}" && git add -A && git -c user.email=b@b -c user.name=b commit -q -m r ) >/dev/null 2>&1
  printf '# a\n' > "${_d}/.claude/commands/meta/a1.md"
  ( cd "${_d}" && git add -A && git -c user.email=b@b -c user.name=b commit -q -m a ) >/dev/null 2>&1
  _o="$( (cd "${_d}" && EVOLVE_STALE_DAYS=99999 EVOLVE_DELTA_MIN=5 EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1) || true )"
  if ! grep -q 'EVOLVE-DELTA	' <<< "${_o}"; then
    _ok '(i) delta de 1 artefato com limiar 5 CALA (a perna tem limiar, nao alarme fixo)'
  else _bad '(i) limiar' "1 artefato disparou com limiar 5: [${_o}]"; fi
  rm -rf "${_d}"

  # (j) `--since` ANCORADO: `--since=<data nua>` significa "essa data NA HORA ATUAL DO RELOGIO",
  #     entao a perna ficava CEGA aos artefatos commitados no DIA do relatorio. Fixa a cura.
  _d="$(mktemp -d)"
  ( cd "${_d}" && git init -q . && git -c user.email=b@b -c user.name=b commit -q --allow-empty -m b ) >/dev/null 2>&1
  mkdir -p "${_d}/docs/analysis" "${_d}/.claude/commands/meta"
  _hj="$(LC_ALL=C date +%Y-%m-%d)"
  printf '# r\n' > "${_d}/docs/analysis/onion-evolution-${_hj}.md"
  printf '# a\n' > "${_d}/.claude/commands/meta/a1.md"
  # ⚠️ TIMESTAMP EXPLICITO DE MADRUGADA: sem ele o commit nasce "agora", e `--since=<data nua>`
  #    (que significa "essa data NA HORA ATUAL") coincide com `T00:00:00` — o caso nao distingue
  #    as duas formas e o mutante sobrevive. Era CORRIDA disfarcada de caso.
  ( cd "${_d}" && git add -A && GIT_AUTHOR_DATE="${_hj}T00:30:00" GIT_COMMITTER_DATE="${_hj}T00:30:00" \
    git -c user.email=b@b -c user.name=b commit -q -m hoje ) >/dev/null 2>&1
  _o="$( (cd "${_d}" && EVOLVE_DELTA_MIN=0 EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1) || true )"
  if grep -q 'EVOLVE-DELTA	' <<< "${_o}"; then
    _ok '(j) artefato commitado no DIA do relatorio E VISTO (--since ancorado em T00:00:00)'
  else _bad '(j) since ancorado' "a perna ficou cega ao dia do relatorio: [${_o}]"; fi
  rm -rf "${_d}"

  # (k) DATA FUTURA acusa. `_AGE` negativo nunca passa `-gt` e `--since=<futuro>` devolve vazio:
  #     sem este caso, um relatorio datado a frente calava as duas pernas PARA SEMPRE.
  _d="$(mktemp -d)"; mkdir -p "${_d}/docs/analysis"
  printf '# r\n' > "${_d}/docs/analysis/onion-evolution-2099-01-01.md"
  _o="$( (cd "${_d}" && EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1) || true )"
  if grep -q 'EVOLVE-DATA-FUTURA' <<< "${_o}"; then
    _ok '(k) relatorio datado no FUTURO acusa (nao silencia as duas pernas para sempre)'
  else _bad '(k) data futura' "saida=[${_o}]"; fi
  rm -rf "${_d}"

  printf '  evolve-staleness --selftest: %d passaram, %d falharam\n' "${_p}" "${_f}"
  [ "${_f}" -eq 0 ] || exit 1
  exit 0
fi

# ── produção ──────────────────────────────────────────────────────────────────────────────────
[ -d "${ANALYSIS}" ] || exit 0                      # opt-in pela presença da pasta

_LAST="$(_last_report || true)"
if [ -z "${_LAST}" ]; then
  _emit SOFT EVOLVE-SEM-RODADA "a auto-auditoria do framework NUNCA rodou (zero \`onion-evolution-*.md\` com data legível em docs/analysis/) — e 'nunca rodou' não é 'está fresco'. rode /meta:evolve. (Esta mensagem viaja para adotante: 'nunca rodou' aqui significa que ESTE repo nao tem relatorio de auto-auditoria, nao um juizo sobre o core)"
  exit 1
fi

_EPOCH="$(_epoch_of "${_LAST}")"
if [ -z "${_EPOCH}" ] || [ "${_EPOCH}" -le 0 ]; then
  _emit SOFT EVOLVE-IDADE-NAO-MEDIDA "idade da última auto-auditoria (${_LAST}) NÃO MEDIDA neste ambiente (date sem -d/-j e awk sem mktime) — degradação declarada, nunca conformidade"
  exit 1
fi
_AGE=$(( ( $(date +%s) - _EPOCH ) / 86400 ))
# ⚠️ DATA FUTURA nao silencia (FN-3 do Elenxo): `_AGE` negativo nunca passa `-gt`, e
#    `--since=<futuro>` devolve vazio — um relatorio datado a frente CALAVA AS DUAS PERNAS PARA
#    SEMPRE. Nao ha caso honesto para isso; e erro de carimbo ou forja.
if [ "${_AGE}" -lt 0 ]; then
  _emit SOFT EVOLVE-DATA-FUTURA "a ultima auto-auditoria esta datada no FUTURO (${_LAST}, ${_AGE}d) — carimbo invalido, e enquanto estiver assim as duas pernas desta guarda ficam cegas; corrija a data do relatorio"
  exit 1
fi
_DELTA="$(_population_delta "${_LAST}")"

_hits=0
if [ "${_AGE}" -gt "${STALE_DAYS}" ]; then
  _hits=1
  _emit SOFT EVOLVE-VENCIDO "a auto-auditoria do framework está VENCIDA (${_AGE}d > ${STALE_DAYS}d desde ${_LAST}) — o Onion mede se GUARDA DISPARA e não mede se DOUTRINA ATERRISSA; rode /meta:evolve. A máquina detecta a idade, o humano dispara (padrão da REGRA 62/65)"
fi
if [ "${_DELTA}" = "NAO-MEDIDO" ]; then
  _emit SOFT EVOLVE-DELTA-NAO-MEDIDO "delta populacional desde ${_LAST} NÃO MEDIDO (git inalcançável) — declarado, nunca zero silencioso"
  _hits=1
# ⚠️ LIMIAR, nao `> 0` (FP-2 do Elenxo): com `> 0` a perna disparava em 52 de 60 dias — uma
# auditoria de ONTEM com 10 artefatos tocados (2,3% da populacao) era declarada "vencida na
# SUBSTANCIA". Guarda que nunca cala e a definicao do veto que a sessao aprende a ignorar
# (clausula 4). O default de 40 e ~10% de uma populacao de 429 artefatos vigiados; ajustavel.
elif [ "${_DELTA}" -gt "${DELTA_MIN}" ]; then
  _hits=1
  _emit SOFT EVOLVE-DELTA "a população mudou desde a última auto-auditoria (${_LAST}): ${_DELTA} artefato(s) (> ${DELTA_MIN}) de \`.claude/{commands,agents,skills,hooks,validation}\` tocado(s) depois dela — a auditoria está vencida na SUBSTÂNCIA, não só no calendário; rode /meta:evolve. (Conta artefato TOCADO, não artefato que precisa de auditoria: o número manda olhar, não afirma que todos importam)"
fi
[ "${_hits}" -eq 0 ] || exit 1
[ "${FORMAT}" = tsv ] || printf '  ✅ REGRA 97: auto-auditoria fresca (%s, %sd) e sem delta populacional\n' "${_LAST}" "${_AGE}"
exit 0
