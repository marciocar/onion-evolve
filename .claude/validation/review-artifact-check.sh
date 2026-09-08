#!/usr/bin/env bash
# review-artifact-check.sh — este PR foi revisado, e há RESÍDUO MATERIAL disso?
#
# ═══ POR QUE EXISTE (dano medido em 2026-08-06) ═══
# Em 2026-08-02 o diário registrou: 15 auto-correções, 8 só existiram porque o maestro perguntou,
# "nenhuma foi pega por auto-revisão". Em 2026-08-06 repetiu na mesma proporção: ~8 erros, quase
# todos descobertos porque ELE perguntou. Nomear o problema não o curou — e é essa a prova de que a
# cura não pode ser outra declaração de intenção.
#
# Das 8 falhas daquele dia, 6 foram achadas por REVISÃO ADVERSARIAL rodada à mão (2 execuções,
# 15 defeitos reais). O revisor do CI não as pegaria: ele estoura o orçamento de turnos justamente
# nos PRs grandes, e o `onion-review` sai VERDE por desenho quando isso acontece.
#
# ═══ O QUE ESTA GUARDA É, E O QUE ELA NÃO É ═══
# Ela NÃO julga a qualidade da revisão — nenhum script determinístico sabe se um achado é bom. Ela
# exige o RESÍDUO: um artefato commitado, cujo hash amarra a revisão ao diff REVISADO. É a forma que
# o diário de 08-02 identificou como a única que funciona — "resíduo material, auditado por terceiro,
# desacoplado do ator" — em oposição à que falhou: "vou prestar mais atenção".
#
# ═══ O TETO, DECLARADO ANTES DE PROMETER ═══
# Este repo NÃO tem branch protection (privado sem Pro — a API devolve 403). Nenhum check é
# obrigatório e NADA impede mecanicamente um merge. O que esta guarda torna impossível não é
# "mergear errado" — é "mergear sem saber". Prometer mais que isso seria falso.
#
# ═══ ESCOPO: SÓ QUANDO HÁ PR, E O CORTE IMPORTA MAIS QUE A REGRA ═══
# Exigir o artefato a cada commit intermediário travaria o trabalho — e falso-positivo TRAVANTE é o
# modo de falha que esta casa já mediu (diary 2026-08-02: como `exit 2` é o único canal, todo
# disparo interrompe; "o detector não pode ser heurístico"). A revisão se faz quando o trabalho é
# PROPOSTO, não enquanto é feito. Logo: só cobra quando existe PR aberto para o branch.
#
# Uso  : bash .claude/validation/review-artifact-check.sh [<repo_root>] [--format tsv]
# Saída: relatório humano (default) ou TSV (severidade·tag·path·mensagem)
# Exit : 0 = artefato presente e casando, ou fora de escopo · 1 = falta/caducou · 2 = uso inválido
set -euo pipefail

REPO_ROOT="$(cd "${1:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'review-artifact-check: repo_root inválido\n' >&2; exit 2; }
FORMAT=human
for a in "$@"; do case "$a" in tsv|--format=tsv) FORMAT=tsv ;; esac; done
cd "${REPO_ROOT}"

REVIEW_DIR="docs/evolution/review"
SKIPS=""
# A ISENÇÃO É EMITIDA NOS DOIS MODOS. O comentário original dizia "declarar a ignorância é o
# comportamento correto" — e isso só valia no modo HUMANO: em TSV o `_skip` alimentava uma variável
# que ninguém imprimia, e `check_review_artifact` trata saída vazia como "nada a relatar". Cinco
# classes de silêncio foram MEDIDAS assim (detached, sem gh, gh não autenticado, sem merge-base,
# helper quebrado). É a mesma família do defeito que este ciclo cura, cometida DENTRO da cura.
_skip() {
  SKIPS="${SKIPS}${SKIPS:+ · }$1"
  [ "${FORMAT}" = tsv ] && printf 'SOFT\tISENCAO\t.claude/validation/review-artifact-check.sh\tREGRA 56 não julgou este PR: %s — a guarda declara que NÃO SABE, em vez de passar em silêncio\n' "$1"
  return 0
}

