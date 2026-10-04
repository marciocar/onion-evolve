#!/usr/bin/env bash
# =============================================================================
# guard-census.sh — o MEDIDOR da forja de guardas (peça 3 do conjunto)
#
# POR QUE EXISTE: a forja de guarda é o procedimento MAIS REPETIDO desta casa e era
# o único sem superfície — medido em 2026-10-02: 206 famílias de bancada e 14
# guardas com `--selftest` próprio, todas forjadas À MÃO, cada vez relendo um molde
# escolhido de memória. O `/meta:forge` tem medidor (forge-census.sh) e a forja de
# guarda não tinha: o resultado é que a sessão decide o SUBSTRATO por lembrança.
#
# O QUE ELE RESPONDE, antes de você pensar:
#   (a) os MOLDES que existem, por substrato — hook Stop, hook PreToolUse, check de
#       lint, guarda embutida no lint-artifacts — com o número de casos de cada um,
#       para a cópia ser do molde mais exercitado e não do primeiro que vier à cabeça;
#   (b) se já existe guarda que cobre a CLASSE pedida (busca por termo), para não
#       re-forjar o que existe;
#   (c) o passivo: guardas SEM família de bancada e guardas NÃO REGISTRADAS — as
#       duas formas de guarda morta que esta casa já mediu.
#
# TETO DECLARADO: ele mede FORMA (presença de `--selftest`, de família, de registro),
# nunca QUALIDADE. Guarda registrada e exercitada pode ainda ser decorativa se os
# casos dela não têm mutante — e mutante não se detecta por grep. É por isso que a
# cláusula do mutante vive na DOUTRINA, cobrada por julgamento, não aqui.
# =============================================================================
set -uo pipefail
# ⚠️ `--markdown` E O UNICO FORMATO, e isto esta DECLARADO em vez de simulado (F10 do Elenxo): a
# 1a versao atribuia `MD` e NADA lia `MD`, enquanto o `forge-guard.md` mandava invocar com a flag —
# flag copiada do irmao `forge-census.sh` sem ser fiada. Esta saida e markdown SEMPRE; a flag e
# aceita por compatibilidade com a chamada documentada e NAO muda nada. Se um dia houver 2o
# formato, ela passa a decidir; hoje mentir que decide seria pior que nao ter.
ROOT="${1:-.}"; [ "${ROOT}" = "--markdown" ] && ROOT="."
cd "${ROOT}" || { echo "guard-census: ROOT inválido: ${ROOT}" >&2; exit 2; }
QUERY="${GUARD_CENSUS_QUERY:-}"

# ⚠️ AS CONVENÇÕES DE ASSERÇÃO SÃO CINCO, NÃO DUAS — e isto é defeito medido no 1º dogfood deste
# censo: a 1ª redação contava `record_pass|record_fail` e `echo "  ✅ ("`, e devolveu 0 CASOS para
# três checks que TÊM selftest (`vendor-scrub-form` usa `FALHOU`, `kg-reverify-schema` usa `✗` nu,
# `consumed-mode` usa `✅`/`✗` sem o ` (`). Zero-por-vocabulário é pior que não medir: lê-se como
# "guarda sem caso". É a classe `guarda-por-lista-falha-pelo-vocabulario` cometida no medidor que
# existe para expor guarda morta.
_count_cases() {  # $1 = arquivo → nº de asserções de selftest (as cinco convenções medidas na casa)
  local f="$1" n
  n="$(grep -cE 'record_pass|record_fail|✅|✗|FALHOU' "$f" 2>/dev/null || true)"
  printf '%s' "${n:-0}"
}

# E o REGISTRO não mora num lugar só: hook vai no settings.json, check de lint é chamado pelo
# lint-artifacts.sh, e alguns são exercitados pelo lint-selftest.sh ou pelo .githooks/pre-commit.
# A 1ª redação olhava UM lugar por substrato e marcou `pipe-verdict-check` como não-registrado
# quando ele é invocado pelo lint-selftest — falso positivo. Diz ONDE, não sim/não.
_where() {  # $1 = basename → lista de consumidores, ou vazio
  # ⚠️ ANCORADO, nao substring (F7 do Elenxo, provado com sandbox): `grep -q "$b"` fazia
  # `title-in-prose.sh` — nunca registrado — aparecer como REGISTRADO em settings.json, porque o
  # nome e substring de `rule-title-in-prose.sh`. E o `.` do nome era CORINGA. Pior: o passivo que
  # existe para achar guarda morta ficava SILENCIOSO, e o `forge-guard.md` manda "re-rodar o censo
  # para confirmar que saiu do passivo" — confirmacao FALSIFICAVEL. Aqui o nome e escapado e
  # cercado por nao-identificador nas duas pontas.
  local b="$1" out="" esc
  esc="$(printf '%s' "${b}" | sed 's/[.[\*^$()+?{|]/\\&/g')"
  for c in .claude/settings.json .claude/validation/lint-artifacts.sh .claude/validation/lint-selftest.sh .githooks/pre-commit; do
    [ -f "$c" ] || continue
    LC_ALL=C grep -qE "(^|[^A-Za-z0-9_.-])${esc}([^A-Za-z0-9_-]|\$)" "$c" 2>/dev/null \
      && out="${out}${out:+,}$(basename "$c")"
  done
  printf '%s' "${out}"
}

