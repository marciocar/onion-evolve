# Transformer — a arquitetura por trás do reasoner do Onion

> **Versão**: 1.1.0 | **Última atualização**: 2026-07-17 | **Categoria**: Conceitos
> O **Transformer** é a arquitetura de rede neural (Vaswani et al., 2017) que sustenta os LLMs modernos —
> Claude, GPT, Gemini. No Onion ele é o **reasoner** da [economia de motores](onion-engine-economy.md):
> o motor de juízo, orquestração e síntese. Esta KB explica **o conceito**, **como ele evoluiu** e o
> **estado de uso em jul/2026** — preenchendo o gap deixado pela engine-economy, que o nomeia sem explicá-lo.

---

## 📋 Metadata

- **Relacionadas:** [Economia de motores](onion-engine-economy.md) · [SDAAL whitepaper](../../sdaal/sdaal.md) · [Context Window Optimization](context-window-optimization.md) · [AI Agent Design Patterns](ai-agent-design-patterns.md) · [Agent Orchestration](agent-orchestration.md)
- **Por que existe:** a [economia de motores](onion-engine-economy.md) (#210) declara "o Transformer é o reasoner" sem definir o termo. Esta KB é o complemento conceitual — referência, não doutrina operacional.

---

## 1. O conceito (2017)

O Transformer nasceu no paper *"Attention Is All You Need"* (Vaswani et al., 2017). A ideia central que
substituiu RNNs/LSTMs é a **self-attention** (autoatenção): cada token "olha" para todos os outros da
sequência **em paralelo** e pondera quanto cada um importa para construir a própria representação.

A mecânica de uma cabeça de atenção:

```
Para cada token, projete 3 vetores: Query (Q), Key (K), Value (V).
peso(i,j) = softmax( Qᵢ · Kⱼ / √d )      # quanto o token i "presta atenção" no token j
saídaᵢ    = Σⱼ peso(i,j) · Vⱼ            # soma ponderada dos Values
```

Três consequências que definem tudo que veio depois:

- **Paralelismo total no treino** — sem recorrência sequencial; escala bem em GPU/TPU.
- **Contexto global** — qualquer token alcança qualquer outro em **um** passo (vs. o caminho longo das RNNs).
- **Custo quadrático O(n²)** no comprimento da sequência — o calcanhar de Aquiles que motiva quase toda a evolução seguinte.

**Componentes de um bloco Transformer:**

| Peça | Função |
|---|---|
| Token embeddings | mapeiam tokens → vetores |
| **Positional encoding** | injeta ordem (a atenção é *permutation-invariant* — sem isso, "cão morde homem" = "homem morde cão") |
| Multi-Head Attention (MHA) | várias cabeças de atenção em paralelo, cada uma capturando relações diferentes |
| Feed-Forward (FFN) | transformação não-linear por token |
| Residual + LayerNorm | estabilizam o treino de redes profundas |

---

## 2. A evolução do conceito

| Fase | Mudança | Por quê |
|---|---|---|
| **Encoder-decoder → decoder-only** | GPT abandona o encoder; BERT fica só encoder | a geração autoregressiva (prever o próximo token) venceu para LLMs |
| **Scaling laws** | Kaplan (2020), Chinchilla (2022) | mais dados + parâmetros + compute → melhor, de forma **previsível** |
| **Eficiência de atenção** | MQA → **GQA**, **FlashAttention**, sliding-window | cortar memória/banda sem perder qualidade |
| **Esparsidade** | **Mixture-of-Experts (MoE)** | ativar só uma fração dos parâmetros por token → capacidade sem custo proporcional |
| **Contexto longo** | RoPE + atenção eficiente → 100k–1M tokens | RAG, agentes, codebases inteiras na janela |
| **Pós-treino** | RLHF → modelos de **raciocínio** / test-time compute | qualidade de juízo, não só *next-token* |
| **Alternativas sub-quadráticas** | **SSM/Mamba**, linear attention, RWKV | escapar do O(n²) em sequências muito longas |

O fio condutor: **a atenção cheia é cara**. Cada fase ou a torna mais barata (GQA, FlashAttention, MoE)
ou tenta substituí-la por algo de custo linear (SSMs).

---

## 3. Estado de uso (jul/2026)

**Os modelos de topo de uso geral seguem Transformer decoder-only + atenção cheia + MoE** — Claude, GPT
e Gemini nessa base; nenhum modelo *puramente* sub-quadrático lidera leaderboards. Mas a fronteira dos
**híbridos** deixou de ser só edge: em 2026 eles chegaram a **frontier-grade**.

**O que mudou de fato no uso (jul/2026):**

- **Híbridos Mamba-Transformer-MoE — convergência confirmada.** Times independentes convergiram na mesma
  receita: **~75% camadas lineares (Mamba/SSM) + ~25% atenção + MoE**. Exemplos: **Jamba-1.5** (398B tot /
  94B ativos, mistura camadas Transformer+Mamba+MoE), **NVIDIA Nemotron 3** (o *Super* ~120B tot / 12B
  ativos, majoritariamente Mamba-2 + poucas camadas GQA + *latent experts* MoE em espaço comprimido),
  **Qwen 3.5 Small** e o arcabouço teórico **Mamba-3 (ICLR 2026)**. O motor: tornar **contexto longo**
  economicamente viável (O(n) linear) — decisivo quando o modelo vira **agente sobre codebases/documentos
  inteiros**. Atenção cheia sobrevive nas poucas camadas onde retrieval e *in-context learning* importam.
- **Constrained / structured decoding** (ex.: XGrammar) virou *default* para saída esquematizada — o
  modelo é forçado a respeitar uma gramática/JSON Schema. Diretamente relevante ao Onion: é o mecanismo
  por trás do `schema` nos subagentes da ferramenta `Workflow`.
- **Compound AI / agêntico** — o Transformer raramente trabalha sozinho. Ele **orquestra** ferramentas
  determinísticas (via MCP como camada de execução) e SLMs especializados. Cada motor no seu lugar.

> **Quando o Transformer NÃO é a resposta:** para tarefa estreita e repetitiva (NER, classificação,
> extração de formato fixo), um **SLM especializado** é mais barato/rápido — e, no Onion, é ferramenta
> via SDAAL, nunca orquestrador. Para contagem, diff e formato fixo, um **script determinístico** é mais
> correto e auditável. Ver a régua P0-P3 na [economia de motores](onion-engine-economy.md).

---

## 4. Integração com o Sistema Onion

A [economia de motores](onion-engine-economy.md) declara três motores; o Transformer é **um** deles —
o **reasoner**:

| Motor | Papel | O Transformer aqui |
|---|---|---|
| **Transformer (Claude)** | juízo, orquestração, síntese, geração | **é este** — lê a spec (Markdown) e age |
| SLM — ferramenta via SDAAL | tarefa estreita esquematizada | *não* é o Transformer; é ferramenta atrás de adapter |
| Shell — determinístico | contagem, diff, drift, formato fixo | o que o Transformer **erra** e não deve fazer |

Dois encaixes doutrinários:

1. **Tese-mãe do SDAAL:** *"o Transformer é o reasoner, o Markdown é o bytecode"* — o LLM é o **runtime**
   do Onion. Não há "chamada de API ao modelo" no código a interceptar; o Transformer simplesmente lê a
   spec versionada e executa. Por isso a fronteira "não use o LLM para o que é determinístico" é
   **doutrina de revisão** (régua P0-P3), não lint automático.
2. **A régua P0-P3** é o classificador "qual motor quando": P0 já-existe?→*extend* · P1 determinístico?→
   script · P2 juízo→Claude (o Transformer) / multi-provider→SDAAL · P3 irreversível?→+gate humano.

Em jul/2026, a pesquisa externa confirma que essa separação (LLM orquestra, determinístico executa, SLM
especializa) **é o padrão para o qual a indústria convergiu** — o Onion apenas o nomeou cedo.

---

## 5. Referências

- *Attention Is All You Need* — Vaswani et al., NeurIPS (2017). [arXiv:1706.03762](https://arxiv.org/abs/1706.03762)
- *The End of Transformers? On Challenging Attention and the Rise of Sub-Quadratic Architectures* — [arXiv:2510.05364](https://arxiv.org/pdf/2510.05364)
- *Small Language Models are the Future of Agentic AI* — NVIDIA, [arXiv:2506.02153](https://arxiv.org/abs/2506.02153)
- *Jamba-1.5: Hybrid Transformer-Mamba Models at Scale* — AI21 (2024). [arXiv:2408.12570](https://arxiv.org/pdf/2408.12570)
- *Convergência híbrida Mamba-Transformer-MoE (75% linear + 25% atenção + MoE)* — Nemotron 3 / Qwen 3.5 / Mamba-3 (ICLR 2026), síntese de leaderboard de modelos open-weight 2026.
- *Beyond Attention: New Possibilities for AI Architectures* — IEEE Computer (2026). [computer.org](https://www.computer.org/csdl/magazine/co/2026/01/11321039/2cTQFfASKCA)
- *Hybrid Mamba-Transformer MoE Architecture* — [EmergentMind](https://www.emergentmind.com/topics/hybrid-mamba-transformer-mixture-of-experts-architecture)
- *Transformer Architecture in 2026: From Attention to Mixture of Experts* — [DEV Community](https://dev.to/jintukumardas/transformer-architecture-in-2026-from-attention-to-mixture-of-experts-moe-3d46)

---

**Última atualização**: 2026-07-17 | **Versão**: 1.1.0 | **Mantido por**: Sistema Onion

> **Nota de salvamento (2026-07-17):** KB nascido em `docs/transformer-kb-and-vscode-analysis` (2026-06-28),
> órfão de merge. Resgatado e reconciliado contra a doutrina viva: §4 confirmado casado com
> [`onion-engine-economy.md`](onion-engine-economy.md) (par da mesma era); §3 refrescado com a convergência
> híbrida frontier-grade de 2026. Descartado o commit-irmão de análise VS-Code (multi-IDE é identidade
> abandonada em 2026-05-18). Companheiro reversível registrado no diário.
