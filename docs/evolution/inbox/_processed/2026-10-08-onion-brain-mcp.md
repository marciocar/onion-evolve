---
title: "Pedido: um servidor MCP remoto do Onion para consultar o Company Brain (grafos com o radar real, docs) fora do Claude Code"
date: 2026-10-08
type: signal
kind: feature-request
from: brain-granaai (hub, pin 1c459812f48b)
severity: medium
---

# Onion Brain MCP: o Company Brain consultável fora do Claude Code

## O que aconteceu no campo

Em 2026-10-07 publicamos, a partir deste repo, um artefato do claude.ai para o time avaliar três controles
antifraude saídos de uma reunião com uma registradora. O artefato tem pareceres por pessoa (capability `db`),
a transcrição da reunião e um chat (capability `sample`) que responde com base no material da página.

O maestro pediu o passo seguinte: o chat consultar também o `docs/business-context/` e o grafo de negócio
(`business.kg.yaml`), **usando a maquinaria do Onion** (radar, integridade, estado, frescor), não uma leitura
improvisada. Não há como fazer isso hoje:

- O artefato roda no navegador, sem shell e sem repositório: `kg-radar.sh` e companhia não executam lá.
- O plugin do Onion vive em sessões do Claude Code (CLI, desktop, IDE); o `sample` do artefato chama o Claude sem
  plugins, só com as funções que a página expõe.
- Um MCP local (`host:`) só responde no app do Claude de quem tem o repo e o servidor na própria máquina: serve ao
  maestro, não ao time.
- O business-context tem ~35 arquivos e ~570 KB (o grafo sozinho, ~140 KB): não cabe num prompt; precisa de
  leitura sob demanda.

O paliativo que vamos usar: publicar com o artefato a **saída do `kg-radar.sh` congelada** na data da publicação e
um navegador simples do grafo em JS, marcado como "consulta, não veredito". O navegador em JS é um **segundo leitor
do corpus**, exatamente o risco da REGRA 82 (Os dois leitores do corpus CONCORDAM sobre quem é nó). Por isso o
pedido.

## O pedido

Um **servidor MCP remoto do Onion**, mantido no core e adotável por hub/adotante, que exponha a maquinaria
existente como ferramentas **somente leitura** sobre um clone sincronizado do repo do adotante. Sugestão de
superfície (os nomes são do core decidir):

| Ferramenta | O que faz | Base no Onion |
|---|---|---|
| `kg_list()` | Grafos do repo, sem fixtures | `git ls-files '*.kg.yaml'` |
| `kg_radar(grafo, flags)` | Saída do radar (atenção, estado, reconciliação, integridade, frescor) | `kg-radar.sh` |
| `kg_node(id)` / `kg_neighbors(id, edge_type?)` | Um nó e as arestas dele | o **mesmo** parser do radar |
| `kg_trace(id)` | Resolve o `trace:` de um nó | `kg-trace-resolve.sh` |
| `docs_search(termo, raiz?)` | Busca nos docs com `status` e `review_after` | `docs/INDEX.md` + frontmatter |
| `docs_read(caminho, faixa?)` | Lê um doc ou um trecho | — |

Assim qualquer cliente MCP (o chat de um artefato, uma conversa no claude.ai, outro agente) recebe **o veredito do
Onion**, ao vivo, sem reimplementar nada.

## Restrições que vemos daqui

1. **Somente leitura.** Nenhuma ferramenta escreve no repo; I3 intacto.
2. **Um leitor só.** `kg_node`/`kg_neighbors` precisam usar o parser do radar, para não abrir a divergência que a
   REGRA 82 (Os dois leitores do corpus CONCORDAM sobre quem é nó) proíbe.
3. **Acesso controlado no servidor.** Quem tem o conector lê o Company Brain inteiro (no nosso caso: métricas,
   preço, sanções, estratégia). Autenticação restrita à organização do adotante; idealmente escopo por raiz
   (`business-context` sim, `compliance` só para certos perfis).
4. **Segredos e tenants.** Nunca servir `.env`, chaves ou dados de tenant; o servidor lê só o que está versionado
   e fora de uma lista de exclusão.
5. **Frescor visível.** Toda resposta carrega o commit e a data do clone, para o cliente dizer "segundo o radar de
   `<sha>`".
6. **Sincronização.** Pull periódico ou webhook do forge; o adotante escolhe a branch (aqui seria a `develop`).
7. **Execução isolada.** Os scripts bash rodam num container sem rede de saída além do forge.

## Perguntas ao core

- Isso cabe no framework (o core mantém, os adotantes hospedam) ou é serviço da família (o core hospeda)?
- O plugin do Onion já tem ou planeja uma superfície MCP que dê para estender?
- Há precedente de expor a maquinaria fora do Claude Code que devamos seguir?

## O que o hub oferece

Ser o piloto: temos o caso real (artefato com chat e pareceres do time), um grafo de negócio de ~220 nós com radar
verde, e a necessidade de o time não técnico consultar o Brain sem abrir o terminal. Podemos medir o uso pelas
conversas gravadas no artefato (o que o time pergunta e onde o material não responde).
