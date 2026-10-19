---
title: 'Proposta da curadoria: diarização no lote da VPS — Nemotron-3-Diarization (Sortformer) no preset v3-offline do NeMo-Speech.cpp, em CPU, sem token'
date: 2026-10-19
from: onion-curation
to: onion-evolve (core)
type: proposal
issue: SAC-167 (Linear, filha da SAC-157)
answers: Q_DIARIZACAO_SHERPA_X_SORTFORMER_1017
kg: docs/evolution/research/meeting-capture-2026-10/meeting-capture-2026-10.kg.yaml
decision_node: C_MC_DIARIZATION_PATH (open; o core sela)
---

# Diarização na VPS: o que medimos e o que propomos

O core pediu em 2026-10-17 que a escolha entre o sherpa-onnx (pyannote 3.0, sem token) e o Sortformer atual da NVIDIA
saísse do número: DER em pt-BR e custo em CPU na VPS, com o critério escrito antes de medir. Tudo abaixo está no grafo
do `kg:`, no repo da curadoria (PR #50, merge 51a6ab0).

**Como foi medido:**
- O protocolo é o `DIAR-PROTOCOL.md@581eea5`, com as emendas 1 (`7e72682`), 2 (`c73ce7e` e `813aea6`), 3 (`679cb49`)
  e 4 (`9045b6c`). Cada emenda foi commitada antes do dado que governa, e o Elenxo 2 conferiu isso pelos horários.
- As duas leituras do core, de 2026-10-18 (RTF de parede decide; o B1 cai por custo, não por qualidade; extensão do
  limiar declarada), estão aplicadas.
- Tudo rodou na própria VPS (8 vCPU, sem GPU), em série, com 4 núcleos e o registro da carga de cada execução.

## Resposta curta
**A diarização entra no lote da VPS com o Nemotron-3-Diarization q8_0 pelo NeMo-Speech.cpp 0.2.0, com
`--preset v3-offline`, em CPU, sem token e sem torch, rodando DEPOIS do Parakeet e não junto.** Ele não precisa do
número de participantes.

| Teste NURC-SP (10 gravações, colar 0,25 s, sobreposição contada) | DER | RTF | RAM de pico | Nº de falantes |
|---|---|---|---|---|
| **Nemotron-3 v3-offline** (`E_MC_DIAR_MEASURED`) | **9,5 %** | **0,047** | 1,65 GB (83 min) | não precisa |
| sherpa-onnx + pyannote 3.0 + CAM++, a reserva | 18,6 % | 0,145 | 0,65 GB | precisa |
| sherpa + TitaNet / + WeSpeaker | 32,2 % / 33,6 % | ~0,11 / ~0,15 | — | precisa |
| Nemotron-3, preset padrão de streaming (`E_MC_DIAR_B1_COST`) | — | 0,57 a 0,58, acima do teto de 0,5 | — | — |

- O Nemotron-3 vence nas 10 gravações, uma a uma (teste do sinal p = 0,001). O bootstrap pareado dá para A1 − B1 o
  IC95 de [+4,4; +15,0].
- A vantagem vem quase toda da confusão de falantes: 1,1 contra 7,9.
- Sanidade no AMI test (colar 0, protocolo do pyannote): 20,1 %, contra 18,8 % do pyannote 3.1 publicado. Ressalva: o
  AMI de treino e de desenvolvimento estão no treino do modelo. O NURC-SP e o português não estão.
- Todos os DER foram recomputados pela sessão a partir dos RTTMs (C5) e, de novo, pelo Elenxo com um avaliador sem
  pyannote. A divergência entre os três é de até 0,04 ponto.

## O que virou no caminho (vale para o método)
1. **O primeiro fechamento estava errado.** "Sortformer inviável nesta CPU" vinha de um único preset. O Elenxo 1 leu o
   `docs/cli.md` do binário e nomeou o `v3-offline` (sem limite de duração, diferente do `--offline` de ~6,6 min). A
   emenda 4 o mediu: 12 vezes mais barato, com o mesmo DER no piloto, e venceu. O Elenxo 2 tentou derrubar a virada e
   não conseguiu: RTF reproduzido em 0,0445, saída determinística, áudio inteiro processado.
2. **Divergência entre desenvolvimento e teste (C6).** No desenvolvimento, o sherpa ficou à frente (21,0 contra 22,7).
   A causa é uma gravação (SP_D2_062), na qual o modelo para de emitir fala por cerca de 10 min e funde dois
   falantes, nos dois presets. Sem ela, o desenvolvimento dá 10,2 contra 11,4; nas 15 gravações juntas, 14,1 contra
   19,4.
3. **A reserva sem número do sherpa ficou sem escolha válida.** O critério congelado escolheu o eigengap, que perdeu
   no teste. O "nº + 1" não passou no desenvolvimento. Com o Nemotron, a pergunta deixa de importar.
4. **Execução limpa:** a primeira definição contava as threads do próprio braço. Foi corrigida e declarada na emenda 2.

## Peça ao core
1. **Selar `C_MC_DIARIZATION_PATH`** (ou divergir): o Nemotron-3 v3-offline no lote da VPS, com o sherpa + CAM++ de
   reserva.
2. **Licença:** a OpenMDW-1.1 (texto lido em openmdw.ai/license/1-1) concede uso "without restriction" e não restringe
   saídas. Exige manter o acordo ao redistribuir, e os direitos terminam se você processar alguém por patente ou
   direito autoral sobre o modelo. O binário a chama de "NVIDIA Open Model License (OpenMDW 1.1)". O
   NeMo-Speech.cpp é Apache-2.0. Cabe ao core a leitura final.
3. **Próximo passo já aberto aqui (SAC-177):** o NeMo-Speech.cpp faz transcrição e diarização numa passada só, com o
   falante em cada palavra, e suporta o Parakeet TDT 0.6B v3. Isso fecharia a junção de palavra e falante e trocaria
   o caminho ONNX por um runtime só. O critério está pré-definido no nó: RTF ≤ 0,165 e RSS ≤ 8e9 no lote de 1 h,
   WER ≤ 6,36 e DER ≤ 11,49. A mesma issue mede o Nemotron 3.5 ASR (ao vivo), o Cohere Transcribe e o Qwen3-ASR,
   achados por trajetória no Open ASR Leaderboard.

## O que NÃO foi medido
- Áudio real do Meet e do Teams: o NURC-SP é gravação antiga.
- GPU.
- O `--offline` de atenção total e o Sortformer v2.1 por NeMo/torch, que o maestro excluiu.
- Mais de 4 falantes: o cartão diz até 8, e os corpora vão até 4.
- A junção de palavra e falante e o custo somado: estimado em RTF ~0,165, ~10 min por hora de reunião.
- A RAM do Nemotron cresce ~1,2 GB por hora de áudio. Somada ao Parakeet (7,41e9) passa de 8e9, então os dois rodam
  em sequência.

## Mercado e capital
Preços conferidos nas páginas primárias em 2026-10-18:
- pyannoteAI: €0,035/h (Community-1) e €0,096 a €0,112/h (Precision-3);
- AssemblyAI: +US$0,02/h sobre a transcrição de US$0,15 a 0,21/h;
- Deepgram: diarização incluída no Nova-3 multilíngue (US$0,26 a 0,31/h).

A diarização é barata no mercado. O valor de rodar na VPS é a privacidade e o grafo da reunião ficar conosco, a custo
marginal de CPU numa máquina já paga. Não abre bilhetagem própria.
