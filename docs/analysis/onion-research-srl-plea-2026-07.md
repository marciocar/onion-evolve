# Pesquisa — Autorregulação da Aprendizagem (SRL) e o PLEA de Pedro Rosário × Sistema Onion

> **Status: ENTREGUE (2026-07-05)** — deep-research multi-fonte com verificação adversarial.
> Semente: [onion-research-seed-srl-plea-2026-07.md](onion-research-seed-srl-plea-2026-07.md).
> **Números do run**: 5 ângulos de busca · 25 fontes · 122 claims extraídos → 25 verificados
> (painel de 3 votos adversariais cada) → **24 confirmados, 1 refutado** → 11 achados pós-síntese ·
> 107 agentes · run `wf_6c1adecd-e36`, sobreviveu a 2 limites de sessão + 1 morte de processo
> via resume-do-cache (a migalha `workflow-resume-cache-recovery` pagou de novo).
> **Honestidade de cobertura**: Q1/Q2/Q4 bem sustentadas; **Q3 e Q5 ficaram ABERTAS** — nenhum
> claim sobreviveu à verificação; nada é afirmado sobre elas.

## 0. Sumário executivo

O mapeamento PLEA→Onion é **rigoroso no esqueleto e incompleto na alma**: as fontes primárias de
Rosário confirmam tudo que a semente assumiu sobre a *estrutura* (três fases cíclicas,
recursividade intra-fase, avaliação-como-redesenho) — mas a lente SRL expõe que o loop do Onion
**não tem componente motivacional/volitivo explícito**, que é parte FORMAL da definição de SRL.
E as pontes que construímos (autoeficácia↔confidence, radar↔monitorização, diário↔narrativas)
tiveram os **fatos-âncora confirmados** e a **analogia rotulada PLAUSÍVEL** pelos verificadores —
são engenharia inspirada, não homologia comprovada. O achado mais acionável para a vertical
educacional é um alerta: **IA genérica como andaime produz "preguiça metacognitiva"** (melhora a
tarefa sem gerar aprendizagem); o andaime só funciona com desenho SRL deliberado.

## 1. Achados confirmados (fatos, alta confiança)

