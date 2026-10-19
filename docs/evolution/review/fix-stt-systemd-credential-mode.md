---
branch: fix/stt-systemd-credential-mode
pr: pendente
date: 2026-10-19
reviewed_diff_sha256: 06776b43f59cccec4364dd313814a433f0546e360b53d22d3a88d7685fe3fb77
reviewed_code_sha256: b10a37db1aa4a4d57e685a760389312891088d8efb664a05de1e836bf3ba3e97
findings_total: 3
findings_real: 2
tokens: 0
duration_min: 20
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão sobre o diff, com prova numa unit transitória real do systemd; sem subagentes
nota: ""
---

# Passada adversarial: `fix/stt-systemd-credential-mode`

## O que muda

O `load_token` aceita leitura de GRUPO só quando o arquivo está direto em `$CREDENTIALS_DIRECTORY` e o dono é root
ou o próprio processo. Fora disso, a máscara continua 0o077. São 3 casos novos no harness do núcleo (44 no total),
2 mutantes novos e a âncora do mutante antigo atualizada.

## Achados

1. **REAL (a causa):** o 1º `install --apply` na VPS reprovou na prova pré-troca com
   `token: /run/credentials/run-u1619.service/token com modo 0o440`. Medido no systemd 255 daqui: o
   `LoadCredential=` entrega o arquivo 0440 root:root, num diretório 0550, num tmpfs `ro,mode=700` privado à unit,
   e o usuário dinâmico o lê por ACL. A bancada não pegava isso porque roda o servidor fora do systemd. O
   fail-closed do wrapper segurou: a unit de produção não foi tocada.
2. **REAL, curado:** a âncora do mutante `load-token-modo-aberto-recusa` sumiu com a mudança (0 ocorrências). A
   bancada acusou isso, e a âncora agora aponta a linha nova (`if st.st_mode & mask:`).
3. **Refutado (o risco da cura):** "aceitar 0440 abre o token a terceiros?". Não abre: dentro do
   `CREDENTIALS_DIRECTORY` o grupo é root e o diretório é privado à unit. Um 0444 lá dentro continua recusado,
   pelo caso e pelo mutante. Um 0440 fora dele continua recusado, mesmo com a variável apontando para outro
   diretório. O critério compara o diretório do arquivo com o da variável (`dirname` contra `abspath`), então um
   caminho mais fundo não passa.

## Mutantes

- `mask = 0o037` → `mask = 0o000`: o caso `load-token-credencial-0444-recusa` reprova (morde).
- A condição do diretório → `if True:`: o caso `load-token-0440-fora-da-credencial-recusa` reprova (morde).
- Família `stt_service`: 91/91.

## Prova no systemd real

Rodei `systemd-run --wait --pipe -p DynamicUser=yes -p LoadCredential=token:<arquivo>` com o `load_token` desta
branch: carregou 64 bytes. O mesmo comando com o `load_token` da `main` reproduz a recusa 0o440.

## Limites declarados

O `install --apply` completo, com o verify, roda depois do merge e a partir da `main`. O deploy não sai de uma
branch que ainda não foi mergeada.
