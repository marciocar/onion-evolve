---
reviewed_diff_sha256: pendente
findings_total: 19
findings_real: 18
tokens: 195983
duration_min: 7
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Uma passada de refutador em worktree isolada, com o veredito começando em reprovado e o mandato de
  achar capacidade declarada sem fonte, falso positivo e falso negativo na guarda. Ele REPROVOU. O
  mecanismo estava verde, e o defeito estava no conteúdo: 12 células implemented citavam uma fonte que
  não sustentava o positivo, e isso repetia o defeito que o PR dizia curar. A guarda tinha furos de forma
  baratos de fechar. Tudo foi curado no mesmo laço: as 12 células viraram unverified, houve 9 casos novos
  no --selftest (27 ao todo), 29 mutantes na bancada e 33 pelo mutate-and-restore.sh, todos mordendo.
---

# Resíduo — `feat/task-manager-capabilities`

Onda 2 da SDAAL do Task Manager (SAC-63). A `interface.md` ganha o vocabulário canônico, as
assinaturas e um bloco de 24 capacidades lido por máquina. Cada adapter declara as 24 num
`adapters/<p>.capabilities.tsv`, e a REGRA 103 (Adapter do task-manager declara todas as capacidades da
interface, com fonte) cobra a declaração. A guarda foi forjada pelo `/meta:forge-guard`.

## Passada adversarial: REPROVA (19 achados, 18 reais)

**(A) Capacidade declarada com fonte que não sustenta.** Doze células foram rebaixadas a `unverified`,
cada uma com a razão escrita na nota.

| Provedor | Capacidade | O que a fonte provava de fato |
|---|---|---|
| Linear | `hierarchy.subtask_create`, `status.transition`, `priority.set` | o nó ancorava o campo de LEITURA do `type Issue`; o adapter escreve por `IssueCreateInput`/`IssueUpdateInput` |
| Linear | `search.query` | só o default de 50; o filtro não estava ancorado |
| Asana | `search.query` | só a exigência de conta premium |
| Jira | `status.transition` | só o POST do Cloud; o `GET /transitions` e o DC não |
| ClickUp | `status.transition`, `item.update` | o trecho citado registrava a medição da FALHA |
| Zoho | `item.read`, `project.read` | a declaração geral do arquivo, não uma sonda |
| Zoho | `search.query`, `hierarchy.subtask_list` | a medição NEGATIVA do filtro do servidor |

Além disso, a ref ao nó `E_ZOHO_SEM_ENDPOINT_TRANSICAO` saiu da transição do Zoho, porque ela afirma
escrita por `custom_status`, que o adapter mediu recusar. A nota do `issueArchive` do Linear perdeu a
afirmação sem fonte.

**(B) Falsos positivos da guarda, todos curados:**

- uma prosa honesta ("este adapter NÃO implementa `searchPage(`") reprovava o `not_implemented`. A
  superfície agora é DEFINIÇÃO (linha de código ou cabeçalho), não citação;
- id de nó entre aspas ou com comentário não resolvia;
- grafo homônimo sombreava o verdadeiro. Agora o grafo é casado pelo `meta.id`;
- CRLF e BOM geravam 75 HARD enganosas. A entrada agora é normalizada;
- a união de provedores em várias linhas virava `provedores-ausentes`.

**(C) Falsos negativos da guarda, todos curados:**

- `adapter:` com trecho vazio ou igual à superfície passava;
- `adapter:` de outro provedor passava;
- nó do `kg:` com curinga de regex (`E_.*`) passava. Agora a forma é validada e a comparação é por
  igualdade;
- objeção do Elenxo como fonte única de `implemented` passava;
- o vocabulário da interface não era conferido (duplicata, superfície vazia).

**(D) Texto.** A tabela de vocabulário afirmava ADF no comentário do Jira Cloud, contra a objeção da Onda 1.
O exemplo chamava uma capacidade opcional pela presença do método. Os nós do grafo traziam contagens
erradas (11/13 em vez de 12/12, e "Zoho 12 required por sonda"). Tudo corrigido e a matriz recontada:
22 implemented, 50 unverified e 48 not_implemented.

**O achado que não exigiu cura (1, com 3 verificações):** status com espaço, linha de 7 colunas e capacidade com caixa
diferente já eram barrados.

## Teto declarado (sem cura mecânica)

- A guarda confere que a fonte EXISTE, não que ela SUSTENTA o que se afirma. Os 12 rebaixamentos acima
  foram juízo do refutador, e esse juízo continua sendo da revisão.
- Um grafo fabricado em `docs/` com o `meta.id` certo resolve como fonte.
- A superfície de campo é conferida só pela presença da palavra no adapter: não distingue leitura de escrita.
- No repo derivado, a ref `kg:` cujo grafo não viajou não é conferida. Na porta `onion-mini` a guarda não
  roda, porque o lint não viaja para lá.

## Achado para o maestro (não curado aqui, por ser o CLAUDE.md)

O CLAUDE.md (l.233 e l.284) prescreve "Bulk-first" pelo `/issue/bulk`, e os 5 adapters declaram
`bulk.create` como `not_implemented`. A REGRA 103 torna isso visível, mas não muda o CLAUDE.md.
