name: Onion Artifact Linter

# Provisionado por /meta:adopt (oferta com consentimento). É o gate que NÃO se pula:
# o githook local do Onion cai com `git commit --no-verify`; este não.
#
# Escopo deliberadamente MENOR que o do core: roda só o lint determinístico
# (`lint-artifacts.sh`, segundos). O auto-teste das guardas (`lint-selftest.sh`) é do
# core — leva ~15 min e existe para provar as guardas DELE; ao adotante ele custaria
# minutos de CI sem lhe dizer nada sobre o próprio repositório.

on:
  pull_request:
    paths:
      - '.claude/**'
      - 'docs/**'
      - 'CLAUDE.md'
      # o próprio CI: sem este path, um PR que mexe no workflow não dispara o lint —
      # ponto cego medido no core (#509), um nível acima do código.
      - '.github/workflows/**'

permissions:
  contents: read

jobs:
  lint-onion-artifacts:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0

      # Capacidade antes do gate: a suíte degrada gracioso sem tooling (pula guardas).
      # Aceitável na máquina do autor, inaceitável aqui — verde por ausência de
      # ferramenta é verde que não significa nada (sinal de campo 2026-07-25).
      - name: Capacidade do runner
        run: |
          command -v jq >/dev/null 2>&1 || { sudo apt-get update -qq && sudo apt-get install -y -qq jq; }
          missing=""
          for t in jq git awk python3; do command -v "$t" >/dev/null 2>&1 || missing="${missing} $t"; done
          [ -z "${missing}" ] || { echo "ERRO: falta no runner —${missing}"; exit 1; }

      - name: Lint determinístico de artefatos Onion
        run: bash .claude/validation/lint-artifacts.sh
