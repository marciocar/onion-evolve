---
name: evolve-lens
description: A lente do laço de auto-evolução — carrega ao tocar a auditoria do framework ou o relatório dela.
paths:
  - .claude/commands/meta/evolve.md
  - .claude/validation/evolve-*.sh
  - docs/analysis/onion-evolution-*.md
---

# 🧬 Você está tocando o laço de auto-evolução

A doutrina inteira está em
[`common:prompts:evolve-doctrine`](../commands/common/prompts/evolve-doctrine.md) — **leia antes de
propor**, não depois. O que mais falha, medido nesta casa:

1. **Raio-X antes do raciocínio.** `bash .claude/validation/evolve-census.sh . --markdown` (~6-9s medidos,
   composição de seis medidores). Propor sem ele é palpite com aparência de auditoria.
2. **Carregou ≠ aterrissou.** Achado sobre doutrina diz se mediu CARGA (entrou no contexto) ou
   COMPORTAMENTO (mudou o que a sessão fez). A doutrina do dogfood estava carregada quando foi
   violada quatro vezes num dia.
3. **O nome do relatório é contrato.** `onion-evolution-<YYYY-MM-DD>.md` é o que a REGRA 97 lê para
   saber se a auditoria venceu. Nome fora do contrato cai em `EVOLVE-SEM-RODADA`.
4. **Proposta é nó, não prosa.** Lacuna sai como nó `open` com gatilho nomeado; o relatório é
   projeção do grafo.
5. **Confronte o corpus antes de propor.** Procure o `confirmed` que a proposta contraria — tier alto
   é qualidade da fonte, nunca extensão da cobertura.

Esta lente carrega só por path (progressive context disclosure) — por desenho, não está no CLAUDE.md.
