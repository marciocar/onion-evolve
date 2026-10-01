---
description: Disseca uma ferramenta de terceiro em niveis selecionaveis (identidade, capacidade, mecanismo, transferibilidade, absorcao) e propoe absorver, costurar, parquear ou rejeitar. Core-only.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, WebSearch, WebFetch, TodoWrite
---

# 🦑 /meta:dissect — dissecar uma ferramenta em níveis selecionáveis

Mapeia uma ferramenta de terceiro, entende **o que ela faz** e decide o que o Onion **absorve**,
**costura**, **parqueia como técnica a investigar** ou **rejeita com razão escrita**. O nome de
casa é cunhagem do maestro: **chupa-cabra de ferramentas** (2026-10-01).

A doutrina inteira — a escada de 5 níveis, os 4 vereditos, a regra de evidência e o que ela NÃO
promete — vive em [`common:prompts:dissect-doctrine`](../common/prompts/dissect-doctrine.md).
**Referencie, não copie.**

## Degrau e limites

- **Maestro-invocado.** Não auto-inicia, sem cron, sem `/loop` sobre si (MOAT W7).
- **Não sela.** Produz o plano e **1 nó `decision` OPEN** por ferramenta; quem sela é o maestro.
- **Executar é ato isolado.** Ferramenta de terceiro roda em worktree/container — nunca na árvore
  de trabalho. Fronteira é mecanismo; instrução em prosa não segura escritor (medido 2026-09-20).
- **MOAT (PARA sempre):** instalar dependência global, deploy, escrever em repo alheio.

## Contexto medido injetado (peça 3 — o medidor roda ANTES de você pensar)

**Hoje:** !`date +%F`
**Dissecações que o corpus já pagou:**
!`bash .claude/validation/dissect-census.sh . --markdown`

Leia o censo como ele se declara: ele mede o que o corpus **DECLARA**, não sabe de ferramenta que
ninguém anotou, e **não confere se a medição do nível de fato ocorreu** — o marcador é
auto-atestado. Se ele sair `3`, está declarando que **não pôde medir** (sem índice git, ou corpus
vazio): conserte o ambiente, nunca siga com censo vazio.

## A escada (resumo operacional — a autoridade é a doutrina)

| Nível | O que se produz | Custo |
|---|---|---|
| **N0** identidade | quem mantém, licença, trajetória **datada** | barato |
| **N1** capacidade | os **verbos** que ela faz e o Onion não — da superfície executável, não do marketing | barato |
| **N2** mecanismo | COMO faz: substrato, estrutura de dados, onde mora o determinismo | **caro — exige comportamento** |
| **N3** transferibilidade | `igual → transfere` / `diferente → desenha`, com evidência e refutador | médio |
| **N4** absorção | o plano: artefato · costura SDAAL · **guarda** que cobra · **caso de bancada** que reprova sem a mudança | caro |

**Nível reprovado não sobe.** É o corte de custo: varrer 30 ferramentas no N0 é barato; levar 30
ao N4 é insano.

## Uso

```
/meta:dissect <ferramenta|lista> [--level N=3] [--budget <tokens>]
```

`--level` **para** no nível pedido. Sem argumento, o default é **N3** (julga transferibilidade e
não gasta o plano de absorção em algo que ainda vai ser rejeitado).

## Procedimento

1. **MEDIR** — o censo acima. Ferramenta com nível **fresco** entra no nível **seguinte**; não
   repague nível. Dissecação **VENCIDA** é re-medida, nunca citada como de hoje.
2. **ENQUADRAR** — para cada ferramenta, o nível de entrada (do censo) e o nível-alvo (`--level`).
3. **DISSECAR** — orquestra via skill `onion-orchestration` reusando o motor já provado da
   pesquisa: `.claude/workflows/onion-research.js` com `mode: 'decision'` (Elenxo + nó `D_` open),
   um worker por nível, **tier por complexidade** (N0/N1 `haiku/low` · N2 `sonnet/high` ·
   N3/N4 `opus/high`). O gate de nível roda em JS, custo 0 tokens: reprovado não dispara o worker
   seguinte.
4. **VEREDITO** — um dos quatro, com razão escrita. `parquear` **exige gatilho nomeado**.
5. **DESTINO (peça 5)** — `write(KG)` em
   `docs/evolution/dissect/<ferramenta>-<AAAA-MM>/<ferramenta>-<AAAA-MM>.kg.yaml` com os
   marcadores que o censo lê (`meta.dissect_tool:`, `dissect_level:` por nó, `dissect_verdict:` no
   nó de decisão), `meta.review_after` pela cadência (ferramenta/preço 30d), `# kg-backlog-guard:
   on` e `# ═══ TETO: N NÓS ═══`. **`kg-radar` exit 0 é obrigatório** antes de qualquer prosa.
   O `SYNTHESIS.md` é **projeção**, com o **contrato de custo** no frontmatter: `kg:` · `run_id` ·
   `tokens` · `agents` · `duration_min`.
6. **GATE** — `lint-artifacts.sh` 0 HARD · família `run_dissect_selftests` verde · resíduo da
   REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) no PR.

## O que este comando NÃO faz

- **Não julga qualidade de software** — decide **encaixe no Onion**. Ferramenta excelente sem
  consumidor aqui reprova no N1, e isso não é demérito dela.
- **Não absorve.** Produz o plano e o nó `decision` **open**; a implementação é o fluxo normal.
- **Não substitui a pesquisa de mercado** — o eixo capital/M&A segue invariante da
  [doutrina de pesquisa](../common/prompts/research-doctrine.md).
- **Não sabe o que ninguém escreveu.** O censo só vê dissecação declarada.

## 🔗 Referências

- Doutrina (peça 2): [`common:prompts:dissect-doctrine`](../common/prompts/dissect-doctrine.md)
- Medidor (peça 3): `.claude/validation/dissect-census.sh`
- Motor reusado (peça 4): `.claude/workflows/onion-research.js` (`mode: 'decision'`)
- Lente (peça 6): `.claude/rules/dissect-lens.md` · Bancada (peça 7): `run_dissect_selftests`
- Forja que o emitiu: [`/meta:forge`](forge.md) · régua de transferência:
  [`transfer-heuristic-aristotle`](../../../docs/knowledge-base/concepts/transfer-heuristic-aristotle.md)
