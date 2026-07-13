# Tendências de Indústria e Mercado

> Da pesquisa orquestrada citada (2026-07-12). Contextualiza onde o Onion joga e por que a tese (contexto explícito no ciclo todo) está no timing certo.

---

## Estado atual

SDD (spec-driven development) deixou de ser vanguarda e virou **tabela-stakes**: "vibe coding is dead" (devs AWS, mar/2026); "toda ferramenta grande de coding de IA lançou sua variante de SDD" ([zeroshot](https://zeroshot.ghost.io/spec-driven-development-with-ai-coding-agents/), [byteiota](https://byteiota.com/spec-driven-development-kills-vibe-coding-march-2026/)). Landscape descrito como "jovem, fragmentado, evoluindo rápido — nenhuma ferramenta faz tudo".

**Implicação p/ o Onion:** fazer SDD não é mais diferencial; o diferencial é **onde** e **como** (3 dimensões peer, governança, federação, auto-evolução).

## Tendências emergentes

### 1. De "conductor" para "orchestrator"
Mudança de 1 agente guiado em tempo real → múltiplos agentes assíncronos, cada um com seu contexto/escopo ([Anthropic 2026 Report](https://agentmarketcap.ai/blog/2026/04/05/anthropic-agentic-coding-trends-report-claude-code-eight-shifts)). Anthropic lançou "Dynamic Workflows" (jun/2026): lead agent distribui dezenas-a-centenas de subagentes + grader separado. **O Onion já opera nesse eixo** (onion-orchestration + Workflow nativo).

### 2. Explosão de interesse em multi-agente
Gartner: consultas sobre sistemas multi-agente **+1.445%** (Q1/24→Q2/25); projeção de **40% das apps enterprise** com agentes de IA até fim de 2026.

### 3. Delegation gap é o gargalo real
Devs usam IA em ~60% do trabalho mas delegam totalmente só **0–20%** das tarefas — o gargalo não é escrever código, é **clareza sobre o que construir** (Anthropic 2026). É exatamente a dor que o contexto explícito ataca.

## Impacto tecnológico

### Context engineering vira disciplina
Formalizado pela Anthropic (set/2025): curar e manter o conjunto ótimo de tokens durante a inferência ([Sourcegraph](https://sourcegraph.com/blog/context-engineering)). **Dado-âncora que valida a tese do Onion:** times com arquivos de contexto bem mantidos veem **40% menos erros e 55% mais velocidade**.

### Convergência de convenção (com atrito)
Padrão cross-tool **AGENTS.md** adotado por 60k+ repos — mas **Claude Code usa CLAUDE.md** nativamente. Como o Onion é Claude Code-only, evita a fragmentação de convenção (mas também não a influencia).

## Ambiente regulatório (reforça o whitespace)

- **EU AI Act:** obrigações de sistemas de alto risco totalmente exigíveis em **ago/2026**.
- **ISO 42001** virando expectativa de certificação baseline; **21 CFR Part 11 / EU GMP Annex 11** já exigem trilha de auditoria em setores regulados.
- **FINRA 2026:** nomeia 3 riscos novos de agentes autônomos — **autonomia, scope creep, auditabilidade** — que os workflows faseados retomáveis + sessions do Onion mitigam estruturalmente.
- **Shadow AI:** 82% das empresas têm agentes/workflows de IA que a segurança desconhece ([Zylos](https://zylos.ai/research/2026-05-01-ai-agent-governance-compliance-2026/)).

> Nenhum SDD tool mapeado (Spec Kit, Kiro, Tessl, BMAD, Agent OS) resolve governança do próprio uso do agente — só qualidade de output. Ver [`competitive-landscape.md`](competitive-landscape.md) §Whitespace e [`../02-product/strategy.md`](../02-product/strategy.md).

## Contraponto honesto (não ignorar)

- SDD chamado de "waterfall com roupa nova"; consenso emergente: **híbrido domina** (specs para arquitetura/complexo, exploração livre para o resto) ([augmentcode](https://www.augmentcode.com/guides/vibe-coding-vs-spec-driven-development)).
- [Fowler](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html): "spec-as-source é caro a menos que a linguagem do spec seja precisa e validada" — a favor de specs pequenos iterativos.
- Adoção enterprise: só o **quintil superior** capturou ganho real (16–30%), e só reformulando processo inteiro, não adotando ferramenta ([InfoQ](https://www.infoq.com/articles/enterprise-spec-driven-development/)).

---

_§template: o adotante troca por tendências do seu setor; a estrutura estado→emergente→tecnológico→regulatório + contraponto honesto é o padrão._
