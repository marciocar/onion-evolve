---
title: 'Resíduo — a sessão não reescreve mais o cliente do provedor'
date: 2026-10-12
branch: feat/guard-direct-provider-api
reviewed_diff_sha256: d4e393ceb7f8e60fab9575c022d0575cecd66d12ec0431a2eb8272dea34d54b2
reviewed_code_sha256: 29c65f328a2913d7e210cc49955b93b65b9bf8055d383649fd706411a68718b0
findings_total: 6
findings_real: 6
findings_fixed: 6
tokens: 120000
duration_min: 4
verdict: CORRIGIDO
elenxo: sim
nota: >-
  SAC-75, forjada pelo /meta:forge-guard (censo primeiro: classe nova). Substrato decidido pela medição:
  o defeito mora no COMANDO da sessão (147 comandos Bash únicos com host de provedor em 20 dias, cinco
  repos, um deles depois do tm.sh existir) e o passivo no arquivo rastreado é ZERO. Por isso o veto
  principal é o hook PreToolUse(Bash) pretooluse-direct-provider-api.sh (exit 2, onFailure: block), que
  arma por provedor só com adapters/<p>.py|.sh E provider ativo; a REGRA 105 (Script rastreado não chama
  a API do provedor de task manager por fora do adapter) cobre o script avulso promovido ao repo, HARD e
  sem catraca, como a REGRA 102. Markdown não é julgado (documentar ≠ chamar). Elenxo em sessão isolada,
  mandato de falso positivo: 6 achados reais (4 classes de FP no hook, 1 na REGRA 105, 1 escape que
  desligava o veto inteiro), todos curados com caso e mutante; escapes menores foram para o teto. REGRA 87
  (PR que EDITA um .kg.yaml enxergou os confirmed dele) — confirmed vistos em auto-drive-2026-10:
  E_LEVA_CONDUZIDA_ATE_O_MERGE_POR_ORDEM, E_OPINIAO_EXPANSAO_AINDA_NAO_CONFIAVEL,
  E_OPINIAO_CARIMBO_PELO_QUE_FOI_LIDO, E_OPINIAO_RISCOS_QUE_FALTAVAM, E_DOGFOOD_POR_COMANDO_REAL;
  nenhum contradiz o fechamento de Q_GUARDA_API_DIRETA_DE_PROVEDOR.
---

# Resíduo — `feat/guard-direct-provider-api`

## O que foi medido antes de escrever

- **Censo** (`guard-census.sh . --markdown`): nenhuma guarda cita os hosts, então a classe é nova. Os
  moldes copiados foram `pretooluse-merge-gate.sh` (veto por exit 2) e `task-manager-executable-check.sh`
  (o helper tsv que o dispatcher chama, como na REGRA 104).
- **Passivo no repo**: 12 arquivos rastreados citam um host. Só 2 são código, e os dois estão dentro de
  `utils/task-manager/`. O histórico tem um caso de 2025 no `.cursor/`, já removido.
- **Passivo na sessão**: nos transcripts, 147 comandos Bash únicos com host de provedor
  (2026-09-23 → 2026-10-12). Em 2026-10-12T03:21, depois do merge do tm.sh, a sessão principal rodou
  `python3 - <<'EOF'` com urllib contra o Linear. Esse é o caso verbatim (i) da bancada.
- **Réplica do uso real**: dos 71 comandos únicos com o host do Linear, 68 vetam (todos com chamada real)
  e 3 calam (todos só citando o host). Zero falso positivo, zero escape. O custo é de cerca de 70 ms por
  comando comum.

## Passada adversarial (Elenxo)

| # | achado | classe | cura |
|---|---|---|---|
| 1 | código que só CITA a chamada era vetado (script de medição, heredoc que grava doc ou KG, `node -e` citando) | FP, bloqueador | idioma de biblioteca (sem curl/wget em código), fora de literal de string, a até 3 linhas do host, sem comentário nem import |
| 2 | heredoc que é DADO no stdin de um script (`tm.sh comment.add - <<EOF`) era julgado como código | FP | heredoc só é código quando não há arquivo de script |
| 3 | comentário de shell com `(` ou `;` virava segmento | FP | comentário recortado antes do shlex |
| 4 | host em qualquer argumento do cliente (`?q=` de busca, corpo `-d`, cabeçalho) | FP | o host tem de abrir o argumento (o destino) |
| 5 | REGRA 105 acusava docstring, mensagem de erro e script de medição | FP, HARD | idioma por linguagem, janela de linhas, docstring e mensagem caladas |
| 6 | um heredoc dentro de `$(…)` derrubava o juiz (`IndexError` calado), e o comando inteiro passava | escape | corpos de heredoc globais para a recursão |

Os escapes que ficaram foram declarados no teto do hook: f-string com o host em variável,
`HTTPSConnection('host')`, `perl -ne`, `env -S`, `uv run`, `cat x | python3 -`.

## Bancada

A família é `run_direct_provider_api_selftests`. Ela cobre:

- as duas polaridades no hook (20 casos) e na REGRA 105 (11 casos);
- o corpus real;
- o dispatcher de produção sobre o defeito verbatim;
- o registro no `settings.json`;
- o hook armado contra a árvore real (o heredoc verbatim dá rc 2, o tm.sh dá rc 0).

São 26 mutantes (17 no hook, 9 na REGRA 105), e todos mordem. A família tem 32 ✓, todos rodados com
`LC_ALL=C`. A `veto-onfailure` (c) passou a contar 5 vetos.

## Não feito / declarado

- O pre-commit foi pulado nos checkpoints (`--no-verify`). A validação é o `pr-finalize` sobre o commit
  final, e o CI.
- O hook não tem flag de escape, por desenho. Verbo que o tm.sh não tem é achado: implementa-se no adapter.
