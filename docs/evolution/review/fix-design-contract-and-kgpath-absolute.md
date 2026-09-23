---
reviewed_diff_sha256: "6a9d669c1085077b08d625b9cb4ad7778297d8ee785db5190c3584c858566370"
findings_total: 9
findings_real: 9
tokens: 186000
duration_min: 17
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Passada adversarial (opus/high, mandato REFUTAR, default REPROVADO, isolation worktree) sobre a
  leva do sinal de campo de 2026-09-07. REPROVOU com 9 achados reais, 2 graves — o pior deles:
  minha cura REINTRODUZIU o defeito do sinal com o prefixo trocado. Refutou 6 dos meus próprios
  ataques e declarou 3 lacunas.
---

# Resíduo — a cura reintroduziu o defeito com o prefixo trocado

## O achado que importa (A1)

Eu troquei uma lista fixa de nomes de foundation por *"derive os alvos de `{alias}` do `semantic/`
e emita esses paths"*. Os alvos vêm como **`{color.brand.orange}`** — com o grupo `color.` — e o
adapter **reinsere** o grupo ao aninhar em DTCG. Um worker obedecendo meu texto ao pé da letra emite
`color.color.brand.orange` e **todo alias vira órfão**: o refutador rodou o gate real sobre a SSOT
real e mediu **12 de 12 HARD**.

O texto VELHO dava a lista na forma certa (`brand.orange`). O meu mandava derivar a forma errada.
**É exatamente o modo-de-falha que o sinal relatou** — *"o gate não conseguia casar"* — reproduzido
pela cura dele. Faltava uma cláusula: *tire o grupo raiz; o adapter o reinsere*.

## Os outros oito

| # | achado | cura |
|---|---|---|
| A2 | o caso (a) da bancada usava `cmd; rc=$?` sob `set -e` → **abortava a suíte**; o `record_fail` abaixo era código morto, e (b)–(e) nunca rodavam justamente quando o corpus regride | captura dentro de `if` — o mesmo idioma que (c) já usava certo, 20 linhas abaixo |
| A3 | o contador de chaves ignora strings e comentários, e mentia nas **duas** direções: `{` solta numa string → corpo vazio → o arquivo vira módulo puro, **degradando o wrapper de volta ao bug que ele cura**; e `export const meta` em comentário reprovava script válido (o `onion-research.js` tem 12 linhas de comentário acima do meta) | **parei de contar chaves**: tiro o `export ` de uma declaração só, ancorada, `count=1`, e envolvo o arquivo inteiro |
| A4 | a skill do plugin mandava rodar um arquivo **que o assembler não empacotava** — guarda nasce morta no consumidor; nenhum gate pega (a **REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core, com catraca)** cobre caminho NU, e este fora reescrito) | entrou no `VALIDATION=()` do manifesto, com o porquê; verificado rodando de dentro do plugin |
| A5 | o `KG_ANCHOR` era **100% prosa**: eu escrevi "a segunda metade é a que MEDE" e não havia uma asserção sequer — `kgPath` era `{type:'string'}` puro e o código só **logava** o que o agente dissesse | `pattern: '^/'` no schema + `kgPathOk()` exigindo que o absoluto **termine** no caminho pedido, nos 2 pontos de consumo |
| A6 | o caso (d) não era fixado por mutante nenhum — apagar a checagem `[ ! -f ]` sobrevivia 5/5 | (d) passou a exigir a **mensagem**, não só o rc |
| A7 | `python3` ausente saía rc=1 acusando o **arquivo**, em vez de "não pude julgar" | vira `⊘` + exit 2, como o ramo do `node` |
| A8 | a lista ilustrativa nova **continuava errada**: omitia `neutral.300`, que o `semantic/` real referencia | corrigida, e o texto agora diz que a lista **já esteve errada** — derive, não confie nela |
| A9 | ferramenta quebrada sem cobertura na bancada | caso (i) — **e ele achou defeito real**: `command -v node` prova que o binário existe, não que roda; um node saindo 127 virava `✗ arquivo`. Agora rc≠0∧≠1 é falha de ferramenta |

## Uma regressão que eu mesmo abri, e peguei antes do commit

A primeira cura do A3 tirava `export ` de **qualquer** declaração de topo. Com isso um
`export const z = 1` perdido no corpo — que **é** `SyntaxError` no runtime — passava a valer. Peguei
reproduzindo o caso `f1` que o próprio refutador havia construído, antes de commitar. A âncora
estreita (`^\s*export\s+const\s+meta`, `count=1`) deixa todo outro `export` intacto. Virou o caso
(f) da bancada.

