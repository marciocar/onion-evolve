# Corpus de automação do Onion — o que a casa já tem (2026-11-11)

Levantamento só leitura. Todo caminho:linha vem de grep desta sessão no core ou, para o kg-ssot, de git show/grep no repositório dele (HEAD 3083a45b).

## 1. Onde nasce a regra "nunca agendado / nunca cron" (W7) e o PORQUÊ

**Achado de precisão:** "W7" não nasceu como cláusula do MOAT. Nasceu como o 7º valor do **Eixo E (topologia de sessão)** do ADR `onion-adr-work-models-session-topologies-2026-07`. O MOAT é o degrau invariante da escada (deploy, repo alheio, irreversível). As superfícies escrevem "MOAT W7" juntando as duas coisas.

- Origem: `docs/knowledge-base/decisions/onion-adr-work-models-session-topologies-2026-07.md:23` (tabela, W7 = "Sessão agendada (cron/daemon)": agente acorda sozinho por relógio/evento e age; 🔴 rejeitado como base) e `:46` (§3 "W7 (cron) rejeitado como base; lazy-por-sessão é o padrão soberano").
- PORQUÊ declarado (`:48-51`): sessão agendada de vendor "exige serviço vivo e autonomia durante a run (routines: cloud-only, sem prompts de aprovação; HITL só post-hoc) — incompatível com o fluxo soberano sempre-gated". O substituto que já se pratica é a **cadência lazy acionada por sessão** (hooks SessionStart/End).
- **Gatilho de reabertura declarado no próprio ADR** (`:53-55`): W7 volta à mesa se surgir necessidade nomeada que o lazy-por-sessão comprovadamente não cobre (exemplo dado: SLA entre membros remotos), e mesmo então na forma **rascunho-only** (agendado só propõe, nunca executa). Linha 81 da tabela de graduação: "W7 rascunho-only agendado | 🔒 | necessidade nomeada".
- Resumo canônico na KB pública: `docs/knowledge-base/concepts/federation-usage-modes.md:56`.
- Onde a regra está escrita nos comandos/guardas (todas "maestro-invocado, nunca cron"):
  - `.claude/commands/meta/drive.md:25`, `radar.md:7,32`, `census.md:38`, `dissect.md:22`, `common/prompts/dissect-doctrine.md:289`, `.claude/skills/onion-research/SKILL.md:139`.
  - Lint: `.claude/validation/lint-artifacts.sh:5072` (REGRA 65), `:5208` e `:5322` (revisita de pesquisa).
  - **Mecanismo, não só prosa:** `.claude/hooks/pretooluse-moat-gate.sh:21` lista o que conta como "relógio" (crontab que instala/edita, at/batch, systemd-run com timer, systemctl que liga .timer) e `:220-222` veta com exit 2: "agendar por relógio é W7: o Onion é maestro-invocado, nunca cron/timer sobre si... agendamento é do maestro, fora da sessão (`!` no prompt)".
- Reforço de doutrina: `docs/knowledge-base/concepts/graduated-automation-ladder.md:42` (MOAT = "nunca", sempre humano, "não se promove").
- Registro do diário: `.claude/diary/2026-07-02-work-models-eixo-e-decision.md:17-27`, re-testado em 2026-10-14 (linha 33): §3 intacto.

## 2. O que já é automático hoje (mesmo com a regra)

A regra veda **o agente do Onion agendar-se**. Ela nunca vedou hook de sessão, CI do repo, nem detecção passiva.

