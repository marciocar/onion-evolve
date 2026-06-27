# Template SOC2 — Trust Services Criteria (AICPA)
*Guia estrutural para o agente @soc2-specialist gerar documentação de controles SOC2 Type II no projeto-alvo.*

---

## Propósito Deste Template

Este template descreve **quais documentos criar**, **quais seções cada documento deve conter** e **quais critérios de qualidade aplicar** ao gerar a documentação SOC2 do projeto-alvo em `docs/compliance-context/soc2/`.

**Use este template para:**
- Estruturar documentação auditável para SOC2 Type II (AICPA Trust Services Criteria)
- Preparar evidências coletáveis por controle durante o período de auditoria (6–12 meses)
- Registrar sobreposições com ISO 27001 (~70%) e ISO 22301 (~60%) para evitar duplicação de esforço
- Subsidiar due diligence enterprise (ex.: checklists de fornecedores que exigem relatório SOC2)

> **Genérico por design.** Este template não assume empresa, setor nem stack de tecnologia.
> Preencha apenas os TSC aplicáveis ao projeto-alvo. Lacunas conhecidas: `[A COMPLETAR]`.
> Inferências sem confirmação: `[INFERIDO]` — nunca invente conformidade.

---

## Princípios de Estrutura

**Estrutura multi-arquivo obrigatória.** Não crie um único arquivo grande.

**Convenção de nomes (kebab-case minúsculo):**
- `index.md` — ponto de entrada único, linka todos os demais
- `trust-services-criteria.md` — visão geral dos 5 TSC e preparação Type II
- `security-controls.md` — controles Common Criteria (CC)
- `availability-controls.md` — controles de disponibilidade (A), SLAs
- `confidentiality-controls.md` — controles de confidencialidade (C)
- `evidence-collection.md` — estratégia de coleta de evidências Type II

**Idioma:** Português brasileiro (PT-BR) para todo o conteúdo narrativo.
Termos técnicos do framework permanecem em inglês: Trust Services Criteria, Common Criteria, Type I/II, SOC2, AICPA, RPO, RTO, MFA, RBAC, DLP, SLA, IaC, SIEM.

**Marcação de frescor:**
- Cada arquivo: `> Última Atualização: YYYY-MM-DD · Dono: [função]`
- Lacunas: `[A COMPLETAR]` com a evidência ou ação necessária
- Inferências: `[INFERIDO]` — nunca afirmar conformidade sem base

---

## Passo 0 — Leitura de Contexto Existente

Antes de criar qualquer arquivo, o agente deve ler o contexto já disponível no projeto-alvo:

1. Ler `docs/compliance-context/` para identificar sobreposições com ISO 27001 e ISO 22301
2. Usar Grep para localizar menções a controles existentes (ex.: padrão `MFA|encryption|SLA|uptime|backup`)
3. Usar Grep para localizar arquitetura relevante (ex.: padrão `multi-AZ|load.balanc|replication|failover`)
4. Registrar sobreposições encontradas nas seções de cross-reference de cada documento

O agente **não deve duplicar** documentação que já existe — deve referenciar com link relativo.

---

## Documento 0: index.md

**Propósito:** Ponto de entrada único. Todo auditor ou leitor começa aqui.

**Seções obrigatórias:**

```markdown
# SOC2 — Trust Services Criteria

> Última Atualização: YYYY-MM-DD · Dono: [função/papel]

## Perfil de Preparação SOC2

- **Tipo de relatório almejado:** SOC2 Type II (período de auditoria: [YYYY-MM a YYYY-MM])
- **TSC selecionados:** [listar os princípios aplicáveis — ver seleção abaixo]
- **Status:** [planejado | em readiness | período de auditoria | relatório emitido]
- **Auditor externo:** [nome ou "a definir"]
- **Última auditoria:** [YYYY-MM ou "nenhuma"]

## Documentos

- [Trust Services Criteria — visão geral](trust-services-criteria.md)
- [Controles de Segurança (CC)](security-controls.md)
- [Controles de Disponibilidade (A)](availability-controls.md)
- [Controles de Confidencialidade (C)](confidentiality-controls.md)
- [Coleta de Evidências](evidence-collection.md)

## Sobreposições com Outros Frameworks

| Framework | Sobreposição estimada | Documentos relacionados |
|-----------|-----------------------|-------------------------|
| ISO 27001 | ~70% | [link] |
| ISO 22301 | ~60% | [link] |

## Pendências de Validação

[Listar itens marcados como [A COMPLETAR] ou [INFERIDO] nos documentos filhos]
```

