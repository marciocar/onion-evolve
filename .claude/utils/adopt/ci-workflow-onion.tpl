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
      # e o gate local: um PR que mexe só no pre-commit também tem de rodar o lint (achado na adoção de
      # um adotante, 2026-10-06 — o template não disparava em .githooks/**)
      - '.githooks/**'

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
          # o leitor do contrato do .kg.yaml (vendor/kg-ssot, que viaja com o Onion) precisa de PyYAML e
          # jsonschema; sem eles o kg-contract-check sai rc 2, "não julgado" (SAC-149). Desde a kg-ssot-v4.7.4 o
          # requirements.txt traz o sha256 de cada arquivo publicado, e o pip já os confere sozinho; o
          # --require-hashes acrescenta falhar alto se o arquivo um dia perder todos os hashes. Ele só entra quando
          # o arquivo traz hash: um vendor/kg-ssot próprio e anterior à v4.7.4 não tem, e com a flag o CI nasceria
          # vermelho. Piso: Python 3.11.
          if [ -f vendor/kg-ssot/tools/requirements.txt ]; then
            python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' \
              || { echo "ERRO: o leitor do contrato KG-SSOT exige Python 3.11 ou mais; o runner tem $(python3 --version 2>&1)"; exit 1; }
            rh=""; grep -q -- '--hash=sha256:' vendor/kg-ssot/tools/requirements.txt && rh="--require-hashes"
            python3 -m pip install --quiet ${rh} -r vendor/kg-ssot/tools/requirements.txt
          fi

      - name: Lint determinístico de artefatos Onion
        run: bash .claude/validation/lint-artifacts.sh
