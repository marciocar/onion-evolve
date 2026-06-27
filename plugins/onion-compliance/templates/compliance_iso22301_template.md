# Template ISO 22301:2019 — Sistema de Gestão de Continuidade de Negócios (BCMS)
*Guia estrutural para o agente @iso-22301-specialist gerar documentação auditável de continuidade de negócios no projeto-alvo*

---

## Propósito Deste Template

Este template orienta a geração da documentação de BCMS conforme ISO 22301:2019. Ele define a **estrutura dos documentos a criar**, as seções obrigatórias por documento, os modelos de BIA, RTOs/RPOs, estratégias de continuidade e o programa de testes.

**Use este template para:**
- Gerar os 5 documentos de continuidade de negócios e disaster recovery
- Produzir evidências auditáveis para due diligence e certificações
- Cobrir requisitos de clientes enterprise (ex.: Serasa Experian, bancos, seguradoras)
- Instalar o framework em qualquer projeto ou setor

> **Genérico por design.** Este template não assume empresa, setor, infraestrutura nem provedor de cloud. Substitua os placeholders `[NOME DA EMPRESA]`, `[SERVIÇO CRÍTICO]`, `[PRIMÁRIO]`, `[DR SITE]` etc. com os valores reais do projeto-alvo.

---

## Princípios de Estrutura

**IMPORTANTE: crie uma estrutura multi-arquivo com um `index.md` que linka para os 5 documentos separados. NÃO crie um único arquivo grande.**

**Convenção de nomes:**
- Use **kebab-case minúsculo** para todos os arquivos (`business-continuity-plan.md`, `recovery-objectives.md`)
- Sem espaços, underscores ou UPPERCASE
- Diretório de saída: `docs/compliance-context/business-continuity/`

**Marcação de status e frescor:**
- Cada arquivo carrega `Última Atualização: YYYY-MM-DD`
- Lacunas conhecidas: `[A COMPLETAR]` com a evidência necessária
- Inferências sem confirmação: `[INFERIDO]` — nunca invente conformidade
- Termos técnicos em inglês são mantidos: BCP, DRP, RTO, RPO, BIA, MTPD, BCT, CMT

---

## Passos de Preparação (antes de escrever)

Antes de gerar qualquer documento, o agente deve coletar contexto do projeto-alvo:

1. Ler `docs/technical-context/system-architecture.md` (componentes, infraestrutura, HA)
2. Ler `docs/business-context/` (processos críticos, receita, clientes-chave)
3. Buscar menções de SLA, disponibilidade, backup e replicação no repositório
4. Identificar serviços com dependências externas (third-party, pagamentos, DNS)
5. Determinar RTOs/RPOs realistas com base no BIA — não aspiracionais

---

## Estrutura Multi-arquivo: criar `index.md` primeiro

**Arquivo:** `docs/compliance-context/business-continuity/index.md`

```markdown
# Continuidade de Negócios — ISO 22301:2019

> Última Atualização: YYYY-MM-DD · Dono: [função/papel]
> Norma: ISO 22301:2019 · Apoio: ISO/TS 22317:2021 (BIA), ISO/TS 22318:2021 (supply chain)

## Perfil de Continuidade

- **Escopo:** [Sistemas, processos e dados cobertos]
- **Status BCMS:** [planejado | em implantação | operacional | certificado]
- **Última revisão:** [YYYY-MM]
- **Última simulação:** [YYYY-MM-DD]
- **Responsável (BC Coordinator):** [função]

## Documentos

| # | Documento | Arquivo | Cláusula ISO 22301 |
|---|-----------|---------|---------------------|
| 1 | Plano de Continuidade de Negócios (BCP) | [business-continuity-plan.md](business-continuity-plan.md) | Cláusula 8.4 |
| 2 | Plano de Recuperação de Desastres (DRP) | [disaster-recovery-plan.md](disaster-recovery-plan.md) | Cláusula 8.4 |
| 3 | Plano de Gerenciamento de Crise | [crisis-management.md](crisis-management.md) | Cláusula 8.4 |
| 4 | Testes de Resiliência | [resilience-testing.md](resilience-testing.md) | Cláusula 8.5 |
| 5 | Objetivos de Recuperação (RTOs/RPOs) | [recovery-objectives.md](recovery-objectives.md) | Cláusula 8.2 |

## Pendências de Validação

- [Itens marcados como [A COMPLETAR] ou [INFERIDO]]
```

