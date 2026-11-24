---
branch: feat/adopt-inbound-report-emitter
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: a2dc26bcfbb360cb8c4b9791c5f7aed3daafd64f04fb9598878cb8b25bbefaff
reviewed_code_sha256: d4dbb56736b56b6b581f14f5838db02d548576242712d02cb29aae2b2b4aebad
findings_total: 4
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: FIXED
elenxo: true
elenxo_isolado: false
reviewer: "passada adversarial do PRÓPRIO condutor (não isolada): leu o helper contra o modo de falha medido (relatório não emitido em dois --update seguidos), plantou 4 mutantes por ops/mutate-and-restore.sh e rodou o helper num clone real de um adotante; a revisão isolada fica com a sessão principal"
nota: "tokens e duração da passada não foram medidos (0); elenxo_isolado false até a revisão isolada da sessão principal"
---

# Passada adversarial: `feat/adopt-inbound-report-emitter`

## O que muda

- `.claude/utils/adopt/emit-inbound-report.sh` (novo): GERA o relatório downstream da adoção e do `--update` no
  `docs/evolution/inbound/` do alvo, rodando cada medição que o procedimento mandava colar: `applied-delta.sh`,
  `remeasure-contract.sh` + `plan-contract-migration.sh` (saídas inteiras com rc e significado), a última linha do
  `prove-gate-blocks.sh`, as linhas do adopter-guard e da `onion/vendor` (passadas), no `--update` a configuração
  (`merge-onion-hooks.sh --diff`, `deny-monotonic.sh`, `sandbox-deny-advice.sh`, `remeasure-hard.sh`) e as
  Novidades como `git log --oneline <prev>..<pin>` da fonte com teto declarado. `assert-dest.sh` antes de qualquer
  escrita, `_processed/` criado, idempotente. rc 0 escrito · 2 uso · 3 escrito com lacuna · 1 falha de E/S.
- `.claude/commands/meta/adopt.md`: o heredoc com `<colar …>` do Procedimento de Relatório Downstream virou a
  chamada ao helper (os dois caminhos, adoção e `--update`, usam o mesmo procedimento), com a explicação curta.
- `.claude/validation/lint-selftest.sh`: família `inbound_report` (7 casos).

## Achados

1. **Real, curado.** A primeira versão saía rc 3 quando a ESCRITA falhava, e rc 3 é "relatório escrito com
   lacuna": o chamador leria um arquivo que não existe. Falha de E/S passou a rc 1, "nada escrito".
2. **Real, curado.** As linhas passadas pelo chamador (adopter-guard, vendor, integração) vêm do mesmo bloco com
   placeholders; copiado sem preencher, `<a linha …>` ia parar no relatório como se fosse medição, a mesma classe do
   heredoc. Valor `<…>` agora vira lacuna declarada (rc 3) ou, na integração, o padrão declarado. Caso (d2).
3. **Real, curado.** O texto do passo do `--update` manda pôr no relatório o diff de hooks, o deny, o sandbox e o
   HARD, que o heredoc não tinha: com o helper reescrevendo o arquivo, colar à mão por cima seria apagado na
   rodada seguinte. Esses quatro entraram no helper (seção "Configuração e HARD", só no `--update`).
4. **Não defeito.** O `prove-gate-blocks.sh` roda também na adoção (o procedimento pedia o veredito do
   verificador do passo (6) ali): a prova de bloqueio vale para qualquer papel, e é mais forte que o verificador.

## Mutantes

Todos por `ops/mutate-and-restore.sh`, contra `LC_ALL=C bash .claude/validation/lint-selftest.sh --families inbound_report`:

- pular a seção do Contrato KG-SSOT → (a) reprova;
- tratar o rc 3 do applied-delta como medido → (d) reprova;
- desligar o reaproveitamento do arquivo existente (sempre a data de hoje) → (b) e (b2) reprovam;
- desligar a detecção de placeholder na linha do adopter-guard → (d2) reprova.

## Limites declarados

- O mesmo commit com pin de comprimento diferente (12 contra 7 caracteres) não se reconhece como o mesmo relatório.
- Rodar de novo conta o relatório da rodada anterior (não commitado) como 1 arquivo "pendente" no applied-delta.
- Saída de medição que contenha uma cerca de código quebra a formatação markdown da seção (o conteúdo fica).
- As linhas do adopter-guard e da `onion/vendor` seguem PASSADAS pelo chamador: o helper não as remede (o
  adopter-guard-core.sh rodado de novo diria "em dia", não o que o passo (0.6) fez).
- O tempo da família no runner do CI não foi medido; localmente, ~5 s de parede.
