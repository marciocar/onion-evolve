---
title: 'Sinal: padrão "vertical de projeto" (hub+help+bootstrap) + ingestão multimídia'
date: 2026-07-13
from: gustavo-pulga (consumidor / workspace Betahauss)
to: core (onion-evolve)
type: signal-feedback
flow: upstream (consumidor → core)
evidencia: repo privado marciocar/projeto-betahauss-tornak (docs/tornak/)
---

# Sinal ao core — 2 padrões que emergiram do dogfood da vertical "Tornak"

Contexto: dogfoodei o Onion para produzir uma **vertical de consultoria de cliente** (Betahauss × Tornak)
— mapa KG SDAAL, skills de proposta lendo um book (SSOT), plugin Cowork, HTMLs premium. No caminho,
dois padrões se mostraram **generalizáveis para o core**.

## Sinal 1 — Padrão "vertical de projeto" = hub homônimo + help contextual + book-resolver + bootstrap
Repliquei o **próprio padrão `onion`** (skill/agente/comando orquestrador) para um projeto-cliente:
- uma **skill-hub nomeada como o projeto** (`tornak`) que **roteia** para as outras e **gere/valida o
  book/SSOT** (criar/editar/atualizar/validar fichas, nunca inventando, mostrando antes de salvar);
- **help contextual sem parâmetros** em toda skill (sem input → o que faz + campos + exemplo + próximos
  passos lidos do estado ao vivo), espelhando `engineer/help.md`;
- um **bootstrap** (`bootstrap-new-project.sh` + template de hub parametrizado) que scaffolda um projeto
  novo do zero (book skeleton + skills + hub homônimo).

**Proposta ao core:** promover isso a **convenção/ferramenta de 1ª classe** — p.ex. um `/meta:create-vertical`
(ou extensão do `/meta:adopt`) que gera, para qualquer projeto adotado, o **hub homônimo + help + resolver
de SSOT + bootstrap**. É o mesmo DNA do `onion`, generalizado; hoje cada adotante reinventa à mão.

## Sinal 2 — Ingestão multimídia ("conhecer uma documentação") como capacidade SDAAL
No Tornak, a fonte mais rica era um **deck em PDF** (só a análise slide-a-slide textual foi usada). A
"mágica do SDAAL" pede uma técnica de **ingestão de documentação multimídia**: PDF/PPT slide-a-slide,
imagens, **frames de vídeo/GIF** → **markdown estruturado** que o KG e as skills consomem. É recorrente
em qualquer engajamento real e deveria ser **ferramenta do core** (dogfoodável), não trabalho manual.

## Sinal 3 (menor) — Packaging: adoção fica sem `.claude-plugin/marketplace.json`
Ao montar plugins numa adoção, o repo falha o próprio lint por **ausência de `marketplace.json`** e **não
há gerador** no subconjunto vendorizado (contornei à mão). Candidato a fix/gerador no core.

---
Sem urgência. Triagem/decisão é do core (fix/feature/backlog). Feliz em detalhar qualquer um.

---

## 🗂️ Triagem do core — 2026-07-14

- **A1 — padrão vertical-hub (`/meta:create-vertical`): FEATURE grande → DESIGN-FIRST.** É o DNA do `onion`
  generalizado; alto valor (todo adotante reinventa à mão). Merece um design pass (ADR/discussão), não
  implementação apressada. **Acopla com o B3** (design-vertical) do sinal 2026-07-14 — são a mesma ideia grande.
  Backlog priorizado.
- **A2 — ingestão multimídia (PDF/PPT/vídeo → markdown SDAAL): FEATURE → RESEARCH-FIRST.** Nova capacidade
  recorrente; precisa de pesquisa da técnica de ingestão antes de virar ferramenta. Backlog.
- **A3 — gerador de `marketplace.json` ausente na adoção: FIX (verificado).** O core tem `assemble-plugin.sh`
  mas não um gerador de `marketplace.json` no subconjunto vendorizado. Backlog de fix concreto.
