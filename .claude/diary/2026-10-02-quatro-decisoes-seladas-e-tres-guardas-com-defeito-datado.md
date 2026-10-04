---
date: 2026-10-02
instance: onion-evolve
type: decision
classification: collective
tags: [evolve, forge-guard, dogfood, elenxo, bancada, decisao-selada]
affects: [meta, validation]
breadcrumb_for: []
share_with: []
next_recommended: "RE-FORJAR O /meta:evolve pelo conjunto das 7 peças — selado pelo maestro em 2026-10-02. ⚠️ CORREÇÃO DE 2026-10-03, leia antes de usar o número: ele é 2/7 (tem a peça 5, destino), EMPATADO com 12 outros, e 37 candidatos estão ABAIXO dele em 1/7 — NÃO é 0/7 nem o menos estruturado. A causa do erro foi instrumento: a projeção markdown do forge-census cortava 12 de 59 EM SILÊNCIO (curado no mesmo dia; hoje ela declara o corte). E o enquadramento certo não vem da contagem, vem do corpus: C_TESE_AUTO_EVOLUCAO (maestro-vivo-2026-08, imp 5) diz, VERBATIM, 'Não estamos atrás do eixo E2 — estamos à frente no PRODUTO do loop e atrás no GATILHO dele.' — o evolve não é fraco de estrutura, é sem gatilho, e são 65 dias sem rodar (não 32: aquele era o número de 2026-08-31). Relógio/cron NÃO está vedado a ele — o W7 escopa o driver, não o auditor read-only. Derive FRESCO contra o vivo (não há plano pré-cozinhado aqui, de propósito): rode o forge-census, leia a cláusula-mãe abaixo, e trate os cinco órgãos (census/radar/drive/onion-research/forjas) como FASES do laço, não como substitutos dele. Os 3 candidatos a guarda também estão selados e cada um tem defeito datado — ordem recomendada: paridade, dogfood-invoke, caso-testa-cópia."
review_after: 2026-11-02
conflict_class: static
---

## Signal

**Quatro decisões seladas pelo maestro em 2026-10-02**, ao fim de uma sessão de 4 PRs mergeados
(#902 ClickUp · #903 triagem · #904 forja de guardas · #905 promoção a hub). Esta migalha existe
porque o maestro pediu reinício imediato para pegar o Claude Code 2.1.288 — e **decisão que só vive
no transcript morre com a sessão**.

| # | Decisão | Estado |
|---|---|---|
| 1 | **Re-forjar o `/meta:evolve`** é a próxima leva | SELADO |
| 2 | **Os três candidatos a guarda valem forjar** | SELADO |
| 3 | O `/meta:study` **espera o gatilho** | SELADO |
| 4 | **Reiniciar** para a 2.1.288 agora | SELADO |

## A cláusula-MÃE do evolve, nas palavras do maestro

Isto não é cláusula *do comando* — é a **constituição do laço de auto-evolução**, e `census`, `radar`,
`drive` e as forjas deveriam **referenciá-la** em vez de carregar pedaços dela por imitação:

> *"ele deve ser o evolve do Onion Evolve"* — o **homônimo**. Raio-X e auditoria dos elementos
> principais, avaliação do backlog, o que aconteceu no mundo, usando dogfood + KG-SSOT-first +
> runtime SDAAL com foco em **transformer, maquinaria e doutrinas**. Propor soluções eficientes e
> eficazes para as lacunas. **Auto-evolução é pela visão de DENTRO**, respeitando, verificando e
> acolhendo o que faz sentido e vem de fora. **Seguir e confrontar** para não fazer nada errado nem
> precipitado, **como guardião do Onion**. *Nem tudo que dizem e que você busca é a verdade — por
> isso **informado é diferente de verificado**.* Sempre com **eficiência e eficácia**.

**O achado que dá urgência** — e ⚠️ **o número abaixo foi MEDIDO ERRADO; a correção está logo em
seguida e é mais instrutiva que o achado**: ~~o repo se chama Onion **Evolve** e o `evolve` dele **não
roda**. Medido pelo `forge-census.sh`: **0 de 7 peças** — ausente do censo inteiro, porque descobre por
CITAÇÃO e o comando cita `doctrine` 5× mas **zero** `census`, **zero** `write(KG)`, **zero** `rules/`,
**zero** `selftests`.~~

**CORRIGIDO EM 2026-10-03, por medição no `--tsv`:** o evolve é **2/7** — ele **tem** a peça 5
(destino: cita `kg-radar`), está **empatado com 12 outros** candidatos, e **37 dos 59 estão ABAIXO
dele**, em 1/7. Nem "0/7", nem "o menos estruturado". A linha riscada fica porque apagá-la
transformaria a correção em propaganda, e porque o **modo de errar** é o que vale guardar:

> **A causa foi INSTRUMENTO, não descuido.** A projeção `--markdown` do `forge-census` tinha um
> `head -12` literal e imprimia 12 de 59 candidatos **em silêncio**. Eu li a projeção, não vi o
> evolve nela, e li a ausência como zero — mas **ausência-por-corte é indistinguível de
> ausência-por-zero** quando o corte não se declara. O cabeçalho até dizia "59 candidato(s)";
> comparar 12 com 59 era trabalho do leitor, e leitor não é mecanismo. **Curado no mesmo dia**: a
> projeção agora imprime quantos ficaram de fora e manda usar `--tsv` para o conjunto.

**E o enquadramento certo não vem da contagem.** Vem do corpus, que já tinha a resposta com
`impact: 5` e Elenxo sustentada-com-emendas — `C_TESE_AUTO_EVOLUCAO`
(`docs/evolution/research/maestro-vivo-2026-08/`), **verbatim**: *"Não estamos atrás do eixo E2 —
estamos à frente no PRODUTO do loop e atrás no GATILHO dele."* (gloss **fora** das aspas: o eixo E2 é
o eixo self-improving do radar.) ⚠️ A 1ª redação desta correção deu como verbatim uma frase
**adulterada** — "do eixo E2" virou "no eixo da auto-evolução", e "loop" virou "laço": substituição
de conteúdo e tradução **dentro das aspas**. Reprovado pelo Elenxo do PR #909.

