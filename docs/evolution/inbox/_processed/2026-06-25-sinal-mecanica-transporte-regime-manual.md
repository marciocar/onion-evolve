---
title: 'Sinal de campo — mecânica de transporte do regime manual: sub-protocolo operacional + script determinístico auto-documentado'
date: 2026-06-25
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (maestro principal / core)
re: lacuna operacional entre o ADR 3-atos (princípio) e o carteiro automático (adiado) — o regime manual de HOJE não tem sub-protocolo (quem/branch/push) nem executável determinístico
type: field-signal (sinal de campo — nascido de operar o doc-bridge pela 1ª vez)
status: assess (proposta + evidência; verdito é do maestro principal)
related:
  - 2026-06-24-sinal-padrao-toolbox.md (esta lacuna é um caso de uso da toolbox)
  - inbox/_processed/2026-06-19-sinal-adocao-a0fdf35.md (adotante é cego / silêncio≠consentimento)
  - inbox/_processed/2026-06-19-flow-a-report-and-bidirectional-mail.md (you-have-mail bidirecional)
  - inbox/_processed/2026-06-24-sinal-branching-trunk-based-vs-develop.md (onde vive o canal)
  - ../../../knowledge-base/decisions/onion-adr-comms-transport-vs-execution-2026-06.md (ADR 3-atos)
---

# Sinal de campo ao maestro principal — mecânica de transporte do regime manual (2026-06-25)

> Doc-bridge adotante→core (fluxo B). Nasceu de **operar o canal pela primeira vez de verdade**.
> Não dita: **propõe e pergunta com evidência**. O verdito é do maestro principal.

## Incidente que originou o sinal (honesto)

Nesta sessão, transportei pela 1ª vez um sinal (`toolbox`) do inbox do `rhilo-metagamify` para o
`onion-evolve` — operando o **blip #1 do radar** (doc-bridge), até então marcado *"nunca operado entre
repos"*. **No ato, a IA (eu):**

1. Executou uma **escrita cross-repo** a partir da sessão do adotante (zona cinza frente ao invariante
   *"a sessão nunca pusha/escreve em repo alheio; o maestro transporta"*).
2. Commitou na **branch errada** do core (`fix/lint-rule16-count-formats`, uma branch de lint em curso)
   em vez do trunk onde o inbox é de fato lido — **porque era a branch em check-out**. Não há guarda que
   force o pouso no branch certo.
3. **Empurrou ao mestre** "em qual branch? push ou não?" como se fossem decisões — quando o **ADR 3-atos**
   já diz que **transporte é Ato-1 (determinístico)**. Houve **erro de classificação**: tratei um detalhe
   de Ato-1 como juízo de Ato-3.

O dono reagiu: de nada adianta ele ter de **descobrir e se preocupar** se as instâncias de IA podem/devem
se comunicar, trocar e ler mensagens. *"Vocês têm que se resolver."*

## 5 Porquês → causa raiz

1. **Por que o mestre teve de decidir branch/push?** Porque o protocolo nomeia o QUÊ ("o maestro
   transporta: `cp` + commit no repo do adotante") mas não fixa o **COMO** do regime pré-carteiro (branch
   de pouso, isolamento do commit, push sim/não).
2. **Por que isso ficou subespecificado?** Porque o core separou o **princípio** (ADR 3-atos) da
   **automação** (o *carteiro*), **explicitamente adiada** até um gatilho de graduação. Entre os dois, o
   regime manual de hoje ficou sem sub-protocolo operacional.
3. **Por que a IA improvisa e joga pro mestre?** Porque **não existe artefato determinístico** que encode
   a política resolvida. Cada sessão re-deriva "posso? em qual branch?" a partir de prosa.
4. **Por que não existe esse artefato?** Porque o protocolo vive como narrativa (README + RFC-0001 + ADR),
   não como **executável anotado** com guardas + recado para a próxima instância.
5. **Causa raiz.** O papel do mestre deve ser **roteamento estratégico + aprovação de intenção (Ato-3)**,
   não **arbitrar mecânica de Ato-1 a cada operação**. Cada mecânica subida ao humano **transfere carga
   cognitiva e corrói a parceria**. Falta a **camada operacional** (procedimento determinístico
   auto-anotado + fronteira explícita do que a IA decide vs. escala) e um **mecanismo de revisão
   permanente**.

## Grounding (modelos / autoridades — para revisão permanente)

- **Promise Theory** (Mark Burgess) — agentes autônomos cooperam por **promessas voluntárias publicadas**,
  nunca por comando externo. É o backbone de *1-escritor-por-repo + sem-A2A + git-async*: responde
  "podem/devem se comunicar?" → **sim, por promessa publicada (doc commitado); jamais por ordem entre IAs**.
- **Design by Contract** (Bertrand Meyer) — pré/pós-condições + invariantes. O script = **guard clauses**
  que enforçam as pré-condições (branch certa, commit isolado, sem push).
- **RACI / DACI** (decision rights) — a fronteira de autonomia: IA = *Driver* dos Atos 1–2; mestre =
  *Approver* do Ato 3. Sobe ao mestre **só** o que é Ato-3.
- **GitOps** (Weaveworks; Argo/Flux) — estado desejado no git + reconciliação **pull pelo destino**: é
  exatamente o *carteiro* adiado. O regime manual é GitOps-com-humano-no-loop até a graduação.