---

## Documento 1: trust-services-criteria.md

**Propósito:** Visão geral dos 5 Trust Services Principles, seleção dos TSC aplicáveis ao projeto e preparação para o audit Type II. É o documento de referência para clientes enterprise e questionnaires de fornecedores.

### Seção 1 — O que é SOC2

Descrever brevemente:
- SOC2 como framework de auditoria da AICPA para service providers
- Diferença entre Type I (snapshot do design) e Type II (eficácia operacional por 6–12 meses)
- Por que Type II é o padrão exigido por clientes enterprise

Incluir tabela comparativa Type I vs Type II:

| Aspecto | Type I | Type II |
|---------|--------|---------|
| Escopo | Design dos controles | Design + eficácia operacional |
| Período | Ponto no tempo | 6–12 meses contínuos |
| Evidências | Políticas e documentação | Logs, tickets, testes, relatórios |
| Valor | Prova de conceito | Maturidade e confiança de clientes |

### Seção 2 — Os 5 Trust Services Principles

Para cada princípio: nome, descrição de uma linha, aplicabilidade, controles-chave com código TSC, e cross-reference com ISO 27001 ou ISO 22301 quando houver sobreposição.

**Princípio 1 — Security (Common Criteria, CC)**
Proteção contra acesso não autorizado (físico e lógico). Obrigatório para todos os service providers.
Controles-chave: CC1 (ambiente de controle), CC6 (acesso lógico, autenticação, criptografia, monitoramento), CC7 (operações e resposta a incidentes).
Cross-reference: ISO 27001 Controle de Acesso (~90% sobreposição).

**Princípio 2 — Availability (A)**
Sistema disponível para operação conforme SLAs acordados.
Aplicável quando o projeto oferece SLAs de uptime a clientes.
Controles-chave: A1.1 (arquitetura de alta disponibilidade), A1.2 (SLAs documentados e monitorados), A1.3 (planejamento de capacidade), A1.4 (gestão de incidentes), A2.1 (plano de recuperação de desastres).
Cross-reference: ISO 22301 DRP (~60% sobreposição).

**Princípio 3 — Processing Integrity (PI)**
Processamento completo, válido, preciso, oportuno e autorizado.
Aplicável quando o projeto processa transações financeiras ou dados críticos de negócio.
Controles-chave: PI1.1 (validação de dados), PI1.2 (tratamento de erros), PI1.3 (trilhas de auditoria transacional).
Nota: registrar explicitamente se este princípio é excluído do escopo e justificativa.

**Princípio 4 — Confidentiality (C)**
Informação confidencial protegida conforme comprometido.
Aplicável quando o projeto processa dados além de PII (segredos comerciais, dados proprietários de clientes).
Controles-chave: C1.1 (classificação de dados), C1.2 (NDAs e acordos com terceiros), C1.3 (prevenção de perda de dados — DLP), C1.4 (descarte seguro).
Cross-reference: ISO 27001 Gestão de Ativos (~70% sobreposição).

**Princípio 5 — Privacy (P)**
PII coletada, usada, retida, divulgada e descartada conforme política de privacidade.
Aplicável quando o projeto coleta ou processa dados pessoais.
Controles-chave: P1.1 (política de privacidade publicada), P1.2 (gestão de consentimento), P1.3 (direitos do titular — ex.: acesso, retificação, exclusão), P1.4 (política de retenção), P1.5 (transferências internacionais de dados).
Cross-reference: regulação local de proteção de dados aplicável.

