# 📚 Comandos `docs/` — documentação como spec-as-code

Comandos da **documentação estruturada** do Onion: geram, validam e mantêm os contextos de domínio (negócio, técnico, compliance), índices e consolidações em `docs/`, tratando a documentação como spec-as-code consumível por IA. Use ao construir/atualizar a arquitetura de contexto de um projeto, diagnosticar a saúde dos docs ou consolidar material bruto em conhecimento estratégico.

## Comandos

| Comando | Finalidade |
|---------|-----------|
| [`/docs:build-business-docs`](build-business-docs.md) | Gera a arquitetura de contexto de negócio em `docs/business-context/`. Delega a `@product-agent`, `@research-agent`, `@storytelling-business-specialist`, `@branding-positioning-specialist`. |
| [`/docs:build-tech-docs`](build-tech-docs.md) | Gera a arquitetura de contexto técnico em `docs/technical-context/`. Delega a `@c4-architecture-specialist`, `@c4-documentation-specialist`, `@docs-reverse-engineer`, `@system-documentation-orchestrator`, `@mermaid-specialist`. |
| [`/docs:build-compliance-docs`](build-compliance-docs.md) | Gera a arquitetura de compliance em `docs/compliance-context/` (ISO 27001, SOC 2, ISO 22301, PMBOK). Delega a `@security-information-master`, `@iso-27001-specialist`, `@soc2-specialist`. |
| [`/docs:build-index`](build-index.md) | Gera e atualiza os índices de `docs/` a partir da estrutura real (contagens escaneadas, nunca hardcoded). |
| [`/docs:refine-vision`](refine-vision.md) | Refina a visão e a estratégia do produto/projeto. |
| [`/docs:reverse-consolidate`](reverse-consolidate.md) | Engenharia reversa de um projeto para documentação consolidada; pré-processador do `/docs:build-tech-docs`. Delega a `@docs-reverse-engineer`, `@system-documentation-orchestrator`. |
| [`/docs:consolidate-documents`](consolidate-documents.md) | Consolida múltiplos documentos em conhecimento unificado (divergências, convergências, insights, gaps). Delega a `@document-consolidator`, `@product-agent`, `@docs-agent`. |
| [`/docs:docs-health`](docs-health.md) | Health check **read-only** da documentação: saúde, gaps e recomendações. Delega a `@system-documentation-orchestrator`. |
| [`/docs:validate-docs`](validate-docs.md) | Valida estrutura, links e padrões da documentação e **corrige** com `--fix`. Delega a `@system-documentation-orchestrator`. |
| [`/docs:sync-sessions`](sync-sessions.md) | Sincroniza e organiza as sessões de trabalho do Sistema Onion. |
| [`/docs:help`](help.md) | Ajuda interativa para os comandos de documentação. |

> **`docs-health` vs `validate-docs`**: `docs-health` é diagnóstico read-only (saúde/gaps/recomendações); `validate-docs` valida estrutura/links/padrões e pode **corrigir** com `--fix`.

## 🔗 Referências
- Agentes de documentação: `@system-documentation-orchestrator`, `@docs-reverse-engineer`, `@c4-architecture-specialist`, `@c4-documentation-specialist`, `@mermaid-specialist`, `@document-consolidator`
- Comandos irmãos: [`/meta:create-knowledge-base`](../meta/create-knowledge-base.md) (KBs em `docs/knowledge-base/`), [`/product:consolidate-meetings`](../product/consolidate-meetings.md)
- Saídas em `docs/`: [`../../../docs/business-context/`](../../../docs/business-context/), [`../../../docs/technical-context/`](../../../docs/technical-context/), [`../../../docs/compliance-context/`](../../../docs/compliance-context/), [`../../../docs/knowledge-base/`](../../../docs/knowledge-base/)
- Meta-specs (L0): [`../../../docs/meta-specs/`](../../../docs/meta-specs/)
