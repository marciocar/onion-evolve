---
branch: feat/service-repos-owner-vps-ops-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: pendente
findings_total: 15
findings_real: 13
findings_blocking: 2
findings_fixed: 9
tokens: 270000
duration_min: 7
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, com mandato de refutar e foco em escalada. A 1ª passada deu REJECTED com 2 achados bloqueantes. A 2ª deu APPROVED, com 4 não-bloqueantes e 1 teto. A 3ª conferiu as curas desses e deu APPROVED. A 4ª revisou o extrator do caso (q) da session_open e deu APPROVED."
nota: "tokens = soma aproximada das passadas pelo harness (119.577 + 150.193 + a 3ª). Os achados que não viraram código são tetos declarados abaixo."
---

# Passada adversarial: `feat/service-repos-owner-vps-ops-1120`

## O que muda

A decisão `D_SERVICE_REPOS_OWNER_VPS_OPS_1120`, de 20/11, dá à sessão `onion-vps-ops` a posse dos 4 repos de serviço da VPS: LibreChat,
Logto, WAHA e Vaultwarden. São repos privados do dono do core, sem CI, com base `master` e `ops/local-gate.sh`. A sessão merja os PRs
deles pelo caminho verificado, sem `--maestro`. Deploy e produção continuam com o maestro.

1. **`members.yaml`**: 4 membros novos, `onion-svc-*`.
   - `kind: method` é provisório, pela lacuna L7, como nos membros de teste do A2A.
   - `onion_version: n/a` e `owner_session: onion-vps-ops`.
   - O `parent` é a fonte, porque o validador exige `parent` = fonte para quem não é consumer.
   - O id não é o nome do clone, porque `onion-vps-*` já aparece em 5 arquivos que viajam (`grep -w`). Isso daria HARD da REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação).
2. **Catraca, regra (3), mesma dona registrada.** Uma sessão fora do core mergeia o alvo cujo membro tem a mesma `owner_session` que o membro do repo dela. Limites:
   - o alvo vem da lista pública e não é a fonte;
   - o repo da sessão está registrado pelo remote público, é do dono do core e não é porta, fonte nem repo de serviço (`kind method` ou `onion_version: n/a`).
3. **«Pode rodar» no delegado, acréscimo do maestro.** Na sessão do core, `--foreign-repo` passa a aceitar o `--one-touch-request` e o `--one-touch`. Só com a palavra do maestro, e só em alvo que não vendoriza:
   - o modo «repo sem CI» vale no delegado;
   - o PR sem resíduo passa. Resíduo presente continua sendo julgado.

   Detalhes do caminho:
   - O pedido não posta o comentário «Merge SEM CI». O uso posta, com a linha «Quem autorizou».
   - A linha `--run` leva o caminho absoluto, o `cd <clone>` e as flags.

## Achados e destino

