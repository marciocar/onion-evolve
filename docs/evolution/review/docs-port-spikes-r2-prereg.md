---
branch: docs/port-spikes-r2-prereg
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "curadoria (Elenxo, sessão peer, a cada emenda e no §13) e kg-ssot (revisor separado, recalculando os vereditos e rodando mutantes próprios)"
nota: "0 nas contagens, tokens e duração = não medido nesta soma: as revisões correram nas sessões peer e os achados não foram somados entre as passadas. O registro de cada um, com a cura, está nas tabelas das Emendas R2-1 a R2-10 de PRE-REGISTRO-R2.md, e não invento um total. A última passada: curadoria com 4 achados sobre o §13, curados em texto; kg-ssot recalculou os 7 vereditos sem objeção."
---

# Passada adversarial: `docs/port-spikes-r2-prereg`

## O que muda

A rodada 2 dos spikes das portas, em `docs/evolution/research/port-spikes-qwen-vibe-2026-11/`: o `PRE-REGISTRO-R2.md`
(Emendas R2-1 a R2-10, §12 a §14), o executor em `harness/` (stub, servidor MCP, `run_cell.sh`, `classify.py`,
`aggregate.py`, `test_classify.py`, `run_batch_r2.py`, `check_parent_rule.py`, `cmp_classify.py`, `reproduce.sh`), a
evidência de 124 células do lote `r2` mais a calibração, o agregado, o grafo e a seção de resultados da síntese.

## Achados

As revisões reprovaram a cada emenda antes dos dados e duas vezes depois deles. Os de maior peso:
- **A contagem de mutantes estava vazia desde a R2-8:** o harness não copiava o `stub_llm.py`, e todo mutante «morria».
  A cópia limpa agora tem de passar antes de contar, e o equivalente declarado tem de sobreviver;
- **A regra do filho do Vibe exigia formas nunca medidas:** o BARRA era inalcançável em célula real. A célula de calibração
  mediu o registro, e a regra foi refeita antes dos dados;
- **Três afirmações minhas caíram com a medição:** a ligação pelo `toolCallId`, o `running` só no spawn e a equivalência de
  B1, b1 e b4;
- **«O pai não recebe sinal» era falso** (depois dos dados): o pai recebe uma conclusão indistinguível do sucesso. Corrigido
  só em texto.

## Não curados, declarados

No `PRE-REGISTRO-R2.md`, seção 10:
- N2, N3, N4, N6, N10, N14, N15, Q9 e Q17: casos sintéticos que a regra do filho ainda aceita;
- a `notice` com forma quebrada e o alvo no texto, que dá BARRA em caso sintético;
- a exceção de classificador que derruba o `cmp_classify.py` sem nomear a célula;
- o comentário falso «determinística» em `classify.py`, a base imprecisa gravada no `verdict.json` e a corrida do
  `self.wait`, com o código congelado depois dos dados.

## Mutantes

`test_classify.py`: 538 checagens e 194 mutantes de código, 193 mortos e 1 equivalente declarado. O modo padrão, em série,
foi rodado pela sessão do core sobre o commit anterior à parte F (rc 0); sobre o código final rodou com `--mutant-jobs=3`.

## Limites declarados

- **Tudo é braço stub.** Nada mede o filho com modelo real, nem se ele relataria o veto ao pai.
- «Não rodou» se apoia no registro do cliente e no ref do bare. Não há sensor de processo.
- Commits, reflog e células usam o mesmo relógio local, sem carimbo externo.
- Os SHAs citados no pré-registro são os de antes do rebase; a correspondência está no §14.
