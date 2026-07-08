---
name: integration
description: |
  Gera e executa testes de integração automaticamente com detecção de framework.
  Use para criar testes de integração (Grey-box) seguindo padrões do projeto, incluindo API contract testing, boundary testing e fuzzing.
model: sonnet
allowed-tools: Read Glob Write Bash(find *) Bash(cat *) Bash(npm *) Bash(pnpm *) Bash(npx *)

parameters:
  - name: api-endpoint
    description: 'Endpoint da API ou serviço para testar (ex: "/api/users", "UserService")'
    required: true
  - name: --generate
    description: Gera arquivo de teste se não existir
    required: false
  - name: --run
    description: Executa os testes após gerar/validar
    required: false
  - name: --contract
    description: Foca em contract testing (valida schemas e contratos)
    required: false
  - name: --boundary
    description: Foca em boundary testing (timeouts, erros, limites)
    required: false
  - name: --fuzz
    description: Inclui fuzzing de API (testes com dados malformados)
    required: false
  - name: --framework
    description: 'Framework específico (sobrescreve auto-detecção: supertest|pact|postman|wiremock|jest|vitest)'
    required: false
  - name: --mock-external
    description: 'Mocka serviços externos (default: true para testes isolados)'
    required: false

category: test
tags:
  - testing
  - integration-tests
  - grey-box-testing
  - api-testing
  - contract-testing
  - test-generation
  - automation

version: "3.0.0"
updated: "2025-12-03"

related_commands:
  - /test/unit
  - /test/e2e
  - /validate/test-strategy/create
  - /engineer/work

related_agents:
  - test-engineer
  - test-planner
  - test-agent
---

# 🔗 Test Integration

Orquestra geração e execução de testes de integração com detecção inteligente de framework, perspectiva **Grey-box** (dev testando outro dev).

> **Teoria e padrões Grey-box** (White/Grey/Black-box, contract testing, boundary, fuzzing, métricas de integração): ver `docs/knowledge-base/frameworks/framework-testes.md` — seções "Diferenças White/Black/Grey-box", "Padrões Grey-box (Cross-Testing)" e "Técnicas Grey-box". Este comando não duplica essa teoria; apenas a aplica.

## 🎯 Objetivo

Automatizar o ciclo completo de testes de integração (Grey-box):
- **Auto-detecção** de framework (Supertest, Pact, Postman, Wiremock)
- **Análise de API/service** para identificar endpoints e contratos
- **Geração** de testes seguindo padrões do projeto
- **Contract testing** (schemas), **boundary** (timeouts, erros, limites) e **fuzzing** (dados malformados)
- **Execução** com mocks de serviços externos

## ⚡ Fluxo de Execução

### Passo 1: Validar Endpoint/Service

```markdown
SE api-endpoint vazio:
  ❌ ERRO: Endpoint ou serviço é obrigatório
  💡 Exemplos: "/api/users", "UserService", "payment-gateway"
SE formato inválido:
  ⚠️ AVISO: Endpoint deve ser caminho de API ou nome de serviço
```

### Passo 2: Detectar Framework de Integração

**Estratégia de Detecção (em ordem de prioridade):**

1. **Verificar configurações:**
   - `pact.config.{js,ts}` → Pact detectado
   - `postman.json` ou `postman/` → Postman detectado
   - `wiremock/` ou `mocks/` → Wiremock detectado
   - `package.json` → `supertest`, `@pact-foundation/pact`, `postman`, `wiremock` em dependencies
   - `jest.config.{js,ts}` ou `vitest.config.{js,ts}` → Jest/Vitest com Supertest

2. **Buscar arquivos de teste existentes:**
   - `**/*.integration.{js,ts}`
   - `**/integration/**/*.spec.{js,ts}`
   - `**/tests/integration/**/*.{js,ts}`
   - `**/contracts/**/*.{js,ts}` (Pact)
   - `**/pacts/**/*.json` (Pact)

3. **Inferir por estrutura:**
   - Diretório `contracts/` ou `pacts/` → Pact
   - Diretório `mocks/` ou `wiremock/` → Wiremock
   - Arquivos `*.postman_collection.json` → Postman
   - Uso de `supertest` em testes → Supertest

**Output:**
```markdown
✅ Framework detectado: [supertest|pact|postman|wiremock|jest|vitest]
📁 Config: [caminho do arquivo de config]
🔧 Test runner: [jest|vitest|mocha]
🌐 Mock strategy: [wiremock|nock|msw]
```

**Se `--framework` fornecido:** Sobrescreve detecção automática

### Passo 3: Analisar API/Service

**Objetivo:** Identificar endpoints, contratos e dependências externas.

#### 3.1 Detectar Tipo de Endpoint

**Buscar no código:**
- Rotas de API: `app.get()`, `router.post()`, `@Get()`, `@Post()`
- Serviços: Classes com métodos públicos, interfaces
- GraphQL: `schema.graphql`, resolvers

