---
name: extract-meeting
description: |
  Extração estruturada de conhecimento de transcrições de reuniões usando Framework EXTRACT.
  Use para transformar arquivos de contexto bruto em artefatos de alto valor para humanos, sistemas e IA.
  Grava o resumo (.md), o grafo da reunião (.kg.yaml, com trace ao trecho, o registro de aviso aos
  participantes e a área de cada ação e risco) e o backlog por área (projeção do grafo, com carry-over) em
  docs/meetings/; o gate meeting-graph-check.sh diz se o grafo vale e se o resumo bate com ele.
allowed-tools: Read Write Bash(find *) Bash(test -e *) Bash(mkdir -p *) Bash(basename *) Bash(wc -l *) Bash(bash .claude/validation/meeting-graph-check.sh *)

parameters:
  - name: source
    description: Caminho do arquivo ou pasta com transcrição(ões)
    required: true
  - name: level
    description: Nível de output (compact, executive, complete, graph)
    required: false
  - name: focus
    description: Foco específico (decisions, tasks, gaps, all)
    required: false
  - name: carry
    description: Grafos (.kg.yaml) das reuniões anteriores da mesma série, para o carry-over do backlog
    required: false

category: product
tags:
  - meeting
  - extraction
  - knowledge-base
  - documentation

version: "3.2.0"
updated: "2026-11-22"

related_commands:
  - /product/task
  - /docs/build-tech-docs
  - /meta/create-knowledge-base

related_agents:
  - extract-meeting-specialist
  - product-agent
  - task-specialist

knowledge_bases:
  - docs/knowledge-base/concepts/meeting-transcription-to-knowledge-base.md

outputs:
  - docs/meetings/<nome>-extract.md
  - docs/meetings/<nome>.kg.yaml
  - docs/meetings/<nome>-backlog.md
---

# 📋 Extrair Conhecimento de Reunião

Transformação de transcrições brutas em conhecimento estruturado usando o Framework EXTRACT.

## 🎯 Objetivo

Processar transcrições de reuniões e gerar outputs estruturados consumíveis por humanos, sistemas e IA, seguindo as 7 dimensões do Framework EXTRACT.

Toda extração gera **três artefatos** em `docs/meetings/`, o diretório único das reuniões (o
`/product:consolidate-meetings`, o `/product:whisper` e o `@whisper-specialist` leem e gravam no mesmo lugar):

- `<nome>.kg.yaml`: o **grafo da reunião** (pessoas, aviso, decisões, ações e riscos), cada nó com
  `trace` ao trecho da transcrição. É a **fonte da verdade** e a entrada da consolidação entre reuniões;
- `<nome>-extract.md`: o resumo EXTRACT no nível pedido, para gente ler. As decisões, ações e riscos dele
  **saem do grafo**, cada item com o id do nó, e o gate confere que os dois batem;
- `<nome>-backlog.md`: o **backlog por área**, projeção gerada do grafo (nunca escrita à mão), com o que
  ficou aberto nas reuniões anteriores da série (carry-over).

Duas vistas, um SSOT: a tabela do resumo agrupa por **responsável**, o backlog agrupa por **área** (a
swimlane dos trackers). Dono, prazo e área moram no mesmo nó, e nenhuma vista é a fonte.

A entrada aceita hoje é **transcrição em texto** (`.txt` ou `.md`, uma fala por linha). Áudio e vídeo passam
antes pelo `/product:whisper`, que gera o texto.

## ⚡ Fluxo de Execução

### Passo 1: Validar Input

```bash
# Verificar se source existe
test -e "{{source}}" || echo "❌ Arquivo/pasta não encontrado"

# Identificar tipo (arquivo ou pasta)
if [ -d "{{source}}" ]; then
  echo "📁 Processando pasta com múltiplos arquivos"
  FILES=$(find "{{source}}" -type f \( -name "*.txt" -o -name "*.md" \))
else
  echo "📄 Processando arquivo único"
  FILES="{{source}}"
fi
```

### Passo 2: Ler Conteúdo

```bash
# Ler transcrição(ões)
Read "{{source}}"
```

