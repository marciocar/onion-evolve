# Log de Tentativas de Relay — Onion Trust Topology
# Gerado por trust-topology-check.sh (RFC-0003)
# Toda tentativa é registrada — autorizada ou bloqueada.

| Timestamp | FROM | TO | ACTION | STATUS | Razão |
|---|---|---|---|---|---|
| 2026-07-01 13:36 | onion-evolve | rhilo-metagamify | relay | AUTORIZADO | core (source) tem autoridade emissora universal |
| 2026-07-01 13:36 | rhilo-metagamify | onion-evolve | advise | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-07-01 13:36 | rhilo-metagamify | onion-evolve | correct | BLOQUEADO | can_correct_to de 'rhilo-metagamify' não inclui 'onion-evolve'. Adicionar se intencional. |
| 2026-10-05 18:56 | metagamify | onion-evolve | relay | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-10-15 12:29 | maestro-notebook-test | onion-evolve | relay | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-10-15 16:43 | maestro-notebook-test | onion-evolve | relay | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-10-15 16:43 | maestro-notebook-test | onion-evolve | relay | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-10-16 01:48 | maestro-notebook-test (declarado, não provado) | onion-evolve | relay | BLOQUEADO | veto do gate a2a-verify: bad-kid |
| 2026-10-16 01:48 | maestro-notebook-test (declarado, não provado) | onion-evolve | relay | BLOQUEADO | veto do gate a2a-verify: unsupported-alg |
| 2026-10-16 02:01 | maestro-notebook-test | onion-evolve | relay | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-10-21 22:17 | maestro-peer-test | onion-evolve | relay | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-10-21 22:22 | maestro-peer-test | onion-evolve | relay | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-10-21 22:22 | maestro-peer-test (declarado, não provado) | onion-evolve | relay | BLOQUEADO | veto do gate a2a-verify: replay |
| 2026-10-21 22:22 | maestro-peer-test (declarado, não provado) | onion-evolve | relay | BLOQUEADO | veto do gate a2a-verify: unknown-kid:maestro-peer-test-9 |
| 2026-10-21 22:22 | maestro-peer-test | onion-evolve | relay | AUTORIZADO | inbox do core é aberto para relay e advise |
| 2026-10-21 22:22 | maestro-peer-test (declarado, não provado) | onion-evolve | relay | BLOQUEADO | veto do gate a2a-verify: future |
| 2026-10-21 22:22 | maestro-peer-test (declarado, não provado) | onion-evolve | relay | BLOQUEADO | veto do gate a2a-verify: exp-beyond-ceiling |
| 2026-10-21 22:22 | maestro-peer-test (declarado, não provado) | onion-evolve | relay | BLOQUEADO | veto do gate a2a-verify: body-mismatch |
| 2026-10-21 22:25 | maestro-peer-test (declarado, não provado) | onion-evolve | relay | BLOQUEADO | veto do gate a2a-verify: expired |
| 2026-10-22 02:37 | maestro-peer-test | onion-evolve | relay | AUTORIZADO | inbox do core é aberto para relay e advise |
