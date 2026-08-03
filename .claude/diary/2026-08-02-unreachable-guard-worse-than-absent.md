---
date: 2026-08-02
instance: onion-evolve
type: learning
classification: collective
tags: [shell, set-e, guarda-inalcancavel, fail-loud, logto, dogfood]
affects: [engineering, meta]
breadcrumb_for: []
share_with: []
next_recommended: "Ao escrever guarda em script com `set -euo pipefail`: a checagem SÓ roda se a atribuição que a alimenta não puder matar o script. Padrão: `x=$(cmd ... || true)` e SÓ ENTÃO `[ -n \"$x\" ] || { erro; exit N; }`. Para achar as inalcançáveis já existentes: `grep -n 'set -euo pipefail' -A999 script.sh | grep -nE '^\\s*\\w+=\\$\\(' ` e pergunte de cada uma se a checagem seguinte é alcançável quando ela falha. E o teste que revela: rode com `bash -x` — leitura do código NÃO mostra, porque o código está certo."
review_after: 2026-10-31
conflict_class: static
significance: "Achei uma guarda que existia, estava CORRETA, e nunca rodava — porque `set -euo pipefail` matava o script na atribuição, antes dela. Guarda inalcançável é pior que guarda ausente: a ausência se vê no code review, a inalcançabilidade dá impressão de cobertura."
---

## Signal

**Uma guarda pode existir, estar correta, e nunca rodar.** Sob `set -euo pipefail`, a falha do
comando mata o script **na atribuição** — antes da checagem que existia justamente para explicar
aquela falha. O resultado é pior que não ter guarda nenhuma: a ausência aparece no code review; a
inalcançabilidade **dá impressão de cobertura**.

## Evidência

`ops/bridge-auth/logto-provision.sh`, passo 0 (token M2M). O script morria **mudo**: `exit 1`, zero
saída. O código tinha exatamente a guarda que teria explicado:

```bash
_secret="$(docker exec "${PG_CONTAINER}" psql ... )"      # ← morre AQUI sob set -e
[ -n "${_secret}" ] || { echo "ERRO: secret vazio..."; exit 4; }   # ← nunca alcançado
```

Causa raiz: `docker` exige `sudo` nesta máquina (usuário fora do grupo). O `docker exec` retornava
não-zero, `set -e` abortava **na linha da atribuição**, e a linha seguinte — a que diria o porquê —
nunca executou.

**Nenhuma leitura do código mostraria isso**, porque o código está certo. Só `bash -x` revelou: o
trace para na atribuição e a checagem não aparece.

Cura em duas frentes, ambas necessárias:
1. `|| true` na atribuição — para a checagem **poder** rodar;
2. helper `_dk()` que tenta `docker` e cai para `sudo -n docker` — serve rodando como root (cron) ou
   como o maestro, sem exigir que o chamador saiba qual dos dois é.

## O que fecha

É [behavior-over-declaration](../../docs/knowledge-base/agentic-patterns/ai-strategies/behavior-over-declaration.md)
aplicado à própria rede de proteção: **a existência da guarda no fonte não prova que ela guarda**.
O que prova é o comportamento sob falha — e o instrumento é `bash -x`, não a leitura.

Par direto com a lição de `2026-07-30` (behavior-over-declaration virado para dentro): lá a triagem
declarava cobertura que não tinha; aqui é o **script** que declara.

## Fronteira honesta

Isto **não virou guarda automática** — não há lint que detecte "checagem inalcançável sob `set -e`"
neste repo hoje. Fica como padrão de escrita e como pergunta de review, que é o degrau mais fraco da
escada `guarda > KB > migalha`. A generalização mecânica (detectar `x=$(...)` sem `|| true` seguido
de checagem de `$x`) é plausível e **não foi construída**: não passou pelos portões — uma ocorrência
medida, dono não nomeado.
