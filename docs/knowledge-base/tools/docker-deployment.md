# Docker Deployment — Knowledge Base

versao: 1.0.0
data: 2026-06-14
categoria: tools
source-agent: docker-specialist

Referência técnica detalhada para containerização com Docker, Docker Compose e integração com PostgreSQL em projetos Node.js/Next.js/NX Monorepo.

---

## Índice

1. [Dockerfiles Completos](#1-dockerfiles-completos)
2. [Docker Compose — Configurações Completas](#2-docker-compose--configurações-completas)
3. [Arquivos de Suporte](#3-arquivos-de-suporte)
4. [Comandos Docker Essenciais](#4-comandos-docker-essenciais)
5. [Otimização de Performance](#5-otimização-de-performance)
6. [Segurança Best Practices](#6-segurança-best-practices)
7. [Troubleshooting](#7-troubleshooting)
8. [Exemplos Completos](#8-exemplos-completos)

---

## 1. Dockerfiles Completos

### 1.1 Dockerfile para Node.js API (Fastify) — Multi-stage Build

```dockerfile
# ==========================================
# Stage 1: Dependencies
# ==========================================
FROM node:20-alpine AS dependencies

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@8.15.9

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# ==========================================
# Stage 2: Build
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@8.15.9

# Copy dependencies from previous stage
COPY --from=dependencies /app/node_modules ./node_modules

# Copy source code
COPY . .

# Build application
RUN pnpm build

# ==========================================
# Stage 3: Production
# ==========================================
FROM node:20-alpine AS production

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@8.15.9

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install production dependencies only
RUN pnpm install --prod --frozen-lockfile

# Copy built application from builder
COPY --from=builder /app/dist ./dist

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "dist/main.js"]
```

### 1.2 Dockerfile para Next.js App

```dockerfile
# ==========================================
# Stage 1: Dependencies
# ==========================================
FROM node:20-alpine AS dependencies

WORKDIR /app

RUN npm install -g pnpm@8.15.9

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# ==========================================
# Stage 2: Build
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

RUN npm install -g pnpm@8.15.9

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

# Set environment to production for optimal build
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Build Next.js application
RUN pnpm build

# ==========================================
# Stage 3: Production
# ==========================================
FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN npm install -g pnpm@8.15.9

# Copy package files and install production dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

# Copy built Next.js app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.js ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["pnpm", "start"]
```

### 1.3 Dockerfile para NX Monorepo (App Específica)

```dockerfile
# ==========================================
# Dockerfile for NX Monorepo - Specific App
# ==========================================
FROM node:20-alpine AS dependencies

WORKDIR /workspace

# Install pnpm
RUN npm install -g pnpm@8.15.9

# Copy workspace configuration
COPY package.json pnpm-lock.yaml nx.json tsconfig.base.json ./

# Install all dependencies (NX needs workspace deps)
RUN pnpm install --frozen-lockfile

# ==========================================
# Stage 2: Build
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /workspace

RUN npm install -g pnpm@8.15.9

# Copy dependencies
COPY --from=dependencies /workspace/node_modules ./node_modules

# Copy entire monorepo (NX needs full context)
COPY . .

# Build specific app (replace 'api-admin' with your app name)
ARG APP_NAME=api-admin
RUN pnpm nx build ${APP_NAME} --configuration=production

# ==========================================
# Stage 3: Production
# ==========================================
FROM node:20-alpine AS production

WORKDIR /app

RUN npm install -g pnpm@8.15.9

# Copy only necessary files for the specific app
ARG APP_NAME=api-admin
COPY --from=builder /workspace/dist/apps/${APP_NAME} ./

# Install production dependencies (if app has package.json)
COPY --from=builder /workspace/node_modules ./node_modules

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

RUN chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

CMD ["node", "main.js"]
```

### 1.4 Dockerfile com Suporte a Migrations (Entrypoint)

```dockerfile
FROM node:20-alpine AS production

WORKDIR /app

RUN npm install -g pnpm@8.15.9

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod

COPY dist ./dist
COPY prisma ./prisma

# Script de entrypoint que roda migrations
COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

USER nodejs

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["node", "dist/main.js"]
```

```bash
# docker-entrypoint.sh
#!/bin/sh
set -e

echo "Running database migrations..."
npx prisma migrate deploy

echo "Starting application..."
exec "$@"
```

---

## 2. Docker Compose — Configurações Completas

### 2.1 Docker Compose com PostgreSQL (Produção)

```yaml
version: '3.9'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:17-alpine
    container_name: ${APP_NAME}-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-change_me_in_production}
      POSTGRES_DB: ${POSTGRES_DB:-app_db}
      PGDATA: /var/lib/postgresql/data/pgdata
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./prisma/migrations:/docker-entrypoint-initdb.d:ro
    networks:
      - ${APP_NAME}-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # API Application
  api:
    build:
      context: .
      dockerfile: apps/api-admin/Dockerfile
      args:
        APP_NAME: api-admin
    container_name: ${APP_NAME}-api
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD:-change_me_in_production}@postgres:5432/${POSTGRES_DB:-app_db}?schema=public
      PORT: 3000
    ports:
      - "${API_PORT:-3000}:3000"
    networks:
      - ${APP_NAME}-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Next.js UI Application
  ui:
    build:
      context: .
      dockerfile: apps/ui-admin/Dockerfile
    container_name: ${APP_NAME}-ui
    restart: unless-stopped
    depends_on:
      - api
    environment:
      NODE_ENV: production
      NEXT_PUBLIC_API_URL: http://api:3000
    ports:
      - "${UI_PORT:-4200}:3000"
    networks:
      - ${APP_NAME}-network

networks:
  ${APP_NAME}-network:
    driver: bridge

volumes:
  postgres_data:
    driver: local
```

### 2.2 Docker Compose para Desenvolvimento

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:17-alpine
    container_name: ${APP_NAME}-postgres-dev
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: change_me_for_local_dev
      POSTGRES_DB: app_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
      - ./prisma/migrations:/docker-entrypoint-initdb.d:ro
    networks:
      - ${APP_NAME}-dev

  # PgAdmin (opcional - para gerenciar database visualmente)
  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: ${APP_NAME}-pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
      PGADMIN_CONFIG_SERVER_MODE: 'False'
    ports:
      - "5050:80"
    depends_on:
      - postgres
    networks:
      - ${APP_NAME}-dev

  # Redis (cache/queue)
  redis:
    image: redis:7-alpine
    container_name: ${APP_NAME}-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - ${APP_NAME}-dev
    command: redis-server --appendonly yes

networks:
  ${APP_NAME}-dev:
    driver: bridge

volumes:
  postgres_dev_data:
  redis_data:
```

### 2.3 Docker Compose Multi-Service (Production-like com Nginx)

```yaml
version: '3.9'

services:
  # PostgreSQL Primary
  postgres-primary:
    image: postgres:17-alpine
    container_name: ${APP_NAME}-postgres-primary
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: app_prod
      POSTGRES_REPLICATION_MODE: master
      POSTGRES_REPLICATION_USER: replicator
      POSTGRES_REPLICATION_PASSWORD: ${REPLICATION_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_primary_data:/var/lib/postgresql/data
    networks:
      - ${APP_NAME}-network

  # Multiple APIs
  api-admin:
    build:
      context: .
      dockerfile: apps/api-admin/Dockerfile
    container_name: ${APP_NAME}-api-admin
    restart: unless-stopped
    depends_on:
      - postgres-primary
    environment:
      DATABASE_URL: postgresql://app:${POSTGRES_PASSWORD}@postgres-primary:5432/app_prod
    ports:
      - "3001:3000"
    networks:
      - ${APP_NAME}-network

  api-creditors:
    build:
      context: .
      dockerfile: apps/api-creditors/Dockerfile
    container_name: ${APP_NAME}-api-creditors
    restart: unless-stopped
    depends_on:
      - postgres-primary
    environment:
      DATABASE_URL: postgresql://app:${POSTGRES_PASSWORD}@postgres-primary:5432/app_prod
    ports:
      - "3002:3000"
    networks:
      - ${APP_NAME}-network

  # UIs
  ui-admin:
    build:
      context: .
      dockerfile: apps/ui-admin/Dockerfile
    container_name: ${APP_NAME}-ui-admin
    restart: unless-stopped
    environment:
      NEXT_PUBLIC_API_URL: http://api-admin:3000
    ports:
      - "4201:3000"
    networks:
      - ${APP_NAME}-network

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: ${APP_NAME}-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - api-admin
      - api-creditors
      - ui-admin
    networks:
      - ${APP_NAME}-network

networks:
  ${APP_NAME}-network:
    driver: bridge

volumes:
  postgres_primary_data:
```

---

## 3. Arquivos de Suporte

### 3.1 .dockerignore

```
# Dependencies
node_modules
npm-debug.log
pnpm-lock.yaml
yarn.lock

# Development
.git
.gitignore
.env
.env.local
.env.*.local

# Testing
coverage
.nyc_output
*.test.ts
*.spec.ts
__tests__
test/
tests/

# Build artifacts
dist
build
.next
out

# NX
.nx
.nx/cache

# Logs
logs
*.log

# IDEs
.vscode
.idea
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Documentation
docs/
*.md
!README.md

# CI/CD
.github
.gitlab-ci.yml
azure-pipelines.yml

# Temporary
tmp/
temp/
*.tmp
```

### 3.2 .env.example (para Docker Compose)

```env
# PostgreSQL Configuration
POSTGRES_USER=app
POSTGRES_PASSWORD=change_me_in_production
POSTGRES_DB=app_db
POSTGRES_PORT=5432

# Application Ports
API_PORT=3000
UI_PORT=4200

# Database Connection
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?schema=public

# Node Environment
NODE_ENV=production

# Application Secrets
JWT_SECRET=change_me_in_production
ENCRYPTION_KEY=change_me_in_production
```

---

## 4. Comandos Docker Essenciais

### 4.1 Build e Run

```bash
# Build image
docker build -t ${APP_NAME}-api:latest -f apps/api-admin/Dockerfile .

# Build com build args
docker build \
  --build-arg APP_NAME=api-admin \
  -t ${APP_NAME}-api-admin:latest \
  .

# Run container
docker run -d \
  --name ${APP_NAME}-api \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://..." \
  ${APP_NAME}-api:latest

# Run com volume mount (desenvolvimento)
docker run -d \
  --name ${APP_NAME}-api-dev \
  -p 3000:3000 \
  -v $(pwd):/app \
  -v /app/node_modules \
  ${APP_NAME}-api:latest
```

### 4.2 Docker Compose

```bash
# Start all services
docker-compose up -d

# Start specific service
docker-compose up -d postgres

# View logs
docker-compose logs -f api

# Stop all services
docker-compose down

# Stop and remove volumes (CUIDADO: perde dados!)
docker-compose down -v

# Rebuild and restart
docker-compose up -d --build

# Scale service
docker-compose up -d --scale api=3
```

### 4.3 Debugging e Manutenção

```bash
# Ver containers rodando
docker ps

# Ver todos containers (incluindo parados)
docker ps -a

# Ver logs de container
docker logs -f container_name

# Executar comando em container
docker exec -it container_name sh

# Executar comando em container como root
docker exec -it -u root container_name sh

# Inspecionar container
docker inspect container_name

# Ver uso de recursos
docker stats

# Limpar recursos não usados
docker system prune -a

# Remover volumes órfãos
docker volume prune
```

### 4.4 PostgreSQL via Docker

```bash
# Conectar ao PostgreSQL via docker
docker exec -it ${APP_NAME}-postgres psql -U app -d app_db

# Backup database
docker exec ${APP_NAME}-postgres pg_dump -U app app_db > backup.sql

# Restore database
docker exec -i ${APP_NAME}-postgres psql -U app app_db < backup.sql

# Ver logs PostgreSQL
docker logs -f ${APP_NAME}-postgres

# Executar SQL file
docker exec -i ${APP_NAME}-postgres psql -U app -d app_db < migration.sql
```

---

## 5. Otimização de Performance

### 5.1 Build Cache Optimization

```dockerfile
# Ruim: invalida cache quando qualquer arquivo muda
COPY . .
RUN npm install

# Bom: copia package.json primeiro para aproveitar cache de layers
COPY package.json pnpm-lock.yaml ./
RUN pnpm install
COPY . .
```

### 5.2 Layer Optimization — Ordem Importa

```dockerfile
# Ordem importa: comandos que mudam menos ficam primeiro

# 1. Base image (muda raramente)
FROM node:20-alpine

# 2. System dependencies (muda raramente)
RUN apk add --no-cache python3 make g++

# 3. Application dependencies (muda às vezes)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# 4. Application code (muda frequentemente)
COPY . .
RUN pnpm build
```

### 5.3 Image Size Reduction

```dockerfile
# Use alpine images (menor)
FROM node:20-alpine  # ~50MB
# vs
FROM node:20         # ~1GB

# Multi-stage builds (não leva builder para produção)
FROM node:20-alpine AS builder
# ... build aqui

FROM node:20-alpine AS production
COPY --from=builder /app/dist ./dist
# Não copia node_modules de dev, etc

# Limpar cache em single layer
RUN pnpm install && \
    pnpm build && \
    rm -rf /root/.npm /tmp/*
```

---

## 6. Segurança Best Practices

### 6.1 Non-Root User

```dockerfile
# SEMPRE criar e usar non-root user em produção
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

RUN chown -R nodejs:nodejs /app

USER nodejs
```

### 6.2 Secrets Management

```bash
# NUNCA colocar secrets no Dockerfile
# ENV DATABASE_PASSWORD=secret123  <- errado

# Usar environment variables em runtime
docker run -e DATABASE_PASSWORD=secret123 ...

# Ou Docker secrets (Swarm/Kubernetes)
docker secret create db_password ./password.txt
```

### 6.3 Image Scanning

```bash
# Scan image por vulnerabilidades (Docker Scout)
docker scan ${APP_NAME}-api:latest

# Ou usar Trivy (mais completo)
trivy image ${APP_NAME}-api:latest
```

---

## 7. Troubleshooting

### 7.1 Container não inicia

```bash
# Ver logs completos
docker logs container_name

# Ver últimas 100 linhas
docker logs --tail 100 container_name

# Seguir logs em tempo real
docker logs -f container_name

# Ver exit code
docker inspect container_name | grep ExitCode
```

### 7.2 Build falha

```bash
# Build com output detalhado
docker build --progress=plain --no-cache .

# Ver cada layer sendo criada
docker build --progress=plain .

# Build apenas até stage específico (útil para debug)
docker build --target builder .
```

### 7.3 Conectividade entre containers

```bash
# Verificar networks disponíveis
docker network ls
docker network inspect ${APP_NAME}-network

# Ping entre containers
docker exec api ping postgres

# Verificar portas expostas
docker port container_name

# DNS resolution entre containers
docker exec api nslookup postgres
```

### 7.4 Performance issues

```bash
# Ver uso de recursos em tempo real
docker stats

# Limitar recursos (memory e CPU)
docker run -m 512m --cpus 1 image_name

# Ver processos em container
docker top container_name

# Inspecionar filesystem layers e tamanhos
docker history image_name
```

---

## 8. Exemplos Completos

### Exemplo 1: Stack Completa Development

```yaml
# docker-compose.dev.yml
version: '3.9'

services:
  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: change_me_for_local_dev
      POSTGRES_DB: app_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev:/var/lib/postgresql/data
      - ./prisma/migrations:/docker-entrypoint-initdb.d:ro

  api:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      DATABASE_URL: postgresql://app:change_me_for_local_dev@postgres:5432/app_dev
      NODE_ENV: development
    ports:
      - "3000:3000"
    depends_on:
      - postgres
    command: pnpm dev

volumes:
  postgres_dev:
```

### Exemplo 2: Multi-App NX Monorepo

```yaml
# docker-compose.yml
version: '3.9'

services:
  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: app_prod
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app

  # Admin API
  api-admin:
    build:
      context: .
      dockerfile: apps/api-admin/Dockerfile
      args:
        APP_NAME: api-admin
    environment:
      DATABASE_URL: postgresql://app:${POSTGRES_PASSWORD}@postgres:5432/app_prod
    ports:
      - "3001:3000"
    depends_on:
      - postgres
    networks:
      - app

  # Creditors API
  api-creditors:
    build:
      context: .
      dockerfile: apps/api-creditors/Dockerfile
      args:
        APP_NAME: api-creditors
    environment:
      DATABASE_URL: postgresql://app:${POSTGRES_PASSWORD}@postgres:5432/app_prod
    ports:
      - "3002:3000"
    depends_on:
      - postgres
    networks:
      - app

  # Admin UI
  ui-admin:
    build:
      context: .
      dockerfile: apps/ui-admin/Dockerfile
    environment:
      NEXT_PUBLIC_API_URL: http://api-admin:3000
    ports:
      - "4201:3000"
    depends_on:
      - api-admin
    networks:
      - app

networks:
  app:
    driver: bridge

volumes:
  postgres_data:
```

### Exemplo 3: Production-Ready com Migrations (Entrypoint Pattern)

Dockerfile base:

```dockerfile
FROM node:20-alpine AS production

WORKDIR /app

RUN npm install -g pnpm@8.15.9

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod

COPY dist ./dist
COPY prisma ./prisma

COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

USER nodejs

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["node", "dist/main.js"]
```

Script de entrypoint:

```bash
#!/bin/sh
set -e

echo "Running database migrations..."
npx prisma migrate deploy

echo "Starting application..."
exec "$@"
```

---

*Gerado a partir de `docker-specialist` — para delegação e workflow macro, consulte o agente: `.claude/agents/deployment/docker-specialist.md`*
