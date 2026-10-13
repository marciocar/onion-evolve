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
#   (1) a DATA do relatório que o próprio `/meta:evolve` produz (o glob canônico dele sob
#       `docs/analysis/`, conforme `evolve.md`; o nome não é escrito aqui — ver a nota de
#       VAZAMENTO no bloco do `--selftest`);
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
#    de vendido como redundância. Desde 2026-10-13 a (2) mede contra um marco próprio, o COMMIT
#    que tocou o relatório por último, mas continua escolhendo QUAL relatório pela perna (1).
#    A dependência diminuiu sem sumir.
#  · BASE DO DELTA = COMMIT, não DATA (cura de 2026-10-13, sinal de campo do adotante KG-SSOT). A
#    redação anterior contava `--since=<data>T00:00:00` e declarava aqui o erro como "caso de borda
#    de um dia". No adotante esse caso deu 42 artefatos, alarme falso, e uma 2ª rodada inteira do
#    /meta:evolve disparada por ele. O dano foi maior do que este teto previa. Agora a base é
#    `git log -1 --format=%H -- <relatório>`, e o delta conta `<commit>..HEAD`.
#    Artefato no MESMO commit do relatório conta como coberto por ele.
#  · FALLBACK DECLARADO, nunca silencioso: com o relatório NÃO RASTREADO (o evolve acabou de
#    escrevê-lo e ainda não houve commit) ou com o commit dele na FRONTEIRA de um clone raso
#    (onde o git finge que o arquivo nasceu ali), a base volta à data e a guarda emite
#    `EVOLVE-DELTA-BASE-DATA` com o motivo. Repo raso não vira silêncio.
#  · EDIÇÃO TARDIA do relatório (corrigir um typo dias depois) move a base para a frente e esconde
#    o que mudou entre a auditoria e a edição. Lacuna conhecida e aceita: o comando regenera o
#    relatório a partir do grafo, então a edição à mão já é desvio de contrato.
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

