---
title: "Plano de promoção — Onion Guardrails / R15 da discussão ao core"
category: discussion
status: plano-para-execucao-gated
date: 2026-07-12
branch: discuss/guardrails-nemo-lens
depende_de: [kb-spine-onion-guardrails.md, taxonomy-onion-r.md, r15-untrusted-content-provenance.md, prototype/README.md]
veiculo_recomendado: /engineer:plan (worklog faseado) em feature/onion-guardrails
---

> **Ainda é PLANO, não execução.** Nada aqui muta o core. A execução cruza a invariante de isolamento do
> SEED — é a decisão do maestro. Este doc diz *o quê, em que ordem, com que gate*.

# Plano de promoção — Onion Guardrails + R15

## Invariantes a preservar (asserção antecipada — Fase 0 valida)

1. **Guardrail é transversal, NÃO 4ª dimensão peer.** As três permanecem produto/engenharia/compliance.
   Guardrail é como Task Manager / Forge: uma camada que atravessa as três. (CLAUDE.md alerta contra inflar
   dimensões — o `@metaspec-gate-keeper` valida isto na Fase 0.)
2. **Consolidação transversal, NÃO vertical nova.** Zero manifesto/plugin/marketplace `onion-guardrails`. Só
   KB + helpers + wire-in. (Conclusão da pesquisa de mercado.)
3. **Motor determinístico + gated + estrutural — nunca classificador probabilístico** no caminho crítico.
4. **Fail-safe / deny-by-default** em toda decisão nova (padrão a2a-verify / trust-topology).
5. **Isolamento até o merge.** O trabalho vive numa feature branch; nada no `main` até o PR passar.

## Escopo

**DENTRO:** KB `onion-guardrails` (conceito + taxonomia como referência); 2 helpers determinísticos
(`onion-untrusted-wrap.sh`, `onion-effect-gate.sh`); wire-in nos canais C1/C2/C3; constituições R15.2/R15.3b
nos agentes consumidores; **cobertura de selftest** (guarda das guardas); reconciliação de SSOT.

