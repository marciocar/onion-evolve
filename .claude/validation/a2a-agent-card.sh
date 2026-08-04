#!/usr/bin/env bash
# =============================================================================
# a2a-agent-card.sh — projeta o SSOT no Agent Card A2A do CORE (/.well-known/agent-card.json).
#
# F2.2 do roadmap de federação (RFC-0004), FUNDAÇÃO SEGURA no core. O Agent Card é a "capa" A2A que um
# receptor publica: quem é, o que expõe, como se autentica. Aqui é GERADO (como federation-console.html) —
# projeção read-only do members.yaml. O endpoint que o SERVE fica na VPS (gated); este script só materializa
# o artefato versionado.
#
# 🔒 CONFIDENCIALIDADE (guard-chave): projeta SÓ o próprio core (id==onion-evolve AND role==source). NENHUM
#    dado de adotante (um adotante multi-linhagem, um adotante regulado, um adotante, ...) entra no card. Descrição = string PÚBLICA CURADA
#    (não personality_summary). O selftest (run_agent_card_selftests) falha se qualquer outro id vazar.
# Contrato A2A (signals-only): skills = recepção de SINAIS GATED; NUNCA conversa autônoma (RFC-0004 §3/§6).
#
# Uso : a2a-agent-card.sh   → JSON (stdout) → docs/onion/agent-card.json
# Gracioso: sem python+yaml → exit 3 (é GERADOR; skip é correto — nenhuma decisão de segurança aqui).
#           Determinístico (sort_keys, sem timestamp/rand). Exercitado por lint-selftest (run_agent_card_selftests).
# Override p/ teste: A2A_MEMBERS_FILE=<path> (default: <git-root>/docs/evolution/federation/members.yaml).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GIT_DIR neutralizado: sob hook do git em worktree o GIT_DIR e ABSOLUTO, e com ele
# setado `git -C <subdir> rev-parse --show-toplevel` devolve o SUBDIR, nao a raiz —
# o script passa a procurar tudo no lugar errado e emite vazio (medido 2026-08-04).
ROOT="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../.." && pwd))"
MEMBERS="${A2A_MEMBERS_FILE:-${ROOT}/docs/evolution/federation/members.yaml}"
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || { echo "a2a-agent-card: python3+yaml ausente (exit 3)." >&2; exit 3; }

python3 - "${MEMBERS}" <<'PY'
import sys, json, yaml
mpath = sys.argv[1]
try: members = (yaml.safe_load(open(mpath)) or {}).get('members') or []
except Exception: members = []

# 🔒 filtro de confidencialidade: SÓ o core (source). Nada de adotante.
core = next((m for m in members if m.get('id') == 'onion-evolve' and m.get('role') == 'source'), None)
if not core:
    sys.stderr.write("a2a-agent-card: membro core (onion-evolve/source) ausente no members.yaml (exit 3).\n")
    sys.exit(3)

# Só campos públicos/curados do PRÓPRIO core. Descrição curada (NÃO personality_summary).
card = {
    "protocolVersion": "0.3.0",
    "name": "onion-evolve",
    "description": ("Onion framework core (source-of-truth). Recebe SINAIS de co-evolução GATED de membros "
                    "da federação; nunca conversa autônoma agente-a-agente. Aceitação sempre sob gate humano."),
    "url": "https://app.onionevolve.com/a2a",   # endpoint GATED (servido pelo onion-bridge na VPS — fase-2)
    "version": "1.0.0",
    "capabilities": {"streaming": True, "pushNotifications": True},
    "defaultInputModes": ["application/json"],
    "defaultOutputModes": ["application/json"],
    "securitySchemes": {
        "oauth2": {
            "type": "oauth2",
            "flows": {"authorizationCode": {
                "authorizationUrl": "https://app.onionevolve.com/oauth/authorize",
                "tokenUrl": "https://app.onionevolve.com/oauth/token",
                "scopes": {"co-evolution.signal": "enviar sinal de co-evolução gated"}
            }}
        },
        "mtls": {"type": "mutualTLS"}
    },
    "security": [{"oauth2": ["co-evolution.signal"]}, {"mtls": []}],
    "skills": [{
        "id": "co-evolution-signal",
        "name": "Recepção de sinal de co-evolução (gated)",
        "description": ("Recebe um SINAL tipado (contrato/anúncio/veredito) para triagem sob gate humano. "
                        "Signals-only: nunca executa conversa autônoma nem auto-aplica mudança."),
        "tags": ["gated", "signals-only", "co-evolution", "human-in-the-loop"],
        "inputModes": ["application/json"],
        "outputModes": ["application/json"]
    }]
}
print(json.dumps(card, ensure_ascii=False, indent=2, sort_keys=True))
PY
