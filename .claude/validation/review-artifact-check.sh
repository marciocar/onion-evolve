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
#        bash .claude/validation/review-artifact-check.sh --skeleton [<branch>]   → o ESQUELETO do resíduo (stdout)
#        bash .claude/validation/review-artifact-check.sh --schema <arquivo>     → só o frontmatter, em ms
#        bash .claude/validation/review-artifact-check.sh --legacy-candidates [<ref>] → os resíduos de <ref> na forma antiga
# Saída: relatório humano (default) ou TSV (severidade·tag·path·mensagem)
# Exit : 0 = artefato presente e casando, ou fora de escopo · 1 = falta/caducou · 2 = uso inválido
#
# ═══ O ESQUEMA MORA AQUI, E SÓ AQUI (SAC-142, decisão do maestro de 2026-10-15) ═══
# Medido de 10-05 a 10-15: 12 resíduos nasceram fora do esquema (verdict fora do vocabulário, campo numérico
# ausente, `reviewed_code_sha256: pendente`), todos escritos à mão porque NÃO HAVIA gerador — o /engineer:pr
# mandava a sessão escrever o arquivo, e os campos só existiam em prosa e aqui dentro. O pr-finalize os achava
# no FIM, depois do pré-voo (3 min 51 s no caso de 2026-10-15). Agora o esqueleto (`--skeleton`) e a conferência
# rápida (`--schema`) leem as MESMAS constantes que o julgamento do PR: o esquema muda num lugar só.
set -euo pipefail

# ═══ VALOR DE CAMPO DE MÁQUINA É CÓDIGO, E CÓDIGO É EM INGLÊS (decisão do maestro de 2026-11-08) ═══
# A prosa do resíduo segue em pt-BR; o VALOR dos campos que um script lê passou ao inglês:
# `verdict` em APPROVED|FIXED|REJECTED|REJECTED_AND_FIXED|NO_FINDINGS e `elenxo`/`elenxo_isolado`
# em true|false. O LEGADO não se reescreve: a forma antiga (APROVADO…, sim|nao) só vale num resíduo
# da LISTA CONGELADA (`docs/evolution/review-residue-legacy.txt`, os que existiam na origin/main no último rebase (gerados por --legacy-candidates), com
# algum valor na forma antiga). Fora dela, resíduo com valor antigo é recusado. A CATRACA
# (`_legacy_ratchet_problems`) impede a lista de crescer: só desce, nunca ganha entrada.
VERDICT_ENUM="APPROVED FIXED REJECTED REJECTED_AND_FIXED NO_FINDINGS"
VERDICT_ENUM_LEGACY="APROVADO CORRIGIDO REPROVADO REPROVADO_E_CURADO SEM_ACHADOS"
BOOL_ENUM="true false"
BOOL_ENUM_LEGACY="sim nao"
BOOL_FIELDS="elenxo elenxo_isolado"
# A LISTA MORA EM docs/evolution/, FORA de .claude/: os nomes dos resíduos carregam nomes de adotante, e .claude/
# viaja para todo adotante (REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) a barrou ali).
LEGACY_LIST_REL="docs/evolution/review-residue-legacy.txt"
LEGACY_LIST="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/${LEGACY_LIST_REL}"
NUMERIC_FIELDS="findings_total findings_real tokens duration_min"
# `findings_blocking` (2026-11-06): quantos dos achados REAIS BLOQUEIAM — o veredito pode sair diferente numa
# direção previsível ou ao arbítrio de quem conduz, ou o artefato promete o que não entrega; o resto é LIMITE,
# que entra declarado. Régua: .claude/commands/common/prompts/review-triage.md. OPCIONAL por desenho: os
# resíduos anteriores não o têm e seguem válidos (histórico não se reescreve). PRESENTE, tem de ser número e
# caber em 0 ≤ blocking ≤ findings_real — bloqueio que não é achado real é contagem inventada.
# Lição de origem (curadoria, 2026-11-05): o pré-registro do problem-route passou por 8 versões em 3 h 28 min,
# cada rodada tratando todo achado como bloqueio; com a triagem pedida na 7ª rodada, fechou em 2 (nó
# C_REVIEW_TRIAGE_IN_PATH_1105 e vizinhos, grafo curation-process-2026-11 do repo da curadoria).
_blocking_problem() {  # $1=arquivo → vazio se ok; senão a frase do problema
  local b r; b="$(_field_of "$1" findings_blocking)"
  grep -qE '^findings_blocking:' <(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1' "$1") || return 0
  case "${b}" in ''|*[!0-9]*) echo "findings_blocking tem de ser número (quantos dos achados reais BLOQUEIAM; 0 se todos são LIMITE), não '${b}'"; return 0 ;; esac
  r="$(_field_of "$1" findings_real)"
  case "${r}" in ''|*[!0-9]*) return 0 ;; esac   # o findings_real inválido já é nomeado pela checagem dele
  [ "$((10#${b}))" -le "$((10#${r}))" ] || echo "findings_blocking (${b}) maior que findings_real (${r}): só achado REAL pode bloquear"
  return 0
}

