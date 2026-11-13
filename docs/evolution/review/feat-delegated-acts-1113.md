---
title: "Revisão — as guardas dos atos delegados de 2026-11-13 (merge alheio, deploy do site, scripts da VPS)"
date: 2026-11-13
branch: feat/delegated-acts-1113
reviewer: "11ª passada: PENDENTE (a cura da 10ª, o ensaio rastreado e o selo da lista nomeada, ainda não passou pelo refutador independente). 10ª passada: o refutador independente no head a065593a3 REPROVOU pela mesma classe (3 escapes do fecho no ENSAIO das portas); por decisão de desenho do team-lead, o ônus se inverteu para a EXECUÇÃO (bancada act_trace). 9ª passada: o refutador independente no head 1759dba93 REPROVOU por um bloqueio (o detector do fecho não via caminho em variável) e uma linha (git replace), curados aqui. 8ª passada: o refutador independente no head 386161856 REPROVOU por um bloqueio (a lista de guarda não seguia o que os atos executam) e uma cura de uma linha (o ls-remote isolado da config), curados aqui. 7ª passada: o refutador independente no head 7a1e8dce3 REPROVOU o item 3 (rename escapa; regex à mão deixava atos de fora), curado aqui com a lista derivada do tsv e o reforço do ls-remote. 6ª passada: o refutador independente no head 8e0b4df5d manteve a constante do core e REPROVOU pela forma delegada rodando o script EDITADO na árvore e pela sessão mergeando o próprio PR com --dispensa; o maestro decidiu por /meta:decide fechar o barato e declarar o resto (6 itens, curados aqui). 5ª passada: o refutador independente no head d820c629b REPROVOU com 1 bloqueio (o members.yaml define o core) e 2 itens baratos (ExecStart e DropInPaths efetivos, /run/systemd/system), curados aqui com o harness re-rodado (after4.txt). 4ª passada: o refutador independente no head ad3260def conferiu as formas de linha curadas e REPROVOU com 2 bloqueios estruturais (F1, F2), curados aqui com o harness re-rodado (after3.txt). 3ª passada: a re-refutação independente no head 454a3c1bb conferiu B1-B5 curados e REPROVOU com 3 novos (N1-N3), curados aqui e com o harness re-rodado (after2.txt). 2ª passada: refutador INDEPENDENTE (agente separado, a pedido do team-lead) REPROVOU com 5 bloqueios (B1-B5), harness em scratchpad/refute1647 (all.sh, allp.sh, cases1-4); o condutor curou e re-rodou o harness do refutador contra a cura. 1ª passada: o condutor sobre o próprio diff. Bancada: moat_gate (dl1-dl5, db1-db8, rb1-rb14, cada um com mutante), pr_merge_verified (fr1-fr11, rf1-rf9, fr-MUT, rf-MUT), deploy_site (52/52, com os casos B2/B4), slack_persona (29/29, com os casos B5), act_signature (13/13 + 12 mutantes), visudo -cf parsed OK"
reviewed_diff_sha256: 242f75529fa9c00dfea833d65c01c15f97b44ee4575bd1106e1df7c72df43cfe
reviewed_code_sha256: a0c9565b7957b3ea9f2bb3ee98834140f192e1424b62e07390afcfd02fdc1a31
findings_total: 33
findings_real: 33
findings_fixed: 33
tokens: 0
duration_min: 60
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
nota: "o refutador independente reprovou nove vezes; as curas entraram neste PR. Pelo item 3 da decisão do maestro de 2026-11-13, este PR toca guarda e o merge dele é do maestro (--maestro), depois de nova passada do refutador"
---

# Resíduo — REGRA 56

Implementa os três selos de delegação do maestro de 2026-11-13 e mantém o quarto (o push de porta segue com ele).
O hook passa só a forma exata (linhas `delega` do `ops/moat-targets.tsv`); o que o hook não mede, o script recusa.

## Achados (todos reais, todos curados neste PR)

1. **Sudoers apontando o repo é root para quem edita o script.** A regra aponta cópias de root em
   `/usr/local/lib/onion-ops`, instaladas da `origin/main` e conferidas por sha256 (`ops/delegated-ops.sh`). Liberar
   os comandos internos não fechava a conta: `git -c core.sshCommand`, `tee`/`install` com caminho variável.
