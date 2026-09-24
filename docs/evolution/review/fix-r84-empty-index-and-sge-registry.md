---
branch: fix/r84-empty-index-and-sge-registry
pr: 871
date: '2026-09-24'
reviewed_diff_sha256: f6e8bb9a37879fef5ea80886ddfb4c262f6b28d7e7a4c63daf828d6af4507cac
findings_total: 8
findings_real: 8
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Sem refutador independente em worktree, e o limite está declarado. O que substitui em parte: TRÊS
  dos seis achados vieram de DOGFOOD que reprovou a leva (adotar um repo real barrou o primeiro
  commit dele), e um veio do MAESTRO reprovando a minha leitura da pesquisa — que é refutação
  externa, só não automatizada. Campos de custo em ZERO porque não houve run de modelo a medir.
---

# Resíduo — a REGRA 84, o registro do SGE e a spec do deck

## Como os achados apareceram, que é o que dá peso a eles

Nenhum veio de leitura de diff. **Três vieram de rodar o artefato num repo novo** e **um veio do
maestro apontando** que eu tinha ignorado a decisão da pesquisa.

| # | achado | como apareceu | destino |
|---|---|---|---|
| 1 | **A REGRA 84 (Índice de leitura do KG em sincronia com os traces) barrava o primeiro commit de TODO adotante** — `2>/dev/null \|\| true` descartava o rc e o stderr, colapsando "corpus sem trace de arquivo" (estado normal do dia 1) com "gerador quebrado" | dogfood: o gate do SGE barrou o commit e o SGE não tinha defeito | CURADO + 3 casos de bancada, incluindo o (c) que impede a cura de virar porta de saída |
| 2 | Meu **primeiro diagnóstico estava errado**: acusei a semente de escrever `trace:` em prosa, quando o cabeçalho do resolvedor (l.33-34) declara prosa como **legítima** | li o contrato do resolvedor depois de afirmar | corrigido antes de tocar código; a cura foi para a guarda, não para a semente |
| 3 | O **SGE estava fora do registro** da federação — e sem entrada a REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) não enxerga o repo | `check-member-registered.sh` no fim da adoção | REGISTRADO |
| 4 | **Divergência entre dois SSOTs**: o stamp carimba `adopted`, o registro exigia `consumer` | o validador reprovou o valor que o `write-stamp.sh` escreve | UNIFICADO em `adopted` (22 sítios lêem essa palavra contra 1 que lia a outra); `consumer` fica como sinônimo legado |
| 5 | O **nome do membro violava a REGRA 30** (Segurança de PROJEÇÃO: nome comercial de membro privado não sai): o que vai ao console publicado é o slug, não o nome humano | lint | corrigido para o formato da convenção |
| 6 | **Eu implementei a opção (E) da pesquisa**, graduada REPROVADA com confiança 0,1, por agir pelo RESUMO em vez de abrir o nó de decisão — a recomendação era (G), confiança 0,75 | **o maestro apontou** | refeito: 9 atos, Orient/Activate/Reinforce, escada memória→skills→hooks→agentes; a spec REGISTRA o erro em vez de apagá-lo |

## O achado 6 merece nome de classe

Agir pelo **resumo** de uma pesquisa em vez do que ela **decidiu** é a mesma família de
`declarado ≠ verificado`, aplicada ao meu próprio insumo: o grafo tinha **sete opções nomeadas** com
recomendação do Elenxo, e eu li o `summary` do retorno. A cura estrutural não é disciplina — é o
hábito de abrir o nó `D_` **antes** de executar, que é literalmente o que a tabela de selagem do
`/meta:drive` manda fazer com KIND `decision`.

## Verificado

- `lint-artifacts.sh` → **0 HARD**, 13 SOFT
- `kg_read_index_empty` → 3/3, com os dois mutantes provados (vazio legítimo vira SOFT; gerador quebrado segue HARD)
- `members-validate.sh` → válido, 20 membros
- `kg-radar.sh` no grafo da pesquisa → exit 0 (21 nós, 49 arestas)
- **dogfood no adotante**: lint do SGE 1 HARD → **0**, e o commit dele passou pelo gate sem `--no-verify`

## Fora do escopo, declarado

- O `door-staleness-baseline.txt` do SGE **veio do core** (o emissor precisa de `members.yaml`, que
  adotante não tem). Inerte lá — a REGRA 85 (Porta pública espelha o core, com catraca) é
  `SEM-OBJETO` sem registro —, mas é passivo alheio. Agora que o SGE está registrado, vale re-rodar
  o `regen-baselines.sh` no próximo `--update`.
- A perna **(C)** da ordem do deck entra como **hipótese**, com o gatilho de re-verificação nomeado
  na spec (leitura integral da doc da plataforma, ou rodada `primaries` com os 6 comparadores).

## Os `confirmed` do grafo que este PR traz (REGRA 87)

O PR adiciona `deck-patterns-2026-09.kg.yaml`. Os `confirmed` de maior impacto (todos impact 5) são
as **objeções do Elenxo**, e eu as li antes de refazer a ordem — três delas são exatamente o que
reprovou a minha primeira tentativa:

- **`E_OBJECAO_1_DIATAXIS_NAO_PRESCREVE_ORDEM`** — Diátaxis é mapa de 4 tipos **independentes** cuja
  regra é SEPARAÇÃO; ele não prescreve ordem, e a pergunta era sobre ordem. Foi o que derrubou a
  opção (B) e metade da (E).
- **`E_OBJECAO_3_QUATRO_ACHADOS_SAO_DUAS_FONTES`** — os "4 achados" são **2 fontes contadas duas
  vezes** (Divio/Diátaxis e NN/g). Eu havia apresentado quatro como se fossem quatro lastros
  independentes; não são.
- **`E_OBJECAO_6_DECK_DE_65_SLIDES_NAO_EXISTE`** — o objeto declarado não existia no repo, e a
  objeção está **certa**: o deck existe como Artifact, que é o que o pesquisador não podia ver. Por
  isso a spec entra no repo — para o alvo passar a existir onde as guardas alcançam.
- **`E_OBJECAO_5_CORPUS_VAZIO_E_FALSO_NEGATIVO`** — o corpus vazio da rodada não provava ausência de
  conhecimento da casa: a autoridade sobre ordem existia em `onion-guided-lifecycle.md` e no
  `onion-onboarding/SKILL.md`, e o grep de termos não a alcançou. É a razão de a opção (D) ter a
  confiança mais alta entre as pernas da fusão.

## Achados 7 e 8 — apareceram ao commitar o grafo

| # | achado | destino |
|---|---|---|
| 7 | **4 traces pendurados** no grafo da pesquisa (REGRA 55 — O `trace:` de um nó APONTA para alvo que EXISTE): todos apontavam para o deck de campo, que vive **só em duas branches de `docs/`**, nunca em main. A própria rodada mediu isso e o agente escreveu o caminho como se resolvesse | CURADO: viraram **prosa** nomeando as branches — forma que o resolvedor declara legítima — em vez de caminho que não resolve. O fio "onde o deck de campo passa a viver" fica aberto na spec |
| 8 | Índice de leitura e `docs/backlog.md` **defasados** pela entrada do grafo novo (REGRAS 84 e 62) | regenerados: índice 1.894 linhas · backlog 215 abertos em 47 grafos |