_field_of() {  # $1=arquivo $2=campo — só o frontmatter, sem aspas
  awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1' "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1 | tr -d '"'
}
_review_rel() {  # $1=caminho → docs/evolution/review/<x>.md (a chave da lista), ou vazio
  case "$1" in
    docs/evolution/review/*) printf '%s' "$1" ;;
    */docs/evolution/review/*) printf 'docs/evolution/review/%s' "${1##*/docs/evolution/review/}" ;;
  esac
}
_legacy_root() { (cd "$(dirname "${LEGACY_LIST}")/../.." 2>/dev/null && pwd); }   # a lista mora em <root>/docs/evolution/
_base_of() {  # $1=root → o merge-base com a branch default (a base CONTRA A QUAL o trabalho foi feito), ou vazio
  local d; d="$(git -C "$1" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)"
  [ -n "${d}" ] || d=main
  git -C "$1" merge-base "origin/${d}" HEAD 2>/dev/null || git -C "$1" merge-base "${d}" HEAD 2>/dev/null || true
}
# LEGADO = ESTÁ NA LISTA **E** NÃO FOI TOCADO. A 1ª versão chaveava só pelo CAMINHO, e o refutador mostrou o
# ataque: uma branch nova com o slug de um resíduo legado (`feat/decide-painel`) reescreve o arquivo com APROVADO e
# `sim`, e passava. Slug repetido não é hipótese: 6 em 1530 PRs. O que o legado protege é o ARQUIVO HISTÓRICO,
# byte a byte; o resíduo que o PR toca é trabalho novo e sai no formato novo, esteja ou não na lista.
_is_legacy() {  # $1=caminho [$2=base] [$3=blob julgado] → 0 só se na lista E idêntico ao da base
  local r root base cur; r="$(_review_rel "$1")"
  [ -n "${r}" ] && [ -f "${LEGACY_LIST}" ] && grep -qxF -- "${r}" "${LEGACY_LIST}" || return 1
  root="$(_legacy_root)"; [ -n "${root}" ] || return 1
  base="${2:-$(_base_of "${root}")}"
  cur="${3:-$(git -C "${root}" hash-object -- "$1" 2>/dev/null)}"
  # INTOCADO: o blob julgado é o da base. Sem base, sem blob ou ausente na base, não se prova — não é legado.
  [ -n "${base}" ] && [ -n "${cur}" ] && [ "$(git -C "${root}" rev-parse -q --verify "${base}:${r}" 2>/dev/null)" = "${cur}" ] || return 1
  return 0
}
# CHAVE DUPLICADA: o bash lê a 1ª ocorrência e o YAML (drive-automate) leria a última — o mesmo resíduo diria duas
# coisas a dois leitores. Medido em 2026-11-08: 0 dos 958 resíduos tinham chave repetida, então recusar não quebra nada.
_dup_keys() {  # $1=arquivo → as chaves de topo repetidas no frontmatter, separadas por espaço
  awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1 && /^[A-Za-z_][A-Za-z0-9_]*:/{k=$0; sub(/:.*/,"",k); if (c[k]++==1) printf "%s ", k}' "$1"
}
_verdict_ok() {  # $1=valor [$2=legacy] — caixa e separador tolerados, palavra inteira
  local v e; v="$(printf '%s' "$1" | tr 'a-z' 'A-Z' | tr '-' '_')"
  e="${VERDICT_ENUM}"; [ "${2:-}" = legacy ] && e="${e} ${VERDICT_ENUM_LEGACY}"
  for _v in ${e}; do [ "${v}" = "${_v}" ] && return 0; done; return 1
}
_bool_problems() {  # $1=arquivo $2=legacy|'' → uma frase por campo booleano fora do vocabulário
  local f="$1" k v e
  e="${BOOL_ENUM}"; [ "${2:-}" = legacy ] && e="${e} ${BOOL_ENUM_LEGACY}"
  for k in ${BOOL_FIELDS}; do
    grep -qE "^${k}:" <(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1' "${f}") || continue
    v="$(_field_of "${f}" "${k}" | tr 'A-Z' 'a-z' | tr -d '[:space:]')"
    case " ${e} " in *" ${v} "*) ;; *)
      case " ${BOOL_ENUM_LEGACY} " in
        *" ${v} "*) echo "${k}: '${v}' é a forma ANTIGA — resíduo novo usa true|false (a forma antiga só vale nos resíduos de ${LEGACY_LIST_REL})" ;;
        *) echo "${k} tem de ser true ou false, não '${v}'" ;;
      esac ;;
    esac
  done
  return 0
}
_verdict_problem() {  # $1=valor $2=legacy|'' → a frase do problema, ou vazio
  _verdict_ok "$1" "${2:-}" && return 0
  if _verdict_ok "$1" legacy; then
    echo "verdict '$1' é a forma ANTIGA — resíduo novo usa ${VERDICT_ENUM// / | } (a forma antiga só vale nos resíduos de ${LEGACY_LIST_REL})"
  else
    echo "verdict '$1' fora do vocabulário fechado (${VERDICT_ENUM})"
  fi
}
# A CATRACA DO LEGADO: a lista só DESCE. Três recusas: entrada que a base não tinha (o legado não
# ganha membro novo), lista maior que a da base, e entrada órfã (arquivo que não existe mais — a
# entrada sai junto com ele). Sem lista NÃO há legado, logo não há o que catracar (adotante, sandbox).
# CRESCER e ENTRADA NOVA se medem contra o MERGE-BASE (o que o PR mudou), não contra a ponta da origin/main: com
# a ponta, um PR antigo acusaria "cresceu" só porque a main desceu depois dele. A ÓRFÃ se mede na ÁRVORE.
_legacy_ratchet_problems() {  # → uma frase por problema
  [ -f "${LEGACY_LIST}" ] || return 0
  local root base_list n_cur n_base added orphan base
  root="$(_legacy_root)"
  n_cur="$(grep -c . "${LEGACY_LIST}" || true)"
  orphan="$(while IFS= read -r l; do [ -z "${l}" ] || [ -f "${root}/${l}" ] || printf '%s ' "${l}"; done < "${LEGACY_LIST}")"
  [ -z "${orphan}" ] || echo "entrada(s) órfã(s) na lista do legado (o arquivo não existe): ${orphan}— tire-as da lista"
  base="$(_base_of "${root}")"; [ -n "${base}" ] || return 0
  base_list="$(git -C "${root}" show "${base}:${LEGACY_LIST_REL}" 2>/dev/null)" || return 0
  n_base="$(grep -c . <<< "${base_list}" || true)"
  [ "${n_cur}" -le "${n_base}" ] || echo "a lista do legado CRESCEU (${n_base} → ${n_cur}) — ela só desce: resíduo novo sai no formato novo"
  added="$(grep -vxF -f <(printf '%s\n' "${base_list}") "${LEGACY_LIST}" | grep . | tr '\n' ' ' || true)"
  [ -z "${added}" ] || echo "entrada(s) que a base não tinha na lista do legado: ${added}— resíduo novo não entra no legado"
  return 0
}
_schema_problems() {  # $1=arquivo → uma linha por problema; vazio = o frontmatter cabe no esquema
  local f="$1" v
  [ "$(head -1 "${f}")" = "---" ] || { echo "sem frontmatter (a 1ª linha tem de ser ---)"; return 0; }
  v="$(_field_of "${f}" reviewed_diff_sha256)"
  case "${v}" in pendente) ;; *) grep -qE '^[0-9a-f]{64}$' <<< "${v}" || echo "reviewed_diff_sha256 tem de ser 'pendente' (revisão nova) ou o hash de 64 hex, não '${v}'" ;; esac
  v="$(_field_of "${f}" reviewed_code_sha256)"
  [ -z "${v}" ] || grep -qE '^[0-9a-f]{64}$' <<< "${v}" || echo "reviewed_code_sha256 só existe carimbado (64 hex) — apague a linha, o pr-finalize a escreve ('${v}')"
  for v in ${NUMERIC_FIELDS}; do
    case "$(_field_of "${f}" "${v}")" in ''|*[!0-9]*) echo "${v} tem de ser número (0 = não medido, e diga isso em 'nota:')" ;; esac
  done
  _blocking_problem "${f}"
  local era='' dup; _is_legacy "${f}" && era=legacy
  dup="$(_dup_keys "${f}")"; [ -z "${dup}" ] || echo "chave duplicada no frontmatter: ${dup}(o bash lê a 1ª ocorrência e o YAML a última — escreva cada chave uma vez)"
  _verdict_problem "$(_field_of "${f}" verdict)" "${era}"
  _bool_problems "${f}" "${era}"
  return 0
}

