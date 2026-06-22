# 🎨 Design Context (vertical de design)

> **Status: PROVISÓRIO** (tensão T1 do plano `transient-cooking-pebble`). Este contexto está sendo
> incubado como candidato a **4º contexto de domínio peer** (ao lado de business/technical/compliance).
> A promoção formal a peer na meta-spec (`architecture.md §1.3/§7/§8`) só ocorre **após** evidência
> empírica de **ritmo distinto** via `/meta:context-freshness`. Até lá, vive aqui sem cravar a constituição.

## O que é

A **SSOT viva da identidade visual** — a fonte de verdade que tanto a IA (artifact-design, agentes) quanto
o código (Tailwind, componentes) quanto a geração de material (apresentações, brand-book) leem para produzir
artefatos **on-brand** e consistentes. É o **spec-as-code aplicado ao design**: os tokens são a spec
(fonte de verdade); CSS/componentes/material são saída gerada.

## Princípios

- **SSOT = tokens W3C/DTCG abertos** (`*.tokens.json`, `$value`/`$type`) — anti-lock-in no nível do dado.
  Ferramentas (artifact-design, Figma, Penpot, Style Dictionary, Tailwind) são **produtores/consumidores
  plugáveis** que leem/escrevem a SSOT, nunca a *são*.
- **A IA gera; o gate determinístico decide.** Contraste WCAG, resolução de referências e conformidade de
  escala são calculados em código (não "achados" pelo modelo). Logos/pixels ficam fora da SSOT, sob gate humano.
- **Cascata de camadas** (`core → semantic → brand → product → mode`): 1 core + N deltas esparsos =
  multi-brand / white-label / escopos-por-produto **sem duplicar**.

## Estrutura

```
design-context/
├── index.md                      # hub navegável + frescor (Última Atualização)
├── foundations/*.tokens.json     # primitivos brand-agnostic (a paleta crua)
├── semantic/*.tokens.json        # papéis (surface, on-surface, action, danger) → referenciam foundations
├── brands/<brand>/*.tokens.json  # override por marca (esparso; multi-brand)
├── products/<product>/*.tokens.json  # override por produto (herda brand)
├── modes/<light|dark|hc>.tokens.json # override por modo
├── system/components.md          # padrões de UI (prosa AI-context)
├── decisions/                    # ADRs de design (subcamada decisional, §8.4)
└── governance/accessibility-rules.md  # SSOT das regras WCAG que o gate consome
```

> No **framework** (este repo) o contexto traz a identidade do **próprio Onion** (dogfood). Num projeto
> **adotante**, é populado pela adoção (`/meta:adopt`) e pelo comando `/design`. Protocolo de geração e
> ciclo de vida (CRUD+, frescor): herda `architecture.md §8` e `/meta:context-freshness`.
