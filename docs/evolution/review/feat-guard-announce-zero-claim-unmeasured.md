---
title: 'Resíduo — a guarda não pegava o dano que a motivou, e só a calibração contou'
date: 2026-10-01
branch: feat/guard-announce-zero-claim-unmeasured
reviewed_diff_sha256: 5962af26feb48055f4db98b733d3f2c62ae80889db2b26078c9469dbf1bfbcb4
findings_total: 13
findings_real: 13
findings_fixed: 13
tokens: 95000
duration_min: 35
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Cinco achados, e o central é que a 1ª versão da guarda passou VERDE no próprio incidente que a
  motivou — porque casava linha a linha e o wrap do markdown parte a afirmação em duas. Sem Elenxo
  formal porque o refutador aqui foi a CALIBRAÇÃO contra o dano real, que é mais forte que um
  worker adversarial: ela reprovou por execução, não por argumento.

# A calibração reprovou a guarda antes de qualquer revisor

## 1. A guarda passava verde no dano que existia para pegar

Escrevi `announce-zero-claim-check.sh` casando **linha a linha** ZERO + CLASSE. Rodei contra o
anúncio real de 2026-08-31 e deu **rc=0**: a guarda aprovava o incidente.

A causa é prosaica e por isso perigosa: markdown **quebra linha**. A afirmação está partida —
`As portas` fecha uma linha, `estão OK (nenhuma sem prefixo de bind)` abre a seguinte. ZERO e
CLASSE nunca caem juntos. A unidade correta é a **FRASE**, com o parágrafo juntando o wrap.

**Foi a calibração, não o raciocínio, que achou isto** — e é a diferença entre guarda e teatro. O
mutante `M1` restaura o defeito e o caso `(a)` o mata, para ninguém "simplificar" de volta.

## 2. Metade do nó já estava curada, e eu ia escrever prosa de novo

O nó pedia três coisas; a **primeira já estava no `co-announce.md`** desde 2026-09-16. Se eu não
tivesse lido o artefato antes de agir, teria reescrito doutrina existente e deixado o mecanismo
faltando — que é exatamente o que mantinha o nó aberto. Padrão `fix-must-become-mechanism`:
instrução existe, nada a cobra.

## 3. Só o ZERO é cobrável, e o teto tem de ser declarado

O mesmo anúncio errou um **não-zero**: disse `3 fallbacks` onde o padrão produzia **19 em 10
variáveis** — quem aplicasse "o fix de 3 linhas" curaria **16% da classe** achando ter curado a
classe. Esse caso é **indetectável por grep**, que não sabe a contagem verdadeira do alvo.

A assimetria que sobra é a que paga: um não-zero errado ainda **provoca** ação (o leitor vai olhar);
um zero **desliga** a ação inteira. A guarda cobra o zero e **declara** que não cobre o resto —
guarda que promete o que não mede ensina a ignorar o vermelho.

## 4. O número certo em OUTRO parágrafo não cala — e é literalmente o incidente

No anúncio real, o `38` estava **doze linhas acima**, no mesmo documento, e o leitor **ainda**
concluiu que não havia o que fazer. Daí a proveniência valer só no **parágrafo da afirmação**. O
caso `(e)` sela isso; minha primeira expectativa de teste estava errada, não a guarda.

## 5. Escopo prospectivo, porque passivo sem cura é o modo-de-falha travante

Medido: **0 anúncios em 1º nível** hoje — os 128 rastreados estão em `_processed/`/`_archive/`, já
viajaram, e história não se reescreve. Julgar só o 1º nível faz a guarda nascer `SEM-OBJETO` e
morder o **próximo** anúncio, onde a cura existe. `SEM-OBJETO` é **declaração**, não conformidade: a
guarda fala que não julgou, em vez de passar calada.

### Defeitos de processo meus nesta passada, pelo registro

