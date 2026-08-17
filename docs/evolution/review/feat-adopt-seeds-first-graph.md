---
branch: feat/adopt-seeds-first-graph
pr: 629
date: 2026-08-17
reviewed_diff_sha256: 75e84b8aff60db21a2c8cbd54d3275fddfefe4f3fa8871d6eeb5940ed5330a4f
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 35
verdict: CONFORME-COM-DEFEITO-DE-ENVIO-CURADO-E-DOIS-DEFEITOS-PROPRIOS
reviewer: pergunta do maestro ("não tem nem KG para mapear?") + medição no adotante real + o radar reprovando o artefato que eu gerei
REVISOU: true
---

# Resíduo — `feat/adopt-seeds-first-graph`

**Origem: uma pergunta do maestro, não uma inspeção.** Depois da adoção do adotante novo, ele
perguntou: *"você adotou mas não tem warm-up global nem catch-up? não tem nem kg para mapear??
preciso dos recursos, como vou operar sem ficar preso em uma sessão aqui?"*.

**Medi antes de responder, e a pergunta estava meio certa — do jeito que importa.** Os RECURSOS
estavam todos lá: `warm-up.md`, `catch-up.md`, `onion.md` (3/3), 11 skills, agentes, comandos. O que
faltava era o **estado**: **zero `.kg.yaml`**.

## Achado 1 — a adoção nunca semeou o primeiro grafo (defeito de ENVIO)

O passo 0 do `/warm-up` é *"se existir um `.kg.yaml` no repo, consulte-o PRIMEIRO"*, resolvido ao
vivo por `git ls-files '*.kg.yaml'`. Com zero grafos, esse passo **não falha — fica vazio**. A sessão
degrada para ler prosa, e o conhecimento do projeto continua morando no contexto de uma conversa em
vez de no repo. É literalmente o que prende o dono a uma sessão.

Verifiquei que é do procedimento e não da minha execução: **nenhuma fase** do `/meta:adopt` semeia
`.kg.yaml` ou `docs/onion/graph/`. O manifesto exclui `docs/onion/` de propósito (é a SSOT do core), e
os passos (8) e (8b) regeneram apenas `inventory.md` e `graph.md` no alvo.

**⚠️ E a causa tem a forma de um achado anterior desta casa.** A medição de 2026-08-16 viu grafo
autoral em 3 de 7 adotantes e ia atribuir a **não-uso** — exatamente como ia culpar o adotante pelo
zero de resíduos R56, até se medir que `review-artifact-check.sh` **nunca foi vendorizado**. Parte do
"não usam KG" é **capacidade que nunca enviamos**. Culpar o hábito antes de conferir o envio erra o
alvo, e é a segunda vez que essa inversão aparece em duas semanas.

**Cura — `seed-adoption-graph.sh`, e o que ele NÃO faz é metade do desenho:**

- **não inventa o domínio do adotante.** Semeia só o que a adoção *verifica de si* (pin, modo, papel,
  branch de integração, prova do gate) mais **uma `question` aberta** pedindo o primeiro nó de
  domínio — que o radar afunda na seção ESTADO a cada leitura. Semente com fato verificado + uma
  pergunta viva é hábito começando; template cheio de TODO é ruído que se aprende a ignorar.
- **o nó do gate nasce `confirmed` OU `open`** conforme o instalador tenha *provado* ou *adiado*. O
  instalador tem **três** resultados (vivo / inerte / prova adiada) e `exit 0` não distingue o
  terceiro — então o passo (6) passou a **capturar** a saída. Grafo que nasce afirmando prova que
  ninguém fez é o defeito que a medição do gate inerte em 4 de 6 já cobrou.
- **never-clobber pela pergunta certa:** *"o alvo TEM grafo?"*, não *"este arquivo existe?"*. Semear
  um 2º grafo em repo que já mapeia o próprio domínio é empurrar ruído a quem já pegou o hábito.
- **emite `meta.schema_version`** (59 dos 64 grafos do core declaram). Sem ele o radar avisaria na
  **primeira** leitura de todo adotante — e aviso na primeira leitura ensina que a saída tem ruído
  tolerável.

## Achado 2 — eu ia grepar uma string que não existe

O passo (6) derivaria o flag procurando `'bloqueio provado'` na saída do instalador. Essa string é do
`ops/verify-adopter-gate.sh`, **não** do instalador: `grep -n 'bloqueio provado'` nele devolve **zero**.
O flag daria **sempre** `--gate-unproven`. Errou para o lado seguro (subdeclarar), mas errou. O
marcador correto é a linha de sucesso do próprio verificador (`GATE VIVO`), que chega ao stderr
capturado — e a polaridade ficou escrita: **só afirma prova quem vê a prova**; ausência de marcador é
"não sei", nunca "sim".

## Achado 3 — flag vazia matava o helper

O chamador usa `"${GATE_FLAG:-}"`, que pode vir vazio. O argumento vazio caía no ramo de alvo e o
helper morria com *"alvo já informado"*. Agora flag vazia é **ausência**, não erro.

## Achado 4 — o `provenance.json` do plugin churna a cada commit

Um hook regenera `plugins/onion-work-tools/.claude-plugin/provenance.json` com o `ref` do HEAD —
logo ele **nunca** pode estar em sincronia com o próprio commit (o sha só existe depois de commitar).
Consequência prática medida hoje: ele bloqueou o `checkout` que o `gh pr merge --delete-branch` faz, e
o `ops/pr-merge-verified.sh` **recusou declarar merge** (comportamento correto dele). Fica descartado
aqui, sem commit. **Não curei a raiz** — o churn continua e volta no próximo PR; registro para não
descobrir de novo como surpresa.

## Prova

- Adoção **ponta a ponta em alvo virgem**: gate provado vivo, flag derivada da saída **real**, grafo
  semeado, e `git ls-files '*.kg.yaml'` (o caminho que o warm-up usa) devolve o arquivo.
- Bancada: **824 passaram · 0 falharam · 0 pularam** (`BENCH_RC=0`), com o kind novo de 5 casos — o
  primeiro **auto-referente**: o que o semeador *gera* tem de passar no **radar** desta casa, porque
  gerador cujo artefato a própria validação reprova entrega dívida, não valor.
- Kind rodado isolado sob `set -euo pipefail` **antes** dos 15 min da suíte, espelhando o runner.
- Lint do core: **0 HARD / 4 SOFT** (rc=0).
- No adotante real: grafo próprio com **19 nós / 21 arestas**, radar **rc=0** com integridade,
  camada domain completa e proveniência ancorada.

## Ressalva declarada (não é achado, é limite)

`.claude/sessions/` é **gitignored** por desenho do framework: o `STATE.md` que o `/catch-up` lê é
**local da máquina**, não viaja no clone. O que viaja é o **grafo**. Se o ponteiro de sessão precisar
ser versionado em adotante, é decisão do maestro — não mudei por conta própria.
