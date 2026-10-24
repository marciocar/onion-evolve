---
description: Disseca um objeto (ferramenta, pratica, ator, app, categoria ou ideia) em niveis selecionaveis, com Etapa 0 pre-registrada e veredito da familia (absorver, costurar, perseguir, parquear ou rejeitar).
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, WebSearch, WebFetch, TodoWrite
---

# 🦑 /meta:dissect — dissecar um objeto em níveis selecionáveis

Mapeia um objeto — ferramenta de terceiro, prática, ator, app, categoria de produto ou ideia (as
**famílias** do registro) —, entende **o que ele faz** e decide o que o Onion **absorve**,
**costura**, **persegue**, **parqueia como técnica a investigar** ou **rejeita com razão escrita**,
no vocabulário da família. O nome de
casa é cunhagem do maestro: **chupa-cabra de ferramentas** (2026-10-01).

A doutrina inteira — a escada de 5 níveis, os vereditos, a regra de evidência, as famílias com a
Etapa 0 (§6) e o que ela NÃO promete — vive em [`common:prompts:dissect-doctrine`](../common/prompts/dissect-doctrine.md).
**Referencie, não copie.**

## Degrau e limites

- **Viaja para todo papel menos o onion-mini** (decisão do maestro, 2026-10-14): o time de um hub disseca
  as ferramentas de terceiro que pensa adotar, com o mesmo método do core.
- **Maestro-invocado.** Não auto-inicia, sem cron, sem `/loop` sobre si (MOAT W7).
- **Não sela.** Produz o plano e **1 nó `decision` OPEN** por ferramenta (no modo estudo, **1 nó
  `question` OPEN** "adotar?" no lugar dele); quem sela é o maestro.
- **Executar é ato isolado.** Ferramenta de terceiro roda em worktree/container — nunca na árvore
  de trabalho. Fronteira é mecanismo; instrução em prosa não segura escritor (medido 2026-09-20).
- **MOAT (PARA sempre):** instalar dependência global, deploy, escrever em repo alheio.

## Contexto medido injetado (peça 3 — o medidor roda ANTES de você pensar)

**Hoje:** !`date +%F`
**Dissecações que o corpus já pagou:**
!`bash .claude/validation/dissect-census.sh . --markdown`

**Famílias registradas e estudos por família** (o checador de forma, peça 3 da §6 da doutrina):
!`bash .claude/validation/dissect-object-check.sh --context 2>&1 || echo "(checador de forma ausente ou sem medir nesta instalação: rc acima; sem ele, a família e a Etapa 0 não se conferem aqui)"`

Leia o censo como ele se declara: ele mede o que o corpus **DECLARA**, não sabe de ferramenta que
ninguém anotou, e **não confere se a medição do nível de fato ocorreu** — o marcador é
auto-atestado. Se ele sair `3`, está declarando que **não pôde medir** (sem índice git, ou corpus
vazio): conserte o ambiente, nunca siga com censo vazio.

## A escada (resumo operacional — a autoridade é a doutrina)

| Nível | O que se produz | Custo |
|---|---|---|
| **N0** identidade | quem mantém, licença, trajetória **datada** | barato |
| **N1** capacidade | os **verbos** que ela faz e o Onion não — da superfície executável, não do marketing | barato |
| **N2** mecanismo | COMO faz: substrato, estrutura de dados, onde mora o determinismo | **caro — exige comportamento** |
| **N3** transferibilidade | `igual → transfere` / `diferente → desenha`, com evidência e refutador | médio |
| **N4** absorção | o plano: artefato · costura SDAAL · **guarda** que cobra · **caso de bancada** que reprova sem a mudança | caro |

**Nível reprovado não sobe.** É o corte de custo: varrer 30 ferramentas no N0 é barato; levar 30
ao N4 é insano.

## Uso

```
/meta:dissect <ferramenta|lista> [--level N=3] [--budget <tokens>] [--against <repo>] [--scope <pathspec[,pathspec]>] [--study]
```

