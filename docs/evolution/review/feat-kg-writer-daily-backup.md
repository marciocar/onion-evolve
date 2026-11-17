---
branch: feat/kg-writer-daily-backup
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: pendente
findings_total: 13
findings_real: 11
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 11
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "1ª passada: o agente de execução do core, sobre a proposta de partida e o próprio diff. 2ª passada independente em 2026-11-17: agente revisor separado, só leitura, com mandato de refutar em sete eixos"
nota: "tokens 0 e duration_min 0 = não medidos: nem a 1ª passada (o próprio agente que escreveu o diff) nem a 2ª (o revisor separado) tiveram cronômetro ou contagem repassados a este resíduo. O backup NÃO rodou contra o dado real, nada foi agendado e nenhum serviço foi tocado: a primeira execução e a ativação são do maestro."
---

# Passada adversarial: `feat/kg-writer-daily-backup`

## O que muda

- **`ops/kg-writer-backup.sh` (core-only), novo.** Backup cifrado da raiz de dados do onion-kg-writer: tar da raiz,
  conferência da listagem (a raiz e ao menos uma área com `.git/HEAD`), cifra para os destinatários do cofre de
  senhas rodando o `gpg` como o dono da chave, conferência do `.gpg` pela saída do `--list-packets`, modo 0600 num
  destino 0700 e retenção de 14 diários. Partiu de uma proposta de outra sessão; as diferenças estão nos achados.
- **`ops/update-kg-writer.sh` (core-only), passo 3.** O tar pré-deploy, que saía em claro, passa a sair pelo script
  novo com o rótulo `pre-<sha>`. O resto do fluxo de atualização não muda.
- **`ops/mcp-onion-kg-writer/README.md`.** Seção do backup: o que pega, o que não pega, as variáveis e os passos do
  maestro (primeira execução, conferência, ensaio de restauração, agendamento sugerido como texto, como desfazer).
- **`.claude/validation/lint-selftest.sh`.** Família nova `kg_writer_backup`: 36 verificações (29 na 1ª passada, 7 a
  mais com as curas da revisão independente).
- **`ops/moat-targets.tsv` (core-only).** Uma linha `fecho` para o script novo, exigida pela REGRA 117 (Ato de
  deploy tem assinatura no veto).
- **`docs/onion/testing-inventory.md`.** Regenerado pelo `harness-inventory.sh` (342 famílias).

## Achados

Treze pontos examinados: dez na 1ª passada e três vindos da revisão independente. Onze reais, todos corrigidos
neste diff; nenhum bloqueante.

1. **Dono da chave fixo no código (real, corrigido).** A proposta trazia o nome do usuário numa variável literal, e
   este repo é público. O dono agora vem de `ONION_KG_BACKUP_OWNER`; sem ela, é quem roda, ou o `SUDO_USER` quando
   quem roda é root; root sem `SUDO_USER` (ou com `SUDO_USER=root`) é recusado antes de qualquer escrita.
2. **Root escrevia no destino do operador (real, corrigido).** A proposta criava o destino, dava `chown`, `chmod` e
   `rm` como root num diretório de outro usuário. É a classe que o `ops/bridge-backup.sh` (core-only) já documenta:
   symlink com nome previsível vira escrita de root. Agora o root só lê a raiz de dados; tudo o que toca o destino e
   a leitura do arquivo de destinatários roda como o dono. O claro entra no `gpg` pelo stdin, então o temporário
   não precisa mudar de dono.
3. **Rótulo sem validação (real, corrigido).** O rótulo entra em nome de arquivo. Agora só `[a-z0-9-]`, sem hífen na
   ponta, até 32 caracteres, e mais de um argumento é recusado.
4. **Retenção por `ls -1t | tail | xargs rm` (real, corrigido).** Ordenava por mtime (um `touch` muda a ordem) e
   passava nome por linha. Agora: só arquivo regular, só dentro do destino, só nome que casa a expressão exata do
   diário, ordenado pelo carimbo do nome, com separador NUL. Destino que é symlink é recusado.
5. **Saída do `gpg` e do `tar` repassada (real, corrigido).** O stderr do `gpg` traz o destinatário e o do `tar`
   traz nome de área (que deriva de e-mail). Nenhum dos dois é repassado; a mensagem de erro traz só o rc.
6. **O `.gpg` nascia com o nome final antes da conferência (real, corrigido).** Agora nasce com nome provisório
   dentro do destino e só é renomeado depois do pacote e do modo conferidos. Falha no meio não deixa arquivo com cara
   de backup bom.
