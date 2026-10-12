# Panorama Competitivo

**Última Atualização:** 2026-10-12 (estrelas re-medidas pela API do GitHub; sinal de campo do adotante de curadoria, 2026-10-09)

> Da pesquisa orquestrada citada (2026-07-12). Categoria: **SDD (spec-driven development) sobre Claude Code**. Complementa [`../02-product/strategy.md`](../02-product/strategy.md) §Posicionamento.

---

## Concorrentes diretos (framework instalável `.claude/` + specs + comandos)

### Agent OS ⚠️ (o mais próximo estruturalmente; 5,5k★ em 2026-10-12)
- **Posicionamento:** "padroniza codebase e melhora specs — funciona com qualquer ferramenta de IA" ([buildermethods.com](https://buildermethods.com/agent-os)).
- **Força:** mesmo padrão do Onion — gera comandos em `.claude/commands/` + standards versionados + spec-shaping por perguntas.
- **Fraqueza:** agnóstico multi-ferramenta (dilui foco); **não** trata compliance/governança como pilar peer.
- **Diferenciação do Onion:** 3 dimensões peer (inc. compliance), federação, auto-evolução. **Risco a monitorar de perto** — evolução v3+.

### SuperClaude Framework (23,9k★ em 2026-10-12)
- **Posicionamento:** "aprimora Claude Code com comandos especializados, personas cognitivas e metodologias" — framing quase idêntico ao Onion.
- **Força:** 30 comandos slash + 9 personas + integração MCP.
- **Fraqueza:** sem spec-as-code documental como SSOT, sem compliance, sem multi-provider de task manager. **Diferenciação:** o Onion é spec-as-code + governança + federação, não só comandos+personas.

### Superpowers (obra/superpowers) — candidato a DIRETO, a confirmar pela dissecação
- **Medido (2026-10-12):** 297,9k★ (github.com/obra/superpowers, ativo); 2º bundle vertical mais instalado do catálogo oficial de plugins, 1.009.371 instalações (`docs/evolution/research/plugin-directory-landscape-2026-09/SYNTHESIS.md`; o contador aparecia igual em 2026-10-08, possivelmente congelado).
- **Por que candidato:** é método em skills e subagentes distribuído por plugin, o mesmo movimento do Onion (caracterização do adotante de curadoria, ainda não dissecada pelo core). **Gatilho para fechar:** a dissecação do Superpowers que o adotante de curadoria vai relayar (`/meta:dissect`); até lá, não afirmar paridade nem diferença de capacidade.

### BMAD-METHOD (54,0k★ em 2026-10-12)
- **Posicionamento:** "substitui vibe coding por time completo de agentes especializados + quality gates" ([github](https://github.com/bmad-code-org/BMAD-METHOD)).
- **Força:** 12+ domain experts, multi-modelo, tração/comunidade; **modelo de negócio análogo** (MIT grátis + workshops de terceiros — ver `strategy.md` §Modelo comercial).
- **Fraqueza:** multi-modelo (não Claude Code-nativo); foco engenharia. **Diferenciação:** Claude Code-only por design + compliance peer + federação.

## Concorrentes indiretos — SDD tooling geral

| Projeto | O que é | Nota vs Onion |
|---|---|---|
| **GitHub Spec Kit** (140,9k★ em 2026-10-12; era ~90k em 07-13) | toolkit CLI agnóstico, fluxo Spec→Plan→Tasks→Implement | plataforma/CLI diferente; sem compliance/produto integrado |
| **Kiro (AWS)** | IDE agentic, "spec é a unidade de trabalho" | IDE completo (concorre com Cursor), não framework sobre agente existente |
| **Tessl** | spec-as-source + registry de 10k+ specs | vende confiabilidade anti-alucinação; framework privado/beta |
| **OpenSpec** | leve, sem phase-gates rígidos | filosofia próxima, escopo menor (só engenharia) |

## Concorrentes indiretos — execução/orquestração

- **Claude Flow / Ruflo** (74,4k★ em 2026-10-12; era ~29k em 07-13; ~100k usuários/mês na medição de 07-13): meta-harness de swarms multi-agente. **Categoria distinta** — infra de execução, não metodologia spec-as-code.
- **MetaGPT / ChatDev**: precursores multi-agente (2023) — "empresa de software de IA" via SOPs. Geração one-shot, não docs versionadas como SSOT.

## Adjacente (não concorrente)
- **GSD (gsd-core)**: open-gsd/gsd-core, 10,4k★ em 2026-10-12; o repo antigo gsd-build/get-shit-done (64,3k★) está **arquivado**. Trajetória citada em 2026-08 (`docs/evolution/research/claude-code-2.1-onion-2026-08/SYNTHESIS.md`).
- **Claude Task Master**: gestão de tasks local drop-in. O Onion é **provider-agnóstico** (Jira/ClickUp/Asana/Linear via SDAAL), categoria diferente.

---

## Win/Loss e objeções

- **Por que ganha:** continuidade (workflows faseados retomáveis) + governança integrada + auto-evolução provada (dogfood).
- **Por que perde (hoje):** Claude Code-only limita alcance; curva de entrada; sem distribuição pública nem comunidade.
- **Objeções comuns → resposta:**
  - *"já tenho CLAUDE.md"* → CLAUDE.md é 1 arquivo; o Onion é o ciclo (3 contextos + workflows + agentes) que conversam entre si.
  - *"SDD não é waterfall de novo?"* → contraponto [Fowler](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html): specs pequenos/iterativos ligados a testes, não PRD monolítico; o Onion é faseado retomável, não big-design-upfront.
  - *"só Claude Code?"* → sim, por design — profundidade > alcance (idiomático da plataforma).

## 🎯 Whitespace (evidência mais forte)

Em 10+ buscas direcionadas, **nenhum** concorrente anuncia produto + engenharia + **compliance** como três dimensões peer num ciclo orquestrado. A indústria trata SDD (engenharia), specs/tasks (produto) e governança de IA (compliance) como **três conversas separadas**; governança fica em nível organizacional/regulatório (EU AI Act, ISO 42001, [FINRA](https://zylos.ai/research/2026-05-01-ai-agent-governance-compliance-2026/)), não como capability integrada a um framework instalável. Os workflows faseados retomáveis + sessions do Onion mitigam por construção os 3 riscos FINRA (autonomia / scope creep / auditabilidade).

> ⚠️ **É lacuna observada, não categoria confirmada por fonte.** Tratar como hipótese de posicionamento forte, a validar em campo. Ver [`../decisions.md`](../decisions.md) `D6`.

**Fontes:** [Fowler/SDD](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html), [Spec Kit](https://github.com/github/spec-kit), [Agent OS](https://buildermethods.com/agent-os), [BMAD](https://github.com/bmad-code-org/BMAD-METHOD), [CxO field guide](https://tooltwist.com/insights/spec-driven-frameworks-cxo-guide), [Zylos governança](https://zylos.ai/research/2026-05-01-ai-agent-governance-compliance-2026/).

---

_§template: o adotante substitui pelos seus concorrentes reais; a categorização (diretos/indiretos/execução/adjacente) + win-loss + whitespace é o padrão._
