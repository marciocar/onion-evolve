---
branch: docs/vitrines-novembro
pr: 1637
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
findings_blocking: 1
tokens: 0
duration_min: 0
findings_fixed: 9
verdict: FIXED
elenxo: true
reviewer: "refutador independente (subagente da sessão principal), depois da passada mecânica do agente de execução"
nota: "tokens e duração não medidos. Duas passadas: a mecânica do agente de execução (5 achados, 1 bloqueante) e a do refutador independente, que APROVOU com 4 limites, todos curados neste PR."
---

# Passada adversarial: `docs/vitrines-novembro`

## O que muda

As três vitrines ganham as criações de 05 a 12/11/2026 que o levantamento de 12/11 achou fora delas.

- **Migalhas** (`site/historia/migalhas/posts/`): três posts próprios (a batuta, os três Delphis do dia e o backbone com a tabela de valores e a coluna Superação) e um post de notas agrupadas por tema para as demais criações, cada nota com o PR que a prova.
- **Diário** (`.claude/diary/`): oito entradas de 05 a 12/11, só dos tipos learning, decision e innovation, no formato que o `/meta:diary create` grava, e o `index.md` regenerado pelo `diary-index.sh`.
- **Site**: a linha dos marcos da página de estado ganha 05 a 12/11, e nasce a página `/backbone/` com a ordem de construção, a tabela de critérios e valores e os limites declarados. A entrada `backbone` entra na allowlist do `ops/deploy-site.sh`.

Só a fonte. Sem deploy.

## Achados

1. **BLOQUEIA (curado):** a página `/backbone/` nunca iria ao ar. O `ops/deploy-site.sh` só publica o que está em `DEPLOY_ENTRIES`, e a entrada não estava lá. Curado com a linha nova; `--selftest` do deploy dá 25/0.
2. **Limite (curado):** a nota sobre o WhatsApp dizia "em construção, com os selos fora da main", mas o #1636 selou a leitura no meio do trabalho. Curado: a nota cita o PR e sai da lista de itens em voo.
3. **Limite (curado):** o rótulo do post de notas dizia 28 PRs; a contagem real dos PRs mergeados citados é 43. Curado pela contagem feita no arquivo.
4. **Limite (curado):** dois marcos da página de estado escreviam "PRs #1480 a #1496" e "#1528 a #1576", sugerindo intervalo contínuo. Curado com a lista exata.
5. **Limite (curado):** o #1461 é de 04/11 e estava num post que diz "5 a 12 de novembro". Curado com a data escrita na nota.

**Passada do refutador independente (APROVADO, com 4 limites, todos curados):**

6. **L1 (curado):** a nota sobre o resíduo citava "#1497 e #1541" como se os dois separassem bloqueio de limite. O #1541 passou para o inglês o valor de campo do resíduo da REGRA 56 (Resíduo de review rastreado), com catraca no legado. A nota agora diz o que cada PR fez.
7. **L2 (curado):** o cabeçalho do `.claude/diary/index.md` saiu com o nome da pasta da worktree. Regenerado pelo `diary-index.sh`, com o título ajustado para `onion-evolve`, que é o que o gerador produz no checkout com o nome canônico. O defeito do gerador (o título cai no nome da pasta quando falta `instance:` no `.onion-version`) fica fora deste PR.
8. **L3 (curado):** este resíduo dizia `pr: pendente` e não registrava a passada independente.
9. **L4 (curado):** glosa curta para lease, adotante carimbado, sandbox, open-core, self-host e p95 onde aparecem, e a linha Gestão de falhas da coluna Superação passa a dizer "a provar, com critério registrado antes do teste".

Conferência mecânica: dos 56 PRs citados nas superfícies novas, 53 estão MERGED; os 3 restantes (#1628 e #1633, fechados; #1635, aberto) aparecem como fechados ou em voo no texto. A varredura por nomes de membro do registro da federação, nome de pessoa, IP, `/home` e host não achou nada nas linhas acrescentadas. O comparável direto da tabela de valores não é nomeado, porque o veredito da curadoria sobre ele ainda não está selado no core.

## Mutantes

Não se aplica: a mudança é de conteúdo e de uma linha de allowlist. O `--selftest` do `ops/deploy-site.sh` passou 25/0 com a entrada nova. O build do site (`npm run build`) gera 11 páginas, inclusive `/backbone/`, e os 4 posts novos saem no índice das migalhas e no feed (66 itens).

## Limites declarados

- A página `/backbone/` não foi conferida em tela, em largura de telefone; a tabela rola na horizontal dentro do próprio contêiner.
- A coluna Superação é publicada como hipótese, e a coluna Hoje como a leitura do core em 12/11, ambas como estão no estudo do #1632.
- O lint completo levou 820 s nesta máquina compartilhada, com 0 HARD.
