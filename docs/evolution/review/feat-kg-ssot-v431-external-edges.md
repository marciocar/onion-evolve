---
title: 'Resíduo — adoção do kit KG-SSOT kg-ssot-v4.3.1 e migração para external_edges (SAC-98)'
date: 2026-10-10
branch: feat/kg-ssot-v431-external-edges
reviewed_diff_sha256: 7f34c95a537e79cc9ebdddac2e0d798d10e935fd9aaa8b7018d8950696155718
reviewed_code_sha256: ae636386c514fa55cd68eaf26b342c547fa663bc48eafbba98111c6cd3c39438
findings_total: 5
findings_real: 5
findings_fixed: 4
tokens: 0
duration_min: 110
verdict: CORRIGIDO
elenxo: nao
nota: >-
  A passada é do autor. O contrato é vendorizado por pin, e o juízo dele é do onion-kg-ssot, que publicou
  a tag. Aqui se prova a integração: vendor íntegro, migração por script com alvo conferido, gate rc 0 com
  a base regravada, os leitores e os geradores do core na forma nova, e a bancada das famílias afetadas
  verde com LC_ALL=C e um mutante por cura, cada um reprovando um caso.
---

# O que a v4.3.1 mudou e o que precisou mudar aqui

A tag `kg-ssot-v4.3.1` (commit 33ea153f02fc, 297 arquivos) traz a 4.3.0 e o guia da classe do `method`. A tag
mudou de nome (`contract-vX.Y.Z` → `kg-ssot-vX.Y.Z`) e nada mais mudou nisso. A novidade é `external_edges`: uma
chave opcional no topo do grafo, uma aresta por item, com exatamente uma ponta externa `<caminho>#<id>`. O gate
confere essa ponta contra todos os `.kg.yaml` rastreados, inclusive os do `--exclude`.

## 1. Vendor e gate

- `kg_vendor.py update --tag kg-ssot-v4.3.1` e `check` íntegro.
- `kg_gate.py --update` com os `--exclude` do CI; a base segue em `granularity: node`.
- Antes e depois: 138 grafos, 19 na dívida herdada, a mesma dívida SHOULD (label 2162, verified_against 141,
  provenance.method 34, unquoted-date 129, untraced-decision 36, verified_at 15, testimony-in-prod 1).
- Só a identidade do contrato mudou. Não houve `--accept-regression`.

**Custo do índice de corpus.** O gate só monta o índice quando algum grafo do corpus usa `external_edges`, e
agora 9 usam. Ele lê os 430 `.kg.yaml` rastreados, e 284 deles são fixtures (247 do vendor). Medido na VPS
compartilhada (8 núcleos, carga 3,6):
- montagem do índice: 10,2 s;
- medição com o índice: 26,7 s; sem ele, 24,3 s;
- gate inteiro: ~34 s.

O custo vem de reler as fixtures, que nunca são alvo. Isso é sinal para o dono do contrato e não se cura aqui,
porque o vendor não se edita.

## 2. Migração

O `kg-migrate-v3.py` ganhou o modo `--external-edges`:
- `x_supersedes_external` no meta (escalar ou lista) vira um item `{to, edge_type: SUPERSEDES}` por alvo, sem
  `from`;
- `x_constrained_by` no nó N vira `{from: alvo, to: N, edge_type: CONSTRAINS}`;
- `x_supersedes_none` fica, porque declara algo e não é aresta, como o ADOPTING diz.

A ferramenta recusa alvo inexistente (rc 2, nada gravado) e prova que o YAML relido difere do de antes só pela
tradução. A narrative que citava `x_constrained_by` ganha a frase de onde a aresta mora agora.

| Tipo | Arestas | Grafos |
|---|---:|---|
| SUPERSEDES | 17 | evolve-cures (7), door-role-parity (7), evolve-staleness, vetos-por-tokens, elenxo-bulbo |
| CONSTRAINS | 6 | onion-identity (2), distribuicao-metodo-vivo (2), onion-tier-matrix, triagem-inbox |

**Referências quebradas: zero.** Conferi os 23 alvos (arquivo e id) antes de migrar. Na 2ª passada, o
`--check` sai rc 0; o `kg_validate --corpus .` aprova os 9 grafos, exceto o `triagem-inbox`, que já estava na
dívida herdada com `form.unknown-key.node.resolution`.