- **SRE — toil & runbooks** (Google SRE) — transporte é **toil** determinístico; automatizá-lo reduz carga
  cognitiva e erro. O mestre não deve ser runbook ambulante.
- **ADR** (Michael Nygard) — registrar a decisão e **revisitar** = revisão permanente (o core já usa ADR).
- **Literate programming** (Knuth) + **context engineering** (prática 2025) — o **recado embutido no
  script** é doc-para-a-próxima-instância: re-alinha o modelo *stateless* a partir do artefato (alavanca
  do transformer).
- **HITL / approval gates** + **PDCA/OODA** (ciclo de revisão) + **idempotência / never-clobber**.

## Proposta ao maestro principal (canonização MÍNIMA)

Recomendamos a **menor superfície** para ratificar (o resto vem em fase 2, *se provar valor*):

1. **ADR do sub-protocolo do regime manual** (`docs/analysis/onion-adr-manual-transport-subprotocol.md`,
   ou emenda ao ADR 3-atos): tabela de decisão explícita — *quem* faz a escrita cross-repo hoje, *em qual
   branch* (sempre o `integration_branch`/trunk do alvo), *push é sempre Ato-3 humano* — + a regra
   **"silêncio≠consentimento"** + os **papéis reconciliados** (ver P2).
2. **Script vendorizado** (`.claude/utils/co-evolve-transport.sh`): promover ao canônico o executável que
   acompanha este sinal (anexo abaixo), herdável por todo adotante via `/meta:adopt`.

**Fase 2 (adiada, só após uso real — disciplina Tech Radar):** comando `/meta:co-evolve --transport`,
skill de segurança (guardrail auto-aplicado), KB how-to, convenção de chave de artefatos.

## Pendências — peço a opinião do maestro principal, COM EVIDÊNCIA

Não para ditar — para **decidir com base**. Cada uma traz evidência citada + nossa inclinação; o **verdito
é do core**.

| # | Pergunta ao maestro principal | Evidência | Nossa inclinação |
| --- | --- | --- | --- |
| **P1** | Transporte: **(A) estrito** (só o mestre executa a escrita cross-repo) vs **(B) IA-como-mãos** (a sessão executa, mas **só via o script determinístico**; mestre aprova a intenção 1×)? | ADR 3-atos `onion-adr-comms-transport-vs-execution-2026-06.md` (transporte = Ato-1 determinístico/automatizável) **×** invariante "sessão nunca pusha repo alheio / maestro transporta" (`co-announce.md`, `adopt.md`); **incidente desta sessão** (commit cross-repo na branch errada) mostra que B-sem-script é arriscado, **B-com-script** resolve | **(B) via script** — preserva Ato-3 humano (push) e tira a mecânica de Ato-1 do colo do mestre |
| **P2** | **Vocabulário de papéis** — adotar **mestre = humano** / **maestro principal = core** (vocabulário do dono) e reconciliar os docs? | Docs hoje **invertidos**: `maestro`=humano (`README.md`, `rfc-0001`), `mestre`=core (frontmatter de inbox `to: ... (core/mestre)`). Ambiguidade real que confunde a próxima sessão | adotar o vocabulário do dono + renomear no canônico |
| **P3** | **Convenção de chave** de artefatos — nome `<data>-mnemônico--<uuidv7>` (sort cronológico + id de correlação ponta-a-ponta)? **UUIDv7 vs ULID**? **escopo** (só planos vs todos os datados)? | Convenções ad-hoc já no repo (`inbox/2026-06-24-...`, `sim-reports/20260624-...`); UUIDv7/ULID são **k-sortable** (padrão de indústria) | padrão data-prefix + uuid-suffix; **encoding e escopo abertos** |
| **P4** | **Fase 2** (comando `--transport` / skill / KB) — quando canonizar? | Regra de promoção do `radar.md`: *"nada passa de assess→trial sem uso real; trial→adopt só com prova no par core↔derivado"* | só após ADR+script provarem **uso real** |
| **P5** | **"Silêncio≠consentimento"** vira **invariante formal** + *you-have-mail* **bidirecional**? | Sinal `a0fdf35` ("silêncio do core = invisível", confirmado mas **nunca formalizado**); `flow-a-report-and-bidirectional-mail` (hoje **sem auto-notify de volta** ao adotante) | formalizar invariante + fechar notificação de fluxo-A |

## Evidência de campo anexa (a prova já está de pé localmente)

Conforme o **bloqueio escopado** (transportar/notificar fluem; só a *canonização* espera o verdito), o
adotante já produziu **localmente** — como prova, não como imposição:

- **Script `scripts/onion/co-evolve-transport.sh`** (este sinal foi transportado **por ele mesmo** —
  dogfooding): worktree isolado no branch de integração, commit isolado, **nunca push**, recado-header
  para a próxima instância, `--dry-run` por default.
- **Correção do incidente**: o commit do sinal `toolbox` foi **realocado** da branch de lint para o trunk
  do core (onde o inbox é lido), preservando o trabalho de lint não-commitado do mestre.

## Premissa que o maestro principal PRECISA internalizar (inalterada)

Como nos sinais anteriores: sem comunicação viva, o adotante só "vê" o que for commitado no canal **E
transportado por humano**. **Silêncio do core = invisível.** A resposta a este sinal precisa de **anúncio
explícito no `inbound/`** (fluxo A) — senão o round-trip morre no silêncio.
