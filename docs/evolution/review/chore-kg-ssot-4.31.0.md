---
branch: chore/kg-ssot-4.31.0
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 15
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: subagente de adoção (worktree agent-a1c9923bc30695f7f), passada própria sobre o diff, depois da bancada pré-tag da ref f113410ba3a0
nota: "tokens 0 = não medido (passada na própria sessão do subagente, sem revisor separado)"
---

# Passada adversarial: `chore/kg-ssot-4.31.0`

## O que muda

- `vendor/kg-ssot/`: de `kg-ssot-v4.30.0` para `kg-ssot-v4.31.0` (5c9526300f92), com o `check` intacto, 651 arquivos
  (eram 648). Novos: `tools/kg_site.py`, `tools/requirements-site.txt` e `zensical.toml`.
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `E_KG_SSOT_431_ADOTADA_1027` e uma aresta.
- `docs/onion/kg-read-index.tsv`: regenerado pelo `kg-trace.sh --emit-index --out`, que escreve em temporário.

## Achados

Nenhum. Suspeitas levantadas e descartadas com medida:

1. **A demo (`docs/demo/`) vazar para o vendor.** Descartada: o diretório não existe em `vendor/kg-ssot/` e o carimbo
   `.kg-ssot-version` não cita `demo`. O `kg_vendor.py` só soma o `mirror_only` com `mirror=True`, que só o
   `kg_mirror.py` passa.
2. **Algo do core ler o `requirements-site.txt` no lugar do requirements do contrato** (o CI instala com
   `--require-hashes`, e o censo de versões compara pinos). Descartada: `grep` por `zensical`, `kg_site`,
   `requirements-site` e `mirror_only` em `.github/`, `ops/` e `.claude/` não acha nada; só o
   `tools/requirements.txt`, que não mudou, é lido.
3. **O `packaging/mirror/release.yml` alterado virar workflow do core.** Descartada: fica sob `vendor/`, fora de
   `.github/workflows/`.
4. **A diferença entre a tag e a ref da bancada mudar o vendor além do anunciado.** Medida com `diff -rq` contra o
   vendor da bancada: só o `locale/pt_BR/LC_MESSAGES/kg-ssot.po` (a tradução da mensagem do `mirror_only`) e o carimbo
   diferem. O ajuste de teste para o console do Windows (`tools/test_kg_vendor.py`) não viaja para o vendor.
5. **O gate mudar com o vendor novo.** Descartada: `ops/kg-gate-ci.sh` com rc 0 e saída idêntica antes e depois
   (193 grafos, 191 no MUST, 2 na dívida herdada), sem `--update`.

## Mutantes

Não se aplica: o PR não forja nem altera guarda. A REGRA 84 (Índice de leitura do KG em sincronia com os traces) é a
verificação mecânica do nó novo, e o lint completo passou com o índice regenerado.

## Limites declarados

- A bancada mediu 191 grafos; a main de 2026-10-27 tem 193. A diferença vem de dois grafos que a main ganhou depois da
  bancada, não do vendor.
- O lint saiu com 0 HARD e as mesmas 23 SOFT da bancada; mudam só a contagem da defasagem das portas (89 para 93
  commits, porque a main andou) e o motivo da isenção da REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial).
