---
title: Decisões delegadas pelo maestro — período noturno de 2026-10-15
date: 2026-10-15
type: decision-log
---

# Decisões delegadas — 2026-10-15 (período noturno e manhã)

**Autorização do maestro (verbatim, 2026-10-15 ~03:05 UTC):** "vou dormir, trabalhe diretamente até o fim, incluindo
as mudanças e tarefas do A2A sem me perguntar nada".

**Renovação (~06:10 UTC, verbatim):** "ok, siga até o fim, tem autorização para rodar o deploy".

**Como a sessão aplica:**
- Decisão que seria do maestro: a sessão escolhe a opção **recomendada**, registra aqui e, quando é nó de grafo, sela pelo
  `kg-decide-seal.sh` com a marca de delegação.
- O MOAT segue valendo:
  - deploy só pelos wrappers de `ops/`;
  - sem rotação de chaves;
  - sem escrita em repo de adotante fora do `/meta:adopt`;
  - sem ação destrutiva;
  - merge só pelo `ops/merge-serial.sh`.
- Antes da noite, o maestro tinha selado `D_COBRAR_NA_SAIDA_E_NO_TRANSPORTE` (SAC-142, «A agora + D em seguida») e
  `D_PRE_VOO_SEMPRE_E_SOMBRA` (SAC-141). O que segue executa esses selos e decide a FORMA de cada execução.

## Histórico

| Hora (UTC) | Decisão / ato | Opção escolhida | Alternativas | Onde ficou |
|---|---|---|---|---|
| 03:05 | Pin do `onion-curation` sobe para 85e93bba1609 depois do merge dele (#20, c4faaa8), conferido no remoto | `ops/registry-pins.sh --seal --only onion-curation` | — | #1132 |
| 03:10 | Respostas à curadoria sobre a direção do dissect (`Q_DISSECT_DIRECTION_AFTER_V2`, pergunta autorizada pelo maestro lá) | medido + derivado da doutrina: extensão LOCAL no adotante primeiro; emenda ao core só com a v3 provada | propor emenda já | mensagem à sessão da curadoria |
| 03:10 | A F1 do A2A (SAC-122) vai a um agente de execução com worktree própria | delegar, no limite de 5 agentes | fazer na sessão principal, em série | ver o relatório do agente abaixo |
| 03:15 | SAC-145, critério da poda do hook aposentado | podar só a forma do Onion com o script ausente NA FONTE E NO ALVO; entrada morta em outra forma recebe aviso | podar todo hook morto · só avisar | #1133 |
| 03:25 | SAC-143, a sincronização do checkout em `main` depois do merge | LIGADA por padrão, só por fast-forward e sem mudar o rc | opt-in (`--sync`), que era o motivo de nunca rodar | #1134 |
| 03:40 | SAC-142 D, onde mora a declaração da cobrança | arquivo irmão `enforcement.tsv` por raiz (molde do `capabilities.tsv`) | bloco na `interface.md`, que estourou o teto da REGRA 5 do núcleo SDAAL (518 > 500) | PR da D |
| 03:40 | SAC-142 D, a severidade | HARD, com o passivo de `none:` em SOFT; no derivado, hook não registrado e validador fora do lint descem a SOFT | SOFT geral | PR da D |
| 04:00 | SAC-144 item 2 (o registro não reconhecia a worktree irmã) | curado: compara também o checkout principal pelo `git-common-dir` | — | #1136 |
| 04:16 | Conflito REAL de fonte no `lint-selftest.sh` entre PRs paralelos, com as famílias novas na mesma âncora | resolvido à mão mantendo os dois blocos, com re-revisão declarada no resíduo; a classe virou issue para estudar | esperar e serializar | SAC-146 |
| 04:16 | Dogfood do SAC-143 no próprio merge: `sync-main: 29231d89→a1c3d7bc (8 commits)` | — (medição) | — | #1134 |
| 04:50 | SAC-144 item 3 (o `--update` sem escolha de fonte) | NÃO curado esta noite: está em 6 pontos de prosa do `/meta:adopt` e a frequência não foi medida; fica como estudo na issue | curar já | SAC-144 |
| 05:44 | F1a do A2A (SAC-122): keygen, remetente canônico e doctor; o refutador achou 14 defeitos, todos curados com caso e mutante | F1 dividida em dois PRs seriais | um PR só | #1137 |
| 05:44 | Piso da chave: 2048 bits no registro, 3072 no keygen | 2048 no registro, porque os pinos vivos (2 membros) têm 2048 e a rotação está parada por ordem | 3072 em tudo, o que derrubaria os pinos vivos | nó aberto no grafo `a2a-configurator-2026-10`, para ratificar |
| 05:44 | O membro recebe um pacote de entrada com os três motores | pacote, porque o adotado standalone não recebe `federation-transport/` | mudar o corte por papel | nó aberto no grafo, para ratificar |
| 06:15 | F2 do lado do bridge (convite por membro, amarrado ao `from`, relido sem restart) aberta em paralelo à F1b | PR no onion-bridge, merge do maestro com `!` (a merge-gate veta `gh pr merge -R`) | esperar a F1b | marciocar/onion-bridge#69 (SAC-123) |
| 06:15 | F2: motivo nomeado no corpo do 401; admin continua recusado no `/a2a` (P9); pool legado `INVITE_TOKENS_A2A` mantido com aviso de depreciação | recomendadas do plano | — | onion-bridge#69 |
| 06:40 | F1b: `/meta:federation-a2a` em 6 trilhas, doutrina, lente, `register` com o bloco `a2a`. O refutador achou 6 defeitos (1 bloqueante: o pino e a revogação só valem quando o clone SERVIDO recebe o merge) | texto corrigido + nó no grafo | — | #1138 |
| 06:40 | O `members-validate` como HARD | já era: a REGRA 66 (Registro da federação validado no gate) o liga desde 2026-09-01; corrigido o cabeçalho que dizia o contrário | — | #1138 |
| 06:50 | Permissões do diretório de dados em produção (pré-condição da F2: fail-closed se gravável pelo grupo) | medido: `onion 755`, passa | — | — |
| 06:55 | **Deploy** (autorizado pelo maestro às ~06:10): `ops/update-bridge.sh` | rc 0; clone servido 867420ae com a F1 provada por `merge-base --is-ancestor`; health 200 local+público; `/a2a` sem bearer e com bearer errado = 401 | — | bridge 94a21ca6 |

## O que fica para o maestro

1. **Merge do onion-bridge#69** (F2 do bridge) com `!`; depois a sessão roda o 2º deploy e liga o lado do core da F2 (o wizard gera e revoga convites no formato do PR).
2. **Ratificar** os dois nós abertos da F1 (piso de 2048 no registro; pacote de entrada) no grafo `a2a-configurator-2026-10`.
3. **SAC-146** (âncora comum no `lint-selftest.sh` entre PRs paralelos): estudo.
4. **SAC-144 item 3** (`--update` sem escolha de fonte): estudo, sem medição de frequência.
5. **`Q_FAMILIAS_BARATAS_DO_MAPA_NO_PRE_VOO`**: revisita em 2026-10-29, com os dados da sombra.
6. **Avisar metagamify e granaai** sobre o `body_sha256`; com a F1, a troca vira "use o remetente canônico" (trilha 3).
7. **S6 vivo e S7**: o ponta a ponta com duas contas de sistema e o onboarding de um adotante real seguem com você.
8. O protocolo A2A emendado que a curadoria pediu (2ª passada): a sessão não sabe onde está.
