# Whisper - Knowledge Base

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Criado** | 2025-12-02 |
| **Última Atualização** | 2025-12-02 |
| **Categoria** | Tools |
| **Tags** | `transcription`, `speech-recognition`, `audio-processing`, `openai` |

---

## 🎯 Visão Geral

**Whisper** é um sistema de reconhecimento automático de fala (ASR) desenvolvido pela OpenAI, lançado em setembro de 2022. Treinado com 680 mil horas de dados supervisionados multilíngues e multitarefas, demonstra alta precisão e robustez na transcrição de áudio em diversos idiomas, incluindo português.

### Características Principais

- **Transcrição Multilíngue**: Suporta múltiplos idiomas com alta precisão
- **Tradução de Áudio**: Traduz áudio de diferentes idiomas para inglês
- **Robustez**: Funciona bem mesmo com sotaques diversos e ruídos de fundo
- **Open Source**: Código e modelos disponíveis publicamente
- **Arquitetura Avançada**: Baseada em transformador codificador-decodificador

### Arquitetura Técnica

- **Processamento**: Áudio dividido em segmentos de 30 segundos
- **Conversão**: Espectrogramas log-Mel
- **Modelo**: Transformador codificador-decodificador
- **Tarefas**: Transcrição, identificação de idioma, marcação temporal, tradução

---

## ⚡ Quick Start

### Instalação

```bash
# Instalar Whisper via pip
pip install openai-whisper

# Instalar FFmpeg (necessário para processamento de áudio)
# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg

# macOS
brew install ffmpeg

# Windows
# Baixar de https://ffmpeg.org/download.html
```

### Uso Básico

```bash
# Transcrição simples
whisper audio.mp3

# Especificar idioma e modelo
whisper audio.mp3 --language pt --model large

# Usar GPU (CUDA)
whisper audio.mp3 --language pt --model large --device cuda

# Formato de saída específico
whisper audio.mp3 --output_format txt
```

---

## 🔧 Configuração e Parâmetros

### Modelos Disponíveis

| Modelo | Parâmetros | Tamanho | Velocidade | Precisão |
|--------|-----------|---------|------------|----------|
| `tiny` | 39M | ~75MB | Muito rápida | Baixa |
| `base` | 74M | ~142MB | Rápida | Média |
| `small` | 244M | ~466MB | Média | Boa |
| `medium` | 769M | ~1.5GB | Lenta | Muito boa |
| `large` | 1550M | ~3GB | Muito lenta | Excelente |
| `large-v2` | 1550M | ~3GB | Muito lenta | Excelente |
| `large-v3` | 1550M | ~3GB | Muito lenta | Excelente |

**Recomendação para Português**: Use `small` ou `medium` para melhor equilíbrio entre precisão e velocidade.

### Parâmetros Principais

#### Básicos

```bash
--model MODEL              # Modelo a usar (tiny, base, small, medium, large)
--language LANGUAGE        # Idioma do áudio (pt, en, es, etc)
--device DEVICE            # Dispositivo (cpu, cuda, mps)
--output_dir OUTPUT_DIR    # Diretório de saída
--output_format FORMAT     # Formato (txt, vtt, srt, tsv, json, all)
```

#### Avançados

```bash
--task {transcribe,translate}  # Tarefa: transcrever ou traduzir
--temperature TEMPERATURE     # Temperatura de sampling (0.0-1.0)
--best_of BEST_OF             # Número de candidatos para beam search
--beam_size BEAM_SIZE         # Tamanho do beam search
--word_timestamps             # Incluir timestamps por palavra
--verbose VERBOSE             # Nível de verbosidade
```

### Exemplo Completo

```bash
whisper reuniao-28-nov.m4a \
  --language pt \
  --model large \
  --device cuda \
  --output_format txt \
  --word_timestamps \
  --verbose True
```

---

## 💡 Casos de Uso

### 1. Transcrição de Reuniões

```bash
# Transcrever reunião em português
whisper reuniao.mp3 --language pt --model small --output_format txt

# Com timestamps para referência
whisper reuniao.mp3 --language pt --model small --output_format srt
```

### 2. Processamento em Lote

```bash
# Processar múltiplos arquivos
for file in *.mp3; do
  whisper "$file" --language pt --model small --output_format txt
done
```

