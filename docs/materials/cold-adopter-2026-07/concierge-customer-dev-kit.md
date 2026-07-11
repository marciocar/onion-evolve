---
title: "Kit concierge — teste ativo de pull arms-length (Instrumento B)"
category: materials
tags: [concierge, customer-development, cold-adopter, jtbd, experimento-B, playbook]
status: pronto-para-executar
audience: INTERNO — playbook do maestro (não postar)
date: 2026-07-11
experimento: docs/analysis/onion-experiment-cold-adopter-2026-07.md (Instrumento B)
relacionado: ["@pain-price-specialist", "@product-agent"]
---

# Kit concierge — teste ativo de pull arms-length

> Playbook para conduzir 1–3 sessões com parceiros **arms-length** e medir **pull real** pelo método KG.
> **O sinal é UM só: eles continuam sozinhos depois da sessão.** Elogio na sessão **não conta**.

## 1. Recrutamento — quem é (e quem NÃO é) arms-length

**Qualifica** (pull válido): alguém que **não deve nada a você** e **não foi empurrado** — encontrado nas
comunidades onde a dor já se discute (knowledge-reconciliation, Company-Brain, spec-driven, context-engineering,
GRC/compliance-knowledge). Ideal: alguém que **já reclamou** de drift de conhecimento / verdade contraditória.

**NÃO qualifica** (contamina o sinal — lição `C_ORBIT_CAVEAT`): repos seus · clientes seus · pessoas onde você
é CTO/consultor · amigos/rede pessoal · quem você convidou pedindo favor. Se você teve que puxar, não é pull.

**Meta:** 1–3 parceiros. **1 genuíno já falsifica "zero pull"** — é existência, não amostra estatística.

## 2. Antes da sessão (prep mínimo)

- Tenha o [one-pager](one-pager-kg-reconciliation.md) e o [`.kg.yaml` de exemplo](example-domain.kg.yaml) à mão.
- **NÃO mande material antes.** A sessão é de descoberta, não de demo. Chegue sem pitch.
- Prepare o radar rodável (onion-mini) para reconciliar **o domínio DELES**, ao vivo.

## 3. Roteiro da sessão (60–90 min)

### Parte 1 — Descoberta da dor (25 min · NÃO pitche)
Enquadramento JTBD/pain (@pain-price-specialist). Perguntas abertas, você **ouve**:
- "Como o time guarda o que sabe — decisões, regras, o que é verdade sobre o produto/cliente?"
- "Já aconteceu de **duas fontes discordarem** e ninguém saber qual valia? Conte."
- "Quando uma verdade **muda**, como o resto fica sabendo? O que quebra?"
- "O que você faz hoje quando o doc diz X e a produção faz Y?"
> Objetivo: achar **uma** dor real de contradição/drift **deles**. Se não houver, anote e encerre — sem dor, sem teste.

### Parte 2 — Reconciliação ao vivo (30 min · deixe ELES verem)
- Pegue a dor da Parte 1 e modele **com eles** um `.kg.yaml` pequeno (5–10 nós) do domínio **deles**.
- Marque a contradição com `REFUTES`/`SUPERSEDES`. Rode o radar. **Deixe o veredito aparecer.**
- Silêncio produtivo: deixe **eles** reagirem ao que o radar pegou que a prosa deles escondia.

### Parte 3 — Entrega e recuo (10 min · o teste começa aqui)
- Entregue o `.kg.yaml` deles + o schema + o ponteiro pro onion-mini.
- **NÃO peça adoção. NÃO agende follow-up de vendas.** Diga só: *"é seu; roda quando quiser."*
- O experimento **começa quando você recua.**

## 4. Medição — o sinal (e o anti-sinal)

| Conta como PULL ✅ | NÃO conta ❌ |
|---|---|
| Em **7–14 dias, sem você puxar**, eles produzem um `.kg.yaml` novo (outra área) | "Adorei!", "muito legal", "vou usar sim" (elogio educado) |
| Voltam com **pergunta de adoção concreta** ("como faço X no meu caso?") | Curtida, star, compartilhar o link |
| Aplicam o método **sem você presente** e contam | Concordar na sessão / responder pesquisa |

Regra: **iniciativa deles, sem seu empurrão, dentro de 14 dias.** Você **não** manda lembrete — o lembrete
contamina o sinal (vira empurrão).

## 5. Guardas anti-viés (o modo de falha do concierge)

- **Não venda.** No instante em que você convence, deixou de medir demanda e passou a fabricá-la.
- **Não racionalize silêncio.** "Ele tá ocupado" ≠ pull. Ausência de iniciativa em 14 dias = H0 para aquele parceiro.
- **Separe interesse de intenção.** Interesse é barato; produzir-sozinho é caro. Só o caro conta.

## 6. Captura do resultado (dogfood recursivo)

Cada sessão vira **claim no grafo de identidade** (`onion-identity-2026-07.kg.yaml`):
- Pull genuíno → `evidence` + aresta **`SUPPORTS`** → `Q_COLD_ADOPTER`.
- Bounce/silêncio → `evidence` + aresta **`REFUTES`** → a hipótese de pull.
- Rode o radar ao fim das 3 sessões: o veredito por-verdade decide **NS1 (destrava)** × **NS3 (hedge)**.
