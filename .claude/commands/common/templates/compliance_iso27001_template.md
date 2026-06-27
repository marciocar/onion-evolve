# Template ISO/IEC 27001:2022 — SGSI (Sistema de Gestão de Segurança da Informação)
*Guia de estrutura para geração de documentação de compliance ISO 27001 pelo agente @iso-27001-specialist*

---

## Propósito Deste Template

Este template descreve **o que gerar** e **como estruturar** os artefatos de compliance ISO/IEC 27001:2022 no diretório `docs/compliance-context/security/` do projeto-alvo. Ele é lido pelo agente @iso-27001-specialist antes de criar qualquer arquivo.

**Princípio guia:** genérico por design. Não assume empresa, setor ou stack. O agente adapta o conteúdo ao contexto real do projeto (lendo `docs/technical-context/` e `docs/business-context/` quando disponíveis).

**Não invente conformidade.** Toda afirmação de controle implementado deve ser rastreável a evidência real ou marcada como `[INFERIDO]` / `[TO BE COMPLETED]`.

> **Veja também:** `compliance-context-template.md` — template genérico multi-framework que este especializa.

---

## Estrutura de Arquivos a Gerar

**Convenção:** kebab-case minúsculo para todos os arquivos e pastas. Estrutura multi-arquivo obrigatória — nunca um único arquivo monolítico.

```
docs/compliance-context/security/
├── index.md                        ← ponto de entrada; linka todos os demais
├── information-security-policy.md  ← Clause 5.2
├── risk-assessment.md              ← Clause 6.1.2 + ISO/IEC 27005:2022
├── asset-management.md             ← Annex A 5.9
├── access-control.md               ← Annex A 5.15–5.18
└── incident-response.md            ← Annex A 5.24–5.28
```

Cada arquivo carrega no cabeçalho:
```
> Última Atualização: YYYY-MM-DD · Referência: ISO/IEC 27001:2022 [Clause/Control]
```

---

## Arquivo 0: index.md

Ponto de entrada obrigatório. Gerado primeiro, atualizado após cada documento.

**Seções obrigatórias:**

```markdown
# Segurança da Informação — SGSI (ISO/IEC 27001:2022)

> Última Atualização: YYYY-MM-DD · Dono: [função/papel]

## Perfil de Governança
- Escopo: [sistemas, processos e dados cobertos]
- Status de certificação: [planejado | em andamento | certificado]
- Última auditoria: [YYYY-MM ou "nenhuma"]
- Responsável pelo SGSI: [função]

## Documentos do SGSI
| Documento | Referência ISO | Status |
|-----------|----------------|--------|
| [Política de Segurança](information-security-policy.md) | Clause 5.2 | |
| [Risk Assessment](risk-assessment.md) | Clause 6.1.2 | |
| [Gestão de Ativos](asset-management.md) | Annex A 5.9 | |
| [Controle de Acesso](access-control.md) | Annex A 5.15–5.18 | |
| [Resposta a Incidentes](incident-response.md) | Annex A 5.24–5.28 | |

## Statement of Applicability (SoA)
Sumário de cobertura do Annex A — ver seção dedicada em risk-assessment.md.
Controles implementados: [N]/93

## Cross-Reference SOC2
Ver mapeamento ISO 27001 ↔ SOC2 ao final de cada documento.

## Pendências de Validação
- Itens marcados [TO BE COMPLETED] ou [INFERIDO]
```

---

## Documento 1: information-security-policy.md

**Referência:** ISO/IEC 27001:2022 Clause 5.2 — Information Security Policy

**Seções obrigatórias (em ordem):**

1. **Propósito e Escopo**
   - Objetivo da política e o que ela cobre
   - Exclusões explícitas (se houver)
   - Relação com outros documentos do SGSI

2. **Princípios de Segurança (CIA Triad)**
   - Confidencialidade (Confidentiality): definição + controles aplicados
   - Integridade (Integrity): definição + controles aplicados
   - Disponibilidade (Availability): definição + controles aplicados

