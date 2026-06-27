# Template de Contexto de Compliance — PMBOK Guide 7th Edition
*Guia de estrutura para o agente `@pmbok-specialist` gerar documentação de governança de projetos*

---

## Propósito deste template

Este template orienta a geração da camada de **Governança de Projetos** dentro de `docs/compliance-context/` de um projeto-alvo. Ele define quais documentos criar, quais seções são obrigatórias em cada um, como mapear os 12 Princípios e os 8 Performance Domains do PMBOK Guide 7th Edition, e como adaptar o conjunto ao contexto real do projeto (tailoring).

**Use este template para:**
- Estruturar documentação de governança de projetos auditável
- Mapear controles e processos aos 12 Princípios e 8 Domains do PMBOK 7th
- Preparar evidências de maturidade em gestão de projetos
- Permitir que IA responda a perguntas de governança com rastreabilidade

> **Genérico por design.** Este template não assume empresa, setor, stack técnica nem metodologia específica. O agente adapta cada seção ao contexto do projeto-alvo durante a geração (ver seção Tailoring).

---

## Princípios de Estrutura

**Multi-arquivo, nunca monolito.** Crie um `index.md` que linka para os demais documentos. Cada documento trata de um domínio de governança específico.

**Convenção de nomes:**
- Use **kebab-case minúsculo** para todos os arquivos e pastas
- Sem espaços, underscores ou UPPERCASE
- Exemplos corretos: `project-governance.md`, `risk-management.md`, `change-management.md`

**Marcação de estado:**
- `Última Atualização: YYYY-MM-DD` em todo arquivo
- Lacunas conhecidas: `[A COMPLETAR]` com a evidência ou ação pendente
- Inferências sem confirmação documental: `[INFERIDO]` — nunca invente conformidade

**Idioma:** Todo conteúdo gerado em **PT-BR**. Termos técnicos consagrados (Project Charter, RFC, Change Request, Backlog, Sprint, Definition of Done, RACI, DORA, stakeholder) são mantidos em inglês por convenção de mercado.

---

## Estrutura de Arquivos a Gerar

```
docs/compliance-context/project-management/
├── index.md                    # índice navegável — criar primeiro
├── project-governance.md       # governança, RACI, PMO, lifecycle
├── change-management.md        # processo de mudança, CR, CI/CD
├── quality-management.md       # DoD, code review, quality gates, métricas
├── stakeholder-management.md   # identificação, engajamento, comunicação
└── risk-management.md          # risk register, matriz, categorias, mitigação
```

---

## Passo 1 — Criar o Índice

**Arquivo:** `index.md`

```markdown
# Governança de Projetos — PMBOK Guide 7th Edition

> Última Atualização: YYYY-MM-DD · Responsável: [função]

## Perfil de Governança

- **Metodologia principal:** [Agile / Scrum / Kanban / Híbrido / Waterfall]
- **Ciclo de entrega:** [Contínuo / Sprint de N semanas / Release mensal]
- **Maturidade PMO:** [Ad hoc / Suporte / Padrão / Otimizado]
- **Frameworks complementares:** [ex.: ISO 27001, ISO 22301 — ou "nenhum"]
- **Última revisão de governança:** [YYYY-MM ou "nenhuma"]

## Documentos

| Documento | Domínio PMBOK | Arquivo |
|-----------|---------------|---------|
| Governança de Projetos | Stakeholders, Team, Planning | [project-governance.md](project-governance.md) |
| Change Management | Development Approach, Change | [change-management.md](change-management.md) |
| Quality Management | Delivery, Measurement | [quality-management.md](quality-management.md) |
| Stakeholder Management | Stakeholders | [stakeholder-management.md](stakeholder-management.md) |
| Risk Management | Uncertainty | [risk-management.md](risk-management.md) |

## 12 Princípios PMBOK 7th — Cobertura

| # | Princípio | Documento principal |
|---|-----------|---------------------|
| 1 | Stewardship (Zelo) | project-governance.md |
| 2 | Team (Equipe) | project-governance.md |
| 3 | Stakeholders | stakeholder-management.md |
| 4 | Value (Valor) | project-governance.md |
| 5 | Holistic Thinking | project-governance.md |
| 6 | Leadership (Liderança) | project-governance.md |
| 7 | Tailoring (Adaptação) | project-governance.md |
| 8 | Quality (Qualidade) | quality-management.md |
| 9 | Complexity (Complexidade) | risk-management.md |
| 10 | Risk (Risco) | risk-management.md |
| 11 | Adaptability & Resilience | change-management.md |
| 12 | Change (Mudança) | change-management.md |

## 8 Performance Domains — Cobertura

| Domain | Documento(s) |
|--------|-------------|
| Stakeholders | stakeholder-management.md |
| Team | project-governance.md |
| Development Approach & Lifecycle | project-governance.md, change-management.md |
| Planning | project-governance.md |
| Project Work | quality-management.md |
| Delivery | quality-management.md |
| Measurement | quality-management.md |
| Uncertainty | risk-management.md |

## Pendências

- [ ] [A COMPLETAR] Itens identificados durante a geração

## Referências

- PMBOK Guide 7th Edition (2021), Project Management Institute
- Agile Practice Guide (PMI + Agile Alliance, 2017)
```

