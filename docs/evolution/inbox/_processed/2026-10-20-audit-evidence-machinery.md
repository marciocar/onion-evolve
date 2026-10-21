---
title: "Maquinaria de auditoria contínua: de afirmação em texto a regra de evidência, coleta recorrente e resposta a questionários"
date: 2026-10-20
type: signal
kind: feature-request
from: brain-granaai (hub, vendor kg-ssot-v4.12.0)
to: [onion-evolve, onion-kg-ssot]
severity: medium
---

> **Redigido no core por ser repo público** (decisão do maestro de 2026-10-20 para sinais com postura de cliente): o nome do cliente, da contraparte, as contagens e as ferramentas internas foram generalizados. O original está no hub.

# Maquinaria de auditoria contínua no core

**Pedido do maestro (2026-10-20):** "isso sempre vai acontecer; temos que criar uma maquinaria para isso em conjunto com o
core, para o processo de auditoria, usando ou criando um framework de acordo com os padrões atuais e modernos, as
comunidades, os fóruns e os padrões de mercado em outubro de 2026, e manter-se atualizado."

## O caso real

Um adotante regulado recebeu um questionário de auditoria de segurança de uma contraparte do setor: algumas dezenas
de perguntas e um pedido de certificações, com prazo curto. A triagem no brain mostrou o problema comum a qualquer adotante regulado:

- **A wiki inteira afirma e não prova.** Os documentos de compliance quase não têm anexos nem imagens. Atas, listas de presença,
  relatórios e prints são citados e não existem. A maior parte das afirmações ligadas às perguntas contradiz o
  código ou outro documento, ou não tem evidência nenhuma.
- **Cada auditoria recomeça do zero.** Não há catálogo do que precisa ser provado, com que frequência e por quem.
- **Evidência sensível não pode ir ao git** (pentest, prints de nuvem, NDAs), mas precisa de integridade (hash) e de
  ponteiro rastreável.

## O que já foi feito no brain (dados, não maquinaria)

| Artefato | O que é |
|---|---|
| `docs/evolution/research/audit-evidence-frameworks-2026-10/` | pesquisa de mercado (grafo + README), out/2026 |
| `docs/compliance/graph/evidence-requirements.kg.yaml` | 21 regras `R_EVR_*` (`node_type: rule`) que `CONSTRAINS` a afirmação |
| `docs/compliance/graph/auditoria-2026-10.kg.yaml` | o questionário como grafo: pergunta → resposta → evidência → pedido ao dono → task manager |
| `docs/compliance/auditoria-2026-10/evidence-index.md` | índice de evidências: dono, local (repo ou Drive restrito), sha256, estado |

Os artefatos estão numa branch do hub, não versionados no core.

## O que a pesquisa recomenda

- **Fonte:** o KG-SSOT continua sendo a fonte. Proveniência por nó, no git.
- **Catálogo de evidências:** o Evidence Request List do SCF (2026.2). A licença é CC BY-ND, então o grafo guarda só o ID.
- **Intercâmbio:** OSCAL 1.2.3, só como exportação (Assessment Plan, Assessment Results, POA&M), validada com o
  compliance-trestle. O OSCAL não serve de armazenamento interno: o Lula 2 o abandonou e o FedRAMP 20x usa JSON próprio.
- **Respostas a questionários:** o CAIQ v4.1 como base, que já sai em JSON, YAML e OSCAL.
- **Conteúdo da evidência:** OCSF 1.9 para log e achado; CycloneDX 1.7 com VEX para vulnerabilidade.
- **Plataformas descartadas como base:** CISO Assistant, Comp AI e Probo guardam estado em banco próprio.
- **Sinal de mercado:** o FedRAMP 2026 exige estado validado nos últimos 7 dias. O mercado troca narrativa por indicador
  com evidência que máquina lê.

## O que proponho para o core (genérico) e o que fica no adotante

**No core Onion:**

1. **Vocabulário de evidência:** uma extensão `x_evidence_*` documentada, ou campos no contrato, com o kg-ssot. Campos:
   `evidence_type`, `oscal_method` (EXAMINE, INTERVIEW, TEST), `acceptance`, `frequency`, `owner_role`, `location`
   (ponteiro, nunca o conteúdo), `retention`, `source_norm` e `claim_class` (verificável, sem evidência, aspiracional,
   falsa).
   - Padrão de arestas: a regra `CONSTRAINS` a afirmação, e a evidência `SUPPORTS` a afirmação e `TRACES_TO` a regra.
2. **Radar lendo vencimento:** a evidência vence em `verified_at` + `frequency`. Evidência vencida e regra sem
   evidência entram na seção ESTADO.
3. **Comando de questionário**, por exemplo `/compliance:questionnaire`:
   - transforma o questionário recebido num grafo como o `auditoria`;
   - faz a triagem contra as regras e o grafo de compliance;
   - gera os pedidos aos donos e as tarefas no task manager;
   - consolida as respostas, com a regra "nenhum sim sem prova".
4. **Exportador OSCAL** (AR e POA&M) e **importador de catálogo** (SCF, CCM), que guarda só ID e título.
5. **Adaptador SDAAL `document-source`:** `outline`, `gdrive` e um `none` que recusa em vez de degradar. Ele tira um
   snapshot só de leitura dos documentos e anexos, com sha256 e manifesto, e mapeia para os nós de política.
   - Detecta drift pelo `updatedAt` e pelo hash.
   - Caso real: dezenas de documentos e centenas de citações na wiki.
6. **Gestão contínua:** cada regra com frequência vira uma tarefa recorrente no task manager, ligada ao nó, e cada coleta
   faz `SUPERSEDES` da anterior.
7. **Manter-se atualizado:** uma lista do que acompanhar, com `review_after`, no próprio grafo de pesquisa, e um passo no
   `/meta:kg-freshness` que lembra de rever. A lista:
   - releases do OSCAL, do compliance-trestle, do FedRAMP rules, do OCSF e do CycloneDX;
   - as publicações trimestrais do SCF e as da CSA;
   - as normas dos reguladores locais.

**No adotante:** as regras concretas, o mapeamento das normas locais (as normas do regulador e a lei de proteção de dados) para os controles, a
biblioteca de respostas e os ponteiros privados para as evidências.

## Pergunta ao core e ao kg-ssot

Os três desenham juntos, como no perfil do migrador? Proponho começar pelo item 1 (vocabulário, que afeta o contrato) e
pelo 2 (radar). O brain serve de caso real e devolve um antes e depois anonimizado quando pedirem. A fase 6 da sessão
`auditoria-2026-10` (gestão contínua) espera esse desenho para não criar maquinaria local que o core depois substitua.