`--level` **para** no nível pedido. Sem argumento, o default é **N3** (julga transferibilidade e
não gasta o plano de absorção em algo que ainda vai ser rejeitado).

## A régua e o modo estudo (decisões do maestro de 2026-10-14)

- **A régua padrão é o PRÓPRIO repo** (decisão do maestro de 2026-10-15, SAC-147). Sem
  `--against`, a régua é o repo onde o dissect roda, e ela é **derivada pelo censo, não digitada**:
  a linha "régua padrão deste repo" do censo injetado acima. No core (sem carimbo, `role: source`)
  e nas portas ela é o **Onion**, como sempre; num adotado ou hub é o **id do repo** (o nome do
  remote `origin`). Grave **sempre** `meta.x_dissect_against:` com ela, mesmo quando é o padrão.
- **`--against <repo>` — outra régua.** Com ele (num hub, medindo para outro repo), o **N1** pergunta "o que ela faz que o **alvo** não faz", o **N3** julga
  transferir **para o alvo**, e o **N4** escreve os nós `x_absorb_*` para o **repo do alvo**, não
  para o framework. N0 e N2 descrevem a ferramenta e não mudam com a régua; N1, N3 e N4 mudam, e
  por isso nível pago só se reusa **na mesma régua** (o censo mostra a coluna). Grave
  `meta.x_dissect_against: <repo>`. A costura com o forge segue: o `/meta:forge` roda no hub e lê
  os planos, medindo as peças no repo do alvo pela raiz que você passa ao leitor (passo 4b).
- **`--scope <pathspec[,pathspec]>` — um componente do repo.** A régua pode ser só uma ferramenta,
  funcionalidade ou biblioteca do repo, não ele inteiro (ex.: **trocar o provedor de identidade de
  um produto**). O escopo é **pathspec do git** relativo à raiz do repo da régua (`services/auth/**`,
  vários separados por vírgula), não um nome: caminho é o que o N1 lê, o N3 compara e o leitor de
  planos confere (arquivo rastreado que casa), e um nome solto ninguém mede. Com ele, o **N1**
  pergunta "o que ela faz que **este componente** não faz", o **N3** julga substituir ou transferir
  **para o componente**, e o **N4** escreve o plano para ele. Grave `meta.x_dissect_scope:`. Nível
  pago só se reusa na **mesma régua E no mesmo escopo** (o censo mostra as duas colunas; `-` = o
  repo inteiro).
- **`--study` — estudo.** Para no **N2** (identidade, capacidade, mecanismo) e o N2 é medido
  **rodando a ferramenta isolada**, sem veredito de absorção. No lugar do nó `decision` fica um nó
  `question` **aberto** "adotar?". Grave `meta.x_dissect_mode: study`. O censo o mostra como
  **estudo**, separado da dissecação **interrompida**: parar no N2 **sem** o marcador continua
  sendo interrompida. `--study` com `--level` diferente de 2 é recusa.
- **O que o estudo NÃO promete:** não decide, não recomenda e não escreve plano. O leitor de
  planos recusa nó `x_absorb_*` em grafo de estudo. Para decidir, disseque de novo **sem**
  `--study`: o N2 fresco entra pago e a escada segue no N3.

## Procedimento

0. **ETAPA 0 (pré-registro, antes de qualquer dado do objeto)** — escolha a **família** pela ordem de
   predicados da §6 da doutrina (a 1ª que responder "sim") e escreva o plano em
   `docs/evolution/dissect/<objeto>-<AAAA-MM>/STAGE0.md` com os 8 elementos (`## 1.` a `## 8.`); o grafo
   nasce com o nó `S_STAGE0` (`x_criterion` com o sha256 do plano) e os marcadores da família
   (`meta.x_dissect_family`, a `external_edges` `TRACES_TO` para o nó da família no registro,
   `meta.x_study_destination`). **Commite o plano antes do primeiro nó `x_dissect_level: 0`** — ancestral
   estrito, e a ordem é conferida no git:
   `bash .claude/validation/dissect-object-check.sh <grafo> --stage plan` (rc 0). Família que não está no
   registro **não se inventa no meio**: entra por PR no core antes do N0. Objeto que é ferramenta de
   terceiro é a família `ferramenta`, e a escada é a de sempre.
