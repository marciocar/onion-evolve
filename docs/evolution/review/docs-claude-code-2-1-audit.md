---
branch: docs/claude-code-2-1-audit
pr: 616
date: 2026-08-16
reviewed_diff_sha256: aa2165914165e49011e76dad02240608ad2429ed7b0b4cb75ec16b4f56101516
findings_total: 5
findings_real: 5
findings_fixed: 5
tokens: 0
duration_min: 40
verdict: CONFORME-COM-TESE-REFUTADA
reviewer: Elenxo dedicado (agente adversarial) que mediu 47 scripts e 63 grafos + 2 frentes de pesquisa externa; a passada derrubou duas cláusulas centrais da tese do autor e o autor as refutou no grafo em vez de editá-las
REVISOR_ADVERSARIAL: elenxo-superacao (veredito por 7 eixos + adendo com verificação independente do binário)
REVISOU: true
---

# Resíduo — `docs/claude-code-2-1-audit`

Este PR é a análise que o maestro pediu **feita pela maquinaria**, não sobre ela. O que
há para revisar não é código: é se os carimbos correspondem ao medido, e se a conclusão
sobreviveu ao ataque. Sobreviveu **encolhida**, e é isso que o resíduo registra.

## Os 5 achados da passada adversarial (todos incorporados, nenhum descartado)

1. **"KG como SSOT de runtime" — REFUTADO por fonte interna.** `lint-artifacts.sh:832`
   diz que o radar valida o grafo contra si mesmo, nunca contra o veredito do run;
   nenhum dos 7 hooks lê `.kg.yaml`. Reconciliado: o nó da tese virou `refuted` e
   recebeu duas arestas `REFUTES` — não foi editado para parecer que sempre esteve certo.
2. **"o único" — REFUTADO por medição externa.** Cruxible e AsDecided atacam a mesma
   tese; o primeiro com content-hash + assinatura e zero LLM na verificação.
3. **A inversão agnóstico/acoplado.** 26.596 linhas de shell agnóstico contra 52.655 de
   markdown acoplado: o que reprova é portátil, o que aconselha é acoplado — e
   `SendMessage`, a capacidade que justificou o acoplamento em 2026-05-18, tem ZERO uso
   na maquinaria.
4. **A armadilha da facilidade.** Os 18 eventos de hook novos tornam construível a cura
   que a casa refutou por medição há 14 dias (1/9, NÃO CONSTRUIR). Registrado como
   `question` com o gatilho ORIGINAL preservado (dogfood 2–3× à mão), não como licença.
5. **O nó de custo estava errado ao mirar a maquinaria.** O gate roda em CI, fora da
   janela, a custo zero de token; a pressão vem da prosa sempre-ligada (~9k) e de
   comandos gordos (`adopt.md` 45,6 KB). O nó foi corrigido no próprio grafo.

## Verificação cruzada (o que dá para conferir sem confiar em mim)

O único FATO deste PR que veio de dogfood do autor — os eventos novos de hook estarem
no binário 2.1.233 — foi **re-medido de forma independente pelo revisor**, que chegou
aos mesmos eventos e ainda contou os 5 tipos de handler. Os demais números vêm de
comandos reproduzíveis citados no grafo.

## Limite declarado

O revisor **não executou** `lint-artifacts.sh` nem a bancada (proibido no briefing):
os 689 `record_pass` são contagem no fonte, não prova de verde hoje. E não mediu os 4
adotantes locais — a lacuna que mais importa, porque se o corpus não transfere, o fosso
é biografia deste repo e não produto. Ambos ficam como medição pendente, nomeada.

Nenhuma ADR foi escrita: a decisão da superação está `open` no grafo, aguardando
ratificação do maestro, e com a perna de leitura declarada buraco aberto — publicá-la
como capacidade entregue seria a terceira repetição de uma classe que a casa já registrou.
