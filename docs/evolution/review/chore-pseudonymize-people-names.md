---
title: 'Resíduo — os nomes de pessoas da árvore pública do core viram papel, e o vínculo mora num mapa privado'
date: 2026-10-13
branch: chore/pseudonymize-people-names
reviewed_diff_sha256: 6777bfe4d1f612f679d3d97df0e1af6a3ab96f9235f0d852877c3b4fae3c6f2a
reviewed_code_sha256: a2e4d0da9d0e60b30bddd16d17a08e251ccc281a2379e3969c572ac510066e6c
findings_total: 4
findings_real: 4
findings_fixed: 2
tokens: 180000
duration_min: 60
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Decisão do maestro de 2026-10-13 (/meta:decide): «Por papel + mapa privado». Dois devs do time
  granaai saem da árvore como dev-1 e dev-2, inclusive nas chaves de linhagem do members.yaml. O
  vínculo papel → pessoa fica num arquivo 0600 fora do repo, ao lado da lista privada de termos.
  O histórico do repo não é reescrito. Sem guarda nova: a opção com guarda foi descartada.
---

# Os nomes de pessoas viram papel

## O que muda

1. **78 ocorrências em 25 arquivos** viram papel: `dev-1` (65) e `dev-2` (13). As formas trocadas
   são o nome completo, o primeiro nome, dois handles, um e-mail (o do campo `reviewer`) e as duas
   chaves de linhagem do granaai no `members.yaml`. A de `dev-1` virou `dev-1:` e a do dev-2 virou
   `instancia-offline:`.
2. **Nenhum leitor das chaves velhas.** `lineages:` é lido genericamente (`graph.sh`, `machine_path.py`).
   `ops/registry-pins.sh` não lê linhagem, e o `members-validate.sh` não nomeia chave. O resultado
   antes e depois é idêntico: `members-validate.sh` rc 0 com 28 membros, e `registry-pins.sh --check`
   rc 0, 20 em dia e 0 divergentes. A saída foi comparada inteira com `diff`.
3. **O mapa privado** fica em `~/.config/onion/people-map.txt`, modo 600 conferido por `stat`, fora
   do repo. Cada linha tem `papel<TAB>forma<TAB>onde aparecia`.
4. **Selo e evidência no grafo** `guard-projection-ids-2026-10`. `D_NOMES_DE_PESSOAS_VIRAM_PAPEL`
   foi gravado pelo `kg-decide-seal.sh` com aresta para `D_P9_DEFAULT_DA_FONTE_PRIVADA_SO_NA_FONTE`.
   `E_TROCA_DE_NOMES_POR_PAPEL_CONTADA` traz a contagem por arquivo. O TETO subiu de 11 para 13.
   A frase «Manter público e limpar a árvore» não existe como nó em grafo nenhum: ela só está no
   resíduo de `chore/public-core-tree-cleanup`. Por isso o selo foi para o grafo do tema, a fonte
   privada de nomes.

## Passada adversarial (refutador default: reprovado)

| # | Achado | Estado |
|---|---|---|
| 1 | Sobrou nome em e-mail, URL, caminho de máquina, `local_path`, nome de arquivo ou autor de commit citado em texto? | curado: o e-mail saiu do `reviewer`. Os dois handles e o autor de commit citado em texto (inbox, provenance-triage, KG colaboracao) viraram papel. A busca case-insensitive por cada forma do mapa privado dá 0 no conteúdo e 0 nos nomes de arquivo |
| 2 | Trocar o nome em prosa e manter o id de membro não esconde nada | declarado como NÃO DECIDIDO: são três pessoas cujo nome é também id de membro, repo remoto, diretório local, pasta de outbox e nome de grafo. Elas foram deixadas intactas para o maestro (ver abaixo) |
| 3 | O `locator` de proveniência que cita o autor de um commit do core agora diz `dev-1`, enquanto o histórico mostra o nome real | teto declarado: o histórico não é reescrito (decisão do maestro). Quem re-medir vê o nome no `git show` e não no grafo, e isso é o efeito desejado, não um drift |
| 4 | `dev-1`/`dev-2` colidiriam com outro uso no repo? | curado por medição: zero ocorrências de `dev-1`, `dev-2` e `instancia-offline` em origin/main antes da troca |

## Não decidido (para o maestro)

- **Três pessoas com nome em id de membro** (o colaborador de campo, o adotante de compliance e o CMO
  do adotante granaai). Medido: são 648 ocorrências das formas de id e de caminho, mais o primeiro nome do colaborador,
  sem contar a prosa das outras duas pessoas. Esconder de
  verdade exige renomear o id de membro, o repo remoto e o clone, e combinar isso com a sessão de cada
  adotante. Os papéis propostos estão no mapa privado como pendentes.
- **Titulares de marca** citados de registro público do INPI numa pesquisa de nome (três nomes).
- Ficam por critério: o maestro, autores publicados citados como referência e personagens fictícios
  de exemplo.
