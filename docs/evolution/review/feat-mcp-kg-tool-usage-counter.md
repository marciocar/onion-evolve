---
branch: feat/mcp-kg-tool-usage-counter
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: "agente de execução, releitura do próprio diff contra os seis requisitos e a bancada da família mcp_onion_kg (sem refutador separado)"
nota: "tokens 0 e duration_min 0 = não medidos: a passada foi feita pelo mesmo agente que escreveu o código, dentro da execução, sem agente separado e sem cronômetro. Nada foi empurrado nem subido em produção."
---

# Passada adversarial: `feat/mcp-kg-tool-usage-counter`

## O que muda

O servidor `ops/mcp-onion-kg/server.py` ganha um contador de uso opcional, ligado pela variável
`ONION_KG_USAGE_DIR`. Ele guarda só totais: data em UTC, nome da ferramenta (uma das 7 registradas ou `unknown`) e
resultado em duas classes (ok, erro), num TSV `tool-usage.tsv` com modo 600 em diretório 700, fora da raiz servida.
A soma acontece num ponto só, o despacho de `tools/call`, num `finally` que roda depois de a resposta ter sido
escrita. A reescrita é atômica (temporário e rename) sob `flock`, com teto de 400 dias distintos. Toda falha do
contador é engolida e contada em memória; o número sai na linha de boot e numa linha de saída no SIGTERM. A leitura
é pela flag `--usage [--days N]` do próprio script, que não sobe servidor nem pede token. Os totais não viram
ferramenta MCP nem rota HTTP. O README do diretório documenta a variável, o formato, o que não é gravado e a leitura.

Nenhuma ferramenta, a autorização e o corpo das respostas mudam: o caso `usage-resposta-inalterada` compara o
envelope de `kg_list` com o contador ligado e desligado.

## Achados

1. **Real, curado: o contador podia sujar a raiz servida.** Com `ONION_KG_USAGE_DIR` apontando para dentro da raiz,
   o arquivo de estado apareceria no `git status` dela e o envelope passaria a declarar `arvore_limpa: false`, o que
   é mudança de resposta. Cura: diretório dentro da raiz desliga o contador, e nada é criado lá. Caso
   `usage-dentro-da-raiz-desliga`, com mutante.
2. **Real, curado: o harness herdava a variável do ambiente de quem roda.** O `start()` do `selftest.py` só tirava
   `ONION_KG_ROOT` e `ONION_KG_TOKEN` do ambiente herdado; com `ONION_KG_USAGE_DIR` exportada na máquina, os casos
   antigos escreveriam no diretório real. Cura: a variável entra na lista do que o harness remove.
3. **Não é achado, é decisão declarada: variável ausente desliga.** O pedido fala em «padrão sensato fora da raiz
   servida» e também em «variável não definida = desligado». As duas não cabem juntas; ficou a segunda, que é a
   explícita e a conservadora (nenhuma instância passa a gravar por ter recebido o código). O padrão sensato virou
   recomendação no README (`/var/lib/onion-kg/<instância>` pelo `StateDirectory=`).

## Mutantes

Treze mutantes novos na família `mcp_onion_kg`, cada âncora casando uma linha do servidor, aplicados pelo harness
numa cópia. Todos morreram no caso nomeado (medido: 36 passaram, 0 falharam, 0 pularam; 54 casos no harness).

| Garantia | Mutante | Caso que mata |
|---|---|---|
| nome desconhecido não é gravado | a chave vira o nome recebido | `usage-desconhecida-vira-unknown` |
| argumento não é gravado | a chave carrega os argumentos | `usage-arquivo-sem-argumento` |
| nome de grafo não é gravado | a chave carrega os argumentos | `usage-arquivo-sem-nome-de-grafo` |
| e-mail não é gravado | a chave carrega o `X-User-Email` | `usage-arquivo-sem-email` |
| token não é gravado | a chave carrega o `X-Api-Key` | `usage-arquivo-sem-token` |
| IP não é gravado | a chave carrega o endereço do cliente | `usage-arquivo-sem-ip` |
| arquivo com modo 600 | temporário criado com 644 | `usage-arquivo-modo-600` |
| teto de 400 dias | poda removida | `usage-poda-400-dias` |
| escrita concorrente não perde | trava removida | `usage-concorrencia-nao-perde` |
| falha conta em erro | toda chamada soma em ok | `usage-erro-conta-em-erro` |
| sucesso conta em ok | o sucesso soma em erro | `usage-ok-conta-em-ok` |
| falha do contador é contada | o incremento de falhas some | `usage-falha-em-runtime-contada` |
| fora da raiz servida | a recusa de diretório interno some | `usage-dentro-da-raiz-desliga` |

Os seis mutantes de privacidade partilham a mesma âncora (a linha que normaliza a chave), com substituições
diferentes. O harness lê o arquivo depois de cada chamada, porque a linha fora do formato some na reescrita seguinte.

## Limites declarados

- A passada é do próprio agente que escreveu; não houve refutador separado.
- Sem mutante: a ordem «responde e depois conta» e o `try/except` do `record`. O handler já respondeu quando a soma
  roda, então quebrar qualquer um dos dois não muda a resposta; o que se observa é o contador de falhas, que tem
  mutante.
- A recusa por e-mail fora da lista não é contada: ela acontece antes do despacho. Quem quiser medir tentativa
  recusada precisa de outra decisão.
- Chamada cuja soma falhou (trava presa por mais de 5 s, disco cheio) não entra no total; só o número de falhas
  aparece, em memória, e ele zera quando o processo reinicia.
- O teto é de 400 dias distintos com chamada, não de 400 dias corridos.
- A linha de saída só sai no SIGTERM (e o processo morre pelo mesmo sinal, com o status preservado, medido no caso
  `usage-linha-de-saida`). SIGKILL e queda não imprimem nada.
- O dia em UTC não tem caso próprio: o harness só confere que a data gravada é a de hoje ou a de ontem em UTC.
- O diretório que já existe com permissão para grupo ou outros desliga o contador; o servidor não muda o modo de
  diretório que não criou. ACL não é lida.
- Nada foi medido em produção: o serviço real roda de outro checkout e a subida é ato do maestro.
