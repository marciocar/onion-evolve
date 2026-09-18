#!/usr/bin/env bash
# =============================================================================
# lint-design-tokens.sh — Gate DETERMINÍSTICO da vertical de design (sem LLM)
#
# Valida a SSOT de design (docs/design-context/) em três eixos — o "gate
# mecânico" da doutrina de dogfooding aplicado a design (o modelo é o pior juiz
# da própria saída; contraste/refs são CALCULADOS, não "achados"):
#   (1) DTCG bem-formado  — JSON válido; todo $value sob um nó com $type herdável.
#   (2) Referências {alias} resolvem — sem alias órfão e sem ciclo.
#   (3) Contraste WCAG    — cada par em governance/contrast-pairs.json >= min.
#
# Uso     : lint-design-tokens.sh [<dir-do-projeto>]   (default: raiz deste repo)
# Saída   : sumário estilo lint-artifacts.sh; exit 1 se houver violação HARD.
# Gracioso: design-context ausente → exit 0 (adotante pode não ter) — e SÓ isso.
#           jq/awk ausente COM design-context presente → exit 2 (não pude julgar ≠ passou), idem
#           contrast-pairs.json presente e ilegível. A graciosidade é sobre AUSÊNCIA legítima de
#           objeto, nunca sobre incapacidade de medir. (Esta linha dizia "aviso + exit 0" e ficou
#           falsa no mesmo PR que mudou o comportamento — cabeçalho é doutrina, e doutrina que não
#           acompanha o código é a classe que este arquivo inteiro persegue.)
#
# Consumido por: CI (.github/workflows/onion-validate.yml — bloqueia em HARD
#                quando muda .claude/**, docs/meta-specs/** ou docs/design-context/**),
#                /design (fase converge), /meta:context-freshness.
# Exercitado por: lint-selftest.sh (run_design_tokens_selftests).
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT="${1:-${REPO_ROOT}}"
DC="${PROJECT}/docs/design-context"

HARD=0
hard() { HARD=$((HARD + 1)); echo "  ✗ HARD: $1" >&2; }
ok()   { echo "  ✓ $1"; }

echo "=== Onion Lint Design Tokens — ${DC} ==="

# --- Graciosidade: contexto ausente / ferramentas ausentes ------------------
if [ ! -d "${DC}" ]; then
  echo "design-context ausente — nada a validar (ok p/ adotante sem design)."; exit 0
fi
# ⚠️ FERRAMENTA AUSENTE COM `design-context` PRESENTE É FALHA, NUNCA "PULADA" — sinal de campo de
# 2026-09-07 (um adotante, item 6), com custo medido: sem `jq` o gate saía `exit 0` dizendo PULADA,
# e **um tint a 1,38:1 virava tema aprovado**. O consumidor teve de tratar o "PULADA" como FALHA por
# conta própria — o que significa que cada adotante reimplementa a desconfiança que o gate deveria ter.
# A diferença que importa: `design-context` AUSENTE é legítimo (adotante sem design, `exit 0` acima);
# ferramenta ausente com o contexto PRESENTE é "não pude julgar", e guarda que não pode julgar
# DECLARA que não sabe — nunca aprova. É o mesmo precedente da REGRA 36, que sai HARD nomeando a
# ausência quando o manifesto de transporte não responde.
_missing_tool() {
  echo "  ✗ HARD: ${1} ausente — a validação NÃO PÔDE ser feita, e ${DC} EXISTE." >&2
  echo "    Isto não é 'pulada': sem medir, um contraste reprovado passaria por aprovado" >&2
  echo "    (medido em campo: 1,38:1 virou tema com exit 0). Instale ${1} ou declare o porquê." >&2
  exit 2
}
command -v jq  >/dev/null 2>&1 || _missing_tool jq
command -v awk >/dev/null 2>&1 || _missing_tool awk