O mesmo grafo guarda um Elenxo que derrubou 4 vereditos, um deles por **não-sequitur causal** ao
explicar os dias sem `/meta:evolve`. ⚠️ E o número envelheceu: eram **32 dias em 2026-08-31**, são
**65 em 2026-10-03** (medido contra `docs/analysis/onion-evolution-2026-07-30.md`, que segue sendo o
último relatório). Carimbar o valor de agosto como presente é `verify-external-for-current` cometido
dentro de casa.

Ou seja: o evolve **não é fraco de estrutura, é sem gatilho** — e re-forjá-lo pelas 7 peças sem lhe
dar gatilho repetiria o erro com mais peças. ⚠️ **E relógio/cron NÃO está vedado a ele**: a 1ª
redação do nó `Q_GATILHO_DO_EVOLVE_QUAL_E` o proibia citando MOAT W7, e isso era invenção — o W7
escopa o **driver** (que executa), o `automation-ladder-registry.txt` tem **duas** entradas MOAT
(ambas de deploy), e o `evolve.md` não menciona cron em lugar nenhum. O Elenxo de 08-31 chamou
`schedule`/`loop` sobre o evolve read-only de *"resposta proporcional"*. Quem decide é o maestro.

A casa
**cresceu órgãos e perdeu o coração**: cada vez que o evolve ficou caro, nasceu um comando específico
para a parte urgente, e nenhum deles tem o dever de olhar o conjunto.

**A posição de desenho que eu levei ao maestro e ele reforçou** (registrada para não ser re-derivada
do zero, mas o PLANO deve ser fresco): ser homônimo não é ser o maior — é ser o **laço canônico** que
fecha `read(KG) → verificar → agir → write(KG)` sobre o próprio framework. Os cinco específicos são
**órgãos**; o valor que nenhum entrega é o **CONFRONTO** entre o que eles medem separadamente. E o
raio-X é em boa parte **composição de medidores que já existem** (`guard-census`, `forge-census`,
`dissect-census`, `kg-census-extract`, `radar-baselines.yaml`, `kg-radar`) — barato, e o padrão que
funciona aqui é medidor rodando ANTES do raciocínio.

**A lacuna que o foco em "transformer, maquinaria e doutrinas" acerta e ninguém serve:** a casa mede
se **guarda dispara** (26.596 linhas de shell que REPROVAM) e **não mede se doutrina ATERRISSA**
(52.655 de markdown que ACONSELHAM — onde o próprio CLAUDE.md diz que está o fosso).

**E o dogfood tem de ser POR CENSO, não por varredura** — varrer tudo é catedral e custaria milhões
de tokens. O raio-X diz quais artefatos estão vencidos ou não-exercitados; o dogfood roda **só
nesses**.

## Os três candidatos a guarda, cada um com defeito DATADO

Todos de 2026-10-02, todos medidos nesta sessão. A cláusula 1 da `guard-doctrine` exige isso, e a
ordem abaixo é por tamanho crescente de desenho.

