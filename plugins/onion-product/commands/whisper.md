---
name: whisper
description: |
  Facilita o uso eficiente do agente Whisper para transcrição de áudio.
  Detecta necessidade do usuário e delega para @whisper-specialist com contexto otimizado.
model: sonnet
allowed-tools: Read Bash(ls *)

parameters:
  - name: query
    description: Sua pergunta ou necessidade (instalação, uso, troubleshooting, workflow)
    required: false
  - name: audio_file
    description: Arquivo de áudio para transcrever (opcional)
    required: false
  - name: platform
    description: Plataforma (windows/linux/macos) para comandos específicos
    required: false

category: product
tags:
  - whisper
  - transcription
  - audio-processing
  - meeting-processing

version: "3.0.0"
updated: "2025-12-02"

related_commands:
  - /product/extract-meeting
  - /product/consolidate-meetings
  - /product/convert-to-tasks

related_agents:
  - whisper-specialist
  - extract-meeting-specialist
---

# 🎤 Whisper - Transcrição de Áudio

Comando facilitador para usar o agente @whisper-specialist com eficiência máxima.

## 🎯 Objetivo

Facilitar o uso do Whisper para transcrição de áudio, integrando com workflows do Sistema Onion:
- Detectar necessidade do usuário automaticamente
- Delegar para @whisper-specialist com contexto otimizado
- Conectar com workflow completo de processamento de reuniões
- Fornecer comandos prontos para uso

## ⚡ Fluxo de Execução

### Passo 1: Detectar Necessidade do Usuário

Analisar `{{query}}` e `{{audio_file}}` para identificar necessidade:

**SE `{{audio_file}}` fornecido:**
- Necessidade: Transcrever arquivo específico
- Ação: Preparar comando Whisper otimizado

**SE `{{query}}` contém palavras-chave:**
- "instalar", "setup", "configurar" → Instalação
- "usar", "transcrever", "processar" → Uso
- "erro", "problema", "não funciona" → Troubleshooting
- "workflow", "integração", "sistema onion" → Workflow completo

**SE nenhum parâmetro:**
- Mostrar ajuda geral e opções disponíveis

### Passo 2: Delegar para @whisper-specialist

Invocar agente com contexto otimizado:

```markdown
@whisper-specialist

{{query_completa_com_contexto}}

**Contexto Adicional:**
- Plataforma: {{platform}} (se fornecido)
- Arquivo de áudio: {{audio_file}} (se fornecido)
- Necessidade detectada: {{necessidade_detectada}}

**Por favor, forneça:**
- Comandos específicos para a plataforma
- Explicação clara dos passos
- Validação e testes
- Próximos passos no workflow (se aplicável)
```

### Passo 3: Integrar com Workflow do Sistema Onion

**SE transcrição foi realizada:**

Apresentar workflow completo:

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ TRANSCRIÇÃO CONCLUÍDA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 **Arquivo transcrito:** {{arquivo_txt}}

🔗 **Próximos passos no Sistema Onion:**

1. Extrair conhecimento estruturado:
   /product/extract-meeting source={{arquivo_txt}} level=executive

2. Consolidar múltiplas reuniões:
   /product/consolidate-meetings source=docs/meet/

3. Converter em tasks:
   /product/convert-to-tasks source=docs/meet/consolidation-*.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 📤 Output Esperado

