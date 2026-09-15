#!/usr/bin/env bash
# =============================================================================
# assemble-plugin.sh — Monta UMA vertical Onion como plugin Claude Code (genérico)
#
# Propósito : Materializar qualquer "vertical-skill" (ADR onion-adr-exchange-unit-2026-06)
#             no layout de plugin Claude Code, a partir de um MANIFESTO que lista as
#             fontes canônicas em .claude/. SSOT continua .claude/; o dir do plugin é
#             ARTEFATO GERADO (à la docs/onion/inventory.md). Distribui SÓ a camada 1
#             (capacidade); a camada 2 (docs/*-context/) fica do consumidor e o
#             SDAAL+transformer adapta (separação de camadas).
#
# Generaliza o antigo assemble-design-plugin.sh: dirigido por manifesto (shell),
# dependency-free (sem jq). Prova de que o padrão vale p/ N verticais (design,
# compliance, …) sem duplicar o assembler.
#
# Manifesto (shell, em verticals/<plugin>.manifest.sh) define:
#   PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_DESC, KEYWORDS=()
#   COMMANDS=()   # dirs (copia *.md de dentro) ou arquivos → commands/
#   AGENTS=()     # arquivos → agents/
#   UTILS=()      # dirs → utils/        (vazio = sem SDAAL utils, ok)
#   VALIDATION=() # arquivos → validation/ (vazio = sem gate, ok)
#   TEMPLATES=()  # arquivos → templates/  (vazio = sem templates, ok)
#   SKILLS=()     # dirs (Agent Skill c/ SKILL.md) → skills/  (auto-descoberto pelo plugin)
#   HOOKS=()      # arquivos (scripts) → hooks/  (registro via hooks.json fica a cargo do consumidor)
#   DOCS=()       # arquivos → kb/  KB de FRAMEWORK (tipo A: gitflow-patterns, worklog-protocol…) que a
#                 # vertical CITA. Torna o plugin auto-suficiente sem /meta:adopt. NÃO é o contexto do
#                 # consumidor (tipo B: docs/*-context/) — esse fica L2, resolvido pela skill de contexto.
#
# Uso       : assemble-plugin.sh <manifest> [source-root] [dest-dir]
#             source-root default = git toplevel; dest default = <root>/plugins/<PLUGIN_NAME>
#             Determinístico + idempotente: mesmo HEAD → mesmo output.
#
# Gracioso  : manifesto/source inválido ou componente-fonte ausente → exit 2.
#             Falha de I/O → aviso STDERR + exit 0. Sem set -e p/ controlar o exit.
#
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_assemble_plugin_selftests).
# =============================================================================
set -uo pipefail

MANIFEST="${1:-}"
[ -n "${MANIFEST}" ] && [ -f "${MANIFEST}" ] || { echo "ERRO: manifesto inválido: '${MANIFEST}'" >&2; exit 2; }

SRC="${2:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
[ -n "${SRC}" ] && [ -d "${SRC}" ] || { echo "ERRO: source-root inválido: '${SRC}'" >&2; exit 2; }
git -C "${SRC}" rev-parse --git-dir >/dev/null 2>&1 || { echo "ERRO: source não é repo git: ${SRC}" >&2; exit 2; }

# Defaults antes do source (manifesto pode sobrescrever).
PLUGIN_NAME=""; PLUGIN_VERSION="0.1.0"; PLUGIN_DESC=""; KEYWORDS=()
COMMANDS=(); AGENTS=(); UTILS=(); VALIDATION=(); TEMPLATES=(); SKILLS=(); HOOKS=(); DOCS=()
CONFORMANCE="bronze"; PROVIDES=(); REQUIRES=(); LOADS=()   # Capability Contract (ADR capability-contract)
# shellcheck disable=SC1090
. "${MANIFEST}"
[ -n "${PLUGIN_NAME}" ] || { echo "ERRO: manifesto sem PLUGIN_NAME: ${MANIFEST}" >&2; exit 2; }

DEST="${3:-${SRC}/plugins/${PLUGIN_NAME}}"

# Valida fontes (todas as listadas devem existir).
for c in "${COMMANDS[@]}"; do [ -e "${SRC}/${c}" ] || { echo "ERRO: command fonte ausente: ${c}" >&2; exit 2; }; done
for a in "${AGENTS[@]}"; do [ -f "${SRC}/${a}" ] || { echo "ERRO: agente fonte ausente: ${a}" >&2; exit 2; }; done
for u in "${UTILS[@]}"; do [ -d "${SRC}/${u}" ] || { echo "ERRO: util fonte ausente: ${u}" >&2; exit 2; }; done
for v in "${VALIDATION[@]}"; do [ -f "${SRC}/${v}" ] || { echo "ERRO: validation fonte ausente: ${v}" >&2; exit 2; }; done

