---
reviewed_diff_sha256: ebaa6ede09584829fb7e0ed71946ae42a0d2302a7f88bc1902d9033cfc0644d8
reviewed_code_sha256: a634dcb1b8937b18aa56a9e5ba79461f858f51dd46444908af30b89204de76b2
findings_total: 10
findings_real: 10
tokens: 183517
duration_min: 9
verdict: APROVADO
elenxo: sim
nota: >
  O refutador (branch-code-reviewer) começou pelo default REPROVADO e tinha um mandato: achar falso
  negativo no corte (a porta standalone ou a plugins ganhando o canal upstream, ou o adotado standalone
  perdendo o canal) e falso positivo (recusa ou reprovação indevida). Não achou bloqueador. Mediu os
  manifestos por destino e todos os chamadores que decidem o corte pelo papel. Dos 10 achados, 8 foram
  curados no mesmo laço. Os achados 1 e 6 viraram a pergunta Q_CARIMBO_DO_ADOTADO_STANDALONE, com
  gatilho. APROVADO descreve o estado depois das curas. Revisto por mim: as curas têm caso e mutante na
  bancada, e os mutantes plantados por ops/mutate-and-restore.sh foram mortos.
  Depois do PR aberto, o contexto principal rebaseou sobre a main (que andou com #1012/#1013) e
  acrescentou só o pin do portal-gamificacao no members.yaml (registry-pins --seal, remoto); revisto, sem
  mudança no código do PR.
---

# Resíduo — `feat/doors-decisions-sealed`

Este PR fecha as quatro decisões do maestro de 2026-10-11 sobre as portas e escreve a evidência da F6.
A decisão 2 mexe no mecanismo: o papel de **adoção** standalone deixa de seguir o papel de **porta**
standalone.

| # | achado | desfecho |
|---|---|---|
| A1 | O lint e a REGRA 92 (Papel da porta no registro concorda com o CARIMBO dela) ainda leem `role: standalone` sem `kind: door` como porta. O mapa da REGRA 92 só aceita registro standalone com carimbo `adopted`, e o `IS_DERIVED` só liga para `adopted\|hub` | **declarado**: virou `Q_CARIMBO_DO_ADOTADO_STANDALONE`, com gatilho no 1º `/meta:adopt --role standalone` real. Hoje ninguém é afetado: o único carimbo standalone é a própria porta |
| A2 | O destino chega ao `vendor-branch.sh` só pelo env, que se perde entre chamadas do agente, e o default erra para o lado da porta | **curado**: com o env vazio, o vendor-branch lê papel e destino do carimbo do alvo. Isso cura também o defeito-irmão anterior, de papel perdido virar `adopted`. Caso (u6) e mutante (u6-MUT) |
| A3 | O nó de evidência dizia "9 linhas", e a soma é 8 | **curado** |
| A4 | `utils/co-evolution/` viaja inteiro, com motores do lado do core inertes | **declarado** no narrative: é o mesmo que o `adopted` já recebe |
| A5 | O KEEPBAD aceitava um comando do conjunto `adoption` no `adoption_keeps` | **curado**, com o caso (p5) |
| A6 | O wizard não lê o kind | **declarado**: dentro do Q de A1, com o comentário emendado. Nenhuma transição tem procedimento em co-* hoje (medido) |
| A7 | O `--list` não mostrava o destino | **curado** |
| A8 | O resolvedor aceitava `--kind adoption` com papel só de porta | **curado**: sai rc 2, com o caso (p5) |
| A9 | Havia comentários defasados (personality-sync em `pending`, cabeçalho do corte) | **curado** nos três sítios de código. O texto da skill wizard e os links de co-* estão declarados no Q de A1 |
| A10 | Redação do D da fábrica de verticais | **curado** |

**Bancada** (LC_ALL=C, só as famílias tocadas, nunca a bancada completa): role_cut, role_bundle,
vendor_manifest, vendor_branch, adopted_role, adopt_robust, moat_boundary, materialize_repo, door,
door_mini, door_role_parity, publish, door_cycle, door_staleness_severity, trust_topology, role_scope,
command_role_parity, core_only_role, hub_role_guard, vendor_scrub_form, kb_vendored_link,
family_topology, role_vocabulary, plugin_bundle e capability, todas verdes.

**Mutantes** pelo `ops/mutate-and-restore.sh`, todos reprovando o caso nomeado:
- M1 e M2: o predicado do destino;
- M3: `adoption_keeps` vazio;
- M4: o `--update` sem derivar door;
- M5 e M6: default door no resolve-manifest e no vendor-branch;
- M7: personality-sync de volta ao pending;
- M8: o vendor-branch sem o papel do carimbo;
- M9: KEEPBAD aceitando o conjunto adoption;
- M10: o resolvedor aceitando papel de porta.

**Fora do escopo, ambiental:** a REGRA 92 acusa o clone local da granaai, que está noutro checkout.
Nenhuma porta é acusada.
