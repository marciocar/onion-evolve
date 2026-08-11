---
branch: fix/backup-cron-and-plaintext-guard
date: 2026-08-11
reviewed_diff_sha256: 4f763b0c8c37500126dba09f50dd8ba80ab20f160debaec2265e758f9c3a92ba
findings_total: 7
findings_real: 7
findings_fixed: 7
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

---

## Passada adversarial — o escopo que eu declarei estava errado

Ataquei a afirmação *"só os `backups/` das ferramentas da casa"* perguntando se existia backup
**fora** dela. Existia, e o achado é maior que o caso original:

| local | estado |
|---|---|
| `/home/marcio/backups/bridge` | **17 arquivos sem cifra**, um deles `644` |
| `/home/onion/.claude/backups` | 5 arquivos, fora do escopo |

Os `bridge-diario-*.tar.gz` carregam o **`.env` do bridge** — `ANTHROPIC_API_KEY` e tokens de
convite. Ficavam em claro em disco.

**Guarda com escopo menor que a classe é verde-vazia onde não olha** — e a minha estava. O escopo
agora é explícito, um caminho por linha: acrescentar diretório novo exige acrescentar ali, e essa
fricção é o ponto.

### Curado na origem, não só no passivo

`ops/bridge-backup.sh` passa a cifrar, com as três lições já pagas hoje embutidas: dono do artefato,
`gpg` como dono da chave quando root, e verificação que não exige a chave privada.

E um defeito de **relato**: o `echo` final media o `.tar` em claro — que o `shred` já tinha
destruído — e anunciava um arquivo inexistente. **Relato que nomeia o artefato errado é pior que
relato ausente**: quem lê procura e não acha. O `SIZE` passou a ser recalculado depois da cifra.

### O passivo, e o limite da prova

17 arquivos cifrados, 0 falhas. **18 verificados como OpenPGP válido**, com o `keyid` do destinatário
(`4620B77B86EDFE42`) batendo com a subchave de cifra do `pass`.

⚠️ **Provei a estrutura, não a restauração.** Decifrar exige a passphrase e sem TTY o `gpg` falha com
`Inappropriate ioctl for device` — que é a **minha medição** não podendo rodar, não o arquivo
quebrado. Distinção que esta sessão errou várias vezes na direção contrária, e que fica declarada em
vez de arredondada.