| # | Passada | Achado | Destino |
|---|---|---|---|
| 1 | 1ª | **Bloqueante.** O «pode rodar» delegado dispensava o resíduo em qualquer membro com `owner_session`, inclusive nas peças que vendorizam e têm a REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial). | **Corrigido.** A dispensa e o modo sem CI só valem com `onion_version: n/a` (`_pmv_member_nonvendor`). Coberto por sv14, sv14-MUT, sv17 e sv17-MUT. |
| 2 | 1ª | **Bloqueante.** A troca do leitor no `_delegated_foreign_gate` reabria o delegado puro para os 6 membros com remote « (privado)». | **Corrigido.** O leitor antigo voltou intacto; o novo é só fallback para o membro que não vendoriza. Coberto por sv16 e sv16-MUT. |
| 3 | 1ª | A regra da mesma dona era simétrica: uma sessão num clone de serviço mergearia os irmãos e a casa. | **Corrigido.** A casa exclui `kind method` e `onion_version: n/a`. Coberto por sv13, sv13-MUT e sv13b-MUT. |
| 4 | 1ª | A linha `--run` não funcionava no modo sem CI e perdia flags. | **Corrigido.** Caminho absoluto com `%q`, `cd <clone>`, `--foreign-repo`, `--merge-commit`, `--keep-branch` e `--assert-ancestor`. O sv9 confere o pedido gravado. |
| 5 | 1ª | O comentário «Merge SEM CI» não dizia quem autorizou. | **Corrigido.** A linha condicional é exigida pelo sv10. |
| 6 | 1ª | No pedido, a sessão do core roda o `ops/local-gate.sh` do head alheio. O PR pode reescrever o próprio gate. O clone precisa estar no head do PR. | **Teto declarado.** Veja abaixo. |
| 7 | 1ª | As mensagens do MOAT (`ops/moat-targets.tsv:171`, `pretooluse-moat-gate.sh:225`) ainda dizem que o `--foreign-repo` sempre exige CI e resíduo. | **Teto declarado.** O texto ficou mais estrito que a regra, não mais frouxo. Fica para o PR que tocar o MOAT. |
| 8 | 1ª | Faltavam casos: `_via_priv`, repo da sessão `door`/`source` e dono diferente, resíduo presente e ruim. | Corrigido em parte: o resíduo ruim virou o sv15. **Teto:** as guardas `_via_priv = 0`, casa `door`/`source` e dono da casa (`_own%%/* = _corown`) não têm caso nem mutante próprio. |
| 9 | 1ª | Confirmação, não achado: o `members.yaml` não quebra os leitores que rodou (`members-validate`, `private-name-check`, `projection-safety`, `vendor-scrub-form-check`). O `peer-ref-check` não mediu. | Confirmado. |
| 10 | 1ª | Era preciso rebasear antes do resíduo. | **Feito.** A branch foi rebaseada sobre `origin/main`. |
| 11 | 2ª | Faltava caso para a cláusula `_DF_NONVENDOR` do modo sem CI. | **Corrigido.** sv17 e sv17-MUT. |
| 12 | 2ª | O cabeçalho do script estava atrás das curas. | **Corrigido.** |
| 13 | 2ª | Os critérios dependem de convenções do registro: «serviço» = `n/a`, «casa» ≠ `method`. | Corrigido em parte: a casa também exclui `n/a`. **Teto:** a L7, ao criar um kind de serviço, tem de tocar a exclusão do `_own_repo_gate`. |
| 14 | 2ª | Faltavam aspas na linha `--run`. | **Corrigido** com `%q`. |
| 15 | 2ª | Havia mudança não commitada por cima do `wip`. | O carimbo é do diff final, pelo `pr-finalize`. |

## Tetos declarados

- **Gate do PR alheio.** No pedido, a sessão do core roda o `ops/local-gate.sh` do head do PR alheio, no mesmo usuário Unix, antes da palavra do maestro. O PR pode reescrever o próprio gate; o comentário avisa, mas a linha do pedido não mostra isso.
- **Um escritor por clone.** No modo sem CI, o clone tem de estar no head do PR. Quem prepara é a sessão dona do clone (`onion-vps-ops`), ou uma worktree própria.
- **Camada de conformidade.** O «pode rodar» de nível 1 continua sendo camada de conformidade, não fronteira de segurança, como o selo de 18/11.

## Bancada

A família `pr_merge_verified` passou com 0 falhas. Casos sv1 a sv17:
- **Mesma dona aceita**, nos casos sv1 e sv7. O sv7 é o caminho inteiro: sem CI, base `master`, gate local no clone.
- **Dona diferente recusa** (sv2).
- **Alvo sem `owner_session` recusa** (sv3, sv3b).
- **Sessão sem membro recusa** (sv4).
- **Cliente e porta recusam** (sv5, sv6).
- **Clone de serviço não mergeia o irmão** (sv13).
- **«Pode rodar» delegado**, nos casos sv8 a sv12 e sv14 a sv17: pedido, uso, uso único, fora do core, peça que vendoriza, resíduo ruim e leitor antigo.

Cada regra nova tem caso. As guardas da linha 8 e a recusa do «pode rodar» com `--foreign-repo` fora do core (só o sv12) não têm mutante.

## 4ª passada: o caso (q) da `session_open`

O #1699, que entrou na main depois do rebase, extraía o awk da catraca de dentro do `_own_repo_gate` por padrão de texto. A catraca
agora chama o `_pmv_member_row` para o alvo, e a extração quebrou. O extrator novo:
- exige a chamada `_row="$(_pmv_member_row "${_t}" "${_m}")"` dentro do corpo do gate, limitado até o fim da função, como pediu o revisor;
- extrai o awk da própria `_pmv_member_row`.

O revisor confirmou que a paridade compara o awk que a catraca usa de fato. O mutante do (q) muda o leitor `ownership.sh` e segue
morrendo pela causa. As famílias `session_open` e `pr_merge_verified` passaram com 0 falhas.
