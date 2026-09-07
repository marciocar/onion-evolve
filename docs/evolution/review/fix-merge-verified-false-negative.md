---
title: "Revisão — o caminho verificado de merge dava falso NEGATIVO; a 1ª cura dava falso POSITIVO"
date: 2026-09-07
branch: fix/merge-verified-false-negative
reviewer: "Elenxo adversarial com mandato de REFUTAR (worker `elenxo-merge`) — veredito REPROVADO na 1ª versão, com falso positivo PROVADO em harness; 8 riscos enumerados, todos curados nesta branch. Bancada nova de 11 vias, do próprio condutor."
reviewed_diff_sha256: 64f3c1c3f753091d993913aa0f242fefddc680719527ed022e3f7dea9bfd9393
findings_total: 8
findings_real: 8
verdict: REPROVADO-E-CURADO
tokens: 800000
duration_min: 50
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O defeito de origem

`ops/pr-merge-verified.sh` é o **único** caminho de merge autorizado no core (um hook veta as
outras vias com `exit 2`). Ele existe para nunca declarar sucesso falso — e tinha a falha
**inversa**: no merge do PR #814 saiu `rc=1` dizendo *"NÃO declaro merge"* para um merge que
**aconteceu**. O `gh` mergeou, apagou a branch, e só então falhou (`could not determine current
branch`, HEAD destacado). O script morria no passo 3 (rc do `gh`) e nunca chegava ao passo 4 — a
prova pelo ESTADO. Falso negativo é mais seguro que o inverso, mas engana: a sessão seguinte
tenta re-mergear.

## A 1ª cura foi REPROVADA — e a reprovação estava certa

Eu tinha testado `state_before` **e** `state_after` vazios (morre, fail-closed) e concluído que o
eixo estava coberto. O refutador testou a metade **assimétrica**: `state_before` vazio (o `gh`
falha na 1ª leitura) + `state_after` = `MERGED` de dias atrás. `case "" in MERGED\|*)` não casa, o
run segue, o merge falha com *"already been merged"*, e o ramo (b) declara `✓ MERGED` com `rc=0` —
**atribuindo a este run o merge de outra pessoa**. Provado em harness, com o script imprimindo a
própria frase "has already been merged" antes de declarar sucesso.

**A lição é sobre o meu teste, não sobre o código: testei a simetria e chamei de cobertura.** O
defeito morava exatamente na combinação que eu não montei. Foi o mesmo padrão do PR anterior.

## Os 8 riscos, e o que fechou cada um

1. **Âncora ilegível → falso positivo total.** `[ -z "$state_before" ] && die` — não consigo ler é
   diferente de não está mergeado, e aqui as duas matam.
2. **Corrida âncora→merge** (outra pessoa, `--auto`, merge queue). Carimbo `t0` antes do merge; um
   `mergedAt` anterior a `t0` (tolerância de 300s para desvio de relógio) **não pode ser deste run**.
   Data não-parseável é fail-closed — não declaro o que não consigo datar.
3. **`state_after` vazio → mensagem que MENTE** (`estado=''` afirma um estado que ninguém leu — a
   reincidência do defeito do #623 com o sinal invertido). Agora tem `die` próprio, dizendo que não leu.
4. **Âncora depois dos gates de check** → um PR já mergeado morria com *"check-run concluiu em
   falha"*, diagnóstico errado. Movida para o topo.
5. **`--sync` matando depois do `✓`.** `git checkout main` falha se `main` estiver tomada por outro
   worktree — o `die` fazia o script sair `rc=1` **após um merge provado**, reintroduzindo pelo sync
   exatamente o falso negativo que este PR existe para matar. Virou aviso: o rc responde pelo MERGE,
   que é o trabalho do script; sincronizar `main` é cortesia.
6. **Assimetria entre os dois `case`.** O bloco de `rc≠0` matava em `MERGED|""`; o passo 4 não tinha
   o padrão e declararia sucesso com `mergedAt` vazio. Apertar um lado e deixar o outro frouxo é
   como o defeito volta pela porta que ninguém olhou.
7. **Evidência disponível e ignorada.** A saída do `gh` (`already been merged` / `not mergeable`)
   era **impressa** pelo aviso e não participava da decisão. Agora barra — e é a única barreira que
   **não depende de relógio nenhum**.
8. **Aviso semi-decorativo.** Mandava rodar `git ls-remote origin refs/heads/<branch>` com o
   placeholder **literal**, sem o comando de remoção. Agora o script lê o `headRefName` real,
   **verifica** se a branch remota sobrou e entrega `git push origin --delete <nome>`.

## O ramo perigoso tem três barreiras independentes

| barreira | fecha | depende de |
|---|---|---|
| âncora não-vazia | `gh` mudo | nada |
| `already been merged` na saída | merge de terceiro / re-run | nada |
| `mergedAt >= t0` | corrida na janela âncora→merge | relógio (com 300s de folga, fail-closed) |

## Bancada: 11 vias (era 0)

`gh` esboçado espelhando as consultas reais (`headRefOid`, `headRefName`, `headRepositoryOwner`,
`statusCheckRollup`, `check-runs`, `pr checks`, `state,mergedAt`). Casos (a)-(e) do desenho
original; (f)-(i) são os que o Elenxo reprovou; (j)-(k) fecham a simetria do passo 4.
O caso (b) — o defeito real do #814 — **continua passando**, que é a razão de existir da cura.

## Limitação declarada

O SUT fala com a rede, então as 11 vias rodam contra um **esboço** do `gh`. O esboço espelha as
consultas reais, mas não prova que o `gh` de verdade responde assim em cada cenário — a evidência
behavioral para o caso (b) é a medição do merge do #814, registrada no grafo, não um caso automático.
