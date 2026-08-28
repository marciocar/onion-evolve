#!/usr/bin/env bash
# =============================================================================
# kg-backlog-project.sh — projeta docs/backlog.md a partir dos nós `status: open`
#
# Propósito : a VISÃO HUMANA do trabalho aberto do core — a fila de decisão/
#             execução num lugar só. Projeção PURA: reescrita a cada run; item
#             fecha no grafo (status ≠ open) → some daqui sozinho. O grafo é a
#             fonte; este .md deriva (nunca editar à mão).
#
# Escopo    : a CAMADA CANÔNICA (docs/onion/graph/*.kg.yaml) EXCETO grafos opt-OUT
#             (# kg-backlog-archive: on — arquivos de pesquisa), UNIÃO os
#             grafos marcados `# kg-backlog-guard: on` em qualquer lugar (ex.: o
#             F4b em docs/evolution/research/). Exclui fixtures e o arquivo de
#             pesquisa/discussão histórica (docs/discussions, docs/evolution/*
#             não-marcado) — ruído epistêmico, visível só via `kg-radar --open-tsv`.
#             Decisão do maestro (2026-08-23): "nada sem controle" = fila inteira.
#
# Fonte     : `kg-radar --open-tsv` (a atenção já vem calculada, coluna 8 — a
#             régua do radar, não recalculada). Ordena por atenção, SEM corte.
#
# Uso       : bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-project.sh [--write|--check]
# =============================================================================
set -uo pipefail
# LOCALE PINADO — a razao e a mesma que instalou o pre-requisito do iconv, e o defeito e
# PIOR. Medido na revisao adversarial (2026-08-28):
#   · `sort` sem LC_ALL=C usa a collation do locale no DESEMPATE: em en_US.UTF-8 dois nos
#     de atencao 7.5 trocam de ordem vs C.UTF-8 → a catraca HARD acusa DRIFT num repo CERTO.
#   · `printf '%.1f'` do bash le LC_NUMERIC: sob pt_BR.UTF-8 (o locale do maestro!) ele
#     emite `38,0` no lugar de `38.2` — 190 erros em stderr e MESMO ASSIM exit 0, entao o
#     `_gen_into` chama de sucesso, o diff da DRIFT, e a mensagem manda REGENERAR: quem
#     obedecer GRAVA a projecao corrompida.
# Os irmaos ja pinam (graph.sh:164,222 · kg-view.sh:103,104) — este era o unico fora do
# padrao. Verificado no-op no artefato atual: com LC_ALL=C a saida e byte-identica.
export LC_ALL=C
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
RADAR="${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh"
OUT="docs/backlog.md"
MODE="--write"
# `case` FECHADO, como os irmaos ja curados (kg-drive-project.sh:31-37,
# kg-realign-project.sh:30-36). O `MODE="${1:---write}"` anterior era FAIL-OPEN num
# caminho de ESCRITA: `--dry-run` (ou qualquer typo) caia no ramo que sobrescreve
# docs/backlog.md em silencio. Arg desconhecido agora RECUSA, e nao muta nada.
for a in "$@"; do
  case "$a" in
    --check)    MODE="check" ;;
    --markdown) MODE="markdown" ;;
    --write)    MODE="--write" ;;
    *) echo "arg desconhecido: $a (use --write | --check | --markdown)" >&2; exit 2 ;;
  esac
done

# escopo: canônico ∪ marcado (dedup, sem fixtures)
mapfile -t GRAPHS < <( {
  git ls-files 'docs/onion/graph/*.kg.yaml'
  git ls-files '*.kg.yaml' | while read -r g; do
    grep -qE '^[[:space:]]*#[[:space:]]*kg-backlog-guard:[[:space:]]*on\b' "$g" 2>/dev/null && echo "$g"
  done
} | grep -v '/fixtures/' | sort -u | while read -r g; do
  # opt-OUT: grafo que se declara ARQUIVO/pesquisa some do backlog (segue no radar --open-tsv).
  # Decisao do maestro 2026-08-23: superficie de controle limpa > completude (federation-research
  # de 2026-06 era 63% do backlog, ruido historico afundando o sinal da fila de decisao).
  grep -qE '^[[:space:]]*#[[:space:]]*kg-backlog-archive:[[:space:]]*on\b' "$g" 2>/dev/null || echo "$g"
done )

