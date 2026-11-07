#!/usr/bin/env bash
# =============================================================================
# private-name-check.sh — REGRA 119: o diff não acrescenta nome de repo ou de clone de adotante NÃO federado.
#
# POR QUE EXISTE (defeito datado). Em 2026-11-04 um selo no grafo da orquestração de sessões citou o nome
# do repo de um adotante de consultoria, e esse nome leva o do cliente. O core é PÚBLICO. A REGRA 106
# (Superfície que viaja passa pela varredura de vazamento da publicação) e a REGRA 36 (Superfície
# VENDORIZADA sem nome comercial de cliente) não pegaram: as duas procuram termos DECLARADOS, e o termo
# não estava na lista de termos de clientes. Guarda por lista falha pelo vocabulário. O PR #1522 tirou o
# nome da árvore; o histórico ficou (decisão (a) do maestro, 2026-11-07). Esta guarda é a decisão (b):
# os nomes proibidos são DERIVADOS da máquina, sem lista à mão.
#
# A DERIVAÇÃO (na máquina do core, em tempo de execução, nada gravado):
#   candidatos = basename de cada diretório IRMÃO do checkout principal do core que é clone git com
#                carimbo do Onion (`.claude/.onion-version`), mais o basename da origin dele;
#              + basename de cada caminho do mapa local de membros (member-paths.tsv), mais a origin dele;
#   federados  = os ids, os basenames de `remote` e de `local_path` do members.yaml (que já é público);
#   proibidos  = (candidatos − federados, com 4 caracteres ou mais) ∪ os termos da fonte privada de
#                clientes (a mesma do projection-safety.sh: ONION_CLIENT_TERMS_FILE ou o default da fonte).
# NO CI a máquina não existe (nenhum irmão carimbado, nenhum mapa): a guarda cai para a lista de termos
# do segredo e DIZ isso (modo SO-LISTA). Sem lista também, declara NAO-VERIFICADO (nunca verde mudo).
#
# O QUE ELA JULGA: as linhas ACRESCENTADAS no diff da árvore de trabalho contra a base (merge-base com
# origin/main, em cascata) e o caminho dos arquivos acrescentados. O passado não é objeto: o histórico
# foi aceito, e a árvore da main ainda carrega ocorrências antigas que só um PR de limpeza tira.
# Casamento: sem caixa, o termo cercado por não-alfanumérico; a ocorrência DENTRO de um token federado
# (ex.: o termo como pedaço de um id do members.yaml) não conta, porque o token inteiro já é público.
#
# O QUE ELA NUNCA FAZ: imprimir o termo. A saída é `arquivo:linha` e um hash curto (8 hex do sha256 do
# termo em minúsculas); caminho que contém o termo sai com o termo trocado por `<hash>`. O termo não
# passa por argv (os termos da lista chegam ao juiz por um arquivo temporário 0600).
#
# Uso : bash private-name-check.sh [<raiz>] [--tsv] [--base <ref>] [--staged]
#       bash private-name-check.sh --hashes          # os hashes do conjunto derivado (depuração sem vazar)
#       bash private-name-check.sh --selftest
# Env : ONION_SIBLINGS_DIR (default: o pai do checkout principal) · ONION_MEMBER_PATHS_FILE · ONION_MEMBERS_FILE
#       ONION_CLIENT_TERMS_FILE (pelo projection-safety.sh)
# Exit: 0 limpo (ou só declaração) · 1 achado · 2 não pôde julgar (NAO VERIFICADO; nunca é verde).
# --tsv: `SEV<TAB>CODIGO<TAB>arquivo<TAB>mensagem`, uma linha por achado ou declaração.
#
# TETO (o que ela não vê): mensagem de commit e corpo de PR (não estão no diff da árvore); nome que não é
#   de diretório irmão nem do mapa (clone fora do pai do core, repo só remoto); abreviação, tradução ou
#   grafia trocada do nome; termo com menos de 4 caracteres derivado da máquina; quem registra o nome
#   real como id no members.yaml o federa (o ato fica no diff, e a REGRA 36 julga o registro); termo da
#   lista que é nome federado não conta aqui (a REGRA 36 o cobra no que viaja); o hash de
#   um nome curto e adivinhável é confirmável por quem adivinha: ele correlaciona, não esconde.
# =============================================================================
set -uo pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT=""; MODE="human"; BASE_REF=""; STAGED=0
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) MODE="tsv"; shift ;;
    --hashes) MODE="hashes"; shift ;;
    --selftest) MODE="selftest"; shift ;;
    --base) BASE_REF="${2:?--base exige ref}"; shift 2 ;;
    --staged) STAGED=1; shift ;;
    -*) echo "ERRO: flag desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] || { echo "ERRO: raiz duplicada '$1'" >&2; exit 2; }; ROOT="$1"; shift ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "private-name: python3 ausente — NAO VERIFICADO" >&2; exit 2; }
