#!/usr/bin/env bash
# =============================================================================
# act-signature-check.sh — REGRA 117: ato de deploy tem assinatura no veto
#
# O QUE   : o veto do MOAT (pretooluse-moat-gate.sh) barra o ATO de deploy e de publicação pelas linhas
#           `ato script <ops/x.sh> <assinatura>` do ops/moat-targets.tsv (core-only). Esta guarda impede que a
#           LISTA envelheça calada, que é como guarda por lista morre (cláusula 3 da guard-doctrine):
#             · wrapper-sem-ato          — um wrapper que alguma linha de deploy/relógio nomeia (4ª coluna) e que
#                                          não tem linha `ato`: o wrapper novo nasceria fora do veto;
#             · ato-sem-script           — a linha `ato` aponta um script que não existe;
#             · assinatura-vazia         — a linha `ato` sem assinatura (o veto não teria o que julgar);
#             · assinatura-fora-do-codigo — uma palavra da assinatura (`--apply`, `apply`, `--push`…) que não
#                                          aparece no CÓDIGO do script: erro de digitação, ou a gramática do
#                                          script mudou, e o veto passaria a calar sem ninguém ver.
#
# DEFEITO DATADO (2026-11-05, estudo problem-route, CERCA.md, confirmado executando o hook): com o wrapper
#           versionado sendo fronteira para tudo, `bash ops/<wrapper>.sh --apply` e `ops/publish-door.sh --push` (core-only)
#           passavam o veto com exit 0, e a sessão rodou deploys assim (corpus: update-bridge.sh em 2026-10-23,
#           docker-engine-migrate.sh apply e install-caddy-config.sh em 2026-10-22, stt-service.sh install
#           --apply em 2026-10-19). O veto do ato nasceu com a lista; esta guarda é a catraca dela.
#
# O QUE NÃO VÊ (teto): não sabe se a assinatura está CERTA, só que ela existe no código. Um modo novo que faz o
#           ato sem nenhuma das palavras (um `--force` que também aplica) passa. Script de deploy que nenhuma
#           linha de deploy nomeia como wrapper (caso do caddy-site-secrets.sh) só entra se alguém escrever a
#           linha `ato` dele. `@none` e `@any` não se conferem no código.
#
# Uso: act-signature-check.sh <raiz> [--format tsv]   |   act-signature-check.sh --selftest
#      tsv: SEVERIDADE \t CÓDIGO \t caminho:linha \t mensagem. rc 0 = julgou (com ou sem achado); 2 = não pôde.
# =============================================================================
set -uo pipefail
export LC_ALL=C

_judge() {  # $1 = raiz
  python3 -I -B - "$1" <<'PY'
import os, re, sys
root = sys.argv[1]
tsv = os.path.join(root, "ops/moat-targets.tsv")  # (core-only)
if not os.path.isfile(tsv):
    sys.exit(0)                                  # adotante: sem o tsv não há veto do ato, nem o que conferir
try:
    lines = open(tsv, encoding="utf-8").read().split("\n")
except OSError as e:
    sys.stderr.write("act-signature-check: tsv ilegível: %s\n" % e); sys.exit(2)
wrappers, acts = {}, {}
for n, ln in enumerate(lines, 1):
    if not ln.strip() or ln.lstrip().startswith("#"):
        continue
    f = ln.split("\t")
    if len(f) < 3:
        continue
    cls, kind, pat = f[0].strip(), f[1].strip(), f[2].strip()
    col4 = f[3].strip() if len(f) > 3 else ""
    if kind == "script":
        if cls == "ato":
            acts[os.path.normpath(pat)] = (n, col4)
        continue
    if cls in ("deploy", "relogio") and col4 not in ("", "-"):
        wrappers.setdefault(os.path.normpath(col4), n)
out = []
def say(code, line, msg):
    out.append("HARD\t%s\tops/moat-targets.tsv:%d\t%s" % (code, line, msg))  # (core-only)
for w, n in sorted(wrappers.items(), key=lambda x: x[1]):
    if w not in acts:
        say("wrapper-sem-ato", n, "%s é wrapper de deploy e não tem linha `ato script %s <assinatura>`: o ato dele passaria pelo veto" % (w, w))
for s, (n, sig) in sorted(acts.items(), key=lambda x: x[1][0]):
    words = [x.strip() for x in sig.split(",") if x.strip()] if sig not in ("", "-") else []
    if not words:
        say("assinatura-vazia", n, "a linha `ato` de %s não tem assinatura (`--apply`, `apply`, `@none`, `@any`…)" % s)
        continue
    p = os.path.join(root, s)
    if not os.path.isfile(p):
        say("ato-sem-script", n, "%s não existe: a linha `ato` aponta um script que não está no projeto" % s)
        continue
    try:
        code = "\n".join(l for l in open(p, encoding="utf-8", errors="replace").read().split("\n")
                         if not l.lstrip().startswith("#"))
    except OSError as e:
        sys.stderr.write("act-signature-check: %s ilegível: %s\n" % (s, e)); sys.exit(2)
    for w in words:
        if w in ("@none", "@any"):
            continue
        if not re.search(r"(?<![\w-])" + re.escape(w) + r"(?![\w-])", code):
            say("assinatura-fora-do-codigo", n, "a palavra `%s` da assinatura de %s não aparece no código dele: o veto calaria nesse ato" % (w, s))
print("\n".join(out))
PY
}

