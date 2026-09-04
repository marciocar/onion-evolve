---
title: "Radar E3 rodada 4 (2.1.260 → 2.1.261): nada muda a adequação da estratégia; o delta é de sessão e auto-approve"
date: 2026-09-04
kg: docs/evolution/research/radar-E3-2026-09-04-r4/radar-E3-2026-09-04-r4.kg.yaml
run_id: wf_3b06e7ee-dcf
tokens: 5907435
agents: 103
duration_min: 41
genre: landscape
mode: research
budget: { maxFetch: 15, maxVerify: 25 }
review_after: 2026-10-19
---

# Radar E3 · rodada 4 — o delta 2.1.260 → 2.1.261

> **Projeção** do grafo (10 nós, radar exit 0). Eixo `E3-claude-code-delta`, disparado pelo SOFT da REGRA 65 (Radar de mundo com baseline DATADA por eixo) após o update do binário. 4ª rodada consecutiva do mesmo eixo.

## Custo declarado

| Item | Valor |
|---|---|
| Tokens | 5.907.435 |
| Workers | 103 · 15 fontes · 43 claims · 25 verificadas (**7 confirmadas, 18 refutadas**) |
| Parede | ~41 min |

## Veredito

**Nada entre 2.1.260 e 2.1.261 altera a adequação da estratégia do Onion.** A capacidade que compra o acoplamento — o `exit 2` determinístico de hook, inclusive sob `bypassPermissions` — segue sem mudança de evento, matcher, payload ou semântica de exit code. Zero mudança em schema de plugin/marketplace, escada de modelos, orquestração e `permissions.allow/ask/deny`.

O delta real é de **sessão e auto-approve**:

1. **Correção a favor do Onion:** a saída de hooks deixou de se perder ao retomar sessão (`resume`). Isso toca o único canal por onde a maquinaria determinística fala — o stderr do `exit 2`. Achado novo em relação a todo o corpus: nenhum grafo anterior nomeava "o veredito pode evaporar na retomada".
2. **`claude -p --resume` com session ID malformado** passa a reiniciar com ID novo em vez de adotá-lo. **Tem consumidor no core:** `.claude/hooks/worklog-capture-session.sh:36` monta literalmente `claude --resume ${sid}`, e o fallback sem `jq` (linhas 20-22, repetido em `session-beacon-hook.sh:16-18`) é justamente o caminho que pode produzir sid malformado. Até 2.1.260 isso entrava em silêncio; agora a sessão renasce limpa e a migalha de retomada pode apontar para a sessão errada **sem erro visível**.
3. **`/skill-doctor` (novo):** mostra skills carregadas sem uso e o custo de contexto de cada uma. Encosta no fio **em aberto** de poda (`poda-instruction-bloat-2026-09`, camada L2, gated em ≥20 sessões ou 14 dias) — é a primeira absorção nativa que colide com um fio ainda não entregue, não com um já pronto.
4. **Auto-approve estreitado:** link que empacota conteúdo na URL de renderizador público de diagramas passa a contar como upload para aquele site. **Sem consumidor no core** (varredura por `mermaid.ink|kroki|plantuml|quickchart` fora de worktrees: zero).

Dois achados são **base-rate de doutrina, não delta** — e valem por si: regras de caminho só são consultadas para `Edit(path)` e `Read(path)` (escrever regra de caminho para `Write`/`NotebookEdit` não pega); e plugins podem ser instalados via *command source*, com managed settings capazes de bloquear marketplaces de usuário.

## A lacuna que domina (transfere das rodadas 1-3, sem melhora)

**Nenhum comportamento de 2.1.261 foi observado.** O processo desta sessão é 2.1.260; o binário no disco, 2.1.261. Os sete achados são leitura de changelog, compare e docs — declaração da plataforma sobre si mesma. Em particular, a afirmação central ("o `exit 2` segue barrando sob `bypassPermissions`") é **inferida da ausência de menção no delta**, não re-testada. A sonda que fecharia isso: sessão nova em processo 2.1.261 e provocar um dos três vetos (`pretooluse-protect-main.sh`, `pretooluse-merge-gate.sh`, `premodelswitch-guard.sh`). **Não rodou.**

Segunda lacuna, esta de **execução da rodada**: o fan-out não teve worker de mercado, o que viola o invariante de que capital é eixo de toda pesquisa. Registrado como falha de execução, não como ausência de sinal no mundo. Gatilho: a próxima rodada E3 — ou a E4-capital, cujo `last_run` é 2026-08-31 e está a poucos dias do teto de 45 dias — inclui o worker explicitamente antes de qualquer selo.

## NÃO-VERIFICADOS

18 refutados, 18 claims fora do orçamento de verificação e 27 fontes não lidas. Refutação notável: a maioria dos "achados" de changelog não sobreviveu à checagem de fonte primária — 18 de 25 caíram, o que é a razão de esta rodada ter só 7 confirmados contra 13 da rodada 3.

## Fios que a rodada abre (com gatilho, não como tarefa)

| Fio | Gatilho |
|---|---|
| Algum veto do core já falhou em silêncio numa sessão retomada em versão ≤2.1.260? | varrer os logs dos hooks por decisão registrada sem efeito observável em commit/merge |
| `/skill-doctor` supera ou só informa a camada L2 da poda? | rodar `/skill-doctor` numa sessão 2.1.261 e comparar com o que o L2 pretendia medir |
| O sid da migalha de retomada pode ser malformado | validar o formato no hook, ou rotular a fonte da extração (`jq` vs fallback) |