Dois comentários e uma narrative descreviam a chave velha como lugar da aresta, e foram atualizados:
- o comentário de `door-role-parity`;
- o teto de `onion-doctrine-elenxo-bulbo`;
- a narrative de `D_MATRIZ_DE_PORTAS_2026_10`.

## 3. Leitores

- **REGRA 89 (Rodada de radar selada reconcilia o corpus que superou (Aufhebung), com catraca)**
  (`radar-aufhebung-check.sh`):
  - aceita `external_edges` com SUPERSEDES;
  - a aresta conta pelo bloco (`edges:` ou `external_edges:`);
  - a CONSTRAINS externa não é Aufhebung;
  - a chave velha deixou de contar (achado 2);
  - o baseline segue com as mesmas 5 rodadas.
- **kg-radar:** seção `external_edges` própria (achado 1):
  - a ponta local conta como ligação, então nó ligado só por aresta externa não é órfão;
  - ponta local inexistente e tipo fora da lista reprovam;
  - a ponta externa fica com o gate, porque o radar é de um arquivo.

  Contra os casos do vendor, o radar concorda com o contrato em `integrity/external-local` (os dois) e aprova os
  três válidos de `form/external-edges`. Os inválidos de forma são do contrato. O `--integrity` sai exit 0 nos 9
  grafos migrados e no grafo do contrato.
- **kg-view (a lente):** soma a ponta local no grau, em paridade com o motor (achado 5).
- **kg-contract-check:** monta o mesmo índice quando o grafo usa a chave e dá a cura dos dois códigos MUST novos
  (achado 3).
- **kg-drive e kg-seal-exception:** só leem `x_drive_checkpoint`, que é declaração e fica `x_`. O `_ckpt` reescreve
  o bloco meta até a próxima chave de topo, e `external_edges` é chave de topo, então nada muda neles.

## 4. Geradores

- **`cc-delta-census.sh --write`:** o esqueleto traz a Aufhebung na forma nova, comentada, com o `kg:` da rodada
  anterior preenchido e o nó a nomear. Descomentar sem nomear seria alvo inventado.
- **`/meta:radar`, `/meta:cc-update` e a doutrina do cc-update:** `external_edges` SUPERSEDES no lugar de
  `x_supersedes_external`.
- **`/onion-research`:** a pesquisa que contradiz nó de outro grafo escreve a aresta em `external_edges`. Antes,
  pedia SUPERSEDES cross-file, que o motor não sabia ler.
- **`kg-grammar`:** a linha de `external_edges`.
- **A matriz de portas:** foi escrita à mão e não tem gerador. É o `door-role-parity`, migrado acima.

# Achados

1. **Real, curado: o kg-radar lia `external_edges` como a seção anterior.** O radar só trocava de seção em
   `meta:`, `nodes:` e `edges:`. Um bloco `external_edges` depois de `edges:` virava aresta intra-arquivo com
   `from` pendurado, e o `edge_type:` do item sobrescrevia o da última aresta real. Os grafos migrados escapavam
   porque a migração escreve o bloco antes de `nodes:`, mas um grafo escrito à mão pelo contrato cairia nisso.
   Cura: seção própria. Mutante (m), que tira a seção, reprova o caso (k).
2. **Real, curado: a REGRA 89 aceitava a chave velha sem conferir o alvo.** O caso (d) da bancada passava com
   `outro.kg.yaml#E_VELHO`, que não existe. Com a forma do contrato o gate confere o alvo, e manter a chave velha
   deixaria a porta sem conferência aberta ao lado da conferida. Cura: a chave velha não conta mais; os casos (d)
   e (d2) passaram a exigir acusação. Mutante: devolver `supersedes_(none|external)` ao awk reprova (d) e (d2).
3. **Real, curado: o kg-contract-check aprovava ponta externa inexistente.** Sem o índice, o leitor de referência
   confere só a forma e a ponta local. Medido com o mutante: `extruim.kg.yaml` saía "conforme". Cura: o índice se
   monta quando o grafo usa a chave. O caso (i) reprova o mutante.