2. **O backup como root escrevia no destino do operador** (symlink plantado no nome previsível do dump viraria
   escrita do root em `/etc/shadow` e `chown` para o operador). Como root, `bridge-backup.sh` agora só lê a origem e
   entrega o tar por pipe ao estágio do operador.
3. **A persona como root copiava o que estivesse no bridge servido**, symlink incluso. `served_regular` recusa o
   que não é arquivo regular dentro do servido; caso novo na bancada da persona.
4. **Script de ato executado direto por caminho que o hook não lê** (`sudo /srv/x/ops/update-bridge.sh`) passava
   com rc 0. O juiz agora julga o ato pelo nome (db7).
5. **A bancada envelheceu com a mudança** (contagens fixas 8/8 e 25, âncoras de mutante que deixaram de ser únicas,
   texto esperado do fr4). Curado, e as quatro catracas novas da REGRA 117 ganharam mutante.
6. **A cura do achado 4 vetava um glob só de curinga** (`/var/lib/onion-bridge/*` como palavra de comando casava o
   1º script de ato por `fnmatch`), e o caso b5 da bancada caiu. O julgamento pelo nome agora exige que o nome
   tenha algo além de curinga. As âncoras dos mutantes ato3 e ato4 seguiram a linha nova.
7. **O seletor da bancada por arquivo (selector_per_file (a)) estourou o teto de 30 famílias para o resíduo**: o
   pr-merge-verified.sh e o deploy-site.sh passaram a LER o resíduo, e as 7 famílias que os leem viraram leitoras
   legítimas dele. Teto 40, com o motivo no comentário. A doutrina e os comentários que citam ops/ ganharam a
   marca (core-only) da REGRA 100.

## 2ª passada: o refutador independente (5 bloqueios, todos curados aqui)

Cada entrada exata do refutador virou caso de bancada que reprovava antes da cura e passa depois, com mutante.

8. **B1 — o marcador `--foreign-repo` casava como token solto.** `--foreign-repo=0`, `--motivo --foreign-repo`,
   `--dispensa X --motivo --foreign-repo` e `<<< --foreign-repo` passavam, e o merge alheio rodava sem o gate. Cura no
   juiz: o marcador se julga pela gramática do script (palavra nua, fora do valor de flag que consome argumento, sem
   --dispensa/--ci-inoperante/--allow-draft); here-string e redirecionamento saem do argv; `bash x.sh <<< y` deixou de
   pular o ramo do shell. Cura no script: `--foreign-repo=*` recusa, e a SESSÃO DO CORE (processo `claude` entre os
   ancestrais, medido em /proc, com o cwd num checkout do core) não mergeia repo alheio sem a forma delegada,
   independentemente do que o hook viu. O maestro tem `--maestro`, que o veto barra à sessão. (rb1-rb5, rf1-rf3, rf5)
9. **B2 — o deploy do site tinha o mesmo cego.** `deploy <<< --verified-pr` e `<<< --verified-pr` passavam. Cura:
   `deploy --verified-pr <N>` em posição exata (argv 1..3, N numérico), `--verified-pr=` saiu, o 1º argumento vazio
   recusa, e o script recusa o deploy do maestro quando um processo `claude` é ancestral (escape: `--maestro`). (rb6-rb8 e
   os casos B2 do deploy-site --selftest)
10. **B3 — o `@foreign` só olhava `--repo`.** `GH_REPO=x`, `export GH_REPO=x` e `cd /outro/repo && bash …` passavam. Cura
    no juiz: sem --repo, o alvo é o GH_REPO da linha/export ou o cwd literal fora do projeto. Cura no script: ele
    resolve o alvo como o gh (--repo, GH_REPO, origin do cwd). (rb9-rb12, rf1, rf4)
11. **B4 — o ambiente forjava as condições.** `PATH=/tmp/fakegh:$PATH` mentia CI e PR; `GIT_CONFIG_*` trocava o
    origin. Cura: no caminho delegado (merge alheio e deploy), PATH fixo do sistema, gh absoluto, e recusa de
    GIT_CONFIG*, GIT_DIR, GIT_WORK_TREE e afins, XDG_CONFIG_HOME e GH_* (exceto GH_TOKEN). (rf6-rf8, casos B4 do deploy)
