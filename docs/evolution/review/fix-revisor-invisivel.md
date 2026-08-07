---
branch: fix/revisor-invisivel
date: 2026-08-07
reviewed_diff_sha256: b88e0570dc98044550ef4dffe17cde686646dbc92881bf9fe1e1f839ca4bc374
findings_total: 52
findings_real: 52
findings_fixed: 12
tokens: 1182479
duration_min: 49
verdict: DUAS-PASSADAS-A-PRIMEIRA-DERRUBOU-A-PREMISSA-A-SEGUNDA-A-IMPLEMENTACAO
reviewer: Elenxo × 2 — 4 refutadores por lente + juiz (opus/high), wf_463c7110-df2 e wf_7669b5a4-150
---

# Passada adversarial — duas rodadas, e cada uma derrubou uma camada

Este PR levou **dois Elenxos** porque o primeiro não deixou o desenho de pé. Registro os dois,
porque a sequência é o achado: **a 1ª rodada derrubou a PREMISSA; a 2ª derrubou a IMPLEMENTAÇÃO da
correção.**

## Rodada 1 — a causa estava errada

**Diagnóstico original:** *"o revisor não posta porque falta `github_token`"*. **Falso.**

Verificado por mim no log da run 31200047905:

```
Requesting OIDC token... / App token successfully obtained   ← já havia credencial de escrita
permission_denials_count: 14                                  ← o revisor TENTOU e foi negado
No buffered inline comments                                   ← o servidor MCP nunca foi instalado
```

A action faz OIDC→App token com `contents/pull_requests/issues: write` por default. A causa real é
**falta de ferramenta**: `claude_args` não declarava `--allowedTools`, então o servidor MCP de
comentário nunca era instalado — e o buffer que o step final drena tem um único produtor.

E a "correção" seria **regressão**: passar `github_token` troca o App token por
`secrets.GITHUB_TOKEN`, que é limitado pelo bloco `permissions:`.

Além disso, o comentário que eu havia escrito no YAML — *"SEM ISTO A ACTION NÃO TEM COMO POSTAR
NADA"* — era **declaração não-verificada**, no commit cujo assunto é declaração não-verificada.

**O maestro então recusou o caminho MCP e perguntou se dava para usar SDAAL.** Daí a reconstrução.

## Rodada 2 — a implementação da correção era regressão estrita

**T1 CAIU, e é o achado que salvou o PR.** O `--json-schema` que eu havia adotado **não passa**.
Verifiquei rodando o parser real da action sobre o `claude_args` verbatim desta branch:

```
371 bytes entram (claude_args) → 253 saem (valor do --json-schema) → JSON.parse: FAIL
CLI real: "Error: --json-schema is not valid JSON", exit 1
SDK: 0 mensagens antes do throw · execution_file seria []
⇒ review-verdict: revisou=false / json-ilegivel, nas DUAS tentativas
```

O `shell-quote` do parser come as aspas do JSON. Hoje o revisor roda **41 turnos com sucesso**; com
a minha mudança, produziria **nada**. **Revertido**, com a medição escrita no lugar para ninguém
tentar de novo sem passar o schema por arquivo.

**T3 CAIU — o rótulo do transporte estava trocado**, medido por comportamento e não por leitura:
com stub de `gh` no PATH, o helper faz **duas chamadas, ambas `gh api`**, zero `gh pr comment`.
A spec reserva `gh pr comment` para o ramo `cli`; `issues/{n}/comments` é o ramo `api`. Corrigido.

**T5 CAIU — a cobertura provava pouco.** Os 6 casos do helper saem no `--dry-run` **antes** de
qualquer `gh`; sabotar a busca sticky deixava `pass=6 fail=0`. E **duas das três guardas-da-guarda
eram vácuas**: o padrão procurado pelo `grep` aparecia no arquivo **intacto** (na própria linha do
`sed`), então um `sed` no-op "passava".

**T4 restringido:** o `>/dev/null 2>&1` das escritas engolia a causa — um 403 ou 404 virava
*"falhei ao postar"* sem dizer o quê. Mesma classe de silêncio que o PR existe para curar.

## A correção de método que veio do maestro, não do juiz

O juiz deu **CAI** em T3 também porque o helper *"nasceu órfão"* e *"a lacuna está sub-declarada"*.
O maestro leu isso e perguntou: **"a ideia do SDAAL não é justamente criar as partes que faltam?"**

Ele está certo, e isso muda o que o CAI significa. Criar a peça que falta **é** o padrão — o que eu
errei foi **onde**: implementei o modo sticky e o edit-por-id **dentro do script**, chamei de
*"extensão declarada"*, e a interface não sabia que existiam. Isso não é SDAAL; é `gh api` com
cabeçalho bonito.

