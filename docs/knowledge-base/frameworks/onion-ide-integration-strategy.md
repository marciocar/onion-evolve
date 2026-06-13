---
status: historical
replaced-by: docs/analysis/onion-review-2026-05.md
---

# Sistema Onion - Estratégia de Integração com IDEs

> ⚠️ **AVISO — DOCUMENTO HISTÓRICO**
>
> Este documento descreve uma estratégia **multi-IDE abandonada em 2026-05-18**. O Sistema Onion roda **exclusivamente no Claude Code**, e a pasta `.claude/` permanece a estrutura **canônica** do framework. A estrutura agnóstica `.onion/` discutida aqui não foi adotada.
>
> O conteúdo abaixo é mantido apenas como **registro histórico** das discussões originais. Para o estado atual e as decisões vigentes, consulte [docs/analysis/onion-review-2026-05.md](../../analysis/onion-review-2026-05.md).

> **Versão**: 1.0.0 | **Última atualização**: 2025-12-20 | **Categoria**: Frameworks  
> Como diferentes IDEs (Claude Code, Claude Code, Windsurf) descobrem e carregam recursos do `.onion/`

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2025-12-20 |
| **Última Atualização** | 2025-12-20 |
| **Categoria** | Frameworks |
| **Aplicação** | IDE Integration Strategy |
| **Status** | Histórico (estratégia abandonada em 2026-05-18) |

---

## 🎯 O Problema

### Questão Crítica

**Como IDEs diferentes (Claude Code, Claude Code, Windsurf) vão encontrar e carregar os recursos (knowledge bases, agentes, comandos, regras) da pasta `.onion/`?**

### O Desafio

Cada IDE tem seu próprio mecanismo de descoberta:

| IDE | Estrutura Esperada |
|-----|-------------------|
| **Claude Code** | `.claude/commands/`, `.claude/agents/`, `.claude/rules/` |
| **Claude Code** | Desconhecido (provavelmente `.claude/` ou similar) |
| **Windsurf** | Desconhecido (provavelmente `.windsurf/` ou similar) |
| **Outros** | Cada um com sua convenção |

**Problema**: Se movermos tudo para `.onion/`, os IDEs não vão encontrar automaticamente.

---

## 🔍 Análise de Opções

### Opção 1: Symlinks (Links Simbólicos)

**Conceito**: `.claude/`, `.claude/`, `.windsurf/` são symlinks para `.onion/`

```bash
# Estrutura no disco
.onion/                          # 📁 Real - fonte única da verdade
├── core/
│   ├── knowledge-base/
│   ├── agents/
│   ├── commands/
│   ├── rules/
│   └── utils/
└── contexts/

.claude/                         # 🔗 Symlink → .onion/
.claude/                         # 🔗 Symlink → .onion/
.windsurf/                       # 🔗 Symlink → .onion/
```

#### ✅ Vantagens

- ✅ **Transparente**: IDEs não precisam saber que estão usando `.onion/`
- ✅ **Zero configuração**: Funciona imediatamente
- ✅ **Compatibilidade total**: IDEs usam seus paths nativos
- ✅ **Única fonte da verdade**: Edições em qualquer IDE atualizam `.onion/`

#### ❌ Desvantagens

- ❌ **Windows**: Symlinks requerem permissões admin ou Developer Mode
- ❌ **Git**: Pode causar confusão (committar symlinks ou não?)
- ❌ **Descoberta**: Não é óbvio que `.claude/` é symlink
- ❌ **Flexibilidade**: Não permite customização por IDE

#### 🔧 Implementação

```bash
# Script de setup
#!/bin/bash
# setup-onion.sh

# Criar estrutura .onion/
mkdir -p .onion/core/{knowbase,agents,commands,rules,utils}
mkdir -p .onion/contexts/{business,technical,customer-success,compliance}

# Criar symlinks para cada IDE
ln -s .onion/ .claude
ln -s .onion/ .claude
ln -s .onion/ .windsurf

# Adicionar ao .gitignore
echo ".claude" >> .gitignore
echo ".claude" >> .gitignore
echo ".windsurf" >> .gitignore

# Commitar apenas .onion/
git add .onion/
```

