---
branch: fix/close-open-loops-vault-bridge
date: 2026-08-11
reviewed_diff_sha256: 780f39648f5c9e7cb438f59362de15384265b50326a9415e6d2ed0d3ba3a1174
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 0
verdict: OS-DOIS-LACOS-NAO-PROVADOS-FECHARAM-COM-LOGIN-REAL-E-UM-DELES-POR-CALCULO
reviewer: verificação por comportamento com o maestro operando o navegador; contagem no SQLite do cofre e conferência aritmética do slug do workspace
---

# Os dois laços que a passada adversarial marcou como não-provados

O PR #578 declarou duas coisas **destravadas, não provadas** — e a passada adversarial contra ele
estava certa em recusar o arredondamento. Ambas fecharam com login real.

## 1. SSO do cofre — `sso_users: 0 → 1`

Medido no SQLite: `users = 1`, `sso_users = 1`, zero erro novo no log.

> ⚠️ **Correção de um número meu, achada na passada adversarial contra este PR.** Eu havia escrito
> `devices = 1` — medido de uma **cópia** do banco tirada antes. No banco **vivo** são **2**: o
> maestro registrou um segundo dispositivo depois. O erro é pequeno e a classe não é: medi um
> snapshot e relatei como estado atual. É a quarta vez nesta sessão que confundo *quando* medi com
> *o que é verdade agora*. Primeiro caso
público conhecido de **Vaultwarden + Logto** funcionando ponta a ponta.

**Três defeitos reais estavam no caminho, e nenhum era o que eu supus:**

| # | defeito | por que quebrava |
|---|---|---|
| 1 | `SSO_SCOPES` pedia `offline_access` | o Logto não emite `refresh_token` para este cliente, e o Vaultwarden trata a ausência como **erro** |
| 2 | cofre com **zero contas** e `SIGNUPS_ALLOWED=false` | o **primeiro** entrante não tinha por onde nascer; `INVITATIONS_ALLOWED=true` não resolve sem SMTP |
| 3 | **duas contas `marciocar`, uma por tenant, senhas separadas** | o maestro recuperou a do `admin` (console); o cofre vai para o `default` |

O (1) é o mais transferível: **pedir escopo que o IdP não honra é declarar capacidade que não
existe** — e o erro aparece do lado do cliente, longe da causa.

O (3) é o meu. Tratei *"recuperei a senha"* como se fosse uma só. **O dado estava neste grafo desde
ontem** — dois tenants, duas identidades — e eu não fiz a ligação.

E antes de tudo isso a recuperação **nem existia**: `forgot_password_methods` era `[]` nos dois
tenants. Eu havia **afirmado** que o caminho de volta existia com base no conector SMTP *estar lá* —
inferência de configuração, não medição de comportamento. Ligado e verificado na API viva.

## 2. Workspace por identidade — provado por CÁLCULO

O login produziu `94c9a93e606c64b2`, e `sha256("xwl2pkq5bdvb")[:16]` — o `sub` da identidade no
Logto — dá **exatamente** esse valor.

Isso é mais forte que "apareceu um diretório novo": é **verificável por aritmética**, não por
confiança. Antes disso o código estava trocado e o serviço bootava — mas a chave nunca tinha sido
exercitada, e foi exatamente isso que a passada adversarial recusou aceitar como provado.

## A janela, aberta e fechada no mesmo dia

`SIGNUPS_ALLOWED` foi a `true` pelo tempo do primeiro login e voltou a `false`. Verificado por
comportamento: `POST /identity/accounts/register` → **400**, cofre → **200**, e a sessão do maestro
sobreviveu ao fechamento.

**Quem precisar de outro entrante reabre pelo mesmo caminho, com janela curta** — endpoint HTTPS
público com cadastro aberto é um cofre em que qualquer um entra.
