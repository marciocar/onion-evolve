---
branch: fix/adopt-update-vendor-push-session-trailer
pr: 1533
date: 2026-11-07
reviewed_diff_sha256: f085c159bb3b33ad7e3ec13b62cd20f0317169250f6c2539aa5efebb8bdb211c
reviewed_code_sha256: bc4c5ee1676139f8bf917d6242553c6692b753bd1db0a6834b2eb1f143940b9a
findings_total: 13
findings_real: 13
findings_blocking: 3
tokens: 0
duration_min: 60
findings_fixed: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: passada própria do agente de execução (Opus 5.5) + refutador externo da sessão principal, que REPROVOU com 2 bloqueios
nota: "tokens não medidos (0). 1ª passada própria (5 achados, 1 bloqueio curado); o refutador externo reprovou com 2 bloqueios e 6 limites; os 2 bloqueios e os limites 3, 4, 5, 7 e 8 foram curados; o 6 é declarado"
---

# Passada adversarial: `fix/adopt-update-vendor-push-session-trailer`

## O que muda

- `vendor-branch.sh update` (SÓ com `vendor_push: true` no membro do registro do core; ver o achado 7): lê a `onion/vendor` remota (ls-remote) ANTES de escrever na vendor. Local ausente → nasce da remota. Remota não ancestral da local → rc 13, nada tocado. Depois do commit da vendor e da guarda de BASE CRUZADA, push por fast-forward (sem force) e conferência por ls-remote (rc 14 se não bater; rc 13 se o push for recusado por não-ff). Uma linha diz de onde para onde a remota foi. Sem remoto ou remoto sem a branch: não empurra e diz. `ONION_VENDOR_PUSH=0` desliga, dito.
- `session-trailer.sh` (novo): `Claude-Session: <URL>` de `ONION_CLAUDE_SESSION_URL` ou de `CLAUDE_CODE_BRIDGE_SESSION_ID`, conferidos pela forma; nada inventado, e a nota é dita quando falta. Usado pelo `durable-commit.sh` (commit da vendor e o durável pós-merge) e pelo merge do `vendor-branch.sh`, logo abaixo da assinatura do alvo e sem duplicar.
- `adopt.md`: rc 13/14 na tabela do --update e a linha da remota na seção "Arquivos aplicados" do relatório downstream (sem seção nova: o comando está no teto de 800 linhas da REGRA 5 (Limites de linhas (por TIPO de artefato — tamanho saudável ≠ número universal))).

## Achados

1. (real, corrigido, bloqueava) A seção nova do relatório no `adopt.md` citava a linha entre crases DENTRO do heredoc sem aspas (`<<EOF`): rodada literal, a crase executaria `onion/vendor` como comando. Trocado por aspas.
2. (real, limite) `GIT_TERMINAL_PROMPT=0` não cala um prompt de SSH (host desconhecido, passphrase): num remoto SSH sem agente o ls-remote pode esperar. Não forcei `BatchMode` para não sobrescrever a config SSH do adotante.
3. (real, limite) O push respeita o hook pre-push do adotante; um hook pesado ou que recuse vira rc 14 com a saída dele.
4. (real, limite) O caminho "push recusado por não-ff DEPOIS do commit da vendor" (corrida entre a leitura e o push) não tem caso próprio; o rc 13 dele é deduzido do `--porcelain`, não medido na bancada.
5. (real, limite) Se o precheck cria a vendor local a partir da remota e o update para em seguida por árvore suja (rc 2), a branch local fica criada. É espelho da remota, inofensivo, e é dito no stdout.

## Achados do refutador externo (2ª passada, REPROVOU)

