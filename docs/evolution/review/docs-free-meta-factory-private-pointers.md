---
title: 'Resíduo — a guarda não olhava o transporte mais público que existe'
date: 2026-09-16
branch: docs/free-meta-factory-private-pointers
reviewed_diff_sha256: e2b75895cb3b0e64c27be3ebdb208387ca4cf786ccd427f4f07b2665944fabf8
findings_total: 12
findings_real: 11
findings_fixed: 11
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Dois refutadores com lentes distintas (prosa/vacuidade · transporte/artefatos gerados) REPROVARAM.
  Os dois achados que valem a rodada não são sobre o que eu escrevi: `plugins/` — o diretório que o
  marketplace publica para qualquer pessoa — não era raiz de varredura de nenhuma guarda, e o
  predicado de privacidade do `--check-bundle` fixava o nome completo de um repo quando a família
  tem vários. Em ambos o CONTEÚDO estava limpo e a COBERTURA não existia. Nenhum dos 11 veio de
  leitura minha; um dos meus próprios "achados" era falso e eu o devolvi ao refutador em vez de curar.
---

# A cura que quebrou uma tabela, e a varredura que não varria o que mais importa

## O que o maestro pediu

*"fecha a classe C e o A_DOUTRINA, avançar para liberar `Q_LIBERAR_A_META_FABRICA_PARA_O_PLUGIN`"* —
com o critério dele já fixado na rodada anterior: liberar a meta-fábrica ao plugin público **sem nada
pessoal, sem segredo, sem identificação de empresa**.

## A metade que faltava do A_DOUTRINA, e por que a cura não era o número

A REGRA 16 (Contagem de inventário-TOTAL divergente da SSOT) disparava 11 vezes no bundle
`standalone` porque a prosa que viaja fixava `109 comandos`. O bundle tem 90.

**A cura não é atualizar o número.** É parar de fixar em prosa que viaja uma contagem que depende do
PAPEL: nenhum literal pode estar certo nos dois. Os 15 sítios passaram a apontar `docs/onion/inventory.md`
— a SSOT que cada alvo regenera do próprio filesystem.

| | `main` | depois |
|---|---|---|
| REGRA 22 (Links relativos quebrados em docs/evolution/ e docs/knowledge-base/) · adopted / hub / standalone | 5 / 5 / 16 | **0 / 0 / 0** |
| REGRA 16 (Contagem de inventário-TOTAL divergente da SSOT) · standalone | 11 | **0** |
| REGRA 45 (Link vendorizado não aponta caminho core-privado, com catraca) · passivo | 23 | **15** |
| total do bundle `standalone` | 88 (55 HARD) | 58 (39 HARD) |

Regressão: **nenhuma, em nenhum papel** — `diff` do conjunto normalizado de violações `main` → árvore
devolve zero linhas novas nos três bundles.

## Os 11 achados, e os dois que mudam o mecanismo

### 1. `plugins/` não era raiz de varredura — o fail-open com cara de cobertura, um andar acima

`--emit-scrub-roots` é a SSOT que diz às REGRAS 36 e 45 **o que varrer**. Emitia 11 raízes sob
`.claude/` e `docs/`. `plugins/` não estava entre elas — e é o diretório que o marketplace publica
para qualquer pessoa.

O conteúdo estava limpo na medição. **É essa a frase perigosa:** limpo era o conteúdo, não a
cobertura. O cabeçalho do próprio `vendor-manifest.sh` já dizia *"guarda que varre menos do que o
transporte emite é fail-open com cara de cobertura"* — e ele não se aplicava a si mesmo, porque
`plugins/` não estava nem no transporte que a SSOT descreve.

Curado com uma lista **separada** (`_SCRUB_EXTRA`), emitida só no modo `scrub`. Pôr em `_base` faria
o plugin montado **viajar dentro do bundle** — outra coisa, e errada. A assimetria já era desenho
declarado: varrer mais do que viaja nunca é fail-open; varrer menos é.

A cobertura nova achou 6 candidatos na primeira execução. Medidos um a um: os seis são o espelho, em
`plugins/`, de uma entrada **já tolerada** na fonte (`Firebase`, `StartupXYZ`, `TechStartup` — nome de
produto e exemplos fictícios de uma KB de precificação). Baseline regenerado, e nada saiu dele.

### 2. O predicado de privacidade fixava um nome completo, e o irmão passava

