---
name: unit
description: |
  Gera e executa testes unitários automaticamente com detecção de framework.
  Use para criar testes seguindo padrões do projeto e executá-los com coverage.
model: sonnet
allowed-tools: Read Write Bash(find *) Bash(ls *) Bash(npm *) Bash(pnpm *) Bash(pytest *) Bash(go *) Bash(cargo *) Bash(mvn *)

parameters:
  - name: file-path
    description: Caminho do arquivo fonte para testar (obrigatório)
    required: true
  - name: --generate
    description: Gera arquivo de teste se não existir
    required: false
  - name: --run
    description: Executa os testes após gerar/validar
    required: false
  - name: --coverage
    description: Inclui relatório de coverage na execução
    required: false
  - name: --watch
    description: Modo watch para re-execução automática
    required: false
  - name: --framework
    description: 'Framework específico (sobrescreve auto-detecção: jest|vitest|pytest|junit)'
    required: false

category: test
tags:
  - testing
  - unit-tests
  - test-generation
  - code-quality
  - automation
  - coverage

version: "3.0.0"
updated: "2025-11-24"

related_commands:
  - /test/integration
  - /test/e2e
  - /validate/test-strategy/create
  - /engineer/work
  - /git/code-review

related_agents:
  - test-engineer
  - test-planner
---

# 🧪 Test Unit

Gera e executa testes unitários automaticamente com detecção inteligente de framework, análise de código e integração com ferramentas de coverage.

## 🎯 Objetivo

Automatizar o ciclo completo de testes unitários:
- **Auto-detecção** de framework de teste baseado em configurações do projeto
- **Análise de código** para identificar funções/métodos públicos testáveis
- **Geração automática** de arquivos de teste seguindo padrões do projeto
- **Execução inteligente** com suporte a coverage e watch mode
- **Integração** com pipeline de testes existente

## ⚡ Fluxo de Execução

### Passo 1: Validar Arquivo Fonte

```bash
# Verificar se arquivo existe
if [ ! -f "{{file-path}}" ]; then
  echo "❌ ERRO: Arquivo não encontrado: {{file-path}}"
  exit 1
fi

# Extrair informações do arquivo
- Extensão: .js, .ts, .tsx, .py, .java, etc.
- Diretório base
- Nome do arquivo (sem extensão)
```

**Validações:**
```markdown
SE arquivo não existe:
  ❌ ERRO: Arquivo não encontrado: {{file-path}}
  💡 Verifique o caminho e tente novamente

SE arquivo não é código fonte suportado:
  ⚠️ AVISO: Tipo de arquivo pode não ser suportado
  Tipos suportados: .js, .ts, .tsx, .jsx, .py, .java, .go, .rs
```

### Passo 2: Detectar Framework de Teste

**Estratégia de Detecção (em ordem de prioridade):**

1. **Verificar configurações:** `package.json` (Jest/Vitest), `pytest.ini` (PyTest), `pom.xml`/`build.gradle` (JUnit), `go.mod` (Go), `Cargo.toml` (Rust)
2. **Buscar arquivos de teste existentes:** `**/*.test.{js,ts}`, `**/test_*.py`, `**/*_test.go`, `**/*Test.java`
3. **Inferir por linguagem:** Jest/Vitest (JS/TS), PyTest (Python), JUnit (Java), testing (Go), cargo test (Rust)

**Output:**
```markdown
✅ Framework: [jest|vitest|pytest|junit|go-test|rust-test]
📁 Config: [caminho]
📦 Package manager: [npm|pnpm|yarn|pip|maven|gradle|cargo]
```

**Se `--framework` fornecido:** Sobrescreve detecção automática

### Passo 3: Analisar Código Fonte

**Objetivo:** Identificar funções/métodos públicos que precisam de testes.

#### 3.1 Ler Arquivo Fonte

```bash
Read {{file-path}}
```

#### 3.2 Extrair Funções/Métodos Públicos

**Padrões por linguagem:**
- **JS/TS:** `export function/const/class`, `export default`
- **Python:** `def nome_funcao` (sem `_` inicial), classes públicas
- **Java:** `public methods`, `@Test` annotations
- **Go:** `func NomeFuncao` (maiúscula inicial)
- **Rust:** `pub fn`, `pub struct`, `impl` públicos

