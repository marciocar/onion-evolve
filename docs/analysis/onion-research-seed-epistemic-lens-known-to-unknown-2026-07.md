# Semente de pesquisa — uma lente do sabido ao a-saber, dogfoodando o caminho × o papel do SDAAL

> **Status: SEMENTE (2026-07-06)** — plantada pelo maestro numa rodada de sementes especulativas
> ("de forma independente, sem julgamento"). Território **novo** — não existe, hoje, um framework
> nomeado de "gap epistêmico" no Onion, embora existam dois vizinhos próximos que resolvem
> problemas parecidos por ângulos diferentes.

## Por que esta pesquisa

O maestro propõe: uma lente que parte do que já se sabe para o que se quer saber, e dogfooda o
caminho entre os dois — e pergunta explicitamente qual o papel do SDAAL nisso.

**Os dois vizinhos mais próximos resolvem uma fatia diferente do problema, nenhum resolve tudo:**

1. **`/meta:graph`** (a "lente sócio-técnica" já nomeada assim) — *"o Transformer lê o grafo para
   achar caminho/solução e orquestrar"*, com um modo `--path <de> <até>` explicitamente descrito
   como *"como chego de uma necessidade à capacidade que a entrega?"*. Isso é muito próximo da
   forma da pergunta do maestro — **mas o caminho é entre nós que JÁ EXISTEM no grafo**. Não é um
   caminho entre "o que sei" e "o que não sei ainda" — é um caminho entre coisas já mapeadas.

2. **O veredito de frescor** (`CURRENT/STALE/HISTORICAL`, via `/meta:context-freshness`,
   fundamentado em `domain-context-lifecycle.md`) — trata de **fidelidade** (o que está
   documentado ainda corresponde à realidade?), não de **cobertura** (o que falta documentar que
   eu nem sei que falta?). Achado central desse documento, citação exata: *"contexto stale engana
   ativamente [...] Remover é frescor"* — é sobre limpar o que envelheceu, não sobre navegar do
   sabido ao desconhecido.

Nenhum dos dois é "gap analysis epistêmico" no sentido que o maestro descreve. O `onion-working-
method.md` tem a estrutura mais próxima em espírito (Seleção → Execução → Validação, com dogfood
como motor de Validação) mas também não nomeia uma "trajetória sabido→a-saber" como conceito — ele
descreve como *escolher e rodar* um fluxo já catalogado, não como *descobrir o que ainda não está
catalogado*.

**Onde o SDAAL entra, hoje**: como fonte da SSOT que a lente consultaria (o contrato/spec é o que
está "sabido" formalmente) e como o padrão que já resolveu um problema estruturalmente parecido em
outro domínio — abstrair providers de negócio por trás de uma interface estável. Se essa semente
propõe algo como "SDAAL para o gap epistêmico", precisa dizer que providers seriam esses (fontes de
conhecimento? métodos de descoberta?) — hoje isso não está desenhado em nenhum lugar.

## Questões de pesquisa

**Q1 — "O que se sabe" está onde, hoje?** Antes de desenhar uma lente, mapear: o "sabido" do
Onion vive espalhado (KB, ADRs, `graph.md` gerado, memória de sessão, `members.yaml`) sem um
inventário único de "isto é o que sabemos, formalmente". `/meta:graph --orphans` já acha
artefatos sem referência — é o inverso parcial do que a semente pede (acha o que está isolado
dentro do sabido, não o que está fora dele).

**Q2 — "O que se quer saber" é decidido por quem?** No `onion-working-method.md`, toda decisão de
gate de uso é "humana por design" — a lente proposta precisaria manter isso, ou o objetivo é uma
IA que **descobre sozinha** o que falta saber (o que colidiria com o mesmo anti-padrão que a
doutrina já rejeitou — "comando que mecaniza julgamento")?

**Q3 — Dogfoodar o caminho significa o quê aqui?** A doutrina de dogfooding já exige "rodar de
verdade, não só planejar" — aplicado a uma lente epistêmica, isso sugeriria: não basta desenhar o
esquema do gap, é preciso *tentar preencher* um gap real e ver onde o desenho quebra (mesma lógica
do `onion-dogfooding-doctrine.md`: "só executar revela o que falta"). Qual seria o primeiro gap
real (não hipotético) para testar essa lente?

**Q4 — Isso é ferramenta nova, ou composição do que já existe?** `/meta:graph --path` +
`/meta:context-freshness` + a doutrina de Seleção do `onion-working-method.md`, combinados, talvez
já cheguem a 80% do que a semente pede — a pesquisa deveria testar essa composição antes de
propor infraestrutura nova.

## Método previsto

Não é pesquisa externa — é primeiro uma tentativa real de composição (Q4): pegar um gap de
conhecimento genuíno e real (algo que o maestro já sabe que não sabe sobre o próprio Onion) e
tentar navegá-lo usando só as ferramentas que já existem (`/meta:graph --path`, freshness,
catálogo do working-method). Se a composição falhar de um jeito específico, esse ponto de falha
*é* a spec do que falta construir — dogfood aplicado à própria pergunta.

## Gatilho

O maestro pede ("vamos tentar a lente sabido→a-saber num caso real") → executar a partir DESTA
semente, começando pela tentativa de composição (Q4), não por design abstrato. Registro na
memória da sessão: `sementes-modelo-federacao-lente-radar-2026-07` (ponteiro consolidado).
