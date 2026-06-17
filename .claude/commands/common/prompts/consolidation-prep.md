---
name: consolidation-prep
description: Steps de preparação compartilhados entre consolidate-documents e consolidate-meetings
type: fragment
---

# Fragmento: Preparação para Consolidação

Passos 1 e 3 compartilhados pelos comandos `/docs/consolidate-documents` e `/product/consolidate-meetings`.

---

## Passo 1: Detectar Tipo de Entrada

Analisar o parâmetro `source` fornecido:

```bash
# Verificar se é pasta ou arquivo(s)
if [ -d "$source" ]; then
  # É uma pasta
  echo "📁 Pasta detectada: $source"
elif [ -f "$source" ]; then
  # É um arquivo único
  echo "📄 Arquivo detectado: $source"
else
  # Múltiplos arquivos (separados por espaço)
  echo "📄 Múltiplos arquivos detectados"
fi
```

**Se for pasta:**
- Listar arquivos de origem na pasta
- Filtrar por extensões relevantes (ver Passo 2 do comando específico)
- Ordenar por data de modificação ou nome

**Se for arquivo(s):**
- Processar arquivo(s) diretamente
- Validar que são arquivos válidos para o tipo de consolidação

---

## Passo 3: Preparar Contexto para Consolidação

Antes de processar, preparar contexto estruturado:

```markdown
## Contexto da Consolidação

### Arquivos a Consolidar
{{lista_de_arquivos_com_paths}}

### Foco da Análise
{{focus}} (all|divergences|convergences|insights|gaps)

### Informações dos Arquivos
{{metadados_dos_arquivos}}
```

**Metadados a Coletar (adapte ao tipo de fonte):**
- Nome do arquivo e caminho completo
- Data de modificação ou data do evento (reunião, publicação)
- Tipo / categoria do arquivo (identificado por conteúdo ou nome)
- Tema principal (extraído do conteúdo)
- Informações específicas do domínio (participantes para reuniões; estrutura/referências para documentos)

---

> **Nota de uso**: importe este fragmento nos Passos 1 e 3 do comando consolidador específico; o Passo 2 (coleta de arquivos) e os Passos 4-6 (análise, validação, salvamento) permanecem específicos de cada comando, pois diferem em filtros, agentes invocados e campos de metadados.
