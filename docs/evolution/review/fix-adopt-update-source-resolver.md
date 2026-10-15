---
branch: fix/adopt-update-source-resolver
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: 4628738c4d2750a82d901677e1889596814b0905825e4b1ad07dae5023118972
reviewed_code_sha256: 17d0d924c381d569981579446c48a189c75a3d4d5bdd317690670d2b6f9aa78a
findings_total: 12
findings_real: 11
tokens: 169099
duration_min: 66
findings_fixed: 9
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose (opus), mandato REFUTAR
nota: "B5 (worktree prune no core) não é defeito: só afeta worktree com diretório ausente. B1 e B3 ficam declarados, sem cura."
---

# Passada adversarial: `fix/adopt-update-source-resolver`

## O que muda

Item 3 da SAC-144. O `/meta:adopt --update` passa a resolver a FONTE pelo `resolve-update-source.sh`
(`--source auto|origin|head|<commit>`), que entrega uma raiz cujo HEAD é o commit escolhido. O
`vendor-branch.sh` recusa pin diferente do HEAD da fonte. O `dedicated-branch.sh` ganha `--worktree`. A prosa
do adopt.md cita o mecanismo em dois tempos.

## Achados

- **A1 (alta, curado):** a guarda nova de pin = HEAD deixava vermelho o `(PIN/MUT)` da família `vendor_pin`,
  porque recusava o lixo antes da guarda antiga. Agora ela compara só o pin que resolve (`--verify -q`). A família
  ficou verde dentro das 1362.
- **A2 (alta, curado):** um `settings.json` sujo passava como fonte, porque a sujeira era medida só no manifesto do
  papel. Agora mede o manifesto do papel, o manifesto adopted, o `settings.json` e o `.env.example`. Coberto pelo s12.
- **A3 (alta, curado):** as três seções de procedimento voltavam calado ao checkout num shell novo
  (`${UPDATE_SOURCE_ROOT:-toplevel}`). Agora o placeholder explícito pede a raiz resolvida, com a instrução de
  re-resolver por `--source <pin>`.
- **M1 (média, curado):** num refspec estreito, o fetch não atualizava `origin/<integração>`. O refspec agora é
  explícito, com `GIT_TERMINAL_PROMPT=0`.
- **M2 (média, curado):** o `auto` sem remoto `origin` seguia. Agora recusa com rc=4 e pede `--source head`. Coberto
  pelo s13.
- **M3 (média, curado em parte):** a worktree da fonte vazava no "Já atualizado". A remoção foi posta ali. Um update
  abortado no meio ainda a deixa no git-dir (declarado).
- **M4 (média, curado):** 4 mutantes sobreviviam. Ganharam casos: s7 (porta atrás e auto sem fetch), s11 (mesmo sha
  com árvore suja e retomada suja) e s12/s13. O fixture da porta passou a usar `role: adopted`, para chegar ao
  bloco da porta.
- **B2 (baixa, curado):** `UPDATE_WORKTREE=0` também forçava a worktree. Agora só o valor 1 força.
- **B4 (baixa, curado):** o fetch podia pedir credencial sem TTY. Recebeu `GIT_TERMINAL_PROMPT=0`.
- **B1 (baixa, declarado):** o STATE.md da adoção segue em `<SOURCE_ROOT>`, que é o checkout na adoção. O `--update`
  não usa o STATE.md.
- **B3 (baixa, declarado):** o `--worktree` é ignorado quando a branch do update já está aberta no próprio alvo. A
  retomada vence.

## Mutantes

13 mutantes, plantados por `ops/mutate-and-restore.sh`; cada um reprova o seu caso (s2, s3, s4, s4b, s6, s6b,
s11, s11b, s7 sem fetch, s13, s8, s9 e s10). A bancada das 128 famílias afetadas deu 1362 casos verdes e 0 falhas,
com `LC_ALL=C`.

## Limites declarados

- Porta pública como FONTE ficou fora: o pin carimbado tem de ser commit do core.
- A frequência foi medida em 22 adotantes locais. Os clones de outras máquinas não foram medidos.
- O dogfood rodou o resolvedor no core real com um adotado e uma porta locais, sem escrita no alvo. Um `--update`
  de ponta a ponta num adotante real não foi rodado: o update é escrita no repo do adotante.