mapfile -t FILES < <(find "${DC}" -type f -name '*.tokens.json' | sort)
if [ "${#FILES[@]}" -eq 0 ]; then
  echo "Nenhum *.tokens.json em ${DC} — nada a validar."; exit 0
fi

# --- (1) DTCG bem-formado + (build do mapa flat path -> raw value) ----------
declare -A TOK
for f in "${FILES[@]}"; do
  if ! jq -e . "${f}" >/dev/null 2>&1; then
    hard "JSON inválido: ${f#${PROJECT}/}"; continue
  fi
  # Extrai "token.path<TAB>valor" para cada nó que tem $value (string).
  while IFS=$'\t' read -r path val; do
    [ -n "${path}" ] || continue
    TOK["${path}"]="${val}"
  done < <(jq -r 'paths(scalars) as $p | select($p[-1]=="$value")
                  | [($p[:-1]|join(".")), (getpath($p)|tostring)] | @tsv' "${f}" 2>/dev/null)
done
[ "${HARD}" -eq 0 ] && ok "DTCG bem-formado (${#FILES[@]} arquivo(s), ${#TOK[@]} token(s))"

# --- (2) Resolução de referências {alias} (sem órfã, sem ciclo) -------------
# resolve <path-ou-valor> → ecoa valor final em STDOUT; rc=1 órfã, rc=2 ciclo.
resolve() {
  local v="$1" depth=0 key
  while [[ "${v}" =~ ^\{(.+)\}$ ]]; do
    key="${BASH_REMATCH[1]}"
    depth=$((depth + 1)); [ "${depth}" -gt 16 ] && return 2     # ciclo
    if [ -z "${TOK[${key}]+x}" ]; then return 1; fi             # alias órfão
    v="${TOK[${key}]}"
  done
  printf '%s' "${v}"
}
ref_fail=0
for path in "${!TOK[@]}"; do
  raw="${TOK[${path}]}"
  [[ "${raw}" =~ ^\{.+\}$ ]] || continue
  resolve "${raw}" >/dev/null; rc=$?     # capturar ANTES de qualquer outro cmd (o ! zeraria $?)
  if [ "${rc}" -ne 0 ]; then
    case "${rc}" in
      1) hard "alias órfão: ${path} → ${raw}";;
      2) hard "ciclo de referência em: ${path} → ${raw}";;
    esac
    ref_fail=1
  fi
done
[ "${ref_fail}" -eq 0 ] && ok "referências {alias} resolvem (sem órfã/ciclo)"

# --- (3) Contraste WCAG dos pares declarados --------------------------------
contrast() {  # contrast <hex_fg> <hex_bg> → razão (float) via awk
  awk -v a="$1" -v b="$2" 'function chan(h,   c){c=strtonum("0x" h)/255.0;
      return (c<=0.03928)?(c/12.92):exp(2.4*log((c+0.055)/1.055))}
    function lum(hex,   r,g,b){r=chan(substr(hex,2,2));g=chan(substr(hex,4,2));b=chan(substr(hex,6,2));
      return 0.2126*r+0.7152*g+0.0722*b}
    BEGIN{la=lum(a)+0.05; lb=lum(b)+0.05; r=(la>lb)?la/lb:lb/la; printf "%.2f", r}'
}
PAIRS="${DC}/governance/contrast-pairs.json"
# ⚠️ ARQUIVO QUE EXISTE E NAO RESPONDE NAO E ARQUIVO AUSENTE — e confundir os dois era fail-open com
# mensagem MENTIROSA. A 1a redacao desta cura usava `[ -f ] && jq -e .` numa condicao so: JSON
# corrompido ou sem permissao de leitura caia no `else` e o gate imprimia "sem
# governance/contrast-pairs.json", sobre um arquivo que ESTA la. Pior: o aviso do modo escuro vive
# dentro do ramo `then`, entao um pairs.json quebrado SILENCIAVA as duas curas de uma vez, com
# `exit 0` e "design tokens validos".
# A doutrina ja estava escrita sessenta linhas acima, em `_missing_tool`: guarda que nao pode julgar
# DECLARA que nao sabe, nunca aprova. Ela nao alcancava este ramo porque ninguem a levou ate ele —
# que e a forma mais comum de uma cura ficar pela metade.
if [ -e "${PAIRS}" ] && ! jq -e . "${PAIRS}" >/dev/null 2>&1; then
  echo "  ✗ HARD: ${PAIRS#"${PROJECT}/"} EXISTE mas não pôde ser lido/parseado." >&2
  echo "    Isto NÃO é 'sem governança': o arquivo está lá e a validação NÃO PÔDE ser feita." >&2
  echo "    Tratar arquivo ilegível como arquivo ausente aprovaria em silêncio exatamente o que a" >&2
  echo "    governança existe para barrar. Corrija o JSON (ou a permissão) ou remova o arquivo." >&2
  exit 2
