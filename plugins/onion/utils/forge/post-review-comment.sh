#!/usr/bin/env bash
# =============================================================================
# post-review-comment.sh — materialização EXECUTÁVEL de `addReviewComment` (transporte `api`).
#
# ── POR QUE ESTE ARQUIVO EXISTE, E O QUE ELE NÃO É ───────────────────────────────────────────
# O SDAAL do forge é MARKDOWN LIDO POR LLM, não código — está escrito na KB do padrão:
# "documentação Markdown substitui código executável" (specification-driven-ai-abstraction-layer.md).
# Um step de GitHub Actions é SHELL PURO: não há LLM ali para ler a spec. Logo, um workflow NUNCA
# pôde "chamar a abstração", e é por isso que `onion-review.yml` postava com `gh api` cru — sem
# isenção declarada, e literalmente a operação que `setup-code-review.md` manda fazer pelo adapter.
#
# Este script é a materialização de UMA operação, no transporte `cli`, para consumidores que não
# são LLM. Ele É TRANSPORTE, não é a abstração: quem quer a abstração lê a spec. Não torna o SDAAL
# executável — abre a porta para as próximas operações quando houver demanda MEDIDA, e não antes.
#
# CONTRATO DE ORIGEM (a spec que ele obedece):
#   ${CLAUDE_PLUGIN_ROOT}/utils/forge/interface.md   — `addReviewComment(prRef, comment)`
#   ${CLAUDE_PLUGIN_ROOT}/utils/forge/types.md       — `ReviewCommentInput { body, path?, line? }`
#   ${CLAUDE_PLUGIN_ROOT}/utils/forge/adapters/github.md — os dois transportes
#
# ⚠️ É TRANSPORTE `api`, NÃO `cli` — o rótulo estava TROCADO na 1ª versão e foi medido por
# COMPORTAMENTO, não por leitura: com um stub de `gh` no PATH, este script faz DUAS chamadas e
# AMBAS são `gh api` (`issues/{n}/comments`), zero `gh pr comment`. A spec reserva `gh pr comment`
# para o ramo `cli` (github.md:209) e `issues/{n}/comments` para o ramo `api` (github.md:214);
# `gh api` no modo cli existe só para o caso INLINE, que este script declara não materializar.
#
# SÃO TRÊS OPERAÇÕES, e as duas que FALTAVAM foram ADICIONADAS À SPEC neste mesmo PR — que é o
# que o SDAAL manda fazer quando falta peça: a abstração cresce, o consumidor não contorna.
#   1. CRIAR          → `addReviewComment` (interface.md)            — já existia
#   2. LISTAR+FILTRAR → `getReviewComments` (interface.md)           — já existia
#   3. EDITAR POR ID  → `updateReviewComment` (interface.md)         — CRIADA aqui
#   + o modo STICKY   → `ReviewCommentInput.upsertBy` (types.md)     — CRIADO aqui
# Este script CITA a spec; não a estende. A 1ª versão fazia o inverso — implementava o sticky e o
# edit-por-id sem que existissem na interface — e por isso nasceu órfão. Regra que fica: quando um
# consumidor CONTORNA a abstração, o defeito é da abstração até prova em contrário.
#
# ⚠️ EXTENSÃO QUE A SPEC NÃO TEM — e a lacuna é medida, não estética: o modo STICKY.
# A spec sempre CRIA comentário. Mas a casa mediu no PR #529 que o workflow roda em `synchronize`,
# então 2 pushes viraram 2 comentários e 2 e-mails — "alarme que chega repetido é alarme que se
# aprende a ignorar". A cura é UM comentário por PR, EDITADO (editar não dispara notificação nova).
# Isso está implementado aqui e NÃO está em `interface.md`. Quando a interface absorver, este
# arquivo passa a citá-la em vez de estendê-la.
#
# NÃO MATERIALIZADO de propósito: o caminho inline (`path`+`line`). A spec o tem, mas o consumidor
# deste PR usa comentário geral (decisão do maestro: um pegajoso, não N inline). Construir o que
# não se exercita é como a REGRA 57 quase nasceu — cobrindo ramo sem caso real.
#
# Uso:
#   post-review-comment.sh --pr <N> --body-file <arquivo> [--sticky <marca-html>] [--repo o/r] [--dry-run]
#
# Exit: 0 SEMPRE que classificou (inclusive falha de rede — posting não reprova PR; degrada com
#       ::warning::). 2 só em erro de USO. É o mesmo contrato de review-verdict.sh.
# =============================================================================
set -uo pipefail

