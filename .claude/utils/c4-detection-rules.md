# 🔍 C4 Project Detection Rules - Sistema Onion

## 📋 **Detection Algorithm**

Regras para detecção automática de tipos de projeto TypeScript/JavaScript.

---

## 🧠 **Detection Flow**

```
1. Read package.json → Extract dependencies & scripts
2. Check directory structure → Identify patterns  
3. Detect build tools → Framework identification
4. Calculate confidence → Score each possibility
5. Select template → Highest confidence or fallback
```

---

## 📱 **Single Page Application Rules**

### **React SPA Detection**
```yaml
react-spa:
  primary_indicators:
    - "react" in dependencies
    - "react-dom" in dependencies  
    - src/App.tsx OR src/App.jsx exists
    - public/index.html exists
  
  secondary_indicators:
    - src/components/ directory
    - src/pages/ OR src/views/ directory
    - src/hooks/ directory
    - "react-scripts" in dependencies (CRA)
    - "vite" in devDependencies (Vite)
  
  build_tools:
    - webpack.config.js (custom webpack)
    - vite.config.ts (Vite)
    - craco.config.js (CRACO)
  
  confidence_weight: 0.9
```

### **Vue.js SPA Detection**
```yaml
vue-spa:
  primary_indicators:
    - "vue" in dependencies
    - src/App.vue exists
    - src/main.ts OR src/main.js exists
  
  secondary_indicators:
    - src/components/ directory
    - src/views/ directory  
    - src/router/ directory
    - "@vue/cli" in devDependencies
    - "nuxt" in dependencies (if dev mode)
  
  build_tools:
    - vue.config.js
    - vite.config.ts
    - nuxt.config.js
  
  confidence_weight: 0.9
```

### **Angular SPA Detection**
```yaml
angular-spa:
  primary_indicators:
    - "@angular/core" in dependencies
    - angular.json exists
    - src/app/app.module.ts exists
  
  secondary_indicators:
    - src/app/ directory
    - src/environments/ directory
    - "@angular/cli" in devDependencies
    - "ng" in scripts
  
  build_tools:
    - angular.json
    - tsconfig.json (Angular-specific)
  
  confidence_weight: 0.95
```

---

## 🔌 **API Service Rules**

### **Express.js API Detection**
```yaml
express-api:
  primary_indicators:
    - "express" in dependencies
    - server.js OR server.ts OR app.js OR app.ts exists
    - NO "react" OR "vue" OR "@angular" in dependencies
  
  secondary_indicators:
    - routes/ directory
    - controllers/ directory
    - middleware/ directory
    - models/ directory
    - "nodemon" in devDependencies
  
  structure_patterns:
    - app.use() patterns in main file
    - router definitions
    - middleware setup
  
  confidence_weight: 0.85
```

### **NestJS API Detection**
```yaml
nestjs-api:
  primary_indicators:
    - "@nestjs/core" in dependencies
    - "@nestjs/common" in dependencies
    - src/main.ts exists
    - nest-cli.json exists
  
  secondary_indicators:
    - src/modules/ directory
    - src/controllers/ directory
    - src/services/ directory
    - "@nestjs/cli" in devDependencies
    - "nest" in scripts
  
  decorators:
    - @Controller presence
    - @Injectable presence
    - @Module presence
  
  confidence_weight: 0.95
```

### **Fastify API Detection**
```yaml
fastify-api:
  primary_indicators:
    - "fastify" in dependencies
    - server.js OR server.ts OR app.js OR app.ts exists
  
  secondary_indicators:
    - routes/ directory
    - plugins/ directory
    - schemas/ directory
    - fastify.register patterns
  
  confidence_weight: 0.8
```

---

## 🌐 **Full-stack Application Rules**

### **Next.js Detection**
```yaml
nextjs-app:
  primary_indicators:
    - "next" in dependencies
    - next.config.js exists
    - pages/ directory OR app/ directory exists
  
  secondary_indicators:
    - pages/api/ directory (API routes)
    - app/api/ directory (App Router)
    - pages/_app.tsx exists
    - public/ directory
    - "next" in scripts
  
  patterns:
    - getServerSideProps usage
    - getStaticProps usage
    - API route files in pages/api/
  
  confidence_weight: 0.95
```

### **Nuxt.js Detection**
```yaml
nuxtjs-app:
  primary_indicators:
    - "nuxt" in dependencies
    - nuxt.config.js OR nuxt.config.ts exists
    - pages/ directory exists
  
  secondary_indicators:
    - components/ directory
    - server/ directory
    - plugins/ directory
    - middleware/ directory
  
  confidence_weight: 0.9
```

---

## 📦 **Monorepo Rules**