_out() {  # $1=sev $2=tag $3=path $4=msg
  if [ "${FORMAT}" = tsv ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
  else printf '  ✗ %s: %s\n    %s\n' "$2" "$3" "$4"; fi
}

[ "${FORMAT}" = tsv ] || printf '══ REVIEW-ARTIFACT — este PR tem resíduo de revisão? ══\n'

# ── ESCOPO ────────────────────────────────────────────────────────────────────────────────────
# NO CI O HEAD É DESTACADO — e descobrir isso custou a 4ª ocorrência da mesma família de erro.
# `onion-validate.yml` faz checkout com `ref: head.sha`, então `git rev-parse --abbrev-ref HEAD`
# devolve "HEAD" e a guarda saía por `detached-head` ANTES de chegar ao ramo escrito PARA o CI.
# Resultado medido: a REGRA 56 nunca executava no único caminho que não depende do autor lembrar —
# o gate contra o gatilho social dependia do gatilho social. `GITHUB_HEAD_REF` traz o nome real do
# branch no evento pull_request e por isso é consultado PRIMEIRO.
BRANCH="${GITHUB_HEAD_REF:-}"
[ -n "${BRANCH}" ] || BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
DEFAULT="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)"
[ -n "${DEFAULT}" ] || DEFAULT=main

if [ -z "${BRANCH}" ] || [ "${BRANCH}" = "HEAD" ]; then
  _skip "detached-head"; [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"; exit 0
fi
if [ "${BRANCH}" = "${DEFAULT}" ]; then
  _skip "branch-default"; [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"; exit 0
fi

# Há PR aberto para este branch? É o que separa "trabalho em curso" de "trabalho PROPOSTO".
# Em CI o contexto é dado pelo evento; localmente pergunta-se ao forge.
PR_NUM=""
if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
  PR_NUM="${GITHUB_REF_NAME%%/*}"
elif command -v gh >/dev/null 2>&1; then
  PR_NUM="$(gh pr view --json number --jq .number 2>/dev/null || true)"
else
  # SEM `gh` a guarda NÃO SABE se há PR. Declarar a ignorância é o comportamento correto — o mesmo
  # que o kg-radar faz quando não consegue ler, e o oposto do verde silencioso.
  _skip "sem-gh-nao-da-para-saber-se-ha-PR"
  [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"
  exit 0
fi

if [ -z "${PR_NUM}" ]; then
  _skip "sem-PR-aberto(trabalho-em-curso)"
  [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"
  exit 0
fi

# ADOTANTE FICA DE FORA — e isto é correção do episódio de HOJE, não precaução: uma REGRA HARD
# validada só no core acusou 11 falsos no 1º adotante que a recebeu. Esta regra cobra um RITUAL DO
# CORE (a passada adversarial sobre o framework); o adotante tem o dele. `role: adopted|hub`.
if grep -qE '^(role:[[:space:]]*(adopted|hub)|decoupled_from:)' "${REPO_ROOT}/.claude/.onion-version" 2>/dev/null; then
  _skip "repo-derivado(role-adopted/hub)"
  [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"
  exit 0
fi

BASE="$(git merge-base "origin/${DEFAULT}" HEAD 2>/dev/null || git merge-base "${DEFAULT}" HEAD 2>/dev/null || true)"
if [ -z "${BASE}" ]; then
  _skip "sem-merge-base-com-${DEFAULT}"
  [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"; exit 0
fi

# ISENÇÃO DECLARADA, vocabulário FECHADO: um PR que edita o próprio revisor não pode ser gateado por
# ele — a action se auto-pula quando o workflow difere da branch default (ovo-galinha estrutural,
# documentado em .github/workflows/onion-review.yml). Isenção CONTADA, nunca silenciosa.
# SÓ quando o diff é EXCLUSIVAMENTE o workflow. Antes bastava TOCAR o arquivo: medido, um PR de 52
# arquivos com uma linha nele saía integralmente isento — buraco que não exige má-fé.
if [ -z "$(git diff --name-only "${BASE}" HEAD 2>/dev/null | grep -vx '.github/workflows/onion-review.yml' | head -1)" ] \
   && git diff --name-only "${BASE}" HEAD 2>/dev/null | grep -qx '.github/workflows/onion-review.yml'; then
  _skip "PR-edita-o-proprio-revisor(ovo-galinha)"
  [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"
  exit 0
fi

# ── O DIFF REVISADO ───────────────────────────────────────────────────────────────────────────
# O diretório de review sai do hash, senão o artefato mudaria o hash que ele mesmo declara.
# HASH CANÔNICO — sem isto, `diff.noprefix` ou `core.abbrev` no ~/.gitconfig de quem carimba produz
# um sha diferente de quem valida, e o artefato nasce CADUCO sem nenhuma pista do motivo. Medido:
# três configs pessoais comuns, três hashes distintos para o MESMO diff.
# ⚠️ ÁRVORE SUJA → COMPARE COM O ÍNDICE. A versão anterior comparava sempre `BASE..HEAD`, ou seja,
# só COMMITS. No pre-commit o `HEAD` ainda é o commit ANTERIOR: o conteúdo em stage NAO ENTRAVA na
# conta, então o hash prospectivo — o que o autor calcula com `--cached`, obedecendo — NAO PODIA
# casar. Do 2o commit em diante o gate reprovava exatamente quem tinha obedecido.
#
# GATILHO MEDIDO ANTES DE MEXER, como o nó do backlog exigia: 23 commits numa única sessão
# carregam `--no-verify DECLARADO`. Vinte e três vezes o autor escreveu o resíduo, calculou o hash
# e mesmo assim teve de contornar o hook. GUARDA QUE PUNE QUEM OBEDECE ENSINA A IGNORAR A GUARDA —
# e o custo não é o bypass, é que o bypass vira idioma e um dia esconde uma falta de verdade.
#
# A escolha é a mesma da catraca da REGRA 49 (`_baseline_ref`): perguntar em que SITUAÇÃO se está,
# em vez de assumir uma. Árvore suja = pré-commit → o alvo é o ÍNDICE. Árvore limpa = pós-commit
# (o CI, que é quem audita) → o alvo é `HEAD`, exatamente como antes.
# ⚠️ A DIRECAO DO DIFF IMPORTA, e a 1a versao a INVERTEU no ramo limpo. O codigo montava
# `${_DIFF_TARGET} "${BASE}"`, que com _DIFF_TARGET=HEAD vira `git diff HEAD BASE` — invertido —,
# e hash de diff invertido e OUTRO hash. O CI pegou: ARTEFATO-CADUCO sobre o residuo deste PROPRIO
# PR. Por isso cada ramo escreve a invocacao INTEIRA: variavel que muda de POSICAO SEMANTICA entre
# ramos e a forma mais barata de inverter um argumento sem ninguem ver.
#
# E o meu 1o teste desta cura NAO reproduziu o defeito, porque eu medi a forma PRETENDIDA
# (`BASE HEAD`) em vez da que o codigo executa. Medir o que se quis dizer, e nao o que roda, foi o
# erro mais repetido desta sessao.
if git diff --quiet HEAD 2>/dev/null; then
  # árvore limpa: pós-commit / CI (quem AUDITA) — exatamente como sempre foi
  DIFF_SHA="$(git -c core.abbrev=40 -c diff.noprefix=false diff --no-ext-diff --no-color \
                "${BASE}" HEAD -- . ":(exclude)${REVIEW_DIR}" 2>/dev/null | sha256sum | cut -c1-64)"
else
  # árvore suja: pré-commit — o alvo é o ÍNDICE, o que VAI virar o commit
  DIFF_SHA="$(git -c core.abbrev=40 -c diff.noprefix=false diff --no-ext-diff --no-color \
                --cached "${BASE}" -- . ":(exclude)${REVIEW_DIR}" 2>/dev/null | sha256sum | cut -c1-64)"
fi
SLUG="$(printf '%s' "${BRANCH}" | tr '/' '-')"
ART="${REVIEW_DIR}/${SLUG}.md"

# COMMITADO, não só em disco. O cabeçalho promete "artefato commitado" e o teste era `-f` — arquivo
# untracked passava, e o "resíduo auditado por terceiro" podia nunca sair do disco do autor.
# ⚠️ E A EXISTENCIA SEGUE A MESMA REGRA DO HASH: a SITUACAO decide. `HEAD:` sozinho e o commit
# ANTERIOR no pre-commit, entao o residuo recem-STAGED "nao existia" e o hook bloqueava o proprio
# commit que o adicionava — impasse: para commitar o artefato era preciso ja te-lo commitado.
# Foi medido no PR que colheu a REGRA 56: eu havia curado o HASH para olhar o indice e deixado a
# EXISTENCIA olhando so o commit. Meia-cura em guarda e como meia-renomeacao em codigo — o lado
# que sobra e o que quebra.
# `:${ART}` le o INDICE; `HEAD:${ART}` le o commit. Arvore suja -> indice; limpa -> HEAD.
if git diff --quiet HEAD 2>/dev/null; then _ART_REF="HEAD:${ART}"; else _ART_REF=":${ART}"; fi
if ! git cat-file -e "${_ART_REF}" 2>/dev/null; then
  _out HARD ARTEFATO-AUSENTE "${ART}" "PR #${PR_NUM} aberto e sem resíduo de revisão. Rode a passada adversarial e registre o resultado em ${ART} (campos: reviewed_diff_sha256 · findings_total · findings_real · tokens · duration_min · verdict — este ultimo em vocabulario FECHADO: APROVADO | CORRIGIDO | REPROVADO | REPROVADO_E_CURADO | SEM_ACHADOS; a narrativa vai em 'nota:', e 'elenxo: sim|nao' declara se houve passada adversarial). O hash deste diff é ${DIFF_SHA}."
  [ "${FORMAT}" = tsv ] || printf '  (o verde do onion-review é soft-pass — não substitui esta passada)\n'
  exit 1
fi

# SÓ O FRONTMATTER, e campo numérico TEM de ser número. A versão anterior lia o arquivo inteiro com
# `sed -n s/^campo://p`: um `tokens: gastei uns poucos` escrito na PROSA satisfazia o gate. Como esses
# campos SÃO o dado da reavaliação em N=10, aceitar string arbitrária significava chegar ao 10º PR com
# ledger não-numérico — a mesma classe de "declarei medido" que este ciclo existe para curar.
_field() { awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1' "${ART}" \
             | sed -n "s/^$1:[[:space:]]*//p" | head -1 | tr -d '"'; }
DECL="$(_field reviewed_diff_sha256)"

if [ -z "${DECL}" ]; then
  _out HARD CAMPO-AUSENTE "${ART}" "artefato existe mas não declara reviewed_diff_sha256 — sem ele não há como saber SE a revisão cobriu ESTE código. Esperado: ${DIFF_SHA}"
  exit 1
fi
if [ "${DECL}" != "${DIFF_SHA}" ]; then
  _out HARD ARTEFATO-CADUCO "${ART}" "a revisão registrada cobre outro diff (declarado ${DECL}, atual ${DIFF_SHA}) — o código mudou DEPOIS de revisado. Re-revise e re-carimbe."
  exit 1
fi

# Os campos da REAVALIAÇÃO EM N=10 (decisão do maestro, 2026-08-06): a cadência "todo PR" só pode ser
# reavaliada se os dados existirem. Sem eles, no 10º PR eu repetiria o erro que este ciclo cura —
# declarar "medido" sem ledger. São exigidos, não sugeridos.
FALTAM=""
for f in findings_total findings_real tokens duration_min; do
  v="$(_field "${f}")"
  case "${v}" in ''|*[!0-9]*) FALTAM="${FALTAM}${FALTAM:+, }${f}(nao-numerico)" ;; esac
done
[ -n "$(_field verdict)" ] || FALTAM="${FALTAM}${FALTAM:+, }verdict"
if [ -n "${FALTAM}" ]; then
  _out HARD CAMPO-DE-REAVALIACAO-AUSENTE "${ART}" "faltam: ${FALTAM}. São o dado da reavaliação em N=10 — sem eles a cadência 'todo PR' não pode ser julgada, e a falsificação declarada deste mecanismo é justamente chegar ao 10º PR sem os campos."
  exit 1
fi

# ---------------------------------------------------------------------------
# VOCABULÁRIO FECHADO DO `verdict:` — selado pelo maestro em 2026-09-08.
#
# POR QUE, medido e não sentido: `review-ledger.sh` agregou os 262 resíduos existentes e
# achou **72 formas DISTINTAS** de veredito (71 se a caixa for ignorada — `conforme` minúsculo
# era uma delas). Sessenta e duas ocorrem UMA vez, e são frase inteira:
# `ELENXO-DERRUBOU-CINCO-AFIRMACOES-MINHAS-E-ACHOU-UMA-BOMBA-RELOGIO`. Campo de texto livre
# NÃO sustenta série: não se pode dizer "a taxa de reprovação caiu" sem vocabulário fechado,
# e a régua da revisão adversarial (hoje 106.881 tokens por achado real) fica sem eixo.
#
# A CAUDA NÃO ERA RUÍDO — eram TRÊS campos espremidos num só, e a partição revelou dois deles:
#   · 8 resíduos usavam o slot para dizer que o Elenxo NÃO rodou (`SEM-ELENXO-...`) — método;
#   · 8 diziam `HARD-MAS-NAO-COMO-ESTAVA-...` — um veredito real que faltava no enum:
#     a revisão REPROVOU e a cura entrou no mesmo PR. É a métrica de eficácia da revisão.
#   · 15 traziam a narrativa do achado — isso vira `nota:`, campo livre que não some.
#
# PROSPECTIVA POR CONSTRUÇÃO, não por baseline: esta guarda só julga o resíduo do PR CORRENTE
# (`${ART}` deriva da branch atual). Os 262 antigos nunca entram em julgamento e não se
# reescrevem — histórico não se reescreve nesta casa. A série começa aqui, com duas eras
# declaradas, e o ledger imprime as duas.
#
# CAIXA É TOLERADA, VOCABULÁRIO NÃO. `aprovado` passa e é normalizado; `CONFORME` não passa.
# A régua desta casa é que em guarda de lista o defeito dominante é o VOCABULÁRIO, não a
# lógica — reprovar por caixa seria falso-positivo travante sem ganho de série.
# ---------------------------------------------------------------------------
# SEPARADOR TAMBÉM É TOLERADO, e não por generosidade: `REPROVADO-E-CURADO` JÁ EXISTIA 5× no
# corpus, com hífen, enquanto `APROVADO_APOS_CORRECAO` usava underscore. A grafia mista é do
# histórico real desta casa — reprovar por `-` vs `_` seria inventar um defeito. A normalização
# só casa a PALAVRA INTEIRA: `CORRIGIDO-E-RE-REVISADO` continua fora do vocabulário, como deve.
VERDICT_ENUM="APROVADO CORRIGIDO REPROVADO REPROVADO_E_CURADO SEM_ACHADOS"
_VERD="$(_field verdict | tr 'a-z' 'A-Z' | tr '-' '_')"
_VERD_OK=0
for _v in ${VERDICT_ENUM}; do [ "${_VERD}" = "${_v}" ] && _VERD_OK=1; done
if [ "${_VERD_OK}" -ne 1 ]; then
  _out HARD VERDICT-FORA-DO-VOCABULARIO "${ART}" "verdict: '${_VERD}' nao esta no vocabulario fechado (${VERDICT_ENUM}). Selado em 2026-09-08 porque 262 residuos produziram 72 formas distintas e o campo deixou de sustentar serie. Se o que voce quer dizer nao cabe num dos cinco, o lugar e o campo livre 'nota:' — o veredito continua sendo um dos cinco. REPROVADO_E_CURADO existe para o caso 'a revisao reprovou e a cura entrou neste mesmo PR'."
  exit 1
fi

[ "${FORMAT}" = tsv ] || printf '  ✅ PR #%s: revisão registrada em %s, casando com o diff atual\n' "${PR_NUM}" "${ART}"
exit 0
