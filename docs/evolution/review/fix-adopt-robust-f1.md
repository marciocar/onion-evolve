---
title: "Revisão — F1 das portas: adoção robusta (SAC-89, absorve SAC-87)"
date: 2026-10-09
branch: fix/adopt-robust-f1
reviewer: "passada adversarial por subagente independente (só leitura, reprodução em /tmp) sobre o diff inteiro; bancada adopt_robust + door/door_seal_pin/role_cut/role_promotion sob LC_ALL=C com um mutante por caso; dogfood dos blocos do próprio adopt.md num sandbox"
reviewed_diff_sha256: cc46f0e8c58d747f476b27ec192b76b9a79f611a4c51ea4f25c0eb30de2d0a20
reviewed_code_sha256: f425390d80bb73cdf2fb56a33318bea1c14f4e83114cba49d71631ff159aed52
findings_total: 8
findings_real: 5
verdict: REPROVADO_E_CURADO
tokens: 175309
duration_min: 10
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Passada adversarial (Elenxo)

O revisor mandou procurar defeito real, sem estilo. Ele afirmou como sustentados os itens 1, 4 e 5 (manifesto, offer-onion-ci e carimbo único). Os achados caíram no item 3 (branch dedicada).

| # | Achado | Classe | Destino |
|---|---|---|---|
| D1 | A retomada quebrava quando o farol mudava entre rodadas. A 1ª rodada, com farol vivo, criava a worktree irmã; a retomada sem farol tentava `checkout` da branch, que já estava presa na worktree, e saía rc=2 (reproduzido) | DEFEITO | **Curado.** O `dedicated-branch.sh` procura a branch em `worktree list` antes do farol (com `worktree prune`). Caso (c4r), cujo mutante reprova |
| D2 | Com farol vivo, o relatório downstream ficava untracked na worktree irmã, depois do PR, e se perdia no `worktree remove`. O `to:` saía com o nome da worktree | DEFEITO | **Curado.** O relatório vem ANTES do commit durável, que o leva na branch dedicada. O `to:` usa `${TARGET:-$DEST}` |
| O1 | O c4 só rodava sem farol (`WORK == TARGET`): trocar `"$WORK"` por `"$TARGET"` na prosa passava verde | mutante que não mordia | **Curado.** c4 roda nos dois modos e lê o re-carimbo no WORK. Medido: o mutante agora reprova (`v2-fora-da-branch`) |
| O2 | Um `ONION_DURABLE_VERIFY=1` exportado vazaria até o commit interno da `onion/vendor` e viraria rc=12 enganoso | real | **Curado.** `ONION_DURABLE_VERIFY=0` fixo na chamada do vendor-branch |
| O5 | A porta pública passava a carregar `framework: onion-evolve`, o nome do core privado | real | **Curado.** A porta carimba o próprio nome (o slug), que é o que o `onion-version.sh` dela responde |
| O3 | O gate cobre só o commit de config + carimbo; o merge da vendor não roda pre-commit | observação | Declarado. Somado ao HARD de nascença, o caminho documentado hoje acaba em `--no-verify` declarado |
| O4 | Bordas do `dedicated-branch.sh`: HEAD destacado, base local atrás do `origin`, alvo parado na branch do update | observação | Declarado. A worktree com diretório apagado ficou coberta pelo `prune` do D1 |
| O6 | Leitores do carimbo da porta | sem defeito | Todos conferidos. Só o `door-seal-pin` lia o campo velho, e agora lê os dois |

## Dogfood

O dogfood executou os blocos do próprio `adopt.md`, extraídos e rodados como o orquestrador faria, num sandbox em /tmp:

- **Adoção `--role standalone`:** saiu `role: standalone`, com 684 arquivos contra 791 do `adopted`.
- **`--update` com outra sessão viva:** a worktree irmã foi criada, a `main` ficou intocada e o checkout alheio seguiu em `main`.
- **`--promote-hub` com farol:** o carimbo caiu na worktree `chore/onion-promote-hub`.

O dogfood achou três coisas que a bancada não via, todas curadas no 2º commit:

- o bloco pós-cópia saía rc=1 no sucesso;
- o `--promote-hub` precisava virar script;
- o bundle `adopted` nasce com 1 HARD (`dissect-lens`), que com o gate ligado recusa o commit final. Este último foi declarado, com cura na F2.

## Resíduos que ficam abertos

- O bundle `adopted` nasce com 1 HARD e o standalone com 2. A cura é a F2 (manifestos por porta).
- `Q_DURABLE_COMMIT_DEIXA_GITIGNORE_FORA` (open, no grafo).
