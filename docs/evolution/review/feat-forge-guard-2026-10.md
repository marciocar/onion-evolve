---
reviewed_diff_sha256: 49a0371511c87339faf2c21fc5aa62e43e697fc47cd02268928c4189f08131f1
findings_total: 11
findings_real: 11
tokens: 142048
duration_min: 10
verdict: REPROVADO_E_CURADO
elenxo: sim
---

# Resíduo da passada adversarial — `feat/forge-guard-2026-10`

Refutador `opus/high` em worktree isolada, **mandato prioritário invertido**: achar o **falso
positivo**, não o defeito. **11 achados, 11 reais, todos provados por execução.** Veredito:
**REPROVADO**. Curados nesta branch, com mutante por cura.

## O achado que invalidava a leva inteira

**A guarda vetava TODO turno honesto em produção** — e a bancada estava verde.

`type: "user"` **não é mensagem humana**: no transcript real os `tool_result` também são rows
`user`. Medido nesta sessão: **1123 de 1327 (85%)**. A janela do turno começava no último
`tool_result`, e no instante do `Stop` não há `tool_use` depois dele → `calls` saía **sempre vazio**
→ a metade "observação" era **código morto** → a guarda vetava **incondicionalmente**.

Medição em produção pelo refutador: **212 vetos em 12.456 pontos de parada reais (1,7%)**, incluindo
turnos em que a sessão estava **ativamente polando o CI**. É a **cláusula 4 da própria doutrina
invertida**: ela errou para o lado de **ACUSAR**.

## A causa estrutural, e é uma lição de bancada

**Nenhum dos 6 casos exercitava o hook como o harness o invoca.** Todos alimentavam `_assess`, uma
função **pura**; o *harvester* — onde viviam **quatro dos cinco** bloqueadores — nunca rodava.
`grep -c transcript` no bloco `--selftest` dava **0**.

É `bancada-espelha-o-runner` violado no caso mais caro possível: a bancada tem de copiar o
**artefato** e o **caminho de geração** do runner, não um atalho conveniente. Os 6 mutantes do
refutador mataram os 6 casos — **nenhum era decorativo** — e ainda assim a guarda era inútil, porque
os casos mediam a metade errada.

**Cura estrutural:** 5 casos novos (`g`–`k`) que rodam o hook **por stdin + transcript**, com fixture
de transcript montado em `mktemp`. Eles teriam pegado F1, F3, F4 e F5.

## Os 11, e o que cada um ensinou

| # | achado | lição |
|---|---|---|
| F1 | janela do turno colapsa (`tool_result` é row `user`) | **bloqueador**; o teto declarado era o errado — ver F6 |
| F2 | a metade "observação" é código morto | consequência de F1: a guarda não implementava o que prometia |
| F3 | `prose = …` **sobrescreve** → só o último bloco de texto é visto | a guarda **não pegava o próprio defeito de origem** (a frase falsa foi 2× no mesmo turno) |
| F4 | a **negação** é acusada | ela vetava **a redação curada** que ela quer que a sessão escreva |
| F5 | `TaskList` no padrão de evidência é código morto | o harvester serializava só `input`, nunca `name` |
| F6 | o TETO declarado era o do **vocabulário** | o teto que importava era **o que a guarda assume da forma do transcript** |
| F7 | `_where` casa por **substring** | o censo declarava REGISTRADO o que não dispara, e o passivo ficava **silencioso** — e a superfície manda "re-rodar o censo para confirmar", **confirmação falsificável** |
| F8 | `--selftest` em **comentário** conta como molde | menção ≠ implementação |
| F9 | erro do Python ≡ ofensa (`exit 1` nos dois) | na **falha** ela acusava, com bullet vazio: contra a cláusula 4. Agora **fail-open** |
| F10 | `--markdown` documentado e **inerte** | flag copiada do irmão sem ser fiada; agora **declarada** como único formato |
| F11 | baseline `14 guardas` já contava a guarda desta leva | o pré-leva era **13** |

## Mutantes — cada cura tem o seu, e nenhum é decorativo

