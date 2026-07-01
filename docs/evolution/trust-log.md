# Log de Tentativas de Relay — Onion Trust Topology
# Gerado por trust-topology-check.sh (RFC-0003)
# Toda tentativa é registrada — autorizada ou bloqueada.

| Timestamp | FROM | TO | ACTION | STATUS | Razão |
|---|---|---|---|---|---|
| 2026-07-01 13:36 | onion-evolve | rhilo-metagamify | relay | AUTORIZADO | core (source) tem autoridade emissora universal |
| 2026-07-01 13:36 | rhilo-metagamify | onion-evolve | advise | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-07-01 13:36 | rhilo-metagamify | onion-evolve | correct | BLOQUEADO | can_correct_to de 'rhilo-metagamify' não inclui 'onion-evolve'. Adicionar se intencional. |
