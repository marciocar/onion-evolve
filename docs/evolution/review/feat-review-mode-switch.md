---
title: 'Resíduo — interruptor do revisor de IA do CI: ONION_REVIEW_MODE on|off|auto (padrão off) e a label review:ia'
date: 2026-10-13
branch: feat/review-mode-switch
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 8
findings_fixed: 5
tokens: 0
duration_min: 150
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Executa a decisão do maestro de 2026-10-13 (D_REVIEW_MODE_SWITCH_PADRAO_OFF, selada por
  kg-decide-seal.sh no grafo docs/onion/graph/review-gate-saldo-2026-09.kg.yaml, com a evidência
  E_REVIEW_MODE_SWITCH_FORJADO). A regra mora em ops/review/review-mode-decide.sh, que tem bancada
  (família review_mode, 19 casos, cada um com mutante que reprova). O merge-verified ganhou cinco casos
  rv-* na família pr_merge_verified (45/45). A passada adversarial partiu do default reprovado: 10
  achados, 8 reais, 5 curados e 3 declarados como teto; 2 hipóteses foram refutadas por medição.
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O que mudou

- `ops/review/review-mode-decide.sh` (novo): o juiz do interruptor. `--mode` aceita on|off|auto, com
  vazio = off e um enum EXATO, sem normalizar (`ON`, `" on"` e `off ` dão rc 2 nomeado). A label
  `review:ia` força a revisão por pertinência exata no array JSON. O `auto` aplica a lista de caminhos
  sensíveis e o teto de 600 linhas de código, que foi medido. `--verdict-gate` é o passo do check, e
  `--print-marker` dá a marca que o merge-verified lê.
- `.github/workflows/onion-review.yml`: os types ganham `labeled` e `unlabeled`. Entra o job leve
  `onion-review-mode`, que não chama API nem lê secret e cujo juiz vem da BASE do PR. O `onion-review`
  só roda com `run == 'true'`. O `onion-review-verdict` passa pelo `--verdict-gate` antes do veredito
  de sempre.
- `ops/pr-merge-verified.sh`: desligada ⇒ "SUCCESS por revisão DESLIGADA, não por aprovação", sem
  dispensa e sem comentário. Se um run anterior no mesmo head apontou violação, o merge recusa e exige
  a dispensa nomeada. Histórico ilegível ⇒ recusa.
- `ops/apply-ruleset-main.sh`: cria a label `review:ia` ao lado da `ci:full`. A lista fica em `_LABELS_SPEC`.
- `ops/review-gate-health.sh`: corrige uma linha do cabeçalho que a medição refutou.
- `docs/technical-context/04-workflow/contributing.md` §3.2: seção "Interruptor do revisor".
- Grafo: `D_REVIEW_MODE_SWITCH_PADRAO_OFF`, `E_REVIEW_MODE_SWITCH_FORJADO` e a cura de duas chaves
  `gatilho:` para `x_gatilho:`. Era dívida do grafo que o selador recusava (`form.unknown-key`), e a
  forma `x_` é a convenção que os outros grafos já usam.

## Medições

- Anotação: `::notice::` de step VIRA anotação do check-run. No PR #887, o `notice` do caso benigno
  aparece em `gh api .../check-runs/<id>/annotations`. Isso refutou a linha do review-gate-health que
  dizia o contrário. O `.output.title/summary` sai `null`, como o script já registrava.
- Teto do `auto`: últimos 100 PRs mergeados, contando linhas de código fora de `docs/` e `*.kg.yaml`.
  Deu p50=198, p70=470, p75=579 e p90=1104, e o teto ficou no p75 arredondado (600). 78 dos 100 tocam
  a lista, 77 deles por `.claude/validation/`. Entre os 22 restantes, o maior tinha 410 linhas.
  **Consequência: o `auto` revisaria cerca de 78% dos PRs deste repo.** É dado para o maestro, não defeito.

## Passada adversarial (default reprovado na dúvida)

