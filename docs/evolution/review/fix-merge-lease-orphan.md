---
branch: fix/merge-lease-orphan
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
findings_blocking: 1
tokens: 154323
duration_min: 9
findings_fixed: 7
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: subagente general-purpose (opus) com mandato de REFUTAR o diff do commit 37e839ee9, isolado do autor
nota: "o refutador não rodou a bancada (carga 14,87, acima de 12; parou a própria rodada). A bancada das duas famílias rodou pelo autor depois das curas."
---

# Passada adversarial: `fix/merge-lease-orphan`

## O que muda

- `ops/pr-merge-verified.sh`: o `pr-finalize --rebase --push` recusado pelo lease de carga (rc 75 do motor
  novo, ou rc 1 com a linha `PR-FINALIZE: carga: … load-lease rc=4` do motor antigo da branch) sai rc 5,
  «ADIADO PELA CARGA», sem rastro no PR e sem merge, e nunca mais «conflito de FONTE». O lease que não mediu
  (rc 2) para nomeando o lease. O teto da espera do lease nessa chamada cai para 600 s
  (`ONION_MERGE_LEASE_WAIT_MAX`), abaixo do timeout de 1200 s que o `merge-serial` dá ao verificado.
- `ops/pr-finalize.sh`: no teto do lease (rc 4) sai `exit 75` (EX_TEMPFAIL), dizendo o que já ficou local
  (rebase, commit do índice sujo).
- `ops/load-lease.sh` + `ops/load-lease.conf`: a vaga presa sem dono legítimo sai da CONTA (ninguém é morto):
  dono registrado morto ou de pid reusado; dono vivo órfão (o pai mudou desde a pegada, ou ppid 1 / pai
  `systemd` no holder antigo) há mais de `ONION_LOAD_ORPHAN_MAX` (7200 s); holder vazio pela idade do mtime.
  O holder grava início, pai e PID namespace, e é gravado sob a trava de admissão. A varredura conta sempre
  2×SLOTS_MAX vagas.

## Achados

1. **BLOQUEADOR (reproduzido pelo refutador):** a vaga extra só era varrida enquanto houvesse órfã antes
   dela; quando a órfã soltava, o dono legítimo da vaga extra ficava invisível e um 2º passo pesado entrava
   com N=1. **Curado:** a varredura conta sempre 2×SLOTS_MAX; caso (u3) com mutante.
2. **Maior:** pelo `merge-serial` (timeout 1200 s) o lease esperava 1800 s, e o adiamento virava «não sei»
   (124). **Curado:** a chamada passa `ONION_LOAD_WAIT_MAX=600`. O `merge-serial` tratar o rc 5 como
   «nova rodada» fica em Limites.
3. **Menor:** o rebase local que fica na worktree tira o caminho rápido da próxima rodada. **Curado na
   mensagem:** ela diz que a próxima rodada espera o CI do head novo.
4. **Menor:** «nada enviado nem pré-voo/lint» omitia o commit do índice sujo, feito antes do lease.
   **Curado:** a mensagem cita o commit quando `_PRECOMMIT=1`.
5. **Menor:** órfão sob outro subreaper não era detectado, e PID namespace daria falso MORTO. **Curado:**
   o holder grava `pai` e `pidns`; órfão = o pai mudou; namespace diferente conta. Casos (w2), (v3).
6. **Menor:** o motor antigo grava o holder fora da trava, e o novo podia ler o dono anterior morto.
   **Curado:** holder gravado há menos de 5 s não se julga morto; caso (v2).
7. **Menor:** mutantes fracos (sem o ramo `systemd`, sem o cenário 1, `_p_ldc` sem conferir o
   comentário). **Curado:** (w3), (u3) e o predicado.

## Mutantes

Cada caso novo reprova contra o seu mutante plantado pela própria família (`_llcase` / `_fxmut` /
`_prove_mutation`): load_lease (u) (u2) (u3) (v) (v2) (v3) (w) (w2) (w3) (x) (x2) (y); pr_merge_verified
(ld-a) (ld-b) (ld-c) (ld-d).

## Limites declarados

- O `ops/merge-serial.sh` não ganhou ramo próprio para o rc 5: o adiamento para a série com a linha
  `✗ auto-rebase ADIADO PELA CARGA…`, sem retentar sozinho.
- Na transição, o motor ANTIGO de uma branch (o que o `pr-merge-verified` executa na worktree dela) ainda
  varre só até SLOTS_MAX e não vê o dono de uma vaga extra: pode admitir um passo a mais enquanto houver
  motor antigo em uso.
- O teto de 7200 s (`ONION_LOAD_ORPHAN_MAX`) foi escolhido sem o maestro, pela bancada completa mais lenta
  medida (70 min sob carga).
- A vaga órfã sai da conta, mas o processo órfão segue rodando e gastando CPU; a admissão por carga é o que
  segura a máquina.

## Correção da declaração (22/11)

O revisor desta passada foi um agente separado do autor, como dizem o campo `reviewer:` e o corpo, mas o
frontmatter não declarava `elenxo_isolado: true`, e o `ops/pr-merge-verified.sh` recusa o merge de PR de guarda
sem esse campo. Acrescentei só a declaração. O código revisado não mudou: o diff volta a `pendente` e o hash do
código foi apagado, para o `pr-finalize` carimbar de novo.