# ── F8: `--selftest` em COMENTARIO contava como molde a copiar, e caia no passivo ERRADO.
# Implementacao != mencao: tira comentario de linha antes de decidir.
_has_selftest() {  # $1 = arquivo → rc 0 se IMPLEMENTA selftest (nao se apenas o menciona)
  # ⚠️ HERE-STRING, NAO PIPE (2026-10-04): `sed | grep -q` sob `set -uo pipefail` e a classe EPIPE do
  #    early-closer — o grep fecha na 1a casada, o sed toma EPIPE escrevendo um arquivo de 27KB, e o
  #    pipefail devolve FALHA com o padrao PRESENTE. Medido pelo Elenxo da re-forja do evolve: seis
  #    execucoes seguidas deram 15,16,16,16,15,16 guardas, e o raio-X do evolve publicava o numero
  #    que a corrida sorteasse. Ler TUDO antes de procurar elimina a corrida.
  local _body; _body="$(LC_ALL=C sed 's/#.*//' "$1" 2>/dev/null)" || return 1
  LC_ALL=C grep -qE -- '--selftest' <<< "${_body}"
}

echo "# censo de guardas · $(date +%Y-%m-%d)"
echo
echo "## moldes por SUBSTRATO (copie o mais exercitado, não o primeiro lembrado)"
printf '%s\n' "substrato | arquivo | casos | registrado"
for f in .claude/hooks/*.sh; do
  [ -f "$f" ] || continue
  _has_selftest "$f" || continue
  _reg="$(_where "$(basename "$f")")"; [ -n "${_reg}" ] || _reg="NENHUM — não dispara"
  printf 'hook | %s | %s | %s\n' "$(basename "$f")" "$(_count_cases "$f")" "${_reg}"
done
for f in .claude/validation/*-check.sh; do
  [ -f "$f" ] || continue
  _has_selftest "$f" || continue
  _reg="$(_where "$(basename "$f")")"; [ -n "${_reg}" ] || _reg="NENHUM — não dispara"
  printf 'check de lint | %s | %s | %s\n' "$(basename "$f")" "$(_count_cases "$f")" "${_reg}"
done
echo
_fam="$(grep -cE '^run_[a-z0-9_]+_selftests\(\)' .claude/validation/lint-selftest.sh 2>/dev/null || true)"
echo "## massa: ${_fam:-?} família(s) de bancada em lint-selftest.sh"
echo
if [ -n "${QUERY}" ]; then
  echo "## já existe guarda para \`${QUERY}\`? (não re-forje o que existe)"
  _hits="$(grep -rilE "${QUERY}" .claude/hooks/ .claude/validation/ 2>/dev/null | grep -vE 'lint-selftest|baseline|fixtures' || true)"
  if [ -n "${_hits}" ]; then printf '%s\n' "${_hits}" | sed 's|^|- |'
  else echo "- nenhum arquivo de guarda menciona o termo — a classe parece NOVA (teto: busca é LEXICAL, não semântica)"; fi
  echo
fi
echo "## passivo — as duas formas de guarda morta que esta casa já mediu"
# ⚠️ A 1a redacao deste bloco SUPERESTIMAVA o passivo em 14 — defeito medido no 2o dogfood: ela
# chamava "guarda morta" todo hook sem `--selftest` PROPRIO, e os 14 acusados estao TODOS no
# lint-selftest.sh, isto e, tem FAMILIA de bancada. Exercitado por familia e exercitado. Falso
# positivo em guarda treina a sessao a ignorar o veto — a clausula 4 da guard-doctrine, cometida no
# medidor dela. A morte real e NAO TER NENHUM DOS DOIS.
_nosel=0
for f in .claude/hooks/*.sh; do
  [ -f "$f" ] || continue
  _has_selftest "$f" && continue
  [ -n "$(_where "$(basename "$f")")" ] || continue
  grep -q "$(basename "$f")" .claude/validation/lint-selftest.sh 2>/dev/null && continue   # tem familia
  echo "- DISPARA e NAO E EXERCITADO (sem --selftest proprio E sem familia): $(basename "$f")"; _nosel=$((_nosel+1))
done
[ "${_nosel}" -eq 0 ] && echo "- (nenhum hook dispara sem ser exercitado — nem por flag propria, nem por familia)"
_soft=0
for f in .claude/hooks/*.sh; do
  [ -f "$f" ] || continue
  _has_selftest "$f" && continue
  grep -q "$(basename "$f")" .claude/validation/lint-selftest.sh 2>/dev/null || continue
  _soft=$((_soft+1))
done
echo "- (informativo, NAO passivo: ${_soft} hook(s) sem \`--selftest\` proprio mas COM familia de bancada —"
echo "   exercitados pela bancada, so nao rodam isolados)"
_noreg=0
for f in .claude/hooks/*.sh; do
  [ -f "$f" ] || continue
  _has_selftest "$f" || continue
  [ -z "$(_where "$(basename "$f")")" ] || continue
  echo "- COM --selftest e NÃO REGISTRADO (guarda que não dispara): $(basename "$f")"; _noreg=$((_noreg+1))
done
[ "${_noreg}" -eq 0 ] && echo "- (nenhum hook exercitado fora do settings.json)"
echo
echo "(TETO: este censo mede FORMA — presença de selftest, de família, de registro."
echo " Ele NÃO sabe se um caso tem MUTANTE, e caso sem mutante pode passar verde com"
echo " a cura revertida. A cláusula do mutante é da doutrina, cobrada por julgamento.)"
