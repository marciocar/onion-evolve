---
title: "ADR — adoção com MÚLTIPLAS integration branches: o vendor de fallback é branch-específico"
date: 2026-07-27
status: ACEITO (guard implementado e testado; convenção por-branch documentada)
origem: sinal upstream do metagamify — docs/evolution/inbox/_processed/2026-07-27-develop-onion-update-base-cruzada.md
kg: docs/onion/graph/vendor-multi-branch-2026-07.kg.yaml
---

# ADR — adoção com múltiplas integration branches

## Contexto

O `--update` do Onion aplica o framework via **3-way merge git**: um branch `onion/vendor` carrega o
framework novo e é mergeado na integration branch. O desenho (ADR `adopt-vendor-branch-merge`) assume
**um vendor por repo** — o que é correto enquanto houver **uma** integration branch.

Um adotante com **duas integration branches vivas e divergentes** (`develop`, base oficial dos PRs, e
`chore/onion-framework`) tentou levar o framework para a segunda e recebeu **~110 arquivos em
conflito**, incluindo código de aplicação (`apps/api/src/...`) que não é framework. Abortou limpo,
nada quebrou, e sinalizou upstream pedindo a receita.

## O que foi medido (e o que a medição derrubou)

Reproduzido no core contra o `vendor-branch.sh` real, em **três tentativas**:

| # | montagem | resultado |
|---|---|---|
| 1 | duas branches divergentes; produto só numa delas | conflito de **1 arquivo de framework** — não é o caso |
| 2 | produto divergente **e** `_clean_baseline` achando a baseline limpa | **0 conflitos**; produto da develop intacto |
| 3 | framework **customizado** ⇒ `_clean_baseline` falha | **exit 10 em `apps/api/src/…`** — a assinatura do campo |

**Duas integration branches não são, por si, o problema** — a tentativa 2 é a prova.

O gatilho é o **caminho de fallback** (`vendor-branch.sh`, bloco "legado entrelaçado"): sem commit na
história da integração cujo tree do framework seja idêntico ao pin adotado, o seed ramifica do **HEAD
da integração**. Nesse instante o `onion/vendor` deixa de ser *portador de framework* e passa a
carregar o **snapshot de produto daquela branch**, ficando estruturalmente casado com ela.

### A hipótese que caiu

A primeira resposta ao adotante disse que a causa era **ancestralidade**, e propôs registrar a origem
do vendor em `git config` na semeadura. Medido:

```
merge-base --is-ancestor(vendor, develop)  →  SIM nos DOIS casos
```

**Ancestralidade não discrimina.** O que discrimina é o conteúdo **não-framework**:

```
seguro  → tree(vendor) == tree(base do merge)  fora do manifesto
cruzado → tree(vendor) != tree(base do merge)  fora do manifesto
```

Este teste é **melhor** que o `git config` proposto, por uma razão que importa: funciona no vendor
**legado** — que é exatamente quem tem o problema, por ter nascido antes de qualquer registro existir.

## Decisão

**D1 — Guard estrutural, antes do merge.** `_vendor_is_framework_pure()` compara o vendor com a base
do merge e recusa (**exit 11**) se houver diferença fora do manifesto de framework. A recusa **nomeia
os arquivos alheios** e entrega o conserto. Critério de aceite explícito: a integração fica
**INTACTA** — recusar depois de sujar a árvore seria trocar 110 conflitos por 110 conflitos com
mensagem bonita.

**D2 — Convenção por-branch.** Havendo mais de uma integration branch adotada, o vendor é
`onion/vendor-<branch>`. O `onion/vendor` sem sufixo segue válido no caso de branch única
(retrocompatível; nenhum adotante precisa migrar por causa deste ADR).

**D3 — Vendor de baseline limpa PODE servir duas branches.** Não se proíbe o compartilhamento —
proíbe-se o compartilhamento **do vendor contaminado**. A distinção é medida, não declarada.

