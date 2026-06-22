# 🎭 C4 Mermaid Patterns - Sistema Onion

## 📋 **Mermaid C4 Syntax Reference**

Padrões específicos para geração de diagramas C4 em Mermaid, focados em compatibilidade GitHub.

---

## 🎨 **Context Diagram Patterns**

### **Basic Context Pattern**
```mermaid
C4Context
    title System Context diagram for [System Name]
    
    Person(user, "User", "Primary system user")
    System(main_system, "Main System", "Core application system")
    System_Ext(external, "External System", "Third-party service")
    
    Rel(user, main_system, "Uses", "HTTPS")
    Rel(main_system, external, "Integrates with", "API/HTTPS")
```

### **Multi-User Context Pattern**
```mermaid
C4Context
    title System Context - Multi-User Application
    
    Person(end_user, "End User", "Application end user")
    Person(admin, "Administrator", "System administrator")
    Person(dev, "Developer", "Development team member")
    
    System(app_system, "Application System", "Main application")
    System_Ext(auth_service, "Auth Service", "Authentication provider")
    SystemDb_Ext(analytics, "Analytics", "Usage analytics service")
    
    Rel(end_user, app_system, "Uses application", "HTTPS")
    Rel(admin, app_system, "Administers", "HTTPS/Admin Panel")
    Rel(dev, app_system, "Develops & deploys", "CI/CD")
    Rel(app_system, auth_service, "Authenticates users", "OAuth/JWT")
    Rel(app_system, analytics, "Sends events", "HTTPS/Events API")
```

### **Microservices Context Pattern**
```mermaid
C4Context
    title System Context - Microservices Architecture
    
    Person(user, "User", "System user")
    
    System_Boundary(microservices, "Microservices Ecosystem") {
        System(api_gateway, "API Gateway", "Request routing & authentication")
        System(service_a, "Service A", "Domain-specific service")
        System(service_b, "Service B", "Domain-specific service")
    }
    
    System_Ext(database, "Database Cluster", "Distributed data storage")
    System_Ext(message_broker, "Message Broker", "Event streaming")
    
    Rel(user, api_gateway, "API requests", "HTTPS/REST")
    Rel(api_gateway, service_a, "Routes requests", "HTTP")
    Rel(api_gateway, service_b, "Routes requests", "HTTP")
    Rel(service_a, database, "Persists data", "SQL")
    Rel(service_b, database, "Persists data", "SQL")
    Rel(service_a, message_broker, "Publishes events", "Message Queue")
    Rel(service_b, message_broker, "Consumes events", "Message Queue")
```

---

## 🏗️ **Container Diagram Patterns**

### **Web Application Container Pattern**
```mermaid
C4Container
    title Container diagram for Web Application
    
    Person(user, "User")
    
    Container_Boundary(web_app, "Web Application") {
        Container(spa, "Single Page App", "React/TypeScript", "User interface")
        Container(api, "API Server", "Node.js/Express", "Business logic & API")
        Container(bg_jobs, "Background Jobs", "Node.js/Queue", "Async processing")
    }
    
    ContainerDb(database, "Database", "PostgreSQL", "Application data")
    ContainerDb(cache, "Cache", "Redis", "Session & temporary data")
    Container_Ext(cdn, "CDN", "CloudFront", "Static assets")
    
    Rel(user, spa, "Uses", "HTTPS")
    Rel(spa, cdn, "Loads assets", "HTTPS")
    Rel(spa, api, "API calls", "JSON/HTTPS")
    Rel(api, database, "Reads/Writes", "SQL")
    Rel(api, cache, "Caches data", "Redis Protocol")
    Rel(api, bg_jobs, "Enqueues tasks", "Message Queue")
    Rel(bg_jobs, database, "Updates data", "SQL")
```

