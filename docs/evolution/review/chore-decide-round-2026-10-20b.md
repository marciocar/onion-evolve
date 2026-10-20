---
branch: chore/decide-round-2026-10-20b
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 0915be1739c3240f7cd591ace2ce2ac857934c9a165d1c64db478474fe701df4
reviewed_code_sha256: 9395ce17940fb6c2a341b7d639cd00a0aacc3e92484d1ab9a96221fb4926aeac
findings_total: 3
findings_real: 2
tokens: 0
duration_min: 25
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, com medição no vivo das units; sem subagentes
nota: ""
---

# Passada adversarial: `chore/decide-round-2026-10-20b`

## O que muda

- **Selos do maestro (2026-10-20):**
  - `D_N2_SEPARAR_A_ESCRITA_DO_CHAT_DA_CONFIANCA_DO_A2A`: fechar, com o resíduo declarado.
  - `D_CANAL_UPSTREAM_POR_VENDOR` (novo, em `field-hub-update-2026-10-19`): o sinal ao upstream de um vendor vai
    direto ao dono.
- **Fechados pelo fluxo normal, sem novo selo:** `Q_MERGE_PROCESS_ONION_2026_10`,
  `Q_POSTMERGE_PROJECTION_WRITER_2026_10`, `D_ISOLATE_CHAT_AGENT_FROM_TRUST_ROOT` e `Q_CHAT_AGENT_ISOLATION_2026`.
  As decisões deles já tinham sido seladas em 10-13, 10-14 e 10-16, e a evidência está citada em cada nó.

## Achados

1. **REAL (curado, e de método):** a pergunta do N2 ao maestro descrevia o estado dos degraus pelo grafo, de 10-16,
   sem medição no vivo. O maestro perguntou se eu tinha revisado. Medi antes de commitar
   (`systemctl show` da unit do bridge e da unit do runner). A premissa se confirmou e apareceu um detalhe a mais:
   o `docs/evolution/trust-log.md` do clone servido também é gravável pelo serviço. O selo foi refeito com o texto
   exato.
2. **REAL (curado):** a 2ª versão do selo trazia caminho absoluto de máquina. A REGRA 99 (Nó de .kg.yaml sem
   caminho de máquina, julgado pela classe) recusou, o selador desfez a escrita, e o texto foi reescrito pela forma.
3. **Refutado:** "fechar as quatro perguntas é selar sem perguntar?" Não é. Cada uma tinha a decisão já selada
   pelo maestro, e a própria Q_MERGE dizia ficar aberta "até o maestro selar D_MERGE…". O fechamento cita esse nó.
   O D_ISOLATE cita os 5 selos de degrau e a medição de hoje.

## Mutantes

Nenhum: não há código. O radar `--integrity --schema` sai 0 nos 5 grafos e o `ops/kg-gate-ci.sh` não acusa PIOROU.

## Limites declarados

O kg-writer na 4.12.0 e a prova de bloqueio do gate, as outras duas respostas da rodada, são execução e saem em
trabalho próprio.
