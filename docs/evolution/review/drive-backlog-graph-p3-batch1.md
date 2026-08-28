---
title: "Revisão — P3 do drive: três nós medidos, três correções contra o autor"
date: 2026-08-28
branch: drive/backlog-graph-p3-batch1
reviewer: "medição executada contra o vivo (P3 do /meta:drive) + auditoria de leitura dos 4 papers por agente dedicado + gates determinísticos (radar/realign/drive)"
reviewed_diff_sha256: bb729f50c09b7c4a6cb1776b677c5f18d156024631d3dffd790bfa0b0e1b62b2
findings_total: 5
findings_real: 5
verdict: APROVADO
tokens: 42000
duration_min: 34
---

# Resíduo — REGRA 56

Passada de `/meta:drive` sobre `backlog-grafo-2026-08`. **Nenhuma linha de lógica; só grafo.** O risco
desta classe é **carimbar sem medir** — e o resultado desta passada é que os três nós medidos
**corrigiram quem os escreveu**.

## Achados

1. **`C_O_DRIVER_CONDUZ_O_GRAFO_VAZIO` exagerava.** Medido: o `fios-abertos` é **default, não trava**
   (linha 34 dos dois scripts aceita `*.kg.yaml`, e há precedente de uso com grafo não-default), e
   **37 dos 190 abertos (19%)** já têm commit citando o id. A fila **não** está sem condutor. O que
   persiste — e por isso o nó segue `open` — é a ausência de **laço cross-grafo**.

2. **`Q_PARADO_DE_PROPOSITO_OU_ABANDONADO` foi respondida, e a resposta dissolveu a dicotomia da
   própria pergunta.** Não é "parado de propósito" nem "abandonado": é **trabalhado por outro
   caminho**. A projeção tem **6 dias**, 7 dos 8 commits que a tocam são da própria construção, e
   **24 dos 37** itens com rastro foram citados **antes de ela existir**. Teto declarado no nó:
   chamá-la de sub-usada seria tão infundado quanto chamá-la de útil.

3. **Uma citação minha era FALSA — e foi o erro mais grave da passada.** A alegação de que o KARMA
   (arXiv 2502.06472) usa *utility scoring + multi-armed bandit* para priorizar **não existe no
   paper** — lido direto do PDF, 20 de 26 páginas, zero ocorrências dos termos. Veio de um resumo de
   busca **alucinado por terceiro**, que repassei sem ler. É exatamente o modo de falha que o próprio
   nó declarava (*"citar título NÃO é ter lido"*), cometido pelo autor do nó.

4. **A tentativa de refutar a nossa régua não caiu — mas deixou um fio.** Os dois papers lidos
   **sustentam** o limite que já tínhamos declarado: SGH exclui do próprio escopo grafos cuja
   dependência não é conhecida antes da execução (a definição de grafo epistêmico), e GRADE, com 6
   corpora reais, usa o grafo de dependência só como **diagnóstico pós-hoc** e nunca reordena. O fio:
   GRADE mede que **centralidade dirigida** prediz falha melhor que contagem crua — nosso `1+grau`
   não-direcionado pode ser mais cego. Fica `open` com gatilho nomeado.

5. **O radar recusou a modelagem proposta, e estava certo.** `REFUTES` contra alvo `drifted` →
   `--integrity` exit 1. Corrigido para `CONSTRAINS`, **com a razão escrita na própria aresta**: o nó
   não foi refutado como um todo (1 de 5 citações caiu), e o label já absorveu a correção por
   medição. A **Aufhebung estrita** (alvo → `superseded` + sucessor) exige flip de status de verdade,
   que a tabela de selagem do drive reserva ao **maestro** — proposta no `STATE.md`, não executada.

## Disciplina de processo

- **P0.5 respeitado com medição**: havia checkpoint pendente do drive de 27/08 (PR #699 "CI aguardando
  verde"). Medido: **MERGED**. O `STATE.md` é que estava velho.
- **BEACON antes de qualquer escrita (I3)**: 3 faróis "VIVA"; medido que **dois compartilham o mesmo
  `owner_pid`** (o daemon) — não são dois escritores. Achado colateral registrado com gatilho.
- **O guarda-chuva não foi tocado**: `Q_ONDA1_GERIR_BACKLOG_GRAFO` fecha na F6, não numa passada.

## Verificação

| gate | resultado |
|---|---|
| `kg-radar --integrity --schema` | **exit 0** |
| `kg-realign-project.sh --check` | **ALINHADO** (commit-drift 1 → 0, por medição) |
| `kg-drive-project.sh --check` | READY, fila 4 → 4 (2 fechados, 2 novos abertos) |
| `lint-artifacts` | 0 HARD |

## Teto declarado

Duas das três correções **reduziram** o alarme que eu mesmo tinha levantado (a fila não está
abandonada; o driver não está travado). Isso é resultado legítimo — mas convém dizer alto: **uma
passada que ameniza os próprios achados anteriores merece ceticismo extra**, e a defesa aqui é que
cada amenização veio de um comando reproduzível citado no `verified_against`, não de releitura.