O grafo cita o trecho por **número de linha** (`#L<a>[-L<b>]`), então leia a transcrição com os números
de linha (a ferramenta Read já os mostra) e guarde-os. Uma transcrição de uma linha só (o texto corrido de alguns exportadores) não dá trecho
citável: quebre uma fala por linha antes de extrair.

### Passo 3: Aplicar Framework EXTRACT

Invocar `@extract-meeting-specialist` com instruções:

```markdown
## Tarefa
Processar a transcrição abaixo aplicando o Framework EXTRACT completo.

## Framework EXTRACT (7 Dimensões)
- **E**ssência: Resumo executivo em 3 linhas
- **X**pectativas: Objetivos da reunião e status (atingido/parcial/não)
- **T**arefas: Ações definidas (quem, o quê, quando)
- **R**esoluções: Decisões tomadas com justificativa
- **A**mbiguidades: Gaps, contradições, pontos não resolvidos
- **C**onexões: Dependências, stakeholders, documentos relacionados
- **T**imeline: Datas e marcos mencionados

## Nível de Output
{{level}} (default: executive)

## Foco
{{focus}} (default: all)

## Regras
1. NUNCA inventar informações — usar [INFERIDO] ou [NÃO ESPECIFICADO]
2. Indicar confidence level em decisões (high/medium/low)
3. Capturar TODOS os gaps — o que NÃO foi decidido é crítico
4. Tasks devem ter owner + deadline sempre que possível
5. Preservar citações importantes entre aspas

## Transcrição
[CONTEÚDO DO ARQUIVO]
```

### Passo 4: Gerar Output

**Nível `compact`:**
```markdown
## Reunião: [Título] | [Data]
**Decisão**: [Principal decisão]
**Ações**: [Nome] faz [quê] até [quando]
**Pendente**: [Principal gap]
```

**Nível `executive`:**
```markdown
## [Título] - [Data]

### Resumo
[3-5 linhas]

### Decisões
- ✅ [Decisão 1] `D_<DECISAO_1>`
- ✅ [Decisão 2] `D_<DECISAO_2>`

### Ações
| Responsável | Ação | Prazo | Nó |
|-------------|------|-------|----|
| [Nome] | [Descrição] | [Data] | `A_<ACAO>` |

### Riscos
- ⚠️ [Risco] `R_<RISCO>`

### Pendências
- ⚠️ [Gap 1]
- ⚠️ [Gap 2]

### Timeline
- 📅 [Data]: [Marco]
```

**O executivo é reconciliado com o grafo (o gate confere).** As seções Decisões, Ações e Riscos listam
**exatamente** as decisões, ações e riscos do grafo, um item por nó, com o id entre crases. Escreva o grafo
primeiro (Passo 6) e derive essas seções dele: duas leituras separadas da transcrição (a sua e a do
`@extract-meeting-specialist`) já deram 5 decisões num e 8 no outro. Decisão que só o resumo tem vira nó no
grafo, com trace; nó que o resumo não cita entra no resumo. Regras que o gate confere:
- cada fato aparece **na seção do seu papel**, num item só (citar o risco só em Pendências não vale, e dois
  itens com o mesmo id reprovam);
- o fato do item é o **primeiro** id dele; outros ids na mesma linha ou em sub-item são referência (ex.: «limita `D_X`»)
  e não mudam a seção;
- nas seções Decisões, Ações e Riscos, todo item de lista, linha de tabela e parágrafo solto precisa de um id;
  sub-item indentado (justificativa, contexto) e a continuação do item não contam como item novo;
- Pendências, Timeline, Resumo, Conexões e Expectativas são livres (não viram nó); um subtítulo sem nome de
  seção dentro de Decisões continua sendo Decisões; comentário HTML não conta como citação.

**Nível `complete`:**
Output YAML completo seguindo schema do knowledge base.

**Nível `graph`:**
Só o grafo da reunião (Passo 6), sem o `.md` do resumo. O grafo e o backlog por área (Passo 8) são gravados
em **todo** nível; os outros níveis mudam só o resumo.

### Passo 5: Salvar Resultado

```bash
# Determinar nome do output
OUTPUT_NAME=$(basename "{{source}}" | sed 's/\.[^.]*$//')
OUTPUT_FILE="docs/meetings/${OUTPUT_NAME}-extract.md"

# Criar diretório se não existir
mkdir -p docs/meetings/

# Salvar
write "${OUTPUT_FILE}"
```