# ── O BUNDLE TEM DE FECHAR O GRAFO DE DEPENDENCIAS ──────────────────────────────────────────────
# Script copiado que resolve uma lib por `HERE/lib/<x>` precisa que a lib venha JUNTO. Sem isto o
# manifesto monta limpo, passa no lint, e o plugin nasce MORTO no adotante — sai 2 no primeiro uso,
# no ambiente de quem instalou, longe de quem publicou. Nao e hipotetico: aconteceu ao introduzir
# `lib/status-factor.awk` e foi curado A MAO nos dois manifestos. Cura a mao nao se repete sozinha,
# entao virou aresta de CONSTRUCAO, aqui, no unico ponto por onde toda vertical passa.
#
# ⚠️ AQUI EM CIMA, JUNTO DA VALIDACAO DE FONTE, E NAO NO LACO DE COPIA — e isso foi medido por dano:
# a 1a versao desta guarda abortava DEPOIS de copiar, e o assembler que desiste deixava o destino
# em ruinas (21 arquivos sujos, `plugin.json` DELETADO, o lint acusando "fora de sincronia"). Guarda
# que aborta tem de abortar ANTES de tocar no destino, senao a recusa e mais destrutiva que o defeito
# que ela recusa. Toda validacao deste script mora antes da 1a escrita, e esta se junta a elas.
_missing_deps=""
for v in "${VALIDATION[@]}"; do
  case "${v}" in *.sh) : ;; *) continue ;; esac
  while IFS= read -r _need; do
    [ -n "${_need}" ] || continue
    case "${_need}" in
      lib/*) _target=".claude/validation/${_need}" ;;
      *)     _target=".claude/validation/${_need}" ;;
    esac
    case " ${VALIDATION[*]} " in *" ${_target} "*) : ;;
      *) _missing_deps="${_missing_deps}\n  · ${v} precisa de ${_target}, que NAO esta no VALIDATION[] deste manifesto" ;;
    esac
    # DUAS formas de dep, e a 2a era invisivel ate 2026-09-05:
    #   · lib/<x>.awk|sh          — a lib compartilhada (a unica que a 1a versao olhava)
    #   · <irmao>.sh ao lado      — resolvido por `$(dirname "$BASH_SOURCE")/<irmao>.sh` ou por
    #                               ${CLAUDE_PLUGIN_ROOT}/validation/<irmao>.sh no bundle
  done < <( { grep -oE 'lib/[A-Za-z0-9_.-]+\.(awk|sh)' "${SRC}/${v}" 2>/dev/null
              # dep IRMAO: so conta se for INVOCACAO em linha NAO-comentario — `bash <x>.sh`,
              # `${VAR}/<x>.sh`, ou `$(dirname ...)/<x>.sh`. Citacao em comentario (`graph.sh:164`)
              # NAO e dependencia: a 1a versao desta generalizacao lia prosa e reprovou o bundle todo.
              grep -vE '^[[:space:]]*#' "${SRC}/${v}" 2>/dev/null \
                | grep -oE '(bash[[:space:]]+|/)[A-Za-z0-9_.-]+\.sh' \
                | grep -oE '[A-Za-z0-9_.-]+\.sh$' \
                | while IFS= read -r _c; do [ -f "${SRC}/.claude/validation/${_c}" ] && printf '%s\n' "${_c}"; done
            } | grep -v "^$(basename "${v}")$" | sort -u )
done
if [ -n "${_missing_deps}" ]; then
  printf 'ERRO: o bundle nao fecha o grafo de dependencias — o plugin nasceria morto no adotante:%b\n' "${_missing_deps}" >&2
  exit 2
fi
for t in "${TEMPLATES[@]}"; do [ -f "${SRC}/${t}" ] || { echo "ERRO: template fonte ausente: ${t}" >&2; exit 2; }; done
for s in "${SKILLS[@]}"; do [ -d "${SRC}/${s}" ] || { echo "ERRO: skill fonte ausente (dir): ${s}" >&2; exit 2; }; done
for h in "${HOOKS[@]}"; do [ -f "${SRC}/${h}" ] || { echo "ERRO: hook fonte ausente (arquivo): ${h}" >&2; exit 2; }; done
for d in "${DOCS[@]}"; do [ -f "${SRC}/${d}" ] || { echo "ERRO: doc-KB fonte ausente (arquivo): ${d}" >&2; exit 2; }; done

# Montagem limpa (idempotente).
# ── O ESTADO COMMITADO, LIDO ANTES DE QUALQUER ESCRITA ────────────────────────────────────────
# A versão é um FATO COMMITADO, não uma derivação de histórico — e os dois insumos (a versão
# publicada e o `tree_sha` que ela descreve) vivem NA ÁRVORE. Por isso qualquer checkout da mesma
# árvore deriva o mesmo número, que é exatamente o que a REGRA 19 precisa para comparar.
#
# ⚠️ LÊ DO CANÔNICO (`${SRC}/plugins/<name>`), NUNCA DO `DEST`. Os dois consumidores desta função
#    são o pre-commit (DEST = o canônico) e a REGRA 19 (DEST = um mktemp descartável). Se o
#    anterior viesse do DEST, a regeneração em temp não teria anterior e o gate reprovaria SEMPRE.
#    Lendo do canônico, os dois leem a MESMA coisa e concordam por construção.
#
# ⚠️ E A POSIÇÃO É PARTE DA CURA, não organização: isto TEM de vir antes do `rm -rf "${DEST}"` da
#    linha abaixo. Quando DEST É o canônico (o caso do pre-commit), aquele `rm -rf` APAGA o fato
#    commitado — e a 1ª versão desta cura lia depois dele e derivava `0.1.0`, zerando a versão de
#    um plugin com 255 publicadas. Medido no primeiro dogfood, antes de qualquer commit.
_canon="${SRC}/plugins/${PLUGIN_NAME}/.claude-plugin"
_prior_version=""; _prior_tree=""
[ -f "${_canon}/plugin.json" ]     && _prior_version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'   "${_canon}/plugin.json"     | head -1)"
[ -f "${_canon}/provenance.json" ] && _prior_tree="$(sed -n    's/.*"tree_sha"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "${_canon}/provenance.json" | head -1)"

rm -rf "${DEST}" 2>/dev/null
mkdir -p "${DEST}/.claude-plugin" "${DEST}/commands" "${DEST}/agents" 2>/dev/null \
  || { echo "AVISO: não criou ${DEST} (permissão?) — plugin não montado." >&2; exit 0; }

# commands/ — dir → *.md de dentro; arquivo → o arquivo.
# ⚠️ O README de categoria NÃO VIAJA (medido 2026-09-07): `claude plugin validate --strict` valida
#    TODO .md em commands/ como comando, e o README de categoria não tem frontmatter — "No
#    frontmatter block found" reprovava 3 dos 5 plugins (design, engineering, product; os outros
#    dois só passavam por não terem README na sua categoria). O `help.md` TEM frontmatter e segue.
#    O skip é por NOME, deliberadamente previsível: filtrar por "não tem frontmatter" faria um
#    comando real mal-formado sumir calado, e sumir calado é pior que reprovar alto — a ausência
#    de frontmatter num comando de verdade já é REGRA 1 no core.
#    O casamento é case-insensitive sobre o RADICAL, espelhando a prior art da camada de geração
#    (`plugin-readme.sh:56` e `:61`, `base.lower()=="readme"`): a decisão "README em commands/ não
#    é comando" já existia lá, e duas metades do mesmo pipeline concordando em FORMAS DIFERENTES é
#    o defeito que volta calado (`readme.md` minúsculo passaria pelo assembler e reprovaria).
#    Vale nos DOIS ramos — o de arquivo avulso também é superfície viva (o manifesto de product
#    faz cherry-pick de `.claude/commands/docs/help.md` por ali), e assimetria entre ramos é como
#    se inverte um argumento sem ninguém ver.
_is_category_readme() {
  local _b; _b="$(basename "${1}")"; _b="${_b%.*}"
  [ "$(printf '%s' "${_b}" | tr '[:upper:]' '[:lower:]')" = "readme" ]
}
for c in "${COMMANDS[@]}"; do
  if [ -d "${SRC}/${c}" ]; then
    for _md in "${SRC}/${c}"/*.md; do
      [ -e "${_md}" ] || continue
      if _is_category_readme "${_md}"; then
        printf 'assemble-plugin: %s: %s não viaja (README de categoria não é comando)\n' "${c}" "$(basename "${_md}")" >&2
        continue
      fi
      cp "${_md}" "${DEST}/commands/" 2>/dev/null
    done
  elif _is_category_readme "${SRC}/${c}"; then
    printf 'assemble-plugin: %s não viaja (README de categoria não é comando)\n' "${c}" >&2
  else cp "${SRC}/${c}" "${DEST}/commands/" 2>/dev/null; fi
done
# agents/ — arquivos.
for a in "${AGENTS[@]}"; do cp "${SRC}/${a}" "${DEST}/agents/" 2>/dev/null; done
# utils/ — dirs (só cria a pasta se houver).
if [ "${#UTILS[@]}" -gt 0 ]; then
  mkdir -p "${DEST}/utils" 2>/dev/null
  # ⚠️ SÓ O QUE É RASTREADO VIAJA — `cp -R` copiava o diretório INTEIRO, lixo gitignorado incluído.
  # Medido 2026-09-15, e o modo de falha é o pior tipo: `.claude/utils/census/__pycache__/*.pyc`
  # existe no disco de quem roda python e NÃO no commit. O bundle montado LOCALMENTE ficava com o
  # .pyc, o montado no CI (checkout limpo) sem ele, e a REGRA 19 (Plugins de vertical (plugins/*)
  # sincronizados com as fontes) acusava "fora de sincronia" só no CI. O local se AUTO-ISENTAVA pelo
  # lixo do próprio ambiente — verde na máquina, vermelho no servidor, sem nada no diff que explicasse.
  # É a mesma doutrina que o transporte de adoção já aplica com `git archive HEAD`: o que não está
  # rastreado não existe para quem recebe.
  for u in "${UTILS[@]}"; do
    while IFS= read -r -d '' _f; do
      _rel="${_f#.claude/utils/}"
      mkdir -p "${DEST}/utils/$(dirname "${_rel}")" 2>/dev/null
      cp "${SRC}/${_f}" "${DEST}/utils/${_rel}" 2>/dev/null
    done < <(git -C "${SRC}" ls-files -z -- "${u}" 2>/dev/null)
  done
fi
# validation/ — arquivos, PRESERVANDO subdiretório relativo a .claude/validation/.
# (Flat vira validation/<arquivo>; aninhado como vendor/kg-console/cytoscape.min.js
#  precisa manter a estrutura — o kg-console.sh resolve o renderer por HERE/vendor/…)
if [ "${#VALIDATION[@]}" -gt 0 ]; then
  mkdir -p "${DEST}/validation" 2>/dev/null
  for v in "${VALIDATION[@]}"; do
    rel="${v#.claude/validation/}"; sub="$(dirname "${rel}")"
    mkdir -p "${DEST}/validation/${sub}" 2>/dev/null
    cp "${SRC}/${v}" "${DEST}/validation/${sub}/" 2>/dev/null
    case "${v}" in *.sh) chmod +x "${DEST}/validation/${sub}/$(basename "${v}")" 2>/dev/null ;; esac
  done
fi
# templates/ — arquivos (só cria a pasta se houver).
if [ "${#TEMPLATES[@]}" -gt 0 ]; then
  mkdir -p "${DEST}/templates" 2>/dev/null
  for t in "${TEMPLATES[@]}"; do cp "${SRC}/${t}" "${DEST}/templates/" 2>/dev/null; done
fi
# skills/ — dirs (Agent Skill = dir com SKILL.md; auto-descoberto pelo plugin). Só cria a pasta se houver.
if [ "${#SKILLS[@]}" -gt 0 ]; then
  mkdir -p "${DEST}/skills" 2>/dev/null
  for s in "${SKILLS[@]}"; do cp -R "${SRC}/${s}" "${DEST}/skills/" 2>/dev/null; done
fi
# hooks/ — arquivos (scripts) + REGISTRO. Sem o hooks.json o Claude Code empacota o hook mas NÃO o
# ativa (dogfood 2026-08-25: install → "Hooks: 0", a guarda exit-2 viajava inerte). O hooks.json é
# AUTO-DESCOBERTO (como commands/agents/skills); geramos mapeando cada hook empacotado ao EVENTO que o
# core lhe atribui em settings.json, com o path reescrito para ${CLAUDE_PLUGIN_ROOT}. Nunca invento
# evento: se o hook não estiver ligado no settings do core, ele não entra no hooks.json (fail-loud no
# relatório abaixo), pois hook sem evento é ruído inerte.
if [ "${#HOOKS[@]}" -gt 0 ]; then
  mkdir -p "${DEST}/hooks" 2>/dev/null
  for h in "${HOOKS[@]}"; do cp "${SRC}/${h}" "${DEST}/hooks/" 2>/dev/null && chmod +x "${DEST}/hooks/$(basename "${h}")" 2>/dev/null; done
  python3 - "${SRC}" "${DEST}/hooks/hooks.json" "${HOOKS[@]}" <<'PYHOOK'
import json, sys, os, glob
src, out = sys.argv[1], sys.argv[2]
bundled = [os.path.basename(h) for h in sys.argv[3:]]
events = {}
for fp in sorted(glob.glob(os.path.join(src, ".claude", "settings*.json"))):
    try: d = json.load(open(fp))
    except Exception: continue
    for event, arr in (d.get("hooks") or {}).items():
        for grp in (arr or []):
            for hk in (grp.get("hooks") or []):
                cmd = hk.get("command", "")
                for bn in bundled:
                    if bn in cmd and bn not in [x[0] for x in events.get(event, [])]:
                        # (basename, matcher) — o matcher do core viaja; sem ele PostToolUse roda em TODA tool (REGRA 73)
                        events.setdefault(event, []).append((bn, grp.get("matcher")))
result = {"hooks": {}}
for event, bns in events.items():
    result["hooks"][event] = [
        ({"matcher": matcher} if matcher else {}) | {"hooks": [{"type": "command", "command": f'bash "${{CLAUDE_PLUGIN_ROOT}}/hooks/{bn}"'}]}
        for bn, matcher in bns
    ]
mapped = {bn for bns in events.values() for bn, _m in bns}
missing = [bn for bn in bundled if bn not in mapped]
if missing:
    sys.stderr.write("AVISO assemble: hook(s) sem evento no settings.json do core (NÃO registrados): %s\n" % ", ".join(missing))
if result["hooks"]:
    with open(out, "w") as fh:
        json.dump(result, fh, indent=2, ensure_ascii=False); fh.write("\n")
PYHOOK
fi
# kb/ — KB de framework embarcado (tipo A). Só cria a pasta se houver.
if [ "${#DOCS[@]}" -gt 0 ]; then
  mkdir -p "${DEST}/kb" 2>/dev/null
  for d in "${DOCS[@]}"; do cp "${SRC}/${d}" "${DEST}/kb/" 2>/dev/null; done
fi

# ---------------------------------------------------------------------------
# PATH-PORTABILITY — reescreve refs ao layout-CORE p/ ${CLAUDE_PLUGIN_ROOT} (manifesto-dirigido).
# Cirúrgico: SÓ os paths dos componentes BUNDLADOS (utils/validation/templates). Refs a docs/* (camada 2
# do consumidor) e a soft-deps (@metaspec-gate-keeper, skills) NÃO entram no mapa → ficam intactas.
# A SSOT (.claude/) não é tocada; só as cópias do plugin. Determinístico.
# ---------------------------------------------------------------------------
PR='${CLAUDE_PLUGIN_ROOT}'
declare -a RW_FROM RW_TO
add_rw() { RW_FROM+=("$1"); RW_TO+=("$2"); }
for u in "${UTILS[@]}"; do add_rw "${u}" "${PR}/utils/$(basename "${u}")"; done
# validation: mapeia o DIRETÓRIO (cobre o glob `.claude/validation/*` e o arquivo específico).
declare -A _vseen=()
for v in "${VALIDATION[@]}"; do vd="$(dirname "${v}")"; [ -n "${_vseen[$vd]:-}" ] && continue; _vseen[$vd]=1; add_rw "${vd}" "${PR}/validation"; done
for t in "${TEMPLATES[@]}"; do add_rw "${t}" "${PR}/templates/$(basename "${t}")"; done
for s in "${SKILLS[@]}"; do add_rw "${s}" "${PR}/skills/$(basename "${s}")"; done
for h in "${HOOKS[@]}"; do add_rw "${h}" "${PR}/hooks/$(basename "${h}")"; done
# DOCS (KB tipo A embarcado): refs a esses docs específicos apontam p/ kb/ do plugin. Só os LISTADOS
# entram no mapa — docs/*-context/ (tipo B, do consumidor) seguem intactos (resolvidos pela skill de contexto).
for d in "${DOCS[@]}"; do add_rw "${d}" "${PR}/kb/$(basename "${d}")"; done

# Aplica os pares em TODOS os arquivos do plugin (escapa regex em FROM; `|` como delim).
while IFS= read -r f; do
  for i in "${!RW_FROM[@]}"; do
    from_esc="$(printf '%s' "${RW_FROM[$i]}" | sed 's/[.[\*^$/]/\\&/g')"
    sed -i "s|${from_esc}|${RW_TO[$i]}|g" "${f}" 2>/dev/null
  done
  # Colapsa prefixos relativos órfãos (`../../../${CLAUDE_PLUGIN_ROOT}` ← links markdown `[x](../../../docs/…)`)
  # → ${CLAUDE_PLUGIN_ROOT} é raiz-do-plugin; qualquer `../` antes dele é resíduo do rewrite. Idempotente.
  sed -i 's#\(\.\./\)\{1,\}\${CLAUDE_PLUGIN_ROOT}#${CLAUDE_PLUGIN_ROOT}#g' "${f}" 2>/dev/null
  # Scripts bundlados: PROJECT default core-ascend → cwd do consumidor (portável; core intacto).
  case "${f}" in *.sh) sed -i 's|\${1:-\${REPO_ROOT}}|${1:-$(pwd)}|g' "${f}" 2>/dev/null ;; esac
  # ⚠️ ${CLAUDE_PLUGIN_ROOT} NÃO EXISTE NO AMBIENTE DE UM SHELL — e o rewrite acima acabou de escrevê-lo
  #    DENTRO de código executável. Em markdown a variável é substituída pelo Claude Code antes de o
  #    comando rodar; num `.sh` ela é expansão de shell em runtime, e sob `set -u` o script morre na
  #    PRIMEIRA linha: `CLAUDE_PLUGIN_ROOT: unbound variable`. Medido 2026-09-06 numa sessão viva: o
  #    Bash tool NÃO exporta a variável (`env | grep CLAUDE` não a traz), e por isso
  #    `kg-backlog-project.sh` estava PUBLICADO E MORTO desde que entrou no bundle, com o gate verde.
  #    A cura é resolver a raiz PELO PRÓPRIO ARQUIVO (BASH_SOURCE), respeitando a variável quando ela
  #    de fato vier do ambiente (hooks). Idempotente e proporcional à profundidade real do arquivo.
  case "${f}" in *.sh)
    _code="$(grep -vE '^[[:space:]]*#' "${f}" 2>/dev/null || true)"
    if grep -qF '${CLAUDE_PLUGIN_ROOT}' <<< "${_code}"; then
      _rel="${f#${DEST}/}"; _slashes="${_rel//[!\/]/}"; _up=""
      for ((_k=0; _k<${#_slashes}; _k++)); do _up="${_up}../"; done
      awk -v up="${_up}" '
        NR==1 && /^#!/ { print; print "# raiz do plugin resolvida PELO PRÓPRIO ARQUIVO (o ambiente do shell não traz a variável)";
                         print ": \"${CLAUDE_PLUGIN_ROOT:=$(cd \"$(dirname \"${BASH_SOURCE[0]}\")/" up "\" \&\& pwd)}\""; next }
        { print }
      ' "${f}" > "${f}.pr" 2>/dev/null && mv "${f}.pr" "${f}"
    fi
    ;;
  esac
done < <(find "${DEST}" -type f ! -path "*/.claude-plugin/*" 2>/dev/null)

# ---------------------------------------------------------------------------
# NAMESPACE-PORTABILITY — comandos de plugin são `/<plugin>:<cmd>`, nunca `/<ns-do-core>:<cmd>`.
# Medido 2026-09-04: 531 refs no namespace do core em plugins/ (208 cross, 194 mesmo-plugin, 129 dangling),
# ZERO na forma do plugin — o lint só varria .claude/ + docs/, onde `/engineer:pr` resolve. A cura é do
# helper da REGRA 72 (um só lugar para regex + mapa): mapeado → forma do plugin (mapa derivado de TODOS os
# manifestos, não só deste); dangling (meta-fábrica, não distribuída) → sem a barra. O helper vive no
# core (dirname deste script), não no SRC — a bancada monta SRCs mínimos sem .claude/validation/.
# ---------------------------------------------------------------------------
NS_HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../validation/plugin-namespace-check.sh"
if [ -f "${NS_HELPER}" ]; then
  bash "${NS_HELPER}" "${SRC}" --rewrite "${DEST}" || printf 'assemble-plugin: NAMESPACE-PORTABILITY falhou (rc=%s) — REGRA 72 vai acusar\n' "$?" >&2
else
  printf 'assemble-plugin: helper de namespace ausente (%s) — refs ao namespace do core ficam intactas\n' "${NS_HELPER}" >&2
fi

# ---------------------------------------------------------------------------
# IRMÃ-NÃO-EMBARCADA → PLAIN-TEXT (cura POR CONSTRUÇÃO — medido em 2026-08-18).
# Uma KB embarcada em kb/ cita as irmãs por link relativo (`[X](irma.md)`). Quando a irmã NÃO está
# no manifesto, o link resolve dentro do plugin para um arquivo que não existe: MORTO. Medição que
# motivou: 15 links mortos em DOIS plugins (onion-work-tools 12, onion-engineering 3), acumulados em
# três PRs sem que guarda nenhuma acusasse — o kb-vendored-link-check testa outro predicado (link
# core-privado) e não varre plugins/. A cura aqui é por construção, não por detecção: o próprio
# empacotamento converte o link em plain-text (o título permanece legível; só a âncora morre), então
# a classe deixa de ser possível. Fonte≠derivação: a SSOT em docs/knowledge-base segue com os links
# vivos — a conversão é só na CÓPIA do plugin, onde o alvo de fato não existe.
# ---------------------------------------------------------------------------
# GENERALIZADO em 2026-09-04 (REGRA 75): a cura acima só cobria kb/ e irmãs no MESMO diretório; medidos 123
# links relativos mortos fora dela (commands 46, utils 31, kb 30, skills 17). Agora: todo .md do plugin,
# qualquer caminho relativo (templates/ fica fora — aponta para o que o consumidor vai gerar). O helper da
# REGRA 75 é o único lugar da regex; o assembler só o chama. Helper no core (dirname deste script), não no SRC.
DL_HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../validation/plugin-dead-link-check.sh"
if [ -f "${DL_HELPER}" ]; then
  bash "${DL_HELPER}" "${SRC}" --rewrite "${DEST}" || printf 'assemble-plugin: dead-link-portability falhou (rc=%s) — REGRA 75 vai acusar\n' "$?" >&2
else
  printf 'assemble-plugin: helper de links mortos ausente (%s) — links relativos mortos ficam intactos\n' "${DL_HELPER}" >&2
fi

# Proveniência content-addressed (padrão gh skill): repository + ref + tree_sha.
# tree_sha = hash do CONTEÚDO da WORKING-TREE das fontes (NÃO `ls-tree HEAD`) — assim é consistente
# no pre-commit (onde HEAD≠staged) e independente de SRC/DEST absolutos. Lista "blobsha relpath"
# ordenada → hash. Determinístico; muda só quando o conteúdo das fontes muda. (ref/commit_date vêm
# do HEAD e são VOLÁTEIS — o drift-guard os ignora; só o tree_sha é o sinal de drift de conteúdo.)
# Face pública (SSOT em public-face.sh): `repository` abaixo é a ORIGEM e serve SÓ à proveniência.
# `homepage` e `repository` do manifesto são a CASA e o CANAL PÚBLICOS — papéis distintos desde
# 2026-09-07 (nó D_CONTATO_DESACOPLADO): a origem é privada e não pode ser publicada como endereço.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/public-face.sh"

# GERADORES SÃO INSUMO (medido 2026-09-07, Elenxo do PR 1). `tree_sha` e a versão derivada eram
# calculados só sobre as FONTES do manifesto — e o assembler, o gerador de README e a face pública
# não estavam em nenhum dos dois conjuntos. Consequência medida: a cura que tirou o README de
# categoria de dentro de `commands/` MUDOU o conteúdo publicado de 3 plugins e, ainda assim,
# `tree_sha` ficou idêntico e a versão travada (design 0.1.22, engineering 0.1.92, product 0.1.53)
# — `claude plugin update` responderia "already at the latest version" e o instalador ficaria com
# o artefato que reprova. É exatamente o modo de falha que a versão derivada nasceu para curar,
# reaparecendo por um flanco que ela não cobria: mudar o GERADOR muda a SAÍDA.
# Ausente = ignorado (adotante sem a maquinaria de marketplace segue montando).
_GEN=()
for _g in .claude/utils/marketplace/assemble-plugin.sh \
          .claude/utils/marketplace/plugin-readme.sh \
          .claude/utils/marketplace/public-face.sh \
          .claude/validation/plugin-namespace-check.sh \
          .claude/validation/plugin-dead-link-check.sh; do
  [ -f "${SRC}/${_g}" ] && _GEN+=("${_g}")
done

url="$(git -C "${SRC}" remote get-url origin 2>/dev/null || true)"
repository="$(printf '%s' "${url}" | sed -E 's#(git@|https://)([^/:]+)[/:]##; s#\.git$##')"
[ -n "${repository}" ] || repository="local/${PLUGIN_NAME}"
ref="$(git -C "${SRC}" rev-parse HEAD 2>/dev/null || echo unknown)"
commit_date="$(git -C "${SRC}" show -s --format=%cI HEAD 2>/dev/null || echo unknown)"
tree_sha="$(
  {
    for p in "${COMMANDS[@]}" "${AGENTS[@]}" "${UTILS[@]}" "${VALIDATION[@]}" "${TEMPLATES[@]}" "${SKILLS[@]}" "${HOOKS[@]}" "${DOCS[@]}" ${_GEN[@]+"${_GEN[@]}"}; do
      # ⚠️ `git ls-files`, NUNCA `find` — medido 2026-09-15, e é a metade do defeito que a cura da
      # cópia não alcançou. `find` varre o DISCO: `.claude/utils/census/__pycache__/*.pyc` existe na
      # máquina de quem roda python, não no commit, e entrava no hash. Resultado: `tree_sha` calculado
      # localmente ≠ calculado num checkout limpo, e a REGRA 19 (Plugins de vertical (plugins/*)
      # sincronizados com as fontes) acusava drift SÓ NO CI, sem nada no diff que explicasse.
      # Content-addressed só vale se o conteúdo endereçado for o MESMO para todo mundo — e o que é
      # igual para todo mundo é o que está rastreado.
      if [ -d "${SRC}/${p}" ]; then git -C "${SRC}" ls-files -- "${p}"; else printf '%s\n' "${p}"; fi
    done | LC_ALL=C sort | while IFS= read -r rel; do
      printf '%s %s\n' "$(git -C "${SRC}" hash-object "${SRC}/${rel}" 2>/dev/null || echo nohash)" "${rel}"
    done
  } | git hash-object --stdin 2>/dev/null || echo unknown
)"

cat > "${DEST}/.claude-plugin/provenance.json" <<EOF
{
  "repository": "${repository}",
  "ref": "${ref}",
  "tree_sha": "${tree_sha}",
  "commit_date": "${commit_date}",
  "note": "Proveniência content-addressed (padrão gh skill). tree_sha = hash do ls-tree das fontes canônicas em .claude/. SSOT = .claude/; este plugin é artefato gerado por assemble-plugin.sh + verticals/${PLUGIN_NAME}.manifest.sh."
}
EOF

# KEYWORDS bash array → JSON array (sem jq).
# VERSÃO DERIVADA DO CONTEÚDO — e a TERCEIRA tentativa de acertar o mecanismo, porque as duas
# primeiras erraram por baixo do mesmo pressuposto: que a versão podia ser CALCULADA do histórico.
#
# O sinal original (2026-09-03): `claude plugin update` compara só a STRING de versão, então um
# manifesto parado em 0.1.0 deixa o updater no-op com o cache 89 arquivos atrás. Versão que não
# anda é declaração (behavior-over-declaration).
#
# TENTATIVA 1 — contar os commits do HEAD, +1 se há staged. Quebrava no SQUASH-MERGE, que é como
#   esta casa funde: N commits da branch viram UM no main, a branch publicava N a mais e o main
#   ganhava 1. Medido no vivo: `origin/main` publicava 0.1.255 e a árvore do próprio main derivava
#   0.1.254 — a REGRA 19 falhando no main, onde nenhum gate de PR olha.
# TENTATIVA 2 — contar sobre `origin/main`. Consertava o squash (confirmado com `merge --squash`
#   real) e introduzia DOIS modos de falha novos, achados na passada adversarial: (a) a versão
#   virava função do REMOTO, então um PR aberto passava a reprovar a REGRA 19 sozinho assim que
#   OUTRO PR mergeava, sem nada mudar nele; (b) sob GitFlow, com `main` parado e `develop` andando,
#   a versão CONGELAVA — literalmente o dano que ela invocava como justificativa.
#
# A lição das duas: enquanto a versão for função do HISTÓRICO ou do REMOTO, ela não pode ser ao
# mesmo tempo reproduzível-da-árvore (o que a REGRA 19 exige) e estável (o que um PR aberto exige).
# São requisitos incompatíveis nesse eixo.
#
# TENTATIVA 3, a desta linha: a versão é um FATO COMMITADO.
#     versão nova = versão COMMITADA + (o `tree_sha` mudou ? 1 : 0)
# Os dois insumos vivem na árvore. Consequências, todas MEDIDAS com squash real antes de escrever:
#   · mesma árvore ⇒ mesmo número, sempre (a REGRA 19 passa a comparar algo estável);
#   · imune ao squash — a branch previu 3, o main pós-squash ficou 3, a regeneração no main deu 3;
#   · imune ao que OUTRO PR faz — o PR aberto ficou em 4 enquanto outro mergeava;
#   · não congela sob GitFlow, porque anda por MUDANÇA DE CONTEÚDO e não por posição no grafo;
#   · monotônica por construção: o único movimento possível é +1.
#
# TETO DECLARADO, e ele encolheu mas não sumiu: dois PRs concorrentes que tocam fontes e são
# mergeados SEM rebase entre si publicam o mesmo número. O fluxo de merge desta casa exige branch
# atualizada, e com rebase o segundo lê a versão do primeiro e segue para N+2. Está escrito aqui
# porque guarda com teto não-declarado vira promessa.
#
# `ONION_PLUGIN_VERSION_DERIVED=0` desliga (bancada/legado): fica a versão do manifesto.
if [ "${ONION_PLUGIN_VERSION_DERIVED:-1}" = "1" ]; then
  if [ -n "${_prior_version}" ]; then
    _n="${_prior_version##*.}"
    case "${_n}" in ''|*[!0-9]*) _n=0 ;; esac
    # A COMPARAÇÃO É DE CONTEÚDO, não de data nem de commit: `tree_sha` já é o hash das fontes
    # canônicas (e inclui os GERADORES desde 2026-09-07, porque mudar o gerador muda a saída).
    [ "${tree_sha}" = "${_prior_tree}" ] || _n=$(( _n + 1 ))
    PLUGIN_VERSION="${PLUGIN_VERSION%.*}.${_n}"
  else
    # PRIMEIRA GERAÇÃO deste plugin (ou alvo sem o canônico ao lado): não há fato commitado de que
    # partir. Fica a versão do manifesto — e a PRÓXIMA geração já terá de onde contar.
    :
  fi
fi

kw_json=""; for k in "${KEYWORDS[@]}"; do kw_json="${kw_json}\"${k}\","; done; kw_json="[${kw_json%,}]"

# plugin.json — EXATAMENTE os 8 campos permitidos (additionalProperties REJEITADO).
cat > "${DEST}/.claude-plugin/plugin.json" <<EOF
{
  "name": "${PLUGIN_NAME}",
  "version": "${PLUGIN_VERSION}",
  "description": "${PLUGIN_DESC}",
  "author": { "name": "Onion - Marcio Carvalho" },
  "homepage": "${ONION_PUBLIC_HOMEPAGE}",
  "repository": "${ONION_PUBLIC_REPOSITORY}",
  "license": "MIT",
  "keywords": ${kw_json}
}
EOF

# capability.json — Capability Contract materializado (auto-descrição content-stable; sem campos voláteis).
# REQUIRES_PLUGINS (opcional, REGRA 77): dependência de OUTRO PLUGIN do marketplace (uma skill/util que só ele
# embarca) vira `plugin:<nome>` em requires — contrato declarado, não menção. Menção de comando cruzado NÃO é
# dependência (é informativa; o README lista em "Funciona melhor com").
declare -a _REQ_PLUGINS=(); for _rp in "${REQUIRES_PLUGINS[@]:-}"; do [ -n "${_rp}" ] && _REQ_PLUGINS+=("plugin:${_rp}"); done
json_arr() { local out="" x; for x in "$@"; do out="${out}\"${x}\","; done; printf '[%s]' "${out%,}"; }
cat > "${DEST}/.claude-plugin/capability.json" <<EOF
{
  "name": "${PLUGIN_NAME}",
  "version": "${PLUGIN_VERSION}",
  "conformance": "${CONFORMANCE}",
  "provides": $(json_arr "${PROVIDES[@]}"),
  "requires": $(json_arr "${REQUIRES[@]}" "${_REQ_PLUGINS[@]}"),
  "loads": $(json_arr "${LOADS[@]}")
}
EOF

# LICENSE por plugin (exigência do diretório oficial de plugins do Claude Code: "each plugin must include its own LICENSE").
# Copia o LICENSE do source; se não houver, escreve MIT com o autor do plugin.json.
if [ -f "${SRC}/LICENSE" ]; then cp "${SRC}/LICENSE" "${DEST}/LICENSE"
else printf 'MIT License\n\nCopyright (c) Onion - Marcio Carvalho\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n' > "${DEST}/LICENSE"
fi

# README do plugin (padrão de referência de plugins do Claude Code) — gerado do próprio plugin montado.
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugin-readme.sh" "${DEST}" "${ONION_MARKETPLACE_NAME:-onion-plugins}" >&2 || true

echo "Onion: plugin '${PLUGIN_NAME}' montado em ${DEST} (tree_sha=${tree_sha:0:12}; conformance=${CONFORMANCE})." >&2
exit 0