PR=""; BODY_FILE=""; MARCA=""; REPO="${GITHUB_REPOSITORY:-}"; DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --pr)        PR="${2:-}"; shift 2 ;;
    --body-file) BODY_FILE="${2:-}"; shift 2 ;;
    --sticky)    MARCA="${2:-}"; shift 2 ;;
    --repo)      REPO="${2:-}"; shift 2 ;;
    --dry-run)   DRY=1; shift ;;
    -h|--help)   sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "post-review-comment: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

[ -n "${PR}" ] || { echo "uso: post-review-comment.sh --pr <N> --body-file <f> [--sticky <marca>] [--repo o/r] [--dry-run]" >&2; exit 2; }
[ -n "${BODY_FILE}" ] && [ -f "${BODY_FILE}" ] || { echo "post-review-comment: --body-file ausente ou inexistente: ${BODY_FILE:-<vazio>}" >&2; exit 2; }

# CORPO VAZIO NÃO É SUCESSO. Postar comentário em branco é pior que não postar: parece que houve
# parecer e não houve. Mesma família do fail-open que este repo passou o dia curando.
if [ ! -s "${BODY_FILE}" ]; then
  echo "::warning::post-review-comment: corpo VAZIO em ${BODY_FILE} — nada postado (corpo vazio nao e parecer)"
  exit 0
fi

if [ -z "${REPO}" ]; then
  REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
fi
[ -n "${REPO}" ] || { echo "::warning::post-review-comment: repo nao resolvido (nem GITHUB_REPOSITORY nem gh repo view) — nada postado"; exit 0; }

# ── STICKY: procura o comentário já existente pela MARCA ─────────────────────────────────────
# Casa pela marca HTML (invisível no render). Sem marca, cai no comportamento da spec: sempre cria.
EXISTENTE=""
if [ -n "${MARCA}" ]; then
  if [ "${DRY}" -eq 1 ]; then
    EXISTENTE="${DRY_EXISTENTE:-}"          # o selftest injeta o estado, sem rede
  else
    EXISTENTE="$(gh api "repos/${REPO}/issues/${PR}/comments" --paginate \
      --jq "[.[] | select(.user.login == \"github-actions[bot]\") | select(.body | contains(\"${MARCA}\"))] | last | .id // empty" \
      2>/dev/null || true)"
  fi
fi

if [ "${DRY}" -eq 1 ]; then
  if [ -n "${EXISTENTE}" ]; then
    printf 'PATCH\t%s\t%s\t%s\n' "${REPO}" "${EXISTENTE}" "$(wc -c < "${BODY_FILE}" | tr -d ' ')"
  else
    printf 'POST\t%s\t%s\t%s\n' "${REPO}" "${PR}" "$(wc -c < "${BODY_FILE}" | tr -d ' ')"
  fi
  exit 0
fi

# O STDERR DO `gh` E O DIAGNOSTICO — nao pode ir para /dev/null. A 1a versao redirecionava os dois
# fluxos, e a causa (403 de permissao, 404 de PR errado, rate limit) sumia; sobrava um
# "falhei ao POSTAR" que nao diz o que consertar. E a mesma classe de silencio que este PR existe
# para curar, cometida no proprio conserto.
ERRF="$(mktemp)"
if [ -n "${EXISTENTE}" ]; then
  if gh api -X PATCH "repos/${REPO}/issues/comments/${EXISTENTE}" -F "body=@${BODY_FILE}" >/dev/null 2>"${ERRF}"; then
    echo "post-review-comment: comentario ${EXISTENTE} ATUALIZADO (edicao nao gera e-mail novo)"
  else
    echo "::warning::post-review-comment: falhei ao ATUALIZAR o comentario ${EXISTENTE} — segue sem bloquear. gh disse: $(tr '\n' ' ' < "${ERRF}" | head -c 300)"
  fi
else
  if gh api -X POST "repos/${REPO}/issues/${PR}/comments" -F "body=@${BODY_FILE}" >/dev/null 2>"${ERRF}"; then
    echo "post-review-comment: comentario POSTADO no PR #${PR}"
  else
    echo "::warning::post-review-comment: falhei ao POSTAR no PR #${PR} — segue sem bloquear. gh disse: $(tr '\n' ' ' < "${ERRF}" | head -c 300)"
  fi
fi
rm -f "${ERRF}"
exit 0
