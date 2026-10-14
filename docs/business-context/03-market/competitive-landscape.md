# Panorama Competitivo

**Última Atualização:** 2026-10-14 (Tessl re-medida: o "10k+ specs" não se confirma hoje e o "único spec-as-source" foi refutado, pelo estudo C do adotante de curadoria; Superpowers fechado pela dissecação do mesmo adotante: PARQUEAR; antes, 2026-10-12: estrelas re-medidas pela API do GitHub)

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

### Superpowers (obra/superpowers) — mesmo movimento SÓ EM PARTE; PARQUEADO em 2026-10-14
- **Medido (2026-10-12):** 297,9k★ (github.com/obra/superpowers, ativo). A dissecação mediu 296,6k★ em 2026-10-09: é crescimento, não divergência. É o 2º bundle vertical mais instalado do catálogo oficial de plugins, com 1.009.371 instalações (`docs/evolution/research/plugin-directory-landscape-2026-09/SYNTHESIS.md`; o contador aparecia igual em 2026-10-08, possivelmente congelado).
- **Desfecho da dissecação (fechado em 2026-10-14):** o movimento se confirma **só em parte**. É método em skills distribuído por plugin, como o Onion, mas o mecanismo é **persuasão injetada no SessionStart, sem gate determinístico**. O determinismo fica em dois scripts que o próprio modelo escolhe chamar. O Onion usa a mesma injeção e soma lint e CI com exit code. A dissecação foi do adotante de curadoria, até o N4, e o core triou o resultado. **Veredito: PARQUEAR** (selado pelo maestro em 2026-10-13, triado pelo core em 2026-10-14), com dois gatilhos de reabertura no grafo [`superpowers-2026-10.kg.yaml`](../../evolution/dissect/superpowers-2026-10/superpowers-2026-10.kg.yaml): rodar as 3 skills que o Onion não tem (systematic-debugging, TDD como fluxo, diagnosing-superpowers) em worktree isolada, e o worker do kg-freshness ou do census devolver `probe {argv[], expect_regex}`.
- **Hipótese de posicionamento (NÃO medida):** o Superpowers chegou a 296,6k★ sem nenhum gate determinístico. Se a tração vem do baixo atrito e do alcance (15 harnesses declarados), o determinismo do Onion pode não ser o que este mercado seleciona. Isso **não prova** que determinismo não vende. Os fatores de confusão não estão controlados: a reputação do fundador e de quem o divulgou, o destaque no catálogo oficial, o fato de estrela não ser adoção e o contador de instalações congelado (nó `E_MERCADO_PERSUASAO_E_DISTRIBUICAO` do grafo da dissecação, confiança 0,4).

### BMAD-METHOD (54,0k★ em 2026-10-12)
- **Posicionamento:** "substitui vibe coding por time completo de agentes especializados + quality gates" ([github](https://github.com/bmad-code-org/BMAD-METHOD)).
- **Força:** 12+ domain experts, multi-modelo, tração/comunidade; **modelo de negócio análogo** (MIT grátis + workshops de terceiros — ver `strategy.md` §Modelo comercial).
- **Fraqueza:** multi-modelo (não Claude Code-nativo); foco engenharia. **Diferenciação:** Claude Code-only por design + compliance peer + federação.

## Concorrentes indiretos — SDD tooling geral

| Projeto | O que é | Nota vs Onion |
|---|---|---|
| **GitHub Spec Kit** (140,9k★ em 2026-10-12; era ~90k em 07-13) | toolkit CLI agnóstico, fluxo Spec→Plan→Tasks→Implement | plataforma/CLI diferente; sem compliance/produto integrado |
| **Kiro (AWS)** | IDE agentic, "spec é a unidade de trabalho" | IDE completo (concorre com Cursor), não framework sobre agente existente |
| **Tessl** | registry de skills e plugins, com o produto se apresentando como "skills are software" (re-medido em 2026-10-14; ver abaixo) | núcleo fechado, Framework ainda em closed beta; a disputa com o Onion deixou de ser o eixo spec-as-source e passou a ser a narrativa "skills como código" |
| **OpenSpec** | leve, sem phase-gates rígidos | filosofia próxima, escopo menor (só engenharia) |

> **Tessl: re-medição de 2026-10-14 (supera a linha de 2026-07-12).** A linha antiga dizia
> *"spec-as-source + registry de 10k+ specs"*. Nenhuma das duas partes se sustenta hoje, pelo estudo
> C do adotante de curadoria (dissecação da Tessl, grafo `tessl-2026-10`, e linha de base `/onion-research`
> `tessl-baseline-2026-10`), lido pelo core como DADO:
> - **O número.** Nenhuma página atual da Tessl (`/`, `/registry`, `/pricing`) declara "10k". O sitemap
>   `tessl.io/sitemap.xml` lista **1.274 páginas de skill** em 2026-10-14. Isso é **piso**, não total: o
>   sitemap pode omitir páginas e a API de busca não devolve total. O total do registry fica **NÃO
>   VERIFICADO**. A linha de base do mesmo estudo registra "mais de 3.000 skills públicas" sem dizer de
>   qual fonte veio; o número é compatível com o piso e também não foi verificado. Isto não refuta o
>   número de 2025: aquele contava specs de bibliotecas OSS, objeto diferente das skills de hoje.
> - **O eixo.** A afirmação "a Tessl é a única que mira spec-as-source" foi refutada pelo Verify da
>   rodada (arXiv 2606.27045, tier 6). O spec-as-source que aparece no registry é plugin de terceiro,
>   sobre o OpenSpec, e não produto da Tessl. O **pivô** para "skills are software" é **indício**, não
>   fato selado: apoia-se no post da própria Tessl *"Skills are software and they need a lifecycle"*
>   (2026-01-29), no slogan citado por dois terceiros e na **ausência** de spec-driven e spec-as-source
>   no `llms.txt` da doc. Os dois nós que sustentam o pivô vêm de 1 agente, sem votação. No grafo do
>   core: `E_TESSL_UNICO_AS_SOURCE_REFUTADO_2026_10` refuta `B5_17_tessl_unico_as_source`.
> - **Também medido no estudo C:** US$ 124,5M em dois Form D de 2024 e nenhum em 2025 ou 2026; núcleo
>   fechado; preço estável desde 2026-07-18. Veredito da curadoria: PARQUEAR, com gatilho em 2026-11-15.
>   O veredito é do adotante; o core não o selou.

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