#### 3.3 Identificar Dependências Externas

- Imports/requires externos, APIs, arquivos/DB, dependências para mocks

**Output da Análise:**
```markdown
📊 Análise de Código:
∟ Funções públicas encontradas: [N]
∟ Classes encontradas: [N]
∟ Dependências externas: [lista]
∟ Complexidade estimada: [baixa|média|alta]
```

### Passo 4: Verificar Arquivo de Teste Existente

**Padrões de nomenclatura:**
- **Jest/Vitest:** `{{file}}.test.{js,ts,tsx}`
- **PyTest:** `test_{{file}}.py` ou `tests/test_{{file}}.py`
- **JUnit:** `{{Class}}Test.java` em `src/test/`
- **Go:** `{{file}}_test.go`
- **Rust:** `#[cfg(test)]` no mesmo arquivo

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
1. **Ler padrões existentes:** Buscar `**/*.test.{js,ts}`, `**/test_*.py` para extrair estrutura, imports, nomenclatura
2. **Gerar testes base:** Padrão AAA (Arrange, Act, Assert) para cada função pública:
   - Happy path: entrada válida → saída esperada
   - Edge cases: null, vazios, limites
   - Error handling: entradas inválidas → exceções
3. **Configurar mocks:** Para dependências externas (Jest: `jest.mock()`, Vitest: `vi.mock()`)
4. **Criar arquivo:** `write {{test-file-path}}`

**Exemplo estrutura (Jest/Vitest):**
```typescript
describe('nomeFuncao', () => {
  test('should return expected result with valid input', () => {
    const result = nomeFuncao('valid input')
    expect(result).toBe('expected output')
  })
  test('should handle edge case', () => {
    expect(() => nomeFuncao(null)).toThrow()
  })
})
```

**Validação:** ✅ Arquivo gerado: {{test-file-path}}, [N] testes (happy path: X, edge: Y, errors: Z)

### Passo 6: Executar Testes (SE --run)

**Comandos por framework:**

- **Jest:** `npx jest {{test-file}} [--coverage] [--watch]` ou `pnpm jest`
- **Vitest:** `npx vitest [run] {{test-file}} [--coverage]` ou `pnpm vitest`
- **PyTest:** `pytest {{test-file}} [--cov={{dir}} --cov-report=html]` ou `ptw` (watch)
- **JUnit:** `mvn test -Dtest={{Class}}` ou `./gradlew test --tests {{Class}}`
- **Go:** `go test ./{{pkg}} [-v] [-cover]`
- **Rust:** `cargo test {{name}}`

**Construir comando:** Base + `--coverage` (se flag) + `--watch` (se flag) + execução única (se não watch)

**Executar:** `Bash [comando]` e capturar: resultados (pass/fail), coverage (se aplicável), erros, tempo

### Passo 7: Apresentar Resultados

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ TESTES UNITÁRIOS - {{file-path}}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Detecção:
∟ Framework: [jest|vitest|pytest|junit|go-test|rust-test]
∟ Config: [caminho do arquivo de config]
∟ Package manager: [npm|pnpm|yarn|pip|maven|gradle|cargo]

📊 Análise de Código:
∟ Arquivo fonte: {{file-path}}
∟ Funções públicas: [N]
∟ Classes: [N]
∟ Dependências externas: [lista]
∟ Complexidade: [baixa|média|alta]

📝 Arquivo de Teste:
∟ Status: [✅ Existente | ✅ Gerado | ❌ Não encontrado]
∟ Caminho: {{test-file-path}}
∟ Testes: [N] casos de teste
  ├─ Happy path: [N]
  ├─ Edge cases: [N]
  └─ Error handling: [N]

🧪 Execução:
∟ Comando: [comando executado]
∟ Status: [✅ Passou | ❌ Falhou | ⚠️ Parcial]
∟ Testes executados: [X/Y] passaram
∟ Tempo: [X]s

📈 Coverage (se --coverage):
∟ Statements: [X]%
∟ Branches: [X]%
∟ Functions: [X]%
∟ Lines: [X]%
∟ Arquivo: [caminho do relatório]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 Próximos Passos:
1. Revisar testes gerados e adicionar casos específicos
2. Executar novamente: /test/unit {{file-path}} --run
3. Integrar no pipeline: /validate/test-strategy/create
4. Code review: /git/code-review

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 📋 Exemplos de Uso

