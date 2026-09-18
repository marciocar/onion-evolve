---
title: 'Resíduo — a catraca contava o próprio livro-caixa'
date: 2026-09-18
branch: fix/door-ratchet-self-exclusion
reviewed_diff_sha256: 7a8a339d5bdcc535738c0170e1c3395bedd96700af8b4bde118054ae4b5f631b
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  A esteira voltou uma volta acima: ontem o teto crescia por trabalho EM VOO; hoje ele crescia
  pelo commit que AJUSTA O PRÓPRIO TETO. Medido — dos 4 arquivos da reconciliação do pin, só um
  está na superfície que viaja, e é o baseline da catraca.
---

# Reconciliar a porta defasava a porta

Depois de mergear o PR que reconciliava o pin, a catraca acusou de novo:

```
onion-core  ANDOU-PARA-TRAS  2 > 0 tolerado
```

Com teto 0, isso significa **um PR depois de todo PR** — regresso infinito, a mesma classe que foi
curada ontem, só que uma volta acima. Ontem o teto crescia por trabalho **em voo**; hoje cresce pelo
commit que **ajusta o próprio teto**.

Medido, e o resultado é cirúrgico — dos 4 arquivos daquele commit:

```
.claude/validation/door-staleness-baseline.txt   ← VIAJA
docs/evolution/federation/members.yaml           ← não viaja
docs/onion/graph.md                              ← não viaja
docs/onion/testing-state.md                      ← não viaja
```

**Um só**, e é o livro-caixa da própria guarda. O teto mora na superfície que ele julga — a mesma
frase que escrevi ontem para o caso da branch, reaparecendo no caso do merge.

## Por que excluir é legítimo, e não afrouxamento

A guarda **já** exclui biografia, com o argumento de que a porta não a receberia. Aqui a porta
**recebe** o arquivo — mas a REGRA 85 (Porta pública espelha o core, com catraca) nela é
`[papel/SEM-OBJETO]`: sem `members.yaml` não há porta a julgar. O conteúdo é **inerte no alvo**.

Um commit que só mexe nesse baseline não muda **nada que a porta possa exercer**, e portanto não a
faz mentir sobre o core — que é a única coisa que esta catraca existe para medir.

**Efeito medido, sem ninguém materializar nada:** `383 → 381` e `2 → 1`. O `1` que sobra é honesto —
é o `regen-core-projections.sh`, mudança real de framework que a porta ainda não recebeu.

## Achado 2 — o meu caso de bancada mediu errado antes de medir certo

A 1ª redação do caso (g) afirmava `! grep ANDOU-PARA-TRAS`. Reprovou — **e o SUT estava certo**: o
caso (f), logo acima, já deixa a porta 1 atrás de propósito, então aquele `1 > 0` era resíduo dele.

O oráculo correto é o **número antes × depois**, não o veredito: `(1→1)` prova que o livro-caixa não
move a distância. E o caso **(h)** existe para impedir que a exclusão vire salvo-conduto: mudança
**real** de framework no mesmo commit **volta a contar**.
