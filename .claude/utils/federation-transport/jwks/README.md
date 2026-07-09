# JWKS fixture — chaves públicas PINADAS por `kid` (a2a-verify.sh)

Diretório de **chaves públicas pinadas** que o `a2a-verify.sh` (camada 5, JWS) usa para verificar a
assinatura de um sinal A2A: `alg: RS256`, `kid: <k>` → lê `${A2A_JWKS_DIR:-este-dir}/<k>.pem`.

## Invariantes (F2.2 — fundação segura)
- **Offline / pinado, nunca fetch ao vivo.** A spec A2A permite JWKS-por-URL, mas o `a2a-verify` **não faz
  rede** (impede "abrir canal vivo por acidente" — RFC-0004). A busca de JWKS ao vivo pertence ao **endpoint
  na VPS** (`~/onion-bridge`), fora deste helper.
- **Só chave PÚBLICA** (`.pem`). Chave privada **jamais** entra aqui (nem no repo). O `.gitignore` deste dir
  ignora `*.pem` justamente para uma chave privada nunca ser commitada por acidente — as públicas reais são
  adicionadas (force-add deliberado) quando o endpoint vivo existir e um membro publicar seu `kid`.
- **`kid` vira nome de arquivo** → o `a2a-verify` sanitiza (`kid` com `/` ou `..` → veto `bad-kid`).
- **Vazio na fundação:** hoje não há endpoint vivo, logo não há `kid` real. Os selftests
  (`run_a2a_verify_selftests`) forjam um par RSA efêmero em `mktemp` — não dependem deste dir.

## Convenção quando o endpoint graduar (VPS)
1. Membro publica seu Agent Card + JWKS; o maestro **pina** a pubkey correspondente aqui como `<kid>.pem`
   (`git add -f`), sob o mesmo gate humano do doc-bridge.
2. `pin-integrity` conceitual: a pubkey pinada é a raiz de confiança do canal — rotação = novo `kid` + novo
   `.pem` pinado, nunca sobrescrever silenciosamente.
