---
branch: chore/maestro-seals-1109
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: 843775f10f5b9223213e718b1e628bb7ba1799047d4539000ec61d961ece5c4a
reviewed_code_sha256: fdf7a5effce8258103248e88fb2fa66009ea1ffa49c4e711f4995fb37a6b54ef
findings_total: 2
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: passada própria do agente de execução sobre o próprio diff, sem subagente (o brief proíbe criar agentes); gates mecânicos kg-radar e kg-contract-check, execução direta do bwrap
nota: "tokens e duração não medidos (0). Quatro selos, uma evidência e o fechamento medido de uma pergunta; sem código."
---

# Passada adversarial: `chore/maestro-seals-1109`

## O que muda

- `docs/onion/graph/maestro-decisions-1108.kg.yaml`: a evidência da rodada de 2026-11-09 e os 4 selos dela. O teto
  declarado sobe de 18 para 23 nós, com o motivo no `meta:`.
- `docs/onion/graph/coordenacao-sessoes-2026-10.kg.yaml`: `Q_COORD_MAESTRO_APPARMOR_BWRAP_1106` fecha por medida.

## Achados

1. MEDIDA FALSA (corrigido antes do commit): a primeira conferência contou processos `bwrap` com `ps` e devolveu 2, mas
   o que casava era a própria linha do comando, que citava o perfil. Na segunda leitura deu zero. A medida virou a
   execução direta do `bwrap` com unshare de user e pid, que sai 0 com a restrição do kernel ligada, mais a leitura do perfil e
   do settings da curadoria. O `evidence_class: testimony` saiu do nó, porque a base agora é medida.
2. CAMINHO DE MÁQUINA (corrigido antes do commit): o contrato reprovou caminhos absolutos do host no `verified_against`
   (REGRA 99, Nó de .kg.yaml sem caminho de máquina, julgado pela classe). Foram reescritos na forma ⟨descrição⟩.

## O que fica de fora, por decisão

- `Q_IT_AGENT_MAIL_RIDER_READING` mora em `docs/onion/graph/inbox-triage-1108.kg.yaml`, que só existe no PR #1555, ainda
  aberto. O selo `D_MD_AGENT_MAIL_NO_LEGAL_READING_1109` entra aqui e cita o nó pelo id; o fechamento dele depende do merge
  daquele PR.
- `Q_COORD_MAESTRO_UPDATE_CONSULTORIA_1106` e SAC-293 seguem abertos: o selo decide, e o registro e o update são de outro agente.
- A redação das quatro perguntas é do agente de execução, porque o brief trouxe o tema e as opções, sem o texto literal.
