---
branch: worktree-docs+typesafe-ai-desmembramento
date: 2026-09-21
reviewed_diff_sha256: 648278c6d723656bd8572eaa80741edab4300c23f513b1a1b69d9ca9aaaa2a52
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 956102
duration_min: 25
verdict: REPROVADO_E_CURADO
reviewer: passada própria sobre o próprio artefato (sem subagente) — gate mecânico: kg-radar + lint-artifacts
---

# Documentei um vendor de "decisão calibrada" e errei um número por não calibrar a minha

> **Nota de vocabulário:** a primeira redação deste resíduo escreveu `verdict:` como uma frase narrativa
> — exatamente o texto livre que o selo de 2026-09-08 fechou. O `testing-state.sh` mostrou o custo na
> hora: o legado subiu de 90 para 91, e a catraca existe para esse número **descer**. Corrigido para
> `REPROVADO_E_CURADO`; a narrativa mora no corpo, que é onde ela sempre coube.

Esta rodada produziu documentação sobre a **TypeSafe AI** — um lab cujo produto inteiro se vende como
*decisão com incerteza honesta*. A passada adversarial sobre o meu próprio artefato achou três coisas,
e a primeira é constrangedora na medida certa.

## Achado 1 — número de manchete invertido, propagado de um resumo (REAL, curado)

Escrevi no SYNTHESIS e no `.kg.yaml`: *"193,6x mais barato, 444,6x mais rápido"*.

O correto, no HTML cru da home: **`193.6x Faster,<br>444.6x Cheaper.`** — invertido.

**A causa não foi desatenção de leitura, foi confiança na camada errada.** Eu tinha **duas** leituras da
mesma página: a transcrição da home trazia o par certo, e a análise do blog trazia o par trocado. Eu
peguei o segundo e não notei que ele contradizia o primeiro. Um resumo automático trocou dois rótulos e
eu repassei a troca.

A cura aplicada foi medir na fonte crua (`curl` + `grep` no HTML) e, na mesma passada, conferir os
outros números da vitrine pelo mesmo caminho — `238x`, `Per Billion input tokens` e `Fable 5.1`
bateram. A lição ficou **escrita dentro do próprio documento**, não só aqui, porque é lá que quem lê o
número vai estar:

> **Número de manchete se confere na fonte crua, não num resumo dela** — e duas leituras discordantes
> da mesma página são um sinal a perseguir, não ruído a mediar.

É a classe `relay-machine-signals-with-source-label` aplicada a um caso novo: a saída de uma ferramenta
é **declaração**, inclusive quando a ferramenta é um resumidor e o assunto é um número.

## Achado 2 — teto do `meta:` declarado antes de contar os nós (REAL, curado)

Declarei `TETO: 24 NÓS` no `meta:` e escrevi 25. O lint pegou como **HARD** — REGRA 58 (O backlog
cumpre as promessas do próprio `meta:`). Curado para 25.

Vale registrar *por que* isso passou: escrevi o cabeçalho do grafo **antes** de terminar os nós, com o
número que eu *planejava* ter. É a mesma família do `exit-code-nao-e-a-verificacao` — declarei sobre
mim mesmo em vez de contar o que produzi. A guarda mecânica funcionou sem ninguém pedir.

## Achado 3 — arestas em flow style que o radar não lê (REAL, curado)

Escrevi as 28 arestas como `- { from: X, to: Y, edge_type: Z }`. O radar é `awk`, não parser YAML: o
resultado foi **25 nós órfãos de grau 0** e exit 1 — um grafo que *parecia* escrito e estava, para o
leitor que importa, vazio.

Curado convertendo para o bloco canônico (uma chave por linha). A regra `kg-grammar` diz isso
explicitamente — *"Formato estrito: o radar é awk, não parser YAML"* — e ela carrega por path
justamente quando se toca um `.kg.yaml`. Eu a li **depois** de escrever. Inverter essa ordem é a cura,
e ela não precisa de mecanismo novo: o mecanismo existe e disparou.

## O que NÃO foi revisado, e fica dito

Nenhuma afirmação **sobre o produto** foi verificada por execução — não houve chamada à API. A passada
cobriu **fidelidade à fonte** (o documento diz o que a fonte diz?) e **conformidade de artefato** (o
grafo é legível? o lint passa?). Não cobriu, porque não podia, **se o produto faz o que declara**. O
`§9 NÃO-VERIFICADOS` do SYNTHESIS carrega essa lista como item de primeira classe.

## Adendo (2º commit) — o dogfood refutou uma recomendação minha, e ela foi rebaixada

Depois de selar a versão acima, rodei o experimento que eu mesmo havia proposto: **25 julgamentos
reais** (5 nós do corpus × 5 repetições, um subagente read-only cada, sem ver o `status:` selado) para
medir *self-consistency* como proxy da distribuição do Jev — **sem vendor, sem chave de API**.

O resultado **refutou parcialmente o §7.4 do próprio SYNTHESIS**, que eu havia escrito como leitura:

- **A moda acertou 5/5.** A distribuição não corrigiu veredito nenhum. A versão ingênua da tese
  ("preciso de distribuição para não errar") não se sustenta nesse recorte.
