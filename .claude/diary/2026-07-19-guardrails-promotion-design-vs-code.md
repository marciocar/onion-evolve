---
date: 2026-07-19
instance: onion-evolve
type: learning
classification: collective
tags: [guardrails, r15, promotion, dogfood, design-vs-code, structural-over-gated, faseado]
affects: [meta, engineering, security]
breadcrumb_for: []
share_with: [granaai, metagamify]
next_recommended: "Guardrails no core: a superfície /meta:guardrails (índice de leitura vs DSL) segue GATED/fora de escopo (fio #4 do promotion-plan). Se um comando de research/produto passar a ingerir conteúdo externo, referenciar common:prompts:untrusted-content-provenance (não recopiar). Ao evoluir a2a-accept/co-relay, preservar o invariante 'a2a-accept nunca inlineia o corpo' — é o que faz C1 ser R15.1-by-construction."
review_after: 2026-10-19
conflict_class: static
---

## Signal
A camada **Onion Guardrails / R15** foi promovida ao core em **6 fases** (PR #452, `/engineer:plan` faseado
retomável). O aprendizado durável não é "guardrails existem agora" — é **o que rodar o código real revelou
contra o design**, e a doutrina que isso afiou. Padrão master de dogfood confirmado: **plano/spec dão falsa
confiança; só invocar o artefato revela a verdade** — e aqui a verdade **refinou o design em ≥3 pontos**.

## Evidence
- **F4 — "estrutural > gated" ≠ "cercar todo transporte".** O design dizia "a2a-accept/co-deliver ganham a
  linha de wrap". O código real: **`a2a-accept` NUNCA inlineia o corpo não-confiável** (só referencia) — já é
  R15.1-compliant **por construção**, mais forte que cercar, zero código. E **`co-relay` copia verbatim** com
  dedup/idempotência I3-crítica — cercar-na-cópia quebraria invariantes tateados; a proteção do corpo migrou
  para **read-time (R15.2)**. Lição na KB `onion-guardrails.md §4.2`: preferir *impossível-por-construção*, não
  emendar cega em todo `cp`.
- **F5 — consumidores verificados vs listados.** R15.2/R15.3b vai em **co-evolve + adopt + reverse-consolidate**
  (ingerem untrusted), **não** em co-deliver/co-announce (produtores core-autorados) — o plano listava os
  produtores; o grep/leitura corrigiu. `common:prompts:untrusted-content-provenance` (fragmento SSOT,
  referenciado não-copiado).
- **F1 — anti-drift por construção.** Catálogo de 148 vetos entrou no core **sem violar o próprio ONION-R1**:
  números de linha rebaixados → read-path a nível de arquivo + string de veto greppável + escopo
  `/meta:kb-freshness`. Sem número perpétuo = nada a driftar.
- **Dogfood comportamental 3/3, injeção 0%.** Um dos agentes **executou o `onion-effect-gate.sh` real** e
  gateou 3 comandos maliciosos (push p/ remote externo, npm postinstall, `rm -rf ~/.claude/`); os outros dois
  reportaram injeção (inbox direto + "passo de processo" sutil) como dado. Confirma o protótipo (75%→0%) com a
  constituição no core real.
- **Gate mecânico** verde em cada fase (selftest 321→0 falhas com `run_guardrails_selftests`); PR #452 CI verde.

## Next crumb
Ao promover qualquer camada da discussão ao core: **rode o código real ANTES de fiar o design** — o design
assume pontos de ingestão/consumo que o código pode já resolver (melhor) ou não ter. A régua "estrutural >
gated" é sobre **impossível-por-construção**, não sobre aplicar o mesmo mecanismo em todo lugar. Faseado
menor-risco→maior (docs→helpers→naming→wire-in→comportamental) permitiu que cada refinação fosse achada e
registrada sem quebrar transporte vivo. Superfície `/meta:guardrails` segue gated. Doutrina completa:
`docs/knowledge-base/concepts/onion-guardrails.md` + `onion-r-taxonomy.md`.