---

## Documento 1: `business-continuity-plan.md`

**Propósito:** Plano abrangente para manter operações críticas durante e após disrupções.
**Cláusula ISO 22301:** 8.4

### Seções obrigatórias

#### 1.1 Resumo Executivo

```markdown
## Resumo Executivo

**Objetivo do BCP:**
Garantir continuidade das operações críticas de [NOME DA EMPRESA] durante eventos disruptivos,
minimizando impacto financeiro, operacional e reputacional.

**Escopo:**
- Processos críticos: [listar serviços e processos cobertos]
- Infraestrutura: [ambiente primário, replicação, serviços de terceiros]
- Pessoas: [times essenciais com papéis de resposta]

**Maximum Tolerable Period of Disruption (MTPD):**

| Classe de Processo | MTPD |
|--------------------|------|
| Crítico | [ex.: 2 horas] |
| Importante | [ex.: 8 horas] |
| Suporte | [ex.: 24 horas] |
```

#### 1.2 Business Impact Analysis (BIA)

Metodologia de referência: ISO/TS 22317:2021

**Passo 1 — Identificação de processos críticos**

```markdown
| Processo | Descrição | Criticidade | MTPD | Impacto se indisponível |
|----------|-----------|-------------|------|-------------------------|
| [Processo A] | [descrição] | Crítico | [tempo] | [impacto financeiro/operacional] |
| [Processo B] | [descrição] | Importante | [tempo] | [impacto] |
| [Processo C] | [descrição] | Suporte | [tempo] | [impacto] |
```

**Passo 2 — Análise de dependências**

Mapear o caminho crítico de dependências entre componentes. Identificar:
- Single Points of Failure (SPOFs)
- Dependências de terceiros sem substituto imediato
- Componentes com failover automático vs. manual

**Passo 3 — Quantificação de impacto**

```markdown
| Janela de Indisponibilidade | Impacto Financeiro | Impacto Operacional | Impacto Reputacional |
|-----------------------------|-------------------|---------------------|----------------------|
| < [limiar 1] | [faixa] | [descrição] | [nível] |
| [limiar 1] a [limiar 2] | [faixa] | [descrição] | [nível] |
| > [limiar 2] | [faixa] | [descrição] | [nível] |
```

**Passo 4 — RTOs/RPOs derivados do BIA**

Os RTOs e RPOs devem ser justificados pelo BIA, não definidos arbitrariamente. Cada objetivo deve ser rastreável ao impacto quantificado no passo 3.

```markdown
| Processo | RTO | RPO | Justificativa (baseada no BIA) |
|----------|-----|-----|-------------------------------|
| [Processo A] | [tempo] | [tempo] | [link para impacto do passo 3] |
```

#### 1.3 Estratégias de continuidade por cenário

Para cada cenário relevante ao projeto-alvo, descrever:

- **Probabilidade** (baixa / média / alta) e frequência estimada
- **Impacto** (crítico / alto / médio)
- **MTPD do cenário**
- **Estratégia** (tecnologia, processo e pessoas)
- **Sequência de ações** numerada com responsável e tempo estimado
- **RTO e RPO reais** alcançáveis com a estratégia

Cenários típicos a considerar (adaptar ao projeto):

