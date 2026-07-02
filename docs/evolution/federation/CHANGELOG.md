# 📣 CHANGELOG de co-evolução — anúncios do core aos projetos (fluxo A)

> Log **append-only**. O core registra aqui mudanças do framework **relevantes aos projetos** que o
> adotam (ex.: bumps que pedem `/meta:adopt --update`, fixes que afetam adotantes, breaking changes).
> Cada projeto puxa e decide em casa. Não reescrever entradas (auditoria). Formato por entrada:
>
> `## <AAAA-MM-DD> · <assunto> · <COMPATÍVEL|BREAKING> · alvo: <ids ou "todos">`

---

## 2026-07-02 · Sinal ACEITO: verify-the-read-path-first promovido a padrão do core (ai-strategy + disciplina de frota) · COMPATÍVEL · alvo: rhilo-metagamify

- **Seu sinal `2026-07-01-sinal-verificar-read-path-antes-de-concluir` foi triado e ACEITO** —
  promoção `assess` → `trial` conforme pedido, nas 3 frentes propostas:
  1. **Padrão nomeado**: KB `docs/knowledge-base/agentic-patterns/ai-strategies/verify-read-path-first.md`
     (crédito à instância rhilo; seu caso WRR das duas tabelas é o golden case do antipadrão).
  2. **Contrato de extrator**: disciplina nova na skill `onion-orchestration` — claim de *localização
     de dado* exige **read-path verificado (`arquivo:linha`)** ou nasce hipótese, nunca nó confirmado.
  3. **Checklist de síntese**: divergência de fonte entre workers (ou worker×banco) é **achado**
     (provável split-brain), não ruído.
- **Contexto que valida:** seu padrão é o 3º membro da família doutrinária consolidada em 02/jul —
  *estado declarado ≠ fato verificado* (pin é hipótese → `pin-integrity-check.sh`; working tree livre
  é hipótese → farol de sessão 🕯️; onde-o-dado-vive é hipótese → **o seu**). A KB registra a família.
- **Amarração com o seu KG SDAAL:** claim de localização sem `TRACES_TO {file:line}` do read-path
  fica `confidence` baixa e `status: open` — as duas propostas suas se reforçam.
- **Ação p/ você: nenhuma obrigatória.** Skill + KB chegam vendorizadas no próximo `--update` (junto
  com o farol de sessão deste mesmo dia).

## 2026-07-02 · CORREÇÃO: o anúncio "você JÁ tem o fix --only" estava ERRADO — seu pin era forjado; guard pin-integrity criado · COMPATÍVEL · alvo: rhilo-metagamify

- **Você estava certo, nós erramos.** Seu sinal `2026-07-02-sinal-lint-only-ausente-no-vendor` foi
  verificado em primeira mão no core e **confirmado nos 2 achados**. Retratação + causa raiz:
  - A ancestralidade que anunciamos era verdadeira (`22f30b0`/`2d2dad0` SÃO ancestrais de `a458a0f`) —
    mas a premissa "vendor = pin" era falsa. **O pin `a458a0f` do seu stamp é forjado:** o commit
    `828dd8f7` (30/jun, "restore Onion skeleton + stamp") carimbou o HEAD do core numa branch
    (`rhilo/main`) que só tem o próprio stamp — nenhum arquivo do framework. Não foi um `--update`;
    foi um restore manual pré-`/meta:recover` que "adivinhou" o pin.
  - **Resposta à sua pergunta 1** (o `--update` de 30/06 deveria ter trazido o fix?): não houve
    `--update` em 30/06 — houve o restore acima. Seu vendor real (em `develop`) é core@`aeee056`
    (24/jun, byte-a-byte verificado no canário), anterior ao fix. O fix chega no próximo `--update` real.
  - **Resposta à sua pergunta 2** (qual pin é canônico?): **o da `integration_branch` (`develop`) =
    `aeee056`** — `members.yaml` reconciliado com nota do incidente. Regra nova: pins de outras branches
    não são canônicos, e anúncios do core passam a citar a branch sobre a qual raciocinam.
- **Cura de raiz (não paliativo):** `.claude/validation/pin-integrity-check.sh` — pin é HIPÓTESE:
  verifica existência na história do core + canário byte-a-byte. O guard roda no início do
  `/meta:adopt --update` (pin não confiável → sem early-exit "Já atualizado", sem delta; cópia segura
  completa + re-carimbo). `/meta:recover` v1.1.0 reforça: NUNCA adivinhar pin com HEAD (`unknown` é
  honesto e resolvível). +5 guardas no lint-selftest (modo `pin-integrity`, 100→105), incluindo a
  regressão exata do seu caso. Dogfood: o script delatou seu stamp na 1ª rodada (`canario-divergente`).
- **Ação p/ você:** aguardar o `--update` real (o core vai entregá-lo na sequência — entrega-sem-commit;
  sua sessão commita na `develop`). Ele traz o `--only` de fato, re-carimba com pin verdadeiro,
  restaura `adopted_at: 2026-06-17` e escreve `updated_at`.
- **Método reconhecido:** sua disciplina "verificar o artefato real antes de concluir" pegou o primeiro
  anúncio falso da federação. Virou migalha permanente no diário do core
  (`2026-07-02-forged-pin-false-announcement`) e guarda determinística. O exercício W6 funcionou.

## 2026-07-02 · Sinal ACEITO PARA AVALIAÇÃO: Knowledge Graph SDAAL vira KB CANDIDATA no core; /meta:kg gated até 1º dogfood · COMPATÍVEL · alvo: rhilo-metagamify

- **Seu sinal `2026-07-02-sdaal-knowledge-graph` foi triado e aceito para avaliação.** O conceito foi
  portado ao core como **KB candidata** `docs/knowledge-base/concepts/knowledge-graph-sdaal.md`, com
  crédito explícito à instância rhilo (nascido na auditoria WRR, dogfood real). O que foi portado:
  modelo (nós/arestas tipadas ponderadas, planes DEV↔PROD, peso = impacto × confiança × status), as 3
  saídas (RADAR/RECONCILIAÇÃO/INTEGRIDADE), a governança DEV↔PROD e o anti-whack-a-mole.
- **O comando `/meta:kg` fica GATED até o core dogfoodar o método uma vez** (próxima
  auditoria/investigação longa do core modela seus achados num `.kg.yaml`) — mesma doutrina
  gated-until-trigger de F2-F5: não construir à frente do gatilho.
- **Generalização decidida:** a versão core será **soberana e determinística** (YAML puro, zero
  dependência do seu stack ML) — RADAR/RECONCILIAÇÃO/INTEGRIDADE são computáveis sem embedding;
  similaridade semântica é Fase 2. Sua implementação (`scripts/kg/radar.js`) permanece a referência viva.
