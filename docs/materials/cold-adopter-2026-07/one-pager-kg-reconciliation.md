---
title: "Reconcilie o conhecimento da sua org como um grafo (não como prosa)"
category: materials
tags: [one-pager, probe, cold-adopter, kg, knowledge-reconciliation, experimento-A]
status: pronto-para-postar
audience: PÚBLICO — leitor frio (nenhum conhecimento de Onion assumido)
date: 2026-07-11
experimento: docs/analysis/onion-experiment-cold-adopter-2026-07.md (Instrumento A)
---

# Seu conhecimento organizacional está derivando — e o `git merge` não conserta isso

> One-pager para postar onde a conversa de *knowledge reconciliation / Company Brain / spec-driven*
> acontece. Leitor-alvo: **estranho, sem conhecimento prévio de Onion.** Honesto e técnico, não hype.

## O problema (que você provavelmente já sentiu)

Times que trabalham com IA acumulam conhecimento em **prosa** — docs, ADRs, wikis, transcrições, prompts.
Três coisas quebram:

1. **Verdade × verdade não se confronta.** Duas fontes acreditam em coisas contraditórias e o doc não sabe.
2. **Drift silencioso.** Uma verdade envelhece; a nova é escrita noutro lugar; ninguém reconcilia.
3. **`git merge` não reconcilia verdades.** Ele junta *texto*, não *o que é verdade*. Editar a linha de um
   doc de 30KB **apaga a história** — a contradição some sem registro.

RAG/GraphRAG não resolvem: eles **recuperam**, não **reconciliam** (pesquisa recente: ~10% de acerto em
mudança implícita de versão). Recuperar conhecimento ≠ decidir o que é verdade.

## A ideia (30 segundos)

Modele o conhecimento como um **grafo tipado**, não prosa:

- **Nós** tipados: `claim` (afirmação), `evidence` (evidência), `decision`, `question`.
- **Arestas** tipadas: `SUPPORTS`, **`REFUTES`** (contradição explícita — não deleção), **`SUPERSEDES`**
  (verdade nova supera a velha, sem apagá-la).
- Um **radar determinístico** (não um LLM) lê o grafo e produz o veredito: onde olhar, quais contradições
  reconciliar, o que está órfão. A atenção sai do **motor**, não da impressão do modelo.

Quando uma verdade cai, ela **não é deletada** — vira `status: refuted` com a aresta que a derrubou.
**História reconcilia, não apaga.**

## Como se parece (um pedaço real de `.kg.yaml`)

```yaml
nodes:
  - id: C_METRICA_INFLADA
    node_type: claim
    label: "a metrica de engajamento X mede o que promete"
    status: refuted        # <- caiu sob evidencia; NAO foi apagada
  - id: E_DADOS_VIVOS
    node_type: evidence
    label: "producao mostra a metrica inflada ~82x por contagem-fantasma"
edges:
  - from: E_DADOS_VIVOS
    to: C_METRICA_INFLADA
    edge_type: REFUTES     # <- a contradicao vira aresta, nao sumico
```
O radar vê essa aresta e te diz: *"há uma verdade refutada por dado vivo — reconcilie antes de decidir."*

## Tente você mesmo (no seu domínio, hoje)

1. Pegue **uma** área onde você tem verdades que se contradizem (uma decisão de produto disputada, uma regra
   de negócio ambígua, um número que dois times reportam diferente).
2. Escreva 5–10 `claim`/`evidence` num `.kg.yaml` (o schema acima é tudo que você precisa).
3. Ligue as contradições com `REFUTES`/`SUPERSEDES`.
4. Rode o radar determinístico e veja o veredito.

O método viaja como **schema + método** (não é um SaaS, não pede seus dados): ponto de partida público em
**`onion-mini`** (github.com/marciocar/onion-mini). Nasceu dogfoodado em auditorias de **produção** reais, não
no papel.

## Se você tentar — mostre

Rodou no **seu** domínio? **Poste o seu `.kg.yaml`** (anonimizado) ou conte o que o radar pegou que a prosa
escondia. É o tipo de coisa que a gente quer ver funcionar fora da nossa própria casa.