case "${1:-}" in
  --skeleton)
    _br="${2:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}"
    printf -- '---\nbranch: %s\npr: pendente\ndate: %s\nreviewed_diff_sha256: pendente\n' "${_br}" "$(date +%F)"
    # findings_blocking logo depois de findings_real: é a partição dele (os reais que BLOQUEIAM)
    for _f in ${NUMERIC_FIELDS} findings_fixed; do printf '%s: PREENCHA\n' "${_f}"
      [ "${_f}" = findings_real ] && printf 'findings_blocking: PREENCHA\n'; done
    # a orientação vai no CORPO: comentário na linha do campo vira parte do valor quando se preenche só o começo
    printf 'verdict: PREENCHA\nelenxo: PREENCHA\nreviewer: PREENCHA\nnota: ""\n---\n\n'
    printf '# Passada adversarial: `%s`\n\n' "${_br}"
    printf '> Preencha o frontmatter: os campos numéricos são números (0 = não medido, dito em `nota:`); `verdict` é um\n'
    printf '> de: %s; `elenxo` é true ou false. `reviewed_diff_sha256: pendente` fica: o pr-finalize carimba.\n' "${VERDICT_ENUM}"
    printf '> `findings_blocking` = quantos dos reais BLOQUEIAM (0 ≤ blocking ≤ real); o resto é LIMITE e vai em\n'
    printf '> `## Limites declarados`. Aqui 0 quer dizer "nenhum bloqueia": se a passada não triou, APAGUE a linha\n'
    printf '> (ausente = não triado). Régua: `.claude/commands/common/prompts/review-triage.md`.\n'
    printf '> Confira com `bash .claude/validation/review-artifact-check.sh --schema <este arquivo>`. Apague este bloco.\n\n'
    printf '## O que muda\n\n## Achados\n\n## Mutantes\n\n## Limites declarados\n'
    exit 0 ;;
  --legacy-candidates)
    # Os resíduos de <ref> (default origin/main) com algum valor na forma antiga — a lista congelada se GERA daqui
    # no último rebase antes do merge, e depois só desce. O que a origin/main ganhar DEPOIS dessa geração fica de
    # fora de propósito: resíduo mergeado não volta a ser julgado (a guarda só julga o do PR corrente), e a lista
    # não cresce — a janela é declarada, não fechada.
    _ref="${2:-origin/main}"; _root="$(_legacy_root)"
    git -C "${_root}" rev-parse -q --verify "${_ref}^{commit}" >/dev/null || { printf 'review-artifact-check: ref inválida: %s\n' "${_ref}" >&2; exit 2; }
    git -C "${_root}" archive --format=tar "${_ref}" docs/evolution/review | python3 -I -c '
