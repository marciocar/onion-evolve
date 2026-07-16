---
title: 'Onion Pessoal — USANDO Dogfood KG-SSOT SDAAL: relato de campo N=1 + gap de uso indocumentado'
date: 2026-07-16
from: discuss/onion-pessoal-marcio (sessão no notebook do Marcio)
to: core (sala de design — quem trabalha em KG SDAAL)
re: docs/discussions/onion-pessoal-marcio/USAGE.md · ~/onion-pessoal (privado)
type: field-signal
status: relato + assess — não-bloqueante
---

# Onion Pessoal — USANDO Dogfood KG-SSOT SDAAL (relato de campo N=1)

> **Para quem trabalha em KG SDAAL:** isto é o método rodado no domínio mais sensível que existe — a **vida
> de uma pessoa**. **Sem dado pessoal aqui** (soberano, no repo privado); só o relato **estrutural**.

## O que fizemos aqui (o arco)

- **Discussão P1–P5** (verticais · reconciliação · fronteira · privacidade · inferência) → mergeada (#343).
  Método: pesquisa citada → derivação `fonte≠derivação` → proto executável (`.kg.yaml` + `kg-radar`).
- A **lente Aristóteles+Hegel** graduou: KB `transfer-heuristic-aristotle`, fiada no `/meta:adopt`.
- **Intent aceito** (Marcio = 1º adotante-de-pesquisa N=1); plano **dogfood-first** F0→F3.

## O achado de campo — o KG SDAAL FUNCIONA numa vida

- **F0 fechado** (vertical Trabalho, em `~/onion-pessoal` privado): o KG SDAAL reconciliou **declarado (DEV) ×
  vivido (PROD)** e **achou atrito real e acionável** — 2 `SUPERSEDES` + 1 `REFUTES` deixado de propósito →
  `exit 1` **honesto**. **NÃO foi grafo bonito e vazio.**
- **Consequência para o KG-SSOT SDAAL:** prova que o método transfere para **domínio não-código / não-negócio**
  (a vida N=1), mantendo a régua — Aufhebung *append-mostly*, confronto DEV×PROD, radar determinístico. É o
  mesmo motor de reconciliar negócio/técnica/compliance de uma org, aplicado a um indivíduo.

## O gap que a pergunta do maestro revelou (o sinal principal)

- Perguntado *"como eu uso isso no dia a dia no notebook?"*, descobrimos que o **baseline de uso está
  INDOCUMENTADO**. O `interface-state-of-art` pesquisa a interface **rica** (telemetria/padrões), mas ninguém
  escreveu o **"como usar" pé-no-chão**: `cd ~/onion-pessoal && claude` → conversar → o `.kg.yaml` é mantido
  pela conversa → `kg-radar` é a lente. **O próprio criador precisar perguntar É o dado.**
- **Escrevemos a nota:** `docs/discussions/onion-pessoal-marcio/USAGE.md` — candidata a **cross-link no
  `interface-state-of-art`** (o baseline conversacional **antes** da interface rica).

## Guardrails (inalterados)

- **Privacidade:** o dado real **nunca** sai do repo privado `~/onion-pessoal`; F0 dogfooda a P4 no passo um.
- **Intra-órbita:** prova **método**, não **mercado** (`Q_COLD_ADOPTER` aberto). Braço de pesquisa, não produto.

## Pedido (assess, não-bloqueante)

Registrar: (1) F0 **validou o KG SDAAL num life-KG N=1** — evidência para a linha KG SDAAL; (2) o **baseline de
uso** precisa da nota pé-no-chão (feita: `USAGE.md`) **linkada** no `interface-state-of-art`, antes da interface rica.

---

## Nota de entrega (2026-07-16) — por que "não chegou" à 1ª leitura

Este sinal foi mergeado em `origin/main` (PR #379), mas **não apareceu** na primeira leitura do core porque
o **checkout local** `/home/marcio/onion-evolve` (branch `main`) estava **3 commits atrás** de `origin/main`.
Worktrees compartilham o `.git` mas têm **working trees separados** — um merge no GitHub **não** atualiza um
checkout que não deu `pull`. **Não foi falha de doc-bridge** (é o mesmo repo, não cross-repo — doc-bridge é
para repos diferentes). **Entregue** via `git pull --ff-only` no checkout do core, a partir da sessão do
worktree (o untracked em curso lá sobreviveu intacto). **Lição:** sinal no mesmo repo só "chega" ao core
quando o checkout de `main` **sincroniza com `origin/main`** — vale um lembrete no ritual de `/meta:co-evolve`
(fazer `git fetch`/`pull` antes de ler o inbox).

## Triagem do core (preencher na recepção)

- **Status:** _pendente_
- **Roteamento:** _(registrar F0-validado na linha KG SDAAL; decidir cross-link USAGE↔interface-state-of-art)_