## O que o refutador REFUTOU de mim

Seis ataques meus caíram: arquivo vazio, `.mjs` módulo puro, CRLF, a família sob `--jobs auto`, a
regressão nas cópias derivadas (**0 HARD, exit 0**, e as projeções conferidas contra o filesystem:
184 famílias, 1166 sítios, 78 scripts, 11 baselines — todas batem), e a hipótese de que o item 2
fosse "só prosa trocada" — a instrução **é** executável; o defeito era o prefixo. E confirmou o meu
número: **2 de 2** scripts do corpus reprovavam no check documentado.

## Triagem do inbox, no mesmo movimento

Os 3 sinais foram lidos **por inteiro** antes de triar, e isso mudou o desfecho: eu ia arquivar o de
09-10 como "curado pelo #865" e ele tem **onze** achados, dos quais o #865 curou **um**. Medidos hoje:
3 caíram (#6 bi-temporal, #7 `review_after`, #8 — este era o inverso, a doutrina afirmava que status
fora do enum passava sem gate e o corpus tem **4.021 status com ZERO fora**; corrigido riscando a
linha, não apagando). Restam 8, incluindo o placar que dói: a KB promete **cinco** reprovações de
integridade e o motor implementa **uma**.

## A catraca me barrou, e eu não a furei

Os 6 fios da triagem iriam para `fios-abertos.kg.yaml` — que tem teto de **19 nós** e a regra *"onda
nova exige onda COLHIDA"*. O teto **já estava exatamente em 19 antes de eu chegar**: o backlog estava
cheio, e triagem nova não tinha onde pousar. Não havia colheita legítima (2 nós GATED com gatilho
nomeado, 1 com a metade viva de um sinal, 1 questão aberta). Em vez de subir o teto, os fios foram
para um **grafo de pesquisa** (`triagem-inbox-2026-09`), sem opt-in de projeção — o backlog segue em
19, e a promoção é do maestro quando colher. O fato de a catraca estar saturada virou nó próprio.

## O que o CI achou DEPOIS da passada adversarial

O `onion-review-verdict` — o gate semântico que virou bloqueante nesta sessão — reprovou o PR por
**identificadores em pt-BR numa função que eu tinha acabado de escrever** (`kgPathOk(devolvido)`,
local `alvo`). Estava certo.

O achado importa menos que a lacuna que ele expõe: **o universo da guarda determinística de idioma
era só `*.sh`**. Metade da linguagem do repo era invisível a ela, e por isso a violação viajou até
o CI. Três camadas de cura, na ordem em que a medição pediu:

1. os identificadores viraram inglês (e nos dois `.mjs`: `teto`→`budgetCap`, `vereditos`→`verdicts`,
   `nao_medidos_por_teto`→`unmeasuredByCap`, mantendo as **chaves de contrato** que o
   `census-seal.py` lê);
2. o universo passou a ver `.js`/`.mjs`, com extração própria — inclusive **parâmetros**, porque foi
   um parâmetro que escapou. Passivo medido antes de ligar: **2 em 396**, curados no mesmo commit,
   então nasce ZERO. Ao ligar, 37 "HARD" apareceram e **todos vinham de `.claude/worktrees/`** —
   worktree de outro agente, que a guarda não deve medir;
3. e a causa raiz não era a lógica, era o **vocabulário** — a classe dominante em guarda de lista.
   O extrator via `devolvido` perfeitamente; a lista é que não o tinha. Medido: de 15 particípios
   comuns, **14 faltavam**. 153 → 167 termos, todos sem homógrafo em inglês, repo em 0 HARD.

Bancada: +3 casos, inclusive o controle que impede a guarda de gritar por gritar. **22/22** nas duas
famílias.

## Teto declarado

O painel `testing-state.md` segue acusando HARD **no lint local** e não no CI. A causa foi provada,
não suposta: a árvore de trabalho carrega uma versão não-commitada e **mais velha** de outro resíduo,
que apaga 10 achados do ledger; o CI lê o commitado. Provei por geração em worktree destacada que o
painel deste commit é o que a árvore limpa produz. Não descartei o arquivo alheio — aquele blob não
está em commit nenhum, e `git checkout --` perderia texto.
