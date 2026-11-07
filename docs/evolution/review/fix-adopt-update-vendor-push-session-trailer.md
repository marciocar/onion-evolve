---
branch: fix/adopt-update-vendor-push-session-trailer
pr: 1533
date: 2026-11-07
reviewed_diff_sha256: pendente
findings_total: 27
findings_real: 27
findings_blocking: 8
tokens: 0
duration_min: 170
findings_fixed: 21
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: passada própria do agente de execução (Opus 5.5) + refutador externo da sessão principal, que REPROVOU quatro vezes (a última só pelo D2, com APROVA_COM_RESSALVAS prometido após a cura)
nota: "tokens não medidos (0). Passada própria: 5 achados, 1 bloqueio. Refutações: 1ª, 2 bloqueios e 6 limites; 2ª, A1-A3 e A4-A5; 3ª, B2 (bloqueio), B3, B1/C5 e A5b; 4ª, D2 (bloqueio), o fetch do registro e o GIT_SSH_VARIANT. Todos curados com caso e mutante, exceto os limites declarados"
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

## Achados da 3ª refutação (4ª passada, REPROVOU por 1 bloqueio e 3 limites)

20. (real, BLOQUEAVA, curado) B2: com várias pushurl, o consentimento conferia só a 1ª, e o `git push` empurra para todas. Agora `get-url --push --all`, e toda URL tem de normalizar para o mesmo destino (o remote do membro). Caso (B2) e mutante `D_CURE-consent-all-pushurls`, que morre. A bancada pegou um `purl` sem valor sob `set -u` no próprio mutante; o `local` agora o inicializa.
21. (real, limite, curado) B3: a `_norm_remote` aceitava caminho local, `file://`, `git://` e URL com espaço ou tab, e baixava a caixa de caminho local. Agora:
    - só aceita `https://`, `ssh://` e a forma scp `usuário@host:`;
    - recusa qualquer espaço e qualquer segmento fora de `[A-Za-z0-9._-]` (inclusive `%2F`, `..` e homóglifo, com LC_ALL=C);
    - baixa a caixa só de host/dono/repo;
    - tira a nota "(privado)" antes, e só do lado do registro.

    Caso (B3), um remoto relativo `github.com/fixture/cur` que imita o curador, com mutante `mut:loose-norm`; e (B3n), unitário.
22. (real, limite, curado) B1/C5: um registro commitado localmente, ou qualquer repo git, fabricava consentimento. Agora o registro é `git -C <core> show origin/main:docs/evolution/federation/members.yaml`: só conta o que passou por PR e merge.
    - O `<core>` (ONION_CORE_ROOT, senão a fonte) tem de ter papel `source` pelo `onion-version.sh`. A variável ONION_MEMBERS_FILE deixou de existir.
    - Caso (B1), em que o consentimento só existe num commit local, com mutante `mut:worktree-registry`; e (B1r), um checkout de papel adopted, recusado.
    - Na bancada, o registro de fixture tem um `origin/main` próprio, e os remotos são `ssh://fixture.test<bare>`, servidos por um "ssh" de fixture que roda o comando localmente, sem rede.
    - TETO declarado: quem controla o disco monta um checkout com `origin/main` e papel source próprios. O registro protege contra engano e configuração alheia, não contra quem já roda o push à mão.
    - Consequência medida: até este PR entrar na main, o `origin/main` do core não tem `vendor_push`, e o push não sai nem para a curadoria.
23. (real, limite, curado) A5b: a recusa de remote dividido agora vale também quando o membro vem pelo `local_path`. O caso (A5b) espera recusa, com mutante `D_CURE-consent-shared-remote`.

As fixtures do refutador `t3.sh` e `t4.sh` rodaram numa cópia com os helpers desta cura:
- em B1, B2, B3 e C1 a C5, nenhum push: todos recusados, porque o registro da fixture não tem papel source;
- na tabela B4 de normalização, as formas https, ssh:// e scp da URL do curador casam, e as outras são recusadas.

Nada rodou em repo de adotante real.

## Achados da 4ª refutação (5ª passada, REPROVOU só pelo D2)

