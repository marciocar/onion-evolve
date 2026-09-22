---
reviewed_diff_sha256: "802d13317bd65e0fca3b030d5b00162f15c496d08f767ac2cf6dfdb996778c86"
findings_total: 7
findings_real: 7
tokens: 384000
duration_min: 21
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Passada adversarial (opus/high, mandato REFUTAR, default REPROVADO, isolation worktree) sobre a
  leva que fez o motor de grafo LER os campos bi-temporais. REPROVOU com 7 achados reais, todos
  reproduzidos antes de curar. Refutou dois ataques meus: o modo `--all` (é o default e a invocação
  canônica, não um caminho opcional) e regressão (zero diff fora da seção nova em 800 combinações
  de grafo × modo).
---

# Resíduo — o motor passa a ler o bi-temporal, e a 1ª cura não media 59% do corpus

## O que a passada derrubou

**#1+#2 (o par mais grave).** A única lógica da cura era inalcançável para **59% do corpus**: o gate
exigia `AAAA-MM-DD` dos dois lados, e 65 dos 110 nós não passavam. Pior que não medir: três grafos
reais (`plugin-mcp-posture-2026-09`, `plugin-directory-landscape-2026-09`, `kg-multi-graph-view-2026-09`)
imprimiam **`✅ nenhuma verificação anterior ao fato`** tendo comparado **zero pares**. A seção
VALIDADE, 40 linhas acima no mesmo arquivo, já tinha exatamente o ramo que faltava — `ILEGÍVEL … NÃO
FOI MEDIDA`. Escrevi a guarda sem copiar o molde que estava à vista.

E a bancada que deveria proteger isso não pegava nem a inversão do operador: `(bt1)` grepava
`E_IMPOSSIVEL` na saída INTEIRA, onde o id já aparece 3×. O mutante `<`→`>` fazia o radar acusar o
nó SÃO e o caso passava.

**#3.** `(bt2)` afirmava um literal de formato (`com source_tier`) — texto que o `printf` emite com o
contador ZERADO. Apagar a captura de `source_tier` deixava bt1, bt2 e bt3 verdes.

**#4.** `"e o motor agora LÊ os dois"` saía incondicionalmente, inclusive com `0 com source_tier`:
saída que se autocontradiz, a classe exata que o commit existia para curar.

**#5.** `source_tier` continuava cerimônia — capturado e contado, alimentando nada. 76% da dívida
que o commit dizia pagar seguia sem consumidor.

**#6.** As cláusulas novas não herdaram a detecção de CHAVE REPETIDA que `verified_at` tem 5 linhas
acima, com 6 linhas de comentário explicando por que ela existe. Um `valid_from` duplicado vencia em
silêncio — e agora alimenta um VEREDITO.

**#7.** Os números embutidos estavam errados. Eu declarei *"465 ocorrências, 12 grafos, 349 de
source_tier"*; o real, medido com âncora de campo, é **110 em 9 grafos + 343 = 453**. Meu `grep` não
tinha âncora e contava prosa, label e trace citando o nome do campo. Dos 3 grafos "a mais", um era a
**fixture do meu próprio selftest**.

## O que a cura fez, e o que ela mudou de rumo

A correção óbvia do #1 seria declarar os 65 nós como não-medidos. **Medi antes, e a medição mudou a
cura:** há **zero lixo** ali. Os 65 são ISO-8601 de precisão reduzida — `2026`, `2026-09` — que é
dado legítimo: uma fonte que datou o fato pelo ano não tem dia para dar. Declarar isso "ilegível"
seria inventar um defeito onde há informação comparável.

Como ISO-8601 ordena lexicograficamente, truncar o mais preciso ao tamanho do mais grosso compara
certo. **O corpus foi de 45 para 110 nós medidos — 100%**, e o que sobra de fato ilegível é
DECLARADO, no molde da VALIDADE.

