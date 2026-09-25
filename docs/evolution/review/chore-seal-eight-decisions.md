---
title: 'Selagem das oito decisões — sem passada adversarial, e por quê'
date: 2026-09-25
branch: chore/seal-eight-decisions
reviewed_diff_sha256: ecc94057db8a1624755c129e5361e19f10ca7d67f7a54af2b29ea2af35d90c3f
elenxo: nao
findings_total: 3
findings_real: 3
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, e a ausência é declarada em vez de omitida: este diff não PROPÕE nada — ele REGISTRA oito escolhas que o maestro já fez, cada uma apresentada com opções nomeadas e recomendação. Um refutador aqui interrogaria a decisão DELE, não um artefato meu, e a tabela de selagem do /meta:drive é explícita: decisão não-tomada PARA para o maestro; decisão TOMADA se registra. Os 3 achados listados são MEUS, pegos por guarda determinística e por leitura do artefato durante a própria selagem.'
---

# Resíduo — selagem das oito decisões

## O que este diff é, e o que ele NÃO é

**É** o registro de oito escolhas do maestro, com o critério de cada uma no `label` do nó — porque
quem reabrir isto em seis meses precisa do critério, não do rótulo. **Não é** proposta: nada aqui
pede aprovação, e por isso não houve passada adversarial. A ausência está declarada no frontmatter
(`elenxo: nao`) em vez de silenciada, que é a diferença entre limite conhecido e limite escondido.

## Os três defeitos meus, todos apanhados

| # | o que eu fiz de errado | quem pegou |
|---|---|---|
| 1 | inventei `sealed_at`/`sealed_by` para um conceito que **já tem palavra** no schema | **REGRA 58 (O backlog cumpre as promessas do próprio `meta:`)**, com `DONE-NU`: *"quem não consegue carimbar não pode declarar feito"* |
| 2 | `index("- id: X")` casa id por **PREFIXO** | leitura nó a nó; acertou por sorte |
| 3 | meu `awk` de verificação reportou os oito como `open` | ler o artefato direto |

**(1) é o mais instrutivo, e é a classe pelo lado oposto.** A casa tem uma lição sobre guarda de lista
falhar pelo vocabulário; aqui eu criei vocabulário novo para um conceito existente, que produz o mesmo
dano por outra porta: dois nomes para a mesma coisa, e nenhuma guarda cobrindo o segundo. A cura foi
usar `verified_at` + `verified_against`, **preservando o registro anterior** de cada nó em vez de
sobrescrevê-lo.

**(2) é o defeito que a âncora de fim do lint existe para evitar** (`_ROLE_TAIL`, para que
`role: adoptedX` não seja confundido com `adopted`). Cometi a versão em Python do mesmo erro, no
mesmo dia em que curei uma guarda por casar substring. Que o alvo certo tenha sido atingido é sorte,
não método — e sorte não é verificação.

**(3) foi a terceira varredura minha a mentir hoje**, e as três mentiram do mesmo jeito: estado que
não se limpa entre iterações. O que salvou nas três foi ler o artefato em vez de acreditar no resumo.

## O que o selo afirma, e o que ele deliberadamente NÃO afirma

`verified_against` diz que a verificação foi **o ato de decidir** — quem decidiu, quando, e com quais
opções na mesa. **Não** afirma medição contra o vivo, porque decisão não se mede, se toma. A distinção
importa para a próxima sessão que ler estes nós: nenhum deles ganhou `verified_at` por alguém ter
conferido algo no mundo, e fingir o contrário seria carimbo-sem-medição — exatamente o que o
`/meta:kg-freshness` existe para impedir.

Uma decisão sela **parcialmente** e isso está dito no nó: **D_D5** sela a ESTRUTURA (quais degraus são
vendíveis-já) e deixa os NÚMEROS abertos, porque os valores são chamada do maestro e nenhuma sessão os
preenche por ele.

## Gate

- `lint-artifacts.sh` → **rc=0 · 0 HARD · 13 SOFT**
- `kg-radar.sh --integrity --schema` → **exit 0 nos 8 grafos tocados**
- `lint-selftest.sh --affected-staged --jobs auto` → **45 casos · 0 falhas**
- `docs/backlog.md` regenerado (REGRA 62 — os oito saem da fila de abertos por projeção, não à mão)