3. **Comprometimento da Alta Direção**
   - Declaração formal de compromisso (Clause 5.1)
   - Alocação de recursos e papéis

4. **Matriz de Responsabilidades**
   | Papel/Função | Responsabilidades de Segurança |
   |---|---|
   - Incluir: alta direção, responsável pelo SGSI, times técnicos, todos os colaboradores

5. **Princípios Operacionais**
   - Least Privilege, Need-to-Know, Segregation of Duties
   - Política de uso aceitável (Acceptable Use Policy)
   - Gestão de terceiros e fornecedores

6. **Revisão e Atualização**
   - Cadência de revisão (mínimo anual — Clause 5.2 e)
   - Aprovador e processo de aprovação

7. **Referências aos Controles (Annex A)**
   - Tabela listando controles diretamente sustentados por esta política
   - Exemplo: A.5.1, A.5.9, A.5.15, A.5.23, A.5.24

8. **Cross-Reference SOC2**
   - Mapeamento: Security Policies (CC9.9 / CC2.2)

---

## Documento 2: risk-assessment.md

**Referência:** ISO/IEC 27001:2022 Clause 6.1.2 + ISO/IEC 27005:2022

**Seções obrigatórias (em ordem):**

1. **Metodologia**
   - Framework: ISO/IEC 27005:2022
   - Escala de impacto: 1 (Baixo) → 4 (Crítico)
   - Escala de probabilidade: 1 (Raro) → 4 (Muito Provável)
   - Fórmula: `Risk Score = Impacto × Probabilidade`
   - Limiar de aceitação de risco (risk acceptance criteria — Clause 6.1.2 b)

2. **Tabela de Escala de Impacto**
   | Nível | Score | Critério |
   |-------|-------|----------|
   | Crítico | 4 | Perda de negócio, impacto legal/regulatório, exposição de dados sensíveis |
   | Alto | 3 | Impacto operacional significativo, degradação de serviços críticos |
   | Médio | 2 | Impacto operacional moderado, recuperável sem perda de dados |
   | Baixo | 1 | Impacto mínimo, autorreparável |

3. **Tabela de Escala de Probabilidade**
   | Nível | Score | Frequência |
   |-------|-------|-----------|
   | Muito Provável | 4 | > 1 vez/ano |
   | Provável | 3 | 1 vez a cada 2 anos |
   | Possível | 2 | 1 vez a cada 5 anos |
   | Raro | 1 | < 1 vez a cada 10 anos |

4. **Critérios de Tratamento**
   | Risk Score | Classificação | Ação Requerida |
   |------------|---------------|----------------|
   | 12–16 | Crítico | Tratamento imediato; escalar para alta direção |
   | 8–11 | Alto | Plano de tratamento em 30 dias |
   | 4–7 | Médio | Plano de tratamento em 90 dias |
   | 1–3 | Baixo | Aceitar ou monitorar; revisão anual |

5. **Risk Register**
   Gerar 10–15 riscos principais identificados para o projeto. Cada risco segue o padrão:

   ```
   ### Risco R-NNN: [Título curto]
   **Ativo afetado:** [nome do ativo]
   **Categoria de ameaça:** [externa | interna | ambiental | regulatória]
   **Ameaça:** [descrição da ameaça]
   **Vulnerabilidade:** [fraqueza explorada]
   **Impacto:** [Nível] ([score]) — [justificativa]
   **Probabilidade:** [Nível] ([score])
   **Risk Score:** [resultado] ([Crítico|Alto|Médio|Baixo])
   **Tratamento:** [mitigar | aceitar | transferir | evitar]
   - [ ] Controle 1 — [Status]
   - [ ] Controle 2 — [Status]
   **Risco Residual:** [score pós-tratamento] ([nível]) — [Aceitável | Monitorar]
   **Referência Annex A:** [A.X.YY]
   ```

   Categorias de ameaça a cobrir:
   - Acesso não autorizado a dados (unauthorized access)
   - Vazamento de credenciais (credential compromise)
   - Ataques de negação de serviço (DDoS)
   - Ransomware / malware
   - Insider threat (ameaça interna)
   - Falha de fornecedor / terceiro (supply chain)
   - Perda de disponibilidade (outage)
   - Não conformidade regulatória
   - Configuração insegura (misconfiguration)
   - Engenharia social / phishing