**1. Gerar e executar com coverage:**
```bash
/test/unit src/utils/validation.js --generate --run --coverage
```
→ Detecta framework, analisa código, gera `validation.test.js`, executa com coverage

**2. Apenas gerar teste:**
```bash
/test/unit app/models/user.py --generate --framework pytest
```
→ Força PyTest, gera `test_user.py`, não executa

**3. Executar com watch:**
```bash
/test/unit components/Button.tsx --run --watch
```
→ Detecta framework, executa `Button.test.tsx` em modo watch

**4. Executar teste existente:**
```bash
/test/unit src/services/api.ts --run --coverage
```
→ Encontra `api.test.ts`, executa com coverage, não gera novo arquivo

## ⚙️ Parâmetros Detalhados

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|-------------|-----------|
| `file-path` | string | ✅ | Caminho do arquivo fonte para testar |
| `--generate` | flag | ❌ | Gera arquivo de teste se não existir |
| `--run` | flag | ❌ | Executa os testes após gerar/validar |
| `--coverage` | flag | ❌ | Inclui relatório de coverage |
| `--watch` | flag | ❌ | Modo watch para re-execução automática |
| `--framework` | string | ❌ | Framework específico (sobrescreve auto-detecção) |

## 🔗 Comandos Relacionados

- `/test/integration` - Testes de integração (Grey-box)
- `/test/e2e` - Testes end-to-end (Black-box)
- `/validate/test-strategy/create` - Criar estratégia completa de testes
- `/engineer/work` - Continuar desenvolvimento com testes
- `/git/code-review` - Revisar código incluindo testes

## ⚠️ Validações e Regras

### Validações Obrigatórias

1. **Arquivo fonte deve existir:**
   ```markdown
   SE arquivo não encontrado:
     ❌ ERRO: Arquivo não encontrado: {{file-path}}
   ```

2. **Framework deve ser detectável ou fornecido:**
   ```markdown
   SE nenhum framework detectado E --framework não fornecido:
     ❌ ERRO: Não foi possível detectar framework de teste
     💡 Instale um framework ou use --framework [nome]
   ```

3. **Arquivo de teste deve existir para execução:**
   ```markdown
   SE --run fornecido E arquivo de teste não existe E --generate não fornecido:
     ❌ ERRO: Arquivo de teste não encontrado
     💡 Use --generate para criar automaticamente
   ```

### Regras de Negócio

1. **Auto-detecção tem prioridade** sobre --framework, exceto se --framework fornecido
2. **Geração segue padrões** do projeto (analisa testes existentes)
3. **Coverage requer** framework com suporte (Jest, Vitest, PyTest)
4. **Watch mode** mantém processo rodando até interrupção
5. **Testes gerados** cobrem happy path, edge cases e error handling básicos

## 🔧 Suporte por Linguagem

| Linguagem | Frameworks | Coverage | Watch |
|-----------|-----------|----------|-------|
| JS/TS | Jest, Vitest, Mocha | ✅ | ✅ |
| Python | PyTest, unittest | ✅ | ⚠️ |
| Java | JUnit 5/4 | ✅ | ❌ |
| Go | testing (built-in) | ✅ | ⚠️ |
| Rust | cargo test | ⚠️ | ❌ |

## 📚 Referências

- **Agente de Testes:** @test-engineer
- **Framework de Testes:** `docs/knowledge-base/frameworks/framework-testes.md`
- **Padrões de Teste:** `.claude/agents/testing/test-engineer.md`

## ⚠️ Notas Importantes

- **Auto-detecção inteligente:** Analisa configurações e padrões do projeto
- **Geração conservadora:** Cria testes básicos, desenvolvedor deve expandir
- **Integração com pipeline:** Testes gerados seguem padrões do projeto
- **Coverage opcional:** Requer configuração prévia do framework
- **Watch mode:** Mantém processo ativo, use Ctrl+C para parar

---

**Versão:** 3.0.0  
**Última atualização:** 2025-11-24  
**Mantido por:** Sistema Onion