1. **MEDIR** — o censo acima. Ferramenta com nível **fresco** entra no nível **seguinte**; não
   repague nível. Dissecação **VENCIDA** é re-medida, nunca citada como de hoje.
2. **ENQUADRAR** — para cada ferramenta, o nível de entrada (do censo) e o nível-alvo (`--level`).
3. **DISSECAR** — orquestra via skill `onion-orchestration` reusando o motor já provado da
   pesquisa: `.claude/workflows/onion-research.js` com `mode: 'decision'` (Elenxo + nó `D_` open),
   **tier por complexidade** (N0/N1 `haiku/low` · N2 `sonnet/high` · N3/N4 `opus/high`).
   ⚠️ **Medido em 2026-10-11 (dogfood do SAC-77):** o motor **não conhece níveis** —
   `grep -ci dissect` nele dá **0**. O "um worker por nível com gate em JS" é **desenho, não
   implementação**. Até existir, a escada é conduzida pela sessão (direto, nível a nível, sem
   subir o reprovado), e o grafo **declara** que foi assim. Sessão que já é subagente não
   orquestra: disseca direto.
4. **VEREDITO** — um dos **vereditos da família** (o registro os lista; `ator` não absorve, `categoria` e
   `ideia` perseguem com `x_dissect_pursue: estudo | projeto-novo`), com razão escrita. Declare
   `meta.x_who_pays` e `meta.x_unverified`. A superação de um negativo é buscada **também na web**
   (`x_dissect_overcoming_search` com ao menos uma `where: web` quando ela é `nenhuma`), e o parque leva
   `x_dissect_trigger` (consulta `kg_query` em lista branca que lê o que persiste, abaixo de `min_count`). `parquear` **exige gatilho nomeado**.
   `rejeitar` e `parquear` são **negativos** e exigem, no nó do veredito, `x_dissect_criterion:` (o
   comando que checa a reprovação) e `x_dissect_overcoming:` (o id do nó deste grafo com o que SUPERA,
   com aresta para a decisão, ou `nenhuma` + `x_dissect_overcoming_measure:` com o que se procurou e
   onde). Confira com `bash .claude/validation/dissect-census.sh . --check-verdict <ferramenta>` e só
   siga com rc 0 (rc 1 = veredito negativo RECUSADO; SAC-151).
4b. **PLANO DE ABSORÇÃO (só `absorver`/`costurar`, N4)** — a passagem para o
   [`/meta:forge`](forge.md). Um nó por peça a absorver, no MESMO grafo, com:
   `x_absorb_target:` (candidato como o `forge-census.sh` o nomeia, ou `novo:<nome>`) ·
   `x_absorb_pieces:` (quais das 7, ex. `"4,7"`) · `x_absorb_origin:` (URL **com pin** — sha ou
   tag) · `x_absorb_license:` (SPDX ou `proprietary`) · `x_absorb_form:` (`reescrita` ·
   `adapter-sdaal` · `vendor-pin`; proprietário **nunca** `vendor-pin`) · `x_absorb_parity:` (o
   caso que prova que a peça faz o que a original fazia, **nomeando** a família
   `run_<n>_selftests`). **Não escreva quais peças já existem** — o leitor as mede ao vivo:
   `bash .claude/validation/dissect-plans.sh . <ferramenta>` (rc 1 = plano INCOMPLETO,
   com o motivo). Com `--against`, passe a raiz do alvo, que o leitor **nunca adivinha**:
   `... dissect-plans.sh . <ferramenta> --against-root <repo>=<caminho>` (sem ela, rc 3 =
   NAO-MEDIDO, porque medir no repo errado é medir outra régua). Para a régua = o **próprio
   repo** (o padrão, num adotado), a raiz é `.` **implícita**: não passe nada. Grafo com
   `x_dissect_scope` cujo escopo não casa arquivo rastreado no repo da régua sai
   INCOMPLETO(escopo-sem-arquivo). Rode-o antes do passo 5 e só
   siga com rc 0. O leitor mora do lado do forge
   (core e standalone): no plugin `onion-meta` o forge não viaja, o leitor também não, e o plano
   fica no grafo esperando quem o forje.