### **NX Monorepo Detection**
```yaml
nx-monorepo:
  primary_indicators:
    - nx.json exists
    - workspace.json OR angular.json exists  
    - apps/ directory exists
    - libs/ directory exists
  
  secondary_indicators:
    - "@nx/" OR "@nrwl/" in dependencies
    - project.json files in subdirectories
    - "nx" in scripts
    - tools/ directory
  
  structure:
    - multiple apps in apps/
    - shared libraries in libs/
    - workspace configuration
  
  confidence_weight: 0.95
```

### **Lerna Monorepo Detection** 
```yaml
lerna-monorepo:
  primary_indicators:
    - lerna.json exists
    - packages/ directory exists
    - "lerna" in devDependencies
  
  secondary_indicators:
    - "lerna" commands in scripts
    - multiple package.json in packages/
    - independent versioning setup
  
  confidence_weight: 0.9
```

### **npm/yarn Workspaces Detection**
```yaml
npm-workspaces:
  primary_indicators:
    - "workspaces" field in package.json
    - multiple package.json files in subdirectories
  
  secondary_indicators:
    - packages/ OR apps/ directories
    - workspace: protocol in dependencies
    - lerna.json absent (pure workspaces)
  
  confidence_weight: 0.8
```

---

## ☁️ **Serverless Rules**

### **AWS Lambda Detection**
```yaml
aws-lambda:
  primary_indicators:
    - handler.js OR handler.ts exists
    - serverless.yml exists
    - "aws-lambda" OR "aws-sdk" in dependencies
  
  secondary_indicators:
    - functions/ directory
    - serverless/ directory
    - "serverless" in devDependencies
    - .aws/ configuration
  
  confidence_weight: 0.85
```

### **Vercel Functions Detection**
```yaml
vercel-functions:
  primary_indicators:
    - vercel.json exists
    - api/ directory exists
    - "@vercel/node" in dependencies
  
  secondary_indicators:
    - functions/ directory
    - serverless function patterns
    - deployment configuration
  
  confidence_weight: 0.8
```

---

## 🎯 **Confidence Scoring**

### **Scoring Algorithm**
```typescript
interface ConfidenceCalculation {
  primary_indicators: number    // 40% weight
  secondary_indicators: number  // 25% weight
  structure_patterns: number    // 20% weight
  build_configuration: number   // 15% weight
}

const calculateConfidence = (detectionData: DetectionData): number => {
  const weights = {
    primary: 0.40,
    secondary: 0.25, 
    structure: 0.20,
    build: 0.15
  }
  
  return (
    (detectionData.primaryMatches / detectionData.primaryTotal) * weights.primary +
    (detectionData.secondaryMatches / detectionData.secondaryTotal) * weights.secondary +
    (detectionData.structureMatches / detectionData.structureTotal) * weights.structure +
    (detectionData.buildMatches / detectionData.buildTotal) * weights.build
  ) * 100
}
```

### **Confidence Levels**
```yaml
confidence_levels:
  definitive: 90-100%    # Auto-proceed with high confidence
  strong: 70-89%         # Proceed with validation  
  moderate: 50-69%       # Request user confirmation
  weak: 30-49%          # Multiple options, user choice
  unknown: 0-29%        # Fallback to generic template
```

---

## 🔄 **Fallback Strategy**

### **Multi-Pattern Projects**
```yaml
hybrid_detection:
  next_with_api:
    - Next.js + Express API combination
    - Full-stack but with separate API
  
  monorepo_multi_type:
    - React app + Node API in same monorepo
    - Different templates for different apps
  
  custom_architecture:
    - Doesn't match standard patterns
    - Generic template with manual customization
```

### **Generic Fallback**
```yaml
generic_typescript:
  indicators:
    - tsconfig.json exists
    - TypeScript files present
    - package.json exists
  
  template:
    - Basic import/export analysis
    - Generic C4 structure
    - Manual enhancement prompts
  
  confidence_weight: 0.3
```

---

## 📋 **Usage in Agent**

### **Implementation Pattern**
```typescript
// Agent logic for detection
const projectDetection = {
  analyzePackageJson: 'Check dependencies and scripts',
  scanDirectoryStructure: 'Identify standard patterns', 
  detectBuildTools: 'Find configuration files',
  scoreConfidence: 'Calculate match percentages',
  selectTemplate: 'Choose highest confidence template',
  applyFallback: 'Use generic if confidence too low'
}
```

---

**Detection Rules**: 🔍 **Comprehensive & Accurate**  
**Coverage**: 10+ project types with confidence scoring  
**Fallback**: Generic template para casos edge  
**Extensibility**: Facilmente expandível para novos tipos
