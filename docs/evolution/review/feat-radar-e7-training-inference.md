---
branch: feat/radar-e7-training-inference
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: a7e8bc22c09a3fb8a47c9c5f516749f5ef432fb0191bdc9c7559e1396602acf3
reviewed_code_sha256: 3a6408a0c8770ef033e0f549d4af99f2ccde73e6ca7e97ed82f2213be4c8659a
findings_total: 5
findings_real: 5
tokens: 148681
duration_min: 27
findings_fixed: 5
verdict: CORRIGIDO
elenxo: sim
reviewer: "agente general-purpose independente, sem o meu contexto, mandato refutar; mais a minha própria medição da bancada"
nota: "tokens e duração são só do revisor; a sessão de execução não mediu os dela à parte"
---

# Passada adversarial: `feat/radar-e7-training-inference`

## O que muda

- O radar ganha o eixo **E7, trajetória de treino e inferência**, aberto **sem rodar** (decisão do maestro de
  2026-10-26, «Novo eixo E7 + registrar o achado»): entrada com `never_run:` em `docs/onion/radar-baselines.yaml`,
  tabela de eixos com a fronteira contra o E6 no `/meta:radar`, grupo `treino-inferencia` em
  `docs/onion/radar-sources.yaml`, contagem 6 → 7 no comando.
- **REGRA 65 (Radar de mundo com baseline DATADA por eixo):** medido antes de escrever, o eixo sem data era
  pulado em silêncio. Agora eixo declarado `never_run:` é SOFT "NUNCA RODOU", eixo sem data e sem declaração é
  SOFT, data junto com `never_run:` é SOFT. Nunca HARD.
- Nós: `E_OPENAI_SELF_SERVE_FINETUNE_SUNSET_2026` (nanochat, CONSTRAINS na opção D),
  `D_RADAR_E7_TREINO_INFERENCIA_ABERTO_1026` (sinais-de-campo), `T_RADAR_AXIS_E6` e `T_RADAR_AXIS_E7`
  (vocabulário da casa, para o lint de nomes), e a linha `E7` no glossário da glosa.

## Achados

1. **REAL, curado — REGRA 62 (Projeção GERADA em sincronia com a fonte (docs/backlog.md)) em HARD.** A aresta
   nova sobe a atenção de `C_OPCAO_D_CORPUS_DATASET_THIRD_PARTY`; `docs/backlog.md` regenerado.
2. **REAL, curado — REGRA 84 (Índice de leitura do KG em sincronia com os traces) em HARD.** O `trace:` do nó de
   decisão faltava no índice; `docs/onion/kg-read-index.tsv` regenerado.
3. **REAL, curado — o alarme de arquivo quebrado enfraquecia.** Contar todo eixo sem data como legível fazia um
   arquivo com `lastrun:` digitado errado passar de HARD "SEM eixos legíveis" para SOFT. Agora só o eixo
   **declarado** nunca-rodado conta. Caso (m) novo.
4. **REAL, curado — parse do `never_run` frágil.** Comentário com `never_run:` virava declaração; `#` entre aspas
   cortava o motivo; aspas simples e valor vazio não eram tratados. Linha de comentário agora é pulada antes do
   `case` (cura também o mesmo defeito latente de `last_run:` e `- id:` em comentário); valor entre aspas é lido
   até a aspa. Caso (n) novo.
5. **REAL, curado, achado pela minha bancada, não pelo revisor — o lint MORRIA calado.** Toda baseline sem
   `cc_version:` matava o lint antes do sumário: o grep do `pinned_cc`, sob `pipefail` + `set -e`. Defeito
   **pré-existente**: o arquivo vivo tem a chave, então nunca disparou na produção, mas toda fixture da bancada
   sem ela morria, e o caso (a) ("eixo fresco fica em silêncio") passava assim mesmo porque só olhava a saída.
   Curado com `|| true`; o caso (a) e os novos agora exigem rc 0 e ausência de `MORREU`.

Conferidos e não são defeito (do revisor): os outros leitores do baseline (os awk de `session_models` fecham no
`session_floor:`; `cc-delta-census.sh` só lê o E3; `radar-aufhebung-check.sh` só lê `kg:`); a fixture do
`model_ladder` sem `last_run` (a asserção só procura a REGRA 70); a prosa e os nós contra a medição (a página da
OpenAI confere palavra por palavra; o grafo do E6 dá 0 para os termos de treino); REGRA 100 e REGRA 106 no que
viaja.

`confirmed` de maior impacto dos arquivos editados (REGRA 87): `E_OBJECAO_VPS_CANNOT_TRAIN`,
`E_OBJECAO_VAL_BPB_NOT_DOMAIN_EVAL` e `E_OBJECAO_SLM_JUDGE_CORRELATED_ERROR`, lidos. Nenhum é contrariado: o nó
novo só restringe a opção D a pesos abertos, e ajustar pesos abertos continua exigindo GPU alugada (a VPS não
treina) e o eval de domínio antes (os dois gates seguem de pé).

## Mutantes

- O revisor rodou, numa cópia, a função da main contra os casos novos: (j) dá HARD e não a mensagem esperada;
  (k) e (l) ficam em silêncio. Os três reprovam a regressão.
- O caso (a) endurecido reprova o defeito 5: com o `|| true` tirado, o lint morre e o caso cai por `MORREU`/rc.

## Limites declarados

- A aresta TRACES_TO do nó de decisão para o nó da curadoria **não entrou**: o gate confere o alvo de
  `external_edges` contra os `.kg.yaml` rastreados neste repo, e o grafo do par não é um deles. A ligação vai
  por texto, conferida pelo `peer-ref-check` (EXISTE na origin/main do par @ b75a5903).
- As fontes do E7, fora a página da OpenAI, chegaram por resumo de busca no estudo da curadoria e ficam sem
  `last_checked`. Que outros provedores fechados também fechem o ajuste não foi medido.
- O `/meta:radar` não foi rodado: a 1ª rodada do E7 é do maestro.
