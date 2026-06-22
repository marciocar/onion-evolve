# 🎨 C4 Templates - Sistema Onion

## 📋 **Template Strategy**

Templates Mermaid C4 adaptativos para diferentes tipos de projeto. Seguindo a estratégia "Cebola" (núcleo → abstração).

---

## 🏢 **Single Page Application (SPA) Templates**

### **React SPA Template**
```mermaid
C4Context
    title System Context diagram for React SPA Application
    
    Person(user, "User", "End user of the application")
    System(spa, "React SPA", "Single Page Application built with React")
    System_Ext(api, "Backend API", "RESTful API providing data")
    System_Ext(cdn, "CDN", "Content Delivery Network")
    
    Rel(user, spa, "Uses", "HTTPS")
    Rel(spa, api, "Fetches data", "HTTPS/REST")
    Rel(spa, cdn, "Loads assets", "HTTPS")
```

### **Vue.js SPA Template**
```mermaid
C4Context
    title System Context diagram for Vue.js SPA Application
    
    Person(user, "User", "Application user")
    System(vue_spa, "Vue.js SPA", "Single Page Application built with Vue.js")
    System_Ext(api, "Backend API", "Data provider")
    System_Ext(router, "Vue Router", "Client-side routing")
    
    Rel(user, vue_spa, "Interacts", "HTTPS")
    Rel(vue_spa, api, "API calls", "HTTPS/REST")
    Rel(vue_spa, router, "Navigation", "Client-side")
```

---

## 🔌 **API Service Templates**

### **Node.js Express API Template**
```mermaid
C4Context
    title System Context diagram for Node.js Express API
    
    System_Ext(client, "Client Applications", "Web, Mobile, or SPA")
    System(api, "Express API", "Node.js REST API built with Express")
    SystemDb(database, "Database", "PostgreSQL/MongoDB")
    System_Ext(cache, "Redis Cache", "Caching layer")
    
    Rel(client, api, "API Requests", "HTTPS/REST")
    Rel(api, database, "Stores/Retrieves data", "SQL/NoSQL")
    Rel(api, cache, "Caches data", "Redis Protocol")
```

### **NestJS API Template**
```mermaid
C4Context
    title System Context diagram for NestJS API
    
    System_Ext(client, "Client Applications", "Various client types")
    System(nestjs_api, "NestJS API", "Enterprise Node.js API with NestJS")
    SystemDb(database, "Database", "TypeORM supported database")
    System_Ext(auth, "Authentication Service", "JWT/OAuth provider")
    
    Rel(client, nestjs_api, "API calls", "HTTPS/REST")
    Rel(nestjs_api, database, "Data operations", "TypeORM")
    Rel(nestjs_api, auth, "Authentication", "JWT/OAuth")
```

---

## 🌐 **Full-stack Application Templates**

### **Next.js Full-stack Template**
```mermaid
C4Context
    title System Context diagram for Next.js Application
    
    Person(user, "User", "Application user")
    System(nextjs_app, "Next.js Application", "Full-stack React framework")
    SystemDb(database, "Database", "Database system")
    System_Ext(cdn, "Vercel CDN", "Static assets and ISR")
    
    Rel(user, nextjs_app, "Uses application", "HTTPS")
    Rel(nextjs_app, database, "Data operations", "Database connection")
    Rel(nextjs_app, cdn, "Serves static content", "CDN")
```

---

## 📦 **Monorepo Templates**

### **NX Monorepo Template**
```mermaid
C4Context
    title System Context diagram for NX Monorepo Workspace
    
    Person(dev, "Developer", "Development team member")
    System(nx_workspace, "NX Workspace", "Monorepo with multiple applications")
    System_Ext(registry, "Package Registry", "npm/private registry")
    System_Ext(ci_cd, "CI/CD Pipeline", "Build and deployment automation")
    
    Rel(dev, nx_workspace, "Develops", "CLI/IDE")
    Rel(nx_workspace, registry, "Publishes packages", "npm publish")
    Rel(nx_workspace, ci_cd, "Triggers builds", "Git hooks")
```

### **Lerna Monorepo Template**
```mermaid
C4Context
    title System Context diagram for Lerna Monorepo
    
    Person(dev, "Developer", "Team member")
    System(lerna_mono, "Lerna Monorepo", "Multi-package repository")
    System_Ext(npm, "NPM Registry", "Package registry")
    System_Ext(git, "Git Repository", "Version control")
    
    Rel(dev, lerna_mono, "Manages packages", "Lerna CLI")
    Rel(lerna_mono, npm, "Publishes", "npm")
    Rel(lerna_mono, git, "Version control", "Git")
```

