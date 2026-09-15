---
title: 'Resíduo — o corte estava invertido, e a SSOT que eu disse não existir já existia'
date: 2026-09-15
branch: fix/adopt-role-cut-transport
reviewed_diff_sha256: 21f1f0f2f36ce98f01ab1433474f84d6af50dec89beee3b07721cc4c7f37b736
findings_total: 13
findings_real: 13
findings_fixed: 13
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Os três refutadores REPROVARAM, de três lentes independentes, e convergiram no mesmo lugar: a cura
  repetiu o pecado do nó uma camada acima. O corte não disparava para adotante NENHUM que exista
  (papel incarimbável + env var que ninguém atribuía), e quando disparava cortava o lado ERRADO —
  o precedente manteve os 14 comandos que eu apagava. Duas implementações inteiras foram ao lixo, e
  a segunda porque eu afirmei, em comentário de código, que a fronteira só vivia em prosa. Vivia num
  resolvedor que eu não procurei.
---

# O corte estava invertido — e a SSOT que eu disse não existir já existia

## O que o nó pedia

> `--role adopted|hub|standalone` devolve listas IDÊNTICAS — ROLE é inicializado, parseado, validado
> e nunca mais lido. **Gap aberto virou gap INVISÍVEL.**

## O que os três refutadores acharam

Nove achados HARD, todos curados aqui. Os quatro que mudam o desenho:

### 1. O corte estava INVERTIDO em relação ao precedente que ele dizia mecanizar

O `onion-standalone` — repo **público**, cortado à mão em 2026-07-19 — **manteve 14 dos 43** comandos
de `meta/` e removeu a meta-fábrica **arquivo a arquivo** (−274). A minha primeira versão fazia o
oposto: apagava `commands/meta/` inteiro (−107) e mantinha `skills/onion-publish` e
`agents/meta/*-creator-*`, que o manual removera.

Entre os apagados estavam **`/meta:kg`** (o norte NS1, citado por 31 arquivos sobreviventes) e
**`/meta:setup-integration`** — o fallback que o próprio CLAUDE.md manda sugerir. O adotante perderia
comandos que o orquestrador continua mandando invocar.

**E isso reescreveu o meu diagnóstico do resíduo.** Eu havia declarado em stderr, como medição, que
as 27 ocorrências de REGRA 22 (Links relativos quebrados em docs/evolution/ e docs/knowledge-base/)
eram "doutrina citando caminho do core". Eram o corte levando comandos que deviam ficar. Com o corte
certo caem para 13.

### 2. A SSOT do escopo por papel já existia — e eu escrevi que não

`bash .claude/utils/marketplace/resolve-role-bundle.sh standalone --tools` devolve **exatamente os
14**. `roles.yaml` declara os verticais e `downstream: false`.