**Uso**:
```bash
curl -fsSL https://onion.dev/setup.sh | bash
# ou
npx @onion/cli init
```

---

### Opção 2: Arquivo de Configuração

**Conceito**: Cada IDE lê `.onion-config.yml` que mapeia onde estão os recursos

```yaml
# .onion-config.yml (raiz do projeto)
onion:
  version: "3.0.0"
  root: ".onion"
  
  # Mapeamento de recursos
  resources:
    knowbase: "${root}/core/knowbase"
    agents: "${root}/core/agents"
    commands: "${root}/core/commands"
    rules: "${root}/core/rules"
    utils: "${root}/core/utils"
    contexts: "${root}/contexts"
  
  # Configuração por IDE (opcional)
  ide_configs:
    claude-code:
      config_file: ".claude/settings.json"
      cache_dir: ".claude/.cache"
    
    claude:
      config_file: ".claude/config.json"
      cache_dir: ".claude/.cache"
    
    windsurf:
      config_file: ".windsurf/settings.json"
      cache_dir: ".windsurf/.cache"
```

#### ✅ Vantagens

- ✅ **Flexibilidade**: Cada projeto pode customizar estrutura
- ✅ **Explícito**: Fica claro onde estão os recursos
- ✅ **Portátil**: Funciona em qualquer OS (Windows, Linux, Mac)
- ✅ **Versionável**: `.onion-config.yml` no Git
- ✅ **Customização por IDE**: Cada IDE pode ter configs específicas

#### ❌ Desvantagens

- ❌ **Requer suporte dos IDEs**: Claude Code, Claude, Windsurf precisam ler este arquivo
- ❌ **Setup manual**: Usuário precisa criar arquivo
- ❌ **Curva de aprendizado**: Mais um arquivo para entender

#### 🔧 Implementação

**No IDE (exemplo Claude Code)**:

```typescript
// claude-code-onion-loader.ts
import yaml from 'yaml';
import fs from 'fs';
import path from 'path';

interface OnionConfig {
  onion: {
    version: string;
    root: string;
    resources: {
      knowbase: string;
      agents: string;
      commands: string;
      rules: string;
      utils: string;
      contexts: string;
    };
  };
}

export class OnionLoader {
  private config: OnionConfig | null = null;
  private projectRoot: string;

  constructor(projectRoot: string) {
    this.projectRoot = projectRoot;
    this.loadConfig();
  }

  private loadConfig(): void {
    const configPath = path.join(this.projectRoot, '.onion-config.yml');
    
    if (!fs.existsSync(configPath)) {
      // Fallback para estrutura legacy
      this.config = this.getLegacyConfig();
      return;
    }

    const configFile = fs.readFileSync(configPath, 'utf-8');
    this.config = yaml.parse(configFile);
  }

  private getLegacyConfig(): OnionConfig {
    // Se não existe .onion-config.yml, usa estrutura legacy (.claude/)
    return {
      onion: {
        version: "legacy",
        root: ".claude",
        resources: {
          knowbase: ".claude/knowbase",
          agents: ".claude/agents",
          commands: ".claude/commands",
          rules: ".claude/rules",
          utils: ".claude/utils",
          contexts: ".claude/contexts",
        }
      }
    };
  }

  public getKnowbasePath(): string {
    return this.resolvePath(this.config!.onion.resources.knowbase);
  }

  public getAgentsPath(): string {
    return this.resolvePath(this.config!.onion.resources.agents);
  }

  public getCommandsPath(): string {
    return this.resolvePath(this.config!.onion.resources.commands);
  }

  public getRulesPath(): string {
    return this.resolvePath(this.config!.onion.resources.rules);
  }

  public getUtilsPath(): string {
    return this.resolvePath(this.config!.onion.resources.utils);
  }

  public getContextsPath(): string {
    return this.resolvePath(this.config!.onion.resources.contexts);
  }

  private resolvePath(relativePath: string): string {
    // Resolve variáveis como ${root}
    const resolved = relativePath.replace('${root}', this.config!.onion.root);
    return path.join(this.projectRoot, resolved);
  }

  // Carregar todos os comandos
  public loadCommands(): Command[] {
    const commandsPath = this.getCommandsPath();
    // ... lógica de carregamento
  }

  // Carregar todos os agentes
  public loadAgents(): Agent[] {
    const agentsPath = this.getAgentsPath();
    // ... lógica de carregamento
  }
}

// Uso no Claude Code
const loader = new OnionLoader(workspaceRoot);
const commands = loader.loadCommands();
const agents = loader.loadAgents();
```

