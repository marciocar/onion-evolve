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
# DEFEITO DATADO (2026-11-05, estudo problem-route, docs/evolution/dissect/problem-route-2026-11/CERCA.md, confirmado executando o hook): com o wrapper
#           versionado sendo fronteira para tudo, `bash ops/<wrapper>.sh --apply` e `ops/publish-door.sh --push` (core-only)
#           passavam o veto com exit 0, e a sessão rodou deploys assim (corpus: update-bridge.sh em 2026-10-23,
#           docker-engine-migrate.sh apply e install-caddy-config.sh em 2026-10-22, stt-service.sh install
#           --apply em 2026-10-19). O veto do ato nasceu com a lista; esta guarda é a catraca dela.
#
# DELEGAÇÃO (2026-11-13, D_DELEGATE_*_1113): a linha `delega script <ops/x.sh> <marcador> <palavras>` libera um ato  (core-only)
#           à sessão numa forma exata. A catraca dela:
#             · delega-sem-ato           — a delegação aponta um script sem linha `ato` (delegar o que não é vetado);
#             · delega-fora-da-assinatura — uma palavra coberta que a assinatura do ato não tem (a delegação cobriria
#                                          o que o veto nem julga, e o leitor acharia que ela libera mais do que libera);
#             · marcador-fora-do-codigo  — a flag-marcador (`--foreign-repo`, `--verified-pr`) não aparece no código: o
#                                          script não conferiria as condições do selo, e o veto deixaria passar;
#             · delega-porta             — linha `delega` para ops/publish-door.sh (D_DOOR_PUBLISH_STAYS_WITH_MAESTRO_1113).  (core-only)
#           `@foreign` (merge com --repo de outro repositório) é palavra de assinatura que não se confere no código.
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
wrappers, acts, delegs, fecho = {}, {}, [], {}
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
        elif cls == "delega":
            delegs.append((n, os.path.normpath(pat), col4, f[4].strip() if len(f) > 4 else ""))
        elif cls == "fecho":
            fecho[os.path.normpath(pat)] = n
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
        if w in ("@none", "@any", "@foreign"):
            continue
        if not re.search(r"(?<![\w-])" + re.escape(w) + r"(?![\w-])", code):
            say("assinatura-fora-do-codigo", n, "a palavra `%s` da assinatura de %s não aparece no código dele: o veto calaria nesse ato" % (w, s))
for n, s, marker, verbs in delegs:
    if os.path.basename(s) == "publish-door.sh":
        say("delega-porta", n, "a publicação das portas segue com o maestro (D_DOOR_PUBLISH_STAYS_WITH_MAESTRO_1113): %s não se delega" % s)
        continue
    if s not in acts:
        say("delega-sem-ato", n, "a delegação aponta %s, que não tem linha `ato`: não há veto a delegar" % s)
        continue
    sig = set(x.strip() for x in acts[s][1].split(",") if x.strip())
    extra = sorted(set(x.strip() for x in verbs.split(",") if x.strip()) - sig)
    if extra or not verbs.strip():
        say("delega-fora-da-assinatura", n, "a delegação de %s cobre %s, fora da assinatura do ato (%s)" % (s, ", ".join(extra) or "nada", ", ".join(sorted(sig))))
    if marker.startswith("@rootcopy="):
        continue
    p = os.path.join(root, s)
    try:
        code = "\n".join(l for l in open(p, encoding="utf-8", errors="replace").read().split("\n")
                         if l.strip()[:1] != "#")      # o marcador em comentário não conta
    except OSError:
        continue
    if not marker or not re.search(r"(?<![\w-])" + re.escape(marker) + r"(?![\w-])", code):
        say("marcador-fora-do-codigo", n, "o marcador `%s` da delegação de %s não aparece no código dele: o script não conferiria as condições do selo" % (marker, s))
# O FECHO (7ª passada do refutador do #1647): o que os atos EXECUTAM também é guarda. Para cada script de ato, delega e
# fecho, as referências de EXECUÇÃO a um script deste repo (`bash x.sh`, `source`, `.`, `python3 x.py`, `"${WT}/ops/x.sh"`
# em posição de comando, `$(…x.sh…)`) têm de estar numa linha ato/delega/fecho. Os dois executores do gate (lint-artifacts
# e lint-selftest) são FRONTEIRA: estão no fecho, mas o que eles rodam (o resto de .claude/validation) não se desce — o
# fecho inteiro dá ~130 arquivos e tornaria quase todo PR do core um merge do maestro (declarado no resíduo).
FRONTEIRA = {".claude/validation/lint-artifacts.sh", ".claude/validation/lint-selftest.sh"}
EXEC = re.compile(r"""(?:^|[;&|(`{]|\$\(|\b(?:bash|sh|source|exec|python3?|timeout\s+\S+)\s+(?:-[\w-]+\s+)*)\s*["']?(?:\$\{?[A-Za-z_]\w*\}?/+|\./|"\$\{?[A-Za-z_]\w*\}?"/+)?((?:ops|\.claude)/[\w./-]+\.(?:sh|py))""", re.M)
known = set(acts) | set(fecho) | set(d[1] for d in delegs)
for s, n in sorted(fecho.items(), key=lambda x: x[1]):
    if not os.path.isfile(os.path.join(root, s)):
        say("fecho-sem-script", n, "a linha fecho aponta %s, que não existe" % s)