### Passo 6: Gravar o grafo da reunião (`docs/meetings/<nome>.kg.yaml`)

`<nome>` é o mesmo `OUTPUT_NAME` do Passo 5 (o nome da transcrição sem extensão), então o resumo e o grafo
ficam lado a lado: `docs/meetings/<nome>-extract.md` e `docs/meetings/<nome>.kg.yaml`.

Escreva o grafo na gramática do `.kg.yaml` (o radar é `awk`: uma chave por linha, listas com `- id:` e
`- from:`, `node_type:`/`edge_type:` nunca `type:`, datas entre aspas, `label` ≤ 280 caracteres, ids
`[A-Za-z0-9_]` em inglês ou sem acento). O esquema mínimo:

```yaml
meta:
  id: meeting-<AAAA-MM-DD>-<tema>
  schema_version: "1"
  baseline: "<data da extração>"
  x_meeting_date: "<AAAA-MM-DD da reunião>"
  x_meeting_source: "<caminho da transcrição, relativo à raiz do repo>"
  x_capture_stopped_at: "-"        # ou "#L<n>": a linha em que a captura parou porque alguém recusou
  purpose: "<uma linha: do que a reunião tratou>"

nodes:
  - id: MEETING                    # 1 por grafo
    node_type: entity
    x_meeting_role: meeting
    plane: DEV
    status: confirmed
    impact: 3                      # INTEIRO de 1 a 5 (nunca low/medium/high)
    confidence: 0.9                # NÚMERO de 0 a 1 (nunca high/medium/low)
    label: "<uma frase em pt-BR, até 280 caracteres>"
    trace: "<x_meeting_source>#L1-L2"
    verified_at: "<data da extração>"
    verified_against: "leitura da transcrição, linhas 1-2"
    provenance:
      source: "<x_meeting_source>"
      locator: "#L1-L2"
      method: "reading: trecho da transcrição da reunião"
      locality: "repo"
  - id: NOTICE_1                   # 1 por TENTATIVA de aviso (gravação, transcrição, uso dos dados)
    node_type: evidence
    x_meeting_role: notice_attempt
    x_notice_channel: chat         # chat | voz | convite | outro
    x_notice_text: "<o texto do aviso, verbatim>"
  - id: P_<NOME>                   # 1 por participante
    node_type: entity
    x_meeting_role: participant
    x_notice_ref: NOTICE_1         # a tentativa de aviso a que esta pessoa responde
    x_notice_response: ciente      # ciente | recusou | sem_resposta | autora_do_aviso
  - id: D_<DECISAO>
    node_type: decision
    x_meeting_role: decision
  - id: A_<ACAO>
    node_type: claim
    x_meeting_role: action
    x_owner: P_<NOME>              # ou NAO_ESPECIFICADO
    x_due: "<AAAA-MM-DD>"          # opcional
    x_area: produto                # UM termo do vocabulário de áreas, ou NAO_ESPECIFICADO
  - id: R_<RISCO>
    node_type: claim
    x_meeting_role: risk
    x_area: tecnico                # idem; x_owner é opcional no risco

edges:
  - from: NOTICE_1
    to: MEETING
    edge_type: SUPPORTS             # o aviso sustenta a reunião
  - from: P_<NOME>
    to: MEETING
    edge_type: TRACES_TO            # participante e decisão apontam a reunião
  - from: D_<DECISAO>
    to: MEETING
    edge_type: TRACES_TO
  - from: A_<ACAO>
    to: D_<DECISAO>
    edge_type: DEPENDS_ON           # a ação nasce da decisão
  - from: R_<RISCO>
    to: D_<DECISAO>
    edge_type: CONSTRAINS           # o risco limita a decisão sem derrubá-la
```

Todo nó com `x_meeting_role` leva os campos que o `MEETING` mostra acima: `plane: DEV`, `status`,
`impact` (inteiro 1-5), `confidence` (número 0-1), `label` (pt-BR) e
**`trace: "<x_meeting_source>#L<a>[-L<b>]"`**, o trecho de onde o fato saiu.
- **`confirmed`**: reunião, aviso, participante e decisão tomada. Levam `verified_at`, `verified_against` e o
  bloco `provenance` exatamente na forma do `MEETING` (o `locator` é o mesmo trecho do `trace`).