import sys, tarfile, re
old = {"APROVADO", "CORRIGIDO", "REPROVADO", "REPROVADO_E_CURADO", "SEM_ACHADOS"}
out = []
with tarfile.open(fileobj=sys.stdin.buffer, mode="r|") as tf:
    for m in tf:
        if not (m.isfile() and m.name.endswith(".md") and m.name.count("/") == 3):
            continue
        lines = tf.extractfile(m).read().decode("utf-8", "replace").split("\n")
        if lines[0] != "---":
            continue
        d = {}
        for ln in lines[1:]:
            if ln == "---":
                break
            mm = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):[ \t]*(.*)$", ln)
            if mm and mm.group(1) not in d:
                d[mm.group(1)] = mm.group(2).replace(chr(34), "").strip()
        if (d.get("verdict", "").upper().replace("-", "_") in old
                or d.get("elenxo", "").lower() in ("sim", "nao")
                or d.get("elenxo_isolado", "").lower() in ("sim", "nao")):
            out.append(m.name)
print("\n".join(sorted(out)))
'
    exit 0 ;;
  --schema)
    [ -f "${2:-}" ] || { printf 'review-artifact-check: --schema <arquivo> (não achei "%s")\n' "${2:-}" >&2; exit 2; }
    _p="$(_schema_problems "$2")"
    if [ -n "${_p}" ]; then printf '  ✗ ESQUEMA %s:\n' "$2"; printf '%s\n' "${_p}" | sed 's/^/    · /'; exit 1; fi
    printf '  ✅ esquema do resíduo conforme: %s\n' "$2"; exit 0 ;;