| mutante | caso que morre |
|---|---|
| volta a janela que conta `tool_result` como humano | `(g)`, `(h)` e `(j)` — **três**, o que confirma que era o bloqueador |
| volta o sobrescrever do bloco de texto | `(h)` |
| tira a exoneração por negação | `(i)` |
| tira o `name` da ferramenta do harvester | `(j)` |
| volta o substring no `_where` | `(c2)` — com os dois sinais: declarou registrado **e** calou o passivo |

Bancada final: `run_guard_forge_selftests` **17/0**, hook **11/11** (6 puros + 5 ponta-a-ponta).

## O que o refutador aprovou

- **Nenhum caso decorativo**: os 6 mutantes dele mataram os 6 casos originais.
- **Registro correto**: `settings.json` válido, mesma forma do vizinho, grupo próprio.
- **Cláusula 2 honesta**: o mutante é declarado como julgamento, não escondido como medição.

## nota:
Duas coisas ficaram **NÃO VERIFICADAS** e estão declaradas, não escondidas. (a) A **interação entre os
dois vetos `Stop`** (`rule-title-in-prose.sh` e este) — o refutador não conseguiu medir sem o
runtime, e um veto pode esconder o outro; gatilho: a próxima resposta que viole as duas regras ao
mesmo tempo. (b) O volume de **falso negativo** da nova exoneração: ao isentar negação, pergunta,
citação e relato de defeito fechado, pode-se calar diante de uma afirmação falsa redigida como
negação parcial. A guarda erra para o lado de CALAR **por desenho** (cláusula 4), e o gatilho é o
mesmo de sempre: eu escrever a frase falsa numa forma que ela não vê.

E um registro de método, porque custou: eu tentei aplicar os patches com `python3 - <<'PY'` e o `PY`
**interno** do hook fechou o meu heredoc **externo**. É a classe do heredoc aninhado que nesta mesma
sessão já havia travado um `git commit -F -` por 31 minutos. A cura foi escrever o patch em
**arquivo** com `Write` — e é essa a forma que a superfície agora recomenda.

## O que a INVOCAÇÃO revelou, depois do Elenxo

O refutador mediu os artefatos; **invocar a forja** achou três defeitos que nenhum dos dois pegaria —
e isto é a doutrina de dogfood provada no caso mais limpo possível: **lint verde, bancada verde,
comando inútil**.

1. **A superfície nasceu MORTA NA CARGA.** Eu escrevi a forma literal da diretiva de injeção (bang +
   crase) **dentro da nota que explica a diretiva**, e o harness executa **toda** diretiva do
   arquivo — inclusive a que era exemplo em prosa. A carga morreu com `cmd: command not found`.
   **Regra geral que sai disto:** toda diretiva de injeção num comando tem de ser um **comando
   executável de verdade**; documentar o mecanismo dentro do arquivo que o mecanismo processa
   transforma o exemplo em invocação.
2. **Duas costuras de prosa** que só aparecem lendo o artefato *como a sessão o vê*: um conector
   pendurado (`— e a`) deixado por substituição cirúrgica, e a numeração de peça misturando **dois
   conjuntos de 7** (o da GUARDA, onde 5 = mutante, e o do COMANDO, onde 5 = destino). Citar "peça 5"
   sem dizer de qual conjunto é ambiguidade que viajaria para todo adotante.
3. **A peça 3 era instruída, não injetada** (achado do maestro, antes da invocação): eu construí o
   medidor e deixei **o disparo dele na disciplina da sessão** — `gatilho social é cura nula`
   cometido na superfície que prega o contrário.

Medição da maturidade, pelo instrumento da casa (`forge-census.sh`): **3/7 → 6/7**, com a peça 4
(orquestração) **ausente por desenho e declarada**, porque forja de guarda é serial e não há
independência real para orquestrar. Gatilho nomeado para ela nascer: N moldes a refutar em paralelo.

E o **destino** (peça 5 do conjunto do comando) passou a existir e **se aplica a si mesmo**:
`docs/evolution/research/guard-forge-2026-10/` — 8 nós, 7 arestas, `kg-radar` exit 0. Antes disto o
conhecimento de forjar uma guarda vivia só na mensagem de commit e neste resíduo, isto é, evaporava
entre sessões: a próxima forja releria um molde escolhido **de memória**, que é exatamente o defeito
que a forja nasceu para curar.
