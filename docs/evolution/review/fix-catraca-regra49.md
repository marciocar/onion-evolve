---
branch: fix/catraca-regra49
date: 2026-08-08
reviewed_diff_sha256: e335863d53b477421a233f0b9efa6eda52f3981c1c24826adf303ece19f32b12
findings_total: 21
findings_real: 17
findings_fixed: 9
tokens: 609253
duration_min: 27
verdict: HARD-MAS-NAO-COMO-ESTAVA-A-PORTA-CONTINUAVA-ABERTA-POR-TRES-ROTAS
reviewer: Elenxo — 4 refutadores por lente + juiz (opus/high), wf_fa9e6ad4-4b7
---

# Passada adversarial — o PR dizia que a porta tinha fechado, e ela não tinha

**4 lentes, 21 achados, 0 descartados por falta de superação. As QUATRO lentes deram `CAI`.**
Veredito do juiz: **«HARD, mas NÃO como está.»**

O eixo do PR sobreviveu inteiro: a denylist em sítio único é a cura correta da raiz, com custo zero
verificado, e classificar a saída do escopo em cinco é estruturalmente superior ao `OBSOLETA` que
afirmava um carimbo. O que **não** sobreviveu foi a **afirmação de fecho** — e ela era o ponto.

## As três rotas que continuavam abertas, duas delas sem forjar nada

**1 · Apagar a linha do baseline no mesmo commit.** O laço de classificação era dirigido por `known`
— o baseline **atual**. Chave apagada some do universo de julgamento e ninguém a classifica; e a
catraca só reprovava quando o baseline **crescia**. Reproduzido:

```
sed no status: confirmed → refuted   +   grep -v da chave no baseline
→ exit=0 · 0 VIOLATION · no escopo sem carimbo: 47 · HARD: 0
```

O custo do bypass tinha subido de **um `sed`** para **um `sed` + um `grep -v`**. Pior: o desenho
punia quem fazia a coisa **menos** encoberta (deixava a linha e levava HARD) e libertava quem
apagava o rastro inteiro. **Curado:** o julgamento passa a ser dirigido por `prev ∪ known`.

**2 · A direção da aresta — e este é o achado mais forte da rodada.** `tem_aresta` casava
`(ef == ID || eto == ID)`: o nó servia como **origem** ou como alvo. Um nó que **refuta outro**
ganhava passe livre para se declarar `refuted`. O juiz mediu no corpus real: **8 das 48 entradas do
baseline** são `from` de uma aresta REFUTES/SUPERSEDES, e fugiam com **um `sed` no `status:`**, sem
forjar uma linha de aresta. E a convenção do corpus é inequívoca no outro sentido: nas 3
conformidades reais o refutado/superseded é sempre o `to`.

*(Os oito ids ficam fora deste texto de propósito. A 1ª redação os enumerava — no artefato e no
comentário do próprio script — e o `vendor-scrub` reprovou com HARD: ids de nó carregam nome de
adotante e o script viaja vendorizado. É a mesma REGRA 36 pela qual este baseline guarda `sha1(id)` e
não o id, cometida no comentário que explica o hash. Conte, não liste.)*

**3 · Self-edge, aresta invertida e emissor fantasma.** Três linhas (`from: X / to: X`) compravam
`RECONCILIADO`. Um nó não se refuta sozinho — e o gate ainda **imprimia** que houve reconciliação.
É o vício que o próprio cabeçalho nomeia ("o gate AFIRMAVA um carimbo que não existia") reencarnado
um campo adiante.

**Curado nas três:** aresta **ENTRANDO**, **duas pontas distintas**, de **qualquer um** dos dois
tipos de reconciliação. Não é *"existe uma aresta por perto"* — é *"alguém, que não ele mesmo, o
reconciliou"*.

## O falso-positivo que a mesma correção matou de graça

Derivar o tipo da aresta do status (`superseded` → exige SUPERSEDES) acusa a reconciliação que o
`kg-radar.sh:620-621` **sanciona**: *"recebe REFUTES mas segue status=… (reconciliar: refuted ou
superseded)"*. Quem escolhe `superseded` nesse fork não tem aresta SUPERSEDES, e levava
`HARD FUGA-SEM-ARESTA`. Mesma família dos 3 falsos-positivos que o Elenxo da REGRA 57 derrubou, e no
**mesmo grafo** (`m2-bridge-logto`) que o contrato chama de *"o dogfood CERTO"*.

