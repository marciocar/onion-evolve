---
title: "Proposta: padronizar o campo color dos agentes na paleta do Claude Code (card SAC-409)"
date: 2026-11-21
from: onion-curation
to: onion-evolve (core)
type: doctrine-proposal
family: pratica
request: "Core → curadoria (2026-11-21): padronizar o campo color dos 51 agentes do core na paleta do Claude Code — medir os agentes, a paleta suportada pela versão atual, propor o mapa por categoria. Sinal pelo co-relay."
reviewed_for_public: true  # relido pelo core em 2026-11-22 como publicado: só a forma (contagens, paleta, mapa proposto), sem cliente, pessoas, segredo nem incidente
---

# Proposta — padronizar o `color` dos agentes por categoria

A curadoria **propõe**; o core sela. Nada aqui é selado.

## 1. Medido — os 51 agentes e o `color` hoje

`.claude/agents/` tem **60 arquivos .md**; menos os **9 `README.md`** de categoria = **51 agentes**
(bate com o card). Nove categorias: development 21, product 10, compliance 6, git 6, meta 6, testing 4,
review 3, deployment 2, research 2.

O `color` está **inconsistente** — não mapeia categoria e usa valores fora da paleta:

| valor | nº agentes | na paleta? |
|---|---|---|
| blue | 13 | ✅ |
| cyan | 8 | ✅ |
| yellow | 6 | ✅ |
| red | 5 | ✅ |
| purple | 5 | ✅ |
| orange | 4 | ✅ |
| green | 4 | ✅ |
| **teal** | 5 | ❌ fora da paleta |
| **black** | 2 | ❌ |
| **maroon** | 1 | ❌ |
| **indigo** | 1 | ❌ |
| **`[cor da categoria]`** (placeholder não preenchido) | 2 | ❌ (vaza do molde do `agent-creator`) |
| **(sem campo `color`)** | 10 | ❌ ausente |

**~21 dos 51** estão fora da paleta, com placeholder, ou sem cor — caem no default (sem cor) em silêncio.
O gate `.claude/validation/agent-frontmatter-keys-check.sh` confere a **chave**, não o **valor** (não há
enum de paleta) — por isso o desvio não é pego.

## 2. A paleta suportada (fonte: o bundle da versão instalada)

A versão instalada (Claude Code 2.1.330) define o mapa de cores de agente **literal**:

```
{red:"red", blue:"blue", green:"green", yellow:"yellow",
 purple:"magenta", orange:"colour208", pink:"colour205", cyan:"cyan"}
```

**A paleta válida é de 8 valores:** `red · blue · green · yellow · purple · orange · pink · cyan`
(purple rende magenta; orange e pink são cores 256). Qualquer outro valor (teal, black, maroon, indigo,
placeholder) **não** está no mapa e não pinta. *(Medido no bundle; se a versão subir, reconferir o mapa.)*

## 3. Proposta — mapa categoria → cor

São **9 categorias e 8 cores**, então **um par compartilha** (a restrição honesta, como o valor único do
backlog). Recomendo `git` + `deployment` juntos (ambos entrega/ops):

| categoria | nº | cor | terminal | razão |
|---|---|---|---|---|
| development | 21 | **blue** | blue | núcleo de engenharia, a maior |
| testing | 4 | **green** | green | verde = passa |
| review | 3 | **yellow** | yellow | atenção/revisão |
| compliance | 6 | **red** | red | segurança/para |
| meta | 6 | **purple** | magenta | o framework sobre si |
| product | 10 | **cyan** | cyan | produto/descoberta |
| git | 6 | **orange** | colour208 | versionamento/entrega |
| deployment | 2 | **orange** | colour208 | entrega/ops — o par que compartilha |
| research | 2 | **pink** | colour205 | exploração |

**Alternativa** se `deployment` tiver de ser distinto: `research` passa a **cyan** (junto de `product`,
ambos descoberta) e `deployment` fica com **pink**. Recomendo a 1ª (git/deployment são o par mais próximo).

## 4. A guarda (para não recair)

- **Estender** o `agent-frontmatter-keys-check.sh` (ou um `agent-color-check.sh` novo) para exigir:
  (a) `color` presente; (b) `color` ∈ {8 valores da paleta}; (c) `color` == a cor da categoria do mapa;
  (d) nenhum placeholder `[cor da categoria]`. Reprova no lint, como o vocabulário fechado já faz noutros
  campos — assim o desvio não volta em silêncio.
- **Corrigir o molde do `agent-creator`** (`.claude/agents/meta/agent-creator-specialist.md` e variantes)
  para **resolver** a cor pela categoria a partir do mapa, em vez de deixar o placeholder.
- **Aplicar** o mapa aos 51 agentes (os ~21 fora da paleta/sem cor, e os 30 já válidos que não batem a
  categoria).

## 5. Veredito

**Veredito proposto: `costurar`.** Um mapa fechado categoria→cor + um check no gate que já existe +
correção do molde. Reusa o padrão de "vocabulário fechado + lint" da casa. Não é `absorver` (sem mecanismo
novo), nem `rejeitar`/`parquear`. **A decisão que não deriva:** qual par compartilha a cor (git+deployment,
recomendado) — fica para o core.

*Mercado (nota leve):* colorir por categoria/namespace é o padrão de rótulos em trackers e de tipos de
arquivo em editores — a cor é um sinal de categoria, de valor único, não um enfeite por agente.

*O que o core sela:* o mapa, o par que compartilha e a guarda. Registro no corpus da curadoria se pedirem;
entregue como sinal.

---

Orquestrado com 🧅 Onion Evolve

## Desfecho no core (2026-11-22)

Selado no PR `feat/agent-colors` (SAC-409): o mapa da seção 3, com git e deployment dividindo o `orange`,
na SSOT `.claude/validation/agent-colors.tsv`; a REGRA 122 (Cor de agente presente, na paleta do Claude Code
e igual à da categoria) com juiz próprio; e o molde do agent-creator e o template de agente derivando a cor
da categoria. A paleta foi reconferida na doc oficial de subagentes e no binário. Uma correção de contagem:
a população real era de 51 agentes com 38 fora da cor da categoria (7 fora da paleta, 1 sem a chave, 30
trocadas). As contagens por categoria da seção 1 somavam os 9 `README.md`, e os 2 placeholders estão no
corpo do molde, não no frontmatter. Grafo: `docs/evolution/research/guard-agent-color-2026-11/`.