12. **B5 — escalada pelo payload da persona.** O `install --apply` copiava como root, verbatim, a unit do bridge
    servido (onion:onion, rw-rw-r--): `User=root` e um ExecStart qualquer viravam root. Cura: a unit e a config se
    leem COMO `onion` (uma leitura, sem janela entre conferir e copiar), a unit passa por uma allowlist FECHADA de
    diretivas (DynamicUser=yes obrigatório, User, SupplementaryGroups, ExecStart, WorkingDirectory, binds e as quatro
    credenciais com valor fixo, nenhuma outra Exec*), a config por parse de JSON, e o root instala o TEXTO conferido de
    um diretório temporário dele. O card e o sudoers deixaram de dizer "nada além de comandos do sistema". (casos B5 da
    bancada da persona; a unit real servida hoje cabe na allowlist, medido)

O harness do refutador, re-rodado contra a cura: as 9 formas de B1/B3 vetam (resta só a forma delegada); de B2 vetam as
3 de here-string e `=`, e as que o hook ainda deixa passar (`"" --verified-pr 3`, PATH falso, GIT_CONFIG_*) o script
recusa. `bash ops/publish-door.sh onion-core <<< --push` e `bash ops/delegated-ops.sh <<< install` seguem passando, e
estão certos: o argv não tem o ato (não há push; é o verify).

## 3ª passada: a re-refutação (3 bloqueios novos, curados aqui)

13. **N1 — merge alheio pelo default do gh.** `git remote add sge …; gh repo set-default …/sge; bash ops/pr-merge-verified.sh 12`
    passava: o script resolvia o alvo pelo origin, e o gh pelo `remote.<nome>.gh-resolved`. Cura no script: sem
    --repo, o alvo é o conjunto de TODOS os remotes do repo do cwd, mais os gh-resolved com nome e o GH_REPO; qualquer
    um que diverja do core é o alvo, e a sessão do core recusa. Cura no hook: `git remote add|set-url|rename`, `git
    config` que escreve `remote.*` e `gh repo set-default` (fora `--view` e `--unset`) vetam na linha da sessão (classe
    nova `forja`, e um sinal novo no pré-filtro, sem o qual o juiz nem rodava para essas linhas). (rb15-rb19, rf10)
