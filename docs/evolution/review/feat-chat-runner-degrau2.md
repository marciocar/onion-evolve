---
branch: feat/chat-runner-degrau2
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 19
findings_real: 18
tokens: 338040
duration_min: 19
findings_fixed: 16
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose (opus), mandato REFUTAR, duas passadas sobre os dois diffs (core e bridge)
nota: "duas passadas do refutador (186108 + 151932 tokens, 13 + 6 min); 1 achado é hipótese (reciclagem de UID dinâmico) e 2 ficam como teto declarado (gpasswd/usermod e python -c no MOAT; resíduo de ACL no rollback). O dogfood real achou mais 3 defeitos, fora desta contagem, todos curados."
---

# Passada adversarial: `feat/chat-runner-degrau2`

## O que muda

O degrau 2 do isolamento do /chat (decisão `D_MAESTRO_DEGRAU2_CONSTRUIR_JA_1016`, selada pelo `kg-decide-seal.sh`
junto com `D_MAESTRO_DEGRAU3_DEPOIS_DO_DEGRAU2_1016`). No core, o wrapper core-only `ops/chat-runner.sh`:

- lê do bridge servido o lançador e os modelos das units, a partir do objeto do commit;
- valida os modelos contra uma allowlist fechada de diretivas, com valores exatos, e recusa bytes de controle;
- ensaia numa unit transitória sob UID dinâmico;
- no `--apply`, que é root e do maestro, cria o grupo `onion-chat` e aplica as ACLs (o estado como root, as raízes e o que existe dentro como a dona, com o `.git` fora);
- instala o socket, o template e o lançador, prova o aperto de mão pelo socket com as propriedades efetivas e a identidade lida do journal, e só então liga o runner no bridge pelo drop-in `40-chat-runner.conf`.

O `update-bridge.sh` passa a chamar o `verify` do runner. Os alvos novos entram no `ops/moat-targets.tsv`, e o juiz do MOAT fecha o modo de teste e a cópia do wrapper. A bancada ganha a família `chat_runner` (37 casos, cada um com mutante) e os casos (m1) a (m6) no `moat_gate`.

No grafo entram os dois selos e dois nós de medição, `E_DEGRAU2_WORKSPACE_SPIKE_1016` e `E_DEGRAU2_CONSTRUIDO_DOGFOOD_1016`. O PR do bridge, em `marciocar/onion-bridge`, traz o lançador, os modelos e o `spawnClaudeCodeProcess` sobre o socket, este só para o convidado e atrás de `CHAT_RUNNER_SOCKET`, desligado por padrão.

Confirmados de alto impacto que conferi contra a proposta:
- `E_SPIKE2_SOCKET_LAUNCHER_DYNAMICUSER_1016`: as 3 correções estão aplicadas (`User=onion-chat-%i`, `CollectMode=inactive-or-failed`, lançador supervisor);
- `E_SDK_SPAWNOPTIONS_HAS_NO_UID` e `E_OBJECAO_27_BRIDGE_CANNOT_SWITCH_UID`: o UID é trocado pelo lançador do root, nunca pelo bridge;
- `E_OBJECAO_24_SHARED_RUNNER_MIXES_TENANTS`: o UID é por conexão, mas o arquivo é do grupo, e isso fica como teto declarado no nó do spike do workspace.

## Achados

Passada 1 (10):
1. **ALTA, curado.** O wrapper aplicava `setfacl` como root nas raízes e nos workspaces sem `-P`, e um symlink trocado depois do pré-voo levava a ACL para fora. A corrida foi provada em 14 de 15 rodadas. Cura: só o estado em si é tocado pelo root; o resto roda como a dona, com `find -user`.
2. **ALTA, curado.** O rollback impresso `setfacl --restore` seguia um componente trocado e restaurava dono e modo fora do estado (provado). Cura: o rollback tira só as entradas que o wrapper pôs, com `-x`, `-R -P` e como a dona.
3. **ALTA, curado.** As units iam para `/etc/systemd` a partir de um clone gravável pela conta do serviço, e "rastreado e limpo" não prova integridade. Havia ainda uma janela entre a checagem e a leitura (TOCTOU). Cura:
   - leitura por `git show <sha>:` em uma só passada;
   - allowlist fechada de diretivas;
   - o degrau 1 como pré-condição.