| Cenário | Gatilho | Estratégia-base |
|---------|---------|-----------------|
| Falha de datacenter / região cloud | Indisponibilidade completa do site primário | Failover para site DR |
| Ataque cibernético (ransomware) | Sistemas comprometidos / cifrados | Isolamento + restore de backup imutável |
| Perda de pessoal-chave | Saída súbita ou incapacidade de membro crítico | Runbooks + cross-training + on-call rotation |
| Falha de fornecedor crítico | Indisponibilidade de serviço de terceiro (DNS, pagamento, CDN) | Fallback, substituto homologado, modo degradado |
| Incidente de segurança / violação de dados | Vazamento ou comprometimento de dados de clientes | Isolamento + plano de comunicação + notificação regulatória |
| Indisponibilidade de escritório | Desastre natural, pandemia, acesso bloqueado | Trabalho remoto total, split-team |

#### 1.4 Business Continuity Team (BCT)

```markdown
| Papel | Titular | Substituto | Responsabilidades principais |
|-------|---------|------------|------------------------------|
| BC Coordinator | [função] | [função] | Ativar BCP, coordenar equipes |
| Technical Lead | [função] | [função] | Executar recovery técnico |
| Communications Lead | [função] | [função] | Comunicação com stakeholders |
| Operations Lead | [função] | [função] | Manter operações essenciais |

**Matriz de contatos de emergência:**
| Nome | Celular | Email | Backup |
|------|---------|-------|--------|
| [membro] | [número] | [email] | [backup] |
```

#### 1.5 Ativação do BCP

Documentar:
- **Gatilhos** que justificam ativação formal
- **Processo de ativação** passo a passo (quem notifica quem, em quanto tempo)
- **Canais de war room** (chat, videoconferência, status page)
- **Cadência de status updates** durante o incidente
- **Critérios de desativação** e retorno à normalidade

---

## Documento 2: `disaster-recovery-plan.md`

**Propósito:** Plano técnico detalhado para restaurar infraestrutura e dados após desastre.
**Cláusula ISO 22301:** 8.4

### Seções obrigatórias

#### 2.1 Visão geral da estratégia DR

```markdown
## Estratégia DR

- **Site primário:** [localização / provedor / região]
- **Site DR:** [localização / provedor / região]
- **Arquitetura:** [Active-Active | Hot Standby | Warm Standby | Cold Standby]

**Tiers de recovery:**

| Tier | Criticidade | RTO | RPO | Estratégia |
|------|-------------|-----|-----|-----------|
| Tier 0 | Mission Critical | [tempo] | [tempo] | [estratégia] |
| Tier 1 | Critical | [tempo] | [tempo] | [estratégia] |
| Tier 2 | Important | [tempo] | [tempo] | [estratégia] |
| Tier 3 | Non-Critical | [tempo] | [tempo] | [estratégia] |
```

#### 2.2 Recovery de infraestrutura

Descrever:
- Topologia da infraestrutura primária e DR (redes, zonas, componentes)
- Abordagem de Infrastructure as Code (IaC) e como ela acelera o recovery
- Pré-requisitos para failover (réplica de banco saudável, credenciais acessíveis, DNS configurado)

#### 2.3 Estratégia de recovery de dados

```markdown
**Política de backup:**

| Tipo | Frequência | Retenção | Localização | RPO coberto |
|------|-----------|----------|-------------|-------------|
| [tipo A] | [frequência] | [período] | [local] | [tempo] |
| [tipo B] | [frequência] | [período] | [local] | [tempo] |
| Air-Gapped | Semanal | [período] | [local offline] | 7 dias |

**Validação de backups:**
- Teste de restore mensal (ao menos 1 sistema por ciclo)
- Validação de integridade (checksums)
- Drill completo conforme cronograma em resilience-testing.md
```

#### 2.4 Runbooks de disaster recovery

Cada runbook deve seguir o padrão abaixo. Criar ao menos 2 runbooks para os cenários de maior impacto.

```markdown
# [CÓDIGO]-[NOME]: [Cenário]

**Gatilho:** [condição que aciona este runbook]

**Pré-requisitos:**
- [ ] [pré-requisito 1]
- [ ] [pré-requisito 2]

**Passos:**
1. [ ] [ação] — Responsável: [papel] — Tempo estimado: [duração]
2. [ ] [ação] — Responsável: [papel] — Tempo estimado: [duração]
...

**Verificação pós-execução:**
- [ ] [health check 1]
- [ ] [health check 2]

**Rollback:** [o que fazer se o runbook falhar]

**RTO:** [tempo] | **RPO:** [tempo]
```