| # | cura |
|---|---|
| 1 | compara na granularidade do dado + ramo `ILEGÍVEL` declarado; ✅ nunca sai sobre zero comparação |
| 2 | `(bt1)` extrai a LINHA da acusação e exige que nomeie o nó certo **e não** o são |
| 3 | `(bt2)` afirma as CONTAGENS (2/2/2), nunca o literal |
| 4 | a linha de cobertura diz `N com valid_from (M comparável(is)) · K com source_tier` — sem adjetivo sobre si |
| 5 | `source_tier` fora da escala 1–10 é acusado, nomeando o nó — o campo virou load-bearing |
| 6 | `dupKey` nas duas cláusulas novas, com o comentário dizendo por que agora é pior |
| 7 | números re-medidos com âncora, e o erro anterior fica REGISTRADO no comentário como a classe que ele é |

## Prova (mutantes)

Quatro mutantes, todos mortos — inclusive os dois que a versão anterior deixava passar:

| mutante | quem pega |
|---|---|
| inverte o operador de ordem (`<`→`>`) | bt1 + bt4 |
| apaga a captura de `source_tier` | bt2 + bt5 |
| volta o gate rígido `AAAA-MM-DD` | bt4 |
| reimprime o ✅ incondicional (o defeito original) | bt6 |

Regressão: **800 combinações** (grafo × 8 modos) contra a versão em `HEAD` — **0 rc divergentes, 0
saídas divergentes fora da seção nova**.

## Duas lições que não são sobre este commit

**A medição que eu publiquei era a do meu harness, não a do motor.** O 1º teste de regressão acusou
`rc 2→0` em TODOS os grafos. Não era o motor: era o radar copiado solto para o scratchpad, sem a lib
irmã, batendo na própria guarda fail-closed — a classe `fail-closed-exposes-incomplete-harness`, que
já me custou 3 casos numa rodada anterior. A cura foi no harness (worktree destacada em `HEAD`),
nunca afrouxar a guarda.

**O #7 é a ironia do commit.** A leva existe para punir campo declarado que ninguém mede, e embutiu
em três artefatos um número que eu não tinha medido. `grep` sem âncora conta prosa. É a terceira vez
nesta sessão que fabrico uma MEDIÇÃO DE REPO — parei de fabricar citações e passei a fabricar
números, e só a passada adversarial pega.

## Catraca da porta

`onion-standalone` 400→402: a `main` andou 2 commits na superfície que viaja e aquela porta segue
parada desde 2026-07-19. Passivo REAL — a catraca medindo trabalho mergeado que a porta não recebeu,
não afrouxamento. `onion-core` segue em ZERO. Só cai por re-materialização, que exige o push do
maestro.

## Depois da revisão — o que os dois commits seguintes acrescentaram

O CI reprovou o 1º commit com 3 HARD que o lint local dava por verdes. **Raiz única:** gerei as
projeções (`graph.md`, `testing-state.md`) numa árvore que carregava edições NÃO-COMMITADAS de
outra frente. O grafo leu um pin de `members.yaml` que só existia no meu disco; o painel leu um
resíduo cuja versão em árvore apaga 10 achados do ledger. **Medir no caminho que eu uso quando o CI
usa outro é não ter medido** — projeção se gera de worktree destacada no commit.

O `onion-core ANDOU-PARA-TRAS 2 > 0` tinha outra causa e foi curado com verificação: a 15ª
materialização estava publicada, só o avanço de pin não fora commitado. Conferido no remoto
(`git ls-remote` → HEAD `28baded9aa5c`), não pela nota que eu mesmo escrevera.

**Erro meu no meio disto, destrutivo:** silenciei o stderr de um `git worktree add` que falhou, e o
`cp` seguinte copiou um arquivo temporário obsoleto por cima do `graph.md` — 805 linhas apagadas.
Restaurado de `HEAD` no mesmo movimento. A guarda anti-fail-open do shell existe exatamente para
isto, e eu a contornei ao redirecionar para `/dev/null`.

**Fica aberto e é do maestro:** `docs/evolution/review/feat-reviewer-findings-block.md` tem na árvore
uma versão estritamente MAIS VELHA sobrescrevendo a commitada. Não descartei — provei que aquele
blob não está em nenhum commit da história, então `git checkout --` perderia conteúdo. Cópia
preservada no scratchpad.