---

## Documento 1 — project-governance.md

**Domínios cobertos:** Team, Planning, Development Approach & Lifecycle
**Princípios cobertos:** 1 (Stewardship), 2 (Team), 4 (Value), 5 (Holistic Thinking), 6 (Leadership), 7 (Tailoring)

### Seções obrigatórias

**1. Framework de Governança**
- Modelo de PMO adotado (suporte, padrão ou controle) e justificativa
- Responsáveis pelo PMO virtual (papéis, não pessoas nominais)
- Responsabilidades do PMO: definir processos, monitorar métricas, facilitar retrospectivas, alinhar portfólio

**2. 12 Princípios — Aplicação ao Contexto**

Para cada princípio, descrever como ele se manifesta nas práticas do projeto:

| Princípio | Como se aplica | Evidência / Prática |
|-----------|----------------|---------------------|
| 1 — Stewardship | [uso eficiente de recursos, proteção de dados] | [A COMPLETAR] |
| 2 — Team | [ambiente colaborativo, RACI clara] | [A COMPLETAR] |
| ... | ... | ... |

**3. Matriz RACI**

Cobrir ao menos as atividades: Definição de Requisitos, Design Técnico, Implementação, Code Review, Testes (QA), Aprovação de Deploy, Gestão de Riscos, Comunicação de Status, Aprovação de Mudanças.

| Atividade | Responsável (R) | Autoridade (A) | Consultado (C) | Informado (I) |
|-----------|-----------------|----------------|----------------|---------------|

**4. Lifecycle de Projetos**

Descrever as fases adotadas pelo projeto (adaptar ao modelo real — não impor waterfall nem scrum):

| Fase | Objetivo | Entregáveis | Critério de saída |
|------|----------|-------------|-------------------|
| Discovery | Validar problema/oportunidade | Project Charter, Problem Statement | Aprovação do sponsor |
| Planning | Detalhar solução, estimar esforço | Design técnico (RFC), Backlog priorizado | Aprovação do responsável técnico |
| Execution | Desenvolver e testar | Incrementos funcionais | Sprint review aprovada |
| Release | Entregar funcionalidade | Feature ativa, documentação | Sign-off do responsável de produto |
| Closing | Avaliar sucesso, lições aprendidas | Retrospectiva, handoff | Aprovação dos stakeholders principais |

**5. Template: Project Charter**

```markdown
# Project Charter — [Nome do Projeto]

## 1. Metadados
- ID: PRJ-YYYYMMDD-XXX
- Data de início: YYYY-MM-DD
- Sponsor: [papel/função]
- Project Manager: [papel/função]

## 2. Problema / Oportunidade
[Contexto e justificativa para existência do projeto]

## 3. Objetivo e Entregável Principal
[O que será entregue ao final]

## 4. Escopo
- Inclui: [...]
- Exclui explicitamente: [...]

## 5. Restrições e Premissas
[Recursos, prazos, dependências externas]

## 6. Critérios de Sucesso
[Como saberemos que o projeto foi bem-sucedido]

## 7. Stakeholders principais
| Papel | Interesse | Nível de influência |
|-------|-----------|---------------------|

## 8. Aprovação
- Sponsor: _____________  Data: ___________
- Responsável técnico: _____________  Data: ___________
```

---

## Documento 2 — change-management.md

**Domínios cobertos:** Development Approach & Lifecycle, Change
**Princípios cobertos:** 11 (Adaptability & Resilience), 12 (Change)

### Seções obrigatórias

**1. Filosofia de Gestão de Mudanças**
- Posicionamento: mudança é esperada e gerenciada, não evitada
- Objetivo: minimizar impacto negativo, manter transparência

**2. Classificação de Mudanças**

| Tipo | Descrição | Exemplos | Aprovação |
|------|-----------|----------|-----------|
| Standard | Pré-aprovada, risco baixo | Deploy de hotfix, patch de dependência | Responsável técnico |
| Normal | Requer análise de impacto | Nova feature, refactoring significativo | Gestor de engenharia |
| Emergency | Urgente, risco imediato | Security patch crítico, P0 de produção | CTO / responsável máximo |

