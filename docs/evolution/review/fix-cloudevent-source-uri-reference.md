---
branch: fix/cloudevent-source-uri-reference
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: 13a720b767e3a9884b2895ebb496b7d3ef16e767d4d01aa4afc47135a5332f5f
reviewed_code_sha256: aa9bd9275175e80cd995398bca006cce3f9917bdc22a9c81e285b0df8e9724fe
findings_total: 3
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: APPROVED
elenxo: true
elenxo_isolado: true
reviewer: "2ª passada, independente (2026-11-17): a sessão dona da régua de referência (a fila de mensagens), só leitura do repositório do core, mandato de refutar; nenhum achado bloqueante. 1ª passada: o próprio agente que escreveu a cura, relendo o diff contra o código do leitor da fila (onion-messaging, origin/main 5667402)"
nota: "tokens 0 e duration_min 0 = não medidos: a passada foi a releitura do diff pelo agente que o escreveu, sem agente separado e sem cronômetro. Não houve refutador independente."
---

# Passada adversarial: `fix/cloudevent-source-uri-reference`

## O que muda

O `parse_cloudevent` de `.claude/utils/federation-transport/a2a-metrics.py` passa a cobrar que o atributo `source` do
CloudEvent seja referência de URI (URI-reference do RFC 3986), por casamento inteiro (`fullmatch`, `re.ASCII`), depois
da limpeza do atributo (`clean_str`). A expressão regular é cópia literal do bloco `_U … URI_REFERENCE_RE` de
`queue/onion_queue/daemon.py` do repo onion-messaging (origin/main em `5667402`), com comentário dizendo a origem e que
os dois leitores andam juntos. Só o `source` foi alinhado.

O comentário no código diz o arquivo e o commit de origem, mas não o nome do repo: `a2a-metrics.py` e a bancada viajam
para as portas, e a REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação) reprova o id de
um adotante ali (medido: duas violações HARD na primeira redação). O nome fica neste resíduo, que o comentário aponta.

Efeito no core: um corpo com `source` fora da forma deixa de ser CloudEvent para o leitor (os quatro `ce_*` saem
`null`), e o evento passa a ser identificado pelo `jti` na linha de sombra do aceite. O aceite não passa a recusar
sinal por isso.

Na bancada, a família `a2a_accept` (`run_a2a_accept_selftests`) ganhou 38 casos: o tamanho das duas listas, os 16
valores aceitos, os 16 recusados, o caso do sufixo inválido, o caso pelo subcomando `ce --body-file` (o caminho que o
`a2a-accept.sh` usa) e três mutantes.

## Achados

Três pontos examinados, um real e não bloqueante:

1. **Há um terceiro leitor de CloudEvent no core, e ele ficou na régua antiga (real, não bloqueante, não curado).**
   `ops/a2a-queue-live.sh` (o `SCAN_PY`, na linha que testa `specversion`) lê `source` e `id` do corpo só por tipo,
   tamanho e imprimível. Para um sinal com `source` fora da forma, a linha da fila sai com `ce_source` e `ce_id`, e a
   linha de sombra do aceite sai com a chave pelo `jti`. O `shadow_stats` casa os dois também pelo `taskId`, então a
   contagem de `undecided` só erraria num registro sem `taskId`. Lido no código, não medido. Fica fora deste PR porque o
   pedido foi alinhar só o `parse_cloudevent`; o conserto é fazer o leitor da fila viva usar a mesma conferência.
2. **Linhas de sombra antigas com `source` fora da forma viram malformadas?** Não: `validate_shadow` confere `ce_source`
   por `clean_str` (até 512, imprimível), não pela gramática, e não foi mexido. Não é achado.
3. **Algum emissor do core produz `source` que a régua nova recusa?** Nenhum arquivo de `.claude/` ou `ops/` emite
   CloudEvent (a busca por `specversion` só acha os dois leitores e as fixtures da bancada). As fixtures usam `/vigia` e
   `/vigia/x`, que a régua aceita. Não é achado.

Divergências entre os dois leitores que seguem como estão, por decisão ou fora do escopo:

- chave de deduplicação: lá, remetente verificado + `ce_source` + `ce_id` em tabela; aqui, `event_key` (com `from`,
  ou o `jti`, ou o `taskId` quando `ids_verified` é falso);