# Saneador de UTF-8 do rotulo truncado. Existe porque a SUPERFICIE DE CONTROLE precisa
# ser grep-avel: com um byte invalido, o grep trata docs/backlog.md como BINARIO e
# SUPRIME A SAIDA — uma busca por um no aberto devolve vazio como se ele nao existisse
# (medido em 2026-08-28: 11 bytes invalidos, 2 buscas minhas mentindo em silencio).
# PRE-REQUISITO FAIL-LOUD, nao degradacao silenciosa: a partir do momento em que uma
# catraca HARD compara esta projecao byte-a-byte, um host sem iconv produziria render
# DIFERENTE e o lint acusaria DRIFT que e do AMBIENTE, nao do conteudo. Guarda que acusa
# o ambiente e pior que guarda nenhuma — entao o gerador recusa rodar em vez de emitir
# um artefato que so ele consegue reproduzir.
if ! command -v iconv >/dev/null 2>&1; then
  echo "kg-backlog-project: iconv AUSENTE — pre-requisito do render deterministico." >&2
  echo "  Sem ele o truncamento pode partir um caractere UTF-8 ao meio, e a projecao" >&2
  echo "  deixa de ser reproduzivel byte-a-byte (a catraca do lint compara bytes)." >&2
  exit 2
fi
_utf8_sane() { iconv -c -f UTF-8 -t UTF-8; }

# ENUMERAÇÃO VAZIA É QUEBRA, NÃO "ZERO ABERTOS". `git ls-files` devolve vazio quando não
# há índice (sandbox sem `git init`) ou quando o GIT_DIR está torto — incidente já medido
# nesta casa em 2026-08-04, com 4 falsos "desatualizado" de uma vez. O render sairia com
# cabeçalho e ZERO itens: não é vazio o bastante para o `_gen_into` do lint chamar de
# QUEBRA, então ele viraria DRIFT e a mensagem mandaria REGENERAR POR CIMA — sobrescrevendo
# a projeção boa por uma quase-vazia. Falha aberta que vira DESTRUTIVA. Recusa alto.
if [ "${#GRAPHS[@]}" -eq 0 ] && [ -d docs/onion/graph ]; then
  echo "kg-backlog-project: enumeracao de grafos VAZIA, mas docs/onion/graph existe." >&2
  echo "  git ls-files nao devolveu nada — sem indice git, ou GIT_DIR torto." >&2
  echo "  Isto e QUEBRA, nao 'zero abertos': gerar agora sobrescreveria a projecao boa." >&2
  exit 2
fi

