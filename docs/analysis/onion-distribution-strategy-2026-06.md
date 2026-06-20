---
title: "Estratégia de distribuição e evolução do Onion — veredito por camadas (jun/2026)"
date: 2026-06-20
type: analysis
status: proposed / living          # norte estratégico revisável — NÃO é execução nem spec congelada
authority: decisão de direção; gradua os cards de distribuição/control-plane do concept-map
research: 2 frentes (claude-code-guide + research-agent), jun/2026, pós-corte ago/2025 → ver confiança
---

# Estratégia de distribuição e evolução do Onion — veredito por camadas

> **Pergunta do maestro:** seguir o modo mais moderno de evolução (jun/2026) — o que Anthropic/comunidade/
> academia fazem — ou um mais adequado à nossa arquitetura? Qual a estratégia para um "Onion de ouro"?
> **Este doc é o veredito — revisável.** Não é ordem de migração; é o norte que decide o apetite depois.

## 1. Terreno (jun/2026, com confiança)

🟢 alta confiança (convergência de 2 frentes + binário Claude Code instalado + fontes):
- **Claude Code = ecossistema de plugins + marketplace:** plugin empacota commands/agents/skills/hooks/MCP;
  versionado por **SHA**; `/plugin install`; marketplaces oficial/comunidade/**privado** (Team/Enterprise);
  **server-managed settings** (org); **update deliberado** (não-automático por default).
- **SKILL.md = padrão ABERTO** (Anthropic dez/2025; cross-vendor). **`gh skill`** (abr/2026) instala/pina/
  atualiza cross-IDE com **proveniência (repo + tree SHA) no próprio arquivo** e detecta divergência de conteúdo.
- **Artifacts** capturam trabalho do Claude Code (PR walkthrough, dashboard); **Cowork** = engine de delegação;
  **Claude Design** (abr/2026) = visual→código (`/design-sync` puxa component library do GitHub).
- **"untraplan" não existe** → é **ultracode** (xhigh+Dynamic Workflows) / **ultrathink** (high-effort). Não são planos.

🟡 média confiança (web dos agentes; detalhes podem mudar): versões/schemas exatos; `gh skill` é preview;
academia (Skilldex/arXiv package manager de skills; GNAP git-native; HAIF human-in-the-loop; monorepo p/ 1-fonte-N-consumidores).

## 2. Insight central

**O ecossistema VALIDOU a filosofia do Onion — e comoditizou só UMA camada.** Viraram padrão de mercado:
SKILL.md (já usamos), update deliberado, human-in-the-loop (HAIF), CLAUDE.md como contexto, sem CLI standalone,
scoping project/user, subagents. **Estávamos à frente na filosofia.** O nativo comoditizou só a **distribuição
da camada `.claude/`**.

## 3. As 3 camadas do Onion (o enquadramento que decide tudo)

| Camada | O que é | Nativo cobre? |
|---|---|---|
| **1 — `.claude/`** (commands/agents/skills/hooks) | execução | ✅ **plugins/marketplace/SKILL.md/gh skill** — maduro, **supera nosso vendoring** |
| **2 — `docs/` spec-as-code** (meta-specs, KB, contexts) | a matéria-prima que a IA lê (SDD) | ❌ **nada nativo** — diferencial |
| **3 — co-evolução + federação + 3 dimensões** (doc-bridge, inbox, contratos, **compliance-peer**) | governança/coordenação | ❌ **nada nativo** (GNAP é o + próximo) — o **moat** |

## 4. Veredito — estratégia de ouro POR CAMADA

**Não é "migrar tudo pra plugin"** (jogaria fora 2+3 = o moat). **Não é "vendoring puro + relay manual"**
(atrás em proveniência/descoberta, contra o open standard). É **híbrido, por camada:**

1. **Camada 1 → NATIVO.** Onion vira **plugin**; `onion-evolve` vira **marketplace**; skills ganham
   **frontmatter de proveniência (repo + tree SHA)** → compatível com `gh skill update`. Isso **resolve o gap
   que vivemos nesta sessão** ([[2026-06-19-flow-a-report-and-bidirectional-mail]] / o sinal do metagamify):
   o tree-SHA dá o sinal "content diverged" que faltou no relay manual. Ganha versão/descoberta/cross-IDE,
   menos scaffolding custom.
2. **Camadas 2 e 3 → ficam e viram o DIFERENCIAL.** Sem equivalente nativo. O moat.
3. **Afia o comercial:** se a distribuição da camada 1 é **commodity nativa/grátis**, o que o Onion monetiza
   (o "control plane / cérebro escondido") é **exatamente 2+3** — governança/coordenação. Open-core clássico:
   *"cobra-se pelo hub que coordena, não pelo que roda no cliente."* **Ir nativo na camada 1 afia o moat, não o enfraquece.**

## 5. Alinhado vs atrás vs validado

- **Alinhado/à frente:** SKILL.md, update deliberado, human-maestro, CLAUDE.md, sem CLI standalone, scoping, subagents.
- **Genuinamente atrás:** (a) **proveniência rastreável** (relay manual sem content-hash — `gh skill` resolve);
  (b) **manifesto declarativo** (`plugin.json` com versão por componente — hoje versionamos por commit do repo
  inteiro); (c) **descoberta** (sem índice pesquisável — marketplace UI / `gh skill search`).
- **Parece atrás mas NÃO é:** ausência de IA-fala-IA viva (vindicada por HAIF + filosofia deliberada);
  vendoring (o nativo o **formaliza** como "project-scoped plugin commitado", não o elimina).

## 6. Honestidade

- Parte do que construímos nesta sessão (`/meta:adopt --update` da camada `.claude/`) seria **parcialmente
  superada** pelo plugin nativo. **Não foi desperdício:** foi a diligência que **revelou o gap de proveniência**
  que aponta pro nativo — e o `--update` segue válido pra **camada 2** (docs, que plugin não distribui).
- Pesquisa **pós-corte** (ago/2025): quadro geral alta confiança, detalhes média.
- **É norte, não execução.** Migração da camada 1 é grande e **gated por apetite do maestro**.

## 7. Caminho de migração (incremental, opcional, gated — NÃO agora)

1. Retrofit **frontmatter de proveniência** nas skills (repo + tree SHA) → ganho imediato de rastreabilidade, sem migrar nada.
2. Adicionar **`plugin.json` + `marketplace.json`** no `onion-evolve` (plugin opcional, coexiste com vendoring).
3. Documentar `/plugin install` como caminho preferido p/ camada 1; manter `/meta:adopt` p/ camadas 2+3.
4. Avaliar deprecar o vendoring-cego da camada 1 quando o plugin provar em campo.
5. Camadas 2+3: manter + evoluir como control-plane (o produto).

## 8. Log / revisibilidade

- **2026-06-20** — Veredito gravado: híbrido por camadas (1 nativo · 2+3 moat). Gated por apetite.
  Para retroagir: editar aqui com data + porquê. É tudo novo — liberdade total.

## Fontes-chave

Claude Code Docs (plugins · plugin-marketplaces · discover-plugins); `anthropics/claude-plugins-official`;
GitHub Changelog "Manage agent skills with gh skill" (abr/2026); SKILL.md open standard (Anthropic, dez/2025);
Skilldex (arXiv 2604.16911); GNAP; HAIF (arXiv 2602.07641); TechCrunch/Anthropic "Claude Design" (abr/2026);
"UltraThink deprecated → extended thinking". (Lista completa nos transcripts de pesquisa desta sessão.)
