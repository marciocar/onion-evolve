---
branch: fix/backup-cron-and-plaintext-guard
date: 2026-08-11
reviewed_diff_sha256: 5a0252cd7fa407d4a7a00b28cca02f8d5d358580c1dc54811208ead4dbace28f
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 0
verdict: TRES-DEFEITOS-EMPILHADOS-NO-CRON-E-UMA-CLASSE-NOVA-QUE-NADA-VIGIAVA
reviewer: simulação do caminho real (root) além do caminho testado (marcio); par acusa/cala por mutação na guarda nova
---

# O backup teria parado hoje à noite, em `/dev/null`

Pôr passphrase na chave GPG — correto e necessário, ela era o segredo de maior alcance da máquina e
estava **nu** — quebrou o acesso não-interativo ao `pass`. Os backups do cron **falhariam esta
noite**, e falhariam **fechado** (recusando gravar em claro, que é o lado certo) — só que em
`/dev/null`. Teria simplesmente deixado de existir backup.

## Três defeitos empilhados, cada um escondendo o próximo

| # | defeito | por que só apareceu depois |
|---|---|---|
| 1 | `${HOME}/.password-store/.gpg-id` | como root, `${HOME}` é `/root` |
| 2 | `gpg` como root usa chaveiro **vazio** | só visível depois de curar o (1) |
| 3 | `marcio` não lê artefato `root:root 600` | só visível depois de curar o (2) |

O **(3) expôs uma assimetria que ninguém tinha visto**: o dump do Logto nascia **`644`** e por isso
"funcionava". Havia uma janela em que o banco de **identidades** ficava legível por qualquer uma das
5 contas com shell. Agora nasce `600` e muda de dono.

**A lição:** eu testava só como `marcio`, e o cron é `root`. **Testar no caminho errado é não
testar** — mesma família do `sso_users` medido numa cópia e do `404` que era artefato de sessão.

**Verificado nos quatro caminhos** (2 scripts × 2 usuários), todos `rc=0`.

## A classe nova que nada vigiava

`BACKUP-EM-CLARO` na guarda de exposição. Nasceu de 19 dumps `root:root 644` em disco — dado
sensível em repouso, e um modo de falha **silencioso por natureza**: um `.sql` a mais num diretório
de backup não chama atenção.

**Par acusa/cala provado por mutação**: com uma sonda `.sql` no diretório a guarda sai **1** nomeando
o caminho; removida, sai **0**.

Duas decisões de escopo, ambas deliberadas: só os `backups/` das ferramentas da casa (varrer o disco
atrás de "coisa que parece backup" seria falso-positivo em massa), e `find` em vez de glob — **glob
sob `sudo` expande no shell do chamador e devolve vazio**, que é o fail-open que este arquivo existe
para impedir.

## Declarado, e é decisão do maestro

Os três `up.sh` leem do `pass`: **reiniciar serviço agora exige interação**. As saídas são presetar a
passphrase no agente (devolve automação, **enfraquece de volta** — o arquivo vira o novo segredo nu)
ou uma chave separada só para automação (isola o dano, **multiplica segredo**). Não escolhi: as duas
desfazem parte do que acabou de ser ganho, e essa troca é do dono.
