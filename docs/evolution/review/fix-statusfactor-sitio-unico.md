---
branch: fix/statusfactor-sitio-unico
date: 2026-08-09
reviewed_diff_sha256: 571b5dc9fb1946761d780fabae9ad451db0eb7d5013589a9c2a92fc772e7d0f4
findings_total: 55
findings_real: 18
findings_fixed: 14
tokens: 1388731
duration_min: 69
verdict: HARD-MAS-NAO-COMO-ESTAVA-A-CURA-DA-GUARDA-CEGOU-A-GUARDA
reviewer: Elenxo — 3 lentes × 3 refutadores + juiz (opus/high, juiz em max), wf_fc82e4cb-466
---

# Passada adversarial — eu curei um falso-positivo abrindo três fail-opens na mesma guarda

**3 lentes, 9 refutadores, 55 achados brutos → 18 defeitos distintos. Nenhuma lente deu `CAI`.**
Veredito do juiz: **«HARD, mas NÃO como está.»**

A tese central sobreviveu, e o juiz a mediu sozinho: em `origin/main` a lente dava `w=0.00` no nó
`D_email_plus_logto_connector` (`unverifiable`) e o radar dava `8.00`; no HEAD os dois dão `8.00`. O
`diff` dos 7 slots entre o radar de main e a lib nova é **vazio** — não houve reescrita silenciosa de
fila. **Sítio único, fail-loud e paridade-de-peso são reais.**

O que não sobreviveu foi a entrega.

## O defeito que o PR existe para fechar

O fator de status vivia **copiado em cinco scripts**. Quando `drifted` e `unverifiable` entraram no
enum (06/08), o radar ganhou os slots e a lente não — passou a devolver `-1`, clampado a 0. E o
`--assert-parity` não via, porque comparava `node_count`/`edge_count`: as duas lentes concordavam em
**quantos** nós existem e discordavam em **qual é o mais urgente**, que é a única pergunta que o
painel responde.

## O achado mais duro, e ele é meu

Eu escrevi, no resíduo da primeira versão: *"guarda que grita errado ensina a ignorar a guarda"*. E
curei o falso-positivo da `bash-empty-result-guard.sh` **cegando a guarda em três formas** — incluindo
o modo-de-falha que a fundou. Medido pelo juiz, `main` × `HEAD`, quatro casos:

```
n="$(ls | wc -l)"; echo $?            main DISPARA   HEAD CALA
bash -c 'ls | tail -1'; echo $?       main DISPARA   HEAD CALA
ssh h "a | b"; echo $?                main DISPARA   HEAD CALA
echo "it's"; ls | wc -l; echo "don't" main DISPARA   HEAD CALA
```

A premissa que escrevi — *"entre aspas, `|` é TEXTO"* — é **falsa em três raízes independentes**:

1. dentro de `$( )` o pipe é **real** (e o próprio diff deste PR tinha **três linhas dessa forma**);
2. em `sh -c`/`ssh`/`su -c`/`xargs`/`-exec`, a string entre aspas **é shell**;
3. par-de-regex não sabe que aspa dentro de aspa é literal: o `gsub` de apóstrofo casava de `it's`
   até `don't` e apagava o **miolo inteiro**, pipe real junto.

**A regra foi invertida:** só remove trecho entre aspas quando dá para **afirmar** que ali é texto.
Havendo substituição de comando, wrapper que recebe comando como string, ou aspas não fechadas,
devolve a linha crua. A varredura passou a ser por **estado**, caractere a caractere. A guarda erra
para o lado de **gritar**, por desenho — porque guarda que cala errado não ensina nada, só mente.

## E a cura entrou SEM UMA ASSERÇÃO

O juiz mutou `semAspas` para identidade — a cura inteira revertida — e a bancada fechou **11/11
verde, saída idêntica**. O cabeçalho afirmava *"as duas direções foram medidas"*: foram, **de mão**, e
em casos **sem aspas**, que são estruturalmente incapazes de ver sobre-remoção.