5. **Real, curado: a lente divergia do motor no grau (REGRA 31 (Lente do grafo: DERIVADA e em paridade com o
   motor)).** O 1º `pr-finalize --check` reprovou 4 grafos migrados com 6 HARD. Quando o kg-radar passou a contar
   a ponta local, o `kg-view.sh` não acompanhou, e a atenção de 6 nós divergia, por exemplo
   `D_ADOPT_REFRAME` 23,75 no motor e 19,00 na lente. O mesmo `--check` acusou a REGRA 19 (Plugins de vertical
   (plugins/*) sincronizados com as fontes) no `onion-engineering`, que também leva o kg-radar. Cura: a lente lê a
   seção, e os dois plugins foram remontados. O caso (n) traz o mutante que quebra a paridade. Depois da cura, o
   `--check` dá 0 HARD.
4. **Real, NÃO curado (decisão do maestro): sobreposição em `door-role-parity`.** A migração é 1:1. A Aufhebung
   do grafo virou SUPERSEDES do grafo inteiro sobre 7 alvos, e 6 desses alvos também recebem CONSTRAINS da
   `D_MATRIZ_DE_PORTAS_2026_10`, que o maestro selou em 2026-10-09 como "CONSTRAINS, sem flip". As duas chaves já
   coexistiam antes. A migração não decide entre elas, porque mudar o tipo seria mudar a verdade do grafo. Fica
   nomeado no nó `E_CONTRATO_V43_ADOTADO`.

# Mutantes (LC_ALL=C, a cura revertida e o caso exigido em ✗)

| Mutante | Caso que reprova |
|---|---|
| kg-contract-check mede sem o índice (`None`) | `kg-contract-check (i)` |
| REGRA 89 sem o `_has_edge … external_edges` | `radar-aufhebung (d4)` |
| REGRA 89 volta a aceitar `supersedes_external` | `radar-aufhebung (d)` e `(d2)` |
| REGRA 89 conta qualquer tipo no bloco externo | `radar-aufhebung (d5)` |
| cc-delta-census volta a ensinar `x_supersedes_external` | `cc-delta-census (i)` |
| kg-radar não conta a ponta local como ligação | `kg-radar-contract (l)`, dentro da família |
| kg-radar sem a seção `external_edges` | `kg-radar-contract (m)`, dentro da família |
| kg-view sem somar a ponta local no grau | `kg-radar-contract (n)`, dentro da família |
| kg-migrate-v3 sem a conferência do alvo | `kg-migrate-v3 (x)` |
| kg-migrate-v3 com from/to do CONSTRAINS invertidos | `kg-migrate-v3 (x)` |

Famílias pedidas: `radar_aufhebung` 21/21, `kg_contract_check` 9/9, `cc_delta_census` 11/11, `drive` e
`seal_exception` verdes. A faixa `--affected` dos arquivos tocados tem 46 famílias, e a `fixtures` ficou com o CI:
377/377 com `--jobs 6`.

# KG

O nó `E_CONTRATO_V43_ADOTADO` foi criado em `contrato-kg-absorcao-2026-10` e `SUPPORTS`
`D_GATE_CHAMA_O_VALIDADOR_DO_CONTRATO` e `Q_ABSORVER_VALIDADOR_DO_CONTRATO`. O teto sobe de 26 para 27, com
justificativa. O lote 12 (onda O7) foi selado com `--seal`. Este é o lote 13, aberto com `--close-lot` e pendente
do selo do maestro.

# Os `confirmed` dos grafos editados

O PR muda a forma de 23 arestas e não muda nenhuma afirmação. Nenhum label, status ou plano foi tocado; a
narrative de 6 nós e a da matriz ganharam só a frase de onde a aresta mora. A ferramenta prova isso grafo a grafo,
relendo o YAML. Os alvos `confirmed` de maior impacto são `D_FAMILIA_TEM_TRES_REGIMES_2026_09` e
`E_FAMILIA_MULTIIDE_CONGELADA`, em `onion-identity`. Eles seguem `confirmed`, como o selo de 2026-10-09 manda
("sem flip"). Este PR não responde nem refuta o que eles afirmam.

# Tetos

- O radar não confere a ponta externa: é um arquivo por invocação. Quem confere é o gate do CI e o
  `kg-contract-check`. Fora deles, a ponta externa fica sem conferência.
- A REGRA 89 julga a existência da aresta SUPERSEDES, não a do alvo. O alvo é do gate.
- O índice relê fixtures que nunca são alvo (achado de custo acima). Isso fica para o dono do contrato.
