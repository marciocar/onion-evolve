---
branch: fix/research-elenxo-recommendation-whole
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: b242de08efc0ea3bd13b9865ada47f8285294b3f3c48426370606c13d7785a9b
reviewed_code_sha256: df8590fea146f37e5d6ec469dd9c786da1b276c26cad5f3bd1c87ab0a969894b
findings_total: 4
findings_real: 2
tokens: 0
duration_min: 40
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: agente de execução (passada própria, adversarial sobre o diff)
nota: "tokens não medidos (passada feita na própria sessão, sem subagente revisor)"
---

# Passada adversarial: `fix/research-elenxo-recommendation-whole`

## O que muda

- `.claude/workflows/onion-research.js`: nasce `agentText()` — a mesma sanitização do `webText()`
  (controles `\p{Cc}\p{Cf}` viram espaço, espaços normalizados, trim) **sem** o teto de 600. O
  `webText()` passa a ser `agentText(s).slice(0, 600)`, com o teto do dado web intacto. A recomendação
  do Elenxo no prompt do escritor (modo decisão) e o mercado do sintetizador passam por `agentText()`.
- `.claude/validation/lint-selftest.sh`: caso `(o2)` e mutante `(o2m)` na família `research_workflow`,
  com o helper `_research_agent_text_whole`.
- `.claude/skills/onion-research/SKILL.md`: o passo 6 diz que a recomendação e o mercado chegam inteiros.

## Achados

1. **REAL, curado (o defeito pedido).** A recomendação chegava cortada em 600 (run `wf_1b66acda-ac8`:
   2786 caracteres viraram 600). Medido nos journals de workflow: 33 de 33 recomendações passavam de 600
   (máx. 5979). A cura de 2026-10-11 (`352b79ba`) tirou um `.slice(0, 1500)` externo que **nunca
   mordia**, porque o `webText()` já cortava em 600 por dentro. A guarda daquela época lia a forma, não o
   comportamento.
2. **REAL, curado (mesma classe, achado na varredura).** O mercado do sintetizador (`report.market`)
   também ia ao escritor por `webText()`. Nos journals, 17 de 19 passavam de 600 (máx. 3114). É texto de
   agente que o escritor transcreve para o nó de mercado. Agora usa `agentText()`.
3. **Não é defeito.** No modo primárias, `objections`, `gapsOpen` e `recommendation` vão ao escritor
   pelo `JSON.stringify(pElenxo)` inteiro (l. 482), que o caso `(o)` já guarda. No modo decisão, as
   `objections` também vão por `JSON.stringify` inteiro. Nada mudou ali.
4. **Limite, não curado (fora do escopo).** O `scope.summary` vai ao **Elenxo** (não ao escritor) por
   `webText()`, com teto de 600. É texto de agente, mas o destinatário não é o escritor, e não medi
   corte com efeito. Os demais `webText()` embrulham dado web (claim, quote, locator, URL), e o teto
   continua neles.

Risco que considerei: a recomendação inteira também é texto que o Elenxo escreveu depois de ler a web.
O teto nunca foi defesa contra injeção (essa defesa é o `WEB_NOTE`), e o campo já ia sem `WEB_NOTE`
antes. O custo extra de prompt é de até cerca de 9 mil caracteres no pior caso medido.

## Mutantes

A guarda **executa** a função que embrulha o campo, com as dependências de topo, sobre 3010
caracteres que terminam num sentinela. Não confere nomes. Rodada contra cada mutante:

| Mutante | Resultado |
|---|---|
| `origin/main` sem a cura (`webText` nos dois campos) | ✗ `webText() devolveu 600 de 3010 chars (truncou)` nos dois |
| `webText(elenxo.recommendation)` reintroduzido na árvore (família rodada) | ✗ `(o2)` e `(o2m)` falham, `Falharam: 2` |
| `(elenxo.recommendation).slice(0, 1500)` | ✗ `cortado direto no prompt` |
| `agentText(elenxo.recommendation).slice(0, 600)` | ✗ `cortado direto no prompt` |
| teto escondido dentro do `agentText` (`.slice(0, 900)`) | ✗ `devolveu 898 de 3010 chars`, nos dois campos |
| `elenxo.recommendation` cru (sem sanitização) | ✗ `passado cru ao escritor` |
| `webText(report.market)` | ✗ `report.market: webText() devolveu 600` |

A família `research_workflow`, com a cura: 48 passaram, 0 pularam, 0 falharam.

## Limites declarados

- A guarda só executa definições de topo de **uma linha** (`const X = ...`). Uma função de várias
  linhas reprova em voz alta (`não executou isolada`), mas nunca passa em silêncio.
- O `(o2m)` depende da forma literal `+ agentText(elenxo.recommendation) +`. Se a forma mudar, ele
  reprova com `o mutante NÃO foi plantado`, e não fica verde por engano.
- Não reexecutei um run real do `/onion-research` em modo decisão depois da cura. A prova é a da função
  executada, mais a medição dos journals.
