---
title: 'Resíduo — quatro guardas que diziam menos do que pareciam, achadas por quem usa'
date: 2026-09-18
branch: fix/kg-doctrine-matches-engine
reviewed_diff_sha256: PENDENTE
findings_total: 6
findings_real: 6
findings_fixed: 6
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Dois sinais de campo do mesmo adotante, medidos com arquivo:linha dos dois lados, confirmados
  no vivo antes de curar. E um deles já estava curado sem que o remetente soubesse — medir o que
  mudou desde a chegada do sinal faz parte de triar.
---

# O adotante foi construir em cima da doutrina e conferiu se ela era verdade

Não era, em onze pontos. Este PR fecha os dois mais baratos e de maior retorno — os que o próprio
sinal ordenou por custo — e confirma no vivo **antes** de curar.

## Achado 1 — a KB promete cinco reprovações; o motor faz cinco OUTRAS

`knowledge-graph-sdaal.md:195-196` afirmava que a INTEGRIDADE reprova: nó `refuted` recebendo
`SUPPORTS` · `decision` `done` fora do plane PROD · órfãos · migalhas pendentes · ciclos
`DEPENDS_ON`.

O motor (`kg-radar.sh:27-29`) barra: **ids duplicados · aresta para nó inexistente · órfão ·
contradição (`REFUTES` entrando em nó `confirmed`/`open`) · enum inválido**.

Placar medido pelo adotante: **uma implementada** (órfãos), **três ausentes**, **uma rebaixada a
aviso**. Não há detecção de ciclo (`grep 'ciclo'` = 0; `A→B→A` passa com exit 0).

**A correção é o texto alcançar o código**, nunca o contrário — o cabeçalho do motor já trazia a
lista certa. E o placar **fica registrado** em vez de apagado, pela mesma razão que a casa já aplicou
uma vez: *"apagá-lo transformaria a vitrine em propaganda"*.

Por que importa, nas palavras do sinal: *"hoje a KB promete um gate que não existe, e um adotante que
confie nela constrói sobre areia."*

Corrigido junto: a atenção era descrita como **"PageRank ponderado"** e o motor nunca fez PageRank —
sem iteração, sem amortecimento, e com **grau não-direcionado**. A diferença não é cosmética: grau
não distingue *"conectado a coisas importantes"* de *"conectado a muitas coisas"*, e ordenar atenção
é a função central do radar.

## Achado 2 — o radar saía verde sobre conhecimento caduco

`meta.review_after` está na gramática e em 16 grafos. Quem o cobrava era só a REGRA 67 (Grafo de
pesquisa com REVISITA carimbada) — **SOFT, e no lint**. Medido: `grep -c review_after kg-radar.sh` = **0**.

Então **quem rodava o radar nunca sabia que o grafo tinha vencido**. Isso é pior que não ter o campo:
é um painel que afirma saúde sem ter olhado para a validade.

Nas palavras do sinal: *"não é feature nova, é parar de esconder"*.

Seção **VALIDADE** nova, com os três estados — vencido, em dia, e **não-medido** (grafo sem o campo
declara que não mediu, em vez de silêncio). **Não reprova**, por doutrina explícita do sinal:

> *"nada disso nasce bloqueando — um gate que impede trabalho é contornado com `--no-verify` na
> primeira sexta-feira, e aí se perde o mecanismo E a informação."*

O caso **(b)** da bancada existe só para guardar isso: se alguém transformar o vencimento em muro,
ele reprova.

## Achado 3 — um item do sinal já estava curado, e o remetente não sabia

O sinal de 09-11 pedia, como item de **maior** retorno, *"ligar o hook de leitura — o menor, e o único
que teria evitado o caso deste sinal"*. Medido hoje: `kg-read-leg.sh` **existe e está registrado no
`settings.json`**.

Ele pagou um dia de trabalho e quatro teses erradas para medir o custo da lacuna, e a lacuna fechou
sem que ele fosse avisado. **Medir o que mudou desde a chegada do sinal faz parte de triar** — sem
isso, a resposta ao adotante seria sobre um mundo que não existe mais.

## Um defeito meu, no harness

A 1ª redação do caso (b) reprovou acusando *"o vencimento virou muro"*. Era **falso**: a fixture não
declarava `impact`, a INTEGRIDADE reprovava por isso, e o `rc=1` não tinha nada a ver com validade.
SUT correto, harness incompleto — a mesma classe que esta casa já registrou em
`[[bancada-espelha-o-runner]]`.


---

# Os dois do design: o gate dizia "passou" e queria dizer outra coisa

Dois adotantes independentes mediram a mesma classe em superfícies diferentes. Os três fail-opens
abaixo têm a **mesma forma** dos dois do KG acima — e é por isso que entram no mesmo PR.

## Achado 4 — o gate aprovava em silêncio uma paleta ilegível no escuro

`lint-design-tokens.sh` só calcula os pares que `governance/contrast-pairs.json` **declara**. Com a
SSOT trazendo `color.dark.*` e a governança cobrindo só o claro, o gate passa — e *"passou no gate"*
vira uma afirmação mais forte do que o gate mediu.

**Custo medido pelo portal-gamificacao**, não hipótese: as quatro candidatas tinham `brand.500` entre
**1,71 e 2,60** contra fundo escuro (alvo 3,0), e **nenhuma teria sido barrada**.

Agora o gate **declara que não mediu o escuro**. Não reprova — a governança é do projeto e pode haver
razão para não cobrir um modo. O que não se admite é o silêncio. O caso **(f)** da bancada guarda
exatamente isso: se o aviso virar muro, ele cai.

## Achado 5 — sem `jq`, "PULADA" com `exit 0`

Medido pelo jogo-da-vida: sem `jq` o gate saía **0** dizendo PULADA, e **um tint a 1,38:1 virava tema
aprovado**. O consumidor teve de tratar o "PULADA" como falha por conta própria — ou seja, **cada
adotante reimplementava a desconfiança que o gate deveria ter**.

A distinção que faltava: `design-context` **ausente** é legítimo (`exit 0`); **ferramenta** ausente
com o contexto **presente** é *"não pude julgar"* — e guarda que não pode julgar **declara**, nunca
aprova. Mesmo precedente da REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente), que sai
HARD nomeando a ausência quando o manifesto não responde.

O caso **(i)** existe para a cura não virar dano: sem `design-context`, o gate **segue gracioso**.
Sem ele, eu teria punido todo adotante que não faz design ao curar quem faz.

## Achado 6 — e eu inventei duas variáveis ao curar

A 1ª redação do aviso do escuro lia `_ALL_TOKEN_KEYS` e `_HAS_DARK_BRANCH`. **Nenhuma das duas existe
no script.** E o `set -u` não pegaria, porque eu havia escrito `${VAR:-}` — o efeito real seria a
guarda **calar para sempre**: um fail-open dentro da cura de um fail-open.

A fonte verdadeira estava a um `grep` de distância: o array `TOK`, que o parse já preenche.
**Conferir a existência do que se lê é a metade barata de qualquer guarda** — e foi só porque rodei o
`grep` que apareceu.
