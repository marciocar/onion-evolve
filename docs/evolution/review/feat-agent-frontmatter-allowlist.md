---
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 5
tokens: 152921
duration_min: 11
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Uma passada de refutador em worktree isolada, com mandato de achar FALSO POSITIVO e veredito default
  reprovado, sobre afbfe5f2. Ele mediu contra o parser do binário 2.1.296 (reproduzido em Bun) e varreu
  1685 agentes de 34 repos locais. REPROVOU com dois falsos positivos reais (fecho --- com espaço ou tab;
  as chaves observer, observerMessage e observeSubagents, que o runtime lê sem a doc listar) e três
  falsos negativos (BOM ou --- com espaço na abertura; --- no meio do frontmatter, onde o runtime corta).
  Os cinco foram curados neste PR; os teóricos baratos também (merge key sai SOFT, frontmatter sem fecho
  não é julgado). Fica no teto o mapping de topo todo indentado. 24 casos no --selftest, 22 mutantes
  mordem na bancada, mais 3 por mutate-and-restore. Não houve 2ª passada.
---

# Resíduo — `feat/agent-frontmatter-allowlist`

A REGRA 102 (Chave de frontmatter de agente pertence à allowlist) foi forjada pelo `/meta:forge-guard`
sobre o SAC-106 (radar E3 r9, 2026-10-11). O Claude Code ignora em silêncio a chave de frontmatter que
não reconhece: `tool:` no lugar de `tools:` deixa o agente com todas as ferramentas, e nenhuma regra via.

## Passada adversarial — REPROVA (9 achados, 5 reais)

| # | Achado | Real? | Cura |
|---|---|---|---|
| 1 | fecho `--- ` com espaço/tab: a guarda lia o corpo como frontmatter (4 HARD num agente real) | sim, FP | abertura e fecho casam `^---[ \t]*$` |
| 2 | `observer`, `observerMessage`, `observeSubagents` lidos pelo runtime 2.1.296, fora da doc | sim, FP | origem `runtime` no `.tsv`, conferida no binário |
| 3 | merge key `<<` acusada como chave | teórico | sai SOFT, classe MERGE-KEY |
| 4 | frontmatter sem fecho, ou fechado com `...`, era julgado | teórico | acusações pendentes até o fecho; sem fecho, silêncio |
| FN-A | BOM ou `--- ` na abertura escondia o `tool:` | sim, FN | BOM tirado; abertura com espaço/tab |
| FN-B | mapping de topo todo indentado | sim, FN | teto declarado |
| FN-C | `---` no meio do frontmatter: o runtime corta ali e o `tools:` some | sim, FN | classe FECHO-AMBIGUO (HARD) |
| FN-D | `<<: {tool: Read}` não acusa `tool` | teórico | coberto pelo aviso MERGE-KEY |
| ruído | `--only=` num agente varre os 51 | não | só custo; mantido |

Dispatcher sem defeito: `--only` em não-agente cala, `role: adopted` rebaixa a SOFT, repo sem
`.claude/agents` sai 0. Variações `disallowed-tools`/`allowed-tools` são acusadas com razão (a doc exige
o nome exato).