1. **Paridade `carimbo role: hub ⟹ registro role: hub`** — a promoção a hub chegou por **sinal do
   adotante**, não por guarda: a **REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela)**
   declara fronteira `kind: door`. ⚠️ **NÃO use o predicado óbvio**: paridade cega em adotante **já
   foi medida como errada** aqui — o refutador rodou o censo e achou **18 comparáveis, 12
   divergentes**, porque em adotante `role:` do registro é **TIER** e do carimbo é **RELAÇÃO**
   (`standalone`+`adopted` é correto), e há caso `(g)` protegendo essa fronteira. O unidirecional
   funciona porque `hub` é o único valor que existe nos dois vocabulários e neles **converge**.
   Hoje acusaria **1 caso real**: `metagamify`, registro `hub` × carimbo `adopted`.
2. **"Dogfood é invocar, não imitar"** — eu descrevi os passos do `/meta:forge-guard` como se os
   seguisse, **sem invocá-lo**, e o maestro me pegou. É verificável no **mesmo substrato** da guarda
   que nasceu ontem (`background-state-needs-evidence`): cruzar a prosa do turno com as chamadas do
   turno, trocando `ps` por `Skill`. ⚠️ E a doutrina **estava carregada no CLAUDE.md** quando eu
   errei — é a prova de que placement em CLAUDE.md não é mecanismo.
3. **"Caso que testa CÓPIA em vez do SUT"** — **quatro ocorrências na mesma sessão**, a classe mais
   caruna: caso que copia o predicado para dentro de si (8/8 verde sobre um fail-open real), e caso
   cujo sandbox nasce de `git archive HEAD` e portanto testa o artefato **commitado** em vez do da
   árvore. É grepável (família que não invoca o SUT pelo caminho do runner), e o próprio
   `lint-selftest.sh` **já avisa disso na l.514**.

## O /meta:study — gatilho, não agora

Defeito **é** datado (duas contaminações medidas: os grafos de pesquisa contaminaram o sandbox do
caso `backlog-projection` que faz `git add -A`, e preservá-los exigiu checkpoint `--no-verify` fora
do gate). Mas **N=1 em necessidade**: não há estudo para abrir. Se um dia forjar, exige **três**
peças, senão vira cemitério não-julgado: caminho **excluído do corpus** (precedente `fixtures/`, que
já exclui 34 de 153 grafos), **promoção explícita** (estudo maduro sai do escopo excluído e passa a
ser cobrado por tudo), e **fronteira declarada** contra o `/onion-research`.
**GATILHO: o próximo estudo que eu precisar abrir.** Nota de passagem: o `/product:collect` **não**
serve — é intake de produto (features/bugs) que alimenta `estimate`/`task`.

## O que a sessão provou sobre mecanismo vs disciplina

A guarda forjada ontem **vetou a resposta do próprio autor no 1º disparo real** — eu escrevi "merge
em curso" sem observar, e ela citou as duas frases ofensoras. Das cinco correções daquele turno,
quatro eram mecânicas e **uma era pergunta do maestro**; agora são cinco mecânicas.

**Mas os erros que mais custaram, nenhuma guarda pegaria**, e isso é o teto honesto do fosso:
- a perna `--framework` **viva** enquanto eu declarava tê-la curado (o comentário afirmava que ela
  entrava no fallback; não entrava, o arg vence);
- o **resíduo adversarial declarando curas que ainda não existiam** — `declarado ≠ verificado`
  cometido **no documento da verificação**;
- `--commit ""` deixando de ser erro e passando a herdar em silêncio: **troquei ruído por silêncio**,
  a pior regressão possível.

Os três caíram por **refutador adversarial, invocação de verdade e releitura** — e um deles só porque
o maestro perguntou por que eu não tinha incluído o `forge-guard` na leitura do censo.

**E uma lição de método que vale mais que os achados:** *"o mutante não mordeu"* tem **DUAS** causas —
o caso é decorativo, **ou** o mutante não muda o que o caso afirma. Confundi-las levaria a "consertar"
um caso que estava certo.

## Re-teste (como falsificar esta migalha)

- `bash .claude/validation/forge-census.sh . --tsv | grep -P '\tevolve\t'` → **use o `--tsv`, não o
  `--markdown`**: foi exatamente a projeção cortada que produziu o número falso acima. Hoje o evolve
  sai em 2/7; se subir, a leva começou (ou o censo mudou de critério — meça qual).
- `bash .claude/validation/guard-census.sh . --markdown` → os 3 candidatos viraram guarda? Procure
  família nova em `lint-selftest.sh`.
- `bash .claude/validation/trust-topology-check.sh --from metagamify --to onion-evolve --action correct`
  e o `role:` dele no `members.yaml` → o 1 achado real do predicado unidirecional ainda existe?