#### 3.2 Extrair Contratos

**Buscar schemas e contratos:**
- OpenAPI/Swagger: `openapi.yaml`, `swagger.json`
- JSON Schema: `schema.json`, `*.schema.json`
- Pact contracts: `pacts/*.json`
- TypeScript types/interfaces
- GraphQL schema

#### 3.3 Identificar Dependências Externas

- APIs externas (HTTP calls)
- Serviços de terceiros
- Bancos de dados
- Message queues
- Cache services

**Output da Análise:**
```markdown
📊 Análise de API/Service:
∟ Tipo: [REST API|GraphQL|Service|Microservice]
∟ Endpoints encontrados: [N]
∟ Contratos encontrados: [Sim/Não]
∟ Dependências externas: [lista]
∟ Mock strategy: [wiremock|nock|msw|manual]
```

### Passo 4: Verificar Arquivo de Teste Existente

**Padrões de nomenclatura:**
- **Supertest:** `{{endpoint}}.integration.test.{js,ts}`
- **Pact:** `{{consumer}}-{{provider}}.spec.{js,ts}` ou `contracts/{{name}}.spec.{js,ts}`
- **Postman:** `{{collection}}.postman_collection.json`
- **Jest/Vitest:** `{{endpoint}}.integration.{js,ts}` ou `integration/{{endpoint}}.spec.{js,ts}`

**Decisão:**
```markdown
SE arquivo existe:
  ✅ Encontrado: [caminho]
  SE --generate: ⚠️ Pula geração, continua execução
  SENÃO: Continua execução

SE não existe:
  SE --generate: → Gerar (Passo 5)
  SENÃO: ❌ ERRO: Use --generate para criar
```

### Passo 5: Gerar Arquivo de Teste (SE --generate)

**Estratégia:**
1. **Ler padrões existentes:** Buscar `**/*.integration.{js,ts}`, `**/contracts/**/*.{js,ts}` para extrair estrutura
2. **Gerar testes base:** Padrão AAA (Arrange, Act, Assert) para cada endpoint:
   - **Contract tests:** Validação de schema, tipos, estruturas
   - **Boundary tests:** Timeouts, erros, limites, edge cases
   - **Fuzzing tests:** Dados malformados, tipos incorretos, valores extremos
3. **Configurar mocks:** Para dependências externas (Wiremock, Nock, MSW)
4. **Criar arquivo:** `write {{test-file-path}}`

**Esqueleto Supertest + Jest** (3 blocos `describe`, padrão AAA):
```typescript
import request from 'supertest';
import app from '../src/app';

describe('API Integration: {{api-endpoint}}', () => {
  beforeEach(() => { /* setup mocks de serviços externos */ });

  describe('Contract Testing', () => {     // valida schema/tipos da resposta
    test('GET retorna schema válido', async () => {
      const res = await request(app).get('/api/users').expect(200);
      expect(res.body).toMatchSchema({ /* ... */ });
    });
  });

  describe('Boundary Testing', () => {      // timeout, erro e resposta inválida do externo
    test('trata timeout do serviço externo', async () => {
      mockExternalService.timeout();
      const res = await request(app).get('/api/users').expect(500);
      expect(res.body.error).toBe('Service timeout');
    });
  });

  describe('Fuzzing Tests', () => {          // dados malformados → 400, sem travar
    test('trata JSON malformado', async () => {
      for (const input of ['{"name": incompleto', '{"name": "'+'x'.repeat(10000)+'"}']) {
        await request(app).post('/api/users').send(input).expect(400);
      }
    });
  });
});
```

> Para Pact, contract testing detalhado e fuzzing, reutilize os padrões prontos em `docs/knowledge-base/frameworks/framework-testes.md` (seção "Padrões Grey-box (Cross-Testing)" e "Técnicas Grey-box").

**Validação:** ✅ Arquivo gerado: {{test-file-path}}, [N] testes (contract: X, boundary: Y, fuzzing: Z)

### Passo 6: Executar Testes (SE --run)

**Comandos por framework:**

- **Supertest + Jest:** `npx jest {{test-file}} [--coverage]` ou `pnpm jest`
- **Supertest + Vitest:** `npx vitest [run] {{test-file}}` ou `pnpm vitest`
- **Pact:** `npx pact-provider-verifier` ou `pnpm pact:verify`
- **Postman:** `npx newman run {{collection}}.json` ou `pnpm postman:test`
- **Wiremock:** `java -jar wiremock.jar --port 8080` (setup) + testes

**Construir comando:** Base + flags específicas + execução

**Executar:** `Bash [comando]` e capturar: resultados (pass/fail), contratos validados, erros, tempo

