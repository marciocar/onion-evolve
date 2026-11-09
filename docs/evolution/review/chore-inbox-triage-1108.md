---
branch: chore/inbox-triage-1108
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
tokens: 0
duration_min: 40
findings_fixed: 5
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: "o próprio agente de execução, com mandato de refutar o diff; sem subagente (o brief proíbe criar agentes)"
nota: "tokens = 0: não medido. Passada de uma lente só. Medidos: --selftest do check 15/15, família relay_public da bancada 33/33 com os mutantes novos, radar 0, contrato ok, varredura de caminho de máquina 0."
---

# Passada adversarial: `chore/inbox-triage-1108`

## O que muda

- Triagem dos 9 sinais do inbox do core; tratados em `_processed/`, os dois do sandbox como forma-resumo.
- REGRA 113 (Sinal relayado a destino público só se commita revisado): no papel source, sinal novo sem a chave
  passa a ser HARD (`sem-marca`), a partir do corte de 2026-11-09.
- Doutrina de dissecação: o campo `onion` é julgamento, o `min_count` útil com `--around`, os três checadores.
- Grafo `inbox-triage-1108` com 2 selos e 8 perguntas, com espelho SAC-374 a SAC-381.

## Veredito por sinal

| Sinal | Veredito |
|---|---|
| WAHA | já tratado, PR #1553 |
| Quatro campos e REGRA 113 | feature selada em parte; a lacuna entregue aqui |
| Codex e MCP por arquivo | já tratado no anúncio; o nó ganhou as duas lacunas aqui |
| Quadro e operação | fix aqui (doutrina) e backlog (guarda de resíduo); o resto informativo |
| Lacunas da campainha | já tratado, PR #1544 e PRs #9 e #10 do onion-messaging |
| Vigia | já tratado, PR #8 do onion-messaging |
| Fila e campainha | backlog, 3 perguntas e 1 do maestro |
| Sandbox F8 | fix em backlog (`Q_IT_SYNC_MAIN_WRITE_PREFLIGHT`); adoção é do maestro |
| Re-medida do sandbox | informativo |

## Achados

1. BANCADA NO ADOTANTE: a família `relay_public` não é core-only, e o caso (j2) reprovaria na cópia vendorizada, onde
   o dispatcher não liga a exigência. O caso passou a esperar o silêncio fora do papel source.
2. RESPOSTA SEM LASTRO: o anúncio anterior disse que as lacunas do Codex e do MCP iam para a
   `Q_ONION_CORE_PORTS_MULTI_MODEL_2026_11`, e o nó não as citava. Escritas no nó.
3. VAZAMENTO AO RE-COMMITAR: o sinal do hub trazia caminho de máquina, e dois sinais o id do membro hub. Trocados.
4. CONTAGEM ERRADA: a evidência dizia 3 atendidos e 5 com trabalho; a tabela dá 4 e 4. Corrigido.
5. CONTRATO: `provenance.method` dos dois selos fora do padrão. Corrigido.

## Limites

- O corte é pelo nome do arquivo: nome com data antiga escapa.
- A guarda vê a marca, não o conteúdo.
- Medidas do sandbox, do quadro e da fila são da curadoria, não refeitas.
