---
branch: fix/lib-path-antes-do-cd
date: 2026-08-10
reviewed_diff_sha256: 361f300f97d499ab17e6d15c69a887c4fe4e124da0347fae62ec4f650863bacd
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-O-DOGFOOD-CONTRA-ADOTANTE-REAL-ACHOU-OS-TRES-E-CORRIGIU-UMA-AFIRMACAO-MINHA
reviewer: sem passada adversarial — os achados vieram de rodar contra 3 adotantes reais desta máquina
---

# Revisar o alinhamento com o Onion — e o Onion cobrou o dogfood

A pergunta não era *"os itens estão alinhados"*, mas **"o que eu fiz está alinhado com o que o Onion
É"**. Medido nos 7 PRs do dia:

```
.claude/validation/          24 arquivos
.claude/{commands,agents,skills}/   0
```

Fiel ao **plano** (W0–W4 eram todas sobre o instrumento), mas contra a doutrina há um fio: criei
**três regras HARD que viajam para adotantes** e não rodei nenhuma contra um adotante real — quando
existem **três** nesta máquina, com `.claude/` e git. *"Dogfood é o padrão master — rodando o artefato
de verdade."*

## O que o dogfood achou, em 3 de 3

**1 · A guarda morria antes de julgar.** `exit 2 — lib AUSENTE` nos três. Causa: eu resolvia
`WORDS` **depois** do `cd "${REPO_ROOT}"`, e `BASH_SOURCE[0]` costuma ser **relativo** — então o
caminho passava a apontar para o repo **julgado**, não para onde o script vive. Rodar o script do
core contra qualquer outro repo era `exit 2`, sempre.

Resolvido **antes** do `cd`. Depois: os três **rodam**.

**2 · E aí apareceu o achado que corrige uma afirmação minha.** Com a regra funcionando, `pedro` e
`arthur` mostraram **3 HARD cada** — todos em código **do core** que eles vendorizam.

No PR #570 eu medi que *"exatamente um dos 7 residuais viaja"*. Medi contra **manifestos**. Estes
adotantes vendorizam **`.claude/` inteiro** — logo **todos** viajavam, e eles herdavam dívida que não
é deles, sem herdar o baseline.

A regra que eu mesmo escrevi ali vale aqui: **baseline tolera o que fica; o que viaja se conserta.**
Os quatro residuais foram renomeados. **Baseline: 4 → 0.** Não há mais dívida tolerada — há dívida
**curada**.

**3 · `arandek` → `exit 2 — universo VAZIO`.** É o fail-loud que a passada adversarial do #569 me
fez construir, funcionando: a guarda **declara que não sabe** em vez de exibir aprovação.

## E o meu próprio rename quebrou um gate

O `perl` renomeou o **lado esquerdo** e deixou o direito: `attention=$((atencao + …))` — variável
indefinida sob `set -u`. O `federation-radar` saiu `rc=141` e dois casos reprovaram.

**Meia-renomeação é pior que nenhuma**: o nome novo existe, o antigo some, e o programa quebra num
ponto que não é o que se editou. A varredura de conferência (`attention=$((atencao`) passou a fazer
parte da cura, e devolve zero.

## Verificação

- bancada **774 passam / 0 falham / 0 pulam** · lint **0 HARD** (fora o resíduo deste PR) + 4 SOFT
- `identifier-language-check`: core **0 HARD, baseline 0 entradas**
- os 3 adotantes **rodam** a regra (antes: `exit 2` em 3 de 3)
- `federation-radar` volta a `rc=0` (advisory), e a varredura por meia-renomeação devolve zero

## O que NÃO foi feito, declarado

- **Sem passada adversarial.** O que substitui é o dogfood contra **três adotantes reais**, que é o
  que a doutrina chama de padrão master — e que achou um defeito (`exit 2` em 3 de 3) que nenhuma
  das medições sintéticas do #569 tinha visto.
- **Os adotantes continuam com 3 HARD** contra a cópia **antiga** que têm vendorizada. Herdam a cura
  ao atualizar; não foi executado `adopt --update` em nenhum deles.
- **O desequilíbrio das dimensões permanece**: 7 PRs, zero em comando/agente/skill. É fiel ao plano
  desta rodada, mas está declarado como fato, não escondido.

## E a REGRA 36 me pegou no ato

O hook bloqueou o commit: escrevi **os nomes dos três adotantes** dentro de um comentário do
`identifier-language-check.sh` — **superfície vendorizada**. Isso vazaria o nome de cada um para
**todos os outros**.

O comentário virou *"três repos adotantes reais desta máquina"*: **a evidência é quantos, não quem**.
E vale registrar que a superfície vendorizada é exatamente `.claude/{agents,commands,skills,utils,
validation,hooks}` + `docs/{meta-specs,knowledge-base,sdaal}` — medido, não suposto. `docs/evolution/
review/` **não** está na lista, e por isso este resíduo pode nomeá-los.

Foi a guarda me pegando no mesmo commit em que eu celebrava o dogfood — o dogfood produziu a
evidência **e** o vazamento.
