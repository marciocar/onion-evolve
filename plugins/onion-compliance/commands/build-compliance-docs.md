---
name: build-compliance-docs
description: Gerar arquitetura de compliance em `docs/compliance-context/`.
model: sonnet

parameters:
  - name: frameworks
    description: Frameworks (iso27001,soc2,iso22301,pmbok ou all)
    required: false
  - name: due_diligence
    description: Caminho para checklist de DD
    required: false

allowed-tools: Read Write Grep Glob Bash(grep *) Bash(find *) Bash(ls *)
category: docs
tags:
  - compliance
  - security
  - audit

version: "4.0.0"
updated: "2026-06-16"

related_commands:
  - /docs:build-tech-docs
  - /docs:build-business-docs

related_agents:
  - security-information-master
  - iso-27001-specialist
  - soc2-specialist
---

# 📋 Gerador de Documentação de Compliance

Criar documentação de conformidade para auditorias e certificações.

## 🎯 Objetivo

Gerar arquitetura completa de docs de compliance multi-framework.

## 🔧 Modos de Execução

```bash
# Modo 1: Seletivo
/docs/build-compliance-docs frameworks="iso27001,soc2"

# Modo 2: Due Diligence
/docs/build-compliance-docs due_diligence="path/to/checklist.md"

# Modo 3: Auto (analisa projeto)
/docs/build-compliance-docs

# Modo 4: Completo
/docs/build-compliance-docs frameworks="all"
```

## ⚡ Fluxo de Execução

### Passo 1: Detectar Modo

SE `{{frameworks}}` → Modo Seletivo
SE `{{due_diligence}}` → Modo DD (analisar checklist)
SENÃO → Modo Auto (analisar projeto)

### Passo 2: Selecionar Frameworks

| Framework | Foco | Quando Usar |
|-----------|------|-------------|
| ISO 27001 | Segurança da Info | Certificação, DD |
| ISO 22301 | Continuidade | DR, BCP |
| SOC2 | Trust Services | Clientes enterprise |
| PMBOK | Governança | Projetos |

#### Resolução de evidência conflitante

Fontes podem se contradizer (ex.: controles reais divergem da política escrita, ou docs antigas
descrevem um processo superado). Aplique esta **ordem de precedência** (mais forte → mais fraca):

1. Controles e configuração reais (o que está implementado e é auditável)
2. Políticas e registros vigentes marcados como atuais
3. Docs de compliance sem marcação de status
4. Docs marcadas como históricas/superadas → **não** usar como verdade atual

Registre o conflito explicitamente e sinalize a fonte desatualizada como follow-up, em vez de
propagar a contradição para a documentação gerada.

> **⚠️ Evidência de FORNECEDOR carrega interesse — a precedência acima ordena por *frescor*, não por
> *neutralidade*.** Relatório de pentest, laudo, parecer e certificação são autênticos e íntegros e ainda
> assim **calibrados** por quem os emite. Ao montar pacote de auditoria a partir deles, leia a
> **estrutura** antes de propagar a métrica: achados replicados por superfície (mesma classe por
> host/endpoint/formulário) inflam a contagem; severidade fora da faixa usual da classe é ênfase;
> **incentivo impresso no próprio texto** (reteste pago, etapa seguinte precificada) é evidência, não
> suspeita. O que o fornecedor **concede contra o próprio interesse** é a parte de maior confiança do
> documento. **Interesse qualifica a leitura, não a anula** — achado distinto e de lógica de negócio não
> se relativiza. Doutrina: [evidence-source-interest.md](../../../docs/knowledge-base/concepts/evidence-source-interest.md).

> **Modo não-interativo (infer-from-evidence).** Sem usuário disponível ou evidência completa,
> não bloqueie: infira a partir do repo e dos artefatos existentes, **marque cada inferência**
> com `[INFERIDO]` e liste as suposições numa seção "Pendências de validação" no `index.md`.
> Requisitos sem qualquer evidência viram `[TO BE COMPLETED]` — **nunca** invente conformidade.

### Passo 3: Delegar para Especialistas (Fan-Out Paralelo)

Os 4 especialistas são **independentes entre si** — sem dependência de ordem. Despachá-los em **paralelo** via orquestração (pattern `fan-out-and-synthesize`).

Use `/meta:orchestrate` ou a skill `onion-orchestration` para despachar em paralelo:

```
PARALELO (todos ao mesmo tempo, sem esperar o anterior):
  "iso27001" → @iso-27001-specialist
  "iso22301" → @iso-22301-specialist
  "soc2"     → @soc2-specialist
  "pmbok"    → @pmbok-specialist
```

> Despache apenas os especialistas cujos frameworks foram selecionados no Passo 2.
> Não há dependência entre eles — iniciar todos simultaneamente.

**Fan-in (síntese):** após todos finalizarem, `@security-information-master` consolida os resultados e segue para o Passo 4.

### Passo 4: Gerar Documentação

Gere os arquivos em `docs/compliance-context/` seguindo o template-base
`${CLAUDE_PLUGIN_ROOT}/templates/compliance-context-template.md`. Crie apenas os arquivos dos
frameworks selecionados.

> **Convenção de nomes (esta seção tem precedência sobre o template-base).** Use
> **kebab-case minúsculo** para todos os arquivos e pastas (`risk-assessment.md`,
> `trust-services.md`), exatamente como na estrutura abaixo. Se o template sugerir nomes em
> UPPERCASE, **ignore** — a estrutura deste comando é a autoritativa.

Estrutura de saída:
```
docs/compliance-context/
├── index.md
├── iso27001/
│   ├── policy.md
│   ├── risk-assessment.md
│   └── controls.md
├── soc2/
│   ├── trust-services.md
│   └── evidence.md
└── reports/
    └── summary.md
```

### Passo 5: Validar e Entregar

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ DOCS DE COMPLIANCE GERADOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Frameworks:
∟ ISO 27001: ✅ 12 documentos
∟ SOC2: ✅ 8 documentos

📁 Estrutura:
∟ docs/compliance-context/index.md
∟ docs/compliance-context/iso27001/ (12)
∟ docs/compliance-context/soc2/ (8)

📋 Cobertura:
∟ Políticas: 100%
∟ Controles: 85%
∟ Evidências: Template

🚀 Próximo: Revisar e customizar
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- **Template-base**: `${CLAUDE_PLUGIN_ROOT}/templates/compliance-context-template.md`
- **Pasta-alvo**: `docs/compliance-context/`
- **Comandos complementares**: `/docs:build-tech-docs` · `/docs:build-business-docs`
- **Ciclo de vida (SSOT viva)**: [domain-context-lifecycle.md](../../../docs/knowledge-base/concepts/domain-context-lifecycle.md)
- Orquestrador: @security-information-master · ISO 27001: @iso-27001-specialist · SOC2: @soc2-specialist

## ⚠️ Notas

- Não criar um único arquivo grande — sempre multi-arquivo linkado pelo `index.md`
- Docs gerados são templates base; customizar para o contexto específico antes de auditorias
- Marcar gaps como `[TO BE COMPLETED]` e inferências como `[INFERIDO]` — nunca inventar conformidade
- Regenerar quando controles, escopo ou frameworks mudam (contexto é SSOT viva, não snapshot)
