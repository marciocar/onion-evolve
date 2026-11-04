---
branch: docs/exit2-coupling-2026-11
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
tokens: 0
duration_min: 0
findings_fixed: 7
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "curadoria, em duas leituras do texto do CLAUDE.md (agente da sessão, só leitura); o Elenxo do run wf_ff363b47-bb6 sobre a pesquisa"
nota: "tokens e duração 0 = não medido nesta soma: as leituras correram na sessão da curadoria. O custo do run está no frontmatter da SYNTHESIS; o custo das três medidas e deste fechamento não foi instrumentado."
---

# Passada adversarial: `docs/exit2-coupling-2026-11`

## O que muda

- Selo do maestro: `D_EXIT2_COUPLING_WORDING_2026_11`, «C com o gatilho da D».
- `CLAUDE.md`: a exclusividade do `exit 2` sai, e o veto passa a camada de conformidade, com grau de prova, condições de força, o vazio declarado e o gatilho de reabertura.
- Cópias da frase corrigidas: dois READMEs gerados, comentário de um hook, nó novo no grafo de identidade.
- Grafo e SYNTHESIS da pesquisa, com `data/` saneado das três medidas: login real, contêiner com API simulada, escrita em `.claude/` roteirizada.
- Fecha `Q_DOCTRINE_EXIT2_REVIEW_2026_11` e `C_TETO_APROVACAO_DE_MOD_SOBRE_EXIT_2`.

## Achados

Todos conferidos contra os dados gravados antes de aplicar, nenhum recusado.

1. Alto: «sem configuração gerenciada não vazia» era falso; virou «sem chave de política».
2. Alto: «só `allowManagedModsOnly` ou `blockedMarketplaces`» passava do medido; ficou mais estreito que a sugestão.
3. Médio: «hook comum» sugeria que o gerenciado não falha; virou «mesmo gerenciado».
4. Médio: faltava dizer que a regra `deny` também cai.
5. Médio: «a sessão seguinte fura» tinha a condição do aceite, com a exceção de `~/.claude/skills/`.
6. Baixo: ruleset só «onde o plano dá».
7. Médio: «só por leitura: Goose» ficou velho com a medida do #1475.

## Mutantes

Não se aplica: doutrina e registro, sem guarda nova. A guarda de escrita de plugin vai em PR próprio.

## Limites declarados

Medida com login real: só o veto do `.env`, haiku, `--setting-sources project,local`. Medidas em contêiner e de escrita: API simulada ou chamadas roteirizadas. Os outros 4 vetos do core sob mod, login Team/Enterprise e Copilot, Gemini e Cursor em modo autônomo não foram medidos. As massas de 2026-08 saíram porque a metade shell não reproduz, e `E_OBJECAO_MASSES_STALE` traz os números. O `CLAUDE.md` ganhou uma versão curta depois das leituras da curadoria, por causa da REGRA 109 (CLAUDE.md não cresce sem tirar o equivalente ou citar um nó); o texto revisto inteiro está na SYNTHESIS, com a frase sobre escrita em `.claude/` acrescentada depois da revisão.
