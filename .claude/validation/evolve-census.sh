#!/usr/bin/env bash
# =============================================================================
# evolve-census.sh — o RAIO-X do framework: peça 3 do /meta:evolve.
#
# ── POR QUE COMPOR EM VEZ DE MEDIR DE NOVO ───────────────────────────────────────────────────
# A casa já tem medidores determinísticos de segundos cada. O raio-X os COMPÕE — medido em
# 2026-10-04 entre ~6s (máquina folgada) e ~9s (load 12 em 8 núcleos), contra o que antes era uma
# varredura de milhões de tokens. A 1ª redação afirmava "~5s" e "1-2s cada"; o Elenxo mediu
# forge-census a 5,4s sob carga, e o número publicado foi corrigido para a faixa medida.
#
# ── A REGRA QUE ESTE SCRIPT EXISTE PARA NÃO VIOLAR: número sem medição não se imprime ────────
# ⚠️ A 1ª versão foi REPROVADA porque publicava NÚMEROS FALSOS COM CARA DE CERTOS — o modo de falha
#    mais caro possível para um raio-X, porque ele empresta autoridade ao número. Medido pelo
#    Elenxo (2026-10-04): "1 dissecação vencida" vinha de um `grep -ci vencido` casando a LEGENDA
#    do dissect-census (a única dissecação estava `fresco`), e esse número falso já tinha ido parar
#    num nó de grafo; um medidor de idade QUEBRADO fazia a seção 6 imprimir "✅ auto-auditoria
#    fresca" (verde falso); medidor que saía 1 ou 2 era engolido e virava ZERO; e no `--tsv` não
#    existia lista do não-medido. A cura é estrutural: CADA DIMENSÃO CARREGA O PRÓPRIO STATUS, e
#    número de dimensão não-medida sai `?` nos DOIS modos — nunca 0, nunca ✅.
#
# ── SEMÂNTICA DE rc, MEDIDA E NÃO SUPOSTA ────────────────────────────────────────────────────
# Os cinco medidores de contagem saem 0 quando medem. O de idade (REGRA 97) usa 1 como "achei
# sinal" — é o código de ENCONTRADO, não de falha. Logo: rc≠0 é NÃO-MEDIDO para os cinco, e
# rc≥2 para o de idade.
#
# ── O QUE ELE CONFRONTA, e a 1ª versão só declarava ──────────────────────────────────────────
# A seção 7 cruza dimensões de verdade: comandos com só a superfície (1/7) que JÁ têm guarda
# citando-os, e doutrinas com `paths:` que NUNCA casaram. A 1ª versão anunciava confronto no
# cabeçalho e nenhuma linha cruzava seções — o Elenxo apontou, e confronto declarado sem código
# é a mesma doença que esta casa persegue em toda prosa.
#
# ── TETO ─────────────────────────────────────────────────────────────────────────────────────
#  · Mede o que os censos DECLARAM. Não sabe de artefato que ninguém anotou.
#  · `instructions-loaded` lê log LOCAL (gitignorado): num checkout novo ele sai NÃO-MEDIDO.
#  · Herda a precisão dos medidores: se um deles oscilar, o raio-X oscila junto. O `guard-census`
#    oscilava por corrida de EPIPE (curada junto desta leva); a lição fica: composição não cura
#    o componente, só o expõe.
#  · Não julga qualidade e não prioriza — nomeia alvos; o julgamento é do evolve.
# Uso: evolve-census.sh [--markdown|--tsv] [--root <repo>]
# =============================================================================
set -uo pipefail

FMT=--markdown; ROOT=""
while [ "$#" -gt 0 ]; do case "$1" in
  --markdown|--tsv) FMT="$1" ;;
  --root) shift; [ -n "${1:-}" ] || { printf 'evolve-census: --root sem valor\n' >&2; exit 2; }; ROOT="$1" ;;
  -h|--help) sed -n '3,6p' "$0"; exit 0 ;;
  --*) printf 'evolve-census: flag desconhecida: %s\n' "$1" >&2; exit 2 ;;
  *) ROOT="$1" ;;
