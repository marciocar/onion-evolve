---
title: 'Resíduo — quatro guardas que diziam menos do que pareciam, achadas por quem usa'
date: 2026-09-18
branch: fix/kg-doctrine-matches-engine
reviewed_diff_sha256: cec0cea36d78983379aab7dbc6f3274a26b972a4a3976af6153617b5c2359561
findings_total: 16
findings_real: 16
findings_fixed: 16
tokens: 198591
duration_min: 28
verdict: CORRIGIDO
elenxo: sim
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


---

# Passada adversarial (Elenxo) sobre o diff EXECUTÁVEL — veredito inicial: **REPROVADO**

Os seis achados acima vieram dos adotantes. Os dez abaixo vieram de um refutador com mandato de
derrubar este PR, rodando os scripts de verdade (28 min, ~199k tokens, 55 chamadas de ferramenta).
Ele **reprovou**. Todos os dez foram curados e cada um ganhou caso de bancada — a família do radar
foi de 4 para 11 casos, a de design de 10 para 13.

## Os dois HARD — e ambos acertavam a TESE do PR

**H1 — `contrast-pairs.json` que EXISTE mas não parseia voltava a ser fail-open, com mensagem falsa.**
A condição era `[ -f "${PAIRS}" ] && jq -e . "${PAIRS}"` numa linha só: JSON corrompido ou sem
permissão caía no `else`, e o gate imprimia *"sem governance/contrast-pairs.json"* sobre um arquivo
que está lá. Pior, o aviso novo do modo escuro vive dentro do ramo `then` — um pairs.json quebrado
**silenciava as duas curas deste PR de uma vez**, com `exit 0` e "design tokens válidos".
A doutrina já estava escrita **sessenta linhas acima**, em `_missing_tool`. Ela não alcançava este
ramo porque ninguém a levou até lá — a forma mais comum de uma cura ficar pela metade.

**H2 — o detector do modo escuro era cego para a topologia que a SSOT desta casa PRESCREVE.**
`docs/design-context/README.md:34` e `index.md:16` mandam usar `modes/<light|dark|hc>.tokens.json`:
arquivos de *override* cujos paths são os **mesmos** semânticos (`color.surface.base`), sem prefixo
`color.dark.` nenhum. Medido: na forma canônica, um `brand` a **2,15:1** no escuro passava com
`OK ✓` e exit 0 — o defeito que esta cura existe para fechar, **intacto dentro da forma que o
próprio framework manda usar**.
Detecção agora é por dois sinais (a chave **ou** o arquivo de modo). E o segundo trouxe um achado
que o gate não cura sozinho: `TOK` é chaveado só pelo path, então um override de modo **sobrescreve
o valor base em silêncio** — dois arquivos, dois tokens, e o escuro some do que foi medido. Está
**declarado**; medir os dois modos exige `TOK` por `(modo, path)`, mudança de contrato do parser.

## O achado mais afiado — S1, e ele é sobre COMO se escreve guarda

O leitor novo de `meta.review_after` casava `^[[:space:]]*review_after:` solto — **a trinta linhas**
do bloco que explica, para o `target:`, as três portas que esse padrão abre e que foram fechadas em
2026-09-11 com `metaClosed` e `metaFieldIndent`. As três reabriram, e aqui a direção é **fail-open**:
com *last-wins*, um `review_after` futuro escondido num submapa, num bloco literal, ou num `meta:`
reaberto depois de `nodes:` **sobrescreve o vencido**, e o grafo caduco sai verde.

> **Campo novo em parser existente herda a superfície de ataque do parser, nunca as curas dele.**
> Proximidade não é herança. As três portas viraram casos (f), (g), (h) da bancada.

## Os demais

- **S2 — comparação de string crua.** `em breve` e `2026-9-8` (vencido há 10 dias, sem zero à
  esquerda) saíam **ambos** como "dentro da validade". A cura já existia no repo — a REGRA 67
  (Grafo de pesquisa com REVISITA carimbada) exige `AAAA-MM-DD` no lint; o radar é que comparava sem
  olhar a forma. Agora há o estado **ILEGÍVEL**.
- **S3 — o "NÃO MEDIDA" nasceu no modo que ninguém chama.** Só existia em `--validade`, um modo com
  **zero** chamadores; em `--all` (o default, e o dos 97 sítios) o radar ficava mudo. Medido no
  corpus vivo: **131 grafos, 25 falavam, 106 calavam**. A guarda declarava que não sabe só onde
  ninguém olhava — exatamente a classe que este PR persegue.
- **S4 — `--validade` era modo fantasma.** Rejeitado na forma composta (`--validade --schema` → rc=2)
  e ausente da ajuda **e da KB**. E aqui a ironia importa: o PR nasceu corrigindo a KB que prometia
  reprovações que o motor não faz, e na mesma leva pôs no motor uma saída que a KB não listava.
  **Doutrina que promete mais do que a máquina faz e máquina que faz mais do que a doutrina diz são
  o mesmo defeito.**
- **S5 — o cabeçalho do gate de design ficou falso neste mesmo PR** ("jq/awk ausente → aviso + exit 0").
- **S6 — `test("dark")` é substring:** um par do *claro* chamado `color.darkblue` bastava para
  silenciar o aviso do escuro. A âncora agora exige `dark` como **segmento** do path.
- **I1 — justificativa que o artefato contradiz.** O comentário dizia que `hoje` entra como variável
  porque *"o mawk não tem systime/strftime"*. Medido: este radar **não roda sob mawk** (morre em
  `asorti never defined`). A razão da reprodutibilidade se sustenta; a do mawk foi removida.
- **I2 — `hoje` vazio** (date quebrado no PATH) fazia tudo sair verde. Agora declara e para.
- **I4 — rótulo `(e)` duplicado** e `rm -rf` repetido na bancada de design.

## O que o refutador atacou e NÃO derrubou

Vale tanto quanto o resto, porque é o que dá força ao selo:

1. **Exit code do radar inalterado** — 131/131 grafos do corpus real + 5 fixtures, `origin/main` vs
   PR: **zero divergência**. A promessa de "avisa, não bloqueia" se sustenta.
2. **Aspas, espaços e comentário inline** em `review_after` são tratados corretamente pelo `trim()`.
3. **Locale** — veredito idêntico em `LC_ALL=C` e `C.UTF-8`.
4. **Injeção/quoting** — `case "${_k}"` com chaves hostis e `-v hoje=` não são injetáveis.
5. **O `exit 2` novo não quebra consumidor** — o único chamador executável já exige `jq` antes e
   trata rc≠0 como falha; ninguém compara `-eq 1`.
6. **As cópias derivadas** (`plugins/onion`, `-engineering`, `-design`) carregam a mudança idêntica,
   sem drift de lógica.

## A lição que fica

A primeira passada sobre o artefato inteiro rendeu os achados de **produto** — e todos os dez são da
mesma família que o PR já perseguia nos outros. Escrever a guarda não imuniza contra a classe que ela
cura; **ao contrário, escrevê-la é quando se está mais perto de reincidir**, porque a atenção está no
caso que motivou, não na superfície inteira.
