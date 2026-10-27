#!/usr/bin/env bash
# ===========================================================================
# mutate-and-restore.sh — planta um MUTANTE, roda o comando, e RESTAURA sempre.
#
# ── POR QUE EXISTE (dano consumado em 2026-10-01) ──────────────────────────────────────────
# Um `exit 137` (SIGKILL do OOM killer) matou a sessão NO MEIO de um teste de mutação e deixou um
# `git add` plantado dentro do `.githooks/pre-commit` — exatamente o defeito que a guarda nova existia
# para pegar. O repo ficou PIOR que antes do teste. A restauração era um `cp` DEPOIS do laço, e `cp`
# depois do laço só roda se o processo sobreviver.
#
# ⚠️ E A CURA ÓBVIA NÃO BASTA, medido: `trap` NÃO intercepta SIGKILL. Um helper que só confia em trap
# seria cura falsa para o caso que de fato ocorreu. Por isso a defesa é em DUAS camadas:
#   1. `trap` em EXIT/INT/TERM/HUP — cobre erro, Ctrl-C e término normal (a maioria dos casos);
#   2. MARKER no mutante + guarda no lint que reprova o marcador — cobre SIGKILL, queda de energia e
#      qualquer morte que trap não vê. Mesmo que o processo evapore, o PRÓXIMO lint acusa.
#
# A camada 2 é a que importa: ela não depende de o processo sobreviver para funcionar.
#
# ── A ÂNCORA ÚNICA E A LINHA DE BASE (2026-10-27) ──────────────────────────────────────────────
# A curadoria mediu este helper contra o mutate.py de um framework irmão, no mesmo alvo e no mesmo teste
# (docs/evolution/dissect/cortex-2026-10/ no core), e achou três lacunas do helper, todas de AFIRMAÇÃO FALSA:
#   1. âncora REPETIDA: a 1ª versão trocava a 1ª ocorrência em silêncio, e o mutante podia cair numa
#      linha que nenhum caso exercita: o "sobreviveu" vinha da escolha do helper, não do teste;
#   2. o rc 3 valia tanto para "não plantei" quanto para um teste que sai 3: quem lia o rc não sabia
#      se o mutante tinha existido;
#   3. ninguém rodava o teste SEM o mutante antes: com a linha de base já vermelha, todo mutante sai
#      "morto", e a morte não prova nada (a curadoria pegou o irmão respondendo "pin OK" para um teste
#      que falhava por ImportError).
# A cura: a âncora é contada (sobreposições incluídas: 'aa' em 'aaa' são DUAS) e só a única muta; o
# teste roda antes, sem o mutante, e a linha de base vermelha recusa; e o rc deixou de ser o do teste
# cru: o rc do comando vai para stderr, e o do helper diz o que aconteceu, sem colisão.
#
# USO:  bash ops/mutate-and-restore.sh <arquivo> <python-expr> <comando...>
#       <python-expr> = 'ANTIGO|||NOVO' (substituição literal) — ANTIGO tem de ocorrer EXATAMENTE 1 vez no
#       arquivo, e o NOVO deve conter o marcador ONION_MUTANTE, senão este script RECUSA (fail-closed:
#       mutante sem marcador é o mutante que some sem rastro).
#       Antes de plantar, o <comando> roda SEM o mutante (a linha de base) e tem de sair 0. Ele roda DUAS
#       vezes, então tem de ser IDEMPOTENTE (um `mkdir d` sairia "morto" na 2ª só pelo estado) e NÃO pode
#       ler o stdin (a linha de base o consumiria, e a rodada mutada leria EOF). O helper não guarda o stdin
#       de propósito: chamado dentro de um `while read … done <<EOF`, guardá-lo comeria o resto do laço.
#       Env MUTATE_BASELINE_PROVEN="<evidência>": pula a linha de base, DECLARADO em stderr. Só para quem
#       acabou de medir o MESMO comando verde no MESMO conteúdo (a família do chamador provou o rc 0 no
#       caso dela antes dos mutantes), ou para o CONTROLE POSITIVO, cujo mutante deve sobreviver e cuja
#       linha de base o chamador mediu à parte; nunca para economizar sem essa medida.
#       As duas variáveis MUTATE_* NÃO passam para o <comando>: um helper aninhado mede a própria linha de base.
#       Env MUTATE_RC_FILE=<caminho>: o helper grava ali o rc CRU do comando com o mutante (só quando ele
#       rodou; o arquivo é apagado no início). Para o chamador cujo caso espera um rc ≠0 específico.
# SAÍDA (o rc é do HELPER; o rc cru do comando sai em stderr como "mutate: rc do comando = N"):
#   0  plantado, e o comando com o mutante saiu 0: o mutante SOBREVIVEU
#   1  plantado, e o comando com o mutante saiu ≠0 (qualquer valor, inclusive 3): o mutante MORREU
#   2  uso inválido, alvo inexistente, âncora vazia ou NOVO sem o marcador (nada plantado, nada rodado)
#   3  âncora AUSENTE no alvo (nada plantado)
#   4  âncora REPETIDA no alvo; a mensagem nomeia a contagem (nada plantado)
#   5  linha de base VERMELHA: o comando sem o mutante já sai ≠0 (nada plantado)
#   6  não consegui escrever o mutante (erro de E/S ou de leitura do alvo; nada plantado)
#   9  a restauração FALHOU: o backup fica onde a mensagem diz. NÃO COMMITE.
# Quem consome lê o rc, nunca a prosa: 3, 4, 5 e 6 são "não plantou"; só 0 e 1 são veredito de mutante.
# ===========================================================================
set -uo pipefail
MARKER='ONION_MUTANTE'
TARGET="${1:-}"; MUT_EXPR="${2:-}"; shift 2 || true
[ -n "${MUTATE_RC_FILE:-}" ] && rm -f -- "${MUTATE_RC_FILE}"   # rc velho de outra rodada não pode responder por esta
[ -f "${TARGET}" ] || { echo "mutate: alvo inexistente: '${TARGET}'" >&2; exit 2; }
[ -n "${MUT_EXPR}" ] && [ "$#" -gt 0 ] || { sed -n '/^# USO:/,/^# Quem consome/p' "$0" >&2; exit 2; }
case "${MUT_EXPR}" in *'|||'*) : ;; *) echo "mutate: expr precisa ser 'ANTIGO|||NOVO'" >&2; exit 2 ;; esac
[ -n "${MUT_EXPR%%|||*}" ] || { echo "mutate: RECUSADO — a âncora (o lado ANTIGO) está vazia." >&2; exit 2; }
case "${MUT_EXPR#*|||}" in *"${MARKER}"*) : ;; *)
  echo "mutate: RECUSADO — o lado NOVO precisa conter o marcador ${MARKER}." >&2
  echo "        Mutante sem marcador é o que desaparece sem rastro quando o processo morre." >&2
  exit 2 ;;
