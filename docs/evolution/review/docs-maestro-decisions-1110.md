---
branch: docs/maestro-decisions-1110
pr: pendente
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 4
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
3. SELO EDITADO À MÃO DEPOIS DE SELADO (ABERTO, para a revisão julgar): fere a regra de nunca editar o selo à mão. O
   `kg-decide-seal.sh` não tem modo de complemento (só `--new`, `--label`, `--link`, `--other` e afins; nenhum recebe
   narrative extra), então os complementos pedidos no brief entraram por edição direta da `narrative`, anexados depois
   da frase do selador. A escolhida, as descartadas, o `verified_against` e a proveniência não foram tocados, e o
   radar e o contrato rodaram de novo depois (rc 0). O que entrou, nó a nó, e por quê:
   - `D_DOC_CONVERTER_PANDOC_1110`: que `D_MARKITDOWN_2610` mora no repo da curadoria e chega ao core pelo caso-modelo
     `E_MARKITDOWN_REJEITAR_COM_SUPERACAO`, e que a premissa da rejeição (o pandoc à mão) é o que o selo cumpre.
     Motivo: o brief pede a ligação a `D_MARKITDOWN_2610` por aresta externa ou narrative, sem URL de repo privado.
   - `D_ADOPTER_DATA_COLLECTOR_1110`: o texto verbatim da opção 1 e o que a resposta livre acrescenta (nunca o banco
     direto; consultas e relatórios complexos fáceis, guiados, interativos e com saídas), e a ligação a
     `D_MESSAGING_SEGREDOS_VAULTWARDEN_SYSTEMD_1106`. Motivo: o brief pede que o narrative registre o acréscimo.
   - `D_THINKING_METHODS_CATALOG_1110`: que a forma fica para depois e que o estudo da curadoria
     (methods-as-contracts-2026-11) fica como registro. Motivo: pedido do brief da segunda leva.
   - `D_PROVENANCE_METHOD_VOCAB_1110`: que as três sessões discutem em 3 rodadas antes de qualquer mudança e que o core
     conduz. Motivo: pedido do brief da segunda leva.
   - `D_PROVENANCE_METHOD_VOCAB_PLAN_1110`: o acordo das três sessões na rodada 3 e os dois ajustes do kg-ssot (a
     ferramenta é o `kg_migrate.py`, que já existe; o kg-ssot migra primeiro, como primeiro adotante). Motivo: pedido
     do brief.
   Saídas possíveis para a revisão: aceitar como está; mover os complementos para nós `E_`/`C_` próprios ligados aos
   selos; ou dar ao selador um modo de complemento (peça nova, pelo `/meta:forge`) e re-selar.
4. SEGUNDA LEVA (curado e declarado): quatro selos novos (D7 a D10), pelo selador. D7 liga a
   `D_THINKING_METHODS_RESEARCH_1110`, D8 a D7, D9 à evidência e D10 a D9. D8 e D9 são resposta livre (`--other`). O
   teto subiu de 8 para 11 e o rótulo da evidência passou de seis para dez questões, ambos à mão e declarados no
   `meta:` (não são selo). O estudo da curadoria em D7 é citado só pelo nome, sem URL nem `repo@sha`. Gates
   re-rodados: radar 0, contrato 0, REGRA 121 sem citação nova, lint de nomes sem achado.
5. CONTAGEM NO RELATÓRIO (curado): o primeiro relatório à sessão principal falava em 6 selos; depois da segunda leva o
   grafo tem 10 (`grep -c "^  - id: D_"` na branch remota). Título e corpo do PR dizem dez.

## Conferências

- Os dois alvos das `external_edges` existem nos grafos citados (`grep -n "id: <ID>"`).
- Lint de nomes sobre o corpus: zero achado no grafo novo.
