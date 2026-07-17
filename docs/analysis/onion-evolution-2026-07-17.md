# Onion Evolution Backlog — 2026-07-17

## 0. Sumário
◆ Dimensões: 10 · ◆ Padrão: fan-out-and-synthesize · ◆ Workers: 8 scan + 5 juízes (opus) + D10 no principal
◆ Tiering: `scan mecânico: haiku/low · scan semântico D2/D4/D5/D6: sonnet/medium · juiz adversarial: opus/high`
◆ Budget: ~614k tokens · ◆ Run ID: `wf_5608e127-eea` · ◆ Duração: 271s · ◆ Erros: 0 (após fix de schema array→object)
◆ Achados brutos: 8 · **sobreviveram: 6** · refutados pelo juiz: 2 · vetos de fase: 0

> Read-only: este relatório é a única escrita. As correções são dos atuadores (`/meta:create-*`,
> `/product:spec→/engineer:plan`) sob validação do `@metaspec-gate-keeper`.

## 1. Backlog priorizado

| # | Sev | Dim | Achado (arquivo:linha) | Padrão (doutrina) | Artefato-alvo | Esforço | Comando de execução |
|---|-----|-----|------------------------|-------------------|---------------|---------|---------------------|
| 1 | 🟡 | D4 | `onion-framework-identity.md` cita contagens **stale** vs a SSOT gerada: "5 skills" (é 8, l.44), "87/82 comandos" (é 97, l.94/312), "49 agentes" (é 51, l.312) | kb-refresh | `docs/knowledge-base/meta/onion-framework-identity.md` | S | `/meta:create-knowledge-base` (update) |
| 2 | 🟡 | D6 | `lint-artifacts.sh` varre `.claude/worktrees/` (gitignored) → **3 HARD + 47 SOFT falsos** locais; nenhuma função `_find` exclui `*/worktrees/*` (outras regras excluem fixtures/sessions/analysis) | guard-scope-fix | `.claude/validation/lint-artifacts.sh` | S | `/meta:create-command` (fix escopo do lint) |
| 3 | 🟡 | D8 | `/meta:create-skill` sem `allowed-tools` no frontmatter (l.1-8: name/description/model/category, falta tools) | frontmatter-complete | `.claude/commands/meta/create-skill.md` | S | fix frontmatter (`allowed-tools:`) |
| 4 | 🟡 | D2 | `/product:task` × `/product:create-task-structure`: descriptions quase idênticas **sem** cláusula "Diferença vs X" (roteamento por description falha); + **category mismatch** (`create-task-structure.md:18` diz `category: meta` vivendo em `commands/product/`) | distinguish | `.claude/commands/product/{task,create-task-structure}.md` | S | `/product:spec→/engineer:plan` |
| 5 | 🟡 | D2 | `@branch-code-reviewer` × `@code-reviewer`: único par branch-*/geral **sem** auto-documentar a distinção na description (os outros 3 pares trazem "Diferença vs @X… DIFF-SCOPED") | distinguish | `.claude/agents/{git/branch-code-reviewer,review/code-reviewer}.md` | S | `/product:spec→/engineer:plan` |
| 6 | 🟢 | D3 | Padrão de roteamento de adapters (forge/git-local/task-sync) duplicado com variações em 5 arquivos, sem fragmento comum | extract-to-common | `git/README.md`, `git/help.md`, `engineer/help.md`, `engineer/pr.md`, `git/flow.md` | M | `/meta:create-command` → `common/prompts/adapter-routing-pattern.md` |

## 2. Achados por dimensão (D1–D10)