### **Monorepo Container Pattern**
```mermaid
C4Container
    title Container diagram for NX Monorepo
    
    Person(developer, "Developer")
    Person(user, "End User")
    
    Container_Boundary(nx_workspace, "NX Monorepo Workspace") {
        Container(web_app, "Web App", "React", "Main user application")
        Container(admin_app, "Admin App", "React", "Administrative interface")
        Container(mobile_app, "Mobile App", "React Native", "Mobile application")
        Container(api_service, "API Service", "NestJS", "Backend API")
        Container(shared_libs, "Shared Libraries", "TypeScript", "Common utilities")
    }
    
    ContainerDb(database, "Database", "PostgreSQL", "Application data")
    Container_Ext(registry, "Package Registry", "npm/private", "Package distribution")
    
    Rel(developer, nx_workspace, "Develops", "NX CLI")
    Rel(user, web_app, "Uses", "HTTPS")
    Rel(user, mobile_app, "Uses", "Mobile App")
    Rel(web_app, shared_libs, "Imports", "ES Modules")
    Rel(admin_app, shared_libs, "Imports", "ES Modules")
    Rel(mobile_app, shared_libs, "Imports", "ES Modules")
    Rel(api_service, shared_libs, "Imports", "ES Modules")
    Rel(web_app, api_service, "API calls", "HTTPS/REST")
    Rel(admin_app, api_service, "API calls", "HTTPS/REST")
    Rel(mobile_app, api_service, "API calls", "HTTPS/REST")
    Rel(api_service, database, "Persists data", "SQL")
    Rel(shared_libs, registry, "Published to", "npm publish")
```

### **Full-stack Container Pattern**
```mermaid
C4Container
    title Container diagram for Next.js Full-stack Application
    
    Person(user, "User")
    
    Container_Boundary(nextjs_app, "Next.js Application") {
        Container(frontend, "Frontend", "React/Next.js", "User interface & pages")
        Container(api_routes, "API Routes", "Next.js API", "Backend API endpoints")
        Container(middleware, "Middleware", "Next.js Middleware", "Auth & routing logic")
    }
    
    ContainerDb(database, "Database", "PostgreSQL", "Application data")
    Container_Ext(cdn, "CDN", "Vercel CDN", "Static assets & ISR")
    Container_Ext(auth_provider, "Auth Provider", "NextAuth.js", "Authentication")
    
    Rel(user, frontend, "Visits pages", "HTTPS")
    Rel(user, cdn, "Loads static content", "HTTPS")
    Rel(frontend, middleware, "Auth checks", "Server-side")
    Rel(frontend, api_routes, "API calls", "HTTP/Internal")
    Rel(middleware, auth_provider, "Validates auth", "OAuth")
    Rel(api_routes, database, "Data operations", "SQL")
    Rel(cdn, frontend, "Serves ISR content", "HTTP")
```

---

## 🧩 **Component Diagram Patterns**

### **React Component Structure Pattern**
```mermaid
C4Component
    title Component diagram for React Frontend
    
    Container(frontend, "Frontend Container", "React")
    
    Component(app, "App Component", "React", "Root application component")
    Component(router, "Router", "React Router", "Client-side routing")
    Component(pages, "Page Components", "React", "Route-specific pages")
    Component(layout, "Layout Components", "React", "Common layout structures")
    Component(ui_components, "UI Components", "React", "Reusable UI elements")
    Component(hooks, "Custom Hooks", "React Hooks", "Business logic abstraction")
    Component(context, "Context Providers", "React Context", "Global state management")
    Component(services, "API Services", "TypeScript", "HTTP client abstractions")
    Component(utils, "Utilities", "TypeScript", "Helper functions")
    Component(constants, "Constants", "TypeScript", "Configuration & constants")
    
    Rel(app, router, "Configures routes")
    Rel(app, context, "Provides global state")
    Rel(router, pages, "Renders page")
    Rel(pages, layout, "Uses layout")
    Rel(pages, ui_components, "Renders components")
    Rel(pages, hooks, "Uses business logic")
    Rel(layout, ui_components, "Composes UI")
    Rel(hooks, services, "Calls APIs")
    Rel(hooks, context, "Consumes context")
    Rel(services, utils, "Uses utilities")
    Rel(services, constants, "Uses configuration")
    Rel(ui_components, constants, "Uses constants")
```

