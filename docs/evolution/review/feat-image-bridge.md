---
branch: feat/image-bridge
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: 7774893b9f4d0d68fb6f2d6f90e430eb9865856addeb3a2d9b05be317fa42781
reviewed_code_sha256: fe284ab3d868732a9e67e6ae39c5b0b47b23e0f8cfb009295fcdd831652c576a
findings_total: 17
findings_real: 17
findings_blocking: 1
tokens: 114331
duration_min: 3
findings_fixed: 16
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "image-reviewer (opus, isolado), 2ª rodada sobre o delta 1cbea22c1..c32ff158c: APPROVE, 58 ✓ 0 ✗ 1 ⊘ pwsh. 1ª rodada dele: revisão encomendada pela sessão do core, separada do condutor, deu FIXES_NEEDED com 5 itens e 2 notas (a chave não vaza); todos curados, cada cura do script com caso e mutante. Antes dela, 1ª rodada: refutador (subagente general-purpose, só leitura, encomendado pelo condutor) REPROVOU com 1 bloqueio e 9 limites/nits, 9 curados (o 7 em parte)."
nota: "TOCA GUARDA: .claude/validation/lint-selftest.sh é «fecho script» em ops/moat-targets.tsv, então o merge é pelo one-touch do maestro. tokens e duração são os do refutador da 1ª rodada; os do image-reviewer não chegaram ao condutor (0 = não medido nessa parte). O delta da 2ª rodada volta ao image-reviewer pela sessão do core. O CI (que tem pwsh) reprovou o caso do parser em 25/11: o defeito era do CASO, não do .ps1 (pwsh -Command não entrega argumentos em $args, então o caminho chegava nulo). Curado pela sessão do core: o caminho entra como parâmetro de bloco, a falha mostra linha e mensagem, e um mutante (chave sem fechar) prova que o caso reprova. Medido com o pwsh oficial em contêiner descartável (sem rede), autorizado pelo maestro: 60 ✓ 0 ✗ 0 ⊘. A EXECUÇÃO do .ps1 num Windows segue sem medida: o 1º uso é a medida."
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

## 2ª rodada: image-reviewer (opus, isolado) — FIXES_NEEDED, 7 achados, curados

1. **Processo.** O diff toca guarda (`lint-selftest.sh` é «fecho script» em `ops/moat-targets.tsv`): declarado na `nota`,
   merge pelo one-touch do maestro. O hunk fora do escopo (~l.18537, `kill … || true` numa família A2A) era efeito
   colateral de um `sed` global do condutor e saiu do PR; a família `image_bridge` não precisa dele.
2. **Link simbólico no meio do caminho** (`HOME/lnk/inbox` com `lnk` → fora do HOME): o `mkdir` criava a pasta lá fora.
   Cura: o ancestral mais fundo que existe tem de resolver (`pwd -P`) para onde o texto diz, e depois do `mkdir` a
   contenção é refeita pelo caminho resolvido. Casos (g4) e (g5), cada um com mutante.
3. **`--check`:** 404 só vira «presente» com o erro JSON de arquivo não encontrado do Gokapi; outro 404 ou outro código
   = «inconclusivo», rc 5. KB e grafo marcam a leitura como inferência até a 1ª medida real. Casos (h2) e (h3).
4. **Config do `.ps1`** em `%APPDATA%\Onion\` (nunca ao lado do script) e `ops/windows/.gitignore` com `*.config.psd1`;
   o README cita o histórico e a sincronia do clipboard do Windows e o `ExecutionPolicy Bypass` contra a marca da web.
   Conferência estática na bancada, com mutante.
5. **Bancada:** id malicioso (`../`, `%2F`, começando por `-`) com mutante `.*` e `pass` falso que registra não ter sido
   chamado (caso m; o id agora não pode começar por `-`); um fixture por formato, png, jpg, gif e webp (n1 a n4); um
   curl-dublê que reprova se a chave aparecer em argv (o).
6. **Nota:** o `.ps1` escolhe a extensão pelos bytes, como o `.sh`.
7. **Nota:** contagens corrigidas: a família tem 29 casos, cada um com o seu mutante (58 verificações), e 1 ⊘ (sem pwsh).

## 3ª passada: image-reviewer (opus, isolado), 2ª rodada sobre o delta `1cbea22c1..c32ff158c` — APPROVE

58 ✓ 0 ✗ 1 ⊘ (pwsh): cada mutante reprova o seu caso. Notas que ficam abertas:

- (a) o casamento do «presente» no `--check` é heurístico, e o formato do erro do Gokapi usado na fixture
  (`{"Result":"error","ErrorMessage":"File not found"}`) não tem fonte primária: confirmar na 1ª medida real.
- (c) a sintaxe do `.ps1` segue sem conferência nesta VPS: o 1º uso no Windows é a medida.

## Correção do caso do parser (sessão do core, 25/11)

O CI reprovou «.ps1 com erro de sintaxe». O pwsh oficial em contêiner (`mcr.microsoft.com/powershell`, `--network none`) achou 0 erros no .ps1; o caso passava o caminho por `$args[0]`, que `pwsh -Command` não preenche. Cura: `& { param($p) … }`, saída do parser no motivo da falha e o mutante «chave sem fechar». Família image_bridge: 60 ✓ 0 ✗ 0 ⊘ com pwsh.