- **Hooks de SessionStart/UserPromptSubmit** (lazy por sessão), `.claude/settings.json:96` (SessionStart) e `:138` (UserPromptSubmit): `task-manager-provider-hook.sh`, `worklog-capture-session.sh`, `co-evolution-inbox-check.sh` (aviso 📬 e ⏰), `session-plugin-write-scan.sh`, `session-beacon-hook.sh up`, `memory-write-scan-check.sh --session`, mais `session-currency-check.sh` (cobra a base atual) e `session-version-drift.sh` no diretório `.claude/hooks/`.
- **Hooks de veto PreToolUse (exit 2)**, `.claude/settings.json:252-336`: `pretooluse-env-guard.sh`, `protect-main`, `merge-gate`, `moat-gate`, `direct-provider-api`, `plugin-write-guard`, `memory-write-guard`, `adopter-guard`; `kg-read-leg.sh` (injeta "o corpus já fala deste arquivo"); `house-code-gloss.sh`. Também há PreModelSwitch (`:337`) e Stop (`:372`).
- **CI agendado (a única exceção real a "nunca cron" hoje):** `.github/workflows/onion-selftest.yml:49-53`, `schedule: cron '17 4 * * *'`, "roda a bancada inteira na main todo dia" para pegar a quebra que vem de fora (runner, dependência, data). Os outros quatro workflows (`onion-validate`, `onion-review`, `onion-review-diagnose`, `onion-door-staleness`) não têm `schedule:` (grep). É infraestrutura do repo, não o agente se agendando.
- **Campainha (doorbell)**: MCP `doorbell` (aviso de sinal novo no inbox; `pending_signals`/`ack_signal`), estado em `.claude/utils/co-evolution/doorbell-state.py`. Grafos: `docs/onion/graph/doorbell-hardening-2026-11.kg.yaml`, `doorbell-session-opener-2026-11.kg.yaml`; nó `D_MD_DOORBELL_CROSS_MACHINE_AFTER_10_1109` (`maestro-decisions-1108.kg.yaml:400`) e `D_MD_EVOLVE_AFTER_DOORBELL_1108` (`:77`).
- **Fila A2A viva**: `ops/a2a-queue-live.sh` (único caminho de escrita na fila; ensaio por padrão, backup cifrado, rollback impresso). Intake autônomo, aceite humano (`a2a-accept.sh`).
- **Lease de carga**: `ops/load-lease.sh` + `ops/load-lease.conf` (régua parar ≥15, retomar <12, teto 1800 s; "lock social" virou mecanismo). Revisões: `docs/evolution/review/feat-load-lease.md`, `ops-lease-psi-30.md`.
- **Radar que avisa vencimento (a máquina DETECTA, o humano DISPARA)**:
  - REGRA 65 "Radar de mundo com baseline DATADA por eixo" `lint-artifacts.sh:5067` [SOFT].
  - REGRA 67 "Grafo de pesquisa com REVISITA carimbada (meta.review_after)" `:5203` [SOFT].
  - REGRA 62 "Projeção GERADA em sincronia" `:1520` [HARD] (backlog).
  - REGRA 85 "Porta pública espelha o core, com catraca" `:2792` [SOFT, só informa].
  - REGRA 97 (evolve vencido), em `.claude/validation/evolve-staleness-check.sh`.
  - REGRA 104 (executável do adapter e capabilities.tsv coerentes) `:6004`.
- **Catracas com baseline** (`.claude/validation/*-baseline.txt`): doctrine-freshness, door-staleness, kb-applies-to, kb-vendored-link, kg-coverage, kg-verification, kg-yaml-validity, identifier-language, vendor-scrub-form e outras. Regras-mãe: REGRA 29 "Gate de PROVENIÊNCIA INVERTIDO, com catraca" `:3880` e REGRA 42 "Gate de FRESCOR DOUTRINÁRIO, com catraca" `:3961`.
- **Estrutural (auto-por-construção)**: registry `.claude/validation/automation-ladder-registry.txt` (inventory-regen, backlog-project-regen, plugin-assemble, graph-map-console-regen, lint-count-autofix, diary-index-regen, kg-radar-verdict).
- **Drive AUTOMATE**: `.claude/validation/drive-automate.sh` (paradas duras como predicado; merge desligado por padrão).

## 3. Níveis que já existem

| Escada | Degraus | Onde |
|---|---|---|
| Autonomia por classe de ação | HUMAN → STRUCTURAL → MONITORED → DYNAMIC → AUTO (teto desenhado, gated) → MOAT (nunca) | `docs/knowledge-base/concepts/graduated-automation-ladder.md:34-42`; registry `.claude/validation/automation-ladder-registry.txt` (gate `ladder-integrity-check.sh`: reprova classe que subiu sem prova de promoção) |
| Estado medido do registry | 7 STRUCTURAL; 1 MONITORED (`regulated-adopter-correct-to-core`); 2 MOAT (`site-vps-deploy`, `bridge-deploy`); nenhum AUTO | idem (grep por degrau) |
| Runtime de condução de fios | Audit → Automate → Moat, com **3 pré-condições duras** para o AUTOMATE (enabler git-nativo + path-allowlist mecânica + política 100% mecânica) | `docs/analysis/onion-adr-autonomous-thread-runtime-2026-07.md`; `docs/evolution/research/autonomous-thread-runtime-2026-07/` |
| /meta:drive | AUDIT (PR verde sozinho, merge humano em lote) · AUTOMATE (`--automate`, merge só com `--merge` explícito); selo `D_AUTO_DRIVE_DEGRAU_AUTOMATE` (2026-10-12, «Forjar com as objeções») | `.claude/commands/meta/drive.md:19-23,41-63`; nó em `docs/evolution/research/auto-drive-2026-10/auto-drive-2026-10.kg.yaml:29` |
| Camadas de liberação (linha INTAKE autônomo × EXECUÇÃO gated) | camadas 0-6 intake (transporte, parse, trust, replay, timestamp, SSRF, JWS); guarda gated; 7 accept (humano); 8 apply | `docs/knowledge-base/concepts/authorization-layers-intake-vs-execution.md:39-58`; espectro A2A em 4 faixas (Automático / GATED-humano / GATED-com-degradação / PROIBIDO) em `graduated-automation-ladder.md:85-92` |
| Esteira de promoção (maturação de ideia → artefato) | `docs/knowledge-base/concepts/onion-promotion-ladder.md:27` | |
| Gravidade de regra do lint | HARD vs SOFT, "HARD só para o novo, baseline só encolhe" (catraca) | `graduated-automation-ladder.md:78-83`; REGRAS 29/42 |
| Modelos de trabalho | W1-W7; W7 🔒 rascunho-only sob necessidade nomeada | ADR work-models `:81` |
| Ideia de hoje do maestro | `D_SEAL_CH_CLAUDE_PEERS_PARK_1111` (`docs/onion/graph/curation-verdicts-core-seal-2026-11.kg.yaml:174`): «Parquear, com a ideia de níveis automático e não automático» (resposta livre, label: "níveis de canal, com o que é automático e o que pede ok separados"). É só decisão de parquear; não há desenho de níveis ainda. A escada de camadas A2A acima é o precursor natural. | |
| Classificação no kg-ssot | não achei "níveis de classificação" de automação; o que há é a escada de status/confiança dos nós (open/confirmed, method `testimony`/`derived`) e a classe de método "derived: runtime capture" | `kg_capture.py` docstring; não aprofundado |