### 3. Integração com Sistema Onion

```bash
# 1. Transcrever reunião
whisper reuniao-28-nov.m4a --language pt --model large --output_format txt

# 2. Extrair conhecimento estruturado
/product/extract-meeting source=reuniao-28-nov.txt

# 3. Consolidar múltiplas reuniões
/product/consolidate-meetings source=docs/meet/sprint-planning/

# 4. Converter em tasks
/product/convert-to-tasks source=docs/meet/consolidation-*.md
```

### 4. Legendagem de Vídeos

```bash
# Gerar legendas em formato SRT
whisper video.mp4 --language pt --model medium --output_format srt
```

### 5. Tradução de Áudio

```bash
# Traduzir áudio para inglês
whisper audio.mp3 --task translate --language pt --model medium
```

---

## 🎯 Best Practices

### 1. Escolha do Modelo

- **Desenvolvimento/Testes**: Use `base` ou `small` para velocidade
- **Produção Português**: Use `small` ou `medium` para melhor precisão
- **Alta Precisão**: Use `large` ou `large-v3` quando precisão é crítica

### 2. Performance

- **GPU**: Sempre use `--device cuda` se disponível (10-50x mais rápido)
- **CPU**: Use modelos menores (`base`, `small`) para melhor performance
- **Batch Processing**: Processe múltiplos arquivos em paralelo quando possível

### 3. Qualidade de Áudio

- **Formato**: Prefira formatos não comprimidos (WAV) ou alta qualidade (MP3 320kbps)
- **Ruído**: Whisper é robusto, mas áudio limpo melhora resultados
- **Duração**: Funciona melhor com segmentos de 30 segundos

### 4. Idioma

- **Sempre especifique**: `--language pt` melhora precisão para português
- **Detecção automática**: Se não especificar, Whisper detecta automaticamente (mais lento)

### 5. Formato de Saída

- **TXT**: Para processamento posterior (recomendado para Sistema Onion)
- **SRT**: Para legendas de vídeo
- **JSON**: Para processamento programático
- **ALL**: Para gerar todos os formatos de uma vez

### 6. Integração com Sistema Onion

```bash
# Workflow recomendado:
# 1. Transcrever com Whisper
whisper reuniao.m4a --language pt --model large --output_format txt

# 2. Usar Framework EXTRACT
/product/extract-meeting source=reuniao.txt level=executive

# 3. Consolidar múltiplas reuniões
/product/consolidate-meetings source=docs/meet/

# 4. Converter em tasks acionáveis
/product/convert-to-tasks source=docs/meet/consolidation-*.md
```

---

## ⚠️ Limitações

### Performance

- **Modelos grandes são lentos**: `large` pode levar minutos por minuto de áudio em CPU
- **GPU necessária**: Para uso em produção com modelos grandes, GPU é essencial
- **Memória**: Modelos grandes (`large`) requerem ~6GB RAM

### Precisão

- **Português**: Precisão varia com sotaque e qualidade do áudio
- **Termos técnicos**: Pode ter dificuldade com jargão específico
- **Nomes próprios**: Pode errar nomes de pessoas ou lugares

### Técnicas

- **Segmentação fixa**: Processa em blocos de 30 segundos (pode cortar frases)
- **Contexto limitado**: Não mantém contexto entre segmentos longos
- **Sem edição**: Não permite correção interativa durante transcrição

### Uso

- **Requer FFmpeg**: Dependência externa para processamento de áudio
- **Formato de entrada**: Suporta formatos comuns, mas pode ter problemas com alguns codecs
- **Tamanho de arquivo**: Arquivos muito grandes podem causar problemas de memória

---

## 🔧 Configuração Avançada

### Otimização de Performance

```bash
# Usar GPU com modelo otimizado
whisper audio.mp3 --model large --device cuda --fp16 True

# Reduzir beam search para velocidade
whisper audio.mp3 --model medium --beam_size 2

# Ajustar temperatura para precisão
whisper audio.mp3 --model large --temperature 0.0
```

### Processamento em Lote com Paralelização

```bash
# Usar GNU parallel para processar múltiplos arquivos
find . -name "*.mp3" | parallel whisper {} --language pt --model small
```

### Integração Python

