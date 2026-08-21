---
branch: fix/propose-kg-write-transport-limit
pr: 647
date: 2026-08-21
reviewed_diff_sha256: 6c31957a8290e6b9273ec3e4953b92dc90d86875668c858bff129e013f644198
findings_total: 2
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CONFORME-GUARDA-INALCANCAVEL-CURADA-DOGFOOD-DE-FRONTEIRA
reviewer: passada adversarial manual; sem subagentes
REVISOU: true
---

# Resíduo — `fix/propose-kg-write-transport-limit`

**Origem:** a sessão da PoC bateu no teto de 64KB de tool call e me deu, de graça, a evidência de
um bug latente meu (limite de 200KB inalcançável no propose_kg_write).

## Achado 1 — guarda inalcançável (REAL, curado)

O `len(kg_yaml) > 200_000` nunca dispararia: o LibreChat corta o argumento em 65536 bytes antes
do server. Curado p/ ~60KB (margem sob 64KB) com mensagem que ensina o caminho certo. É a
família guarda-inalcançável numa dimensão nova — o teto de um MCP é do TRANSPORTE, não do server.

## Os outros MCPs estão limpos (ataque de completude)

Re-checado: onion-kg e onion-framework só RECEBEM argumentos curtos (slug, termo, caminho,
categoria) — nenhum recebe payload grande. As saídas têm MAX_OUT de 60KB. Só o propose_kg_write
recebia grande, e era o único exposto ao teto. A cura é pontual e completa.

## Ressalva declarada

~60KB é heurístico (margem para o JSON-RPC restante); o teto exato do LibreChat é 65536 do
argumento serializado, não só do valor. Se um dia uma proposta legítima passar de 60KB, o
caminho é ingestão-por-arquivo (o padrão da PoC), não subir o número — subir reintroduz o
inalcançável.
