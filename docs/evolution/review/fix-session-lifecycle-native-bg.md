---
branch: fix/session-lifecycle-native-bg
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: 9cb0e78c607eefb0589b2ee2a9c594d93598b2cef9c5e8359a62da4cecd00eb6
reviewed_code_sha256: 2dd804713afcb9fcf4eee683f86f9d02ac031a301f0c50375a50ef86b61ead8e
findings_total: 16
findings_real: 16
findings_blocking: 3
tokens: 154748
duration_min: 6
findings_fixed: 15
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "1ª passada: subagente general-purpose (opus) lançado pelo agente de execução; 2ª: revisão isolada pela sessão do core"
nota: "A 1ª passada (6 achados, tokens 154748) foi do refutador lançado pelo próprio agente. A revisão isolada da sessão do core REPROVOU com 2 bloqueios e mais 3 pontos e 5 mutantes sobreviventes, todos curados nesta re-revisão; os tokens dela não chegaram a este agente (não medidos). Fica sem cura o namespace de pid isolado (limite declarado)."
---

# Passada adversarial: `fix/session-lifecycle-native-bg`

## O que muda

A sessão do core foi mandada ao fundo nativo (tecla `←`, Claude Code 2.1.331) e virou uma cópia de id novo
(`535955f0`, transcript com `history-suppression`/`fork_inherit` na 1ª linha). O processo antigo morreu. O
`ops/session-open.sh` recusou reabrir por causa de um registro de fundo morto (`f1eae138`, `blocked`, sem pid) que o
`baton-pulse.sh` dava como UNREACHABLE. As cinco curas aprovadas pelo maestro:

1. **Uma regra só de «viva»**: `.claude/utils/orchestration/session-liveness.sh` (`live`, `classify`, `fork-of`).
   Viva = interativa listada, ou de fundo com pid vivo; pid listado e morto = morta. O abridor e o pulso a usam, e o
   `pid_alive` do pulso saiu.
2. **O abridor reconhece o fundo e a cópia**: a sessão de fundo viva ganha a receita (`claude attach <id>`; ou
   `claude stop <id> && bash ops/session-open.sh <nome> --resume <id>`). A cópia viva do id escolhido (por `--resume`
   ou pelo nome) recusa com «a conversa já vive como <id>». A janela `claude attach <id>` (um `claude` com o cwd na
   pasta) é reconhecida pelo cmdline.
3. **`/meta:restart` pelo modo** (tmux, fundo nativo, terminal solto, não medido), e o `--resume-check` da cópia
   segue o bilhete do ancestral. O sufixo « (N)» do nome sai antes do abridor.
4. **Pulso**: `SESSION_NATIVE_BG_LONG_DUTY` e `SESSION_STALE_BG_RECORD` (cura `claude rm`, só oferecida).
5. **KB** `parallel-work-worktrees-pattern.md` §3.5: tmux para serviço longo, fundo nativo para tarefa curta.

Grafo: `docs/onion/graph/session-native-bg-2026-11.kg.yaml` (3 nós, radar e contrato rc 0).

## Achados

1. **A janela attach que sobra vira laço de receita** (`ops/session-open.sh`): a recusa dizia «vive no fundo» sem
   olhar o veredito da lista. **Curado:** se a sessão da janela não está viva, a recusa manda fechar a janela. Caso (x2).
2. **Namespace de pid isolado** (`session-liveness.sh`): num sandbox, o `kill -0` daria toda interativa listada como
   morta. **Limite declarado** (grafo, `E_SNB_LIMITS_DECLARED_1124`).
3. **Bilhete errado com dois ancestrais** (`restart-drain.sh`): a cópia de uma cópia casa com o avô pelo uuid
   herdado, e o `--resume-check` seguia o primeiro em ordem alfabética. **Curado:** segue o gravado por último e diz o
   outro, sem arquivá-lo. Caso (t2).
