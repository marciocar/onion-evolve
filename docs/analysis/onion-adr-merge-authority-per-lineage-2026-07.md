---
title: 'ADR — Autoridade de merge por papel/linhagem: production de cliente = merge consent-gated pelo cliente'
date: 2026-07-12
type: adr
status: accepted (doutrina) — implementação design-target (slice de follow-on)
decision-scope: engineering / adoption governance (autoridade de merge por branch-role)
supersedes: none
extends: onion-adr-branch-roles-sdaal-2026-07.md
origin-signal: docs/evolution/inbox/_processed/2026-07-12-producao-de-cliente-merge-consent-gated.md (metagamify, dogfood Movimento 1)
deciders: maestro
related:
  - onion-adr-branch-roles-sdaal-2026-07.md (define os papéis; NÃO atribuía autoridade de merge — o gap)
  - rfc/rfc-0004-a2a-live-interop.md (aceitação-gated: mesmo princípio, outra superfície)
  - rfc/rfc-0005-scope-inheritance-polymorphism.md (cliente-como-deploy)
  - onion-parecer-rhilo-lineages-2026-07.md (modelo de linhagens do metagamify)
---

# ADR — Autoridade de merge por papel/linhagem

## Contexto (furo descoberto em dogfood)

Dogfood do **Movimento 1** (vendorizar o framework na produção `rhilo/main` do metagamify): o
`/meta:adopt --update` gerou o **PR #78** (framework-only, 432 arquivos, zero em `apps/`/`src/`) — tudo certo.
**Mas ao ver o PR pronto, o maestro travou o merge**, expondo um furo que o ADR `branch-roles-sdaal` não nomeou.

**O furo:** a RHILO é **cliente de consultoria** (metagamify é produto do Marcio). `rhilo/main` é a **produção
DELES**. Mesmo o repo sendo do Marcio, o código deployado que serve a RHILO é governado pela **aceitação da
RHILO** — a palavra final do merge é **do cliente**, não do maestro do adotante. O `adopt/vendor` e o
branch-roles assumiram implicitamente "quem adota controla a produção" — **falso para adotante-cliente**. Hoje
**só a prudência humana** travou; a doutrina, como está, **permitiria** o maestro mergear na produção do
cliente sem consentimento.

O branch-roles-sdaal definiu os papéis (`integration`/`production`/`lineage:<nome>`/…) e a direção
`produto→deploy`, mas **não atribuiu AUTORIDADE DE MERGE por papel/linhagem**. `production` de um adotante-dono
≠ `production` de um adotante-cliente.

## Decisão

**Adicionar o atributo `merge_authority: self | client | core` ao contrato de branch-role** (faceta,
esp. `environment:production` e `lineage:<nome>`). Default `self`. É o eixo que faltava: *quem pode aceitar o
merge naquela linhagem*.

### 1. Semântica
- **`self`** (default): o maestro do adotante mergeia (o dono controla sua produção). Comportamento atual.
- **`client`**: a linhagem serve um CLIENTE cuja aceitação é a palavra final. O vendor **propõe (PR)**; o
  merge é **gate do cliente**. Nem o maestro do adotante nem o core mergeiam.
- **`core`**: (raro) linhagem cuja autoridade é do core — reservado; não usado hoje.

Para `lineage:<cliente>` (ex.: `rhilo/main` servindo a RHILO) → `merge_authority: client`.

### 2. Onde mora a declaração (segue o split do branch-roles-sdaal)
- **`.onion-version branch_roles:`** (SSOT local versionado) — ao lado do papel→branch, o adotante declara
  `merge_authority` por papel. É a topologia local.
- **`members.yaml lineages:`** (visão da federação) — ao lado do pin, o core registra `merge_authority` da
  linhagem-cliente. `client` = fora do controle do maestro-do-adotante E do core.

### 3. O gate (nomear a proibição — não deixá-la à prudência)
`adopt/vendor` já **não mergeia** (o Procedimento de Commit Durável para no commit da branch; o `--update` faz
merge só na integração local do adotante). **Falta nomear**: quando a linhagem-alvo tem `merge_authority ≠ self`,
o fluxo **PARA no PR** e imprime a proibição explícita — *"não mergear: autoridade da linhagem é do `<owner>`"*.
O **relatório downstream** do adopt, para lineage-de-cliente, diz nos próximos passos: *"abrir o PR e ENTREGAR
ao cliente para revisão/aceite — o maestro NÃO mergeia"*.

### 4. Pin proposto-até-aceite (5º membro de declarado≠verificado)
O pin de produção de uma linhagem-cliente fica **"proposto" até o cliente mergear** — declarado (o PR existe)
≠ verificado (o cliente aceitou). O `members.yaml lineages:` marca `pin_status: proposed | accepted` (ou o
`onion_version`/pin da linhagem **só avança no aceite**). O `pin-integrity-check` já é a base de "verificado";
aqui a verificação inclui *"o merge do cliente aconteceu"*. Detalhe de design do slice de implementação.

## Por que isto é o mesmo princípio, noutra superfície

É **aceitação-gated** — o mesmo moat da RFC-0004 (a2a-live só aplica sob gate; `federation-check` fail-safe =
veto) e do fio guardrails (*"mapear consentido ≠ vigiar"*): **nada se impõe na superfície de quem tem a palavra
final**. Aqui a superfície é a **linhagem de produção de um cliente**; o gate é o **merge do cliente**. O
`members.yaml.trust` já é policy-as-data; `merge_authority` é a policy da *escrita em produção*, irmã da
policy de *aceitação de sinal*.

## Invariantes
- **Nunca impor merge numa linhagem cuja palavra é de outro.** Fail-safe: autoridade desconhecida/ausente na
  linhagem-cliente = tratar como `client` (não `self`) — ausência nunca vira permissão.
- **`/meta:adopt` fica** — muda o wording e ganha um gate nomeado, não muda o mecanismo (vendor propõe).
- **declarado≠verificado** no pin proposto-até-aceite.

## Próximos passos (slice de implementação — design-target)
1. `branch-roles/types.md`: `merge_authority` no `BranchRole` (o SDAAL do branch-roles-sdaal §4).
2. `.onion-version branch_roles:` + `members.yaml lineages:`: campo `merge_authority` (+ `pin_status`).
3. `adopt.md`/`vendor-branch.sh`: gate nomeado quando `merge_authority ≠ self` (para no PR + wording do relatório).
4. Selftest do gate (fail-safe = trata ausência como `client`).

## Resposta ao metagamify (para o maestro transportar)
Aceito como slice de doutrina: `production`/`lineage` ganha `merge_authority`; `lineage:<cliente>` = `client`.
**PR #78 corretamente congelado** — a prudência já fez o certo; a doutrina passa a **nomeá-lo** (gate explícito,
não prudência). O pin-proposto-até-aceite entra como 5º membro de declarado≠verificado. Implementação = slice
de follow-on (design-target acima).
