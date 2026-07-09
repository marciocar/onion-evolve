---
tipo: sinal-upstream
data: 2026-07-09
origem: rhilo-metagamify + rhilo-app (consolidação WRR/SLA/Oráculo → PRs)
assunto: MÉTODO PROMOVÍVEL — "Consolidação segura multi-repo/multi-branch" (map-SSOT + verificação adversarial + prova prod em código E dado)
relacionado:
  - docs/evolution/inbox/2026-07-09-sdaal-generaliza-para-design-ia.md (KG-SDAAL — este sinal é o 3º dogfood)
  - docs/wrr/2026-07-09-mapa-consolidacao.md (o artefato SSOT produzido)
  - docs/rhilo/graph/wrr-audit.kg.yaml (nó C_CONSOLIDATION_MAP)
para: onion-evolve (core) — candidato a comando/vertical de engenharia
---

# Sinal: um método repetível de CONSOLIDAÇÃO SEGURA emergiu — vale virar padrão do core

## O contexto (uma frase)
Dois repos (metagamify + rhilo-app) com ~19 branches espalhadas (features, docs, KG, CI, experimentos, superseded) precisavam **convergir para branches consolidadas → PRs sob comando**, com dois mandatos absolutos: **nada fica pelo caminho** e **nada quebra produção**. Fizemos isso e o *como* se provou um método geral, não um one-off.

## O método (o que promover) — 8 movimentos

1. **Mapa-como-SSOT** (`docs/.../mapa-consolidacao.md`): inventário das árvores de branch vs os baselines de PROD, uma linha por branch com classe + ação. É o `.kg.yaml` aplicado ao *release* (1 fonte da verdade da consolidação). Rastreado no KG (nó `C_CONSOLIDATION_MAP`) → **3º dogfood do KG-SDAAL**.

2. **Duas LANES que não se misturam**: **CÓDIGO** (toca runtime → mira prod → prod-safety obrigatória) vs **CONHECIMENTO** (docs + `.claude/` + KG → mira `develop`). Descobrir a lane de cada branch pelo *footprint* (`git diff --name-only base...branch | conta por dir`) evita PRs poluídos.

3. **Verificação adversarial por fan-out de subagentes** — 1 subagente **read-only por branch** (proibido `git checkout`, só `git diff/log/show/cherry`), devolvendo veredito **estruturado**: `PROD-CANDIDATE | NEEDS-CHANGES | NEEDS-REBASE | STRAGGLER-DROP | SUPERSEDED-SALVAGE`. Cada um caça: migração destrutiva? flag default? contrato quebrado? ruído a strip? o que NÃO migrou (salvage). Pegou coisas que review manual perderia (ex.: um alias SQL órfão que um auto-merge deixou e quebraria runtime **sem** marcador de conflito).

4. **Prova de "não quebra prod" em DUAS dimensões**: **(a) CÓDIGO** — montar a consolidada em *worktree isolado*, `pnpm install` + `prisma generate` + build de libs + `tsc EXIT=0`; **(b) DADO** — restaurar o dump de PROD, aplicar as migrações, e rodar a lógica nova contra dado real com um **cenário de controle** que mede a regressão que a mudança *evita* (no nosso caso: baseline 45 · composta 29 · controle-ingênuo 167 → a composição prova que preserva a cura E adiciona o escopo). Compilar não basta; rodar-contra-dado-de-prod é o que fecha o mandato.

5. **Salvage disciplinado antes de dropar superseded**: quando uma branch antiga tem valor não-migrado, **RE-IMPLEMENTAR sobre o main atual — não cherry-pick** (o código velho é stale e regride). Documentar cada item resgatado + os *desvios conscientes* (ex.: manter um tipo largo p/ não dropar casos não-mapeados = zero regressão). "Nada fica pelo caminho" = ledger explícito do que foi salvo/preservado/dropado.

6. **Política de escopo de PR** ("nada fica pelo caminho" ≠ "tudo vai no PR"): PR de código = só `apps/**` + migrações + testes; **fora**: `docs/**`, `scripts/*probe*`, `.claude/**`, e **NUNCA** dumps/backups/dados-de-sessão (sanear com `git rm --cached` + gitignore, em branch de higiene separada). Cada artefato ao destino certo, ou dropado de propósito.

7. **Ordem de release derivada das dependências**: migrações isoladas **primeiro** (aditivas/reversíveis, aplicadas antes do código), depois código, depois **deploy pareado** cross-repo quando há contrato compartilhado. "PRs só sob comando do maestro" — a IA prepara branches provadas, o humano dispara.

8. **Root-cause sobe a pilha quando o DB é inconclusivo**: um "a fila parou" que o Postgres não explicava foi fechado nos **logs de infra** (WAF/CloudWatch: 0 hits no endpoint hoje vs N no corte → causa upstream, não no engine). Lição: a forense não termina no banco.

## Por que é do CORE (não só nosso domínio)
Nada acima é WRR/SLA — é **higiene de release multi-branch** que qualquer consumidor Onion com muitas feature-branches enfrenta. Candidato a:
- um comando **`/eng:consolidate`** (ou extensão do `@gitflow-specialist`): gera o mapa-SSOT, dispara o fan-out de verificação, produz o veredito + a ordem de PR;
- um **subagente `branch-consolidation-verifier`** (o read-only por-branch com schema de veredito);
- reforço do **KG-SDAAL** (este foi o 3º dogfood: o *release* também é um grafo de nós/arestas rastreáveis).

## Evidência
- Artefato SSOT: `docs/wrr/2026-07-09-mapa-consolidacao.md` (inventário + verdicts + sequência).
- 6 subagentes de verificação rodados (veredictos estruturados) + 2 consolidadas montadas e **build-green** (rhilo-app back+front tsc=0, metagamify api tsc=0) + **SLA validado no dump** (45/29/167).
- Salvage commitado (Outbox guarda #2; F3a re-implementado non-regressing). Higiene em 2 branches. KG registrado.
- Stack consolidado **subiu local** contra dump de prod restaurado (prova ponta-a-ponta).

## Pedido ao core
Triar como **feature/pattern**: absorver o método (comando + subagente + schema de veredito) e reconciliar com o `@gitflow-specialist`. Perguntas abertas p/ o core: onde vive o "mapa-SSOT" canônico? o schema de veredito de branch vira metaspec? o fan-out de verificação é genérico o suficiente p/ virar util reusável?
