---
title: "Revisão — as guardas dos atos delegados de 2026-11-13 (merge alheio, deploy do site, scripts da VPS)"
date: 2026-11-13
branch: feat/delegated-acts-1113
reviewer: "passada própria do condutor sobre o próprio diff (sem subagente: o brief vedou spawn); bancada moat_gate (dl1-dl5, db1-db8, cada um com mutante), pr_merge_verified (fr1-fr11 + fr-MUT), deploy_site (43/43), slack_persona (26/26), act_signature (13/13 + 12 mutantes), delegated-ops --selftest 5/5, visudo -cf parsed OK, e o hook real rodado com payload PreToolUse nas 6 formas"
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
findings_fixed: 7
tokens: 0
duration_min: 60
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: false
nota: "PR de guarda: exige refutador INDEPENDENTE (agente separado) antes do merge; esta passada é uma voz só"
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

## Tetos declarados

- A regra de sudoers **não reduz nada** enquanto o operador tiver `(ALL) NOPASSWD: ALL` e o grupo `docker` (medido
  com `sudo -n -l`). O card `docs/onion/delegated-ops-sudoers-card.md` diz isso antes do passo a passo.
- `elenxo_isolado: true` no resíduo é auto-atestado: o `deploy-site.sh --verified-pr` exige a declaração, não prova
  o isolamento.
- O veto é camada de conformidade, não fronteira de segurança: o `!` do maestro não passa pelos hooks.

## Não mudou

- Nada instalado na VPS: as cópias e a regra são do maestro (`ops/delegated-ops.sh install`, vetado à sessão).
- `publish-door.sh --push` sem linha `delega`, e a REGRA 117 acusa se alguém a escrever.
