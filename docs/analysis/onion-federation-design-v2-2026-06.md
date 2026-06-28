# 🧅 Onion Federation v2 — Design + Backlog (Topologia Peer com Ledger Git)

> **Status:** efêmero / forward-looking (segue [analysis/README.md](README.md)) — **design e backlog** da capacidade Federation, agora na **topologia peer**. Pronto para a próxima `/meta:evolve` (ou execução manual faseada) consumir. Conclusões duradouras migram para a KB `multi-repo-federation.md` e a meta-spec do formato de contrato (criadas na execução).
>
> **Data:** 2026-06-14 · **Supersede:** onion-federation-design-2026-06.md (v1, topologia hub — removido no #53) · **Racional do pivô:** [onion-federation-design-review-2026-06.md](onion-federation-design-review-2026-06.md) (review adversarial, 24/36 achados) + decisão do usuário (topologia peer + comunicação simplificada).

---

## 1. Context — o pedido e o pivô

**Capacidade desejada:** coordenar mudanças entre múltiplos repositórios sem quebrar integrações — "ajustes em integrações que **não podem quebrar** o que está funcionando, com garantia de sucesso, **monitorável e testável**" — tendo o **humano como maestro**.

**v1 (hub) — o que era:** um orquestrador **único** operando sobre N diretórios de outros repos (fan-out por subagente-especialista por membro). Doc: v1 (removido no #53).

**Por que pivotamos (review adversarial de 42 agents):**
- **SA-3 (load-bearing):** o hub repousa num **spike não-verificado** — uma sessão Claude Code operar sobre o dir de outro repo **como raiz de subagente**. Se falhar, as fases cross-repo colapsam.
- **SA-1 (estrutural):** o hub criava estruturas que violam meta-specs L0 (`.claude/federation/`, novas categorias de comando/agente).

**v2 (peer) — o que é (decidido com o usuário):** cada repo mantém seu **Onion soberano e independente**; a comunicação é **simplificada e assíncrona** via um **ledger git compartilhado**; **você é o maestro** que leva decisões entre instâncias.

### Comparação hub × peer

| Dimensão | v1 hub | v2 peer |
|---|---|---|
| Quem conhece o repo-membro | orquestrador, por docs reverse-consolidated (2ª mão, lossy) | o Onion que **vive** no repo (1ª mão) |
| Mecanismo cross-repo | 1 sessão opera N dirs alheios (**spike SA-3**) | cada Onion opera só o **próprio** repo (modo nativo comprovado) |
| Onde vivem manifesto/contratos | `.claude/federation/` (**viola SA-1**) | ledger git externo (dissolve SA-1) |
| Coordenação | hub automatiza (mas atomicidade multi-repo é impossível no GitHub) | **humano-maestro** explícito + contratos |
| "Defende seus interesses" | subagente-expert do hub | o repo dono valida **em casa** |
| Risco principal | SA-3 não-validado | nenhum spike load-bearing (ledger = working dir adicional) |

> **O que NÃO mudou:** a **camada de contrato/segurança** (o coração de "não pode quebrar"). Ela só foi **realocada** para onde é mais forte — a validação roda no repo que é dono do código.

---

## 2. Guardrails de identidade (NÃO violar)

A visão "instâncias vivas autônomas conversando em tempo real" beira o que foi **formalmente abandonado em 2026-05-18** (CLI standalone, multi-IDE, `.onion/`, `packages/`, aprendizado contínuo — ver [onion-review-2026-05.md](onion-review-2026-05.md) §4). O design v2 é **Claude Code-nativo**:

- ✅ Comandos + skills + agentes + SDAAL + git como substrato. ❌ Nenhum runtime/CLI standalone, `.onion/`, `packages/`, multi-IDE.
- ✅ Orquestração em skill/comando, nunca em agente. ❌ `agents/* → commands/*`.
- ✅ **"Cada Onion defende seus interesses"** = o Onion **dono do repo** valida localmente as mudanças de contrato que o afetam (conhecimento de 1ª mão). Não é autonomia competitiva nem negociação IA-IA.
- ❌ **Linha vermelha:** instâncias vivas conversando em **tempo real** (A2A / MCP como runtime distribuído) — beira o abandonado. Fica como Fase 5 premium/futura, fora do MVP.
- ✅ Cada arquivo SDAAL-like ≤ 400 linhas (rever a régua p/ adapters ricos — review #8). Toda mudança em metaspec/estrutura passa pelo `@metaspec-gate-keeper`.

> **Onde fica a linha (do review de identidade):** instalar Onion em vários repos + humano coordenando + compartilhar contratos versionados via git = **permitido**. A2A automático entre instâncias + MCP como runtime de orquestração distribuída = **abandonado**. O v2 fica inteiramente do lado permitido.

---

## 3. Modelo mental — peer com ledger git

```
  REPO A (Onion soberano)                         REPO B (Onion soberano)
   produz contrato C                               consome contrato C
   você muda a API X                               você abre sessão no B
   Onion-A valida em casa                          Onion-B lê a caixa, valida em casa
        │   publica mudança                              ▲  lê inbox + valida local
        └──────────────►  LEDGER GIT (federation spine)  ─┘
                          ├─ members.yaml        (manifesto — quem está na federação)
                          ├─ contracts/<C>.md    (SSOT versionada, semver, tests+fixtures)
                          └─ CHANGELOG.md         (caixa de correio append-only)
        montado em cada membro como ADDITIONAL WORKING DIRECTORY (nativo Claude Code)

   VOCÊ = maestro: leva a decisão de A p/ B. Cada Onion defende SEU repo validando em casa.
   Sem servidor, sem conexão viva, sem IA-fala-IA. Só git + arquivos + sessões.
```

**Comunicação simplificada = assíncrona, não tempo real.** Duas sessões Claude Code em repos diferentes não têm canal nativo de conversa viva; montar isso é runtime distribuído (abandonado). A "comunicação" é, então, **e-mail versionado entre repos**: cada Onion **publica** mudanças de contrato no ledger e **lê a caixa** quando começa a trabalhar. O Claude Code já tem todas as peças (git, contratos Markdown estilo SDAAL, sessões como estado).

### Onde o ledger vive

O ledger é **sempre seu próprio repo git** ("federation spine"), montado em cada membro como **additional working directory** (o ambiente Claude Code já roda com vários working dirs). É **neutro** — não pertence a nenhum membro (submódulo é dor de manutenção; branch órfã acopla o spine a um membro). O **remote é opcional**: local-only para solo/mesma-máquina; com remote (GitHub/GitLab) para time/distribuído — dá pra começar local e adicionar remote depois sem reescrever nada.

> **Padrão jun/2026:** isto espelha o **"contract/schema registry repo"** — a forma mainstream de compartilhar contratos de API/evento entre repos (repo dedicado, versionado, releases semver, consumidores fazem pin). O ledger do Onion = esse registry + uma caixa de correio (CHANGELOG append-only).
>
> **Por que dispensa o spike SA-3:** ler/escrever uma pasta adicional a partir da sessão é trivial e nativo. O que era arriscado no hub era operar um repo **alheio** como **raiz de subagente** — coisa que aqui simplesmente não existe.

---

## 4. Componentes — onde vivem + reuso

| Componente | Onde vive | Reuso / observação |
|---|---|---|
| **Ledger (spine)** | repo git dedicado; montado como working dir adicional | git puro; padrão schema-registry |
| **Manifesto** `members.yaml` | **no ledger** (não `.claude/federation/`) | dissolve review SA-1/#1; campos: `id` estável (sobrevive a rename), `name`, `path`, `remote`, `role` producer/consumer/lib (review #24) |
| **Formato de contrato** | `contracts/<C>.md` no ledger | padrão SDAAL (interface/types/semver/producer↔consumers) **+ campos obrigatórios `tests:` e fixtures de payload** (review #4, #14) |
| **Caixa de correio** | `CHANGELOG.md` append-only no ledger | convenção nova, mínima; cada entrada datada referencia o contrato + versão |
| **Comandos publish/check** | `meta/` namespace (`/meta:federation-*`) | **não** nova categoria — dissolve SA-1/#2; precedente `/meta:orchestrate`, `/meta:evolve`, `/meta:inventory` |
| **Validação local (o "veto")** | Onion do repo dono | `MemberExpertSchema` `{approved, blocked_contracts[], required_migrations[], reasoning}`; ausência de output = veto (**fail-safe**, review #5) |
| **PRs coordenados + rollback** | forge adapter, por repo | `.claude/utils/forge/`; ordem de merge + protocolo de rollback (review #12, #15) |
| **Monitor / status** | `/meta:federation-status` | lê ledger + forge CI por membro; detecta **contract-drift** e commit fora do fluxo (review #16) |
| **KB conceitual** | `docs/knowledge-base/concepts/multi-repo-federation.md` | enquadra como instância de SDAAL + spec-as-code (criada na execução) |

---

## 5. Máquina de segurança realocada ("não pode quebrar", monitorável, testável)

O núcleo do pedido. As cinco camadas continuam, mas a validação **migra para quem é dono do código** — mais forte que no hub:

1. **Contrato de integração** = SSOT do que não pode quebrar (spec-as-code, versionado no ledger, semver).
2. **Contract-tests** vivem no repo **producer** e rodam no **CI dele**. O formato de contrato exige campo `tests:` (paths) — **contrato sem teste correspondente = violação blocker** (review #4). Sem isso o gate é promessa, não gate.
3. **Contrato comportamental, não só sintático** — o formato exige ≥1 **fixture de payload** por operação; o juiz/validação revisa mudança de *significado* com mesma assinatura (review #14).
4. **Validação local do consumer (o "veto" de 1ª mão)** — ao ver mudança no inbox, o Onion do consumer valida **em casa** contra o contrato e emite `MemberExpertSchema`; `approved:false` (ou output ausente) bloqueia. É o sentido forte de "defende seus interesses".
5. **Coordenação + rollback (você, maestro)** — PRs coordenados por repo (forge), ordem de merge (producer-compatível primeiro), e **Rollback Protocol** explícito (trigger, ordem inversa, falha parcial → gate humano, pin de versão de contrato — review #15). `/meta:federation-status` monitora drift (review #16).

---

## 6. Workflow do maestro (human-in-the-loop explícito)

Checkpoints humanos são de primeira classe (review #21), não exceção:

```
1. você muda algo no PRODUCER (repo A)              ← sessão normal, Onion soberano de A
2. /meta:federation-publish                          ← grava contract bump + entrada no CHANGELOG do ledger
   └─ checkpoint: confirmar escopo da mudança de contrato
3. (em cada CONSUMER) /meta:federation-check         ← lê inbox, valida em casa, emite veredito
   └─ se algum veredito = breaking → você decide a migração
4. PRs coordenados (forge, 1 por repo), linkados
   └─ checkpoint: revisar PRs antes de abrir
5. ordem de merge: producer-compatível primeiro; consumers depois (CI verde gate)
6. rollback coordenado se algo quebrar (ordem inversa + pin de contrato)
```

Você é o barramento entre as instâncias — explícito e auditável, em vez de um hub que finge automatizar coordenação que o GitHub não permite (merge atômico multi-repo não existe).

---

## 7. Backlog faseado (risco crescente; cada fase = PR atômico)

**Fase 0 — Spikes + alinhamento de meta-spec (GATE de tudo).**
(a) Decidir placement final (`meta/` vs categoria nova) e obter veredito do `@metaspec-gate-keeper` **antes do primeiro arquivo** (review SA-1).
(b) Spike go/no-go: validar o padrão **ledger-como-working-dir-adicional** (read/write + `git` no dir do ledger a partir da sessão de um membro). Muito mais leve que o SA-3 do hub.
*Aceite:* veredito do gate-keeper + prova de leitura/escrita no ledger documentada como KB em `docs/knowledge-base/platforms/`.

**Fase 1 — Formato de contrato + bootstrap do ledger (MVP).**
Define o formato de contrato (spec-as-code validável pelo gate-keeper, com `tests:`+fixtures obrigatórios). Bootstrap do ledger (repo dedicado: `members.yaml`, `contracts/`, `CHANGELOG.md`). Comando para **registrar/validar** um contrato localmente em UM repo.
*Aceite:* um contrato versionado existe p/ ≥1 integração real; o gate-keeper valida o formato; há um teste que falha se o contrato quebrar; **tudo testável num repo só** (o "átomo" da federação).

**Fase 2 — Publish + Check (a comunicação simplificada).**
`/meta:federation-publish` (producer escreve bump de contrato + entrada no CHANGELOG). `/meta:federation-check` (consumer lê o inbox, valida em casa, reporta quebra com `MemberExpertSchema` fail-safe).
*Aceite:* mudar um contrato no repo A e, no repo B, o `check` detectar e validar o impacto; ausência de output válido = veto.

**Fase 3 — Mudança cross-repo conduzida (contract-safe).**
Fluxo do maestro completo (§6): change → publish → checks → PRs coordenados → ordem de merge → rollback. Monitor `/meta:federation-status` (CI por membro + contract-drift).
*Aceite:* mudança atravessando ≥2 repos aplicada sem quebrar contratos (testes verdes em todos), PRs linkados e reversíveis; tentativa incompatível bloqueada com mensagem acionável; rollback coordenado restaura o estado.

**Fase 4 — (opcional) Aceleração MCP read-only.**
Exposição opcional de contratos via MCP resource p/ consulta sob demanda (API/arquivo-first, MCP **opcional** — doutrina SDAAL). Não é pré-requisito de nada; o ledger continua a SSOT.

**Fase 5 — (premium/futuro, FORA DE ESCOPO) Instâncias vivas A2A.**
A fronteira abandonada; exige decisão de identidade própria. Só costura/flag; não implementar sem nova aprovação.

---

## 8. Achados da review v1 — como o v2 os endereça

Os **24 achados confirmados** da [review](onion-federation-design-review-2026-06.md):

| Achado (review) | Status no v2 |
|---|---|
| **SA-1** #1,#2,#3,#7,#9,#10,#18 (viola meta-spec L0) | ✅ **Dissolvido em grande parte** — manifesto/contratos no ledger externo; comandos em `meta/`. Resíduo (se houver) vai à **Fase 0** com gate-keeper, não nota de rodapé |
| **SA-3** #11,#3 (spike cross-dir load-bearing) | ✅ **De-riscado** — ledger é working dir adicional (trivial), não repo alheio como raiz de subagente. Spike da Fase 0 é muito mais leve |
| **SA-2** #4 (contract-tests sem garantia) | ✅ Campo `tests:` obrigatório + lint "sem teste = blocker" (§5.2) |
| **SA-2** #5 (veto sem schema/determinismo) | ✅ `MemberExpertSchema` fail-safe (§4, §5.4) |
| **SA-2** #14 (breaking change só sintático) | ✅ Fixtures de payload obrigatórias = contrato comportamental (§5.3) |
| **SA-2** #15 (rollback sem protocolo) | ✅ Rollback Protocol explícito (§5.5, Fase 3) |
| **SA-2** #16 (monitor cego a drift) | ✅ `/meta:federation-status` com contract-drift (§4, Fase 3) |
| #6 (reverse-consolidate cai no hub, não no membro) | ✅ **N/A no peer** — não há adoção cross-dir; cada Onion já vive no seu repo |
| #12 (PRs sem atomicidade) | ✅ Aceito explicitamente: humano-maestro + ordem de merge (§6); atomicidade multi-repo não existe no GitHub |
| #13 (merge de `.claude/` legado) | ✅ **N/A no peer** — sem bootstrap-adopt cross-dir; cada repo adota Onion pelo fluxo normal |
| #17 (`/meta:evolve` não é reusável como scan) | ✅ v2 não reusa evolve como scan; usa padrão orchestrator-worker só onde couber |
| #8 (guardrail "≤400 linhas" já violado) | 🟡 Reconhecido (§2) — rever a régua p/ adapters ricos na execução |
| #19 (schema de manifesto: débito F1→F2) | ✅ `members.yaml` com schema estável mínimo desde a Fase 1 |
| #20 (membros não-Onion / stacks heterogêneos) | 🟡 **Endereçar na Fase 1** — classificar modos: full-member / observe-only / external |
| #21 (conflito entre experts + HITL) | ✅ Maestro humano + checkpoints explícitos (§6) |
| #22 (budget de token de orquestração) | 🟡 **Aberto** — menor no peer (sem orquestração cross-dir); modelar na Fase 3 se necessário |
| #23 (F3 conflaciona spike + produto) | ✅ Spike isolado na Fase 0; produto nas fases seguintes |
| #24 (concorrência + naming collision) | ✅ `id` estável no manifesto + (futuro) lock no ledger |

**Legenda:** ✅ resolvido/endereçado · 🟡 parcial/aberto · N/A não se aplica no peer.

---

## 9. Onde isto entra na evolução

Ao executar: primeiro a **Fase 0** (gate-keeper decide placement + spike do ledger), depois a KB `multi-repo-federation.md` e a meta-spec do **formato de contrato** (Fase 1) — para o `@metaspec-gate-keeper` ter régua. A Fase 1 é o átomo concreto e independente (um contrato + ledger, testável num repo só); as demais empilham sobre ela. Este doc é o backlog que a próxima `/meta:evolve` (ou execução manual faseada) consome.