14. **N2 — o HOME ficou fora da cura de B4.** `HOME=x bash …` trocava o `~/.gitconfig` (insteadOf troca o origin) e o
    config.yml do gh (`http_unix_socket` desvia todo o HTTP). Cura: no caminho delegado, HOME fixo pelo passwd,
    GH_CONFIG_DIR dentro dele, e recusa de *_PROXY/*_proxy, SSL_CERT_*, CURL_CA_BUNDLE, REQUESTS_CA_BUNDLE,
    NODE_EXTRA_CA_CERTS, GIT_SSL_* e XDG_CONFIG_DIRS. (rf11-rf13 e os casos N2 do deploy-site, cada um com mutante)
15. **N3 — a allowlist da unit era furada por `\r`.** O systemd parte linha em `\r`: um Description com
    `\r[Service]\rExecStartPre=+/bin/true\r[Unit]` era UMA linha aqui e três lá (root). Cura: caractere de controle
    (fora o `\n`) no texto inteiro recusa antes do parse, as linhas se partem em `[\r\n]`, e o Description só aceita
    ASCII imprimível sem `[` nem `\`. As três units do refutador (unit.cr-*) recusam; a unit real servida segue
    passando. (caso N3 da bancada da persona, com o mutante da allowlist de antes)

Harness re-rodado (after2.txt): a linha do N1 veta. As formas com HOME passam o hook e o script as neutraliza (HOME do
passwd). O que ainda passa o hook é forma legítima, é recusado pelo script com caso na bancada, ou é LIMITE abaixo.

## 4ª passada: 2 bloqueios estruturais (curados aqui)

16. **F1 — a config do git apontando outro remote.** `GIT_DIR` de outro repo, `GIT_CONFIG_*`/`GIT_CONFIG_PARAMETERS`/
    `GIT_CONFIG_GLOBAL` com `url.X.insteadOf`, `git config url.…`, escrita direta no `.git/config` e include no
    `~/.gitconfig` faziam o origin "do core" apontar o outro repo: alvo e core empatavam, porque o slug do core vinha
    de `git remote get-url origin`. Cura estrutural: o slug do core sai do `remote:` do membro `kind: source` do
    members.yaml do checkout (na falta, da constante), nunca da config do git; na sessão do core sem --repo, o script
    entrega `GH_REPO=<o core>` ao gh, que nunca resolve pela config; o `vp_slug` do deploy-site lê o mesmo members.yaml;
    o caminho delegado já recusava GIT_DIR, GIT_WORK_TREE e GIT_CONFIG*. No hook, a forja passa a ver `git config url.*`
    e `include*`. Com isso, insteadOf e include ficam inofensivos para o alvo. (rf14-rf16, rb20-rb21, F1 do deploy-site,
    cada um com mutante). As formas de r3.txt que ainda passam o hook (GIT_DIR, GIT_CONFIG_*, printf/sed/cp no
    .git/config) são neutralizadas no script, não na linha, como o refutador indicou.
17. **F2 — a allowlist da unit furada por NBSP.** O `strip()` do Python comia U+00A0; o systemd ignorava a chave
    "\xa0DynamicUser" e o serviço rodava como root. Cura: sem strip; fora das linhas de comentário (# ou ; na coluna 0,
    que o systemd descarta inteiras), só ASCII imprimível; espaço nas pontas do valor recusa; a linha casa com
    `^[A-Za-z]+=`. E depois do daemon-reload, antes de seguir (e de novo no start), a unit EFETIVA se confere por
    `systemctl show` (DynamicUser=yes, User=onion-slack-persona, CapabilityBoundingSet e AmbientCapabilities vazios,
    nenhuma Exec* além do ExecStart); divergiu, a unit sai e nada liga. Desvio declarado do pedido: os comentários da
    unit real são em pt-BR (acentos), então o não-ASCII é aceito só em linha de comentário. (casos F2 da bancada da
    persona, com dois mutantes)

## 5ª passada: quem é "o core" (curado aqui)

18. **M1 — o members.yaml do checkout definia o core.** Trocar o `remote:` do membro `kind: source` por sge (Edit ou
    sed) fazia `pr-merge-verified.sh 12 --repo marciocar/sge` passar no hook (MOAT_SELF_SLUGS vinha do registro) e no
    script (alvo = core = sge), sem gate. Cura: o core é uma CONSTANTE (`marciocar/onion-evolve`) no pr-merge-verified.sh
    (`_PMV_CORE_CONST`), no deploy-site.sh (`VP_CORE_CONST`) e no juiz do hook (`_MOAT_CORE_SLUG`). O members.yaml só
    se confere contra ela: divergiu, o script recusa (sessão do core e caminho delegado; o deploy delegado também) e o
    hook não delega nada. Não se usa `git show HEAD:` como fonte, porque o commit também é da sessão. A edição do
    members.yaml em si segue passando o hook; o que ela não faz mais é mudar o alvo. (rf17, rf18, rb22, rb23, o caso M
    do deploy-site, cada um com mutante; a bancada troca a constante pela do sandbox, numa costura declarada)
19. **O efetivo da unit, mais apertado, e o drop-in em runtime.** O `effective_ok` confere o ExecStart do `systemctl
    show` contra o valor fixo e exige `DropInPaths` vazio; `/run/systemd/system/onion-*` entrou no moat-targets.tsv
    (com o glob: o caminho nu punha "system" no sinal do pré-filtro, que casava todo `systemctl` e matava os mutantes
    d14 e d22). (caso do drop-in na bancada da persona, com mutante; as formas de r4b/r4c vetam)

## 6ª passada: a forma delegada roda o revisado (decisão do maestro de 2026-11-13: fechar o barato, declarar o resto)

20. **Item 1 — a forma delegada rodava o script EDITADO na árvore**, sem PR (`verified_gate() { return 0;`, a constante
    do core). Cura no hook: a forma delegada só vale se o script invocado (o de ops/ ou a cópia de root) e a cerca (o
    hook, o juiz, o tokenizador e o moat-targets.tsv) forem byte a byte os de `origin/main` (`git hash-object` contra
    `origin/main:<rel>`), a mesma régua do @rootcopy. No script: o merge alheio delegado confere o próprio blob contra
    `origin/main:ops/pr-merge-verified.sh`; o deploy delegado já exigia HEAD = origin/main e ops/deploy-site.sh limpo.
    (rb24-rb26, rf22, com mutante)
21. **Item 2 — `--dispensa` e `--ci-inoperante` são do maestro.** Na sessão do core o script recusa sem `--maestro`, e
    as duas viraram palavras de assinatura do ato no tsv (o hook veta). (rf19, rf20, rb27, rb28, com mutante)
22. **Item 3 — PR do core que toca guarda não é mergeado pela sessão.** Hooks, settings.json, moat-targets.tsv, os
    scripts delegados e o fecho deles, sudoers: o pmv lê os arquivos do PR e recusa na sessão do core sem --maestro.
    **Este próprio PR passa a ser de merge do maestro.** (rf21, com mutante)
23. **Item 4 — PATH fixo sempre que a sessão do core chama**, não só no delegado. (rf23, com mutante; a bancada desliga
    a chamada nas cópias dela, cujo gh é o falso do PATH, costura declarada)
24. **Item 5 — o efetivo exige `FragmentPath=/etc/systemd/system/onion-slack-persona.service` e
    `SupplementaryGroups=onion-brain-hub`**, e os diretórios `/run/systemd/{system,transient,system.control,generator,
    generator.early,generator.late}` entraram no tsv inteiros (o `cp /tmp/u /run/systemd/transient/` do refutador
    passava com o glob `onion-*`); o sinal do pré-filtro não ganha "system", que casaria todo systemctl. (casos da
    bancada da persona, com mutante; rb29 com o tsv sem a linha)

**Item 6 — a fronteira real é outro usuário do sistema.** A sessão roda como o usuário do maestro: escreve o checkout,
a ref origin/main local, o ~/.gitconfig, a config do gh e o próprio hook. Os hooks e as recusas dos scripts são CAMADA
DE CONFORMIDADE, não fronteira de segurança. Declarado também no card (docs/onion/delegated-ops-sudoers-card.md).

## 7ª passada: o item 3 enxergando o que deve (curado aqui)

25. **Rename escapava.** `pulls/N/files --jq .filename` trazia só o nome novo, e renomear ops/moat-targets.tsv para
    .old (o que põe o hook em modo derivado) passava como PR comum. Cura: o pmv lê `.filename` E `.previous_filename`;
    o arquivo `removed` vem pelo `.filename`. (rf24, com o --jq do script rodando de verdade no gh de bancada, e mutante)
26. **A regex escrita à mão deixava guarda de fora** (o publish-door.sh e os outros scripts de ato, o members.yaml, os
    workflows, ops/review/, a catraca da REGRA 117). Cura: a lista é DERIVADA do moat-targets.tsv (o da árvore somado ao
    de origin/main: as linhas `ato` e `delega` e os wrappers de deploy/relógio), mais os fixos (o tsv, members.yaml,
    .github/workflows/, ops/review/, act-signature-check.sh, .claude/hooks/, settings.json, ops/sudoers/ e o fecho dos
    scripts delegados). (rf25, rf26, com mutante)
27. **A ponta da main medida no remoto** (o reforço que o refutador recomendou para o limite da ref local): rb30 forja a
    origin/main local por update-ref com o deploy-site.sh editado e a árvore igual; o hook veta, e o mutante que lê a
    ref local passa. A bancada aponta a URL constante para o próprio repo de sandbox (costura declarada).

## 8ª passada: o fecho do que os atos executam (curado aqui)

28. **A lista de guarda não seguia o que os atos EXECUTAM.** O publish-door.sh, mesmo em ensaio, roda o
    materialize-door.sh e o materialize-marketplace-repo.sh; um PR que só os tocasse não era guarda. Cura: linhas
    `fecho script <path>` no moat-targets.tsv, explícitas e revisadas (82 depois da 10ª passada), que o pr-merge-verified.sh soma à lista
    de guarda, mais os .githooks/. A REGRA 117 (act-signature-check.sh) confere o fecho contra o código: toda execução de
    um script do repo (`bash x.sh`, `source`, `.`, `python3 x.py`, `"${WT}/ops/x.sh"`, `$(…)`) a partir de uma linha
    ato/delega/fecho tem de estar numa delas (`fecho-incompleto`), e a linha fecho sem arquivo acusa
    (`fecho-sem-script`). (rf27 com o materialize-door.sh, rf28 com .githooks/, (xiv)-(xvi) da REGRA 117, com mutante)
    **FRONTEIRA declarada:** os executores do gate (lint-artifacts.sh e lint-selftest.sh) estão no fecho, mas o que eles
    rodam não se desce. Medido: o fecho transitivo inteiro passa de 130 arquivos (quase todo .claude/validation e boa
    parte de .claude/utils), e tornaria quase todo PR do core um merge do maestro. Se o maestro quiser o fecho inteiro,
    é tirar a FRONTEIRA da REGRA 117 e deixar o lint pedir as linhas. O ops/local-gate.sh citado pelo refutador não existe.
29. **O ls-remote isolado da config do git.** Um insteadOf no .git/config (escrito por Edit) desviava a URL constante.
    Cura: cwd=/, GIT_CONFIG_GLOBAL=/dev/null, GIT_CONFIG_NOSYSTEM=1, sem GIT_* do ambiente, e `-c protocol.allow=never
    -c protocol.https.allow=always`. (rb31, com mutante; a bancada troca o protocolo por file, costura declarada)

## 9ª passada: o caminho em variável e o git replace (curado aqui)

30. **O detector do fecho não via caminho em variável.** O materialize-marketplace-repo.sh (que o ensaio de onion-plugins
    roda) executa `bash "${ASM}"` (ASM="${HERE}/assemble-plugin.sh"), `bash "${GEN}"` e `bash "${HERE}/marketplace-readme.sh"`,
    e nenhum casava. Cura: a REGRA 117 resolve as variáveis de diretório do script (`dirname … BASH_SOURCE`, cada `/..`
    sobe um nível) e as que guardam um caminho de script do repo a partir delas, reescreve o texto com elas antes do
    EXEC, e o EXEC passou a ver o source por ponto (`. x.sh`). O lint pediu 16 linhas fecho novas (as 3 do marketplace e o
    que elas executam: plugin-readme, public-face, plugin-dead-link-check, plugin-namespace-check, resolve-role-bundle, e
    o 2º nível de a2a-accept, kg-decide-seal, door-seal-pin e pr-merge-verified). O 2º nível que o refutador do #1652
    apontou já estava: vendor-manifest.sh, selftest-families.py e load-lease.sh. (xvii)-(xx) da REGRA 117, um por forma
    (X="${HERE}/y.sh" + bash "${X}", python3 -I "${P}", `. "${HERE}/y.sh"`, bash "${HERE}/y.sh"), cada um com mutante; rf29
    no pr-merge-verified com o assemble-plugin.sh.
31. **`git replace` desviava a régua.** `git replace <main> <commit forjado>` trocava a árvore que o hook lê. Cura:
    `--no-replace-objects` no hash-object, no rev-parse e no cat-file do ROOT. (rb32, com mutante)

## 10ª passada: o fecho medido por EXECUÇÃO (curado aqui)

32. **Os escapes do fecho no ensaio das portas** (a variável de diretório derivada de outra, `CORE="$(cd "${HERE}/.."
    && pwd)"` e `bash "${LEAK_SCAN}"`; a raiz de mktemp, `bash "${_pb}"`; o caminho montado dentro da função, `_regen`).
    Por decisão de desenho do team-lead, parei de perseguir forma por forma e inverti o ônus: a bancada nova
    `act_trace` (ops/testing/act-trace-check.sh) roda o ENSAIO REAL de onion-core e onion-plugins (o publish-door.sh de
    produção, sem --push) num clone de sandbox, com `bash`, `sh` e `python3` no PATH trocados por um registrador que anota
    cada script executado, e reprova se algum script do repo executado não está numa linha ato/delega/fecho nem abaixo
    da FRONTEIRA do lint. O rastro é a verdade; o detector estático da REGRA 117 é pré-filtro. A 1ª medição achou 29
    scripts fora do fecho (os 3 do refutador e mais 26: o regen-baselines.sh do materialize-door roda os checadores
    de baseline FORA do lint, e por isso eles são do ato); o tsv tem agora 82 linhas fecho. A bancada (a1)-(a3) julga o
    juiz em rastros sintéticos, (b) roda o ensaio e (m) julga o mesmo rastro contra o tsv sem a linha fecho do
    materialize-door.sh, que tem de reprovar nomeando-o. Custo: ~4 min, com nice.
    **O ensaio exercitado é o caminho de produção, com os mesmos argumentos**; a única diferença, declarada, é o
    registro por --members (as portas apontam repositórios bare locais, semeados sem rede); e, onde a fonte privada de termos
    de cliente não existe (CI, pré-voo), o ensaio usa um termo sintético e o registro de bancada sai sem os marcadores
    CONFIDENCIAL/PRIVADO (sem os termos reais nenhum nome se deriva, e o passo 5a recusaria). Nenhuma das duas muda o que
    se executa. **Lacuna nomeada:** o que
    não tem ensaio executável (o merge alheio, o deploy do site, o update do bridge e a persona do Slack) fica no
    detector estático; o rastro não vê arquivo lido por `source`/`.`, nem script executado por `/bin/bash` absoluto ou
    shebang `#!/bin/bash`; e o rastro é o de HEAD (o pre-commit local mede o commit anterior; o CI mede o do PR).
33. **O git replace nos scripts.** `GIT_NO_REPLACE_OBJECTS=1` exportado no `delegated_env_guard` do deploy-site.sh e no
    `_delegated_env_guard` e no `_pmv_fix_path` do pr-merge-verified.sh (o replace ainda desviava o show do resíduo, o
    rev-parse de site/, o merge-base e o show de origin/main:members.yaml e do tsv). (rf30 e o caso L do deploy-site,
    com mutante)
34. **A forma da lista de guarda (decisão do maestro de 2026-11-13, selo D_GUARD_LIST_NAMED_CODEOWNERS_1113 em
    docs/evolution/research/automation-levels-2026-11/automation-levels-2026-11.kg.yaml)**: a lista cujos PRs só o
    maestro mergeia é NOMEADA, arquivo a arquivo, no formato do padrão de mercado CODEOWNERS, e não a pasta inteira
    (medido pelo maestro: ~17% dos PRs contra ~46%). É a forma que o `_guard_paths` do pr-merge-verified.sh já tem
    (derivada do tsv; as entradas com `/` final são as pastas que JÁ eram guarda inteira: workflows, hooks, sudoers,
    review, .githooks). **Medida de conferência (155 commits não-projeção da origin/main, 10 a 13/11):** a lista deste
    head pega 56 (36%), e 53 deles só pelo `.claude/validation/lint-selftest.sh`, que entrou no fecho como executor da
    FRONTEIRA; sem os dois executores do lint (lint-selftest e lint-artifacts), pega 19 (12%). A pasta inteira
    (.claude/hooks, .claude/validation, ops, .github, .githooks) pega 60 (39%). O número do maestro e o meu divergem
    pela janela e pela unidade (PR × commit); a pergunta que sobra é dele: **os dois executores do lint são guarda?**
    Ficam, por ora, porque o ensaio das portas os executa e o fecho tem de cobri-los.
    **Os `confirmed` do grafo editado, conferidos:** E_KG_SSOT_FRONTIER_1111 (nível 3, agir fora da área, sempre por
    PR) é o chão em que o selo se apoia, e não o contraria; E_WATCHER_API_CHURN_MEASURED_1111 (o custo do vigia) e
    E_LGPD_OPERATOR_RESEARCH_1111 (o operador de dados na LGPD) não falam da lista de guarda.
    **Próximo passo nomeado (não coube aqui):** gerar `.github/CODEOWNERS` a partir da mesma derivação do `_guard_paths`,
    com catraca de igualdade no lint. Não coube porque (a) com dono único que é também o autor dos PRs, ligar "exigir
    revisão do dono" na proteção da main trava todo PR de guarda (o autor não aprova o próprio PR), e ligar é do
    maestro; sem ligar, o arquivo só informa; (b) a catraca é guarda nova (REGRA nova pelo /meta:forge-guard); (c) não
    medi se `.github/` viaja para as portas, e um dono nomeado num arquivo que viaja pede decisão de porta.

## LIMITES aceitos (o refutador e o maestro, 2026-11-13)

- **(6) o mesmo usuário**: a sessão roda como o usuário do maestro; os hooks são camada de conformidade, a fronteira
  real é outro usuário do sistema.
- **A FRONTEIRA do lint**: o fecho não desce no que o lint-artifacts.sh e o lint-selftest.sh executam. A reserva: isso só
  vale se nenhum ato executar FORA do lint um script que o lint chama. Agora é conferível: a REGRA 117 examina o que cada
  ato/delega/fecho (exceto os dois executores) executa, então um ato que chamar direto um script de .claude/validation
  pede a linha fecho dele.
- **curl, systemd-run e NOPASSWD**: `curl -X PUT …/merge`, `sudo systemd-run -p User=root …` e o `(ALL) NOPASSWD: ALL`
  do operador passam ou valem por cima do hook; fecham com outro usuário e sem sudo amplo.

## LIMITES declarados (o refutador os apontou; não se curam aqui)

- **BASH_ENV e `--rcfile`**: `BASH_ENV=x bash ops/deploy-site.sh …` e `sudo bash --rcfile x -i <cópia>` passam o hook.
  São anteriores a este PR. O sudoers real (env_reset, !setenv e só o caminho da cópia) barra as formas com sudo.
- **visudo com EDITOR** (`sudo EDITOR='tee -a' visudo -f …`): passa o hook; é a escrita do sudoers por outra porta, e
  hoje o operador já tem NOPASSWD: ALL.
- **Argumento extra na cópia de root** (`sudo …/update-bridge.sh --restart extra-arg`): o hook passa; o sudoers real,
  com argumentos fixos, recusa.
- **A troca de symlink no bridge-backup** entre o teste e o uso é anterior a este PR (o caminho do root já só lê a
  origem por tar).
- **O `ops/moat-targets.tsv` é editável pela sessão**: quem edita a lista edita o veto. A REGRA 117 confere a forma das
  linhas, não a autoria.
- **sudo amplo, `curl` e script em arquivo**: com `(ALL) NOPASSWD: ALL`, `sudo systemd-run -p User=root …` roda
  qualquer coisa como root; `curl -X PUT …/pulls/N/merge` e um script em arquivo com `gh pr merge --repo <outro>` no
  corpo passam o hook (r5b do refutador). Correção de registro (7ª passada): o `gh api … /merge` NÃO passa, o
  refutador mediu e todas as formas dele são vetadas; a 6ª redação deste resíduo dizia que passava, e estava errada.
  São o item 6: a sessão é o usuário do maestro, e a fronteira é outro usuário.
- **A ref `origin/main` local deixou de ser a régua do hook (7ª passada)**: o hook mede a ponta da main no REMOTO
  (`git ls-remote https://github.com/marciocar/onion-evolve refs/heads/main`, URL constante) e exige o objeto aqui
  (`cat-file -e`); sem rede, a forma delegada fecha. O update-ref, o fetch de outro lugar e a escrita no arquivo da ref
  não movem mais a régua sem editar o hook. O script do merge alheio ainda confere contra a origin/main local (limite).
- **A constante do core mora em três arquivos que a sessão edita**: mudar a constante é mudar o script ou o hook, que
  passam por PR e pelo refutador (é a mesma natureza do tsv editável); trocar só o members.yaml não basta mais.
- **O `~/.gitconfig` (include, insteadOf) agora é limite de verdade, não alvo**: ele ainda muda o que o git busca (o
  fetch do deploy-site, por exemplo), mas não muda mais o repo que o merge e o CI miram.
- **O próprio HOME do operador é escrito pela sessão**: com o HOME fixo pelo passwd, o `~/.gitconfig` e o
  `~/.config/gh/config.yml` reais continuam editáveis pelo mesmo usuário (um `insteadOf` ou um `http_unix_socket`
  plantados ali valem no caminho delegado). O mesmo vale para o set-url do origin feito por outra porta que o hook não
  lê (editor, script versionado). Fecha só com a sessão rodando como outro usuário.
- **A sessão do core se mede pelos ancestrais**: um processo desligado da árvore (setsid/nohup com o pai morto) perde o
  ancestral `claude`. O hook barra essas formas na linha. A bancada se declara por ONION_PR_MERGE_VERIFIED_TEST=1, que
  o hook veta na linha da sessão (rb14).

## Tetos declarados

- A regra de sudoers **não reduz nada** enquanto o operador tiver `(ALL) NOPASSWD: ALL` e o grupo `docker` (medido
  com `sudo -n -l`). O card `docs/onion/delegated-ops-sudoers-card.md` diz isso antes do passo a passo.
- `elenxo_isolado: true` no resíduo é auto-atestado: o `deploy-site.sh --verified-pr` exige a declaração, não prova
  o isolamento.
- O veto é camada de conformidade, não fronteira de segurança: o `!` do maestro não passa pelos hooks.

## Não mudou

- Nada instalado na VPS: as cópias e a regra são do maestro (`ops/delegated-ops.sh install`, vetado à sessão).
- `publish-door.sh --push` sem linha `delega`, e a REGRA 117 acusa se alguém a escrever.