| # | Q | Achado | Fonte-âncora |
|---|---|---|---|
| A1 | Q1 | **Genealogia confirmada**: PLEA proposto por Rosário (2002a) como versão cíclica *deliberadamente mais parcimoniosa* do modelo sociocognitivo de Zimmerman (1998/2000) — verbatim na Revista Portuguesa de Educação 16(2), 2003 | [Redalyc](https://www.redalyc.org/pdf/374/37416206.pdf) · [repositorium U.Minho](https://repositorium.uminho.pt/server/api/core/bitstreams/4a31b228-9947-4bfd-b5f0-40768fae0411/content) |
| A2 | Q1 | **Recursividade intra-fase é explícita e original de 2003**: "a fase de planificação das tarefas, também é planificada, executada e avaliada" (o "segundo eixo norteador"; Fig. 2 com ciclo PAE em cada fase). *Caveat*: Rosário diz "cíclico"/"interpenetração", não "recursivo" — nossa glosa é fiel mas não literal | idem |
| A3 | Q1 | **Avaliação = redesenho de estratégias**, "não mera constatação de discrepâncias", precursora da Planificação seguinte — mapeamento rigoroso EXIGE adaptação estratégica entre ciclos, não só veredito do juiz | Rosário 2003 · [Panadero 2017](https://pmc.ncbi.nlm.nih.gov/articles/PMC5408091/) |
| A4 | Q1 | **LACUNA DO LOOP**: a dimensão volitiva/motivacional é componente FORMAL do SRL (fase "performance/volitional control" em Zimmerman; definição canônica inclui aspectos motivacionais e emocionais). O loop radar→atuadores→juiz não tem análogo explícito | Panadero 2017 · [Frontiers 2024](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2024.1307574/full) |
| A7 | Q2 | **Narrativas de Rosário confirmadas**: (Des)venturas do Testas (2002-04) precede Gervásio (2006) e Sarilhos (2007); mecanismo = modelação observacional (Bandura 1997) — herói-aluno como modelo de estratégias | Rosário 2003 · [ResearchGate](https://www.researchgate.net/publication/26465035) |
| A8 | Q2 | **Contra-evidência ao andaime automático ("metacognitive laziness")**: RCT peer-reviewed (Fan et al. 2025, BJET 56(2), N=117, 4 condições): grupo ChatGPT melhorou o ensaio SEM ganho de conhecimento/transferência; andaimes mudaram os *processos* de SRL mas não a motivação intrínseca. **Agentes de IA NÃO andaimam SRL automaticamente — o desenho deliberado importa** | [arXiv 2412.09315](https://arxiv.org/abs/2412.09315) (BJET DOI 10.1111/bjet.13544) |

## 2. Achados fato-confirmado / analogia-PLAUSÍVEL

Os verificadores confirmaram o fato e pediram explicitamente rótulo PLAUSÍVEL para a ponte ao
Onion (construção analítica nossa, não da literatura):

| # | Q | Fato confirmado | Ponte PLAUSÍVEL (nossa) |
|---|---|---|---|
| A5 | Q1 | Autoeficácia (Bandura) é crença motivacional da fase de **Planificação** em Zimmerman — a confiança *precede e condiciona* o planejamento | autoeficácia ↔ `confidence` de claims (crença de capacidade do agente ≠ credência epistêmica sobre proposições) |
| A6 | Q4 | Em Winne & Hadwin, a monitorização metacognitiva é o processo central que guia o **controle** em cada fase ("gateway to self-regulating") | radar (monitorização) / atuadores (controle) / re-teste de migalhas — *caveat estrutural*: em W&H a monitorização é interna e metacognitiva; o radar é script externo determinístico |
| A7b | Q2 | (do A7) narrativa como veículo de SRL tem precedente factual robusto | diário/autobiografia do Onion ↔ narrativas de Rosário — mecanismos diferem (identificação humano-com-personagem vs sistema-escrevendo-o-próprio-diário) |

## 3. Achados de confiança média (preprints, Ns pequenos)

- **A9 (Q2, medium)** — **SRLAgent**: agente LLM gamificado *estruturado explicitamente nas 3
  fases de Zimmerman* melhorou escores de SRL (M 5,66→5,92; t(15)=4,41; p<0,001) enquanto
  controles não; sugere que **a estrutura de fases embutida é o ingrediente ativo**. Rebaixado a
  medium: preprint, N=16, autorrelato, sessão única ([arXiv 2506.09968](https://arxiv.org/html/2506.09968)).
- **A10 (Q4/Q5-adjacente, medium)** — features derivadas da teoria SRL elevaram acurácia de
  predição de 65%→88% (XGBoost, N=142); autores argumentam que a natureza cíclica não-direcionada
  do SRL resiste a DAGs/Bayes — **operacionalizar SRL em máquina exige representar o ciclo
  explicitamente, não emerge dos dados** ([arXiv 2507.02913](https://arxiv.org/pdf/2507.02913)).
  Caveats: preprint, risco de quase-circularidade das features, tese contestável.

## 4. Veredito sintético (A11, medium)

> O mapeamento PLEA→loop do Onion é **rigoroso no esqueleto estrutural** (3 fases cíclicas ✓ ·
> recursividade intra-fase ✓ · avaliação-como-redesenho ↔ juiz que realimenta ✓ · adaptação entre
> ciclos como exigência ✓) e **incompleto pela lente SRL**: falta componente motivacional/volitivo
> explícito, e a monitorização do Onion é externa/determinística onde a do SRL é metacognição
> interna. As pontes propostas são **analogias de engenharia PLAUSÍVEIS**, não homologias.

## 5. Refutado (preservado — história reconcilia)

- ❌ (0-3) *"A fase de autorreflexão seria a mais difícil de andaimar via agentes LLM"* — leitura
  do SRLAgent que não se sustentou na verificação. Não usar.

## 6. Questões ABERTAS (sem lastro verificado — rodadas dedicadas futuras)

1. **Q3 (prompts autorregulatórios via WhatsApp/SMS)**: eficácia, dosagem e riscos seguem SEM
   claims sobreviventes. **Consequência prática: o eixo `messenger` continua gated com razão
   redobrada** — nem o caso pedagógico tem lastro bibliográfico verificado ainda.
2. **Q5 (LLM-as-VM vs ACT-R/SOAR/memória externa)**: a originalidade da tese do maestro está
   **não-avaliada** (≠ confirmada, ≠ refutada). Fontes candidatas foram coletadas (CoALA
   2309.02427, MemGPT 2310.08560 etc.) mas nenhum claim sobreviveu — rodada dedicada necessária.
3. Como operacionalizar a dimensão volitiva num loop agêntico **sem antropomorfismo vazio**?
   Candidatos concretos no Onion: persistência de re-tentativa, orçamento de esforço por ciclo,
   priorização do backlog como orientação-a-metas — precisam de mapeamento formal falseável.
4. O ingrediente ativo do SRLAgent replica com N maior e medidas comportamentais? A "preguiça
   metacognitiva" atenua quando o agente FORÇA avaliação explícita (o análogo do juiz adversarial
   aplicado ao aprendiz humano)?

## 7. Implicações acionáveis para o Onion

1. **Vertical educacional (F0)**: os confirmados desta pesquisa são a fundação da KB de doutrina.
   **Diretriz nº 1 vinda da evidência**: andaime educacional só com desenho SRL deliberado
   (estrutura de fases embutida — A9) e com avaliação forçada (anti-A8); IA genérica gera
   dependência sem aprendizagem.
2. **Lacuna volitiva (A4)**: candidata a questão no KG da próxima auditoria — se/como o loop
   ganha análogo motivacional formal (openQuestion 3 dá os candidatos).
3. **Rótulos honestos**: onde o Onion citar SRL (KBs, materiais), manter a separação
   fato-confirmado vs analogia-PLAUSÍVEL deste relatório — é o mesmo rigor declarado≠verificado.
4. **Pesquisa-irmã plantada**: [semente Hegel](onion-research-seed-hegel-dialectics-2026-07.md)
   (Aufhebung ↔ append-mostly do KG; a Q4 de lá toca a Q1 daqui via Vygotsky).

## 8. Caveats metodológicos (do próprio harness)

Cobertura desigual (Q3/Q5 vazias) · pontes Onion↔SRL são construção do projeto (rotuladas) ·
3 fontes centrais de 2025 são preprints sem peer review (exceção: Fan et al., BJET confirmado) ·
nenhuma meta-análise quantitativa de SRL sobreviveu (magnitudes de efeito humano-vs-IA sem base
numérica) · "recursivo" é glosa; datação 2002a/2004b oscila na literatura (mesma obra conceitual).

---

*Gerado pelo harness de deep-research do Onion (fan-out → fetch → extração → verificação
adversarial 3-votos → síntese), 2026-07-05. Fontes completas e vereditos por claim no journal do
run `wf_6c1adecd-e36`.*