6. **Statement of Applicability (SoA)**
   Documentar todos os 93 controles do Annex A. Target mínimo: 78 controles (84%).

   Formato por grupo de controles:

   ```
   | Controle | Título | Aplicável | Status | Justificativa / Evidência |
   |----------|--------|-----------|--------|---------------------------|
   | A.5.1 | Políticas de segurança da informação | Sim | Implementado | information-security-policy.md |
   ```

   Status possíveis: `Implementado` | `Parcialmente Implementado` | `Planejado` | `Não Aplicável`
   Justificativa de "Não Aplicável" é obrigatória (Clause 6.1.3 d).

7. **Plano de Tratamento de Riscos (Risk Treatment Plan)**
   Tabela consolidada dos riscos Crítico e Alto com responsável, prazo e métrica de validação.

8. **Cross-Reference SOC2**
   | ISO 27001 | SOC2 Trust Service Criteria |
   |---|---|
   | Clause 6.1.2 (Risk Assessment) | CC3.1, CC3.2, CC9.1 |

---

## Documento 3: asset-management.md

**Referência:** ISO/IEC 27001:2022 Annex A 5.9 — Inventory of Information and Other Associated Assets

**Seções obrigatórias (em ordem):**

1. **Propósito e Escopo**
   - O que constitui um ativo de informação no contexto do projeto
   - Critérios de inclusão no inventário

2. **Data Classification Framework (Classificação de Dados)**

   | Nível | Nome | Exemplos | Controles Mínimos |
   |-------|------|----------|-------------------|
   | 4 | Crítico / Regulado | PII, dados de pagamento, registros de saúde | Criptografia AES-256, MFA, Segregation, CISO approval, Monitoramento contínuo |
   | 3 | Confidencial | Dados de clientes, registros financeiros, código-fonte | Need-to-know, Criptografia em repouso e trânsito, MFA, Audit logs |
   | 2 | Interno | Documentação interna, configurações não sensíveis | Acesso apenas autenticado, sem compartilhamento externo |
   | 1 | Público | Material de marketing, documentação pública | Nenhum controle especial |

3. **Inventário de Ativos de Dados (Data Assets)**
   Gerar 20–40 ativos. Tabela por categoria:

   | ID | Nome | Tipo | Classificação | Localização | Owner | Backup | Criptografia |
   |----|------|------|---------------|-------------|-------|--------|--------------|
   | DA-NNN | ... | ... | ... | ... | ... | ... | ... |

4. **Inventário de Ativos de Sistemas (System Assets)**
   | ID | Nome | Tipo | Classificação | SLA | Owner | Dependências |
   |----|------|------|---------------|-----|-------|--------------|
   | SA-NNN | ... | ... | ... | ... | ... | ... |

5. **Inventário de Ativos de Infraestrutura (Infrastructure Assets)**
   | ID | Nome | Tipo | Classificação | Redundância | Owner |
   |----|------|------|---------------|-------------|-------|
   | IA-NNN | ... | ... | ... | ... | ... |

6. **Ativos de Pessoas e Processos**
   - Papéis com acesso privilegiado (privileged access roles)
   - Processos críticos dependentes de segurança (deployment, backup, incident response)

7. **Lifecycle Management (Ciclo de Vida dos Ativos)**
   Descrever controles por fase:
   - Criação: registro obrigatório, classificação, designação de owner, aplicação de controles
   - Manutenção: revisão anual de classificação, validação de controles, atualização do inventário
   - Descarte: sanitização de dados (data sanitization), revogação de acessos, documentação do descarte

8. **Cross-Reference SOC2**
   | ISO 27001 | SOC2 |
   |---|---|
   | A.5.9 (Asset Inventory) | CC6.1, CC6.5 |
   | A.5.10 (Acceptable Use) | CC6.6 |

