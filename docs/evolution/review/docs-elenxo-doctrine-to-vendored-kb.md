---
branch: docs/elenxo-doctrine-to-vendored-kb
pr: 630
date: 2026-08-17
reviewed_diff_sha256: ddc44ba6aa2c8d163ca2dc991df5666de851cee3f66adfcff26a70f69345dc89
findings_total: 7
findings_real: 5
findings_fixed: 4
tokens: 0
duration_min: 65
verdict: CONFORME-DEPOIS-QUE-O-REVISOR-DO-CI-CORRIGIU-A-MINHA-PROPRIA-AUDITORIA
reviewer: passada adversarial manual (3 ataques dirigidos) + revisor do CI (2 achados que a manual perdeu, ambos confirmados por medição) + medição no vivo; sem subagentes por restrição da sessão
REVISOU: true
---

# Resíduo — `docs/elenxo-doctrine-to-vendored-kb`

**Origem: um sinal de campo do maestro**, não uma inspeção — *"o ADOTANTE NÃO SABIA O QUE É O
ELENXO"*, colhido de uma sessão da PoC que teve de grepar o repo antes de responder à pergunta dele.

## Limite do método, declarado antes dos achados

A passada adversarial foi **manual**, não orquestrada: esta sessão está sob restrição de não usar
subagentes sem pedido explícito. Rodei **3 ataques dirigidos** ao meu próprio diff em vez de N lentes
independentes. Isso é **menos** que uma refutação adversarial de verdade — e por isso **este PR não é
um Elenxo**, é uma revisão. Usar o nome certo é a primeira exigência da doutrina que o PR entrega.

> **E o limite não ficou teórico — ele cobrou.** O revisor do CI achou **2 defeitos reais que a minha
> passada perdeu** (Achados 2-corrigido e 4), ambos confirmados por medição minha depois. Os dois são
> da **mesma família do que eu estava curando**: link que não resolve, e contagem que não foi varrida
> inteira. Uma lente sozinha — ainda que a minha, ainda que atenta — **não é fan-out de lentes
> independentes**; e a etapa 1 do Elenxo existe exatamente porque *lente única não vê o próprio ponto
> cego*. Este resíduo é a evidência empírica disso, colhida contra o autor.

## Achado 1 — o grafo não sabia que a doutrina graduou (REAL, curado)

O ataque que mais rendeu foi *"algo linkava o rascunho que eu acabei de marcar como graduado?"*.
Rendeu: `docs/onion/graph/onion-doctrine-elenxo-bulbo-2026-07.kg.yaml` tinha **8 nós** com `trace:`
apontando para o rascunho, o **cabeçalho declarava** *"GATED — a pagina nao esta publicada nem
vendorizada"* (agora falso), e `D_PAGE_GATED` seguia **`open`** afirmando *"nao publicar nem
vendorizar ainda"*.

O que torna este achado grave não é o tamanho — é **de quem** é o defeito. Ele viola:

