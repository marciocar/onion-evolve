---
title: Agente ou sessão dona de repo, e o que disso serve à sessão dona por peça
date: 2026-11-12
kg: docs/evolution/research/agent-repo-ownership-2026-11/agent-repo-ownership-2026-11.kg.yaml
run_id: wf_af517294-7a8
tokens: 2446025
agents: 58
duration_min: 6
review_after: 2027-02-10
type: research
mode: decision
---

# Agente ou sessão dona de repo

> Projeção do grafo `agent-repo-ownership-2026-11.kg.yaml`. A fonte é o grafo; este texto deriva dele.

**A pergunta** (`Q_AGENT_REPO_OWNERSHIP_1112`): existe em novembro de 2026 um padrão de mercado consolidado, com nome,
para um agente ou sessão persistente dona de repo ou componente, coordenada por um orquestrador? Ela veio do maestro em
2026-11-12, depois do selo `D_BACKBONE_OWNER_1112`: as peças estratégicas têm uma sessão Onion própria que as defende,
no molde do kg-ssot.

## A resposta

**Não há nome de mercado.** A ausência vale para as fontes lidas, e as lacunas estão contadas abaixo. O mercado trata o
agente como OBJETO governado, com dono humano ou grupo. Não existe agente dono de repo:

- **AGENTS.md** (`E_AGENTSMD_DIRECTORY_SCOPE_1112`, `E_AGENTSMD_NO_OWNER_FIELD_1112`): escopo de instrução por
  diretório, Markdown livre, sem campo de dono.
- **Backstage** (`E_BACKSTAGE_SPEC_OWNER_AIRESOURCE_1112`, `E_BACKSTAGE_AI_AS_RESOURCE_1112`): `spec.owner` é
  obrigatório em recurso de IA (skill, rule, servidor MCP) e aponta grupo ou usuário do catálogo.
- **Spotify Portal AI Explorer** (`E_SPOTIFY_PORTAL_OWNER_RESOLUTION_1112`,
  `E_SPOTIFY_PORTAL_OWNER_MUST_BE_CATALOG_1112`): o dono se resolve em ordem fixa (manifesto, CODEOWNERS,
  catalog-info.yaml, organização do GitHub) e para na primeira que responde. O dono tem de existir no catálogo, e a
  página não prevê aviso de recurso sem dono.
- **Agent teams do Claude Code** (`E_CC_AGENT_TEAMS_*_1112`): experimentais, desligados por padrão e efêmeros. O dono é
  uma partição de arquivos feita pelo lead, e o `/resume` não restaura os teammates.
- **Microsoft Entra Agent ID** (`E_ENTRA_AGENT_ID_THREE_ROLES_1112`, `E_ENTRA_PERSON_OVER_AUTOMATION_1112`): três
  papéis (Owner, Sponsor e Manager). A fonte é analista tier 5, e a primária não foi lida.
- **Mercado e capital** (`E_MERCADO_AGENT_OWNERSHIP_1112`): sem sinal. A tendência medida é a governança DE agentes,
  não a posse POR agentes.

## O que o Onion levou (`D_PIECE_FIELD_NOT_KIND_1112`)

Três formas foram transferidas. O resto (o aviso `PIECE_UNOWNED`, o desencontro de nome e o card de arranque) é
desenho do Onion, sem par de mercado.

| Forma do mercado | Fonte | No Onion |
|---|---|---|
| dono obrigatório que aponta entidade registrada | Backstage `spec.owner` | `owner_session` no members.yaml, o NOME de uma sessão |
| ordem fixa de resolução, parando na primeira | Spotify Portal AI Explorer | `owner_session` → `owners.tsv` → a sessão do core |
| patrocinador humano ao lado do dono | Entra Agent ID (Sponsor) | `sponsor: maestro` |

**Campo novo, não `kind:` novo.** O `purpose` do grafo falava em `kind: piece`. Antes de mudar, o core mediu: `kind:` é
a natureza do membro, um enum fechado no `members-validate.sh`, e a paridade de porta, os pins e o destino do
`/meta:adopt` o leem. As peças seguem adotantes. Por isso entraram `piece: true`, `owner_session` e `sponsor`.

**As peças declaradas:** `onion-kg-ssot`, `onion-curation` e `onion-messaging`. As worktrees `onion-kg-ssot-*` não são
peças. O `onion-bridge` não virou membro: ele é a infra que hospeda o endpoint A2A do core (`a2a.host`), e os
conectores dele ficam sob a peça `onion-messaging`, como diz o selo.

**Onde mora:** `.claude/validation/baton-pulse.sh` (classes `PIECE_*`), cláusula 8 de
`.claude/commands/common/prompts/baton-doctrine.md`, e os casos (ag) a (am) de `run_baton_pulse_selftests`.

## Lacunas (`E_LACUNAS_AGENT_OWNERSHIP_1112`)

A rodada teve 16 claims, das quais 12 foram confirmadas. Foram 0 refutadas por fonte fraca, 0 não verificadas e 0
reprovações recusadas. O corte por orçamento ficou em 43 fontes. Ficaram **sem julgamento**, nem a favor nem contra:
CODEOWNERS do GitHub como primária própria, OpsLevel, Cortex, GitHub Copilot coding agent e custom agents, Devin,
Factory droids, OpenHands, os projetos da AAIF além do AGENTS.md, e os papéis de dono em CrewAI, AutoGen e LangGraph.
A primária do Entra Agent ID não foi lida. Uma rodada que leia essas fontes pode achar um termo de fornecedor.

## Custo

| run | agentes | tokens | duração |
|---|---:|---:|---:|
| `wf_af517294-7a8` | 58 | 2.446.025 | cerca de 6 min |
