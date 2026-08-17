---
branch: ci/split-gate-from-bench
pr: 625
date: 2026-08-16
reviewed_diff_sha256: cecdafef385ef94152bca833f4ed6fe11c2bec1bc890ba8ddad1aedf08c5bab7
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 25
verdict: CONFORME-COM-QUESTAO-REFORMULADA
reviewer: revisão da PERGUNTA antes da solução — a proposta original (sharding) caiu na medição; e a checagem pegou uma afirmação que eu já tinha feito duas vezes sem verificar
REVISOU: true
---

# Resíduo — `ci/split-gate-from-bench`

O maestro pediu **superação**, não solução. A passada foi sobre a pergunta.

## Achado 1 — a solução que eu tinha proposto era pior que a questão

Eu ia shardar a bancada em matriz: **mesmo trabalho, em paralelo, mais minutos de runner**.
A medição derrubou: a bancada era **686s de 729s (94% do CI)** e dos 8 PRs daquele dia
**6 tocaram ZERO arquivo de maquinaria**. Eles esperaram 12 min por uma suíte que prova as
**guardas** — e as guardas não estavam no diff.

A distinção que dissolve o problema: **gate sobre a mudança** (lê o diff, reprova o
artefato, ~44s) *versus* **teste de regressão da maquinaria** (prova que as guardas
reagem). Gatilhos diferentes ⇒ workflows diferentes. PR de docs: ~12 min → ~1 min, e o
custo em minutos **diminui** em vez de aumentar.

## Achado 2 — o filtro de path só é seguro com rede debaixo

Esta casa tem **três** pontos cegos nascidos de filtro de path (#241 `plugins/`, #254
`docs/`, #509 `ops/`). O defeito comum não foi filtrar — foi **filtrar e não ter mais
nada**: path fora da lista nunca era coberto. Por isso o workflow novo tem `schedule`
noturno rodando a bancada **inteira** na main, independente de path. A cobertura deixa de
depender de alguém tocar o arquivo certo.

## Achado 3 — eu havia afirmado duas vezes sem verificar

Disse ao maestro, duas vezes, que "os 4 adotantes com gate inerte serão pegos no próximo
`--update`". Fui checar ao escrever este resíduo: **passa mesmo** (`adopt.md` §Atualizar um
repo adotado → "Re-aplicar a configuração install-only", que contém o passo do githook).
Estava certo **por sorte, não por verificação** — e é a classe que esta rodada existe para
curar. Registrado no nó `E_MEDICAO_DOS_REMOTOS_PERDEU_VALOR_DE_DECISAO`.

## A segunda questão pendente foi revisada e perdeu valor de decisão

Rastreei a origem de cada conclusão: "o corpus centraliza" veio de **créditos medidos dentro
do core** (13 no CHANGELOG + 7 no lint) — independe de disco alheio; "gate inerte em 4 de 6"
veio do disco local e é exatamente o que a cura mecânica resolve. Medir os remotos seria
vigiar repo alheio para confirmar defeito que já tem cura, com dado que envelhece na hora.
A superação é **inverter o fluxo**: o veredito chega pelo canal de co-evolução.

## Limite declarado

O ganho de tempo é **projetado, não medido** — só o primeiro PR de docs após este merge
provará o ~1 min. E o `schedule` noturno só se prova amanhã: se ele não disparar, a rede
debaixo do filtro não existe e o ponto cego volta. **Ambos ficam para verificar no vivo.**
