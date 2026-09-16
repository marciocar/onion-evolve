# Sinal ao core — `onion-research` volta VAZIO quando a fonte primária é uma aplicação com sessão

**Data:** 2026-09-10 · **Repo:** jogo-da-vida (adotante) · **Comando:** `/onion-research` → `.claude/workflows/onion-research.js`

## O que aconteceu

Duas rodadas sobre o mesmo tema (nome comercial de um app brasileiro), no mesmo dia:

| Rodada | Desenho | Resultado | Custo |
|---|---|---|---|
| `brand-naming-br-2026-09` | busca aberta | 13 claims, **todas** de blog de escritório que vende registro de marca (tier 3–5); os 4 eixos que importavam vieram vazios | 4,52 M tokens · 95 agentes · 33 nós |
| `brand-name-candidates-2026-09` | **fontes primárias nomeadas** (INPI pePI, WIPO Brand DB, EUIPO eSearch, USPTO, registro.br) | **ZERO claims. 19 fontes, 19 vazias.** Nenhum grafo escrito (`kgPath: null`, `radarExit: null`) | 1,46 M tokens · 31 agentes · **0 nós** |

A segunda rodada foi a correção recomendada pelo Elenxo da primeira ("refaça com fontes primárias").
Ela falhou **mais completamente** que a rodada que ela vinha corrigir.

## O diagnóstico

As fontes primárias deste domínio **não são documentos**: são aplicações com sessão, JavaScript e, em
alguns casos, captcha. `WebFetch` bate na porta e volta de mãos vazias. O coletor não distingue
"a fonte disse que não há nada" de "não consegui entrar na fonte" — e as duas viram o mesmo silêncio.

O padrão é geral, não é sobre marcas: vale para qualquer base pública consultável só por formulário
(processos judiciais, licitações, cadastros regulatórios, bases de patentes).

## O que dói

1. **A rodada com o desenho CERTO devolve menos que a rodada com o desenho errado.** Isso inverte o
   incentivo: quem aprende a lição do Elenxo é punido com um grafo vazio, e a maquinaria não distingue
   as duas situações — as duas terminam sem resposta.
2. **`kgPath: null` sem erro.** Zero claims não escreve grafo e o run devolve sucesso. O gate "sem radar
   0 o run devolve erro" não dispara, porque não houve grafo para o radar julgar. O caso "não colhi
   nada" passa em silêncio, que é exatamente o que a doutrina de fail-loud existe para impedir.
3. **1,46 M tokens por zero nó.** Não há custo declarado por resultado vazio: o `valeu-a-pena` divide por
   nós, e a divisão por zero simplesmente não aparece.

## O que este adotante fez no lugar

Verificação direta pelo shell, que **funciona e é barata**: a disponibilidade de domínio `.com.br` sai do
endpoint público `https://registro.br/v2/ajax/avail/raw/<fqdn>` (JSON, `status 0` = livre, `2` = ocupado)
e a de `.com` sai do `whois`. Vinte e seis nomes conferidos em segundos, com a resposta crua no log.
O que continua sem instrumento é a **anterioridade de marca** — INPI, WIPO, EUIPO, USPTO.

## Sugestões (o adotante propõe; quem decide é o core)

1. **Distinguir "fonte vazia" de "fonte inalcançável"** no retorno do Fetch. Hoje as duas somem juntas.
   Uma fonte que devolveu HTTP 200 com uma tela de login não é uma fonte sem conteúdo.
2. **Falhar alto quando não há claim nenhuma.** Um run com zero achados devia sair ≠0 e dizer por quê,
   em vez de devolver `kgPath: null` com sucesso.
3. **Roster com uma marca `fetch_kind`**: `document` (dá para ler) vs `application` (precisa de sessão ou
   navegador). O Scope pode então avisar, ANTES de gastar, que o eixo pedido não é alcançável por fetch —
   e sugerir o caminho de navegador ou humano.
4. **Ponte para automação de navegador** onde ela existir, ou uma fase declarada de "verificação humana"
   que devolve a pergunta ao maestro com a lista exata do que conferir, em vez de silêncio.