1. **REAL, CURADO.** Um PR que reescreve o próprio juiz para dizer `run=false` se desligaria sozinho.
   Agora o juiz da decisão vem da base (`git show BASE_SHA:...`). A exceção declarada é o bootstrap,
   ou seja este PR. E `ops/review/*` entrou na lista do `auto`.
2. **REAL, CURADO.** Label removida depois do run: o vermelho de um parecer que apontou viraria o verde
   "desligada". O merge-verified agora lê o histórico do check no head (`filter=all`) e recusa (rv-b).
   Com dispensa nomeada, passa e registra que o achado existiu (rv-c).
3. **REAL, CURADO.** Variável com espaço ou maiúscula: o enum exato dá falha nomeada nos casos l, m e n.
   O caso n prova que a label não salva um valor quebrado.
4. **REAL, CURADO.** Diff que renomeia hook para `docs/`: `--no-renames` faz o nome antigo contar (caso j,
   com o mutante `-M --name-only` sobrevivendo só se o caso não pegasse).
5. **REAL, TETO.** O evento `pull_request` roda o workflow e os scripts do PR. Um PR que reescreve o
   próprio YAML ou o `--verdict-gate` controla o próprio check. A classe é anterior a este PR (já
   valia para `review-verdict.sh --gate`). O juiz da base fecha só a variante "mexi no script e não no YAML".
6. **REAL, TETO.** Label alheia também dispara o workflow e recalcula a mesma decisão. No modo `on`, ou
   com a `review:ia`, isso re-roda a revisão. Pular esse run deixaria um SKIPPED por cima do veredito
   real. O preço está declarado no YAML e na doc.
7. **REAL, TETO.** Label posta por quem não é dono: pôr label exige permissão de triagem e só ACRESCENTA
   revisão, então custa tokens e não tem bypass. Alternar a label em loop gasta tokens, com a
   concorrência cancelando o run em voo. Isso fica declarado, sem cura.
8. **REFUTADO.** "PR de fork passa a sair verde": os três jobs exigem `fork == false`, então o fork segue
   como antes (verdict skipped, que o merge-verified recusa).
9. **REFUTADO.** "Desligada some da telemetria como gate cego": no `review-gate-health.sh`, PR sem parecer
   é NO-PARECER, que não entra na sequência cega (lido no código).
10. **REAL, CURADO, achado pela MEDIÇÃO no próprio PR.** Pus e tirei uma label alheia no #1076. O head
    passou a ter DUAS check-runs `onion-review-verdict`, e a API devolveu as duas mesmo SEM `filter=all`.
    O `statusCheckRollup` também: saiu `SUCCESS\nSUCCESS`. O `pr-merge-verified` comparava esse valor
    com `SUCCESS` e recusaria, e um veredito velho em falha bloquearia o verde novo para sempre. Com
    labels re-disparando o workflow, isso deixa de ser raro. Cura: `_LATEST_PER_NAME_JQ` (uma linha por
    nome, maior id) e o rollup pelo mais recente, com o caso (t) e um mutante na família `review_mode`.
    O `review-gate-health.sh` também lê agora pelo maior id, onde antes usava `head -1`.

## O que NÃO foi medido

- O caminho do CI com a variável `on`/`auto` e a label `review:ia` em PR real. A variável não pode ser
  setada por esta sessão, e a revisão real está sem crédito (D_SEM_CREDITO_POR_ORA).
- MEDIDO no #1076, modo off com a variável ausente: `onion-review-mode` pass (o juiz do bootstrap, com
  warning), `onion-review` skipping, `onion-review-verdict` pass, com a anotação `notice` "onion-review-desligado:
  revisão desligada (modo off, motivo: variável ausente ou vazia ⇒ padrão off; sem a label review:ia)".
  O `check_name` + `filter=all` devolveu os 2 runs do head (achado 10).
- O comportamento do adotante: `onion-review.yml` não viaja pelo `/meta:adopt`, que só oferta o
  `onion-validate.yml`. Quem copiasse o workflow à mão precisaria de `ops/review/`.
