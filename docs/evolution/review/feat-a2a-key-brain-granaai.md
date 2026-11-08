---
branch: feat/a2a-key-brain-granaai
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: 192ba9f1a31f7d1eaf872f9467a445d21a9c2cd8e8328c411e6dc820400884fd
reviewed_code_sha256: b01ef2c0808ac0b6e8473aee6814a807cb88bc220483097d447d5b2546334dbe
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: APROVADO
elenxo: nao
reviewer: passada própria sobre o próprio diff (sem subagente); gate mecânico members-validate e lint
nota: "tokens 0 = não medido. Diff: 1 PEM público e 3 linhas no registro."
---

# Passada adversarial: `feat/a2a-key-brain-granaai`

## O que muda

O membro `brain-granaai` ganha o bloco `a2a` (remetente ao core, `keys: [brain-granaai-1]`), e a chave pública
fica em `.claude/utils/federation-transport/jwks/brain-granaai-1.pem`. O arquivo entra com `git add -f`, como manda
o `.gitignore` do jwks.

## Achados

1. **A chave chegou por um sinal no inbox, que é canal não confiável (REAL, mitigado).** A confiança vem de
   duas medidas:
   - a impressão SHA-256 do DER, calculada pelo core a partir do PEM do sinal (`9d47d9ab…0620650f`), bate com a
     que o sinal declara;
   - o maestro conferiu a impressão fora de banda, na sessão do hub, em 2026-11-08, pelo /meta:decide.

   O PEM foi conferido: não tem bloco PRIVATE (`grep -c PRIVATE` = 0).

## Mutantes

Não se aplica: o diff é dado de registro e uma chave pública. O gate é o `members-validate.sh` (rc 0). A prova viva
é o teste da fila com o hub: sem o kid no registro, o gate responde `kid-not-owned-by-from`.

## Limites declarados

- O endereço (`sends_to: onion-evolve`) e a fila local são o desenho já em uso com a curadoria. Este PR não muda
  nada no gate.
