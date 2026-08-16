---
branch: docs/human-gates-closed
pr: 614
date: 2026-08-16
reviewed_diff_sha256: ac00a700149ffacb8c403a935d1fce06a06c2f1a5dd5d5f674479b9e4bba46d0
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 4
verdict: CONFORME
reviewer: carimbo por MEDIÇÃO dos rastros (tenant + ledger), não pela declaração — a passada achou um item do roteiro sem nenhuma evidência
REVISOU: true
---

# Resíduo — `docs/human-gates-closed`

Dois nós de gate mudam de status. O que revisar aqui não é código, é **se o carimbo
corresponde ao medido** — e a passada existiu justamente para isso.

O maestro disse "prova foi feita". Em vez de carimbar pela frase, medi os rastros:

- **G-ID → `done`**: org com membro real; ledger do bridge com **25 linhas `org`
  preenchido** sobre 4 subs (o critério pedia uma).
- **Q_ROUND → `confirmed`**: identidade criada 21:58 entrando 22:08 **com username**
  (MissingProfile fechou); `Totp`+`BackupCode` em duas contas (a ordem obrigatória do
  Logto), com `hasPassword=sim`; 1 PAT vivo em cada.

**Achado da passada (o único, e é o que importa):** o 5º item do roteiro — reenviar
convite de org — **não deixou rastro nenhum** (0 convites na org; ela segue com 1
membro). Carimbar `done` teria embutido um quinto invisível dentro de um veredito de
sucesso: exatamente a classe "parece sucesso" que esta sessão passou o dia curando
(approve-sem-convite na F-ID.4; 2FA meio-ativado no Elenxo da rodada). Por isso o nó
fica `confirmed`, com o gatilho nomeado no próprio label.

Nota de processo: a guarda `BRANCH-EM-PT-BR` acusou o nome original desta branch
(`docs/gates-humanos-fechados`) antes do PR virar referência — renomeada enquanto era
grátis, PR #613 fechado e reaberto como #614.