command -v git >/dev/null 2>&1 || { echo "private-name: git ausente — NAO VERIFICADO" >&2; exit 2; }

# ── o JUIZ (python): deriva, casa e imprime. Lê os termos declarados de um arquivo temporário. ─────────────────────────
# argv: <raiz> <siblings_dir> <map_file> <members> <diff_file> <modo> <ct_rc> <arquivo dos termos declarados>
_judge() {
  python3 -I -B - "$@" <<'PY'
import hashlib, os, re, subprocess, sys
root, sib_dir, map_file, members, diff_file, mode, ct_rc, ct_file = sys.argv[1:9]
# os termos vêm de um ARQUIVO temporário 0600 (o stdin é o próprio script): nunca por argv
declared = [l.strip() for l in open(ct_file, encoding="utf-8", errors="replace").read().splitlines() if l.strip()]

def h8(t): return hashlib.sha256(t.lower().encode()).hexdigest()[:8]
def base(v):
    v = (v or "").strip().strip('"').strip("'").rstrip("/")
    if not v or v.lower() in ("n/a", ".") or " " in v or v.startswith("("): return ""
    b = re.split(r"[/:]", v)[-1]
    return b[:-4] if b.endswith(".git") else b
def origin(d):
    try:
        r = subprocess.run(["git", "-C", d, "config", "--get", "remote.origin.url"], capture_output=True, text=True, timeout=10)
        return base(r.stdout.strip())
    except Exception: return ""

# federados: o que o registro público já nomeia
fed = set()
try:
    import yaml
    doc = yaml.safe_load(open(members, encoding="utf-8")) or {}
    for m in doc.get("members") or []:
        if isinstance(m, dict):
            for k in ("id", "remote", "local_path"):
                b = base(str(m.get(k) or "")) if k != "id" else str(m.get("id") or "").strip()
                if b: fed.add(b.lower())
except FileNotFoundError:
    pass
except Exception as e:
    print(f"private-name: members.yaml ilegível ({type(e).__name__}) — NAO VERIFICADO", file=sys.stderr); sys.exit(2)
fed.add(os.path.basename(os.path.realpath(root)).lower())

# candidatos da máquina
cands, machine = set(), False
if sib_dir and os.path.isdir(sib_dir):
    for n in sorted(os.listdir(sib_dir)):
        d = os.path.join(sib_dir, n)
        if os.path.isfile(os.path.join(d, ".claude", ".onion-version")) and os.path.exists(os.path.join(d, ".git")):
            machine = True
            cands.update(x for x in (n, origin(d)) if x)
if map_file and os.path.isfile(map_file):
    for line in open(map_file, encoding="utf-8", errors="replace"):
        if not line.strip() or line.lstrip().startswith("#"): continue
        parts = line.rstrip("\r\n").split("\t")
        if len(parts) >= 2 and parts[1].strip():
            machine = True
            p = os.path.expanduser(parts[1].strip())
            cands.update(x for x in (base(p), origin(p) if os.path.isdir(p) else "") if x)
derived = {c for c in cands if c.lower() not in fed and len(c) >= 4}
# um termo da lista que É nome federado não conta aqui: o registro público já o nomeia (a REGRA 36 segue
# cobrando-o nas superfícies que viajam). Sem isto, toda menção nova a um membro registrado reprovaria.
# A comparação com o federado é pela forma NORMALIZADA (só letras e dígitos): a variante de grafia de um
# membro registrado (com ponto, hífen ou espaço) é o mesmo nome público, e a lista a carrega para a REGRA 36.
def norm(t): return re.sub(r"[^a-z0-9]", "", t.lower())
fed_norm = {norm(f) for f in fed}
derived_l = {t.lower() for t in derived}
declared_l = {t.lower() for t in declared if norm(t) not in fed_norm}
terms = derived_l | declared_l

if mode == "hashes":
    print(f"modo={'MAQUINA' if machine else 'SO-LISTA'} derivados={len(derived)} declarados={len(declared)} federados={len(fed)}")
    for t in sorted(terms, key=h8): print(h8(t))
    sys.exit(0)

out = []
def emit(sev, code, path, msg):
    out.append((sev, code, path, msg))
if machine and ct_rc not in ("0", "4"):
    emit("SOFT", "SEM-LISTA", "docs/evolution/federation/members.yaml",
         "a lista de termos de clientes está AUSENTE: a guarda julgou só pelos nomes derivados da máquina")
if not machine:
    if ct_rc == "0":
        emit("SOFT", "SO-LISTA", "docs/evolution/federation/members.yaml",
             "a derivação da máquina não existe aqui (nenhum clone irmão carimbado, nenhum mapa de membros): a guarda julgou só pela lista de termos do segredo")
    else:
        emit("SOFT", "NAO-VERIFICADO", "docs/evolution/federation/members.yaml",
             "nem a derivação da máquina nem a lista de termos estão disponíveis: o diff NÃO foi varrido por nome privado")

if terms:
    # Duas fronteiras, medidas na história da main (2026-08 a 2026-11): o nome DERIVADO não casa quando vem
    # depois de hífen ou sublinhado (`hero-<nome>` numa classe CSS, `adopt-poc-<nome>` numa sessão: pedaço de
    # outro identificador), mas casa seguido de hífen (`<nome>-wt`, `<nome>-notas.md`, que ainda nomeiam o
    # clone). O termo DECLARADO casa cercado só por não-alfanumérico, como na REGRA 36.
    def alt(ts): return "|".join(re.escape(t) for t in sorted(ts, key=len, reverse=True))
    rxs = []
    if derived_l: rxs.append(re.compile(r"(?<![A-Za-z0-9_-])(" + alt(derived_l) + r")(?![A-Za-z0-9])", re.I))
    if declared_l: rxs.append(re.compile(r"(?<![A-Za-z0-9])(" + alt(declared_l) + r")(?![A-Za-z0-9])", re.I))
    tok = re.compile(r"[A-Za-z0-9_-]")
    def finditer(s):
        for rx in rxs: yield from rx.finditer(s)
    def hits(s):
        for m in finditer(s):
            a, b = m.start(), m.end()
            while a > 0 and tok.match(s[a-1]): a -= 1
            while b < len(s) and tok.match(s[b]): b += 1
            if s[a:b].lower() in fed: continue   # o token inteiro é federado: já é público pelo registro
            yield m.group(1)
    def redact(p):
        for rx in rxs: p = rx.sub(lambda m: "<" + h8(m.group(1)) + ">", p)
        return p
    cur, ln, seen = None, 0, set()
    for raw in open(diff_file, encoding="utf-8", errors="replace"):
        line = raw.rstrip("\n")
        if line.startswith("+++ "):
            cur = line[6:] if line.startswith("+++ b/") else None
            if cur:
                for t in hits(cur):
                    k = (cur, 0, t.lower())
                    if k not in seen:
                        seen.add(k); emit("HARD", "NOME-PRIVADO", redact(cur), f"o CAMINHO do arquivo acrescenta um nome privado (hash {h8(t)})")
            continue
        if line.startswith("@@"):
            m = re.match(r"@@ -\S+ \+(\d+)", line); ln = int(m.group(1)) if m else 0; continue
        if cur is None or line.startswith("---"): continue
        if line.startswith("+"):
            for t in hits(line[1:]):
                k = (cur, ln, t.lower())
                if k not in seen:
                    seen.add(k); emit("HARD", "NOME-PRIVADO", redact(cur), f"linha {ln} acrescenta um nome privado (hash {h8(t)})")
            ln += 1
        elif line.startswith(" "):
            ln += 1

for sev, code, path, msg in out:
    if mode == "tsv": print(f"{sev}\t{code}\t{path}\t{msg}")
    else: print(f"  {'✗' if sev == 'HARD' else '⚠'} [{code}] {path}: {msg}")
if mode != "tsv":
    n = sum(1 for o in out if o[0] == "HARD")
    print(f"private-name: modo {'MAQUINA' if machine else 'SO-LISTA'} · {len(terms)} termo(s) proibido(s) · {n} achado(s)")
sys.exit(1 if any(o[0] == "HARD" for o in out) else 0)
PY
}