- **`open`**: ação e risco (são compromisso e incerteza, não fato verificado), só com o `trace`.
- **Trace do participante**: a linha em que ele responde ao aviso; sem resposta, a primeira fala dele.
- **Inferência**: dono ou prazo que você deduziu (ex.: "eu faço até sexta" → a data) entra com
  `[INFERIDO]` no `label` e `confidence` de 0.6 ou menos. Dono que ninguém nomeou é `NAO_ESPECIFICADO`.
- **Arestas**: as do bloco `edges:` acima, uma por nó. Nó sem aresta reprova no radar como órfão.
- **Área (`x_area`)**: toda ação e todo risco leva **um** valor, nunca dois nem lista (a lição da swimlane:
  campo multivalor quebra o agrupamento). O vocabulário é **fechado**: o repo declara o seu em
  `docs/meetings/meeting-areas.txt` (um termo por linha, minúsculo e sem acento, ex.: as áreas do app), e sem o
  arquivo vale o padrão `produto · tecnico · negocio · compliance · design · operacoes · pesquisa`. Área que
  ninguém nomeou é `NAO_ESPECIFICADO` (nunca inventar): o item não se perde, vai para o topo do backlog, a
  triar. Decisão, participante e aviso não levam área.
- **Fechar uma ação ou um risco** (numa reunião seguinte, por exemplo) é mudar o `status` do nó no grafo dele
  para `done` com `verified_at` e `verified_against` (o motivo); sem os dois o gate reprova
  (`FECHADO-SEM-MOTIVO`), porque o item sumiria do backlog calado. O `label` de ação e risco é uma linha só.
- **Grafo gravado antes da área** (versão 3.1.0 do comando) reprova com `AREA-AUSENTE` em cada ação e risco,
  inclusive no `--for-use` da consolidação. A migração é acrescentar `x_area: NAO_ESPECIFICADO` a cada um (ou
  a área certa) e rodar o gate de novo.

**O registro de aviso (aviso ≠ consentimento).** O grafo registra **o que aconteceu**: cada tentativa de
aviso e a resposta de cada participante a ela. Ele **nunca declara consentimento legal**: isso é juízo
jurídico, não fato da transcrição, e o gate reprova qualquer chave `legal_consent`/`consentimento_legal`.
- **Não houve aviso, e isso se sabe** (transcrição inteira lida e o organizador não aponta aviso por outro
  canal): registre a ausência com um nó `x_meeting_role: notice_absent`, com `x_notice_absent_basis` (como se
  sabe), `label` com as palavras "não houve aviso", `x_notice_remediation: pendente`, `x_owner` (quem responde, ou
  `NAO_ESPECIFICADO`), `status: open`, `impact` 4 ou 5 e `trace` do início ao fim da transcrição (ou à parada, se
  houve recusa). Cada participante fica em `x_notice_ref: <id do nó>` e `x_notice_response: nao_avisado` (ou
  `recusou`, com a parada de sempre). **Isto registra o fato e não supre a transparência devida aos titulares;
  não é conformidade nem consentimento.** Ausência na reunião também não prova ausência em contrato ou política.
  Base legal, informação aos titulares e reter, usar ou eliminar são do controlador, e a remediação registra o
  que ele fez (`titulares_informados`, `analise_feita`, `dados_eliminados`), sem nenhum valor que declare licitude.
  Pergunte se há dado sensível ou de criança: nesse caso, não use o grafo antes da análise jurídica.
- Sem aviso na transcrição **e sem saber se houve**, **não invente um**: grave o grafo sem `notice_attempt`, com cada participante em
  `x_notice_ref: "-"` e `x_notice_response: sem_resposta`, e o gate reprova com um motivo só,
  `SEM-TENTATIVA-DE-AVISO`. É o comportamento esperado; o caminho é registrar o aviso na próxima reunião (ou anexar à transcrição o aviso
  que foi dado por outro canal, como o convite, e citar essa linha).
