# Gamma.App API — especificação, padrões de integração e exemplos

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-04 | **Categoria**: Platforms
> Conhecimento técnico da Gamma.App Generations API, **extraído do agente
> `@gamma-api-specialist`** na rodada shed-ceremony de 2026-07-04 (doutrina: agente mantém o grafo
> executável; conhecimento de fundo vive em KB citável). O agente cita esta KB; consumidores
> humanos e IA leem daqui.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-04 |
| **Última Atualização** | 2026-07-04 |
| **Fonte** | Extração de `.claude/agents/development/gamma-api-specialist.md` v3.0.0 (validado contra a API em produção) |
| **Docs oficiais** | <https://developers.gamma.app/> |

---

## 1. Especificação da API (testada e validada)

### Base URL e autenticação

```typescript
// Base URL (VALIDADA em produção — não usar api.gamma.app/api/v1, é legado)
GAMMA_API_URL = "https://public-api.gamma.app/v0.2"

// Header de auth: X-API-KEY (maiúsculo), NÃO Bearer
headers: {
  'X-API-KEY': process.env.GAMMA_API_KEY,
  'Content-Type': 'application/json'
}
// API key: gamma.app/settings/api (beta users). Nunca commitar; .env + .gitignore.
```

### POST `/generations` — payload completo

```typescript
{
  "inputText": string,           // OBRIGATÓRIO (min 10, max 50.000 chars)
  "textMode": "generate" | "condense" | "preserve",   // default: generate
  "format": "presentation" | "document" | "social",   // default: presentation
  "themeName": string,           // tema válido (ver §2)
  "numCards": number,            // 1-60 (Pro) / 1-75 (Ultra), default 10
  "cardSplit": "auto" | "inputTextBreaks",
  "additionalInstructions": string,  // max 500 chars
  "exportAs": "pdf" | "pptx",
  "textOptions": { "amount": "brief|medium|detailed|extensive", "tone": string,
                   "audience": string, "language": string /* ISO: pt-BR, en */ },
  "imageOptions": { "source": "aiGenerated|pictographic|unsplash|giphy|webAllImages|webFreeToUse|webFreeToUseCommercially|placeholder|noImages",
                    "model": string /* imagen-4-pro, flux-1-pro */, "style": string },
  "cardOptions": { "dimensions": "fluid|16x9|4x3|1x1|4x5|9x16|pageless|letter|a4" },
  "sharingOptions": { "workspaceAccess": "noAccess|view|comment|edit|fullAccess",
                      "externalAccess": "noAccess|view|comment|edit" }
}
// 201 Created → { "generationId": string }
// 400 → { message, statusCode } · 403 → sem créditos
```

### GET `/generations/{generationId}` — polling de status

```typescript
// 200 pending   → { status: "pending", generationId }
// 200 completed → { generationId, status: "completed", gammaUrl,
//                   credits: { deducted, remaining } }
// 404           → generationId não encontrado
// Poll a cada ~3s; timeout de 120s.
```

### Modos de texto (`textMode`)

| Modo | Uso | Exemplo |
|---|---|---|
| `generate` | expandir texto curto em deck completo | "apresentação sobre IA no varejo" → deck de N slides |
| `condense` | resumir texto longo em visual conciso | doc técnico de 10 páginas → pontos principais |
| `preserve` | manter estrutura, só formatar | conteúdo já estruturado → slides fiéis |

### Idiomas (60+) e constraints

- Principais: `pt-BR`, `en-US`, `es-ES`, `fr-FR`, `de-DE`, `it-IT`, `ja-JP`, `zh-CN`, `ko-KR`, `ar-SA`.
- **Rate limits**: 50 gerações/hora por usuário · 100 requests/min (demais operações) · 3 gerações concorrentes.
- **Tempo de processamento**: simples 10-15s · médio 15-30s · complexo 30-60s · timeout 120s.

## 2. Temas

```yaml
business:  [Aurora, Basalt, Beam, Blueprint, Breeze]
creative:  [Canvas, Cosmic, Drift, Echo, Flow]
technical: [Grid, Logic, Matrix, Mono, Platform]
elegant:   [Pearl, Silk, Luxe, Frost, Crystal]
# 40+ temas built-in; validar nome antes de usar (tema inválido → fallback "Oasis").
```

## 3. Padrões de integração

### Rate-limit manager (fila com margem de segurança)

```python
RATE_LIMIT = 50; SAFETY_MARGIN = 5   # opera a 45/50
class RateLimitManager:
    def can_generate(self): self._reset_if_needed(); return self.count < (RATE_LIMIT - SAFETY_MARGIN)
    async def generate_with_backoff(self, payload):
        if not self.can_generate(): await self.queue(payload); return {"status": "queued"}
        result = await gamma_api.generate(payload); self.count += 1; return result
# Reset por janela de 3600s; delay ~2s entre requests (evitar burst).
```