esac

# o backup tem de EXISTIR antes do trap: com o `cp` falho (alvo sem leitura), a 1ª versão armava a
# restauração com um backup vazio e, no EXIT, podia truncar o alvo por cima.
_BACKUP="$(mktemp)"
if ! cp -p "${TARGET}" "${_BACKUP}" 2>/dev/null || ! _HASH0="$(sha256sum "${TARGET}" 2>/dev/null | cut -d' ' -f1)" || [ -z "${_HASH0}" ]; then
  rm -f "${_BACKUP}"; echo "mutate: não consegui ler ${TARGET} para o backup — nada plantado (rc 6)" >&2; exit 6
fi
_BLOG=""
_restore() {
  [ -n "${_BLOG}" ] && rm -f "${_BLOG}" 2>/dev/null
  [ -n "${_BACKUP:-}" ] || return 0
  cp -p "${_BACKUP}" "${TARGET}" 2>/dev/null
  local _h; _h="$(sha256sum "${TARGET}" 2>/dev/null | cut -d' ' -f1)"
  if [ "${_h}" != "${_HASH0}" ]; then
    # o backup FICA: a 1ª versão o apagava logo depois de dizer onde ele estava
    echo "❌ mutate: RESTAURAÇÃO FALHOU em ${TARGET} — o backup está em ${_BACKUP}. NÃO COMMITE." >&2
    _BACKUP=""; exit 9
  fi
  rm -f "${_BACKUP}" 2>/dev/null; _BACKUP=""
}
# EXIT restaura sempre; o sinal SAI (pelo EXIT, que restaura). Na 1ª versão o trap de INT restaurava e o
# script SEGUIA: um Ctrl-C durante a linha de base deixaria o helper plantar e rodar o mutante depois.
trap _restore EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