### Seção 3 — Seleção de TSC do Projeto

Tabela com os 5 princípios, status (aplicável / excluído / [A COMPLETAR]) e justificativa para cada decisão.

### Seção 4 — Preparação para Audit Type II

Descrever:
- Timeline típico (readiness assessment → gap analysis → implementação → período de auditoria → relatório)
- Papéis envolvidos (responsável técnico, jurídico, auditor externo)
- Critério de conclusão: 12 meses de evidências contínuas coletadas e organizadas

---

## Documento 2: security-controls.md

**Propósito:** Documentar controles de Security (Common Criteria — CC), aplicáveis a todos os TSC.

### Seção 1 — Ambiente de Controle (CC1)

Para cada subcontrole documentar: descrição do controle, como está implementado no projeto (`[A COMPLETAR]` se ausente), e evidências coletáveis.

- CC1.1: Supervisão gerencial (responsável de segurança designado, revisões periódicas)
- CC1.2: Código de conduta e política de uso aceitável
- CC1.3: Competência e treinamento em segurança

### Seção 2 — Controles de Acesso Lógico (CC6)

Para cada controle: descrição, implementação no projeto, e evidências Type II (o que coletar, com qual frequência).

**CC6.1 — Restrição de acesso lógico**
Acesso a sistemas e dados restrito a usuários autorizados e autenticados.
Implementação: `[A COMPLETAR]` — descrever solução de SSO/IdP, RBAC, princípio do menor privilégio.
Evidências: lista de usuários ativos (mensal), exportação de configuração de roles (trimestral), relatório de revisão de acessos (trimestral).
Cross-reference: ISO 27001 A.5.15–5.18.

**CC6.2 — Autenticação**
Autenticação forte para identificação de usuários.
Implementação: `[A COMPLETAR]` — descrever política de senhas, MFA, proteção contra força bruta, gestão de sessão.
Evidências: configuração de política de autenticação, taxa de adoção de MFA (alvo: 100%), logs de tentativas falhas.

**CC6.6 — Criptografia**
Dados sensíveis criptografados em repouso e em trânsito.
Implementação: `[A COMPLETAR]` — descrever algoritmos (padrão: AES-256 em repouso, TLS 1.2+ em trânsito), gestão de chaves, criptografia de backups.
Evidências: status de criptografia de banco de dados, certificados TLS (validade e força), logs de rotação de chaves, relatórios de varredura de segurança.

**CC6.7 — Monitoramento de operações**
Atividades de sistema e usuário monitoradas e alertadas.
Implementação: `[A COMPLETAR]` — descrever centralização de logs, alertas configurados, retenção de logs (mínimo: 12 meses).
Evidências: política de retenção de logs, configurações de alertas, dashboards de monitoramento, tickets de alertas respondidos.

### Seção 3 — Resposta a Incidentes de Segurança (CC7)

**CC7.2 — Detecção e resposta a incidentes**
Incidentes de segurança detectados, reportados e respondidos tempestivamente.
Implementação: `[A COMPLETAR]` — descrever mecanismos de detecção (EDR, WAF, IDS), canal de reporte, plano de resposta a incidentes, obrigatoriedade de post-mortem.
Evidências: tickets de incidentes (contínuo), timelines de resposta, documentos de post-mortem, logs de alertas de detecção.
Cross-reference: ISO 27001 Gestão de Incidentes.

---

## Documento 3: availability-controls.md

**Propósito:** Documentar controles de Availability (A), incluindo arquitetura de alta disponibilidade, SLAs, planejamento de capacidade e recuperação de desastres.

### Seção 1 — Declaração de Disponibilidade