Cheguei a implementar **duas** alternativas — lista de prefixos, depois um campo `travels:` no
frontmatter de cada comando — e as duas eram **segundas SSOTs do mesmo fato**, repetindo a duplicação
que o PR #826 curou (*"a mesma lista vivia TRÊS vezes, e uma já tinha driftado"*). Pior: o comentário
que eu mesmo escrevi no manifesto **racionalizava ignorá-la** (*"os dois são SSOTs de coisas
diferentes"*).

> Antes de declarar que algo só existe em prosa, **procure o resolvedor.**

O custo de não procurar foram duas implementações descartadas e uma decisão do maestro tomada sobre
premissa falsa.

### 3. O corte não disparava para adotante nenhum que exista

Duas causas somadas, e cada uma sozinha bastava:

- `write-stamp.sh` **recusava** `standalone` (só `adopted|hub`). O papel que o transporte aprendeu a
  cortar não podia entrar no stamp que o transporte aprendeu a ler.
- `ONION_ROLE` era lido por dois arquivos e **atribuído por nenhum**. O `--update` copia pelo merge do
  `vendor-branch.sh`, que roda `adopted`; meu `TARGET_ROLE` alimentava só o `diff --stat`.

O único standalone do mundo carrega `role: adopted` até hoje. **Gap invisível trocado por gap
invisível** — a tese exata do nó que este PR fecha.

### 4. O manifesto que falha copiava o repositório inteiro

`mapfile -t manifest < <(script)` **engole o rc**. Com o manifesto saindo ≠0, o array fica vazio — e
para o git **pathspec ausente significa TODOS**: 2222 arquivos, 353 de biografia, o diário inteiro,
`rc=0`.

É **pré-existente**, e as guardas `exit 2/3` que eu acrescentei ao manifesto **aumentaram as portas**
para esse estado sem que ninguém do outro lado as lesse. Guarda que o consumidor não lê é decoração —
a mesma classe do `--role`, uma camada adiante.

## E a bancada que eu escrevi aprovava tudo isso

- **(b2)** era tautológico: fazia `grep` dos **mesmos 7 prefixos** do `_role_cut`. Perguntava ao
  código o que o código respondera. Agora o oráculo é o `roles.yaml` — fonte que o corte **consome**
  mas não define.
- **(g)** eram três `grep` de string literal dando `record_pass "o corte sobrevive à atualização"`.
  Uma guarda `behavior-over-declaration` testando a declaração — e aprovando um caminho quebrado.
  Agora executa: `ONION_ROLE=standalone` produz **93 excludes** contra **0** sem papel.

### 5. A SSOT do escopo estava DEFASADA, e o corte a tornou consequente

O maestro apontou: *"mesmo o kg e metas tem que ir com standalone core geral"* — e `hub` recebe tudo.
Medido, ele estava certo e o problema era `work_tool_sets.full`, escrito quando `inventory`,
`kg-freshness`, `backlog`, `drive`, `radar`, `realign`, `graph`, `census` e `kg-inbox` **não
existiam**. Enquanto o transporte ignorava o papel, a defasagem não tinha consequência; quando o
corte passou a CONSUMIR o arquivo, virou entrega errada.

O critério que fecha isso é medido, não opinado:

> **Comando que as mensagens das guardas mandam o ALVO rodar tem de viajar para o alvo.**

Contado nas mensagens de `.claude/validation/*.sh`: `/meta:inventory` aparece **32×** ("rode
/meta:inventory"), `/meta:kg-freshness` 27×, `/meta:drive` 5×, `/meta:radar` 4×. Entregar a guarda
sem o comando da cura é dar ao adotante uma instrução impossível de cumprir. O standalone passou de
14 para **23** comandos, e o caso `(k)` da bancada impede a lista de defasar de novo.

### 6. O papel de fidelidade TOTAL existe, e agora é medido

Ordem do maestro: *"vamos mandar tudo incluindo meta fábrica, temos que ter um que tenha tudo do core
para trabalhar como o core"*. Esse papel é o **`hub`** — e a medição confirma: **685 arquivos, zero
excludes, byte a byte a superfície do core**, com a meta-fábrica inteira (os 43 comandos de `meta/`,
`utils/{adopt,marketplace,wizard,vertical,federation-transport}`, `validation/federation-*`).

Isso já era verdade, mas **por default, não por invariante** — nada reprovaria o dia em que alguém
acrescentasse um corte para `hub` por simetria ou engano, e o papel que deveria trabalhar como o core
viraria um core mutilado em silêncio. É a classe deste PR inteiro. O caso `(b3)` trava.

### 7. `standalone` passou a significar duas coisas — e eu caí na armadilha primeiro

Vi `members.yaml` dizer `standalone` para o jogo-da-vida e o stamp dizer `adopted`, li como
divergência e "corrigi" o registro. **Estava errado, e a REGRA 66 (Registro da federação validado no
gate (members.yaml)) me reprovou na hora:** `adopted` não pertence ao vocabulário daquele arquivo.

São **duas escalas**, não um conflito:

| arquivo | o que `role:` significa | vocabulário |
|---|---|---|
| `members.yaml` | **tier topológico** — quem adota quem | `source \| hub \| standalone` |
| `.claude/.onion-version` | **papel de transporte** — o que o alvo RECEBE | `adopted \| hub \| standalone` |

**13 dos 15 membros** são `standalone` no registro e `adopted` no stamp. Não é divergência — é a
normalidade, e o registro nunca mentiu.

**Mas o achado é real, e é desta família:** até hoje a colisão era inerte. Depois deste PR, um
`standalone` no **stamp** corta a meta-fábrica; um `standalone` no **registro** descreve treze repos
que recebem tudo. Copiar o valor de um arquivo para o outro — o gesto que eu acabei de fazer — tira
capacidade de um adotante **em silêncio**. A colisão está agora nomeada em comentário no próprio
`members.yaml`, onde o próximo leitor a encontra antes de "corrigir" alguma coisa.

Quem me pegou foi uma guarda que já existia. É o contraponto honesto do resto deste resíduo: nem
toda cura aqui veio de refutador — esta veio do gate, fazendo o que promete.

### 8. O empacotador copiava lixo do ambiente — e o local se auto-isentava

O `assemble-plugin.sh` montava `UTILS` com `cp -R` do **diretório inteiro**. Ao empacotar
`.claude/utils/census` (que eu acrescentei nesta rodada), o `__pycache__/*.pyc` — que existe no disco
de quem roda python e **não** no commit — foi junto.

O resultado é o pior formato de defeito: o bundle montado **localmente** tinha o `.pyc`, o montado no
**CI** (checkout limpo) não, e a REGRA 19 (Plugins de vertical (plugins/*) sincronizados com as
fontes) acusava "fora de sincronia" **só no CI**. Verde na máquina, vermelho no servidor, e nada no
diff que explicasse — a máquina do operador se isentando pelo próprio lixo.

**A cura tem DUAS metades, e a primeira sozinha não bastou** — o CI reprovou de novo e me obrigou a
achar a segunda:

1. **a cópia**: `UTILS` era `cp -R` do diretório; passa a copiar só o que `git ls-files` lista;
2. **o cálculo do `tree_sha`**: era `find <dir> -type f`, que varre o **disco**. O `.pyc` entrava no
   hash, então o `tree_sha` calculado localmente **nunca** ia bater com o de um checkout limpo.

A segunda é a que importa mais, porque `tree_sha` é o sinal de drift do plugin: *content-addressed só
vale se o conteúdo endereçado for o mesmo para todo mundo* — e o que é igual para todo mundo é o que
está **rastreado**. Provado por execução: com e sem o `__pycache__` no disco, o hash agora é o mesmo.

É a mesma doutrina que o transporte de adoção já aplica com `git archive HEAD`. Ela valia num canal e
não no outro.

Pré-existente, e só ficou alcançável porque este PR foi o primeiro a pôr em `UTILS` um diretório com
artefato gerado dentro.

## Curado junto

- **C-quoting**: `git ls-tree --name-only` escapa acento/espaço, o `case` por prefixo deixa de casar e
  o arquivo **vaza em silêncio** — numa porta pública, num repo pt-BR. E o resultado dependia de
  `core.quotePath`, config **pessoal** do operador. Agora `-z` + `read -r -d ''`.
- **`.claude/commands/` inteiro cortado**: a primeira tentativa do fail-closed varreu todas as
  categorias e zerou os 146 comandos do bundle. Fail-closed onde ninguém é obrigado a declarar não é
  rigor, é apagamento.
- **REGRA 5 (Limites de linhas (por TIPO de artefato — tamanho saudável ≠ número universal))**: a
  resolução do manifesto virou `resolve-manifest.sh` — 804 → 800 linhas.

## O resíduo que FICA, medido

| bundle (pós-configuração) | arquivos | HARD |
|---|---|---|
| `adopted` | 685 | 32 |
| `standalone` | **601** | **47** |

REGRA 22 ×9 e REGRA 16 (Contagem de inventário-TOTAL divergente da SSOT) ×11 — agora genuinamente
doutrina citando a meta-fábrica cortada. Nó `A_DOUTRINA_VENDORIZADA_LINKA_CAMINHO_DO_CORE`, aberto
com gatilho.

A progressão conta a história: **69 → 50 → 47 HARD** conforme o corte foi ficando certo. Número que
cai sozinho quando o desenho melhora é sinal de que ele media o desenho, não o ruído.

## Bancada

Família `role_cut`, **17 casos**, dos quais 8 nasceram desta passada: `(b2)` com oráculo independente,
`(g)` por execução, `(g2)` export do papel, `(h)` stamp carimbável, `(i)` rc lido pelo consumidor,
`(j)` enumeração NUL-separada, `(k)` a SSOT do escopo não defasa em silêncio, `(b3)` o hub é fidelidade TOTAL.

## Gate

```
bancada completa : 1260 pass · 0 fail · 0 skip
lint (LC_ALL=C)  : 0 HARD
radar / integrity: exit 0 (33 nós)
família role_cut : 17/17
commit           : SEM --no-verify
```
