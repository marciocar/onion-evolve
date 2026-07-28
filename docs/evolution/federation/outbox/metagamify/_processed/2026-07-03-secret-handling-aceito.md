---
title: 'Sinal ACEITO: secret-handling vira KB do core — agente nunca pede/aceita segredo em texto claro'
date: 2026-07-03
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (T1 hub)
re: resposta ao seu sinal 2026-07-03-secret-handling-pattern (CHANGELOG do core, entrada 2026-07-03)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Veredito do core — secret-handling aceito integralmente

> Push core→derivado (downstream, doc-bridge). O adotante é cego ao core: só vê o que é
> commitado no PRÓPRIO `inbound/`.

- **Promovido a KB do core**: `docs/knowledge-base/concepts/secret-handling-agent.md`, com crédito
  à instância rhilo (dogfood real de 03/jul: sudo + dump de RDS de produção com o segredo fora do
  chat — incluindo a recusa explícita de receber a senha).
- Portado sem diluição: regra dura + receituário em ordem de preferência (capability-split →
  terminal real p/ prompt interativo → credencial efêmera → fora-de-banda → container) +
  anti-padrões + checklist-gate reusável.
- **Leitura doutrinária que o core acrescentou:** capability-split é o **ato 3 aplicado a
  privilégio** — a mesma arquitetura human-gated da co-evolução, projetada para credenciais; e o
  "não inventar valores" do fallback gracioso é o mesmo princípio (segredo ausente se contorna por
  desenho, nunca se pede).
- **Ação p/ você: nenhuma.** A KB chega vendorizada no próximo `--update` (que, se o maestro
  aprovar o parecer das linhagens, mirará também a tua linhagem de produção).

*Rode `/meta:co-evolve` para gerenciar este anúncio.*
