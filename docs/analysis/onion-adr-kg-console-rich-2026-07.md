---
title: "ADR — Console rico narrável do KG (Cytoscape + narração pré-cozida)"
date: 2026-07-29
status: ratificado
kg: docs/onion/graph/kg-console-rich-design-2026-07.kg.yaml
---

# ADR — Console rico narrável do Knowledge Graph

**Status:** ratificado (2026-07-29) · promove ao core o que o estudo
[`docs/discussions/kg-visualization-dashboards/SEED.md`](../discussions/kg-visualization-dashboards/SEED.md)
deixou **gated** (`D_DESKTOP_CYTOSCAPE`, `D_EVOLVE_NOT_ADOPT`).

## Contexto

O `.kg.yaml` é o **SSOT-as-runtime** do Onion, mas suas projeções visuais eram o texto do
`kg-radar.sh` e um `kg-console.sh` que desenhava um **SVG de círculo estático** — sem física,
zoom, busca nem IA, ilegível acima de ~30 nós (grafos reais vão de 5 a **881 nós**). A doutrina
chama o grafo de "view de inspeção, teto ~50 nós"; a causa do teto é a falta de **narrativa** — um
grafo grande só fica legível quando alguém (ou uma IA) conduz o leitor por ele em ordem de atenção.

Pesquisa de mercado (jul/2026): Cytoscape.js é o único renderer maduro que vira single-file sem
build; narração **pré-cozida** é o padrão para grafos offline/CSP; o encoding epistêmico
(tamanho=importância, opacidade=confiança, cor/borda=status, aresta por predicado) é consenso.

## Decisões

### D1 — Evoluir o `kg-console.sh` in-place (não um sibling, não CLI nova)
É o **core visualizando os próprios artefatos** (precedente `federation-console.sh`), já plugado em
`/meta:kg` e `lint-selftest`. "Evolve-not-adopt" do SEED, agora executado. **Projeção read-only
preservada:** o veredito não é recalculado — vem do `kg-radar.sh` (motor soberano); o grafo vem do
`kg-view.sh --json` (lente vigiada por `--assert-parity`); a freshness é JOIN do `--freshness-tsv`.

### D2 — Renderer: Cytoscape core 3.34, vendorizado como UM arquivo
Cytoscape UMD inline (CSP-safe, `file://`, zero rede). **Layout `cose` embutido** em vez de fcose —
evita a cadeia frágil de dependências (cose-base + layout-base) e mantém o vendoring em **um único
arquivo de 435KB, SHA congelado** (`vendor/kg-console/provenance.md`), fiel ao ethos "um artefato"
do Onion. Foco/filtro/glow/partículas implementados à mão sobre a API. **D3-force** fica registrado
como renderer alternativo **sob o mesmo contrato JSON** (soberania de runtime).

### D3 — O que viaja na federação é o CONTRATO, não o JS
O canônico é o **contrato JSON** (`kg-view.sh --json`) + o **método de encoding** + o **arco de
narração**. O Cytoscape é *uma* implementação de renderer. "Ver ≠ distribuir": o core NÃO distribui
componente de UI de adotante; cada instância renderiza o próprio grafo soberano sob o mesmo contrato.

### D4 — Narração PRÉ-COZIDA, não live-chat
A "IA que explica" é um artefato `<slug>.narration.json` autorado por agente (modo `/meta:kg
narrate`) e **embutido** pelo console, que o toca **offline** dirigindo câmera/foco. Narração live
(POST a um LLM) quebraria o autocontido/CSP — a escolha pré-cozida é deliberada. **O `kg-console.sh`
continua LLM-free**; o único ponto com IA é a autoria, fora do script. A narração é **projeção dos 4
vereditos do radar** (atenção→ordem; REFUTES/SUPERSEDES→Aufhebung; STALE→"o que re-verificar"),
nunca fonte paralela. Sem narração, o console degrada para **tour-esqueleto** por atenção.

### D5 — REGRA 47 é o mecanismo, não a promessa
"Citar ids que existem, nunca re-derivar da prosa" vira guard determinístico:
`kg-narrate-validate.sh` reprova (HARD) narração que cite id inexistente — senão o console dropa o id
morto **em silêncio** (o no-op que a doutrina combate). 5 selftests + registro na REGRA.

## Encoding epistêmico canônico

| Canal | Atributo | Regra |
|---|---|---|
| tamanho do nó | atenção (`impact × confidence × status × (1+grau)`) | ranqueia/dimensiona; "o grafo diz o que é central" |
| opacidade | confiança | baixa confiança = translúcido |
| cor de preenchimento | `node_type` | paleta fixa |
| cor/estilo da borda | `status` | verde=confirmed · vermelho=refuted · cinza-tracejado=superseded |
| contorno duplo | `layer: domain` | — |
| halo âmbar | freshness (STALE-*) | do radar, não recomputado |
| toggle + dessaturação | plane DEV/PROD | focus+context |
| cor+seta+traço da aresta | `edge_type` | SUPPORTS→ · REFUTES⊣ · SUPERSEDES⇢ |

## Consequências

- **Positivas:** o grafo grande fica legível (a narrativa resolve o teto de ~50 nós); a Aufhebung e a
  refutação retrógrada PROD→DEV ficam navegáveis; a fronteira stale fica visível; o door (via plugin
  `onion-work-tools`) ganha o console funcional (manifesto ganhou `kg-view` + vendor + validador; o
  `assemble-plugin.sh` passou a preservar subdir de `validation/`).
- **Custo:** ~435KB de JS vendorizado no core (mitigado: é o core visualizando os próprios artefatos;
  o contrato JSON é o que viaja, não o JS).
- **Gated (não agora):** F3 wow polish (partículas, semantic-zoom, minimapa, scrollytelling);
  narração live opcional como enhancement que degrada gracioso offline.

## Rastros

`kg-console.sh` · `kg-view.sh` · `kg-narrate-validate.sh` · `vendor/kg-console/` · REGRA 47 em
`lint-artifacts.sh` · modo `narrate` em `commands/meta/kg.md` · dogfood:
`docs/onion/graph/kg-console-rich-design-2026-07.kg.yaml` (este desenho, modelado e narrado por si
mesmo — o instrumento provado nele próprio).