4. **ALTA, curado.** O ensaio injetava `DynamicUser=yes`, e um template com `User=root` passava (provado). Cura: o valor vem do template validado, e o verify confere as propriedades efetivas.
5. **MÉDIA, curado.** Havia vacuidade no ensaio: o laço do `TemporaryFileSystem` e o `ProtectHome` passavam só pela separação de UID. Cura: o tmpfs é medido por `findmnt`, e o ProtectHome por `stat` do pai da home.
6. **MÉDIA, curado.** O supervisor travava com 2 MiB em cada sentido, e o CLI seguia vivo (provado). Cura: os dois sentidos ficaram não bloqueantes, com buffer e contrapressão.
7. **MÉDIA, parte curada, parte teto.** O backup e o socket viraram alvos do MOAT. Ficam declarados como teto o `gpasswd`/`usermod` no grupo e o `python -c`.
8. **BAIXA, curado.** Cabeçalho patológico (JSON fundo, NUL, surrogate) gerava traceback. Agora dá recusa 64.
9. **BAIXA, curado.** A validação aceitava `v` booleano e regex com `\n` no fim. Cura: `type is int` e `fullmatch`.
10. **BAIXA, curado.** O lançador cobrava menos que o bridge. Agora exige a deny de escrita na config do próprio workspace.

Passada 2 (9):
1. **ALTA, curado.** O byte NUL quebra linha para o systemd e não para o parser do wrapper, então um segundo `User=` passava (provado com `systemd-analyze`). Cura: bytes de controle recusados antes do parse, e as propriedades efetivas conferidas no `systemctl show` da instância.
2. **MÉDIA, curado.** Diretivas de sandbox e tetos aceitavam qualquer valor. Cura: todas exigidas com o valor exato; ficam livres só `Description` e `SyslogIdentifier`.
3. **MÉDIA, curado.** Havia um `.git` gravável pelo grupo, que é o caminho de volta para a conta do serviço no git do bridge. Cura:
   - `privateGitDir` no bootstrap e no clone de org;
   - o `.git` fora do devolver-ao-grupo e das ACLs do wrapper;
   - o verify confere que nenhum `.git` está aberto.
4. **MÉDIA, curado.** O `resume` das conversas de antes do runner quebrava. Cura: `ensureChatHome` copia os transcritos uma vez.
5. **MÉDIA, curado.** O devolver-ao-grupo rodava depois de fechar a conexão, deixando uma corrida com o próximo turno. Agora roda antes.
6. **MÉDIA, curado.** O verify não provava sob qual UID a instância real roda. Agora lê a identidade da sessão e da recusa no journal.
7. **BAIXA, curado.** Os drop-ins das units do runner não eram conferidos. Agora o `DropInPaths` tem de estar vazio.
8. **BAIXA, teto declarado.** O rollback deixa a ACL nos arquivos dos UIDs dinâmicos e a máscara padrão. Isso está impresso no rollback.
9. **Hipótese, declarada no grafo.** O systemd recicla o UID dinâmico.

O dogfood achou 3 defeitos, fora da contagem acima, todos curados:
- a recusa do lançador derrubava o processo do bridge (ECONNRESET sem handler no readline do SDK);
- o destroy depois do fim da entrada só era visto no fim do grace;
- o aperto de mão do verify não levava a política inteira nem tratava o reset da recusa.

## Mutantes

- **Core:** família `chat_runner` com 37 casos, cada um com mutante, provados por `_prove_mutation`: 74 de 74. No `moat_gate`, os casos (m1) a (m6), cada um com mutante.
- **Bridge:** `scripts/chat-runner-mutants.sh` com 48 mutantes no lançador, no `chat-runner.ts`, no `chat.ts` e no `workspace.ts`. Os casos novos reprovam a versão anterior do lançador; isso foi medido para s5b e s5c (deadlock e traceback) e para o RST com a versão anterior do `chat-runner.ts`.
- **Equivalentes, retirados e declarados no script:** o salto do symlink no devolver-ao-grupo e o `allowHalfOpen` do cliente.

## Limites declarados

- **Não medido no host real:** o `--apply`, um turno com a API e um convidado logado, e a primeira cópia de transcritos com conversas reais.
- **Ensaio do wrapper em produção:** contra o bridge servido de hoje ele recusa, porque o bridge ainda não foi implantado com o runner (medido). O ensaio de verdade é depois do deploy.
- **Teto do degrau 2:**
  - o grupo é comum, então entre convidados quem separa é o degrau 0 (sem execução e com guarda de leitura), não o UID;
  - a chave da API chega ao CLI (degrau 5);
  - o admin segue no processo.
- **Sessões antigas e rollback:** sessões abertas antes da virada continuam pela cópia de transcritos. Num rollback, as sessões criadas sob o runner não voltam para a home do serviço.
