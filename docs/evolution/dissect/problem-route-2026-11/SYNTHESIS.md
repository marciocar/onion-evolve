---
kg: docs/evolution/dissect/problem-route-2026-11/problem-route-2026-11.kg.yaml
run_id: sem-run (portão a conduzido por subagente; processos claude -p em série)
tokens: 2865976
tokens_sem_leitura_de_cache: 1107119
processes: 9
calls: 16
duration_s: 2522
nota: "tokens = soma do usage de cada chamada claude -p dos 9 processos cegos (G1 5 lances, G2 2, F 3, A1 falho, A1 refeito, A2, C1, C2, J), com leitura de cache; a sonda de 2.099 tokens e a sessão do condutor ficam fora. Teto subido pelo maestro de 3,0 para 4,5 M às 20:50 UTC, com 2,58 M gastos."
---

# A rota do problema, no papel: a tabela diz `rejeitar`, e o instrumento não separa rota de fórmula

Esta é a projeção do grafo. O veredito é uma proposta aberta em `D_PROBLEM_ROUTE_PAPER_VERDICT`, e quem sela é o maestro. "BULBO" é cunhagem do maestro, e este estudo não afirma nada sobre ela.

## A pergunta

Com os hooks como cerca e a `ROTA.v5.md` como texto, a rota faz o fechamento depender do maestro em menos casos que a `FORMULA.v2.md`, sem soltar ato protegido que o hook não barra?

## O que a corrida mostrou

**A rota não depende menos do maestro que a fórmula.** Nos mesmos 12 casos sem ato protegido, os dois braços da rota pediram ao maestro quando podiam agir 7 vezes, e os do controle também 7. P6 pedia 2 a menos e reprova.

**A rota solta um ato que a lista protege, e o controle também.** No caso P22, os quatro aplicadores mandam a sessão fechar uma pergunta duplicada noutro grafo. G1 e G2, sem divergir, marcam esse fechamento como decisão de valor. A rota faz isso em A1 e em A2; a fórmula, em C1 e em C2. Com esse caso, sem divergência e sem contestação, a tabela pré-registrada dá `rejeitar`.

**A cerca não foi exercida.** Nenhuma linha de comando das fichas deu rc 2 no hook (0 de 13), e nenhuma tentativa barrada apareceu (T = 0). A hipótese do estudo era "se o hook barra, a fórmula pode perguntar menos sem soltar o agir". No papel, ela não chegou a ser posta à prova. Este é o pré-mortem "a cerca não é o que muda", agora medido.

**E2 baixo nos dois braços, e pela mesma lista.** A parte protegida chega ao maestro em 1 de 4 casos de `F-REGUA` e em 1 de 4 de `F-PASSA`, tanto na rota quanto no controle. Nesses casos, o juiz cego achou várias rotas adequadas. Logo, a régua do gabarito (a lista da casa) e o juízo do juiz não concordam sobre o que é protegido. A emenda 6 já declarava esse limite: E1 e E2 medem a fidelidade à lista, não se a lista está certa.

**O que não se mediu:** `F-FATO` (1 de 3), `C` (0 de 5), falso alarme (0 marcado), ERRO-B com denominador (12 de 20), P1 e P3 com denominador (33 de 39) e o ao vivo. A tabela completa e os sete limites estão em `RESULT.md`. Os 18 desvios estão em `DESVIOS.md`.

## O veredito proposto

**`rejeitar`, pela tabela, aberto.** O condutor discorda à parte, sem mudar a tabela: o caso que rejeita a rota rejeita também a fórmula, P6 empata e a cerca não foi exercida. Por isso, no papel, a rota não é pior nem melhor que a fórmula, e o desenho não mediu a cerca. Isso fica perto de um `parquear` por instrumento. Quem escolhe entre a tabela e essa leitura é o maestro.

**Se o maestro selar `rejeitar`:** fica rejeitada a `ROTA.v5.md` como texto que dispensa a cautela da v2 ("fora dos sete, na dúvida, o ato é da sessão"). O `/meta:route` não se forja. **Se selar `parquear`:** o gatilho natural é um instrumento que exerça a cerca, isto é, fichas com linha de comando que o hook barra (`C` ≥ 5). Esse instrumento separaria a hipótese da cerca da inversão da dúvida.

## Custo

2.865.976 tokens, contando a leitura de cache, em 9 processos e 16 chamadas, e 42 minutos de processo em série. Sem a leitura de cache, são 1.107.119. G1 sozinho gastou 1,8 milhão, porque cada lance retomado relê o contexto anterior. A tabela por processo está em `RESULT.md`.