**3. Template: Change Request (CR)**

```markdown
# Change Request — CR-YYYYMMDD-XXX

## 1. Metadados
- CR ID: CR-YYYYMMDD-XXX
- Data: YYYY-MM-DD
- Solicitante: [papel]
- Projeto: [nome]
- Tipo: [Standard / Normal / Emergency]
- Prioridade: [Crítica / Alta / Média / Baixa]

## 2. Descrição da Mudança
[O que está sendo proposto]

## 3. Justificativa
[Por que é necessário — impacto de não fazer]

## 4. Análise de Impacto
- Escopo: [Adiciona / remove funcionalidades — quantificar se possível]
- Cronograma: [Impacto estimado em dias/semanas]
- Esforço: [Impacto em pessoas/horas]
- Qualidade: [Novos testes necessários]
- Riscos introduzidos: [Novos riscos ou mitigações existentes afetadas]
- Dependências: [Outros sistemas, times ou projetos afetados]

## 5. Alternativas Consideradas
[Outras abordagens avaliadas e por que foram descartadas]

## 6. Decisão
- [ ] Aprovado
- [ ] Rejeitado
- [ ] Adiado (nova data: _______)
- Responsável: [papel]
- Data: YYYY-MM-DD
- Justificativa: [breve]
```

**4. Fluxo de Aprovação**

Descrever o processo de submissão, análise (SLA: 24h úteis para Normal) e notificação de stakeholders.

**5. Estratégia de Rollback**

Descrever como mudanças são revertidas se necessário (feature flags, rollback de deploy, revert de merge).

---

## Documento 3 — quality-management.md

**Domínios cobertos:** Project Work, Delivery, Measurement
**Princípios cobertos:** 8 (Quality)

### Seções obrigatórias

**1. Filosofia de Qualidade**
- "Qualidade é construída no processo, não inspecionada ao final"
- Shift-left: testar o mais cedo possível
- Automação sobre inspeção manual

**2. Definition of Done (DoD)**

Definir o DoD em dois níveis:

**Feature-level DoD** — critérios que cada feature deve cumprir antes de ser considerada pronta:
- [ ] Código implementado conforme requisitos
- [ ] Testes unitários escritos (cobertura mínima: `[A COMPLETAR]`%)
- [ ] Code review aprovado por `[N]` revisores
- [ ] Testes de integração passando
- [ ] Documentação atualizada
- [ ] Performance validada (sem degradação > `[threshold]`%)
- [ ] Scan de segurança sem vulnerabilidades críticas
- [ ] `[A COMPLETAR]` — critérios específicos do projeto

**Sprint / Ciclo-level DoD** — critérios que encerram um ciclo de entrega:
- [ ] Todas as features com DoD completo
- [ ] Deploy em ambiente de homologação bem-sucedido
- [ ] Sign-off do responsável de produto
- [ ] Release notes preparadas

**3. Processo de Code Review**

| Critério | Descrição |
|----------|-----------|
| Funcionalidade | O código faz o que deveria? |
| Legibilidade | O código é compreensível e bem documentado? |
| Manutenibilidade | É fácil de modificar no futuro? |
| Performance | Não introduz gargalos? |
| Segurança | Sem vulnerabilidades aparentes? |
| Cobertura de testes | Cobertura adequada? |

- Mínimo de aprovadores: `[A COMPLETAR]`
- SLA de revisão: `[A COMPLETAR]` horas úteis

**4. Quality Gates**

Descrever os gates automáticos e manuais no pipeline de entrega:

| Gate | Momento | Verificações |
|------|---------|--------------|
| Pre-commit | Local, antes do push | Lint, formatação, testes unitários afetados |
| Pull Request | CI, ao abrir PR | Lint, testes, build, cobertura mínima, scan de segurança |
| Pre-deploy | Antes de staging/produção | Testes E2E críticos, testes de performance |
| Post-deploy | Após deploy em produção | Smoke tests, health checks, alertas de monitoramento |

**5. Métricas de Qualidade**

**DORA Metrics** (Four Key Metrics — referência: Accelerate, DORA Research):

| Métrica | Descrição | Target | Atual | Tendência |
|---------|-----------|--------|-------|-----------|
| Deployment Frequency | Frequência de deploys para produção | [A COMPLETAR] | [A COMPLETAR] | [A COMPLETAR] |
| Lead Time for Changes | Tempo do commit ao deploy em produção | [A COMPLETAR] | [A COMPLETAR] | [A COMPLETAR] |
| Mean Time to Recovery (MTTR) | Tempo médio para restaurar serviço após falha | [A COMPLETAR] | [A COMPLETAR] | [A COMPLETAR] |
| Change Failure Rate | % de deploys que causam falha ou rollback | [A COMPLETAR] | [A COMPLETAR] | [A COMPLETAR] |

