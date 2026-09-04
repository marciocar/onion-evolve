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
    _target=".claude/validation/lib/${_need}"
    case " ${VALIDATION[*]} " in *" ${_target} "*) : ;;
      *) _missing_deps="${_missing_deps}\n  · ${v} precisa de ${_target}, que NAO esta no VALIDATION[] deste manifesto" ;;
    esac
  done < <(grep -oE 'lib/[A-Za-z0-9_.-]+\.(awk|sh)' "${SRC}/${v}" 2>/dev/null | sed 's#^lib/##' | sort -u)
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
rm -rf "${DEST}" 2>/dev/null
mkdir -p "${DEST}/.claude-plugin" "${DEST}/commands" "${DEST}/agents" 2>/dev/null \
  || { echo "AVISO: não criou ${DEST} (permissão?) — plugin não montado." >&2; exit 0; }

# commands/ — dir → *.md de dentro; arquivo → o arquivo.
for c in "${COMMANDS[@]}"; do
  if [ -d "${SRC}/${c}" ]; then cp "${SRC}/${c}"/*.md "${DEST}/commands/" 2>/dev/null
  else cp "${SRC}/${c}" "${DEST}/commands/" 2>/dev/null; fi
done
# agents/ — arquivos.
for a in "${AGENTS[@]}"; do cp "${SRC}/${a}" "${DEST}/agents/" 2>/dev/null; done
# utils/ — dirs (só cria a pasta se houver).
if [ "${#UTILS[@]}" -gt 0 ]; then
  mkdir -p "${DEST}/utils" 2>/dev/null
  for u in "${UTILS[@]}"; do cp -R "${SRC}/${u}" "${DEST}/utils/" 2>/dev/null; done
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
if [ -d "${DEST}/kb" ]; then
  for f in "${DEST}/kb/"*.md; do
    [ -f "${f}" ] || continue
    while IFS= read -r tgt; do
      [ -f "${DEST}/kb/${tgt}" ] && continue
      tgt_esc="$(printf '%s' "${tgt}" | sed 's/\./\\./g')"
      sed -i -E "s|\[([^][]*)\]\(${tgt_esc}(#[^)]*)?\)|\1|g" "${f}"
    done < <(grep -oE '\]\([a-z0-9-]+\.md(#[^)]*)?\)' "${f}" | sed -E 's/^\]\(([a-z0-9-]+\.md).*/\1/' | sort -u)
  done
fi

# Proveniência content-addressed (padrão gh skill): repository + ref + tree_sha.
# tree_sha = hash do CONTEÚDO da WORKING-TREE das fontes (NÃO `ls-tree HEAD`) — assim é consistente
# no pre-commit (onde HEAD≠staged) e independente de SRC/DEST absolutos. Lista "blobsha relpath"
# ordenada → hash. Determinístico; muda só quando o conteúdo das fontes muda. (ref/commit_date vêm
# do HEAD e são VOLÁTEIS — o drift-guard os ignora; só o tree_sha é o sinal de drift de conteúdo.)
url="$(git -C "${SRC}" remote get-url origin 2>/dev/null || true)"
repository="$(printf '%s' "${url}" | sed -E 's#(git@|https://)([^/:]+)[/:]##; s#\.git$##')"
[ -n "${repository}" ] || repository="local/${PLUGIN_NAME}"
ref="$(git -C "${SRC}" rev-parse HEAD 2>/dev/null || echo unknown)"
commit_date="$(git -C "${SRC}" show -s --format=%cI HEAD 2>/dev/null || echo unknown)"
tree_sha="$(
  {
    for p in "${COMMANDS[@]}" "${AGENTS[@]}" "${UTILS[@]}" "${VALIDATION[@]}" "${TEMPLATES[@]}" "${SKILLS[@]}" "${HOOKS[@]}" "${DOCS[@]}"; do
      if [ -d "${SRC}/${p}" ]; then ( cd "${SRC}" && find "${p}" -type f ); else printf '%s\n' "${p}"; fi
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
# VERSÃO DERIVADA DO CONTEÚDO (sinal de campo 2026-09-03: `claude plugin update` compara só a string de versão —
# "already at the latest version (0.1.0)" com o cache 89 arquivos atrás do repo). Uma versão que não anda é
# declaração (behavior-over-declaration). Aqui: PLUGIN_VERSION = <major.minor do manifesto>.<N>, N = commits que
# tocaram as fontes canônicas deste plugin (+1 se o índice tem mudança pendente nelas — assim o pre-commit e o CI
# concordam). Monotônica, semver-válida, muda exatamente quando o conteúdo muda; regenerada pela REGRA 19.
# Sem git (alvo sem histórico) mantém a versão do manifesto. ONION_PLUGIN_VERSION_DERIVED=0 desliga (bancada/legado).
if [ "${ONION_PLUGIN_VERSION_DERIVED:-1}" = "1" ] && git -C "${SRC}" rev-parse --verify HEAD >/dev/null 2>&1; then
  _vsrc=(); for p in "${COMMANDS[@]}" "${AGENTS[@]}" "${UTILS[@]}" "${VALIDATION[@]}" "${TEMPLATES[@]}" "${SKILLS[@]}" "${HOOKS[@]}" "${DOCS[@]}"; do _vsrc+=("${p}"); done
  _mrel="${MANIFEST#${SRC}/}"; [ -f "${SRC}/${_mrel}" ] && _vsrc+=("${_mrel}")
  _n="$(git -C "${SRC}" rev-list --count HEAD -- "${_vsrc[@]}" 2>/dev/null || echo 0)"
  git -C "${SRC}" diff --cached --quiet -- "${_vsrc[@]}" 2>/dev/null || _n=$(( _n + 1 ))
  PLUGIN_VERSION="${PLUGIN_VERSION%.*}.${_n}"
fi

kw_json=""; for k in "${KEYWORDS[@]}"; do kw_json="${kw_json}\"${k}\","; done; kw_json="[${kw_json%,}]"

# plugin.json — EXATAMENTE os 8 campos permitidos (additionalProperties REJEITADO).
cat > "${DEST}/.claude-plugin/plugin.json" <<EOF
{
  "name": "${PLUGIN_NAME}",
  "version": "${PLUGIN_VERSION}",
  "description": "${PLUGIN_DESC}",
  "author": { "name": "Onion - Marcio Carvalho" },
  "homepage": "https://github.com/${repository}",
  "repository": "https://github.com/${repository}",
  "license": "MIT",
  "keywords": ${kw_json}
}
EOF

# capability.json — Capability Contract materializado (auto-descrição content-stable; sem campos voláteis).
json_arr() { local out="" x; for x in "$@"; do out="${out}\"${x}\","; done; printf '[%s]' "${out%,}"; }
cat > "${DEST}/.claude-plugin/capability.json" <<EOF
{
  "name": "${PLUGIN_NAME}",
  "version": "${PLUGIN_VERSION}",
  "conformance": "${CONFORMANCE}",
  "provides": $(json_arr "${PROVIDES[@]}"),
  "requires": $(json_arr "${REQUIRES[@]}"),
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
