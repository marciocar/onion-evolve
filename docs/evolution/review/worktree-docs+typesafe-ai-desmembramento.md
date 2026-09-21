---
branch: worktree-docs+typesafe-ai-desmembramento
date: 2026-09-21
reviewed_diff_sha256: f0c859e7cfe4bde2c8d780a63e3d19d27e2b729125dc21c457e06e3d0fc30c7a
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 8
verdict: REPROVADO_E_CURADO
reviewer: passada própria sobre o próprio artefato (sem subagente) — gate mecânico: kg-radar + lint-artifacts
---

# Documentei um vendor de "decisão calibrada" e errei um número por não calibrar a minha

> **Nota de vocabulário:** a primeira redação deste resíduo escreveu `verdict:` como uma frase narrativa
> — exatamente o texto livre que o selo de 2026-09-08 fechou. O `testing-state.sh` mostrou o custo na
> hora: o legado subiu de 90 para 91, e a catraca existe para esse número **descer**. Corrigido para
> `REPROVADO_E_CURADO`; a narrativa mora no corpo, que é onde ela sempre coube.

Esta rodada produziu documentação sobre a **TypeSafe AI** — um lab cujo produto inteiro se vende como
*decisão com incerteza honesta*. A passada adversarial sobre o meu próprio artefato achou três coisas,
e a primeira é constrangedora na medida certa.

## Achado 1 — número de manchete invertido, propagado de um resumo (REAL, curado)

Escrevi no SYNTHESIS e no `.kg.yaml`: *"193,6x mais barato, 444,6x mais rápido"*.

O correto, no HTML cru da home: **`193.6x Faster,<br>444.6x Cheaper.`** — invertido.

**A causa não foi desatenção de leitura, foi confiança na camada errada.** Eu tinha **duas** leituras da
mesma página: a transcrição da home trazia o par certo, e a análise do blog trazia o par trocado. Eu
peguei o segundo e não notei que ele contradizia o primeiro. Um resumo automático trocou dois rótulos e
eu repassei a troca.

A cura aplicada foi medir na fonte crua (`curl` + `grep` no HTML) e, na mesma passada, conferir os
outros números da vitrine pelo mesmo caminho — `238x`, `Per Billion input tokens` e `Fable 5.1`
bateram. A lição ficou **escrita dentro do próprio documento**, não só aqui, porque é lá que quem lê o
número vai estar:

> **Número de manchete se confere na fonte crua, não num resumo dela** — e duas leituras discordantes
> da mesma página são um sinal a perseguir, não ruído a mediar.

É a classe `relay-machine-signals-with-source-label` aplicada a um caso novo: a saída de uma ferramenta
é **declaração**, inclusive quando a ferramenta é um resumidor e o assunto é um número.

## Achado 2 — teto do `meta:` declarado antes de contar os nós (REAL, curado)

Declarei `TETO: 24 NÓS` no `meta:` e escrevi 25. O lint pegou como **HARD** — REGRA 58 (O backlog
cumpre as promessas do próprio `meta:`). Curado para 25.

Vale registrar *por que* isso passou: escrevi o cabeçalho do grafo **antes** de terminar os nós, com o
número que eu *planejava* ter. É a mesma família do `exit-code-nao-e-a-verificacao` — declarei sobre
mim mesmo em vez de contar o que produzi. A guarda mecânica funcionou sem ninguém pedir.

## Achado 3 — arestas em flow style que o radar não lê (REAL, curado)

Escrevi as 28 arestas como `- { from: X, to: Y, edge_type: Z }`. O radar é `awk`, não parser YAML: o
resultado foi **25 nós órfãos de grau 0** e exit 1 — um grafo que *parecia* escrito e estava, para o
leitor que importa, vazio.

Curado convertendo para o bloco canônico (uma chave por linha). A regra `kg-grammar` diz isso
explicitamente — *"Formato estrito: o radar é awk, não parser YAML"* — e ela carrega por path
justamente quando se toca um `.kg.yaml`. Eu a li **depois** de escrever. Inverter essa ordem é a cura,
e ela não precisa de mecanismo novo: o mecanismo existe e disparou.

## O que NÃO foi revisado, e fica dito

Nenhuma afirmação **sobre o produto** foi verificada por execução — não houve chamada à API. A passada
cobriu **fidelidade à fonte** (o documento diz o que a fonte diz?) e **conformidade de artefato** (o
grafo é legível? o lint passa?). Não cobriu, porque não podia, **se o produto faz o que declara**. O
`§9 NÃO-VERIFICADOS` do SYNTHESIS carrega essa lista como item de primeira classe.

## Gate mecânico no SHA final

- `bash .claude/validation/kg-radar.sh docs/evolution/research/typesafe-ai-2026-09/typesafe-ai-2026-09.kg.yaml` → **exit 0** (25 nós, 28 arestas, sem contradição estrutural)
- `bash .claude/validation/lint-artifacts.sh` → **exit 0** (0 HARD; as 12 SOFT restantes são pré-existentes e alheias a este diff)
