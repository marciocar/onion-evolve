---
branch: feat/session-merges-own-guard-1118
pr: pendente
date: 2026-11-18
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 7
findings_blocking: 4
tokens: 0
duration_min: 50
findings_fixed: 6
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Duas passadas por agentes revisores separados (code-reviewer), só leitura, mandato de refutar, com sondas em mktemp (claude e gh falsos, nenhum merge real). 1ª (cf2729c53): REJECTED — A1 --maestro desligava a catraca fora do core; A2 a variável de bancada desligava catraca e gate de guarda; A3 a catraca julgava um slug e o gh ia para outro; M1 a sessão mergearia a própria catraca. Curados no ded021dbc. 2ª (ded021dbc): A1, A2, A3 e B1 curados; REJECTED porque o M1 não cobria o hook do veto em que A1 e A2 se apoiam. Curado no 87ea715ba (lista ampliada com o hook, o juiz, o tokenizador e os settings). O último delta, só a lista, foi conferido pela sessão do core, sem 3ª passada separada."
nota: "tokens 0 = não medido (o harness não devolveu o custo dos revisores); duration_min soma as duas passadas, ~25 min cada pelo teto. O merge deste PR é do maestro: ele toca a própria catraca (M1)."
---

# Passada adversarial: `feat/session-merges-own-guard-1118`

## O que muda

Decisão do maestro de 18/11 (`D_SESSIONS_MERGE_OWN_PRS_INCL_GUARD_1118`): cada sessão merja os PRs do próprio repo,
inclusive os de guarda, e a liberdade vale só no repo próprio, numa catraca de lista fechada.

- **Guarda pela sessão:** `ops/pr-merge-verified.sh` aceita PR de guarda sem `--maestro` quando o resíduo da branch
  declara `elenxo: true`, `elenxo_isolado: true`, verdict aceito e diff carimbado; sem isso, recusa dizendo o que falta.
- **Catraca de repo próprio:** qualquer sessão Claude só merja no repo dela, que tem de ser do dono do core e estar no
  `members.yaml` de origin/main com `kind: source` ou `owner_session:` (nunca porta). Repo de cliente ou empresa é
  recusado sempre. Fora do core, `--maestro` e a variável de bancada não pulam a catraca, e o gh recebe o alvo julgado.
- **A própria catraca segue do maestro:** PR que toca o script de merge, o registro de membros, a tabela de atos, o hook
  do veto, o juiz, o tokenizador que o hook carrega ou os settings que o registram.
- Deploy, produção, firewall, segredo e publicação externa seguem vetados à sessão.

## As passadas

- **1ª (REJECTED):** A1, A2 e A3 (contornos da catraca fora do core, todos medidos por sonda) e M1 (a sessão
  mergearia a própria catraca, medido por leitura: `marciocar/brain-dufrio` é origin de uma consultoria). B1, B2 e B3
  baixos.
- **2ª (REJECTED):** A1, A2, A3 e B1 curados e medidos por sonda; o M1 não incluía o hook do veto, de que A1 e A2
  dependem (caminho em dois PRs, por leitura).
- **Último delta (87ea715ba):** a lista do M1 ganhou o hook, o juiz, o tokenizador e os dois settings; casos m1c, m1d e
  a2c com mutantes mortos. Conferido pela sessão do core na leitura do diff; famílias pr_merge_verified, moat_gate e
  members_registry com 622 casos e 0 falhas.

## Tetos declarados (na doutrina)

Host GitHub Enterprise; chave do `members.yaml` entre aspas; processo desligado da árvore (setsid/nohup) perde o
ancestral Claude; Claude instalado por npm; sessão de repo de peça que reaponta o próprio origin para o core; o
`elenxo_isolado` é auto-atestado no resíduo (o script exige a declaração, não a prova). A Parte 2 (o veto vira pedido de
permissão de um toque) ficou só no desenho: o modo das sessões desta casa é bypass, e a documentação não garante que o
`ask` de hook segure nele.
