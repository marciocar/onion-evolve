---
title: "Revisão — o 3º uso de /meta:kg-freshness, e a revisão que me reprovou"
date: 2026-08-29
branch: fix/kg-freshness-primeiro-dogfood
reviewer: "3 lentes adversariais opus/high (factual · sobre-alegação · doutrina) confrontadas com os journals brutos dos runs; os 2 achados ALTA foram RE-MEDIDOS por mim antes de aceitos, e a cura proposta foi provada por sonda na API"
reviewed_diff_sha256: 18437e6d58bdbf8b060df28f3c9d27a3825d1c982448abe7850706f1653f8ece
findings_total: 36
findings_real: 36
verdict: APROVADO_APOS_CORRECAO
tokens: 1853000
duration_min: 95
---

# Resíduo — REGRA 56

**3 de 3 lentes REPROVARAM. 36 achados, todos REAIS.** A aritmética não cedeu em nenhum ponto
— as lentes refizeram cada número contra os journals brutos e todos bateram. O que caiu foi a
camada de **label**: âncora no artefato errado, universais sobre amostra, e causa declarada onde
só houve sequência.

## Os dois ALTA que refutam nós centrais — re-medidos por mim antes de aceitos

| achado | como verifiquei | veredito |
|---|---|---|
| `verified_against` do nó-raiz aponta o run **errado** | `grep` do erro nos dois runs: **0** em `wf_3790d38b-6a8`, **8** em `wf_6aa135ec-1e2` | **PROCEDE** — corrigido |
| `C_A_GUARDA_BLOQUEIA_A_PROPRIA_CURA` é **falso** | montei a cura em `if/then/else` aninhado: guarda **rc=0**; e sonda `wf_742e3a39-e7f` → **API aceita** | **PROCEDE** — nó `refuted` |

O segundo é o erro mais grave que cometi aqui: **medi uma variante destrutiva** (apagar o
`allOf` *e as guardas junto*) e generalizei para *"a única forma que a API aceita"*. É o
universal-sobre-amostra que eu estava acusando nos workers, na mesma página.

A consequência é boa: **a cura é uma reestruturação de ~12 linhas no schema**, e a guarda
estrutural **não precisa mudar**.

## O que mais caiu, e foi corrigido no grafo

- **"primeiro dogfood"** — falso. O comando já rodara ponta a ponta em 2026-08-12 com **16
  workers** (`wf_7804d86f-3a7`). Este é o **3º uso**.
- **"nenhum tinha medição que o sustentasse"** — falso. **4 dos 8** trazem `reverify_note` de
  08-23 com re-verificação ao vivo.
- **"três exemplos" da skill** — são **dois**; o terceiro está quebrado por outro defeito.
  Contar o mesmo bloco duas vezes é a mesma manobra de denominador que o grafo acusa.
- **"apenas na própria skill"** — o defeito está em **três arquivos**: as duas cópias de plugin
  têm md5 idêntico, e são o **canal de instalação**.
- **3 evidence** → são **quatro** (3 decision + 4 evidence + 1 claim).
- **"dois nós com reverify_note"** → **quatro de oito** — metade da amostra.
- **C_PROJETOR CAUSES E_ESPELHO** — o projetor resolveu o arquivo **certo** nesta passada; a
  falta de ancoragem é risco **latente**, não a causa medida. E o dano anunciado excedia o
  medido: `--enroll` com SSOT caduco **falha fechado** (exit 7).
- **Duas arestas CAUSES eram sequência**, não causa — inclusive `E_ALLOF → E_ZERO`, impossível:
  a medição rodou **com o `allOf` já removido**.

## A autocontradição que mais dói

`C_TAMANHO_DO_NO_PREVE_VERIFICABILIDADE` calculava "70% de cobertura real, número que nunca
existiu antes" **sobre os denominadores que o nó vizinho declara subcontados em ~48%**. Recontando
com os juízes: cobertura cai para **~56%**, a razão desaba de **2,6× para ~1,33×**, e o universal
*"todo nó com ≥8 voltou parcial"* é falsificado pelo próprio corpus. **Rebaixado a `question`.**

## A prova reflexiva

O juiz adversarial pegou a subcontagem de 3 dos 4 workers. Virado contra **este** grafo, achou
36 defeitos meus. É o argumento mais forte do PR e não é retórico: **o juiz não é ornamento do
fluxo — é a etapa sem a qual o fluxo publica o próprio erro com carimbo.**

## Reconciliação (Aufhebung, não apagamento)

`--reconcile` agora mostra 3: um `REFUTES` sobre a tese da guarda, um `SUPERSEDES` da decisão
antiga pela nova, e um `REFUTES` sobre a premissa da migração. **As posições derrubadas ficam** —
são elas que explicam o desenho novo.

## Gate mecânico

- `kg-radar.sh --integrity --schema` → **exit 0** (22 nós, 21 arestas)
- lint no pre-commit → **0 HARD**
- Nada carimbado no grafo M2 — a regra do comando cumprida
