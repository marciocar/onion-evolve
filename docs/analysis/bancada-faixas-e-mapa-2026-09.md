# Bancada em faixas e mapa família→arquivo — pesquisa de embasamento (2026-09-02/03)

**Pergunta do maestro** (verbatim, 2026-09-02): *"~830 não é muito? não deveria ter uma separação? será que todos são
necessários?"* e *"esta estratégia é a estratégia padrão?"* — sobre `lint-selftest.sh` (~850 casos, cada um sobe um
sandbox e roda o lint inteiro: O(casos × lint), single-thread, ~14 min no CI e >25 min na VPS sob carga).

**Este documento é EVIDÊNCIA para uma decisão aberta** (`D_BANCADA_FAIXAS_E_MAPA` em `docs/onion/graph/fios-abertos.kg.yaml`),
não a decisão. Nasceu como fan-out de pesquisa (4 eixos: doutrina de pre-commit/merge-queue, suítes de shell, valor de
teste/mutation/agentes, mercado/capital) e ficou no scratchpad até ter um nó que a justifique — regra da casa: mudança com
embasamento datado, nunca no susto.

**Medições locais que a motivaram (2026-09-02/03):** 6 reprovações de gate em 24 h, todas por classes já conhecidas e
baratas de checar (contagem antiga em docs, vendor-scrub, registro de regras, `lint` local por família, TDZ em workflow,
aspas simples em `printf` de bancada) — cada uma custando 15–25 min de gate; uma faixa rápida (`pre-gate.sh`, scratch)
pega as mesmas classes em segundos e ficou fora do repo até esta decisão.

**Resumo das respostas** (detalhe nas tabelas abaixo, com tier de fonte):
1. Rodar a bancada inteira no pre-commit **não é padrão** — pre-commit.com passa só os arquivos staged; `--all-files` é
   documentado como uso de CI.
2. O estado da arte 2026 é **escopo declarado + prova de não-interferência + recusa no incerto** (Mergify, merge queue).
3. Rodar tudo no CI é doutrina; o que não se sustenta é o **número** (DORA: <10 min).
4. Técnicas consagradas: RTS por arquivo (Ekstazi/Nx affected), paralelismo (bats `--jobs`, Git `make -jN` + `prove`),
   ordenação por histórico (lentos/falhados primeiro). **Nenhuma fonte primária de agente (Claude Code/Codex/Cursor)
   fazendo seleção por diff** — se o Onion fizer seleção declarada com failsafe, está à frente.
5. **Mercado**: seleção de teste NÃO é o escasso (Launchable virou feature da CloudBees; Cursor comprou Graphite; test
   intelligence é feature paga de plataforma, nenhuma cobre shell). O escasso é confiança no que o agente produz.

**Desenho recomendado (5 passos, na ordem):** (1) paralelizar antes de selecionar — o sandbox já isola cada caso;
(2) mapa família→globs + `git diff --name-only` próprio; (3) failsafe: tocar lint/harness/regras/mapa ⇒ tudo;
(4) três faixas: pre-commit = afetado + faixa rápida, pre-push/PR = famílias tocadas, CI = completo;
(5) mutation só dirigido a risco nomeado. **Não fazer:** PTS por ML, plataforma paga, `tj-actions/changed-files`
(CVE-2025-30066), mutation como escore, deletar famílias quietas, trocar harness.

---

## Tabelas da pesquisa (recuperadas do run; tier: 8-9 primária · 7 vendor-on-self · 5 vendor-on-competitor · 3-4 blog)

| pre-commit.com (primária) | hooks recebem só os arquivos STAGED; filtros files/exclude/types; stages commit/push; `--all-files` = "useful if you are using pre-commit in CI" | 8 primária | rodar a bancada inteira no pre-commit é o anti-padrão que o framework existe para evitar |
| GitHub merge queue (docs) | checks obrigatórios no evento merge_group | 9 primária | gate caro vive na fila, não no PR |
| tenki.cloud blog 2026 | leve no PR, caro na fila; batching 4 PRs ⇒ ~25% execuções | 4 secundária | direção certa, número de blog |
| Mergify changelog 2026-07-20 (direct merge for scope-unaffected PRs) | escopo declarado + prova de não-interferência; RECUSA quando não prova | 7 vendor-on-self | estado da arte 2026 = escopo + prova + recusa no incerto |
| blogs 2025-26 "pre-commit <1s, pre-push <10s, CI completo" | — | 3-4 | direção certa, SEM primária |