**FORA (deferido, decisão separada):**
- **Superfície `/meta:guardrails`** — a questão índice-de-leitura vs DSL ainda está aberta (fio #4). NÃO entra.
- **Relabel ONION-Rn de TODOS os gates existentes** nos próprios arquivos — a KB referencia os read-paths sem
  editar cada helper; o relabel amplo é um docs-pass opcional posterior.
- **Fios #2 e #5** (auditoria de placement; FP/FN versionado) — pesquisa, não entrega.

## Decisões que o maestro fecha ANTES de executar

| Decisão | Opção proposta | Alternativa |
|---------|----------------|-------------|
| Home dos helpers | `.claude/utils/guardrails/` (novo dir — lugar único à camada) | `.claude/utils/trust/` (SDAAL de confiança **já existe** — R15 é o mesmo campo semântico: `verified-crypto`/`verified-semantic`, a2a-verify/trust irmãos) **⚠️ avaliar antes** · `.claude/utils/federation-transport/` (só C1/C2, pior p/ C3) |
| Constituição R15.2/R15.3b | **fragmento único** em `.claude/commands/common/prompts/untrusted-content-provenance.md` (padrão SSOT já usado, ex. `task-manager-provider-detection.md`) — referenciado, não copiado | colar o bloco em cada consumidor (**anti-DRY — rejeitado**) |
| Taxonomia (148 vetos) | KB de referência companheira, linkada do conceito | apêndice do próprio conceito |
| R15.3a nos helpers reais | **KB-only** (nomeia via read-path, sem tocar a2a-accept/co-deliver) | comentário nos .sh (churn desnecessário) |
| Vínculo com a branch | **feature branch nova** off main via `/engineer:plan`; docs da discussão ficam como registro | reusar a branch de discussão (mistura design + entrega) |

> **Decisão de home (aberta):** `.claude/utils/trust/` já existe (interface/factory/detector/adapters — Trust SDAAL, RFC-0003). R15 trata do MESMO campo (confiança de origem). Antes de criar `utils/guardrails/`, decidir se os helpers R15 são **irmãos do trust** (mesmo dir) ou uma camada distinta (guardrails ⊃ trust). Colisão de nome/escopo é risco real — resolver na Fase 0.

## Fases (menor-risco/reversível → maior-risco)

### Fase 0 — Gate arquitetural (read-only, ANTES de qualquer código)
Rodar `@metaspec-gate-keeper` sobre a proposta: valida invariantes 1–3 (transversal, sem vertical, motor).
**Gate:** veredito CONFORME. Se INCONCLUSIVO/REJEITADO → parar e reconciliar. **Risco:** nulo. **Reverter:** —.

### Fase 1 — KB (docs puros, zero mudança de comportamento)
- `kb-spine-onion-guardrails.md` → `docs/knowledge-base/concepts/onion-guardrails.md`.
- `taxonomy-onion-r.md` → KB de referência linkada.
- Marcar toda reivindicação "cobre LLM0X" como **provisória**.
**Gate:** `lint-artifacts` (convenções de KB) + `/meta:inventory` (contagem de KB muda → SSOT) + `/docs:build-index`.
**Risco:** baixo. **Reverter:** remover os arquivos.

### Fase 2 — Helpers determinísticos (aditivo, sem wire-in, COM selftest)
- Mover `onion-untrusted-wrap.sh` + `onion-effect-gate.sh` → o dir decidido na Fase 0 (`utils/guardrails/` vs `utils/trust/`).
- **Escrever um runner novo no `lint-selftest.sh`** (ex.: `kind=wrap` / `kind=gate`, análogo a `run_merge_fixture`)
  — ⚠️ **correção da revisão:** o formato de fixture atual (manifest.tsv, kinds lint|fix|contract|merge|kg)
  **não cobre** um harness standalone que invoca um `.sh` via CLI e assere stdout/exit. Isto é **trabalho de
  código no script de validação do core**, não só "adicionar fixtures". Os `test-*.sh` (agora 9/9 cada) viram
  a base desse runner.
**Gate:** `lint-selftest` verde com o runner novo. **Risco:** **médio** (edita o próprio gate — a guarda das
guardas). **Reverter:** remover runner + helpers.

### Fase 3 — R15.3a: nomear o que já existe (docs, zero código)
Na KB, rotular `a2a-accept.sh:8` e `co-deliver.sh:12` como membros ONION-R15.3a (efeito-gate estrutural
existente), com read-path. **Gate:** `lint`. **Risco:** nulo. **Reverter:** editar a KB.

### Fase 4 — Wire-in R15.1 (estrutural; SÓ C1/C2)
- Cercar o conteúdo no ingresso: `a2a-accept` (C1) e `co-deliver`/`co-relay` (C2) — **scripts bash reais com
  ponto de ingestão programável** (`cat | wrap`).
- ⚠️ **Correção da revisão — C3 é qualitativamente diferente:** `adopt`/`reverse-consolidate` leem repo alheio
  via a tool nativa `Read` do Claude Code — **não há hook de ingestão único** a interceptar. A cerca
  estrutural R15.1 **NÃO se aplica a C3**. C3 é coberto por R15.2 (constituição) + R15.3b (gate de efeito),
  não pela cerca. (Reflete o design r15 §3/§7, já corrigido.)
**Gate:** `lint-selftest` + **re-rodar o dogfood comportamental** (os 12 subagentes) contra o caminho C1/C2 já
cercado — confirmar que a obediência à injeção segue 0%. **Risco:** médio (muda o input dos agentes).
**Reverter:** desfazer o wire-in (o helper fica).

### Fase 5 — Wire-in R15.2 + R15.3b (gated; muda comportamento dos consumidores)
- Criar o **fragmento único** de constituição (`common/prompts/untrusted-content-provenance.md`) e
  **referenciá-lo** (não copiar) nos **comandos** consumidores. ⚠️ **Correção da revisão:** o alvo são
  **comandos** — `co-evolve.md`, `adopt.md`, `reverse-consolidate.md`, `co-deliver.md` (verificado: **nenhum
  agente** em `.claude/agents/` referencia `inbound/`; só comandos). A cláusula "agentes que leem inbound/"
  do rascunho anterior não tinha alvo real.
- Invocar `onion-effect-gate.sh` antes de verbos de execução em `adopt`/`reverse-consolidate`.
**Gate:** dogfood comportamental (re-run) + `@metaspec-gate-keeper` (constituição consistente com REGRA
ZERO/R9). **Risco:** médio. **Reverter:** reverter a referência ao fragmento (o fragmento fica).

### Fase 6 — Reconciliação de SSOT + PR
`/meta:inventory` · `/meta:graph` · contagens do CLAUDE.md · `/docs:build-index`. Gate mecânico completo
(lint + selftest + inventory) verde localmente → `/engineer:pr`.
**Gate:** CI verde (o mesmo gate determinístico). **Risco:** baixo. **Reverter:** o PR não mergeia.

## Gates transversais (toda fase)
- **Gate mecânico** (`lint-artifacts` + `lint-selftest` + `inventory`) ao fim de cada fase — o dogfood
  determinístico. Drift de SSOT é auto-veto (ONION-R1): a própria camada de guardrails tem que passar nos
  guardrails do core.
- **Dogfood do artefato** após Fases 4–5 — invocar e observar (comportamental), não só lint/spec.
- **Fail-safe review**: cada decisão nova nega-por-default.

## Rollback
Cada fase é reversível isoladamente (a ordem menor-risco-primeiro garante que docs/helpers aditivos precedem
o wire-in). Se a Fase 4/5 regredir o dogfood, reverte-se **só o wire-in** — a KB (1–3) e os helpers (2) ficam,
pois não mudam comportamento. Rollback total = reverter o PR (nada foi ao `main` sem ele).

## Veículo de execução
`/engineer:plan` cria o worklog faseado em `feature/onion-guardrails`, com estas 6 fases como as fases do
plano. As sessões de discussão (`docs/discussions/guardrails-nemo-lens/`) ficam como **registro de design**
(rastreabilidade: da pesquisa → taxonomia → R15 → promoção). O maestro dispara quando decidir sair do modo
discussão.
