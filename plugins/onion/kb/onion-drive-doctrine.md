# Doutrina do `/onion:drive` — conduzir um plano-grafo até o fim, com rigor Onion

> **O que este doc é.** O **contrato canônico** do driver de plano: o laço, o roteamento do passo
> AVANÇAR por KIND de nó, a **tabela de selagem** (onde o driver auto-avança e onde PARA), as 6 regras
> de doutrina que ele encarna, e os anti-padrões. A **Fase 0** (o Censo determinístico) já existe como
> mecanismo: `${CLAUDE_PLUGIN_ROOT}/validation/kg-drive-project.sh`. A **Fase 1** (o laço em si, `/onion:drive`) é
> construída sobre este contrato. **Fase 2** (o degrau AUTOMATE) é gated.
>
> **Por que existe.** O reforço-prosa do maestro (*"siga com execução até o final… nada parado sem
> controle"*) é **disciplina, não mecanismo**. O `/onion:realign` já mecanizou o *alinhamento*; este
> mecaniza a *condução*. O precedente é o ADR `autonomous-thread-runtime` (a escada + o loop), que era
> **prosa gated** — a 1ª passada do `/onion:drive` é o dogfood que o **sela** (proposed→accepted).

## 0. A escada de autonomia (do ADR `onion-adr-autonomous-thread-runtime-2026-07.md`)

O driver opera num **degrau declarado**, nunca acima:
- **Nível 0** (auto sempre): atos reversíveis em worktree própria (branch/commit/PR/dogfood), `write(KG)` de append, **propor** ato-3.
- **AUDIT** (o degrau da Fase 1): conduz um fio **até PR-verde sozinho**; **merge no main é 100% humano, em LOTE** num checkpoint.
- **AUTOMATE** (Fase 2, gated): auto-merge só sob 3 pré-condições duras (enabler git-nativo · path-allowlist `git diff ∩ vendor = ∅` · política 100% mecânica, LLM veto-only).
- **MOAT** (nunca): deploy · escrever repo alheio (I3) · merge de path vendorizado/outward-facing · **agendar por relógio (W7)**. O driver é **maestro-invocado**, nunca cron/`/loop` sobre si.

Alinhamento SOTA 2026: GAIE (arXiv 2606.22484) = os mesmos 3 tiers; Loop Engineering = *stopping-conditions + verificador determinístico SEPARADO checando o objetivo a cada turno, nunca o auto-relato* (= `kg-realign --check` / `kg-radar`, `declarado≠verificado`).

## 1. O Censo — `kg-drive-project.sh` (Fase 0, determinístico, PRONTO)

Projeta a **FILA-PRONTA** de um plano-grafo: nós `status: open` cujos predecessores `DEPENDS_ON` já
**fecharam** (não estão mais no conjunto de abertos), por **atenção** (a régua do radar), anotados com
`drive_kind`. Consome `kg-radar --open-tsv` + `--triples` (não reparseia YAML). Vereditos:
- **DONE** — 0 abertos (plano sem trabalho).
- **READY** — há fila-pronta.
- **DEADLOCK** — há aberto(s) mas fila-pronta VAZIA (predecessor travado/ciclo/onda mal-modelada); `--check` sai **exit 1**.

`DEPENDS_ON` aqui é **GUARDA** ("não faça B antes de A"), **não ordenação** — a topológica dirigida é
Fase 2 (transformar atenção em precedência é *"o defeito fundador da REGRA 49 cometido na autoria"*,
aviso do `fios-abertos`). Ordena por atenção; a guarda só segura o bloqueado.

## 2. O laço (Fase 1 — nível-principal, budget-capped, retomável)

```
P0   LEGIBILIDADE     kg-radar --integrity --schema → exit≠0 PARA
P0.5 CHECKPOINT PEND. lote não-selado no STATE.md? → PARA (guarda 1-passada/checkpoint)
P1   CENSO            kg-drive-project.sh → FILA-PRONTA + BLOQUEADOS
P2   SELECIONAR LOTE  top --max-nodes (guardas max-nós/passada + budget)
P3   POR NÓ           classificar drive_kind · session-beacon check (I3) · AVANÇAR (§3) ·
                      ELENXO se peso doutrinário · veredito-de-escrita (§4) · abort-on-anomaly
P4   FECHAR O LOOP    dogfood RODOU o artefato + modo-de-falha? fix→re-dogfood no MESMO loop
P5   CHECKPOINT LOTE  STATE.md: PRs p/ merge humano · DRIFTED/REFUTED p/ selo · kg-radar exit 0 ·
                      kg-realign --check (drift residual)
P6   PARA             nenhuma passada nova enquanto o checkpoint pende (batch-confirm AUDIT)
```

## 3. Roteamento de AVANÇAR, por `drive_kind` (default inferido do `node_type`; campo `drive_kind:` sobrepõe)

| KIND | node_type | "avançar" = | delega a (REUSADO) | produz |
|---|---|---|---|---|
| **research** | `question` | colher evidência vs o vivo/externo | `onion-orchestration` fan-out + Web* + `write(KG)` | `evidence` + `SUPPORTS`/`REFUTES` |
| **verification** | `claim` | MEDIR o nó contra o vivo | `/onion:kg-freshness --node <id>` (mede, propõe) | veredito + `proposed_write` |
| **execution** | `decision` (reversível) | trabalho em worktree até **PR-verde** + dogfood | orquestração de execução (molde de fases do `/onion-engineering:work`, até 1 PR) | branch/PR + evidência |
| **decision** | `decision` (não-tomada) | enquadrar + Elenxo, **propor** a chamada | `adversarial-verification` | `decision` PROPOSTO (não selado) |

## 4. Tabela de SELAGEM (postura AUDIT — mata o carimbo-automático)

| Evento | Ação | AUTO vs PARA |
|---|---|---|
| research → `evidence` (append) | `write(KG)` | **AUTO** |
| verification **CONFIRMED** (mediu de fato) | carimba `verified_at` | **AUTO** (só porque houve medição executada) |
| verification **DRIFTED** | apenda nó-medido + `SUPERSEDES`; alvo fica `confirmed` (radar exit 0) | **AUTO escreve / PARA o humano flipar** alvo→superseded (salvo §4.1, que vale para `SUPERSEDES` tanto quanto para `REFUTES`) |
| verification **REFUTED** | propõe nó + `REFUTES` + flip atômico | **PARA** (apendar solto quebra `--integrity`; peso alto) |
| **REFUTED/SUPERSEDED de nó NUNCA SELADO** (§4.1) | mesmo ato, mas o par nasce e cai no MESMO PR | **AUTO nas 3 precondições mecanizáveis** (`kg-seal-exception.sh`); a 4ª — declarar no `STATE.md` — é humana |
| verification **UNVERIFIABLE** | `blocked_by`, **não carimba** | **AUTO** (não-escrita; 1ª classe) |
| execution → PR-verde | conduz em worktree | **AUTO até o PR** |
| **merge no main** | — | **PARA** (100% humano, em lote) |
| **decisão não-tomada** | frame + Elenxo + propõe | **PARA** (selo humano) |
| drift tipo-(c) estrutural | novo nó + `SUPERSEDES` datado | **AUTO** (realign repara determinístico) |
| **MOAT** | — | **NUNCA / PARA** |

**Invariante que amarra:** *o único caminho para um `verified_at` novo passa por uma medição executada*
(contrato do `/onion:kg-freshness`). O driver **apenda** evidência; quem **flipa** o status de verdade
(→`superseded`/→`refuted`) é o humano no checkpoint. O radar/realign viram o forcing-function do selo.

### 4.1 A exceção nomeada — **auto-refutação de nó NUNCA SELADO**

> *O selo existe para que uma verdade que o humano já aceitou não mude sem ele. Um nó que nunca chegou
> ao humano nunca foi aceito — logo não há selo para preservar.*

**Antes da exceção, o caminho preferido.** Se o nó nasceu no PR, ainda é **rascunho do driver**, e
rascunho errado normalmente se **corrige**: edite o nó. A Aufhebung preserva posição que a **casa**
sustentou, não erro de vinte minutos do próprio driver. A exceção é para o caso em que a refutação
**carrega conhecimento que vale guardar** — o método que derrubou a hipótese, e que a próxima sessão
usaria para não repetir o mesmo erro — ou em que a reconciliação já está escrita e desfazê-la custaria
mais do que registrá-la.

**Regra.** Escolhida a Aufhebung, o driver PODE flipar `→refuted`/`→superseded` sem parar quando as
**quatro** precondições valem juntas:

1. **NUNCA SELADO** — o `id:` do alvo não existe em **nenhum** `*.kg.yaml` da base (`origin/main`)
   nem na história dela. O par *nó + refutação* chega ao maestro como **uma proposta só**.
2. **MEDIÇÃO EXECUTADA** — a refutação vem de execução (sandbox determinístico, comando com saída
   capturada), nunca de raciocínio novo sobre o mesmo fato.
3. **AUFHEBUNG COMPLETA** — nó `evidence` novo + aresta `REFUTES`/`SUPERSEDES` + alvo reconciliado,
   com `kg-radar --integrity --schema` **exit 0**. A posição derrubada **fica** no grafo.
4. **DECLARADA NO CHECKPOINT** — o `STATE.md` do lote **nomeia** o flip como auto-selado por esta
   exceção. Flip silencioso não é exceção, é o carimbo-automático que o anti-padrão 1 do §6 proíbe.

**O que é mecânico e o que não é — sem arredondar para cima.** O predicado
[`kg-seal-exception.sh`](${CLAUDE_PLUGIN_ROOT}/validation/kg-seal-exception.sh) decide `AUTO`/`PARA` e sai
`1` em toda dúvida (fail-closed). Mas ele **não cobre as quatro**:

| precondição | quem decide | teto |
|---|---|---|
| (1) nunca selado | **o predicado** | lê YAML de verdade, varre TODOS os grafos da base (árvore + história), recusa repo raso e base defasada |
| (2) medição executada | **parcial** | prova que `verified_at`/`verified_against` **existem e não são placeholder**; nenhum script sabe se o texto descreve algo que rodou |
| (3) Aufhebung + integridade | **o predicado** | aresta e status lidos por YAML (não por texto), mais o radar |
| (4) declarada no checkpoint | **o humano** | **não mecanizada e não mecanizável aqui** — `exit 0` NUNCA significa que a (4) foi cumprida |

**A metade que faz o maestro VER o flip é justamente a não-mecanizada.** Isso não é descuido, é o
preço da exceção, e está escrito para que ninguém leia `exit 0` como "pode selar sozinho".

**Por que a exceção existe (medido, não suposto).** Na sessão de condução de 2026-09-05 o driver
derrubou **duas** posições próprias criadas no mesmo dia, para o mesmo sintoma
(`Q_UPDATE_EXIGE_ADOCAO_INTEGRADA`, supersedida, e `Q_VENDOR_ENTRELACADO_COM_PRODUTO`, refutada por
sandbox). Sem exceção, a regra geral produz o pior dos dois mundos: ou o driver **para** e um lote
inteiro fica represado por auto-correção de coisa que o maestro nunca viu, ou ele **não se corrige** e
o `--integrity` quebra (aresta `REFUTES` cujo alvo segue `open` reprova). E há um detalhe que decide a
forma da regra: rodado sobre esses dois flips, o predicado **libera um e recusa o outro** — o primeiro
já estava em `main`, era selo do maestro, e foi flipado sem parada. A exceção nasce, portanto,
**estreita de propósito**: ela cobre o caso que o driver de fato tem, não o que ele gostaria de ter.

**O que a exceção NÃO abre — o teto, com as frestas conhecidas nomeadas:**

- **Nó já em `origin/main`** → selo humano, sempre. É a fronteira inteira.
- **`verified_at` sem medição · merge no main · MOAT · decisão não-tomada** → seguem PARA.
- **FRESTA DECLARADA — PR empilhado.** A base é `origin/main`. Um nó criado num PR **aberto** (já
  visto por um revisor, ainda não mergeado) e derrubado num PR empilhado sobre ele sai `AUTO`. A
  equação "não está em `origin/main`" ⇒ "o humano nunca viu" é **falsa** nessa topologia, e esta casa
  usa stack. Quem empilha passa `--base` apontando o PR de baixo.
- **FRESTA DECLARADA — a (2) não separa medição de opinião.** `verified_against: "eu pensei melhor"`
  passa. O campo é auto-atestado por quem quer o `AUTO`; quem fecha isso é o maestro lendo o
  checkpoint, e é a razão de a (4) existir.
- **Fabricar o caso** — criar um nó só para poder derrubá-lo — não é impedido por mecanismo nenhum.
  É a razão de o caminho preferido, no topo desta seção, ser **corrigir o rascunho**: quem fabrica
  Aufhebung sobre erro próprio está gastando cerimônia para comprar autonomia, e isso aparece no
  checkpoint.

**E o selo que continua existindo.** A exceção dispensa um **selo separado**, não a supervisão: o
flip viaja no PR, e o merge no `main` — que segue 100% humano, pelo caminho verificado — é onde o
maestro o aceita. Note o que isso **não** é: o revisor automático do PR é adversarial, não é o
maestro. É a linha do `STATE.md` que põe o flip diante dele.

## 5. As 6 regras de doutrina que o driver encarna

1. **Refutar antes de avançar** — passo de peso doutrinário enfrenta um worker adversarial (default=REPROVADO); a objeção sobrevivente vira nó preservado, nunca apagada. ([`onion-elenxo-doctrine.md`](onion-elenxo-doctrine.md))
2. **Rodar de verdade + fechar o loop** — executa o artefato + modo-de-falha; fix→re-dogfood no mesmo loop; **lint-verde ≠ pronto**. ([`onion-dogfooding-doctrine.md`](onion-dogfooding-doctrine.md))
3. **Toda cura vira mecanismo** — defeito→`SUPERSEDES` no grafo (velho preservado, Aufhebung) + mecanismo, não conselho. (`sync-gate-superacao-2026-08.kg.yaml`, `fix-must-become-mechanism`)
4. **Grafo-primeiro, escreve-depois** — o driver **É** o forcing-function `read(KG)→act→write(KG)` (o Censo é o Passo 1 obrigatório); a perna de LEITURA do KG **não é mecanismo** ([[onion-kg-ontology-hierarchy]] §5) — o driver a supre lendo primeiro, mas não força absorção no lado humano.
5. **Interface estável, motores como adapters** — o driver é a interface (`conduzir até o fim`); Elenxo/dogfood/kg-freshness/forge são adapters por trás de contratos (SDAAL, `integrations.md`).
6. **Confie no comportamento, não na declaração** — cada gate validado por execução/entrega; *"exit-code é evidência, leitura é hipótese"*; cuidado com o teste no caminho errado. (`behavior-over-declaration.md`)

## 6. Anti-padrões (provar AUSENTES na verificação)

1. **Carimbo-automático-sem-medição** — só a rota `kg-freshness` carimba, só com método executado; `UNVERIFIABLE` é 1ª classe. A exceção do §4.1 **não** afrouxa isto: ela dispensa o SELO de um flip, nunca a MEDIÇÃO que o justifica.
2. **Thrashing** — histerese do realign; 1-passada/checkpoint; nó em-voo não é re-selecionado (status monotônico).
3. **Agendar-por-relógio (MOAT/W7)** — maestro-invocado; nunca `/loop`/`schedule`/`cron` sobre o driver; sem auto-start no boot.
4. **Fundir fases contra a orquestração** — decompor→delegar→sintetizar/verificar; nunca um worker que mede **e** escreve.
5. **Ordenação dirigida na Fase 1** — `DEPENDS_ON` é só guarda "não-antes-de"; topológica é Fase 2.
6. **Starvation** — o Censo reporta BLOQUEADOS com o bloqueador; o bloqueador vira item de alta atenção próprio.
7. **Colisão de worktree (I3)** — `session-beacon.sh check` antes de todo switch; abort-on-collision, nunca operar a árvore do main.

## Referências
- Censo: [`${CLAUDE_PLUGIN_ROOT}/validation/kg-drive-project.sh`](${CLAUDE_PLUGIN_ROOT}/validation/kg-drive-project.sh) · fixtures (**core-only**, não viajam no plugin) em `${CLAUDE_PLUGIN_ROOT}/validation/fixtures/kg-drive/`
- Verificador-por-turno: `/onion:realign` · Motor: `kg-radar.sh`
- Precedente/escada (**core-only**): ADR `onion-adr-autonomous-thread-runtime-2026-07` · KB `graduated-automation-ladder.md`
- Motores adapter: `/onion:kg-freshness` · skill `onion-orchestration` · `agent-orchestration.md`
- Fonte-plano de exemplo (**core-only**): `docs/onion/graph/fios-abertos.kg.yaml` — num repo que instalou o plugin, o plano-grafo é o do próprio repo
