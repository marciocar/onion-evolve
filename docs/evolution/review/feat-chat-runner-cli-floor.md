---
branch: feat/chat-runner-cli-floor
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 13
findings_real: 12
tokens: 378467
duration_min: 13
findings_fixed: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "general-purpose (opus), 2 passadas, mandato refutar; cobre este PR e o par no onion-bridge"
nota: "SAC-156. Tokens e duração são a soma das duas passadas do refutador. 7 achados na passada 1 e 6 na 2; 1 é só registro (o ver() ancorado no início, que falha fechado). Curados 8: a captura sem amarra ao chat.ts (curada duas vezes: o parser de chaves e depois a função pura no bridge), o snapshot do system prompt, o ambiente do SDK, o timeout e o rc do cli_floor, o verify sem o argv do SDK (r64-r66), a guarda do snapshot só de texto (agora medida no initialize) e o comentário do custo. Ficam declarados: o bridge sem CI, o update-bridge que avisa sem barrar, o rc 1 que não separa sudo de CLI e o SSE cru."
---

# Passada adversarial: `feat/chat-runner-cli-floor`

## O que muda

O `ops/chat-runner.sh` ganha o **piso do CLI** do Agent SDK do bridge, `CLI_FLOOR=2.1.64` (CVE-2026-39861). O `cli_floor` roda o `--version` do binário que o template liga por bind, como a conta do serviço, com `env -i`, `timeout 30` e o rc lido à parte, e compara por campo. Ele é medido no `verify` e no pré-voo do `install`.

O `verify` também ganha o **contrato SDK↔lançador** (`sdk_contract`). Ele roda `scripts/sdk-runner-contract-selftest.py` do bridge servido, como a conta do serviço e com o ambiente limpo, contra o lançador **instalado**.

Na bancada, a família `chat_runner` ganha os casos r59 a r66, cada um com mutante. No grafo, o nó `E_SDK_0_3_301_CONTRATO_E_PISO_1016` sobe o teto de 142 para 143.

## Achados

Passada 1 (7):
1. A captura copiava as Options do chat.ts à mão. Curado no bridge.
2. O piso só avisa no update. Declarado como teto.
3. O snapshot do system prompt vinha ligado por default desde o 0.3.267. Curado no bridge com `snapshot: false`.
4. A variável `CLAUDE_CODE_SDK_READS_SESSION_STATE` era descartada pelo lançador sem declaração. Curado: agora tem destino declarado, com mutante.
5. O `cli_floor` não tinha teto e confundia o rc. Curado com timeout e rc (r63).
6. O SSE repassa tipos novos crus. Declarado.
7. O `ver()` é ancorado no início. Só registro.

Passada 2 (6):
1. O parser de chaves tinha falso verde em 6 formatos. Curado: a função pura `src/chat-query-options.ts` é chamada pelo chat.ts e pela captura.
2. O verify não via deriva do argv do SDK. Curado com o `sdk_contract` (r64 a r66).
3. A guarda do snapshot era só de texto. Curado: agora é medida no frame do initialize.
4. O custo do snapshot false estava subestimado no comentário. Curado: o comentário foi corrigido.
5. O rc do sudo e o do CLI colidem. Declarado.
6. O SSE cru e a variável descartada. O teto se sustenta.

## Mutantes

- Família `chat_runner`: 132 passaram e 0 falharam, com r59 a r66 e os mutantes de cada um.
- `ops/mutate-and-restore.sh` sobre o `ops/chat-runner.sh` real, com a comparação do piso trocada por `true`: a família caiu, com 5 falhas, e a restauração foi conferida.
- Bridge: 11 mutantes do contrato, todos mortos.

## Limites declarados

- O bridge não tem CI.
- O update do bridge roda o verify depois do `npm ci` e do start, e avisa sem desfazer. Barrar antes do start pede uma bancada própria do update-bridge, que não existe.
- O verify agora REPROVA enquanto o bridge servido não tiver o selftest do contrato. Por isso a ordem é: merge do bridge, depois o update, e o verify fica verde no mesmo update.
- O verify em produção com o CLI 2.1.301 não foi medido.
- Medido antes do deploy: o selftest do contrato, rodado como onion contra o lançador de produção, passa 25 asserções.