- o **invariante 6 da KB que eu mesmo acabei de escrever** (*"a fonte viva são os grafos; divergiu, o
  grafo ganha"*);
- a **etapa 5 do Elenxo**, que a própria doutrina nomeia como **a que mais falha**: *refutação narrada
  em prosa e grafo em 0/0/0/0*.

Escrever a doutrina da superação-que-vira-aresta e não virar aresta seria a página se refutando na
prática enquanto prega o método.

**Curado:** `E_ADOPTER_DID_NOT_KNOW_ELENXO` e `E_PATH_SCOPED_SKILL_INVISIBLE` (evidências `PROD`, com
`verified_at` e o que foi medido) sustentando `D_GRADUATED_TO_VENDORED_KB`, que `SUPERSEDES`
`D_PAGE_GATED` — com o **status do alvo reconciliado** para `superseded`, porque nó que recebe
`SUPERSEDES` e continua `open` é contradição estrutural que o radar reprova.

**A superação é declaradamente PARCIAL**, e isso está no rótulo: supera a metade **VENDORIZAR**; a
metade **PUBLICAR** segue `open` em `Q_PUBLICATION_AREA`. Fechar as duas seria cerimônia — o maestro
autorizou vendorizar, não publicar.

Radar depois: **exit 0**, 21 nós / 16 arestas, sem contradição estrutural.

## Achado 2 — link morto que EU introduzi no plugin (REAL — e a MINHA CONTAGEM ESTAVA ERRADA)

> ### ⚠️ Correção deste achado, feita depois que o revisor do CI me pegou
>
> A versão original desta seção dizia **"o meu é o 5º de uma classe pré-existente"** — contando **1
> link novo**. **Errado, e medido:** eram **3**. O revisor do CI achou os outros dois — as skills
> `onion-onboarding` e `onion-wizard` **também** são embarcadas no plugin, e o link que eu pus nelas
> foi copiado sem a profundidade extra de `plugins/onion-work-tools/`, resolvendo para
> `plugins/docs/knowledge-base/…` (confirmado inexistente por `realpath` + `ls`).
>
> Meu erro de método foi específico: verifiquei o link **na KB** e supus que as **skills** herdavam a
> mesma resolução. Não herdam — vivem em profundidade diferente dentro do plugin. **Um resíduo que
> conta errado sobre si mesmo é pior que um resíduo ausente**, porque dá impressão de auditoria.
>
> **Curado, pelo mecanismo que o assembler já oferecia** (não por máquina nova): a doutrina entrou em
> `DOCS=()` do manifesto, então ela **embarca** em `kb/` e o rewrite converte as referências para
> `${CLAUDE_PLUGIN_ROOT}/kb/onion-elenxo-doctrine.md`. Os **3** links novos resolvem.
>
> ### E o preço da cura, que eu também não tinha medido
>
> Embarcar a doutrina trouxe junto a seção **"🔗 Relacionados"** dela — **7 irmãs que não estão no
> plugin**. Placar medido, sem arredondar:
>
> | Momento | Links mortos em `plugins/onion-work-tools/kb/` |
> |---|---|
> | Antes deste PR | **4** (`inference-mitigation`, `onion-dogfooding-doctrine`, `onion-guardrails`, `specification-driven-ai-abstraction-layer`) |
> | Depois da cura | **11** (as 4 acima + as 7 "Relacionados" da doutrina) |
>
> **Mantive assim, e a razão é declarada:** o que se ganha é a **definição presente e legível** dentro
> do plugin — que é o propósito inteiro deste PR — e o que se perde são links de **rodapé**. Conteúdo
> degradado, não conteúdo quebrado. Mas **o número piorou**, e enterrar isso seria exatamente a
> propaganda que a doutrina proíbe. **Decisão do maestro** se o plugin deve embarcar as 7 irmãs,
> deixar assim, ou o assembler passar a converter link-de-irmã-não-embarcada em plain-text.

**O que aconteceu.** Ao ligar as 4 KBs e as 2 skills à definição, esses links viajaram para dentro do
plugin (`plugins/onion-work-tools/`), onde o alvo **não estava embarcado**.

**A lacuna estrutural, que a cura NÃO fecha:** `kb-vendored-link-check.sh` varre
`docs/knowledge-base/**` e **não** varre `plugins/**/kb/`. Por isso o lint passou verde nas duas
vezes em que eu estava errado — nem no meu primeiro erro (3 links), nem no segundo (11 links). Foi
**revisor humano-equivalente**, não guarda, que pegou; e o gate seguiu verde o tempo todo.

É a mesma família dos três pontos cegos de filtro de path desta casa (`plugins/` #241, `docs/` #254,
`ops/` #509) — e repare qual foi o **primeiro** deles: `plugins/`. **Quarta ocorrência da classe.**

Estender a guarda a `plugins/**/kb/` é mecanismo novo que o maestro não pediu; fica **registrado sem
cura**, com o número honesto na tabela acima.

## Achado 3 — `8 skills` onde são 11 (REAL, curado de passagem)

`docs/onion/agents-reference.md:9` declarava **8 skills**. São **11** no disco e no inventário. O lint
de deriva de contagem **não pega** essa forma composta — pegou os `90 → 91` de KBs na mesma linha e
passou reto pelo número de skills ao lado.

Curado. Fica o registro de que a regra de contagem tem cobertura desigual por recurso.

## Achado 4 — varri os TOTAIS e esqueci o SUB-TOTAL (REAL, curado)

Também do revisor do CI: `docs/INDEX.md:29` dizia **"49 em `concepts/`"**. São **50** (`find`), porque
este PR acrescenta um arquivo a esse diretório. Eu tinha atualizado as **duas contagens-total** da
mesma hunk (`90→91` KBs, `91→92` arquivos) e passado reto pelo **sub-total logo abaixo**.

E o revisor pegou **um** dos dois sítios: a **linha 104** (a árvore ASCII) dizia 49 também. Curei os
dois.

**Terceira vez, no mesmo PR, com o mesmo eixo.** O `INDEX.md` avisa de si mesmo na linha 598 que a
cura anterior desta classe *"parou em 1/4"* — eu li esse aviso, citei-o no PR body como se fosse
lição aprendida, e **reincidi na linha seguinte do mesmo arquivo**. Ler o aviso não é o mecanismo;
enquanto não houver feeder de lint para sub-totais de `docs/<seção>`, a única cura é **conferir a
soma**, não confiar na varredura.

## Os dois ataques que não acharam nada (e por isso valem)

- **O SOFT lexical de frescor doutrinário é meu?** Não. É `vps-tool-repo-skeleton.md` (`latest` sem
  `verified_at`), pré-existente. A KB nova não acrescenta SOFT algum.
- **Algo consumia o texto que removi de `onion-patterns`?** Não. `fan-out-and-synthesize` continua
  definido em `onion-orchestration/SKILL.md` — o conceito que a KB cita está vivo e é de outro dono.

## Prova

- Lint: **0 HARD / 4 SOFT** — idênticos à linha de base de antes do trabalho; as 4 são por desenho
  (2 passivos com catraca, 1 isenção declarada, 1 lexical alheio).
- **Passivo de link vendorizado intacto em 43**, `HARD=0` — a KB nova introduz **zero** link
  core-privado (medido com `--format tsv | grep onion-elenxo-doctrine` → vazio).
- Radar do grafo: **exit 0** (medido isolado, não por `$?` depois de pipe — a guarda de shell me pegou
  fazendo isso e estava certa).
- Contagem `90 → 91` varrida em **7 sítios independentes**, incluindo as 4 formas distintas do
  `INDEX.md` — cujo próprio rodapé (linha 598) avisa que a cura anterior desta classe parou em 1/4.

## Ressalva declarada — e a minha própria ressalva ficou FALSA no meio do PR

A versão original desta seção afirmava: *"este PR **não dispara a bancada** — não toquei maquinaria
nenhuma, só doutrina, docs e skills"*. Era verdade quando escrevi, e **deixou de ser** quando a cura
do Achado 2 me levou a editar `.claude/utils/marketplace/verticals/onion-work-tools.manifest.sh` —
que casa `.claude/utils/**`. **A bancada rodou.** O filtro de path se comportou exatamente como
desenhado: mudou maquinaria, o teste de regressão veio junto.

Corrijo em vez de reescrever em silêncio, porque a afirmação falsa é do mesmo gênero do que este
resíduo já teve de corrigir uma vez (a contagem de links).

**O limite que permanece:** a rede que justifica o filtro — o `schedule` de 04:17 UTC em
`onion-selftest.yml` — **ainda não disparou uma única vez** (nasceu hoje, 12:54 UTC; primeira janela
2026-08-18 04:17 UTC). Todos os runs até agora são `pull_request`. Enquanto não disparar, o filtro
segue **nu**: um path fora da lista não tem ninguém por baixo, que é o defeito comum dos três pontos
cegos anteriores (#241, #254, #509).
