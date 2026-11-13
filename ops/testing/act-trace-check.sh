#!/usr/bin/env bash
# act-trace-check.sh — o FECHO dos atos medido por EXECUÇÃO, não por leitura (core-only).
#
# POR QUE EXISTE (9ª passada do refutador do #1647, decisão de desenho do team-lead em 2026-11-13): o detector estático
# da REGRA 117 (act-signature-check.sh) persegue FORMAS de execução no texto, e cada passada achava uma nova (o caminho
# em variável, a variável de diretório derivada de outra, a raiz de mktemp, o caminho montado dentro de uma função). Aqui o
# ônus se inverte: roda-se o ENSAIO REAL de cada porta (o mesmo publish-door.sh, os mesmos argumentos de produção, sem
# --push) num clone de sandbox, com `bash`, `sh` e `python3` no PATH trocados por um registrador que anota cada script
# executado; e reprova se algum script do repo executado não está numa linha ato/delega/fecho do ops/moat-targets.tsv nem
# abaixo da FRONTEIRA do lint (o que o lint-artifacts.sh e o lint-selftest.sh rodam não se desce). O rastro é a verdade;
# o detector estático vira pré-filtro.
#
# USO
#   ops/testing/act-trace-check.sh [--doors "onion-core onion-plugins"] [--keep] [--trace-out <arquivo>]
#       roda o ensaio de cada porta no sandbox (sem rede: as portas são repositórios bare locais semeados aqui) e julga
#   ops/testing/act-trace-check.sh --judge <rastro> <moat-targets.tsv> <raiz-do-core>
#       só julga um rastro já gravado (a bancada usa para o mutante: o mesmo rastro contra o tsv sem uma linha fecho)
#
# O QUE NÃO VÊ (lacuna nomeada): arquivo LIDO por `source`/`.` (não é processo; o detector estático o cobre); script
# executado por caminho absoluto de shell (`/bin/bash x.sh`, shebang `#!/bin/bash`); e todo ato SEM ensaio executável
# (o merge alheio, o deploy do site, o update do bridge e a persona do Slack), que fica no detector estático.
# A diferença do ensaio para a produção é uma só, declarada: o registro vem de --members (as portas apontam os bare locais).
#
# rc: 0 todo script executado está no fecho · 1 há script fora · 2 não pude medir (o ensaio falhou ou não rodou nada)
set -uo pipefail

NAME=act-trace-check
FRONTEIRA_RE='(^|/)\.claude/validation/lint-(artifacts|selftest)\.sh$'
say() { printf '[%s] %s\n' "${NAME}" "$*"; }

judge() {  # $1 rastro · $2 tsv · $3 raiz do core
  python3 -I - "$1" "$2" "$3" <<'PY'
import os, re, sys
trace, tsv, root = sys.argv[1:4]
known = set()
for ln in open(tsv, encoding="utf-8"):
    if not ln.strip() or ln.lstrip().startswith("#"):
        continue
    f = ln.rstrip("\n").split("\t")
    if len(f) >= 3 and f[0] in ("ato", "delega", "fecho") and f[1] == "script":
        known.add(os.path.normpath(f[2]))
front = {".claude/validation/lint-artifacts.sh", ".claude/validation/lint-selftest.sh"}
seen, out = set(), {}
for ln in open(trace, encoding="utf-8", errors="replace"):
    p, _, under = ln.rstrip("\n").partition("\t")
    m = re.search(r"((?:^|/)(?:ops|\.claude)/[^\s]+\.(?:sh|py))$", p)
    if not m:
        continue
    rel = m.group(1).lstrip("/")
    if not os.path.isfile(os.path.join(root, rel)):
        continue                                       # script do bundle que não existe no core: não é do repo
    seen.add(rel)
    if under == "1" or rel in front or rel in known:
        continue
    out.setdefault(rel, p)
if not seen:
    print("NAO-MEDI: o rastro não tem nenhum script do repo (o ensaio rodou?)")
    sys.exit(2)
for rel, p in sorted(out.items()):
    print("FORA-DO-FECHO\t%s\t(executado como %s)" % (rel, p))
print("scripts do repo executados no ensaio: %d únicos; fora do fecho (e fora da FRONTEIRA): %d" % (len(seen), len(out)))
sys.exit(1 if out else 0)
PY
}

if [ "${1:-}" = --judge ]; then
  [ $# -eq 4 ] || { echo "uso: $0 --judge <rastro> <tsv> <raiz>" >&2; exit 2; }
  judge "$2" "$3" "$4"; exit $?
fi

DOORS="onion-core onion-plugins"; KEEP=0; TRACE_OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --doors) DOORS="${2:?--doors exige a lista}"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    --trace-out) TRACE_OUT="${2:?--trace-out exige um arquivo}"; shift 2 ;;
    -h|--help) sed -n '/^# USO/,/^# rc:/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "uso: $0 [--doors \"a b\"] [--keep] | --judge <rastro> <tsv> <raiz>" >&2; exit 2 ;;
  esac