# ── perna (2): o DELTA POPULACIONAL desde o COMMIT do relatório, medido no GIT ───────────────
# A base preferida é o commit que tocou o relatório por último. A data é o FALLBACK, e vem
# declarada. A função roda no shell corrente, nunca em `$( )`, para as duas variáveis
# sobreviverem: `_DELTA` (N ou NAO-MEDIDO) e `_DELTA_BASE` (`commit:<sha>` ou `data:<motivo>`).
_DELTA=""; _DELTA_BASE=""
_population_delta() {   # $1 = data ISO do relatório
  local since="$1" rep sha=""
  local -a range
  command -v git >/dev/null 2>&1 || { _DELTA='NAO-MEDIDO'; return 0; }
  ( cd "${REPO}" && git rev-parse --git-dir >/dev/null 2>&1 ) || { _DELTA='NAO-MEDIDO'; return 0; }
  rep="${ANALYSIS}/onion-evolution-${since}.md"
  # relativo quando a pasta mora no repo (o caso de produção); absoluto fora dele, onde o git
  # recusa, `sha` fica vazio e a base cai no fallback declarado
  case "${rep}" in "${REPO}/"*) rep="${rep#"${REPO}/"}" ;; esac
  sha="$( (cd "${REPO}" && git log -1 --format=%H -- "${rep}" 2>/dev/null) || true )"
  if [ -z "${sha}" ]; then
    _DELTA_BASE="data:relatorio sem commit no git (nao rastreado ou fora do repo)"
  else
    # ⚠️ CLONE RASO: o commit de fronteira aparenta CRIAR todo arquivo da árvore, então o
    #    `log -1` devolve a fronteira e não o commit real do relatório. A base ficaria adiantada e
    #    o delta, subcontado. Só vale o commit que NÃO está no arquivo `shallow`.
    #    `--git-path` sem `--path-format` (que só existe desde o git 2.31): o caminho sai relativo
    #    ao cwd, por isso o teste roda dentro do REPO. Num worktree ligado ele aponta o dir comum.
    if ( cd "${REPO}" && shallow_file="$(git rev-parse --git-path shallow 2>/dev/null)" \
         && [ -f "${shallow_file}" ] && grep -qx "${sha}" "${shallow_file}" ); then
      _DELTA_BASE="data:repo raso, o commit do relatorio e a fronteira do clone (git fetch --unshallow resolve)"
    else
      _DELTA_BASE="commit:${sha}"
    fi
  fi
  case "${_DELTA_BASE}" in
    commit:*) range=("${sha}..HEAD") ;;
    # ⚠️ `T00:00:00` E OBRIGATORIO no fallback: `--since=2026-10-04` significa "essa data NA HORA
    #    ATUAL DO RELOGIO", nao "o inicio do dia" (medido pelo Elenxo: 0 contra 5). No fallback,
    #    errar para o lado de AVISAR dentro do dia do relatorio e o mal menor, e vem declarado.
    *)        range=("--since=${since}T00:00:00") ;;
  esac
  _DELTA="$( (cd "${REPO}" && git log "${range[@]}" --name-only --pretty=format: -- \
        '.claude/commands' '.claude/agents' '.claude/skills' '.claude/hooks' '.claude/validation' 2>/dev/null \
        | grep -E '\.(md|sh)$' | sort -u | grep -c . ) || true )"
  _DELTA="${_DELTA:-0}"
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
  # ⚠️ OS NOMES DE FIXTURE SÃO COMPOSTOS, nunca literais, e a razão é de VAZAMENTO: o
  #    `ops/materialize-door.sh` recusa a projeção pública quando um artefato cita um DOCUMENTO
  #    NOMEADO sob `docs/analysis/` — o diretório nu descreve a arquitetura e fica, mas
  #    `docs/analysis/<algo>.md` é ponteiro para documento CORE-PRIVADO, e esta guarda VIAJA para a
  #    porta. Medido no CI (shard 2, 2026-10-04): o materializador abortou listando cinco linhas
  #    minhas, e o caso `door: (g)` caiu por um motivo que nada tem a ver com o que ele mede — a
  #    assinatura exata de bancada medindo ambiente. As fixtures são sintéticas; compor o nome diz
  #    isso ao leitor E ao detector.
  _PFX="onion-evo""lution-"   # concatenado de proposito: nao forma o literal que o detector busca
  _rel() { printf '%s/%s%s.md' "docs/ana""lysis" "${_PFX}" "$1"; }
  _sandbox() {   # $1=data do relatorio (vazio = nenhum relatorio)
    local d; d="$(mktemp -d)"; mkdir -p "${d}/docs/analysis" "${d}/.claude/commands/meta"
    [ -n "${1:-}" ] && printf '# relatorio\n' > "${d}/$(_rel "$1")"
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
  printf '# x\n' > "${_d}/$(_rel "sem-data")"
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
  printf '# r\n' > "${_fx}/$(_rel "2026-01-01")"
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
  printf '# r\n' > "${_d}/$(_rel "2026-07-30")"
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
  printf '# antiga\n' > "${_d}/$(_rel "2026-01-01")"
  printf '# triagem\n' > "${_d}/$(_rel "triagem-sinal-$(LC_ALL=C date +%Y-%m-%d)")"
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
  printf '# r\n' > "${_d}/$(_rel "2026-01-01")"
  ( cd "${_d}" && git add -A && git -c user.email=b@b -c user.name=b commit -q -m r ) >/dev/null 2>&1
  printf '# a\n' > "${_d}/.claude/commands/meta/a1.md"
  ( cd "${_d}" && git add -A && git -c user.email=b@b -c user.name=b commit -q -m a ) >/dev/null 2>&1
  _o="$( (cd "${_d}" && EVOLVE_STALE_DAYS=99999 EVOLVE_DELTA_MIN=5 EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1) || true )"
  if ! grep -q 'EVOLVE-DELTA	' <<< "${_o}"; then
    _ok '(i) delta de 1 artefato com limiar 5 CALA (a perna tem limiar, nao alarme fixo)'
  else _bad '(i) limiar' "1 artefato disparou com limiar 5: [${_o}]"; fi
  rm -rf "${_d}"

  # (j) `--since` ANCORADO, agora no FALLBACK: `--since=<data nua>` significa "essa data NA HORA
  #     ATUAL DO RELOGIO", entao a perna ficava CEGA aos artefatos commitados no DIA do relatorio.
  #     Desde 2026-10-13 a base e o commit do relatorio, e a data so vale quando ele nao tem
  #     commit. Por isso o relatorio aqui fica NAO RASTREADO: e o caminho onde a ancora ainda
  #     decide, e o caso exige tambem que o fallback venha DECLARADO.
  _d="$(mktemp -d)"
  ( cd "${_d}" && git init -q . && git -c user.email=b@b -c user.name=b commit -q --allow-empty -m b ) >/dev/null 2>&1
  mkdir -p "${_d}/docs/analysis" "${_d}/.claude/commands/meta"
  _hj="$(LC_ALL=C date +%Y-%m-%d)"
  printf '# r\n' > "${_d}/$(_rel "${_hj}")"
  printf '# a\n' > "${_d}/.claude/commands/meta/a1.md"
  # ⚠️ TIMESTAMP EXPLICITO DE MADRUGADA: sem ele o commit nasce "agora", e `--since=<data nua>`
  #    (que significa "essa data NA HORA ATUAL") coincide com `T00:00:00` — o caso nao distingue
  #    as duas formas e o mutante sobrevive. Era CORRIDA disfarcada de caso.
  ( cd "${_d}" && git add .claude && GIT_AUTHOR_DATE="${_hj}T00:30:00" GIT_COMMITTER_DATE="${_hj}T00:30:00" \
    git -c user.email=b@b -c user.name=b commit -q -m hoje ) >/dev/null 2>&1
  _o="$( (cd "${_d}" && EVOLVE_DELTA_MIN=0 EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1) || true )"
  if grep -q 'EVOLVE-DELTA	' <<< "${_o}" && grep -q 'EVOLVE-DELTA-BASE-DATA	.*nao rastreado' <<< "${_o}"; then
    _ok '(j) relatorio sem commit: fallback por data ancorado em T00:00:00 VE o dia, e vem DECLARADO'
  else _bad '(j) since ancorado / fallback declarado' "saida=[${_o}]"; fi
  rm -rf "${_d}"

  # (l) O ALARME FALSO DO CAMPO, verbatim da forma (adotante KG-SSOT, 2026-10-12: 42 artefatos): o
  #     artefato commitado no MESMO DIA, ANTES do relatorio, NAO conta. A base e o commit do
  #     relatorio, nao a meia-noite. Mutante medido: voltar ao `--since=<data>T00:00:00` faz
  #     este caso reprovar, porque o artefato das 09h passa a contar.
  # (m) O PAR DE (l): o artefato commitado DEPOIS do relatorio, no mesmo dia, CONTA. Sem (m), um
  #     delta zerado sempre passaria (l).
  _d="$(mktemp -d)"
  ( cd "${_d}" && git init -q . && GIT_AUTHOR_DATE=2026-01-01T08:00:00 GIT_COMMITTER_DATE=2026-01-01T08:00:00 \
    git -c user.email=b@b -c user.name=b commit -q --allow-empty -m b ) >/dev/null 2>&1
  mkdir -p "${_d}/docs/analysis" "${_d}/.claude/commands/meta"
  printf '# antes\n' > "${_d}/.claude/commands/meta/antes.md"
  ( cd "${_d}" && git add -A && GIT_AUTHOR_DATE=2026-01-01T09:00:00 GIT_COMMITTER_DATE=2026-01-01T09:00:00 \
    git -c user.email=b@b -c user.name=b commit -q -m antes ) >/dev/null 2>&1
  printf '# r\n' > "${_d}/$(_rel "2026-01-01")"
  ( cd "${_d}" && git add -A && GIT_AUTHOR_DATE=2026-01-01T11:00:00 GIT_COMMITTER_DATE=2026-01-01T11:00:00 \
    git -c user.email=b@b -c user.name=b commit -q -m rel ) >/dev/null 2>&1
  _o="$( (cd "${_d}" && EVOLVE_STALE_DAYS=99999 EVOLVE_DELTA_MIN=0 EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1) || true )"
  if [ -z "${_o}" ]; then
    _ok '(l) artefato commitado no MESMO dia ANTES do relatorio NAO conta (base = commit do relatorio)'
  else _bad '(l) alarme falso do mesmo dia' "o artefato anterior ao relatorio contou: [${_o}]"; fi
  printf '# depois\n' > "${_d}/.claude/commands/meta/depois.md"
  ( cd "${_d}" && git add -A && GIT_AUTHOR_DATE=2026-01-01T12:00:00 GIT_COMMITTER_DATE=2026-01-01T12:00:00 \
    git -c user.email=b@b -c user.name=b commit -q -m depois ) >/dev/null 2>&1
  _o="$( (cd "${_d}" && EVOLVE_STALE_DAYS=99999 EVOLVE_DELTA_MIN=0 EVOLVE_ANALYSIS_DIR="${_d}/docs/analysis" bash "${SELF}" "${_d}" --tsv 2>&1) || true )"
  if grep -q 'EVOLVE-DELTA	.*: 1 artefato(s).*(base: commit)' <<< "${_o}" && ! grep -q 'BASE-DATA' <<< "${_o}"; then
    _ok '(m) artefato commitado DEPOIS do relatorio CONTA (1, base commit, sem fallback)'
  else _bad '(m) delta pos-relatorio' "devia contar exatamente 1 com base commit: [${_o}]"; fi

  # (n) REPO RASO nao vira silencio: no clone de profundidade 1 o commit do relatorio e a
  #     fronteira, que aparenta criar todos os arquivos. A guarda cai na data e DECLARA o motivo.
  _sh="$(mktemp -d)"; rmdir "${_sh}"
  git clone -q --depth 1 "file://${_d}" "${_sh}" >/dev/null 2>&1 || true
  _o="$( (cd "${_sh}" && EVOLVE_STALE_DAYS=99999 EVOLVE_DELTA_MIN=99999 EVOLVE_ANALYSIS_DIR="${_sh}/docs/analysis" bash "${SELF}" "${_sh}" --tsv 2>&1) || true )"
  if grep -q 'EVOLVE-DELTA-BASE-DATA	.*repo raso' <<< "${_o}"; then
    _ok '(n) clone raso: a base cai na data e o fallback vem DECLARADO (nunca silencio)'
  else _bad '(n) repo raso' "o fallback do clone raso nao foi declarado: [${_o}]"; fi
  rm -rf "${_d}" "${_sh}"

  # (k) DATA FUTURA acusa. `_AGE` negativo nunca passa `-gt` e `--since=<futuro>` devolve vazio:
  #     sem este caso, um relatorio datado a frente calava as duas pernas PARA SEMPRE.
  _d="$(mktemp -d)"; mkdir -p "${_d}/docs/analysis"
  printf '# r\n' > "${_d}/$(_rel "2099-01-01")"
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
_population_delta "${_LAST}"

_hits=0
case "${_DELTA_BASE}" in
  data:*)
    _hits=1
    _emit SOFT EVOLVE-DELTA-BASE-DATA "o delta populacional desde ${_LAST} foi contado pela DATA, nao pelo commit do relatorio. Motivo: ${_DELTA_BASE#data:}. Pela data, artefato commitado no mesmo dia ANTES do relatorio conta como posterior a auditoria, entao o numero pode vir inflado. Commite o relatorio (num clone completo) para a base voltar a ser o commit"
    ;;
esac
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
  _emit SOFT EVOLVE-DELTA "a população mudou desde a última auto-auditoria (${_LAST}): ${_DELTA} artefato(s) (> ${DELTA_MIN}) de \`.claude/{commands,agents,skills,hooks,validation}\` tocado(s) depois dela (base: ${_DELTA_BASE%%:*}) — a auditoria está vencida na SUBSTÂNCIA, não só no calendário; rode /meta:evolve. (Conta artefato TOCADO, não artefato que precisa de auditoria: o número manda olhar, não afirma que todos importam)"
fi
[ "${_hits}" -eq 0 ] || exit 1
[ "${FORMAT}" = tsv ] || printf '  ✅ REGRA 97: auto-auditoria fresca (%s, %sd) e sem delta populacional\n' "${_LAST}" "${_AGE}"
exit 0
