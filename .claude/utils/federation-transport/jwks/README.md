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
- **`kid` vira nome de arquivo** → o `a2a-verify` julga a forma antes de usá-lo (1–160 de `[A-Za-z0-9._-]`, sem `.` no início; fora dela → veto `bad-kid`, sem eco do valor).
- ~~**Vazio na fundação:** hoje não há endpoint vivo, logo não há `kid` real.~~ Caduco desde 2026-07-09: o
  endpoint está vivo e há públicas reais pinadas aqui. O `members-validate.sh` cobra, desde 2026-10-15, que
  todo `kid` de `a2a.keys` tenha `<kid>.pem` RSA de 2048 bits ou mais aqui, com dono único. Os selftests
  (`run_a2a_verify_selftests`, `run_federation_a2a_selftests`) forjam pares efêmeros em `mktemp` e não
  dependem deste dir.

## Convenção do pino (trilha 2 do `/meta:federation-a2a`)
1. O membro gera o par com `a2a-keygen.sh` e manda só a pública; o receptor confere a impressão por canal
   fora de banda e **pina** a pública aqui como `<kid>.pem` (`git add -f`), sob gate humano, no mesmo PR que
   põe o `kid` em `a2a.keys`. A confiança vale depois do merge.
2. `pin-integrity` conceitual: a pubkey pinada é a raiz de confiança do canal — rotação = novo `kid` + novo
   `.pem` pinado, nunca sobrescrever silenciosamente.
