meta:
  id: {{SLUG}}
  schema_version: "1"
  date: {{DATE}}
# ── KG de DIAGNÓSTICO de engajamento (2 camadas) — /meta:kg diagnose ──────────
# Prefixos por convenção (mnemônico; o radar ignora, o node_type manda):
#   C_ claim · E_ evidence · D_ decision · Q_ question · A_ artifact · ENT_ entity
# Camada domain = o NEGÓCIO do cliente (SSOT durável): entity/state/event/rule/policy.
# Camada audit  = a EPISTEMOLOGIA da consultoria (hipóteses/achados): claim/evidence/
#   question/decision/artifact. O audit TRACES_TO o domain.
# Invariante: todo nó ≥1 aresta. plane: PROD = fato consolidado · DEV = hipótese/trabalho.
nodes:
  # LOTE 1 — comece pelo ciclo/processo do cliente (domain) + as 1as hipóteses (audit).
  # Ex.:
  #   - id: ENT_cliente
  #     node_type: entity
  #     layer: domain
  #     plane: PROD
  #     impact: 4
  #     confidence: 0.9
  #     status: confirmed
  #     label: "..."
  #     trace: "sources/..."
edges:
  # Ligue cada nó (SUPPORTS/REFUTES/SUPERSEDES/DEPENDS_ON/TRACES_TO; HAS_STATE/TRANSITIONS/…).
