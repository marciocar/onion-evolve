---
branch: fix/protect-main-default-branch
pr: pendente
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 4
findings_fixed: 1
tokens: 206000
duration_min: 50
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial curta da própria sessão (opus), refutador com default reprovado
---

# Passada adversarial — `fix/protect-main-default-branch`

Nó: `Q_VETO_DE_FORCE_PUSH_SO_PROTEGE_O_LITERAL_MAIN`. Mandato do refutador, com default reprovado:
(a) achar uma forma de push forçado ou direto ao ramo padrão que ainda passe; (b) achar falso
positivo em branch de feature.

## Achados

| # | sev | achado | status |
|---|---|---|---|
| 1 | alta | **Falso positivo que o desenho óbvio teria criado.** Na config real do brain-granaai, lida sem escrever nada lá, o `origin/HEAD` aponta **`develop`** e `gitflow.branch.master = master`. Somar as duas fontes (a 1ª versão desta cura) vetaria `git push -f origin develop`, que hoje passa e não é produção. | **CURADO**: o gitflow tem precedência; o `origin/HEAD` só vale sem ele. Caso `pr-gfd-dev` e mutante M6 (sem a precedência, o caso reprova). |
| 2 | média | **Push NÃO-force direto e deleção na produção do adotante seguem passando** (`git push origin master`, `:master`, `--delete origin master`). Quem os barra é o merge-gate, que se desarma sem `ops/pr-merge-verified.sh`, por desenho. O protect-main só olha force, e é igual para `main` (`git push origin :main` rc=0 antes e depois). | **DECLARADO** (teto `C_TETO_PUSH_DIRETO_NO_ADOTANTE_SEGUE_SEM_VETO`, com gatilho). No repo de bancada armado o merge-gate barra os dois (paridade medida). |
| 3 | média | **A resolução lê o clone, não o host**: `origin/HEAD` defasado, produção com outro nome sem gitflow nem `origin/HEAD`, e o padrão de um repo empurrado por URL não são vistos. | **DECLARADO** (teto `C_TETO_RESOLUCAO_LOCAL_E_FONTES` e cabeçalho da lib). |
| 4 | baixa | **Fallback fecha uma branch de trabalho chamada `master`** num repo sem gitflow e sem `origin/HEAD` (só `git init` + `remote add`). | **DECLARADO**: fechado por desenho, raro; com qualquer fonte resolvida, `master` que não é produção passa (`pr-ohn`, `pr-gf-master`). |

## Formas tentadas que o veto barra (repo de produção master, rc=2)

`+master` · `'+master'` · `-f origin master` · `+HEAD:master` · `+master~0` · `-f HEAD:refs/heads/master` ·
`heads/master` · `+feat:refs/heads/Master` (caixa) · `--force-with-lease=master origin master` ·
`B=master; git push -f origin "$B"` · `"${B:-master}"` · `{master,feat}` · push nu `-f` sentado em master ·
`+main` (segue barrado).

## Falso positivo procurado e não achado (rc=0)

`--force origin feat` · `-f origin master-old` · `-f origin feat/master` · `-f origin mastery` ·
`-f origin develop` e `-f origin onion/develop` na config real do brain-granaai · `-f origin master` no core
(`origin/HEAD` → main) · `+master` num repo cujo `origin/HEAD` é main.

## Evidência

> `tokens` é a diferença do contador de contexto da sessão (medido); `duration_min` é ESTIMADO (a sessão
> não carimbou o relógio no início).

- Bancada: `LC_ALL=C bash .claude/validation/lint-selftest.sh --families pretooluse_veto` = 236/236.
- Seis mutantes por `ops/mutate-and-restore.sh`, todos mordendo (9, 6, 4, 2, 1 e 1 casos).
- Dogfood: hook alimentado com payload cujo `cwd` é o brain-granaai (somente leitura): `+master` rc=2,
  `-f origin master` rc=2, `+main` rc=2, `-f origin develop` rc=0.
