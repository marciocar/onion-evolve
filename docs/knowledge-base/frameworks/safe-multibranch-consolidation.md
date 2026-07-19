# Consolidação Segura Multi-Branch — Método

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-10 | **Categoria**: Frameworks
> Método para convergir N feature-branches acumuladas (em 1+ repos) para branches consolidadas e
> PRs sob comando, com dois mandatos duros: **nada fica pelo caminho** e **nada quebra produção**.
> Promovido via co-evolução: nasceu e foi executado de ponta a ponta numa instância adotante
> (um adotante + o app de um adotante, ~19 branches, 2026-07-09); o core pediu o destilável
> ("declarado ≠ verificado"), recebeu o artefato com a verificação completa e destilou esta KB.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-10 |
| **Última Atualização** | 2026-07-10 |
| **Categoria** | Frameworks |
| **Origem** | Sinal upstream um adotante ([método](../../evolution/inbox/_processed/2026-07-09-metodo-consolidacao-segura-multibranch.md)) + [artefato verificado](../../evolution/inbox/_processed/2026-07-09-artefato-mapa-consolidacao.md) (mapa-SSOT com vereditos 6-branch, build-green, salvage) |
| **Relacionado** | [gitflow-patterns](gitflow-patterns.md) (motor git local) · [knowledge-graph-sdaal](../concepts/knowledge-graph-sdaal.md) (C_DEVPROD_GAP; o mapa vira nó do KG) |

---

## O problema que o método resolve

Trabalho real acumula branches: fixes que produção absorveu por outro caminho, features
substituídas por reescritas, experimentos, docs misturados com runtime. Na hora de consolidar,
os dois modos de falha clássicos:

1. **Perder trabalho** — branch dropada levava um commit único (um script de rollback, uma guarda).
2. **Quebrar produção** — merge de branch stale reintroduz o que prod já curou, ou código chega
   antes da migração de schema que ele exige.

## Os 8 princípios

1. **Duas lanes, nunca misturar.** **CÓDIGO** (toca runtime → mira a branch de produção →
   prod-safety obrigatória) × **CONHECIMENTO** (docs + corpo do framework + grafos → mira a branch
   de integração → não afeta a imagem de prod).
2. **"Nada fica pelo caminho" ≠ "tudo vai no PR".** Cada artefato vai ao **destino certo** ou é
   **descartado de propósito** (decisão registrada) — nada valioso se perde, nada de ruído entra
   em prod.
3. **Baseline de PROD explícito por repo.** *Ler branch de trabalho ≠ ler produção* (nó
   `C_DEVPROD_GAP` do KG). Todo Δ se mede contra o artefato deployado, não contra a branch default.
4. **Declarado ≠ verificado.** Classe de branch (`+N commits` = payload?) é hipótese até review
   commit-a-commit — marcar `[VERIFICAR]` e só promover com veredito.
5. **Migração antes do código (ordem HARD).** Migrations aditivas isoladas em PR próprio, aplicadas
   em prod **antes** do código que as lê — senão o deploy quebra o painel/serviço que depende delas.
6. **Salvage antes de drop.** Branch SUPERSEDED pode carregar commits únicos de valor (guardas,
   scripts de rollback) — resgatar (cherry-pick ou re-implementação consciente sobre o main atual)
   **antes** de dropar; branch só morre depois da extração.
7. **Build-green como prova.** Consolidada montada em **worktree isolado**, conflitos resolvidos,
   build/typecheck **EXIT=0** — e, quando há dado, validação contra dump fresco (a composta não
   pode regredir o que cada parte curou).
8. **Deploy pareado quando há contrato cross-repo.** Config/flag compartilhada = ordem
   produtor→consumidor, com degradação benigna comprovada se um subir sem o outro.

## O fluxo (6 fases)

