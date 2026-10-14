---
branch: feat/decide-and-forge-travel
date: 2026-10-14
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 40
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida; corte medido por papel no resolve-role-bundle, lint 0 HARD, famílias assemble_plugin, kg_status_factor, role_bundle e role_cut 78/0
---

# /meta:decide, /meta:forge e /meta:dissect viajam para todos os papéis menos o mini

Três decisões do maestro de 2026-10-14, pedidas para a aula prática de KG e forja de um hub:

- o `decide` sai do `pending` e vai para o `full`, ficando de fora só o mini, que nasce sem KG;
- o `forge` abre a face que viaja;
- o `dissect` deixa de se declarar só do core.

Corte medido por papel (`resolve-role-bundle.sh <papel> --tools`): source, hub, standalone e plugins recebem os três; o mini, nenhum.
Os selos estão nos grafos: `D_DECIDE_VIAJA_PARA_TODOS_MENOS_MINI` (supera `Q_DECIDE_FICA_EM_PENDING`),
`D_FORGE_FACE_QUE_VIAJA_ABERTA` e `D_DISSECT_VIAJA_PARA_TODOS_MENOS_MINI`.

## Passada adversarial

1. **O plugin núcleo leva o comando que o papel promete?** Real, curado: a REGRA 37 (Mapa role→bundle (roles.yaml)
   consistente com os verticais) acusou `full:decide` ausente do manifesto `onion`. O manifesto passou a levar o
   comando, o medidor e o selador.
2. **O bundle fecha o grafo de dependências?** Real, curado: o `assemble-plugin` recusou (rc 2), porque o selador
   precisa do `kg-contract-check.sh`, e duas famílias da bancada caíram. Com o checador no manifesto, a montagem
   sai rc 0 e as famílias deram 78/0.
3. **A doutrina do forge passou a prometer mais do que mede?** Real, curado: a cláusula 4 dizia "gated até
   medição do lado de quem consome". A medição existe (o censo rodou num hub, no ensaio da aula: 59 candidatos), e
   a cláusula agora declara a fronteira que continua: o censo só reconhece a bancada (peça 7) dentro do
   `lint-selftest.sh`, que no adotante vira conflito de update.
4. **O checador viaja vivo no plugin?** Real, curado na rodada 1 do CI: a família `plugin_bundle` reprovou pela REGRA 74
   (Caminho .claude/ NU dentro de plugin só resolve no core, com catraca), porque o `kg-contract-check.sh` cita a biblioteca
   `utils/kg` com o caminho nu num comentário, e a catraca do baseline cresceu. O comentário cita sem o prefixo, e o
   manifesto leva `.claude/utils/kg` (o checador a importa de `validation/../utils/kg`). `plugin_bundle` e
   `assemble_plugin` deram 21/0.
