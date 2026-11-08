# Amostra da parte em papel (etapa d)

Semente: `5773269bc1b25df57129601717c0029ff6f36be0` (commit da `STAGE0.md`). Árvore: `5773269bc` (STAGE0.v2). Filas por `sample.py`; exclusão por carga por `carga.sh` (2 itens de 1.103, um em B e um em A); aceite por `score.py accept` sobre as marcas de G1. G1 decidiu os pulos por conteúdo; "cota cheia" e "já lido" são do script. Caminhos com id de adotante saem como `<adotante>`.

| Classe (G1, em d) | Aceitos | Cota de (d) |
|---|---|---|
| F-VALOR | 4 | 4 |
| F-FATO | 0 | 3 |
| F-REGUA | 3 | 3 |
| F-PASSA | 9 | 9 |
| O | 4 | 4 |
| N | 17 | 20 |

Falsos alarmes em N: 0 (G1 marcou 0 falso alarme em 134 itens). Paradas por fila (posição): {'FR': 24, 'FF': 30, 'FV': 0, 'B': 0, 'A': 40}.

## Aceitos

| Fila | Pos. | Arquivo | Classe G1 | Origem |
|---|---|---|---|---|
| FR | 1 | FR-001.txt | O | `docs/evolution/review/docs-escada-de-adocao-1105.md` |
| FR | 2 | FR-002.txt | N | `docs/evolution/review/fix-catraca-regra49.md` |
| FR | 3 | FR-003.txt | N | `docs/evolution/review/docs-radar-e3-2026-10-17-r13.md` |
| FR | 4 | FR-004.txt | N | `docs/evolution/review/fix-paths-semantics-e-dirty-tree.md` |
| FR | 5 | FR-005.txt | F-VALOR | `docs/evolution/review/docs-elenxo-doctrine-to-vendored-kb.md` |
| FR | 6 | FR-006.txt | F-PASSA | `docs/evolution/review/feat-provenance-wave-o3-1.md` |
| FR | 7 | FR-007.txt | N | `docs/evolution/review/fix-radar-decision-done-in-dev.md` |
| FR | 8 | FR-008.txt | F-VALOR | `docs/evolution/review/chore-seal-composition-questions.md` |
| FR | 10 | FR-010.txt | N | `docs/evolution/inbox/_processed/2026-09-10-doutrina-versus-codigo-no-motor-do-kg.md` |
| FR | 12 | FR-012.txt | F-VALOR | `docs/evolution/review/feat-client-manual-doctrine.md` |
| FR | 13 | FR-013.txt | F-PASSA | `docs/evolution/review/feat-regra59-modo-consumido.md` |
| FR | 14 | FR-014.txt | N | `docs/evolution/review/fix-regra58-e-w2-em-campo.md` |
| FR | 16 | FR-016.txt | F-VALOR | `docs/evolution/review/drive-open-threads-batch3.md` |
| FR | 18 | FR-018.txt | F-REGUA | `docs/evolution/review/feat-kg-seal-check.md` |
| FR | 19 | FR-019.txt | F-PASSA | `docs/evolution/review/chore-door-17-pin.md` |
| FR | 20 | FR-020.txt | F-PASSA | `docs/evolution/review/fix-kg-engine-doutrina-vs-codigo.md` |
| FR | 21 | FR-021.txt | F-PASSA | `docs/evolution/review/chore-pin-after-853.md` |
| FR | 22 | FR-022.txt | N | `docs/evolution/inbox/_processed/2026-07-16-kg-sdaal-dogfood-ouro.md` |
| FR | 23 | FR-023.txt | F-REGUA | `docs/evolution/inbox/_processed/2026-10-27-proposal-projection-with.md` |
| FR | 24 | FR-024.txt | F-REGUA | `docs/evolution/review/docs-a2a-a7c1-stop-and-record.md` |
| FF | 1 | FF-001.txt | N | `docs/evolution/review/docs-wsync-workspace-updated-1022.md` |
| FF | 2 | FF-002.txt | N | `docs/evolution/inbox/_processed/2026-09-08-agente-expo-react-native.md` |
| FF | 5 | FF-005.txt | N | `docs/evolution/review/feat-plugin-lint-deps-contract.md` |
| FF | 6 | FF-006.txt | N | `docs/evolution/review/fix-kg-contract-debt-cheap.md` |
| FF | 7 | FF-007.txt | N | `docs/evolution/review/feat-regra60-idioma-identificador.md` |
| FF | 8 | FF-008.txt | N | `docs/evolution/review/docs-decide-seals-1025.md` |
| FF | 10 | FF-010.txt | F-PASSA | `docs/evolution/review/feat-bench-machine-cpu-semaphore.md` |
| FF | 12 | FF-012.txt | O | `docs/evolution/review/fix-write-stamp-rebuilds-installed-node.md` |
| FF | 14 | FF-014.txt | N | `docs/evolution/review/feat-meta-cc-update.md` |
| FF | 15 | FF-015.txt | N | `docs/evolution/review/docs-radar-e3-2026-11-03-r22.md` |
| FF | 16 | FF-016.txt | F-PASSA | `docs/evolution/review/chore-kg-ssot-4.11.0.md` |
| FF | 17 | FF-017.txt | N | `docs/evolution/review/fix-read-leg-reaches-bash.md` |
| FF | 22 | FF-022.txt | F-PASSA | `docs/evolution/review/fix-migrate-python-venv-copy-perms.md` |
| FF | 24 | FF-024.txt | F-PASSA | `docs/evolution/review/research-codex-as-core.md` |
| FF | 26 | FF-026.txt | N | `docs/evolution/review/fix-kg-reverify-worker-contract.md` |
| FF | 28 | FF-028.txt | O | `docs/evolution/review/feat-dissect-object-families.md` |
| A | 5 | A-005.txt | O | `docs/evolution/review/docs-co-announce-elenxo-2026-08-18.md` |

