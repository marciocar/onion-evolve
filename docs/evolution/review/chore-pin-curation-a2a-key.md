---
branch: chore/pin-curation-a2a-key
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: cc1d928e80006e3f97895132fc6f1449e7ce7b7c419bb66124f30039541a5028
reviewed_code_sha256: 15f3dbdd1d8412a726bf297ecdd66229176dad1b52f78036b45d9840803585f5
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 0
verdict: APROVADO
elenxo: sim
reviewer: claude-opus-5-5 (agente de execução pin-curation-key, passada própria sem subagente)
nota: "tokens não medido (0). O único achado real é LIMITE: a ida assinada fim a fim não foi exercida, porque o agente não toca a privada."
---

# Passada adversarial: `chore/pin-curation-a2a-key`

## O que muda

- `.claude/utils/federation-transport/jwks/onion-curation-1.pem`: a pública do par `onion-curation-1`, que a sessão
  da curadoria gerou, entra com `git add -f`, do mesmo jeito que a do core entrou no #1519. O arquivo tem só
  `BEGIN PUBLIC KEY` (`grep -c PRIVATE` = 0).
- `docs/evolution/federation/members.yaml`: o membro `onion-curation` ganha `a2a:` como REMETENTE
  (`sends_to: onion-evolve`, `keys: [onion-curation-1]`). O bloco foi editado como texto, sem re-serializar.

A impressão `sha256:48960509a221a74a44c625bfaaca406dd4803fa8da1f81fcb94130ad6f4b32f7`, conferida pelo maestro fora de
banda em 2026-11-07, foi medida de novo (`openssl pkey -pubin -outform DER | sha256sum`) antes da cópia e na
worktree nova de origin/main, e bateu as duas vezes.

## Achados

1. **LIMITE (não bloqueia):** a verificação fim a fim de um envelope assinado por `onion-curation-1` não foi
   exercida aqui. Só a sessão da curadoria tem a privada, e o brief proíbe tocá-la. A ligação kid→from é a
   que o `a2a-verify.sh` (camada do `kid-not-owned-by-from`) lê do `members.yaml`. Conferi por `yaml.safe_load`
   que o membro devolve `a2a.keys == ['onion-curation-1']`, e a primeira ida real da curadoria fecha a prova.

## Mutantes

Cópia limpa primeiro (M0, `members-validate.sh` sobre a cópia no scratchpad): rc 0. Depois, cada mutante:

| # | Mutação | Resultado |
|---|---|---|
| M1 | `keys: [onion-curation-9]` (kid sem pem) | morto, rc 1 (`jwks/onion-curation-9.pem ausente (o gate vetaria unknown-kid)`) |
| M2 | segundo `a2a:` no mesmo bloco | morto, rc 1 (`chave 'a2a' repetida no mesmo mapa`) |
| M3 | `sends_to: onion-nada` | morto, rc 1 (`aponta 'onion-nada', que não está no registro`) |
| M4 | `--jwks` sem o `onion-curation-1.pem` | morto, rc 1 (`jwks/onion-curation-1.pem ausente`) |

Bancada `--families federation_a2a,a2a_verify`: 267 passaram, 0 pularam, 0 falharam.

## Limites declarados

- A ida assinada fim a fim fica para a primeira mensagem real da curadoria (achado 1).
- A rotação e a revogação de `onion-curation-1` seguem o caminho de qualquer kid pinado e não entram aqui.
