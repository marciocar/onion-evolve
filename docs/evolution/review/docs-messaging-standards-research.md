---
title: 'Resíduo — a pilha do onion-messaging selada, com a síntese dos dois runs'
date: 2026-11-06
branch: docs/messaging-standards-research
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 4
findings_blocking: 0
findings_fixed: 4
tokens: 0
duration_min: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: passada própria sobre o diff inteiro (sem subagente, por regra do brief), com o gate mecânico (radar, contrato, lint de nomes, backlog-check)
nota: >-
  Passada adversarial própria sobre a SYNTHESIS, os selos e os JSON de data/, conferindo cada número e cada
  frase contra o grafo e os retornos dos runs. Quatro afirmações da síntese iam além da fonte e foram
  corrigidas; nenhuma bloqueava. Os dois itens restantes são confirmações. tokens 0 = não medido (a passada
  rodou na sessão do agente, sem contador próprio).
---

# A síntese dizia mais do que os dois runs mediram, em quatro frases

## O que entrou

- O diretório `docs/evolution/research/messaging-standards-2026-11/`, movido do checkout da main, com o grafo
  de 115 nós escrito pelos dois runs do `/onion-research`.
- O selo de `D_MESSAGING_STACK_2026_11` e cinco selos novos pelo `kg-decide-seal.sh` (o teto do grafo sobe de
  115 para 120, com o motivo no `meta:`).
- `SYNTHESIS.md` como projeção do grafo e os retornos dos runs em `data/`, sem caminho de máquina.
- `docs/backlog.md` regenerado.

## Os achados e o destino de cada um

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | "É a mesma razão medida em 2026-09-13": a medida de 09-13 é 291 mil contra 42 mil tokens por nó (quase 7x); a desta rodada é 3,4x | menor | curado: "vai na mesma direção", com os números de 09-13 |
| 2 | "A campainha vale só depois dele (o smoke)": regra minha, não do selo nem da objeção `E_OBJECAO_F5_PIN_CC_AND_RESMOKE` | menor | curado: "a campainha selada segue sem medida nela" |
| 3 | "porque o README o declara alpha" atribuía ao maestro um motivo que ele não deu | menor | curado: o motivo virou fato separado (alpha no README, não rodado no core) |
| 4 | "release v0.6.0 visível só na API do GitHub": o nó diz "fora do README", não "só" | menor | curado: "visível na API do GitHub e não no README" |
| 5 | os JSON de `data/` carregam caminho de máquina, segredo ou nome de cliente? | — | confirmação: varredura por `/home`, `/tmp`, prefixos de token e nomes de adotante deu zero |
| 6 | as contagens da síntese batem com os retornos? | — | confirmação: 20 de 25 confirmadas, 5 refutadas, 34 de 49 URLs e 39 de 64 claims fora por orçamento, 15 ancoradas e 8 rejeitadas, 118 agentes, 8.732.849 tokens, 44 min |

## O que o gate achou antes da passada (fora da contagem)

O `ops/kg-vocab-ci.sh` reprovou 11 códigos curtos sem termo nas narrativas que o workflow escreveu (`P4`,
`F1`, `F11`, `r1`, `r2`). O grafo era novo para o CI, por isso a dívida apareceu agora. Curado escrevendo por
extenso: "passo 4", "réplicas 1 e 2" e os ids completos das objeções.

## Decisões de forma (declaradas, não achados)

- `D_MESSAGING_DEVICE_FLOW_LOGTO_JA_1106` liga por `TRACES_TO` a `D_MESSAGING_IDENTIDADE_DOIS_ADAPTERS_1106`,
  não direto à pilha: ela é uma sub-decisão do adapter Logto. Os outros quatro selos novos ligam à pilha.
- O `trace:` que aponta a síntese foi posto em `D_MESSAGING_IDENTIDADE_DOIS_ADAPTERS_1106`. Os outros quatro
  selos novos seguem sem `trace:`, porque o selador não o escreve e o brief pedia um só.
- O `meta.review_after` ficou em 2026-12-06 (30 dias, o tipo dominante é ferramenta), que já era a cadência.

## O que a passada NÃO cobriu (declarado)

- Não re-li as fontes primárias: as afirmações da síntese foram conferidas contra o grafo e os JSON, não
  contra a web.
- O conteúdo dos 115 nós escritos pelos runs não foi re-revisado; só os 11 códigos do lint foram tocados.
