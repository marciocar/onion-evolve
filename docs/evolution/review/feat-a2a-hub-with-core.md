---
branch: feat/a2a-hub-with-core
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 6
tokens: 224870
duration_min: 20
findings_fixed: 6
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "subagente general-purpose (opus) com mandato de refutar, sobre o diff do core e do onion-bridge#70"
nota: "o 7º achado é de processo (o diff entregue ao refutador foi capturado com um mutante da bancada plantado); não é defeito do código, e o commit saiu com o grep de ONION_MUTANTE vazio"
---

# Passada adversarial: `feat/a2a-hub-with-core`

## O que muda

F3 do configurador A2A (SAC-124): o hub recebe os filhos dele pelo bridge do core (`/a2a/<hub>`, no
onion-bridge#70). No core: camada `receiver` e `aud` obrigatório no gate, consumer só fala com o próprio
hub na topologia, regras de `parent` e de forma do registro no validador, aceite por receptor, convite
que confere o receptor, doctor que confere a rota, carteiros que tratam hub e consumer, seletor
`parent:<hub>`, trilhas 2 e 5 no hub, cláusula 10 da doutrina e item 8 da lente.

## Achados

1. **MÉDIA, curado.** `co-relay.sh` deixava um standalone do core relayar para qualquer hub: o carimbo
   `adopted` não distingue o filho do hub. Agora o `adopted_from` do remetente tem de ser o remote ou o
   caminho do hub. Casos (F3.r4) e (F3.r5), com mutante.
2. **MÉDIA, curado.** O doctor tirava a barra final, não via a caixa e chamava 404 de "alcançável". Agora
   julga a rota que o bridge vê e sonda por POST (401 = a rota existe, 404 = não existe). Casos (F3.d3),
   (F3.d5), (F3.d6), (F3.d7), e G1 a G4 no dogfood contra o bridge real.
3. **MÉDIA/BAIXA, curado.** `parent` duplicado, comentário na linha do `- id:` e id com espaço: o PyYAML
   e o awk do trust-check divergiam no lado que autoriza. O validador (REGRA 66 (Registro da federação
   validado no gate)) reprova as três formas. Casos (F3.p10), (F3.p11) e (F3.p12).
4. **BAIXA, curado (decisão declarada).** O gate deixou de aceitar standalone como receptor, e o adapter
   `a2a-live.md` dizia `--receiver <self>`. O adapter agora declara que receber ao vivo é só da fonte e
   dos hubs, e o never-live-pull vale para o hub regulado.
5. **BAIXA, curado.** O comentário da camada receiver dava um motivo falso; reescrito com o motivo medido.
6. **BAIXA, curado em parte.** O motor de convite aceitava a fonte por `kind` e o gate pelo `role`:
   alinhados ao critério do gate. Hub→hub segue recusado no convite (fora da F3, declarado).
7. **Processo.** O diff entregue ao refutador tinha um mutante plantado pela bancada em andamento. Antes
   do commit, o grep de `ONION_MUTANTE` nos SUT saiu vazio.

O que o refutador tentou e não quebrou: o guard nas duas rotas (fuzz de 18 caminhos × 5 métodos × 3
credenciais), a divergência de receptor entre o guard e o handler, a injeção pelo id do receptor, o
replay entre receptores, o consumer burlando o parent, o pool legado fora do core e o aceite da fila
de outro receptor.

## Mutantes

43 mutantes plantados por `ops/mutate-and-restore.sh`, todos mortos no caso nomeado:

- a2a_verify: 10;
- federation_a2a: 20 (validador 9, convite 4, doctor 7);
- a2a_accept: 6;
- codeliver: 2;
- corelay: 4;
- resolve_target: 1.

Na 1ª rodada sobreviveram 2 mutantes, (F3.r2) e (F3.r3). A guarda nova do `adopted_from` barrava antes
da checagem que cada caso mirava. Os dois casos foram reescritos para que só a checagem mirada barre,
e então os dois mutantes morreram.

No onion-bridge#70: 21/21 mutantes do receptor e 22/22 dos convites.

## Limites declarados

- **Não medido:** o bridge de produção com o receptor múltiplo (deploy do maestro) e um hub real com
  filhos (o registro não tem nenhum consumer hoje).
- **Janela medida:** com o bridge da F3 deployado e o core antigo no clone servido, a rota do hub aceita
  JWS sem `aud` e consumer de outro hub. Por isso nenhum convite para receptor hub antes deste PR chegar
  ao clone servido.
- **Pendente:** o trust-check segue lendo o registro por awk. A cura foi barrar no gate as formas em que
  os dois leitores divergem.
- **Pendente:** destino sem carimbo segue tratado como o core no `co-relay` (comportamento anterior).
