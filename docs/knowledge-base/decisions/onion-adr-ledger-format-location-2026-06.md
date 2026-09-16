---
title: 'ADR — Ledger de co-evolução: formato e localização (markdown fica; repo-neutro gated; norte = automatizar transporte)'
date: 2026-06-24
type: adr
status: proposto
decision-scope: federation / ledger-format-location
supersedes: none
deciders: maestro + sessão de evolução
context_freshness: 2026-06-24
related:
  - ../evolution/rfc/rfc-0001-co-evolution-comms.md (protocolo dos 3 fluxos — invariantes)
  - onion-federation-adr-a2a-format-interop-2026-06.md (linha vermelha A2A: runtime ❌, formato one-way ✅)
  - onion-federation-design-v2-2026-06.md (ledger como repo neutro / additional working directory)
  - onion-distribution-strategy-2026-06.md (open-core por camadas; control-plane = produto)
  - ../knowledge-base/platforms/git-ledger-as-working-dir.md (spike Fase-0 — ledger é working dir trivial)
  - ../knowledge-base/concepts/multi-repo-federation.md (contrato spec-as-code + members.yaml)
  - onion-adr-phased-resumable-pattern-2026-06.md (precedente de método: ADR provisório + gatilho)
---

# ADR — Ledger de co-evolução: formato e localização

> **Última Atualização:** 2026-06-24 · **Status: PROPOSTO (provisório).** Responde a uma pergunta de
> arquitetura (*"o ledger deveria virar outro formato, ou um repo neutro dedicado?"*) **sem** re-arquitetar:
> nomeia o veredito, ancora em evidência + invariantes, e difere a execução por gatilho. Espelha o método do
> ADR-PFR (core-only): provisório primeiro, evidência antes de lei.

## Contexto

Na operação real de 2026-06-24, o maestro sentiu o atrito do **transporte manual** do doc-bridge ao
entregar um veredito (RFC-0002) a um adotante: `cp` à mão, canal `inbound/` desconectado
por branch (mora em `develop`, mas o dev ativo estava em `rhilo/wrr-dose-next`), e fragilidade de arquivo
untracked. Disso veio a pergunta: **trocar o formato do ledger? mover para um repo neutro dedicado? qual o
padrão dominante em jun/2026?**

A investigação (3 exploradores: arquitetura interna, costura de federação, estado-da-arte externo) mostrou
que **a resposta já está majoritariamente desenhada** e que mudar formato/localização **não** é o que
resolve a dor — o que resolve é **automatizar o transporte**.

### O que já existe (evidência)

1. **O ledger hoje é doc-bridge leve.** Markdown commitado no próprio core (`docs/evolution/`): `inbox/`
   (upstream), `inbound/` (downstream no adotante), `federation/{CHANGELOG.md, members.yaml, outbox/}`.
   Transportado **à mão** pelo maestro (RFC-0001 §6 "Carteiro" = ainda a-desenhar).
2. **Os artefatos já são machine-readable.** `CHANGELOG.md` é regex-parseável por
   `federation-inbox-scan.sh`; `members.yaml` é YAML puro (`yq`-parseável); `contracts/<id>.md` têm
   validador determinístico (`federation-contract-validate.sh`, sem LLM). Não há prosa solta a "estruturar".
3. **O repo neutro já é o design da Federação formal.** O ledger-como-repo-git-dedicado (montado como
   *additional working directory*) está especificado e Fase-0 de-riscada
   (`git-ledger-as-working-dir.md`); os 5 comandos `/meta:federation-*` resolvem o ledger via
   `--ledger` → `.env FEDERATION_LEDGER` → path relativo (**zero hardcoding**, invariante I8). Não é ideia
   nova — é capacidade **já costurada**, gated por gatilho (RFC-0001 §6, I14).

### Validação externa (jun/2026)

O padrão dominante para coordenação core↔adotantes **não** é "repo neutro" nem "novo formato" por si — é
**changelog estruturado + transporte automático + humano aprova** (conventional-commits + `release-please`/
`semantic-release` + CI que faz broadcast da mudança como PR). O Onion **já tem 2/3** (CHANGELOG estruturado
+ `/meta:co-announce` + `members.yaml`); falta o terço do **transporte automático**. Repo-neutro/hub é a
*graduação* (5–50 adotantes: Backstage, conda-forge, Terraform Registry, Helm Hub); o formato permanece
compatível. SLSA/Sigstore (proveniência) e A2A/MCP (agente↔agente) são **prematuros** para este caso em 2026.

## Decisão

**1. Formato: permanece markdown append-only + YAML.** Migrar `CHANGELOG`/`contracts` para JSON Schema é
**cosmético** — os artefatos já são validáveis por script determinístico; trocar a serialização não adiciona
função e arrisca o append-only auditável. **Rejeitado.**

**2. Localização: o repo neutro = Federação formal, já desenhada, fica GATED.** Ligar o ledger-repo-neutro
agora — com **1 adotante** e **nenhum contrato quebrável** — viola **I14 (eficiência > cerimônia)**. A
capacidade está pronta; a ativação espera o gatilho. **Diferido.**

**3. Norte (o que de fato resolve a dor): automatizar o transporte — o "Carteiro".** É o terço que falta do
padrão 2026 e já está no roadmap (RFC-0001 §6). A forma sempre respeita os invariantes: **entrega/
notificação automáticas OK; commit/execução no repo alheio = gate humano** (I1, I3, I13). Há **duas
versões, com gating distinto**:

