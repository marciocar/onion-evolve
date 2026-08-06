---
title: "A refinaria, o motor, e a leva 1 executada — W3 + triagem dos 15 + M1/M2/M3/M7"
category: research
date: 2026-08-06
status: leva-1-executada-menu-aberto-para-escolha
method: "W3: Elenxo de 12 workers com `superacao` OBRIGATÓRIA em toda refutação (wf_083d49f2-3b2). Triagem: 9 workers, 2 lentes cegas + juiz opus/high por bloco (wf_7541c420-c55). Execução e medição pelo maestro-agente, com re-medição de todo número herdado."
run_id: "wf_083d49f2-3b2 + wf_7541c420-c55"
kg: docs/evolution/research/onion-refinaria-2026-08/onion-refinaria-2026-08.kg.yaml
verified_at: 2026-08-06
source: "medição direta no HEAD 3f10f75 + gh pr list (13 PRs antes do corte 2026-08-02) + env -i sobre 39 scripts"
---

# A refinaria, o motor, e o que foi executado

> **Projeção do grafo.** SSOT: [`onion-refinaria-2026-08.kg.yaml`](./onion-refinaria-2026-08.kg.yaml) (radar exit 0).

## A correção de método que rege esta rodada

> *"Uma escolha ou negativa deve vir acompanhada de uma **sugestão de superação** — e não um juiz de sim
> ou não, **por isso criamos o Elenxo**. As decisões nem sempre são zero e um."* — o maestro

O W2 refutou **5 de 5** e não propôs superação nenhuma. Isso não é Elenxo — *élenchos* é refutação **que
supera**. O W3 mecanizou a correção como campo **obrigatório** no schema, com a consequência **invertida**:

> **Refutação sem `superacao` é DESCARTADA — cai a refutação, não a proposta.**

**Resultado medido: 24 vereditos, 11 refutações, ZERO sem superação.**

## O terceiro termo da metáfora

```
BRUTO ──────────→ REFINO ──────────→ MOTOR
2.049 nós         existe, 16ms       NÃO EXISTE
de sobra          3 de 53 grafos
                  têm derivado (5,7%)
```

*"Um carro a gasolina não funciona com petróleo puro."* Eu vinha perguntando **"devemos derivar mais
nós?"** — isso é **cavar mais poço**. O veredito do levantamento:

> **"O que falta não é uma refinaria melhor — é um MOTOR que peça gasolina."**

Os ~5 casos de decisão-por-derivado que existem são **todos** de sessões que estavam **construindo o
instrumento**: dogfood do refinador, não consumo do refinado. Consequência de desenho adotada: **derivado
sem consumidor nomeado não entra no menu — vira pergunta.**

## O que foi EXECUTADO nesta leva

### M1 — o ⚠ que nomeia, e não reprova

A INTEGRIDADE cobra contradição **só para `REFUTES`** (`kg-radar.sh:438`). `SUPERSEDES` passava em
silêncio — e de **137** arestas, **15** apontavam para alvo ainda `confirmed`/`open`.

**A triagem justifica a forma da guarda:**

| remédio | casos | o que significa |
|---|---|---|
| **`CONSTRAINS`** | **8** | o superseder **refina**; o alvo segue vigente |
| **`done`** | **4** | pergunta **respondida** — não é história superada |
| **`superseded`** | **3** | só estes deixaram mesmo de valer |

> **Virar o status cegamente estaria errado em 12 de 15 (80%).** Um gate HARD que compra verde
> **corrompendo** o grafo é o verde falso invertido.

Por isso o M1 **nomeia com menu de remédios** e mantém `problems` intocado. Filtro deliberado: só acusa
se o **superseder** estiver `confirmed` — relação não assentada não cobra reconciliação do alvo.

**Verificado:** 14 avisos exatos antes · **0 depois** · REGRA 52 exit 0 nos 53 grafos **nas duas pontas**.
**Promoção a ✗ HARD segue gated** — gatilho: um 16º caso aparecer *depois* da triagem.

### M7 — o item que morreu por medição, de graça

A fatia mínima pedia *"conte nos próximos 3 PRs"*. Medi **retroativamente**: amostra **não-enviesada** e
resposta hoje, com corte de contaminação em 2026-08-02 (a partir daí eu mesmo passei a citar ids).

```
DENOMINADOR: 13 PRs tocaram .kg.yaml antes do corte
NUMERADOR:    1 cita id de nó no corpo            ≈ 8%
```

E o único positivo era uma sessão de Elenxo **escrevendo grafo**. **Fora de quem autora, ninguém cita.**
Custo: **zero linha de código**.