**SPACE Framework** (dimensões de produtividade de engenharia — referência: Forsgren et al., 2021):

| Dimensão | Indicadores | Target |
|----------|-------------|--------|
| Satisfaction | Pesquisa de satisfação do time | [A COMPLETAR] |
| Performance | Tempo de turnaround de code review | [A COMPLETAR] |
| Activity | PRs mergeadas por semana | [A COMPLETAR] |
| Communication | Participação em RFCs | [A COMPLETAR] |
| Efficiency | Tempo de build | [A COMPLETAR] |

---

## Documento 4 — stakeholder-management.md

**Domínios cobertos:** Stakeholders
**Princípios cobertos:** 3 (Stakeholders)

### Seções obrigatórias

**1. Identificação de Stakeholders**

| Stakeholder | Interesse principal | Nível de influência | Estratégia de engajamento |
|-------------|---------------------|---------------------|---------------------------|
| [papel] | [o que importa para esse papel] | Alta / Média / Baixa | [abordagem] |

**2. Power-Interest Grid**

Classificar stakeholders nos quadrantes:
- Alto poder + alto interesse → Gerenciar de perto (parceiros-chave)
- Alto poder + baixo interesse → Manter satisfeitos
- Baixo poder + alto interesse → Manter informados
- Baixo poder + baixo interesse → Monitorar

```
        Alto Poder
            |
  Manter    |  Gerenciar
  Satisfeito| de Perto
────────────+────────────
  Monitorar |  Manter
            |  Informado
        Baixo Poder
            |
       Baixo  ←→  Alto
          Interesse
```

**3. Plano de Comunicação**

| Stakeholder | Frequência | Canal | Conteúdo | Responsável |
|-------------|-----------|-------|----------|-------------|
| [papel] | [diário/semanal/mensal] | [Slack/e-mail/reunião] | [tipo de informação] | [papel] |

**4. Template: Registro de Engajamento**

```markdown
## Engajamento — [Stakeholder] — YYYY-MM-DD

- Tipo de interação: [reunião / e-mail / demo / report]
- Participantes: [papéis]
- Pontos discutidos: [...]
- Decisões tomadas: [...]
- Ações resultantes: [responsável · prazo]
- Próxima interação prevista: YYYY-MM-DD
```

---

## Documento 5 — risk-management.md

**Domínios cobertos:** Uncertainty
**Princípios cobertos:** 9 (Complexity), 10 (Risk)

### Seções obrigatórias

**1. Filosofia de Gestão de Riscos**
- Proativo: identificar e planejar mitigações antes que o risco se materialize
- Oportunidades também são gerenciadas (riscos positivos)
- Risco residual aceito deve ser documentado explicitamente com justificativa

**2. Metodologia de Pontuação**

```
Risk Score = Probabilidade × Impacto

Probabilidade: 1 (< 20%) · 2 (20–40%) · 3 (40–60%) · 4 (60–80%) · 5 (> 80%)
Impacto:       1 (muito baixo) · 2 (baixo) · 3 (médio) · 4 (alto) · 5 (muito alto)
```

**3. Matriz de Risco**

| Probabilidade ↓ / Impacto → | 1 Muito Baixo | 2 Baixo | 3 Médio | 4 Alto | 5 Muito Alto |
|-----------------------------|---------------|---------|---------|--------|--------------|
| 5 Muito Alta | Médio | Médio | Alto | Crítico | Crítico |
| 4 Alta | Baixo | Médio | Alto | Alto | Crítico |
| 3 Média | Baixo | Baixo | Médio | Alto | Alto |
| 2 Baixa | Muito Baixo | Baixo | Baixo | Médio | Alto |
| 1 Muito Baixa | Muito Baixo | Muito Baixo | Baixo | Baixo | Médio |

**Estratégias de resposta por nível:**
- Crítico: mitigação imediata + plano de contingência obrigatório
- Alto: mitigação em até 30 dias + monitoramento semanal
- Médio: mitigação em até 90 dias + monitoramento mensal
- Baixo: aceitar ou monitorar sem ação imediata

**4. Template: Risk Register — entrada individual**