## C. Suítes de shell
| bats-core usage | `--jobs N` (GNU parallel); ordem não garantida; exige isolamento; re-rodar ao ligar -j | 8 primária | cada caso do Onion já nasce em sandbox — paralelizar é o ganho de menor risco |
| Git t/ suite (gitforwindows + git-scm unit-tests) | maior suíte de shell em produção: `make -jN` + `prove` (lentos primeiro, re-roda os que falharam) | 8 primária | paralelismo + ordenação por histórico, SEM seleção por diff |
| ShellSpec comparison | paralelo, foco/tags, mock, POSIX vs bats bash-only | 5 vendor-on-competitor | trocar harness não ataca O(casos × lint); aproveitar tag/foco por família |

## D. Valor de teste / mutation / agentes
| InfoQ 2026-01 + arXiv 2501.12862 | Meta: mutation guiado por LLM em produção (out-dez/2024), 73% dos testes gerados aceitos | 8 | mutation DIRIGIDO a risco nomeado, nunca varredura global |
| guias 2026 | mutation clássico não pegou: excesso de mutantes, custo, equivalentes; escore 75-85% | 4 | não usar escore como gate |
| busca agentes 2026 | NENHUMA fonte primária de Claude Code/Codex/Cursor fazendo seleção por diff | lacuna | se o Onion fizer seleção declarada, está à frente |
"Testes que nunca falham": nenhuma primária defende deleção; DORA trata suíte confiável como controle; Trunk vende QUARENTENA de instável.

## E. Mercado/capital
| CloudBees adquire Launchable 2024-08-07 → "CloudBees Smart Tests" | o único puro-sangue de PTS virou feature de plataforma |
| Cursor adquire Graphite 2025-12-19 (Série B US$52M) | capital foi para agente+review; escasso = confiança no que o agente produz |
| Datadog TIA, Buildkite Test Engine (per-seat), Trunk Flaky Tests (US$25M A) | test intelligence = feature paga de plataforma; nenhuma cobre shell |
| Mergify "$0 raised" | nicho maduro sem VC |
| Nx US$16M A (2023) | affected = infra de monorepo; grafo estático + failsafe, não ML |
Síntese: seleção de teste NÃO é o escasso.

## (i) 4 respostas
1 padrão? NÃO (pre-commit = só staged; --all-files é de CI). 2 moderna? NÃO (2026 = escopo declarado + prova + recusa). 3 mais usada? no CI rodar tudo é doutrina; o que não se sustenta é o NÚMERO (DORA <10 min). 4 consagradas: RTS por arquivo (Ekstazi), TEST_MAPPING, paralelismo (bats --jobs, git make -j/prove).
## (ii) Desenho (5)
1 paralelizar antes de selecionar (sandbox já isolado; --only já existe: lint-selftest.sh:244/:775/:1186); 2 mapa família→globs (TEST_MAPPING) + git diff --name-only próprio; 3 failsafe: tocar lint/harness/rules/mapa ⇒ tudo; 4 três faixas: pre-commit afetadas+smoke (dezenas de s) · CI PR completa paralela (10 min) · merge completa no head; 5 provar a seleção: rodar seleção e completa em paralelo N semanas, contar perdas; registrar duração e reprovações reais por família.
## (iii) Não fazer
PTS por ML; plataforma paga (sem shell); tj-actions/changed-files (CVE-2025-30066, 2025-03-14, 23k repos); mutation como escore; deletar famílias quietas; trocar harness.
## (iv) NÃO-VERIFICADOS
"<1s/<10s" só blogs; perfis/simulação Develocity = marketing; agentes com seleção por diff = nenhuma fonte; "97%" atribuído ao DORA = agregador; Trunk Série B; preço Buildkite e data do rebrand Launchable; parser da bancada varrido por padrão (só ONION_SELFTEST_STRICT achado); O(casos × lint) lido, não medido por família.