done

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(mktemp -d)"
[ "${KEEP}" = 1 ] || trap 'rm -rf -- "${T}"' EXIT
say "sandbox: ${T}"
# o core de sandbox: um bare com a main no HEAD deste checkout, e um clone dele (o motor lê origin/main)
git clone -q --bare --shared "${SRC}" "${T}/core-origin.git" || { say "não clonei o core"; exit 2; }
git -C "${T}/core-origin.git" update-ref refs/heads/main "$(git -C "${SRC}" rev-parse HEAD)"
git -C "${T}/core-origin.git" symbolic-ref HEAD refs/heads/main
git clone -q "${T}/core-origin.git" "${T}/core" || { say "não clonei o checkout de sandbox"; exit 2; }
OLD="$(git -C "${T}/core" rev-parse HEAD~1 2>/dev/null || git -C "${T}/core" rev-parse HEAD)"
# as portas: bare locais semeados como uma porta já publicada (por fetch de um repo-semente, sem push)
_seed() {  # $1 bare · $2 ramo · $3 arquivo · $4 conteúdo
  local s="${T}/seed-$(basename "$1" .git)"; git init -q "${s}"; mkdir -p "${s}/$(dirname "$3")"
  printf '%s' "$4" > "${s}/$3"; git -C "${s}" add -A
  git -C "${s}" -c user.email=t@t -c user.name=t commit -qm semente
  git init -q --bare "$1"; git -C "$1" fetch -q "${s}" "HEAD:refs/heads/$2"; git -C "$1" symbolic-ref HEAD "refs/heads/$2"
}
_seed "${T}/door-core.git" main .claude/.onion-version "$(printf 'source_commit: %s\nrole: source\nkind: door\n' "${OLD:0:12}")"
_seed "${T}/door-standalone.git" main .claude/.onion-version "$(printf 'source_commit: %s\nrole: standalone\nkind: door\n' "${OLD:0:12}")"
_seed "${T}/door-plugins.git" master plugins/onion/.claude-plugin/provenance.json "$(printf '{"ref": "%s"}\n' "${OLD}")"
sed -e "s#remote: github.com/marciocar/onion-core\\b.*#remote: ${T}/door-core.git#" \
    -e "s#remote: github.com/marciocar/onion-plugins\\b.*#remote: ${T}/door-plugins.git#" \
    -e "s#remote: github.com/marciocar/onion-standalone\\b.*#remote: ${T}/door-standalone.git#" \
    "${T}/core/docs/evolution/federation/members.yaml" > "${T}/members-bench.yaml"
# o REGISTRADOR: bash, sh e python3 no PATH anotam o script que vão executar e seguem para o binário real. Abaixo da
# FRONTEIRA (o processo do lint e os filhos dele), a anotação leva a marca 1 e não se julga.
mkdir -p "${T}/bin"; : > "${T}/trace.log"
for b in bash sh python3; do
  real="$(command -v "${b}")"
  cat > "${T}/bin/${b}" <<EOF
#!/bin/bash
k=0; for a in "\$@"; do
  case "\$a" in -c|-m) break ;; -o|-O|--rcfile|--init-file) k=1; continue ;; -*) continue ;; esac
  [ "\$k" = 1 ] && { k=0; continue; }
  if [ -f "\$a" ]; then
    p="\$(realpath -- "\$a" 2>/dev/null || printf '%s' "\$a")"
    printf '%s\t%s\n' "\$p" "\${ONION_TRACE_FRONT:-0}" >> "${T}/trace.log"
    [[ "\$p" =~ ${FRONTEIRA_RE} ]] && export ONION_TRACE_FRONT=1
  fi
  break
done
exec "${real}" "\$@"
EOF
  chmod +x "${T}/bin/${b}"
done
rc_all=0
for door in ${DOORS}; do
  say "ensaio de ${door} (o publish-door.sh real, sem --push)"
  ( cd "${T}/core" && PATH="${T}/bin:${PATH}" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
      timeout 1500 bash ops/publish-door.sh "${door}" --members "${T}/members-bench.yaml" ) > "${T}/run-${door}.log" 2>&1
  r=$?
  if [ "${r}" -ne 0 ]; then say "o ensaio de ${door} saiu ${r}: $(tail -2 "${T}/run-${door}.log" | tr '\n' ' ' | cut -c1-240)"; rc_all=2; fi
done
[ -n "${TRACE_OUT}" ] && cp -- "${T}/trace.log" "${TRACE_OUT}"
judge "${T}/trace.log" "${SRC}/ops/moat-targets.tsv" "${SRC}"; jr=$?  # (core-only)
[ "${KEEP}" = 1 ] && say "rastro: ${T}/trace.log"
[ "${jr}" -ne 0 ] && exit "${jr}"
exit "${rc_all}"