Registrar:
- Meta de uptime do projeto (ex.: 99.9% mensal = menos de 43 minutos de downtime/mês)
- Definição de "downtime" adotada (janelas de manutenção planejada excluídas ou não)
- Fórmula de cálculo: `Uptime% = (Minutos totais − Minutos de downtime) / Minutos totais × 100`

### Seção 2 — A1.1: Arquitetura de Alta Disponibilidade

Controle: infraestrutura projetada para eliminar pontos únicos de falha.
Implementação: `[A COMPLETAR]` — descrever redundância de zona/região, balanceamento de carga, auto-scaling, replicação de banco de dados, serviços stateless.
Evidências: Infrastructure as Code (IaC versionado), configurações de auto-scaling, health checks de load balancer, diagramas de arquitetura.

### Seção 3 — A1.2: SLAs Documentados e Monitorados

Controle: SLAs de disponibilidade documentados, monitorados por ferramenta externa e reportados a clientes.

**Tabela de SLAs do projeto:**

| Serviço | SLA de Uptime | Período | Penalidades |
|---------|---------------|---------|-------------|
| [A COMPLETAR] | [A COMPLETAR] | Mensal | [A COMPLETAR] |

**Monitoramento:**
Descrever ferramenta de synthetic monitoring externo (verificações a cada N minutos), status page público (endereço), e dashboard interno de SLA.

**Documentação contratual:**
Registrar a cláusula contratual que formaliza os SLAs — número da seção no contrato-padrão, texto da garantia de uptime, penalidades por descumprimento.
`[A COMPLETAR]` — citar seção do contrato ou DPA.

Evidências: relatórios mensais de uptime da ferramenta de monitoramento, histórico do status page, tickets de incidentes com impacto em SLA.

### Seção 4 — A1.3: Planejamento de Capacidade

Controle: capacidade monitorada e provisionada para evitar esgotamento de recursos.
Implementação: `[A COMPLETAR]` — descrever processo de forecasting, frequência de load testing, thresholds de alerta (ex.: >80% de utilização).
Evidências: documentos de planejamento de capacidade (trimestral), relatórios de load testing, gráficos de utilização de recursos, ações de escalonamento realizadas.

### Seção 5 — A1.4: Gestão de Incidentes de Disponibilidade

Controle: incidentes de disponibilidade detectados, comunicados e resolvidos dentro dos SLAs de resposta.
Implementação: `[A COMPLETAR]` — descrever SLA de detecção (ex.: <5 min), SLA de resposta do on-call (ex.: <15 min), cadência de atualização do status page durante incidente, processo de post-mortem.
Evidências: tickets de incidentes (contínuo), logs de notificação de on-call, histórico de atualizações do status page, documentos de post-mortem.

### Seção 6 — A2.1: Recuperação de Desastres (DR)

Controle: plano de DR documentado, com RTOs e RPOs definidos, testado periodicamente.
Implementação: `[A COMPLETAR]` — descrever site de DR (região/ambiente), RTO alvo, RPO alvo, procedimento de failover, frequência de simulações.
Evidências: documento do plano de DR, relatórios de simulação de DR (com RTOs/RPOs alcançados), runbooks de failover.
Cross-reference: ISO 22301 DRP (~60% sobreposição).

---

## Documento 4: confidentiality-controls.md

**Propósito:** Documentar controles de Confidentiality (C) para proteção de informações confidenciais além de PII.

### Seção 1 — C1.1: Classificação de Dados

Controle: dados classificados por nível de sensibilidade e protegidos conforme a classificação.
Implementação: `[A COMPLETAR]` — descrever níveis de classificação (ex.: público, interno, confidencial, crítico/regulado), controles por nível (criptografia, acesso, log de auditoria), ownership de ativos.
Evidências: política de classificação de dados, inventário de ativos (com classificação), configurações de controle de acesso por nível.
Cross-reference: ISO 27001 Gestão de Ativos (~70% sobreposição).

### Seção 2 — C1.2: NDAs e Acordos com Terceiros

