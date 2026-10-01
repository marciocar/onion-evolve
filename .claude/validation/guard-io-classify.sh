#!/usr/bin/env bash
# ===========================================================================
# guard-io-classify.sh — classifica cada ponto do gate em ESCRITOR / LEITOR / NÃO-MEDIDO.
#
# ── POR QUE EXISTE, e por que NÃO JULGA NADA ───────────────────────────────────────────────
# Passo 1 (e só o passo 1) da Capacidade 1 do plano de absorção de capacidades de motor (o doc vive
# no repo-fonte, que é PRIVADO — citado pelo NOME, sem caminho, porque este script viaja pela porta
# pública e quem a ler não pode abrir caminho core-privado), selado pelo maestro em 2026-10-01:
# *"primeiro tem que analisar a proposta e suas consequências e o que pode quebrar"*. Este script
# ENTREGA A LISTA e nada mais. Não emite violação, não entra no lint, não reprova commit.
#
# O QUE ELE RESPONDE, e são DUAS perguntas que pagam contas diferentes:
#   1. ORDEM (Cap. 1): a única convenção de ordenação que existe no mundo — medida na rodada de
#      2026-10-01 — é *"quem só LÊ roda depois de quem ESCREVE"* (pacote `precommit` do R). Para
#      aplicá-la é preciso saber quem é quem, e a classe tem de ser DERIVADA, nunca declarada à mão:
#      declaração que ninguém confere envelhece (é a classe `declarado ≠ verificado`).
#   2. GATILHO DA CAP. 3: a análise de conflito por SMT (Cedar) só vale para DECISÃO PURA — sem ler
#      arquivo, sem escrever, sem depender de ordem. Se existir um subconjunto do gate com essa forma,
#      ele é candidato legítimo; se não existir, a Cap. 3 fica recusada com razão medida em vez de
#      suposta. Esta classificação é o insumo dessa resposta.
#
# ⚠️ TETO DECLARADO, e ele é o motivo de existir o rótulo NÃO-MEDIDO: a classe sai de heurística
# TEXTUAL. Escrita feita por helper indireto, ou leitura via variável montada em runtime, não aparece.
# O script NUNCA chuta: o que não consegue classificar sai como NÃO-MEDIDO e FICA VISÍVEL — mesmo
# dialeto do `resolve-production-branch.sh` ("sem candidato identificável, o STDOUT sai VAZIO").
#
# USO:  bash .claude/validation/guard-io-classify.sh [REPO] [--tsv]
# SAÍDA: tabela legível (default) ou TSV. Exit 0 sempre que conseguiu ler os dois arquivos; 3 se não.
# ===========================================================================
set -uo pipefail
REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
case "${1:-}" in --tsv) REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; TSV=1 ;; *) TSV=0 ;; esac
[ "${2:-}" = "--tsv" ] && TSV=1
LINT="${REPO}/.claude/validation/lint-artifacts.sh"
HOOK="${REPO}/.githooks/pre-commit"
[ -r "${LINT}" ] || { echo "guard-io: lint ilegível em ${LINT} — NÃO PUDE JULGAR" >&2; exit 3; }
[ -r "${HOOK}" ] || { echo "guard-io: hook ilegível em ${HOOK} — NÃO PUDE JULGAR" >&2; exit 3; }

_emit() { if [ "${TSV}" = "1" ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"; else printf '  %-10s %-34s l.%-5s %s\n' "$1" "$2" "$3" "$4"; fi; }

[ "${TSV}" = "1" ] || {
  echo "# Classificação I/O do gate — ESCRITOR · LEITOR · NÃO-MEDIDO"
  echo "# Passo 1 da Capacidade 1: IMPRIME, não julga. Heurística textual; o que não casa sai NÃO-MEDIDO."
  echo
  echo "## .githooks/pre-commit — o ESCRITOR do par (muta o índice)"
}
# ESCRITOR no hook: muta índice ou reescreve arquivo rastreado
# ⚠️ COMENTÁRIO E MENSAGEM NÃO SÃO ESCRITA, e eu errei nisto na 1ª versão: das 8 linhas que a
# heurística crua devolveu, TRÊS eram falso positivo — um comentário explicando o `git add` e duas
# mensagens de erro que o citam. Conferi à mão, como o plano exige, e a conferência me corrigiu.
# Logo: linha que começa com `#`, ou cuja ocorrência está DENTRO de um `echo`, sai como NÃO-MEDIDO —
# não como escritor. Classificar com confiança onde se devia hesitar é o defeito que o rótulo
# NÃO-MEDIDO existe para impedir.
grep -nE 'git add|sed -i|> *"\$\{REPO_ROOT\}' "${HOOK}" | while IFS=: read -r n rest; do
  _t="$(printf '%s' "${rest}" | sed 's/^[[:space:]]*//')"
  case "${_t}" in
    '#'*)            _emit "NÃO-MEDIDO" "pre-commit" "${n}" "comentário — cita, não executa" ; continue ;;
  esac
  # ⚠️ E A CORREÇÃO DA CORREÇÃO, porque eu quebrei o certo tentando consertar o errado: `git add X ||
  # echo "aviso"` EXECUTA a escrita e TEM echo. Filtrar por "contém echo" derrubou 4 escritores reais.
  # O teste é a POSIÇÃO: echo ANTES do verbo é menção; echo DEPOIS é aviso de falha. Usa-se o
  # PREFIXO da linha, não a presença da palavra.
  case "${_t}" in
    echo*|printf*)   _emit "NÃO-MEDIDO" "pre-commit" "${n}" "a linha É uma mensagem — cita, não executa" ; continue ;;
  esac
  case "${_t}" in
    'git add'*) _emit "ESCRITOR" "pre-commit" "${n}" "muta o índice" ;;
    *'sed -i'*) _emit "ESCRITOR" "pre-commit" "${n}" "reescreve arquivo" ;;
    *)          _emit "ESCRITOR" "pre-commit" "${n}" "redireciona para o repo" ;;
  esac
done

[ "${TSV}" = "1" ] || { echo; echo "## lint-artifacts.sh — o LEITOR do par (compara projeção vs fonte)"; }
# LEITOR no lint: compara projeção gerada contra a fonte
grep -nE 'byte-a-byte|projeção desatualizada|regenere com|índice DEFASADO' "${LINT}" | while IFS=: read -r n rest; do
  _emit "LEITOR" "lint-artifacts" "${n}" "compara projeção com a fonte"
done

[ "${TSV}" = "1" ] || { echo; echo "## As 93 guardas — alguma ESCREVE? (a pergunta que decide o escopo)"; }
_w="$(grep -cE '^\s*(git add|sed -i)' "${LINT}" || true)"
if [ "${_w}" = "0" ]; then
  _emit "LEITOR" "as 93 check_*" "-" "ZERO escrita detectada no corpo do lint — o motor só LÊ"
else
  _emit "NÃO-MEDIDO" "as 93 check_*" "-" "${_w} sítio(s) de escrita no lint — classificar um a um"
fi

[ "${TSV}" = "1" ] || {
  echo
  echo "## Insumo para o gatilho da Capacidade 3 (SMT só vale em DECISÃO PURA)"
}
_fs="$(grep -cE 'find |git ls-files|grep -r' "${LINT}" || true)"
_emit "NÃO-MEDIDO" "decisão pura?" "-" "${_fs} sítio(s) do lint tocam o sistema de arquivos — subconjunto de decisão pura ainda NÃO ISOLADO"
exit 0