---

## Documento 3: `crisis-management.md`

**Propósito:** Coordenação estratégica, comunicação e tomada de decisão durante crises.
**Cláusula ISO 22301:** 8.4

### Seções obrigatórias

#### 3.1 Crisis Management Team (CMT)

Diferença de escopo:
- **BCT** (Business Continuity Team): foco operacional e técnico
- **CMT** (Crisis Management Team): foco estratégico, comunicação e decisão

```markdown
| Papel | Titular | Responsabilidades |
|-------|---------|-------------------|
| Crisis Manager | [função — ex.: CEO] | Decisões estratégicas, aprovações finais |
| Technical Lead | [função — ex.: CTO] | Assessoria técnica, coordenação BCT |
| Communications Director | [função] | Comunicação externa, mídia, clientes |
| Legal Advisor | [função/externo] | Compliance, regulatório, contratos |
| Customer Liaison | [função] | Comunicação com clientes-chave |

**Gatilhos de ativação da CMT:**
- [lista dos eventos que requerem envolvimento estratégico]
```

#### 3.2 Canais de comunicação durante crise

Documentar por audiência:
- **Clientes** (email, status page, calls individuais para enterprise)
- **Mídia** (apenas via Communications Director ou assessoria)
- **Reguladores** (ANPD, Banco Central, outros — via Legal + CEO)
- **Parceiros e fornecedores-chave** (Customer Liaison)
- **Internamente** (war room, canal dedicado, cadência de updates)

Para clientes enterprise com SLA formal, incluir:
```markdown
**Pontos de contato dedicados:**

| Cliente / Parceiro | Contato principal | Email | Celular | Canal prioritário |
|--------------------|------------------|-------|---------|-------------------|
| [nome do cliente] | [papel interno responsável] | [email] | [número] | [canal] |
```

#### 3.3 Playbooks de comunicação

Para cada tipo de crise, definir:
- Timeline de notificações (T+0, T+2h, T+24h, T+72h)
- Template de mensagem para cada audiência
- Aprovador da comunicação antes do envio

Crises típicas com playbooks:
- Violação de dados / data breach (obrigação LGPD em 72h para a ANPD)
- Indisponibilidade prolongada (> 4 horas)
- Incidente de segurança sem vazamento confirmado

#### 3.4 Matriz de decisão

```markdown
| Nível | Quem decide | Exemplos de decisão |
|-------|-------------|---------------------|
| Operacional | BCT | Failover técnico, restore de backups, escalar recursos |
| Tático | CMT | Comunicação externa, contratar suporte externo, RTO revisado |
| Estratégico | CEO/Diretoria | Notificação regulatória, ações legais, anúncios públicos |
```

---

## Documento 4: `resilience-testing.md`

**Propósito:** Programa de testes de resiliência e registro de evidências auditáveis.
**Cláusula ISO 22301:** 8.5

### Seções obrigatórias

#### 4.1 Programa de testes

```markdown
| Tipo de Teste | Frequência | Escopo | Duração estimada | Responsável |
|---------------|------------|--------|-----------------|-------------|
| Tabletop Exercise | Trimestral | CMT + BCT | 2 horas | BC Coordinator |
| Technical DR Drill | Semestral | Time técnico | 4 horas | Technical Lead |
| Full-Scale Simulation | Anual | Toda a organização | 1 dia | CEO + Technical Lead |
| Component Testing | Mensal | Componentes individuais | 1 hora | Time de operações |
```

#### 4.2 Registro de evidências (template por exercício)

Cada teste deve gerar um registro com a estrutura abaixo. Guardar evidências anexas (logs, screenshots, gravações de war room).

