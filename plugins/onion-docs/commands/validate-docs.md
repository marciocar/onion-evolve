---
name: validate-docs
description: |
  Validação de completude e consistência da documentação.
  Use para verificar estrutura, links e padrões.
  Diferença vs /docs:docs-health: este VALIDA + corrige (estrutura/links/padrões, com --fix); o docs-health é o diagnóstico read-only (saúde/gaps/recomendações).
model: sonnet
allowed-tools: Read Bash(find *) Bash(grep *) Bash(ls *) Bash(test -f *)

parameters:
  - name: path
    description: 'Caminho para validar (default: docs/)'
    required: false
    default: docs/
  - name: fix
    description: Corrigir problemas automaticamente
    required: false
    default: "false"

category: docs
tags:
  - validation
  - documentation
  - quality

version: "3.0.0"
updated: "2025-11-24"

related_commands:
  - /docs/docs-health
  - /docs/build-tech-docs

related_agents:
  - system-documentation-orchestrator
---

# ✅ Validar Documentação

Validação abrangente de estrutura e qualidade de docs.

## 🎯 Objetivo

Verificar completude, consistência e padrões da documentação.

## ⚡ Fluxo de Execução

### Passo 1: Validar Estrutura

```bash
# Arquivos obrigatórios
REQUIRED=(README.md CHANGELOG.md)
for f in "${REQUIRED[@]}"; do
  test -f "$f" && echo "✅ $f" || echo "❌ $f ausente"
done

# Hierarquia de diretórios
ls -la {{path}}/
```

#### Checklist de Estrutura

- [ ] `README.md` na raiz
- [ ] `docs/` com índice
- [ ] Naming em kebab-case
- [ ] Extensão `.md`

### Passo 2: Validar Conteúdo

#### Verificações por Arquivo

```bash
for f in $(find {{path}} -name "*.md"); do
  # Header presente
  head -1 "$f" | grep -q "^#" || echo "⚠️ $f: sem header"
  
  # Linhas mínimas
  [ $(wc -l < "$f") -lt 10 ] && echo "⚠️ $f: muito curto"
done
```

#### Seções Obrigatórias

| Tipo de Doc | Seções Requeridas |
|-------------|-------------------|
| README | Objetivo, Uso, Instalação |
| API | Endpoints, Exemplos |
| Guide | Pré-requisitos, Steps |
| Spec | Objetivo, Requisitos |

### Passo 3: Validar Links

```bash
# Links internos
grep -roh '\[.*\](.*\.md)' {{path}}/ | \
  sed 's/.*(\(.*\))/\1/' | \
  while read link; do
    test -f "$link" || echo "❌ Link quebrado: $link"
  done
```

### Passo 4: Gerar Relatório

## 📤 Output Esperado

### Sem Erros

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ VALIDAÇÃO CONCLUÍDA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Resumo:
∟ Arquivos: 45
∟ Erros: 0
∟ Avisos: 3

✅ Estrutura: OK
✅ Conteúdo: OK
✅ Links: OK

⚠️ Avisos:
∟ 3 arquivos sem update >30d
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Com Erros

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ ERROS ENCONTRADOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Resumo:
∟ Arquivos: 45
∟ Erros: 5
∟ Avisos: 8

❌ Erros:
∟ docs/api.md: link quebrado (line 45)
∟ docs/guide.md: sem header
∟ README.md: seção "Uso" ausente

⚠️ Avisos:
∟ 8 arquivos muito curtos (<50 linhas)

💡 Para corrigir: /docs/validate-docs fix="true"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- Health check: /docs/docs-health
- Agente: @system-documentation-orchestrator

## ⚠️ Notas

- Executar antes de releases
- `fix="true"` corrige apenas formatação
- Links quebrados requerem correção manual
