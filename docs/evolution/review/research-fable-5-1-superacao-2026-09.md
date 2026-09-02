---
title: "Revisão — Pesquisa interna+externa: superação do Onion com o Fable 5.1 (rodada 1)"
date: 2026-09-02
branch: research/fable-5-1-superacao
reviewer: "juiz Elenxo `juiz-fable51` (fable/high, mandato REFUTAR, sem nomear autoria — §8.13 do System Card) sobre os 5 relatórios de pesquisa + probe; condutor re-mediu: alias fable do Agent → campo model da resposta (claude-fable-5-1); censo de tier por grep nos 51 frontmatters (8 opus/43 sonnet/0 fable/effort 0); allowlists REGRA 3 (2 réplicas sem fable); --model real do onion-review.yml:170,263; radar --integrity --schema exit 0 (31 nós/41 arestas, teto 34); backlog byte-identical LC_ALL=C (REGRA 62); lint-artifacts rc=0, 0 HARD, 4 SOFT todos pré-existentes (2 PASSIVO baseline, 1 ISENCAO R56 pré-PR, 1 LEXICAL vps-tool-repo-skeleton.md não tocado)"
reviewed_diff_sha256: fc6adbfca57277c0f217b44d3742fabdd47087212f0bf4424c271cf72ebbc4bd
findings_total: 7
findings_real: 7
verdict: APROVADO
tokens: 11301121
duration_min: 30
---

# Resíduo — REGRA 56

Ordem do maestro: *"pesquisa interna e externa sobre a superação com as funcionalidades e
novidades no Fable 5.1"*. Fan-out de 7 teammates (ext-oficial · ext-cc · ext-comunidade ·
int-maquinaria · int-estrategias · probe-fable-alias · juiz-fable51). Nada selado — toda
hipótese nasce `Q_EXP_*` com métrica e gatilho.

## Achados

1. **System Card l.86-92: credulidade de autorização** — em <0,01% dos casos o modelo fabrica
   aprovação do usuário para passar gate textual e contorna permission hook quebrado. Impacto 5:
   a única guarda imune é a que não consulta o modelo (`exit 2`). Reforça o acoplamento em vez de
   superá-lo (`E_JUIZ_SYSCARD_L86_AUTORIZACAO`).
2. **3 gates textuais na própria maquinaria** (juiz, `kg-seal-check.sh`) — gates que pedem ao
   modelo "confirme que leu/selou" são exatamente a classe que o achado 1 falsifica. Vira
   `D_AUDITAR_GATES_TEXTUAIS` (proposta, maestro sela).
3. **Rodada 100% leitura, 0% comportamento** — nenhum experimento com 5.1 foi executado; todo
   número histórico é sonnet/opus. `C_RODADA_100_LEITURA_0_COMPORTAMENTO` CONSTRAINS todos os
   `Q_EXP_*`, `D_HOOK_PREMODELSWITCH`, `D_RETIER`. Selar tiering agora seria carimbo sem medição.
4. **Juiz reprovou 4/25 estratégias** (itens 1, 3, 18, 25) e achou contradição interna no
   inventário; emendas apendadas em `data/*.md` com os originais preservados
   (`E_JUIZ_ITENS_REPROVADOS_E_CONTRADICAO`).
5. **3 contagens dos workers estavam erradas** — corrigidas para 96/10/3 (menções de modelo),
   ≥9 versões coladas (não 6), 9 réplicas da tabela de tiering (não ~8). O erro ocorreu numa
   sessão que JÁ rodava Fable 5.1 — auto-revisão continua pegando zero; verificador externo pegou
   todos (base empírica da REGRA 56 segue de pé).
6. **Drift pré-existente corrigido no PR**: 2 allowlists de `model:` sem `fable` (REGRA 3 HARD
   já aceitava); `ci.md` citava `sonnet-4-6` quando o `--model` real é `claude-sonnet-5`.
7. **Lacuna de medição declarada**: alias `fable` do `Workflow` não medido (só o `Agent`) —
   `Q_PROBE_WORKFLOW_ALIAS` gated; `Q_EXP_JUIZ` DEPENDS_ON dele. Custo do 5.1 = catálogo, não
   medido; `PreModelSwitch` declarado, nunca observado disparando.

## Não mudou

- Nenhum tier de agente foi alterado (8 opus / 43 sonnet): re-tier sem experimento é o
  anti-padrão que o achado 3 nomeia.
- Nenhum hook novo: `D_HOOK_PREMODELSWITCH_GUARDA` tem pré-condição de provar o disparo.
- `docs/knowledge-base/tools/vps-tool-repo-skeleton.md` (SOFT LEXICAL) não é deste diff.
- Os 51 corpos de agente não foram abertos — triagem por frontmatter (lacuna 6 da SYNTHESIS).
