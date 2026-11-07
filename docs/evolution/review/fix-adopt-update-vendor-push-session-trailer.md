---
branch: fix/adopt-update-vendor-push-session-trailer
pr: 1533
date: 2026-11-07
reviewed_diff_sha256: pendente
findings_total: 19
findings_real: 19
findings_blocking: 6
tokens: 0
duration_min: 100
findings_fixed: 13
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: passada própria do agente de execução (Opus 5.5) + refutador externo da sessão principal, que REPROVOU duas vezes (2 bloqueios, depois 1 bloqueio com 3 ataques)
nota: "tokens não medidos (0). 1ª passada própria: 5 achados, 1 bloqueio curado. 1ª refutação: 2 bloqueios e 6 limites; curados os bloqueios e os limites 3, 4, 5, 7 e 8; o 6 é declarado. 2ª refutação: o consentimento não ficava preso ao destino (A1, A2, A3, cada um com caso e mutante); A4 e A5 curados; a nota do L4 é declarada"
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

## Achados da re-refutação (3ª passada, REPROVOU por 1 bloqueio)

14. (real, BLOQUEAVA, curado) A1: `ONION_MEMBER_ID=<curador>` num alvo alheio empurrava, porque o awk só comparava o id. Agora o id só RESTRINGE: o membro tem de casar pelo `local_path` ou pela URL de push, e então ser o do id. Caso (A1) e mutante `mut:member-id-widens`, que devolve o id sozinho consentindo.
15. (real, BLOQUEAVA, curado) A2: url de fetch do curador com pushurl de outro repo contava como consentido e empurrava para o outro. Agora o destino é a URL de PUSH normalizada do remoto efetivo, e ela tem de ser o `remote` do membro. Caso (A2) e mutante `mut:fetch-url`.
16. (real, BLOQUEAVA, curado) A3: `branch.onion/vendor.remote=mirror` empurrava para o mirror, porque o consentimento lia o origin fixo. Agora ele lê o mesmo `_vendor_remote` que o ls-remote e o push usam. Caso (A3) e mutante `mut:origin-fixed`.
17. (real, limite, curado) A4: um ONION_MEMBERS_FILE forjado fabricava consentimento. Agora o registro tem de ser `docs/evolution/federation/members.yaml` rastreado (`ls-files --error-unmatch`) e sem alteração contra o HEAD no topo de um repo git. Não há via própria da bancada: a bancada usa um repo de registro de fixture que cumpre a mesma regra. Caso (A4) e mutante `mut:any-registry`. Teto declarado: quem controla o ambiente consegue montar um repo git com esse caminho, mas quem controla o ambiente já roda o push sozinho.
18. (real, limite, curado) A5: um remote dividido por membros (o caso real é um repo de dois membros) se resolve primeiro pelo `local_path`. Sem casamento por caminho, o update recusa quando nem todos consentiram. Casos (A5), só fixture, e (A5b), em que o `local_path` desempata e o dono empurra. A normalização ignora caixa e forma (https, ssh scp-like, ssh://, usuário, `.git`, barra final, nota entre parênteses), e foi conferida.
19. (real, limite, DECLARADO) L4: `failed to update ref` também sai de falha do servidor (disco, permissão), e aí o rc 13 diz "recusado por não-ff" quando a causa é outra. A saída do git vai inteira ao stderr.

Um defeito da própria cura apareceu na bancada antes do push: o `read` com IFS=tab colapsava campos vazios (membro sem `local_path`), e todo casamento por `remote` falhava. O separador virou `\037`. As fixtures do refutador (`t1.sh`), rodadas numa cópia com o registro real rastreado do core, deram SEM push nos três ataques A1, A2 e A3. Nada rodou em repo de adotante real.

## Mutantes

Família `vendor_push_trailer` (fixtures em mktemp, remoto bare local e um repo de REGISTRO de fixture com o members.yaml rastreado; nenhum adotante real nem o registro do core): 15 casos verdes e 11 mutantes que morrem. 7 são blocos `D_CURE-*` removidos numa cópia dos helpers, com a sanidade de que a remoção ocorreu. 4 são substituições `mut:*` que devolvem o defeito medido, com âncora única conferida.
- (a) push ff com consentimento casado pelo local_path ← `D_CURE-vendor-ffpush`
- (b) remota divergente → rc 13 ← `D_CURE-vendor-remote-diverged`
- (c) clone novo: a vendor nasce da remota ← `D_CURE-vendor-from-remote`
- (f) sem consentimento ← `D_CURE-vendor-push-consent`
- (g) remoto que desfaz a ref → rc 14 ← `D_CURE-vendor-verify`
- (A1) id do curador num alvo alheio ← `mut:member-id-widens`
- (A2) pushurl alheio ← `mut:fetch-url`
- (A3) upstream da vendor num mirror ← `mut:origin-fixed`
- (A4) registro solto ← `mut:any-registry`
- (d1) e (d2) Claude-Session atual sem a herdada ← `D_CURE-session-trailer-durable` e `D_CURE-session-trailer-merge`
- (A5), (A5b), (h) pushurl ≠ url com o membro registrando o destino de push, e (e) sem sessão: sem mutante próprio

Pelo `ops/mutate-and-restore.sh`, contra os arquivos reais: push desligado (morreu), trailer do durable-commit desligado (morreu) e, na 2ª rodada, a conferência trocada por `if false` (o mutante do refutador): morreu no caso (g), com o arquivo restaurado. Rodadas com `LC_ALL=C`: as famílias `vendor_push_trailer,shell_pipefail_robustness,vendor_branch,durable_commit,vendor_baseline_removido` verdes, 0 falhas.

## Limites declarados

- Achados 2, 3, 5 e 11 acima. O achado 4 (corrida de push recusado depois do commit) segue sem caso próprio; a leitura do rc ganhou `failed to update ref` e `cannot lock ref` (achado 9).
- O remoto que não tem a `onion/vendor` não a ganha: criar branch no remoto do adotante é decisão do dono, e a linha diz o comando.
- A curadoria já está com local e remota iguais (461834f) depois do PR #234; a prova do defeito é o relatório daquele update, não o estado de hoje.
