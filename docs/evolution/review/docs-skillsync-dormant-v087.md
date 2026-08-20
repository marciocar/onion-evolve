---
branch: docs/skillsync-dormant-v087
pr: 638
date: 2026-08-20
reviewed_diff_sha256: 91e4aa1f72a9e5a1bcd5359aab7375844d9cb0b8d0b7f58983289f478db25ba7
findings_total: 2
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CONFORME-CORRECAO-DE-PESQUISA-LIDA-NO-CODIGO
reviewer: passada adversarial manual (re-medição do claim central na imagem viva); sem subagentes
REVISOU: true
---

# Resíduo — `docs/skillsync-dormant-v087`

**Origem:** a tentativa REAL de ligar o skillSync (PAT válido, fiação pronta) não produziu nem
tráfego nem status — e a investigação desceu ao código da imagem em produção.

## Achado 1 — a exploração externa acertou o schema e errou o TIMING (REAL, curado no grafo)

O relatório de pesquisa afirmou o skillSync como capacidade do config 1.3.13 (correto: o schema
aceita) — mas no v0.8.7 o serviço está DORMANT: `initializeGitHubSkillSync` existe em
`sync.js` e **zero callers** fora do teste (re-medido no momento deste resíduo: grep na imagem
viva devolve 0). O PR #13293 mergeou 13 dias antes do corte do tag; o código entrou, o wiring
não. Curado como nó `E_SKILLSYNC_DORMANT_V087` com `CONSTRAINS` (adia, não derruba) — correção
que virou ARESTA, não prosa, como a etapa 5 do Elenxo manda.

## A forma da lição (a mesma do WAHA/LibreChat inteiro)

Exploração externa dá o mapa; **só o dogfood de campo dá o veredito**. Doc oficial + changelog
+ PR mergeado alinhados ainda descreveram capacidade que o binário não exercita — a família
declarado≠verificado no software de TERCEIRO. O custo de descobrir foi 1 restart + 1 grep; o
custo de não descobrir seria esperar um sync que nunca viria.

## Ressalva declarada

Não medi o v0.8.8-rc1 (seria puxar imagem rc só para confirmar wiring — o gatilho mecânico do
check-version.sh cobre o caso: quando o stable sair, o upgrade prova por comportamento).