Nota de honestidade: a lente apresentou este achado como REPRODUZIDO no nó `E_federation_projected`,
e o **juiz derrubou a reprodução** — o nó não está no baseline, e a repro proposta dá `48 · 48 ·
HARD: 0`. O gap é **latente, não corrente**. Está corrigido porque cai na mesma linha, não porque
alguém o viu disparar.

## O gradiente que estava invertido

A memoização `UNIVERSO_CARREGADO` era **morta**: todo consumidor roda em command substitution, a
atribuição morria com o subshell, e o universo era relido a cada chave. Medido no **estado-alvo da
própria catraca** (os 48 nós já medidos):

```
antes  20,1 s      depois  7,2 s      saída byte-idêntica (diff vazio)
```

Uma linha — `carrega_universo` içado para o escopo pai. Sem ela, quanto mais a doutrina fosse
obedecida, mais lento ficaria o gate que a cobra.

## O que eu escrevi no cabeçalho e ninguém tinha observado

O comentário afirmava: *"sem a checagem de aresta o guarda acusaria 3 CONFORMIDADES"*. **Falso**, e
falsificável em um comando. Hoje `--emit-baseline` é idêntico ao baseline versionado, logo o laço da
guarda de direção **nunca executa** no corpus real, e nenhum dos 3 nós citados está no baseline:

```
sed 's/exit(achou ? 0 : 1)/exit(1)/' … | awk … | sort | uniq -c
→ 48 SOFT PASSIVO, ZERO HARD
```

O fato de base era verdadeiro (os 3 nós existem e têm sua aresta); a **consequência** era inventada.
Escrever medição não-observada no cabeçalho de um gate cuja tese é `declarado ≠ verificado` é o
defeito da REGRA 49 cometido dentro do instrumento. O texto agora diz que a checagem é **preventiva**
e carrega junto o comando que o falsifica.

**A outra medição central resistiu:** custo-zero da denylist é **verdadeira**, conferida pelo juiz no
corpus (43 confirmed + 5 open + 2 superseded + 1 refuted; `drifted`/`unverifiable`/`done` sem carimbo
= 0). Gate 48 antes e depois.

## Três defeitos meus que a bancada solo pegou antes do juiz — e a lição já anotada

A bancada morreu **duas vezes no mesmo ponto**, `rc=1`, zero `✗`, nenhuma soma. Li a primeira como
colisão de corrida. Era determinístico, e eram três defeitos empilhados, todos do `set -euo pipefail`
que a bancada tem e que **meu runner isolado não copiava**:

1. `cmd; rc=$?` mata a suíte no comando que retorna ≠ 0, antes da atribuição;
2. `pipefail` faz `helper | grep -q` devolver o exit do **helper** — e ele sai `1` justamente quando
   **acha** HARD, então o `_prova_mutacao` acusava `FIXTURE MORTA` sobre fixture viva;
3. `_g49` terminava em `[ -n "$6" ] && printf`, que devolve `1` sem aresta — a fixture derrubava a
   suíte **antes do primeiro caso**.

No meu runner: 16/16 verdes. Na bancada real: morta no caso 7. **Dois números, e o confortável era o
falso** — que é exatamente a memória `bancada-espelha-o-runner` desta casa, cometida de novo.

**Cura mecanizada:** trap de `EXIT` que grita se a suíte terminar sem imprimir a soma, nomeando os
dois suspeitos e mandando copiar o `set` para runners extraídos. Provado nos dois sentidos.

## A cobertura de teste, medida por mutação em vez de contada

O juiz rodou um sweep e achou **cinco mutações que sobreviviam 9/9**: ignorar a direção da aresta,
ignorar o tipo, aceitar self-edge, trocar `SOFT REMOVIDO` por `HARD`, e zerar o contador `hard`. Os
9 casos usavam **só** `refuted`, **só** a aresta certa, **só** baseline de uma entrada, e **nenhum**
lia o exit do helper.

Agora são **21 casos** (7 + 14), a fixture fabrica direção (`in`/`out`/`self`) e tipo, o baseline é
**commitado** (sem isso o `prev` fica vazio e metade da cura nunca é exercitada), e três casos aferem
o **exit** do gate. Sweep refeito contra a bancada endurecida: **as 6 mutações acusam**.