**Retrocompatibilidade**:
- Se `.onion-config.yml` não existe → usa `.claude/` (legacy)
- Se existe → usa paths configurados
- **Migração gradual sem breaking changes**

---

### Opção 3: Convention Over Configuration

**Conceito**: `.onion/` vira o padrão da indústria. IDEs precisam suportá-la.

```bash
# Estrutura padrão universal
.onion/                          # 🌐 Convenção universal
├── core/
│   ├── knowledge-base/
│   ├── agents/
│   ├── commands/
│   ├── rules/
│   └── utils/
└── contexts/

# IDEs NÃO usam .claude/, .claude/, etc
# TODOS usam .onion/ diretamente
```

#### ✅ Vantagens

- ✅ **Simplicidade máxima**: Uma única convenção
- ✅ **Portabilidade perfeita**: Funciona em qualquer IDE (se suportarem)
- ✅ **Futuro-proof**: Novos IDEs já sabem onde procurar
- ✅ **Zero configuração**: Não precisa de nada além de `.onion/`

#### ❌ Desvantagens

- ❌ **Adoção**: Requer que IDEs adotem a convenção
- ❌ **Tempo**: Pode levar meses/anos para adoção ampla
- ❌ **Incompatibilidade**: IDEs legados não funcionam
- ❌ **Especificação**: Precisa de spec formal (RFC, documentação oficial)

#### 🔧 Implementação

**Especificação Onion Format (RFC)**:

```markdown
# Onion Directory Format v1.0

## Objetivo
Padronizar estrutura de comandos, agentes, e conhecimento para IDEs com IA.

## Estrutura Obrigatória

.onion/
├── core/                        # OBRIGATÓRIO
│   ├── knowledge-base/                # OBRIGATÓRIO
│   ├── agents/                  # OBRIGATÓRIO
│   ├── commands/                # OBRIGATÓRIO
│   └── rules/                   # OPCIONAL
└── contexts/                    # OPCIONAL

## Formato de Arquivo

### Comandos (.onion/core/commands/)
- Extensão: `.md`
- Header: YAML frontmatter
- Corpo: Markdown

### Agentes (.onion/core/agents/)
- Extensão: `.md`
- Header: YAML frontmatter
- Corpo: Markdown

### Knowledge Base (.onion/core/knowledge-base/)
- Extensão: `.md`
- Estrutura livre

## Descoberta

IDEs compatíveis DEVEM:
1. Verificar existência de `.onion/` na raiz do projeto
2. Carregar comandos de `.onion/core/commands/` recursivamente
3. Carregar agentes de `.onion/core/agents/` recursivamente
4. Indexar knowledge base de `.onion/core/knowledge-base/` recursivamente

## Retrocompatibilidade

IDEs PODEM manter suporte a estruturas legadas (.claude/, .claude/) mas DEVEM priorizar .onion/ se existir.
```

**Proposta para IDEs**:
- Submeter PR para Claude Code: adicionar suporte a `.onion/`
- Contatar equipes Claude, Windsurf
- Criar issue/discussion em repositórios oficiais

---

### Opção 4: Híbrido (Fonte + Loaders)

**Conceito**: `.onion/` é fonte única, cada IDE tem loader/adapter

