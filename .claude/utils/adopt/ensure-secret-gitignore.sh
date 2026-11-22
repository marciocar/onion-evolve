#!/usr/bin/env bash
# =============================================================================
# ensure-secret-gitignore.sh — garante que o adotante NÃO versione segredos locais
#
# POR QUÊ : a adoção de dois adotantes (2026-10-06) mediu que o /meta:adopt não
#           gerava `.gitignore` de segredos — nada impedia commitar um `.env` no adotante. As duas
#           sessões curaram à mão, no próprio repo. Cura de classe: o adopt garante o bloco.
#
# MECÂNICA: never-clobber e idempotente. Se o `.gitignore` não tem regra para `.env`, acrescenta o
#           bloco Onion (cria o arquivo se não existir). Regra do adotante que já cubra `.env` é
#           respeitada e nada muda. Um `.env` JÁ VERSIONADO não é desfeito (gitignore não destrackeia):
#           o script AVISA em voz alta, com o comando que o maestro roda se quiser.
#
# BYTECODE (SAC-444, medido em 2026-11-22): o bundle viaja com ferramentas Python (vendor/kg-ssot/tools,
#           .claude/validation/*.py) e o adotante nascia sem `__pycache__/` no `.gitignore`. Numa adoção de
#           teste, um `import kg_gate` plantou `vendor/kg-ssot/tools/__pycache__/` como não-rastreado: um
#           `git add -A` o versiona, e o `kg_vendor.py check` reprova o vendor como divergente da tag. O mesmo
#           helper garante o 2º bloco, pela mesma régua: regra do adotante que já cubra (`__pycache__`,
#           `**/__pycache__/`, `*.pyc`, `*.py[cod]`) é respeitada; senão acrescenta. Bytecode JÁ versionado
#           só avisa. Teto: o gitignore não apaga o `__pycache__/` do disco, e o `kg_vendor.py check` lê o
#           disco; quem roda o Python do vendor sem `-B` ainda o planta (o gitignore só o tira do commit).
#
# USO     : ensure-secret-gitignore.sh <DEST>      → rc 0 (e imprime o que fez); rc 2 = uso errado
# =============================================================================
set -uo pipefail
DEST="${1:?uso: ensure-secret-gitignore.sh <DEST>}"
[ -d "${DEST}" ] || { echo "ensure-secret-gitignore: diretório inexistente: ${DEST}" >&2; exit 2; }
GI="${DEST}/.gitignore"

# já existe regra que ignora `.env`? (`.env`, `/.env`, `.env*`, `*.env` — não as negações)
_has_env_rule() {
  [ -f "${GI}" ] || return 1
  grep -qE '^[[:space:]]*/?(\.env|\.env\*|\*\.env|\.env\.\*)[[:space:]]*$' "${GI}"
}

if _has_env_rule; then
  echo "ensure-secret-gitignore: o .gitignore já ignora .env — nada a fazer"
else
  {
    [ -s "${GI}" ] && [ -n "$(tail -c1 "${GI}")" ] && echo
    [ -s "${GI}" ] && echo
    echo "# Segredos locais — nunca versionados (o .env.example é o modelo, este sim versionado). Onion."
    echo ".env"
    echo ".env.*"
    echo "!.env.example"
    echo "!.env.example.onion"
  } >> "${GI}"
  echo "ensure-secret-gitignore: bloco de segredos acrescentado a ${GI}"
fi

# bytecode do Python: já existe regra que o ignora? (o diretório em qualquer nível, ou os .pyc)
_has_pyc_rule() {
  [ -f "${GI}" ] || return 1
  grep -qE '^[[:space:]]*(\*\*/)?__pycache__/?[[:space:]]*$|^[[:space:]]*\*\.py(c|\[[a-z]*c[a-z]*\])[[:space:]]*$' "${GI}"
}
if _has_pyc_rule; then
  echo "ensure-secret-gitignore: o .gitignore já ignora __pycache__ — nada a fazer"
else
  {
    [ -s "${GI}" ] && [ -n "$(tail -c1 "${GI}")" ] && echo
    [ -s "${GI}" ] && echo
    echo "# Bytecode do Python — gerado ao rodar as ferramentas do Onion, nunca versionado. Onion."
    echo "__pycache__/"
  } >> "${GI}"
  echo "ensure-secret-gitignore: bloco de bytecode (__pycache__/) acrescentado a ${GI}"
fi

# um .env já VERSIONADO segue versionado: o gitignore não o desfaz
if git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1; then
  _tracked="$(git -C "${DEST}" ls-files -- '.env' '.env.*' ':!.env.example' ':!.env.example.onion')" || _tracked=""
  if [ -n "${_tracked}" ]; then
    echo "⚠️  ensure-secret-gitignore: arquivo(s) de segredo JÁ VERSIONADO(s) — o .gitignore não os desfaz:"
    printf '     %s\n' ${_tracked}
    echo "   Para parar de versionar (sem apagar o arquivo local): git -C '${DEST}' rm --cached <arquivo>"
    echo "   E trate o segredo como VAZADO se o repo já foi enviado a algum remoto."
  fi
  _pyc="$(git -C "${DEST}" ls-files -- '*__pycache__/*' '*.pyc')" || _pyc=""
  if [ -n "${_pyc}" ]; then
    echo "⚠️  ensure-secret-gitignore: bytecode do Python JÁ VERSIONADO — o .gitignore não o desfaz:"
    printf '     %s\n' ${_pyc}
    echo "   Para parar de versionar (sem apagar o local): git -C '${DEST}' rm -r --cached <caminho>"
  fi
fi
exit 0
