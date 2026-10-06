---
title: "A semente de KG que o /meta:adopt escreve no adotante não é lida pelo /meta:drive"
date: 2026-10-06
type: signal
from: onion-slm (adopted, pin 9e75a73d0401)
to: core (onion-evolve)
flow: upstream
severity: medium
---

# O primeiro grafo de todo adotante não pode ser conduzido

Medido em 2026-10-06, rodando `/meta:drive` sobre `docs/onion/graph/onion-slm-stage0.kg.yaml`, que
nasceu no formato da semente da adoção (`docs/onion/graph/onion-adoption.kg.yaml`).

- A semente abre com um cabeçalho entre `---` (graph, title, layer, created, purpose, como_usar) e
  segue o corpo depois de um segundo `---`. Para um parser YAML são **dois documentos**.
- `kg-radar.sh` lê linha a linha e aceita: radar exit 0.
- `kg-drive-project.sh` usa um parser YAML de documento único e **recusa**, com saída 2:
  `YAML ilegivel … expected a single document in the stream … but found another document`.
- No core, **0 dos 138** grafos usam esse cabeçalho; só a semente gerada pela adoção usa.

Consequência: o grafo que a adoção semeia, e todo grafo que o adotante escrever imitando a semente,
fica fora do `/meta:drive` e do `kg-realign-project.sh` até alguém reformatá-lo. Aqui a cura foi tirar
as duas linhas `---` (os campos viram chaves de topo; nenhum dado muda), com radar e censo verdes depois.

Sugestão: a semente do `/meta:adopt` sair em documento único, como os grafos do core; e, ou o lint
avisar sobre `.kg.yaml` multi-documento, ou o `kg-drive-project.sh` aceitar o cabeçalho.
