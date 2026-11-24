---
branch: fix/session-lifecycle-native-bg
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: 71299c74a240c1822686f68a2504e0abc261db27a2b5b7b9b313007f662978e3
reviewed_code_sha256: 54e08b2f382eb762586182d8cadb812cd2524bb7b81d82c690387e45b4c3f8cb
findings_total: 6
findings_real: 6
findings_blocking: 0
tokens: 154748
duration_min: 6
findings_fixed: 5
verdict: FIXED
elenxo: true
elenxo_isolado: false
reviewer: "subagente general-purpose (opus), mandato de refutar o diff, só leitura"
nota: "Revisor lançado pelo próprio agente de execução, com o diff e os fatos medidos, sem a conclusão: não é isolado (elenxo_isolado: false). O achado 2 (namespace de pid) ficou como limite declarado, sem cura."
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