**D4 — Não registrar origem em `git config`.** Descartado em favor do teste estrutural (D1): estado
declarado pode divergir do real, e não cobre o legado. É a mesma razão pela qual o radar prefere medir
o grafo a confiar no carimbo.

## Consequências

- Adotantes com uma integration branch: **nada muda**.
- Adotantes com duas: o `--update` na segunda **recusa com instrução** em vez de despejar conflitos.
- O caminho de fallback continua existindo (é legítimo para legado entrelaçado de branch única), mas
  o vendor que ele produz agora é **reconhecidamente branch-específico**.
- O aviso *"risco de clobrar customização"* que já existia deixa de ser texto que rola na tela: vira
  consequência verificável no próximo update.

## Verificação

`lint-selftest.sh`, `run_vendor_branch_selftests`, casos **(g)** e **(g-MUT)**:

- **(g)** base cruzada ⇒ exit 11, mensagem contém `BASE CRUZADA`, o arquivo alheio é nomeado, e
  `git status` da integração fica com **0 alterações e 0 conflitos**.
- **(g-MUT)** com a guarda removida por mutação, o mesmo caso **mergeia e suja** a integração — prova
  que (g) não é vacuidade. A mutação é verificada antes de valer (mutação que não aplica não prova).
- Os 6 casos anteriores seguem verdes — inclusive **(f)**, que cobre o fallback legítimo de branch única.

Falsos-positivos conferidos à mão em fixtures: update normal, **segundo** update na mesma branch (o
caso mais comum de todos) e vendor de baseline limpa servindo uma segunda branch — os três mergeiam
limpo.

## Fronteira declarada

- **Não** reproduzimos os 110 arquivos do adotante — reproduzimos a **classe**. O volume depende da
  divergência real do repo deles.
- O guard **detecta e recusa**; não **conserta** sozinho (não renomeia branch nem re-semeia). Automatizar
  o conserto exigiria escrever em branch do adotante sem gate humano — fora do escopo.
- Casos com **três ou mais** integration branches não foram exercitados. A convenção D2 se estende por
  construção, mas isso é inferência, não medição.

## Desfecho de campo (2026-07-27, mesmo dia) — e um falso-vermelho meu

O adotante aplicou a receita e reportou o resultado. **As duas integration branches ficaram no mesmo
pin, cada uma com vendor próprio, zero conflito.** A convenção por-branch (**D2**) foi adotada por eles
**antes** de este ADR ser publicado — fica como precedente de campo, não como sugestão do core.

**O erro foi meu, e é simétrico ao que combatemos.** Eu instruí *"se vier o ⚠️ 'legado entrelaçado',
PARE"*. O ⚠️ disparou — corretamente, porque de fato não havia baseline limpa — e mesmo assim o
desfecho certo era **seguir**: o entrelaçamento era só framework velho, não customização; vendor
re-semeado do HEAD da **mesma** branch dá 3-way trivial e delta só de framework (194 arquivos de
framework, **0 de produto**). Transformar *"revise"* em *"pare"* é **falso-vermelho** — trava operação
segura e ensina a ignorar o aviso.

**Regra revista:** o ⚠️ é *revise o merge*; o sinal de parada é o **exit 11**, não o aviso.

O adotante propôs que o critério do guard fosse *"o merge toca paths fora do manifesto?"* — que é
**exatamente** o que `_vendor_is_framework_pure` faz, só que **antes** de mergear. Reproduzido para
confirmar (fixture: sem baseline limpa, vendor do HEAD da própria branch): `exit 0`, merge
framework-only, produto intacto. Eles chegaram ao critério pela experiência, o teste chegou pela
medição — convergência independente.

## Crédito

O caso, o diagnóstico inicial e o pedido de guard vieram do **metagamify** (adotante), no sinal de
2026-07-27. É o segundo achado de campo que vira mecanismo no core vindo dessa instância.
