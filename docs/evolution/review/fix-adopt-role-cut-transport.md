---
title: 'Resíduo — o corte por papel, e a guarda nova que aprovava a si mesma'
date: 2026-09-15
branch: fix/adopt-role-cut-transport
reviewed_diff_sha256: PENDENTE
findings_total: 3
findings_real: 3
findings_fixed: 2
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Três medições fixaram o desenho e a segunda derrubou a primeira tentativa inteira. Mas o achado
  que dói é o terceiro: a bancada que eu escrevi para provar o corte reprovou num caso, e investigar
  POR QUE ela reprovava revelou um fail-open maior — manifesto vazio com rc=0, que para o `git`
  significa TODOS e não NENHUM. A primeira versão da minha guarda nova aprovava a si mesma pelo
  mesmo motivo.
---

# O `--role` cortava zero arquivos — e curar isso exigia descobrir o que NÃO pode ser cortado

## O nó, verbatim

> `--role adopted|hub|standalone` devolve listas IDÊNTICAS — ROLE é inicializado, parseado, validado
> e nunca mais lido. É PIOR que o gap anterior: antes não havia papel e quem publicasse um standalone
> sabia que precisava cortar à mão; agora há flag que aceita `standalone` e entrega a meta-fábrica
> inteira. **Gap aberto virou gap INVISÍVEL.**

## As três medições que fixaram o desenho

| # | O que mediu | Resultado | O que mudou no desenho |
|---|---|---|---|
| 1 | `:(exclude)` vs positivo | **exclude vence, em qualquer ordem** | o corte é emitido **arquivo a arquivo**; não se poupa arquivo dentro de diretório cortado |
| 2 | lint no bundle cortado | **REGRA 36 HARD** | cortar `utils/adopt` inteiro leva a SSOT junto → nasceu o **CONTRATO** |
| 3 | `git archive` com tudo excluído | **rc=0, tar VAZIO** | contar o que sobra virou obrigação do manifesto |

A medição **2** derrubou a primeira tentativa inteira. `.claude/utils/adopt` é o coração da
meta-fábrica — cortá-lo parece óbvio. Mas `vendor-manifest.sh` mora lá dentro, e três guardas do
**ALVO** o leem: `lint-artifacts.sh` (REGRA 36, **fail-closed deliberado**), `vendor-scrub-form-check.sh`
(`exit 2`) e `kb-vendored-link-check.sh` (fallback defasado). O standalone nasceria **vermelho** —
trocando um gap invisível por outro.

Daí a distinção que o arquivo agora carrega:

> **a FÁBRICA não viaja; a PLANTA que as guardas do alvo leem, sim.**

## O corte é DERIVADO, não uma lista

A lista de arquivos a cortar sai de `git ls-tree` sobre **prefixos de caminho**. Helper de adoção
criado amanhã dentro de `.claude/utils/adopt/` **nasce cortado**, sem ninguém lembrar de acrescentá-lo.
É a cura da classe [[guarda-por-lista-falha-pelo-vocabulario]] aplicada ao transporte: asserir a
**FORMA** (o prefixo), nunca os nomes. A única lista manual é o CONTRATO — uma entrada, e a bancada
prova que ela está completa.

## O achado que a própria bancada produziu

O caso `(e)` reprovou. A causa imediata era fixture irreal (o contrato sempre sobrevive, então o
manifesto nunca chegava a zero). Investigar isso expôs o defeito real:

> Para o `git`, **pathspec AUSENTE significa TODOS**, não NENHUM.

Um repo sem nenhuma raiz da superfície Onion emitia manifesto **vazio com rc=0**. Quem lesse só o rc
copiaria o **repositório inteiro** — biografia e segredos junto. E a primeira versão da minha própria
guarda nova **aprovava a si mesma**: ela contava com `diff-tree --` sem pathspec, que casa tudo.

Classe [[exit-code-nao-e-a-verificacao]], agora um andar acima — no transporte.

## O corte da instalação não vale nada se o `--update` o desfizer

Duas pontas estavam cegas ao papel, e enquanto ele era decorativo isso não tinha efeito observável:

- `adopt.md --update` não passava `--role`. Agora lê o papel do **STAMP DO ALVO** (`onion-version.sh`
  hardcoda `role: source` por ser a identidade da FONTE — não serve aqui).
- `vendor-branch.sh` não propagava. Agora propaga por `ONION_ROLE`.

## O resíduo, medido e DECLARADO (não curado aqui)

| bundle (pós-configuração) | arquivos | HARD | SOFT |
|---|---|---|---|
| `adopted` | 685 | 32 | 8 |
| `standalone` | **578** | **69** | 23 |

O delta é de **duas classes, ambas da doutrina que viaja** — não do corte:

- **REGRA 22 (×27)** — KB vendorizada linka `../../../.claude/commands/meta/<cmd>.md`. Link
  **relativo de sistema de arquivos** para um comando que o papel legitimamente não recebe. A forma
  certa é o **nome** do comando (`/meta:kg`), que viaja para todo papel.
- **REGRA 16 (×14)** — prosa com contagem fixa (`109 comandos`) num bundle de 67.

**Por que fica aberto:** são ~41 referências em ~20 arquivos de doutrina, e curar exige decidir a
**forma canônica** de citar comando em superfície vendorizada — decisão de desenho, não conserto
mecânico. O que este PR garante é que o número é **VISÍVEL**: o manifesto imprime o resíduo medido em
stderr sempre que o papel corta. Nó `A_DOUTRINA_VENDORIZADA_LINKA_CAMINHO_DO_CORE`, gatilho nomeado.

## `--emit-scrub-roots` ignora o papel, e isso é desenho

As guardas que o consomem varrem **diretórios**; um `:(exclude)` ali as faria varrer **menos**.
Varrer mais do que viaja nunca é fail-open — varrer menos é. A assimetria entre os dois modos é o
lado seguro, e a bancada a fixa no caso `(f)`.

## Bancada

Família `role_cut`, **11 casos**:

```
(a)      standalone ≠ adopted (o papel corta)
(a2)     some a meta-fábrica, FICA a doutrina
(a-MUT)  sem _role_cut o standalone volta a ser adopted — (a) é load-bearing
(b)      bundle REAL (git archive + tar): 578 arquivos e o CONTRATO viajou
(b2)     nada mais da fábrica vazou
(c)      sem o contrato a guarda do ALVO falha FECHADA (rc=2)
(d)      helper NOVO sob prefixo cortado nasce cortado (derivado, não lista)
(e)      corte que cancela TUDO sai ≠0 em vez de virar bundle vazio
(e2)     repo sem superfície → manifesto vazio FALHA ALTO (pathspec ausente = todos)
(f)      --emit-scrub-roots IGUAL nos dois papéis
(g)      --update lê o papel do STAMP DO ALVO e o vendor-branch propaga
```

## Gate

```
bancada completa : PENDENTE
lint (LC_ALL=C)  : PENDENTE
radar / integrity: exit 0
commit           : SEM --no-verify
```
