---
branch: chore/coord-graph-harvest-1031
pr: pendente
date: 2026-10-31
reviewed_diff_sha256: pendente
findings_total: 11
findings_real: 4
tokens: 85028
duration_min: 3
findings_fixed: 4
verdict: CORRIGIDO
elenxo: nao
reviewer: "@branch-code-reviewer, agente separado e só leitura, mandato refutar"
nota: "tokens e duração do revisor medidos pelo harness (85028 tokens, 194 s). Os 4 achados reais foram curados no mesmo PR, num commit depois da revisão."
---

# Passada adversarial: `chore/coord-graph-harvest-1031`

## O que muda

- `coordenacao-sessoes-2026-10.kg.yaml` estava no teto de 40 nós (opt-in da REGRA 58 (O backlog cumpre as
  promessas do próprio meta:)). O caminho é o do próprio `meta:` («pendência nova entra quando uma fechada sai») e
  o precedente do `fios-abertos.kg.yaml` (commit bf87b613d: ondas colhidas no mesmo commit, história no git): os
  10 nós `done` e o 1 `refuted` saem, com as arestas que tocavam neles; o 4390 é religado ao censo de 1027.
- Entram 9 nós (1 evidence e 8 questions com owner) e um external_edge DEPENDS_ON para `Q_MA_WRITE_SURFACE`.
  Ficam 38/40.
- `docs/backlog.md` regenerado depois do `git add`.

## Achados

1. Caminho escolhido contra a doutrina: falso-positivo (kg-backlog-check l.71, o `meta:`, fios-abertos l.6 e l.37-39).
2. Ids removidos ainda citados: falso-positivo; só resíduos, CHANGELOG e um outbox já enviado.
3. Arestas pendentes: falso-positivo; radar 38 nós e 37 arestas sem contradição.
4. `verified_against` contra o vivo: falso-positivo; os quatro comandos reproduzem.
5. Vazamento num repo público: falso-positivo; 0 IP, host, usuário ou cliente no diff; REGRA 99 (Nó de .kg.yaml sem
   caminho de máquina, julgado pela classe) rc 0.
6. Gates: falso-positivo; radar rc 0, backlog-check rc 0, projeção em dia, contract-check rc 0.
7. **REAL.** O nó novo do dia zero duplicava `Q_COORD_MAESTRO_VITRINE_E_DIA_ZERO_KGSSOT`. **Curado:** a data
   (2026-11-04) e a versão 5 do LAUNCH.md entraram no VITRINE, no lugar; o nó novo virou
   `Q_COORD_MAESTRO_PLANO_FORMA_C_KGSSOT`, só a forma C.
8. **REAL.** O label de `Q_COORD_KGSSOT_ARESTA_ENTRE_REPOS_URL_FIXADA` dizia só o estado e perdia o que o item é.
   **Curado:** o label nomeia a aresta tipada entre repos e mantém o texto do gatilho pedido.
9. **REAL.** O `method` da evidência nova estava em português e chamava de medição o que em parte é testemunho.
   **Curado:** `measurement:`, com o testemunho declarado.
10. **REAL.** O label do `/onion-research` sem argumento afirmava o aborto da skill sem tê-lo medido. **Curado:**
    a narrative separa o rc 2 medido do efeito na abertura, que é testemunho.
11. Resíduo ausente: informativo, é este arquivo.

## Veredito

CORRIGIDO. Depois da cura: radar `--integrity --schema` rc 0, `kg-backlog-check` 38/40 rc 0, `ops/kg-gate-ci.sh`
rc 0, backlog regenerado.
