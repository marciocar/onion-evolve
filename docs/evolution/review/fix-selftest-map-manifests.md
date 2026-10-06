---
reviewed_diff_sha256: 92319e6576ff9f9aab02fcaa909532b08aba95ce016c60d0c2feb7923eaccc02
reviewed_code_sha256: 6654e9b3948dc84701d069772e26bf7cce596fd36e390ebcfe259cc03d228ada
findings_total: 4
findings_real: 2
tokens: 119597
duration_min: 12
verdict: APROVADO_COM_CURA
elenxo: sim
nota: >
  Medido no PR #932 (2026-10-06): mexer em onion-engineering/onion-product.manifest.sh fazia o pre-commit
  cair no failsafe "tudo" (217 famílias, 27 min, máquina carregada). Causa: as famílias que percorrem
  TODOS os manifestos citavam `verticals` sem a barra final, e o `_selftest_family_map` só trata como
  prefixo o caminho que termina em `/`. Cura: a barra no `vdir` do `plugins_sync`, que regenera cada
  manifesto e compara com o plugin commitado. Com ela, os 5 manifestos selecionam 17-19 famílias.
  Caso (g2) novo na selftest_lanes; o mutante (sem a barra) morde em todos os manifestos.
  Elenxo (opus, mandato REFUTAR) APROVOU, com 4 achados:
  (1) fail-open: NÃO é real. Nenhuma família fora da seleção quebra com manifesto real; role_bundle e
  graph são cobertos pelo lint completo (REGRA 37 e REGRA 21), e o hook_autofix clona o HEAD, então
  nunca via o staged. A bancada completa segue no CI.
  (2) o `//` em "${vdir}/x" é inócuo (medido: capability+plugins_sync 21/21).
  (3) REAL, CURADO: a barra no `capability` era redundante (a família já entrava por citar
  `.claude/utils/`) e o comentário mentia sobre ela → barra e comentário removidos dali; o braço
  `capability` do (g2), que não discriminava nada, saiu.
  (4) REAL, CURADO: o manifesto "que ninguém cita" era citado pelo próprio caso (o mapa captura o
  literal `${REPO_ROOT}/.claude/...`) → o caminho agora é montado sem o prefixo; `--map` não o
  captura mais (0 ocorrências).
  FORA DO ESCOPO, CURADO AQUI (o gate deste PR o revelou): a bancada completa reprovou 1/1893 —
  `premodelswitch-guard: Pre → fable-5-1[1m]` — e isolada passava 11/11. Causa: o hook decidia com
  `printf "$allowed" | grep -qxF` sob `set -o pipefail`; sob carga o grep -q fecha cedo, o printf toma
  EPIPE e o veto NEGAVA uma troca de modelo permitida. O sítio estava no passivo TOLERADO da catraca
  (pipe-verdict-baseline.txt). Cura: here-string, e a linha sai do baseline (catraca desce 124→123).
  Mutante (o pipe de volta) → a família shell_pipefail_robustness acusa "ACIMA da catraca" (✗).
  Gate: famílias afetadas verdes localmente + lint 0 HARD; o commit é CHECKPOINT DECLARADO
  (ONION_FINALIZE_CHECKPOINT=1) e a bancada completa é o CI — padrão escolhido pelo maestro em 2026-10-06.
  Teto declarado: a seleção afetada local é um pré-filtro; o gate final é a bancada completa no CI.