Controle: terceiros com acesso a dados confidenciais assinam NDA ou DPA antes do acesso.
Implementação: `[A COMPLETAR]` — descrever processo de NDA para colaboradores (onboarding), DPA para fornecedores (processadores de dados), NDA para consultores.
Evidências: modelos de NDA/DPA aprovados pelo jurídico, NDAs assinados (com assinatura digital), DPAs com fornecedores de infraestrutura e SaaS.

### Seção 3 — C1.3: Prevenção de Perda de Dados (DLP)

Controle: exfiltração de dados confidenciais prevenida e detectada.
Implementação: `[A COMPLETAR]` — descrever controles de DLP adotados (email, endpoint, rede, cloud), padrões monitorados.
Evidências: configurações de DLP, alertas disparados, tentativas de exfiltração bloqueadas.

### Seção 4 — C1.4: Descarte Seguro

Controle: dados confidenciais descartados de forma segura ao final do ciclo de vida.
Implementação: `[A COMPLETAR]` — descrever processo para mídia digital (sanitização, deleção de chaves de criptografia), banco de dados (deleção + vacuuming + exclusão de snapshots), hardware (destruição física com certificado).
Evidências: política de retenção e descarte, logs de descarte (o quê, quando, por quem), certificados de destruição de hardware.

---

## Documento 5: evidence-collection.md

**Propósito:** Estratégia de coleta, armazenamento e organização de evidências para o período de auditoria SOC2 Type II (12 meses contínuos).

### Seção 1 — Filosofia de Evidências

Princípio central: toda evidência deve ser **coletável, verificável e imutável** — o auditor precisa checar a existência e integridade sem depender de memória da equipe.

Tipos de evidência aceitos:
- **Documentação:** políticas, procedimentos, runbooks versionados
- **Configuração:** exportações de sistema, Infrastructure as Code (Git)
- **Logs:** autenticação, acesso, eventos de segurança (retenção mínima 12 meses)
- **Tickets:** incidentes, mudanças, solicitações de acesso (rastreáveis no task manager)
- **Relatórios:** gerados por ferramentas de monitoramento, scanning, compliance
- **Artefatos:** resultados de testes, deployments, simulações de DR

### Seção 2 — Matriz de Evidências por Controle

Para cada controle relevante, registrar: tipo de evidência, frequência de coleta, responsável e local de armazenamento.

| Controle | Evidência | Frequência | Responsável | Armazenamento |
|----------|-----------|------------|-------------|---------------|
| CC6.1 — Acesso lógico | Lista de usuários ativos | Mensal | [A COMPLETAR] | [A COMPLETAR] |
| CC6.1 — RBAC | Exportação de configuração de roles | Trimestral | [A COMPLETAR] | [A COMPLETAR] |
| CC6.2 — MFA | Taxa de adoção de MFA | Mensal | [A COMPLETAR] | [A COMPLETAR] |
| CC6.6 — Criptografia | Status de criptografia de banco de dados | Mensal | [A COMPLETAR] | [A COMPLETAR] |
| CC6.7 — Monitoramento | Configuração de logging e alertas | Mensal | [A COMPLETAR] | [A COMPLETAR] |
| CC7.2 — Incidentes | Tickets de incidentes de segurança | Contínuo | [A COMPLETAR] | [A COMPLETAR] |
| A1.2 — SLAs | Relatórios de uptime (ferramenta externa) | Mensal | [A COMPLETAR] | [A COMPLETAR] |
| A1.3 — Capacidade | Gráficos de utilização de recursos | Mensal | [A COMPLETAR] | [A COMPLETAR] |
| A2.1 — DR | Relatório de simulação de DR | Anual | [A COMPLETAR] | [A COMPLETAR] |
| C1.1 — Classificação | Inventário de ativos com classificação | Trimestral | [A COMPLETAR] | [A COMPLETAR] |
| C1.2 — NDAs | NDAs assinados | Contínuo | [A COMPLETAR] | [A COMPLETAR] |

