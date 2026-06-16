# Template de Arquitetura de Contexto de Compliance
*Framework estratégico para organizar conhecimento de conformidade, governança e auditoria para consumo por humanos e IA*

---

## Propósito Deste Template

Este template ajuda times de compliance, segurança e governança a projetar sua **Arquitetura de Contexto de Compliance** — a abordagem sistemática para organizar políticas, controles, avaliações de risco e evidências de modo que tanto auditores quanto IA consigam entender e navegar o estado de conformidade do projeto.

**Use este template para:**
- Estruturar documentação de compliance multi-framework (ISO 27001, ISO 22301, SOC2, PMBOK, etc.)
- Preparar material para auditorias e certificações
- Permitir que IA responda a perguntas de conformidade com rastreabilidade
- Escalar conhecimento de governança entre times
- Manter evidências e controles atualizados ao longo do tempo

> **Genérico por design.** Este template não assume um framework específico nem um setor. Preencha apenas as camadas e frameworks relevantes ao projeto-alvo (princípio de framework instalável — `architecture.md §3`).

---

## Perfil de Contexto de Compliance

### Fundação de Governança

- **Escopo de compliance:** `[Sistemas, processos e dados cobertos]`
- **Frameworks aplicáveis:** `[ex.: ISO 27001, SOC2 — ou "a definir"]`
- **Setor regulatório:** `[ex.: financeiro, saúde, SaaS — ou "não regulado"]`
- **Status de certificação:** `[planejado | em andamento | certificado | não aplicável]`
- **Última auditoria:** `[YYYY-MM ou "nenhuma"]`
- **Responsável (dono do contexto):** `[função/papel]`

---

## Princípios de Estrutura

**IMPORTANTE: crie uma estrutura multi-arquivo com um `index.md` que linka para arquivos separados por framework/camada. NÃO crie um único arquivo grande.**

**Convenção de nomes:**
- Use **kebab-case minúsculo** para todos os arquivos e pastas (`risk-assessment.md`, `trust-services.md`)
- Sem espaços, underscores ou UPPERCASE
- Nomes descritivos e focados no conteúdo de compliance

**Marcação de status e frescor (contexto é SSOT viva):**
- Cada arquivo carrega uma marcação `Última Atualização: YYYY-MM-DD`
- Lacunas conhecidas: `[TO BE COMPLETED]` com a evidência ou ação necessária
- Inferências sem confirmação: `[INFERIDO]`, sempre validáveis — **nunca** invente conformidade
- Veja [domain-context-lifecycle.md](../../../../docs/knowledge-base/concepts/domain-context-lifecycle.md) para a gramática completa do ciclo de vida

---

## Crie o Índice Primeiro

**Criar: `index.md`**
```markdown
# Contexto de Compliance

> Última Atualização: YYYY-MM-DD · Dono: [função]

## Perfil de Governança
[Inclua o perfil de contexto de compliance aqui]

## Frameworks
- [ISO 27001](iso27001/index.md)
- [SOC2](soc2/index.md)
- [Outros frameworks aplicáveis]

## Relatórios
- [Sumário de cobertura](reports/summary.md)

## Pendências de validação
- [Itens marcados como [TO BE COMPLETED] ou [INFERIDO]]
```

---

## Camadas por Framework

Para cada framework selecionado, crie uma pasta dedicada com os artefatos relevantes. A estrutura abaixo é um molde — adapte os nomes de arquivo ao vocabulário do framework, mantendo kebab-case.

### Camada 1: Políticas (`<framework>/policy.md`)
```markdown
# Política — [Framework]

## Objetivo e Escopo
O que a política cobre e por quê.

## Declarações de Política
Regras e compromissos formais.

## Papéis e Responsabilidades
Quem é responsável por quê.

## Revisão e Aprovação
Cadência de revisão e aprovador.
```

### Camada 2: Avaliação de Risco (`<framework>/risk-assessment.md`)
```markdown
# Avaliação de Risco — [Framework]

## Metodologia
Como riscos são identificados e pontuados.

## Inventário de Riscos
| Risco | Probabilidade | Impacto | Tratamento | Dono |
|-------|---------------|---------|------------|------|

## Riscos Residuais Aceitos
Riscos conscientemente aceitos e justificativa.
```

### Camada 3: Controles (`<framework>/controls.md`)
```markdown
# Controles — [Framework]

## Mapa de Controles
| Controle | Requisito | Status | Evidência | Última verificação |
|----------|-----------|--------|-----------|--------------------|

## Lacunas
Controles ausentes ou parciais → `[TO BE COMPLETED]`.
```

### Camada 4: Evidências (`<framework>/evidence.md`)
```markdown
# Evidências — [Framework]

## Catálogo de Evidências
Referências rastreáveis (logs, configs, registros) que sustentam cada controle.

## Coleta e Retenção
Como e por quanto tempo as evidências são mantidas.
```

---

## Relatórios Consolidados

**Criar: `reports/summary.md`**
```markdown
# Sumário de Compliance

> Última Atualização: YYYY-MM-DD

## Cobertura por Framework
| Framework | Políticas | Controles | Evidências |
|-----------|-----------|-----------|------------|

## Próximas Ações
Itens priorizados para fechar lacunas.
```

---

## Manutenção (ciclo de vida CRUD+)

O contexto de compliance é **SSOT viva**, não um snapshot de auditoria. Mantenha-o assim:

- **Dono e cadência:** atribua um responsável por framework; revise na cadência do ciclo de auditoria.
- **Gatilhos de atualização:** mudança de escopo, novo controle, incidente, nova versão do framework, auditoria concluída.
- **Remover é frescor:** evidência ou política superada **engana ativamente** — remova/atualize em vez de acumular.
- **Validar:** rastreabilidade (todo controle aponta evidência) + frescor (`Última Atualização` ≤ threshold) + ausência de contradição com `technical-context/` e `business-context/`.

---

## Checklist de Qualidade

- [ ] Cada afirmação de conformidade é rastreável a uma evidência real
- [ ] Lacunas marcadas com `[TO BE COMPLETED]`; inferências com `[INFERIDO]`
- [ ] Nenhuma conformidade inventada
- [ ] `index.md` é o único ponto de entrada; links funcionam
- [ ] Naming em kebab-case minúsculo
- [ ] Cada arquivo carrega `Última Atualização`
- [ ] Apenas frameworks/camadas relevantes ao projeto foram criados