# ── resolve a raiz, a base, o diff e as fontes, e chama o juiz ──────────────────────────────────────────
_run() {
  local root="$1" tmp rc=0
  root="$(cd "${root}" 2>/dev/null && pwd)" || { echo "private-name: raiz ilegível — NAO VERIFICADO" >&2; return 2; }
  git -C "${root}" rev-parse --git-dir >/dev/null 2>&1 || { echo "private-name: ${root} não é repo git — NAO VERIFICADO" >&2; return 2; }
  # o pai do CHECKOUT PRINCIPAL (numa worktree, o pai dela não é onde os clones moram)
  local gcd main sib
  gcd="$(git -C "${root}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
  main="${gcd%/.git}"; [ "${main}" != "${gcd}" ] || main="${root}"
  sib="${ONION_SIBLINGS_DIR:-$(dirname "${main}")}"
  local mapf="${ONION_MEMBER_PATHS_FILE:-${HOME:-/nonexistent}/.config/onion/member-paths.tsv}"
  local members="${ONION_MEMBERS_FILE:-${root}/docs/evolution/federation/members.yaml}"
  tmp="$(umask 077; mktemp -d)" || return 2
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp}'" RETURN
  # a base em cascata (o molde da REGRA 63); sem base, NÃO pode julgar
  local base="" ref
  if [ -n "${BASE_REF}" ]; then base="$(git -C "${root}" merge-base "${BASE_REF}" HEAD 2>/dev/null || true)"
  else
    for ref in origin/main main origin/master; do
      base="$(git -C "${root}" merge-base "${ref}" HEAD 2>/dev/null || true)"; [ -n "${base}" ] && break
    done
  fi
  if [ "${MODE}" != "hashes" ]; then
    if [ "${STAGED}" -eq 1 ]; then
      git -C "${root}" diff --cached --no-color --no-ext-diff -U0 > "${tmp}/diff" 2>"${tmp}/err" || { echo "private-name: git diff --cached falhou: $(head -1 "${tmp}/err") — NAO VERIFICADO" >&2; return 2; }
    else
      [ -n "${base}" ] || { echo "private-name: nenhuma base resolvível (origin/main, main, origin/master) — NAO VERIFICADO" >&2; return 2; }
      git -C "${root}" diff "${base}" --no-color --no-ext-diff -U0 > "${tmp}/diff" 2>"${tmp}/err" || { echo "private-name: git diff falhou: $(head -1 "${tmp}/err") — NAO VERIFICADO" >&2; return 2; }
    fi
  else : > "${tmp}/diff"; fi
  # os termos declarados, pela P8 do projection-safety.sh (um leitor só da fonte privada)
  local ct_rc=0
  ( cd "${root}" && bash "${_HERE}/projection-safety.sh" --emit-declared ) > "${tmp}/ct" 2>/dev/null || ct_rc=$?
  [ "${ct_rc}" -eq 0 ] || : > "${tmp}/ct"
  _judge "${root}" "${sib}" "${mapf}" "${members}" "${tmp}/diff" "${MODE}" "${ct_rc}" "${tmp}/ct" || rc=$?
  return "${rc}"
}