---

## Documento 4: access-control.md

**Referência:** ISO/IEC 27001:2022 Annex A 5.15–5.18 (Access Control, Identity Management, Authentication, Access Rights)

**Seções obrigatórias (em ordem):**

1. **Política de Controle de Acesso**
   - Princípio do Least Privilege (Privilégio Mínimo)
   - Princípio Need-to-Know
   - Segregation of Duties (Segregação de Funções) — quais funções são segregadas e por quê
   - Referência: A.5.15, A.5.16, A.5.17, A.5.18

2. **Autenticação de Usuários (User Authentication)**
   Descrever controles implementados:
   - Single Sign-On (SSO): provider, protocolos (SAML 2.0, OAuth 2.0, OIDC), cobertura
   - Multi-Factor Authentication (MFA): obrigatoriedade, métodos suportados, enforcement
   - Política de senhas (Password Policy): comprimento mínimo, complexidade, histórico, bloqueio
   - Gerenciamento de sessão: timeout, revogação, tokens

3. **Role-Based Access Control (RBAC)**
   Tabela de papéis definidos:

   | Role | Permissões | Sistemas Cobertos | Aprovador | Revisão |
   |------|------------|-------------------|-----------|---------|
   | [role] | [escopo de acesso] | [sistemas] | [função] | [cadência] |

   Incluir ao menos: Developer, DevOps/Infra, Support, Admin, CISO.

4. **Processo de Solicitação e Provisionamento de Acesso**
   - Fluxo de solicitação (quem solicita, quem aprova, quem provisiona)
   - Documentação obrigatória (ticket, justificativa, aprovação)
   - SLA de provisionamento

5. **Controle de Acesso à Rede (Network Access Control)**
   - VPN: obrigatoriedade para acesso remoto, MFA para VPN
   - IP allowlisting para sistemas críticos
   - Abordagem de firewall (default-deny / whitelist)
   - Segmentação de rede (produção vs staging vs desenvolvimento)

6. **Controle de Acesso Privilegiado (Privileged Access Management)**
   - Definição de acesso privilegiado no contexto do projeto
   - Controles adicionais: just-in-time access, session recording, aprovação dual
   - Referência: A.8.2 (Privileged Access Rights)

7. **Processo de Revisão de Acessos (Access Review)**
   - Frequência: trimestral (recertification) + imediata no offboarding
   - Responsável pela revisão (manager + security team)
   - Procedimento de offboarding: desativação de SSO, revogação de tokens, coleta de dispositivos

8. **Registros de Auditoria (Audit Logs)**
   - O que é logado (autenticações, acessos privilegiados, mudanças de permissão)
   - Retenção de logs (mínimo 12 meses)
   - Referência: A.8.15 (Logging), A.8.17 (Clock Synchronization)

9. **Cross-Reference SOC2**
   | ISO 27001 | SOC2 Trust Service Criteria |
   |---|---|
   | A.5.15 (Access Control) | CC6.1, CC6.2, CC6.3 |
   | A.5.16 (Identity Management) | CC6.2 |
   | A.5.18 (Access Rights) | CC6.3 |

---

## Documento 5: incident-response.md

**Referência:** ISO/IEC 27001:2022 Annex A 5.24–5.28 (Incident Management Planning, Assessment, Response, Learning, Evidence Collection)

**Seções obrigatórias (em ordem):**

1. **Definição de Incidente de Segurança**
   - Definição formal
   - Diferença entre evento (event), alerta (alert) e incidente (incident)
   - Categorias de incidente:
     - Breach (vazamento de dados)
     - Cyberattack (ataque cibernético: DDoS, ransomware, phishing, malware)
     - Insider Threat (ameaça interna)
     - Availability Issue (indisponibilidade crítica)
     - Supply Chain Compromise

