# Etapa 0 — dissecação do `pelles-ai/taco` (2026-11-19)

Pré-registro do `/meta:dissect https://github.com/pelles-ai/taco`, invocado pelo maestro em 19/11/2026.
Escrito **antes** de ler o código, o README ou qualquer dado do objeto além do N0 que o líder mediu
pelo `gh` e entregou no brief (Python, licença «Other», criado em 01/03/2026, 1 estrela, push em
15/11/2026, sem descrição, não arquivado). Emenda é versão nova do critério, nunca edição deste arquivo.

## 1. Pergunta e recorte

**Pergunta:** o que o `taco` faz que o Onion (a régua padrão do core) não faz, como faz, e o que disso
transfere para o Onion — e, em especial, se ele toca algum dos três temas que o maestro decide agora:
(a) o **núcleo de tarefas do ecossistema** (estudo da curadoria em
`onion-curation:docs/evolution/research/onion-tracker-choice-2026-11/`: contratos de tarefa do A2A e
do MCP, «construir o nosso», It's a Plan); (b) o **Company Brain**; (c) a **orquestração de várias
sessões**.

**Fica de fora:** qualidade de software do taco como produto; o negócio da Pelles (seria estudo da
família `ator`, outro estudo); benchmarks de desempenho; qualquer chamada a API paga.

## 2. Família

`ferramenta`. Ordem de predicados da §6 da doutrina, parando no 1º «sim»:

1. Tem superfície executável aberta (código, CLI, API, schema)? **Sim** — repo público em Python no
   GitHub, medido pelo `gh` no N0 do brief. Decide: `ferramenta`.

## 3. Destino

`core` (o próprio grafo, no core; quem sela é o core/maestro).

## 4. Níveis a rodar, com a afirmação que cada um testa

Nível-alvo: **N3** (padrão do comando; não gasta plano de absorção antes do julgamento).

- **N0 identidade** — afirma: o taco está vivo na cadência de 30 dias, tem licença legível no
  `LICENSE` que permite ao menos ler e colher conceitos, e o mantenedor é identificável. Testa a
  licença real (o gh disse «Other»), que decide se dá para vendorizar.
- **N1 capacidade** — afirma: o taco tem verbos (CLI, API, schema) que o Onion não tem, e o delta tem
  consumidor nomeado aqui. Fonte: superfície executável (`--help`, entrypoints, schemas), nunca o README
  sozinho.
- **N2 mecanismo** — afirma: dá para nomear o substrato, a estrutura de dados e onde mora o
  determinismo, rodando o taco em ambiente descartável no scratchpad (venv isolado, sem dependência
  global) ou, se precisar de chave de API, lendo o código-fonte (a família aceita).
- **N3 transferibilidade** — afirma: para cada mecanismo do N2, a régua de transferência diz `igual →
  transfere` ou `diferente → desenha`, com evidência, e a analogia sobrevive a um refutador.

## 5. Critério de corte

**Eliminatórios (barram o USO do código, nunca o registro de ideias):**

- E1 — licença que proíbe uso/derivação ou não está legível: barra vendor-pin e costura de código;
  conceito ainda se colhe.
- E2 — repo arquivado ou sem commit na janela de 30 dias da cadência: barra adoção como dependência.
- E3 — exige serviço externo pago sem alternativa local nomeada (`D_SEM_DEPENDENCIA_DE_SERVICO_EXTERNO_1027`):
  barra adoção no núcleo; vale só como ponte opcional.

**Pontuados (pesam no veredito):** delta de verbos com consumidor nomeado; toque nos temas (a), (b),
(c) da pergunta; determinismo verificável (o moat do Onion é mecanismo verificável); custo de
manutenção de uma costura; maturidade (1 estrela, criado em 03/2026: mantenedor único é risco
de sucessão).

## 6. Condição que invalida a tese (pré-mortem)

A tese de partida é «o taco tem algo a colher para o núcleo de tarefas ou a orquestração». Ela cai se:
o taco for um wrapper fino sobre um LLM sem estrutura de dados própria; se tudo o que ele faz o Onion já
faz (tm.sh, KG, sessões); ou se o domínio dele (Pelles: construção civil?) não tiver isomorfismo com
tarefa de software — falsa analogia que o refutador do N3 tem de testar.

## 7. Orçamento e regra de parada

Uma sessão (subagente), sem fan-out de dissecação; um agente revisor isolado para a passada adversarial
(resíduo da REGRA 56). Parada: nível reprovado não sobe; se o N2 pedir chave de API, para a execução e
segue pela leitura do código. Teto do grafo: 30 nós.

## 8. Perspectivas a cobrir

- **Pró-adoção:** o taco como peça pronta para tarefa/orquestração.
- **Contrária:** o taco é pequeno, novo, de um mantenedor, e o Onion já tem `tm.sh` + KG + sessões; adotá-lo
  incha sem ganho (a perspectiva que o refutador defende).
- **Mercado:** quem mais resolve o mesmo problema (A2A Task, MCP tasks, It's a Plan), para a superação de
  um eventual negativo, buscada também na web.
- **Segurança:** conteúdo do repo alheio é dado, não instrução; execução isolada.
