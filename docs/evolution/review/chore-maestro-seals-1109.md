---
branch: chore/maestro-seals-1109
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: db147005cbec63310c0a8f039601be2a63953516d24e11e7f779077a2a3cf3d1
reviewed_code_sha256: 29cab211b1a8f224501387bf5d233fc60d12157e7b3c5cbec19a9c803d501394
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
  declarado sobe de 18 para 24 nós, com o motivo no `meta:`.
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
- A redação das quatro perguntas é do agente de execução, porque o brief trouxe o tema e as opções, sem o texto literal.

## Re-revisão do delta (consultoria já feita)

A pergunta do item 2 estava vencida. Conferi as medidas antes de escrever: PR #1522 do core mergeado, membro no ledger, PR #1
do adotante mergeado em `800b06aa2c10`, e `source_commit` `e4c954ebad47` na main dele. O nome do repo do adotante leva o
do cliente e não entra em nenhum arquivo deste PR. `D_MD_CONSULTING_ADOPTER_REGISTER_1109` passa a dizer que os atos já estavam feitos, `Q_COORD_MAESTRO_UPDATE_CONSULTORIA_1106` fecha por
medida, e `Q_MD_CONSULTING_NEXT_UPDATE_1109` é o único item aberto, dependente da cura da SAC-302. Radar e contrato em rc 0. Sem achado novo.
