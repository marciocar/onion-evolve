#!/usr/bin/env bash
# ===========================================================================
# session-transcript.sh — acha a CONVERSA de uma sessão do Claude Code pelo id ou pelo título, e a PASTA onde ela
# se retoma (core-only; lido pelo ops/session-open.sh e pelo ops/onion-attach.sh).
#
# Por que existe (2026-11-25): o session-open.sh tirava a pasta do registro de posse, e o registro é AMBÍGUO para a
# sessão dona de várias peças (a sessão de serviços casa 6 membros): o abridor recusava mesmo com --resume <id>. A pasta
# certa de uma retomada não é a do registro, é a do TRANSCRIPT: o `claude --resume <id>` acha a conversa pela pasta
# codificada em ~/.claude/projects/<pasta codificada>/<id>.jsonl, e essa pasta é a de ONDE a sessão foi lançada.
#
# Como se acha a pasta: a codificação do harness troca todo caractere fora de [A-Za-z0-9-] por «-» e por isso não se
# desfaz (/a/b.c e /a/b-c dão o mesmo nome). Então a pasta é o primeiro `cwd` gravado no transcript cuja codificação
# é IGUAL ao nome da pasta do transcript. O `cwd` mais recente (a worktree em que a sessão entrou depois) é só dito,
# em LAST_CWD: retomar de lá procuraria a conversa noutra pasta codificada.
#
# Uso:
#   session-transcript.sh by-id <id>          → TSV: mtime id pasta caminho último-cwd título (rc 1 nenhum · 5 mais de um)
#   session-transcript.sh by-title <nome>     → o mesmo TSV, uma linha por conversa cujo ÚLTIMO título é <nome>, da mais
#                                               recente para a mais antiga (rc 1 nenhuma)
# Opção: --projects <dir> (padrão ${SESSION_TRANSCRIPT_PROJECTS:-~/.claude/projects}).
# Campo que não se mede vira «-» (ex.: pasta sem cwd compatível). Só lê: do transcript lê o título e os `cwd`, nunca a
# conversa. Saída: 0 achou · 1 nenhum · 2 uso · 5 ambíguo (by-id com o mesmo id em duas pastas).
# Bancada: run_onion_attach_selftests e run_session_open_selftests (lint-selftest.sh).
# ===========================================================================
set -uo pipefail

PROJECTS="${SESSION_TRANSCRIPT_PROJECTS:-${HOME}/.claude/projects}"
_usage() { printf 'uso: session-transcript.sh by-id <id> | by-title <nome> [--projects <dir>]\n' >&2; exit 2; }
[ $# -ge 2 ] || _usage
MODE="$1" KEY="$2"; shift 2
while [ $# -gt 0 ]; do
  case "$1" in
    --projects) shift; PROJECTS="${1:-}"; [ -n "${PROJECTS}" ] || _usage ;;
    *) _usage ;;
  esac
  shift
done
command -v python3 >/dev/null 2>&1 || { echo "session-transcript: python3 ausente" >&2; exit 2; }
# pasta de projetos ausente ou ilegível NÃO é «nenhuma conversa» (quem chama sugeriria abrir uma nova): rc 2
[ -d "${PROJECTS}" ] && [ -r "${PROJECTS}" ] || { echo "session-transcript: não li a pasta de projetos ${PROJECTS}" >&2; exit 2; }

case "${MODE}" in
  by-id)
    [[ "${KEY}" =~ ^[A-Za-z0-9][A-Za-z0-9-]{7,63}$ ]] || { echo "session-transcript: id inválido: «${KEY}»" >&2; exit 2; }
    # o id é o nome do arquivo: nenhuma varredura de conteúdo
    files="$(find "${PROJECTS}" -mindepth 2 -maxdepth 2 -type f -name "${KEY}.jsonl" 2>/dev/null)" ;;
  by-title)
    [[ "${KEY}" =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$ ]] || { echo "session-transcript: nome inválido: «${KEY}»" >&2; exit 2; }
    # pré-filtro em C (o título aparece em algum ponto do arquivo); o ÚLTIMO título é conferido no python
    files="$(grep -rlF --include='*.jsonl' -- "\"customTitle\":\"${KEY}\"" "${PROJECTS}" 2>/dev/null)"; grc=$?
    # rc 2 do grep = erro de leitura: sem nenhum achado, não é «nenhuma» (rc 2); com achados, segue e diz
    if [ "${grc}" -eq 2 ]; then
      [ -n "${files}" ] || { echo "session-transcript: erro de leitura em ${PROJECTS}: não sei se há conversa «${KEY}»" >&2; exit 2; }
      echo "session-transcript: ⚠️ parte de ${PROJECTS} não se leu: pode haver conversa «${KEY}» mais recente fora da lista" >&2
    fi ;;
  *) _usage ;;
esac
[ -n "${files}" ] || exit 1

out="$(python3 -I -c '
import json, os, re, sys
mode, key = sys.argv[1], sys.argv[2]
enc = lambda p: re.sub(r"[^A-Za-z0-9-]", "-", p)
rows = []
for path in sys.stdin.read().splitlines():
    if not path: continue
    folder = os.path.basename(os.path.dirname(path))
    title, launch, last = None, None, None
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                if "\"customTitle\"" in line or "\"cwd\"" in line:
                    try: d = json.loads(line)
                    except ValueError: continue
                    if not isinstance(d, dict): continue
                    t = d.get("customTitle")
                    if isinstance(t, str): title = t
                    c = d.get("cwd")
                    if isinstance(c, str) and c:
                        last = c
                        if launch is None and enc(c) == folder: launch = c
        m = int(os.stat(path).st_mtime)
    except OSError:
        continue
    if mode == "by-title" and title != key: continue
    sid = os.path.basename(path)[:-len(".jsonl")]
    clean = lambda v: (v or "-").replace("\t", " ").replace("\n", " ")
    rows.append((m, sid, clean(launch), path, clean(last), clean(title)))
rows.sort(key=lambda r: -r[0])
for r in rows: print("\t".join(str(v) for v in r))
' "${MODE}" "${KEY}" <<< "${files}")" || exit 2
[ -n "${out}" ] || exit 1
printf '%s\n' "${out}"
if [ "${MODE}" = by-id ] && [ "$(wc -l <<< "${out}")" -gt 1 ]; then
  echo "session-transcript: o id ${KEY} tem transcript em mais de uma pasta: ambíguo" >&2; exit 5
fi
exit 0