```python
import whisper

# Carregar modelo
model = whisper.load_model("large")

# Transcrever
result = model.transcribe("audio.mp3", language="pt")

# Acessar resultado
print(result["text"])
print(result["segments"])  # Com timestamps
```

---

## 📊 Comparação com Alternativas

| Ferramenta | Precisão | Multilíngue | Open Source | Custo |
|------------|---------|-------------|-------------|-------|
| **Whisper** | ⭐⭐⭐⭐⭐ | ✅ | ✅ | Gratuito |
| Google Speech-to-Text | ⭐⭐⭐⭐⭐ | ✅ | ❌ | Pago |
| AWS Transcribe | ⭐⭐⭐⭐ | ✅ | ❌ | Pago |
| Azure Speech | ⭐⭐⭐⭐ | ✅ | ❌ | Pago |
| DeepSpeech | ⭐⭐⭐ | Limitado | ✅ | Gratuito |

**Vantagens do Whisper:**
- ✅ Open source e gratuito
- ✅ Alta precisão multilíngue
- ✅ Funciona offline
- ✅ Fácil integração
- ✅ Suporte robusto a português

---

## 🔗 Referências

### Documentação Oficial

- **GitHub**: [https://github.com/openai/whisper](https://github.com/openai/whisper)
- **OpenAI Blog**: [https://openai.com/research/whisper](https://openai.com/research/whisper)
- **Paper**: [Robust Speech Recognition via Large-Scale Weak Supervision](https://arxiv.org/abs/2212.04356)

### Recursos Adicionais

- **FFmpeg**: [https://ffmpeg.org/](https://ffmpeg.org/)
- **Documentação Python**: [https://github.com/openai/whisper#python-usage](https://github.com/openai/whisper#python-usage)

### Integração com Sistema Onion

- **Framework EXTRACT**: `/product/extract-meeting`
- **Consolidação**: `/product/consolidate-meetings`
- **Conversão em Tasks**: `/product/convert-to-tasks`

---

## 📝 Exemplos Práticos

### Exemplo 1: Transcrição de Reunião de Sprint

```bash
# Transcrever reunião de planejamento
whisper sprint-planning-2025-12-02.m4a \
  --language pt \
  --model large \
  --device cuda \
  --output_format txt \
  --output_dir docs/meet/transcripts/

# Resultado: docs/meet/transcripts/sprint-planning-2025-12-02.txt
```

### Exemplo 2: Processamento em Lote com Qualidade Alta

```bash
# Processar todas as reuniões de uma pasta
for file in docs/meet/raw/*.m4a; do
  filename=$(basename "$file" .m4a)
  whisper "$file" \
    --language pt \
    --model large \
    --device cuda \
    --output_format txt \
    --output_dir docs/meet/transcripts/
done
```

### Exemplo 3: Workflow Completo Sistema Onion

```bash
# 1. Transcrever reunião
whisper reuniao-28-nov.m4a --language pt --model large --output_format txt

# 2. Extrair conhecimento estruturado (Framework EXTRACT)
/product/extract-meeting source=reuniao-28-nov.txt level=executive

# 3. Consolidar múltiplas reuniões relacionadas
/product/consolidate-meetings source=docs/meet/sprint-planning/

# 4. Converter conhecimento consolidado em tasks
/product/convert-to-tasks source=docs/meet/consolidation-*.md
```

---

## 🎓 Dicas Avançadas

### 1. Melhorar Precisão para Português

```bash
# Use modelo large com temperatura baixa
whisper audio.mp3 --language pt --model large --temperature 0.0

# Especifique prompt inicial com termos técnicos
whisper audio.mp3 --language pt --model large --initial_prompt "Termos técnicos: API, backend, frontend, deploy"
```

### 2. Processar Arquivos Longos

```bash
# Para arquivos muito longos, processe em chunks
# Whisper já faz isso internamente, mas você pode ajustar:
whisper audio.mp3 --language pt --model large --clip_timestamps "00:00,30:00"
```

### 3. Extrair Apenas Timestamps

```bash
# Gerar apenas arquivo JSON com timestamps detalhados
whisper audio.mp3 --language pt --model medium --output_format json --word_timestamps True
```

---

**Última atualização**: 2025-12-02  
**Versão**: 1.0.0  
**Fonte principal**: OpenAI Whisper GitHub Repository

