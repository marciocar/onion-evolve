# Peças do ecossistema: estado e transição proposta (2026-11-10)

Coluna «estado da peça e transição proposta» do mapa de interconexão de 2026-11-10, aplicada pela
doutrina [`common:prompts:piece-state-doctrine`](../../../../.claude/commands/common/prompts/piece-state-doctrine.md).
Esta é a versão pública: sem hosts, contas nem caminhos de máquina. O mapa completo é local. A decisão que
pediu esta coluna é `D_PIECE_STATE_DOCTRINE_1110`, no grafo deste perfil.

Cada linha leva o estado de hoje, a transição proposta, o gatilho medido e a evidência. **Proposta não é
ato:** cada transição passa pelo `/meta:decide` e, para adotar, pelo `/meta:adopt` com o maestro, na ordem
batuta, bridge, `onion-messaging`.

Refs lidas: core em `origin/main` de 2026-11-10; `onion-messaging` em `origin/main` `b9b7f5c`
(2026-11-09); `onion-bridge` pelo clone local em `origin/main` `92079ae` (2026-11-07). «Commits próprios»
são os da janela de 30 dias que tocam arquivo fora de `.claude/`, `vendor/` e `docs/evolution/` e levam
`Claude-Session:`; «do core» é quando essa sessão também assina commit do core na mesma janela.

| peça | estado hoje | transição proposta | gatilho medido | evidência |
|---|---|---|---|---|
| **`onion-bridge`** (`/a2a`, `/chat`, OIDC, pull do inbox) | exclusiva do core: repo próprio, fora do registro, sem sessão dona | **adotar** (repo e sessão donos, registro no `members.yaml`) | dívida sem dono: roda em produção pelo core e quem escreve é o core | 15 arquivos de operação do core o citam (`git grep -lw onion-bridge -- ops deploy .github/workflows .claude/hooks`); 34 de 34 commits próprios da janela vindos de sessão do core; fora do `members.yaml` |
| **`onion-messaging`** (campainha, fila, vigia) | adotada no registro (2026-11-06), sem sessão dona de fato | **adotar** a sessão dona | dívida sem dono: o dono declarado não é quem escreve | 25 de 25 commits próprios da janela vindos de sessão do core |
| **`onion-queue`**, para o repo | adotada (vive no `onion-messaging`), sem sessão dona | **adotar** a sessão dona, com a do `onion-messaging` | dívida sem dono: hoje agentes do core escrevem nela | a linha acima: os commits da fila estão entre os 25 de 25 |
| **`onion-queue`**, para os membros | o daemon roda em três membros (core, curadoria e o hub), cada um a partir do próprio checkout, sem versão publicada | **vendorizada como dependência fixada por versão**, como o kg-ssot: versão publicada, carimbo e um `--update` que aponte membro em versão velha | consumidor novo: três membros já rodam o daemon | o daemon roda em três membros a partir do checkout de cada um; risco de versão nomeado no mapa local |
| **`onion-queue`**, futuro | — | **promoção a produto** («operar o nó») | só com adotante ou cliente que peça; **hoje não há**, logo sem transição | nenhum pedido registrado |
| **gate A2A** (`a2a-verify.sh`) | duas cópias idênticas, no core e no `onion-messaging`, e leitura viva pelo `onion-bridge` | **vendorizar com carimbo**, do core para a fila; **não** ganha repo | consumidor novo, com contrato que já tem de mudar junto: o perfil v1 manda as duas cópias mudarem juntas (seção A2 e `D_INTERCONNECT_PROFILE_A_V1_1110`), e o mapa o põe entre os 3 maiores riscos de quebra | blob git idêntico nos dois (`c4f1e34d…`); citado por `queue/onion_queue/daemon.py`, `doorbell/server.ts` e `tools/` na mensageria, e por `src/a2a.ts`, `src/a2a-invites.ts` e `src/a2a-receivers.ts` no bridge; a cópia da mensageria veio pelo adopt, que fixa o commit, não o arquivo |
| **persona `@brain`** (`onion-slack-persona`, código em `src/slack-persona/` do `onion-bridge`) | exclusiva do core | **adotar a operação**: o código fica no core e a operação da instância vai ao hub, depois do selo `D_MA_ARCH` (previsto para 16/11) e do piloto `Q_PS_PILOTO_EM_RASCUNHO_1117` (17/11, dono: core) | função nova e consumidor: piloto real (10 rascunhos postados só depois da aprovação do maestro em 07/11, `docs/onion/graph/comms-stable-2026-11.kg.yaml`, nó `Q_CS_DEGRAU2_SLACK_RASCUNHO_1109`) e um consumidor, o hub | risco do modo hub nomeado no mapa local, a tratar antes do ato |
| **`members.yaml`** | exclusiva do core, lida por muitos | nenhuma de estado | o gatilho existe (consumidores em três repos), mas a cura já está decidida pelo perfil: leitor único do registro primeiro (`D_INTERCONNECT_EXEC_ORDER_1110`) | 24 parsers próprios no core (mapa, ligação 15); o bridge e a mensageria o leem por caminho |
| **kg-ssot** | adotada (`onion-kg-ssot`) e vendorizada no core com carimbo por arquivo | **nenhuma** | — | `vendor/kg-ssot/.kg-ssot-version` com sha256 por arquivo; 64 commits de vendor no core desde 2026-10-10 (`git log --oneline --since='2026-10-10 00:00:00 +0000' origin/main -- vendor/kg-ssot | wc -l`, medido em 2026-11-10; sem a hora, o `--since` corta na hora atual do dia e devolve menos) |
| **portas públicas** (`onion-core`, `onion-standalone`, `onion-plugins`, `onion-mini`) | porta | nenhuma | — | projeção de `origin/main` por `ops/publish-door.sh` |

## O que esta coluna não diz

- Não mede valor estratégico: diz em que estado a peça está e qual gatilho acendeu.
- A campainha e o vigia (no `onion-messaging`) seguem com a peça-mãe. O vigia não está implantado, logo
  não tem consumidor nem transição própria.
- Os números de commits são da janela de 30 dias, lidos por git sem fetch, nas refs acima.
