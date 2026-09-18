---
title: 'Resíduo — o adotante nasce verde, e o slug neutro se prova em produção'
date: 2026-09-17
branch: feat/register-vendas-pdi-enterprise
reviewed_diff_sha256: fb6e6ad1552d5fc9986eb42a7bda656eb4aae3f77eeae5f500b906b039d9766c
findings_total: 4
findings_real: 4
findings_fixed: 4
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


---

# Achado 4 — a cobertura das projeções estava partida, e só uma metade tinha dono

Tocar o `members.yaml` envelheceu `federation-map.md`, `federation-console.html` e `lint-rules.md`.
Foi a **quarta vez no mesmo dia** que descobri isso **pelo gate vermelho**, uma projeção por vez.

A causa não é distração. O `regen-ssot-projections.sh` **isenta** esses geradores, e a isenção está
**certa**: eles derivam do `members.yaml`, que é core-only — sem registro não há mapa, console nem
agent-card a gerar num adotante. Eu mesmo escrevi essa razão hoje, no caso `regen_completude`.

O que faltava era o outro lado. **No core** essas quatro projeções têm catraca no lint (REGRAS 24,
38, 39 e a do agent-card) e **ninguém as regenerava em bloco**. A isenção legítima para o alvo virava
buraco na fonte — cobertura partida em duas com dono só numa metade.

Curado com `regen-core-projections.sh`, e o contrato de escrita é o ponto:

> nenhuma projeção é sobrescrita sem que o gerador tenha saído **0** *e* produzido **tamanho
> plausível**.

Isso não é zelo: hoje eu truncei o `kg-read-index.tsv` para **zero linhas** com um gerador que saiu
`rc=2` e um redirect direto. O `[ -s ]` sozinho não protege — um byte já passa. O gerador escreve num
temporário e só é promovido se convencer.

Bancada, 4 casos, e o (b) é o que justifica o script existir: **gerador que falha não destrói a
projeção boa, e diz que não escreveu**. Mais: `rc=0` com saída abaixo do piso também é recusado (o
vazio-que-parece-conteúdo), e gerador ausente **declara que não julgou** em vez de inventar arquivo.