- **Convergência que valida o método:** no MESMO dia, o incidente do pin forjado (entrada acima) provou
  sua regra DEV↔PROD na direção oposta — o core concluiu de um *carimbo* (plane DEV) o que só o
  *artefato vivo* (plane PROD) podia afirmar. A KB candidata registra essa evidência cruzada.
- **Ação p/ você: nenhuma obrigatória.** Continue dogfoodando o `.kg.yaml` no WRR; sinais de evolução
  (reconciliação por embedding, novos node_types) são bem-vindos no canal upstream.

## 2026-07-02 · Eixo E (topologias de sessão W1-W7) + responder-gated + gatilho de reflexão ⏰ · COMPATÍVEL · alvo: rhilo-metagamify

- **Novo eixo doutrinário — "quem trabalha onde, a partir de onde":** o ADR
  [`onion-adr-work-models-session-topologies-2026-07`](../../analysis/onion-adr-work-models-session-topologies-2026-07.md)
  institui o **Eixo E** (7 topologias: W1 source-por-path · W2 sessão-do-alvo · W3 duas-sessões-mesmo-repo ·
  W4 par local · W5 remoto · **W6 responder-gated** · W7 agendada 🔴 rejeitada como base). Decisões
  fundamentadas em **pesquisa verificada** (deep-research, 24 claims 3-votos): cron vendor = serviço vivo +
  autonomia-default → incompatível com o fluxo soberano; o padrão validado é **trigger lazy por sessão**.
- **O que muda no seu vendor (próximo `--update`):**
  - **Hook "you have mail" ganha o sinal ⏰:** migalhas do diário com `review_after` vencido aparecem no
    boot (gatilho invariável de reflexão). +4 guardas no lint-selftest (modo `mail-hook`).
  - **`/meta:co-evolve` v1.2.0 — Passo 3.5 (responder-gated, W6):** com 📬/📥/⏰ pendente, a sessão
    **propõe o rascunho** (triagem/processamento/re-teste) e **para** para sua confirmação — ato 3 nunca
    auto-executa.
  - **`/meta:diary` v1.1.0 — sub-comando `review`:** migalha vencida é **RE-TESTADA contra evidência
    atual** (válida→novo prazo; inválida→`superseded: true`, nunca apagada; parcial→reescrita). Antídoto
    do risco nº1 documentado (reflexão falsa persistida → erro auto-reforçante).
- **KB atualizada:** `federation-usage-modes.md` agora tem os **cinco eixos** (A-E) + tabela W1-W7 (§1.0).
- **Ação p/ você: nenhuma obrigatória.** Tudo chega vendorizado no próximo `/meta:adopt --update`. Se seu
  diário local tiver migalhas, o ⏰ passa a vigiá-las automaticamente.

## 2026-07-02 · RFC-0003 ACEITA — identidade federada, tiers e trust agora são doutrina (você é T1 hub) · COMPATÍVEL · alvo: rhilo-metagamify

- **A RFC-0003 (identidade federada e inteligência coletiva) saiu de `draft` → `accepted`** (2026-07-02,
  revisão completa: 5 pendências arbitradas — PRs #215/#216/#217, motivadas pela auditoria orquestrada de
  federação `wf_48c138b0-5f6`). O que passa a ser doutrina e **como te afeta como T1 hub**:
  - **Tiers canônicos:** você é `role: hub` (T1) no `members.yaml` do core; `producer/consumer` de membro
    aposentado (o de **contrato** permanece — eixo ortogonal). A reconciliação completa "federação × tipos
    de uso" vive na KB nova `docs/knowledge-base/concepts/federation-usage-modes.md` (chega vendorizada no
    próximo `--update`).
  - **Trust granular agora FUNCIONA:** o bloco `trust:` (can_receive_from/can_advise_to/can_correct_to/
    diary_readable_by/exposes_downstream) estava **inoperante** por bug de parsing (indentação + comentário
    inline) — corrigido + 15 guardas de selftest + flag `--dry-run` (testa sem poluir o trust-log). Seu
    `can_correct_to: []` agora é um bloqueio real, não coincidência.
  - **T2 (sub-adotados): core-driven.** Se você um dia tiver sub-adotados, o onboarding deles roda **via
    core** (maestro + `/meta:adopt`) com `parent: rhilo-metagamify` registrado — você não roda adopt;
    hub-driven adoption é gatilho futuro (1º T2 real).
  - **Roadmap F1-F5 com gates mensuráveis:** diário (F1, o core está dogfoodando — 2/10 entradas),
    personality-sync (F2, híbrido mecânico+maestro), trust peer (F3), síntese coletiva (F4), market-scan
    (F5). Nada disso te pede ação agora.
  - **Semântica de `adopted_at` corrigida:** o `--update` **preserva** a data da 1ª adoção e escreve
    `updated_at`. Seu stamp atual carrega `adopted_at: 2026-06-30` (re-carimbo pré-fix) — o próximo
    `--update` restaura `2026-06-17` (a data real da sua adoção) + `updated_at` corrente.
- **Ação p/ você: nenhuma obrigatória.** No próximo `/meta:adopt --update` chegam vendorizados: a KB
  `federation-usage-modes`, os fixes de validação (`trust-topology-check.sh` + `--dry-run`,
  `onion-version.sh` role-aware) e os 15+3 casos novos do selftest. RFC canônica:
  `docs/evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md` (no core).

## 2026-07-01 · Sinal RESOLVIDO: lint-selftest O(fixtures × repo) — escopo-de-arquivo `--only` (você JÁ tem o fix) · COMPATÍVEL · alvo: rhilo-metagamify

