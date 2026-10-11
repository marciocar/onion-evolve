---
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
tokens: 110036
duration_min: 10
verdict: APROVADO
elenxo: sim
nota: >
  O refutador opus foi instruído a achar o escape-hatch reaberto, leitores de role:source que mudam de
  comportamento e pins que não batem com o remoto, e REPROVOU. O achado principal é de segurança:
  com a onion-core em role:source, o trust-topology-check (camada 1 do a2a-verify) passou a dar
  autoridade de fonte a quem só declara o papel. Ele construiu um adotante disfarçado que passava no
  validador e ficava AUTORIZADO a `correct` qualquer membro. Os 3 achados foram curados no mesmo laço.
  Os pins das 4 portas conferem no remoto. APROVADO descreve o estado depois das curas. Depois do
  1º push, o CI reprovou 10 casos do a2a-verify: o members.yaml de sandbox da bancada declarava a fonte
  sem kind: source, e a autoridade passou a se ler pelo kind (fail-closed expondo harness incompleto).
  A fonte ganhou kind: source nos sandboxes que não o tinham. Revisto por mim: a2a e trust com 46 casos verdes.
---

# Resíduo — `chore/doors-registry-after-f6`

Depois da publicação das 4 portas (F6, 2026-10-10, pin `0bf23f0c`), o registro alcança o carimbo: pins
das 4 portas, a onion-core em `role: source` com `kind: door`, e o validador passa a aceitar a face
pública da fonte.

| # | achado | desfecho |
|---|---|---|
| A1 | **ALTA**: o `trust-topology-check` decidia a autoridade de fonte por `role == source`; um adotante com `role: source` + `kind: door` passava no validador e ficava AUTORIZADO a `correct` qualquer membro | curado: autoridade e inbox do core por `kind: source`; o validador aceita no máximo uma porta source; casos na bancada trust, fixture ruim de duas portas source e mutante (decidir pelo role) mordendo |
| A2 | projeções caducas (mapa e console da federação, inventário do harness) | curado pelo `ops/pr-finalize.sh` |
| A3 | comentários velhos no registro e exceção `n/a` do mini ainda aceita depois da publicação | curado: comentários emendados, exceção removida, fixture ruim do mini com `n/a` |

**Fora do escopo, ambiental:** a REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela) acusa
o adotante granaai porque o clone local dele está noutra branch. As portas passam.
