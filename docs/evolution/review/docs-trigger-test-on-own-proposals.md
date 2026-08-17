---
branch: docs/trigger-test-on-own-proposals
pr: 627
date: 2026-08-17
reviewed_diff_sha256: 64726f2801913d83483c904021a1bd9439d5005c5407b85d5a1f124633c05d19
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CONFORME-COM-PROPOSTA-PROPRIA-REPROVADA
reviewer: o Teste do Gatilho aplicado à MINHA proposta — reprovou; e este PR é, ele mesmo, a medição do CI que eu havia afirmado sem provar
REVISOU: true
---

# Resíduo — `docs/trigger-test-on-own-proposals`

**Achado — propus mecanismo sem rodar o teste que a casa exige.** Depois de três incidentes
baratos de branch-base, ofereci construir uma guarda. O Teste do Gatilho reprova em três
frentes: dano auto-revelador (mecanismo é para defeito silencioso), cura que não distingue
acidente do padrão intencional de PR empilhado (seria o `--no-verify` de amanhã), e
precedente medido contra (3 curas reprovadas por cobrirem 1/9). A diretriz de rodar esse teste
**antes de propor** existe como memória desde 2026-08-05 — logo o problema é aplicação, não
conhecimento, e o gatilho eficaz seguiu **social**.

**Coerência verificada:** não criei mecanismo para isto tampouco. Uma guarda que me obrigasse
a rodar o Teste do Gatilho seria, ela mesma, uma proposta que não passa pelo teste. Registro é
a cura mais fraca, e está dito no diário que a escolhi por ausência da forte.

**Este PR é também um instrumento.** Nasceu de `main` e toca apenas `.claude/diary/` — logo
mede a divisão do CI que eu afirmei sem provar: se `selftest` **não** aparecer nos checks, os
~49s do gate deixam de ser projeção; se aparecer, meu filtro de path está errado e o PR que
registra a lição é o que a refuta. As duas leituras estão declaradas ANTES do resultado.
