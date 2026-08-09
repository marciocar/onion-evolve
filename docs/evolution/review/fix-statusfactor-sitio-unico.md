---
branch: fix/statusfactor-sitio-unico
date: 2026-08-09
reviewed_diff_sha256: e9310289f249aad04295ce2b450bca646ec9354f22c517185096c20d07f276da
findings_total: 7
findings_real: 7
findings_fixed: 7
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-DECLARADO-A-VERIFICACAO-FOI-POR-MUTACAO-E-PELA-PROPRIA-BANCADA
reviewer: sem passada adversarial — ver a seção "O que NÃO foi feito"
---

# A lente pesava ZERO o nó mais urgente, e a paridade não via

## O defeito

O fator de status vivia **copiado** em cinco scripts. Quando `drifted` e `unverifiable` entraram no
enum (2026-08-06), o radar ganhou os slots e a **lente não** — passou a devolver `-1`, clampado a 0.

Medido, no nó real que a catraca do PR anterior trouxe de volta à vida:

```
D_email_plus_logto_connector (unverifiable, grafo da VPS)
  radar : 8.00        lente : 0.00
```

E o `--assert-parity` **não via**, porque comparava `node_count` e `edge_count`. As duas lentes
concordavam em **quantos** nós existem e discordavam em **qual é o mais urgente** — que é a única
pergunta que o painel responde.

## A correção

- **Sítio único**: `lib/status-factor.awk`. Zero cópias em script (medido com `git grep`), e os dois
  plugins mais a lente vendorizada leem dele.
- **Fail-loud**: ausência da lib é `exit 2` **nomeando o arquivo**. Isso se provou sozinho — a
  primeira montagem sem a lib no manifesto fez o plugin sair 2 em vez de rodar com fator errado.
- **`--assert-parity` compara PESO**: a **soma** da atenção dos nós em aberto, mais a **identidade**
  do topo.

## Os defeitos que EU criei ao curar, e como cada um apareceu

**1 · A primeira paridade de peso passou VERDE no mutante.** Eu comparava só o **topo**, e o nó
afetado (8.00) não era o topo daquele grafo (14.40). Cobrir o ramo sem o caso real — dentro da
própria cura. Achado pelo meu mutation test, não por leitura.

**2 · A segunda versão gerou FALSO-POSITIVO** no único grafo com lente do repo: eu comparava o valor
**arredondado para exibição** do `--radar` (`%5.1f` → `42.8`) contra o preciso da lente (`42.75`).
O topo passou a comparar **identidade**; o valor ficou com a soma.

**3 · O sítio único quebrou 6 mutation tests alheios**, que copiavam o motor sem a lib e passaram a
ver o `fail-loud` em vez do comportamento. Curado com **um helper** (`_lib_ao_lado`), não com seis
remendos.

**4 · E a minha varredura automática quase destruiu o teste do `fail-loud`**: ela inseriu a lib
exatamente onde a **ausência dela É o teste**. O caso `(b)` teria passado por vacuidade, com o
`fail-loud` nunca disparando. Varredura mecânica não sabe qual cópia é deliberada — a razão ficou
escrita nos dois sítios.

**5 · A suíte inteira abortava com `rc=3`, sem soma e sem o grito do trap.** Reproduzido
deterministicamente (267 linhas, duas vezes) e isolado num **terceiro** sítio de cópia que minha
enumeração não cobria: o `kg-console` rodava num tmp sem a lib, o radar saía 2, o console saía 3, e
`HN="$(...)"` sob `set -e` derrubava tudo. Antes de perseguir, **medi e descartei** a hipótese barata
(disco em 27%, inodes em 5%).

**6 · `status-reverif (f)` virou vácuo por INVERSÃO.** Ele mutava o *script* e checava
`! grep -q <padrão> m.sh` — mas o fator mudou de arquivo, então a linha nunca esteve lá e a negação
virou sempre-verdadeira. Agora muta a **lib** e prova com `cmp` de arquivo.

**7 · Uma guarda da casa pegou o meu código**: `sort | head -1` fecha cedo e dá EPIPE sob `pipefail`.
Trocado por `sed` sem `q`, que **drena**.

## E a guarda que gritava errado — 5 disparos numa sessão

`bash-empty-result-guard.sh` acusava `EXIT-CODE-DE-PIPE` em:

```bash
bash algo.sh > arquivo 2>&1
echo "rc=$?"; grep -E 'Passaram|Falharam|ABORTOU' arquivo
```

O `$?` vem de um **redirect** (correto) e o único `|` está no **padrão do grep**. A heurística
contava `|` **dentro de aspas** como pipe de shell. É a **3ª classe** de falso-positivo dela achada
POR USO — o arquivo já documenta as duas anteriores.

Curado removendo os trechos entre aspas **antes** do teste, com as duas direções medidas: **cala** no
redirect-com-grep, **dispara** em `find | tail` + `$?` e em `ls | wc -l; echo $?`.

**Guarda que grita errado ensina a ignorar a guarda** — mesma família dos falsos-positivos HARD que
esta casa vem curando nos gates do KG, e por isso o mesmo rigor.

## Verificação

- `git grep -l 'function statusFactor' -- '*.sh'` → **zero**
- lente × radar no nó `unverifiable`: **8.00 = 8.00** (era 0.00 × 8.00)
- mutante que zera `unverifiable` na lib → paridade **reprova** (`exit 1`); intacto passa nos 3 grafos
- 3 selftests novos (`status-factor` a/b/c) · bancada completa e lint: ver rodapé
- plugins regenerados **depois** da última edição, e a regeneração passou a sair na mesma invocação
  da medição — cinco vezes nesta sessão eu medi artefato derivado que estava defasado

## O que NÃO foi feito, declarado

**Não houve passada adversarial neste PR.** Os PRs anteriores desta sequência tiveram Elenxo; este
não. O que substitui, e é menos: mutation test em cada afirmação central (paridade de peso, fail-loud,
sítio único), as duas direções medidas na guarda, e a bancada completa em corrida solo.

O risco que isso deixa é conhecido e tem nome nesta sessão: **três vezes um Elenxo achou defeito que
o meu próprio teste não alcançava** — a direção da aresta, o `prev` vazio, a colisão de id. Um
revisor independente aqui provavelmente atacaria a **soma de pesos** (ela é agregada: duas
divergências que se cancelam passariam) e o **escopo do filtro** que eu uso para somar (repliquei a
denylist do radar dentro do `kg-view`, o que é uma **segunda cópia da mesma regra** — exatamente o
defeito que este PR existe para curar, num campo adiante).

Esse último ponto fica declarado como dívida, não como resolvido.

## Dívida declarada

- **A soma de pesos é agregada** — duas divergências de sinal oposto se cancelariam. Comparar o
  vetor completo (ou um hash dele) é o passo seguinte, e custa uma passada a mais.
- **A denylist do escopo está replicada** dentro do `--assert-parity` do `kg-view` para poder somar
  só os nós em aberto. É cópia de regra, no PR que mata cópia de regra. O certo é o radar expor a
  soma e a lente consumi-la.
- **`--assert-parity` roda por grafo e só há UMA lente no repo** — a guarda continua exercitada em
  1 de 58 grafos. O valor real aparece quando houver a segunda.