24. (real, BLOQUEAVA, curado) D2: 24 dos 31 membros do registro escrevem o `remote:` sem esquema (`github.com/dono/repo`). A `_member_remote_norm` os normalizava para vazio, a recusa de remote dividido não os via, e o push passava por cima de um irmão sem consentimento. O caso real é um repo dividido por dois membros. Agora o lado do REGISTRO aceita também `host/dono/repo` sem esquema, com os mesmos segmentos estritos: host com ponto, ao menos dono/repo, `[A-Za-z0-9._-]`, sem espaço, `..` nem `/.git`. O lado do ALVO segue estrito, porque lá a forma sem esquema é caminho local. Caso (D2), irmão sem esquema e sem consentimento, com mutante `D_CURE-registry-schemeless`, que morre.
25. (real, limite, curado) O registro era lido do `origin/main` LOCAL, e um consentimento retirado só valeria depois de um fetch. Agora `git -C <core> fetch -q origin main` vem antes da leitura, com falha fechada. Caso (D1), um `origin/main` forjado por `update-ref` sem remoto, com mutante `D_CURE-registry-fetch`, que morre. TETO que segue declarado: um checkout forjado com remoto próprio alcançável passa, o que foi medido com a variante `t5b` da fixture do refutador. É o mesmo teto do achado 22.
26. (real, limite, curado) A bancada dava unset em `GIT_SSH_VARIANT` sem restaurar o valor anterior. Agora restaura, como já fazia com `GIT_SSH_COMMAND`.
27. (real, limite, curado, achado ao rodar a tabela D5 do refutador) Porta fora da padrão (`:8443`, `:2222`) normalizava igual à padrão, e `repo/.git` igual a `repo`. Agora só a porta padrão do esquema é aceita (443 no https, 22 no ssh), e `/.git` no fim é recusado. Os dois foram somados ao caso (B3n).

Fixtura `t5.sh` do refutador, numa cópia com os helpers desta cura:
- D1 a D4: todos recusados, porque o core forjado dele não tem remoto e o fetch falha;
- variante `t5b`, com um remoto bare real para o core forjado: D2 e D3 recusam pelo remote dividido, e D4 (membro sem esquema que consentiu) empurra, como deve;
- D5: só :443 e :22 casam.

Nada rodou em repo de adotante real.

## Mutantes

Família `vendor_push_trailer` (fixtures em mktemp, bares locais servidos por `ssh://fixture.test`, e um registro de fixture com `origin/main` próprio e papel source; nenhum adotante real nem o registro do core): 21 casos verdes e 16 mutantes que morrem, todos na mesma rodada.
- (a) ← `D_CURE-vendor-ffpush` · (b) ← `D_CURE-vendor-remote-diverged` · (c) ← `D_CURE-vendor-from-remote` · (f) ← `D_CURE-vendor-push-consent` · (g) ← `D_CURE-vendor-verify`
- (A1) ← `mut:member-id-widens` · (A2) ← `mut:fetch-url` · (A3) ← `mut:origin-fixed`
- (B1) commit local do registro ← `mut:worktree-registry` · (B2) várias pushurl ← `D_CURE-consent-all-pushurls` · (B3) remoto relativo ← `mut:loose-norm` · (A5b) remote dividido pelo local_path ← `D_CURE-consent-shared-remote` · (D1) origin/main sem remoto real ← `D_CURE-registry-fetch` · (D2) irmão sem esquema ← `D_CURE-registry-schemeless`
- (d1) e (d2) ← `D_CURE-session-trailer-durable` e `D_CURE-session-trailer-merge`
- Sem mutante próprio: (A5), (B1r), (B3n), (h) e (e)

Pelo `ops/mutate-and-restore.sh`, contra os arquivos reais: push desligado (morreu), trailer do durable-commit desligado (morreu) e, na 2ª rodada, a conferência trocada por `if false` (o mutante do refutador): morreu no caso (g), com o arquivo restaurado. Rodadas com `LC_ALL=C`: as famílias `vendor_push_trailer,shell_pipefail_robustness,vendor_branch,durable_commit,vendor_baseline_removido` verdes, 0 falhas.

## Limites declarados

- Achados 2, 3, 5 e 11 acima. O achado 4 (corrida de push recusado depois do commit) segue sem caso próprio; a leitura do rc ganhou `failed to update ref` e `cannot lock ref` (achado 9).
- O remoto que não tem a `onion/vendor` não a ganha: criar branch no remoto do adotante é decisão do dono, e a linha diz o comando.
- A curadoria já está com local e remota iguais (461834f) depois do PR #234; a prova do defeito é o relatório daquele update, não o estado de hoje.
