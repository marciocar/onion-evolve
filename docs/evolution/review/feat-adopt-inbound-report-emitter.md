---
branch: feat/adopt-inbound-report-emitter
pr: pendente
date: 2026-11-24
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 11
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 11
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "1ª passada do condutor (4 achados, 3 reais) + revisão ISOLADA da sessão principal, que REPROVOU com 2 bloqueantes e 6 reais (8 mutantes sobreviventes); todos curados pelo condutor e 15 mutantes mortos na re-revisão"
nota: "tokens e duração não medidos (0); a re-revisão pós-cura é do condutor, não isolada"
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

## Revisão isolada (sessão principal, 2026-11-24): REPROVADA, curada

Bloqueantes:

1. **No `update` o rc saía 0 com medição faltando.** As linhas «não medido aqui» / «não informada ao emissor» (diff de
   hooks sem `--settings-before`, linha da `onion/vendor`, linha do adopter-guard) não entravam nas lacunas. **Cura:**
   as três viram lacuna (rc 3), como o `--prev` ausente no update (achado 5). O caso (a) agora passa tudo e exige
   rc 0; o (a2) omite as quatro e exige rc 3 com as quatro lacunas nomeadas.
2. **A família não discriminava: 8 mutantes do refutador sobreviveram.** **Cura:** casos novos por STUB dos irmãos
   (cópia do helper do disco ao lado de scripts falsos com rc pelo ambiente), um por rc raro: (f) HD rc 3, RC rc 3,
   DN rc 1, PG rc 4, PL rc 5; (g) o teto `ONION_INBOUND_LOG_MAX`; (d2) placeholder da `--vendor-line`; (a) o diff
   de hooks real com `--settings-before` (`+ PreToolUse [Bash] b.sh`, `1 → 2`).

Reais, não bloqueantes, curados:

3. PARE com rc próprio: **rc 4** (deny perdido, prove-gate rc 4, plan rc 5), vence o 3, bloco «⛔ PARE» no topo do
   relatório; documentado no cabeçalho e no adopt.md.
4. Pin normalizado para 12 pela fonte (`rev-parse --short=12`): 7 e 40 do mesmo commit dão um arquivo (caso b3).
5. `update` sem `--prev` diz «pin anterior não informado» e conta lacuna (não mais «1ª adoção»).
6. DEST normalizado com `cd && pwd -P` depois do `assert-dest`; o caminho devolvido ao chamador é absoluto (c2).
7. Linhas do chamador achatadas: quebras viram espaço, `<!--` vira `&lt;!--`, crase vira aspa, `#` inicial é
   escapado (d3). Achado do próprio conserto: no bash 5.2 o `&` cru na troca `${v//…/…}` repete o texto casado
   (`&lt;` saía `<!--lt;`); a troca vai entre aspas.
8. `usage()` cita `--settings-before`.

## Mutantes

Todos por `ops/mutate-and-restore.sh`, contra `LC_ALL=C bash .claude/validation/lint-selftest.sh --families inbound_report`.

Re-revisão (15 mutantes, todos mortos; a família tem 17 casos):

- M1 deny rc 1 vira ok → (f) DN; M2 remeasure-hard rc 3 medido → (f) HD; M3 prove-gate rc 4 sem PARE → (f) PG;
- M4 teto removido → (g); M5 placeholder da vendor ao relatório → (d2); M6 contrato NÃO MEDIDO sem lacuna → (f) RC;
- M7 plan rc 5 sem PARE → (f) PL; M8 `--diff` com o par errado → (a); M9 sem `--settings-before` sem lacuna → (a2);
- M10 pin sem normalizar → (b3); M11 linha não achatada → (d3); M12 `--prev` ausente sem lacuna → (a2);
- M13 DEST sem normalizar → (c2); M14 PARE devolvendo rc 3 → (f) DN, PG e PL; M15 guard ausente sem lacuna → (a2).

Primeira passada:

- pular a seção do Contrato KG-SSOT → (a) reprova;
- tratar o rc 3 do applied-delta como medido → (d) reprova;
- desligar o reaproveitamento do arquivo existente (sempre a data de hoje) → (b) e (b2) reprovam;
- desligar a detecção de placeholder na linha do adopter-guard → (d2) reprova.

## Limites declarados

- Rodar de novo conta o relatório da rodada anterior (não commitado) como 1 arquivo "pendente" no applied-delta.
- Saída de medição que contenha uma cerca de código quebra a formatação markdown da seção (o conteúdo fica).
- As linhas do adopter-guard e da `onion/vendor` seguem PASSADAS pelo chamador: o helper não as remede (o
  adopter-guard-core.sh rodado de novo diria "em dia", não o que o passo (0.6) fez).
- O tempo da família no runner do CI não foi medido; localmente, ~6 s de parede.
- O M13 só reprova pelo caminho devolvido: um DEST relativo não quebrava nenhum irmão medido (o gate real PROVOU sem a
  normalização); a cura fica pelo contrato de devolver caminho absoluto.