TMP="$(mktemp)"
n_open=0
n_owner_declared=0   # quantos nos DECLARARAM owner: hoje ZERO no corpus inteiro
RERR="$(mktemp)"; RTSV="$(mktemp)"
trap 'rm -f "$TMP" "$RERR" "$RTSV"' EXIT
n_processed=0
for g in "${GRAPHS[@]}"; do
  # Grafo ENUMERADO mas AUSENTE do worktree (sparse-checkout, submodulo, `rm` sem `git rm`)
  # era `continue` — os itens dele sumiam CALADOS da projecao e a catraca carimbava
  # "em sincronia". Item que some em silencio e exatamente o que esta guarda existe para
  # impedir; deixa-lo passar aqui seria a guarda selando a propria doenca.
  if [ ! -f "$g" ]; then
    echo "kg-backlog-project: grafo ENUMERADO mas ausente do worktree: $g" >&2
    echo "  Isto e QUEBRA, nao 'zero itens': gerar agora perderia os itens dele em silencio." >&2
    exit 2
  fi
  base="$(basename "$g" .kg.yaml)"
  # mapa id→owner do grafo, UMA passada (owner é raro; ausente → fallback grafo)
  declare -A OWN=()
  while IFS=$'\t' read -r nid now; do OWN["$nid"]="$now"; done < <(
    awk '
      /^[^[:space:]]/ { id="" }                               # top-level (nodes:/edges:/meta:) sai do escopo do no
      /^[[:space:]]*- id:/ { id=$0; sub(/^[[:space:]]*- id:[[:space:]]*/,"",id); sub(/[[:space:]]*$/,"",id); next }
      /^[[:space:]]*owner:/ && id!="" { o=$0; sub(/^[^:]*:[[:space:]]*/,"",o); gsub(/"/,"",o); print id"\t"o; id="" }
    ' "$g" )
  # O rc do radar era DESCARTADO (`2>/dev/null` dentro de process substitution). Medido:
  # UM grafo ingramatical fazia 27 itens sumirem, o `--fix` gravava a perda, e a REGRA 62
  # reportava ZERO violacoes — a guarda selando de verde a perda silenciosa que ela existe
  # para impedir. Agora o radar roda ANTES, com rc lido e stderr preservado.
  # rc capturado em variavel: dentro de `if ! cmd`, o `$?` do corpo ja e o do PROPRIO if,
  # nao o do comando — a 1a versao desta mensagem imprimia "exit 0" para uma falha real.
  _rrc=0; bash "$RADAR" "$g" --open-tsv > "$RTSV" 2>"$RERR" || _rrc=$?
  if [ "$_rrc" -ne 0 ]; then
    echo "kg-backlog-project: kg-radar FALHOU em $g (exit $_rrc)" >&2
    sed 's/^/  radar: /' "$RERR" >&2
    echo "  Isto e QUEBRA: os itens deste grafo sumiriam da projecao sem aviso." >&2
    exit 2
  fi
  while IFS=$'\t' read -r file id typ plane st imp conf att vat trace c11 label; do
    [ -n "${id:-}" ] || continue
    if [ -n "${OWN[$id]:-}" ]; then owner="${OWN[$id]}"; n_owner_declared=$((n_owner_declared + 1)); else owner="$base"; fi
    printf '%s\t%s\t%s\t%s\t%s\n' "${att:-0}" "$owner" "$id" "$base" "${label:-}" >> "$TMP"
    n_open=$((n_open+1))
  done < "$RTSV"
  unset OWN
  n_processed=$((n_processed + 1))
done

# Sanidade final: todo grafo enumerado foi processado. Cinto sobre suspensorio — se algum
# caminho novo voltar a "pular" um grafo, isto reprova antes de a projecao ser escrita.
if [ "$n_processed" -ne "${#GRAPHS[@]}" ]; then
  echo "kg-backlog-project: processei $n_processed de ${#GRAPHS[@]} grafos enumerados." >&2
  echo "  Diferenca = itens perdidos em silencio. QUEBRA." >&2
  exit 2
fi

n_graphs="${#GRAPHS[@]}"
n_with_open="$(cut -f4 "$TMP" | sort -u | grep -c . || true)"
n_owners="$(cut -f2 "$TMP" | sort -u | grep -c . || true)"
n_archived="$(git ls-files 'docs/onion/graph/*.kg.yaml' '*.kg.yaml' 2>/dev/null | sort -u | while read -r g; do grep -qE '^[[:space:]]*#[[:space:]]*kg-backlog-archive:[[:space:]]*on\b' "$g" 2>/dev/null && echo x; done | grep -c . || true)"

render() {
  printf '# Backlog vivo — projeção dos grafos ⚙️ GERADO\n\n'
  printf '> Gerado por `${CLAUDE_PLUGIN_ROOT}/validation/kg-backlog-project.sh` a partir dos nós `status: open` da\n'
  printf '> camada canônica (`docs/onion/graph/`, exceto arquivos opt-OUT) + grafos marcados. **Não editar à mão**: feche o\n'
  printf '> item no grafo (status ≠ open, com carimbo) e ele sai daqui. Ordem = atenção (a régua do\n'
  printf '> radar: impact × incerteza × status). Sem corte NO ESCOPO; %s grafo(s) de arquivo (opt-OUT) ficam fora — visíveis via `kg-radar --open-tsv`.\n\n' "$n_archived"
  # O eixo de agrupamento e IMPRESSO, nunca prometido. O campo `owner:` e lido aqui desde
  # a origem e NUNCA foi escrito por ninguem — 0 ocorrencias no corpus inteiro (medido
  # 2026-08-28) — enquanto tres lugares em prosa afirmavam "agrupado por owner". E a mesma
  # assinatura que originou a REGRA 58: o cabecalho prometendo em letra grande o que era
  # disciplina. Agora a omissao e VISIVEL em vez de silenciosa (forma P1/P5 do
  # projection-safety.sh: a projecao imprime os marcadores que procurou).
  if [ "$n_owner_declared" -gt 0 ]; then
    printf '**%s itens abertos** em %s grafo(s) com aberto (de %s no escopo) · %s grupo(s), agrupados por `owner:` (%s nó(s) o declaram). A fila de decisão/execução do core; o topo por atenção é o que "custa caro estar errado".\n\n' "$n_open" "$n_with_open" "$n_graphs" "$n_owners" "$n_owner_declared"
  else
    printf '**%s itens abertos** em %s grafo(s) com aberto (de %s no escopo) · %s grupo(s). **Nenhum nó declara `owner:`** — o agrupamento é por GRAFO (o fallback). A fila de decisão/execução do core; o topo por atenção é o que "custa caro estar errado".\n\n' "$n_open" "$n_with_open" "$n_graphs" "$n_owners"
  fi
  if [ "$n_open" -eq 0 ]; then printf '_Nada aberto no escopo._\n'; return; fi
  # grupos ordenados por MAIOR atenção do grupo (empate: ordem estável do sort)
  cut -f2 "$TMP" | sort -u | while read -r grp; do
    maxatt="$(awk -F'\t' -v g="$grp" '$2==g{if($1+0>m)m=$1+0}END{printf "%.2f",m}' "$TMP")"
    printf '%s\t%s\n' "$maxatt" "$grp"
  done | sort -t$'\t' -k1,1nr | while IFS=$'\t' read -r _m grp; do
    cnt="$(awk -F'\t' -v g="$grp" '$2==g' "$TMP" | grep -c . || true)"
    printf '## %s — %s item(ns)\n\n' "$grp" "$cnt"
    printf '| Atenção | Nó | Grafo | O que é |\n|--:|---|---|---|\n'
    awk -F'\t' -v g="$grp" '$2==g' "$TMP" | sort -t$'\t' -k1,1nr | while IFS=$'\t' read -r att own id gr label; do
      # `sed`, NAO `tr`: o `tr` opera em BYTES e mapeia o `|` (0x7C) para o PRIMEIRO byte
      # de `·` (U+00B7 = C2 B7), gravando um 0xC2 solto — UTF-8 invalido. Consequencia
      # medida em 2026-08-28: 11 bytes invalidos em docs/backlog.md, e o grep passa a
      # tratar a SUPERFICIE DE CONTROLE como binario, suprimindo a saida EM SILENCIO
      # (uma busca por um no aberto devolvia vazio como se ele nao existisse).
      # E o `cut -c` conta BYTES (medido aqui mesmo, sob LANG=C.UTF-8): corta `ç` (C3 A7)
      # ao meio e deixa um C3 solto. `iconv -c` DESCARTA a sequencia incompleta — cura
      # deterministica que nao depende de locale. Sem iconv, degrada para o corte cru.
      lbl="$(printf '%s' "$label" | sed 's/|/·/g' | cut -c1-130 | _utf8_sane)"
      printf '| %.1f | `%s` | %s | %s |\n' "${att:-0}" "$id" "$gr" "$lbl"
    done
    printf '\n'
  done
}

# --markdown: a MESMA funcao render em stdout. E o modo que o `_gen_into` do lint exige
# (gerador que escreve em stdout), e os tres irmaos ja o tem (inventory, kg-view, graph).
# Por ser a mesma funcao, a paridade com `--write` e estrutural, nao uma promessa.
if [ "$MODE" = "markdown" ]; then
  render
  exit 0
fi

if [ "$MODE" = "check" ]; then
  if [ "$(cat "$OUT" 2>/dev/null || true)" = "$(render)" ]; then echo "backlog.md: em dia ($n_open abertos)"; else echo "backlog.md: DRIFT (advisory) — rode /meta:backlog"; fi
  exit 0
fi
render > "$OUT"
echo "✓ $OUT gerado: $n_open abertos · $n_with_open grafo(s) com aberto (de $n_graphs no escopo)"