O `_priv` do `--check-bundle` — a guarda que reprova biografia dentro de um bundle — casava o nome
completo de **um** repo do vertical pessoal. A família tem mais de um. Seis citações viajavam, e
**duas já estavam dentro do plugin público montado**.

Mesma classe do `guarda-por-lista-falha-pelo-vocabulário`, agora no predicado de privacidade: o
defeito é o vocabulário, não a lógica. Trocado por **prefixo** — que cobre inclusive o repo que
ninguém criou ainda — e as 6 citações passaram a creditar o sinal de campo sem nomear o repo.

### 3. A §10 da KB de identidade publicava a topologia de hospedagem do core

Ela descrevia backend, VPS com TLS e o **caminho do clone em disco**. Viaja em
`plugins/onion/kb/onion-framework-identity.md` — o artefato público. Mais três anedotas de campo com
o diretório home do maestro dentro de um hook, de um comando e de uma KB. Genericizadas mantendo a
lição; o site público continua nomeado, porque é público por decisão do maestro.

Verificado por ausência em `plugins/`: `/home/marcio/`, `/home/onion/`, o host do backend e o repo
privado da ponte dão **zero**.

### 4. Eu quebrei uma tabela ao curar a contagem

Troquei o header da tabela §6 para 2 colunas e deixei 12 linhas com 3 células. Pela regra do GFM as
células excedentes não renderizam: sumiria a coluna *Fonte* inteira — inclusive o marcador
`⚠️ não-verificável` da linha dos 22 PRs, que é doutrina desta casa. Restaurada com 3 colunas.

### 5. Eu afirmei mais do que tinha medido, no bloco que existe para combater isso

Escrevi *"as quatro métricas dependem do papel"*. Medido nos três bundles: **só a contagem de
comandos diverge**; agentes, skills e KBs coincidem. Reescrito com a medição — e com a razão de ainda
assim apontar a SSOT: o corte é por **prefixo de caminho**, então um recorte futuro sobre
`.claude/agents/` ou `docs/knowledge-base/` move esses números sem avisar ninguém.

### 6-11. O resto

Marcador `(core-only)` aplicado **duas vezes** na mesma citação (2 sítios, já regenerados no plugin) ·
meia-cura em que o nome do arquivo privado sobreviveu à esquerda da etiqueta (3 sítios) ·
`warm-up.md` citando documento privado e infraestrutura, e que só entrou no diff pela contagem — eu
não reli o resto do arquivo (2 sítios) · `rescue-prompt.md` dentro de uma string de `echo` ·
sobras de literal no mesmo arquivo que a cura tocou, inclusive um `12 programas de orquestração` que
já divergia da SSOT (13) e escapava da guarda por não dizer "skills".

## O achado que eu NÃO curei

`census.md:51` cita `docs/analysis/backlog-real-<data>.md`. O refutador marcou REPROVA por
inconsistência com a linha 65, que eu curei. Devolvi com o argumento em vez de curar: a 51 é caminho
de **escrita** com placeholder, para onde o *alvo* grava a projeção no repo dele; a 65 apontava um
documento **específico e existente do core**. São coisas diferentes. Se a distinção não se sustentar,
curo.

## O que fica aberto, medido e com gatilho

Caminho de máquina em **código funcional** — defaults de varredura de backup, endpoints, URL de pull:
**14 sítios**. Ali o caminho não é prosa a limpar, é **valor padrão a parametrizar**, e parametrizar
destino é desenho, não limpeza. É exatamente a peça (4) que o nó `Q_LIBERAR_A_META_FABRICA_PARA_O_PLUGIN`
já nomeia como a única que o critério "sem segredo" não resolve sozinho. Registrado no grafo como
`A_CAMINHO_DE_MAQUINA_EM_CODIGO_FUNCIONAL_E_PARAMETRIZACAO`, gatilho = a decisão do maestro sobre
parametrizar destino.

## Grafo

`docs/evolution/research/passada-adversarial-2026-09/passada-adversarial-2026-09.kg.yaml` — o nó
`A_DOUTRINA_VENDORIZADA_LINKA_CAMINHO_DO_CORE` passou a `done` **sem apagar** os números que ele
afirmava em 15/09 (são o que se media então); o desfecho foi apendado. Mais 3 nós, teto declarado
36 → 39. Radar `--integrity --schema`: exit 0, 39 nós / 39 arestas.
