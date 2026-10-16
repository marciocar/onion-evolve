---
name: extract-meeting
description: |
  Extração estruturada de conhecimento de transcrições de reuniões usando Framework EXTRACT.
  Use para transformar arquivos de contexto bruto em artefatos de alto valor para humanos, sistemas e IA.
  Grava o resumo (.md) e o grafo da reunião (.kg.yaml, com trace ao trecho e o registro de aviso aos
  participantes) em docs/meetings/; o gate meeting-graph-check.sh diz se o grafo vale.
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

category: product
tags:
  - meeting
  - extraction
  - knowledge-base
  - documentation

version: "3.1.0"
updated: "2026-10-16"

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
---

# 📋 Extrair Conhecimento de Reunião

Transformação de transcrições brutas em conhecimento estruturado usando o Framework EXTRACT.

## 🎯 Objetivo

Processar transcrições de reuniões e gerar outputs estruturados consumíveis por humanos, sistemas e IA, seguindo as 7 dimensões do Framework EXTRACT.

Toda extração gera **dois artefatos** em `docs/meetings/`, o diretório único das reuniões (o
`/product:consolidate-meetings`, o `/product:whisper` e o `@whisper-specialist` leem e gravam no mesmo lugar):

- `<nome>-extract.md`: o resumo EXTRACT no nível pedido, para gente ler;
- `<nome>.kg.yaml`: o **grafo da reunião** (pessoas, aviso, decisões, ações e riscos), cada nó com
  `trace` ao trecho da transcrição. É a entrada da consolidação entre reuniões.

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
- ✅ [Decisão 1]
- ✅ [Decisão 2]

### Ações
| Responsável | Ação | Prazo |
|-------------|------|-------|
| [Nome] | [Descrição] | [Data] |

### Pendências
- ⚠️ [Gap 1]
- ⚠️ [Gap 2]

### Timeline
- 📅 [Data]: [Marco]
```

**Nível `complete`:**
Output YAML completo seguindo schema do knowledge base.

**Nível `graph`:**
Só o grafo da reunião (Passo 6), sem o `.md`. O grafo é gravado em **todo** nível; os outros níveis
mudam só o resumo.

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
      method: "leitura: trecho da transcrição da reunião"
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
  - id: R_<RISCO>
    node_type: claim
    x_meeting_role: risk

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

**O registro de aviso (aviso ≠ consentimento).** O grafo registra **o que aconteceu**: cada tentativa de
aviso e a resposta de cada participante a ela. Ele **nunca declara consentimento legal**: isso é juízo
jurídico, não fato da transcrição, e o gate reprova qualquer chave `legal_consent`/`consentimento_legal`.
- Sem aviso na transcrição, **não invente um**: grave o grafo sem `notice_attempt`, com cada participante em
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
bash .claude/validation/meeting-graph-check.sh docs/meetings/<nome>.kg.yaml
```

- **rc 0**: conforme (aviso registrado, trace ao trecho, radar verde).
- **rc 1**: reprovado. A saída lista um motivo por linha, `MOTIVO<TAB>nó<TAB>detalhe`; mostre todos. O
  grafo reprovado **fica gravado** em `docs/meetings/` (é o registro do que a transcrição tem e do que falta),
  mas não é apresentado como válido, e quem o consome roda o gate antes. Corrija o que é erro de extração (trace
  errado, nó órfão, dono que não é participante) e rode de novo. `SEM-TENTATIVA-DE-AVISO` e
  `RECUSA-SEM-PARADA` **não se corrigem no grafo**: dizem que a reunião não tem registro de aviso ou que a
  captura seguiu depois de uma recusa. Mostre o motivo ao usuário e não apresente o grafo como válido.
- **rc 2**: o gate não pôde julgar (radar ou python3 ausente). Não é verde: diga isso ao usuário.

> **Dados reais.** O grafo guarda nomes e falas reais, sem anonimização. Não o grave em repositório público.

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ EXTRAÇÃO CONCLUÍDA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Arquivo: docs/meetings/[nome]-extract.md
🕸️ Grafo:   docs/meetings/[nome].kg.yaml (gate: ✅ conforme | ✗ MOTIVO)

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
3. Criar tasks no gerenciador (@task-specialist)
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