5. **DESTINO (peça 5)** — `write(KG)` em
   `docs/evolution/dissect/<ferramenta>-<AAAA-MM>/<ferramenta>-<AAAA-MM>.kg.yaml` com os
   marcadores que o censo lê (`meta.x_dissect_tool:`, `x_dissect_level:` por nó, `x_dissect_verdict:` no
   nó de decisão; `meta.x_dissect_against:` sempre; e, quando houver, `meta.x_dissect_scope:` e
   `meta.x_dissect_mode: study`; e os da família, §6 da doutrina: `meta.x_dissect_family` com a aresta ao
   registro, `meta.x_study_destination`, `meta.x_who_pays`, `meta.x_unverified` e o `S_STAGE0` apontando o
   `STAGE0.md` da mesma pasta), `meta.review_after` pela cadência (ferramenta/preço 30d), `# kg-backlog-guard:
   on` e `# ═══ TETO: N NÓS ═══`. **`kg-radar` exit 0 é obrigatório** antes de qualquer prosa.
   O `SYNTHESIS.md` é **projeção**, com o **contrato de custo** no frontmatter: `kg:` · `run_id` ·
   `tokens` · `agents` · `duration_min`.
6. **GATE** — `bash .claude/validation/dissect-object-check.sh <grafo>` rc 0 (estudo por família;
   rc 3 é "não mediu", nunca aprovação) · `lint-artifacts.sh` 0 HARD · famílias `run_dissect_selftests` e
   `run_dissect_object_selftests` verdes · resíduo da
   REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) no PR.

## O que este comando NÃO faz

- **Não roda o motor do protótipo de dissecação de qualquer objeto** (o workflow de 3 agentes de um
  adotante de curadoria). Ele ficou **parqueado** por decisão do maestro de 2026-10-24; o gatilho é 1
  objeto decisório a mais com o protocolo corrigido (§6 da doutrina). A escada segue conduzida pela
  sessão, como no passo 3.
- **Não julga qualidade de software** — decide **encaixe no Onion**. Ferramenta excelente sem
  consumidor aqui reprova no N1, e isso não é demérito dela.
- **Não absorve.** Produz o plano e o nó `decision` **open**; a implementação é o fluxo normal.
- **Não substitui a pesquisa de mercado** — o eixo capital/M&A segue invariante da
  [doutrina de pesquisa](../common/prompts/research-doctrine.md).
- **Não sabe o que ninguém escreveu.** O censo só vê dissecação declarada.

## 🔗 Referências

- Doutrina (peça 2): [`common:prompts:dissect-doctrine`](../common/prompts/dissect-doctrine.md)
- Medidor (peça 3): `.claude/validation/dissect-census.sh` · checador de forma por família:
  `.claude/validation/dissect-object-check.sh`, com o registro `.claude/validation/dissect-families.kg.yaml`
- Motor reusado (peça 4): `.claude/workflows/onion-research.js` (`mode: 'decision'`)
- Lente (peça 6): `.claude/rules/dissect-lens.md` · Bancada (peça 7): `run_dissect_selftests` e
  `run_dissect_object_selftests`
- Forja que o emitiu: [`/meta:forge`](forge.md) · régua de transferência:
  [`transfer-heuristic-aristotle`](../../../docs/knowledge-base/concepts/transfer-heuristic-aristotle.md)