```bash
# Estrutura no disco
.onion/                          # 📁 Fonte única da verdade
├── core/
│   ├── knowledge-base/
│   ├── agents/
│   ├── commands/
│   ├── rules/
│   └── utils/
└── contexts/

.claude/                         # 🔌 Loader Claude Code
├── onion-loader.js              # Script que lê .onion/
└── settings.json                # Config: { "onion_root": ".onion" }

.claude/                         # 🔌 Loader Claude
├── onion-adapter.py             # Script que lê .onion/
└── config.json                  # Config: { "onion_root": ".onion" }

.windsurf/                       # 🔌 Loader Windsurf
├── onion-bridge.ts              # Script que lê .onion/
└── settings.yml                 # Config: onion_root: .onion
```

#### ✅ Vantagens

- ✅ **Flexibilidade máxima**: Cada IDE pode ter lógica customizada
- ✅ **Compatibilidade**: Funciona com IDEs atuais
- ✅ **Customização**: Cada IDE pode filtrar/transformar recursos
- ✅ **Gradual**: Implementar IDE por IDE

#### ❌ Desvantagens

- ❌ **Manutenção**: Precisa manter loader para cada IDE
- ❌ **Complexidade**: Mais moving parts
- ❌ **Consistência**: Loaders podem divergir

#### 🔧 Implementação

**Loader para Claude Code**:

```javascript
// .claude/onion-loader.js
const fs = require('fs');
const path = require('path');
const yaml = require('yaml');

class ClaudeCodeOnionLoader {
  constructor() {
    this.onionRoot = '.onion';
    this.cache = new Map();
  }

  // Carregar todos os comandos
  loadCommands() {
    const commandsPath = path.join(this.onionRoot, 'core/commands');
    return this.loadMarkdownFiles(commandsPath, 'command');
  }

  // Carregar todos os agentes
  loadAgents() {
    const agentsPath = path.join(this.onionRoot, 'core/agents');
    return this.loadMarkdownFiles(agentsPath, 'agent');
  }

  // Carregar knowledge base
  loadKnowbase() {
    const kbPath = path.join(this.onionRoot, 'core/knowbase');
    return this.indexMarkdownFiles(kbPath);
  }

  // Carregar contextos disponíveis
  loadContexts() {
    const contextsPath = path.join(this.onionRoot, 'contexts');
    if (!fs.existsSync(contextsPath)) return [];
    
    return fs.readdirSync(contextsPath, { withFileTypes: true })
      .filter(dirent => dirent.isDirectory())
      .map(dirent => {
        const contextConfig = path.join(contextsPath, dirent.name, '.context-config.yml');
        if (fs.existsSync(contextConfig)) {
          return {
            name: dirent.name,
            config: yaml.parse(fs.readFileSync(contextConfig, 'utf-8'))
          };
        }
        return { name: dirent.name, config: {} };
      });
  }

  // Helper: carregar arquivos markdown recursivamente
  loadMarkdownFiles(dir, type) {
    const files = [];
    
    function traverse(currentDir) {
      const entries = fs.readdirSync(currentDir, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(currentDir, entry.name);
        
        if (entry.isDirectory()) {
          traverse(fullPath);
        } else if (entry.name.endsWith('.md')) {
          const content = fs.readFileSync(fullPath, 'utf-8');
          const parsed = parseMarkdownWithYAML(content);
          files.push({
            type,
            path: fullPath,
            name: entry.name.replace('.md', ''),
            metadata: parsed.yaml,
            content: parsed.markdown
          });
        }
      }
    }
    
    traverse(dir);
    return files;
  }

  // Helper: indexar knowledge base para busca
  indexMarkdownFiles(dir) {
    const index = {};
    
    function traverse(currentDir, relativePath = '') {
      const entries = fs.readdirSync(currentDir, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(currentDir, entry.name);
        const relPath = path.join(relativePath, entry.name);
        
        if (entry.isDirectory()) {
          traverse(fullPath, relPath);
        } else if (entry.name.endsWith('.md')) {
          const content = fs.readFileSync(fullPath, 'utf-8');
          index[relPath] = {
            path: fullPath,
            relativePath: relPath,
            content,
            // Extrair títulos, tags, etc para busca
            metadata: extractMetadata(content)
          };
        }
      }
    }
    
    traverse(dir);
    return index;
  }
}

// Helper para parsear YAML frontmatter
function parseMarkdownWithYAML(content) {
  const yamlRegex = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/;
  const match = content.match(yamlRegex);
  
  if (match) {
    return {
      yaml: yaml.parse(match[1]),
      markdown: match[2]
    };
  }
  
  return {
    yaml: {},
    markdown: content
  };
}

// Extrair metadata para indexação
function extractMetadata(content) {
  const lines = content.split('\n');
  const metadata = {
    title: null,
    headings: [],
    tags: []
  };
  
  for (const line of lines) {
    // Título H1
    if (line.startsWith('# ') && !metadata.title) {
      metadata.title = line.substring(2);
    }
    // Headings
    if (line.match(/^#{1,6} /)) {
      metadata.headings.push(line);
    }
    // Tags (exemplo: #tag)
    const tagMatches = line.match(/#[\w-]+/g);
    if (tagMatches) {
      metadata.tags.push(...tagMatches);
    }
  }
  
  return metadata;
}

// Exportar singleton
module.exports = new ClaudeCodeOnionLoader();
```

