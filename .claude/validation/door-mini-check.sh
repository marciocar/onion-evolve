#!/usr/bin/env bash
# =============================================================================
# door-mini-check.sh — a verificação da PORTA DIDÁTICA (onion-mini), que não leva o lint.
#
# Uso:
#   door-mini-check.sh --bundle <dir> --source <core> [--no-exact] [--format text|tsv]
#   door-mini-check.sh --apply-overlays <dir> --source <core>
#
#   --bundle  a porta MONTADA (o clone, depois da materialização) — ou um diretório montado à parte
#   --source  a raiz do core de onde ela nasceu (no motor: a worktree destacada em origin/main). Dali
#             vêm a allowlist, os overlays e a lista do que EXISTE no core (comandos, agentes, fragmentos)
#   --no-exact  pula a conferência de allowlist exata (o `vendor-manifest --list mini` mede só ponteiro)
#   --apply-overlays  escreve no <dir> os arquivos PRÓPRIOS do mini (README, CLAUDE.md, skill onion
#             simplificada), lidos do HEAD do core. Falha FECHADA: overlay ausente ou vazio é rc 2.
#
# rc: 0 limpo · 1 achado (a porta não deve sair) · 2 não medi (SSOT ausente, uso inválido). Não medir
#     NUNCA vira limpo: quem chama trata o 2 como reprovação.
#
# ══ POR QUE ESTE SCRIPT EXISTE (F5 das portas, SAC-94, D_MATRIZ_DE_PORTAS_2026_10) ═══════════════
# As outras portas levam o lint e saem com 0 HARD; o mini é uma allowlist didática e não leva guarda
# nenhuma (dar a um iniciante 26 mil linhas de shell que reprovam seria o oposto do propósito). Sem
# lint, a pergunta "esta porta está boa?" precisava de OUTRA resposta, e são três:
#   1. ALLOWLIST EXATA — o que foi montado é exatamente o manifesto do papel (vendor-manifest --role
#      mini) mais os overlays e o que o materializador escreve (carimbo e LICENSE). Nem um arquivo a
#      mais (o core vazando para o iniciante), nem um a menos (o ciclo quebrado).
#   2. SEM PONTEIRO MORTO — tudo que um arquivo do mini cita tem de estar no mini: caminho `.claude/…`,
#      comando por nome (`/categoria:comando` e a forma antiga `/categoria/comando`), agente (`@nome`) e
#      fragmento (`common:prompts:nome`). Só conta citação de algo que EXISTE no core: nome inventado
#      não é ponteiro. A F2 media caminho e comando e achou 6 + 32; a 1ª passada da F5 mediu também
#      agente e fragmento, e eles eram dependência real (o `engineer:start` manda seguir um fragmento
#      que não viajava).
#   3. SEM CAMINHO DE MÁQUINA — nenhum `/home/<conta>/` no mini, de conta nenhuma. Aqui não há lista
#      de tolerados: o mini é pequeno o bastante para a regra ser absoluta.
# O que o mini cita e deliberadamente NÃO leva mora em `known_absent` no roles.yaml, uma linha por
# citação com o porquê. É uma catraca nos dois sentidos: citação nova fora da lista reprova, e entrada
# da lista que ninguém mais cita também reprova (lista de tolerância que só cresce é a que apodrece).
# =============================================================================
set -uo pipefail

BUNDLE=""; SRC=""; EXACT=1; FORMAT="text"; APPLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --bundle) BUNDLE="${2:?--bundle exige um diretório}"; shift 2 ;;
    --source) SRC="${2:?--source exige a raiz do core}"; shift 2 ;;
    --no-exact) EXACT=0; shift ;;
    --format) FORMAT="${2:?--format exige text|tsv}"; shift 2 ;;
    --apply-overlays) APPLY="${2:?--apply-overlays exige um diretório}"; shift 2 ;;
    -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
[ -n "${SRC}" ] || { echo "ERRO: --source é obrigatório" >&2; exit 2; }
SRC="$(cd "${SRC}" 2>/dev/null && pwd)" || { echo "ERRO: --source não existe" >&2; exit 2; }
git -C "${SRC}" rev-parse --verify --quiet HEAD >/dev/null || { echo "ERRO: --source não é repositório git com HEAD" >&2; exit 2; }
RESOLVER="${SRC}/.claude/utils/marketplace/resolve-role-bundle.sh"
[ -f "${RESOLVER}" ] || { echo "ERRO: sem o resolvedor do roles.yaml em ${SRC} — não sei o que o mini leva" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "ERRO: python3 necessário" >&2; exit 2; }
# DISCO × HEAD (passada adversarial da F5): o resolvedor e o manifesto leem o roles.yaml do DISCO de
# --source; a árvore do core e as fontes de overlay vêm do HEAD. No motor a worktree é limpa e as duas
# coincidem; num checkout com o roles.yaml editado e não commitado elas contariam histórias diferentes.
# Recusa em vez de misturar.
git -C "${SRC}" diff --quiet HEAD -- .claude/utils/marketplace/roles.yaml 2>/dev/null \
  || { echo "ERRO: o roles.yaml de ${SRC} tem edição não commitada — a allowlist do disco e a árvore do HEAD divergiriam; commite ou descarte antes de medir" >&2; exit 2; }