6. (real, BLOQUEAVA, curado) A bancada não exercia a conferência por ls-remote: o mutante `if false` no lugar dela sobrevivia (11/11 verdes). Cura: caso (g), remoto bare com `post-receive` que desfaz a ref depois de aceitar o push; o real sai rc 14 com a integração intacta, e o mutante (bloco `D_CURE-vendor-verify` removido, e também o `if false` plantado pelo `ops/mutate-and-restore.sh`) sai rc 0 e morre.
7. (real, BLOQUEAVA, curado) O push vinha ligado por padrão para todo adotante, e só um tinha consentido. Cura: opt-in registrado NO CORE, com `vendor_push: true` no membro do `docs/evolution/federation/members.yaml` (o members-validate.sh aceita o campo, rc 0). Membro casado por `ONION_MEMBER_ID`, ou pelo `local_path` igual ao checkout principal do alvo (a worktree irmã resolve para ele), ou pelo `remote` normalizado. Sem o campo, nada é lido nem empurrado, e a linha diz "onion/vendor remota não empurrada: sem consentimento registrado" com o comando. Só a curadoria está marcada `true`. O adopt.md passa `ONION_MEMBERS_FILE` do checkout do core. Caso (f) e mutante `D_CURE-vendor-push-consent`.
8. (real, limite, curado) A leitura e a conferência agora usam a URL de PUSH (`remote get-url --push`). Caso (h): com `pushurl` diferente da `url`, a vendor chega ao repo de push e o de fetch fica intocado.
9. (real, limite, curado) `failed to update ref` e `cannot lock ref` agora contam como recusa (rc 13).
10. (real, limite, curado) A dica `ONION_VENDOR_PUSH=0` também sai no erro do push e no da conferência.
11. (real, limite, DECLARADO) Remoto offline bloqueia o update de quem consentiu (rc 14 antes de tocar em nada). A saída é `ONION_VENDOR_PUSH=0`, declarada no relatório.
12. (real, limite, curado) A `Claude-Session:` herdada da assinatura do alvo (de outra sessão) sai antes de entrar a atual, no durable-commit e no merge; sem sessão conhecida, sai e nenhuma entra. A fixture da bancada carrega uma herdada (session_VELHA9).
13. (real, limite, curado) `ONION_CLAUDE_SESSION_URL` inválida cai para `CLAUDE_CODE_BRIDGE_SESSION_ID` (caso (e)).

## Mutantes

Família `vendor_push_trailer` (fixtures em mktemp, remoto bare local e registro de membros PRÓPRIO; nenhum adotante real nem o members.yaml do core): 9 casos verdes e 7 mutantes in-bancada que morrem, cada um com o bloco `D_CURE-*` removido numa cópia dos helpers e com a sanidade de que a remoção ocorreu. (O bloco do push foi renomeado para `D_CURE-vendor-ffpush`: o nome antigo era prefixo do `-consent`, e a sanidade por `grep -c` o acusou.)
- (a) push ff com consentimento casado pelo local_path ← `D_CURE-vendor-ffpush`
- (b) remota divergente → rc 13, vendor e integração intactas ← `D_CURE-vendor-remote-diverged`
- (c) clone novo: a vendor nasce da remota (consentimento casado pelo remote) ← `D_CURE-vendor-from-remote`
- (f) sem consentimento: nada empurrado, e é dito ← `D_CURE-vendor-push-consent`
- (g) remoto que desfaz a ref → rc 14 ← `D_CURE-vendor-verify`
- (d1) commit da vendor: Claude-Session atual, sem a herdada ← `D_CURE-session-trailer-durable`
- (d2) merge não-ff idem ← `D_CURE-session-trailer-merge`
- (h) pushurl ≠ url e (e) sem sessão, com a URL inválida caindo para o id: sem mutante próprio

Pelo `ops/mutate-and-restore.sh`, contra os arquivos reais: push desligado (morreu), trailer do durable-commit desligado (morreu) e, na 2ª rodada, a conferência trocada por `if false` (o mutante do refutador): morreu no caso (g), com o arquivo restaurado. Rodadas com `LC_ALL=C`: as famílias `vendor_push_trailer,shell_pipefail_robustness,vendor_branch,durable_commit,vendor_baseline_removido` verdes, 0 falhas.

## Limites declarados

- Achados 2, 3, 5 e 11 acima. O achado 4 (corrida de push recusado depois do commit) segue sem caso próprio; a leitura do rc ganhou `failed to update ref` e `cannot lock ref` (achado 9).
- O remoto que não tem a `onion/vendor` não a ganha: criar branch no remoto do adotante é decisão do dono, e a linha diz o comando.
- A curadoria já está com local e remota iguais (461834f) depois do PR #234; a prova do defeito é o relatório daquele update, não o estado de hoje.
