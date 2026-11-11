---
title: Company Brain para quem não é dev — Slack primeiro, login por pessoa e permissão por papel
date: 2026-11-11
kg: docs/evolution/research/company-brain-non-devs-2026-11/company-brain-non-devs-2026-11.kg.yaml
run_id: "nenhum — sem run de Workflow: estudo orquestrado entre sessões (hub, kg-ssot, curadoria) com dois agentes de leitura de primárias"
tokens: 0
agents: 2
duration_min: 0
review_after: 2026-12-11
type: research
mode: decision
---

# Company Brain para quem não é dev

> Projeção do grafo: quem manda é o `.kg.yaml`. `tokens: 0` e `duration_min: 0` = **não medido** (os dois
> agentes de leitura rodaram sem contabilidade agregada); os relatórios deles estão em `data/primaries.md` e
> `data/claude-community.md`.

**A pergunta** (`Q_COMPANY_BRAIN_NAO_DEVS_1111`): como colaboradores que não são desenvolvedores consultam
e propõem mudança no Company Brain por Slack e pelo Claude desktop e celular, com permissão por papel e no
padrão que a auditoria cobra. O hub do primeiro cliente é o piloto.

## O que foi decidido (selos do maestro)

| Nó | Decisão |
|---|---|
| `D_PRIMEIRA_ENTREGA_SLACK_1111` | 1ª entrega é o bot do Slack; Claude desktop e celular vem em seguida |
| `D_LOGIN_PELO_PROVEDOR_DA_FAMILIA_1111` | login por pessoa emitido pelo provedor de identidade da família, papel no token |
| `D_PERMISSAO_ESTENDE_A_POLITICA_ATUAL_1111` | a permissão estende a política de áreas do kg-ssot, medida e testada antes de valer |
| `D_VERTICAL_COMPANY_BRAIN_CONTEXT_AGORA_1111` | o core abre a vertical `company-brain-context` com a persona dela |
| `D_VERSAO_REDIGIDA_E_GRAFO_PROPRIO_1111` | versão redigida é grafo próprio de nível menor, sem ponteiro para a fonte |
| `D_MATRIZ_DE_PAPEIS_V1_DO_PILOTO_1111` | a matriz do hub vale como v1, consultando o kg-ssot, e só depois do teste de zero vazamento; contas mistas |

## As peças (abertas, uma por card)

1. **Bot do Slack por eventos** (`Q_PECA_BOT_SLACK_POR_EVENTOS_1111`): Socket Mode, leitura só dos canais
   declarados, eventos ao hub pelo socket local, envio por política de tipo cobrada no serviço.
2. **MCP remoto com login por pessoa** (`Q_PECA_MCP_REMOTO_COM_LOGIN_POR_PESSOA_1111`): borda pública com
   TLS e o perfil OAuth do MCP, validando a audiência do token; login por link na web.
3. **Papel por identidade** (`Q_PECA_PAPEL_POR_IDENTIDADE_1111`): o papel vira grupos de área; a exceção
   do Crítico vai num grafo próprio em área separada, o que já se faz hoje
   (`E_KG_SSOT_LE_A_MATRIZ_V1_1111`). Faltam o log de leitura sem conteúdo, o relatório da matriz efetiva
   com diff e o merge protegido da política, depois da tag 4.49.0 do kg-ssot.
4. **Escrita com aprovação** (`Q_PECA_ESCRITA_COM_APROVACAO_1111`): quem não usa git propõe na área
   própria; a promoção ao canônico vira PR com gate e aprovação humana.
5. **A2A para contas pessoais** (`Q_PECA_A2A_PARA_CONTAS_PESSOAIS_1111`): o mesmo servidor, com o login
   próprio, e a sessão fala com o hub pela fila assinada que já existe.
6. **Vertical `company-brain-context`** (`Q_PECA_VERTICAL_COMPANY_BRAIN_CONTEXT_1111`).

## Critério de pronto do piloto

20 perguntas reais respondidas com fonte, zero vazamento entre papéis em teste dirigido, resposta em até
2 minutos e nenhuma escrita sem aprovação (`E_DADOS_DO_PILOTO_DO_PRIMEIRO_CLIENTE_1111`). O controle de
acesso segue a ISO/IEC 27001:2022 (5.15, 5.18, 8.2, 8.3) e a LGPD
(`E_CONTROLE_DE_ACESSO_NO_PADRAO_DE_AUDITORIA_1111`); a matriz concreta mora no repositório privado do
adotante.

## Mercado

Bot token é identidade de serviço; o Socket Mode dispensa URL pública, com entrega best-effort, ack em 3 s
e dedupe por `event_id`. O conector personalizado do claude.ai existe em todos os planos e exige servidor
alcançável pela internet; a spec MCP exige validar a audiência e proíbe repassar o token. No Team a URL do
conector é visível a todos, então a permissão tem de morar no servidor (`E_PRIMARIAS_…`,
`E_COMUNIDADE_CLAUDE_COMO_FRONT_1111`).

## NÃO-VERIFICADOS

- SCIM e device flow no Logto 1.46.0: não confirmados.
- Revogação: o token segue válido até expirar; a bancada de revogação ainda não existe.
- Matriz de clientes MCP (desktop, celular, Code) com login por pessoa: não medida.

## valeu-a-pena

Não medido em tokens. O estudo fechou seis selos e uma leitura do dono do motor de permissão num dia, e
deixou seis peças com nome para card.