- Branch nomeada em **pt-BR** (`...-sem-medicao`) — a guarda de shell pegou enquanto era grátis.
- Dois erros de fatiamento em `python3` ao editar o lint (`blk` sem o `]`, heredoc aninhado) — nada
  foi escrito nos dois casos, porque as asserções vêm antes da escrita. Foi o desenho que salvou,
  não o cuidado.

## 6. Editei à mão a projeção GERADA, num PR sobre não afirmar em prosa o que se mede

A **REGRA 39 (Registro de REGRAS derivado e em paridade com as guardas)** reprovou o commit: eu
acrescentei a linha da REGRA 95 em `lint-rules.md` **digitando**, quando aquele arquivo é projeção
de `rules-registry.sh`. Regenerado da fonte.

A ironia é o conteúdo deste próprio PR. A REGRA 95 existe para impedir que um artefato **afirme em
prosa** o que outro **mede** — e eu cometi a mesma classe no arquivo ao lado, no mesmo commit.
Reforça o que a casa já sabe e eu re-aprendi hoje pela quarta vez: **regenerar é o último passo, e
projeção gerada nunca se edita** — o gate é que sabe disso, não eu.

## 7. A CURA que o maestro mandou fazer: a classe virou tabela, não lição

O maestro leu *"é a quarta vez nesta sessão que ordem ou derivação me cobram… eu não internalizei"* e
devolveu a pergunta certa: **se a lição se repete, não é caso de resolver o problema?** É, e a régua é
da casa — `fix-must-become-mechanism`.

O que existia: **um bloco** no pre-commit regenerando **uma** projeção (o painel), escrito porque
aquela regra barrou 3× num dia. O docstring dele já dizia que *"a cura de disciplina (lembrar de
regenerar) é cura nula nesta casa"* — e eu passei a sessão lembrando à mão das outras cinco.

O que existe agora: **tabela de 6 projeções** (REGRAS 16, 39, 62, 80, 81, 84), no motor
`onion-regen-lib.sh`, sourçado pelo hook. Cobrir projeção nova = **acrescentar uma linha**.

Duas propriedades que não são detalhe: roda **antes** do carimbo da REGRA 56 (auto-fix depois tornaria
o hash caduco — defeito medido 2× hoje), e **gerador que falha não trunca o alvo** (`temp+mv` com o rc
lido **e** `[ -s ]`, porque projeção que **desaparece** é pior que defasada). A bancada
`hook_regen_table` mata um mutante de cada metade.

## 8-11. E a captura que eu rodei para caçar o flaky achou QUATRO defeitos meus

Rodei a **invocação exata do hook** (`--affected-staged --jobs auto`) fora de um commit, para capturar
o dado que o nó `Q_KG_BACKLOG_E_CONTADOR…` pede. **O flaky não reproduziu** — 1605 asserções passaram.
Isso é achado: **o ambiente do `git commit` é a variável**, e a caça estreita de "algo na faixa
paralela" para "o que o commit muda".

Mas a passada achou quatro defeitos que nenhuma rodada anterior pegou, **todos meus**:

| # | Guarda | Achado |
|---|---|---|
| 8 | `idioma` | identificadores `alvo`/`regra` — **REGRA 60 (Identificador de código em INGLÊS)** |
| 9 | `selftest-lanes (0)` | **âncora morta**: a bancada recortava o motor por `sed` de um símbolo que só existia no **hook** |
| 10 | `shell-pipefail` | sítio **novo** de `<produtor> \| grep -q` acima da catraca |
| 11 | — | o aninhamento de aspas da minha própria correção quebrou o sandbox |

O **#9** é o mais instrutivo e mudou o desenho: a guarda não disse *"renomeie"* — revelou que eu
pusera o motor **no lugar errado**. A cura dela é melhor engenharia: o motor saiu do hook para a lib,
o hook ficou fino, e a bancada passou a **sourçar o artefato real** em vez de uma cópia recortada.
Guarda que te obriga a mover código para onde ele é testável é guarda de **arquitetura**, não de
estilo.