O próprio arquivo já tinha escrito a doutrina que eu violei: `(f)/(g)` e `(h)/(i)` **nasceram em par**,
porque *"filtro anti-ruído sem o par é como silenciar um alarme inteiro e passar no teste"*. Meu 3º
filtro entrou sem par. Agora existem `(l)`…`(p)`: uma de silêncio, três de não-cegou (uma por raiz), e
o **mutation test** que prova que o filtro é load-bearing nas duas direções.

## O gate nunca exercitava a cura — 1 de 58, e naquele 1 o defeito é invisível

A REGRA 31 só rodava `--assert-parity` em grafo que **já tem lente**. O juiz reintroduziu o defeito
original inteiro e rodou no único grafo vigiado: **`✅ paridade, 881 nós`, exit 0**. Motivo medido:
aquele grafo tem **zero** nós `drifted`/`unverifiable`; o único do corpus que tem **não tem lente**.

A separação estava **escrita no comentário do check desde sempre** e o código não a respeitava:
(a) drift de **conteúdo** compara a lente contra o grafo — sem lente não há o que comparar, opt-in
certo; (b) drift de **parser** compara **dois motores** sobre o mesmo `.kg.yaml` — a lente não entra
na conta. A paridade saiu de dentro do `continue`.

**E estender aos 58 achou drift real na hora.** Cinco grafos reprovaram, com correlação perfeita:

```
os 5 que reprovaram  = os 5 que usam `on:`
os 53 que passaram   = os 53 sem `on:`
```

A lente **parseava `eon[]` e nunca o usava no grau**; o motor conta (`kg-radar.sh:297`). `EV_RELAY`:
motor `4×1×1×(1+4)=20.00`, lente `(1+3)=16.00`. Drift de parser vivo, exatamente o que a REGRA 31(b)
existe para pegar — invisível porque o gate olhava para o único grafo que não o exercita. Depois da
cura: **58/58**.

## A soma era cega a mais da metade do peso

O juiz mutou `superseded` 0.2→0.9 (4,5×) e `done` 0.1→0.9 (9×) em grafo **real**: ✅ verde nos dois.
`r_sum` vinha do `--open-tsv` e `v_sum` replicava a mesma denylist, então **4 dos 7 slots ficavam fora
por construção** — 53% do peso cego num grafo, 64% noutro. E o comentário que eu escrevi no código
afirmava o oposto: *"a SOMA pega QUALQUER divergência"*.

Somado ao **cancelamento** (trocar os pesos de dois nós inverte a ordem de urgência e a soma não
muda: `10.40+8.00 == 8.00+10.40`), a soma foi substituída por **vetor**: `id → peso` de **todos** os
nós, ordenado por id, comparado com `diff`, nomeando o nó culpado.

**Uma cura que resolveu quatro achados e uma dívida:** some o cancelamento, some o buraco de escopo,
some o falso-positivo de arredondamento — e some a **denylist replicada** que eu declarara como
dívida no PR anterior, porque ela só existia para poder somar.

## Mais quatro fail-opens fechados

- **Um nó órfão desarmava a guarda inteira.** O bloco de peso vinha **depois** do early-exit que sai
  `0` quando o radar não reporta contagens — e ele só as imprime quando está verde. Mesma lente
  adulterada: grafo limpo reprovava, grafo com um órfão saía 0. Peso não depende de integridade.
- **Lib corrompida (não só ausente) furava o fail-loud** e a paridade culpava **o grafo**. Agora
  vetor vazio reprova nomeando o **instrumento**.
- **O caso `(b)` passava por vácuo** para o `kg-view`: chamava `--integrity`, que ele **não tem** —
  saía 2 por modo inválido, e o nome do arquivo vinha da mensagem do `cat`. Apagar a guarda inteira
  mantinha o caso verde. Agora usa um modo que existe e cobra a palavra que **só a guarda escreve**.
- **O caso `(c)` provava com o mutante já apagado**: `cmp` contra arquivo inexistente devolve 2,
  nunca 0 — a guarda-da-guarda nº1 estava **morta por construção**. É a 3ª vez que a família
  *"medi um artefato que não estava lá"* morde nesta casa, então a checagem foi para dentro do
  `_prove_mutation`, no chamador obrigatório, e não para a memória de quem escrever o próximo.

