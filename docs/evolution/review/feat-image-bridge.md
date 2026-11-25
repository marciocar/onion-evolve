---
branch: feat/image-bridge
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: pendente
reviewed_code_sha256: pendente
findings_total: 10
findings_real: 10
findings_blocking: 1
tokens: 114331
duration_min: 3
findings_fixed: 9
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: false
reviewer: "refutador (subagente general-purpose, só leitura, brief com o código e sem a conclusão do condutor; testou cópias com pass falso e servidor HTTP falso em loopback, sem pass real nem o Gokapi real) REPROVOU com 1 bloqueio e 9 limites/nits; o condutor curou 9 (o 7 em parte) e cada cura do script virou caso com mutante na família image_bridge. Não houve 2ª rodada do refutador sobre o head curado."
nota: "tokens e duração são os do refutador (1 rodada). elenxo_isolado: false porque o refutador foi encomendado pelo próprio condutor. O .ps1 não roda nesta VPS (sem pwsh): só o BOM é conferido pela bancada; a sintaxe fica como lacuna declarada."
---

# Passada adversarial: `feat/image-bridge`

## O que muda

- `ops/gokapi-fetch.sh` (novo, core-only): baixa uma imagem do Gokapi pela API para a pasta privada de imagens
  recebidas (0700, arquivo 0600), confere o tipo pelos bytes e imprime só o caminho; `--check` (uma sonda só-leitura),
  `--prune`, `--dir`. Por padrão usa a mesma entrada do pass do `gokapi-upload.sh` (correção do maestro, 25/11).
- `ops/windows/onion-paste-image.ps1` e `README.md` (novos): o atalho do Windows, clipboard → sftp → caminho no clipboard.
- `ops/gokapi-upload.sh`: `curl -q --max-redirs 0` (o mesmo bloqueio, achado no irmão).
- KB `send-image-to-session.md`, grafo `image-bridge-2026-11.kg.yaml`, família `image_bridge` (38 casos com mutante).

## Achados do refutador

1. **Bloqueante, curado.** Um `~/.curlrc` com `location` fazia o curl seguir o 302 levando o cabeçalho `apikey` a
   outro host (reproduzido em loopback). Valia também para o `gokapi-upload.sh`. Cura: `curl -q` (1º argumento) e
   `--max-redirs 0` nos dois. Caso (j) com `.curlrc` plantado e mutante.
2. `ONION_IMAGE_KEEP_DAYS=0` fazia o fetch sair rc 2 calado com a imagem já gravada. Cura: validação no início
   (rc 2 antes de baixar) e a limpeza oportunista num subshell. Caso (l).
3. `ONION_IMAGE_INBOX=<link>/` furava o `[ -L ]`. Cura: barras do fim tiradas, `.`, `..` e `//` recusados, e a pasta
   tem de ficar dentro do HOME. Caso (g3) ampliado.
4. `.part-*` órfão em SIGTERM. Cura: trap de HUP, INT e TERM, e a limpeza apaga `.part-*` com mais de 1 hora. Caso (g).
5. `.ps1` sem BOM: o PowerShell 5.1 estragaria os acentos. Cura: gravado com BOM; conferência de bytes com mutante.
6. Pipe de texto ao `sftp -b -` no 5.1 é ASCII («João» vira «Jo?o»). Cura: batch num arquivo UTF-8 sem BOM, barras normais.
7. Mensagens: host e esquema em maiúsculas recusados. Cura: comparação sem caixa. (O `fail` do `.curlrc` sai pelo `-q`.)
8. Pasta só protegida contra raiz e HOME. Cura: dentro do HOME obrigatório (item 3).
9. A bancada não exercia o teto nem a ausência da chave na saída. Cura: caso (k) e a conferência no caso (a).
10. `.ps1` não revalidava o `RemoteDir` nem os bytes do arquivo copiado no Explorer. Cura: os dois conferidos.

Não curados (limite declarado): opções que não se aplicam ao modo (`--days` com `--check`) são aceitas e ignoradas;
o SIGTERM no meio do download não tem caso na bancada (a cura do trap foi conferida por leitura).