**Integração no Claude Code**:

```javascript
// No código do Claude Code
const onionLoader = require('./.claude/onion-loader.js');

// Quando Claude Code inicia
const commands = onionLoader.loadCommands();
const agents = onionLoader.loadAgents();
const knowbase = onionLoader.loadKnowbase();
const contexts = onionLoader.loadContexts();

// Registrar comandos
commands.forEach(cmd => {
  registerCommand(`/${cmd.metadata.name}`, cmd);
});

// Registrar agentes
agents.forEach(agent => {
  registerAgent(`@${agent.metadata.name}`, agent);
});

// Indexar knowledge base para busca semântica
indexKnowbase(knowbase);

// Disponibilizar contextos
registerContexts(contexts);
```

**Adapter para Claude Code**:

```python
# .claude/onion_adapter.py
import os
import yaml
from pathlib import Path
from typing import Dict, List, Any

class ClaudeOnionAdapter:
    def __init__(self, onion_root: str = '.onion'):
        self.onion_root = Path(onion_root)
        self.cache = {}
    
    def load_commands(self) -> List[Dict[str, Any]]:
        """Carregar todos os comandos"""
        commands_path = self.onion_root / 'core' / 'commands'
        return self._load_markdown_files(commands_path, 'command')
    
    def load_agents(self) -> List[Dict[str, Any]]:
        """Carregar todos os agentes"""
        agents_path = self.onion_root / 'core' / 'agents'
        return self._load_markdown_files(agents_path, 'agent')
    
    def load_knowbase(self) -> Dict[str, Any]:
        """Carregar e indexar knowledge base"""
        kb_path = self.onion_root / 'core' / 'knowbase'
        return self._index_markdown_files(kb_path)
    
    def load_contexts(self) -> List[Dict[str, Any]]:
        """Carregar contextos disponíveis"""
        contexts_path = self.onion_root / 'contexts'
        if not contexts_path.exists():
            return []
        
        contexts = []
        for context_dir in contexts_path.iterdir():
            if not context_dir.is_dir():
                continue
            
            config_file = context_dir / '.context-config.yml'
            config = {}
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config = yaml.safe_load(f)
            
            contexts.append({
                'name': context_dir.name,
                'config': config
            })
        
        return contexts
    
    def _load_markdown_files(self, directory: Path, file_type: str) -> List[Dict[str, Any]]:
        """Carregar arquivos markdown recursivamente"""
        files = []
        
        for md_file in directory.rglob('*.md'):
            with open(md_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            parsed = self._parse_markdown_with_yaml(content)
            files.append({
                'type': file_type,
                'path': str(md_file),
                'name': md_file.stem,
                'metadata': parsed['yaml'],
                'content': parsed['markdown']
            })
        
        return files
    
    def _index_markdown_files(self, directory: Path) -> Dict[str, Any]:
        """Indexar knowledge base para busca"""
        index = {}
        
        for md_file in directory.rglob('*.md'):
            with open(md_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            rel_path = md_file.relative_to(directory)
            index[str(rel_path)] = {
                'path': str(md_file),
                'relative_path': str(rel_path),
                'content': content,
                'metadata': self._extract_metadata(content)
            }
        
        return index
    
    def _parse_markdown_with_yaml(self, content: str) -> Dict[str, Any]:
        """Parsear YAML frontmatter"""
        import re
        
        yaml_pattern = r'^---\n(.*?)\n---\n(.*)$'
        match = re.match(yaml_pattern, content, re.DOTALL)
        
        if match:
            return {
                'yaml': yaml.safe_load(match.group(1)),
                'markdown': match.group(2)
            }
        
        return {
            'yaml': {},
            'markdown': content
        }
    
    def _extract_metadata(self, content: str) -> Dict[str, Any]:
        """Extrair metadata para indexação"""
        lines = content.split('\n')
        metadata = {
            'title': None,
            'headings': [],
            'tags': []
        }
        
        for line in lines:
            # Título H1
            if line.startswith('# ') and not metadata['title']:
                metadata['title'] = line[2:]
            
            # Headings
            if line.startswith('#'):
                metadata['headings'].append(line)
            
            # Tags
            import re
            tags = re.findall(r'#[\w-]+', line)
            if tags:
                metadata['tags'].extend(tags)
        
        return metadata

# Exportar singleton
onion_adapter = ClaudeOnionAdapter()
```

