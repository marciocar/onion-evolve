---
branch: docs/maestro-decisions-1110
pr: pendente
date: 2026-11-10
reviewed_diff_sha256: 53362d33694e506cf27994630233d78f8b6b5822639a305a7f8b72fb4ba6ca84
reviewed_code_sha256: 26d06bbac46472c311d17ee206f76545abd36c411da2b1e315f5a9c0df8e13d3
findings_total: 4
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: passada própria do agente de execução sobre o próprio diff, sem subagente (o brief proíbe criar agentes); gates mecânicos kg-decide-seal (radar --integrity --schema, kg-contract-check, lint de nomes antes×depois), private-repo-cite-check
nota: "tokens e duração não medidos (0). Dez selos e uma evidência num grafo novo, em duas levas; sem código."
---

# Passada adversarial: `docs/maestro-decisions-1110`

## O que muda

- `docs/onion/graph/maestro-decisions-1110.kg.yaml` (novo): a evidência da rodada de 2026-11-10 e os dez selos dela
  (seis na primeira leva, quatro respondidos depois no mesmo dia), todos escritos pelo `kg-decide-seal.sh --new`, nunca
  à mão. Teto declarado de 11 nós.
- `docs/backlog.md`: projeção regenerada (213 grafos no escopo; nenhum aberto novo, porque o grafo só tem selos).

## Achados

1. VERBATIM APARADO (declarado, não curado): a resposta livre do maestro em `D_ADOPTER_DATA_COLLECTOR_1110` terminava
   com um espaço («…incluindo saidas »). O selador apara as bordas da opção; o texto, com os erros de digitação
   («nuncao», «usuario», «saidas»), ficou como o maestro escreveu. Só o espaço final saiu.
2. LIGAÇÃO AO REPO DA CURADORIA (curado antes do commit): `D_MARKITDOWN_2610` mora num repo não conferível por terceiro.
   Em vez de URL ou `repo@sha` (REGRA 121, Grafo novo ou tocado não cita repositório não conferível por terceiro), a
   narrative cita o id e a aresta externa vai ao caso-modelo `E_MARKITDOWN_REJEITAR_COM_SUPERACAO`, que já está no core.
   `private-repo-cite-check.sh`: 0 citação nova.
3. COMPLEMENTO À MÃO NAS NARRATIVES (curado e declarado): o selador não recebe narrative extra. O texto da opção 1 e o
   que a resposta livre acrescenta (D5), e a premissa do pandoc (D2), foram anexados depois do selo, sem tocar a
   escolhida, as descartadas nem a proveniência. Radar e contrato re-rodados depois: rc 0.

4. SEGUNDA LEVA (curado e declarado): quatro selos novos (D7 a D10). D7 liga a `D_THINKING_METHODS_RESEARCH_1110`, D8 a
   D7, D9 à evidência e D10 a D9, cada um ao nó de onde nasce. D8 e D9 são resposta livre (`--other`). O teto subiu de
   8 para 11 e o rótulo da evidência passou de seis para dez questões, ambos à mão e declarados no `meta:`. Os
   complementos de narrative de D7, D9 e D10 entraram depois do selo, nas mesmas regras do achado 3. O estudo da
   curadoria em D7 é citado só pelo nome, sem URL nem `repo@sha`. Gates re-rodados: radar 0, contrato 0, REGRA 121 sem
   citação nova, lint de nomes sem achado.

## Conferências

- Os dois alvos das `external_edges` existem nos grafos citados (`grep -n "id: <ID>"`).
- Lint de nomes sobre o corpus: zero achado no grafo novo.
