---
branch: feat/update-bridge-mechanism
pr: 593
date: 2026-08-13
reviewed_diff_sha256: 2a6ecacf5870fc555ddf1c4523a4d55a4ebd8008bea538b01ae01588686d64e8
findings_total: 19
findings_real: 19
findings_fixed: 19
tokens: 46712
duration_min: 13
verdict: CORRIGIDO
reviewer: code-reviewer (opus, adversarial — 7º Elenxo da linha de mecanismos)
---

# Passada adversarial — `feat/update-bridge-mechanism`

## O 7º Elenxo: o script que mata "update sem verificação" afirmava sem medir

A lei da linha pela 7ª vez, em dose dupla: a prova central da v1 (boot com `auth: enforce`)
era satisfeita por **um boot de três dias atrás** (as últimas 40 linhas do journal atravessam
3 invocações), e a fase chamada "higiene de rollback" **destruía o não-versionado que dizia
salvar** (`git diff` não carrega conteúdo de untracked; `clean -fd` apagava o resto — e o
`.diff` nascia root, EM CLARO, no diretório que o `vps-exposure-check` marca como HARD).

## Achados (19 reais, 7 refutados) — todos endereçados na v2

| # | sev | achado | cura na v2 |
|---|---|---|---|
| 1 | ALTO | trap religava o serviço com `ExecStart` DENTRO do node_modules que o `npm ci` apaga — 203/EXEC em loop de 5s (assinatura de 08-10); rollback sem `reset-failed` nem rebuild da PWA | trap desarmado ANTES do `npm ci` (`DEPS_TOUCHED`); `fail` avisa "deixado parado de propósito"; rollback ganha `reset-failed` + web ci/build |
| 2 | ALTO | `journalctl -n 40` atravessa invocações — boot velho provava o update novo | `_SYSTEMD_INVOCATION_ID` da invocação atual |
| 3 | ALTO | `npm ci --silent` = 0 chars no erro (medido) | `--no-audit --no-fund`; a linha `added N packages` volta a ser contagem |
| 4 | ALTO | NOOP cego à árvore do BRIDGE ("árvore limpa" sem olhar o repo onde a edição manual acontece) | porcelain dos DOIS repos no gate |
| 5 | ALTO | dump de resíduo não salvava conteúdo de untracked e o `clean -fd` apagava | `git stash push --include-untracked` no clone (dentro do repo, como onion) |
| 6 | ALTO | `.diff` root e EM CLARO em `/home/marcio/backups/*` → HARD no `vps-exposure-check` (provado com o knob da bancada) | resolvido pelo stash — nenhum arquivo fora do repo |
| 7 | MÉDIO | cabeçalho prometia "HEADs == origin/main" e a fase 5 não comparava | duas linhas de `fail` comparando com os REMOTE capturados |
| 8 | MÉDIO | fase 3 reescrevia a árvore SERVIDA com serviço no ar (workspaces symlinkam o clone; /a2a spawna o gate) | stop movido para ANTES do reset |
| 9 | MÉDIO | `rev-parse`/`start` sem `\|\| fail` — aborto mudo sob `set -e`, um deles na janela de mutação | `\|\| fail` em todos |
| 10 | MÉDIO | `sleep 3` fixo com margem medida ZERO (boots reais de 1s e 3s) | espera ativa ~30s, passo 2s |
| 11 | MÉDIO | `/health` como oráculo que o PRÓPRIO PR documenta como mentiroso (IdP fora → 200 com tudo 401) | corpo inspecionado (`ok:true`) + TETO DECLARADO no cabeçalho apontando o fio Q_JWKS |
| 12 | MÉDIO | guarda de node_modules-root não era fail-closed (find falhou → "limpo") | `-print -quit` + existência do dir; ausente = falha |
| 13 | BAIXO | backup sem nomear o artefato | saída capturada e logada |
| 14 | BAIXO | comentário do `-H` ensinava mecanismo que esta máquina refuta (sudoers já reseta HOME — medido) | comentário honesto, flag mantida como seguro barato |
| 15 | BAIXO | header prometia `OLD_RESTARTS` no rollback e não entregava | promessa removida do desenho |
| 16 | BAIXO | README afirmava "main == produção" no presente, sem mecanismo — a MESMA classe prazo-em-comentário que o `D_retire_legacy` deste PR registra | redação: a igualdade só vale após rodar, e é o script quem a MEDE |
| 17 | BAIXO | traces absolutos: 12 TARGET-MISSING → 0, mas o balde fora-de-julgamento foi 35→49 sem baseline | teto declarado no README de bridge-auth |
| 18 | BAIXO | sem flock — execuções concorrentes fazem stop/start cruzados | `flock -n` em /tmp |
| 19 | BAIXO | aresta `Q_A2A → C_logto_now_critical` era non-sequitur (existia só para não órfão) | retarget para `C_a2a_gate_narrow` |

**Refutados (7):** SIGPIPE do #502 nesta forma (dentro de `[ ]` o status é descartado);
`npm --prefix run build` (funciona, cwd = prefixo); postinstall com `--prefix`; `--silent`
como argumento do script; unbound no rollback precoce; gramática dos nós novos (radar 0/0/0
nos 3 grafos); "nó sem veredito no freshness" (erro de medição do próprio revisor, declarado).

## Verificação da v2

`bash -n` ok · dogfood NOOP real na produção: detecta "em dia" nos DOIS repos e sai sem
tocar o serviço (`active` antes e depois) · radar `--integrity`/`--schema` exit 0 nos 3
grafos · lint 0 HARD. O ciclo COMPLETO (com mudança real) foi provado manualmente nesta
rodada (F0–F5: clone 74607ec→4770098, bridge e09d4c7→2bb0b78, bancada de provas por
contagem no boot da invocação nova) — o script codifica exatamente esse fluxo.

## Teto declarado

O ramo NÃO-NOOP do script não foi executado ponta-a-ponta pelo próprio script (o fluxo foi
provado à mão nesta rodada; a primeira execução real do ramo cheio será o próximo update
com delta — e o NOOP-gate garante que ele não roda à toa). E a nota do revisor sobre o
próprio método: para medir o "antes" ele usou `stash -u --keep-index` + `pop` (árvore
voltou byte-idêntica) — exatamente o sujar-e-limpar que a guarda dirty-tree do PR #592
declara como teto.
