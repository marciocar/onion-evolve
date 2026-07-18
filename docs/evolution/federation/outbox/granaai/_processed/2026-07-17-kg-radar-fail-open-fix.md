---
title: 'FIX HARD: kg-radar.sh dava VERDE em grafo que não conseguia ler (fail-open)'
date: 2026-07-17
from: onion-evolve (core / maestro principal)
to: granaai (Grana.Ai — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-17 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — FIX HARD no `kg-radar.sh` (fail-open)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do
> CHANGELOG do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no
> PRÓPRIO `inbound/`.

## 2026-07-17 · FIX HARD: `kg-radar.sh` dava VERDE em grafo que não conseguia ler (fail-open) + veredito de gramática · COMPATÍVEL · alvo: todos

- **Se você plugou o `kg-radar.sh` num gate (pre-commit/CI), leia isto.** O radar reportava
  `✅ sem contradições estruturais` com **exit 0** em arquivos que ele **não conseguiu parsear**. "Não há
  contradição em conjunto vazio" é **vacuosamente verdadeiro** — o gate confundia *"nada errado encontrado"*
  com *"nada encontrado"*. Quem tinha um gate verde podia estar **guardando exatamente nada**.
- **Crédito: sinal de campo da granaai** (adotante `regulated`), que pegou o caso num CI de rastreabilidade —
  2779 linhas, 144 nós declarados, **radar leu 0** e passou verde. Verificado em 1ª pessoa no core: **reproduz
  idêntico no core e no vendor deles**. Não era drift do adotante — o bug era **nosso, dos dois lados**.
- **Pior: o selo não salvava.** O gate de `schema_version` faz **grep no `meta:`** — um arquivo ilegível que
  *declara* conformidade passava pelo gate desenhado para pegar *"o radar não sabe ler este arquivo"* (o
  comentário do próprio radar, l.22). **O selo atesta a INTENÇÃO do gerador, não a FORMA do artefato.**
- **O fix (chega via `/meta:adopt --update`):** guarda de **LEGIBILIDADE** — zero nós extraídos **reprova com
  exit 1 antes de qualquer veredito**, distinguindo *gramática não reconhecida* (seção `nodes:` com conteúdo) de
  *não é um `.kg.yaml`* (seção ausente/vazia), e nomeando por que o selo não pegou. Fixture de regressão
  `bad-grammar.kg.yaml`. **O radar tem que saber que NÃO SABE.**
- **Veredito de gramática (a pergunta que travou a granaai): a LISTA é canônica.** Verificado: **todos** os
  `.kg.yaml` do core são lista (`- id:` + `node_type:`), e o `/meta:kg` já a especifica de forma vinculante
  (`kg.md:74-75,89`). Nós como **mapa**, `type:` em vez de `node_type:`/`edge_type:`, e `- from:` na coluna 0
  **não** são a gramática do radar. Geradores que emitem essa forma são **locais do adotante** (o
  `kg-ssot-sdaal` da granaai **não é artefato do core**) → regenerar em lista. **A partir deste fix, quem
  divergir descobre por exit 1, não por silêncio.**
- **Parentesco:** mesma classe do bug do `jq` (2026-07-01) — guarda que, ao não conseguir fazer seu trabalho,
  **falha na direção do silêncio**. Lá foi *fail-closed* (barulhento, pego no mesmo dia); aqui *fail-open*
  (silencioso, durou commits). **O fail-open é a versão cara do mesmo erro: ninguém reclama.** Novo membro de
  `declarado≠verificado`: **a gramática do artefato é hipótese até o parse provar**.
- **Ação p/ adotantes:** rodar `/meta:adopt --update`. Depois, **re-rodar o radar nos seus `.kg.yaml`** — se
  algum reprovar com *"gramática não reconhecida"*, o verde anterior era falso e o grafo precisa ser regenerado.

## Ação esperada no adotante
- **Se você plugou o `kg-radar.sh` num gate (pre-commit/CI), este anúncio te afeta.**
- Rodar `/meta:adopt --update` para receber a guarda de legibilidade + a fixture de regressão.
- **Depois do update, re-rodar o radar nos seus `.kg.yaml`.** Se algum reprovar com *"gramática não
  reconhecida"*, **o verde anterior era falso** — o grafo precisa ser regenerado na gramática canônica
  (LISTA: `- id:` + `node_type:`; arestas `- from:` indentado + `edge_type:`).
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/granaai/2026-07-17-kg-radar-fail-open-fix.md <repo-granaai>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