7. **Aviso falso de «o shred falhou» (real, corrigido).** Defeito da primeira versão deste diff, achado no ensaio
   ponta a ponta: com a cifra falhando antes de criar o provisório, a limpeza tentava triturar um arquivo que não
   existia e avisava. A limpeza agora confere a existência antes.
8. **«Não corrompe o repositório» era forte demais (real, corrigido no texto).** O tar com o serviço de pé não é
   instantâneo atômico: a cópia de uma área pode sair com a ref um commit à frente dos objetos. O README diz isso,
   diz que o `git fsck` da restauração acusa e como recuperar pelo reflog. É leitura do modelo do git, não medição.
9. **`tar` com rc 1 (arquivo que mudou durante a leitura) derruba o backup do dia (examinado, não é defeito).** É a
   falha fechada pedida. Fica declarado no README; se virar ruído no uso real, a decisão de tolerar o rc 1 é do
   maestro.
10. **`ops/moat-targets.tsv` (core-only): o script novo entra como `fecho`, não como `ato` (examinado, não é
    defeito).** A REGRA 117 (Ato de deploy tem assinatura no veto) reprovou a primeira versão: o
    `update-kg-writer.sh` é ato e passou a executar um script fora da lista. A cura é a linha
    `fecho script ops/kg-writer-backup.sh -`, no molde da linha do `bridge-backup.sh`: um PR que mude o backup passa
    a ser PR de guarda. Promover o script a `ato` (vetar a sessão de rodá-lo) é decisão do maestro e não foi tomada.

11. **Raiz sem área travava o deploy (real, não bloqueante, corrigido; da revisão independente).** A conferência
    exigia ao menos uma área com `.git/HEAD`; com a raiz vazia (serviço recém-instalado) o backup recusava e o passo 3
    da atualização parava, o que o tar antigo não fazia. Agora raiz vazia de verdade (só ela na listagem do tar) é
    estado válido: aviso no stderr, `.gpg` normal, rc 0. Raiz com alguma entrada e nenhuma área com `.git/HEAD`
    continua recusando.
12. **SIGHUP fora dos traps (real, não bloqueante, corrigido; da revisão independente).** Os traps cobriam EXIT, INT e
    TERM; entrou HUP com saída 129. Medido à parte: o bash já roda o trap de EXIT ao morrer por HUP sem trap próprio
    (rc 129, limpeza feita), então a linha nova é explícita e não a única defesa. Por isso o caso não tem mutante.
13. **Relógio para trás derrubava o recém-nascido (real, não bloqueante, corrigido; da revisão independente).** Com
    14 ou mais diários de carimbo posterior, o diário recém-publicado ordenava como o mais antigo e caía na retenção.
    A retenção agora exclui dos candidatos o arquivo que a própria execução publicou. O desenho (ordenar pelo carimbo
    do nome) não mudou.

## Mutantes

Dez, plantados numa cópia do script por substituição literal. Cada âncora casa exatamente uma linha (a bancada
recusa âncora que aparece 0 ou 2 vezes, cópia igual ao original e cópia que não é bash válido), e cada um é morto
pelo caso nomeado:

| Mutante | Caso que reprova |
|---|---|
| tirar a conferência do `.git/HEAD` na listagem | `tar-sem-git-head-recusa` |
| aceitar qualquer saída do `--list-packets` | `gpg-sem-pacote-apagado` |
| expressão do diário frouxa (casa qualquer rótulo) | `retencao-16-ficam-14-rotulados-intactos` |
| tirar o `trap` de saída | `gpg-falha-nada-no-destino-claro-triturado` |
| tirar o `-type f` da listagem da retenção | `symlink-no-destino-nao-alcanca-fora` |
| validação do rótulo só para vazio | `rotulo-invalido-recusa-antes-de-escrever` |
| root sem dono vira dono `root` | `dono-nao-derivavel-recusa` |
| aceitar destino que é symlink | `destino-symlink-recusa` |
| toda falta de `.git` vira estado válido | `area-sem-git-recusa` |
| retenção sem excluir o recém-publicado | `relogio-para-tras-recem-nascido-fica` |

Medido: `LC_ALL=C ONION_LOAD_LEASE_HELD=1 bash .claude/validation/lint-selftest.sh --families kg_writer_backup --jobs 2`
deu 29 passaram, 0 pularam, 0 falharam na 1ª passada e 36 passaram, 0 pularam, 0 falharam depois das curas da
revisão independente (20 casos, a contagem, 10 mutantes, 3 casos do passo 3 do update, 2 com o `gpg` real). Na 1ª
passada, com as duas famílias que leem o `moat-targets.tsv` (core-only) de verdade
(`--families act_signature,moat_gate,kg_writer_backup`): 472 passaram, 0 pularam, 0 falharam.