### Para Instalação

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 INSTALAÇÃO WHISPER - {{platform}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **Comandos para executar:**

{{comandos_específicos_da_plataforma}}

✅ **Validação:**
{{comando_de_teste}}

💡 **Dica:** Use @whisper-specialist para ajuda detalhada
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Para Transcrição

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎤 COMANDO WHISPER OTIMIZADO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **Comando recomendado:**
{{comando_completo_otimizado}}

📊 **Parâmetros:**
∟ Modelo: {{modelo_recomendado}}
∟ Idioma: pt (português)
∟ Formato: txt (para Sistema Onion)
∟ GPU: {{device}} (se disponível)

🔗 **Próximo passo:**
/product/extract-meeting source={{arquivo_txt}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Para Troubleshooting

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 SOLUÇÃO IDENTIFICADA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️ **Problema:** {{problema_identificado}}

✅ **Solução:**
{{solução_detalhada}}

📋 **Comandos para executar:**
{{comandos_de_solução}}

💡 **Prevenção:**
{{dicas_para_evitar_problema}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🎯 Casos de Uso

### Caso 1: Instalação

```bash
# Detectar plataforma automaticamente ou especificar
/product/whisper "Como instalar Whisper?" platform=linux

# Ou deixar detectar automaticamente
/product/whisper "Preciso instalar Whisper no Ubuntu"
```

### Caso 2: Transcrição Simples

```bash
# Transcrever arquivo específico
/product/whisper audio_file=reuniao.mp3

# Com pergunta específica
/product/whisper "Qual melhor modelo para português?" audio_file=reuniao.mp3
```

### Caso 3: Workflow Completo

```bash
# 1. Transcrever
/product/whisper audio_file=reuniao-28-nov.m4a

# 2. Extrair conhecimento (comando gerado automaticamente)
/product/extract-meeting source=reuniao-28-nov.txt

# 3. Consolidar e converter (workflow completo)
/product/consolidate-meetings source=docs/meet/
/product/convert-to-tasks source=docs/meet/consolidation-*.md
```

### Caso 4: Troubleshooting

```bash
# Problema específico
/product/whisper "FFmpeg não encontrado no Windows"

# Erro de GPU
/product/whisper "GPU não detectada" platform=linux
```

### Caso 5: Ajuda Geral

```bash
# Sem parâmetros - mostra ajuda
/product/whisper

# Pergunta geral
/product/whisper "Como usar Whisper com eficiência?"
```

## 🔗 Integração com Sistema Onion

### Workflow Completo Automatizado

Este comando facilita o workflow completo:

```bash
# 1. Transcrever reunião
/product/whisper audio_file=reuniao.m4a

# → Gera: reuniao.txt

# 2. Extrair conhecimento (Framework EXTRACT)
/product/extract-meeting source=reuniao.txt level=executive

# → Gera: conhecimento estruturado

# 3. Consolidar múltiplas reuniões
/product/consolidate-meetings source=docs/meet/sprint-planning/

# → Gera: documento consolidado

# 4. Converter em tasks
/product/convert-to-tasks source=docs/meet/consolidation-*.md

# → Gera: tasks no Task Manager
```

### Otimizações Automáticas

- **Formato de saída**: Sempre `txt` para melhor integração
- **Modelo recomendado**: `small` ou `medium` para português (equilíbrio)
- **GPU**: Detecta e usa automaticamente se disponível
- **Idioma**: Sempre `pt` para português

## ⚙️ Parâmetros Detalhados

### `query`
- **Opcional**: Pergunta ou necessidade do usuário
- **Exemplos**: 
  - "Como instalar?"
  - "Melhor modelo para português"
  - "FFmpeg não encontrado"
  - "Workflow completo com Sistema Onion"

### `audio_file`
- **Opcional**: Caminho para arquivo de áudio
- **Formatos suportados**: .mp3, .m4a, .wav, .mp4, etc
- **Quando fornecido**: Prepara comando de transcrição otimizado

### `platform`
- **Opcional**: windows | linux | macos
- **Quando não fornecido**: Detecta automaticamente ou pergunta
- **Uso**: Para comandos específicos de instalação

## 💡 Boas Práticas

1. **Sempre especifique plataforma** para instalação (mais preciso)
2. **Forneça arquivo de áudio** quando quiser transcrição direta
3. **Use workflow completo** para máximo aproveitamento
4. **Consulte @whisper-specialist** para questões técnicas detalhadas
5. **Revise transcrição** antes de processar com Framework EXTRACT

## ⚠️ Notas Importantes

- **Delegação**: Este comando delega para @whisper-specialist
- **Knowledge Base**: @whisper-specialist consulta `docs/knowledge-base/tools/whisper.md`
- **Workflow**: Sempre sugere próximos passos no Sistema Onion
- **Plataforma**: Detecta automaticamente ou permite especificar
- **Otimização**: Comandos gerados são otimizados para português e Sistema Onion

## 🔄 Relacionamentos

**Agente Principal:**
- `@whisper-specialist` - Especialista técnico em Whisper

**Comandos Relacionados:**
- `/product/extract-meeting` - Extrair conhecimento de transcrições
- `/product/consolidate-meetings` - Consolidar múltiplas reuniões
- `/product/convert-to-tasks` - Converter em tasks acionáveis

**Knowledge Base:**
- `docs/knowledge-base/tools/whisper.md` - Conhecimento completo sobre Whisper

---

**Versão:** 3.0.0  
**Última atualização:** 2025-12-02

