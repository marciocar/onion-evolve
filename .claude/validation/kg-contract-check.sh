#!/usr/bin/env bash
# kg-contract-check.sh — julga UM ou mais .kg.yaml contra o contrato vendorizado (hoje v4.2), ANTES do commit.
#
# Por que existe (2026-10-08, SAC-71): desde que o gate do contrato entrou no CI (vendor/kg-ssot,
# kg_gate.py), todo grafo NOVO tem de nascer limpo no SHOULD — e o gate só enxerga arquivo rastreado
# pelo git. O escritor de grafo (o write(KG) do /onion-research, o /meta:drive, quem for) escreve o
# arquivo ANTES de qualquer `git add`; sem esta checagem por arquivo ele só descobre a dívida no CI.
# Aconteceu duas vezes no mesmo dia (#967 e #968), as duas curadas à mão.
#
# NÃO reimplementa o contrato: importa o leitor de referência do vendor (kg_gate.measure_texts, a mesma
# medição que a catraca usa). O vendor não se edita aqui; o que o contrato decidir chega pela tag.
#
# Regra por arquivo:
#   · arquivo FORA do índice do git (grafo novo) → MUST e SHOULD vazios;
#   · arquivo RASTREADO → MUST vazio, e nenhum código SHOULD que a versão de HEAD não tinha
#     (a dívida herdada do arquivo não é cobrada aqui; a migração do corpus é outro trabalho).
#
# Uso:  bash .claude/validation/kg-contract-check.sh <arquivo.kg.yaml>...
# rc:   0 = conforme · 1 = algum arquivo piora o contrato (códigos impressos) · 2 = não pôde julgar
#       (vendor ausente, dependência faltando, arquivo inexistente) — nunca passa como verde.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "kg-contract-check: fora de um repo git" >&2; exit 2; }
VENDOR="${KG_CONTRACT_VENDOR:-${ROOT}/vendor/kg-ssot}"
[ "$#" -ge 1 ] || { echo "uso: kg-contract-check.sh <arquivo.kg.yaml>..." >&2; exit 2; }
[ -f "${VENDOR}/tools/kg_gate.py" ] || { echo "kg-contract-check: vendor do contrato ausente em ${VENDOR} — não dá para julgar" >&2; exit 2; }

# -B: sem bytecode. O leitor importa as ferramentas do vendor; sem -B ele plantava tools/__pycache__ e o
# `kg_vendor.py check` seguinte reprovava o vendor como divergente da tag (medido 2026-10-08).
python3 -I -B - "${VENDOR}/tools" "${ROOT}" "$@" <<'PY'
import os, subprocess, sys
tools, root, files = sys.argv[1], sys.argv[2], sys.argv[3:]
sys.path.insert(0, tools)
try:
    import kg_gate
except Exception as e:  # PyYAML/jsonschema ausentes, vendor quebrado
    print(f"kg-contract-check: não consegui carregar o leitor do contrato ({e}) — instale vendor/kg-ssot/tools/requirements.txt", file=sys.stderr)
    sys.exit(2)

HINT = {
    "yaml.unquoted-date": "data sem aspas: escreva \"2026-10-08\" (baseline, review_after, verified_at, valid_from)",
    "form.required.node.provenance": "nó confirmed ou PROD sem provenance: {source, locator, method} com fonte VERIFICÁVEL; sem fonte, o nó não é confirmed",
    "form.range.node.label": "label acima de 280 caracteres: a afirmação curta fica no label, o resto vai para narrative",
    # avisos do v4.1 (2026-10-09): SHOULD, mas grafo novo nasce sem nenhum
    "form.required.node.verified_against": "claim com verified_at e sem verified_against: o carimbo diz QUANDO, falta CONTRA O QUÊ foi verificado",
    "integrity.untraced-decision": "decision sem origem: dê a ela trace: \"<run, pergunta ou fonte>\", provenance ou uma aresta TRACES_TO",
    "integrity.testimony-in-prod": "nó PROD apoiado em testemunho: rebaixe para DEV ou meça e troque o method para medição/leitura",
    "integrity.verified-before-fact": "verified_at anterior ao valid_from: não se verifica um fato antes de ele valer; corrija uma das datas",
    # aviso do v4.2 (2026-10-09, SAC-97): locality é opcional, mas quando vem tem de estar no vocabulário
    "form.enum.node.provenance.locality": "provenance.locality fora do vocabulário: use repo, web, host ou pessoa (ou tire a chave; kg-migrate-v3.py --locality a deriva do source)",
}
rc = 0
for f in files:
    path = os.path.relpath(os.path.abspath(f), root)
    if not os.path.isfile(os.path.join(root, path)):
        print(f"kg-contract-check: {f} não existe", file=sys.stderr); sys.exit(2)
    now = kg_gate.measure_texts([(path, open(os.path.join(root, path), encoding="utf-8").read())])[path]
    tracked = subprocess.run(["git", "-C", root, "ls-files", "--error-unmatch", "--", path],
                             capture_output=True).returncode == 0
    before = set()
    if tracked:
        old = subprocess.run(["git", "-C", root, "show", f"HEAD:{path}"], capture_output=True, text=True)
        if old.returncode == 0:
            before = set(kg_gate.measure_texts([(path, old.stdout)])[path]["should"])
    worse_should = sorted(set(now["should"]) - before)
    if now["must"] or worse_should:
        rc = 1
        kind = "rastreado" if tracked else "novo"
        print(f"✗ {path} ({kind})")
        for c in now["must"]:
            print(f"    MUST   {c}")
        for c in worse_should:
            print(f"    SHOULD {c} — {HINT.get(c, 'ver vendor/kg-ssot/spec')}")
    else:
        print(f"✓ {path} conforme ao contrato" + (" (sem piorar o SHOULD herdado)" if tracked and before else ""))
sys.exit(rc)
PY
