---
kg: docs/evolution/research/onion-slm-2026-10/onion-slm-2026-10.kg.yaml
run_id: wf_78edad4f-896
mode: primaries
tokens: 2613991
agents: 37
duration_min: 17
date: 2026-10-05
fonte_de_entrada: "discuss/onion-slm — docs/discussions/onion-slm/fontes (pesquisa do chat do maestro, 45 afirmações, estado nao-verificado)"
---

# Onion SLM: o que a pesquisa do chat diz, contra as primárias

> **Projeção do grafo**, não fonte. O grafo é `onion-slm-2026-10.kg.yaml` (86 nós, 118 arestas,
> `kg-radar --integrity --schema` exit 0). A pergunta veio da discussão `discuss/onion-slm`. Os
> docs do chat **não são verdade**: só viraram nó as afirmações que um leitor citou verbatim da
> primária **e** que um segundo agente, reabrindo o documento, ancorou.

## Enquadramento (maestro, 2026-10-05)

- *"o nanochat foi um exemplo, não é nosso moat"* (`C_MAESTRO_FRAME_NANOCHAT_EXAMPLE_NOT_MOAT`).
- *"o mote do modelo é ter um DOGFOOD KG-SSOT First e Runtime (SDAAL)"*. O modelo é a doutrina
  encarnada, não um fim.
- *Capitalizar sempre*: bench aberto, treinamentos, consultorias, gestão de federação, advisor de
  core/hub, membro de rede. Toda opção diz qual via abre e quem paga.

## O que a rodada sustenta

1. **O recurso escasso é o verificador, não o modelo.** As primárias convergem:
   - a OpenAI manda avaliar o Privacy Filter no domínio e nega que ele garanta anonimização;
   - o KaLLM diz que F1 automático de triplas é **piso**;
   - Wang 2020 mede que erro sintético não substitui erro real (recall cai cerca de 30%);
   - o paper da NVIDIA é *position paper*;
   - o LoRA Land escolhe o melhor de 10 bases contra o GPT-4-0613.

   O mecanismo verificável do Onion é exatamente o que falta ao mercado
   (`C_CAPITAL_FUNDS_SMALL_MODELS_NOT_THE_MOAT`).
2. **A decisão vigente "não treinar agora" sai fortalecida.**
   - Hamel: não comece por fine-tune. O anti-caso "requisitos que mudam" vale para uma doutrina que muda
     por PR (`C_FINETUNE_WINS_ONLY_NARROW_AFTER_PROMPT`).
   - A destilação on-policy exige um professor de pesos abertos com distribuição por token, o que o
     Claude não fornece. E o aluno herda o professor (`C_DISTILLATION_REAL_BUT_TEACHER_BOUND`).
3. **Já existe um menu de especialistas prontos, com licença Apache 2.0 verificada na primária**, para a
   opção C *sem treino*:
   - **de-id**, o 1º caso de uso: OpenAI Privacy Filter (1,5B, 50M ativos) e GLiNER2-PII
     (`C_DEID_OFF_THE_SHELF_CANDIDATES`);
   - **extração tipada**: NuExtract 3 (sobre Qwen3.5-4B) e GLiNER2.5 (74M–0,3B)
     (`C_TYPED_EXTRACTION_OFF_THE_SHELF`);
   - **embedders**, só como complemento do grep do corpus, nunca do radar
     (`C_EMBEDDERS_LOCAL_RETRIEVAL_COMPLEMENT`).

   **Nenhum deles tem desempenho provado em pt-BR, CPF/CNPJ ou no KG do Onion.** Todo número de
   qualidade é do próprio fornecedor.
4. **Desenho do eval de domínio, informado pelas primárias** (`C_EVAL_DESIGN_F1_FLOOR_REAL_ERRORS`):
   - **Tarefas de conjunto fechado** (11 `node_type`, 12 `edge_type`, declarado × verificado) têm gold
     completo e escapam da crítica do KaLLM.
   - **Extração aberta** exige adjudicação, porque ali o F1 é só piso.
   - **Rótulo por mutação de grafo** serve para fumaça e treino, nunca para certificar. O holdout usa os
     **erros reais já selados** do corpus: o histórico de REFUTES e SUPERSEDES.

## Correções ao chat (viraram nó com aresta)

