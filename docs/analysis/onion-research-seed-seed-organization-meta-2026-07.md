# Semente de pesquisa — como organizar múltiplas sementes abertas × o gap que esta própria rodada revelou

> **Status: ENTREGUE (2026-07-06)** — resolvida no mesmo dia do plantio, dentro da própria rodada
> que a gerou (as outras 9 sementes desta rodada — ver a tabela em
> [`README.md`](README.md) (seção "Sementes de pesquisa abertas") — são o caso de uso real que motivou e
> testou a resposta).

## Por que esta pesquisa

O maestro perguntou, entre as sementes especulativas: "como organizar esta loucura toda?" — dado
que havia 9 outras ideias soltas, nenhuma decidida, sem forçar convergência prematura entre elas.

**A investigação achou o gap com precisão, e ele tinha resposta simples.** O template de
"semente de pesquisa" já existia e já funcionava — confirmado em 2 instâncias reais,
[`onion-research-seed-hegel-dialectics-2026-07.md`](onion-research-seed-hegel-dialectics-2026-07.md)
e
[`onion-research-seed-srl-plea-2026-07.md`](onion-research-seed-srl-plea-2026-07.md) —
com uma estrutura consistente (Título → blockquote de status → Por que → Questões → Método
previsto → Gatilho com ponteiro de memória). O que **não existia** era qualquer índice que
listasse "quais sementes estão vivas agora" — o rastreamento morava inteiramente na memória
pessoal de sessão do Claude, invisível a qualquer sessão futura ou a outra pessoa que abrisse o
repositório.

## O que foi decidido (não é pergunta aberta — é o registro da decisão)

1. **O template não muda.** As 2 instâncias existentes já provaram o formato; as 9 sementes desta
   rodada seguem o mesmo padrão, em `docs/analysis/onion-research-seed-<slug>-2026-07.md`.
2. **Uma tabela nova em `docs/analysis/README.md`** — "Sementes de pesquisa abertas" — fecha o
   gap de índice, encaixando no critério de retenção que o próprio arquivo já define (é
   referência viva, não efêmera).
3. **Uma memória consolidada, não uma por semente** — `sementes-modelo-federacao-lente-radar-
   2026-07` — aponta pra tabela real; mantém a memória como ponteiro/cache (doutrina
   `session-memory-lifecycle`), não como fonte de verdade do rastreamento.
4. **Sementes que colidem com decisão anterior citam a decisão e perguntam "o que é diferente
   agora"** — não fingem território virgem (aplicado às sementes 2 e 5 desta rodada).

## Por que isto conta como "entregue" e não como semente aberta

Diferente das outras 9, esta pergunta não dependia de pesquisa externa nem de uma decisão do
maestro sobre território de produto — dependia só de **olhar pra o que já existia e notar o
buraco**. A `## Gatilho` de uma semente normal seria "o maestro pede a pesquisa"; aqui o gatilho já
disparou dentro da própria exploração que a motivou.

## Relações

- Índice real: [`README.md`](README.md), seção "Sementes de pesquisa abertas"
- Doutrina de retenção que a tabela nova respeita: [`README.md` §"Princípio"](README.md)
- Doutrina de memória-como-ponteiro:
  [`session-memory-lifecycle`](../knowledge-base/concepts/session-memory-lifecycle.md)
