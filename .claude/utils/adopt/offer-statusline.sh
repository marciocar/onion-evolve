#!/usr/bin/env bash
# Oferece (não impõe) a linha de status do censo de sessões: «sessões: N trabalhando · M esperam você».
#
# ── POR QUE OFERTA, E NÃO ESCRITA ───────────────────────────────────────────────────────
# A statusLine NÃO se mescla entre camadas: o objeto inteiro da camada mais alta vence (managed > CLI >
# settings.local.json > settings.json do projeto > settings.json do usuário). Daí os dois cuidados, medidos
# pela curadoria no estudo statusline-sessoes-2026-11 e decididos pelo core em 2026-11-21:
#   · ESCREVER no settings do PROJETO apagaria, sem aviso, a statusLine que cada pessoa já usa no próprio
#     settings de usuário. Então o adopt NUNCA escreve statusLine no projeto.
#   · Projeto que JÁ tem statusLine esconde o censo naquele projeto, mesmo com a linha ligada no usuário.
#     O helper DETECTA e AVISA; não sobrescreve (é do adotante).
# O lugar certo é o settings do USUÁRIO, que o adopt não toca: o helper imprime o bloco pronto para colar,
# com o caminho ABSOLUTO resolvido agora (no settings de usuário o cwd varia por sessão, então caminho
# relativo quebraria). O caminho é o do checkout PRINCIPAL do repo (a adoção legacy instala numa worktree
# que some depois do merge), resolvido pelo git, nunca chutado.
#
# Somente leitura: não escreve em arquivo nenhum. Idempotente por construção.
# Uso : offer-statusline.sh <dest-dir>
# Exit: 0 bloco oferecido (avisos podem acompanhar) · 2 uso · 3 sem bloco: o script ou o python3 faltam
# Bancada: lint-selftest.sh (run_sessions_statusline_selftests).
set -uo pipefail

DEST="${1:-}"
[ -n "${DEST}" ] && [ -d "${DEST}" ] || { echo "uso: offer-statusline.sh <dest-dir>" >&2; exit 2; }
DEST="$(cd "${DEST}" && pwd -P)"
REL=".claude/utils/statusline/onion-sessions-line"

[ -f "${DEST}/${REL}" ] || { echo "✗ statusLine NÃO oferecida: ${DEST}/${REL} ausente (a cópia do framework está incompleta)." >&2; exit 3; }
command -v python3 >/dev/null 2>&1 || { echo "✗ statusLine NÃO oferecida: python3 ausente nesta máquina, e a linha roda em python3." >&2; exit 3; }

# ── 1. O caminho DURÁVEL: o checkout principal do repo (a worktree da adoção é temporária) ───────────────
HOME_DIR="${DEST}"; NOTE=""
_common="$(git -C "${DEST}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [ -n "${_common}" ] && [ "$(basename "${_common}")" = ".git" ] && [ -d "$(dirname "${_common}")" ]; then
  HOME_DIR="$(cd "$(dirname "${_common}")" && pwd -P)"
elif [ -n "${_common}" ] && [ "$(git -C "${_common}" rev-parse --is-bare-repository 2>/dev/null)" = true ]; then
  NOTE="repo bare: não há checkout principal, o caminho é o desta worktree; se ela for removida, rode a oferta de novo"
fi
if [ "${HOME_DIR}" != "${DEST}" ] && [ ! -f "${HOME_DIR}/${REL}" ]; then
  NOTE="o arquivo chega a ${HOME_DIR}/${REL} com o merge da branch em que ele está (adoção ou update): cole o bloco depois do merge"
fi
LINE="${HOME_DIR}/${REL}"

# ── 2. Ler (só ler) as camadas: projeto e usuário ────────────────────────────────────────────────────────
USER_SETTINGS=""
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then USER_SETTINGS="${CLAUDE_CONFIG_DIR}/settings.json"
elif [ -n "${HOME:-}" ]; then USER_SETTINGS="${HOME}/.claude/settings.json"; fi
python3 -I - "${LINE}" "${DEST}/.claude/settings.json" "${DEST}/.claude/settings.local.json" "${USER_SETTINGS}" "${NOTE}" <<'PY'
import json, os, shlex, sys

line, proj, proj_local, user, note = sys.argv[1:6]


def status_line(path):
    """(estado, valor): ausente | sem-campo | ilegivel | presente."""
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        return "ausente", None
    except (OSError, ValueError):
        return "ilegivel", None
    if not isinstance(data, dict) or "statusLine" not in data:
        return "sem-campo", None
    return "presente", data["statusLine"]


quoted = "'" + line.replace("'", "'\\''") + "'"
block = {"statusLine": {"type": "command", "command": f"python3 -I {quoted}", "refreshInterval": 30}}

for path in (proj, proj_local):
    st, val = status_line(path)
    if st == "presente":
        print(f"⚠️ AVISO: {path} já tem statusLine ({json.dumps(val, ensure_ascii=False)}). A statusLine do projeto "
              "substitui a do usuário sem aviso: neste projeto o censo de sessões NÃO aparece. Não mexi (é do projeto); "
              "para ver o censo aqui, tire a do projeto ou chame a linha de dentro dela.")
    elif st == "ilegivel":
        print(f"⚠️ AVISO: {path} ilegível (JSON inválido): NÃO medi se o projeto tem statusLine.")

def census_path(val):
    """O caminho do script do censo dentro do command da statusLine, ou None."""
    if not isinstance(val, dict):
        return None
    try:
        words = shlex.split(str(val.get("command", "")))
    except ValueError:
        return None
    return next((w for w in words if w.endswith("onion-sessions-line")), None)


st, val = status_line(user) if user else ("sem-home", None)
on = census_path(val) if st == "presente" else None
if on and not os.path.isabs(on):
    print(f"⚠️ AVISO: o settings do usuário ({user}) liga o censo por caminho RELATIVO ({on}): no settings do usuário o "
          "cwd muda a cada sessão, e a linha quebra fora deste repo. Troque pelo bloco abaixo.")
elif on and os.path.isfile(on):
    print(f"✓ statusLine do censo já ligada no settings do usuário ({user}): nada a colar.")
    sys.exit(0)
elif on:
    print(f"⚠️ AVISO: o settings do usuário ({user}) liga o censo em {on}, que NÃO existe mais (worktree removida?): "
          "a barra fica vazia. Troque pelo bloco abaixo.")
elif st == "sem-home":
    print("⚠️ AVISO: nem CLAUDE_CONFIG_DIR nem HOME definidos: NÃO medi o settings do usuário.")
    user = "~/.claude/settings.json"
elif st == "presente":
    print(f"ℹ️ o settings do usuário ({user}) já tem outra statusLine ({json.dumps(val, ensure_ascii=False)}): "
          "colar o bloco abaixo a SUBSTITUI. Decida antes de colar.")
elif st == "ilegivel":
    print(f"⚠️ AVISO: {user} ilegível: NÃO medi se já há statusLine no usuário.")

print("── statusLine do censo de sessões (oferta; o adopt não escreve) ──")
if note:
    print(f"ℹ️ {note}")
print(f"PASSO DO MAESTRO: cole no settings do USUÁRIO ({user}), na raiz do objeto, e abra uma sessão nova:")
print(json.dumps(block, ensure_ascii=False, indent=2))
PY