# 1) a âncora: contada no alvo ANTES de rodar qualquer coisa (sem custo de teste para o que não vai plantar)
_count_rc=0
_count="$(python3 -I -B - "${TARGET}" "${MUT_EXPR}" <<'PY'
import sys
p, expr = sys.argv[1], sys.argv[2]
a = expr.split('|||', 1)[0]
try:
    s = open(p, 'rb').read().decode('utf-8', 'surrogateescape')
except OSError as e:
    sys.stderr.write(f"mutate: não consegui ler {p}: {e}\n"); sys.exit(6)
n, i = 0, s.find(a)
while i != -1:            # sobreposições contam: 'aa' em 'aaa' é ambíguo, e str.count diria 1
    n += 1; i = s.find(a, i + 1)
print(n)
PY
)" || _count_rc=$?
[ "${_count_rc}" = 0 ] || { echo "mutate: não consegui contar a âncora em ${TARGET} (rc ${_count_rc})" >&2; exit 6; }
_anchor="${MUT_EXPR%%|||*}"
case "${_count}" in
  0) echo "mutate: âncora AUSENTE em ${TARGET}: '${_anchor:0:60}' — nada plantado (rc 3)" >&2; exit 3 ;;
  1) : ;;
  *) echo "mutate: âncora REPETIDA em ${TARGET}: ${_count} ocorrências de '${_anchor:0:60}' (precisa 1) — nada plantado (rc 4)" >&2; exit 4 ;;
esac

# o comando nunca herda as variáveis do helper (um helper aninhado pularia a própria linha de base)
_run() { env -u MUTATE_BASELINE_PROVEN -u MUTATE_RC_FILE "$@"; }

# 2) a linha de base: o MESMO comando, SEM o mutante, tem de sair 0
if [ -n "${MUTATE_BASELINE_PROVEN:-}" ]; then
  echo "mutate: ⚠️ linha de base NÃO rodada (MUTATE_BASELINE_PROVEN=${MUTATE_BASELINE_PROVEN})" >&2
else
  _BLOG="$(mktemp)"
  _run "$@" > "${_BLOG}" 2>&1; _brc=$?
  if [ "${_brc}" -ne 0 ]; then
    echo "mutate: linha de base VERMELHA — o comando SEM o mutante saiu ${_brc}; um mutante 'morto' aqui não provaria nada (rc 5). Fim da saída dela:" >&2
    tail -5 "${_BLOG}" | sed 's/^/  | /' >&2
    rm -f "${_BLOG}"; exit 5
  fi
  rm -f "${_BLOG}"
fi

# 3) planta: troca a ocorrência única, preservando bytes (sem reescrever fins de linha)
python3 -I -B - "${TARGET}" "${MUT_EXPR}" <<'PY' || { echo "mutate: não consegui escrever o mutante em ${TARGET} (rc 6)" >&2; exit 6; }
import sys
p, expr = sys.argv[1], sys.argv[2]
a, b = expr.split('|||', 1)
s = open(p, 'rb').read().decode('utf-8', 'surrogateescape')
if s.count(a) != 1:
    sys.exit(1)           # o alvo mudou entre a contagem e a escrita: não planta às cegas
open(p, 'wb').write(s.replace(a, b, 1).encode('utf-8', 'surrogateescape'))
PY

# 4) o comando com o mutante: o rc cru vai para stderr; o do helper é 0 (sobreviveu) ou 1 (morreu)
_run "$@"; _rc=$?
echo "mutate: rc do comando = ${_rc}" >&2
[ -n "${MUTATE_RC_FILE:-}" ] && printf '%s\n' "${_rc}" > "${MUTATE_RC_FILE}"
[ "${_rc}" -eq 0 ] && exit 0
exit 1