## Pulos e descartes, item a item

- FR 9, `docs/evolution/inbox/_processed/2026-10-06-radar-cego-mu07-mu18.md`: duplicata: Duplica o incidente de FR-007: o radar não avisa o MU-18, curado lá, e o MU-07 já virou pergunta de pesquisa lá.
- FR 11, `docs/evolution/review/feat-kg-projection-with.md`: sem data: Nem o frontmatter nem o texto trazem data.
- FR 15, `docs/evolution/review/fix-extrator-piso-e-supressao.md`: duplicata: Duplica a dívida do extrator declarada em FR-013 (contador de supressão, supressão invisível no tsv e falta de piso).
- FR 17, `docs/evolution/review/feat-provenance-wave-o2.md`: cota cheia
- FF 3, `docs/evolution/review/chore-kg-ssot-4.17.0.md`: sem problema: A passada não teve achado; o limite é trabalho seguinte, não defeito.
- FF 4, `docs/evolution/review/docs-research-postmerge-projection-writer.md`: cota cheia
- FF 9, `docs/evolution/review/docs-canonical-names-1023.md`: duplicata: É o selo de D_NOMES_CANONICOS_NASCEM_CERTOS_1023, que já está na USED.
- FF 11, `docs/evolution/inbox/_processed/2026-10-28-proposal-company-brain-market.md`: duplicata: Duplica o incidente de Q_MA_FREE_ORG_READ_ENFORCED, da USED: o card da organização gratuita do Company Brain multiaudiência.
- FF 13, `docs/evolution/review/docs-seal-sharing-criterion.md`: duplicata: Duplica o incidente da fronteira indivíduo × empregador, do sinal 2026-09-13 que está na USED.
- FF 18, `docs/evolution/review/research-living-method-distribution.md`: cota cheia
- FF 19, `docs/evolution/review/chore-kg-ssot-4-28-0.md`: sem problema: Atualização de vendor sem achado.
- FF 20, `docs/evolution/review/feat-provenance-wave-o4.md`: cota cheia
- FF 21, `docs/evolution/review/chore-kg-ssot-4.12.0.md`: sem problema: O único achado foi refutado; os limites repetem trabalho já declarado.
- FF 23, `docs/evolution/review/fix-catraca-regra49.md`: já lido em FR-002.txt
- FF 25, `docs/evolution/review/docs-radar-e3-2026-10-17-r13.md`: já lido em FR-003.txt
- FF 27, `docs/evolution/inbox/_processed/2026-07-15-sinal-kg-audit-layer-content-audit.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- FF 29, `docs/evolution/review/docs-reverify-dissect-read-only.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- FF 30, `docs/evolution/review/chore-kg-ssot-4391.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 1, `docs/evolution/review/chore-core-maint-1027.md`: cota cheia
- A 2, `docs/evolution/review/chore-ctx-freshness-voice-p6-fix.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 3, `docs/evolution/review/feat-adopt-update-proves-gate-blocks.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 4, `docs/evolution/review/docs-radar-e3-cc-2-1-300.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 6, `docs/evolution/review/docs-wsync-workspace-updated-1022.md`: já lido em FF-001.txt
- A 7, `docs/evolution/review/feat-poda-l1-instructions-loaded.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 8, `docs/evolution/research/session-orchestration-2026-11/DIARIO.md::## Desfechos`: sem data: O trecho do diário não traz data.
- A 9, `docs/evolution/review/fix-merge-gate-warns-in-adopter.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 10, `docs/evolution/inbox/_processed/2026-09-08-agente-expo-react-native.md`: já lido em FF-002.txt
- A 11, `docs/evolution/review/fix-drive-checkpoint-in-graph.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 12, `docs/evolution/inbox/_processed/2026-10-21-a2a-<adotante>-793157ea69e0e017.md`: sem problema: Sinal de teste do canal, sem problema.
- A 13, `docs/evolution/review/chore-kg-ssot-4.17.0.md`: já lido em FF-003.txt
- A 14, `docs/evolution/review/fix-reconcile-c-p9-admin-oidc.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 15, `docs/evolution/review/fix-door-kg-read-index.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 16, `docs/evolution/review/docs-escada-de-adocao-1105.md`: já lido em FR-001.txt
- A 17, `docs/evolution/review/docs-research-audit-reanchor.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 18, `docs/evolution/review/docs-research-postmerge-projection-writer.md`: já lido em FF-004.txt
- A 19, `docs/evolution/review/feat-plugin-lint-deps-contract.md`: já lido em FF-005.txt
- A 20, `docs/evolution/review/feat-update-bridge-mechanism.md`: cota cheia
- A 21, `docs/evolution/review/fix-kg-contract-debt-cheap.md`: já lido em FF-006.txt
- A 22, `docs/evolution/review/fix-kg-premodelswitch-restart-correction.md`: duplicata: Corrige o carimbo do veto ao vivo do PreModelSwitch, incidente de docs-premodelswitch-guard-live-veto.md, da USED.
- A 23, `docs/evolution/review/feat-regra60-idioma-identificador.md`: já lido em FF-007.txt
- A 24, `docs/evolution/review/fix-merge-verified-auto-rebase.md`: cota cheia
- A 25, `docs/evolution/review/docs-design-fourth-dimension-direction.md`: cota cheia
- A 26, `docs/evolution/review/feat-background-probe-replaces-prose-veto.md`: cota cheia
- A 27, `docs/evolution/review/docs-decide-seals-1025.md`: já lido em FF-008.txt
- A 28, `docs/evolution/inbox/_processed/2026-07-14-branch-model-provisionamento-design-vertical.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 29, `docs/evolution/review/docs-canonical-names-1023.md`: já lido em FF-009.txt
- A 30, `docs/evolution/review/feat-bench-machine-cpu-semaphore.md`: já lido em FF-010.txt
- A 31, `docs/evolution/inbox/_processed/2026-10-28-proposal-company-brain-market.md`: já lido em FF-011.txt
- A 32, `docs/evolution/review/docs-promote-adrs-to-knowledge-base.md`: cota cheia
- A 33, `docs/evolution/review/fix-protect-main-bare-push-scope.md`: cota cheia
- A 34, `docs/evolution/review/feat-doors-decisions-sealed.md`: cota cheia
- A 35, `docs/evolution/review/docs-diary-superacao-sync-gate.md`: sem problema: Registro de aprendizado sem defeito.
- A 36, `docs/evolution/review/docs-round-elenxo-cured.md`: cota cheia
- A 37, `docs/evolution/review/fix-write-stamp-rebuilds-installed-node.md`: já lido em FF-012.txt
- A 38, `docs/evolution/review/fix-kg-seed-single-doc-and-constrains.md`: cota cheia (N sem falso alarme; vagas guardadas para falso alarme)
- A 39, `docs/evolution/review/docs-seal-sharing-criterion.md`: já lido em FF-013.txt
- A 40, `docs/evolution/inbox/_processed/2026-10-15-<adotante>-th-20261015-936ada43-nb-00f94d24f82914b66abd7ce9.md`: sem problema: Handshake sem corpo.