O **#11** é a lição de método: eu "conferi" a linha gerada com `cat -A`, **li** e dei por boa. Só
reproduzindo o sandbox à mão o `command not found` apareceu. **Ler não é medir** — e isso aconteceu
na correção de um defeito cuja lição era exatamente essa.

### A lacuna de plataforma que o maestro nomeou, e que estes quatro confirmam

Os quatro só apareceram quando rodei **a condição real** (a invocação do consumidor), não a
conveniente. São todos da camada *"a maquinaria roda, ou nunca é acionada?"* — a terceira de três, e a
única sem mecanismo:

| Camada | Pergunta | Estado |
|---|---|---|
| 1. exercitada | a guarda tem bancada? | ✅ `--map` responde (380 famílias, 14 sem arquivo derivado) |
| 2. achou algo real | a regra já pegou passivo? | ⚠️ 13 baselines provam 13 regras |
| 3. **disparou em uso** | a maquinaria é acionada? | ❌ **falta** — mas o padrão existe em 2 hooks (`instructions-loaded.jsonl`, `model-switch.jsonl`) |

Proposta de plano, **para o maestro selar na colheita** (não cabe nó novo: o backlog está no teto):
**(0)** rodar a maquinaria na condição real — custo zero, rendeu 4 defeitos hoje; **(1)** livro de
execução por heartbeat, generalizando o padrão dos 2 hooks; **(2)** falha que carrega o próprio dado
(gatilho disparado 3× hoje); **(3)** comando/fluxo nunca invocado — **gated**, tem cheiro de catedral.

## 12-13. Os dois sítios de shell, e um deles mostrou que a cura óbvia era cargo-cult

O maestro perguntou se os violations de shell estavam arrumados. Nos artefatos: **sim** (as três
classes em zero nos 7 scripts). Mas a auditoria achou **dois sítios reais**, e o primeiro ensina:

**12. `onion-regen-lib.sh` sem `pipefail` — e adicionar seria ERRADO.** A lib é **sourçada** pelo
hook, e `set` num arquivo sourçado **vaza para o shell do chamador**: endureceria o hook no meio da
execução, por efeito colateral. A cura certa foi outra — **razão declarada** no docstring e cada
função robusta **independente** das opções do chamador.

E aí apareceu o defeito que o `pipefail` ausente estava escondendo: `onion_staged` era
`git diff … 2>/dev/null | head -1`, **duas classes numa linha** — `| head -1` é fechador precoce (o
`git` leva EPIPE e o veredito **inverte com o caminho presente**), e o `2>/dev/null` faz
git-que-falhou e nada-staged devolverem o **mesmo vazio**. Reescrito sem pipe: captura, **lê o rc**,
corta a 1ª linha por expansão de parâmetro. Provado sob `pipefail` (`1a=[a.txt]`, `rc=0`).

**13. `.githooks/pre-commit` tinha um `git diff | grep -q` PRÉ-EXISTENTE** (gatilho do
`kg-freshness`). Curado reusando o `onion_staged` já corrigido — a lib nova pagou dívida antiga.

### A cura da tabela provou-se em produção no PRÓPRIO commit desta leva

O gate imprimiu `🔁 docs/onion/testing-inventory.md regenerado (REGRA 80)`. A projeção que eu teria
esquecido foi regenerada **pela máquina**, no primeiro uso real. É a diferença entre a lição e o
mecanismo, medida no mesmo dia em que a lição falhou quatro vezes.

## O que esta passada NÃO fez, e por quê

**Nenhum nó foi escrito no grafo.** O backlog está **no teto** (19 nós, `TETO: 19` — *"onda nova
exige onda COLHIDA"*), e isso inclui a evidência que o nó `Q_KG_BACKLOG_E_CONTADOR…` pede. A
colheita é do maestro; o detalhe e o candidato estão no `STATE.md` desta passada.