- **O custo mora na MEDIÇÃO, não no julgamento.** 956.102 tokens, ~38.244/julgamento, gastos rodando
  `git branch -a`, `grep` no `members.yaml`, `ls` no registry, abrindo o repo de um adotante. Escolher o
  enum depois disso é a fração barata — e **Jev não mede**, ele avalia um `state` que você já montou.
  Logo ele substituiria só o passo que já é de graça.
- O candidato #1 foi **rebaixado** e o **gatilho do nó de decisão foi reescrito**: deixa de ser o
  `kg-freshness` e passa a ser uma superfície onde *uma* medição alimente *N* perguntas (o
  *speculative fan-out*).

Dois achados colaterais que só a repetição expôs, e que valem por si:

1. **N3 ("branch two-tier") empatou 3×2 porque o ENUNCIADO é ambíguo, não porque o modelo é fraco** —
   metade mediu o core (sem essas branches), metade mediu um adotante (com todas). Os dois lados
   mediram certo. `confidence` baixo virou um sinal útil de *"conserte o label"*, não de *"recarimbe"*.
2. **N2 teve veredito unânime e contagem divergente por baixo** — 3 workers contaram 14 adotantes, 2
   contaram 13, no mesmo arquivo, variando só o `grep`. Dispersão no **fato**, invisível no veredito.
   É a classe `guarda-por-lista-falha-pelo-vocabulário` aparecendo na aritmética.

Isto é a Doutrina de Dogfooding fazendo o que promete: **rodar o artefato refutou a recomendação que a
leitura tinha produzido**, no mesmo loop, antes de custar uma assinatura.

## Conferência da REGRA 87 — e ela pegou algo, não foi formalidade

O 2º commit edita `typesafe-ai-2026-09.kg.yaml`, então conferi os três `confirmed` de maior impacto
desse arquivo contra o que estou propondo:

- **`E_TRES_PRIMITIVAS_TIPADAS`** — compatível. O experimento usou exatamente a forma `Choice` de 4
  opções que esse nó descreve; nada aqui o contraria.
- **`E_SKILL_E_PLUGIN_NO_MARKETPLACE_CLAUDE_CODE`** — ortogonal ao achado. Nada a reconciliar.
- **`E_SYSTEM_ONE_CLASSE_DE_MODELO`** — ⚠️ **este já respondia, e eu não vi.** Ele diz, em texto que eu
  mesmo escrevi horas antes: *"avalia um `state` e devolve respostas TIPADAS"*. A palavra **avalia** já
  carregava a fronteira inteira — Jev recebe um `state` pronto, **não sai medindo**. A refutação do meu
  candidato #1 estava dentro do meu próprio grafo, num `confirmed`, e eu precisei de 25 subagentes e
  956k tokens para reencontrá-la.

Não mudo o achado — o dogfood continua valendo, e ele quantificou o que o nó só insinuava (que a
medição custa ~38k por julgamento e o julgamento custa quase nada). Mas a lição de processo é a que a
regra existe para cobrar: **o grafo já sabia, e eu li a fonte externa antes de reler o que eu tinha
acabado de carimbar.** É a mesma classe do hook de corpus que avisa "o corpus já fala deste arquivo" —
com a diferença de que aqui o arquivo era meu, e de hoje.

## Gate mecânico no SHA final

- `bash .claude/validation/kg-radar.sh docs/evolution/research/typesafe-ai-2026-09/typesafe-ai-2026-09.kg.yaml` → **exit 0** (27 nós, 33 arestas, sem contradição estrutural)
- `bash .claude/validation/lint-artifacts.sh` → **exit 0** (0 HARD; as 12 SOFT restantes são pré-existentes e alheias a este diff)

## Nota de rebase e de validação — 2026-09-26

Este PR ficou **5 dias aberto** e `main` andou **87 commits**. Rebaseado sobre `b7f24eb2`; os dois
conflitos foram em **projeções geradas** (`docs/backlog.md` e `docs/onion/testing-state.md`), resolvidos
**regenerando dos produtores** — aceitar um lado num arquivo derivado produz artefato que casa com o git
e mente sobre a fonte.

**E o achado que justifica esta nota existir:** o head deste PR **nunca tinha sido validado por nada**.
Medido no forge — os dois runs verdes (`Onion Artifact Linter`, `Onion Code Review`) são do SHA
`f6d734e54b7f`, de 21/09 às 21:17; o head era `adbbd1247d5b`, empurrado às **22:37 do mesmo dia**, e a
listagem de check-runs dele volta **vazia**. O commit não medido é justamente
*"rodei o experimento que eu propus, e ele refutou a minha própria recomendação"* — o trabalho mais
consequente do PR.

O `gh pr checks` diz *"no checks reported"*, que é honesto e **fácil de ler como "nada a ver aqui"** em
vez de "isto não foi medido". A primeira hipótese que levantei — ponto cego de filtro de path — foi
**refutada por medição**: `docs/**` está no filtro do `onion-validate`, e os runs existiram; o que não
existia era run **para o head**.

**Gate rodado agora, no conteúdo rebaseado:** `kg-radar --integrity --schema` **exit 0** ·
`lint-artifacts` **rc=0, 0 HARD**. As SOFT extras são as baselines das portas, que resolvem no merge da
leva vizinha. `meta.review_after` do grafo é **2026-10-21** — a pesquisa não venceu.