_overlays() {  # "destino<TAB>fonte" por linha, do roles.yaml do core
  local o; o="$(bash "${RESOLVER}" mini --overlays 2>/dev/null)" || { echo "ERRO: o resolvedor não devolveu os overlays do mini" >&2; return 2; }
  [ -n "${o}" ] || { echo "ERRO: o mini não declara overlays no roles.yaml — sem eles a porta sai sem README e CLAUDE.md próprios" >&2; return 2; }
  printf '%s\n' "${o}"
}

# ── --apply-overlays: os arquivos próprios do mini, do HEAD do core ───────────────────────────
if [ -n "${APPLY}" ]; then
  [ -d "${APPLY}" ] || { echo "ERRO: destino inexistente: ${APPLY}" >&2; exit 2; }
  ov="$(_overlays)" || exit 2
  n=0
  while IFS=$'\t' read -r dst src; do
    [ -n "${dst}" ] || continue
    case "${dst}" in *..*|/*|.git|.git/*) echo "ERRO: overlay com destino inválido: '${dst}'" >&2; exit 2 ;; esac
    case "${src}" in *..*|/*) echo "ERRO: overlay com fonte inválida: '${src}'" >&2; exit 2 ;; esac
    mkdir -p "$(dirname "${APPLY}/${dst}")"
    # do HEAD (git show), nunca do disco: o overlay é parte do que se publica e vem do mesmo commit
    git -C "${SRC}" show "HEAD:${src}" > "${APPLY}/${dst}" 2>/dev/null && [ -s "${APPLY}/${dst}" ] \
      || { echo "ERRO: overlay '${src}' ausente ou vazio no HEAD de ${SRC} — o mini não sai sem ele" >&2; exit 2; }
    n=$((n + 1))
  done <<< "${ov}"
  echo "overlays do mini aplicados: ${n}"
  exit 0
fi

[ -n "${BUNDLE}" ] && [ -d "${BUNDLE}" ] || { echo "ERRO: --bundle inexistente" >&2; exit 2; }
BUNDLE="$(cd "${BUNDLE}" && pwd)"
case "${FORMAT}" in text|tsv) : ;; *) echo "ERRO: --format text|tsv" >&2; exit 2 ;; esac

T="$(mktemp -d)"; trap 'rm -rf "${T}"' EXIT
# O que existe no core (só citação de algo real é ponteiro), lido do HEAD da fonte.
git -C "${SRC}" -c core.quotePath=false ls-tree -r --name-only HEAD -- .claude/commands .claude/agents docs > "${T}/core.txt" \
  || { echo "ERRO: não li a árvore do core" >&2; exit 2; }
_ka_rc=0; bash "${RESOLVER}" mini --known-absent > "${T}/known.tsv" 2>"${T}/known.err" || _ka_rc=$?
[ "${_ka_rc}" -eq 0 ] || { echo "ERRO: o resolvedor não devolveu o known_absent do mini: $(head -c 200 "${T}/known.err")" >&2; exit 2; }
: > "${T}/expected.txt"
# Os overlays escritos À MÃO para o mini (fonte em ops/door-templates/) são conteúdo PRÓPRIO dele: neles
# nenhuma ausência declarada vale (a tolerância é para arquivo COMPARTILHADO com o core). Os overlays que
# trazem um arquivo real do core (a SSOT do contrato de sessão) seguem a regra dos compartilhados.
ov_all="$(_overlays)" || exit 2
printf '%s\n' "${ov_all}" | awk -F'\t' '$2 ~ /^ops\/door-templates\// {print $1}' > "${T}/owned.txt"
if [ "${EXACT}" -eq 1 ]; then
  _m_rc=0
  _spec="$(bash "${SRC}/.claude/utils/adopt/vendor-manifest.sh" --role mini --repo "${SRC}" 2>/dev/null)" || _m_rc=$?
  [ "${_m_rc}" -eq 0 ] && [ -n "${_spec}" ] || { echo "ERRO: o manifesto do mini falhou (rc=${_m_rc}) — sem ele não há allowlist a conferir" >&2; exit 2; }
  mapfile -t _specs <<< "${_spec}"
  git -C "${SRC}" -c core.quotePath=false diff-tree -r --name-only --no-commit-id \
    4b825dc642cb6eb9a060e54bf8d69288fbee4904 HEAD -- "${_specs[@]}" > "${T}/expected.txt" \
    || { echo "ERRO: não contei o manifesto do mini" >&2; exit 2; }
  ov="$(_overlays)" || exit 2
  printf '%s\n' "${ov}" | cut -f1 >> "${T}/expected.txt"
  # o que o materializador escreve FORA do manifesto (o carimbo e a licença do código)
  printf '%s\n' .claude/.onion-version LICENSE >> "${T}/expected.txt"
fi

python3 - "${BUNDLE}" "${T}/core.txt" "${T}/known.tsv" "${T}/expected.txt" "${EXACT}" "${T}/owned.txt" > "${T}/out.tsv" <<'PY'
import os, re, sys
bundle, core_txt, known_tsv, expected_txt, exact = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5] == "1"
owned = set(l.strip() for l in open(sys.argv[6], encoding="utf-8") if l.strip())
core = set(l.strip() for l in open(core_txt, encoding="utf-8") if l.strip())
known = {}
for l in open(known_tsv, encoding="utf-8"):
    l = l.rstrip("\n")
    if l:
        k, _, why = l.partition("\t")
        known[k] = why
files = []
for d, dirs, fs in os.walk(bundle):
    dirs[:] = [x for x in dirs if x != ".git"]
    for f in fs:
        files.append(os.path.relpath(os.path.join(d, f), bundle))
fset = set(files)
out = []
# 1. allowlist exata
if exact:
    exp = set(l.strip() for l in open(expected_txt, encoding="utf-8") if l.strip())
    for f in sorted(fset - exp):
        out.append(("EXTRA", f, "fora da allowlist do mini"))
    for f in sorted(exp - fset):
        out.append(("MISSING", f, "a allowlist o nomeia e ele não foi montado"))
agents_core = {os.path.basename(p)[:-3]: p for p in core if p.startswith(".claude/agents/") and p.endswith(".md")}
agents_here = {os.path.basename(p)[:-3] for p in fset if p.startswith(".claude/agents/") and p.endswith(".md")}
SKIP = (".claude/sessions", ".claude/.onion-version", ".claude/projects", ".claude/settings")
seen = set()
def dangling(kind, cit, f):
    if f in owned:
        # arquivo PRÓPRIO do mini: nenhuma ausência vale, e a citação não conta como 'vista' (senão uma
        # linha do known_absent sobreviveria à sua última citação compartilhada só por estar aqui)
        out.append(("DANGLING", cit, f))
        return
    seen.add(cit)
    if cit not in known:
        out.append(("DANGLING", cit, f))
def path_ok(c):
    return c in fset or (c + ".md") in fset or any(x.startswith(c + "/") for x in fset)
re_path = re.compile(r"\.claude/[A-Za-z0-9_./-]+")
re_cmd = re.compile(r"(?<![A-Za-z0-9_.~/-])/([a-z]+):([a-z][a-z0-9-]*)(?::([a-z][a-z0-9-]*))?")
re_old = re.compile(r"(?<![A-Za-z0-9_.~/-])/([a-z]+)/([a-z][a-z0-9-]*)(?![A-Za-z0-9_/.-])")
re_frag = re.compile(r"(?<![A-Za-z0-9_./-])common[:/](prompts|templates)[:/]([a-z0-9][a-z0-9-]*)")
re_agent = re.compile(r"(?<![A-Za-z0-9_.])@([a-z][a-z0-9-]+)")
re_root = re.compile(r"(?<![A-Za-z0-9_.~/:@`-])/([a-z][a-z0-9-]+)(?![A-Za-z0-9_/:.@-])")
re_docs = re.compile(r"(?<![A-Za-z0-9_./-])docs/[A-Za-z0-9_./-]+\.(?:md|ya?ml|json|txt)")
re_link = re.compile(r"\]\(([^)\s]+)\)")
# home de QUALQUER conta, inclusive maiúscula, o /Users/ do macOS e o /root/ (passada adversarial da F5)
re_home = re.compile(r"/home/[^/\s`'\"<>]+/|/Users/[^/\s`'\"<>]+/|(?<![A-Za-z0-9_.-])/root/")
for f in sorted(files):
    p = os.path.join(bundle, f)
    try:
        t = open(p, encoding="utf-8", errors="replace").read()
    except OSError:
        continue
    for n, line in enumerate(t.splitlines(), 1):
        if re_home.search(line):
            out.append(("MACHINE", "%s:%d" % (f, n), re_home.search(line).group(0)))
    if not (f.endswith(".md") or f.endswith(".sh")):
        continue
    for c in sorted(set(re_path.findall(t))):
        c = c.rstrip(".,;:)").rstrip("/")
        if not c or c.startswith(SKIP) or c.count("/") < 2 or path_ok(c):
            continue
        dangling("path", c, f)
    for m in sorted(set(re_cmd.findall(t))):
        cat, cmd, sub = m
        rel = ".claude/commands/%s/%s%s.md" % (cat, cmd, ("/" + sub) if sub else "")
        cit = "/%s:%s%s" % (cat, cmd, (":" + sub) if sub else "")
        if rel in core and rel not in fset:
            dangling("cmd", cit, f)
    for cat, cmd in sorted(set(re_old.findall(t))):
        rel = ".claude/commands/%s/%s.md" % (cat, cmd)
        if rel in core and rel not in fset:
            dangling("cmd", "/%s/%s" % (cat, cmd), f)
    for kind, name in sorted(set(re_frag.findall(t))):
        rel = ".claude/commands/common/%s/%s.md" % (kind, name)
        if rel in core and rel not in fset:
            dangling("frag", "common:%s:%s" % (kind, name), f)
    for a in sorted(set(re_agent.findall(t))):
        if a in agents_core and a not in agents_here:
            dangling("agent", "@" + a, f)
    # comando de RAIZ (/onion, /warm-up): existe no core como .claude/commands/<nome>.md e falta no mini
    for n in sorted(set(re_root.findall(t))):
        rel = ".claude/commands/%s.md" % n
        if rel in core and rel not in fset:
            dangling("cmd", "/" + n, f)
    # documento citado por caminho do repo (docs/...): o mini só leva o que a allowlist nomeia
    for c in sorted(set(re_docs.findall(t))):
        if not path_ok(c):
            dangling("doc", c, f)
    # link markdown RELATIVO, resolvido contra o diretório do arquivo citante
    for tgt in sorted(set(re_link.findall(t))):
        if re.match(r"^(https?:|mailto:|#|/|<)", tgt):
            continue
        tgt = tgt.split("#", 1)[0].split("?", 1)[0]
        if not tgt or "{" in tgt or "$" in tgt:
            continue
        r = os.path.normpath(os.path.join(os.path.dirname(f), tgt))
        if r.startswith(".."):
            dangling("link", "fora-da-porta:" + tgt, f)
        elif not path_ok(r):
            dangling("link", r, f)
for k in sorted(known):
    if k not in seen:
        out.append(("STALE", k, "o known_absent declara e nenhum arquivo do mini cita mais — tire a linha"))
for row in out:
    print("\t".join(row))
PY
_py=$?
[ "${_py}" -eq 0 ] || { echo "ERRO: o verificador python falhou (rc=${_py})" >&2; exit 2; }

if [ "${FORMAT}" = "tsv" ]; then
  cat "${T}/out.tsv"
else
  _n_files="$(find "${BUNDLE}" -path "${BUNDLE}/.git" -prune -o -type f -print | grep -c . || true)"
  if [ ! -s "${T}/out.tsv" ]; then
    printf 'door-mini-check: %s arquivo(s) · %s · sem ponteiro morto · sem caminho de máquina · %s ausência(s) declarada(s)\n' \
      "${_n_files}" "$([ "${EXACT}" -eq 1 ] && echo 'allowlist exata' || echo 'allowlist não conferida (--no-exact)')" \
      "$(grep -c . "${T}/known.tsv" || true)"
  else
    awk -F'\t' '
      $1=="EXTRA"    { printf "  ✗ arquivo a MAIS: %s (%s)\n", $2, $3 }
      $1=="MISSING"  { printf "  ✗ arquivo a MENOS: %s (%s)\n", $2, $3 }
      $1=="DANGLING" { printf "  ✗ ponteiro morto: %s (citado por %s)\n", $2, $3 }
      $1=="STALE"    { printf "  ✗ ausência declarada que ninguém cita: %s (%s)\n", $2, $3 }
      $1=="MACHINE"  { printf "  ✗ caminho de máquina: %s (%s)\n", $2, $3 }' "${T}/out.tsv"
  fi
fi
[ -s "${T}/out.tsv" ] && exit 1
exit 0