4. **Checagem da cópia só com `--resume`** (`ops/session-open.sh`): **curado**, a checagem roda sobre o id resolvido,
   pelo nome ou por `--resume`. Caso (w4).
5. **Ramos do `SESSION_NATIVE_BG_LONG_DUTY` sem prova**, entre eles o do core, que é o que disparou no vivo.
   **Curado:** caso (bg2c) para o ramo do core. Os ramos de owner_session, pasta, peça e owners.tsv seguem sem caso
   próprio (limite).
6. **Docs afirmando o não medido**: **curado**. restart.md, baton.md e a KB dizem o que não foi medido sobre `stop`,
   `attach` e o id da retomada. O teto do grafo foi corrigido para 3.

## Mutantes

Um ou mais por cura, todos mordem (bancada `LC_ALL=C`):

- **session_open:** (u) a regra única mutada (`state` decide) e (u2) `peer_live` sempre verdadeiro; (v) a receita do
  fundo desligada; (w) a recusa da cópia desligada, (w2) `fork_inherit` invertido no helper, (w3) `fork-of` sempre
  verdadeiro; (w4) a checagem da cópia desligada para o id resolvido; (x) o reconhecimento do attach desligado; (x2) o
  veredito da janela ignorado.
- **baton_pulse:** (bg1) a regra única mutada, (bg1b) o veredito ignorado, (bg2/bg2b) o filtro de dever, (bg2c) o ramo
  do core, (bg3/bg3b) o limiar de 24 h, (bg4) a regra ilegível não para mais em rc 2.
- **restart_drain:** (p) fundo nativo, (q) terminal solto, (r) não medido, (s) o sufixo « (N)», (t) o bilhete da cópia,
  (t2) o ancestral mais recente.

## Limites declarados

- O namespace de pid isolado (achado 2).
- Não medido, porque nenhuma peça roda `claude stop`, `attach` ou `rm`: que a retomada interativa depois do `stop`
  mantém o mesmo id, que `stop`/`attach`/`rm` aceitam o id curto que o harness lista, e que a janela `attach` fecha
  sozinha depois do `stop`.
- O modo «tmux» do restart lê só a chave `TMUX` do ambiente do processo, não a árvore.
- Os ramos de owner_session, pasta, peça e owners.tsv do `SESSION_NATIVE_BG_LONG_DUTY` não têm caso próprio.

## Revisão isolada

A sessão do core revisou o diff isolada e **reprovou com 2 bloqueios**. Esta re-revisão os curou na mesma worktree:

1. **Bloqueio: a sessão interativa viva recebia a receita `claude stop`** quando o mesmo `sessionId` vinha duas vezes
   na lista (o registro de fundo morto e a interativa viva), que é o caminho do incidente. **Curado nas duas peças:**
   no `restart-drain.sh`, o `session_mode()` escolhe a linha VIVA; no `baton-pulse.sh`, o `kind` e o pid da sessão
   saem da mesma linha do veredito. Casos: restart (u); pulso (bg5), com mutante no `kind`, e (bg5b) no filtro de `kind`
   do aviso de fundo, que era o M11.
2. **Bloqueio: o `--resume-check` seguia o bilhete de uma IRMÃ**, porque o 1º `uuid` se repete em duas cópias da mesma
   origem. **Escolha: exigir o ÚLTIMO uuid herdado** (a última mensagem com `timestamp` anterior ao `ts` da linha
   `history-suppression`) no transcript da origem. Não escolhi o filtro pelo `ts` do bilhete porque ele não exclui a
   irmã: o bilhete de uma irmã gravado antes do fork também passaria. O último uuid herdado é a ponta da conversa no
   instante do fork; a irmã divergiu antes dela e não a tem. Medido no vivo: `535955f0` casa com `022965f2` (rc 0) e
   não com `ed9f72cc` (rc 1). E `022965f2` casa com `ed9f72cc`: pela herança, ela é a origem de `022965f2`, não irmã.
   Casos: session-open (w7), com mutante «o 1º uuid»; restart (t2), em que a irmã com o bilhete mais novo não é seguida
   nem citada.