- Participante que não respondeu é `sem_resposta`, nunca `ciente` por suposição.
- Se alguém **recusou**, a captura para ali: `x_capture_stopped_at: "#L<linha da recusa>"` (a linha do
  `trace` do participante que recusou, ou antes dela), e nenhuma decisão, ação ou risco pode citar trecho
  que **termine** depois dessa linha.
- O `x_notice_text` é **verbatim** do trecho que o `trace` do aviso cita, e o aviso vem antes do primeiro
  fato (decisão, ação ou risco). Aviso dado depois do que foi decidido não avisou ninguém.
- O `x_notice_text` é a fala do aviso **inteira** (ao menos metade do trecho citado), nunca uma palavra dela.
- Todo nó do grafo leva `x_meeting_role`, e `x_meeting_source` é relativo à raiz do repo, sem `..` que saia
  dela. As chaves `x_` são **só** as do esquema acima (vocabulário fechado), e nenhuma chave fala de
  consentimento. Um nó por item `- id:`, sem estilo fluxo (`- {id: …}`), sem chave repetida e sem lista
  dentro do nó.

### Passo 7: Gate do grafo

```bash
# nível executive (o padrão): o gate reconcilia o resumo com o grafo
bash .claude/validation/meeting-graph-check.sh docs/meetings/<nome>.kg.yaml --summary docs/meetings/<nome>-extract.md
# compact, complete e graph: só o grafo (o compact é um digest de uma decisão; não cita todos os nós)
bash .claude/validation/meeting-graph-check.sh docs/meetings/<nome>.kg.yaml
```

- **rc 0 sem linha SOFT**: conforme (aviso registrado, trace ao trecho, radar verde).
- **rc 0 com `SOFT:AVISO-AUSENTE`**: estado próprio, **`⚠️ NÃO HOUVE AVISO`**, nunca "conforme". O registro é
  válido e o aviso **não aconteceu**. Mostre a linha SOFT inteira e use o relatório de ausência abaixo. O uso do
  grafo fica retido: quem consome pede `--for-use`, que sai rc 3.
- **rc 1**: reprovado. A saída lista um motivo por linha, `MOTIVO<TAB>nó<TAB>detalhe`; mostre todos. O
  grafo reprovado **fica gravado** em `docs/meetings/` (é o registro do que a transcrição tem e do que falta),
  mas não é apresentado como válido, e quem o consome roda o gate antes. Corrija o que é erro de extração (trace
  errado, nó órfão, dono que não é participante) e rode de novo. `SEM-TENTATIVA-DE-AVISO` e
  `RECUSA-SEM-PARADA` **não se corrigem no grafo**: dizem que a reunião não tem registro de aviso ou que a
  captura seguiu depois de uma recusa. Mostre o motivo ao usuário e não apresente o grafo como válido.
- **`RESUMO-*`**: grafo e resumo divergem (`RESUMO-SEM-NO`: o grafo tem, o resumo não; `RESUMO-ITEM-SEM-NO`:
  o resumo tem, o grafo não; `RESUMO-NO-INEXISTENTE` e `RESUMO-SECAO-ERRADA`: id errado). Reconcilie: o que só
  o resumo tem vira nó com trace (ou sai do resumo, se não está na transcrição); o que só o grafo tem entra no
  resumo. Rode o gate de novo.
- **`AREA-*`**: ação ou risco sem área, com área fora do vocabulário ou com mais de uma. Corrija no grafo.
- **rc 2**: o gate não pôde julgar (radar ou python3 ausente). Não é verde: diga isso ao usuário.

### Passo 8: Backlog por área (`docs/meetings/<nome>-backlog.md`)

O backlog é **projeção do grafo**, gerada pelo gate e nunca escrita à mão:

```bash
bash .claude/validation/meeting-graph-check.sh docs/meetings/<nome>.kg.yaml \
  --backlog docs/meetings/<nome>-backlog.md [--carry docs/meetings/<anterior>.kg.yaml ...]
```

- Uma seção por área, `NAO_ESPECIFICADO` primeiro (é o que precisa de triagem); cada ação ou risco aberto é
  `- [ ] <id> · dono: <owner> · prazo: <due|—> — <label>`, e o risco leva `⚠️`. Os campos vêm antes do texto
  livre, e o texto livre sai escapado (ele vem da fala da reunião: é texto, nunca marcação).
