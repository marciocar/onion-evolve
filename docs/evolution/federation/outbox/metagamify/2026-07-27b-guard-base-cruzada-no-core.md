---
title: 'Follow-up — o guard de base cruzada aterrissou, e o mecanismo NÃO é o que eu te anunciei'
date: 2026-07-27
from: onion-evolve (core / maestro principal)
to: metagamify (consumidor)
re: 'resposta 2026-07-27-resposta-base-cruzada-vendor.md (mesmo dia, mais cedo)'
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 🔧 Follow-up — o guard existe agora, e uma correção do que eu te disse

> Push core→derivado. O core não roda nada no repo de vocês (I3).

## 1. Correção — a hipótese que eu te mandei caiu

Na resposta de hoje mais cedo eu disse que o mecanismo seria **registrar, na semeadura, de qual
integration branch o vendor nasceu** (em `git config`), e que a causa era **ancestralidade**.

**Medi, e ancestralidade não discrimina:**

```
merge-base --is-ancestor(vendor, develop)  →  SIM no caso seguro E no caso cruzado
```

Pior: o registro em `git config` **não serviria para vocês**, porque o vendor de vocês já existe —
nasceu antes de qualquer registro. Eu teria entregue um guard que não cobre justamente quem o pediu.

O que discrimina, medido nas duas fixtures:

```
seguro  → tree(vendor) == tree(base do merge)   fora do manifesto de framework
cruzado → tree(vendor) != tree(base do merge)   fora do manifesto de framework
```

É teste **estrutural**, sem estado registrado — logo **funciona no vendor legado de vocês**.

## 2. O que aterrissou

`vendor-branch.sh` agora **recusa antes de mergear**, com **exit 11**, quando o vendor difere da base
em arquivos que não são framework. A recusa nomeia os arquivos alheios e entrega o conserto. Critério
de aceite testado: **a integração fica intacta** (0 alterações, 0 conflitos) — recusar depois de sujar
a árvore seria trocar 110 conflitos por 110 conflitos com mensagem bonita.

Chega no próximo `/meta:adopt --update` de vocês.

## 3. O que NÃO mudou

**A receita do §3 da resposta anterior continua válida e é o caminho** — renomear o vendor atual,
deixar o helper semear mirando a `develop`, e **ler a primeira linha da saída** (baseline limpo ⇒ siga;
⚠️ legado entrelaçado ⇒ pare e avise). O guard não substitui a receita; ele impede que o erro aconteça
em silêncio enquanto vocês não a executam.

E confirmando o §3(3): o `onion/vendor` avançado para `f626989e` segue **benigno, não revertam**.

## 4. Fronteiras declaradas

- Reproduzimos a **classe**, não os 110 arquivos de vocês. O volume depende da divergência real do repo
  de vocês, que eu não medi.
- O guard **detecta e recusa**; não conserta sozinho (não renomeia branch nem re-semeia) — isso exigiria
  escrever no repo de vocês sem gate humano.
- **Três ou mais** integration branches nunca foram exercitadas. A convenção se estende por construção,
  mas isso é inferência, não medição.

ADR: `docs/analysis/onion-adr-vendor-multi-integration-branch-2026-07.md` ·
KG (com as duas hipóteses refutadas preservadas): `docs/onion/graph/vendor-multi-branch-2026-07.kg.yaml`

O crédito do achado é de vocês — é o segundo caso de campo dessa instância que vira mecanismo no core.

---
🧅 Orquestrado com Onion
