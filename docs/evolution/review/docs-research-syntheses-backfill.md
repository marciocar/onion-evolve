---
title: 'Resíduo adversarial — as cinco sínteses que faltavam às pesquisas com grafo'
date: 2026-09-13
branch: docs/research-syntheses-backfill
reviewed_diff_sha256: 1fdc10a64fa4efa3024cc13d4a80b8f76ffbcaaa66e1c36f04e8bdbbcc4e8db9
findings_total: 27
findings_real: 27
findings_fixed: 27
tokens: 293619
duration_min: 11
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Um refutador com default REPROVADO atacou as cinco sínteses contra os grafos, os commits e os resíduos.
  Reprovou duas (ocr-local-sei e kg-freshness-dogfood) e deixou três com ressalvas: 23 achados, 2 ALTA.
  Somam-se 4 achados que eu mesmo peguei no lint e na proveniência antes da passada. A classe das duas
  reprovações foi instrução MINHA: mandei declarar "NÃO MEDIDO" onde git e docs não tinham custo, e os
  diários de workflow das sessões guardavam o número.
---

# Duas sínteses declaravam "NÃO MEDIDO" sobre um custo que estava no disco

Cinco pastas de pesquisa tinham só `.kg.yaml`, sem a projeção `SYNTHESIS.md` que a skill `onion-research`
prevê. Cinco agentes escreveram uma cada, com o mesmo contrato: projeção fiel, custo só se atribuível ao run, e
"NÃO MEDIDO" declarado no lugar de número inventado.

O contrato estava certo, mas a instrução de **onde procurar** estava incompleta, e o erro é meu. Eu mandei
procurar em `meta` do grafo, na pasta, nos commits e nos resíduos. Os diários da ferramenta Workflow
(`~/.claude/projects/<repo>/<sessão>/workflows/wf_*.json`) guardam `totalTokens`, `agentCount`, `durationMs` e
o `kgPath` de cada run, e ninguém olhou lá.

## Os dois ALTA

1. **ocr-local-sei:** "NÃO MEDIDO" em tudo. O diário `wf_fb266335-f95` tem o `kgPath` deste grafo: 6.717.798
   tokens, 104 agentes, 32 min. O valeu-a-pena passou a ser computável, ≈ 249 mil tokens por nó.
2. **kg-freshness-dogfood:** a passada adversarial `wf_56959265-e4e` estava com 1.853.000 tokens e 95 min,
   números do **resíduo da sessão**. O diário do run diz 436.488 tokens e 12 min. O frontmatter agora soma
   só os 10 runs cujo diário prova serem deste grafo, com a lista no corpo. `wf_d68dc607-bce` ficou fora: o
   script dele mira outro grafo.

## MÉDIA

- **ocr-local-sei:**
  - o nó de lacunas trocou "39 fontes descartadas" por "39 fontes" e "23 claims fora do orçamento" por "23
    claims". A divergência está declarada; o nó é de um grafo já mergeado, e a correção vai ao selo do maestro;
  - o modo revisit do workflow não abre eixo novo (`angles: []`). O eixo de SLMs para OCR, reforço do maestro
    nesta sessão, virou prescrição de run novo, não de revisita;
  - dois nós de confiança 0,7 que sustentam a opção recomendada entraram em NÃO-VERIFICADOS.
- **kg-freshness-dogfood:** o papel de cada run auxiliar (3 tentativas com 0 token, sonda, run de outro grafo)
  saiu do diário, e o frontmatter declara o escopo da soma.
- **vaultwarden-logto:**
  - o `review_after` escolhido já nasce vencido, e o grafo passa a emitir o SOFT da REGRA 67 (Grafo de pesquisa
    com REVISITA carimbada (meta.review_after)). Mantido **de propósito**, porque o conhecimento está velho e o
    sinal é verdadeiro; a síntese declara isso e põe a revisita no Backlog;
  - o item GATED do backup (saída da máquina) estava dado como pago, e não estava.
- **claude-code-2.1-onion:** o `review_after` usou "a classe que envelhece mais rápido", que não é o critério
  da regra. Agora está declarado como **exceção explícita**, com a razão: a pergunta é de troca de versão, e a
  tabela da REGRA 67 não tem classe para medição interna.

## BAIXA (13)

- precisão falsa em "79.167 tokens/nó";
- citação não literal do custo do audit;
- citações por linha caducas no grafo do audit, agora avisadas;
- cadência "120d" sem classe na regra;
- contagem de commits e de nós por data na síntese claude-code;
- fonte externa ao grafo sem rótulo;
- gatilho omitido;
- `trace:` fora da posição de convenção;
- "a mais alta" onde há empate;
- lista de refutadas incompleta;
- observação da síntese apresentada como nó;
- backlog "alinhar" onde já estava alinhado;
- commit omitido na lista.

## Os 4 que peguei antes da passada

1. O título da REGRA 67 que eu passei aos agentes **não existe**. Duas sínteses citaram "Revisita de pesquisa
   datada". Corrigido para o título real.
2. A tabela de custo do audit dizia "3 workers", e a REGRA 16 (Contagem de inventário-TOTAL divergente da SSOT)
   leu isso como total de agentes do repo. Reescrito por extenso.
3. `run_id` do audit era uma frase inteira no frontmatter, e a síntese kg-freshness tinha comentários `#` nos
   campos numéricos. Um leitor por `sed` pegaria o comentário junto. Limpo; a explicação foi para o corpo.
4. As cinco sínteses nasceram **sem nó que as cite**, e o `kg-provenance-coverage.sh` deu HARD NEW nas cinco.
   Cada grafo ganhou `projeção: …/SYNTHESIS.md` no `trace:` do nó de decisão.

## Gate

```
radar --integrity --schema : exit 0 nos 5 grafos
kg-provenance-coverage     : 0 HARD
pre-commit (lint, LC_ALL=C): 0 HARD
edições nos .kg.yaml       : só meta.review_after (3 grafos) e projeção: no trace (5 grafos) — confirmado pelo refutador
```