- **Carry-over**: passe em `--carry` os grafos das reuniões anteriores da **mesma série** (o parâmetro
  `carry`; sem ele, liste os `.kg.yaml` de `docs/meetings/` e pergunte ao usuário quais são da série). O que
  segue aberto lá entra aqui com `↩ reunião de <data>`. O item some quando o nó fecha **no grafo dele**
  (`status: done` com `verified_at` e `verified_against`, o motivo); o cabeçalho conta os fechados e a seção
  final os nomeia, para nada sumir calado. Grafo repetido (o mesmo `meta.id`) entra uma vez só, senão reprova.
- Só grava com **todos** os grafos conformes: reprovado sai rc 1 (`CARRY-REPROVADO`, `CARRY-FORA-DE-ORDEM`
  para grafo posterior à reunião ou repetido), reunião sem aviso sai rc 3 (o backlog é uso, retido como no
  `--for-use`), e em nenhum dos dois o arquivo é escrito. Saída que é um dos insumos, que não é `.md`, cujo
  diretório não existe ou que já existe sem ser uma projeção anterior do backlog sai rc 2, sem tocar em nada.

> **Dados reais.** O grafo guarda nomes e falas reais, sem anonimização. Não o grave em repositório público.
> Combine com o controlador o prazo de eliminação: apagar de um repo com histórico exige reescrever o histórico.

## 📤 Output Esperado

Com `⚠️ NÃO HOUVE AVISO`, o título do bloco é `⚠️ EXTRAÇÃO CONCLUÍDA, NÃO HOUVE AVISO`, e a linha SOFT inteira vem logo abaixo do grafo.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ EXTRAÇÃO CONCLUÍDA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Arquivo: docs/meetings/[nome]-extract.md
🕸️ Grafo:   docs/meetings/[nome].kg.yaml (gate: ✅ conforme | ⚠️ NÃO HOUVE AVISO | ✗ MOTIVO)
📋 Backlog: docs/meetings/[nome]-backlog.md ([N] abertos em [K] áreas; [C] de reuniões anteriores | retido | não gravado)

📊 Extração EXTRACT:
∟ Essência: ✅
∟ Expectativas: ✅
∟ Tarefas: [N] itens
∟ Resoluções: [N] decisões
∟ Ambiguidades: [N] gaps
∟ Conexões: [N] links
∟ Timeline: [N] datas

📈 Qualidade:
∟ Confidence Score: [0.X]
∟ Tasks com Owner: [X]%
∟ Tasks com Deadline: [X]%
∟ Gaps com Owner Sugerido: [X]%

🚀 Próximos Passos:
1. Revisar gaps críticos
2. Validar decisões com participantes
3. Triar a seção NAO_ESPECIFICADO do backlog e criar tasks no gerenciador (@task-specialist)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🎯 Exemplos de Uso

```bash
# Extrair reunião específica (nível executivo default)
/product/extract-meeting source=reuniao-28-nov.txt

# Nível completo com YAML
/product/extract-meeting source=reuniao.txt level=complete

# Foco apenas em decisões
/product/extract-meeting source=reuniao.txt focus=decisions

# Processar pasta de contexto
/product/extract-meeting source=contextos/projeto-x/

# Só o grafo da reunião (docs/meetings/reuniao.kg.yaml), sem o resumo
/product/extract-meeting source=reuniao.txt level=graph

# Com o carry-over da reunião anterior da série no backlog por área
/product/extract-meeting source=reuniao-2.txt carry=docs/meetings/reuniao-1.kg.yaml
```

## 🔗 Referências

- **Agente**: `@extract-meeting-specialist`
- **Knowledge Base**: `docs/knowledge-base/concepts/meeting-transcription-to-knowledge-base.md`
- **Framework**: EXTRACT (7 dimensões)
- **Gate do grafo**: `.claude/validation/meeting-graph-check.sh` (esquema completo no cabeçalho dele)

## ⚠️ Notas

- Processar em até 24h após reunião (contexto fresco)
- Validar decisões críticas com participantes
- Gaps são tão importantes quanto decisões
- Para criar tasks automaticamente, usar `@task-specialist` após extração