| Fase | O que faz | Saída |
|---|---|---|
| **1. Inventário** | Por branch: Δ vs baseline de prod, lane, classe *hipotética* | Tabela branch→Δ→lane→classe→ação, tudo `[VERIFICAR]` |
| **2. Verificação** | Fan-out read-only, review commit-a-commit por branch | **Veredito** por branch (schema abaixo) |
| **3. Montagem** | Consolidada em worktree isolado + build-green (+ validação com dado) | Branch consolidada provada |
| **4. Salvage** | Extrair commits únicos das SUPERSEDED antes do drop | Cherry-picks/re-implementações registrados |
| **5. Higiene** | O que NUNCA entra em PR (abaixo) → branch dedicada de untrack/gitignore | Repo limpo sem tocar runtime |
| **6. Sequência de PRs** | **Sob comando** (nunca autônomo): migrações isoladas → código (pareado se cross-repo) → salvage follow-on → lane conhecimento → drops | Prod atualizada sem regressão; conhecimento preservado |

## Schema de veredito por branch

> Vocabulário validado pelo `@metaspec-gate-keeper` antes da canonização (não se cria vocabulário
> normativo sem gate).

| Veredito | Significado | Ação |
|---|---|---|
| `PROD-CANDIDATE` | payload real, prod-safe (aditivo/retrocompat/flag-gated) | entra na consolidada |
| `NEEDS-CHANGES` | payload real com pendência dura (ex.: migração faltando) | corrigir antes (ex.: 2 PRs — migração 1º) |
| `NEEDS-REBASE` | payload real, base stale, overlaps disjuntos | rebase → vira PROD-CANDIDATE |
| `ABSORBED` | prod já contém (por outro caminho) | descartar |
| `STRAGGLER-DROP` | Δ residual sem payload não-absorvido | descartar |
| `SUPERSEDED-SALVAGE` | substituída por reescrita, mas carrega commits únicos | salvage (fase 4) → depois drop |
| `KNOWLEDGE-LANE` | só docs/scripts/grafos de valor | extrair p/ lane conhecimento |
| `SAFE-TO-DROP` | nada único (ex.: só self-fix de conflito) | descartar já |

Os três vereditos de descarte se distinguem pelo **porquê** (MECE): `ABSORBED` = prod **já tem** o
payload por outro caminho · `STRAGGLER-DROP` = o Δ **não é** payload (artefato residual) ·
`SAFE-TO-DROP` = nada único em nenhum sentido (nem payload, nem conhecimento).

## Escopo de PR — o que INCLUI / EXCLUI / NUNCA

- **PR de CÓDIGO inclui só runtime**: `apps/**`, schema + migrações, testes, `.env.example`.
- **EXCLUI** (vai à lane conhecimento ou é dropado de propósito): `docs/**`, relatórios, probes
  SQL, corpo do framework (`.claude/**`).
- **NUNCA, em PR nenhum** (higiene/segurança): dumps de dados, backups `*.sql` não-migração,
  `*.bkp.zip`, diretórios de sessão com transitórios (risco de PII). Achado pré-existente →
  **não propagar**: untrack + gitignore em branch dedicada, separada do PR de feature.

## Evidência de campo (a execução que originou o método)

2 repos, ~19 branches, 8 vereditos emitidos e verificados; 2 consolidadas montadas em worktrees com
typecheck **EXIT=0**; validação com dado (backlog SLA: baseline 45 · composta 29 · controle 167 — o
reconcile sozinho **reintroduziria** 167, provando por que a composição importa); salvage 2/3
cherry-picked + 1 preservado-em-branch; higiene em 2 branches dedicadas (backup de auth e 2016
arquivos de sessão untracked). Detalhe completo: [artefato-mapa-consolidacao](../../evolution/inbox/_processed/2026-07-09-artefato-mapa-consolidacao.md).

## Relações

- **[gitflow-patterns](gitflow-patterns.md)** — o motor git local (branch/merge/tag); esta KB é a
  camada de **método de release multi-branch** por cima dele. PRs/CI = adapter forge.
- **[knowledge-graph-sdaal](../concepts/knowledge-graph-sdaal.md)** — o mapa de consolidação vira
  **nó do KG** (`claim` com traces) e o princípio 3 é o `C_DEVPROD_GAP` aplicado a release.
- **Playbooks (RFC-0002)** — situação reconhecível: "muitas branches acumuladas + medo de perder
  trabalho/quebrar prod" → aplicar este método; deliberação só onde o veredito pedir.