```markdown
# Exercício [TIPO] — [YYYY-MM-DD]: [Nome do Cenário]

**Data:** [data e horário, fuso]
**Cenário simulado:** [descrição]
**Objetivo:** [o que se quer validar]

**Participantes:**
- CMT: [lista de papéis]
- BCT: [lista de papéis]
- Observadores: [auditoria interna, terceiros]

**Timeline do exercício:**

| Tempo | Evento | Responsável | Resultado |
|-------|--------|-------------|-----------|
| T+0 | [início da simulação] | Facilitador | [ok / falha] |
| T+Xmin | [evento] | [papel] | [resultado] |

**RTO alcançado:** [tempo] (meta: [meta]) — [dentro / fora do objetivo]
**RPO alcançado:** [tempo] (meta: [meta]) — [dentro / fora do objetivo]

**Gaps identificados:**
1. [gap] — severidade: [alta / média / baixa]

**Plano de ação:**
| Item | Responsável | Prazo | Status |
|------|-------------|-------|--------|
| [ação] | [papel] | [data] | [aberto / concluído] |

**Aprovações:**
- BC Coordinator: [nome] — [data]
- Technical Lead: [nome] — [data]
- CEO/Diretoria: [nome] — [data]

**Anexos:**
- [logs, screenshots, gravações]
```

#### 4.3 Cronograma de testes (ano corrente)

```markdown
| Data prevista | Tipo | Cenário | Participantes | Status |
|---------------|------|---------|---------------|--------|
| [YYYY-MM-DD] | Tabletop | [cenário] | CMT | Planejado |
| [YYYY-MM-DD] | Component | [componente] | Ops | Planejado |
| [YYYY-MM-DD] | Technical Drill | [cenário] | BCT | Planejado |
| [YYYY-MM-DD] | Full-Scale | [cenário principal] | Todos | Planejado |
```

---

## Documento 5: `recovery-objectives.md`

**Propósito:** Política de backup e restauração com RTOs e RPOs definidos por criticidade.
**Cláusula ISO 22301:** 8.2

### Seções obrigatórias

#### 5.1 Política de backup e restauração

```markdown
## Política de Backup e Restauração

**Objetivo:** Garantir recuperação de dados e sistemas dentro dos objetivos definidos,
minimizando perda de dados e tempo de indisponibilidade.

**Princípios:**
- Regra 3-2-1: 3 cópias, 2 tipos de mídia, 1 cópia offsite
- Imutabilidade: backups críticos são imutáveis (WORM)
- Criptografia: todos os backups criptografados em repouso e em trânsito
- Testabilidade: restore testado mensalmente; drill completo anual
```

#### 5.2 Definição de RTOs por tier

RTO (Recovery Time Objective): tempo máximo aceitável para restaurar um sistema ou processo após disrupção.

```markdown
| Tier | Criticidade | RTO | Justificativa (baseada no BIA) |
|------|-------------|-----|-------------------------------|
| Tier 0 | Mission Critical | [tempo] | [impacto financeiro direto — negócio para] |
| Tier 1 | Critical | [tempo] | [operações severamente impactadas] |
| Tier 2 | Important | [tempo] | [impacto operacional moderado] |
| Tier 3 | Non-Critical | [tempo] | [impacto mínimo] |

**RTOs por componente:**

| Componente | Tier | RTO | Estratégia de recovery |
|------------|------|-----|------------------------|
| [componente A] | 0 | [tempo] | [estratégia] |
| [componente B] | 1 | [tempo] | [estratégia] |
| [componente C] | 2 | [tempo] | [estratégia] |
```

#### 5.3 Definição de RPOs por tier

RPO (Recovery Point Objective): quantidade máxima de dados (em tempo) aceitável perder após disrupção.

```markdown
| Tier | Criticidade | RPO | Estratégia de backup |
|------|-------------|-----|----------------------|
| Tier 0 | Mission Critical | 0 (zero data loss) | Replicação síncrona contínua |
| Tier 1 | Critical | [tempo] | Replicação assíncrona + backup por hora |
| Tier 2 | Important | [tempo] | Backup a cada [N] horas |
| Tier 3 | Non-Critical | [tempo] | Backup diário |

**RPOs por componente:**

| Componente | Tier | RPO | Método de backup |
|------------|------|-----|-----------------|
| [componente A] | 0 | 0 | [replicação síncrona] |
| [componente B] | 1 | [tempo] | [método] |
| [componente C] | 2 | [tempo] | [método] |
```

