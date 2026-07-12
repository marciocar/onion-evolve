---
title: "Síntese P2 — Intake × execução aplicado ao pipeline do sensor (perfilar × decidir; HITL)"
category: research-synthesis
responde: "SEED.md — pergunta 2 (intake × execução)"
data: "2026-07-12"
branch: "discuss/behavior-mapping-kg"
fontes_verificadas: 15
metodo: "pesquisa orquestrada 2 frentes (agentes diretos, WebSearch real) + doutrina interna do Onion"
---

# Síntese P2 — Onde estão os gates no pipeline bruto→ação

> **Carimbo: hoje = 2026-07-12.** Duas frentes (agentes `general-purpose` diretos, WebSearch real):
> (A) o ato regulado — perfilar × decidir; (B) human-in-the-loop / propose-only. Datas como
> fornecidas; **s/d** = sem data visível. Esta síntese aplica material externo **e** a doutrina
> interna do Onion (KB `authorization-layers`) — a convergência entre as duas é o achado central.

---

## A. O ato regulado — perfilar (derivar) × decidir (agir)

No direito europeu, **observar/derivar** e **decidir/agir** já são ambos regulados — o que muda é o
*nível* de intervenção. **Perfilar** (Art. 4(4)) é "qualquer forma de tratamento automatizado" para
avaliar aspectos pessoais (comportamento, desempenho, localização): **a própria derivação é
tratamento regulado, sem exigir "ação"**. **Decidir** de forma *unicamente* automatizada com efeito
jurídico/significativo dispara o regime reforçado do Art. 22 (proibição-com-exceções + **intervenção
humana**). E a jurisprudência **colapsou parcialmente** a distinção: no **SCHUFA** (C-634/21, 2023),
o TJUE decidiu que **derivar** um score já *é* a decisão automatizada do Art. 22 quando um terceiro
"se apoia fortemente" nele — **o ato de inferir foi juridicamente equiparado ao de decidir**.

