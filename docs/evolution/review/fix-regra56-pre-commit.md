---
branch: fix/regra56-pre-commit
date: 2026-08-10
reviewed_diff_sha256: ed691d334e833304e06d4b775bf7e188e98b3fb2c061af433b1fb935bb89d40a
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-O-GATILHO-FOI-MEDIDO-23-VEZES-ANTES-DE-MEXER
reviewer: sem passada adversarial — ver "O que NÃO foi feito"
---

# A REGRA 56 punia quem obedecia — 23 vezes numa sessão

O nó do backlog exigia, em letra grande: **"MEDIR o gatilho exato antes de mexer"**. Medido:

```
commits desta sessão com `--no-verify DECLARADO`:  23
```

Vinte e três vezes o autor **obedeceu** — escreveu o resíduo, calculou o hash prospectivo — e mesmo
assim teve de contornar o hook.

## A raiz, precisa

```
DIFF_SHA = git diff "${BASE}" HEAD ...      ← só COMMITS
```

No pre-commit o `HEAD` ainda é o commit **anterior**. O conteúdo em stage **não entrava na conta**,
então o hash que o autor calcula com `--cached`, obedecendo, **não podia** casar. Do 2º commit em
diante o gate reprovava exatamente quem tinha feito a coisa certa.

**Guarda que pune quem obedece ensina a ignorar a guarda.** E o custo não é o bypass — é o bypass
virar **idioma**, e um dia esconder uma falta de verdade.

## A cura: a situação decide, não a suposição

Mesma escolha do `_baseline_ref` da catraca da REGRA 49 — **perguntar em que situação se está**:

| situação | alvo | quem é |
|---|---|---|
| árvore **suja** | `--cached` | pré-commit — o que **vai virar** o commit |
| árvore **limpa** | `HEAD` | pós-commit / CI, **quem audita** — inalterado |

Provado no cenário exato que me pegou 23 vezes (2º commit numa branch, obedecendo):

```
hash prospectivo do autor :  4e30918351ab…
o que a regra calcula AGORA:  4e30918351ab…   ✓ casa
o que ela calculava ANTES  :  f74870e55dfa…   ✗ era isto que punia
```

## Duas coisas que a bancada pegou de mim, na mesma corrida

**1 · A REGRA 60 me pegou na primeira oportunidade.** Escrevi `alvo="HEAD"` no bloco novo — pt-BR,
**7ª ocorrência** da classe. Dessa vez quem acusou foi **a máquina**, no dia seguinte ao merge, e não
um revisor. É o mecanismo fazendo exatamente o que foi construído para fazer.

**2 · `bancada-espelha-o-runner`, de novo.** O `_sha_of()` das fixtures fixava `main HEAD` — o alvo
**antigo**. Com a regra decidindo por situação, a fixture passou a calcular um hash que o gate
**nunca produz** naquele estado, e dois casos acusaram `ARTEFATO-CADUCO` sobre artefato **correto**.
A bancada agora espelha a escolha de alvo, não só as opções de shell.

## A prova final

**Este commit foi feito SEM `--no-verify`** — o primeiro da sessão. É a única verificação que
importa: a regra passou a ser satisfazível por quem obedece.

## Verificação

- bancada **774 passam / 0 falham / 0 pulam**, **artefato ESTÁVEL** · lint **0 HARD** + 4 SOFT
- par `(j)`/`(k)`: suja → índice, e o hash de quem obedece casa; limpa → `HEAD`, o CI inalterado

## O que NÃO foi feito, declarado

- **Sem passada adversarial.** O que substitui é menos: o gatilho foi medido (23) **antes** de
  mexer, a cura foi provada no cenário real, e a bancada — que espelha o runner — pegou dois
  defeitos meus na mesma corrida. O que um refutador provavelmente atacaria: `git diff --quiet HEAD`
  como detector de "pré-commit" é **heurística**, não contexto — um `git commit --amend` com árvore
  limpa, ou um hook rodando em `rebase`, cai no ramo `HEAD` e pode não ser o que se espera.
- **A REGRA 56 continua sem cobrir o caso do `amend`**, e isso não foi medido.
