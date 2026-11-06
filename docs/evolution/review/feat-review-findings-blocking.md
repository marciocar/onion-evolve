---
branch: feat/review-findings-blocking
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 6
findings_blocking: 4
tokens: 0
duration_min: 0
findings_fixed: 4
verdict: REPROVADO_E_CURADO
elenxo: nao
reviewer: autor (agente de execução forge-findings-blocking), passada própria sem agente separado
nota: "Passada própria do autor, sem revisor separado: o brief da sessão principal proibiu abrir agentes. A sessão principal confere o diferencial antes do PR. tokens e duration_min = 0 porque não foram medidos à parte do trabalho. 1º resíduo com findings_blocking: blocking=4 non_blocking=2 (o 4º veio do CI, door-mini (a))."
---

# Passada adversarial: `feat/review-findings-blocking`

## O que muda

- `review-artifact-check.sh`: campo opcional `findings_blocking` (número, `0 ≤ blocking ≤ real`), cobrado no
  `--schema` e no julgamento do PR (tag `FINDINGS-BLOCKING-INVALIDO`); o `--skeleton` o emite logo depois de
  `findings_real`. Resíduo sem o campo segue válido: os 912 resíduos existentes deram o mesmo rc no `--schema`
  antigo e no novo (912 de 912, zero diferenças, nenhum tem o campo).
- `review-ledger.sh`: coluna nova no fim do TSV/JSON e a linha "achados que BLOQUEIAM" com a população que declara.
- Régua canônica em `.claude/commands/common/prompts/review-triage.md`, adaptada do brief da curadoria
  (`docs/curation/tools/review-triage-brief.md`, só lido), ligada em `/engineer:pr`, `/meta:forge`,
  `/meta:forge-guard` e `/meta:dissect`.
- `onion-research.js`: os dois Elenxos exigem `triage` (bloqueia|limite) na objeção que sobrevive, com a régua
  no prompt (`TRIAGE_NOTE`) e a contagem no log.

## Achados

- issue (blocking): o fragmento, o `/engineer:pr`, o checador e a bancada diziam "8 rodadas sem a triagem e 1
  com ela". cenário: quem lê o número cita 8→1 como medido, e o grafo da curadoria registra 8 versões e, com a
  triagem pedida na 7ª rodada, fechamento em 2. Curado: o texto passou a citar a medida do grafo.
- issue (blocking): o `/meta:dissect` citava "o revisor separado da Etapa 0", que o comando do core não tem
  (é prática da curadoria). cenário: quem segue o comando procura um revisor que não existe. Curado: "o
  refutador do N3, e toda revisão separada que a dissecação encomendar".
- issue (blocking): o caso (og2) da família `research_workflow` casava `then: { required: ['superacao',
  'criterio'] }` literal, e o campo `triage` o derrubou (pego pela bancada). cenário: a bancada fica vermelha
  em todo PR, ou alguém tira o `triage` para ela voltar a verde. Curado: a regex aceita campos a mais, e o
  caso novo (tri) cobra o `triage` (mutante manual sem a régua num prompt: reprovou `regua-no-prompt(1/2)`).
- issue (blocking): o `engineer:pr` viaja na porta mini e passou a citar `review-triage.md`, que a allowlist não
  leva (pego pelo CI, `door-mini (a)`, run 42163288689). cenário: o mini materializado sai com ponteiro morto e a
  porta reprova no próprio checador. Curado: `known_absent` no `roles.yaml` com o porquê (a régua cita comandos de
  meta que não viajam, e o iniciante não tem passada adversarial); levar o fragmento ao mini criava 3 ponteiros
  mortos novos, medido. `door_mini` local: 13 passaram.
- suggestion (non-blocking): o `findings_blocking` com mais de 19 dígitos estoura a aritmética do bash e pode
  passar o teto. limite: o teto 0 ≤ blocking ≤ real vale para número de até 18 dígitos; valor absurdo não é testado.
- suggestion (non-blocking): o write(KG) do `onion-research` recebe o `triage` no JSON do Elenxo, mas o prompt
  do escritor não diz como modelá-lo. limite: a triagem do Elenxo da pesquisa chega ao log e ao JSON; o grafo
  só a carrega se o escritor a transcrever.

## Mutantes

Cópia limpa provada no mesmo arranjo antes de contar o morto:

- `review-artifact (t)`: sem o teto `blocking ≤ real`, `findings_blocking: 3` com `findings_real: 2` passa.
  Limpa rc 1, mutante rc 0.
- `residue-schema (h)`: sem a chamada `_blocking_problem` no esquema, o mesmo resíduo passa no `--schema`.
  Limpa rc 1, mutante rc 0.
- `research-workflow (tri)` (manual, fora da bancada): sem `TRIAGE_NOTE` num dos dois prompts, o caso reprova.

## Limites declarados

- O validador cobra a forma e o teto, não se a triagem foi justa: isso é de quem lê o resíduo.
- `findings_blocking` ausente = não triado; o ledger conta só onde o campo foi declarado.
- Números acima de 18 dígitos não são testados (estouro do bash).
- O write(KG) do `onion-research` não tem instrução própria para o `triage`.
- Passada sem revisor separado (`elenxo: nao`), por ordem do brief.
