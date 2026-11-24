---
branch: feat/gokapi-upload-1123
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: pendente
findings_total: 15
findings_real: 12
findings_blocking: 3
tokens: 187000
duration_min: 20
findings_fixed: 12
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "refutador INDEPENDENTE (agente separado, brief sem a conclusão do condutor; testou cópias com pass e curl falsos e servidor https local, sem pass real nem o servidor real) REPROVOU em duas rodadas: 1ª com 2 bloqueios e 6 limites, 2ª com 1 bloqueio novo (rastreio do shell) e 3 limites; o condutor curou os 12 e re-mediu o rastreio (0 ocorrências da chave)"
nota: "tokens e duração são os do refutador nas duas rodadas (~187 mil tokens somados, ~20 min); a passada do condutor não foi medida"
---

# Passada adversarial: `feat/gokapi-upload-1123`

## O que muda

- `ops/gokapi-upload.sh` (novo, core-only): sobe um arquivo ao Gokapi do Onion e imprime o link de download. A chave
  de API sai do pass só por dentro e vai ao curl por descritor; nada além do link ou do campo de erro é impresso.

## 1ª rodada: 10 achados, 8 reais, 2 bloqueantes (curados)

1. **Bloqueante.** `-F "file=@${FILE}"`: um caminho com `;filename=` subia OUTRO arquivo com rc 0; vírgula e `;type=`
   quebravam o curl. Cura: o arquivo vai pelo stdin com `filename` entre aspas e o basename saneado.
2. **Bloqueante.** O rc 3 (chave ausente) nunca saía: o status do `pass` se perdia no grupo, e a requisição ia sem
   chave. Cura: a chave é lida antes, e falha ou chave vazia saem rc 3 sem tocar a rede.
3. Rede e recusa caíam no mesmo rc 4 com mensagem trocada: agora `--fail-with-body`, rc 5 para rede/TLS/tempo.
4. `--days 0`/`--downloads 0` criavam link sem limite: recusados (>= 1).
5. Arquivo começando com `-`: `--` suportado.
6. `GOKAPI_URL` aceitava http ou outro destino: só `https://<host>`.
7. E2E: o cabeçalho declara que este endpoint guarda em claro quando o servidor cifra de ponta a ponta.
8. Fallback para `UrlHotlink` (outro tipo de link): só `UrlDownload`.

## 2ª rodada: 5 achados, 4 reais, 1 bloqueante (curados)

1. **Bloqueante, nascido da cura do rc 3.** Com `bash -x` ou `SHELLOPTS=xtrace` herdado, a chave aparecia no rastreio.
   Cura: `{ set +x; } 2>/dev/null` no topo; re-medido pelo condutor: 0 ocorrências da chave no rastreio.
2. `a -- b` descartava `a` sem avisar: agora rc 2.
3. Servidor que guarda o arquivo sem devolver `UrlDownload` era relatado como «recusado»: mensagem própria.
4. `GOKAPI_URL` com usuário e senha passava: o host recusa `@`, `?` e `#`.

Não real: vazamento por `/proc` (linha de comando e ambiente do curl medidos durante o envio, sem a chave).
Declarado, não medido: com `-F file=@-` o curl pode ler o arquivo inteiro para a memória; o cabeçalho diz que a
ferramenta é para arquivos pequenos.
