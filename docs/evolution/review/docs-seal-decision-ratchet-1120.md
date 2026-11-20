---
branch: docs/seal-decision-ratchet-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: 242f4dd1de19fbe8227901817ff31e23208691b657ad39cb81de63d089a7bd96
reviewed_code_sha256: 2794f4e69d980da9b8b3af7c2a6be7759b4f1474b9905728ed440555b24912fc
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 3
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: true
elenxo_isolado: false
reviewer: "Passada da própria sessão do core, só leitura: quatro nós novos pelo kg-decide-seal (radar exit 0) com as respostas do maestro em 20/11 à síntese do Delphi catraca-1120 (7 sessões, 6 aceites e 1 objeção pontual)."
nota: "tokens 0 = não medido. Não toca guarda."
---

# Passada adversarial: `docs/seal-decision-ratchet-1120`

## O que muda

Quatro selos: a síntese da catraca de decisões (com a exigência de documentar para explicação e auditoria); o pode
rodar (classe B) vale já; o PR #111 da ponte segue e as medições de mods da curadoria estão liberadas; até o executor
separado, o automático só para ato que não muda estado.

## O que se tentou refutar

Algum selo afirma escolha que o maestro não fez? O do automático veio depois de ele perguntar se o ambiente é sandbox;
a medição (usuário do maestro, sudo sem senha, token de dono, sem sandbox) foi mostrada e ele escolheu a opção 1. O
selo da síntese registra o acréscimo dele sobre documentação. Nenhum nome comercial de membro privado nos rótulos.
