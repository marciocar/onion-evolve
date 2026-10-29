---
branch: chore/coord-seal-4380
pr: pendente
date: 2026-10-29
reviewed_diff_sha256: 0bce69b3ca46c870947278839a5923d8dcf3bd886103c0a6c3ea4e2cac60b77a
reviewed_code_sha256: ab77f91bdb5e4da6d4f92794706fdc37361ef8d7904e977a78bee41ff3c28bbe
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 20
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, conferindo cada afirmação contra gh pr view, o registry-pins --seal e --check, o radar, o contrato e a leitura dos sinais; sem subagentes
nota: ""
---

# Passada adversarial: `chore/coord-seal-4380`

## O que muda

- `members.yaml`: o 2º selo da rodada da 4.38.0. `ops/registry-pins.sh --seal --only <id>` carimba
  onion-curation, onion-kg-ssot, sge e brain-granaai de 5b27d09c088f para 1d04d4e24cec, lido do remoto;
  o `--check` depois dá os quatro `ok`.
- Grafo de coordenação: fecha com carimbo `Q_COORD_UPDATE_4_ADOTANTES_4380` (os quatro merges e o selo);
  abre `Q_COORD_DECIDIR_VIGIA_DE_EVENTOS`, dono maestro, com as quatro decisões e a hipótese do vigia
  sobre o A2A; as duas narrativas que diziam "entrega do brain em 31/10" passam a "fechamento interno
  30/10, entrega à registradora 02/11".
- Inbox: seis sinais tratados entram em `_processed/` (três respostas aceitas do teste A2A, os dois do
  vigia de eventos e o ack do update 1d04d4e24cec). Os dois do Esperanto ficam.
- Federação: entrada de 2026-10-29 no CHANGELOG e rascunho na staging `outbox/brain-granaai/`.

## Achados

1. **Real, corrigido.** A inserção do nó novo procurou a chave `edges:` e casou com `external_edges:`,
   no topo do arquivo: o contrato acusou `parse.yaml-error`. O arquivo voltou ao commit e o nó entrou
   antes da chave `edges:` de linha inteira; o contrato e o radar passaram.
2. **Real, corrigido.** O sinal `2026-10-27-proposal-projection-with.md` do inbox não era byte a byte
   igual ao de `_processed/`: o arquivado é o original mais a triagem do core, acrescentada no fim
   (o diff só tem linhas a mais). O original foi apagado sem novo arquivamento, e o relatório diz que a
   cópia é a mesma mais a triagem, não idêntica.

## Conferido sem achado

- Os PRs por `gh pr view`: curadoria 161 (60d887e) e 163 (f7fc136), sge 167 (8daa811), kg-ssot 293
  (dccd527), brain 1663 (bb0d98881bf7, base onion/develop) e 1669, todos MERGED.
- A busca `git grep '31/10|31 de outubro|2026-10-31'` em `*.kg.yaml` e `*.md`: só as duas narrativas do
  grafo de coordenação falam da entrega do brain; o resto é `review_after` de grafo e de diário, o
  Cedar e o prazo de uma subsidiária num sinal de outro tema, que não mudam.
- Os sinais movidos não têm nome comercial de cliente nem dado privado (REGRA 36 (Superfície VENDORIZADA
  sem nome comercial de cliente)): só o id de membro do hub, que o registro e o grafo já usam, e nomes
  genéricos ("a registradora") ou de fornecedor (Slack, Gmail, Outline, AWS).
- Nenhum caminho de máquina nos nós (REGRA 99 (Nó de .kg.yaml sem caminho de máquina, julgado pela
  classe)).
- Radar `--integrity --schema` rc 0 (36 nós, 38 arestas), contrato conforme, backlog-check 36/40.

## Mutantes

Nenhum: a mudança é dado de grafo, registro e sinal, sem código.

## Limites declarados

- Os casos W1 a W3d são medida da curadoria numa cópia do core; o core não os re-executou.
- "O pedido de perfil event foi aceito pelo kg-ssot" entra como testemunho repassado pela sessão
  principal do core, não lido no repo do kg-ssot.
- O hub-operacoes-enterprise segue divergente no registro (8278fee79d1c contra 58f162825541): não é
  desta rodada.