## 4. kg-ssot (HEAD 3083a45b, via git show)

- **Captura automática (`kg_capture`)**: `tools/kg_capture.py` lê rastro PROV-JSON ou traduz transcript de harness e **PROPÕE nós `open`**, ligados por TRACES_TO às entidades do rastro. Regras seladas (`D_CAPTURE_CONTRACT_SHAPE`): nada nasce `confirmed` nem com `verified_at`, o selo é de quem mede depois; method "derived: runtime capture". **Fora da release** até o spike de valor (`Q_CAPTURE_VALUE_SPIKE`) decidir (`D_EPIC_10_NEXT_1012`). Nó: `A_KG_CAPTURE_ADAPTER` em `docs/onion/graph/kg-ssot-product.kg.yaml:1329` (medido: 140 propostas open sobre PROV-JSON de terceiro; 95 com descrição cortada); épico no `:1272`. Revisões: `docs/evolution/review/feat-kg-capture-adapter.md`, `feat-capture-spike.md`. Moral: "a captura propõe, o contrato sela".
- **Gate com catraca**: `tools/kg_gate.py` (grafos do adotante contra o contrato, catraca POR GRAFO: `failing` herdado nomeado por caminho, dívida SHOULD só pode cair; rc 1 reprova grafo novo ou piora) e `tools/kg_ratchet.py` (E5: suíte, core no MUST, core_debt SHOULD; base em `docs/onion/measurements/ratchet.json`; `--update` recusa regressão sem `--accept-regression "<motivo>"`).
- **Execução contínua**: `.github/workflows/conformance.yml` e `onion-validate.yml` (grep de `schedule|cron` só devolveu o gatilho `on:` de linha 20; não confirmei se há cron). O que a KB do kg-ssot diz de cron é **condicional**: `behavior-over-declaration.md:119,236` descreve um verifier que "compara o pin corrente contra o último release, em cron semanal — nunca [latest]" como exemplo de padrão, e `decision-snapshot-retention.md:86` deixa cron de arquivamento ao projeto adotante.
- **Frescor**: `/meta:kg-freshness` (fila determinística do `kg-radar.sh --freshness-tsv`, worker só propõe, maestro sela), `meta.review_after` (REGRA 67), spec `revisit.schema.json`, `due.schema.json` no kg-ssot.

## 5. Tensões: onde a regra já foi relaxada ou contestada

