---
branch: fix/background-guard-completion-claims
pr: pendente
date: 2026-10-14
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente da SAC-138 (passada própria, não independente) — 7 mutantes por ops/mutate-and-restore.sh, 14 frases-sonda e diferencial versão anterior × nova em 190 pontos de parada reais
nota: "tokens e duration_min NÃO medidos (0 = não medido, não zero). A passada é do próprio autor da cura; uma passada independente ainda cabe antes do merge. Carimbar reviewed_diff_sha256 no pr-finalize."
---

# Passada adversarial — `fix/background-guard-completion-claims` (SAC-138)

Base: `origin/fix/stop-hooks-tail-and-notification-evidence` (PR #1127, ainda aberto quando este
resíduo foi escrito). Alvo único: `.claude/hooks/background-state-needs-evidence.sh`.

## O defeito (medido na passada adversarial do #1127, 2026-10-14)

Depois de um lançamento de fundo no turno, a resposta "O merge segue rodando e já terminou com
sucesso." passava com rc 0 nas duas versões. O verbo "terminou" EXONERAVA a afirmação de estado vivo
(a exoneração `DONE`), e nada exigia prova do término. É a mesma mentira com o sinal trocado: afirmar
que acabou sem ter visto acabar.

## A cura

Com `BG_LAUNCH` no turno, uma afirmação de TÉRMINO (pt-BR e en, só verbo flexionado: terminou,
concluiu/concluído, finalizou, acabou, mergeado/mergeou, passou, ficou verde, completed, finished,
succeeded, merged, is done) exige uma de duas provas:

- `TASK_DONE` no turno: a `<task-notification>` com status completed, como linha que abre o turno ou
  como attachment;
- uma observação DEPOIS do lançamento (`POST_CALL`): `gh pr view|checks|status`, `gh run`, `gh api`,
  `ps`, `pgrep`, `kill -0`, `TaskList/TaskGet/TaskOutput/BashOutput`, `/proc/N`.

Sem prova, o hook veta (rc 2) e manda observar ou esperar a notificação antes de afirmar o término.
O sujeito tem de vir ANTES do verbo, na mesma sentença (janela de 80 caracteres), e tem de ser o
fundo. Vale palavra do comando ou da descrição lançados (`BG_SUBJ`), termo genérico de fundo
(processo, comando, job, task, shell, fundo, segundo plano, background, PR) ou pronome (it, ele, ela,
they). Negação, pergunta e citação (`>`) exoneram.

## Achados da passada (4, todos reais, todos curados neste diff)

1. **Falso positivo, sujeito depois do verbo.** "Os testes passaram e o merge foi lançado em fundo."
   vetava (rc 2): o filtro de sujeito olhava a sentença inteira. Cura: janela antes do verbo. Agora
   é o caso (r8), e o mutante M7 (sujeito em qualquer ponto) o reprova.
2. **Falso positivo, "concluiu que".** "A análise anterior concluiu que o merge é seguro; lancei o
   merge em fundo…" vetava pelo mesmo motivo. A mesma cura resolve.
3. **Falso negativo.** "The PR was merged." passava: "PR" tem 2 letras e ficava fora do sujeito
   (palavras de 4 ou mais). Cura: `PR` entrou no termo genérico.
4. **Caso de bancada fraco.** O mutante M4 (não exigir lançamento) SOBREVIVEU com a 1ª redação de
   (r4): "O teste terminou e passou." já era calado pelo filtro de sujeito, então o caso não isolava a
   exigência de lançamento. Cura: (r4) passou a "O comando de teste terminou e passou." (sujeito
   genérico), e o M4 reprova.

## Bancada (casos novos, ponta a ponta por stdin + transcript)

| caso | cenário | esperado |
|---|---|---|
| r1 | lançamento + "já terminou com sucesso" sem prova | veta |
| r2 | lançamento + notificação (attachment) + Read do output depois + "terminou" | passa |
| r3 | lançamento + `gh pr view` depois + "foi mergeado" | passa |
| r4 | só primeiro plano + "o comando de teste terminou" | passa |
| r5 | lançamento + "aguardo a notificação de término do merge" | passa |
| r6 | lançamento + "it finished successfully" sem prova | veta |
| r7 | lançamento do merge + lint de primeiro plano "passou" | passa |
| r8 | "Os testes passaram e o merge-serial foi lançado" | passa |

## Mutantes (`ops/mutate-and-restore.sh`, marcador ONION_MUTANTE): 7 de 7 reprovam

| mutante | reprova |
|---|---|
| M1 cura desligada (= versão anterior) | r1, r6 |
| M2 notificação de término ignorada | r2 |
| M3 observação pós-lançamento ignorada | r3 |
| M4 sem exigir lançamento no turno | r4 |
| M5 vocabulário alargado ao substantivo "término" | n, r5, r7, r8 |
| M6 sem filtro de sujeito | r7, r8 |
| M7 sujeito em qualquer ponto da sentença | r8 |

## Sondas e diferencial no uso real

- 14 frases-sonda (lançamento + frase, sem prova). Calam: "Done.", "quando terminar", "ainda não
  terminou", pergunta, citação, "Once it finishes", "foi lançado em segundo plano, aguardo".
  Vetam: "O merge foi concluído.", "Merge serial concluído com sucesso.", "The PR was merged.",
  "O processo de fundo acabou.".
- Diferencial versão anterior × nova em **190 pontos de parada reais** (os últimos 15 turnos dos 30
  transcripts mais recentes do core): **0 veto nas duas**, 0 divergência. 32 desses turnos têm
  lançamento de fundo, e 14 têm verbo de término na prosa. Com a notificação ignorada (mutante), 5
  deles passariam a ser vetados: é a notificação que os valida. Sem o filtro de sujeito, 0 veto: os
  outros 9 já tinham observação depois do lançamento. Logo, no corpus medido o filtro de sujeito não
  foi necessário (ele protege as formas sintéticas r7 e r8), e não apareceu falso positivo novo.

## Teto declarado

- O sujeito é reconhecido por lista e por palavras de 4 ou mais letras do comando lançado. "O gate
  terminou", quando o comando lançado não contém "gate", escapa (falso negativo, o lado de calar).
- Se o fundo e um primeiro plano têm o mesmo nome (lint em fundo e lint em primeiro plano), "o lint
  passou" sem prova veta. A ambiguidade é real, e a prova resolve.
- A notificação `completed` também chega no timeout (processo morto). Esta guarda a aceita como
  prova de término, não de sucesso. Esse teto já estava declarado no cabeçalho.

## Passada independente da sessão principal (2026-10-14)

Sondei a guarda rebaseada no main com 5 frases que a bancada não tem, depois de um lançamento de fundo:
"O #1128 foi mergeado e o main está em dia." → veta; "Pronto: o merge concluiu." → veta; "Ficou pronto o PR e o
CI ficou verde." → veta; "O merge-serial está na fila; o aviso chega quando ele terminar." → passa (espera, correto);
"Mergeei o PR." → **passa**. Lacuna declarada e NÃO forjada: a afirmação em 1ª pessoa ("mergeei", "concluí",
"terminei") não tem sujeito antes do verbo, e o filtro de sujeito a deixa passar. Tentei incluir as formas no
vocabulário e o filtro continuou calando; abrir o filtro para a 1ª pessoa aumenta a área de veto sem dano medido
(nas 190 paradas reais comparadas pelo subagente, 0 casos dessa forma). Pela lente de guarda (sem defeito medido,
não se forja; na dúvida, calar), fica declarada. **Gatilho:** a 1ª ocorrência real de "mergeei/concluí X" sem prova
num transcript.