| afirmação do chat | o que a primária diz | nó |
|---|---|---|
| GKD foi para `trl.experimental` na v0.29 (set/2026) | na **v0.26.0, em 09/12/2025** | `C_CHAT_TRL_GKD_MOVED_IN_029` refuted |
| destilação on-policy chega a 67,6% no AIME | 67,6% é o **RL**; a on-policy chega a **74,4 a 1/10 do custo** | `C_CHAT_AIME_676_DISTILLATION` refuted |
| GLiNER2-PII cobre IDs brasileiros | **sem rótulo CPF/CNPJ**; português só no treino sintético, sem eval | `C_CHAT_GLINER2PII_COVERS_BR_IDS` refuted |
| Gemma 4 E2B/E4B sem atualização | release MTP em 16/04 | `C_CHAT_GEMMA4_EDGE_NOT_UPDATED` refuted |
| OpenAI Privacy Filter F1 97,43% | F1 de **tokens** após re-rotulagem do vendor; spans 0,926 | `C_CHAT_OPF_F1_9743` superseded |
| fine-tune 54% → 96% num domínio novo | 0,545 → 0,962 em SPY sintético, parte é **política de rótulo** | `C_CHAT_OPF_FINETUNE_54_TO_96_DOMAIN` superseded |
| LoRA Land = LoRAs sobre Mistral vencem o GPT-4 | 310 = **10 bases × 31 tarefas**; 224/310 vencem; perde em código e SQL | `C_CHAT_LORA_LAND_25_MISTRAL_BEAT_GPT4` superseded |
| bge-m3 = 63,0 no MTEB | a primária dá **59,56**; o 63,0 mistura métricas | `C_CHAT_BGE_M3_MTEB_63` unverifiable |
| Qwen3.7 é proprietário | sem primária | `C_CHAT_QWEN37_PROPRIETARY` unverifiable |

E a mais importante para o desenho: a fonte apresentava **rótulo por mutação de grafo como "prática
madura"**. A primária (TransE + Wang 2020) diz outra coisa: é gerador de **negativo de treino**, e o
detector medido em erro sintético superestima o real.

## Capitalizar: via × quem paga (proposta, não medida)

| peça | via de bilhetagem | quem paga |
|---|---|---|
| Eval de domínio com erros reais selados + radar como corretor | bench aberto (autoridade) → consultoria/advisor que o aplica | adotante regulado; hub que audita sua federação |
| Menu de de-id local medido em pt-BR (CPF/CNPJ) | entregável de consultoria de compliance; serviço gerido da federação | adotante com dado sensível (saúde, finanças) |
| Primitiva tipada SDAAL plugada no KG | treinamento ("o mecanismo, não o modelo"); material de curso | alunos, times que adotam o core |
| Correções verificadas ao estado da arte | credencial pública (site, diário) | indireto: abre consultoria e rede |

A rodada **não** mediu o modelo de negócio de benchmarks abertos nem de eval como serviço. Isso fica
para a rodada complementar já nomeada na discussão.

## Proposta (não sela)

`Q_SLM_OPTION_C_EVAL_STARTS_WITH_OFF_THE_SHELF`: quando o gatilho de C abrir, o eval começa medindo
**zero-shot** os especialistas prontos contra o LLM atual. A medição usa F1 como piso, holdout de
**erros reais** do corpus e custo de inferência **medido na VPS**. Fine-tune só entra se **todos**
falharem. Quem sela é o maestro.

## NÃO-VERIFICADOS

- **28 claims rejeitadas na ancoragem** (24 exageradas, 3 sem citação, 1 não encontrada) não viraram nó.
  A lista com o motivo de cada uma está em `E_LACUNAS_ONION_SLM_PRIMARIES_1005` e em `data/`.
- **Lacunas abertas:**
  - português e latência do GLiNER2.5;
  - o placar GLiNER2-PII × OPF (quote costurada, rejeitada);
  - licença e contexto do Qwen3.5 (rebaixados por procedimento);
  - lineup Qwen 3.7/3.8 só por agregador;
  - ranking de 2026 do EmbeddingGemma;
  - "consenso" do Ask HN, que é um comentarista só.
- **Smol Training Playbook: OMITIDO** — o leitor não produziu claim nem marcou inalcançável. É objeção
  sobrevivente por omissão (cláusula 6). As "3 razões para treinar do zero" seguem como afirmação do chat.
- **Capital incompleto:**
  - NuMind e Zyphra estão sem evidência;
  - Fastino só tem fonte via TechCrunch;
  - a durabilidade dos fornecedores não foi respondida. A mitigação real é a licença Apache 2.0 dos
    pesos, forkáveis.
- **Nenhum modelo foi rodado.** Latência em CPU, scripts do NuExtract e repo do KaLLM seguem
  declarados-não-verificados até o dogfood.
- **Retorno do Elenxo:** chegou truncado na objeção 23 durante a escrita do grafo. O nó de lacunas
  declara isso, e o `data/` guarda as 58 objeções completas (29 sobreviventes).
- **A fonte do chat** não existe nesta árvore: vive na branch `discuss/onion-slm` (`X_CHAT_SOURCES_ONION_SLM`).

## valeu-a-pena

2.613.991 tokens ÷ 86 nós ≈ **30k/nó**. É abaixo dos 42k/nó da referência de primárias (2026-09-13,
`wf_1865aba9-e20`) e dos 68–74k/nó do censo. Rendeu 9 correções nomeadas ao chat e o desenho do eval.
O caro e decisivo foi a ancoragem: ela derrubou 28 afirmações que a leitura sozinha teria selado.