### **API Service Component Pattern**
```mermaid
C4Component
    title Component diagram for Node.js API Service
    
    Container(api_service, "API Service Container", "Node.js")
    
    Component(app, "App Module", "Express", "Application setup & middleware")
    Component(routes, "Route Handlers", "Express Router", "HTTP endpoint definitions")
    Component(controllers, "Controllers", "TypeScript Classes", "Request/response logic")
    Component(services, "Business Services", "TypeScript Classes", "Business logic layer")
    Component(repositories, "Repositories", "TypeScript Classes", "Data access layer")
    Component(middleware, "Middleware", "Express Middleware", "Cross-cutting concerns")
    Component(validators, "Validators", "Joi/Zod", "Input validation")
    Component(auth, "Auth Module", "JWT/Passport", "Authentication & authorization")
    Component(config, "Configuration", "TypeScript", "Environment & settings")
    Component(utils, "Utilities", "TypeScript", "Helper functions")
    
    Rel(app, routes, "Registers routes")
    Rel(app, middleware, "Applies middleware")
    Rel(app, auth, "Configures auth")
    Rel(routes, controllers, "Delegates to")
    Rel(controllers, validators, "Validates input")
    Rel(controllers, services, "Calls business logic")
    Rel(controllers, auth, "Checks authorization")
    Rel(services, repositories, "Accesses data")
    Rel(repositories, config, "Uses DB config")
    Rel(middleware, auth, "Validates tokens")
    Rel(auth, config, "Uses auth config")
    Rel(services, utils, "Uses utilities")
```

---

## 🎯 **Pattern Selection Rules**

### **Context Level Selection**
```typescript
const contextPatterns = {
  'single-user-spa': 'basic-context-pattern',
  'multi-user-app': 'multi-user-context-pattern',
  'microservices': 'microservices-context-pattern',
  'monolith': 'basic-context-pattern',
  'serverless': 'serverless-context-pattern'
}
```

### **Container Level Selection**
```typescript
const containerPatterns = {
  'spa-with-api': 'web-application-container-pattern',
  'monorepo-nx': 'monorepo-container-pattern',
  'nextjs-fullstack': 'fullstack-container-pattern',
  'microservices': 'microservices-container-pattern',
  'api-only': 'api-service-container-pattern'
}
```

### **Component Level Selection**
```typescript
const componentPatterns = {
  'react-frontend': 'react-component-structure-pattern',
  'vue-frontend': 'vue-component-structure-pattern',
  'node-api': 'api-service-component-pattern',
  'nestjs-api': 'nestjs-component-pattern',
  'express-api': 'express-component-pattern'
}
```

---

## 🔧 **Mermaid Optimization Rules**

### **GitHub Compatibility**
```yaml
github_optimizations:
  max_diagram_size: '2MB'
  recommended_nodes: '< 20 per diagram'
  text_length: '< 50 chars per label'
  
  avoid:
    - Complex nested boundaries
    - Too many relationship lines
    - Very long descriptions
    
  prefer:
    - Simple, clear node names
    - Consistent styling
    - Logical grouping with boundaries
```

### **Performance Guidelines**
```yaml
performance_rules:
  context_diagrams:
    max_systems: 8
    max_actors: 4
    max_relationships: 12
    
  container_diagrams:
    max_containers: 12
    max_databases: 4
    max_external_systems: 6
    
  component_diagrams:
    max_components: 15
    max_relationships: 20
    recommended_depth: 1  # Avoid nested components
```

### **Styling Consistency**
```yaml
styling_patterns:
  colors:
    person: '#08427B'
    system: '#1168BD'
    system_ext: '#999999'
    container: '#438DD5'
    component: '#85BBF0'
    database: '#F2F2F2'
    
  node_naming:
    use_snake_case: true
    max_length: 20
    avoid_special_chars: true
    
  relationship_labels:
    action_oriented: 'Uses, Calls, Sends, Reads'
    include_protocol: 'HTTPS, REST, SQL'
    max_length: 30
```

---

**Patterns**: 🎭 **GitHub-Optimized & Performance-Tuned**  
**Compatibility**: Testado com GitHub Mermaid rendering  
**Performance**: Otimizado para diagramas < 2MB  
**Quality**: Templates seguem melhores práticas C4 Model