#### 5.4 Matriz completa de backup

```markdown
| Sistema | Método | Frequência | Retenção | Localização | RPO | RTO | Último teste |
|---------|--------|------------|----------|-------------|-----|-----|--------------|
| [sistema A] | [método] | [freq] | [período] | [local] | [tempo] | [tempo] | [YYYY-MM-DD] |
| [sistema B] | [método] | [freq] | [período] | [local] | [tempo] | [tempo] | [YYYY-MM-DD] |
| Air-Gapped | Exportação manual | Semanal | [período] | [local offline] | 7d | [tempo] | [YYYY-MM-DD] |
```

---

## Guidelines de Idioma

**PT-BR é o idioma padrão** para todo o conteúdo dos documentos.

Exceções: os seguintes termos técnicos são mantidos em inglês por serem amplamente adotados na indústria e em auditorias internacionais:

| Termo mantido em inglês | Significado em PT-BR |
|------------------------|----------------------|
| BCP | Plano de Continuidade de Negócios |
| DRP | Plano de Recuperação de Desastres |
| BIA | Análise de Impacto no Negócio |
| RTO | Objetivo de Tempo de Recuperação |
| RPO | Objetivo de Ponto de Recuperação |
| MTPD | Período Máximo Tolerável de Interrupção |
| BCT | Time de Continuidade de Negócios |
| CMT | Time de Gerenciamento de Crise |
| WORM | Write Once Read Many (backup imutável) |
| SPOF | Single Point of Failure |

Nomes de serviços, provedores e tecnologias (AWS, Kubernetes, PostgreSQL etc.) são mantidos em inglês no contexto técnico.

---

## Checklist de Qualidade

- [ ] 5 documentos criados em `docs/compliance-context/business-continuity/`
- [ ] `index.md` com links funcionais para todos os 5 documentos
- [ ] Naming em kebab-case minúsculo
- [ ] Cada arquivo carrega `Última Atualização: YYYY-MM-DD`
- [ ] Idioma PT-BR respeitado (exceções da tabela acima permitidas)
- [ ] RTOs e RPOs justificados pelo BIA — não aspiracionais
- [ ] BCP contém BIA com impacto quantificado
- [ ] DRP contém ao menos 2 runbooks com passos executáveis
- [ ] Crisis Management contém matriz de decisão e playbook de comunicação
- [ ] Resilience Testing contém cronograma e template de evidência
- [ ] Recovery Objectives contém política de backup e matriz completa
- [ ] Nenhuma conformidade inventada — lacunas marcadas com `[A COMPLETAR]`
- [ ] Inferências marcadas com `[INFERIDO]`
- [ ] Todo controle aponta para uma evidência rastreável ou gap explícito

---

## Manutenção (ciclo de vida CRUD+)

Este contexto é **SSOT vivo**, não um snapshot de auditoria:

- **Dono e cadência:** atribuir BC Coordinator; revisão anual obrigatória (ISO 22301 Cláusula 9.1)
- **Gatilhos de atualização:** mudança de infraestrutura, novo cenário de risco, resultado de exercício, incidente real, renovação de certificação
- **Remover é frescor:** runbook desatualizado engana a equipe durante um incidente real — atualizar ou marcar como obsoleto imediatamente
- **Validação pós-exercício:** após cada drill, atualizar RTOs/RPOs alcançados, gaps e plano de ação nos documentos correspondentes

---

**Norma de referência:** ISO 22301:2019 (BCMS Requirements)
**Normas de apoio:** ISO/TS 22317:2021 (BIA), ISO/TS 22318:2021 (supply chain continuity)
**Idioma:** PT-BR (termos técnicos internacionais mantidos em inglês — ver tabela acima)
**Última Atualização:** 2026-06-27