_selftest() {
  local d pass=0 fail=0 o
  d="$(mktemp -d)"; trap 'rm -rf "${d}"' RETURN
  _mk() {  # $1 = nome; stdin = tsv
    mkdir -p "${d}/$1/ops"; cat > "${d}/$1/ops/moat-targets.tsv"  # (core-only)
    printf '#!/usr/bin/env bash\ncase "$1" in install) [ "${2:-}" = --apply ] && echo aplica ;; esac\n' > "${d}/$1/ops/w.sh"
  }
  _ck() {  # $1 = rótulo; $2 = raiz; $3 = código esperado ("" = nenhum achado)
    local r=0; o="$(_judge "$2" 2>&1)" || r=$?
    if [ "${r}" -eq 0 ] && { { [ -z "$3" ] && [ -z "${o}" ]; } || { [ -n "$3" ] && grep -qF "	$3	" <<< "${o}"; }; }; then
      pass=$((pass + 1)); echo "  ✓ $1"
    else fail=$((fail + 1)); echo "  ✗ $1 — veio: ${o:-<nada>}"; fi
  }
  printf 'deploy\tunit\tx\tops/w.sh\nato\tscript\tops/w.sh\t--apply\n' | _mk ok
  _ck "(i) wrapper com linha ato e assinatura no código cala" "${d}/ok" ""
  printf 'deploy\tunit\tx\tops/w.sh\n' | _mk sem
  _ck "(ii) wrapper sem linha ato acusa" "${d}/sem" "wrapper-sem-ato"
  printf 'deploy\tunit\tx\tops/w.sh\nato\tscript\tops/w.sh\t--aply\n' | _mk typo
  _ck "(iii) assinatura que o código não tem acusa (o erro de digitação)" "${d}/typo" "assinatura-fora-do-codigo"
  printf 'deploy\tunit\tx\tops/w.sh\nato\tscript\tops/w.sh\t--apply\nato\tscript\tops/sumiu.sh\t@any\n' | _mk falta
  _ck "(iv) linha ato de script inexistente acusa" "${d}/falta" "ato-sem-script"
  printf 'deploy\tunit\tx\tops/w.sh\nato\tscript\tops/w.sh\t-\n' | _mk vazia
  _ck "(v) linha ato sem assinatura acusa" "${d}/vazia" "assinatura-vazia"
  printf 'deploy\tunit\tx\t-\nato\tscript\tops/w.sh\t@none,install\n' | _mk semwrap
  _ck "(vi) @none e palavra do case (install) calam; linha de deploy sem wrapper não pede ato" "${d}/semwrap" ""
  printf '#!/usr/bin/env bash\n# --apply só no comentário\necho x\n' > "${d}/ok/ops/c.sh"
  printf 'ato\tscript\tops/c.sh\t--apply\n' >> "${d}/ok/ops/moat-targets.tsv"  # (core-only)
  _ck "(vii) palavra só em COMENTÁRIO não conta como código" "${d}/ok" "assinatura-fora-do-codigo"
  mkdir -p "${d}/adotante"
  _ck "(viii) sem ops/moat-targets.tsv (adotante) cala" "${d}/adotante" ""  # (core-only)
  echo "selftest: ${pass}/$((pass + fail)) verdes"
  [ "${fail}" -eq 0 ]
}

case "${1:-}" in
  --selftest) _selftest; exit $? ;;
  ""|-h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac
command -v python3 >/dev/null 2>&1 || { echo "act-signature-check: python3 ausente" >&2; exit 2; }
_judge "$1"
