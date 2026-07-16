---
date: 2026-07-16
instance: onion-evolve
type: decision
classification: protected
tags: [kg-sdaal, dogfood, backlog, verified_at, radar-parser, co-evolution]
affects: [meta, engineering]
breadcrumb_for: [meta:kg, meta:co-evolve, meta:evolve]
share_with: []
next_recommended: ""
review_after: 2026-10-14
conflict_class: conditional
valid_when: "as propostas #1/#2/#3/#4/#6/#7 do sinal rhilo-metagamify dogfood-ouro (2026-07-16) ainda NÃO estão implementadas no core — quando cada uma entrar, riscar do backlog; quando todas, aposentar"
---

## Signal
Dogfood mais intenso do KG SDAAL até hoje num adotante (rhilo-metagamify, reconciliação do SSOT
WRR/Modo Equilíbrio, 165 nós/288 arestas — decidiu arquitetura + gerou código + validação ao vivo).
Sinal upstream com **7 propostas ao core**, todas verificadas contra o código real na triagem. Só a
**#5 (footguns YAML na KB)** foi executada nesta sessão; as outras 6 ficam como **backlog priorizado**.

## Decision — triagem (o que fica pendente)
Ordem por alavanca × custo (dogfood: barato→caro, helper→fiação→campo):

- **#2 ⭐ Frescor (a flagship, maior buraco):** `verified_at:` + gate **STALE** no `kg-radar.sh`.
  **F1+F1.1+F2 IMPLEMENTADAS (2026-07-16)** → `[[onion-adr-kg-freshness-gate-2026-07]]`: F1 = modos
  `--freshness`/`--schema` + selftests; **F1.1** = frescor estende a DEV via `verified_against:` (opt-in),
  **supersedendo o "só PROD"** após o sinal-companheiro `ssot-como-runtime` `REFUTAR` em campo (nó DEV
  `C_CONSOLIDATION_MAP` stale); F2 = fiação `/meta:kg` (v1.3.0) + doutrina a seção na KB + semeadura.
  283/0. **F3 SUBSUMIDA** (o campo operou a SSOT e o relato substituiu "rodar o radar lá"). Puro dogfood
  SDAAL sobre o core: decisão-própria virou claim → `REFUTES` de campo → `SUPERSEDES`, história reconciliada.
- **#1 schema_version + gate:** `schema_version:` no `meta:`; radar **recusa** na divergência. **F1 FEITA
  junto do #2** (mesma família): `RADAR_SCHEMA="1"`, gate de drift (recusa) + degradê de retrocompat (ausente
  = ⚠, não quebra grafo legado). Teria pego o fork `scripts/kg`↔`kg-radar.sh` no dia 1.
- **#3 Robustez do parser (hardening):** guard de linter no `lint-selftest` reprovando `label:`/`trace:`
  com substring de keyword (`plane:`/`status:`/`impact:`) + regra "campos livres antes dos escalares"
  documentada. Bug confirmado em `kg-radar.sh:64` (awk `line ~ /plane:/` + `sub(/.*plane:/...)` pega a
  última ocorrência por linha). Alternativa maior: parser YAML real mantendo determinismo.
- **#4 `kg migrate` de 1ª classe:** `type→node_type`, flow-map→bloco, planes, `on:`-bool. **Backlog**
  (só quando o schema evoluir de novo).
- **#6 Promover "ledger docs-as-evidência"** como método do modo `map` (classifica docs concorrentes
  canonical/superseded/historical/redundant → nó-KG governante). Desarmou 126 docs no campo. **Docs/método.**
- **#7 Nomear "drive-to-verify"** (verificar claim PROD de alto impacto *dirigindo* o sistema vivo, não
  só lendo — o A/B de-sat ao vivo provou end-to-end) como passo canônico do ciclo KG. **Docs/método.**

Seção 7 do sinal (não testado: `kg-console.sh` a fundo, modo `map` F4, domínio cross-repo, fase-2
semântica por embeddings, escala do radar >1k nós) → informativo/backlog, não acionável.

## Trabalho derivado do 2º sinal rhilo (`ssot-como-runtime`, triado 2026-07-16)
Além da F1.1 (feita), o sinal-operação deixou 2 features de desenho próprio:
- **`kg state`** — projeção de estado-de-trabalho (feito/pendente/próximo), irmão do radar. O adotante
  escreveu um `kg-state.py`. Backlog: um `--state`/`kg-state.sh`. **Desenho próprio.**
- **Cabear KG-first nos loops** (`catch-up`/`warm-up`/`work` consultam o `.kg.yaml` PRIMEIRO, acima do
  git) — o buraco que fez o adotante re-derivar à mão 3×. **Fiação, backlog.**
Doutrina **SSOT-as-runtime** (read→verify→act→write; LLM=VM, .kg.yaml=bytecode) absorvida no ADR.

## Pendente — triagem própria (não desta sessão)
- **Omnibus do gustavo** (`2026-07-16-treino-vertical-colaboracao-produtos`, ainda no inbox): 8 sinais
  (spec→N-artefatos, absorção de skill 3º, retro-as-code, colaborador-visitante+autorização, KB
  colaboração; **KG-SSOT: Sinais 5/6/7** = KG por fronteira de confiança + SSOT com partição de
  visibilidade + gate client-safe determinístico). Entrou aqui só como **evidência convergente** da
  virada SSOT-de-1ª-classe; a triagem completa é passo à parte. Lição da sessão: **ler o conteúdo
  inteiro antes de triar** ([[read-full-content-before-triage]]) — quase descartei por leitura parcial.

## Done nesta sessão
- **#5 [DONE]:** seção "Footguns ao autorar o `.kg.yaml`" na KB `knowledge-graph-sdaal.md` — `on:`→bool
  (YAML 1.1), colisão de keyword-substring, vírgulas finais em flow-maps + ponteiro ao backlog de frescor.
- Sinal triado e movido para `docs/evolution/inbox/_processed/`.

## Next crumb
Quando abrir o ADR do #2 (frescor), lembrar de **costurar o #1** (schema_version) — mesma família
"radar recusa quando a SSOT driftou". Ver KB `[[knowledge-graph-sdaal]]` e o sinal em `_processed/`.