### Seção 3 — Automação de Coleta

Descrever a estratégia de automação do projeto-alvo para coleta mensal:

- Versionamento de IaC no Git (Terraform, Pulumi, CloudFormation) como evidência permanente de configuração
- Scripts de exportação periódica (listas de usuários, status de criptografia, relatórios de uptime)
- Armazenamento centralizado e imutável das evidências (ex.: bucket de object storage com versionamento habilitado e política de lifecycle) — estrutura sugerida: `audit-evidence/YYYY-MM/<controle>/`
- Ferramentas de compliance automatizado (se adotadas) que coletam evidências de forma contínua

Preencher com as soluções reais do projeto: `[A COMPLETAR]`.

### Seção 4 — Checklist de Preparação para Auditoria

**3 meses antes do audit:**
- [ ] Validar que 12 meses de evidências estão completos e organizados
- [ ] Identificar gaps de evidência e criar plano de fechamento
- [ ] Revisar políticas e procedimentos (atualizar `Última Atualização` em cada documento)
- [ ] Treinar equipe para entrevistas com auditor

**1 mês antes:**
- [ ] Organizar evidências por controle em pasta compartilhada acessível ao auditor
- [ ] Preparar narrativa de como cada controle funciona (não só o que existe, mas como opera)
- [ ] Validar imutabilidade dos logs (sem adulteração)
- [ ] Realizar dry-run de auditoria interna

**Durante o audit (2–4 semanas):**
- [ ] Disponibilidade dos responsáveis técnico, segurança e jurídico para entrevistas
- [ ] Responder pedidos de evidências adicionais em até [N] dias úteis
- [ ] Fornecer acesso de leitura a sistemas se solicitado pelo auditor

**Pós-audit:**
- [ ] Implementar recomendações do auditor (com prazo e responsável)
- [ ] Atualizar documentação com achados e melhorias
- [ ] Publicar / compartilhar relatório SOC2 com clientes enterprise (NDA se necessário)

---

## Sobreposição com Outros Frameworks

| Domínio SOC2 | Framework relacionado | Sobreposição estimada | Ação recomendada |
|---|---|---|---|
| Security (CC6, CC7) | ISO 27001 Controle de Acesso + Gestão de Incidentes | ~90% | Referenciar documentos ISO 27001 existentes; não duplicar |
| Confidentiality (C1) | ISO 27001 Gestão de Ativos | ~70% | Reutilizar inventário e política de classificação |
| Availability (A) | ISO 22301 DRP | ~60% | Reutilizar plano de DR e metas de RTO/RPO |
| Privacy (P) | Regulação local de proteção de dados | Variável | Referenciar DPO e documentação de privacidade |

---

## Checklist de Qualidade dos Documentos Gerados

- [ ] `index.md` criado como único ponto de entrada; todos os links funcionam
- [ ] 5 documentos filhos criados em kebab-case: `trust-services-criteria.md`, `security-controls.md`, `availability-controls.md`, `confidentiality-controls.md`, `evidence-collection.md`
- [ ] Cada arquivo carrega `> Última Atualização: YYYY-MM-DD · Dono: [função]`
- [ ] TSC aplicáveis declarados explicitamente; TSC excluídos justificados
- [ ] Todo controle tem pelo menos uma evidência coletável descrita
- [ ] Sobreposições com ISO 27001 e ISO 22301 registradas com link relativo (sem duplicação)
- [ ] Lacunas marcadas com `[A COMPLETAR]`; inferências com `[INFERIDO]`
- [ ] Nenhuma conformidade inventada sem base em evidência real do projeto-alvo
- [ ] Nomes de empresa, fornecedor ou stack tecnológica específica substituídos por descrições genéricas ou `[A COMPLETAR]`
- [ ] Idioma PT-BR; termos técnicos de framework em inglês
