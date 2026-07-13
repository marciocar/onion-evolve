---
type: sinal-campo
from: dogfood do pre-pr da branch docs/onion-guardrails
date: 2026-07-13
status: para triagem do core (fix | feature | backlog)
origem: pre-PR canônico (engineer:pre-pr) rodado na promoção da KB onion-guardrails
---

# 📬 Sinal de campo → core: 2 (+1) achados de higiene do dogfood do pre-PR

Rodar o fluxo canônico `pre-pr → pr` num caso **docs-only nascido de discussão** expôs costuras do
próprio core. Nenhum bloqueia a promoção da KB — são débitos/lacunas de higiene pra triar.

## Achado 1 — `status: candidato` não está no enum de `code-standards.md §2.6`
O `branch-metaspec-checker` apontou: o frontmatter de KB documentado em `code-standards.md §2.6` lista
`status: <active | historical | draft>`, mas **duas KBs já usam `candidato`** por uso repetido
(`authorization-layers-intake-vs-execution.md` e agora `onion-guardrails.md`). A convenção está sendo
**estabelecida por uso, não pela constituição**.
- **Proposta:** atualizar `code-standards.md §2.6` para incluir `candidato` (semântica: *"entra pra ganhar
  core por uso, não por estar pronta"*), fechando o gap convenção-emergente ↔ constituição-escrita.
- **Classe provável:** fix (docs de meta-spec).

## Achado 2 — o link-check determinístico só cobre `docs/evolution/`
O `branch-test-planner` observou: o único gate de link-check determinístico (`check_evolution_links` em
`lint-artifacts.sh`) escopa **apenas `docs/evolution/`** — não `docs/knowledge-base/` nem
`docs/discussions/`. Um link relativo quebrado numa KB **não é pego** pelo gate mecânico (só por revisor
semântico). É a mesma família do gap que a checagem #2/A2 da discussão guardrails achou: *falta guardrail
determinístico onde a doutrina promete integridade*.
- **Proposta:** estender o link-check a `docs/knowledge-base/` (ao menos), tornando-o o guardrail
  determinístico de integridade de link de KB. Casaria com a categoria ONION-R1 (integridade de SSOT).
- **Classe provável:** feature (novo check no lint) — gated por gatilho.

## Achado 3 (secundário) — `/engineer:pr` presume `feature/*`
O passo 2 do `/engineer:pr` hardcoda `git checkout -b feature/[descricao]`. Uma mudança **docs-only**
legitimamente vive em `docs/*` (como esta), e o comando não trata esse caso limpo. Não bloqueou (contornei),
mas **o comando presume feature-first** e ignora que GitFlow tem `docs/*`/`hotfix/*`/`release/*`.
- **Proposta:** `/engineer:pr` resolver o prefixo da branch pelo tipo de mudança (ou aceitar a branch atual
  se já for de um prefixo GitFlow válido), em vez de forçar `feature/*`.
- **Classe provável:** fix/feature (comando).

---
*Sinal gerado durante o dogfood de promoção de `onion-guardrails` (as 3 checagens do core estão fechadas no
registro de discussão). Entregue no próprio `inbox/` do core para triagem via `/meta:co-evolve`.*
