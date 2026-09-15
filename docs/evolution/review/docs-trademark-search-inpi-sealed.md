---
title: 'Resíduo — o selo da marca: a busca derrubou a recomendação, como o nó previa'
date: 2026-09-15
branch: docs/trademark-search-inpi-sealed
reviewed_diff_sha256: ed92ffaa308ccd0126ee8db01a3afc3f603f9c112215c75148fce610c29f3b75
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  DECLARADO SEM PASSADA ADVERSARIAL, e a razão é proporcionalidade, não conveniência: o PR é um selo
  de 3 arquivos de docs/ que registra uma medição EXTERNA (a busca no INPI, feita pelo maestro em
  busca.inpi.gov.br/pePI) e reconcilia o grafo. Não há maquinaria nova para um refutador atacar, e o
  fato central não é derivável por raciocínio — ou a busca foi feita, ou não foi. O que um refutador
  poderia contestar aqui é o JUÍZO jurídico, e esse teto o próprio nó já declara na fonte primária.
---

# O selo da marca — o que este PR registra, e o que ele NÃO prova

## O fato, verbatim da busca

O nó `D_MARCA_MEDIR_ANTES_DE_DECIDIR` (selado em 2026-09-14) nomeou a condição: *a colidência real de
"onion" na base do INPI não foi medida, e é a evidência que pode derrubar a recomendação inteira.*

A busca foi feita em **2026-09-15, 11:19**, em `busca.inpi.gov.br/pePI` (base até 15/09):

- `onion` → **9 processos**
- `onion evolve` → **nenhum resultado**

**Derrubou.** O bloqueador é o processo **933007990** (19/12/2023, NCL(12) 42, marca mista), **vivo**
— *requerida, aguardando exame de mérito* — e anterior a qualquer depósito de hoje, na exata classe
pretendida. A nova recomendação é `ONION EVOLVE`, **nominativa**, classe 42.

## Por que a nova recomendação é MELHOR, e não só o que sobrou

Três razões independentes, e só a primeira vem do bloqueador:

1. zero colidência na base;
2. `onion` sozinho é **genérico** (cebola) — baixa distintividade intrínseca já era risco de
   indeferimento por si só, independente do 933007990;
3. dissolve o vizinho semântico `Onion Architecture` (18 anos de uso), que era questão de
   posicionamento, não de registro.

E é o nome **real**: o site é onionevolve.com.

## O teto, declarado pela própria fonte

A página de resultado do INPI diz, e o nó repete: **busca satisfatória NÃO garante registro** — o
exame refaz a busca e decide. Este PR sela uma **medição**, não um veredito jurídico.

## Aufhebung

`E_MARCA_LACUNAS_DA_RODADA_0914` passa a `superseded` **na lacuna principal**, com as demais
NOMEADAS como ainda abertas (prazo de exame, regra do símbolo, art. 1.166 do CC, USPTO/EUIPO).
Superar uma lacuna não apaga as irmãs.

Fio novo e barato: `A_MARCA_LER_ESPECIFICACAO_DO_933007990` — a classe 42 é larga (de design de
software a análise química). Se a especificação do bloqueador estiver longe de TI, a coexistência
fica mais confortável. Gatilho: **antes do depósito**.

## Gate

```
lint (LC_ALL=C)  : 0 HARD
radar / integrity: exit 0 (54 nós, 94 arestas)
realign          : ALINHADO
commit           : SEM --no-verify
```
