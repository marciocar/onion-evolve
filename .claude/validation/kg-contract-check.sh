#!/usr/bin/env bash
# kg-contract-check.sh — julga UM ou mais .kg.yaml contra o contrato vendorizado (hoje v4.3), ANTES do commit.
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
# Aresta para OUTRO grafo (contrato v4.3, 2026-10-10, SAC-98): quando o arquivo tem `external_edges`, a ponta
# externa é conferida contra os .kg.yaml rastreados do repo (o mesmo índice do gate: corpus_index) — alvo que não
# existe reprova aqui, no MUST, com a dica de cura, em vez de só no CI. Sem `external_edges`, nada se monta.
#
# Regra por arquivo:
#   · arquivo FORA do índice do git (grafo novo) → MUST e SHOULD vazios;
#   · arquivo RASTREADO → MUST vazio, e nenhum código SHOULD que a versão de HEAD não tinha
#     (a dívida herdada do arquivo não é cobrada aqui; a migração do corpus é outro trabalho).
#   · CAMINHO DE MÁQUINA (REGRA 99, SAC-103, 2026-10-10), pela CLASSE de .claude/utils/kg/machine_path.py — a
#     mesma do migrador e da catraca do lint: grafo NOVO nasce sem nenhum; RASTREADO não ganha nenhum que a
#     versão de HEAD não tinha. Nó marcado `x_path_is_content` (selo P4) isenta, com a condição do selo.
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
_KG_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/kg"
[ -f "${_KG_LIB}/machine_path.py" ] || { echo "kg-contract-check: a classe do caminho de máquina (machine_path.py) não está em ${_KG_LIB} — não dá para julgar" >&2; exit 2; }
python3 -I -B - "${VENDOR}/tools" "${ROOT}" "${_KG_LIB}" "$@" <<'PY'
import collections, os, subprocess, sys
tools, root, kglib, files = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
sys.path.insert(0, tools)
sys.path.insert(0, kglib)
import machine_path
_hrx = machine_path.host_re(machine_path.known_hosts(root))
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
    # MUST do v4.3 (2026-10-10, SAC-98): external_edges
    "integrity.dangling-external": "external_edges aponta arquivo ou id que não existe entre os .kg.yaml rastreados: corrija o alvo pela origem (nunca invente; arquivo novo precisa de git add)",
    "integrity.dangling-external-local": "external_edges com a ponta LOCAL inexistente: o id sem `#` tem de ser um nó deste arquivo",
}
rc = 0
for f in files:
    path = os.path.relpath(os.path.abspath(f), root)
    if not os.path.isfile(os.path.join(root, path)):
        print(f"kg-contract-check: {f} não existe", file=sys.stderr); sys.exit(2)
    text = open(os.path.join(root, path), encoding="utf-8").read()
    # o índice do corpus só se monta quando o grafo usa external_edges (como no gate): custo zero no caso comum
    index = (kg_gate.kg_validate.corpus_index(root, kg_gate.tracked_graphs(root))
             if kg_gate.kg_validate.uses_external(text) else None)
    now = kg_gate.measure_texts([(path, text)], index)[path]
    tracked = subprocess.run(["git", "-C", root, "ls-files", "--error-unmatch", "--", path],
                             capture_output=True).returncode == 0
    before = set()
    mp_before = collections.Counter()
    if tracked:
        old = subprocess.run(["git", "-C", root, "show", f"HEAD:{path}"], capture_output=True, text=True)
        if old.returncode == 0:
            before = set(kg_gate.measure_texts([(path, old.stdout)], index)[path]["should"])
            mp_before = collections.Counter(machine_path.scan_text(old.stdout, _hrx)[0])
    worse_should = sorted(set(now["should"]) - before)
    mp_now = machine_path.scan_text(open(os.path.join(root, path), encoding="utf-8").read(), _hrx)[0]
    worse_mp = sorted((collections.Counter(mp_now) - mp_before).elements())
    if now["must"] or worse_should or worse_mp:
        rc = 1
        kind = "rastreado" if tracked else "novo"
        print(f"✗ {path} ({kind})")
        for c in now["must"]:
            print(f"    MUST   {c}" + (f" — {HINT[c]}" if c in HINT else ""))
        for c in worse_should:
            print(f"    SHOULD {c} — {HINT.get(c, 'ver vendor/kg-ssot/spec')}")
        for nid, fld, kind, tok in worse_mp:
            print(f"    MACHINE-PATH {nid}.{fld}: '{tok}' ({kind}) — caminho de máquina (REGRA 99): reescreva pela forma "
                  "(relativo do repo, remoto@sha:caminho ou ⟨descrição⟩); se o caminho É o conteúdo, marque o nó com "
                  "x_path_is_content: \"citação\"|\"vetor\"|\"receita\" (home de conta e hostname só a citação isenta)")
    else:
        print(f"✓ {path} conforme ao contrato" + (" (sem piorar o SHOULD herdado)" if tracked and before else ""))
sys.exit(rc)
PY