## Revisão independente (2026-11-17)

Segunda passada, por agente revisor separado, só leitura, com mandato de refutar em sete eixos. Sem defeito
bloqueante; três observações, que são os achados 11, 12 e 13 acima.

**Medido por ele:**

- a família `kg_writer_backup` em 29 de 29 (o estado da 1ª passada), com `gpg` e `git` reais e chave descartável;
- dois mutantes aplicados à mão: retenção que apaga tudo reprova três casos; limpeza sem triturar reprova três casos;
- o backup recusa antes de o `update-kg-writer.sh` (core-only) tocar código ou serviço;
- nenhuma referência ao nome antigo do artefato;
- script, README e bancada sem pessoa, e-mail, host nem id de chave.

**Lido por ele:**

- a classe `fecho` na tabela do veto é a certa: o script não é o deploy, é chamado por ele. A linha não vira alvo do
  veto e só satisfaz a REGRA 117 (Ato de deploy tem assinatura no veto); o script de atualização segue como ato
  barrado à sessão.

**Não verificado por ele:**

- execução contra o dado real;
- o caminho de root de verdade: só com dublê de `id` e de `sudo`, que pode esconder diferença de sudoers e de `PATH`;
- cron e systemd.

## Limites declarados

- **Nada rodou contra o dado real.** A raiz de dados, o destino e o cofre de verdade não foram lidos. O que a
  bancada prova é o script sobre uma raiz falsa; a prova com o `gpg` real usa chave descartável sem passphrase num
  `GNUPGHOME` temporário.
- **O caminho de root é exercido com dublê de `id`**, não como root: a bancada confere que o tar roda direto e que
  cifra, destino e destinatários passam por `sudo -n -u <dono>`, mas o `sudo` é dublê. O comportamento do `sudo` e do
  `gpg` reais sob o cron do root (ambiente, chaveiro, agente) só a primeira execução do maestro prova.
- **A chave do cofre tem passphrase, a da bancada não.** A cifra não pede a passphrase (usa a chave pública), e a
  listagem sem a privada destravada foi medida com um chaveiro só de chave pública (rc 2, com o pacote na saída).
  Com o agente do dono destravado o rc da listagem pode ser 0; o script não olha o rc.
- **O `update-kg-writer.sh` não tem bancada própria** (caminhos e unidade reais). O passo 3 é extraído do script e
  rodado isolado contra o backup; os outros passos não foram exercidos, e não mudaram.
- **Precondição nova do deploy:** o operador que roda a atualização precisa ter o arquivo de destinatários do cofre
  e a chave pública no chaveiro. Sem isso o backup recusa e a atualização para antes da troca do código.
- **O nome do artefato pré-deploy mudou** de `onion-chat-kg-<data>-pre-<sha>.tar.gz` para
  `onion-chat-kg-pre-<sha>-<data>.tar.gz.gpg`. Os arquivos antigos em claro continuam no destino.
- **`ops/migrate-python-service.sh` (core-only) ainda faz um tar pré-troca em claro** da mesma raiz. Ficou fora do
  escopo deste diff.
- **Mesmo disco.** O backup não é cópia fora da máquina.
- **`ops/update-kg-writer.sh` (core-only) traz caminho de home fixo**, pré-existente na main e fora deste diff.
- **O caso do HUP não envia o sinal de fora:** o dublê do `gpg` sinaliza o script (o pai dele) e dorme, o que tira a
  corrida do caso. Um HUP vindo do terminal ou do cron, para o grupo de processos inteiro, não foi exercido.
- **Relógio para trás:** só o recém-publicado é protegido. Os diários de carimbo posterior continuam contando como
  mais novos até o relógio os alcançar.
- **Bancada parcial.** A linha nova do `moat-targets.tsv` (core-only) seleciona 30 famílias pelo mapa da bancada;
  rodaram as duas que julgam a tabela (`act_signature`, `moat_gate`) e a família nova. As outras 28 ficam para o CI.
- **`lint-artifacts.sh`:** a primeira passada inteira acusou 2 HARD, ambas deste diff: REGRA 80 (Números do harness
  saem de SSOT gerada, nunca de comentário) e REGRA 117 (Ato de deploy tem assinatura no veto). Depois das duas
  curas, a segunda passada inteira deu 0 HARD e 31 SOFT; as 31 já estavam na primeira passada e não são deste diff.