### Matriz de erros e recuperação

| Erro | Recuperação |
|---|---|
| `RATE_LIMIT_EXCEEDED` | enfileirar para a próxima janela |
| `INVALID_INPUT` (400) | validar campos (tamanho, formato, tema, ISO) e retentar |
| `AUTHENTICATION_FAILED` | verificar/renovar `GAMMA_API_KEY` |
| `GENERATION_TIMEOUT` | simplificar input e retentar |
| `INTERNAL_ERROR` (500) | retry com exponential backoff (até 3×) |

### Best practices

```yaml
Input:     validar 10-50k chars · sanitizar · idioma ISO · tema existente · nunca dados sensíveis crus
RateLimit: fila sempre · contador local · margem 45/50 · nunca loop tight
API key:   env var · nunca commitar/logar · rotacionar · keys distintas dev/prod
Qualidade: textMode adequado · input em markdown estruturado · revisar output antes de usar
Performance: cache de resultados · geração em background · timeout 120s
```

## 4. Casos de uso (código de referência)

### Task → apresentação (com task manager via adapter)

```typescript
async function generatePresentationFromTask(taskId: string) {
  const task = await taskManager.getTask(taskId);   // adapter agnóstico (REST API; MCP opcional)
  const inputText = `# ${task.name}\n\n## Contexto\n${task.description}\n\n## Entregáveis\n` +
    task.subtasks.map(st => `- ${st.name}`).join('\n');
  const p = await gamma.generate({ inputText, textMode: 'condense',
    format: 'presentation', themeName: 'Beam', textOptions: { language: 'pt-BR' } });
  await taskManager.addComment(taskId, `✅ Apresentação: ${p.gammaUrl}`);
  return p;
}
```

### Docs → conteúdo social (config por plataforma)

```typescript
const platformConfig = {
  linkedin:  { textMode: 'condense', style: 'professional' },
  twitter:   { textMode: 'condense', style: 'concise' },
  instagram: { textMode: 'generate', style: 'engaging' },
};
// gamma.generate({ inputText: doc, format: 'social', ...platformConfig[platform] })
```

### Sprint report (preserve + tema técnico)

```typescript
// inputText estruturado (objetivos ✅ / métricas / impedimentos ⚠️ / próximos →)
// gamma.generate({ inputText, textMode: 'preserve', format: 'presentation',
//                  themeName: 'Grid', exportAs: 'pptx' })
```

### Batch com fila (respeitando concurrency 3)

```typescript
class GammaBatchProcessor {
  // while queue: if !rateLimiter.can_generate() → aguardar reset;
  // processar 1 a 1 com sleep(2000) entre requests; sucesso/erro por item.
}
```

## 5. SDK wrapper e CLI (implementação de referência)

```typescript
// GammaSDK: axios com timeout 120s + validateInput (10-50k chars, formato válido)
// + RateLimitManager embutido + waitForCompletion(id) com poll de 3s.
// CLI (commander): generate <file> [--format --theme --mode --language --export] · themes · status
// Fonte completa no histórico do agente (git log -- .claude/agents/development/gamma-api-specialist.md, v3.0.0).
```

## 6. Monitoramento

```yaml
Métricas:  generationsPerHour · averageProcessingTime · successRate · queueLength · editRate
Alertas:   40/50 gerações → pausar não-urgentes · erro >10% → revisar retry ·
           fila >20 → priorizar críticos · média >45s → simplificar inputs
KPIs:      simples <15s · complexa <45s · timeout <2% · sucesso >95% · output sem edição >70%
```

## 7. Limitações conhecidas (beta) e workarounds

| Limitação | Workaround |
|---|---|
| Sem OAuth (só API key) · sem webhooks · sem streaming · sem batch endpoint | polling com backoff · fila própria · notificação própria |
| 50 gerações/h restritivo p/ alto volume · concurrent 3 | fila inteligente · priorização · cache de similares |
| Custom themes/brand assets via API indisponíveis | pós-processamento · biblioteca de templates prontos |

## 8. Referências

- API Docs: <https://developers.gamma.app/> · Reference: <https://developers.gamma.app/reference/>
- Status: <https://status.gamma.app/> · Changelog: <https://developers.gamma.app/changelog/>
- Agente executor: `.claude/agents/development/gamma-api-specialist.md`
- Orquestrador consumidor: [presentation-orchestration.md](../patterns/presentation-orchestration.md)