for s in sorted(known - FRONTEIRA):
    p = os.path.join(root, s)
    try:
        code = "\n".join(l for l in open(p, encoding="utf-8", errors="replace").read().split("\n") if not l.lstrip().startswith("#"))
    except OSError:
        continue
    for m in EXEC.finditer(code):
        r = os.path.normpath(m.group(1))
        if r not in known and os.path.isfile(os.path.join(root, r)):
            say("fecho-incompleto", fecho.get(s, acts.get(s, (0,))[0] if s in acts else 0),
                "%s executa %s, que não está numa linha ato/delega/fecho do tsv: um PR que o mude não seria guarda" % (s, r))
            known.add(r)                         # uma vez por alvo
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
  # a DELEGAÇÃO (2026-11-13): a forma certa cala; cada desvio acusa
  printf '#!/usr/bin/env bash\ncase "$1" in install) [ "${2:-}" = --apply ] && [ "${3:-}" = --delegado ] && echo aplica ;; esac\n' > "${d}/ok/ops/w.sh"
  printf 'delega\tscript\tops/w.sh\t--delegado\t--apply\n' >> "${d}/ok/ops/moat-targets.tsv"  # (core-only)
  sed -i '/ops\/c.sh/d' "${d}/ok/ops/moat-targets.tsv"  # (core-only)
  _ck "(ix) delegação com marcador no código e palavras da assinatura cala" "${d}/ok" ""
  printf 'deploy\tunit\tx\tops/w.sh\nato\tscript\tops/w.sh\t--apply\ndelega\tscript\tops/w.sh\t--sumido\t--apply\n' | _mk mk
  _ck "(x) marcador que o código não tem acusa" "${d}/mk" "marcador-fora-do-codigo"
  printf 'deploy\tunit\tx\tops/w.sh\nato\tscript\tops/w.sh\t--apply\ndelega\tscript\tops/w.sh\t@rootcopy=/x\t--apply,creds\n' | _mk fora
  _ck "(xi) delegação que cobre palavra fora da assinatura acusa" "${d}/fora" "delega-fora-da-assinatura"
  printf 'deploy\tunit\tx\tops/w.sh\nato\tscript\tops/w.sh\t--apply\ndelega\tscript\tops/outro.sh\t@rootcopy=/x\t--apply\n' | _mk semato
  _ck "(xii) delegação de script sem linha ato acusa" "${d}/semato" "delega-sem-ato"
  printf 'ato\tscript\tops/publish-door.sh\t--push\ndelega\tscript\tops/publish-door.sh\t--x\t--push\n' | _mk porta  # (core-only)
  printf '#!/usr/bin/env bash\n[ "$1" = --push ] && echo push\n' > "${d}/porta/ops/publish-door.sh"  # (core-only)
  _ck "(xiii) delegação do push de porta acusa (fica com o maestro)" "${d}/porta" "delega-porta"
  # o FECHO (7ª passada): o ato que executa outro script do repo pede a linha fecho dele; a linha fecho sem arquivo acusa
  printf 'deploy\tunit\tx\tops/w.sh\nato\tscript\tops/w.sh\t--apply\n' | _mk fx
  printf '#!/usr/bin/env bash\ncase "$1" in install) [ "${2:-}" = --apply ] && bash "${WT}/ops/filho.sh" ;; esac\n' > "${d}/fx/ops/w.sh"
  printf '#!/usr/bin/env bash\necho filho\n' > "${d}/fx/ops/filho.sh"
  _ck "(xiv) ato que executa um script fora de ato/delega/fecho acusa" "${d}/fx" "fecho-incompleto"
  printf 'fecho\tscript\tops/filho.sh\t-\n' >> "${d}/fx/ops/moat-targets.tsv"  # (core-only)
  _ck "(xv) com a linha fecho do filho, cala" "${d}/fx" ""
  printf 'fecho\tscript\tops/sumido.sh\t-\n' >> "${d}/fx/ops/moat-targets.tsv"  # (core-only)
  _ck "(xvi) linha fecho de script inexistente acusa" "${d}/fx" "fecho-sem-script"
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
