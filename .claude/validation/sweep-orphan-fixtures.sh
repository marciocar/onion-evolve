#!/usr/bin/env bash
# sweep-orphan-fixtures.sh — remove fixtures ÓRFÃS que a bancada deixou na árvore viva.
#
# Uso: sweep-orphan-fixtures.sh [--dry-run]
#
# ══ POR QUE EXISTE ════════════════════════════════════════════════════════════════════════════
# A bancada cria fixtures NA ÁRVORE VIVA (é deliberado: ela precisa exercitar guardas que só
# existem num repo de verdade). Uma rodada INTERROMPIDA — sessão que cai, Ctrl+C, timeout — as
# deixa para trás. O lint seguinte então as vê como artefatos REAIS e reprova:
#   · `plugins/__mbguard__` → REGRA 19 "plugin ausente"
#   · `verticals/__mbguard__<pid>.manifest.sh` → REGRA 61 + 14 ocorrências da REGRA 27
#   · `site/__selftest-deeplink__.html` → REGRA 35
# Medido 3x em 2026-09-15, uma delas com 271 HARD, e as três vezes a cura foi eu LEMBRAR de limpar.
# Cura-que-depende-de-lembrar não é cura: `fix-must-become-mechanism`.
#
# ══ O QUE TORNA ISTO SEGURO, e não um `rm -rf` com glob ═══════════════════════════════════════
# (1) SÓ UNTRACKED, via `git status --porcelain`. Arquivo RASTREADO nunca é tocado — medido: zero
#     arquivos rastreados casam o padrão, e se um dia casarem, este helper os ignora por construção.
# (2) OLHA TAMBÉM OS IGNORADOS (`--ignored`), e isso foi medido: `plugins/__*__/` JÁ ESTÁ no
#     .gitignore (linha 60) — alguém antecipou o lixo sem antecipar a limpeza. Sem `--ignored` a
#     varredura não via justamente a fixture que produziu as 271 HARD.
#     O PREÇO de olhar ignorados é o `node_modules`: `site/node_modules/css-what/src/__fixtures__`
#     casa o padrão e é DEPENDÊNCIA DE TERCEIRO — apagá-la quebra o site. Duas barreiras em série:
#     `__fixtures__` está fora por nome (razão (3)), e qualquer caminho sob `node_modules/` é
#     recusado explicitamente. Uma barreira só seria sorte.
# (3) `__fixtures__` está FORA do alcance por nome: é convenção de Vitest/Jest usada por projeto
#     real (um adotante a usa), não artefato desta bancada. Apagar convenção alheia é pior que o
#     problema que este helper resolve.
# (4) NUNCA silencioso: cada remoção é impressa. Varredura que apaga sem dizer é a classe que esta
#     casa persegue.
# ══ CORE-ONLY POR ORA, E DECLARADO ════════════════════════════════════════════════════════════
# O helper VIAJA (mora em .claude/validation/), mas o passo no pre-commit é só do core — mesmo
# tratamento que a guarda anti-commit-na-default-branch recebe no mesmo hook, e pela mesma razão:
# apagar untracked no repo de OUTRO é aposta maior que no próprio. O adotante roda a bancada e pode
# colher o mesmo lixo; quando isso acontecer (gatilho nomeado: um adotante reportar fixture órfã
# reprovando o lint dele), o passo entra no template `githook-pre-commit-onion.tpl`.
set -uo pipefail

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "sweep: fora de um repo git — nada a fazer" >&2; exit 0; }

# As fixtures que ESTA bancada cria. Derivado do arquivo dela, não inventado — mas com `__fixtures__`
# excluído pela razão (3). Se a bancada passar a criar um nome novo, ele entra aqui sozinho.
# ⚠️ O REGEX ACEITA HÍFEN — a 1ª versão (`__[a-z0-9]+__`) não casava `__selftest-deeplink__`, e a
#    fixture que dispara a REGRA 35 sobrevivia à varredura em silêncio. Derivação estreita demais é
#    guarda que parece funcionar: ela limpa o que lembra e deixa o resto.
_PADROES="$(grep -ohE '__[a-z0-9][a-z0-9-]*__' "${ROOT}/.claude/validation/lint-selftest.sh" 2>/dev/null \
            | sed 's/__$//; s/^__//' | sort -u | grep -vx 'fixtures' || true)"
[ -n "${_PADROES}" ] || exit 0

_n=0
while IFS= read -r _p; do
  [ -n "${_p}" ] || continue
  _base="$(basename "${_p%/}")"
  while IFS= read -r _pat; do
    [ -n "${_pat}" ] || continue
    case "${_base}" in
      "__${_pat}__"*)
        if [ "${DRY}" -eq 1 ]; then
          echo "  (dry-run) removeria fixture órfã: ${_p}"
        else
          rm -rf "${ROOT:?}/${_p}" && echo "  🧹 fixture órfã removida: ${_p}"
        fi
        _n=$(( _n + 1 )); break ;;
    esac
  done <<< "${_PADROES}"
done < <(git -C "${ROOT}" status --porcelain --ignored 2>/dev/null | sed -n 's/^\(??\|!!\) //p' | grep -v '/node_modules/')

[ "${_n}" -eq 0 ] || echo "sweep: ${_n} fixture(s) órfã(s) da bancada $([ "${DRY}" -eq 1 ] && echo 'detectada(s)' || echo 'removida(s)') — rodada anterior interrompida."
exit 0
