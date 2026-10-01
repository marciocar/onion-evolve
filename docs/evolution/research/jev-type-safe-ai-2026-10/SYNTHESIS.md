---
kg: docs/evolution/research/jev-type-safe-ai-2026-10/jev-type-safe-ai-2026-10.kg.yaml
kg_round2: docs/evolution/research/jev-type-safe-ai-2026-10/jev-decision-round2-2026-10.kg.yaml
run_id: wf_0fe3f8d2-88c + wf_61b79cac-2ac
tokens: 3542823
agents: 138
duration_min: 53
review_after: 2027-01-01
---

# JEV / TypeSafe AI — o que é, e por que o slogan não é do fabricante

## O achado que reenquadra a pergunta

**`jevtypesafeai.com` não é do fabricante.** O rodapé declara: *"independently operated by CODEFASHION
TECH LTD and is not affiliated with or endorsed by TypeSafe AI"*. Duas consequências medidas:

- **preço 6–10× inflado**: o fabricante cobra **US$ 0,042/M** de entrada (`$42 Per Billion`,
  typesafe.ai); o site lido cobra US$ 0,25–0,42/M
- **"0 hallucinations by construction" é slogan do revendedor** — o fabricante formula o oposto em
  tom: entrega estimativa de confiança **para o software escalar quando não estiver confiante**

## O que o JEV é

"System One Model" da TypeSafe: hospedado, fechado, acessado por API. **Devolve decisão tipada, não
texto.** Uma chamada leva `state` + perguntas tipadas e volta em **passada paralela única**, sem parsing.

Três primitivas: **Choice** (até 255 rótulos), **Score** (2–10 níveis ordenados), **Noul**
(probabilidade 0–1). Latência **70–500 ms**, 40–200× mais rápido que um LLM. Janela **32k** em
`jev-1.13.0`. Treino por RLCD. Acesso por lista de espera / Cloudflare Workers AI. Permite **fixar a
versão** "para os limiares não deslocarem".

## A garantia real, e o seu tamanho

*"cannot make a type error and cannot return an option that was not in your list"* — decodificação em
**conjunto fechado**. Garantia sobre a **FORMA**, não sobre a **VERDADE**. A cobertura independente é
explícita: *"a confidently wrong typed answer is still possible"*.

E a propriedade que o fabricante de fato oferece — **probabilidade calibrada** — **não tem um número em
nenhuma fonte**: zero ECE, zero Brier, zero dataset, zero avaliação. É a lacuna que decide tudo.

## Onde encaixaria no Onion

**Não** em gate determinístico — a doc manda fixar versão para o limiar não deslocar (fronteira de
decisão **não-determinística no tempo**), resposta tipada confiantemente errada é possível, e o `noul`,
justamente a primitiva de guardrail, devolve **número nu sem confiança**.

**Poderia** nas camadas que **aconselham**: triagem, roteamento de modelo/skill, priorização de atenção,
pré-filtro de parecer — a metade que o `CLAUDE.md` já mede como **52.655 linhas de markdown que
ACONSELHA**, contra as 26.596 de shell que REPROVA.

## NÃO-VERIFICADOS

- **calibração**: nenhum número publicado em nenhuma das fontes
- **arquitetura e treino**: nenhuma fonte diz como o modelo é construído
- **"não há MCP nativo"**: **pesquisado, não medido** — nenhum servidor foi instalado nem chamado

## valeu-a-pena

3.542.823 tokens ÷ 75 nós = **~47k por nó**. Faixa de primárias (42k), não de varredura (291k) — porque
a rodada 1 teve fontes nomeadas. O custo se pagou no reenquadramento: sem ela, o Onion teria absorvido
o preço do revendedor e o slogan dele como posição do produto.
