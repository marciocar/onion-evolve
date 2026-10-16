---
branch: chore/radar-e3-2026-10-16-r12
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: c1ae7c855fe50669b78178ff97a21498cbdf41a07dba5645fd251dfd06650964
reviewed_code_sha256: f463e03d5d49af8c3b0e160275941a37c8fa87844e64bbbee785b1be2589beca
findings_total: 11
findings_real: 9
tokens: 142641
duration_min: 6
findings_fixed: 9
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose opus, mandato REFUTAR o diff
nota: "rodada de radar (só dados: grafo, SYNTHESIS, data/ e a baseline E3); sem código, então sem mutante aplicável; o juiz da rodada (opus/high, 159071 tokens) é passada separada, registrada em data/judge-verdicts.json"
---

# Passada adversarial: `chore/radar-e3-2026-10-16-r12`

## O que muda

Rodada r12 do radar E3 (Claude Code 2.1.300 → 2.1.301, 51 itens) pelo `/meta:cc-update`: grafo com 13 nós,
`SYNTHESIS.md`, a cópia do delta, os vereditos do juiz com critérios pré-registrados, e o eixo E3 selado em
`docs/onion/radar-baselines.yaml` no mesmo commit. Achado central: o /chat em produção roda o CLI 2.1.232 do
SDK do bridge, então o delta não chega aos degraus de isolamento. Ações: SAC-155 e SAC-156.

## Achados

O refutador devolveu 11 achados: 9 reais e 2 falsos-positivos. Os 9 reais foram curados.

1. (média) O nó de Workflow isentava o `onion-research`, mas a Ancoragem e a recusa só existem no modo
   primaries. **Cura:** o nó e a SYNTHESIS nomeiam o Fetch de research/decision como o 2º buraco.
2. O piso de CVE é pré-condição do degrau 3, que está parqueado, e o CLI 2.1.232 já era medido no grafo de
   isolamento. **Cura:** o nó declara isso, e uma `external_edges` SUPPORTS liga ao `E_CVE39861_FIXED_IN_2_1_64`.
3. As flags citadas eram da sonda do runner, não da política de produção. **Cura:** o nó cita
   `agent-policy.ts` l.163-172.
4–7. Citações do juiz: arquivo errado, `GUEST_TOOLS` inexistente, r11 com 12 nós, lista de omissões, e a
   superfície do host no Workflow após cd. **Cura:** notas no `judge-verdicts.json`, e os 12 nós no
   `x_supersedes_none`.
8. A duração do frontmatter da SYNTHESIS estava ambígua. **Cura:** a SYNTHESIS separa os 40 min da rodada dos
   8,6 min do juiz.
9. A pergunta do consolo foi respondida pela própria sessão julgada. **Cura:** a autoavaliação está declarada,
   e a próxima rodada passa o enum ao juiz.

Falsos-positivos: a REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse) e a REGRA 36
(Superfície VENDORIZADA sem nome comercial de cliente) não se aplicam, porque `docs/evolution/` e `docs/onion/`
não viajam (vendor-manifest). O outro é cosmético (uma vírgula), e foi curado mesmo assim.

## Mutantes

Nenhum. O diff só tem dados de pesquisa, sem guarda nem código. As guardas que julgam o diff (`kg-radar`,
`kg-contract-check`, `judge-verdict-check`, `radar-aufhebung-check`) já têm bancada própria.

## Limites declarados

- Não verificado: os defeitos dentro do CLI 2.1.232, a configuração de modelo e de gateway do bridge (no `.env`,
  que não foi lido) e as runs antigas de Workflow. A lista completa está na SYNTHESIS.
- O refutador não conferiu as issues no Linear (exigiria o `.env`); a sessão as criou pelo `tm.sh`, com rc 0.