# ── SELFTEST: as polaridades, com nomes INVENTADOS. Nenhum nome real entra aqui. ────────────────────────
_selftest() {
  local t ok=0 bad=0 out rc
  t="$(mktemp -d)" || return 2
  # shellcheck disable=SC2064
  trap "rm -rf '${t}'" RETURN
  _mkclone() { mkdir -p "$1/.claude" && git -C "$1" init -q >/dev/null 2>&1 && printf 'role: adopted\n' > "$1/.claude/.onion-version"
               [ -z "${2:-}" ] || git -C "$1" remote add origin "$2"; }
  mkdir -p "${t}/maq"
  _mkclone "${t}/maq/cliente-ficticio-alfa" "git@forja.invalid:dono/repo-ficticio-beta.git"
  _mkclone "${t}/maq/membro-publico"
  _mkclone "${t}/fora/clone-do-mapa"
  mkdir -p "${t}/maq/sem-carimbo-gama" && git -C "${t}/maq/sem-carimbo-gama" init -q >/dev/null 2>&1
  printf 'membro-x\t%s\n' "${t}/fora/clone-do-mapa" > "${t}/map.tsv"
  printf 'termo-declarado-delta\nMembro.Publico\n' > "${t}/ct.txt"
  local core="${t}/maq/core"
  mkdir -p "${core}/docs/evolution/federation" && git -C "${core}" init -q -b main >/dev/null 2>&1
  printf 'members:\n  - id: membro-publico\n  - id: poc-cliente-ficticio-alfa\n    remote: github.com/dono/membro-publico\n    local_path: n/a\n' > "${core}/docs/evolution/federation/members.yaml"
  printf 'base\n' > "${core}/a.md"
  git -C "${core}" add -A && git -C "${core}" -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1
  git -C "${core}" update-ref refs/remotes/origin/main HEAD
  _case() {  # <nome> <conteúdo> <esperado: HARD|LIMPO> [<arquivo>]
    local name="$1" body="$2" want="$3" f="${4:-a.md}"
    git -C "${core}" reset -q --hard HEAD >/dev/null 2>&1; git -C "${core}" clean -qfd >/dev/null 2>&1
    mkdir -p "$(dirname "${core}/${f}")"; printf 'base\n%s\n' "${body}" > "${core}/${f}"; git -C "${core}" add -A >/dev/null 2>&1
    out="$(ONION_SIBLINGS_DIR="${t}/maq" ONION_MEMBER_PATHS_FILE="${t}/map.tsv" ONION_CLIENT_TERMS_FILE="${t}/ct.txt" \
           bash "${BASH_SOURCE[0]}" "${core}" --tsv 2>&1)"; rc=$?
    local got="LIMPO"; grep -q $'^HARD\tNOME-PRIVADO' <<< "${out}" && got="HARD"
    if [ "${got}" = "${want}" ]; then ok=$((ok+1)); echo "  ✅ ${name}"; else bad=$((bad+1)); echo "  ✗ ${name} — esperava ${want}, veio ${got} (rc=${rc}): $(printf '%s' "${out}" | head -2 | tr '\n' ' ')"; fi
  }
  # ── acusa ──
  _case "acusa: nome do diretório irmão carimbado (derivado, não listado)" "o clone cliente-ficticio-alfa tem o caso" HARD
  _case "acusa: nome da origin do irmão carimbado" "veja repo-ficticio-beta no forge" HARD
  _case "acusa: nome do clone do mapa de membros" "entregue em clone-do-mapa" HARD
  _case "acusa: termo da lista declarada" "o termo-declarado-delta apareceu" HARD
  _case "acusa: sem caixa, dentro de caminho" "cd ../CLIENTE-FICTICIO-ALFA/docs" HARD
  _case "acusa: nome no CAMINHO do arquivo acrescentado" "nada" HARD "docs/cliente-ficticio-alfa-notas.md"
  # ── cala ──
  _case "cala: nome federado (id do members.yaml)" "o membro-publico recebeu" LIMPO
  _case "cala: termo dentro de token federado inteiro" "o poc-cliente-ficticio-alfa é público" LIMPO
  _case "cala: diretório irmão SEM carimbo não é candidato" "o sem-carimbo-gama fica" LIMPO
  _case "cala: pedaço de palavra não casa" "xcliente-ficticio-alfax" LIMPO
  _case "cala: linha sem nome nenhum" "texto comum" LIMPO
  _case "cala: derivado depois de hífen é pedaço de outro identificador" ".hero-cliente-ficticio-alfa { top:0 }" LIMPO
  _case "acusa: derivado seguido de hífen ainda nomeia o clone" "o cliente-ficticio-alfa-wt ficou" HARD
  _case "cala: variante de grafia de um membro federado na lista" "o Membro.Publico entrou" LIMPO
  # ── nunca imprime o termo ──
  _case "acusa (para o caso de vazamento)" "cliente-ficticio-alfa e termo-declarado-delta" HARD "docs/cliente-ficticio-alfa.md"
  if grep -qiE 'cliente-ficticio-alfa|termo-declarado-delta' <<< "${out}"; then
    bad=$((bad+1)); echo "  ✗ a saída IMPRIMIU um termo em texto claro"
  elif grep -qE 'hash [0-9a-f]{8}' <<< "${out}" && grep -qE '<[0-9a-f]{8}>' <<< "${out}"; then
    ok=$((ok+1)); echo "  ✅ a saída traz arquivo:linha e hash, e o caminho sai com o termo trocado por <hash>"
  else bad=$((bad+1)); echo "  ✗ a saída não trouxe o hash: $(printf '%s' "${out}" | head -1)"; fi
  # ── CI: sem máquina, cai para a lista e diz ──
  git -C "${core}" reset -q --hard HEAD >/dev/null 2>&1; git -C "${core}" clean -qfd >/dev/null 2>&1; printf 'base\no termo-declarado-delta e cliente-ficticio-alfa\n' > "${core}/a.md"
  out="$(ONION_SIBLINGS_DIR="${t}/vazio-inexistente" ONION_MEMBER_PATHS_FILE="${t}/ausente.tsv" ONION_CLIENT_TERMS_FILE="${t}/ct.txt" bash "${BASH_SOURCE[0]}" "${core}" --tsv 2>&1)"
  if grep -q $'^SOFT\tSO-LISTA' <<< "${out}" && [ "$(grep -c $'^HARD\tNOME-PRIVADO' <<< "${out}")" = 1 ]; then
    ok=$((ok+1)); echo "  ✅ sem máquina (CI): declara SO-LISTA e acusa só o termo da lista"
  else bad=$((bad+1)); echo "  ✗ modo CI — veio: $(printf '%s' "${out}" | tr '\n' ' ' | cut -c1-160)"; fi
  out="$(ONION_SIBLINGS_DIR="${t}/vazio-inexistente" ONION_MEMBER_PATHS_FILE="${t}/ausente.tsv" ONION_CLIENT_TERMS_FILE="${t}/ct-ausente.txt" bash "${BASH_SOURCE[0]}" "${core}" --tsv 2>&1)"
  if grep -q $'^SOFT\tNAO-VERIFICADO' <<< "${out}"; then ok=$((ok+1)); echo "  ✅ sem máquina e sem lista: declara NAO-VERIFICADO"
  else bad=$((bad+1)); echo "  ✗ sem nada — veio: $(printf '%s' "${out}" | tr '\n' ' ' | cut -c1-160)"; fi
  echo "private-name selftest: ${ok} ok · ${bad} falha(s)"
  [ "${bad}" -eq 0 ]
}

case "${MODE}" in
  selftest) _selftest; exit $? ;;
  *) _run "${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"; exit $? ;;
esac
