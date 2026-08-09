---
branch: fix/carimbo-de-campo-floors
date: 2026-08-09
reviewed_diff_sha256: 6f6fdb814042c59a1d5b67ea47b90550b838e3c4cca21f18f29c831828621f51
findings_total: 1
findings_real: 1
findings_fixed: 0
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-E-O-PRIMEIRO-CARIMBO-DE-CAMPO-O-ACHADO-E-DE-PRODUCAO-NAO-DE-CODIGO
reviewer: sem passada adversarial — mudança de dados (grafo + baseline), nenhuma linha de código
---

# O primeiro `CARIMBADO` de campo — e a medição achou um piso decorativo

Este é o **primeiro nó a sair do baseline da REGRA 49 por medição real**, não por regeneração.
Baseline **48 → 47**, uma linha sai, **zero entram**.

## O que foi medido

`Q_floors_effective` perguntava, desde 26/07: *"floors aplicados podem estar INEFETIVOS: verificar o
EFETIVO, não o configurado. É uma CLASSE, não um caso."* Ficou aberto porque a sessão que o escreveu
o marcou **VPS-DECLARADO** — o que ela não pôde medir.

Esta sessão roda **em `srv1812846`**, que é o host de que o nó fala. O que era `unverifiable` de
fora é medível de dentro, e essa é toda a diferença entre os dois rótulos.

## A preocupação procedia

A classe tem **três** membros, não um:

| drop-in | declara | unit alvo | efeito |
|---|---|---|---|
| `system.slice.d` | 384M / 768M | `loaded, active` | vale |
| `caddy.service.d` | 64M / 128M | `loaded, active` | vale |
| `onion-bridge.service.d` | **256M / 512M** | **`not-found, failed`** | **nenhum** |

O bridge que roda é `onion-vps-bridge.service`, com `MemoryMin=0` e `MemoryLow=0`. O serviço ganhou o
prefixo `onion-vps-` (convenção da casa para serviços core da VPS) e **o drop-in ficou para trás,
protegendo um fantasma**.

A medição de **29/07** registrava `onion-bridge.service=268435456 (256M)` lida do cgroup. Ela estava
**certa quando foi feita** — não é erro de quem mediu, é o mundo andando depois. Por isso aquele nó
vira `drifted`, e não `refuted`: `drifted` é o status que existe exatamente para *"mediu, e a
realidade mudou"*, e ele **sobe** a atenção (fator 1.3) em vez de zerá-la.

## O método é o achado, e generaliza

Enumerar por **runtime** — `systemctl list-unit-files --type=service` — encontrou **UM** membro.
Perde slice (não é service) e perde unit inexistente (não responde a `show`). Quem achou os três foi
`grep` nos **arquivos** de unit.

**Enumerar pelo que responde ao runtime é cego justamente para o caso que interessa: a configuração
órfã.** Um piso que aponta para nada nunca aparece numa lista de coisas que existem.

É a mesma forma do `behavior-over-declaration` desta casa, com o sinal invertido: ali se desconfia do
que o artefato *declara* de si; aqui, do que o *runtime* consegue listar. Nos dois casos a cura é
olhar a fonte, não o índice.

## O que NÃO foi feito, e por quê

**A correção em produção não foi executada.** Renomear `onion-bridge.service.d/` para
`onion-vps-bridge.service.d/` + `daemon-reload` restauraria os 256M/512M que já se pretendia dar — e
está escrito no nó como **sugestão clara**, que é o que a diretriz do maestro permite. Mudança em
produção na VPS é decisão dele, não minha; a autorização desta sessão cobre repo (comandos, commits,
PRs, merges).

## Verificação

- `Q_floors_effective`: `status: confirmed`, `verified_at: 2026-08-09`, `verified_against` nomeando o
  host e o método
- `E_floors_effective_measured_20260729`: `confirmed → drifted`, e aparece no `--freshness-tsv`
- radar do grafo: **116 nós, 163 arestas, sem contradições**
- catraca: emitiu `CARIMBADO … remova do baseline`, e a remoção foi feita **com `--emit-baseline`**,
  não à mão — `SAI 1, ENTRA 0`
- re-medido **no ato do carimbo**, não pela anotação de uma hora antes: carimbo não vale por lembrança
- bancada e lint: ver rodapé

## Dívida declarada

- **Sem passada adversarial.** É mudança de dados (grafo + baseline), zero linhas de código. O que
  substitui: a medição foi refeita no ato, por dois caminhos independentes (runtime e arquivos de
  unit), e os dois discordaram — foi a discordância que produziu o achado.
- **Só 1 dos 5 nós da W2.** O plano pede cinco, um por classe de saída. Este é o `CARIMBADO`. Faltam
  `RECONCILIADO` e as tentativas que devem MORDER (`REMOVIDO`, `FUGA-DE-ESCOPO`, `ID-AMBIGUO`) — e
  vale registrar a correção de leitura: **as três HARD não são saídas legítimas do baseline**, são o
  que acontece quando alguém sai errado. O dogfood delas é *tentar e ser recusado*, não *conseguir*.
- **Os outros dois nós `VPS-DECLARADO`** (`Q_route_inventory`, `Q_vps_declared`) seguem abertos e
  agora se sabe que são medíveis daqui.
