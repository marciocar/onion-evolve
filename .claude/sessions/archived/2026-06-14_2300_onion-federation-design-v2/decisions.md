# Decisões Tomadas — Onion Federation Design v2

## Decisão 1: Topologia peer em vez de hub

- **Contexto:** A review adversarial expôs SA-3 — o hub repousava num spike não-verificado
  (subagente operar sobre diretório de repo alheio). Se falhasse, as fases cross-repo colapsariam.
- **Opções:**
  - Hub: orquestrador único, spike SA-3 load-bearing. Risco estrutural.
  - Peer: cada repo soberano; cada Onion opera só o próprio repo (modo nativo comprovado).
- **Decisão:** Peer/descentralizado.
- **Justificativa:** Contorna SA-3 (sem spike arriscado); dissolve SA-1 (sem `.claude/federation/`);
  mais resiliente (falha de um repo não colapsa os demais); mais fiel à identidade Onion.
- **Impacto:** Cada repo Onion é autônomo. Coordenação é assíncrona. Humano é o maestro.

## Decisão 2: Ledger git como "federation spine"

- **Contexto:** Precisávamos de um meio compartilhado, assíncrono, versionado/auditável para
  coordenar contratos e mudanças entre repos.
- **Opções consideradas:**
  - Branch dedicado num dos repos: vinculado a um dono, cria dependência.
  - Submódulo git: complexidade operacional, acoplamento.
  - Pasta local compartilhada: não funciona para times distribuídos.
  - Repo git dedicado ("ledger"): neutro, versionado, auditável, remote opcional.
- **Decisão:** Repo git dedicado, montado em cada membro como *additional working directory*
  nativo do Claude Code. Remote opcional (local-only p/ solo mesma-máquina; com remote p/ time).
- **Justificativa:** Dissolve SA-3 (ler/escrever pasta adicional é trivial, sem spike);
  é o padrão "schema-registry repo" de jun/2026; remote opcional não cria dependência.
- **Impacto:** `members.yaml` + `contracts/<C>.md` + `CHANGELOG.md` (mailbox append-only) no ledger.
  Cada Onion lê/escreve o ledger de sua sessão — sem servidor, sem conexão viva.

## Decisão 3: Comandos em `meta/`, não nova categoria `federation/`

- **Contexto:** SA-1 apontou que criar `federation/` como categoria nova viola `architecture.md §7`.
- **Opções:**
  - Nova categoria `federation/`: intuitiva mas viola meta-spec L0.
  - Namespace `meta/`: precedente claro (`/meta:fleet`, `/meta:evolve`, `/meta:inventory`).
- **Decisão:** `meta/` namespace. `/meta:federation-publish`, `/meta:federation-check`,
  `/meta:federation-status`.
- **Justificativa:** Precedente existe; dissolve SA-1; fica a validar com `@metaspec-gate-keeper`
  na Fase 0 antes de criar o primeiro arquivo.
- **Impacto:** Nenhum novo namespace; menos peso no inventário.

## Decisão 4: Máquina de segurança realocada para o consumer

- **Contexto:** SA-2 expôs que o hub prometia segurança de 2ª mão (consolidava docs de outros
  repos para validar). O consumer tem conhecimento de 1ª mão sobre seu próprio código.
- **Decisão:** O repo *consumer* valida localmente a mudança de contrato quando vê a mudança
  no inbox (ledger). Veto = validação local falha → humano coordena a migração.
- **Justificativa:** Mais forte que hub; sem atraso de consolidação; sem spike cross-dir.
  `MemberExpertSchema` com fail-safe: ausência de output válido = veto (não é silencioso).
- **Impacto:** Cada Onion é responsável pela segurança do seu próprio repo. Contratos devem
  ter `tests:` + fixtures obrigatórios (comportamental, não só sintático).

## Decisão 5: Linha vermelha — A2A/MCP runtime descartado

- **Contexto:** "Comunicação entre si" poderia ser interpretada como instâncias vivas conversando
  em tempo real (A2A/MCP como runtime distribuído).
- **Decisão:** Isso é exatamente a visão abandonada em 2026-05-18. Fica como Fase 5
  premium/futura, fora de escopo do MVP.
- **Justificativa:** A fronteira "comunicação simplificada = assíncrona via git" vs "instâncias
  vivas em tempo real" foi mapeada explicitamente. Só o primeiro lado é permitido.
- **Impacto:** Sem A2A, sem MCP como runtime entre instâncias. Só git + arquivos + sessões.

## Decisão 6: Design only — sem implementar nada em `.claude/`

- **Contexto:** O usuário pediu "design v2 + backlog faseado" explicitamente sem implementação.
- **Decisão:** Nenhum arquivo em `.claude/` foi tocado. Só docs em `docs/analysis/`.
- **Justificativa:** Fase 0 é gate real — sem veredito do `@metaspec-gate-keeper` e sem spike
  do ledger, não há base para comprometer estrutura em `.claude/`.
- **Impacto:** O blueprint v2 existe em `docs/analysis/`; a implementação aguarda a Fase 0.
