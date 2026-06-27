# Compliance Context

> Arquitetura de contexto de compliance e governança do projeto — gerada e mantida pelo comando `/docs:build-compliance-docs`.

---

## Propósito

Esta pasta organiza o **contexto de compliance e governança** estruturado para consumo por IA e por humanos: frameworks regulatórios, controles de segurança da informação, continuidade de negócios, gestão de projetos e ética corporativa. É a **terceira camada peer** do Sistema Onion, equivalente em importância a `docs/business-context/` e `docs/technical-context/`.

Use quando o projeto-alvo precisa demonstrar conformidade com frameworks regulatórios (ISO 27001, ISO 22301, SOC2, PMBOK) ou estabelecer governança corporativa formal.

**Esta pasta deve permanecer vazia neste repositório-mãe.** Será populada quando o comando `/docs:build-compliance-docs` for executado em um projeto de desenvolvimento que tenha instalado o Onion e exija compliance.

---

## Estrutura esperada

```
docs/compliance-context/
├── README.md                       # este arquivo
├── index.md                        # índice navegável (gerado pelo comando)
│
├── 01-security/                    # Camada 1 — Segurança da Informação (ISO 27001)
│   ├── isms-policy.md              # Política de SGSI
│   ├── risk-assessment.md          # Análise de riscos
│   ├── access-control.md           # Controle de acesso
│   ├── incident-response.md        # Resposta a incidentes
│   └── controls/
│       └── <controle-X>.md
│
├── 02-continuity/                  # Camada 2 — Continuidade de Negócios (ISO 22301)
│   ├── bcms-policy.md              # Política de BCMS
│   ├── business-impact-analysis.md # BIA
│   ├── continuity-plans.md         # BCP
│   ├── disaster-recovery.md        # DRP
│   └── rto-rpo.md                  # Objetivos de tempo/ponto de recuperação
│
├── 03-soc2/                        # Camada 3 — Trust Services Criteria (SOC2 Type II)
│   ├── security.md                 # Critério de Segurança
│   ├── availability.md             # Critério de Disponibilidade
│   ├── confidentiality.md          # Critério de Confidencialidade
│   ├── processing-integrity.md     # Critério de Integridade
│   ├── privacy.md                  # Critério de Privacidade
│   └── evidence/                   # Evidências coletadas
│       └── <controle>-<periodo>.md
│
├── 04-governance/                  # Camada 4 — Governança (PMBOK + Corporate)
│   ├── change-management.md
│   ├── quality-management.md
│   ├── stakeholder-management.md
│   ├── risk-management.md
│   └── ethics-anti-corruption.md
│
└── 05-audit/                       # Camada 5 — Auditoria e Evidência
    ├── audit-trail.md
    ├── compliance-calendar.md
    └── findings/
        └── <YYYY-MM>-<framework>.md
```

> Cada camada é ativada conforme aplicabilidade ao projeto. Projetos pequenos podem ter só `01-security/`. Projetos regulados em saúde geralmente combinam ISO 27001 + SOC2. Projetos financeiros podem precisar de ISO 27001 + ISO 22301. Decisão guiada por `/docs:build-compliance-docs` durante a fase de discovery.

---

## Como gerar / atualizar

```bash
/docs:build-compliance-docs <fontes-de-input>
```

O comando faz três fases:

1. **Detecção de framework** — `@security-information-master` orquestra identificação de quais frameworks aplicam ao projeto-alvo (matriz: setor + tamanho + clientes + dados manipulados)
2. **Discussão** — pergunta ao usuário sobre escopo, controles em vigor, gaps conhecidos, certificações almejadas
3. **Geração** — escreve os arquivos delegando para especialistas conforme framework:
   - ISO 27001 → `@iso-27001-specialist`
   - ISO 22301 → `@iso-22301-specialist`
   - SOC2 → `@soc2-specialist`
   - PMBOK → `@pmbok-specialist`
   - Compliance corporativo (anticorrupção, PLD/KYC) → `@corporate-compliance-specialist`

---

## Princípios

- **Evidência primeiro**: toda afirmação de controle deve ter evidência rastreável (log, política, treinamento, configuração)
- **Multi-arquivo, não monolito**: cada controle é um arquivo focado para facilitar auditoria
- **Otimizado para IA e auditores**: estrutura previsível, terminologia padronizada por framework, mapeamento cruzado entre frameworks quando aplicável
- **Vivo**: regenerar/atualizar a cada mudança de escopo, novo controle implementado ou achado de auditoria
- **Separação de duties**: compliance é peer (não subordinado) a produto e engenharia

---

## Matriz de decisão — qual framework escolher

| Setor / Cenário | Framework primário | Frameworks complementares |
|---|---|---|
| SaaS B2B | SOC2 Type II | ISO 27001 |
| Saúde / health-tech | ISO 27001 + SOC2 | LGPD/HIPAA (não cobertos por agentes específicos) |
| Financeiro / fintech | ISO 27001 | ISO 22301, SOC2 |
| Governo / setor público | PMBOK + ISO 22301 | ISO 27001 |
| Startup early-stage | Compliance corporativo básico | ISO 27001 quando crescer |

Decisão final guiada por `@security-information-master` durante `/docs:build-compliance-docs`.

---

## Relação com outras pastas

| Pasta | Papel |
|---|---|
| `docs/compliance-context/` | **Esta pasta** — compliance, governança, frameworks regulatórios |
| `docs/business-context/` | Clientes, mercado, produto, comunicação |
| `docs/technical-context/` | Codebase, arquitetura, decisões técnicas |
| `docs/knowledge-base/` | Conhecimento de referência (frameworks, conceitos) |
| `docs/meta-specs/` | Constituição (L0) — regras imutáveis do framework Onion |

---

## Agentes consumidores

| Agente | Função | Framework |
|---|---|---|
| [@security-information-master](../../.claude/agents/compliance/security-information-master.md) | Orquestrador — detecta framework aplicável e delega | Todos |
| [@iso-27001-specialist](../../.claude/agents/compliance/iso-27001-specialist.md) | SGSI ISO 27001:2022 | ISO 27001 |
| [@iso-22301-specialist](../../.claude/agents/compliance/iso-22301-specialist.md) | BCMS ISO 22301:2019 | ISO 22301 |
| [@soc2-specialist](../../.claude/agents/compliance/soc2-specialist.md) | Trust Services Criteria | SOC2 Type II |
| [@pmbok-specialist](../../.claude/agents/compliance/pmbok-specialist.md) | PMBOK Guide 7th Edition | PMBOK |
| [@corporate-compliance-specialist](../../.claude/agents/review/corporate-compliance-specialist.md) | Anticorrupção, PLD/KYC, ética | Corporate |

---

## Referência

- KB de padrão de spec-as-code: [docs/sdaal/sdaal.md](../sdaal/sdaal.md)
- Guia de aplicação em projeto regulado: [docs/applying/applying-regulated.md](../applying/applying-regulated.md)

---

**Comando responsável**: `/docs:build-compliance-docs`
**Orquestrador**: `@security-information-master`
