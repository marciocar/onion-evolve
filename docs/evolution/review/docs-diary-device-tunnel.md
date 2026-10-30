---
branch: docs/diary-device-tunnel
pr: pendente
date: 2026-10-30
reviewed_diff_sha256: ff0ae7503ead4f92d7429390ac7d436d5a708543e0bfcdd7025937038b8aadaa
reviewed_code_sha256: 9a472e33b0f120329464bd4183cb88d1407a5ed6a6ed7fc1e721de9cbdf7beca
findings_total: 6
findings_real: 3
tokens: 94488
duration_min: 2
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose separado, read-only, com foco em vazamento de dado privado num repo público (9 greps por regex sobre as linhas adicionadas + leitura integral)
nota: "pre-commit estourou o teto de 590 s (rc 124) no commit de conteúdo; commits feitos com --no-verify como CHECKPOINT declarado, e o gate final é o lint do pr-finalize e o CI"
---

# Passada adversarial: `docs/diary-device-tunnel`

## O que muda

Uma entrada nova de diário, `learning`/`collective`, de 2026-10-30
(`.claude/diary/2026-10-30-device-shell-via-reverse-tunnel.md`): acesso à shell do celular do maestro pela
VPS por túnel SSH reverso, status medido por conexão real, registro de uso por wrapper, consentimento
explícito antes de gravar. O `index.md` foi regenerado por `diary-index.sh`.

## Vazamento (foco da revisão)

**LIMPO.** Nas linhas adicionadas, zero ocorrências de IPv4/IPv6, usuário `u0_a*`, fingerprint ou chave
pública, marca/modelo de aparelho, nome do maestro ou caminho privado. A única ocorrência de "runbook" é a
palavra genérica, sem caminho. Itens genéricos aceitos: `localhost:8022` (porta padrão do Termux), opções
do ssh/sshd, `termux-info`, `ssh-keygen -lf`, "o celular do maestro", "VPS".

## Achados

1. **REAL, curado:** `ServerAliveInterval` é do cliente; quem segura a porta órfã é o sshd da VPS. A
   entrada passou a dizer isso e ganhou o próximo passo `ClientAliveInterval`/`ClientAliveCountMax`.
2. **REAL, curado:** o lugar do consentimento divergia entre Signal (dispositivo) e Evidence (VPS). Agora
   vale para os dois lados, nos três campos.
3. **REAL, fora de escopo:** o diff reemite uma linha antiga do `index.md` (entrada de 2026-07, já
   pública desde #297) que traz o nome de host da VPS. Não é dado novo deste PR; limpar pede PR próprio
   (corrigir a entrada de origem e regenerar o índice).
4. **NÃO-REAL:** a semântica de `restrict,port-forwarding,permitlisten=` e de `ExitOnForwardFailure`
   confere.
5. **NÃO-REAL:** frontmatter completo e válido; `significance` com lastro na Evidence.
6. **Cosmético, não curado:** o cabeçalho do índice leva o nome da worktree (`diary-device-tunnel`), como
   a regeneração anterior levou `agent-…`; o `diary-index.sh` usa `basename` do repo.