esac; shift; done
ROOT="${ROOT:-.}"
REPO="$(cd "${ROOT}" 2>/dev/null && pwd)" || { printf 'evolve-census: repo_root inválido: %s\n' "${ROOT}" >&2; exit 2; }
V="${REPO}/.claude/validation"
[ -d "${V}" ] || { printf 'evolve-census: %s ausente — não emito raio-X vazio. Recuso.\n' "${V}" >&2; exit 3; }

# ⚠️ A LISTA DO NÃO-MEDIDO VIVE EM ARQUIVO, NÃO EM VARIÁVEL: `_run` é chamado dentro de `$( )`, e
#    uma variável acumulada num SUBSHELL morre quando ele sai. A 2ª versão deste script acumulava em
#    variável e a lista ficava SILENCIOSAMENTE VAZIA para cinco das sete dimensões — os números
#    saíam `?` corretamente, mas o "porquê" sumia. A bancada pegou (casos d/e) antes do commit; é a
#    armadilha clássica de shell, e ela anulava exatamente a propriedade que o Elenxo exigiu.
UNM_FILE="$(mktemp)"; trap 'rm -f "${UNM_FILE}"' EXIT
_note() { printf '%s\t%s\n' "$1" "$2" >> "${UNM_FILE}"; }

# _run <dim> <ok_max_rc> <script> [args...] — imprime a saída SE mediu; senão registra e imprime nada.
_run() {
  local dim="$1" okmax="$2" scr="$3"; shift 3
  if [ ! -f "${V}/${scr}" ]; then _note "${dim}" "AUSENTE: ${scr}"; return 1; fi
  local out rc=0
  out="$(cd "${REPO}" && bash "${V}/${scr}" "$@" 2>/dev/null)" || rc=$?
  if [ "${rc}" -gt "${okmax}" ]; then _note "${dim}" "NAO-MEDIDO: ${scr} saiu rc=${rc}"; return 1; fi
  printf '%s' "${out}"; return 0
}
# _n <valor> — número medido, ou `?` se a dimensão não mediu. NUNCA 0 por omissão.
_n() { if [ -n "${1:-}" ]; then printf '%s' "$1"; else printf '?'; fi; }

# ── 1. PEÇAS ──────────────────────────────────────────────────────────────────────────────────
P_OK=0; P_TOT=""; P_7=""; P_1=""; P_SURF=""
if PIECES="$(FORGE_CENSUS_TOP=1000 _run pecas 0 forge-census.sh . --tsv)"; then
  P_OK=1
  P_TOT="$(awk -F'\t' 'NR>1 && $2!=""' <<< "${PIECES}" | grep -c . || true)"
  P_7="$(awk -F'\t' 'NR>1 && $1==7' <<< "${PIECES}" | grep -c . || true)"
  P_1="$(awk -F'\t' 'NR>1 && $1==1' <<< "${PIECES}" | grep -c . || true)"
  P_SURF="$(awk -F'\t' 'NR>1 && $1==1 {print $2}' <<< "${PIECES}" | sort)"
fi

# ── 2. GUARDAS ────────────────────────────────────────────────────────────────────────────────
G_OK=0; G_N=""; G_FAM=""; G_PASSIVE=""
if GUARDS="$(_run guardas 0 guard-census.sh . --markdown)"; then
  G_OK=1
  G_N="$(grep -cE '^(hook|check de lint) \|' <<< "${GUARDS}" || true)"
  G_FAM="$(grep -oE 'massa: [0-9]+' <<< "${GUARDS}" | grep -oE '[0-9]+' | head -1)"
  # o PASSIVO de verdade: linhas `- ` que NÃO são o caso feliz "(nenhum …)" nem o "(informativo …)".
  # A 1ª versão filtrava só linhas que começavam com `(`, que é o contrário — escondia
  # `DISPARA e NAO E EXERCITADO` e `COM --selftest e NÃO REGISTRADO` (achado do Elenxo).
  G_PASSIVE="$(grep -E '^- ' <<< "${GUARDS}" | grep -vE '^- \((nenhum|informativo)' || true)"
fi