- **D1 — Peso/tamanho:** limpo. `adopt.md` (545 l.) na zona soft; **refutado** pelo juiz — o core executável já vive em `.claude/utils/adopt/*.sh` (durable-commit, vendor-branch, write-stamp, merge-*); o inline restante é orquestração de fase, não conceito extraível. Templates (>500) isentos.
- **D2 — Redundância:** 2 achados (itens 4-5) — mesma causa sistêmica (ver §3).
- **D3 — Duplicação >50 l.:** 1 sobreviveu (item 6, roteamento de adapters). **Refutado:** detecção de provider — os 4 comandos já referenciam `common:prompts:task-manager-provider-detection` (stubs finos, não cópia).
- **D4 — KBs stale:** 1 achado (item 1). Gate ≤18mo respeitado (não é idade — é divergência factual de contagem vs SSOT).
- **D5 — Conformidade meta-spec:** limpo (nenhuma violação estrutural nos artefatos de alto risco; nenhum veto de fusão de fase).
- **D6 — Moderna-vs-legada + SDAAL:** 1 achado (item 2, lint scope). Sem resíduo `.onion`/CLI/npm; sem vazamento provider-specific fora de adapters.
- **D7 — Cross-refs/links:** limpo (0 symlinks quebrados; sem links relativos órfãos na amostra).
- **D8 — Frontmatter/plataforma:** 1 achado (item 3). Inventário verificado **em sync** (sem drift).
- **D9 — Frescor de contexto de domínio:** **no-op** — no framework os `docs/*-context/` são templates (só README); valor real em projeto-alvo populado.
- **D10 — Frescor da memória de sessão:** **0 rot em 22 entradas** (amostra checável). Testes: `jq` presente (env-fact ✅); 4 adotantes presentes c/ `.onion-version` (granaai, gustavo-pulga, pulse-mais, rhilo-metagamify ✅); PRs #299-304/#320/#321/#348/#357/#394 mergeados ✅; preferências não auto-expiram. Nada corrigido/apagado.

## 3. Alertas transversais (causa sistêmica)

- **🔔 Description-como-contrato-de-roteamento (D2 ×2):** itens 4 e 5 são o mesmo modo de falha — pares com overlap **real** (distintos só em `allowed-tools`/`category`/escopo) que **não expõem a distinção na `description`**, a única superfície que um dispatcher lê. O repo já tem o padrão-cura em outros pares (`docs-health` vs `validate-docs`, `create-agent` vs `create-agent-express`, os 3 branch-*). Candidato a **regra de lint** (par de nomes próximos sem cláusula "Diferença vs" → SOFT).
- **🔗 declarado≠verificado (D4 item 1 ↔ sinal do dia):** a KB `onion-framework-identity.md` cita contagens que **drift**aram da SSOT gerada — a mesma família do sinal `adopt-update-pin-integrity` triado hoje (confiar em estado declarado sem verificar o vivo). Reforça o valor de gerar-da-fonte, não copiar números.

## 4. Invariantes respeitadas
- Nenhuma proposta funde fases de `engineer/*` ou `product/*` (juiz adversarial: 0 vetos de fusão de fase).
- Orquestração rodou **no nível principal** (skill `onion-orchestration` → `Workflow`); nenhum agente "evolve-worker".
- Read-only sobre `.claude/`: única escrita = este relatório. Exceção D10 (memória fora do repo) não gerou mutação (0 rot).

## 5. Próximos passos (cada item → seu comando atuador)
1. **Item 1 (D4)** — resync das 3 contagens em `onion-framework-identity.md` via `/meta:create-knowledge-base` (ou fix direto lendo `docs/onion/inventory.md`). **Mais barato e alto-valor** (documentação de identidade mentindo sobre o próprio tamanho).
2. **Item 2 (D6)** — excluir `*/worktrees/*` nas funções `_find` do `lint-artifacts.sh` (espelhar as exclusões já existentes de fixtures/sessions). Elimina 50 falsos-positivos locais.
3. **Item 3 (D8)** — adicionar `allowed-tools:` ao frontmatter de `create-skill.md`.
4. **Itens 4-5 (D2)** — tratar como **cluster** via `/product:spec→/engineer:plan`: adicionar cláusula "Diferença vs" nas 4 descriptions + corrigir o `category` de `create-task-structure.md`; considerar a regra de lint anti-drift (§3).
5. **Item 6 (D3)** — extrair `common/prompts/adapter-routing-pattern.md` e referenciar nos 5 arquivos.

> **Nota de tiering (auto-verificação):** nenhuma fase difícil rodou barata nem mecânica rodou cara — scan mecânico em haiku, semântico em sonnet, juiz adversarial em opus. O fix de schema (array→object no `StructuredOutput`) é lição operacional: top-level de schema de worker deve ser `object`.