### M2 — o número selado, com o eixo certo

**356** decisões · **135** `confirmed` · **95 sem `verified_against` (70%)** · **90 fora do bloco de
frescor** (`kg-radar.sh:355`).

O eixo é **ANCORADO / NÃO-ANCORADO**, nunca *"medido × aposta"*: ~21 dos 39 `verified_against` nomeiam
**método ou autoridade**, não alvo — selar *"39 medidos"* carimbaria **declaração como medição**, o
erro-de-categoria que o item existia para denunciar, um nível acima.

### M3 — portabilidade executada, e um número herdado corrigido

**28 de 39** scripts saem **exit 0 sob `env -i`** (sem `HOME`, sem PATH do usuário, sem Claude Code); os
9 restantes saem 1/2 por **usage sem argumento**, não por dependência.

**Correção:** a leitura anterior dizia *30/39*. Re-executando, os 2 "timeouts" eram **artefato do meu
instrumento** (corte de 25s) — `lint-artifacts.sh` roda sob `env -i` em 43s, e seu exit 1 é **veredito
de lint**, não falha de portabilidade.

Este número **acrescenta chão** a `C_POSTURA_ACOPLAMENTO`; **não o edita nem o contradiz**.

## A guarda do maestro — com a medição que ela pediu

> *"Em algum momento vamos precisar rever nossos `lint-*.sh` … A estratégia do mecanismo pode ser
> revisada e **tem que ser provado, não pode ser achismo**."*

**O pull é datado e os números são desta sessão:**

| | |
|---|---|
| `lint-selftest.sh` | **606 guardas**, >600s — rodei **inteiro** para validar **5** casos novos |
| `lint-artifacts.sh` | **44,1s / 43,4s / 44,7s** em 3 rodadas — contra **~16s** pós-PR #357 = **regressão de ~2,75×** |
| onde o tempo está | sub-scripts somam **~9,2s (21%)**; **~35s (79%)** nas guardas *inline* do script de 2.800 linhas |

**Consequência de desenho:** *"rodar só a seção afetada"* **não é pular sub-script** — é **fatiar o
script principal**, onde a granularidade **não** é limpa como as 84 funções `run_*_selftests` do selftest.

**E o achado incômodo:** o número histórico (16s) **não está no repo** — vive só em memória de sessão.
A performance do gate **não tem carimbo versionado**, e por isso a regressão cresceu sem ninguém ver.

**A prova é o gate, e ela tem três passos:** (1) medir que fração das guardas uma mudança típica afeta ·
(2) provar que a execução parcial **não perde nada** — rodando o completo em paralelo e comparando
vereditos por N rodadas · (3) só então trocar. **Sem (2), é achismo com cara de otimização** — o modo de
falha exato que esta casa já mediu: *verde que não verificou*.

## O refinamento doutrinário que atravessou as duas levas

> **Taxa de defeito medida: 9 números errados em MESES.** Custo do gate (gerador + guarda + selftest +
> manutenção) **>** custo do conserto manual ⇒ **mecanizar É a catedral**.
>
> `fix-must-become-mechanism` **não** é *"todo fix vira gate"* — é *"todo fix vira mecanismo **quando o
> volume justifica**"*. Sem o portão 4, a doutrina anti-catedral **fabrica** catedral.

Aplicado nesta leva: os 9 números do `technical-context` viraram **conserto manual** (PR #542); o
`SUPERSEDES` não-reconciliado — **15 casos vivos, classe recorrente** — virou **guarda**.

## O que fica para a próxima decisão

A leva **para aqui**, por escolha do maestro: **M7 é a evidência barata que pode inverter a ordem**. Ele
voltou ≈0, e o contra-argumento da própria síntese dizia:

> *"Se M7 voltar 0/3 e M5 voltar 0/5, a ordem certa era a inversa — M1–M4 são polimento de um instrumento
> que ninguém lê."*

**Metade da condição está satisfeita.** Mas há uma distinção que não pode ser apagada: **o M1 não depende
de ninguém ler PR** — o consumidor dele é o `kg-radar --integrity`, que roda em **53 grafos por run de
CI** e em todo PR que toca `.kg.yaml`. Motor provado, não hipotético. O que o M7 refutou foi a projeção
**para humano no PR**, que é outra coisa.

**Restam no menu, para escolha e ordem do maestro:** M4 (fila de âncora) · M5 (`--state` como modo do
radar) · M6 (colheita do ledger de custo) · M8 (corrida serial reescopada) · M9 (a lacuna do porte).
