---
title: 'Sinal de campo — arandek: plane×verified_against incoerente passa no radar, Elenxo evaporou pela 4ª vez, e falso-verde por caminho de erro (6 ocorrências)'
date: 2026-07-27
from: arandek (consumidor)
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core / sinal)
source_commit: 5e3ea5ee46ac
kg: docs/onion/graph/promocao-main-elenxo.kg.yaml
contexto: >-
  Sessão de vários dias: movimento Elenxo sobre a tese de promover uma PR, seguido da
  obtenção de acesso de leitura a produção (AWS) e da reverificação de todos os nós
  plane:PROD dos grafos do adotante. 1 lacuna concreta no radar (com conserto proposto),
  1 reincidência do modo de falha dominante do Elenxo, 1 padrão candidato a doutrina.
---

# Sinal de campo — arandek, o dia em que produção virou legível

O trabalho: um movimento Elenxo de 4 lentes sobre a tese *"a PR #183 pode sair do rascunho?"*,
seguido de algo que mudou o enquadramento — **acesso de leitura ao artefato vivo**. Com ele, reverifiquei
todos os nós `plane: PROD` dos grafos deste adotante. O que segue é o que isso ensinou sobre **o
Onion**, não sobre o Arandek.

---

## L1 — `plane: PROD` com `verified_against: branch` passa no radar (lacuna com conserto proposto)

**O item mais acionável deste sinal, e o mais barato de consertar.**

Na doutrina SDAAL, `plane: PROD` significa **artefato vivo** (deploy + config + dados) e `plane: DEV`
significa **fonte/branch**. O campo `verified_against:` nomeia o alvo móvel rastreado
(`branch|commit|deploy|config|dump:`). São dois campos que falam da **mesma coisa** — a natureza da
evidência — e o radar não os confronta.

Consequência medida neste adotante, com o radar **verde** o tempo todo:

| grafo | nós `plane: PROD` | com `verified_against: deploy` |
|---|---|---|
| `promocao-main-elenxo` | 19 | **8** |
| `runtime-race-ci-blindness` | 14 | **4** |

**21 nós afirmavam sobre produção com evidência que era leitura de código (`branch`/`commit`) ou
medição na máquina local (`config`).** Eu escrevi todos eles, e nenhum gate reclamou.

### Por que o FRESCOR atual não pega

O `--freshness` do core (que já evoluiu desde o pin deste adotante) cobra:

- **STALE-MISSING** — nó rastreado sem `verified_at:`
- **STALE-OLD** — `verified_at` anterior à `meta.baseline`
- **UNANCHORED** — `node_type: claim` com `verified_at:` mas **sem** `verified_against:`

Os três olham se o carimbo **existe** ou se **envelheceu**. Nenhum olha se ele veio do **lugar certo**.
E o UNANCHORED isenta explicitamente os tipos não-`claim` — *"os demais tipos ancoram por
`trace:`/`TRACES_TO`"* —, que é exatamente onde os meus 21 casos estavam: quase todos `evidence`.

Isto é o **falso-verde por escopo de detecção** que sinalizei em 2026-07-25, reaparecendo num gate
diferente: o gate está correto, roda, e mede uma propriedade adjacente à que importa.

### Conserto proposto (uma checagem, sem campo novo)

Uma linha de coerência no FRESCOR, para **todos** os tipos de nó:

```
plane: PROD  +  verified_against ∈ {branch, commit}   → ⚠ MISPLANED
```

O nó diz que cruzou com o vivo e declara ter olhado a fonte. É contradição **interna ao próprio nó** —
detectável sem rede, sem contexto e sem heurística. Sugiro `⚠ atenção`, não gate: reclassificar é
juízo (o meu resolveu-se mandando os 21 para `plane: DEV`), e um nó mal-carimbado **mente, não
corrompe** — mesmo racional do STALE.

O inverso (`plane: DEV` + `verified_against: deploy`) é mais raro e provavelmente legítimo (medir o
vivo para concluir sobre a fonte); não sugiro cobrar.

**Implementei a versão externa disto como
`scripts/kg/verify-prod-claims.sh` (no repo do adotante — não vendorizado, ver nota de soberania abaixo)** neste adotante —
auditoria offline + sondas opt-in contra AWS. Fica como referência de comportamento, **não como código
a vendorizar**: soberania, o motor é de cada instância. O que viaja é schema + método.

**Limitação que o próprio script declara:** ele audita a procedência **declarada**, não se a declaração
é verdadeira. Um nó meu declarava `deploy` sendo bench local e passou — precisou de olho humano. A
checagem proposta tem o mesmo teto, e é honesto dizer isso antes de graduá-la.

---

## L2 — Elenxo evaporou pela QUARTA vez, e desta vez com a guarda ligada

O modo de falha dominante do Elenxo está documentado três vezes no core (2026-07-18, 2026-07-20,
2026-07-23): **não é o método, é a evaporação do resultado**. Este movimento nasceu com o `.kg.yaml`
criado **antes** do fan-out, com os 4 claims já abertos, e o cabeçalho do arquivo citava os três
incidentes por extenso.

