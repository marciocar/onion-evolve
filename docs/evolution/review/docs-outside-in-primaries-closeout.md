---
branch: docs/outside-in-primaries-closeout
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: 88afe9058b9990d0cff16cb1024e4cc0c20093e73dd5b7d3ef8a0746ffec21af
reviewed_code_sha256: 87c45f0069594707353fc963f36ec1db7911df7253acaf1aa2871c8350d11c5b
findings_total: 4
findings_real: 4
findings_blocking: 1
tokens: 0
duration_min: 0
findings_fixed: 4
verdict: FIXED
elenxo: true
elenxo_isolado: false
reviewer: "Elenxo do workflow wf_d23ecc85-e21, passada separada sobre as 46 claims do grafo (quem julgou não escreveu; opus); e passada própria do agente de execução sobre o fechamento, com gate mecânico kg-radar, kg-contract-check e kg-backlog-check"
nota: "tokens e duração da passada de fechamento não medidos (0); o custo do Elenxo está no run e na SYNTHESIS. O Elenxo julgou o grafo, não este diff: a parte nova (7 nós, SYNTHESIS, migalha) só passou pela passada própria. Sem código."
---

# Passada adversarial: `docs/outside-in-primaries-closeout`

O Elenxo do workflow é a passada separada sobre o conteúdo da rodada. Ele produziu 32 objeções sobreviventes, 13
bloqueantes, todas no grafo. Elas foram aplicadas pelo escritor do workflow, antes deste diff.

No fechamento, a passada própria achou quatro defeitos, todos corrigidos antes do commit:

1. **(bloqueante)** Os 7 itens ATRÁS vinham de heads antigos. Cada um foi medido de novo no vivo; os 7 seguem reais,
   e o comando e o resultado estão em `verified_against`.
2. O critério de pronto do Agent Card citava `a2a-agent-card.sh` como verificação, mas é gerador. Virou "regenerar
   não deixa diff", no nó e em SAC-363 (a tarefa do Agent Card).
3. A contagem de pins usava `2>/dev/null` sobre um diretório ausente. Refeita sem supressão, com o mesmo 7 e 12.
4. Duas linhas ALINHADO do vigia descreviam código fora da main. A SYNTHESIS as marca "só no PR #8", ainda aberto.

Dois limites ficam declarados: as linhas ALINHADO e DIVERGE marcadas "não remedido" continuam sendo posição de 1
agente, e nada se afirma sobre o binário do Scorecard ou o nível SLSA L3.
