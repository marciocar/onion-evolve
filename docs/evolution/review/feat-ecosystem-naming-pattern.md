---
branch: feat/ecosystem-naming-pattern
pr: pendente
date: 2026-11-27
reviewed_diff_sha256: pendente
findings_total: 14
findings_real: 14
findings_blocking: 3
tokens: 296612
duration_min: 44
findings_fixed: 13
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "refutador isolado (subagente general-purpose novo, sem o contexto nem o raciocínio do autor, mandato de refutar), que rodou o lint inteiro (14m36s), o validador em registros construídos e a bancada"
nota: "Padrão de nomes do ecossistema (D_ECOSYSTEM_NAMING_PATTERN_1127, SAC-567): aliases + rename_trigger no registro, validador, guardas 36/106/119 lendo o alias, KB e mapa."
---

# Passada adversarial: `feat/ecosystem-naming-pattern`

## O que muda

- `members.yaml`: campos `aliases:` (fluxo, numa linha) e `rename_trigger:`; dois membros antigos ganham
  alias; o membro novo da Persona do Onion Evolve é registrado antes do repo existir.
- `members-validate.sh`: colisão de alias com id e com alias, forma, prefixo nu, gatilho obrigatório,
  leitura igual entre PyYAML e o awk das guardas, aviso SOFT de membro novo fora do prefixo, e o mapa
  core-only obrigatório na fonte.
- REGRA 36 (lint), REGRA 106 (`door-leak-scan.sh`), REGRA 119 (`private-name-check.sh`) e o P2 do
  `projection-safety.sh` leem o alias. A REGRA 66 emite SOFT para os avisos.
- KB `concepts/ecosystem-naming.md` (genérica, viaja) e o mapa `docs/evolution/federation/ecosystem-naming-map.md`.

## Achados

| # | Severidade | Achado | Cura |
|---|---|---|---|
| 1 | bloqueante | o nome da Persona estava literal no `members-validate.sh` (viaja): a REGRA 36 dava HARD | o literal saiu; a Persona recebe o aviso SOFT de membro novo uma vez, e o texto do aviso a nomeia como categoria à parte |
| 2 | bloqueante | o mapa citava o nome comercial de um adotante: REGRA 33 HARD | trocado por «T2, sob um hub» |
| 3 | bloqueante | contagens à mão do índice de KBs (árvore e estatísticas) e projeções defasadas | índice corrigido (118/61); projeções regeneradas |
| 4 | importante | formas que o PyYAML aceita e o awk não lê (chave entre aspas, `- aliases:`, tag, escape) | o validador compara os dois conjuntos e reprova divergência; fixture e mutante (a2) |
| 5 | importante | `aliases:` aninhado fora do membro entrava no awk sem a checagem de colisão | coberto pela mesma comparação; fixture `members-bad-alias-nested.yaml` |
| 6 | importante | a mensagem HARD da REGRA 66 mostrava os avisos no lugar do erro | os avisos saem do `tail` da mensagem HARD |
| 7 | menor | prefixo nu com hífen no fim (`company-brain-`) passava | alias termina em letra ou dígito; fixture |
| 8 | menor | `aliases` de tipo errado dava traceback | reprova com mensagem; fixture |
| 9 | menor | apagar o mapa desligava a catraca; o gatilho do mapa não era conferido | mapa obrigatório na fonte; gatilho conferido contra o registro |
| 10 | menor | a bancada não cobria parte das afirmações | entraram prefixo nu, gatilho sem alias, alias igual ao próprio id e o mutante da comparação; o resto é limite (abaixo) |

O que o refutador tentou e não quebrou: colisão sem caixa nos dois sentidos, aspas e comentário no valor,
`[""]`, `aliases: []` com gatilho, lista em várias linhas, chave repetida, comentário do template, o
registro real e o mapa, o TSV do motor sem linha de alias, e o aviso que nunca muda o rc.

## Limites declarados

- A emissão SOFT da REGRA 66 no lint e o alias no P2 do `projection-safety.sh` não têm caso de bancada
  próprio: a 66 só roda com o marcador do registro real e o registro-base vem do git, que o sandbox não tem.
- O aviso de membro novo cala sem `origin/main` (checkout raso). É só aviso, então calar não reprova nada.
- Os cinco `onion-svc-*` e o `watcher-onion-evolve` ficam sem alias neste PR. O maestro decidiu em
  2026-11-28 que eles entram num 2º PR, pela superação «chave + nome + classe» (`class: client|internal`).
- A Persona é varrida pela REGRA 36 como qualquer id fora de `onion-*`. O maestro decidiu em 2026-11-28
  não isentá-la.

## Rodada 2 (delta de 2026-11-28)

Decisões do maestro aplicadas: a Persona ganha `piece: true`, e o comentário do remote passa a dizer o
medido (repo criado em 2026-11-27, privado e vazio). Um 2º refutador isolado, novo, revisou só esse delta
e deu APROVA COM RESSALVAS, com 4 achados:

| # | Severidade | Achado | Cura |
|---|---|---|---|
| 11 | importante | a peça entrou sem `local_path`, e o pulso da batuta entregava `cd <local_path>` como arranque | `local_path: /home/marcio/brain-onion-evolve` (clone vazio medido, origin = o remote); `ownership.sh who` agora devolve a pasta |
| 12 | importante | a peça entrou sem `sponsor`, que o cabeçalho do registro pede para peça | `sponsor: maestro`, como as outras peças |
| 13 | menor | a KB dizia «peça do Onion → `onion-<peça>`» e a Persona é peça sem o prefixo; a decisão de 11-28 só estava no comentário do YAML | a KB diz que ela é a única peça sem o prefixo e sem isenção; a decisão foi para a narrativa do nó `D_ECOSYSTEM_NAMING_PATTERN_1127` |
| 14 | menor, anterior | `piece: "true"` ou `piece: sim` passavam no validador e tiravam a peça do pulso calada | o validador exige booleano; fixture `members-bad-piece-not-bool.yaml` |

A bancada da rodada 2 rodou `ecosystem_naming` (11/11); a família `fixtures` inteira fica com o pr-finalize.

## O CI pegou dois defeitos meus depois da rodada 2

- O «mapa obrigatório na fonte» disparava nos registros SINTÉTICOS da família `federation_a2a`, que montam o
  caminho canônico num sandbox. Cura: só o checkout do CORE exige o mapa (marcador do registro real na 1ª linha e
  origin no core).
- O caso (a) da família `members_registry` reprovava qualquer menção à REGRA 66, e a 66 passou a emitir SOFT para
  o aviso de membro novo. Cura: o caso cobra só o HARD («registro da federação INVÁLIDO»).

Medido local: `federation_a2a,members_registry,ecosystem_naming` deu 138 de 138.
