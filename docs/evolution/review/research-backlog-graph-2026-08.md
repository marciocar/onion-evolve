---
title: "Revisão — F0 da Onda 1 (o achado do realign vira grafo)"
date: 2026-08-28
branch: research/backlog-graph-2026-08
reviewer: "self-review — grafo puro, verificado pelos gates determinísticos do radar (integridade/schema/frescor) + realign + isolamento da baseline medido"
reviewed_diff_sha256: 60779f2ae79fe13e150d4732faedc7dff274cb4e330c77bca6e6ad4362990f66
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 12000
duration_min: 16
---

# Resíduo — REGRA 56

**Um arquivo, 13 nós, 12 arestas. Zero lógica, zero guarda, zero superfície nova.** O risco desta
classe não é quebrar o build — é **escrever no grafo coisa que não foi medida**, e nomear como
fato o que é opinião.

## Achados (3 reais, todos de método, todos endereçados)

1. **O programa aprovado não tinha casa na SSOT.** Medido: grep pelos ids nomeados no plano em
    e  → **zero ocorrências**; o plano (33 KB) está
   **fora do repositório** (git: *"outside repository"*). O  dizia ALINHADO **com
   razão** e era cego a isso — ele audita o que está escrito, e ninguém tinha escrito. É o achado
   que originou este PR, e virou o nó .

2. **Risco de contaminar a própria baseline.** Um grafo de pesquisa sobre o backlog é, por
   construção, +13 itens na fila que ele mede — efeito observador. Endereçado com
   `# kg-backlog-archive: on` e **verificado, não assumido**: `docs/backlog.md` segue com **190**
   e zero ocorrências do slug.

3. **Tentação de calar o indicador.** A camada 3 do realign acusa commitment-drift em
   `Q_PARADO_DE_PROPOSITO_OU_ABANDONADO`. Trocar uma aresta `CAUSES` por `SUPPORTS` silenciaria
   o sinal em um minuto. **Não foi feito, de propósito**: o apoio dessa pergunta é a medição da
   lente L1, que ainda não existe, e mexer no grafo para melhorar um indicador é o risco **R5**
   (forjar a métrica) que o próprio plano nomeia. O sinal fica aceso.

## Disciplinas aplicadas na escrita dos nós

- **`verified_against` nomeia o COMANDO que mediu**, nunca o documento que afirma. Ex.: a idade
  vem de `git log -S "  - id: <ID>" -- <grafo> | tail -1`, com cobertura declarada 186/186.
- **Dissenso preservado como nó**, não dissolvido: o desenhista gateou o handoff dizendo *"ninguém
  está bloqueado"*; a medição contradiz. As duas leituras estão no grafo.
- **Prior-art mantido `open`** com a ressalva literal *"citar título NÃO é ter lido"* — títulos e
  ids foram verificados, o conteúdo não foi auditado. Marcá-lo `confirmed` seria a fraude barata.
- **Nada foi escrito em `fios-abertos`**: ele está em 20/20 e o compromisso da onda é F6, que exige
  colheita — flip de status, selo do maestro.

## Verificação mecânica

| gate | resultado |
|---|---|
| `kg-radar --integrity --schema` | **exit 0** (13 nós, 12 arestas) |
| UNANCHORED entre os `claim` | **0** (o gate da F0) |
| `kg-realign-project.sh --check` | **ALINHADO**, exit 0 |
| `lint-artifacts` | **0 HARD** |
| isolamento da baseline | `docs/backlog.md` = 190, slug ausente |

Os dois `STALE-MISSING` são `question` com `verified_against` e **sem** `verified_at` — deliberado:
é a convenção que faz pergunta gated **envelhecer sozinha** no `--freshness-tsv` em vez de apodrecer
como item aberto.

## Teto declarado

Este PR **não responde** nenhuma das perguntas que registra — ele as torna **consultáveis**. O valor
só se realiza nas fases seguintes; um grafo bem-formado que ninguém conduz é a mesma doença numa
embalagem melhor. O gatilho de fechamento está no north-star: a F6, com o **delta da taxa de
mortalidade** medido entre F1 e F6.
