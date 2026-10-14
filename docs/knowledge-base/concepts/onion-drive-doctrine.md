# Doutrina do `/meta:drive` — conduzir um plano-grafo até o fim, com rigor Onion

> **O que este doc é.** O **contrato canônico** do driver de plano: o laço, o roteamento do passo
> AVANÇAR por KIND de nó, a **tabela de selagem** (onde o driver auto-avança e onde PARA), as 6 regras
> de doutrina que ele encarna, e os anti-padrões. A **Fase 0** (o Censo determinístico) já existe como
> mecanismo: `.claude/validation/kg-drive-project.sh`. A **Fase 1** (o laço em si, `/meta:drive`) é
> construída sobre este contrato. **Fase 2** (o degrau AUTOMATE) foi forjada em 2026-10-14, com o merge
> desligado por padrão: `.claude/validation/drive-automate.sh`, contrato no fragmento `drive-doctrine.md`.
>
> **Por que existe.** O reforço-prosa do maestro (*"siga com execução até o final… nada parado sem
> controle"*) é **disciplina, não mecanismo**. O `/meta:realign` já mecanizou o *alinhamento*; este
> mecaniza a *condução*. O precedente é o ADR `autonomous-thread-runtime` (a escada + o loop), que era
> **prosa gated** — a 1ª passada do `/meta:drive` é o dogfood que o **sela** (proposed→accepted).

## 0. A escada de autonomia (do ADR `onion-adr-autonomous-thread-runtime-2026-07.md`)

O driver opera num **degrau declarado**, nunca acima:
- **Nível 0** (auto sempre): atos reversíveis em worktree própria (branch/commit/PR/dogfood), `write(KG)` de append, **propor** ato-3.
- **AUDIT** (o degrau da Fase 1): conduz um fio **até PR-verde sozinho**; **merge no main é 100% humano, em LOTE** num checkpoint.
- **AUTOMATE** (Fase 2, forjada em 2026-10-14): auto-merge só sob 3 pré-condições duras (enabler git-nativo · path-allowlist `git diff ∩ vendor = ∅` · política 100% mecânica, LLM veto-only).
  **Decisão do maestro (2026-10-12, SAC-74, `/meta:decide` sobre `D_AUTO_DRIVE_DEGRAU_AUTOMATE`): «Forjar com as
  objeções», com `--merge` DESLIGADO por padrão.** A proposta pedia merge por padrão; a pergunta selada o
  inverteu, e as quatro objeções do grafo (`CONSTRAINS`) viraram requisito. A ordem de 2026-08-18 ("até o final"
  = executar → commit → PR → **MERGE**) vira degrau **com mecanismo de controle**: o merge acontece quando o
  maestro passa `--merge`, e nunca por omissão. O contrato do degrau é o fragmento
  `common:prompts:drive-doctrine` (citado pelo `/meta:drive`), e o executor, `.claude/validation/drive-automate.sh`.
  As 3 pré-condições ganham nome concreto nesta casa:
  - o **enabler** é o `ops/pr-merge-verified.sh` (core-only), o único caminho de merge; o hook `merge-gate` veta
    qualquer outro com exit 2;
  - o merge **em série** (o lote) é `bash ops/merge-serial.sh <PR>...` (core-only), na ordem dos argumentos: duas séries não mergeiam ao mesmo tempo (lock só no rebase+merge, CI esperado fora dele) — decisão em `docs/evolution/research/merge-process-onion-2026-10/merge-process-onion-2026-10.kg.yaml#C_OPCAO_C_MERGE_SERIAL_IN_OPS`;
  - a **bancada roda em dois níveis, sem fila** (passo D, `…merge-process-onion-2026-10.kg.yaml#C_OPCAO_D_TWO_TIER_BENCH_NO_QUEUE`):
    - **no PR**, só as famílias que o diff toca (`ops/testing/selftest-pr-selection.sh` (core-only), que usa a seleção do pre-commit pelo range `base...head`);
    - cai na **completa**, com o porquê no log, quando o mapa não classifica um arquivo tocado, quando o diff toca a bancada ou a infra do CI (`lint-selftest.sh`, `.github/workflows/*`, `ops/testing/*` (core-only)), ou com a label `ci:full`;
    - **no push ao main**, a completa. Se ela reprova, `ops/testing/main-bench-alarm.sh` (core-only) abre a issue de título fixo com o commit culpado e prepara `revert/<sha12>`, **sem mergear**. O merge do revert passa pelo caminho verificado;
    - **o main vermelho não tem um culpado por commit** (defeito medido em 2026-10-13, `…merge-process-onion-2026-10.kg.yaml#E_ALARME_CULPA_SO_A_PRIMEIRA_QUEBRA_2026_10_13`). A completa reprovou em `ff5abe51` (issue #1086, revert #1085). O commit seguinte, `825e93f6`, só herdou a quebra, e o alarme abriu um 2º revert (#1087) contra ele. A causa era o `docs/backlog.md` fora de sincronia, consertado para a frente no #1088. A regra agora:
      - a **assinatura** da quebra é o conjunto de famílias com falha, lido dos relatórios TSV das faixas (o job `alarme-main` baixa os artefatos). Cada post da issue guarda a sua num marcador `<!-- onion-alarm v1 … -->`. Só conta marcador de post do Actions, lido pela autoria que o forge informa: o repo é público, e um marcador colado por terceiro calaria o revert;
      - **1º vermelho** (sem issue aberta): issue + revert, como antes;
      - **issue já aberta e só famílias conhecidas**: só comenta com o commit, o resultado e as famílias. **Sem revert**, porque o commit herdou a quebra;
      - **família nova**: é uma quebra sobre a quebra. Comenta, nomeia o commit como **suspeito novo** e **prepara o revert dele**. Preparar é reversível e nunca mergeia, e quando a 1ª quebra sair a 2ª continua. Se o commit é o merge de um revert, só nomeia;
      - **commit mais velho que o culpado registrado**, com as mesmas famílias (dois pushes concorrentes, a bancada do mais velho terminou depois): ele é o culpado e o revert é dele;
      - **issue ilegível** (não consigo ler, ela não tem marcador ou o 1º alarme não teve assinatura) **ou assinatura atual ilegível**: declara o porquê e **não abre revert às cegas**;
      - issue **fechada à mão** com o main vermelho continua valendo como referência. Duas issues de 1º vermelho concorrentes se fundem na de número menor;
      - o **verde** fecha a issue e, **depois**, fecha com comentário os PRs de revert superados. São os que batem nas três condições: head `revert/<12 hex>`, autor `app/github-actions` e sha12 citado na issue;
    - **localmente, nunca a completa** (decisão do maestro de 2026-10-13, `D_BANCADA_SEMAFORO_DA_MAQUINA_SEM_COMPLETA_LOCAL` no grafo da decisão de faixas): o pre-commit e o `ops/pr-finalize.sh` (core-only) rodam a **faixa local** (`lint-selftest.sh --local`). Mesmo quando o diff toca a bancada, os workflows ou `ops/testing/*`, ela roda só quem cita os arquivos tocados, os blocos mudados da bancada e um núcleo local fixo (`selftest_lanes`, `selftest_selection`, `two_tier_bench`, `machine_slots`, `shell_pipefail_robustness`), e declara que a completa é do CI. A completa local é opt-in: `ONION_SELFTEST_FULL=1` ou `--full`. E toda bancada da máquina divide **N = nproc vagas**, um semáforo `flock` do usuário que vale para todas as worktrees e sessões. A espera por vaga sai no sumário. Medido no dia: cinco agentes com a completa em 8 vCPUs levaram uma bancada de ~8 min a 34+, e o runner matou dois pre-commits;
    - **janela declarada:** entre o merge e o merge do revert, o main pode estar quebrado (a completa leva da ordem de 25 min por faixa, mais o merge verificado). Com o alarme aberto, só se mergeia o conserto;
    - os checks que o ruleset do main exige são os estáveis: `selftest-gate` e `lint-onion-artifacts`. O ruleset é aplicado por `ops/apply-ruleset-main.sh` (core-only) e o admin tem bypass **só em merge de PR** (`bypass_mode: pull_request`, decisão do maestro de 2026-10-13): o merge verificado passa com a dispensa nomeada, mas o push direto ao main fica barrado também no forge, inclusive para o dono — uma 2ª camada sobre o hook exit 2 e o caminho verificado;
  - **auto-rebase limpo não espera o CI do head novo** (decisão do maestro de 2026-10-13, «A agora, B se precisar», `…merge-process-onion-2026-10.kg.yaml#D_MERGE_SEM_CI_APOS_REBASE_LIMPO`). Medido: cada merge da fila levava 20–25 min, quase tudo esperando o CI do head rebaseado. Agora o verificado mergeia na mesma chamada quando **todas** as condições valem; qualquer uma que falha volta à espera de antes (rc 4 na série):
    - o rebase não teve conflito de fonte (conflito só de projeção gerada conta como limpo: o `pr-finalize` a regenera e roda o lint);
    - a worktree estava no head que o PR mostrava (verde de outro head não vale, como depois de um force-push);
    - os checks que o ruleset exige estavam verdes no head **anterior**, e nenhum outro check falhou sem dispensa;
    - o que a main trouxe entre o merge-base velho e o novo não toca arquivo do PR, fora as projeções geradas;
    - nenhum alarme de main quebrado está aberto (com o alarme aberto, só o conserto entra, e nunca sem CI);
    - o ruleset não tem regra além dos checks (o bypass contorna o ruleset inteiro; com outra regra, espera);
    - não foi passado `--wait-ci-after-rebase` (o opt-out, também aceito pelo `merge-serial.sh`);
    - as projeções geradas do head novo, regeneradas na árvore combinada, são **byte-idênticas** às do head anterior (FASE 0, abaixo). Mudou alguma, o CI nunca viu aquela projeção e o head novo espera.
    Os gates rodam contra o head anterior. O ruleset exige os checks **no head do PR**, e um head recém-empurrado não tem nenhum, então o merge vai pelo bypass de admin em PR, com `--match-head-commit` no head novo: se alguém empurrar depois da decisão, o forge recusa. A decisão sai no log e no comentário de auto-rebase do PR. **Janela declarada:** dois PRs que mudam arquivos diferentes e se quebram semanticamente entram os dois, e só a completa do main pega. O lote com bissecção (B) fica gated em `#Q_MERGE_LOTE_COM_BISSECCAO`, e o gatilho é o main quebrar por combinação de PRs, contado pelas issues do alarme;
  - **a base do PR tem de ser a ponta do main** (strict local, FASE 0 da decisão do maestro de 2026-10-14 sobre `D_POSTMERGE_PROJECTION_WRITER_2026_10`, «Fase 0 já + ler primárias antes do B1»; evidência em `…merge-process-onion-2026-10.kg.yaml#E_STRICT_LOCAL_EXECUTADO_2026_10_14`). O ruleset tem `strict_required_status_checks_policy: false`, então o forge aceita PR atrás do main e mergeia a árvore combinada, que o CI nunca viu. Foi assim que o `docs/backlog.md` entrou com 479 itens e o cabeçalho de 478: dois PRs faziam o mesmo `477→478`, e o merge textual somou os itens sem conflito. Agora:
    - a distância é lida no forge (`compare <base>...<head>`, `behind_by`); leitura ilegível não mergeia;
    - PR atrás **sem conflito** passa pelo mesmo auto-rebase do CONFLICTING (`pr-finalize --rebase --push`, que regenera as projeções na árvore combinada e as commita no head), com o mesmo teto de 2 rebases na série; o main que não para de andar para no teto, sem merge;
    - uma última leitura logo antes do merge: o `--match-head-commit` amarra o head, não a base, e o main pode ter andado durante a espera do CI (direto: para; na série: rc 4, volta à fila);
    - com `--merge-commit`, PR atrás é recusado com o caminho (mergear a base na branch), porque o rebase linearizaria o merge que é o conteúdo;
    - **preço medido** nos 50 últimos merges (#1045–#1099): 5 estavam atrás, ou seja, 5 rebases a mais (10%), e 3 deles esperariam o CI do head novo (~15–25 min cada) porque o main tinha trazido projeção. Como 43 de 50 PRs commitam projeção, o caminho rápido depois de um rebase fica raro;
  - a **path-allowlist** é a parada dura "path vendorizado/outward-facing" (REGRA 36 e REGRA 30);
  - a **política mecânica** são as **paradas duras**, todas PARA:
    - decisão não tomada;
    - Elenxo reprovado;
    - CI vermelho inesperado (o veredito do revisor sem crédito é dispensa NOMEADA, não silêncio);
    - repo alheio (I3);
    - budget esgotado;
    - ciclo na cadeia.

  ⚠️ **O degrau só abre quando as paradas duras forem predicados executáveis com mutante (SAC-114).**
  Merge por padrão sobre parada em prosa é o carimbo automático que esta doutrina existe para matar.
  **Aberto em 2026-10-14:** cada parada acima é um veredito nomeado do `drive-automate.sh` (`DECISAO-NAO-TOMADA`,
  `ELENXO-REPROVADO`/`ELENXO-UMA-VOZ`, `CI-VERMELHO`/`CI-VAZIO`, `REPO-ALHEIO`, `BUDGET-ESGOTADO`/`TETO-DE-NOS`,
  `CICLO`, `PATH-VENDORIZADO`), com caso e mutante na família `run_drive_automate_selftests`. Sem `--merge`
  o degrau para em PR verde (rc 3, AUDIT).
- **MOAT** (nunca): deploy · escrever repo alheio (I3) · merge de path vendorizado/outward-facing · **agendar por relógio (W7)**. O driver é **maestro-invocado**, nunca cron/`/loop` sobre si.

  **O que do MOAT é VETO e o que segue PROSA (2026-10-13).** Até 2026-10-13 só o merge no main tinha veto
  (`pretooluse-merge-gate.sh`). Desde então o hook `pretooluse-moat-gate.sh` (armado só no core) veta **por ALVO**, nunca por
  vocabulário (`rsync`, `systemctl` e `git commit` são legítimos fora de deploy). Os alvos são dado versionado:
  `ops/moat-targets.tsv` (core-only) e o `local_path` de `docs/evolution/federation/members.yaml`. A família de
  bancada `moat_gate` prova cada linha da coluna "veto" com um caso e um mutante executado.

  | item | veto (exit 2, antes de executar) | segue prosa (fronteira declarada) |
  |---|---|---|
  | deploy | `systemctl`/`service`/`docker` que muda unidade `onion-vps-*`, `onion-adopt-*` ou `caddy`; escrita (`cp`, `mv`, `install`, `rsync`, `tee`, `ln`, `rm`, `sed -i`, `dd`, `tar -x`, redirecionamento…) em caminho servido; `git checkout/reset/pull…` numa árvore servida; script FORA do projeto (ou não rastreado) que faça isso, lido e julgado | script versionado do projeto (é assim que o wrapper `ops/…` passa); os 3 serviços que servem do checkout principal do core; `docker compose`; ssh; `systemctl daemon-reload` |
  | repo alheio (I3) | `git push` num clone de membro registrado; `git push` cujo destino é provadamente outro repositório | commit, branch e config LOCAIS num clone de adotante (é o `/meta:adopt --update`); `gh` escrevendo em repo alheio |
  | relógio (W7) | `crontab` que instala/edita/remove; `at`/`batch`; `systemd-run` com timer; `systemctl` que liga `.timer`; escrita em `/etc/cron*`, `/var/spool/cron` ou num `.timer` | as ferramentas `CronCreate`/`ScheduleWakeup` do Claude Code (o `/loop` é superfície legítima do maestro, e o hook não sabe quem o pediu) |
  | merge de path vendorizado | o merge no main (merge-gate) | o resto segue PARA em prosa |

  No adotante o hook **se desarma**: sem `ops/moat-targets.tsv` (core-only) não há alvo, e o MOAT do adotante segue
  prosa. Escape = o maestro roda fora da sessão (`!` no prompt). Não há variável de bypass: escape que o modelo
  escreve na própria string seria gate textual com outro nome.

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
P0.5 CHECKPOINT PEND. meta.drive_checkpoint: pending no grafo? → PARA (o censo emite CHECKPOINT-PENDENTE)
P1   CENSO            kg-drive-project.sh → FILA-PRONTA + BLOQUEADOS
P2   SELECIONAR LOTE  top --max-nodes (guardas max-nós/passada + budget)
P3   POR NÓ           classificar drive_kind · session-beacon check (I3) · AVANÇAR (§3) ·
                      ELENXO se peso doutrinário · veredito-de-escrita (§4) · abort-on-anomaly
P4   FECHAR O LOOP    dogfood RODOU o artefato + modo-de-falha? fix→re-dogfood no MESMO loop
P5   CHECKPOINT LOTE  meta.drive_checkpoint: pending no grafo: PRs p/ merge humano · DRIFTED/REFUTED p/ selo · kg-radar exit 0 ·
                      kg-realign --check (drift residual)
P6   PARA             nenhuma passada nova enquanto o checkpoint pende (batch-confirm AUDIT)
```

## 3. Roteamento de AVANÇAR, por `drive_kind` (default inferido do `node_type`; campo `drive_kind:` sobrepõe)

| KIND | node_type | "avançar" = | delega a (REUSADO) | produz |
|---|---|---|---|---|
| **research** | `question` | colher evidência vs o vivo/externo | `onion-orchestration` fan-out + Web* + `write(KG)` | `evidence` + `SUPPORTS`/`REFUTES` |
| **verification** | `claim` | MEDIR o nó contra o vivo | `/meta:kg-freshness --node <id>` (mede, propõe) | veredito + `proposed_write` |
| **execution** | `decision` (reversível) | trabalho em worktree até **PR-verde** + dogfood | orquestração de execução (molde de fases do `/engineer:work`, até 1 PR) | branch/PR + evidência |
| **decision** | `decision` (não-tomada) | enquadrar + Elenxo, **propor** a chamada | `adversarial-verification` | `decision` PROPOSTO (não selado) |

### 3.1 Spike que mede hipótese de produto (KIND research ou verification)

Quando o nó `Q_` conduzido é uma **hipótese de produto** testada por spike ("o adaptador X propõe nós
que valem a pena?"), o avanço exige, **num commit anterior à amostra**:

1. **critério de morte com denominador fixo** — escrito no próprio nó ou ao lado, com o proponente e o
   placar. Trocar o denominador depois de medir é mover a régua: num adotante, a 1ª leitura passou de
   26,6% para 68% trocando "todas as propostas" por "as julgadas", e o Elenxo a derrubou;
2. **uma medida de VALOR com avaliador cego** — um agente separado, sem acesso à hipótese, marca cada
   proposta MANTER ou DESCARTAR. Sobrevivência à selagem **não** basta, porque premia a proposta
   trivial (100% numa cópia, 0 de 8 no valor, na mesma hipótese).

A ordem fica verificável no `git log` (critério antes da amostra). A pergunta que o Elenxo faz a esse
critério é a da etapa 3 em [`onion-elenxo-doctrine.md`](onion-elenxo-doctrine.md) ("o critério separa a
proposta útil da trivial?").

## 4. Tabela de SELAGEM (postura AUDIT — mata o carimbo-automático)

| Evento | Ação | AUTO vs PARA |
|---|---|---|
| research → `evidence` (append) | `write(KG)` | **AUTO** |
| verification **CONFIRMED** (mediu de fato) | carimba `verified_at` | **AUTO** (só porque houve medição executada) |
| verification **DRIFTED** | apenda nó-medido + `SUPERSEDES`; alvo fica `confirmed` (radar exit 0) | **AUTO escreve / PARA o humano flipar** alvo→superseded (salvo §4.1, que vale para `SUPERSEDES` tanto quanto para `REFUTES`) |
| verification **REFUTED** | propõe nó + `REFUTES` + flip atômico | **PARA** (apendar solto quebra `--integrity`; peso alto) |
| **REFUTED/SUPERSEDED de nó NUNCA SELADO** (§4.1) | mesmo ato, mas o par nasce e cai no MESMO PR | **AUTO nas 4 precondições** (`kg-seal-exception.sh`); a 4ª — o flip nomeado na `drive_checkpoint_note` do lote — mecanizada em 2026-10-04 |
| verification **UNVERIFIABLE** | `blocked_by`, **não carimba** | **AUTO** (não-escrita; 1ª classe) |
| execution → PR-verde | conduz em worktree | **AUTO até o PR** |
| **merge no main** | — | **AUDIT: PARA** (100% humano, em lote) · **AUTOMATE: PARA por padrão**; com `--merge` explícito, AUTO pelo `ops/merge-serial.sh` → `ops/pr-merge-verified.sh` (core-only), salvo parada dura (§0; decisão de 2026-10-12, aberta em 2026-10-14) |
| **decisão não-tomada** | frame + Elenxo + propõe | **PARA** (selo humano) |
| drift tipo-(c) estrutural | novo nó + `SUPERSEDES` datado | **AUTO** (realign repara determinístico) |
| **MOAT** | — | **NUNCA / PARA** (parte é veto por alvo desde 2026-10-13; a tabela do §0 diz qual) |

**Invariante que amarra:** *o único caminho para um `verified_at` novo passa por uma medição executada*
(contrato do `/meta:kg-freshness`). O driver **apenda** evidência; quem **flipa** o status de verdade
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
4. **DECLARADA NO CHECKPOINT** — a `drive_checkpoint_note` do lote (no `meta:` do grafo, escrita por
   `kg-drive-project.sh --close-lot`) **nomeia** o flip como auto-selado por esta exceção. Até
   2026-10-04 era o `STATE.md`, que é gitignorado e que o maestro nunca via. Flip silencioso não é exceção, é o carimbo-automático que o anti-padrão 1 do §6 proíbe.

**O que é mecânico e o que não é — sem arredondar para cima.** O predicado
[`kg-seal-exception.sh`](../../../.claude/validation/kg-seal-exception.sh) decide `AUTO`/`PARA` e sai
`1` em toda dúvida (fail-closed). Mas ele **não cobre as quatro**:

| precondição | quem decide | teto |
|---|---|---|
| (1) nunca selado | **o predicado** | lê YAML de verdade, varre TODOS os grafos da base (árvore + história), recusa repo raso e base defasada |
| (2) medição executada | **parcial** | prova que `verified_at`/`verified_against` **existem e não são placeholder**; nenhum script sabe se o texto descreve algo que rodou |
| (3) Aufhebung + integridade | **o predicado** | aresta e status lidos por YAML (não por texto), mais o radar |
| (4) declarada no checkpoint | **o predicado** (desde 2026-10-04) | `drive_checkpoint: pending` e o id na `drive_checkpoint_note`, por fronteira de identificador; a nota viaja no diff do PR |

**A metade que faz o maestro VER o flip deixou de ser não-mecanizada** quando o checkpoint saiu do
`STATE.md` gitignorado para o grafo. O que segue humano é o selo: o merge.

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
maestro. É a linha da `drive_checkpoint_note`, no diff, que põe o flip diante dele.

## 5. As 6 regras de doutrina que o driver encarna

1. **Refutar antes de avançar** — passo de peso doutrinário enfrenta um worker adversarial (default=REPROVADO); a objeção sobrevivente vira nó preservado, nunca apagada. ([`onion-elenxo-doctrine.md`](onion-elenxo-doctrine.md))
2. **Rodar de verdade + fechar o loop** — executa o artefato + modo-de-falha; fix→re-dogfood no mesmo loop; **lint-verde ≠ pronto**. ([`onion-dogfooding-doctrine.md`](onion-dogfooding-doctrine.md))
3. **Toda cura vira mecanismo** — defeito→`SUPERSEDES` no grafo (velho preservado, Aufhebung) + mecanismo, não conselho. (`sync-gate-superacao-2026-08.kg.yaml`, `fix-must-become-mechanism`)
4. **Grafo-primeiro, escreve-depois** — o driver **É** o forcing-function `read(KG)→act→write(KG)` (o Censo é o Passo 1 obrigatório); a perna de LEITURA do KG **não é mecanismo** ([[onion-kg-ontology-hierarchy]] §5) — o driver a supre lendo primeiro, mas não força absorção no lado humano.
5. **Interface estável, motores como adapters** — o driver é a interface (`conduzir até o fim`); Elenxo/dogfood/kg-freshness/forge são adapters por trás de contratos (SDAAL, `integrations.md`).
6. **Confie no comportamento, não na declaração** — cada gate validado por execução/entrega; *"exit-code é evidência, leitura é hipótese"*; cuidado com o teste no caminho errado. ([`behavior-over-declaration.md`](../agentic-patterns/ai-strategies/behavior-over-declaration.md))

## 6. Anti-padrões (provar AUSENTES na verificação)

1. **Carimbo-automático-sem-medição** — só a rota `kg-freshness` carimba, só com método executado; `UNVERIFIABLE` é 1ª classe. A exceção do §4.1 **não** afrouxa isto: ela dispensa o SELO de um flip, nunca a MEDIÇÃO que o justifica.
2. **Thrashing** — histerese do realign; 1-passada/checkpoint; nó em-voo não é re-selecionado (status monotônico).
3. **Agendar-por-relógio (MOAT/W7)** — maestro-invocado; nunca `/loop`/`schedule`/`cron` sobre o driver; sem auto-start no boot.
4. **Fundir fases contra a orquestração** — decompor→delegar→sintetizar/verificar; nunca um worker que mede **e** escreve.
5. **Ordenação dirigida na Fase 1** — `DEPENDS_ON` é só guarda "não-antes-de"; topológica é Fase 2.
6. **Starvation** — o Censo reporta BLOQUEADOS com o bloqueador; o bloqueador vira item de alta atenção próprio.
7. **Colisão de worktree (I3)** — `session-beacon.sh check` antes de todo switch; abort-on-collision, nunca operar a árvore do main.

## Referências
- Censo: [`../../../.claude/validation/kg-drive-project.sh`](../../../.claude/validation/kg-drive-project.sh) · fixtures (**core-only**, não viajam no plugin) em `.claude/validation/fixtures/kg-drive/`
- Verificador-por-turno: `/meta:realign` · Motor: `kg-radar.sh`
- Precedente/escada (**core-only**): ADR `onion-adr-autonomous-thread-runtime-2026-07` · KB [`graduated-automation-ladder.md`](graduated-automation-ladder.md)
- Motores adapter: `/meta:kg-freshness` · skill `onion-orchestration` · [`agent-orchestration.md`](agent-orchestration.md)
- Fonte-plano de exemplo (**core-only**): `docs/onion/graph/fios-abertos.kg.yaml` — num repo que instalou o plugin, o plano-grafo é o do próprio repo
