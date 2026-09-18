---
title: 'Resíduo — o adotante nasce verde, e o slug neutro se prova em produção'
date: 2026-09-17
branch: feat/register-vendas-pdi-enterprise
reviewed_diff_sha256: c2760d05f5cda07c81956802ffdd28fff6b9ea6661984be9d862dc540dceac22
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Três achados, e os três vieram de RODAR em vez de planejar: o lint do alvo cobrou um
  `settings.json` que eu não emiti por ter pulado a Configuração pós-cópia; o
  `members-validate.sh` recusou o vocabulário errado de `role`; e a verificação por ausência
  provou que o slug neutro não vaza o cliente nas superfícies projetadas.
---

# O adotante nasce com 0 HARD — medido, não prometido

703 arquivos do manifesto `adopted`, pin `f5ec0dcf2dfb` (commit **mergeado em main**, nunca de
branch em voo). Dogfood do artefato real: `lint-artifacts.sh` → **0 HARD, 8 SOFT**.

E o **pre-commit do próprio adotante rodou o gate** no commit da adoção — prova de que a maquinaria
chegou **viva**, não apenas copiada. Existência de arquivo não é capacidade; execução é.

## Achado 1 — eu pulei a Configuração pós-cópia, e o lint do alvo cobrou

Primeira medição: **3 HARD**, todos a mesma causa — três documentos do framework apontando para
`.claude/settings.json`, que o alvo não tinha. O manifesto não carrega `settings.json` porque ele é
**específico do alvo**; quem o emite é a Configuração pós-cópia, que eu não rodei ao materializar à
mão.

O procedimento estava certo e escrito (`adopt.md`, passo 1: merge never-clobber, ou cópia quando o
alvo não tem). **Quem errou fui eu**, e o gate do alvo foi quem disse.

## Achado 2 — o registro recusou meu vocabulário, e estava certo

Escrevi `role: adopted` no `members.yaml`. O `members-validate.sh` recusou nomeando o vocabulário
aceito: `consumer|hub|source|standalone`.

Não é inconsistência da casa — são **perguntas diferentes**. O `.claude/.onion-version` diz a
**relação com o framework** (este repo vendoriza o Onion: `adopted`); o `members.yaml` diz o **tier na
rede** (`standalone`: adota o core direto, sem sub-adotados). Anotado na própria entrada, porque quem
ler depois vai tropeçar no mesmo lugar.

A guarda barrou **antes**, em vez de deixar o drift entrar calado. É o comportamento que se quer.

## Achado 3 — o slug neutro se prova por AUSÊNCIA

A decisão do maestro de neutralizar o slug (o pedido original nomeava o cliente) foi verificada onde
importa:

```
grep -ril '<nome-do-cliente>' federation-console.html federation-map.md members.yaml → ZERO
grep -c 'vendas-pdi-enterprise'  federation-map.md → 2 · federation-console.html → 1
```

O membro **aparece** pelo identificador neutro e o cliente **não aparece** em superfície projetada.
Precedente que motivou: um nome comercial entrou numa entrada deste mesmo arquivo e apareceu no
console, e o lint não pegou porque a guarda reconhece por **lista** e não conhecia o nome.

## Fronteira de NDA

`material/` está no `.gitignore` desde o **primeiro** commit do adotante — antes de existir qualquer
material. Repo privado protege contra terceiros; não protege contra o repo ser clonado, espelhado ou
aberto por engano depois.