E o `(c)` tinha um erro conceitual meu: ele mutava **a lib**. Com sítio único, mutar a lib muta os
**dois** motores — eles voltam a concordar e o caso passa por vácuo. O mutante tem de ser **a lente**.

## O bundle não fechava o grafo de dependências

Um manifesto que leva `kg-radar.sh` sem `lib/status-factor.awk` montava limpo, passava no lint, e o
plugin **nascia morto no adotante** — saindo 2 no primeiro uso, no ambiente de quem instalou. Não é
hipotético: aconteceu ao introduzir a lib, e foi curado **à mão** nos dois manifestos.

Cura à mão não se repete sozinha. Virou **aresta de construção** no `assemble-plugin.sh`, o único
ponto por onde toda vertical passa: ele varre os `.sh` copiados por referência a `lib/<arquivo>` e
**aborta** se o alvo não estiver no `VALIDATION[]`.

**E a primeira versão dessa guarda era destrutiva** — quinto defeito meu neste PR, achado pelo lint
logo depois de eu escrevê-la. Ela abortava **dentro do laço de cópia**, então o assembler que desiste
deixava o destino em ruínas:

```
recusa da 1ª versão →  21 arquivos sujos em plugins/, plugin.json DELETADO
                       lint: "plugin fora de sincronia com a fonte"
```

**Guarda que aborta tem de abortar ANTES de tocar no destino** — senão a recusa é mais destrutiva que
o defeito que ela recusa. Foi para junto da validação de fonte, onde moram todas as outras checagens
do script, e o caso `(h)` passou a medir **o estado do destino**, não só o exit code.

## Verificação

- **58/58** grafos em paridade (era 1 de 58 fiscalizado, e 5 divergências reais achadas ao estender)
- guarda: **7/7** nas quatro direções — as 3 regressões gritam, os 2 casos históricos gritam, o
  falso-positivo e o `pipefail` calam
- cancelamento: soma `18.4` nos dois cenários, **vetor diferente** — a guarda antiga não veria
- assembler: manifesto sem a lib **aborta** (rc=2, nomeando os dois scripts); íntegro **monta**
- bancada completa e lint: ver rodapé

## Dívida declarada — não resolvida neste PR

- **O sentinela `-1` tem tradução divergente em 5 sítios** (`0` no radar/state/freshness/lente,
  `1.3` no `--open-tsv`). O sítio único cobre o **fator**, não o **sentinela**. Neste PR o
  `--weights-tsv` foi alinhado ao `0` do painel de propósito, e isso está escrito no código — mas a
  cura estrutural é a lib expor `statusFactorFila()` / `statusFactorRadar()` e as 5 linhas de clamp
  virarem chamadas.
- **`--assert-parity` continua sem seletor de grupo na bancada**: verificar os casos novos exige
  rodar 8.700 linhas. O juiz observou que um `--only <grupo>` é o que teria exposto o vácuo de `(b)`
  e `(c)` **na própria autoria** — reproduzir um mutation test em segundos muda o que o autor
  consegue verificar.
- **`_lib_ao_lado` engole o próprio erro** em ~18 chamadores.
- **Os detectores (2)(3)(5) da guarda** seguem contando caractere dentro de aspas, com o comentário
  afirmando o contrário. A `semAspas` curada não foi estendida a eles.

## O fio de método

O juiz registrou o que mais importa, e vale contra mim: **nenhum dos quatro HARD apareceu para quem
escreveu o código.** Dois deles eu *introduzi curando outra coisa*, e um terceiro eu havia declarado
como "dívida latente" — quando era **explorável**, e o juiz mediu a exploração.

A regra que fica é a que a `semAspas` ensinou por dano: **filtro anti-ruído nasce com o par que prova
que ele não cegou o alarme.** Sem o par, silenciar a guarda inteira passa no teste — e foi o que
aconteceu, 11/11 verde, no mesmo arquivo que já tinha essa lição escrita duas vezes.
