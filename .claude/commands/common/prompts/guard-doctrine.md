# 🛡️ Doutrina da forja de GUARDAS

O conjunto que uma guarda pede — irmão do [`forge-doctrine`](forge-doctrine.md), que forja
**comando-com-framework**. Guarda é outro animal: não tem superfície invocável (ela **dispara
sozinha**), não produz conhecimento (ela **barra**), e o que a mata não é falta de uso — é
**passar verde**.

**Por que esta doutrina existe, medido em 2026-10-02:** forjar guarda é o procedimento **mais
repetido** desta casa — **206 famílias de bancada** e **13 guardas com `--selftest` próprio** (pré-leva; esta forja soma a 14ª) — e era
o único **sem superfície**. Cada forja relia um molde escolhido de memória, e a sessão decidia o
substrato por lembrança. O `/meta:forge` tem medidor; a forja de guarda não tinha.

## As 7 peças de uma guarda

| # | peça | o que ela compra | modo de falha se ausente |
|---|---|---|---|
| 1 | **o DEFEITO MEDIDO** | a guarda nasce de dano observado, com data e evidência | guarda de hipótese: custo de manutenção sem dívida que a pague |
| 2 | **o MOLDE medido** (censo, não memória) | o substrato certo — hook `Stop`, `PreToolUse`, check de lint, regra embutida | copia-se o 1º molde lembrado e o veto nasce no lugar errado |
| 3 | **o ARTEFATO** | o veto propriamente dito | — |
| 4 | **as DUAS POLARIDADES** no `--selftest` | acusa o defeito **e** cala no caso honesto | guarda que só tem o caso positivo é superfície: ninguém sabe se ela acusa o inocente |
| 5 | **o MUTANTE** | prova que o caso **morde** | caso decorativo — passa verde com a cura revertida, e dá licença |
| 6 | **o REGISTRO** | ela dispara | guarda exercitada e morta: o censo mede exatamente isto |
| 7 | **o TETO declarado** | quem lê sabe o que ela **não** vê | guarda que parece cobrir a classe e cobre uma redação |

## As cláusulas

### 1. Sem defeito medido, não se forja
Guarda é dívida de manutenção permanente. A pergunta não é *"isto seria bom vigiar?"* — é *"que dano
já aconteceu, quando, e com que evidência?"*. Sem resposta datada, o desfecho correto é **nó com
gatilho nomeado**, não guarda. É a objeção `N=1` que sobreviveu a refutação na forja de comandos.

### 2. O MUTANTE é o que separa guarda de enfeite — e ele não se detecta por grep
Reverta a cura e **exija que o caso reprove**. Medido nesta casa: um caso de bancada com
`grep -qF "onion_regen <alvo> 21"` passava **verde** com o alvo trocado para `21x`, porque `-qF` é
substring; só a **deleção** da linha reprovava. O caso cobria metade do que anunciava, e meia
cobertura **dá licença**. O censo de guardas **não** vê isto — por isso a cláusula é de julgamento.

### 3. O VOCABULÁRIO é o defeito dominante, não a lógica
Medido 3× num dia: em guarda de lista, o que falha é a **lista de formas**, não o algoritmo. Três
consequências práticas:
- **o motor do padrão decide a sintaxe**: `[[:space:]]` é POSIX do `grep` e o `re` do Python o trata
  como *nested set* — a 1ª redação do `background-state-needs-evidence` ficou **cega ao `ps`** que ela
  existe para exigir;
- **o locale do hook não é o seu**: `Viola..es` casa em UTF-8 e **não** em locale `C`, que é o do
  hook. Rode a bancada com `LC_ALL=C`. **E meça com o BINÁRIO do script, nunca com a ferramenta da
  shell** — medido em 2026-10-02 ao forjar este próprio conjunto: um caso reprovou por `n[ãa]o` em
  locale `C` (o `ã` tem 2 bytes, o conjunto casa 1), eu "refutei" o diagnóstico rodando `grep` na
  shell interativa — onde ele é uma **função que chama o ugrep**, que casa por caractere em qualquer
  locale — e quase **reverti a cura certa**. Com `/usr/bin/grep` a conta fecha: `rc=1` em `C`, `rc=0`
  em `C.UTF-8`;
- **zero-por-vocabulário é pior que não medir**: lê-se como "não há". O 1º dogfood do próprio
  `guard-census.sh` devolveu **0 casos** para três checks que têm `--selftest`, porque contava duas
  convenções de asserção e a casa tem cinco.

### 4. A guarda erra para o lado de CALAR, nunca de acusar
Falso positivo treina a sessão a ignorar o veto, e veto ignorado é pior que veto ausente. Quando a
guarda **não sabe**, ela declara que não sabe (o idioma `ISENÇÃO`/`NÃO MEDIDO` desta casa), jamais
afirma conformidade. É o P0 da REGRA 30.

### 5. Guarda que terceiro dispara à distância é superfície, não proteção
Medido em 2026-10-02: a REGRA 22 julgava **intake não-confiável**, então qualquer adotante podia
deixar o gate do core vermelho só mandando um sinal. Antes de selar, pergunte **quem controla a
entrada** que a guarda lê.

### 6. O registro é parte da forja, não o passo seguinte
O censo mede as duas mortes: **registrada e sem `--selftest`** (dispara sem ser exercitada) e **com
`--selftest` e não registrada** (exercitada e nunca dispara). O 1º dogfood do censo acusou a guarda
que estava sendo forjada **naquele instante** na segunda categoria.

## O que esta doutrina NÃO promete

- **Não garante que a guarda pegue a classe** — só que ela pegue a **forma** que o caso descreve. A
  cláusula 3 existe para isso ser dito, não escondido.
- **Não substitui o Elenxo.** Guarda nova muda o gate de todos; a passada adversarial é onde se
  descobre que ela acusa o inocente.
- **Não sabe medir mutante.** Cláusula 2 é julgamento, e assumida como tal.

## 🔗 Referências

- Medidor (peça 2): `.claude/validation/guard-census.sh` · superfície: [`/meta:forge-guard`](../../meta/forge-guard.md)
- Irmã para comandos: [`forge-doctrine`](forge-doctrine.md) · bancada: `run_guard_forge_selftests`
- Moldes mais exercitados (o censo diz o atual): `.claude/hooks/rule-title-in-prose.sh` (hook `Stop`),
  `.claude/validation/ladder-integrity-check.sh` (check de lint)