- **Seu sinal de campo foi endereçado** ([inbox 2026-06-24](../inbox/_processed/2026-06-24-sinal-lint-selftest-escala-adotante-grande.md)): o `lint-selftest.sh` levava **~10-17 min** no seu repo porque cada fixture re-rodava o `lint-artifacts.sh` **repo-inteiro** (41s/passada × ~20 fixtures) — O(fixtures × tamanho-do-repo), invisível no core (docs/ pequeno). Exatamente o alvo da sua recomendação "escopo de scan no lint".
- **Fix (PR #180, commit `22f30b0`, 2026-06-27):** `lint-artifacts.sh` ganhou a flag **`--only=<arquivo>`** (wrapper `_find`): cada regra varre **só o arquivo injetado**, preservando a semântica de escopo por regra. O selftest passa `--only="${dst}"` nas invocações → cada fixture roda **O(1 arquivo)** em vez de re-escanear `docs/` inteiro. No core: ~8min → ~30s. No seu repo a projeção é **de ~10-17min para ~1-2min** (o `cp -a docs/` do sandbox permanece — o `inventory.sh` precisa dos números reais — mas o custo dominante, o re-scan por fixture, morreu). Complementado pelo PR #202 (modos core-only pulam gracioso — já anunciado em 2026-06-28).
- **Você JÁ tem o fix:** verificado no core que `22f30b0` e `2d2dad0` são ancestrais de `a458a0fc6b71` — o seu `--update` de 2026-06-30 os trouxe vendorizados. **Nenhuma ação além de re-rodar** `bash .claude/validation/lint-selftest.sh` e conferir o wall-clock. Se a medição real divergir da projeção, é um sinal novo bem-vindo (a sugestão "guard-rail de tempo" do seu sinal segue no radar, não implementada).

## 2026-07-01 · Veredito: "object-led discovery & fitting" vira playbook do catálogo (não skill/comando novo) · COMPATÍVEL · alvo: rhilo-metagamify

- **Sinal de campo do `rhilo-metagamify`:** propôs canonizar o ciclo "promover objeto existente a papel premium" (espelhar → descobrir → vestir → materializar → realimentar), motivado pelo DataTable premium do dashboard WRR construído imperativamente (pedidos sucessivos re-improvisados a cada rodada).
- **Veredito: ACEITO como doutrina, materializado como playbook** — não como ADR-skill isolada nem comando `/onion:promote` dedicado. Aplicando a régua P0-P3 (`onion-adr-toolbox-lifecycle`), o substrato já cobria quase tudo (Capability Contract + SDAAL + catálogo-first do RFC-0002) — a síntese que faltava virou a **6ª entrada de playbook** em `onion-patterns/SKILL.md` §Playbooks ("promover objeto existente a papel premium").
- **Dogfood guiado retroativo** sobre a própria evidência anexada ao sinal (sem tocar o rhilo-app de novo): o gap real estava em **descobrir+vestir não anteciparem o perfil completo** do papel-alvo (emergiu por ~10 pedidos sucessivos em vez de 1 fitting único) — não em "materializar", que já era dirigido e verificado. Doc: [`onion-adr-object-led-discovery-2026-07.md`](../../analysis/onion-adr-object-led-discovery-2026-07.md) (PR #213).
- **Ação p/ adotantes: nenhuma obrigatória.** O playbook vive no core; chega vendorizado via `/meta:adopt --update` (dentro de `onion-patterns/SKILL.md`). Quem quiser aplicar o ciclo já pode usá-lo por analogia — é disciplina em prosa, não automação. Sinal triado em [`../inbox/_processed/2026-06-29-capability-adaptive-object-led-discovery.md`](../inbox/_processed/2026-06-29-capability-adaptive-object-led-discovery.md).

## 2026-06-28 · BREAKING: skill `onion-fleet`→`onion-orchestration` + `/meta:fleet`→`/meta:orchestrate` (migração de vocabulário) · BREAKING · alvo: rhilo-metagamify

- **Migração de vocabulário no core:** os apelidos `frota` (PT) / `fleet` (EN) foram **aposentados** em favor do vocabulário canônico da indústria de orquestração multi-agente — `orquestração` (conceito) / `orchestrator-worker` (padrão) / `workers` (coletivo executor). Decisão fundamentada por pesquisa (3 ângulos + web jul-2026): o canônico é *orchestrator-worker / fan-out-fan-in*; "fleet" é jargão em transição e "frota" era o único termo técnico traduzido. Doc: [onion-orchestration-ontology-2026-06](../../analysis/onion-orchestration-ontology-2026-06.md).
- **O que mudou (afeta você):**
  - **Skill renomeada:** `onion-fleet` → **`onion-orchestration`** (mesma capacidade: reconhece fan-out e autora/dispara Workflow).
  - **Comando renomeado:** `/meta:fleet` → **`/meta:orchestrate`**.
  - **KB renomeada:** `agent-fleet-orchestration.md` → `agent-orchestration.md` (+ 4 ADRs `onion-fleet-*` → `onion-orchestration-*`).
  - **Anti-pattern:** `fleet-orchestrator` → `worker-orchestrator` (a guarda §4.2 / Regra 7 do lint).
  - **Vocabulário:** prosa migrada para `orquestração`/`workers` em todo o core (308 reescritas + de-mão).
- **Por que BREAKING para você:** seu repo tem `onion-fleet` **vendorizado**. Ao rodar `/meta:adopt --update`, o delta troca a skill/comando renomeados. **Ação no alvo:** (1) rodar o `--update` quando oportuno; (2) se você tiver docs/sessões/refs próprias citando `/meta:fleet` ou `onion-fleet`, atualizar para `/meta:orchestrate` / `onion-orchestration` (muscle-memory); (3) o anti-pattern proibido passou a ser `worker-orchestrator` (refletido no lint vendorizado). Sem pressa — o `--update` é idempotente; coordene quando for atualizar o framework.
- **Validação no core:** lint 0/0, selftest 100/0, revisão independente (pegou substituição semântica cega em L0, corrigida), grep-zero limpo. PR #205 MERGED.

## 2026-06-28 · Sinal RESOLVIDO: lint-selftest.sh robusto a adotante (não aborta mais sem plugins/) · COMPATÍVEL · alvo: rhilo-metagamify

- **Seu sinal de campo foi endereçado** ([inbox 2026-06-28](../inbox/_processed/2026-06-28-lint-selftest-aborts-in-adopter-without-plugins.md), relayado via `/meta:co-relay`, PR #202). O `lint-selftest.sh` **abortava com exit 2** no seu repo (sem `plugins/`) — sob `set -e`, um modo **core-only** derrubava o script **antes** do `run_de_identification_selftests` (o de-id do #201) rodar. Você teve que validar o round-trip à mão; agora não precisa mais.
- **Diagnóstico (seu, confirmado):** o harness é **artefato distribuído** com dois contextos — core (tem `plugins/`, `fixtures/`) e adotante (subconjunto). Um `set -e` global tornava o modo mais frágil o **teto de todos**. Não era regressão do #201 — fragilidade estrutural pré-existente que o de-id apenas tornou visível.
- **Fix (PR #202, sua opção (2) + (1) combinadas):**
  1. **Skip gracioso por precondição local** (mesmo idioma do `jq ausente → pulado`): modos core-only auto-reportam `pulado (adotante)` como **PASS** quando o artefato falta — loop de fixtures (sem `manifest`), `assemble-plugin`/`plugins-sync`/`graph` (sem `plugins/` vendorizados; o consumidor **não publica plugins**).
  2. **Rede de segurança `|| true`** nos modos de maquinaria de marketplace: um abort imprevisto **jamais esconde** os modos self-contained seguintes.
- **Strictness do core preservada:** onde `plugins/`/`fixtures/` existem (o core), o skip **nunca dispara** → drift real ainda vira FAIL + exit ≠0. O gate ficou **context-aware, não mais frouxo**.
- **Validado nos dois contextos (dogfood adversarial):** core **100/0 exit 0**; adotante simulado (sem `plugins/` nem `fixtures/`) **47/0 exit 0**, com o **de-id passando** (round-trip, dedupe, determinismo).
- **Ação p/ você:** no próximo `/meta:adopt --update`, o `lint-selftest.sh` corrigido chega vendorizado. A partir daí, o passo pós-update **"rode `lint-selftest.sh`"** conclui com **exit 0** e valida o de-id no harness (sem precisar rodar o `redact-deterministic.sh` à mão). Sem ação obrigatória agora.

## 2026-06-27 · S1 RESOLVIDO: padrão "toolbox" = régua P0-P3 + coesão dos create-* (ciclo ASSESS→TRIAL→ADOPT fechado) · COMPATÍVEL · alvo: rhilo-metagamify

- **Seu sinal S1 (padrão "toolbox") saiu de "triado" para RESOLVIDO** ([inbox 2026-06-24](../inbox/_processed/2026-06-24-sinal-padrao-toolbox.md)). O pedido — um **meio de 1ª classe para classificar procedimentos recorrentes** (script/skill/comando) e gerir seu ciclo de vida — foi escopado, trialado e selado num ciclo completo (ASSESS #181 → TRIAL #183/#184/#185 → ADOPT #186).
- **Veredito do scoping (ASSESS, PR #181, [doc](../../analysis/onion-toolbox-s1-scoping-2026-06.md)):** o "toolbox" **NÃO é infra nova**. É uma **régua de classificação P0-P3 + coesão dos `/meta:create-*`** assentada sobre o substrato que já existe (`inventory.sh` + lint + `context-freshness`). Construir registry/dedup/embedding seria inchaço sem dogfood.
- **O que entrou (vendorizado no próximo `--update`):**
  1. **Régua P0-P3 de classificação** no `onion/SKILL.md` (#184) — o classificador que você pediu: como decidir se um procedimento recorrente vira script (P0, determinístico/controle), comando (P1, juízo/quando), skill (P2, recall) ou ADR (P3, doutrina).
  2. **Passo `inventory-sync` nos `/meta:create-*`** (#183, fragmento `common:prompts:inventory-sync-after-create`) — fecha um **HARD-fail silencioso** que você poderia pegar: criar command/agent/skill/KB sem regenerar a SSOT deixava o repo em falha da **Regra 8** até o CI pegar no PR. Agora "criar" carrega "sincronizar" (mesmo espírito do entrega-sem-commit).
  3. **Outliers de coesão** (#185): `create-task-structure` movido `/meta:`→`/product:` (é task de produto, não artefato Onion); `create-agent-express` ganhou path categorizado; cross-links dos `create-*` fechados (eram assimétricos).
  4. **Doutrina selada** ([ADR onion-adr-toolbox-lifecycle](../../analysis/onion-adr-toolbox-lifecycle-2026-06.md), #186).
- **Deferido conscientemente (gatilho = gate-de-uso, não esquecimento):** `kind/status` no frontmatter, dedup por embedding e registry externo só graduam **quando a régua P0-P3 acumular uso real**. Radar, não roadmap.
- **Conexão com o seu S2:** o `/meta:co-relay` (resolvido ontem) foi o **1º caso concreto** deste padrão e destilou o critério (*procedimento recorrente → script + comando + ADR + gate humano*); a régua P0-P3 agora é o **classificador genérico** desse critério.
- **Ação p/ você:** no próximo `/meta:adopt --update`, a régua + os `create-*` coesos chegam vendorizados. Pode **mover o blip "toolbox" no seu radar → done** (o que você levantou tem resposta canônica agora). Sem ação obrigatória.

## 2026-06-27 · S2 resolvido: /meta:co-relay (transporte upstream entrega-sem-commit) + S1 toolbox triado · COMPATÍVEL · alvo: rhilo-metagamify

- **Seu sinal S2 (mecânica do transporte manual) foi resolvido** ([inbox 2026-06-25](../inbox/2026-06-25-sinal-mecanica-transporte-regime-manual.md), PR #178). O incidente que você reportou — a IA commitou cross-repo na **branch errada** do core e escalou ao maestro decisões de **Ato-1 determinístico** — está **dissolvido por construção**.
- **Como (reframe):** o core já tinha o padrão certo no `/meta:co-deliver` (downstream): **entrega-sem-commit** — larga o arquivo **untracked** no canal do alvo; quem commita é a sessão home do destino → **branch-agnóstico**. Faltava o **espelho upstream**. Criamos **`/meta:co-relay`** (adotante→core `inbox/`). **Sem commit cross-repo → não existe "branch errada" nem pergunta de push → nada a escalar.** O script worktree+commit que você propôs foi **rejeitado** (reintroduziria o incidente).
- **Bug latente que você teria pego:** a guarda de papel **lê o STAMP `.claude/.onion-version`**, NÃO `onion-version.sh` — esse hardcoda `role: source` e, vendorizado no seu repo, mentiria 'source'. Provado em campo: rodamos o `--dry-run` do co-relay no SEU repo e ele prosseguiu (leu `adopted` do stamp). `co-deliver`/`co-announce` também foram endurecidos p/ ler o stamp primeiro.
- **Doutrina fixada** ([ADR onion-adr-manual-relay-subprotocol](../../analysis/onion-adr-manual-relay-subprotocol-2026-06.md)): RACI do regime manual (Ato-1 transportar = IA Driver, determinístico; Ato-3 commitar/triar = humano na sessão home); vocabulário (**maestro = humano**; core = maestro principal); guarda canônica = stamp; "silêncio ≠ consentimento".
- **Seu sinal S1 (padrão "toolbox") foi triado → backlog/pesquisa.** O S2 é o **1º caso concreto** dele e destilou o critério que você pediu: *procedimento recorrente → script determinístico (controle) + comando (juízo/quando) + ADR (doutrina) + gate humano (irreversível)*. Não será materializado como produto sem dogfood.
- **Ação p/ você:** no próximo `/meta:adopt --update`, o `co-relay` chega vendorizado. A partir daí, p/ mandar um sinal ao core (mesma máquina): escreva no seu `docs/evolution/inbox/` e rode `/meta:co-relay <sinal> --target <path-do-core>` (Ato-1, entrega-sem-commit; a sessão do core commita + tria). Sem ação obrigatória agora.

## 2026-06-24 · Digest de sessão: re-sync recomendado (catálogo #9) + roadmap dos 2 follow-ups gated · COMPATÍVEL · alvo: rhilo-metagamify

- **Complementa os anúncios individuais de hoje** (branching, laço-sem-guarda, #9) com o **net** pra você. Não re-anuncia — consolida sync + roadmap.
- **Re-sync recomendado:** você sincronizou p/ `025225e`; o **catálogo #9** entrou **depois** (`0dcdc47`, PR #164). Um `/meta:adopt --update` (já na trunk `rhilo/main` que você setou) traz os 5 playbooks vendorizados. Delta pequeno (1 arquivo: `onion-patterns/SKILL.md`).
- **Roadmap dos 2 follow-ups GATED** (decisões tomadas, costura diferida — nada que você precise fazer agora):
  1. **git:* base resolvida** (`onion-adr-branching-base-agnostic`) — sync/flow/init deixarão de hardcodar `develop`, resolvendo a integration branch. **Gatilho = seu caso** (migrar p/ trunk única); quando graduar, anuncio e você ganha os git:* coerentes com `rhilo/main`.
  2. **adoção-de-design defere ao padrão do projeto** (`onion-adr-adopt-to-not-impose`) — se um dia o `/design:identity` rodar num projeto seu com design próprio (shadcn etc.), ele detecta e **defere**, não impõe.
- **Ação p/ você:** rodar o `--update` quando for oportuno (traz o #9); os follow-ups chegam por downstream quando graduarem. Sem ação obrigatória.

## 2026-06-24 · #9 MATERIALIZADO: catálogo de playbooks em `onion-patterns` (5 recognition-primed) · COMPATÍVEL · alvo: rhilo-metagamify

- **Seus 2 sinais empurraram o #9 pra frente — e ele saiu.** A doutrina catálogo-first (RFC-0002) foi **materializada** (PR #164): seção **Playbooks (recognition-primed)** em `onion-patterns`, conforme a forma decidida (§2: estender a skill, 3-5 destilados, não skill/comando novo).
- **Os 5 playbooks:** descoberta→backlog · planejamento→entrega (é um PFR) · assumir-repo ("adota não impõe") · **agir-em-ambiente-compartilhado** (do seu sinal de 2026-06-23) · **laço-sem-guarda** (do seu pedido de 2026-06-24). Os 2 últimos **nasceram dos seus sinais** — seu uso de campo virou doutrina.
- **Doutrina:** reconheça a situação → aplique o playbook (barato); sem match → delibere (caro) e o resíduo vira playbook novo. Seleção (catálogo) + execução (**PFR**).
- **Ação p/ você:** no próximo `/meta:adopt --update` o catálogo chega vendorizado. Pode mover o **blip #9 → `done`** no seu radar (materialização entregue). O playbook "laço-sem-guarda" formaliza a doutrina; a **implementação** das guardas segue local (como no veredito).

## 2026-06-24 · Veredito: "laço-sem-guarda" = playbook candidato (core) + guardas específicas (local) — reforça #9 · COMPATÍVEL · alvo: rhilo-metagamify

- **Seu pedido-de-ajuda triado** ([inbox 2026-06-24](../inbox/_processed/2026-06-24-pedido-ajuda-escolha-dose-fila.md)): dose/fila + 4 laços de realimentação sem guarda. Sua intuição de **DIVIDIR** está certa.
- **(Q1) Doutrina ou local? → DIVIDIR.** O padrão genérico *"reconheça um laço de realimentação sem guarda → aplique clamp/anti-windup/estado-mínimo/dead-letter"* **é candidato a playbook** em `onion-patterns` (recognition-primed) e **reforça o #9** (catálogo-first, de-deferido hoje no veredito RFC-0002). É teoria de controle genérica, não RHILO-específica → **core**. A *implementação* (qual guarda p/ BullMQ/WRR/outbox/dose) é **engenharia local sua**. Materialização do playbook = junto da materialização do #9 (caminho governado), não ad-hoc.
- **(Q2) Ordem das guardas? → meta-heurística é doutrina; a ordem específica é sua.** A heurística *"guarde primeiro o laço de maior ganho/raio-de-dano; kill-switch antes de afinar"* é o nível-core. A ordem concreta (BullMQ→outbox→retenção→dose) é **decisão local com seu contexto de prod** — não ranqueio suas guardas daqui (não tenho o contexto de lá; "dev de outro repo não vive aqui").
- **(Q3) Forma do playbook → sim, encaixa catálogo(seleção)+PFR(execução).** Se materializado: entrada recognition-primed em `onion-patterns` (reconhece o caso) → sequência de aplicação de guarda (um PFR se não-trivial). Confirma o framing seleção+execução (PFR #154).
- **2º sinal de campo pró-#9.** Junto do veredito RFC-0002 de hoje, são duas evidências empurrando a materialização do catálogo p/ frente. Registrado como candidato a playbook ("unguarded-loop guard").
- **Disposição dos anexos:** a pesquisa volumosa (técnicas de fila, freeze-triage — ~49KB) é **material seu (adotante)**, input de triagem, **não doc durável do core** — removida do core após triar (você a tem; o core retém o sinal + este veredito como registro). "Não vive aqui."
- **Ação p/ você:** implementar as guardas localmente na ordem que seu contexto pedir (a meta-heurística orienta); o playbook genérico chega quando o #9 materializar (anúncio downstream). Abrir/!atualizar blip se fizer sentido no seu radar.

## 2026-06-24 · Veredito: branching = base resolvida (agnóstica), NÃO trunk-default — instância do "adota não impõe" · COMPATÍVEL · alvo: rhilo-metagamify

- **Seu sinal recebido e triado** ([inbox 2026-06-24](../inbox/_processed/2026-06-24-sinal-branching-trunk-based-vs-develop.md)): o "metade em cada lado" (canal `docs/evolution/` + comandos vendorizados encalhados em `develop`, divergente da `rhilo/main` que deploya). Diligência adversarial sobre as 3 alegações: (1) git:* embute develop = **verdade** (sync/init/flow); (2) já há resolução de base = **verdade, mas só metade** (`resolve-integration-branch.sh` + `/engineer:pr` #104 existem; **não propagaram** aos git:*); (3) "/meta:co-evolve mandou commitar em develop" = **falso** (o co-evolve é agnóstico a branch; o canal vive onde o `docs/evolution/` foi commitado — quem o pôs em develop foi a adoção, não o comando).
- **(Q1) default de branching → agnóstico/parametrizável, NÃO trunk-default.** Trocar o default p/ trunk-based só **troca uma imposição por outra** — vetado pelo ADR [onion-adr-adopt-to-not-impose](../../analysis/onion-adr-adopt-to-not-impose-2026-06.md) (#160, mergeado hoje). A base de branch é **dado resolvido** (a semente já existe: `.onion-version` + `resolve-integration-branch.sh`). GitFlow = **uma** topologia; trunk-based = setar a integration branch = o trunk. **Este sinal é evidência de campo do #160, estendendo-o de design p/ branching.**
- **(Q2) onde vive o canal:** na **integration/deploy trunk resolvida**, não preso em `develop`. O problema não foi o co-evolve forçar develop — foi o `docs/evolution/` encalhar lá. O mesmo encalhe explica o *"Unknown command: /meta:co-evolve"* na sua branch de trabalho (comandos vendorizados em develop, invisíveis fora dela).
- **(Q3) blip:** no seu radar = **blip novo** (modelo-de-branching, quadrante MET). No core = não é ADR novo — instância do #160 + follow-up nomeado (propagar a resolução de base aos git:*).
- **Ação p/ você (local, já — não espere o framework):** você pode colapsar p/ a trunk que deploya (`rhilo/main`) como integration branch única: setar `integration_branch: rhilo/main` no `.claude/.onion-version` (o `/engineer:pr` **já respeita** isso) + mover `docs/evolution/` + radar p/ essa linha. Os git:* full-propagados chegam no follow-up.
- **Follow-up (core):** [ADR onion-adr-branching-base-agnostic](../../analysis/onion-adr-branching-base-agnostic-2026-06.md) (provisório) nomeia a decisão; a **costura** (propagar `resolve-integration-branch` aos git:* sync/flow/init + guidance de canal-na-trunk) é diferida ao gatilho (mexe no motor GitFlow — exige selftest + revisão). Anunciado quando graduar.

## 2026-06-23 · Veredito: evidência de campo p/ materialização do catálogo (RFC-0002) — de-deferir #9, forma confirmada · COMPATÍVEL · alvo: rhilo-metagamify

- **Seu sinal de campo recebido e triado** ([inbox 2026-06-23](../inbox/2026-06-23-evidencia-campo-materializacao-catalogo-rfc0002.md)): evidência de que a **materialização diferida** do catálogo (RFC-0002) custa caro na operação real — com o auto-relato do operador (não conhecia o RFC-0002, reinventou a doutrina pior, errou o canal) como a prova mais nítida. **Não é proposta nova** (a doutrina já está aceita); é evidência de que o diferimento tem custo.
- **(1) Core ou local? → DIVIDIR** (mesmo padrão do veredito decision-snapshot). O *catálogo/doutrina* (situação→playbook) é **core** — RFC-0002 §2 já decidiu a forma: estender `onion-patterns` com 3-5 playbooks. Os 3 casos que você nomeou (*firefight-em-prod-durante-dev*, *ação-em-ambiente-compartilhado*, *verificar-antes-de-agir-em-prod*) são **candidatos a playbook genérico** no core. Os playbooks *operacionais concretos* (guardas de ambiente dev/HML, split de frentes) são **engenharia local** sua — ambiente/DB-específicos, autorizado a destilar já.
- **(2) Acionável na ponta? → recall automático de `onion-patterns`** — **não** skill/comando novo (`/meta:strategize` ❌ contradiz RFC-0002), **não** guarda-hard que bloqueia ação em prod. A skill `onion-patterns` **já é recall-automático** (carrega quando o trabalho casa o caso) — é exatamente o "momento de ação" que você pediu, sem nova superfície. **Guarda-hard rejeitado** como over-engineering: você mesmo relatou que "doutrina sem gate não impediu meus erros", mas todo gate hard vira atrito ou bypass; o mecanismo recognition-primed que **emerge no momento certo** é mais robusto que um bloqueio. Se quiser um pre-flight gate, é engenharia **local** sua (no seu fluxo), não no framework.
- **(3) Blip novo ou reforça? → reforça #9** (catálogo-first, já em `trial`). Não abra blip novo. É **evidência de campo** para **de-deferir** a materialização de #9 — subir na fila (ou ao menos paralelo ao reposicionamento), dado o custo demonstrado.
- **Conexão com o PFR (mergeado hoje, PR #154):** o ADR PFR nomeou a **camada de execução** (backbone faseado retomável) que o catálogo (camada de **seleção**) escolhe. Isso **destrava** parte da materialização: um playbook em `onion-patterns` pode agora dizer "reconheça o caso X → rode o PFR Y" com vocabulário concreto. Seleção (catálogo) + execução (PFR) = as duas camadas que seu incidente precisava.
- **Auto-relato de canal — reconhecido:** largar o `.md` no `docs/evolution/` do adotante (em vez do `inbox/` do core) é o gap que o protocolo de co-evolução cobre; você já corrigiu (apagou o avulso + emitiu pelo `inbox/`). O protocolo funciona quando o maestro pergunta "mandou pela fila correta?" — vale internalizar no warm-up do adotante.
- **Ação p/ você:** mover #9 na fila conforme de-deferição (decisão de apetite sua); nenhuma ação obrigatória de framework. Sinal a ser triado para `_processed/` no core.

## 2026-06-22 · `/meta:adopt` provisiona proteção de formatador nativamente (`.prettierignore` never-clobber) — backlog #7 ENTREGUE · COMPATÍVEL · alvo: rhilo-metagamify

- **Resposta ao seu sinal de prettier (PR #141, merge `727de4a`).** O `/meta:adopt` agora **provisiona** a proteção de formatador automaticamente: passo (5) do "Procedimento de Configuração pós-cópia" (Fase 3 + `--update`) mescla, never-clobber, os paths de artefatos Onion num `.prettierignore` do alvo — incluindo o SSOT `docs/onion/inventory.md`. O fix que você aplicou à mão (PR #62) deixa de ser redescoberta manual.
- **Como funciona:** helper determinístico `merge-prettierignore.sh` + template curado `prettierignore-onion.tpl` (espelha o seu fix empírico). **Append-only** — não toca no seu `.prettierignore` existente; só adiciona paths faltantes. Idempotente. Coberto por 7 cenários de selftest (incl. CRLF e o caso do seu arquivo sem cabeçalho).
- **Escopo honesto:** cobre **prettier** (e ferramentas que respeitam `.prettierignore`). **dprint/biome NÃO leem `.prettierignore`** — o helper os **detecta e avisa** (cobertura ativa = follow-up). Eixo corrigido por revisão dupla: o `.prettierignore` protege *artefatos Onion* (vendor + SSOT gerado-por-você), não "o que o manifesto copia".
- **Ação p/ você:** opcional. No próximo `/meta:adopt --update`, o passo (5) roda e garante a proteção (idempotente — seu `.prettierignore` atual já está correto, então será no-op ou complementar). Pode **remover** sua nota local de "redescobrir o problema" — agora é responsabilidade do framework. Sinal triado em [`../inbox/_processed/2026-06-22-sinal-prettier-vendor-quebra-ssot.md`](../inbox/_processed/2026-06-22-sinal-prettier-vendor-quebra-ssot.md).

## 2026-06-22 · Delta `06f7232` (anúncio retroativo) + proteção de vendor contra formatador no `/meta:adopt` · COMPATÍVEL · alvo: rhilo-metagamify

- **Anúncio retroativo do delta `06f7232` (de `a0fdf35`).** Você adotou este delta via `/meta:adopt --update` (seu PR #62, merge `18479ce`) **antes** de o core deixar o anúncio flow A — o laço que você mesmo sinalizou (3ª reincidência). Eis a classificação do que entrou (superfície vendorizada, ~29 arquivos):
  - **Comandos novos:** `/catch-up` (briefing de retomada por sinais duráveis) e `/meta:co-announce` (este produtor de flow A).
  - **Lint reforçado (HARD):** regras **r16** (count-drift do inventário), **r17** (guarda do `:` em frontmatter YAML), **r18** (proíbe a árvore não-padrão `.claude/docs/`); novas fixtures + `lint-selftest`. O delta **remove** `.claude/docs/` e move os utils C4 para `.claude/utils/`.
  - **Self-heal de inventário** (`lint --fix`) + `inventory.sh` ajustado.
  - **KBs novas:** `decision-snapshot-retention` (resposta à sua consulta) e `onion-dogfooding-doctrine`.
  - **Canal flow A (`inbound/`) + you-have-mail bidirecional** já presentes neste delta (#116).
- **Resposta ao seu sinal de prettier (causa raiz do drift do SSOT — 3ª reincidência, agora com fail HARD de CI).** Achado **aceito**: o `/meta:adopt` copia `docs/knowledge-base/`, `docs/meta-specs/`, `docs/sdaal/` e **gera** o SSOT `docs/onion/inventory.md`, mas **não provisiona** a proteção de formatação correspondente — então um adotante com formatador + pre-commit hook reformata o SSOT e quebra o lint HARD (`check_inventory_sync`), em laço vicioso. **Decisão:** o Procedimento de Configuração pós-cópia (install + `--update`) passará a **provisionar/mesclar (never-clobber) um `.prettierignore`** cobrindo TODOS os paths que o manifesto escreve no alvo, incluindo explicitamente o SSOT `docs/onion/inventory.md`. Rastreado como item de backlog do `/meta:adopt`. O core **não adota prettier** — só provisiona a proteção (generaliza p/ prettier/dprint/biome).
- **Ação p/ você:** nenhuma obrigatória. Seu fix local (`docs/knowledge-base/` + `docs/onion/inventory.md` no `.prettierignore`) está correto e continua válido; quando a proteção graduar no `/meta:adopt`, o `--update` a mesclará idempotente (never-clobber não toca no seu `.prettierignore`). Sinal triado em [`../inbox/_processed/2026-06-22-sinal-prettier-vendor-quebra-ssot.md`](../inbox/_processed/2026-06-22-sinal-prettier-vendor-quebra-ssot.md).

## 2026-06-22 · RFC-0002 — veredito da camada de meta-estratégia (catálogo-first + reposicionamento) · COMPATÍVEL · alvo: rhilo-metagamify

- **Veredito profundo entregue.** Em resposta ao seu ack de 2026-06-17 (`veredito profundo pendente — RFC-0002`), o core escreveu [`rfc-0002-meta-strategy-verdict.md`](../rfc/rfc-0002-meta-strategy-verdict.md).
- **Catálogo-first / recognition-primed: ACEITO como doutrina**, materialização **diferida** (estender `onion-patterns` com 3-5 playbooks — não skill/comando novo — atrás do reposicionamento na fila). Validação adversarial: a sobreposição com `onion-orchestration` é real (~60%) mas a distinção é genuína (forma-de-trabalho vs caso-de-uso) → não é redundância. **Blip #9: `assess` → `trial`.**
- **Reposicionamento como produto: direção RATIFICADA** via distribuição por camadas (camada 1 nativa/open; camadas 2+3 = moat/control-plane). A tensão com a identidade de 2026-05-18 foi resolvida por decomposição. Residual (follow-up): ADR FASE-0 + licença BSL. **Blip #10: `assess` → `adopt`.**
- **Ação p/ você:** mover os blips #9 e #10 no seu `radar.md` conforme o veredito. Sem outra ação obrigatória.

## 2026-06-22 · `/meta:co-announce` — anúncio flow A vira passo de ritual (não mais memória humana) · COMPATÍVEL · alvo: adotantes

- **Novo comando produtor do doc-bridge leve.** `/meta:co-announce [<data|slug>]` transforma uma entrada deste CHANGELOG num anúncio pronto-para-transportar no `inbound/` do adotante, resolvendo o(s) destinatário(s) do campo `alvo:` via `members.yaml` e escrevendo na staging do core `federation/outbox/<id>/`. Fecha o **gap de processo** do backlog #6 (a capacidade de flow A existia, mas o anúncio nunca era *exercido* ao shipar — dependia de o humano lembrar).
- **Fronteira:** é o **core-empurra** (anuncia sem esperar o adotante rodar `--update`), distinto do relatório auto-emitido de `/meta:adopt --update` (adotante-puxa) e de `/meta:federation-publish` (ledger de contratos, federação formal). Human-in-the-loop preservado: gera e endereça; o **maestro** transporta (a sessão do core nunca pusha repo alheio).
- **Ritual documentado:** `CONTRIBUTING.md` agora tem o passo pós-merge "anuncie mudança relevante a adotantes". Move o blip #1 (doc-bridge) de `assess` rumo a `trial`.
- **Ação p/ adotantes: nenhuma.** Você passa a receber anúncios de mudança via `inbound/` (📥 you-have-mail) mesmo entre updates. Chega no próximo `/meta:adopt --update` (o comando é infra do core).

## 2026-06-22 · Veredito: diretriz de retenção do *decision-snapshot* é candidata de framework (impl é local) · COMPATÍVEL · alvo: rhilo-metagamify (informativo p/ demais)

- **Sinal de campo do `rhilo-metagamify`:** o padrão "decision snapshot" (rastreabilidade atômica, herdado da doutrina spec-as-code/SDAAL) inflou o banco do adotante (32MB→86MB/semana) — cada decisão grava o **pool inteiro de candidatos** (~79KB/linha), **sem retenção nem teto de payload**.
- **Veredito (roteamento): DIVIDIR.** A *implementação* (poda por janela, payload mínimo = selecionado + top-N, TOAST/arquivamento) é **engenharia local** do adotante — DB/volume-específica; autorizado a rascunhar já. A *diretriz* é **lacuna doutrinária real** do framework: a doutrina de rastreabilidade nunca especificou retenção nem payload mínimo. Registrado candidato (quadrante MET) no backlog de co-evolução.
- **Ação p/ adotantes: nenhuma obrigatória.** Quem usa rastreabilidade atômica deve declarar política de retenção localmente até a diretriz graduar (KB/meta-spec). Resposta empurrada ao `inbound/` do adotante. Sinal triado em [`../inbox/_processed/2026-06-19-consulta-retencao-decision-snapshot.md`](../inbox/_processed/2026-06-19-consulta-retencao-decision-snapshot.md).

## 2026-06-22 · Confirmação de protocolo: o core trata o adotante como **cego** (anúncio explícito obrigatório) · COMPATÍVEL · alvo: rhilo-metagamify

- **Sinal de campo (adoção a0fdf35, vendorizado):** aplicou limpo (16 arquivos, sem conflito/segredo), mas **o anúncio flow A não operou** — o delta chegou por `--update` deliberado e cego, sem o core deixar mensagem no `inbound/`.
- **Resposta:** (1) a reescrita do `gitflow-patterns.md` foi **intencional** (refactor `1ca200c`, motor GitFlow consolidado na KB) — não efeito colateral; (2) **sim**, o protocolo já trata o adotante como cego — a capacidade existe (`inbound/` + relatório auto-emitido + you-have-mail bidirecional, anúncio de 2026-06-20). O a0fdf35 expôs **gap de processo, não de capacidade**: a capacidade não foi *exercida* naquele delta.
- **Ação p/ adotantes: nenhuma.** Gap de processo (operar o anúncio flow A ponta-a-ponta) registrado no backlog. Resposta empurrada ao `inbound/` do adotante. Sinal em [`../inbox/_processed/2026-06-19-sinal-adocao-a0fdf35.md`](../inbox/_processed/2026-06-19-sinal-adocao-a0fdf35.md).

## 2026-06-21 · Decisão: **não adotar** roteamento dinâmico de tier em runtime (sinal HeyClicky) · COMPATÍVEL · alvo: nenhum (informativo, sem ação)

- **Decisão de governança, não mudança de framework.** Avaliado o micro-delta do sinal de mercado HeyClicky (YC S26): escolher o tier do modelo **dinamicamente em runtime** (router de 1ª camada por tarefa) vs. o padrão atual do Onion — tier **fixado na autoria** (quem escreve o grafo define `model` por agente/fase na Workflow).
- **Veredito: não adotar.** Complexidade > ganho no modelo spec-as-code; o tiering estático por autoria é determinístico, auditável e suficiente. As outras 3 leituras do sinal foram **validações confirmatórias** de padrões já canônicos (model-tiering, background agents + report-back, proxy=SDAAL) — nada a mudar.
- **Ação p/ adotantes: nenhuma.** Entrada registrada só para deixar o trilho de decisão git-visível (o core avaliou um sinal externo e declinou conscientemente). Sinal triado em [`../inbox/_processed/2026-06-20-heyclicky-model-routing-signal.md`](../inbox/_processed/2026-06-20-heyclicky-model-routing-signal.md) (#120).

## 2026-06-20 · Fluxo A com canal próprio (`inbound/`) + "you have mail" bidirecional + relatório de update auto-emitido · COMPATÍVEL · alvo: adotantes

- **Canal de fluxo A:** a adoção/update agora provisiona `docs/evolution/inbound/` (irmão do `inbox/`) — o canal **core→consumidor**, separado do `inbox/` (que é o outbox de fluxo B). Provisionado idempotente (never-clobber) pelo Procedimento de Configuração pós-cópia.
- **Relatório auto-emitido:** `/meta:adopt` (v1.7.0) e `--update` escrevem o relatório do delta (arquivos aplicados · novidades · próximos passos) direto no `inbound/` do alvo — antes só saía no chat da fonte e o maestro repassava à mão.
- **"You have mail" bidirecional:** o hook SessionStart passou a contar os dois canais (`📬 inbox` fluxo B + `📥 inbound` fluxo A). `/meta:co-evolve` (v1.1.0) lê e gerencia ambos.
- Origem: sinais de campo do dogfooding ([`../inbox/2026-06-19-flow-a-report-and-bidirectional-mail.md`](../inbox/2026-06-19-flow-a-report-and-bidirectional-mail.md) + [`../inbox/2026-06-19-mgfy-adocao-update-a0fdf35.md`](../inbox/2026-06-19-mgfy-adocao-update-a0fdf35.md)).
- Ação p/ adotantes existentes: rodar `/meta:adopt --update` traz o hook bidirecional e provisiona o `inbound/`; idempotente. O README-ponteiro de `docs/evolution/` no consumidor é never-clobber (não se auto-atualiza — editar à mão se quiser refletir os dois canais).

## 2026-06-19 · `/meta:adopt --integration-branch` + base do PR resolvida do `.onion-version` (#104) · COMPATÍVEL · alvo: adotantes

- `/meta:adopt` ganhou `--integration-branch <nome>` (carimbado no `.onion-version`, campo `integration_branch`); `/engineer:pr` passou a **resolver** a base do PR via `.claude/validation/resolve-integration-branch.sh` (cadeia: `.onion-version` → `git config gitflow.branch.develop` → default detectado) em vez de hardcodar `develop`.
- Útil para adotantes com branch de integração própria (ex.: `<projeto>-evolve`, separada da branch de produto).
- Ação p/ adotantes: opcional. Sem escolha explícita, a base resolve por detecção (sem regressão). Para fixar uma branch, rodar `/meta:adopt --update <repo> --integration-branch <nome>`.

## 2026-06-18 · warm-up aponta para o inbox de co-evolução + `/meta:co-evolve` (#102) · COMPATÍVEL · alvo: adotantes

- `warm-up.md` (root) e `engineer/warm-up.md` passaram a apontar para `docs/evolution/inbox/` + `/meta:co-evolve` quando o diretório existe (silencioso se vazio; o hook "you have mail" continua contando).
- Ação p/ adotantes: nenhuma; chega via `/meta:adopt --update`.

## 2026-06-18 · `/meta:adopt --update` idempotente + Procedimento de Configuração pós-cópia (#99) · COMPATÍVEL · alvo: adotantes

- O `--update` passou a re-aplicar os passos install-only via "Procedimento de Configuração pós-cópia (idempotente)" — merge never-clobber dos hooks Onion no `settings.json` (helper testável `merge-onion-hooks.sh`) + starter `docs/evolution/`. Sem isto, um adotante com `settings.json` próprio recebia os *scripts* dos hooks mas não o **registro** (o "you have mail" não disparava).
- Ação p/ adotantes existentes: rodar `/meta:adopt --update` para receber o registro dos hooks; idempotente (re-rodar não duplica).

## 2026-06-18 · Bootstrap do canal de co-evolução · COMPATÍVEL · alvo: todos

- Criado `docs/evolution/` no core (modelo dos 3 fluxos, inbox upstream, RFC-0001 canônica) e este registro.
- Nenhuma ação requerida dos projetos. A partir daqui, mudanças do framework relevantes aos adotantes são anunciadas neste log.

## 2026-06-17 · fix `/meta:adopt` never-clobber `.env.example` (#89) · COMPATÍVEL · alvo: futuros adotantes

- O `/meta:adopt`/`--update` deixou de sobrescrever o `.env.example` do projeto-alvo (escreve `.env.example.onion` se já existir).
- Origem: sinal de campo do `rhilo-metagamify` (dogfooding) — ver [`../inbox/2026-06-17-veredito-strategy-layer.md`](../inbox/2026-06-17-veredito-strategy-layer.md) e o bug `adopt-env-example-clobber`.
- Ação p/ adotantes existentes: nenhuma retroativa; vale na próxima adoção/update.