```markdown
### Risco R-XXX: [Nome curto e descritivo]

**Categoria:** [Técnico / Cronograma / Qualidade / Externo / Organizacional]
**Probabilidade:** [Muito Baixa / Baixa / Média / Alta / Muito Alta] (X%)
**Impacto:** [Muito Baixo / Baixo / Médio / Alto / Muito Alto]
**Risk Score:** [P × I = resultado] ([nível])

**Descrição:**
[Contexto e por que este risco existe]

**Condições de disparo:**
[Sinais observáveis que indicam que o risco está se materializando]

**Plano de Mitigação:**
- [ ] [ação · responsável · prazo]
- [ ] [ação · responsável · prazo]

**Plano de Contingência:**
Se o risco se materializar:
1. [passo 1]
2. [passo 2]

**Dono:** [papel]
**Revisão:** YYYY-MM-DD
**Status:** [Aberto / Em mitigação / Aceito / Encerrado]
```

**5. Categorias de Risco a Cobrir**

Catalogar ao menos 10 riscos, distribuídos entre:

- **Riscos técnicos:** escalabilidade, débito técnico, dependências de terceiros, segurança
- **Riscos de cronograma:** estimativas otimistas, escopo creep, disponibilidade de recursos
- **Riscos de qualidade:** cobertura de testes insuficiente, performance degradada, acessibilidade
- **Riscos externos:** SLA de fornecedores, mudanças regulatórias, movimentos competitivos
- **Riscos organizacionais:** rotatividade de time-chave, conflito de prioridades, comunicação inadequada

**6. Cadência de Revisão**

| Nível | Frequência de revisão |
|-------|-----------------------|
| Crítico | Semanal |
| Alto | Quinzenal |
| Médio | Mensal |
| Baixo | Trimestral |

---

## Tailoring — Como Adaptar ao Contexto do Projeto

O PMBOK 7th Edition valoriza **tailoring** (Princípio 7): o processo deve servir ao contexto, não o contrário. Ao gerar os documentos, o agente deve:

1. **Identificar a metodologia real** do projeto-alvo (Scrum, Kanban, SAFe, waterfall, híbrido) e refletir isso no lifecycle e no plano de comunicação — não assumir Scrum por padrão.

2. **Ajustar papéis ao organograma real** — se não houver CTO ou PMO, mapear os papéis equivalentes que existem. A RACI deve refletir a estrutura real, não um organograma ideal.

3. **Escalar a profundidade ao tamanho do projeto** — times pequenos podem colapsar stakeholder-management dentro de project-governance; times grandes podem precisar de subseções por área.

4. **Marcar lacunas honestas** — se informação não foi fornecida, marcar `[A COMPLETAR]` com orientação do que buscar, não inventar conformidade.

5. **Referenciar artefatos existentes** — se o projeto já tem um risk register em outra ferramenta, referenciar e não duplicar; se tem um Jira/ClickUp com backlog, linkear.

6. **Preservar termos técnicos em inglês** — Project Charter, RFC, Change Request, Definition of Done, Backlog, Sprint, RACI, DORA, stakeholder, feature flag: mantê-los em inglês mesmo em texto PT-BR.

---

## Checklist de Qualidade (geração concluída)

- [ ] `index.md` criado com links funcionais para os 5 documentos
- [ ] Todos os arquivos em kebab-case minúsculo dentro de `docs/compliance-context/project-management/`
- [ ] Cada arquivo carrega `Última Atualização: YYYY-MM-DD`
- [ ] 12 Princípios PMBOK 7th documentados (mapeados no `index.md` e detalhados no `project-governance.md`)
- [ ] 8 Performance Domains mapeados no `index.md`
- [ ] RACI Matrix completa e aderente ao organograma real do projeto
- [ ] Lifecycle adaptado à metodologia real (não assumido)
- [ ] Templates prontos para uso: Project Charter, Change Request, Risk Register
- [ ] Métricas DORA + SPACE com targets definidos (ou marcados `[A COMPLETAR]`)
- [ ] Risk Register com no mínimo 10 riscos catalogados
- [ ] Lacunas marcadas com `[A COMPLETAR]`; inferências com `[INFERIDO]`
- [ ] Nenhuma conformidade inventada
- [ ] Idioma PT-BR; termos técnicos em inglês preservados
- [ ] Pronto para consolidação no `index.md` da camada de compliance pelo orquestrador `@security-information-master`

---

## Referências Normativas

- PMI. *A Guide to the Project Management Body of Knowledge (PMBOK Guide) — Seventh Edition*. 2021.
- PMI. *Agile Practice Guide*. 2017.
- Forsgren, N. et al. *Accelerate: The Science of Lean Software and DevOps*. IT Revolution Press, 2018.
- Forsgren, N. et al. *The SPACE of Developer Productivity*. ACM Queue, 2021.