# ── 3. DISSECAÇÕES — contadas pela COLUNA de frescor, nunca pela legenda ──────────────────────
D_OK=0; D_N=""; D_VENC=""
if DISS="$(_run dissect 0 dissect-census.sh . --markdown)"; then
  D_OK=1
  D_N="$(grep -oE '[0-9]+ dissecação\(ões\) declarada' <<< "${DISS}" | grep -oE '^[0-9]+' | head -1)"
  # ⚠️ ÚLTIMA COLUNA da tabela == vencido. O `grep -ci vencido` da 1ª versão casava a LEGENDA
  #    ("VENCIDO não se cita como se fosse de hoje") e publicava "1 vencida" sobre uma dissecação
  #    `fresco` — número falso que chegou a um nó de grafo antes de o Elenxo pegar.
  D_VENC="$(awk -F' [|] ' 'NF>=6 && $1!="ferramenta" {v=$NF; gsub(/[[:space:]]/,"",v); if (v=="vencido") n++} END {print n+0}' <<< "${DISS}")"
fi

# ── 4. DOUTRINA QUE CARREGA — só arquivo que EXISTE e que CARREGOU ───────────────────────────
I_OK=0; I_N=""; I_NEVER=""; I_NEVER_LIST=""
if INSTR="$(_run doutrina 0 instructions-loaded-census.sh)"; then
  I_OK=1
  # ⚠️ exclui worktrees, linhas NUNCA (sessions=0) e arquivos que NÃO EXISTEM MAIS. A 1ª versão
  #    contava os três e publicava "14 carregados" quando eram 4 (Elenxo: 6 sondas `zz-*` apagadas
  #    e 4 linhas NUNCA estavam somadas).
  I_N="$(awk -F'\t' 'NR>1 && $1!="" && $1!~/worktrees/ && $2>0 {print $1}' <<< "${INSTR}" \
          | while IFS= read -r f; do [ -f "${REPO}/${f}" ] && printf '%s\n' "${f}"; done | grep -c . || true)"
  I_NEVER_LIST="$(awk -F'\t' 'NR>1 && $1!~/worktrees/ && $NF=="NUNCA" {print $1}' <<< "${INSTR}" \
          | while IFS= read -r f; do [ -f "${REPO}/${f}" ] && printf '%s\n' "${f}"; done)"
  I_NEVER="$(grep -c . <<< "${I_NEVER_LIST}" || true)"
  # skill com paths: é NAO-MEDIVEL (o hook de carga não dispara para skills): vai para O QUE NÃO
  # FOI MEDIDO, nunca para a lista de alvos — a 1ª versão as publicava como "nunca casou".
  I_BLIND="$(awk -F'\t' 'NR>1 && $1!~/worktrees/ && $NF=="NAO-MEDIVEL" {print $1}' <<< "${INSTR}" \
          | while IFS= read -r f; do [ -f "${REPO}/${f}" ] && printf '%s\n' "${f}"; done | grep -c . || true)"
  if [ "${I_BLIND:-0}" -gt 0 ]; then
    _note doutrina "NAO-MEDIVEL: ${I_BLIND} skill(s) com paths: — o hook InstructionsLoaded não dispara para skills"
  fi
fi

# ── 5. PLANO ──────────────────────────────────────────────────────────────────────────────────
PL_OK=0; PL_RDY=""; PL_BLK=""; BL_N=""
PLAN="${REPO}/docs/onion/graph/fios-abertos.kg.yaml"
if [ ! -f "${PLAN}" ]; then _note plano "AUSENTE: docs/onion/graph/fios-abertos.kg.yaml"
elif PL="$(_run plano 0 kg-drive-project.sh "${PLAN}")"; then
  PL_OK=1
  PL_RDY="$(grep -oE 'pronto=[0-9]+' <<< "${PL}" | grep -oE '[0-9]+' | head -1)"
  PL_BLK="$(grep -oE 'bloqueado=[0-9]+' <<< "${PL}" | grep -oE '[0-9]+' | head -1)"
fi
if [ -f "${REPO}/docs/backlog.md" ]; then
  BL_N="$(grep -oE '\*\*[0-9]+ itens abertos\*\*' "${REPO}/docs/backlog.md" | grep -oE '[0-9]+' | head -1)"
  [ -n "${BL_N}" ] || _note backlog "NAO-MEDIDO: docs/backlog.md sem a linha de total (formato mudou?)"