E o `sed` do mutation test da aresta passou a ter **range limitado à função** — o padrão
`exit(achou ? 0 : 1)` aparece duas vezes no helper, a segunda dentro do comentário que documenta o
comando de falsificação. Um `sed` solto mutava os dois e o `cmp` passaria a diferir por duas razões:
a armadilha de padrão-que-casa-a-si-mesmo, um passo adiante.

## Verificação

- corpus limpo: `48 · 48 · HARD: 0 · SOFT: 0`, exit 0, **0,77s** — zero regressão
- as 5 reproduções do juiz, refeitas por mim em sandbox: bypass do `grep -v` → **HARD, exit 1** ·
  `E_RESEARCH` (nó real, aresta invertida) → **HARD** · self-edge → **HARD** · fork `superseded` via
  REFUTES → **SOFT RECONCILIADO** · **fluxo legítimo** (mede, carimba, remove a linha) → **SOFT
  CARIMBADO, exit 0**
- içamento: 20,1s → 7,2s com saída byte-idêntica (`diff` vazio)
- bancada completa, corrida **SOLO**, sob as opções reais: ver rodapé
- `lint-artifacts` 0 HARD · `kg-radar` exit 0 nos dois grafos

## Dívida declarada — sai deste PR de propósito

- **`git mv` para qualquer pasta `fixtures/` esvazia o baseline em lote.** Um `git mv` de um arquivo
  tirou **5** entradas de uma vez, com o gate mandando removê-las e os nós intactos no disco,
  versionados, afirmando sobre produção. Exige resolver a chave por hash em **todo** o universo antes
  de concluir remoção, mais uma classe `MUDOU-DE-PATH`. Mexe na convenção `grep -v '/fixtures/'` que
  é da casa inteira (`kg-radar-integrity.sh:41`), não deste PR.
- **`REMOVIDO` como SOFT.** Apagar o nó também não deveria encolher o número sozinho. É a metade
  coerente da objeção sobre reclassificação — resolve-se **endurecendo o REMOVIDO**, não afrouxando
  o FUGA-DE-ESCOPO. O replay histórico de 152 commits deu **zero** rebaixamentos honestos.
- **Colapso de campo do `IFS=$'\t'`.** TAB é IFS-whitespace: campo vazio some e o resto desliza, e um
  nó **medido** levava `HARD FUGA-DE-ESCOPO` com `status:2026-08-08` na mensagem — a guarda acusando
  o ato que existe para premiar. Latente atrás do `kg-radar-integrity.sh` (0 nós sem `status` em
  2.130), mas é regressão contra o script antigo. Trocar por `\037` nos seis sítios internos.
- **`verified_at: nunca-medi-isto` compra "foi MEDIDO".** O irmão `doctrine-freshness.sh` já trata
  carimbo malformado como `HARD MALFORMED`. Coerência entre irmãos, risco baixo.
- **Emissor fantasma** (aresta de um `from` que não existe como nó): zero endpoints cross-file em
  2.512 arestas, e quem forja aresta forja nó. Valor baixo.

## NÃO-VERIFICADO, declarado — e é o fio mais honesto deste PR

**As cinco classes novas não têm NENHUMA cobertura de campo.** `--emit-baseline` é hoje idêntico ao
baseline versionado, logo o laço da guarda de direção **nunca executou no corpus real, nem uma vez**.
Toda a evidência de que este bloco funciona é **sintética**. O primeiro nó que sair do baseline de
verdade — via `/meta:kg-freshness` — é o **primeiro dogfood real** desta guarda, e é aí que ela vale
ou cai. O verde do CI não substitui essa medição.

## O fio de método, que é o que esta rodada mais ensina

Dois dos quatro achados confirmados (a direção da aresta e o `git mv`) **não são variantes do defeito
curado** — são a **mesma classe reaparecendo num campo diferente a cada rodada**. A pergunta que
sobra não é *"esta porta fechou?"*, é: **por que este guarda é fundado num predicado que aceita
qualquer coisa que TOQUE o nó, num arquivo que qualquer `git mv` remove do universo?** Enquanto a
identidade do nó for `path::hash` e o álibi for proximidade, cada Elenxo vai render mais um `sed` de
uma linha.
