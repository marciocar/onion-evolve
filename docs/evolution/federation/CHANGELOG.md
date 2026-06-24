# 📣 CHANGELOG de co-evolução — anúncios do core aos projetos (fluxo A)

> Log **append-only**. O core registra aqui mudanças do framework **relevantes aos projetos** que o
> adotam (ex.: bumps que pedem `/meta:adopt --update`, fixes que afetam adotantes, breaking changes).
> Cada projeto puxa e decide em casa. Não reescrever entradas (auditoria). Formato por entrada:
>
> `## <AAAA-MM-DD> · <assunto> · <COMPATÍVEL|BREAKING> · alvo: <ids ou "todos">`

---

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
- **Catálogo-first / recognition-primed: ACEITO como doutrina**, materialização **diferida** (estender `onion-patterns` com 3-5 playbooks — não skill/comando novo — atrás do reposicionamento na fila). Validação adversarial: a sobreposição com `onion-fleet` é real (~60%) mas a distinção é genuína (forma-de-trabalho vs caso-de-uso) → não é redundância. **Blip #9: `assess` → `trial`.**
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