2. **Matriz de Severidade**
   | Severidade | Critério de Classificação | Tempo de Resposta | Escalation |
   |------------|--------------------------|-------------------|------------|
   | P0 — Crítico | Dados sensíveis expostos, sistema crítico indisponível | 15 minutos | Alta direção + responsável SGSI |
   | P1 — Alto | Tentativa confirmada de breach, degradação severa | 1 hora | Responsável SGSI + liderança técnica |
   | P2 — Médio | Anomalia confirmada, indisponibilidade parcial | 4 horas | Equipe de segurança |
   | P3 — Baixo | Evento suspeito sem impacto confirmado | 24 horas | Analista de segurança |

3. **Canais de Reporte**
   - Email de segurança (24/7)
   - Canal de comunicação interna (ex.: Slack #security-incidents)
   - Sistema de tickets (task manager configurado)
   - Linha de emergência para P0/P1

4. **Processo de Resposta a Incidentes (6 Fases)**

   **Fase 1 — Detecção e Reporte (Detection & Reporting)**
   - Fontes de detecção: monitoramento automatizado, reporte manual, terceiros
   - SLA de detecção por severidade
   - Referência: A.5.24

   **Fase 2 — Triagem e Classificação (Triage & Classification)**
   - Validação (incidente real vs falso positivo)
   - Atribuição de severidade e categoria
   - Abertura de ticket e notificação de stakeholders
   - SLA: < 15 minutos para P0/P1
   - Referência: A.5.25

   **Fase 3 — Contenção (Containment)**
   - Ações por categoria de incidente
   - Preservação de evidências forenses antes de qualquer remediação
   - Isolamento de sistemas comprometidos
   - SLA: < 1 hora para P0/P1
   - Referência: A.5.26

   **Fase 4 — Erradicação (Eradication)**
   - Remoção da causa raiz (root cause)
   - Aplicação de patches e correções de configuração
   - Validação de limpeza

   **Fase 5 — Recuperação (Recovery)**
   - Reativação controlada de sistemas
   - Validação de integridade (checksums, testes funcionais)
   - Monitoramento intensivo pós-recuperação (24–48 h)
   - Referência: A.5.26

   **Fase 6 — Revisão Pós-Incidente (Post-Incident Review)**
   - Reunião de retrospectiva em até 72 horas após resolução
   - Conteúdo obrigatório: timeline, root cause analysis, lições aprendidas, action items
   - Documento de registro: `docs/security/incidents/[YYYY-MM-DD]-[incident-id].md`
   - Referência: A.5.27

5. **Runbooks por Tipo de Incidente**
   Gerar ao menos 3 runbooks com checklists acionáveis:

   ```
   ### Runbook: [Tipo de Incidente]
   **Severidade esperada:** [P0/P1/P2]
   **Gatilho:** [condição que aciona este runbook]

   #### Contenção
   - [ ] Passo 1
   - [ ] Passo 2

   #### Erradicação
   - [ ] Passo 1

   #### Comunicação
   - [ ] Notificar [papel] em até [tempo]
   - [ ] Avaliar obrigações regulatórias (LGPD/GDPR: 72h para notificação)

   #### Evidências a preservar
   - [ ] [tipo de evidência]
   ```

   Runbooks obrigatórios: Suspected Data Breach, Ransomware/Malware, DDoS Attack.

6. **Obrigações Regulatórias de Notificação**
   - LGPD (Brasil): notificação à ANPD em até 2 dias úteis para incidentes com risco relevante
   - GDPR (quando aplicável): 72 horas para notificação à autoridade supervisora
   - Notificação a titulares de dados: critérios e prazo
   - Referência: A.5.28

7. **Coleta e Preservação de Evidências (Evidence Collection)**
   - Procedimento de cadeia de custódia
   - Tipos de evidência: logs, imagens de disco, capturas de tráfego, screenshots
   - Retenção: mínimo 12 meses (ou conforme requisito regulatório)
   - Referência: A.5.28

8. **Cross-Reference SOC2**
   | ISO 27001 | SOC2 Trust Service Criteria |
   |---|---|
   | A.5.24–5.25 (Planning & Assessment) | CC7.3, CC7.4 |
   | A.5.26 (Response & Recovery) | CC7.5 |
   | A.5.27 (Lessons Learned) | CC7.5 |

---

## Mapeamento Completo — Annex A (93 Controles)

O SoA em `risk-assessment.md` deve cobrir todos os grupos. Referência rápida por grupo:

### Controles Organizacionais (A.5 — 37 controles)
A.5.1 Políticas de segurança da informação · A.5.2 Papéis e responsabilidades · A.5.3 Segregação de funções · A.5.4 Responsabilidades da direção · A.5.5 Contato com autoridades · A.5.6 Contato com grupos de interesse especial · A.5.7 Inteligência de ameaças · A.5.8 Segurança no gerenciamento de projetos · A.5.9 Inventário de ativos · A.5.10 Uso aceitável · A.5.11 Devolução de ativos · A.5.12 Classificação da informação · A.5.13 Rotulagem da informação · A.5.14 Transferência de informação · A.5.15 Controle de acesso · A.5.16 Gerenciamento de identidade · A.5.17 Informações de autenticação · A.5.18 Direitos de acesso · A.5.19 Segurança na cadeia de suprimentos · A.5.20 Acordos com fornecedores · A.5.21 Gerenciamento de segurança na TIC na cadeia de suprimentos · A.5.22 Monitoramento de serviços de fornecedores · A.5.23 Segurança para uso de serviços em nuvem · A.5.24 Planejamento e preparação para incidentes · A.5.25 Avaliação e decisão sobre incidentes · A.5.26 Resposta a incidentes · A.5.27 Aprendizado com incidentes · A.5.28 Coleta de evidências · A.5.29 Continuidade de negócios · A.5.30 Prontidão de TIC para continuidade · A.5.31 Requisitos legais, estatutários e regulatórios · A.5.32 Direitos de propriedade intelectual · A.5.33 Proteção de registros · A.5.34 Privacidade e proteção de PII · A.5.35 Revisão independente · A.5.36 Conformidade com políticas e normas · A.5.37 Procedimentos operacionais documentados

### Controles de Pessoas (A.6 — 8 controles)
A.6.1 Triagem · A.6.2 Termos e condições de emprego · A.6.3 Conscientização, educação e treinamento · A.6.4 Processo disciplinar · A.6.5 Responsabilidades após encerramento ou mudança · A.6.6 Acordos de confidencialidade · A.6.7 Trabalho remoto · A.6.8 Reporte de eventos de segurança

### Controles Físicos (A.7 — 14 controles)
A.7.1 Perímetros de segurança física · A.7.2 Entrada física · A.7.3 Proteção de escritórios, salas e instalações · A.7.4 Monitoramento físico de segurança · A.7.5 Proteção contra ameaças físicas e ambientais · A.7.6 Trabalho em áreas seguras · A.7.7 Mesa limpa e tela limpa · A.7.8 Localização e proteção de equipamentos · A.7.9 Segurança de ativos fora das instalações · A.7.10 Mídia de armazenamento · A.7.11 Utilitários de suporte · A.7.12 Segurança do cabeamento · A.7.13 Manutenção de equipamentos · A.7.14 Descarte ou reutilização segura de equipamentos

### Controles Tecnológicos (A.8 — 34 controles)
A.8.1 Dispositivos de endpoint · A.8.2 Direitos de acesso privilegiado · A.8.3 Restrição de acesso à informação · A.8.4 Acesso ao código-fonte · A.8.5 Autenticação segura · A.8.6 Gerenciamento de capacidade · A.8.7 Proteção contra malware · A.8.8 Gerenciamento de vulnerabilidades técnicas · A.8.9 Gerenciamento de configuração · A.8.10 Exclusão de informações · A.8.11 Mascaramento de dados · A.8.12 Prevenção de vazamento de dados (DLP) · A.8.13 Backup de informações · A.8.14 Redundância de instalações de processamento · A.8.15 Log (registro) · A.8.16 Atividades de monitoramento · A.8.17 Sincronização de relógios · A.8.18 Uso de programas utilitários privilegiados · A.8.19 Instalação de software em sistemas operacionais · A.8.20 Segurança de redes · A.8.21 Segurança de serviços de rede · A.8.22 Segregação de redes · A.8.23 Filtragem web · A.8.24 Uso de criptografia · A.8.25 Ciclo de vida de desenvolvimento seguro · A.8.26 Requisitos de segurança de aplicações · A.8.27 Arquitetura segura de sistemas · A.8.28 Codificação segura · A.8.29 Teste de segurança no desenvolvimento · A.8.30 Desenvolvimento terceirizado · A.8.31 Separação de ambientes · A.8.32 Gerenciamento de mudanças · A.8.33 Informações de teste · A.8.34 Proteção de sistemas de informação durante teste de auditoria

---

## Cross-Reference ISO 27001 ↔ SOC2 (~70% de sobreposição)

| Domínio ISO 27001 | Documento | SOC2 Trust Service Criteria | Sobreposição |
|---|---|---|---|
| Políticas de Segurança (A.5.1–5.2) | information-security-policy.md | CC2.2, CC9.9 | ~95% |
| Risk Assessment (Clause 6.1.2) | risk-assessment.md | CC3.1, CC3.2, CC9.1 | ~80% |
| Controle de Acesso (A.5.15–5.18) | access-control.md | CC6.1, CC6.2, CC6.3 | ~90% |
| Gestão de Ativos (A.5.9–5.13) | asset-management.md | CC6.1, CC6.5 | ~60% |
| Incident Response (A.5.24–5.28) | incident-response.md | CC7.3, CC7.4, CC7.5 | ~85% |
| Continuidade (A.5.29–5.30) | [TO BE COMPLETED se SOC2 Availability in scope] | A1.1, A1.2, A1.3 | ~75% |
| Criptografia (A.8.24) | access-control.md (seção) | CC6.1, CC6.7 | ~70% |
| Monitoramento (A.8.15–8.16) | incident-response.md (seção) | CC7.2 | ~80% |

**Estratégia de aproveitamento:** documentos ISO 27001 servem como base de evidência. Em auditorias SOC2, referenciar diretamente estes artefatos. Adicionar cross-references explícitos `> SOC2: [criteria]` ao final de cada seção relevante.

---

## Guidelines de Idioma

- **Seções descritivas, títulos de seção, texto corrido:** português brasileiro (PT-BR)
- **Termos técnicos de segurança:** preservar em inglês — exemplos: Risk Assessment, RBAC, MFA, SSO, ISMS, BIA, DLP, SoA, least privilege, need-to-know, threat intelligence, supply chain, runbook, patch, audit log, endpoint, firewall
- **Primeira menção de conceito:** formato híbrido — "Avaliação de Riscos (Risk Assessment)"
- **IDs de controle:** sempre no formato canônico ISO — A.5.15, A.8.24 (não "controle 5.15")
- **Status:** português — Implementado, Parcialmente Implementado, Planejado, Não Aplicável
- **Datas:** ISO 8601 — YYYY-MM-DD

---

## Checklist de Qualidade — Geração Completa

- [ ] `index.md` gerado primeiro e atualizado após cada documento
- [ ] 5 documentos criados em `docs/compliance-context/security/`
- [ ] Todos os arquivos em kebab-case minúsculo
- [ ] Cada arquivo carrega `Última Atualização: YYYY-MM-DD`
- [ ] Nenhuma conformidade inventada; lacunas marcadas `[TO BE COMPLETED]` ou `[INFERIDO]`
- [ ] Risk Register com 10–15 riscos baseados no contexto real do projeto
- [ ] Asset inventory com 20–40 ativos catalogados
- [ ] RBAC com papéis e permissões documentados
- [ ] Incident Response com 3+ runbooks com checklists
- [ ] SoA com 78+ controles do Annex A documentados (84% dos 93)
- [ ] Cross-references ISO 27001 ↔ SOC2 presentes em cada documento
- [ ] Idioma PT-BR com termos técnicos em inglês preservados
- [ ] `index.md` linka todos os 5 documentos com status atualizado