esac

REPO_ROOT="$(cd "${1:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'review-artifact-check: repo_root inválido\n' >&2; exit 2; }
FORMAT=human
for a in "$@"; do case "$a" in tsv|--format=tsv) FORMAT=tsv ;; esac; done
cd "${REPO_ROOT}"
# O legado que vale é o do repo JULGADO, não o da cópia do script (a bancada julga sandboxes com o helper real).
LEGACY_LIST="${REPO_ROOT}/${LEGACY_LIST_REL}"

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

# A CATRACA DO LEGADO RODA ANTES DE TODA ISENÇÃO: ela julga a LISTA, não o PR — vale até no branch default.
_RATCHET="$(_legacy_ratchet_problems)"
if [ -n "${_RATCHET}" ]; then
  while IFS= read -r _l; do _out HARD LEGADO-CATRACA "${LEGACY_LIST_REL}" "${_l}"; done <<< "${_RATCHET}"
  exit 1
fi

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
# `kind: door` (2026-10-10, F2 das portas): plugins, mini e a porta source não estão na lista de papéis;
# o carimbo de porta os cobre todos (passada adversarial: guarda por lista falha pelo vocabulário).
if grep -qE '^(role:[[:space:]]*(adopted|hub|standalone)|decoupled_from:|kind:[[:space:]]*door)' "${REPO_ROOT}/.claude/.onion-version" 2>/dev/null; then
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
   && grep -qx '.github/workflows/onion-review.yml' <<< "$(git diff --name-only "${BASE}" HEAD 2>/dev/null)"; then
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
  _out HARD ARTEFATO-AUSENTE "${ART}" "PR #${PR_NUM} aberto e sem resíduo de revisão. Rode a passada adversarial e registre o resultado em ${ART} (campos: reviewed_diff_sha256 · findings_total · findings_real · findings_blocking (opcional, ≤ real) · tokens · duration_min · verdict — este ultimo em vocabulario FECHADO: APPROVED | FIXED | REJECTED | REJECTED_AND_FIXED | NO_FINDINGS; a narrativa vai em 'nota:', e 'elenxo: true|false' declara se houve passada adversarial). O hash deste diff é ${DIFF_SHA}."
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
for f in ${NUMERIC_FIELDS}; do
  v="$(_field "${f}")"
  case "${v}" in ''|*[!0-9]*) FALTAM="${FALTAM}${FALTAM:+, }${f}(nao-numerico)" ;; esac
