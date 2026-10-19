---
branch: feat/stt-service
pr: 1184
date: 2026-10-17
reviewed_diff_sha256: pendente
reviewed_code_sha256: b26db6988dad94a40e6196c40233bdefcf2865c69477f70e377ae0e0fc6a3e4d
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

Bancada `stt_service`: 87 verdes com o venv do serviço; sem ele (CI, STRICT), 78 verdes, com a amarração do server.py
conferida pela FORMA (AST + mutante) e o rótulo dizendo que o servidor real não rodou (o 1º CI reprovou o ⊘ em STRICT). Mutantes plantados por
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

## Re-revisão (depois das 2 passadas)

O diff mudou depois da revisão só na BANCADA: o 1º CI do #1184 reprovou em STRICT o ⊘ do caso (s) (sem o venv do
serviço no runner). A cura troca o ⊘ por uma conferência pela FORMA (AST do `server.py`: o `build_app` devolve
`core.AuthGate(core.BodyLimit(...))` e o `parse_args` recusa host fora do loopback), com mutante (`return inner`
reprova), e o rótulo diz que o servidor real não rodou ali. Re-revisado por mim (sessão de execução), sem refutador:
não muda código de produção (`ops/stt/*.py`, wrapper) — só `.claude/validation/lint-selftest.sh`, o resíduo e o grafo.
Bancada sem o venv, STRICT: 78 verdes, 0 ⊘.

## Re-revisão depois do rebase (2026-10-19)

O PR ficou 53 commits atrás da `main` e foi rebaseado depois do selo da segunda rodada de transcrição (#1212). O
`git range-diff` contra a versão revisada mostra 10 dos 12 commits idênticos. Os dois que mudaram (o 3 e o 4)
mudaram só no grafo `meeting-capture-2026-10` (o TETO passa a 11 e a aresta de `D_MC_ASR2_MANTER_MOTOR_1019` fica
junto das duas deste PR) e em `docs/onion/testing-inventory.md`, que é projeção e foi regenerada. O patch de
código é o mesmo. O hash de código mudou porque a base mudou: a `main` trouxe as ondas 1 e 2 do EPIPE em
`lint-selftest.sh`, que este PR também toca. A interação foi exercida no pré-voo do `pr-finalize`, com as
famílias `moat_gate`, `stt_service` e `shell_pipefail_robustness` (318 verdes). O radar do grafo passa em
`--integrity --schema` e o teto bate (11/11). Sem achado novo. A bancada completa fica para o CI.

## Cura depois do CI no ubuntu 26.04 (2026-10-19)

O 1º CI depois do rebase reprovou a faixa 3: de (w4) a (w16), todos com `python3 não é 3.12`. A `main` tinha
voltado o runner para o `ubuntu-latest` (26.04), que não traz 3.12. A bancada passava o `python3` REAL à sonda de
versão do wrapper, então media o runner e não o wrapper. A recusa em si está certa: o lock fixa rodas `cp312`.
A cura fica na bancada: um `python3` falso no PATH dos falsos responde só à sonda, como a máquina-alvo, e
repassa todo o resto ao interpretador real. O caso novo (w22) prova que a recusa morde (rc 1, com mutante).
Medido nos dois ambientes: com o 3.12 da VPS, 80/80; com um runner simulado (um `python3` à frente no PATH que
reprova a sonda), 80/80. A mesma simulação SEM a cura reproduz as falhas do CI, de (w4) a (w16). Logo o verde
mede a cura, não o ambiente.
