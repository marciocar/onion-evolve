# Defesa contra inferência por LLM — o estado da arte

> Camada 1 (fiel à fonte, zero derivação). Sandbox de discussão — não é a KB do core.

Descreve, fielmente às fontes, o estado-da-arte (2024-2026) de defesas contra **inferência de
atributo** por LLM — quando o modelo **deduz** dado sensível não-declarado (não copia). Não tira
conclusões de design.

## Scrubbing de PII é insuficiente contra inferência

Após remover todo PII literal (NER + filtro LLM de self-disclosure), um Llama-3.3-70B recuperou
idade/gênero/país com F1 ponderado 0,84/0,90/0,88 — a inferência opera sobre **estilo e tópico**, não
sobre strings (*Inferential Privacy Leakage in Anonymized Logs*, 2026; estudo de 1.057 usuários). A
inferência explora a **capacidade de raciocínio emergente, não a memorização** (Staab et al.,
*Beyond Memorization*, ICLR 2024: até 85% top-1; "anonimização de texto e alinhamento são atualmente
ineficazes"). O position paper *Privacy Is Not Just Memorization!* (2025) estima memorização em ~8% da
superfície real.

## Anonimização adversarial: reduz, não zera (e assume um RELEASE)

- **FgAA** (Staab et al., *LLMs are Advanced Anonymizers*, ICLR 2025): um LLM-atacante guia o
  anonimizador; supera Azure em utilidade+privacidade — mas é **padrão empírico, não teorema**, e
  depende de atacante GPT-4-class.
- **INTACT** (*Truthful Text Sanitization Guided by Inference Attacks*, 2024): ganho modesto; re-id
  residual ~10,9% vs ~8,7% da supressão total; recai a rótulo genérico em 22%; o ataque custa 15-20× o
  compute da geração.
- **TRACE-RPS** (*Stop Tracking Me!*, ICLR 2026): perturbação proativa 50%→<5% em modelos open, mas
  exige **white-box aos logits** e cai a ~45% em modelos fechados.

Todas pressupõem defender um **texto/embedding publicado** — não o dono lendo o próprio grafo.

## DP e k-anonymity não fecham inferência por correlação

Inferência de atributo é essencialmente **imputação**: um baseline ingênuo (valor mais comum) bate 3
ataques SOTA (*Are Attribute Inference Attacks Just Imputation?*, 2022) — DP protege *membership*, não
correlação populacional. **k-anonymity / l-diversity / t-closeness falham em grafo denso**: a
composição não preserva k; quase-identificadores estruturais (grau/vizinhança) re-identificam; a
maldição da dimensionalidade torna cada nó quase-único (Ganta 2008; Narayanan-Shmatikov 2009; Aggarwal
2005). **DP-GNN** (GAP, node-level DP) perturba embedding/aresta mas **não impede** link/attribute
inference.

## Enforcement em runtime: dois lados da fronteira

**Acesso (need-to-know):** *AskSafely* (RCIS 2026) passa ao LLM só o **schema mascarado** (valores de
instância ocultos), com RBAC embutido — mas admite: *"não podemos garantir plenamente que nenhuma
informação seja inferida das perguntas mascaradas"*, e **se o schema em si é sensível, não pode ser
usado por design**. Permission-aware RAG filtra na **camada de recuperação**, antes de o conteúdo
chegar ao modelo.

**Saída:** filtro de duas camadas (regex + estimador de densidade de **cluster de quase-identificadores**)
detecta a violação-por-composição — mas **colapsa sob confusão de estilo** (AUROC 0,95→0,72). *CI-CoT/CI-RL*
torna Contextual Integrity executável (reduz vazamento ~40%, não elimina). *C-Trace* (2026) expressa
purpose-limitation como predicado sobre o traço de execução e **rejeita** ação não-conforme. *1-2-3 Check*
separa gerador de porteiro (o mesmo LLM não deve ser motor E juiz). Agentes violam contexto **por descuido,
não por ataque** (*Capable but Careless*, AgentCIBench, 2026).

## Arquitetura/cripto: protegem outra fronteira

Capability-split (reasoner externo não vê o bruto), TEE (protege contra o **operador** do host),
unlearning (imaturo, contornável — o fato vive no **store re-consultável**: *GraphSteal*, 2026) —
**nenhum** impede o motor **legítimo e local** de inferir para o dono.

## A fronteira é empírica

Deng et al. (*When Are LLM Inferences Acceptable?*, 2026): conforto por destinatário — 3,75/5
plataforma própria, 2,34/5 terceiros; "creepy corner" 1,74. O controle desejado é aprovação
**por-destinatário/propósito no ponto de transmissão** (geração, retenção, **transmissão**), não
impedir a dedução. **Conclusão da literatura de 2025:** raciocínio rico e mínima superfície de
inferência são **irreconciliáveis**; privacidade em tempo de inferência segue **não-resolvida** em
sistemas implantados.

## Referências

- Staab, R. et al. (2024). *Beyond Memorization: Violating Privacy via Inference with LLMs.* ICLR 2024. https://arxiv.org/pdf/2310.07298
- Staab, R. et al. (2025). *Large Language Models are Advanced Anonymizers (FgAA).* ICLR 2025. https://arxiv.org/abs/2402.13846
- *Position: Privacy Is Not Just Memorization!* (2025). https://arxiv.org/pdf/2510.01645
- *Inferential Privacy Leakage in Anonymized Conversational AI Logs* (2026). https://arxiv.org/abs/2605.23820
- Jayaraman & Evans (2022). *Are Attribute Inference Attacks Just Imputation?* https://arxiv.org/abs/2209.01292
- *Truthful Text Sanitization Guided by Inference Attacks (INTACT)* (2024). https://arxiv.org/abs/2412.12928
- *Stop Tracking Me! (TRACE-RPS)* (2026). https://arxiv.org/abs/2602.11528
- *Ask Safely (PrivateNL2CYPHER)* (RCIS 2026). https://arxiv.org/abs/2512.04852
- *Contextual Integrity via Reasoning and RL (CI-CoT/CI-RL)* (2025). https://arxiv.org/abs/2506.04245
- *Capable but Careless (AgentCIBench)* (2026). https://arxiv.org/abs/2606.23189
- *Runtime Compliance Verification (C-Trace)* (2026). https://arxiv.org/abs/2606.19242
- *1-2-3 Check* (2025). https://arxiv.org/abs/2508.07667
- Deng et al. (2026). *When Are LLM Inferences Acceptable?* https://arxiv.org/abs/2605.10013
- *GraphSteal* (2026). https://arxiv.org/abs/2605.28645
