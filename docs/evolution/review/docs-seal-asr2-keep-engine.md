---
branch: docs/seal-asr2-keep-engine
pr: pendente
date: 2026-10-19
reviewed_diff_sha256: cbf1485d236dd956884d4ad654d37a4c05bc9c0109389fc3cfb8c6e1fe6086ad
reviewed_code_sha256: 615302b4da24c808624c1b2701c936e2124e3234368a8df146edd5268845ef6f
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 0
verdict: APROVADO
elenxo: sim
reviewer: passada adversarial manual da sessão (o diff contra o PR #1184 e contra o grafo da curadoria); sem subagentes
nota: "o achado real é de ordem de merge, não do diff: fica declarado e é curado no rebase do #1184"
---

# Passada adversarial: `docs/seal-asr2-keep-engine`

## O que muda

O maestro selou, por pergunta com opções, o pedido da curadoria (`C_MC_ASR2_RECOMMEND`, SAC-177): o motor de
transcrição fica (Parakeet v3 int8 pelo onnx-asr, com VAD), sem passada única, e o ao vivo vai para a extensão
local. O selo entra pelo selador (`kg-decide-seal.sh --new D_MC_ASR2_MANTER_MOTOR_1019`), com o radar
`--integrity --schema` e o contrato em rc 0. O teto do grafo sobe de 9 para 10 pelo gatilho que ele declara,
e a proposta vai para o `_processed/`.

## Achados

1. **REAL, curado no rebase:** o PR #1184 (`feat/stt-service`) mexe no MESMO grafo e também sobe o teto de 9
   para 10, para a evidência `E_MC_STT_SERVICO_CORE_MEDIDO_1017`. As duas mudanças juntas dão 11 nós. Quem
   mergear depois conflita na linha do TETO e precisa subir para 11, nomeando os dois gatilhos. A ordem é
   este primeiro e o #1184 rebaseado depois.
2. **Refutado:** o rótulo afirma que "o PR #1184 segue válido". Conferido no diff dele: o serviço usa o
   onnx-asr com o Parakeet int8 e o VAD silero fixados, e não reescreve a rota WS ao vivo (N = 0). O motor
   que o selo mantém é exatamente o que o #1184 instala.

## Mutantes

Nenhum: o diff não toca guarda nem código. O gate deste PR é o próprio selador, que desfaz a escrita quando o
radar reprova.

## Limites declarados

- O nó da curadoria (`C_MC_ASR2_RECOMMEND`, no repo `onion-curation`) continua `open` lá. Fechá-lo é da sessão
  da curadoria (I3, um escritor por repo). O retorno vai por anúncio downstream, que ainda não foi gerado.
- A pergunta sobre forçar pt-BR no candidato foi oferecida e descartada pelo maestro. Ela não volta como nó.