**Corrigido na spec, que é onde a peça nasce:**

| operação | antes | agora |
|---|---|---|
| `addReviewComment` | existia | ganhou `upsertBy` (modo sticky) |
| `getReviewComments` | existia | — |
| **editar comentário por id** | **não existia sob nome nenhum** | `updateReviewComment` |

E a regra que fica escrita: **quando um consumidor CONTORNA a abstração, o defeito é da abstração
até prova em contrário.** O `gh api` cru do `onion-review.yml` existia porque a operação de editar
comentário não existia — não porque alguém foi desleixado.

O helper agora **cita** a spec, e entrou no inventário do `README.md` do forge, que listava 7 `.md`
e ficou exatamente um arquivo defasado.

## Os dois pontos cegos que eu mesmo criei ao corrigir

**O escape de célula.** O `--corpo` interpolava a evidência crua: um `|` produzia 5 células contra
cabeçalho de 3; um `\n` **terminava a tabela no meio**. `rc=0` e sem aviso nos dois casos — num
repo cujos diffs são cheios de pipe. E na primeira correção **sobre-escapei** (`\\|` em vez de
`\|`); peguei olhando os bytes com `cat -A`, não o render.

**O teste do teste.** Ao provar que o `cmp` cura as guardas vácuas, usei o sentinela
`PADRAO-QUE-NAO-CASA-NADA` — que existia **na própria linha do `sed`** dentro da cópia, então
casava a si mesmo e o arquivo mudava. Só descobri porque o `cmp` isolado dizia "idênticos" e o
selftest dizia "diferem", e dois números não podiam ser ambos verdadeiros. Refeito com o `sed`
removido de vez: aí sim a guarda acusa *"mutação NÃO aplicada"*.

## O que embarca, e o que NÃO embarca

**Embarca:** o revisor devolve o parecer em **prosa formatada** (`VEREDITO:` + lista) e o Onion
posta um **comentário pegajoso** pelo transporte `api` do adapter; a spec do forge ganha as duas
operações que faltavam; o `--texto` degrada em três degraus (`.result` → `errors[]` → texto parcial
de `assistant`); as declarações falsas saíram do YAML e do `contributing.md`; o `gh api` cru saiu
do workflow (zero invocações vivas).

**NÃO embarca:** o `--json-schema`. O ramo estruturado do `--corpo` fica no código porque é o
estado-alvo e tem 5 selftests, mas está **inalcançável hoje** — e isso está declarado no arquivo,
não escondido.

## Verificação

- `review-verdict --selftest` **21/21** · `lint-selftest` **702** passam / 0 falham (env de CI, solo)
- as 3 guardas-da-guarda passaram de `grep`-de-padrão para **`cmp`-de-arquivo** — não tem como ser
  vácuo: ou o arquivo mudou, ou não mudou. Provado com o `sed` removido: acusa
- o step real **extraído do YAML** e simulado ponta a ponta sob `bash --noprofile --norc -eo pipefail`
- 7 blocos `run:` com `bash -n` limpo — o `yaml.safe_load` **não vê** erro de shell dentro de bloco
  escalar, e eu já tinha metido uma linha de env dentro do `run:` por causa disso
- `elenxos-2026-08-07.kg.yaml`: **18 nós, 18 arestas**, radar exit 0
- lint **0 HARD** — e a REGRA 55 pegou este artefato faltando quando o nó do KG já o citava

## NÃO-VERIFICADO, declarado

**Um PR que edita o workflow não mede o revisor** — a action se auto-pula quando o arquivo difere
da branch default. A prova real é o **PR seguinte ao merge**: tem de aparecer um comentário
pegajoso com o parecer. Até lá, *"o revisor comenta"* é **não-verificado**, e está escrito assim no
`contributing.md`.

## Fios declarados

- **o `--json-schema` por arquivo** — reabilitaria o ramo estruturado; o input da action não aceita
  neste pin
- **`Q_SDAAL_EXECUTAVEL_ONDE_PARA`** — esta é a 1ª peça executável em `.claude/utils/forge/`. A
  regra declarada é *"materializar só o que tem consumidor não-LLM medido"*. Qual é o gatilho para
  a 2ª? Se forem 5, o SDAAL virou código com documentação ao lado
- **o linter não enxerga `.github/`** — as REGRAS 10/11 varrem só `commands` e `agents`, e foi por
  isso que o `gh api` cru viveu sem ninguém ver
- **`review-artifact-check.sh:87`** escreve *"pergunta-se ao forge"* e chama `gh pr view` direto
