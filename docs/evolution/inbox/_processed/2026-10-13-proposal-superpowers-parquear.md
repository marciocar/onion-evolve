---
title: 'Proposta da curadoria: Superpowers → PARQUEAR (1º estudo, dissecação até o N4)'
date: 2026-10-13
from: onion-curation (consumidor)
to: core (onion-evolve)
type: proposal
flow: upstream (consumidor→core)
---

# Proposta: PARQUEAR o Superpowers, com dois gatilhos

O 1º estudo da curadoria é a dissecação do Superpowers (obra/superpowers, Prime Radiant, MIT, HEAD
`8ca22dba`, v6.4.2). Aqui se propõe; quem decide é o core.

- **Grafo:** `onion-curation:docs/evolution/dissect/superpowers-2026-10/superpowers-2026-10.kg.yaml`
- **Projeção:** `SYNTHESIS.md`, no mesmo diretório

O veredito proposto é **PARQUEAR**, escolhido pelo maestro entre parquear, costurar e rejeitar
(selado em `D_SUPERPOWERS_2610`). O censo de dissecações do core já o lê como N4, `parquear`, fresco até 2026-11-08 (o N4 vem do plano
reprovado do carimbo; o veredito da ferramenta é de N3).

**Isto dispara o gatilho da entrada do Superpowers no panorama do core**
(`competitive-landscape.md:22-24`, "candidato a DIRETO, a confirmar pela dissecação"). Para fechar a entrada:
o estudo confirma o mesmo movimento só em parte, porque o mecanismo é persuasão sem gate. Divergência
de estrelas: 296,6k (2026-10-09, aqui) contra 297,9k (2026-10-12, no panorama), que é crescimento e não erro.

## O que o estudo mediu

| Nível | Resultado |
|---|---|
| N0 | MIT, 296,6k★, 5 releases em 3 meses. Cerca de 80% dos commits são do fundador. Capital **parcial**: a Prime Radiant (4 pessoas) vende suporte enterprise e tem 52 sponsors. Rodada, receita e preço não foram verificados. |
| N1 | 15 skills, 1 hook SessionStart, nenhum comando. O Onion **não tem** systematic-debugging, test-driven-development **como fluxo** nem diagnosing-superpowers. Considerados: o agente `test-engineer` declara expertise em TDD, mas não como fluxo; o `/meta:kg diagnose` diagnostica engajamento, não sessão. |
| N2 | Lido no código, **não rodado**. O mecanismo é prosa injetada no SessionStart. O determinismo fica só em dois scripts que o modelo escolhe chamar (`task-done`, `review-package`). Não há CI nem grafo. |
| N3 | A persuasão é o mesmo mecanismo que o Onion já usa (o Onion também injeta no SessionStart); a diferença é que o Onion soma lint e CI. O `task-done`, que só grava conclusão com teste verde, transfere em parte. |
| N4 | O plano do "carimbo por reexecução" foi **REPROVADO pelo Elenxo** (ver abaixo). |

## Os dois gatilhos

1. **As 3 skills** que o Onion não tem: reabrir quando forem rodadas em worktree isolada contra uma tarefa
   de bancada, com disparo e efeito observados. Só então propor absorver pelo `/meta:absorb-skill`.
2. **O carimbo por reexecução** (`P_N4_STAMP_REEXECUTED`): reabrir quando o worker do `/meta:kg-freshness`
   ou do `/meta:census` devolver um campo estruturado `probe {argv[], expect_regex}`.

   O plano v1 caiu por 3 fatais, medidos no core:
   - **Inviável:** em `census-2026-09-01`, 24 de 30 `method` são prosa, 3 usam `sudo` e 2 dependem de web.
   - **Injeção de comando:** o plano reexecutaria uma string vinda de LLM.
   - **A guarda não guarda:** a REGRA 57 (O veredito do run está SELADO no grafo que ele julgou) só dispara com `ledger:`, e um recibo textual seria forjável.

   O core já tem metade do conceito: o juiz do census manda "re-rodar o barato" (`census-workflow.mjs:102`).
   O alvo certo de uma futura absorção é o `stamp()` do `census-seal.py`, não o `kg-freshness`.

## Para o core, fora do veredito (hipótese, não medida)

O Superpowers chegou a 296,6k★ sem nenhum gate determinístico e declara 15 harnesses. Isso não prova que
determinismo não vende, porque há fatores de confusão nomeados no nó `E_MERCADO_PERSUASAO_E_DISTRIBUICAO`.
Mas é pergunta de posicionamento para a entrada do Superpowers no panorama.

## Bilhetagem

O estudo não abre via nova. É o modelo OSS grátis com receita de serviço adjacente (aqui, suporte
enterprise e sponsors), análogo ao do BMAD no panorama (MIT grátis + workshops de terceiros, `competitive-landscape.md:28`).
