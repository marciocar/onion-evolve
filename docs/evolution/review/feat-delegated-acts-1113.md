---
title: "Revisão — as guardas dos atos delegados de 2026-11-13 (merge alheio, deploy do site, scripts da VPS)"
date: 2026-11-13
branch: feat/delegated-acts-1113
reviewer: "5ª passada: o refutador independente no head d820c629b REPROVOU com 1 bloqueio (o members.yaml define o core) e 2 itens baratos (ExecStart e DropInPaths efetivos, /run/systemd/system), curados aqui com o harness re-rodado (after4.txt). 4ª passada: o refutador independente no head ad3260def conferiu as formas de linha curadas e REPROVOU com 2 bloqueios estruturais (F1, F2), curados aqui com o harness re-rodado (after3.txt). 3ª passada: a re-refutação independente no head 454a3c1bb conferiu B1-B5 curados e REPROVOU com 3 novos (N1-N3), curados aqui e com o harness re-rodado (after2.txt). 2ª passada: refutador INDEPENDENTE (agente separado, a pedido do team-lead) REPROVOU com 5 bloqueios (B1-B5), harness em scratchpad/refute1647 (all.sh, allp.sh, cases1-4); o condutor curou e re-rodou o harness do refutador contra a cura. 1ª passada: o condutor sobre o próprio diff. Bancada: moat_gate (dl1-dl5, db1-db8, rb1-rb14, cada um com mutante), pr_merge_verified (fr1-fr11, rf1-rf9, fr-MUT, rf-MUT), deploy_site (52/52, com os casos B2/B4), slack_persona (29/29, com os casos B5), act_signature (13/13 + 12 mutantes), visudo -cf parsed OK"
reviewed_diff_sha256: af33f832970dc7fe14a1b5c64bcba58be33d56572f371e161afa43bbc0c15a6a
reviewed_code_sha256: 3263570a810fa2e973a5881a393e1b0971989504b3640c085442b19910a64ed8
findings_total: 19
findings_real: 19
findings_fixed: 19
tokens: 0
duration_min: 60
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
nota: "o refutador independente reprovou quatro vezes (B1-B5, N1-N3, F1-F2, M1); as curas entraram neste PR. PR de guarda: a cura do M1 também passa por refutador independente antes do merge"
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
