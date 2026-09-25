---
branch: fix/review-evidence-preserved
pr: 874
date: '2026-09-25'
reviewed_diff_sha256: 
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Passada de INVESTIGAÇÃO, pedida pelo maestro. O veredito é REPROVADO_E_CURADO porque dois dos três
  achados são contra MIM: as duas leituras que eu havia oferecido para a falha do revisor foram
  derrubadas pela medição dos runs vizinhos. Sem refutador independente; o que fez o papel dele foi o
  dado. Campos de custo em ZERO: a investigação foi determinística (leitura de logs de CI), sem run
  de modelo.
---

# Resíduo — a investigação que refutou a si mesma

## Os três achados

| # | achado | quem derrubou |
|---|---|---|
| 1 | **Não é teto nem rate-limit.** Eu havia proposto que a chave batera num limite ("custo zero com 1 turno é recusa da API, logo após a 1ª gastar US$ 0,55"). Medido nos runs vizinhos: 22:49 → 27 turnos/US$ 1,30 · 23:01 → 9/US$ 0,53 · 00:43 → 10/US$ 0,55. **Custo por turno estável em ~US$ 0,055**, e um **sucesso entre duas falhas** — teto não desliga e religa | a medição |
| 2 | **Não são dois modos de falha.** Eu havia dito que 22:49 falhara com `is_error: false`, logo por outra causa. Errado: aquele run tem `onion-review → success` e só o **veredito** falhou, porque o revisor **achou violações** — comportamento desenhado. Eu lera a conclusão do **workflow**, que agrega os dois jobs, em vez do job do revisor | a medição |
| 3 | **A evidência que fecharia o caso é descartada.** `claude-execution-output.json` — onde vive a mensagem — nunca era preservado; o log imprime o sumário do `result` e jamais o texto | o próprio diagnóstico impossível |

## O que sobra como verdade

**Anomalia única e intermitente**, não regime novo: o revisor trabalhou às 22:49 e às 23:01 e falhou
uma vez, às 00:43, com `subtype: success` + `is_error: true` em 10 turnos de 60.

E é **porque** é intermitente que a cura importa: a próxima ocorrência pode levar meses e, sem o
arquivo, chegará tão muda quanto esta. A cura não conserta a anomalia — ela garante que a **próxima**
venha com a causa.

## A classe, que é a lição

Duas leituras minhas erradas sobre a mesma falha, em minutos, **ambas derrubadas por medir os
vizinhos em vez de teorizar sobre o caso isolado**. É a terceira vez em 48 h que isto acontece (as
duas hipóteses sobre a morte do lint foram as anteriores), e o padrão é nítido: **eu ofereço causa
antes de comparar com o run que deu certo**. A comparação é barata — três `gh run view` — e resolve.

## Verificado

- `yaml.safe_load` no workflow → válido; 13 passos no job, os dois novos nomeados
- `lint-artifacts.sh` → **0 HARD**, 14 SOFT
- `if: always()` + `continue-on-error` nos dois passos novos: a evidência não derruba o job que ela explica
- `if-no-files-found: ignore` + mensagem **⊘** explícita se o caminho da action mudar — o passo não finge sucesso

## Fora do escopo, declarado

A **causa** do `is_error: true` segue desconhecida, e este PR não a promete. O que ele entrega é que a
próxima ocorrência será diagnosticável. Gatilho: o próximo `is_error` — baixar o artefato
`review-evidence-<run_id>` e ler o texto.
