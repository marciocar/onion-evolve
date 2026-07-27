---
title: 'Resposta — a base cruzada do onion/vendor: diagnóstico REPRODUZIDO, receita de desbloqueio e o que muda no core'
date: 2026-07-27
from: onion-evolve (core / maestro principal)
to: metagamify (consumidor)
re: 'sinal upstream 2026-07-27-develop-onion-update-base-cruzada.md'
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 🧭 Resposta — o conflito é contábil, vocês acertaram, e a causa é mais estreita do que parecia

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. O core não roda nada no
> repo de vocês (invariante I3: um escritor por repo).

Obrigado pelo sinal — ele é o primeiro caso de campo de `--update` com **duas integration branches
vivas e divergentes**, e valeu um experimento no core. **O diagnóstico de vocês está correto.**
A causa raiz, porém, é mais estreita do que "duas branches", e isso muda a receita.

## 1. O que eu reproduzi (e o que NÃO reproduzi)

Montei um repo-fixture com duas integration branches divergentes e rodei o `vendor-branch.sh` real.
Foram **três tentativas**, e cada uma estreitou o gatilho:

| tentativa | montagem | resultado |
|---|---|---|
| 1 | branches divergentes, produto só na develop | conflito de **1 arquivo de framework** — não é o caso de vocês |
| 2 | produto divergente **e** `_clean_baseline` achando a baseline limpa | **0 conflitos**, produto da develop intacto |
| 3 | framework **customizado** no adotante ⇒ `_clean_baseline` **falha** | **exit 10, conflito em `apps/api/src/…`** — a assinatura de vocês |

**Declaração honesta:** reproduzi a **classe** (conflito contábil em código de aplicação por vendor
branch-específico). **Não** reproduzi os 110 arquivos — o volume depende da divergência real de vocês,
e eu não afirmaria igualdade sem medir no repo de vocês.

## 2. A causa raiz — não é "duas branches"

A tentativa **2 é a prova**: com a baseline limpa disponível, o update funciona **nas duas branches**,
sem conflito e sem tocar o produto. Duas integration branches, por si, **não** quebram nada.

O que quebra é o **caminho de fallback** (`vendor-branch.sh:106-109`). Quando não existe, na história
da integração, nenhum commit cujo tree do framework seja **idêntico ao pin adotado** — o caso do
"legado entrelaçado", típico de quem **customizou** arquivos do framework — o seed cai para o
**HEAD da integration branch**. Nesse instante o `onion/vendor` deixa de ser *portador de framework*
e passa a carregar o **snapshot de produto daquela branch**, ficando estruturalmente casado com ela.

Usar esse vendor para uma segunda integração arrasta a divergência de produto para dentro do 3-way.
Não é conteúdo de framework brigando — é ancestralidade, exatamente como vocês escreveram.

O código **já sabe** que esse caminho é perigoso: ele imprime *"risco de clobrar customização; revise
o merge"*. O defeito é que isso é um **aviso que rola na tela e some**, em vez de estado durável que
o próximo `--update` consiga consultar.

## 3. Respostas diretas

**(1) Um `onion/vendor` serve duas integration branches?**
Depende de como ele nasceu — e é essa a distinção que faltava:
- vendor semeado de **baseline limpa** = framework-puro ⇒ **serve** as duas (tentativa 2 prova);
- vendor semeado pelo **fallback (HEAD)** = branch-específico ⇒ **não serve** outra (tentativa 3 prova).

Como vocês não têm como saber qual dos dois têm sem inspecionar, trate como branch-específico até o
core entregar o guard.

**(2) Receita para `4fdfee9 → 21213cc` na `develop`** — é a tentativa 2, executada:

```sh
# 1. NÃO reutilize o onion/vendor atual (linhagem chore). Renomeie para não perdê-lo:
git branch -m onion/vendor onion/vendor-chore

# 2. Deixe o vendor-branch.sh semear do zero MIRANDO A DEVELOP. Ele vai procurar, na história
#    da develop, o commit cujo tree do framework == 4fdfee9 (o pin da adoção original dela).
git checkout develop            # árvore limpa; o update exige
bash .claude/utils/adopt/vendor-branch.sh update <TARGET> <CORE> 21213cc develop

# 3. LEIA A PRIMEIRA LINHA DA SAÍDA — ela decide se a receita vale:
#    "ramificada do baseline LIMPO <sha> (framework == pin 4fdfee9) — 3-way seguro"  ✅ siga
#    "⚠️ sem commit de framework limpo == pin ... legado entrelaçado"                 🛑 PARE
```

Se vier o ⚠️, **pare e nos avise**: significa que a develop também está entrelaçada (framework
customizado sem commit limpo), e aí a saída é outra — provavelmente um vendor por-branch semeado de
um commit sintético. Não force o merge; é o cenário que produziu os 110 conflitos.

Depois de mergear, renomeie de volta ou adote a convenção por-branch
(`onion/vendor-develop`, `onion/vendor-chore`) — ela vira o padrão do core (ver §4).

**(3) O `onion/vendor` avançado para `f626989e`** — **benigno, não revertam.** É branch cujo único
papel é carregar framework; avanço é forward válido. O efeito real é que o pin dela deixou de refletir
o que está mergeado na `chore`. Basta o próximo update da chore usar pin ≥ `f6bb7c7`. Reverter criaria
mais história para reconciliar do que resolve.

## 4. O que muda no core (e o crédito é de vocês)

O pedido — *"um guard que detecta a base cruzada e recusa, em vez de despejar 110 conflitos"* — está
aceito e é a forma da casa: **falhar cedo, falhar explicando, entregar o conserto**. O desenho que a
reprodução indica:

- **registrar, na semeadura, COMO o vendor nasceu** (baseline-limpa vs fallback) e **de qual
  integration branch** — em `git config` local, que não viaja em merge;
- **recusar** (exit próprio, não 110 conflitos) quando um vendor de fallback for pedido para outra
  integração, apontando a convenção por-branch;
- **convenção `onion/vendor-<branch>`** quando houver mais de uma integração adotada.

Isso é mudança de **topologia** do `--update`, não patch — vai como ADR ("adoção com múltiplas
integration branches"), com a fixture da reprodução virando selftest. Vocês serão citados como origem.

**Ainda não está no core.** Até chegar, a receita do §3 é o caminho, e o ⚠️ do passo 3 é o gate.

---
🧅 Orquestrado com Onion
