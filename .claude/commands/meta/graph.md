---
description: Consulta a lente sócio-técnica do Onion (grafo gerado da spec-as-code) — impacto reverso, caminho entre necessidade e capacidade, e órfãos. Dogfooda o grafo a serviço da orquestração.
name: graph
allowed-tools: Read Bash(bash .claude/validation/graph.sh*)
argument-hint: "[--impact <nó> | --path <de> <até> | --orphans | --view]"
category: meta
tags: [ontologia, grafo, orquestracao, impacto, dogfood]
version: "1.0.0"
updated: "2026-06-27"
---

# /meta:graph — Lente sócio-técnica do Onion

Expõe o **grafo de conhecimento** do Onion (atores + artefatos + canais), **gerado** da spec-as-code por
`.claude/validation/graph.sh` (SSOT = spec-as-code; o grafo é derivado, **sem store externo** — tese SDAAL).
A serviço do **dogfood**: o Transformer lê o grafo para achar caminho/solução e orquestrar; o script
responde o que o LLM faz mal (impacto/órfão/caminho).

> TBox (vocabulário): `docs/knowledge-base/concepts/onion-relation-vocabulary.md`
> Lente legível: `docs/onion/graph.md` (gerada; navegável pelo Transformer)

## Quando usar

- **Antes de mudar um artefato:** "o que depende disto?" (análise de impacto reversa).
- **Para orquestrar:** "como chego de uma necessidade à capacidade que a entrega?" (caminho).
- **Na higiene/`/meta:evolve`:** achar **órfãos** (artefatos que ninguém referencia).
- **Para o `@onion` compor a visão-de-fora** sem tabela hardcoded.

## Uso

```bash
# Impacto reverso — quem aponta para o nó
bash .claude/validation/graph.sh --impact design-system-specialist

# Caminho dirigido entre dois nós (criar caminhos)
bash .claude/validation/graph.sh --path assistant onion

# Órfãos — artefatos sem nenhuma referência (related/requires)
bash .claude/validation/graph.sh --orphans

# Lente legível (regenera docs/onion/graph.md) / triplas cruas
bash .claude/validation/graph.sh --markdown > docs/onion/graph.md
bash .claude/validation/graph.sh --triples
```

## Passos

1. Resolver a intenção do maestro para o modo certo (`--impact` / `--path` / `--orphans` / `--view`).
2. Rodar `graph.sh` no modo escolhido (determinístico, sem LLM).
3. **Interpretar** o resultado a serviço da tarefa: para orquestração, ler `docs/onion/graph.md` (navegável)
   e propor o caminho/agentes; para impacto, listar dependentes antes de mudar.
4. Se a fonte mudou, **regenerar** `docs/onion/graph.md` — o lint (REGRA 21) bloqueia drift.

## Notas

- **Read-only / orientação** (exceto `--markdown`, que regenera a lente). Não muta a spec-as-code.
- O grafo é **gerado**: para mudar uma aresta, edite a fonte (`actors.yaml`, capability contract,
  frontmatter) e regenere — nunca edite `graph.md` à mão.
- Wiring pleno de auto-routing no `@onion` (GraphRAG) é follow-up gated — ver
  `onion-research-self-describing-components-2026-06` (core-only).
