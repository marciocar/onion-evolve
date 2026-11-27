# Mapa de nomes do ecossistema

> **Core-only.** Este arquivo não viaja no `/meta:adopt`: ele cita ids de adotante, e as guardas que
> varrem o que viaja (REGRA 36 e REGRA 106) reprovariam esse id fora daqui. A regra e o porquê estão na
> KB [ecosystem-naming](../../knowledge-base/concepts/ecosystem-naming.md). A decisão é o nó
> `D_ECOSYSTEM_NAMING_PATTERN_1127` (grafo `docs/onion/graph/onion-identity-2026-07.kg.yaml`); o card, SAC-567.

**Quem confere:** o `members-validate.sh` (REGRA 66 no lint) reprova quando um membro do
`members.yaml` falta aqui, quando uma linha daqui não é membro, ou quando o alias diverge do registro.
Registrou um membro novo? Acrescente a linha dele aqui no mesmo PR.

**Como ler a coluna «conforme»:**

- **sim**: o id já segue o prefixo do tipo.
- **não**: é peça de um tipo do padrão, com id antigo. Ganha alias registrado e gatilho de rename; o id
  não muda até o gatilho.
- **n/a**: projeto de adotante comum ou membro técnico. O padrão de prefixo não se aplica.

**Pendentes** (precisam da palavra do maestro, ver a KB): o `watcher-onion-evolve` e os cinco
`onion-svc-*`. O alias natural dos serviços (`onion-vps-<serviço>`) já aparece em arquivos que viajam,
e a REGRA 106 o acusaria no dia em que virasse alias registrado. Antes é preciso limpar esses arquivos
ou decidir outra forma.

| id atual | tipo | conforme | alias | gatilho de rename |
|---|---|---|---|---|
| `onion-evolve` | fonte (o core) | sim | — | — |
| `metagamify` | projeto adotante | n/a | — | — |
| `pulse-mais` | projeto adotante (organização externa) | n/a | — | — |
| `granaai` | projeto adotante | n/a | — | — |
| `ticket-ai` | projeto adotante (sob o hub da Grana.Ai) | n/a | — | — |
| `gustavo-pulga` | projeto adotante | n/a | — | — |
| `onion-mini` | porta | sim | — | — |
| `onion-standalone` | porta | sim | — | — |
| `hub-operacoes-enterprise` | hub adotante | n/a | — | — |
| `brain-granaai` | company brain | não | `company-brain-granaai` | renomear na migração para a AWS |
| `vendas-pdi-enterprise` | projeto adotante | n/a | — | — |
| `onion-core` | porta | sim | — | — |
| `onion-plugins` | porta | sim | — | — |
| `onion-codex` | porte | sim | — | — |
| `marcio-pessoal` | second brain | não | `second-brain-marcio` | renomear quando o Second Brain ganhar repo próprio no notebook e entrar na rede A2A |
| `onion-pedro` | projeto adotante (o prefixo onion- é anterior ao padrão) | n/a | — | — |
| `onion-arthur` | projeto adotante (o prefixo onion- é anterior ao padrão) | n/a | — | — |
| `poc-venda-direta-pdi` | projeto adotante | n/a | — | — |
| `arandek` | projeto adotante | n/a | — | — |
| `onion-dist` | peça do Onion (investigação) | sim | — | — |
| `sge` | projeto adotante | n/a | — | — |
| `hub-formacao-enterprise` | hub adotante | n/a | — | — |
| `sacola-de-ideias` | projeto adotante | n/a | — | — |
| `portal-gamificacao` | projeto adotante | n/a | — | — |
| `jogo-da-vida` | projeto adotante | n/a | — | — |
| `onion-slm` | peça do Onion | sim | — | — |
| `onion-curation` | peça do Onion | sim | — | — |
| `agente-whatsapp` | projeto adotante | n/a | — | — |
| `onion-company-brain-product` | peça do Onion | sim | — | — |
| `onion-kg-ssot` | peça do Onion | sim | — | — |
| `bomtexto` | projeto adotante | n/a | — | — |
| `maestro-notebook-test` | membro de teste (dispositivo) | n/a | — | — |
| `maestro-peer-test` | membro de teste (dispositivo) | n/a | — | — |
| `watcher-onion-evolve` | serviço do core (vigia de webhooks) | não | pendente (decisão do maestro) | pendente |
| `onion-vps-ops` | peça do Onion (operação da VPS) | sim | — | — |
| `onion-svc-librechat` | serviço da VPS | não | pendente: onion-vps-librechat | pendente |
| `onion-svc-gokapi` | serviço da VPS | não | pendente: onion-vps-gokapi | pendente |
| `onion-svc-logto` | serviço da VPS | não | pendente: onion-vps-logto | pendente |
| `onion-svc-waha` | serviço da VPS | não | pendente: onion-vps-waha | pendente |
| `onion-svc-vaultwarden` | serviço da VPS | não | pendente: onion-vps-vaultwarden | pendente |
| `onion-messaging` | peça do Onion | sim | — | — |
| `consultoria-analise-de-caso` | projeto adotante | n/a | — | — |
| `brain-onion-evolve` | Persona do Onion Evolve (categoria à parte) | sim | — | — |