---

## ☁️ **Serverless Templates**

### **AWS Lambda Template**
```mermaid
C4Context
    title System Context diagram for AWS Lambda Functions
    
    System_Ext(client, "Client", "Application or API Gateway")
    System(lambda, "Lambda Functions", "Serverless compute functions")
    SystemDb(dynamo, "DynamoDB", "NoSQL database")
    System_Ext(s3, "S3 Bucket", "File storage")
    
    Rel(client, lambda, "Invokes functions", "API Gateway/Direct")
    Rel(lambda, dynamo, "Data operations", "AWS SDK")
    Rel(lambda, s3, "File operations", "AWS SDK")
```

---

## 🎯 **Container Level Templates**

### **React SPA Container Diagram**
```mermaid
C4Container
    title Container diagram for React SPA
    
    Person(user, "User")
    
    Container(web_app, "Web Application", "React, TypeScript", "Single-page application")
    Container(api_app, "API Application", "Node.js, Express", "Provides functionality via API")
    ContainerDb(database, "Database", "PostgreSQL", "Stores data")
    
    Rel(user, web_app, "Uses", "HTTPS")
    Rel(web_app, api_app, "Makes API calls to", "JSON/HTTPS")
    Rel(api_app, database, "Reads from and writes to", "SQL/JDBC")
```

### **Monorepo Container Diagram**
```mermaid
C4Container
    title Container diagram for NX Monorepo
    
    Person(dev, "Developer")
    
    Container(web_app, "Web Application", "React", "Main user-facing app")
    Container(admin_app, "Admin Application", "React", "Administrative interface") 
    Container(api, "API Service", "Node.js/NestJS", "Backend API service")
    Container(shared_lib, "Shared Libraries", "TypeScript", "Common utilities and types")
    ContainerDb(database, "Database", "PostgreSQL", "Shared database")
    
    Rel(dev, web_app, "Develops")
    Rel(dev, admin_app, "Develops")
    Rel(dev, api, "Develops")
    Rel(web_app, shared_lib, "Uses")
    Rel(admin_app, shared_lib, "Uses")
    Rel(api, shared_lib, "Uses")
    Rel(web_app, api, "API calls", "HTTPS")
    Rel(admin_app, api, "API calls", "HTTPS")
    Rel(api, database, "Persists data")
```

---

## 🧩 **Component Level Templates**

### **React Component Structure**
```mermaid
C4Component
    title Component diagram for React Application
    
    Container(web_app, "Web Application", "React")
    
    Component(app_comp, "App Component", "React Component", "Main application component")
    Component(router, "Router", "React Router", "Handles client-side routing")
    Component(pages, "Page Components", "React Components", "Individual page components")
    Component(components, "UI Components", "React Components", "Reusable UI components")
    Component(hooks, "Custom Hooks", "React Hooks", "Business logic hooks")
    Component(services, "API Services", "TypeScript", "API communication layer")
    Component(utils, "Utilities", "TypeScript", "Helper functions and utilities")
    
    Rel(app_comp, router, "Uses")
    Rel(router, pages, "Routes to")
    Rel(pages, components, "Renders")
    Rel(pages, hooks, "Uses")
    Rel(hooks, services, "Calls")
    Rel(services, utils, "Uses")
```

---

## 🔧 **Template Selection Logic**

### **Detection Patterns**
```typescript
// Template selection based on project detection
const templateMappingRules = {
  // SPA Projects
  'spa-react': {
    contextTemplate: 'react-spa-context',
    containerTemplate: 'spa-container-diagram',
    componentTemplate: 'react-component-structure'
  },
  
  // API Projects
  'node-api': {
    contextTemplate: 'nodejs-api-context', 
    containerTemplate: 'api-service-containers',
    componentTemplate: 'api-layered-components'
  },
  
  // Monorepo Projects
  'nx-monorepo': {
    contextTemplate: 'nx-workspace-context',
    containerTemplate: 'monorepo-container-diagram', 
    componentTemplate: 'nx-lib-components'
  }
  
  // ... more mappings
}
```

---

**Templates**: 🎨 **Adaptive & Project-Aware**  
**Strategy**: Seleção automática baseada em detecção de projeto  
**Fallback**: Template genérico quando tipo não identificado  
**Extensibilidade**: Novos templates facilmente adicionáveis
