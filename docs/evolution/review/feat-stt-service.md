---
branch: feat/stt-service
pr: pendente
date: 2026-10-17
reviewed_diff_sha256: 45e805f608706c2619cf33887135112dcb1ac9a35b94e896ea1cdc840a3f1394
reviewed_code_sha256: 8e73eff2e21df59887263b86eb3ff6c596a6b95a9d8a4f5d845ba1c0749cc0c0
findings_total: 17
findings_real: 16
tokens: 303551
duration_min: 28
findings_fixed: 14
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose opus, mandato REFUTAR, 2 passadas
nota: "tokens e duração somam as 2 passadas do refutador opus"
---

# Passada adversarial: `feat/stt-service`

## O que muda

O STT em LOTE do core na VPS (D_MC_STT_PARAKEET_ADAPTADOR_CORE_1017, D_MC_CAPTURA_WINDOWS_LOTE_VPS_1017): o adaptador
da curadoria reescrito em `ops/stt/` (só as rotas de lote; sem o WS ao vivo) e operado pelo wrapper `ops/stt-service.sh`
(unit `onion-vps-stt` só em loopback, DynamicUser, sandbox, sem rede de saída, token por LoadCredential, MemoryMax=6G;
modelo e venv por pin com hash). MOAT, bancada `stt_service` e o nó E_MC_STT_SERVICO_CORE_MEDIDO_1017.

Os `confirmed` de maior impacto do grafo editado foram lidos e seguem válidos: E_MEETING_GRAPH_GATE_1016 (o gate de
reunião, intocado por este PR) e E_MC_STT_SERVICO_CORE_MEDIDO_1017 (o nó novo, cujos números saem da medição deste PR).

## Achados

Passada 1 (opus):
1. ALTA — bomba de descompressão: 4,1 MB de FLAC de silêncio = 6 h, +2,7 GB e 134 s presos. CURADO: `--max-audio-s`
   (10800) lido do cabeçalho antes de decodificar, `-t` no ffmpeg e conferência do decodificado. Re-medido com o mesmo
   arquivo: 413 em 0,035 s; m4a de 4 h pelo ffmpeg: 413 em 26 s, pico 1,18e9 B. Casos `duracao-acima-do-teto`,
   `srv-duracao-acima-do-teto-413` e `srv-duracao-pelo-ffmpeg-413`, com mutante.
2. MÉDIA — o verify não via drop-in, IPAddressAllow nem swap. CURADO: casos (w17)–(w19), com mutante.
3. MÉDIA — o server.py não tinha bancada (o mutante `return inner` passava). CURADO: `server_selftest.py` (servidor
   real, motor falso; 8 casos, 7 mutantes). Teto: no CI, sem o venv, ⊘ declarado.
4. BAIXA/MÉDIA — o 413 chunked virava 500 (e 400 no multipart) com o Starlette real. CURADO: exception_handler e
   re-raise; casos `srv-chunked-…` e `srv-multipart-chunked-…`, com mutante.
5. BAIXA — o verify não conferia o `core_sha256`; o reuso do code-dir confiava no marcador. CURADO (caso
   `smoke-reprova-nucleo-diferente`, com mutante; o reuso compara o conteúdo).
6. BAIXA — (w2) tautológico. CURADO: o mutante é commitado num checkout temporário e tem de renderizar a unit.
7. BAIXA — trava em /tmp comum: CURADO (`/run/user/<uid>`). Token sem credencial lia `./token`: CURADO (caminho vazio
   recusa). Stderr do ffmpeg (300 B, caminho trocado por `<tmp>`) volta ao cliente autenticado: DECLARADO, mantido.
   "Lista fechada de formatos" vale só para o ffmpeg: DOCSTRING corrigida. Upload lento ocupa a fila: DECLARADO.

Passada 2 (opus), sobre as curas:
8. ALTA — bomba por CANAIS: no caminho do ffmpeg o out.wav era escrito inteiro antes da recusa (64 canais de opus num
   mka: 245 MB por minuto no /tmp). CURADO: `-fs` (teto de bytes = canais × duração), `-ac 1` sem multichannel e PCM de
   16 bits; caso `srv-ffmpeg-fs-limita-disco` (mutante: sem o `-fs`). Teto declarado: o `-fs` é mole (+1 pacote).
9. MÉDIA — MAX_CHANNELS não valia no caminho direto (WAV 16 kHz com 512 canais = 512 inferências). CURADO no
   `audio_too_long`; casos `canais-acima-do-teto` e `srv-canais-acima-do-teto-413`, com mutante.
10. MÉDIA — FLAC corrompido virava 500 (LibsndfileError é RuntimeError). CURADO: vira 400; `srv-flac-corrompido-400`.
11. BAIXA — o verify aceitava IPAddressDeny parcial e config viva diferente do disco. CURADO: exige as duas famílias (ou
    `any`) e NeedDaemonReload=no; casos (w20) e (w21), com mutante.
12. BAIXA — FLAC de stream sem total_samples era recusado como "6e17 s". CURADO: duração desconhecida vai ao ffmpeg
    (que tem -t e -fs); caso `frames-desconhecidos-vao-ao-ffmpeg`.
DECLARADOS sem cura: o decode roda no mesmo pool de 1 worker (um ffmpeg até o timeout de 600 s prende a fila); o reuso
do modelo e do venv montados confia no marcador (refazer o hash a cada --apply custaria ~3 s e exige root em /opt;
fica como próxima leva).

## Mutantes

Bancada `stt_service`: 87 verdes com o venv do serviço (77 + 1 ⊘ sem ele, como no CI). Mutantes plantados por
`ops/mutate-and-restore.sh` numa CÓPIA: 32 no núcleo e no smoke, 9 no server.py, 24 no wrapper. Tetos declarados no
cabeçalho da família (defesa dupla: `if not token` do authorized; S_ISLNK do load_token). `moat_gate`: 237 verdes,
com (s1)–(s6) e os 2 mutantes antigos re-ancorados na tupla nova `_MOAT_WRAPPER_COPIES`.

## Limites declarados

- O --apply não foi rodado (é do maestro): a unit real, o sandbox no systemd e o verify vivo NÃO foram medidos aqui;
  o --apply os prova numa unit transitória ANTES de trocar a de produção.
- O proxy/TLS/domínio não foi tocado: espera decisão do maestro.
- Medição de memória com 1 repetição por braço e carga ambiente alta (load 7,8–9,2): o RTF não é comparável entre
  braços; o pior caso com 2 pedidos e corpos de 384 MB é ESTIMADO, não medido.
- O ffmpeg escreve o out.wav (float32, até o teto de 3 h) no /tmp privado da unit, que fica no disco raiz.
