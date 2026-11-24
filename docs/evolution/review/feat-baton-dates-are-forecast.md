---
branch: feat/baton-dates-are-forecast
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: pendente
findings_total: 13
findings_real: 12
findings_blocking: 2
tokens: 81138
duration_min: 5
findings_fixed: 10
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: code-reviewer em contexto isolado (subagente só leitura com tm.sh falsos e repos de teste; recebeu o diff e o objetivo, não a minha conclusão)
nota: "12 achados reais: 10 curados no mesmo PR e 2 parciais declarados como limite (vocabulário de espera e mutantes por alternativa da regex). Os 2 que bloqueavam: o nó destravado pelo /meta:decide sumia pela causa antiga na narrativa, e o card sem data saía da fila por prosa técnica no corpo."
---

# Casar espera na prosa escondia justamente o nó que o maestro destravou

## O que muda

Toda data passa a ser **previsão** por padrão, e só vira **espera** quando o item declara a causa que trava. O reforço veio do maestro: «nem toda data é espera; isso não pode ser memória, tem de ser doutrina e maquinaria».

- **Doutrina:** a cláusula 11 da doutrina da batuta e uma seção nova na doutrina da data no compromisso.
- **Maquinaria (`baton-pulse.sh`):** card com `dueDate` futura e nó `open` com `x_due` futura contam como trabalho pronto e saem na oferta como «adiantável (prevista <data>)».
  - **A espera declarada** pode estar em três lugares: no título do card, numa linha do corpo que começa pela causa («Aguarda:», «Pré-registro:», «Janela de observação:», «Gatilho:»…) ou no campo `x_wait:` do nó.
  - **A sessão `IDLE_WITH_QUEUE`** com nó adiantável recebe a oferta, e a batida não cala.
  - **O relatório** ganhou a seção «Adiantáveis», para a revisão item a item ao terminar uma tarefa.

## Achados

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | o nó pedido pelo `/meta:decide` virava espera, porque o selo acrescenta o pedido sob o «Gatilho: …» antigo da narrativa | bloqueia | curado: a narrativa não conta; no nó vale o campo `x_wait:` ou o rótulo. Caso (cq), com essa narrativa no fixture |
| 2 | card sem data saía da fila por prosa técnica no corpo | bloqueia | curado: o corpo só conta para card com data futura. Caso (cs) |
| 3 | falsos positivos («Etapa 0 pré-registrada», «aguarda a calibração», «o gatilho está armado») | média | curado: no corpo vale só a linha que começa pela causa, na forma «Causa:». Caso (cs) |
| 4 | falsos negativos («aguardar», «esperando», «bloqueado por», sem acento) | média | parcial: título e corpo aceitam essas formas e «observacao»; «depende de» e «parqueado» ficam de fora (limite) |
| 5 | assimetria entre nó e card | média | curado: nos dois, a espera só vale para item com data futura |
| 6 | nenhum teste prendia o `--with-description` | média | curado: o tm.sh falso confere o `$4` |
| 7 | data inválida virava adiantável | baixa | curado: `date.fromisoformat`. Caso (cs) |
| 8 | «hoje» calculado em UTC | baixa | curado: fuso `BATON_TZ`, padrão America/Sao_Paulo |
| 9 | o rótulo de contagem ficou enganoso; a espera só aparecia no TSV | baixa | curado: «fora de estado pronto» separado de «espera declarada»; as contagens também saem no markdown |
| 10 | o cache passou a guardar o corpo dos cards, e o comentário ficou velho | baixa | curado: o comentário diz que o cache guarda título e corpo, em 0600 |
| 11 | mutantes faltando para cada alternativa da regex | baixa | parcial: o (cs) cobre a forma declarada contra a prosa; uma alternativa por mutante fica como limite |
| 12 | «ao terminar, pergunte item a item» sem maquinaria | baixa | curado em parte: a seção «Adiantáveis» do relatório é o ponto de consulta. O ato de perguntar segue da sessão |
| 13 | sha, oferta entre nó e card, campos ausentes, `null`, `x_due` sem aspas | não-defeito | — |

## Mutantes

Casos (co), (cp), (cq), (cr) e (cs), cada um com o seu mutante. Os mutantes de (cb), (cp) e (cr) mudaram de âncora para as regex novas (`WAIT_TITLE`, `WAIT_DECL`, `x_wait`).

## Limites declarados

- **Vocabulário de espera:** é uma lista. «Depende de» e «parqueado» não entram, porque casariam prosa demais. A forma robusta é o campo estruturado (`x_wait:` no nó). No Linear, a forma equivalente seria uma label de espera, ainda não adotada.
- **A revisão item a item** ao terminar uma tarefa é ato da sessão. O pulso entrega a lista, mas não a pergunta por ela.

## Re-revisão pós-rebase (2026-11-24)

- **O que foi feito:** o #1722, base desta pilha, entrou na main com sha novo (`30206db89`, diferente do `4676ccfdf` da pilha), então o git não reconheceu o patch. Rebase com `git rebase --onto origin/main b9fe9e41b`, levando só os 2 commits deste PR (a feature e a projeção). Os commits já mergeados pelo #1722 (`606a5dd10`, `33d2714f6`, `4676ccfdf`, `b9fe9e41b`) ficaram de fora.
- **Conflitos:** nenhum textual. O ponto delicado era semântico: a main ganhou, depois da base antiga, o aviso do reinício gracioso (`restart-drain.sh`) no `baton-pulse.sh`, com a chave `'rs'` no estado do sha. Conferido: o estado final carrega as duas, `'rs'` da main e `'of'` (ofertas) do PR, e o `bash -n` passa no `baton-pulse.sh` e no `lint-selftest.sh`.
- **Bancada:** `LC_ALL=C nice -n 10 timeout 1500 bash .claude/validation/lint-selftest.sh --families baton_pulse,restart_drain`, com rc 0: **200 passaram, 0 pularam, 0 falharam**.
- **Revisão isolada:** o resíduo segue com `elenxo_isolado: true`, da revisão de 2026-11-21. O rebase não mudou o código do PR, mas mudou a base, então `reviewed_diff_sha256` voltou a `pendente` e a linha `reviewed_code_sha256` saiu.