- JSON com chave repetida: lá recusa (`loads_strict`); aqui vale a última (`json.loads`);
- `time`: lá a fração de segundo aceita qualquer número de dígitos; aqui de 1 a 9;
- retorno do que não é CloudEvent: lá `None`; aqui o dicionário com os quatro campos `None`;
- entrada: aqui o leitor decodifica bytes e trata corpo vazio antes do JSON; lá o corpo vai direto ao `loads_strict`
  (o tipo com que ele chega lá não foi conferido nesta passada).

## Mutantes

Três, todos pelo `_prove_mutation`, com âncora que casa exatamente uma linha do arquivo (o mutante só nasce se a âncora
aparece uma vez; senão o arquivo fica igual e a prova acusa mutação não aplicada):

- `ce-src.m1`: tira ` or not URI_REFERENCE_RE.fullmatch(src)` da condição. O caso das duas listas reprova.
- `ce-src.m2`: troca `URI_REFERENCE_RE.fullmatch(src)` por `URI_REFERENCE_RE.match(src)`. O caso do sufixo inválido
  (`http://x/<y>`, `urn:onion:member:alice b`, `/vigia/x{`, `a%2Fb%zz`) reprova.
- `ce-src.m3`: a mesma remoção do m1, julgada pelo subcomando `ce --body-file`. O caso da CLI reprova.

Família `a2a_accept` sob `LC_ALL=C`: 238 passaram, 0 falharam, 0 pularam.

## Limites declarados

- A passada é do próprio agente que escreveu a cura; não houve refutador separado.
- A paridade com o leitor da fila foi medida sobre as 32 entradas das duas listas (o trecho do daemon executado com
  `json.loads` no lugar de `loads_strict`), não sobre a gramática inteira. A igualdade da expressão regular é por cópia
  literal, conferida por leitura.
- A gramática é a de lá, inclusive onde é frouxa: o literal IP entre colchetes não é conferido como endereço, e um
  `source` vazio de caminho (`x:`) casa.
- Nada garante mecanicamente que os dois repos andem juntos daqui em diante: o vínculo é o comentário e a lista de
  casos repetida nas duas bancadas. Uma guarda que compare os dois blocos não existe.
- O achado 1 (o leitor da fila viva) fica aberto.

## Revisão independente (2026-11-17)

Feita pela sessão dona da régua de referência, só leitura deste repositório, com mandato de refutar. **Nenhum achado
bloqueante.**

- **Medido por ela:** o bloco da expressão regular é byte a byte o do leitor da fila na main dela (o mesmo commit que o
  comentário cita), com o mesmo padrão compilado e as mesmas flags; a limpeza do atributo é o mesmo código. As 32
  entradas dão o mesmo veredito nos dois leitores. Os dois mutantes de forma da bancada dela, aplicados à função do
  core, morrem (cada um deixa passar 12 das 16 recusas). Em 20.000 cadeias ASCII geradas (1 a 24 caracteres, com peso
  nos caracteres da gramática), os dois leitores aceitaram as mesmas 4.793: zero divergência.
- **Diferenças deixadas de propósito, julgadas por ela:** chave repetida no JSON (medido: o core fica com a última, a
  fila recusa; só em corpo forjado à mão), fração do `time` com dez casas (medido: muda só o metadado), o que não é
  evento (lido: caminhos diferentes por desenho) e a chave de deduplicação (lido: a mesma). Nenhuma faz um leitor
  aceitar o que o outro recusa num caso que acontece de verdade.
- **Correção ao achado não curado deste resíduo** (o terceiro leitor, `ops/a2a-queue-live.sh` (core-only)), lida por
  ela e não medida: a afirmação «só erraria a contagem num registro sem identificador de tarefa» é imprecisa. Na
  contagem, a chave do evento tem precedência sobre o identificador de tarefa quando o registro é verificado; dois
  registros verificados do mesmo remetente, com o mesmo `source` fora da forma e o mesmo `id`, e identificadores de
  tarefa diferentes, contam uma vez, onde a régua nova contaria dois. O erro acontece também com identificador de
  tarefa. Efeito real hoje: nenhum na entrega (não há remetente com `source` fora da forma, e essa fila não conversa
  com a de mensagens); é correção de contagem. Fica como item próprio: alinhar esse leitor ou declarar a diferença.