---

## 🎯 RECOMENDAÇÃO

### Estratégia Híbrida em 3 Fases

**Combinar opções para máxima compatibilidade e futuro-proof.**

#### FASE 1: Híbrido (Opção 4) - IMEDIATO

**Implementar agora para funcionar com IDEs atuais**:

```bash
.onion/                    # ✅ Fonte única da verdade
├── core/
│   ├── knowledge-base/         # 📚 Corrigido (não "kb")
│   ├── agents/
│   ├── commands/
│   ├── rules/
│   └── utils/
└── contexts/

.claude/                  # 🔌 Loader para Claude Code
├── onion-loader.js
└── settings.json

.claude/                  # 🔌 Loader para Claude (futuro)
└── onion-adapter.py

.windsurf/                # 🔌 Loader para Windsurf (futuro)
└── onion-bridge.ts
```

**Benefícios**:
- ✅ Funciona AGORA com Claude Code
- ✅ Preparado para Claude, Windsurf
- ✅ Sem breaking changes

**Implementação**:
1. Migrar `.claude/` → `.onion/`
2. Criar `.claude/onion-loader.js`
3. Atualizar `.claude/settings.json`:
   ```json
   {
     "onion": {
       "enabled": true,
       "root": ".onion",
       "loader": ".claude/onion-loader.js"
     }
   }
   ```

#### FASE 2: Config File (Opção 2) - PRÓXIMOS MESES

**Adicionar `.onion-config.yml` para flexibilidade**:

```yaml
# .onion-config.yml
onion:
  version: "3.0.0"
  root: ".onion"
  
  resources:
    knowbase: "${root}/core/knowbase"
    agents: "${root}/core/agents"
    commands: "${root}/core/commands"
    rules: "${root}/core/rules"
    utils: "${root}/core/utils"
    contexts: "${root}/contexts"
```

**Benefícios**:
- ✅ Documentação explícita
- ✅ Customização por projeto
- ✅ Retrocompatibilidade (loaders leem config)

#### FASE 3: Convention (Opção 3) - LONGO PRAZO

**Propor `.onion/` como padrão da indústria**:

1. **Criar RFC** (Request for Comments)
   - Especificação formal do Onion Directory Format
   - Publicar em onion.dev

2. **Propor para IDEs**:
   - PR para Claude Code: adicionar suporte nativo a `.onion/`
   - Contatar equipes Claude, Windsurf
   - Issue/discussion em repositórios oficiais

3. **Depreciar loaders gradualmente**:
   - Quando IDEs suportarem `.onion/` nativamente
   - Loaders continuam funcionando (retrocompatibilidade)
   - Documentação indica preferência por suporte nativo

