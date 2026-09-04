---
date: 2026-09-04
instance: onion-evolve
type: learning
classification: public
tags: [plugins, marketplace, namespace, lint, behavior-over-declaration]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "REGRA 73/74 (hook resolvível, caminho .claude/ nu em plugin) — a mesma cegueira, outra classe"
review_after: 2026-12-03
conflict_class: static
---

# Comando de plugin é `/<plugin>:<cmd>` — o lint não via porque só olhava o core

**Medido 2026-09-04** na revisão dos 8 plugins para o diretório oficial: 531 referências a comando no namespace do core (`/engineer:pr`, `/meta:kg`) dentro de `plugins/**`, ZERO na forma do plugin. Três classes: mesmo-plugin com prefixo errado (194), cross-plugin (208) e dangling para a meta-fábrica que nunca viaja (129). O consumidor instalado via `/help` listando `/onion-engineering:pr` e o próprio comando mandando rodar `/engineer:pr` — que não existe na instalação dele.

**Por que nenhuma guarda pegou:** REGRA 48 valida `.claude/…` em backtick **no core**, onde tudo resolve; as raízes do lint são `.claude/` + `docs/`; `plugins/` só tinha a REGRA 19 (sincronia com a fonte). Um artefato gerado 100% fiel à fonte pode ser 100% errado no destino — é `declarado ≠ verificado` na projeção.

**Cura como mecanismo, não como passada:** o helper `plugin-namespace-check.sh` deriva o mapa comando→plugin de TODOS os manifestos (não só do plugin corrente), o assembler chama `--rewrite` (NAMESPACE-PORTABILITY: mapeado → forma do plugin; dangling → sem barra) e o README gerado lista os comandos do core citados e não distribuídos. REGRA 72 é HARD sem baseline porque a cura vive no gerador. Bancada: 5 casos, com o mutante (plugin editado à mão → 3 HARD).

**O que fica declarado:** a reescrita cross-plugin cria dependência implícita entre plugins (`/onion-engineering:flow` citado pelo `onion-product`) — é o que a REGRA 77 (contrato de dependência) vai tornar explícito.
