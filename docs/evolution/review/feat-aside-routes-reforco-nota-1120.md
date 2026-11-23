---
branch: feat/aside-routes-reforco-nota-1120
pr: 1704
date: 2026-11-20
reviewed_diff_sha256: 48f8754623df4768b412ad58b0a13ce573670fb150971f4b681f111f7388bc39
reviewed_code_sha256: 641b8711d86d3c7f57b66b200cedc465261db30d1ad3271a6d046ca8c5f3551f
findings_total: 15
findings_real: 15
findings_blocking: 1
tokens: 92944
duration_min: 11
findings_fixed: 12
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "subagente code-reviewer isolado, sem a conclusão do autor, com mandato de refutar e rodar comandos (proibido criar card real)"
nota: "tokens = os do subagente revisor. elenxo: true (corrigido em 2026-11-22 pela sessão do core; antes false porque não era o Elenxo de workflow): no esquema do resíduo o campo declara se houve passada adversarial, e houve, por revisor com mandato de refutar; elenxo_isolado: true porque o revisor não escreveu o diff e não recebeu a conclusão. 1 bloqueante (item 10, CI, curado), 6 ressalvas, 3 nits; 8 curados e 1 aceito (dívida: como prefixo vira dúvida, coerente com 0 usos da palavra própria)."
---

# Passada adversarial: `feat/aside-routes-reforco-nota-1120`

## O que muda

Decisão do maestro de 2026-11-20 sobre a revisão medida dos apartes (transcripts do core, 19/10 a 20/11):
- `reforço:` é reforço de ORDEM ou diretriz: aplicar já e, se durável, memória de feedback com a frase e a data.
- `nota:` vira card pelo `tm.sh item.create` no dono certo, com o número confirmado; sem `tm.sh` ou sem
  provider, `notes.md` declarado. `fyi:`/`avisa:` seguem aviso de sessão.
- Prefixo composto: até 3 rotas na ordem escrita, numa linha, sem efeito encadeado depois de `dúvida:`.
- `dpuvida:`/`dívida:` viram alias de `dúvida:`; `DÚVIDA:`/`REFORÇO:` roteiam em `LC_ALL=C`; sai `mandou bem,`.

## Achados e destino

1. RESSALVA — rótulos da bancada cortavam texto por caractere, que em C conta bytes: falha falsa em `LC_ALL=C`.
   Curado: ids ASCII. Medido: 28/28 em C e em C.UTF-8.
2. RESSALVA — a frase da nota entre aspas duplas executaria crase e `$( )`. Curado: heredoc de delimitador citado,
   contrato `b:sem-heredoc` com mutante.
3. RESSALVA — caminho sem aspas na rota. Curado: `%q`; a cópia da bancada vive num caminho com espaço e o mutante
   que tira o `%q` morre.
4. RESSALVA — `dúvida: nota: vira card?` mandava criar card. Curado: depois de dúvida, efeito não encadeia (casos
   e7/e8, mutante e7).
5. RESSALVA — `fyi:`/`avisa:` virariam card sem medição. Curado: chave própria de aviso de sessão (d8/d9).
6. RESSALVA — custo da família. Curado em parte: cada mutante roda só a sua seção; ~53 s com carga ~10.
7. NIT — mutantes vivos (teto 3, data da nota, `dpúvida`, `CDPATH`). Curado: e6 e `b:sem-data`; `dpúvida` saiu; o
   comentário do `CDPATH` agora diz o motivo real (diretório homônimo de outra raiz).
8. NIT — motivo casado por prefixo. Curado: casa com `=`.
9. NIT — `dívida: técnica…` roteia como dúvida. Aceito: 0 usos da palavra como prefixo no período.

## Bancada

Famílias isoladas: `aside_router_routes` 28/28 (em C e em C.UTF-8; 23 mutantes de motor e 2 de hook, todos mortos
pelo id certo); `aside_router` e `aside_router_hook` 9/9.

## Achado do CI (depois da revisão isolada)

10. BLOQUEANTE (CI do PR, faixa 3) — a bancada abortava o worker sem trailer de soma. Sob o `set -euo pipefail`
    do runner, um diretório vazio no PATH devolve o `*` literal; o 2º `ln -s` dele caía sobre o link pendente e o
    rc≠0 matava o worker. A revisão isolada e a bancada local não viram porque o harness local rodava sem `set -e`
    e o PATH daqui tem um só diretório vazio. Curado: pula o que não existe, confere `-L` e o `ln` nunca decide o
    rc. Caso permanente: a varredura inclui dois diretórios vazios (numa variável, porque o `:` literal entre
    expansões não divide pelo IFS — a 1ª tentativa do caso não varria os vazios). Mutante (a cura revertida) com
    o harness espelhando o runner (`set -euo pipefail`): rc=1 sem trailer, como no CI. Curado: 28/28 com trailer em
    `LC_ALL=C` e C.UTF-8. Não houve nova passada isolada sobre esta cura; a prova é o mutante que reproduz o CI.

## Revisão isolada (2026-11-23)

Subagente general-purpose (opus), isolado, mandato REFUTAR. Veredito: **APPROVED** com 4 ressalvas; CI verde em todas as
faixas. A bancada local não rodou nele (teto de 500 s esperando a vaga de carga).

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 11 | Depois de `dúvida:`, `paralelo:` e `corrige:` ainda acionam a própria rota (o `break` cobre só NOTE, ±etapa e guardas) | sim | não | Declarado: o caso e6 trava o encadeamento de PARALLEL de propósito; rever com uso medido |
| 12 | O título do card ia entre aspas simples montado da frase do maestro: um apóstrofo quebra o comando e `'$(…)'` escapa | sim | não | Curado: a rota diz que o `<resumo>` é escrito pela sessão, sem aspas simples, crase nem `$`, nunca a frase do maestro |
| 13 | O modelo de heredoc numa linha só não roda se copiado | sim | não | Curado: «modelo, não literal: o heredoc abre e fecha em linhas próprias» |
| 14 | `findings_blocking: 0` com o item 10 bloqueante no corpo | sim | não | Curado: `findings_blocking: 1` |
| 15 | `dívida:` roteia como dúvida | aceito | não | Já aceito no item 9 |

## Re-revisão pós-rebase (2026-11-23)

O #1701 (rota `tarefa:`) entrou antes e tocou os mesmos pontos. Conflitos resolvidos por união, sem mudar o
comportamento de nenhum dos dois: em `lint-selftest.sh` as duas famílias novas ficam lado a lado
(`aside_router_task` e `aside_router_routes`, cada uma com o seu `_family`); em `warm-up.md` a lista de marcadores
traz `tarefa:` e a nota de `reforço:`/`nota:`; no KB a linha de aliases soma `faça:`→`tarefa:` à redação nova de
`fyi:`/`avisa:`, e as duas seções (rota `tarefa:` e revisão por medição) ficam. As três famílias passam juntas
(`--families aside_router,aside_router_task,aside_router_routes`: OK, todas reagiram).