fi
if [ -f "${PAIRS}" ]; then
  wcag_fail=0
  while IFS=$'\t' read -r fg bg min note; do
    [ -n "${fg}" ] || continue
    fgv="$(resolve "${TOK[${fg}]:-}" 2>/dev/null || true)"
    bgv="$(resolve "${TOK[${bg}]:-}" 2>/dev/null || true)"
    if [[ ! "${fgv}" =~ ^#[0-9A-Fa-f]{6}$ ]] || [[ ! "${bgv}" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
      hard "par de contraste com token ausente/não-hex: ${fg} / ${bg}"; wcag_fail=1; continue
    fi
    ratio="$(contrast "${fgv}" "${bgv}")"
    if awk -v r="${ratio}" -v m="${min}" 'BEGIN{exit !(r+0 < m+0)}'; then
      hard "contraste ${ratio}:1 < ${min}:1 — ${fg} sobre ${bg} (${note})"; wcag_fail=1
    fi
  done < <(jq -r '.pairs[] | [.fg, .bg, (.min|tostring), (.note//"")] | @tsv' "${PAIRS}")
  [ "${wcag_fail}" -eq 0 ] && ok "contraste WCAG dos pares declarados OK"

  # ⚠️ O GATE SÓ MEDE O QUE A GOVERNANÇA DECLARA — e esse é o ponto cego que um adotante mediu em
  # 2026-09-07 (outro adotante): com a SSOT trazendo `color.dark.*` e a governança declarando só
  # o tema claro, o gate APROVA EM SILÊNCIO uma paleta ilegível no escuro. "Passou no gate" vira uma
  # afirmação mais forte do que o gate mediu — a classe que esta casa persegue em toda guarda.
  # CUSTO MEDIDO, não hipótese: as quatro candidatas daquele projeto tinham `brand.500` entre 1,71 e
  # 2,60 contra fundo escuro (alvo 3,0), e NENHUMA teria sido barrada.
  # Aviso, não reprovação: a governança é do projeto, e pode haver razão para não cobrir um modo. O
  # que não se admite é o silêncio — a guarda declara o que NÃO mediu.
  # A fonte é o array TOK, que o parse acima já preencheu — não uma variável inventada. (A 1ª
  # redação deste bloco citou duas que NÃO EXISTEM no script; `set -u` não pega porque eu havia
  # escrito `${VAR:-}`, e o efeito seria a guarda calar para sempre: fail-open dentro da cura de
  # um fail-open. Conferir a existência do que se lê é a metade barata de qualquer guarda.)
  # ⚠️ DETECTAR POR CHAVE SO ACHA A TOPOLOGIA QUE EU IMAGINEI — e a que a SSOT desta casa PRESCREVE
  # e outra. `docs/design-context/README.md:34` e `index.md:16` mandam usar
  # `modes/<light|dark|hc>.tokens.json`: arquivos de OVERRIDE cujos paths sao os MESMOS semanticos
  # (`color.surface.base`), sem prefixo `color.dark.` nenhum. Medido na passada adversarial deste
  # PR: com a estrutura canonica, um `brand` a 2,15:1 no escuro passava com `OK ✓` e exit 0 — o
  # defeito que esta cura existe para fechar, intacto, dentro da forma que o proprio framework manda
  # usar. Por isso a deteccao e por DOIS sinais, e basta um: a chave (`color.dark.*`, forma de quem
  # achata tudo num arquivo) OU o ARQUIVO de modo escuro (forma canonica).
  # ⚠️ E O SEGUNDO SINAL CARREGA UM ACHADO QUE O GATE NAO TEM COMO CURAR SOZINHO: `TOK` e chaveado
  # so pelo path, entao um override de modo SOBRESCREVE o valor base em silencio — dois arquivos,
  # dois tokens, e o escuro simplesmente some do que foi medido. Declarar isso e o que esta ao
  # alcance aqui; medir os dois modos de verdade exige TOK por (modo, path), que e mudanca de
  # contrato do parser e nao cabe nesta correcao.
  _has_dark_branch=0
  for _k in "${!TOK[@]}"; do case "${_k}" in color.dark.*) _has_dark_branch=1; break ;; esac; done
  _dark_mode_file=""
  if [ "${_has_dark_branch}" -eq 0 ]; then
    for _f in "${FILES[@]}"; do
      case "${_f#"${DC}/"}" in modes/dark*.tokens.json) _dark_mode_file="${_f#"${PROJECT}/"}"; _has_dark_branch=1; break ;; esac
    done
  fi
  if [ "${_has_dark_branch}" -eq 1 ]; then
    if [ -n "${_dark_mode_file}" ]; then
      echo "  ⚠ Há ARQUIVO de modo escuro (${_dark_mode_file}) e o parser indexa os tokens só pelo"
      echo "    path — o override do escuro SOBRESCREVE o valor claro no mesmo endereço, então o que"
      echo "    foi medido acima é UM tema, não dois. O gate não sabe qual. Declarado, não medido."
    fi
    # ⚠️ `test("dark")` e SUBSTRING: um par do CLARO chamado `color.darkblue` bastava para silenciar
    # o aviso do escuro. A ancora exige `dark` como SEGMENTO do path (inicio, fim ou entre pontos).
    if ! jq -e '[.pairs[] | select((.fg|test("(^|\\.)dark($|\\.)")) or (.bg|test("(^|\\.)dark($|\\.)")))] | length > 0' "${PAIRS}" >/dev/null 2>&1; then
      echo "  ⚠ A SSOT tem ramo de modo ESCURO e a governança NÃO declara nenhum par"
      echo "    com ele — o contraste do tema escuro NÃO FOI MEDIDO. O gate está dizendo menos do que"
      echo "    parece: 'passou' aqui significa 'passou no claro'. Declare os pares do escuro em"
      echo "    ${PAIRS#"${DC}/"} (medido em campo: 4 paletas com brand.500 a 1,71-2,60 contra fundo"
      echo "    escuro passariam inteiras)."
    fi
  fi
else
  # Sem governança declarada, o gate NÃO mediu contraste nenhum — e dizer "pulada" sem dizer o que
  # isso custa é como o "PULADA" do jq: uma palavra que soa benigna sobre uma lacuna que não é.
  echo "  ⚠ sem governance/contrast-pairs.json — NENHUM contraste WCAG foi medido neste projeto."
  echo "    O gate validou forma e aliases, não legibilidade. Não conclua 'acessível' a partir daqui."
fi

# --- Sumário ----------------------------------------------------------------
echo ""
echo "=== Sumário ==="
echo "  Violações HARD : ${HARD}"
if [ "${HARD}" -gt 0 ]; then echo "FALHOU — corrija as violações HARD."; exit 1; fi
echo "OK ✓ — design tokens válidos."
exit 0