- **Carteiro-local mínimo — NÃO gated.** Para repos na mesma máquina: entrega o outbox no `inbound/` do
  adotante (branch certa via worktree, **entrega-sem-commit**) → o hook "you have mail" dispara sozinho.
  **Não requer o repo-neutro** (só lê o outbox do core e escreve um arquivo no `inbound/` do adotante), logo
  **não** depende do gatilho de graduação — pode ser pedido como item separado a qualquer momento (resolve
  diretamente o atrito do contexto). Fica fora do escopo *deste* ADR (que decide formato/local), mas o ADR
  o **libera** explicitamente.
- **Carteiro distribuído (CI broadcast) — gated.** Para repos remotos: CI abre PR no consumidor (maestro
  aprova). Acompanha a Federação plena (precisa do repo-neutro + members com remote), logo **segue o
  gatilho de graduação** abaixo.

**4. Gatilho de graduação** (quando ligar **o repo-neutro formal + o Carteiro distribuído**; o
Carteiro-local não espera por isto): **(a)** surgir um contrato que pode quebrar consumers, **ou (b)** ≥3–5
adotantes (coordination-tax > 15–30%). Até lá: doc-bridge leve basta — e é a opção certa.

## Reconciliação com a Federação formal já desenhada

Não há decisão nova de arquitetura aqui — há **confirmação de que a arquitetura existente está certa e que
o gatilho ainda não disparou**. O design v2 (`onion-federation-design-v2-2026-06.md`) já prevê: topologia
peer (não hub), ledger como working directory, resolução abstraída, contratos spec-as-code. Este ADR
**fecha a pergunta** ("formato/local?") apontando para o que o próprio design e o mercado convergem
(automatizar transporte), e **evita** a armadilha de graduar cedo por causa de um atrito pontual.

## Estado-da-arte 2026 (resumo)

| Camada | Padrão | Adoção/quando | Veredito p/ o Onion hoje |
|---|---|---|---|
| **L1** | Ledger markdown+git append-only (atual) | ✅ ótimo até ~5 adotantes | **Manter** — é onde estamos |
| **L2** | Hub/repo-neutro + transporte automático (CI broadcast, release-please) | dominante, 5–50 adotantes | **Graduar no gatilho** (já desenhado) |
| **L3** | Proveniência (SLSA/Sigstore/in-toto) | emergente; compliance | Prematuro (≥2027, se auditoria exigir) |
| **L4** | Agente↔agente (A2A/MCP runtime) | hype; não p/ humano-no-loop | **Vetado** runtime (I10); formato one-way só no gatilho A2A (I11) |

Fontes-chave: conventional-commits + `release-please`/`semantic-release` (transporte estruturado);
Backstage / conda-forge / Terraform Registry (hub no scale); SLSA/Sigstore (proveniência, 2027+);
A2A/MCP ecosystem map 2026 (agente↔agente, fora de escopo humano-no-loop).

## Coerência com os invariantes (não contradiz)

- **RFC-0001** (3 fluxos · git-async · um-escritor-por-repo · maestro-humano) — o ADR **reforça**; o
  Carteiro automatiza só atos 1-2 (transportar + notificar), nunca a execução (gate humano).
- **ADR A2A** — o Carteiro é **git-async**, não IA↔IA: **não** abre runtime (I10); nada de Agent Card
  bidirecional (I11 permanece one-way, gated).
- **Open-core por camadas** — manter markdown+git **não** enfraquece o moat (I12/I15): o produto é a
  **coordenação** (control-plane), não a serialização do ledger.
- **I8** (sem path absoluto) e **I14** (gatilho/eficiência > cerimônia) — citados como a régua que mantém o
  repo-neutro diferido.

## Consequências

- ✅ Encerra a pergunta de arquitetura sem re-arquitetar — o atrito vira **norte nomeado** (Carteiro), não
  uma migração precipitada.
- ✅ Protege o doc-bridge leve como a escolha **correta** para 1 adotante (anti-cerimônia).
- ✅ Dá ao Carteiro um lugar canônico no roadmap, alinhado ao padrão 2026 e aos invariantes.
- ⚠️ O atrito manual persiste **só enquanto ninguém pedir o Carteiro-local** — que não está gated (Decisão
  3). Hoje, com 1 adotante local, o custo de entregar à mão é baixo; o Carteiro-local mínimo é o atalho
  disponível quando o atrito incomodar, sem esperar a graduação plena.
- ⚠️ "Provisório" até o gatilho — vive em `docs/analysis/`, não na constituição.

## Alternativas consideradas

1. **Trocar o formato para JSON Schema / Protobuf** — rejeitado: cosmético; os artefatos já são validáveis
   por script; arrisca o append-only.
2. **Bootstrapar o repo-neutro do ledger agora** — rejeitado: viola I14 (1 adotante, nenhum contrato
   quebrável); a capacidade já existe e espera o gatilho.
3. **Automação CI completa (L2b) já** — rejeitado: campeão 2026 para 5–50 adotantes, mas prematuro com 1
   adotante local; exige remote em todos os repos.
4. **Abrir runtime A2A/MCP para coordenação** — rejeitado: linha vermelha (I10); fora do caso humano-no-loop.
5. **Não responder (deixar a pergunta aberta)** — rejeitado: o atrito reincidente merece um veredito
   durável e um gatilho explícito, não re-decisão a cada incidente.