- Art. 22 GDPR — direito de não se sujeitar a decisão *unicamente* automatizada com efeito
  jurídico/similar; exceções + salvaguarda de intervenção humana, expor ponto de vista, contestar — [Art. 22 GDPR (gdpr-info)](https://gdpr-info.eu/art-22-gdpr/), 2016.
- Art. 4(4) — *profiling* = qualquer tratamento automatizado que avalie aspectos pessoais; **derivar
  já é tratamento regulado**, sem "agir" — [Art. 4 GDPR (gdpr-info)](https://gdpr-info.eu/art-4-gdpr/), 2016.
- WP251rev.01 (Art. 29 WP / EDPB) — separa *profiling* (derivar/categorizar) de *automated
  decision-making* (decidir sem envolvimento humano); a intervenção humana precisa ser **real**
  (autoridade e competência para mudar a decisão) — [Guidelines on ADM and Profiling (WP251)](https://ec.europa.eu/newsroom/article29/items/612053/en), 2017/2018.
- **SCHUFA (C-634/21):** gerar o score (derivar) já é "automated individual decision-making" quando
  um terceiro se apoia fortemente nele — a responsabilidade recai sobre **quem perfila**, não só
  quem age — [Key takeaways from SCHUFA (Bird & Bird)](https://www.twobirds.com/en/insights/2023/global/key-takeaways-from-the-schufa-case-of-the-cjeu), dez/2023; [CJEU on credit score (A&O Shearman)](https://www.aoshearman.com/en/insights/ao-shearman-on-data/cjeu-rules-that-a-credit-score-constitutes-automated-decision-making-under-the-gdpr), 2023/2024.
- **EU AI Act** Art. 14 (human oversight) — alto risco exige supervisão humana efetiva (entender,
  monitorar, **sobrepor-se/parar**); Anexo III ponto 4 torna **monitoramento/avaliação de trabalho
  = alto risco** (obrigações plenas a partir de ago/2026) — [Article 14 (AI Act)](https://artificialintelligenceact.eu/article/14/), 2024; [Annex III HR & Employment (Knowlee)](https://www.knowlee.ai/blog/ai-act-annex-iii-hr-employment), 2024/2026.
- Wachter & Mittelstadt — a *inferência* é o ponto de maior risco e o mais fraco em proteção — [A Right to Reasonable Inferences](https://journals.library.columbia.edu/index.php/CBLR/article/view/3424), 2019.

**Tensões:** a linha derivar×agir é **porosa** (SCHUFA move o gatilho para quem infere), mas
perfilar regulado ≠ Art. 22 acionado (muita derivação fica no 1º nível). GDPR regula por *operação*;
AI Act por *domínio/risco* — "human intervention" (Art. 22) e "human oversight" (Art. 14) são
próximos mas não idênticos.

## B. Human-in-the-loop & propose-only — o gate de agir

O princípio converge: **o gate humano se justifica pelo efeito da saída, não pela leitura**. Ler e
recomendar é reversível; escrever/deletar/gastar/comunicar-em-nome-de produz efeito externo que pode
não se desfazer. Três padrões formam um espectro: **HITL** (aprovar antes de agir), **HOTL** (agir
sob supervisão que pode interromper), **human-in-command** (fixar parâmetros, revisar agregados). A
escolha é regida por **reversibilidade × impacto**. O padrão de engenharia 2025–2026 é a **autonomia
em camadas**: auto-aprovar o reversível, enfileirar o sensível, **bloquear o irreversível** até
aprovação — com a ressalva dura de que o gate deve ser **determinístico/de política, não o
auto-julgamento do agente**, e que HITL "de fachada" (carimbo sob pressão) não é supervisão.

- HITL (aprovar antes) / HOTL (supervisionar, interromper) / human-in-command (parâmetros + revisão) — [HITL vs HOTL in Agentic AI (Tek Leaders)](https://tekleaders.com/human-in-the-loop-vs-human-on-the-loop-agentic-ai/), s/d.
- AI Act Art. 14: entender limites, evitar *automation bias*, **decidir não usar / reverter**,
  **botão stop**, dupla verificação humana para biometria — [Article 14 (AI Act)](https://artificialintelligenceact.eu/article/14/), 2024.
- Em RPA: o bot age, mede confiança/risco e **escala exceções ao humano** antes de prosseguir — [Human-in-the-Loop Automation (Balto)](https://www.balto.ai/blog/what-is-human-in-the-loop-automation/), s/d; [Human in the Loop RPA (Moxo)](https://www.moxo.com/blog/human-in-the-loop-rpa), s/d.
- **Tiered autonomy:** Tier 1 auto-aprova (read-only, reversível, interno); Tier 2 enfileira; Tier 3
  bloqueia (financeiro, irreversível, legal) — [AI Agent Guardrails (BetterClaw)](https://www.betterclaw.io/blog/ai-agent-human-approval-guardrails), 2025; [Classify AI Agent Actions by Risk (MindStudio)](https://www.mindstudio.ai/blog/classify-ai-agent-actions-by-risk), s/d.
- Segurança de IA = **controle da irreversibilidade**; HITL superficial não preserva soberania — [AI Safety as Control of Irreversibility (arXiv)](https://arxiv.org/html/2605.01415v1), 2026.
- Gatear pelo **efeito de saída**; a autorização deve viver no sistema *downstream* (política
  determinística), **não** no julgamento do LLM — [Access Control in the Era of AI Agents (Auth0)](https://auth0.com/blog/access-control-in-the-era-of-ai-agents/), 2025–2026.

**Tensões:** aprovar tudo mata velocidade e gera fadiga (humano vira carimbo) → tiered autonomy, mas
a fronteira "reversível × irreversível" é julgamento, não fórmula; e "read-only" nem sempre é inócuo
(efeitos colaterais: marcar como lido, incrementar contador) — gatear pelo *side effect*, não pelo
verbo.

---

## Convergência com a doutrina interna do Onion (o achado central)

O estado-da-arte externo de 2026 **reencontra**, por caminhos independentes, o que a KB
[`authorization-layers-intake-vs-execution`](../../knowledge-base/concepts/authorization-layers-intake-vs-execution.md)
já cravou:

| Doutrina Onion (interna) | Estado-da-arte externo (2024–2026) |
|--------------------------|-------------------------------------|
| "guardar ≠ aceitar ≠ aplicar" — gatear no **efeito de saída** | gatear pelo *output effect / side effect*, não pela leitura (Auth0, MindStudio) |
| gate degrada para **VETO, nunca skip** (fail-safe) | bloquear o irreversível até aprovação; stop-button (AI Act 14) |
| `apply_mode: propose-only` para membros regulados | tiered autonomy Tier 3; RPA escala exceção ao humano |
| gate **determinístico** (shell/awk, "não aluga LLM") | autorização determinística *downstream*, **não** o auto-julgamento do agente |

O Onion não precisa importar o padrão — ele **já é** o padrão. O que a P2 acrescenta é: para um
**sensor**, a mesma linha se aplica **três vezes**, não uma.

## Implicações para a nota P2 (os 3 gates)

1. **Gate 1 — OBSERVAR** (pré-intake): herda a P1. Captura exige dupla autorização; sem ela, VETO.
2. **Zona de intake autônomo:** guardar → verificar/de-identificar → mapear em KG. Aqui vale a regra
   original: *guardar não é agir*. Autônomo, mas **local-first e escopado** (não-retenção > cifra).
3. **Gate 2 — INFERIR** (o gate novo, no meio): SCHUFA + Art. 4(4) mostram que **derivar já é ato
   regulado** — inferir/perfilar/agregar-cross-pessoa **não é intake livre**. Debita escopo/ε; a
   inferência entra no *threat model* (ecoa a lacuna da P1).
4. **Propor é propose-only:** guardar uma proposta de processo/automação ≠ aplicá-la — sem efeito de
   saída, fica na zona autônoma.
5. **Gate 3 — AGIR** (execução clássica): automatizar/decidir sobre a pessoa = Art. 22 + AI Act 14 +
   irreversibilidade. Só **humano** aplica; regulado = propose-only; supervisão **real**, não de
   fachada.