**Evaporou assim mesmo.** A quarta lente (a que atacava *"nada mais quebrou nos 54 commits"*) rodou,
devolveu, e a saída nunca foi escrita no grafo — sumiu na compactação de contexto e não é recuperável
do transcript. O claim correspondente segue `open`: não pode ser confirmado nem refutado, e a tese foi
a decisão com um quarto do ataque perdido. Registrado como `E_L4_EVAPOROU`, em vez de apagado ou
reconstruído de memória.

**A lição não é "tente de novo com mais disciplina".** É estrutural:

> **Nascer antes garante o LUGAR da escrita, não a escrita.**

O `kg-born-marker.sh` já é honesto ao declarar que não detecta investigação nascida fora do grafo. O
que este incidente acrescenta é que **nem o nascimento correto protege** — entre a saída da lente e o
`write(KG)` existe uma janela, e é nela que o resultado morre. Enquanto o write for ato do modelo no
fim do movimento, ele compete com a compactação e com o cansaço do contexto.

Direção que me parece valer (não implementada, é sinal e não proposta fechada): **escrever por lente,
não por movimento** — cada lente materializa o próprio nó ao voltar, e o consolidador lê o grafo em vez
de ler as saídas. Aí a evaporação de uma lente custa uma lente, não a rodada.

---

## L3 — Falso-verde por CAMINHO DE ERRO (padrão candidato, 6 ocorrências na mesma semana)

O core já tem três famílias de falso-verde documentadas: por **bug**, por **vacuidade** (`0 == 0`), e
por **escopo de detecção** (meu sinal de 2026-07-25). Esta é uma quarta, e foi a que mais me custou
tempo: **o caminho de erro produz verde ou zero em vez de falhar alto.**

Seis ocorrências, todas minhas, todas nesta semana:

1. `services-stable` no CI comparando `0 == 0` — "estável" porque não havia nada rodando.
2. Uma asserção passava em 0 ms com o endpoint em 404, 500 ou sem o registro: `undefined?.status !==
   'paused'` é vacuamente verdadeiro.
3. `filter-log-events … 2>/dev/null || echo 0` — `AccessDeniedException` virou "0 ocorrências". **Eu
   reportei isso ao maestro e escrevi no grafo como evidência confirmada.** Precisou de retratação.
4. O **denominador** que acrescentei para consertar (3) não me salvou: vinha da **mesma chamada** que
   falhava.
5. `pass insert` com stdin vazio criou entrada de **0 caracteres** — `pass show` tem sucesso, então
   todo teste de existência passa.
6. Os 21 carimbos `plane: PROD` da L1 — presença de campo passando por procedência.

### O que destila, e por que acho que é doutrina e não dica

**(a) Guarda que compartilha o caminho de falha do que ela guarda não é guarda.** É o caso (4), e é o
mais instrutivo: eu tinha endurecido a *leitura* do número, não a *origem* dele. Vale para todo gate
que se apoia numa chamada que pode falhar do mesmo jeito que a coisa medida.

**(b) Zero sem denominador não é evidência de ausência.** Ao ver um zero, a primeira pergunta é
*quanto havia para medir*. Se a resposta for "não sei", o zero não vale nada.

**(c) Silêncio não é aprovação.** Verificador que não sabe checar algo diz `⚠ SEM PROBE`, nunca verde.

**Onde isto encosta no core:** o `kg-radar.sh` já pratica (c) — *"o radar tem que saber que NÃO
SABE"*. O que não vi com casa é (a), que é a regra que teria pego 4 das 6. E o que expôs o caso (3)
não foi mais rigor: foi uma **contradição visível** — log group com 10,8 MB e evento de 30 minutos
atrás reportando "0 linhas em 7 dias". Vale registrar que o que quebra falso-verde é confronto entre
duas medições independentes, não revisão mais atenta da mesma.

---

## L4 — Validação: o radar-de-domínio cobra a ARESTA, e está certo

Criei a primeira camada `layer: domain` deste adotante (31 nós). O `--domain` cobrou 10 coisas e
acertou nas três classes. A que mais ensinou: **RULE-sem-trace cobra a aresta `TRACES_TO`, não o campo
`trace:`**. Achei rigor excessivo até entender — campo é migalha para humano, aresta é o que a máquina
percorre. Sem ela, uma regra podia citar arquivo inexistente e o grafo não notaria.

Também vale como validação: os quatro estados absorventes que ele apontou eram terminais legítimos, e
a resposta virou um nó `decision` no grafo em vez de aviso solto. A instrução *"lacuna vira decisão
explícita"* funciona na prática — sem ela o aviso vira ruído que se aprende a ignorar.

---

## Resumo para triagem

| # | tipo | ação sugerida |
|---|---|---|
| **L1** | lacuna com conserto proposto | checagem `plane` × `verified_against` no FRESCOR, `⚠` para todos os tipos de nó |
| **L2** | reincidência de doutrina (4ª) | avaliar write-por-lente; a janela entre saída e `write(KG)` é onde o Elenxo morre |
| **L3** | padrão candidato | 4ª família de falso-verde: por caminho de erro. A regra (a) é a que não tem casa |
| **L4** | validação | radar-de-domínio confirmado em campo; nenhuma ação |

Nada aqui pede código do adotante no core. L1 vem com conserto proposto **e com o teto dele
declarado**; L2 e L3 são sinal, não proposta fechada.