---

## 📋 CORREÇÕES NO DOCUMENTO ANTERIOR

### 1. Nomenclatura: `knowbase` (não `kb`)

Todos os paths devem usar `knowbase`:

```diff
.onion/
├── core/
-│   ├── kb/                  # ❌ INCORRETO
+│   ├── knowledge-base/            # ✅ CORRETO
│   ├── agents/
│   ├── commands/
│   ├── rules/
│   └── utils/
└── contexts/
    ├── business/
-    │   ├── kb/             # ❌ INCORRETO
+    │   ├── knowledge-base/       # ✅ CORRETO
    │   ├── agents/
    │   └── commands/
    └── technical/
-        ├── kb/             # ❌ INCORRETO
+        ├── knowledge-base/       # ✅ CORRETO
        ├── agents/
        └── commands/
```

**Justificativa**: 
- ✅ Consistente com `docs/knowledge-base/` existente
- ✅ Mais claro que "kb" (abreviação ambígua)
- ✅ Self-documenting

### 2. Discovery Mechanism

Adicionar seção explícita no documento anterior:

```markdown
## 🔍 Como IDEs Descobrem Recursos

### Claude Code
1. Verificar `.claude/settings.json` → ler `onion.loader`
2. Executar `.claude/onion-loader.js`
3. Loader lê `.onion/` e carrega recursos
4. Registra comandos, agentes, knowledge base

### Claude Code (futuro)
1. Verificar `.claude/config.json` → ler `onion.adapter`
2. Executar `.claude/onion-adapter.py`
3. Adapter lê `.onion/` e carrega recursos

### Windsurf (futuro)
1. Verificar `.windsurf/settings.yml` → ler `onion.bridge`
2. Executar `.windsurf/onion-bridge.ts`
3. Bridge lê `.onion/` e carrega recursos
```

---

## 🚀 PRÓXIMOS PASSOS PRÁTICOS

### Passo 1: Criar Loader para Claude Code (URGENTE)

```bash
# Criar loader
touch .claude/onion-loader.js

# Implementar (código fornecido acima)
# Testar:
node .claude/onion-loader.js
```

### Passo 2: Migrar para `.onion/` (CRÍTICO)

```bash
# Script de migração
/meta/migrate-to-onion

# O que faz:
# 1. Criar estrutura .onion/
# 2. Mover .claude/ → .onion/ (preservar histórico git)
# 3. Criar .claude/onion-loader.js
# 4. Atualizar .claude/settings.json
# 5. Testar tudo funciona
# 6. Commitar
```

### Passo 3: Documentar (IMPORTANTE)

```bash
# Atualizar documentação
docs/onion/ide-integration.md   # Este documento
docs/onion/getting-started.md   # Atualizar paths
README.md                         # Atualizar estrutura
```

### Passo 4: Criar `.onion-config.yml` Template (ESTRATÉGICO)

```bash
# Template
.onion-config.yml.example
```

---

## 💬 QUESTÕES PARA DISCUSSÃO

1. **Estratégia Híbrida faz sentido?**
   - Fase 1 (loaders) → Fase 2 (config) → Fase 3 (convention)

2. **Prioridade de loaders?**
   - Claude Code agora, Claude/Windsurf depois?

3. **RFC do Onion Format?**
   - Vale a pena especificar formalmente?

4. **Nomenclatura `knowbase` confirmada?**
   - Ou prefere `knowledge-base`, `kb`, outro?

5. **Retrocompatibilidade?**
   - Manter `.claude/` como symlink temporariamente?

---

**Última atualização**: 2025-12-20  
**Versão**: 1.0.0  
**Mantido por**: Estratégia de Integração IDE  
**Status**: Para Discussão

---

## 📚 Documentos Relacionados

- [Entendimento Completo do Ciclo](./onion-complete-cycle-understanding.md)
- [Visão Multi-Context Orchestrator](./onion-multi-context-orchestrator-vision.md)
- [Análise Crítica Original](./onion-system-critical-analysis-2025.md)

