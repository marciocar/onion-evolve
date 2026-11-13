---
title: "Revisão — as guardas dos atos delegados de 2026-11-13 (merge alheio, deploy do site, scripts da VPS)"
date: 2026-11-13
branch: feat/delegated-acts-1113
reviewer: "2ª passada: refutador INDEPENDENTE (agente separado, a pedido do team-lead) REPROVOU com 5 bloqueios (B1-B5), harness em scratchpad/refute1647 (all.sh, allp.sh, cases1-4); o condutor curou e re-rodou o harness do refutador contra a cura. 1ª passada: o condutor sobre o próprio diff. Bancada: moat_gate (dl1-dl5, db1-db8, rb1-rb14, cada um com mutante), pr_merge_verified (fr1-fr11, rf1-rf9, fr-MUT, rf-MUT), deploy_site (52/52, com os casos B2/B4), slack_persona (29/29, com os casos B5), act_signature (13/13 + 12 mutantes), visudo -cf parsed OK"
reviewed_diff_sha256: 4dcec4d3e324f1a253ce23371eebdd15795367baff4c5bba086eb4c6a1a1ab63
reviewed_code_sha256: 1d57dd60cb81d128e03ef4afaa2d4cf349f7f5f063f842e51ef2714dbdcbb0b8
findings_total: 12
findings_real: 12
findings_fixed: 12
tokens: 0
duration_min: 60
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
nota: "o refutador independente reprovou a 1ª forma (B1-B5); a cura entrou neste PR. PR de guarda: a cura também passa por refutador independente antes do merge"
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
