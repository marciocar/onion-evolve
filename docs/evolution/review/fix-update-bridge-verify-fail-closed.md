---
branch: fix/update-bridge-verify-fail-closed
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 14
findings_real: 13
tokens: 259577
duration_min: 10
findings_fixed: 11
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose (opus), 2 passadas com mandato de refutar
nota: "tokens e duração somados das duas passadas do refutador; o trabalho de autoria não foi medido"
---

# Passada adversarial: `fix/update-bridge-verify-fail-closed`

## O que muda

A fase 6 do `ops/update-bridge.sh` vira FAIL-CLOSED. Medido numa sandbox: na versão de `origin/main`, o verify do degrau 1 ou o do runner reprovando matava o script na atribuição `VOUT="$(…)"; VRC=$?` sob `set -e`. O script saía com rc 1 ou 2 e sem uma linha, e o `case` do AVISO era código morto. JWKS ausente e serviço que caiu saíam rc 0 com AVISO.

Agora tudo que não se prova vai para `NOT_PROVEN`, e o script sai rc 1 nomeando cada item com a sua cura. Cobre: verify que reprova, verify que não mede (rc 2, 124 do teto), rc 1 sem linha FALHA, JWKS, NRestarts absoluto maior que zero, NRestarts ilegível, diretório das units ilegível e juiz do checkout diferente do clone servido. A saída imprime o rollback com os HEADs de antes e deixa o serviço RODANDO. O NOOP roda as mesmas checagens sobre o boot vivo, e a trava ocupada sai rc 2.

**Escolha (a), declarada:** falhar nomeado, sem rollback automático. O script tem os dois HEADs e o backup, mas o rollback refaz o npm ci, que depende de rede. Se o npm ci falhar, o serviço fica parado, pior que no ar com `/health` 200 e auth enforce. Além disso, o verify é o do core novo, e o bridge antigo pode reprovar o mesmo piso. A cura de cópias do runner defasadas é o install do runner. E o rollback não pode ser provado sem o serviço real.

Nó: `E_DEPLOY_DO_BRIDGE_REPROVA_O_QUE_NAO_PROVOU_1016` no grafo da rodada r12.

## Achados

1ª passada (8):

1. **ALTA, real, curado.** O NRestarts por delta tinha falso negativo. O refutador mediu no systemd 255 que o stop e o start manuais zeram o contador, e a checagem voltou a ser absoluta. Caso (u10).
2. **MÉDIA, real, curado em parte.** Um rc 1 sem linha FALHA saía como "0 falha(s)", e agora leva a última linha (u15). Os wrappers vizinhos que devolvem rc 1 quando o sudo falha não foram tocados: estão fora do diff, declarado.
3. **MÉDIA, real, curado.** O juiz do checkout do operador podia não ser o servido. Agora `sudo cmp` exige igualdade (u11, u21).
4. **MÉDIA, real, curado.** Cada item agora leva a sua cura para a frente.
5. **BAIXA, real, curado.** A frase "neste boot" foi trocada por "no momento da medida".
6. **BAIXA, real, não curado.** O JWKS é medido uma vez só; aceito, porque sai nomeado.
7. **BAIXA, real, curado.** Faltavam casos (u14 a u17), e o verify ganhou teto.
8. **MÉDIA, real, curado em parte.** O sudo falho no teste de instalado agora vai para NOT_PROVEN (u17). A ausência do drop-in segue "não se aplica" de propósito: o update não remove units.

2ª passada (6):

9. **MÉDIA, real, curado.** O "rode de novo" caía no NOOP e saía rc 0. Agora o NOOP re-verifica (u18, u19).
10. **BAIXA, real, curado.** O verify passou a rodar com `timeout -k 30` e `</dev/null`.
11. **BAIXA, real, curado.** O cmp rc 2 agora tem mensagem própria (u21).
12. **BAIXA, real, curado.** Os nomes de u10 e u16 passaram a dizer o que provam.
13. **INFORMATIVO, curado.** O comentário dizia que só o start zera o contador; o stop também zera.
14. **BAIXA, fora do diff, curado.** A trava ocupada saía rc 0 e agora sai rc 2 (u20).

## Mutantes

- Família `update_bridge`: 21 casos, cada um com mutante na cópia, **42/42** com `LC_ALL=C`.
- Cinco mutantes plantados no arquivo real por `ops/mutate-and-restore.sh`, com restauração conferida por hash e 0 marcadores restantes:
  - a forma antiga `; rc=$?` derrubou 7 casos intactos (u2 a u8);
  - o delta derrubou 2;
  - o limiar `-gt 9` derrubou 1 (u10);
  - a guarda cmp desligada derrubou 1 (u11);
  - o NOOP sem checagens derrubou 2 (u18, u19).

## Limites declarados

- Não houve deploy real; o deploy é da sessão principal. A prova é a sandbox: cópia com caminhos trocados por sed, guarda que reprova se sobrar caminho de produção, sudo, systemctl, journalctl, curl, npm e timeout falsos, e git real.
- O KILL real do timeout não é exercido (o timeout é falso).
- Os wrappers vizinhos devolvem rc 1 quando o sudo falha, e isso aparece aqui como REPROVOU, não como NÃO MEDIU.
- Moat-targets: não se aplica, porque nenhum caminho servido novo foi criado.
- O NOOP agora roda os verifies, que só leem, mas com sudo: ele fica mais lento do que o NOOP de antes.

## Re-revisão (rebase sobre origin/main 9ae5e233)

O rebase trouxe a SAC-155, o censo do SDK, que também mexe no grafo r12 e na bancada. O hash de código mudou só pelo contexto: as linhas
adicionadas e removidas de `ops/update-bridge.sh` e `.claude/validation/lint-selftest.sh` são IDÊNTICAS antes e depois. Medido com
`diff` das linhas `+`/`-` de `git diff 5179e467 af7d7c5a` contra as de `git diff origin/main HEAD`, saída vazia. O conflito real ficou no grafo
r12: os dois nós (o E_CENSO_MEDE_O_CLI_DO_SDK_1016 da main e o deste PR) foram mantidos, e a linha do teto foi para 16 nós. Radar e
contrato saíram com rc 0 depois da resolução, e o pré-voo do pr-finalize também ficou verde. Não houve nova passada de agente: a re-revisão é essa conferência
mecânica, declarada aqui.
