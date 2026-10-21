# Fixture de aceitação do `kg_migrate.py`: um adotante hub

O `corpus.tgz` é o corpus de um adotante real (papel hub) no estado anterior à migração ao contrato v4, anonimizado
por ele e publicado com a autorização dele. São 25 grafos e 1.024 nós no universo da migração.

- **O que foi tirado.** Os ids viraram hash estável (`N_<12 hex>`), o label virou `nó <hash>`, a narrative saiu e o
  `verified_against` ficou genérico. A estrutura ficou intacta: node_type, plane, status, impact, confidence, layer,
  source_kind, as datas e todas as arestas.
- **O trace é sintético, da mesma classe do original.** São código em `src/`, fonte versionada, prosa, reunião,
  pesquisa, outro grafo, URL, `drive:<n>`, conversa, script nunca versionado e vazio. Os caminhos existem na árvore
  como arquivos vazios, e os `src/ausente<n>.ts` faltam de propósito.
- **O `esperado.csv`, dentro do pacote, é o gabarito.** Ele traz a classe do `method`, a `locality` e o status de cada
  nó, tirados da migração que o adotante fez com o próprio classificador. A chave é grafo + id, porque 19 ids se
  repetem entre grafos.
- **O `profile.yaml` é o perfil medido.** Tem as regras do exemplo `spec/migrate-examples/company-brain.profile.yaml`
  com os ids reais (em hash) dos dois nós rebaixados e dos 18 nós com `verified_scope`.

O teste `AdopterHub` de `tools/test_kg_migrate.py` roda o `plan` e o `apply` sobre uma cópia e confere:
- **a classe do `method`** bate com o gabarito em todos os nós;
- **a `locality`** bate onde o gabarito tem uma (a migração original não marcava o Drive, que hoje é `privado`);
- **os dois rebaixamentos** viram `unverifiable`;
- **o `apply` não recusa nada**, e o segundo `apply` não muda nada;
- **nenhum nó** fica devendo `provenance` no MUST.
