---
branch: docs/kb-reverify-five-1118
pr: pendente
date: 2026-11-18
reviewed_diff_sha256: 42402b9010f619f31cccfc5e7c2a02389e2ff2e70b7f76a45c8e2f22b6a651be
reviewed_code_sha256: f342468fb79dc96f4b2bce4cec43b9addbf7edfa48680f451ff31820c42a5b3c
findings_total: 6
findings_real: 6
findings_blocking: 0
tokens: 0
duration_min: 9
findings_fixed: 4
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, mandato de refutar o recarimbo: conferiu 24 afirmações das cinco KBs na fonte primária por curl (CHANGELOG oficial do Claude Code, code.claude.com/docs, overview de modelos, doc de prompt caching, registro npm, llms-full.txt do Runflow); 23 batem, 1 errava a versão de uma nota histórica. Veredito APPROVED com 6 achados baixos. A sessão do core curou 4 (C1 a C4) num commit à parte e declarou 2 (C5, C6)."
nota: "tokens 0 = não medido (o harness não devolveu o custo do agente revisor); duration_min 9 é o relógio que o revisor declarou (05:55 a 06:04 UTC)."
---

# Passada adversarial: `docs/kb-reverify-five-1118`

## O que muda

Cinco bases de conhecimento do core vencidas pela REGRA 42 (verified_at 2026-07-23, 118 dias contra o teto de 90)
foram reverificadas contra a fonte atual, corrigidas onde a fonte mudou e recarimbadas com 2026-11-18:
`concepts/agent-orchestration.md`, `concepts/ai-agent-design-patterns.md`, `concepts/context-window-optimization.md`,
`platforms/runflow.md` e `tools/claude-code-commands-best-practices-2026.md`. Elas travavam a catraca de frescor nos
repos que vendorizam o core (o commit da síntese do Jogo do Company Brain na curadoria, em 18/11).

## A passada

O risco que importava era recarimbar sem verificar. O revisor escolheu 24 afirmações espalhadas pelas cinco KBs
(limites de subagentes, aninhamento, limites do Workflow, agent view, TeamCreate, lineup e preços de modelos,
multiplicadores de cache, `.claudeignore`, WebSearch, deep link, pacotes npm, SDK do Runflow, AutoGen) e as conferiu
na fonte primária. 23 batem. `doctrine-freshness.sh` no branch: rc 0, as cinco fora da lista de vencidas.

## Achados e destino

- **C1 (baixo, curado):** os «5 níveis» de aninhamento eram atribuídos ao 2.1.181; nasceram no 2.1.172 (o 2.1.181 só
  alinhou os subagentes em primeiro plano). Corrigido nas ocorrências de `agent-orchestration.md` e
  `ai-agent-design-patterns.md`.
- **C2 (baixo, curado):** as fontes primárias divergem no cache do Sonnet 5.5 (doc de caching 0,05×; CHANGELOG
  2.1.284, $0,20/Mtok = 0,1×). A divergência fica declarada na KB, que segue a doc de caching.
- **C3 (baixo, curado):** o `isolation: "worktree"` dos agentes está declarado no CHANGELOG, não só no binário; o
  `budget` segue sem menção pública. Texto ajustado.
- **C4 (baixo, curado):** a tabela de contexto prometia «~400K linhas» para 1M de tokens; trocado por ~60–100K.
- **C5 (baixo, declarado):** `@codebase` ainda aparece sem ressalva em exemplos de antipadrão de duas KBs. Risco
  baixo; fica para a próxima revisita.
- **C6 (info, declarado):** a KB omite que no plano Pro o Workflow é ligado em `/config`; Managed Agents e Routines
  ficaram declarados como não reconferidos.

## O que não foi medido

O binário local do Claude Code não foi aberto pelo revisor (a afirmação das strings é do autor); os exemplos de
código do Runflow além das 5 citações verbatim não foram reconferidos.
