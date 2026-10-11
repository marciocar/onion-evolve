---
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 9
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Uma passada adversarial (branch-code-reviewer, default reprovado) sobre o versionamento das portas.
  REPROVOU com 1 bloqueador, 3 altos, 4 médios e deslizes de forma; dois achados foram reproduzidos
  rodando o motor numa cópia da bancada. Nove curados no mesmo PR, com caso e mutante; o resto ficou
  declarado no teto da doutrina. Antes da passada, o dogfood por ensaio real (--from desta branch, sem
  --push) nas quatro portas achou um defeito meu (ponteiro morto no mini) e um passivo de origin/main
  (o lint do onion-standalone sai com 1 HARD), declarado.
---

# Resíduo — `feat/onion-release-versioning`

Versionamento das portas, decisão do maestro de 2026-10-11 (nó `D_VERSIONAR_AS_PORTAS_POR_RELEASE`).

## Dogfood antes da passada (ensaio real, sem push)

- `onion-core`, `onion-plugins` (com `claude plugin validate --strict` real) e `onion-mini`: proposta
  `onion-v1.0.0 (primeira)`, verificação verde, changelog varrido.
- **Defeito meu:** o cabeçalho do `onion-version.sh` citava `/meta:publish`, que não viaja ao mini; o
  `door-mini-check` acusou ponteiro morto. Curado.
- **Passivo de origin/main, declarado:** o ensaio do `onion-standalone` sai com 1 HARD no lint da
  porta também a partir de `origin/main` (a lente `publish-lens.md` viaja e o glob dela aponta um
  arquivo que o corte do standalone não leva). Não é deste PR, e trava a release do standalone até ser
  curado.

## Passada adversarial — REPROVADA (10 achados, 9 reais)

**Curados, cada um com caso e mutante:**

1. **(bloqueador)** um assunto de commit com nome de adotante travava a porta para sempre: o assunto
   é imutável e entra no intervalo de toda release seguinte. Junto com o achado 4, a cura é que **os
   assuntos não viajam**; o changelog leva a contagem por tipo (r12, r12b).
2. **(alto)** a re-rodada que recupera uma tag gravava um changelog falso: o diff era contra a ponta,
   que já estava na release. Agora compara com a tag anterior (r4c).
3. **(alto)** o número "único da família" só valia no `--all`: uma porta propunha a partir da própria
   tag e aceitava um número que outra porta já usava noutro pin. Agora se leem as tags de todas as
   portas; a proposta parte do máximo e um número só nomeia um pin (r3f, r5c, r5d).
4. **(alto)** o changelog levava a biografia do core (assuntos internos) a uma porta sem biografia.
   Curado pelo item 1.
5. **(médio)** a re-rodada noutro dia, depois de uma tag que falhou, publicava um 2º commit. O
   `_same_rel` não depende mais da tag existir (r3d, com `date` falsa).
6. **(médio)** o `_same_rel` engolia uma troca de papel no mesmo pin e número. Agora exige que a única
   diferença seja a linha `materialized_at` (r3e).
7. **(médio)** tags ilegíveis viravam "primeira 1.0.0" e contaminavam a família. Agora é NÃO-MEDIDO, e
   a agregação do `--all` declara NÃO MEDIDA quando falta porta.
8. **(médio)** renomeação e chave do carimbo sem caso: r7b e r7c.
9. **(baixo)** as tags no `_core_state` traziam o falso positivo de outra sessão: agora só
   `refs/tags/onion-v*`.

**Formas curadas:** `--release=X` no materializador; a mensagem do ensaio por porta dentro do `--all`
aponta a proposta da família; o schema só é comparado quando há tag anterior.

**Declarados no teto (doutrina, "O que esta doutrina NÃO promete"):** tag local velha num `--clone`
do maestro faz a re-rodada sair rc 4; a versão derivada do `--status` é aproximação, não `git
describe`; a publicação da família não é atômica; a proposta lê nomes e chaves, não comportamento.

## Bancada

`run_publish_release_selftests` 26/26 com `LC_ALL=C`; mutantes por caso via `ops/mutate-and-restore.sh`
(core-only); `run_publish_selftests`, `run_write_stamp_selftests` e `run_door_selftests` verdes.
