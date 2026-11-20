---
branch: fix/vps-exposure-restore-test-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: 2506d7117d483bfc41cfb381bc7018f6dc3b908b8556f0fe7478c934541c6125
reviewed_code_sha256: b86f0446390a35879e1f792295c32e4a4ee91e1b0e710e7c1de37730a6bd1adb
findings_total: 6
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 3
findings_fixed: 2
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, mandato de refutar, fixtures em mktemp. 1ª passada: APPROVED com 2 menores e 2 nits. Curados: a extensão dupla (restore-test-x.sql.txt) passava calada e o comentário prometia o contrário; e5b aceitava FORA como morte. Registrado no comentário: a allowlist confia no nome. Fora: (d)/(d2) herdados sem portão de docker. 2ª passada: APPROVED, 14 de 14, e5a/e5b/e5c morrem."
nota: "tokens 0 = não medido."
---

# Passada adversarial: `fix/vps-exposure-restore-test-1120`

## O que muda

A guarda `.claude/validation/vps-exposure-check.sh` contava `restore-test-<data>.txt` (o relatório do teste
de restauração, sinal da operação da VPS em 19/11) como BACKUP-EM-CLARO HARD. O `find` do bloco (3) passa a
excluir só `restore-test-*.txt` sem ponto no miolo. O dump, o `.tar`/`.sql` de mesmo prefixo, a extensão dupla
(`.sql.txt`) e o `.txt` de nome qualquer seguem HARD. A família `vps_exposure` do `lint-selftest.sh` ganha os
casos (e1..e5c), com portão de escopo: sem docker o caso é SKIP, nunca verde-vazio.

## O que se tentou refutar

- Nomes que casam o glob e são dado: a extensão dupla escapava, e foi curada com o mutante e5c.
- Verde-vazio fora da VPS.
- Mutantes no-op.
- Defeitos de shell.

A segunda passada sondou maiúsculas, ponto no miolo e espaço, e todos ficam do lado seguro.

## Resíduo

- O formato real do nome não foi medido. Um carimbo com ponto (`T10.30`) voltaria a ser acusado, o que é falha
  para o lado seguro.
- `(d)`/`(d2)` são herdados e não têm portão de docker.

## Veredito

FIXED. O PR toca guarda (`lint-selftest.sh`, linha `fecho`), mas não toca a lista da catraca (M1). Por isso a
sessão faz o merge com este resíduo isolado.
