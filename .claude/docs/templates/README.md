# 📋 Templates do Sistema Onion

> Templates estruturados com YAML front matter v2.0 para consumo por Claude Code.

## 🎯 Visão Geral

Este diretório guarda templates **realmente usados** por comandos do Onion. A curadoria de 2026-06 removeu os templates órfãos (sem referência por nenhum comando/agente): os antigos `execution-plan` e `phase-execution-prompt` (planejamento faseado migrou para [`/engineer/plan`](../../commands/engineer/plan.md) → [`/engineer/work`](../../commands/engineer/work.md) com worklog + `STATE.md`), e os `adr`/`guide`/`reference`/`solution` (peso morto, recuperáveis via git history).

## 📚 Templates Disponíveis

### 1. **analysis-template.md**
```yaml
type: analysis
category: documentation
complexity: Média (52 linhas YAML)
```

**Uso:** análises críticas, de implementação ou status de sistemas.

**Usado por:** [`/meta:analyze-complex-problem`](../../commands/meta/analyze-complex-problem.md) e [`/quick:analisys`](../../commands/quick/analisys.md).

**Principais seções:** Analysis Metadata · Severity Config · Status (overall/completion/actions/risks) · Tracking (fases, métricas).

**Capacidades AI:** auto-status, action tracking, métricas, priorização de riscos, sugestão de soluções.

## 🚀 Como Usar

```bash
# Análise de sistema
cp analysis-template.md analise-arquitetura-atual.md
```

Personalize o YAML front matter (`template.type`, `context`, `status`, `tracking`) e preencha as seções substituindo os placeholders `[VARIÁVEL]`.

## 🔗 Onde foram parar os outros tipos

| Preciso… | Use |
|----------|-----|
| 📋 Planejar/executar implementação faseada | [`/engineer/plan`](../../commands/engineer/plan.md) → `/engineer/work` (worklog + `STATE.md`; contrato em [gitflow-patterns.md §Contrato de Sessão](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento)) |
| 🏛️ Documentar decisão arquitetural (ADR) | [c4-adr-patterns.md](../../../docs/knowledge-base/architectures/c4-adr-patterns.md) |
| 📝 Criar guia / 📖 referência / 🔧 solução | KBs em [docs/knowledge-base/](../../../docs/knowledge-base/) via [`/meta:create-knowledge-base`](../../commands/meta/create-knowledge-base.md) |

---

**📦 Total de Templates:** 1
**🎨 Versão YAML:** 2.0
**📊 Última Atualização:** 2026-06-14

---

<div align="center">

**Sistema Onion** 🧅

</div>
