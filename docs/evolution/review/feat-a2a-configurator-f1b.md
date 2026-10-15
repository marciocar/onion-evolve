---
branch: feat/a2a-configurator-f1b
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 6
tokens: 139980
duration_min: 9
findings_fixed: 6
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente refutador (general-purpose)
nota: "1 bloqueante (a confiança vale no clone servido pelo bridge, não no merge) curado no texto; o bridge não foi lido (MOAT)"
---

# Passada adversarial: `feat/a2a-configurator-f1b`

## O que muda

F1b do configurador A2A (SAC-122), sobre a F1a (PR #1137, 181a7708):

- `/meta:federation-a2a` (`.claude/commands/meta/federation-a2a.md`): o wizard em trilhas 1 a 6 para o par
  core↔membro (preparar o receptor, convidar, entrar na rede, conferir, aceitar a fila, revogar), com as
  diretivas de injeção (data, papel, `a2a-doctor.sh --selftest`) e dry-run antes de toda escrita.
- Doutrina `common/prompts/federation-a2a-doctrine.md` (8 cláusulas e o que o comando NÃO promete) e lente
  `.claude/rules/federation-a2a-lens.md` (`paths: .claude/utils/federation-transport/**`, REGRA 53).
- `/meta:federation-member register` ganha o bloco `a2a` (nasce sem chave) e termina no doctor do receptor.
- `roles.yaml`: `federation-a2a` no conjunto `adoption`. Corte medido pelo `vendor-manifest.sh --list`: fonte
  e hub levam comando, doutrina, lente e motores; standalone, plugins e mini, nenhum.
- Textos defasados do transporte corrigidos (o "stub, sem canal vivo" do `detect-transport.sh` e do README;
  o "vazio na fundação" do JWKS). Contagem de comandos 116 → 117 (`inventory.sh`).
- Grafo do programa: o selo da F1 (`E_F1_ENTREGUE_COM_DOGFOOD`), o passo manual que sobra, a confiança no
  clone servido e 1 decisão da sessão.

## Achados

| # | sev. | achado | desfecho |
|---|---|---|---|
| 1 | bloqueia | o comando e a doutrina diziam que a confiança nasce no merge; o bridge lê um clone próprio do core (que já ficou 108 commits atrás), então pino e revogação só valem quando esse clone recebe o merge | curado: trilhas 2 e 6 e cláusula 3 dizem o clone servido; nó `C_CONFIANCA_VALE_NO_CLONE_SERVIDO` |
| 2 | corrigir | a trilha 6 mandava conferir sem `--kid`, e o doctor só olha os kids que restam | curado: o bloco nomeia o `--kid` revogado |
| 3 | corrigir | o `a2a.conf` do pacote não é lido por motor nenhum | curado: declarado lembrete legível (comando e nó) |
| 4 | limite | `allowed-tools` não cobria o doctor no register nem Edit/Write no wizard | curado nos dois frontmatters |
| 5 | limite | depois de rotação o remetente usa `<id>-1` por default | declarado na trilha 3 (`--kid <id>-<N>`) |
| 6 | limite | o `--dry-run` imprime um JWS válido por 300 s | declarado na trilha 3 (não colar em canal compartilhado) |

## Mutantes

A F1b não muda motor nem guarda: é superfície (comando, doutrina, lente), dado de corte (`roles.yaml`) e texto.
Os mutantes da família `federation_a2a` (54, todos mortos) foram provados na F1a, no PR #1137, e os motores
não mudaram desde então. As guardas que cobram as peças novas já existem e têm bancada própria: REGRA 37
(Mapa role→bundle (roles.yaml) consistente com os verticais) para o corte, REGRA 53 (Regra path-scoped declara
`paths:` que casa algo real) para a lente, e o censo da forja (`forge-census.sh`, 6/7, a peça 4 ausente por
desenho e declarada). Famílias rodadas sob `LC_ALL=C`: `detect_transport`, `role_cut`, `role_bundle`,
`rules_registry`, `forge`, `command_role_parity`, `ops_citation_travel`, `vendor_manifest`, `door_leak_scan`,
`federation_a2a` e `core_only_role`, 196/196.

## Decisões tomadas sem o maestro

1. **Pacote de entrada com os três motores** para o membro (nó `D_PACOTE_DE_ENTRADA_LEVA_OS_MOTORES`, aberto
   para ratificação), em vez de mudar o corte para o adotado standalone levar a federação cross-repo.
2. **Na F1 o receptor é só o core**; o hub roda as trilhas 3 e 4 (entrar e conferir) e o receptor do hub fica
   na F3, como o plano fasea.
3. **O convite da F1 segue o pool do bridge** (o bearer gerado direto em arquivo 0600); o convite por membro é a F2.
4. **O wizard não lê a fila do serviço nem faz deploy**: a trilha 5 aceita registro por registro com o
   `a2a-accept.sh`, e a listagem e o deploy ficam com o maestro (MOAT).
5. **`a2a.conf` como lembrete**, sem motor que o leia (achado 3): fazer os motores o lerem mudaria código já
   mergeado e provado; fica como melhoria nomeada.

## Limites declarados

- **NÃO MEDIDO:** o S6 de verdade (duas contas de sistema e o bridge vivo); o dogfood rodou em sandbox, com
  dois HOMEs e um bridge local de teste que chama o gate real.
- **NÃO MEDIDO:** se o bridge lê o JWKS do clone servido além do registro (código do bridge não lido, MOAT).
- A Skill do harness não carregou o comando novo (nasceu depois da carga da sessão): o procedimento foi
  executado como o harness o executaria (diretivas injetadas, literalmente, e os blocos das trilhas 1 e 4
  contra o registro vivo, só leitura).
- O lint completo do refutador foi cortado pelo teto dele; o da sessão saiu 0 HARD, e o pré-voo e o CI decidem.