else _note backlog "AUSENTE: docs/backlog.md"; fi

# ── 6. A IDADE DESTA AUDITORIA — rc 1 é "achei sinal", só ≥2 é falha ──────────────────────────
S_OK=0; S_N=""; S_TXT=""
if STALE="$(_run idade 1 evolve-staleness-check.sh "${REPO}" --tsv)"; then
  S_OK=1
  S_N="$(awk -F'\t' '$2 ~ /^EVOLVE-/' <<< "${STALE}" | grep -c . || true)"
  S_TXT="$(awk -F'\t' '$2 ~ /^EVOLVE-/ {printf "%s ", $2}' <<< "${STALE}")"
fi

# ── 7. CONFRONTO — cruzar dimensões, que é o que nenhum órgão isolado entrega ─────────────────
C_GUARDED=""
if [ "${P_OK}" = 1 ] && [ -n "${P_SURF}" ]; then
  C_GUARDED="$(while IFS= read -r c; do
      [ -n "${c}" ] || continue
      if grep -lqE "/meta:${c}([^a-z-]|$)" "${V}"/*-check.sh 2>/dev/null; then printf '%s\n' "${c}"; fi
    done <<< "${P_SURF}")"
fi

if [ "${FMT}" = --tsv ]; then
  printf 'dimensao\tmetrica\tvalor\n'
  printf 'pecas\tcandidatos\t%s\npecas\tcompletos_7_7\t%s\npecas\tso_superficie_1_7\t%s\n' "$(_n "${P_TOT}")" "$(_n "${P_7}")" "$(_n "${P_1}")"
  _gp="?"; [ "${G_OK}" = 1 ] && _gp="$(grep -c . <<< "${G_PASSIVE}" || true)"
  printf 'guardas\tcom_selftest\t%s\nguardas\tfamilias_bancada\t%s\nguardas\tpassivo\t%s\n' "$(_n "${G_N}")" "$(_n "${G_FAM}")" "$(_n "${_gp}")"
  printf 'dissect\tdeclaradas\t%s\ndissect\tvencidas\t%s\n' "$(_n "${D_N}")" "$(_n "${D_VENC}")"
  printf 'doutrina\tcarregaram_e_existem\t%s\ndoutrina\tnunca_casaram\t%s\n' "$(_n "${I_N}")" "$(_n "${I_NEVER}")"
  printf 'plano\tpronto\t%s\nplano\tbloqueado\t%s\nplano\tabertos_corpus\t%s\n' "$(_n "${PL_RDY}")" "$(_n "${PL_BLK}")" "$(_n "${BL_N}")"
  printf 'autoauditoria\tsinais\t%s\n' "$(_n "${S_N}")"
  # a lista do não-medido EXISTE no tsv — a 1ª versão não a tinha, e tudo que falhava virava 0
  while IFS=$'\t' read -r d m; do [ -n "${d}" ] && printf 'nao_medido\t%s\t%s\n' "${d}" "${m}"; done < "${UNM_FILE}"
  exit 0
fi

printf '# raio-X do framework · %s\n\n' "$(LC_ALL=C date +%Y-%m-%d)"
printf '## 1. PEÇAS — comandos-com-framework completos\n'
printf '  %s candidatos · **%s completos (7/7)** · %s com só a superfície (1/7)\n' "$(_n "${P_TOT}")" "$(_n "${P_7}")" "$(_n "${P_1}")"
if [ "${P_OK}" = 1 ]; then
  _top="$(awk -F'\t' 'NR>1 && $1>=4 && $2!="" {printf "%s/7 %s\n", $1, $2}' <<< "${PIECES}" | sort -r)"
  printf '%s\n' "${_top}" | sed 's/^/    /'
  printf '    (todos os %s com 4+ peças; os 1/7 estão nomeados na seção 7)\n' "$(grep -c . <<< "${_top}" || true)"
fi

printf '\n## 2. GUARDAS — o que REPROVA\n'
printf '  %s com selftest próprio · %s família(s) de bancada\n' "$(_n "${G_N}")" "$(_n "${G_FAM}")"
if [ "${G_OK}" = 1 ]; then
  if [ -n "${G_PASSIVE}" ]; then printf '  ⚠️ PASSIVO (guarda morta ou órfã):\n'; printf '%s\n' "${G_PASSIVE}" | sed 's/^/    /'
  else printf '  passivo: nenhuma guarda morta ou órfã\n'; fi
fi

printf '\n## 3. DISSECAÇÕES — o que o corpus pagou de ferramenta de terceiro\n'
printf '  %s declarada(s) · %s vencida(s) (contadas pela coluna frescor)\n' "$(_n "${D_N}")" "$(_n "${D_VENC}")"

printf '\n## 4. DOUTRINA QUE CARREGA — e ⚠️ CARREGOU ≠ ATERRISSOU\n'
printf '  %s arquivo(s) de instrução que CARREGARAM e ainda existem · %s com paths: que NUNCA casou\n' "$(_n "${I_N}")" "$(_n "${I_NEVER}")"
printf '  ⚠️ Mede se a doutrina ENTROU NO CONTEXTO, nunca se MUDOU O COMPORTAMENTO. A diferença é\n'
printf '     medida: em 2026-10-02 a doutrina do dogfood estava carregada no CLAUDE.md e a sessão a\n'
printf '     violou QUATRO vezes no mesmo dia. Achado sobre doutrina diz qual das duas coisas mediu.\n'

printf '\n## 5. PLANO — o trabalho aberto\n'
printf '  fila-pronta=%s · bloqueado=%s · abertos no corpus inteiro=%s\n' "$(_n "${PL_RDY}")" "$(_n "${PL_BLK}")" "$(_n "${BL_N}")"

printf '\n## 6. A IDADE DESTA PRÓPRIA AUDITORIA (REGRA 97)\n'
# ⚠️ ✅ SÓ COM MEDIÇÃO: a 1ª versão imprimia "✅ fresca" quando o medidor QUEBRAVA, porque a contagem
#    de sinais dava zero sobre uma saída vazia. Verde sem medição é o pior verde que existe.
if [ "${S_OK}" != 1 ]; then printf '  ? NÃO MEDIDA — o medidor de idade não respondeu (ver a lista abaixo); nunca ✅ sem medição\n'
elif [ "${S_N}" -gt 0 ]; then printf '  ⚠️ %s sinal(is): %s\n' "${S_N}" "${S_TXT}"
else printf '  ✅ auto-auditoria fresca e sem delta populacional (medida)\n'; fi

printf '\n## 7. CONFRONTO — os ALVOS, cruzando dimensões\n'
if [ "${P_OK}" = 1 ]; then
  printf '  · %s comandos com SÓ A SUPERFÍCIE (1/7) — os candidatos naturais da próxima forja\n' "$(_n "${P_1}")"
  if [ -n "${C_GUARDED}" ]; then
    printf '  · e destes, já VIGIADOS por guarda (a casa os cobra e não lhes deu peças):\n'
    printf '%s\n' "${C_GUARDED}" | sed 's/^/      /'
  fi
else printf '  · peças NÃO MEDIDAS — sem alvos de forja nesta rodada\n'; fi
if [ "${I_OK}" = 1 ] && [ -n "${I_NEVER_LIST}" ]; then
  printf '  · doutrina com `paths:` que NUNCA casou (escrita e nunca lida — ou recém-nascida):\n'
  printf '%s\n' "${I_NEVER_LIST}" | sed 's/^/      /'
fi

printf '\n## O QUE NÃO FOI MEDIDO (lista de 1ª classe, nunca omissão)\n'
if [ -s "${UNM_FILE}" ]; then
  while IFS=$'\t' read -r d m; do [ -n "${d}" ] && printf '  ✗ %s — %s\n' "${d}" "${m}"; done < "${UNM_FILE}"
else printf '  todos os medidores responderam.\n'; fi
printf '  TETO: mede o que os censos DECLARAM; herda a precisão deles; não julga qualidade.\n'
exit 0
