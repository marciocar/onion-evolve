---
kg: docs/evolution/research/engenharia-de-corpus-de-regras-2026-10/engenharia-de-corpus-de-regras-2026-10.kg.yaml
pre_registro: docs/evolution/research/engenharia-de-corpus-de-regras-2026-10/PRE-REGISTRO-aposta.md
run_id: wf_2361d115-99e
tokens: 9564636
agents: 140
duration_min: 81
review_after: 2027-01-01
---

# Engenharia de um corpus de regras — e o confronto da aposta pré-registrada

## A resposta primeiro

Nos sete eixos, **o único lugar com análise estática REAL de corpus é AUTORIZAÇÃO** (Cedar, por SMT com
prova em Lean). E isso **não se compra para guardas em shell**, porque o poder vem da **linguagem
restrita**, não da ferramenta.

**No eixo 3 — sequenciamento, o de maior interesse — a arte NÃO resolve:**

- o ESLint só descobre conflito de fix **executando**, em múltiplos passes, e **o aviso não nomeia as
  regras**
- os hooks do Claude Code rodam **em paralelo**, sem ordem garantida dentro do mesmo evento — logo a
  ordem **não pode morar na lista de hooks**, tem de viver num **despachante único**
- a **única convenção de ordenação achada** é uma heurística de uma linha (pacote `precommit` do R):
  **quem só LÊ roda depois de quem ESCREVE**

Essa heurística é exatamente o que falta aqui, e é **derivável do corpo da guarda** como a severidade já
é — sem obrigar ninguém a desenhar DAG.

## O confronto do pré-registro (escrito ANTES do resultado)

| critério | veredito | evidência |
|---|---|---|
| **R6** — sequenciamento antes de cobertura | **CONFIRMADO** | a arte não resolve, e entrega a heurística derivável |
| **R1** — cobertura destrava conflito | **SOBREVIVEU → meu passo 3 era FALSO** | conflito se detecta em runtime ou estaticamente sobre a DEFINIÇÃO; nenhum caminho usa contador de disparo |
| **R2** — adotar seria mais barato | **CAIU** | zero sinal de capital: ninguém vende "saber quais das suas 91 regras estão vivas" |
| **R4** — contador não seria barato | **CAIU** | precedente `bully-review`: telemetria JSONL com `violation_rate` |
| **R3** — a dor é ruído, não regra morta | **não resolvido** | aposentadoria por métrica só como anedota (GitLab removendo `detect-object-injection`) |
| **R5** — "nunca disparou" pode ser sucesso | **SOBREVIVEU** | a arte não distingue; a separação bancada=capacidade × contador=relevância segue minha, não verificada |

**Conclusão honesta: a aposta erra na prioridade e no mecanismo-destravador; acerta no custo e no
"absorver, não adotar".**

## NÃO-VERIFICADOS

- **Semgrep deduplica ACHADOS por fingerprint, nunca REGRAS** — não há dedup de corpus em lugar nenhum
- **aposentadoria por métrica**: anedota, não prática medida
- **mercado**: ausência declarada e medida — gestão de corpus de regras é dor de **engenharia interna**,
  não categoria que capital persegue. Isso é argumento **a favor** de absorver em shell

## valeu-a-pena

9.564.636 tokens ÷ 44 nós = **~217k por nó**. Três dos sete eixos voltaram vazios ou anedóticos — e
**isso é resultado**: pagou-se preço de varredura para descobrir **ausência**, que é exatamente o que
impede adotar ferramenta que não existe.