### Passo 7: Apresentar Resultados

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ TESTES DE INTEGRAÇÃO - {{api-endpoint}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Detecção: framework [..] · config [..] · runner [jest|vitest|mocha] · mock [wiremock|nock|msw]
📊 API/Service: tipo [REST|GraphQL|Service] · endpoints [N] · contratos [Sim/Não] · deps externas [lista]
📝 Arquivo: [✅ Existente|✅ Gerado|❌] {{test-file-path}} → contract [N] · boundary [N] · fuzzing [N]
🧪 Execução: [✅|❌|⚠️] [X/Y] passaram · contratos [X/Y] · tempo [X]s

📊 Resultados:
∟ Contract [X/Y] ✅  — schemas/contratos validados: [lista]
∟ Boundary [X/Y] ✅  — timeouts [N] · erros tratados [N]
∟ Fuzzing  [X/Y] ✅  — inputs malformados [N] · edge cases [N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Próximos: revisar/expandir casos · re-executar `--run` · `--contract` · /validate/test-strategy/create
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 📋 Exemplos de Uso

**1. Gerar e executar com contract testing:**
```bash
/test/integration /api/users --generate --run --contract
```
→ Detecta framework, analisa API, gera `users.integration.test.js` com contract tests, executa

**2. Apenas gerar testes de boundary:**
```bash
/test/integration payment-service --generate --boundary --framework supertest
```
→ Força Supertest, gera testes de boundary (timeouts, erros), não executa

**3. Executar com fuzzing:**
```bash
/test/integration /api/orders --run --fuzz
```
→ Executa `orders.integration.test.js` existente com fuzzing habilitado

**4. Gerar testes completos (contract + boundary + fuzzing):**
```bash
/test/integration user-service --generate --contract --boundary --fuzz
```
→ Gera suite completa de testes de integração

**5. Executar teste existente sem mockar externos:**
```bash
/test/integration /api/products --run --mock-external false
```
→ Executa contra serviços reais (útil para staging)

## ⚙️ Parâmetros Detalhados

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `api-endpoint` | string | ✅ | Endpoint da API ou nome do serviço |
| `--generate` | flag | ❌ | Gera arquivo de teste se não existir |
| `--run` | flag | ❌ | Executa os testes após gerar/validar |
| `--contract` | flag | ❌ | Foca em contract testing (schemas) |
| `--boundary` | flag | ❌ | Foca em boundary testing (timeouts, erros) |
| `--fuzz` | flag | ❌ | Inclui fuzzing de API (dados malformados) |
| `--framework` | string | ❌ | Framework específico (sobrescreve auto-detecção) |
| `--mock-external` | boolean | ❌ | Mocka serviços externos (default: true) |

## 🔗 Comandos Relacionados

- `/test/unit` - Testes unitários (White-box)
- `/test/e2e` - Testes end-to-end (Black-box)
- `/validate/test-strategy/create` - Criar estratégia completa de testes
- `/engineer/work` - Continuar desenvolvimento com testes

## ⚠️ Validações e Regras

**Validações obrigatórias:**
- `api-endpoint` vazio → ❌ ERRO (obrigatório)
- Nenhum framework detectado E `--framework` ausente → ❌ ERRO (💡 instale ou use `--framework`)
- `--run` E arquivo inexistente E `--generate` ausente → ❌ ERRO (💡 use `--generate`)

**Regras de negócio:**
- `--framework` sobrescreve a auto-detecção; senão, auto-detecção tem prioridade
- Geração segue padrões do projeto e a perspectiva Grey-box (dev testando outro dev)
- Mock externo é default (`true`) para isolamento; `--mock-external false` testa serviços reais
- Significado de contract / boundary / fuzzing: ver KB Framework de Testes (referenciada no topo)

## 🔧 Suporte por Framework

| Framework | Contract | Boundary | Fuzzing | Mock Strategy |
|-----------|----------|----------|---------|---------------|
| Supertest | ✅ | ✅ | ✅ | Nock, MSW |
| Pact | ✅ | ⚠️ | ❌ | Pact Mock Service |
| Postman | ✅ | ✅ | ⚠️ | Postman Mock Server |
| Wiremock | ⚠️ | ✅ | ⚠️ | Wiremock |
| Jest/Vitest | ✅ | ✅ | ✅ | Jest/Vitest mocks |

## 📚 Referências

- **Framework de Testes (teoria/padrões Grey-box):** `docs/knowledge-base/frameworks/framework-testes.md`
- **Agentes:** @test-engineer, @test-agent
- **Docs:** [Supertest](https://github.com/visionmedia/supertest) · [Pact](https://docs.pact.io) · [Wiremock](https://wiremock.org)

## ⚠️ Notas Importantes

- **Geração conservadora:** cria testes básicos; o desenvolvedor expande
- **Contract testing:** mira 100% de coverage de contratos (conforme métricas Grey-box da KB)
- **Fuzzing:** opcional via `--fuzz`; testes gerados seguem padrões do projeto

---

**Versão:** 3.0.0  
**Última atualização:** 2025-12-03  
**Mantido por:** Sistema Onion

