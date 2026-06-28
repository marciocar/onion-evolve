---
title: 'Auditoria de fidelidade ao norte (Transformers + SDAAL) — certificação 2026-06-28'
date: 2026-06-28
type: analysis
status: living
authority: certificação read-only (não muta artefatos; fundamenta o PR de higiene SDAAL)
research: 3 auditores em paralelo (SDAAL / tese Transformer-Markdown / coerência pós-migração) + verificação adversarial no fluxo principal
related:
  - ../sdaal/sdaal.md (doutrina SDAAL — alvo da higiene H1)
  - ../knowledge-base/concepts/specification-driven-ai-abstraction-layer.md (KB do padrão)
  - onion-orchestration-ontology-2026-06.md (migração de vocabulário recém-auditada)
  - ../knowledge-base/concepts/onion-relation-vocabulary.md (tese "sem store externo")
---

# Auditoria de fidelidade ao norte — Transformers + SDAAL

> **Pedido do maestro (2026-06-28):** antes de atacar a dívida do ADR de topologia (F3), certificar de forma
> **profunda e auditável** que a base está sólida e fiel ao norte — Transformers + SDAAL, tese "o Transformer
> é o reasoner, o Markdown é o bytecode; não há store externo". Separar ponta-solta-real de dívida-consciente,
> com evidência verificável, **antes** de mexer em qualquer coisa.

## Método

3 auditorias independentes em paralelo + verificação adversarial dos achados duvidosos no fluxo principal
(validação adversarial é insumo, não ordem — refutar falso-positivo com evidência).

## Veredito: ✅ BASE SÓLIDA E FIEL AO NORTE

As 3 auditorias convergem e a verificação confirma.

### Confirmado com evidência
- **Tese consistente** em 5+ lugares canônicos (`sdaal.md:394,707`, `onion-relation-vocabulary.md:6-7`, `graph.md:4`, `meta/graph.md`, ADRs slm/capability) — sem contradição.
- **SSOT gerada íntegra**: `inventory.md` e `graph.md` carimbados "GERADO, não editar"; protegidos por lint HARD (Regra 8 inventário, Regra 19 plugins, Regra 21 graph-sync). Contagens batem (92 cmd, 51 ag, 5 skills, 39 KB).
- **Store externo: ZERO violações.** Triple-store/RDF/registry-central **explicitamente rejeitados**; embeddings/dedup **deferidos com gatilho** (radar, não esquecimento).
- **SDAAL — invariantes cumpridos**: consumidor chama a abstração (`getTaskManager`/`getForge`/`getDeIdentifier`), nunca provider direto (0 violações em comandos); factory+detector+Null Object nas 3 abstrações; Regra 12 guarda contra MCP-provider-direto no frontmatter.
- **Migração de orquestração (#205): limpa.** 0 refs vivas fora de histórico/fixtures; 0 links quebrados.

### Pontas soltas reais encontradas (baixa severidade, higiene) — RESOLVIDAS neste ciclo
1. **Limite de tamanho universal vs realidade.** `sdaal.md` declarava "regra dura: 400 linhas" — mas (a) o lint não a enforçava e (b) a tabela §7 (núcleo ≤200-300) estava abaixo do real (`factory` tm 465, `types` 439). **A contradição era a ponta solta**, não os adapters. **Resolução (decisão do maestro):** critério **por tipo** baseado na realidade medida — núcleo ≤500, adapter de provider ≤900 — + guarda **SOFT** no lint (Regra 5 estendida a `utils/`), tornando o débito visível em vez de invisível. Crescimento orgânico com critério = dogfood.
2. **`task-manager/adapters/none.md` ausente.** Único outlier (forge e de-id tinham o arquivo); template exige. **Resolução:** criado, espelhando forge. As 3 abstrações agora simétricas.

### Dívida consciente documentada (NÃO é ponta solta — é o F3, com gatilho)
- **ADR de topologia**: metadados incoerentes (título "RASCUNHO" + `status:accepted`); promoção draft→adr + ancorar "nó sumarizador"→synthesizer + 4 refs cruzadas. Registrado no review #154 com gatilho. Outros ADRs-draft (`strategy-layer`) estão `status:proposed` (apropriado).

### Falso-positivo refutado (validação adversarial)
- Um auditor classificou o limite-400 como "violação dos adapters". Reenquadrado: nada enforça o limite, então os adapters não violam regra alguma — a falha era do **contrato doutrinário** (afirma regra que não vale). O alvo do fix mudou de "refatorar 5 adapters" (caro, desnecessário) para "alinhar a doutrina + dar critério guardável" (barato, correto).

## Lição (dogfood)

O gate determinístico (lint/selftest) passava 0/0 o tempo todo — porque os achados eram **semânticos/doutrinários**, não sintáticos. A **auditoria independente + verificação adversarial** é o que pega isto. E a régua certa não era "dobrar a doutrina à conveniência" (suavizar cego) nem "honrar cega a regra dura" (refatorar tudo) — foi **crescimento orgânico com critério por tipo**, baseado em evidência medida e tornado visível por uma guarda. Adaptação consciente, sem orgulho.