1. **O evolve nunca foi vedado a relógio.** `docs/evolution/research/medidores-silenciosos-2026-10/medidores-silenciosos-2026-10.kg.yaml:114` (`Q_GATILHO_DO_EVOLVE_QUAL_E`): a 1ª redação o proibia citando W7 e isso foi **invenção corrigida** (diário `.claude/diary/2026-10-02-quatro-decisoes-seladas-e-tres-guardas-com-defeito-datado.md:76`). Texto vigente: `.claude/commands/common/prompts/evolve-doctrine.md:66` ("Relógio/cron não é vedado ao evolve — ele é read-only; o MOAT W7 escopa o driver que executa") e `.claude/validation/evolve-staleness-check.sh:29-33` (o refutador de 2026-08-31 chamou `schedule`/`loop` sobre o evolve read-only de "resposta proporcional"; "a escolha entre avisar e agendar é do maestro"). O W7 escopa **quem executa**, não quem lê e propõe.
2. **CI já roda por cron** (`onion-selftest.yml:49-53`), então "nunca cron" na prática significa "o agente Onion não se agenda", não "nada na casa roda por relógio".
3. **O próprio ADR deixa a porta aberta** (`:53-55`): W7 reabre com necessidade nomeada, em forma rascunho-only. A proposta do adotante (logs, anomalias, checkpoints de auditoria, custo de nuvem) precisa **nomear a necessidade que o lazy-por-sessão não cobre** para usar esse gatilho.
4. **Vendor mudou o chão**: skills `schedule` e `loop` existem na plataforma; `docs/evolution/research/radar-E3-2026-11-10-r24/radar-E3-2026-11-10-r24.kg.yaml:246` (`E_LOOP_AUTOPACED_TERMINA_SEM_REAGENDAR_1110`): o CC 2.1.319 mudou o `/loop` autopaced e "o maestro já usou o /loop assim em orquestração longa". Git grep do nó: o `/loop` no core só aparece como proibição de auto-início.
5. **Canal vivo**: `canal-vivo-sessoes-2026-10.kg.yaml:275`: canal Slack/Teams "não roda headless nem agendado — exige humano presente" (limite da plataforma, reforça lazy-por-sessão para canais).
6. **Decisão do maestro de 2026-11-06 sobre "Cards agendados"** (`docs/onion/graph/comms-stable-2026-11.kg.yaml:93`): foi **descartada** (escolhidas «Delegar deploy do bridge» e «Push + seu ! rápido»). Evidência de que agendamento foi oferecido e recusado recentemente em outro contexto.
7. **Agentes do próprio Onion estão vetados de agendar** (`pretooluse-moat-gate.sh:220`): se o maestro mudar a regra, a guarda de exit 2 também tem de mudar (e ela é "conformidade, não fronteira de segurança", per CLAUDE.md).

## Tabela "o que temos"

| Mecanismo | Gatilho | Quem aprova | Onde mora |
|---|---|---|---|
| Hooks SessionStart/UserPromptSubmit (inbox ⏰/📬, currency, beacon, scans) | abrir sessão / enviar prompt (lazy) | ninguém (só avisa/mede) | `.claude/settings.json:96,138`; `.claude/hooks/*` |
| Veto PreToolUse exit 2 (env, main, merge, MOAT, relógio, provider-api, plugin/memory/adopter) | tool call | ninguém; maestro roda por `!` | `.claude/settings.json:252-336`; `pretooluse-moat-gate.sh:220` |
| CI selftest diário | cron 04:17 UTC | ninguém (relatório) | `.github/workflows/onion-selftest.yml:49-53` |
| Campainha (doorbell) | sinal novo no inbox/fila | humano dá ack | MCP doorbell; `.claude/utils/co-evolution/doorbell-state.py` |
| Fila A2A | sinal verificado | humano aceita (`a2a-accept.sh`) | `ops/a2a-queue-live.sh` |
| Lease de carga | chamada de passo pesado | maestro muda a régua | `ops/load-lease.sh`, `load-lease.conf` |
| Radar de vencimento (REGRAS 62/65/67/85/97) | lint (pre-commit/CI) | maestro dispara a rodada | `lint-artifacts.sh:1520,2792,5067,5203`; `evolve-staleness-check.sh` |
| Catracas (baseline que só encolhe) | lint | maestro (`--update` com motivo) | `.claude/validation/*-baseline.txt`; REGRAS 29/42 |
| Escada por classe (HUMAN..MOAT) e seu gate | edição do registry / lint | maestro (prova de promoção) | `automation-ladder-registry.txt`; `ladder-integrity-check.sh` |
| /meta:drive AUDIT / AUTOMATE | maestro invoca | merge só humano (ou `--merge` explícito) | `.claude/commands/meta/drive.md`; `drive-automate.sh` |
| Estrutural (regen de inventory, backlog, índices) | lint --fix / comando | ninguém (derivação) | registry linhas STRUCTURAL |
| kg_capture (propõe nós open) | rodado à mão, fora da release | quem mede/lê sela | kg-ssot `tools/kg_capture.py`; `A_KG_CAPTURE_ADAPTER` |
| kg_gate / kg_ratchet | CI do adotante | maestro (`--accept-regression`) | kg-ssot `tools/kg_gate.py`, `tools/kg_ratchet.py` |
| /meta:kg-freshness, review_after | maestro invoca; REGRA 67 avisa | maestro sela | `.claude/commands/meta/kg-freshness.md` |
| W7 rascunho-only agendado | **não existe** (porta de reabertura) | maestro, com necessidade nomeada | ADR work-models `:53-55,81` |

## Lacunas honestas

- Não li o ADR `docs/analysis/onion-adr-autonomous-thread-runtime-2026-07.md` por inteiro (só via KB que o sintetiza).
- Não confirmei `schedule:` nos workflows do kg-ssot.
- Níveis de classificação do kg-ssot: não achei escada própria de automação; só status/method.
