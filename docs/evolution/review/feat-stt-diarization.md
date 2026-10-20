---
branch: feat/stt-diarization
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: b00c01e4109c7425b138dcbe5df7bb2f86bfae309b09d02d4dc1770817fbb66c
reviewed_code_sha256: e07d18fcd1b83b25b5d11045b6fc45c89ca45db2023c3898d13c0f4278ae4235
findings_total: 8
findings_real: 8
tokens: 163537
duration_min: 11
findings_fixed: 7
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose, mandato REFUTAR, 1 passada sobre o 1º commit do branch, antes do rebase (só leitura, sem sudo)
nota: "o achado 8 foi curado em parte: o diarized_json do OpenAI fica declarado como não suportado"
---

# Passada adversarial: `feat/stt-diarization`

## O que muda

A diarização entra no serviço de STT em lote (D_MC_DIARIZACAO_NO_SERVICO_PROXIMO_1019). O pedido liga a diarização
com `diarize=true`. O Nemotron-3-Diarization q8_0 roda pelo NeMo-Speech.cpp 0.2.0, com preset v3-offline e em CPU,
num subprocesso sem PATH. Ele vem depois do Parakeet e lê o mesmo áudio. O falante vai para cada palavra pela
sobreposição de tempo. A falha nunca derruba a transcrição. O wrapper fixa e confere o binário pelo digest do GitHub
e o gguf pela revisão do HF. A prova ganhou o fixture de 2 falantes, e a bancada ganhou os casos e os mutantes.

## Achados do refutador e o que foi feito

1. **REAL, curado (média-alta): a ordem de memória não valia entre pedidos.** O pool FIFO recebia três submissões
   por pedido. O vizinho decodificava entre a transcrição e o filho, e o float32 dele ficava vivo durante o filho.
   No multicanal, o canal seguinte também ficava vivo. Agora o pedido inteiro é UMA submissão (`pipeline`). Todos
   os canais são transcritos e soltos antes de qualquer filho subir. Os casos `srv-diarize-float-solto-antes-do-filho`
   (weakref do áudio morta quando o filho sobe) e `srv-diarize-multicanal-cada-canal` cobrem a cura, cada um com
   mutante.
2. **REAL, curado (média-alta): o OOM do filho derrubava a unit.** O padrão medido nesta VPS é
   `DefaultOOMPolicy=stop`. Agora `OOMPolicy=continue` está na lista SANDBOX, ou seja, na unit e na transitória. O
   verify lê a propriedade, e o (w26) reprova `stop`, com mutante. Provado numa unit transitória real: o binário roda
   com a propriedade.
3. **REAL, curado (média): 6 mutantes sobreviviam.** Agora cada um tem caso que o mata: ordem e float vivo,
   multicanal com o diarizador do canal 0, `rmtree` (`srv-diarize-temporario-limpo`), teto do RTTM
   (`diarize-rttm-grande-vira-failed`), cabeçalho `X-Diarization` (no caso Deepgram) e `np.clip`
   (`srv-diarize-wav-com-clip`, com um WAV float de 1,5). A extração filtrada (`filter="data"`) e a sonda sem root
   são conferidas pela FORMA no (w27), com mutante. O download real é do `--apply`.
4. **REAL, curado (baixa): RTTM velho no multicanal.** O `core.diarize` apaga o RTTM antes de rodar. Caso
   `diarize-rttm-velho-nao-conta`.
5. **REAL, curado (baixa): `mkdtemp` fora de try virava 500.** Agora está dentro do `pipeline`. Se falhar, a
   diarização sai `failed`, nunca 500.
6. **REAL, curado (baixa): o JSON do GitHub ia pelo argv.** Agora vai pelo stdin.
7. **REAL, curado (baixa): o `--version` rodava como root.** Agora roda por
   `setpriv --reuid=65534 --no-new-privs`, provado com uma cópia legível por nobody.
8. **REAL, curado em parte (baixa):**
   - A palavra a mais de 1,5 s de qualquer turno fica sem falante (`speaker-longe-de-turno-fica-sem-falante`).
   - Os ids saem pela ordem da primeira PALAVRA (`speaker-ids-pela-primeira-palavra`).
   - O caminho do modelo e do binário sai da cauda do stderr (`diarize-stderr-sem-caminho-do-modelo`).
   - Não curado, declarado: o `response_format=diarized_json` do OpenAI toma 400. A diarização na rota OpenAI é o
     campo `diarize` com verbose_json.

## O que o refutador tentou derrubar e se sustentou

- **Injeção no subprocesso:** não há. Os caminhos são gerados pelo servidor, e o rótulo do RTTM passa por regex.
- **Sandbox:** o binário roda sob a lista da unit. O refutador provou numa unit `--user`, e esta sessão numa unit
  transitória do sistema com `DynamicUser`, `SystemCallFilter=@system-service`, `TasksMax=64`,
  `ProtectProc=invisible` e `IPAddressDeny=any`. Nas duas, o RTTM A-B-A saiu igual e rc 0. O RPATH fica dentro do
  diretório conferido.
- **Ponta a ponta real:** o smoke deu `n_fail=0`, com concordância 1,00 nas duas rotas, antes e depois das curas.
- **"Nunca levanta":** `TimeoutExpired` mata o filho. `MemoryError` cai em `failed`. `KeyboardInterrupt` não chega
  ao worker.
- **O `/tmp` desta VPS é ext4:** o WAV de 3 h não conta como memória fixa do cgroup.

## Bancada

- Família `stt_service`: 144 verdes com o venv do serviço.
- Núcleo: 75 casos, um mutante por caso.
- Servidor real com motor falso: 22 casos e mutantes.
- Wrapper: (w23) pin do GitHub, (w24) pin do HF, (w25) o fixture de 2 falantes na prova, (w26) OOMPolicy, (w27)
  forma da extração.

## Limites declarados

- O servidor inteiro dentro da unit, com o caso de 2 falantes, é provado pelo `install --apply` na unit transitória
  ANTES da troca. Isso é a próxima etapa, depois do merge.
- O pior caso de memória multicanal (2 × 3 h) não foi medido.
