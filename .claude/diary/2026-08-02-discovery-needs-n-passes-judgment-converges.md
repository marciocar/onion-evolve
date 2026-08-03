---
date: 2026-08-02
instance: onion-evolve
type: learning
classification: collective
tags: [pesquisa, descoberta, loop-until-dry, uniao, orquestracao, elenxo]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "DESCOBERTA (achar itens de conjunto desconhecido: bugs, players, arquivos, riscos) precisa de N passadas com UNIÃO — uma passada cobre ~55-60%, medido. JULGAMENTO (avaliar um item conhecido) converge e não precisa. O padrão já existe e se chama `loop-until-dry` (para quando K rodadas seguidas não trazem nada novo) — está em `.claude/skills/onion-orchestration/SKILL.md`. A régua prática: se você não sabe QUANTOS itens existem, você está em descoberta; não confie na primeira passada, e não use `top-N` sem `log()` do que ficou de fora."
review_after: 2026-10-31
conflict_class: static
kg: docs/evolution/research/onion-market-kg-2026-08/onion-market-kg-2026-08.kg.yaml
significance: "Duas execuções IDÊNTICAS da mesma descoberta acharam 46 e 41 itens, união 74 — cada uma cobriu só 55-62%. Medi por acidente (rodei duplicado), e o número desmonta a confiança na passada única."
---

## Signal

**Descoberta com uma passada cobre ~55-60%. Julgamento converge.** São regimes diferentes e pedem
orquestrações diferentes — e eu tratei os dois como se fossem o mesmo.

## Evidência

Medi **por acidente**: um `ls -d` com segmento errado no caminho devolveu vazio, concluí que o
workflow tinha morrido, e **relancei um que estava vivo**. Ficaram duas execuções idênticas da mesma
descoberta rodando em paralelo — controle experimental que eu nunca teria montado de propósito.

| execução | itens achados |
|---|---|
| A | 46 |
| B | 41 |
| **união** | **74** |
| cobertura de cada uma | **62% e 55%** |

Mesmo prompt, mesmo escopo, mesmo modelo. A diferença **não é erro** — é a natureza da descoberta:
cada passada explora um caminho e não sabe o que não viu.

E o contraste, na mesma sessão: onde o trabalho era **julgar** itens já conhecidos (este achado é
real? esta peça é cerimônia?), rodadas independentes **convergiam** — o desacordo era raro e
resolvível por evidência.

A ironia que fecha o caso: o duplicado acidental produziu o **maior achado da sessão** (a YC nomeando
"Company Brain" sete dias depois de um nó nosso afirmar que a categoria não tinha nome). A passada
única teria perdido.

## O que fecha

O padrão certo **já existia e não foi usado**: `loop-until-dry` está escrito em
`.claude/skills/onion-orchestration/SKILL.md` — repetir finders até K rodadas seguidas não trazerem
nada novo. Não foi ignorância do padrão; foi **não reconhecer o regime**. A régua que faltava: *se
você não sabe quantos itens existem, você está em descoberta* — e aí passada única é amostra, não
varredura.

Casa com **`search-by-trajectory-not-by-name`** (memória) da mesma sessão: lá o eixo da
busca estava errado, aqui o **número de passadas**. Duas formas de a varredura mentir por completude.

## Fronteira honesta

O 55-62% é **uma medição, com n=2**, num tipo de tarefa (descoberta de players/ferramentas em fonte
aberta). Não é constante universal e não deve ser citado como tal. O que generaliza é a **direção** —
passada única subestima — não o número. E `loop-until-dry` custa tokens: o portão para usá-lo é
*"não sei o tamanho do conjunto"*, não *"quero mais confiança"*.
