---
title: "Revisao — skill wizard onion-publish (Fase 3, self-review)"
date: 2026-08-24
branch: feat/onion-publish-skill
reviewer: "self-review (autor) — skill de CONDUCAO baixo-risco (delega ao helper ja revisado no #665) + propagacao mecanica de contagem"
reviewed_diff_sha256: deca2f8459df0171e708921ac53617318d421984b3d76df822071a490d37ea2c
findings_total: 2
findings_real: 0
verdict: APROVADO
tokens: 900
duration_min: 3
---

# Residuo de revisao — REGRA 56 (self-review)

A skill `onion-publish` conduz a publicacao do marketplace; NAO reimplementa nada — delega ao
`materialize-marketplace-repo.sh` (ja revisado adversarialmente no PR #665, incl. as guardas de moat
C1/C2). Baixo risco: a determinismo mora no helper; a skill so orienta e para no push (human-gated I3).

- **Nao pusha / nao publica moat?** SIM por construcao: a skill instrui parar no checkpoint do push
  (o helper comita no alvo, o maestro pusha); a REGRA 61 + a 2a guarda ja barram o moat no helper.
- **Core-only (nao vira meta-fabrica publica)?** SIM: onion-publish NAO entra em nenhum manifesto de
  plugin — publicar e ato da FONTE (role:source, guardado no fluxo). Distribui-la seria dar a fabrica.
- **Propagacao de contagem 11→12 correta?** SIM: SSOT (inventory.md) regenerada; as 7 superficies vivas
  alinhadas; notas HISTORICAS (resync/102 comandos) preservadas de proposito.
- **allowed-tools coerente?** SIM: AskUserQuestion + Read + Bash escopado (utils/marketplace/*,
  onion-version, git rev-parse, claude plugin validate) — sem Write nem push.

**Veredito: APROVADO** — condução fina sobre helper ja provado; sem lógica nova a arriscar. Fecha a
Fase 3. Resta so a Fase 5 (repo publico marciocar/onion-plugins), human-gated por I3 (o maestro cria+push).
