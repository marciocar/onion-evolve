# Doutrina SRL/PLEA — fundação da vertical educacional (classificada por veredito)

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-05 | **Categoria**: Education
> Tijolo 1 da vertical `onion-education` (F0). Todo conteúdo carrega o **veredito da verificação
> adversarial** da pesquisa de origem — fatos e analogias nunca se misturam. Fonte completa (com
> verbatims, votos e caveats): [onion-research-srl-plea-2026-07.md](../../analysis/onion-research-srl-plea-2026-07.md).

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-05 |
| **Última Atualização** | 2026-07-05 |
| **Base de evidência** | 24 claims confirmados (painel adversarial 3-votos), fontes primárias de Rosário/Zimmerman/Panadero + RCTs 2025 |
| **ADR da vertical** | [onion-adr-education-vertical-2026-07.md](../../analysis/onion-adr-education-vertical-2026-07.md) |

---

## 1. O modelo PLEA (Pedro Rosário, U. Minho) — ✅ CONFIRMADO em fonte primária

- **Genealogia**: versão cíclica *deliberadamente mais parcimoniosa* do modelo sociocognitivo de
  Zimmerman (1998/2000), proposta em Rosário (2002a); fundamento último: Teoria Social Cognitiva
  de Bandura (agência, determinismo recíproco).
- **Três fases**: **Planificação** (análise da tarefa, metas, plano) → **Execução** (aplicar
  estratégias + automonitorizar a eficácia delas) → **Avaliação**.
- **Recursividade intra-fase** ("segundo eixo norteador", verbatim 2003): *"a fase de
  planificação das tarefas, também é planificada, executada e avaliada"* — o ciclo PAE existe
  dentro de cada fase e de cada atividade. (Nota terminológica: Rosário diz "cíclico"/
  "interpenetração"; "recursivo" é glosa fiel, não literal.)
- **Avaliação = redesenho de estratégias**, verbatim: *"O núcleo fundamental desta fase não se
  centra na mera constatação de eventuais discrepâncias, mas sim no redesenho de estratégias"* —
  e é *"percursora da fase de planificação. O ciclo auto-regulatório fica desta forma assegurado"*.
- **Adaptação entre ciclos é constitutiva** — não há PLEA sem o ciclo seguinte incorporar o que a
  avaliação redesenhou.

## 2. Base SRL que o PLEA herda — ✅ CONFIRMADO

- **SRL é multidimensional por definição**: aspectos cognitivos, metacognitivos, comportamentais,
  **motivacionais e emocionais/afetivos** (Panadero 2017). A fase de performance de Zimmerman
  chamava-se *"performance/volitional control"* — **volição não é opcional**.
- **Autoeficácia (Bandura)** é crença motivacional da fase de **Planificação/Forethought** — a
  confiança *precede e condiciona* o planejamento e a ativação de estratégias (e é melhor
  preditor de desempenho nessa fase que as emoções).
- **Monitorização → controle (Winne & Hadwin)**: a monitorização metacognitiva é o *gateway* que
  guia o controle em cada fase — monitorar e agir-sobre-o-monitorado são processos distintos.

## 3. Narrativas autorregulatórias — ✅ CONFIRMADO

A inovação central de Rosário: **narrativa como veículo de promoção de SRL**. Cronologia:
*(Des)venturas do Testas* (2002-04) → *Cartas do Gervásio ao seu Umbigo* (2006) → *Sarilhos do
Amarelo* (2007). Mecanismo: **aprendizagem observacional (Bandura, 1997)** — o herói-aluno cujos
comportamentos autorregulados servem de modelo, com o leitor construindo a própria narrativa.

## 4. Evidência sobre agentes de IA como andaime — a dupla que governa o desenho

| Achado | Veredito | Consequência de desenho |
|---|---|---|
| **"Preguiça metacognitiva"** — grupo ChatGPT melhorou o ensaio SEM ganho de conhecimento/transferência (RCT, N=117, 4 condições; Fan et al., BJET 56(2) 2025) | ✅ CONFIRMADO (peer-reviewed) | **IA genérica NÃO é andaime** — melhora a tarefa e gera dependência. Artefato educacional nunca entrega resposta sem forçar avaliação/reflexão |
| **SRLAgent** — agente estruturado explicitamente nas 3 fases de Zimmerman melhorou escores de SRL; controles (multimídia; agente sem features SRL) não | ⚠️ medium (preprint, N=16, autorrelato) | **A estrutura de fases embutida é o ingrediente ativo** — desenhar artefatos COM as fases explícitas, aguardando replicação |
| "Autorreflexão é a fase mais difícil de andaimar" | ❌ REFUTADO (0-3) | não usar esta leitura |

## 5. Pontes com o Onion — ⚖️ analogias PLAUSÍVEIS (fatos confirmados, homologia NÃO)

Rótulo obrigatório em qualquer material derivado — são **engenharia inspirada**, construção do
projeto, não achado da literatura:

| Ponte | Fato-âncora ✅ | Limite da analogia |
|---|---|---|
| autoeficácia ↔ `confidence` de claims | autoeficácia é crença da Planificação | crença de capacidade do agente ≠ credência epistêmica sobre proposições |
| radar/atuadores ↔ monitorização/controle | W&H: monitorização guia o controle | no SRL a monitorização é metacognição INTERNA; o radar é script externo determinístico |
| diário/autobiografia ↔ narrativas do Testas | narrativa como veículo de SRL | identificação humano-com-personagem ≠ sistema escrevendo o próprio diário |
| loop de auto-evolução ↔ ciclo PLEA | 3 fases + recursividade + redesenho ✅ | **falta a dimensão volitiva/motivacional** no loop (lacuna real, formal no SRL) |

## 6. Diretrizes de desenho (vinculantes na vertical — do ADR)

1. **Fases SRL explícitas** em todo artefato educacional (planificar-executar-avaliar visível ao aprendiz).
2. **Avaliação forçada** — o análogo pedagógico do juiz adversarial: sem reflexão, sem resposta.
3. **Rótulos de veredito preservados** em materiais derivados.
4. **Prompts móveis: não prometer** — Q3 aberta; messenger gated.

## 7. Aberto (não construir em cima ainda)

- Q3: eficácia/dosagem/riscos de prompts autorregulatórios móveis — sem lastro verificado.
- Q5: originalidade da tese LLM-as-VM — não-avaliada.
- Operacionalização da dimensão volitiva num loop agêntico sem antropomorfismo (candidatos:
  persistência de re-tentativa, orçamento por ciclo, priorização como orientação-a-metas).
- Replicação do SRLAgent (N maior, medidas comportamentais).

## 8. Relações

- Pesquisa de origem: [onion-research-srl-plea-2026-07.md](../../analysis/onion-research-srl-plea-2026-07.md)
- ADR da vertical: [onion-adr-education-vertical-2026-07.md](../../analysis/onion-adr-education-vertical-2026-07.md)
- Fundação filosófica irmã (semente): [onion-research-seed-hegel-dialectics-2026-07.md](../../analysis/onion-research-seed-hegel-dialectics-2026-07.md)
- Loop de auto-evolução que a §5 mapeia: [onion-dogfooding-doctrine.md](../concepts/onion-dogfooding-doctrine.md) · [knowledge-graph-sdaal.md](../concepts/knowledge-graph-sdaal.md)
