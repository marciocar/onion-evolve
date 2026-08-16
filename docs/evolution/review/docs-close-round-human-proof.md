---
branch: docs/close-round-human-proof
pr: 620
date: 2026-08-16
reviewed_diff_sha256: f6f84b2e7f28c89628a29dd8bcf8e3efcbcb307f068f6e201f3f4d198248cf6a
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 5
verdict: CONFORME
reviewer: passada sobre o CARIMBO — a pergunta revisada é se o nó distingue o que eu medi do que me foi contado
REVISOU: true
---

# Resíduo — `docs/close-round-human-proof`

Mudança de um status (`confirmed` → `done`) e um label. O que há para revisar é se o
carimbo mente sobre a origem da evidência.

**Achado:** as duas provas deste fechamento têm naturezas diferentes e o primeiro rascunho
do label as fundia num "verificado" só. Corrigido: o **✖️ cancelar** está MEDIDO (li o
tenant: `Pending` → `Revoked`); o **🔁 reenviar** está ATESTADO pelo maestro (o e-mail
chegou na caixa dele — não deixa rastro de estado, e a caixa de entrada dele é a única
fonte possível). Chamar as duas de "medido" seria exatamente a classe `declarado ≠
verificado` que esta rodada passou o dia curando — desta vez cometida no ato de fechá-la.

Limite que fica: nenhum mecanismo do bridge registra "e-mail enviado com sucesso" (o Logto
devolve 204 e o resto é com o Postmark). Se algum dia isso importar como auditoria, é
feature nova, não ajuste — e não está pedida.
