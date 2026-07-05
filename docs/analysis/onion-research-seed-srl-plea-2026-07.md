# Semente de pesquisa — Autorregulação da Aprendizagem (SRL) e o PLEA de Pedro Rosário × Onion

> **Status: ENTREGUE (2026-07-05)** — a deep-research rodou no mesmo dia do plantio; relatório
> verificado em [onion-research-srl-plea-2026-07.md](onion-research-srl-plea-2026-07.md)
> (11 achados, 1 refutado; **Q3 e Q5 ficaram ABERTAS** — rodadas dedicadas futuras). Plantada
> em 2026-07-05 a partir da reflexão registrada no
> [parecer do whatsapp-sender](onion-parecer-whatsapp-sender-2026-07.md) §4-C.
>
> **Princípio-guia do maestro (formulação canônica):** *"Onion dogfoodando com SDAAL — LLM como
> VM; MD/KG/grafos/scripts como bytecode"* — sem sobrecarga do que não precisa; o poder do
> Transformer com a lente do Onion, mapeando e deixando migalhas para guiar em tempo de execução.

## Por que esta pesquisa

O modelo **PLEA** de Pedro Rosário (Planificação → Execução → Avaliação, **recursivo dentro de
cada fase**) descreve com precisão inquietante o loop de auto-evolução que o Onion já vive:

| Fase PLEA | Análogo no Onion (já operante) |
|---|---|
| **Planificação** | radar do KG (atenção = onde olhar) · backlog priorizado do `/meta:evolve` · plans |
| **Execução** | atuadores (`/meta:create-*`, edição dirigida) · dogfood como padrão master |
| **Avaliação** | juiz adversarial (refutações → arestas REFUTES) · re-teste de migalhas por `conflict_class` · D10 (memória) · gates determinísticos |

E os artefatos metacognitivos já existem: **diário = automonitorização** ·
**`conflict_class`/`valid_when`/`review_after` = autoavaliação calibrada** ·
**`confidence` dos claims = autoeficácia epistêmica**. A pesquisa formaliza (ou refuta) essas
correspondências e extrai o que a literatura tem a ensinar ao loop — e vice-versa.

## Questões de pesquisa

**Q1 — PLEA como lente formal do loop de auto-evolução.** Mapear rigorosamente as fases
(incluindo a recursividade intra-fase) sobre o ciclo radar-KG → atuadores-dogfood →
juiz/re-teste. Auditar o que FALTA no Onion pela lente SRL: há análogo da fase
volitiva/motivacional? A autoeficácia (Bandura, via Rosário) mapeia em `confidence`? O que o
modelo prevê que o loop ainda não faz (ex.: adaptação de estratégia entre ciclos)?

**Q2 — Onion como andaime de SRL humano (educação).** O framework promove agência de quem o usa
(maestro decide; IA propõe)? Como as intervenções narrativas de Rosário ("Cartas do Gervásio ao
seu Umbigo"; Sarilhos do Amarelo) dialogam com o **Autobiographical Marketing** do Onion (o
framework que conta a própria história como instrumento de ensino)? Aplicação direta: os
materiais educacionais do maestro (guia do aluno pulse-mais-2026) como campo de teste.

**Q3 — `messenger` como canal de prompts autorregulatórios.** A capacidade extraída
(whatsapp-sender) reencontra propósito: lembretes de planificação, check-ins de execução,
reflexões de avaliação entregues onde o aprendiz está. O que a literatura de *SRL prompts* e
mobile learning diz sobre eficácia, dosagem e risco (interrupção vs suporte)? Requisito de
implementação: eixo SDAAL spec-first (parecer §4-C), gated.

**Q4 — Breadcrumbs/diário × automonitorização e calibração metacognitiva.** As migalhas
(`review_after`, re-teste por classe, "nunca re-carimbar sem re-testar") são um mecanismo de
calibração — o que Zimmerman/Rosário e a literatura de *judgments of learning* dizem sobre
formatos, frequência e vieses? A família "declarado ≠ verificado" tem eco na distinção
monitorização-vs-controle da metacognição?

**Q5 — A tese LLM-as-VM com família de bytecodes como arquitetura cognitiva.** MD (spec
executável) + KG/`.kg.yaml` (estado de conhecimento) + grafos (mapa navegável) + scripts
(determinismo) — como as fases PLEA se materializam em cada classe de bytecode (planificar =
ler radar/grafo · executar = rodar spec MD · avaliar = radar/re-teste/script)? O que a
literatura de arquiteturas cognitivas (ACT-R, SOAR, agentes LLM com memória externa) diz sobre
esse substrato executável — e onde a tese do maestro é original?

## Método previsto (quando disparar)

Deep-research harness (fan-out multi-fonte: literatura acadêmica de SRL/PLEA — Rosário, Zimmerman,
Panadero — + arquiteturas cognitivas + SRL prompts/mobile learning + campo agêntico) com
**verificação adversarial** de cada alegação antes da síntese; relatório citado em
`docs/analysis/`; achados acionáveis viram claims no KG e candidatos a ADR/KB — mesmo ciclo que
levou a pesquisa de breadcrumbs até o `conflict_class` do diário e o `/meta:kg`.

## Gatilho

O maestro pede ("roda a pesquisa SRL/PLEA") → executar a partir DESTA semente, tecendo as
respostas nas questões Q1-Q5. Memória da sessão aponta para cá
(`srl-plea-research-vision`).