done
[ -n "$(_field verdict)" ] || FALTAM="${FALTAM}${FALTAM:+, }verdict"
if [ -n "${FALTAM}" ]; then
  _out HARD CAMPO-DE-REAVALIACAO-AUSENTE "${ART}" "faltam: ${FALTAM}. São o dado da reavaliação em N=10 — sem eles a cadência 'todo PR' não pode ser julgada, e a falsificação declarada deste mecanismo é justamente chegar ao 10º PR sem os campos."
  exit 1
fi
_BLK="$(_blocking_problem "${ART}")"
if [ -n "${_BLK}" ]; then
  _out HARD FINDINGS-BLOCKING-INVALIDO "${ART}" "${_BLK}. O campo é opcional (resíduo sem ele segue válido); presente, conta quantos achados reais BLOQUEIAM — régua em .claude/commands/common/prompts/review-triage.md."
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
# VALORES EM INGLÊS (2026-11-08): o resíduo da lista congelada aceita as duas formas; o resto, só a nova.
# Legado só se o PR NÃO tocou o resíduo: o blob julgado (índice ou HEAD, a mesma situação do hash) é o da base.
_DUP="$(_dup_keys "${ART}")"
if [ -n "${_DUP}" ]; then
  _out HARD CHAVE-DUPLICADA "${ART}" "chave duplicada no frontmatter: ${_DUP}— o bash le a 1a ocorrencia e o YAML a ultima; escreva cada chave uma vez."
  exit 1
fi
_ERA=''; _is_legacy "${ART}" "${BASE}" "$(git rev-parse -q --verify "${_ART_REF}" 2>/dev/null)" && _ERA=legacy
_VERD="$(_field verdict | tr 'a-z' 'A-Z' | tr '-' '_')"
if ! _verdict_ok "${_VERD}" "${_ERA}"; then
  if _verdict_ok "${_VERD}" legacy; then
    _out HARD VERDICT-FORMA-ANTIGA "${ART}" "verdict: '${_VERD}' e a forma ANTIGA (pt-BR). Desde 2026-11-08 valor de campo de maquina e codigo, em ingles: ${VERDICT_ENUM}. A forma antiga so vale nos residuos de ${LEGACY_LIST_REL}, que nao crescem."
  else
    _out HARD VERDICT-FORA-DO-VOCABULARIO "${ART}" "verdict: '${_VERD}' nao esta no vocabulario fechado (${VERDICT_ENUM}). Selado em 2026-09-08 porque 262 residuos produziram 72 formas distintas e o campo deixou de sustentar serie. Se o que voce quer dizer nao cabe num dos cinco, o lugar e o campo livre 'nota:' — o veredito continua sendo um dos cinco. REJECTED_AND_FIXED existe para o caso 'a revisao reprovou e a cura entrou neste mesmo PR'."
  fi
  exit 1
fi
_BOOLP="$(_bool_problems "${ART}" "${_ERA}")"
if [ -n "${_BOOLP}" ]; then
  _out HARD BOOLEANO-FORA-DO-VOCABULARIO "${ART}" "$(printf '%s' "${_BOOLP}" | tr '\n' ';')"
  exit 1
fi

[ "${FORMAT}" = tsv ] || printf '  ✅ PR #%s: revisão registrada em %s, casando com o diff atual\n' "${PR_NUM}" "${ART}"
exit 0