3. **Cópia recém-criada sem uuid herdado:** agora o `fork-of` dá rc 2 (não medido), e o abridor diz «não medi» e
   abre, sem barrar por palpite. Fica declarado na KB §3.5. Caso (w8).
4. **Recusa falsa entre irmãs:** resolvida junto com o 2, em (w7).
5. **Pasta vazia no conjunto de pastas de donas** (`baton-pulse.sh`): corrigido, só entra a pasta absoluta. Sem caso
   próprio (limite).

Mutantes que sobreviviam e agora morrem: **M1**, EPERM tratado como morto, caso (y), que pula declarado quando roda
como root; **M3**, `fork-of` sem exigir `fork_inherit`, caso (w5); **M6**, cópia morta barrando a retomada, caso (w6);
**M10**, `max` virando `min`, caso (bg6); **M11**, aviso de fundo sem conferir o `kind`, caso (bg5b).

## Re-revisão isolada

A re-revisão isolada em `e5fcb74` **aprovou a cura do achado 1 e reprovou a do 2**: o `fork-of` seguia simétrico entre
pai e filha. O último uuid herdado pela cópia reaparece em toda descendente dela, então `fork-of ed9f72cc ← 022965f2`
dava rc 0, e o `--resume-check` do pai seguia e arquivava o bilhete da filha (cadeia O→A→B na bancada do revisor).

**Cura:** a cópia descende da origem quando um uuid **herdado** pela cópia está na parte **própria** da origem, ou seja,
no que a origem escreveu depois do próprio fork (todo o transcript, se a origem não é cópia). O uuid que aparece na filha
ou na irmã mais nova é herança dela (timestamp anterior ao `ts` do fork dela) e não conta. A relação fica assimétrica, e
a cadeia vale do jeito certo: a neta casa com a avó pelo que a avó escreveu antes do fork da mãe. Somei a trava do
`ts`: só vale bilhete gravado **antes** do fork da cópia. Medido no vivo: `535955f0 ← 022965f2` dá 0;
`022965f2 ← ed9f72cc` dá 0; `ed9f72cc ← 022965f2` dá 1; `022965f2 ← 535955f0` dá 1.

Casos novos, cada um com mutante, sendo o da regra do fork-of «sem filtrar a parte própria»:
- (w9) irmã mais velha × mais nova, nos dois sentidos;
- (w10) pai × filha: retomar a filha com o pai vivo abre, e retomar o pai com a filha viva recusa (resolve o C);
- restart (t4) O→A→B com só o bilhete da filha: o `--resume-check` do pai não o segue nem o arquiva;
- restart (t3): bilhete gravado depois do fork, com mutante na trava do `ts`.

O (w7) foi refeito com a irmã como cópia, e o mutante dele passou a ser o da parte própria.

Não bloqueantes:
- **B (o avô):** a cadeia é seguida quando a cópia ainda carrega o que o avô escreveu. A compactação apaga essa parte, e
  aí o bilhete do avô não é seguido. Fica como limite declarado no `restart-drain.sh`, no `restart.md` e na KB. No vivo,
  `535955f0 ← ed9f72cc` dá 1 por isso. O comentário antigo (l.157) foi reescrito.
- **C:** resolvido junto com a cura principal, caso (w10).
- **D:** o nome e a pasta da sessão, logo o rótulo, também saem da linha viva no pulso. Caso (bg5c), com mutante.
- **M2:** interativa com pid morto, caso (z) na família `session_open`, com mutante no helper.
- **M16:** a pasta vazia, caso (bg8). O cwd ausente agora fica vazio, em vez de virar o `realpath('')`, que é a pasta do
  processo. A guarda redundante saiu, e o filtro de caminho absoluto virou a única defesa, mordida pelo mutante.

