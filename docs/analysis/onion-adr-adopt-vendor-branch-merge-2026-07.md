---
title: "ADR/Spec — /meta:adopt --update via merge de vendor-branch (never-clobber estrutural)"
date: 2026-07-09
type: adr
status: accepted — implementado (2026-07-09, Fases 1-3); verificado por dogfood de campo (392 arquivos)
decision-scope: adoption / update durability / never-clobber
supersedes: none
related:
  - onion-adr-repo-adoption-2026-06.md
  - onion-evolution-2026-07-08.md
  - ../evolution/inbox/_processed/2026-07-08-proposta-branch-onion-vendor.md
  - ../../.claude/utils/adopt/durable-commit.sh
  - ../evolution/rfc/rfc-0001-co-evolution-comms.md
---

# ADR/Spec — `/meta:adopt --update` via merge de vendor-branch

| Campo | Valor |
|-------|-------|
| **Achado** | #2 do `/meta:evolve` dirigido (`onion-evolution-2026-07-08.md`) |
| **Decisão** | `--update` migra de **copy-over** (`cp -R` + revisão de `diff`) para **merge de uma branch `onion/vendor`** persistente |
| **Superfície** | **L1+L2 completo** (o manifest atual: `.claude/*` + `docs/{meta-specs,knowledge-base,sdaal}`) — preserva o fallback L1 do adopt |
| **Constrói sobre** | #301 (`durable-commit.sh`) — reusado como o passo de commit no vendor-branch |
| **Status** | design aceito; implementação via `/engineer:plan` |

## 1. Contexto e problema

O #301 tornou a instalação **durável** (commit automático numa branch dedicada), fechando o incidente
"uncommitted apagado por descarte". Mas o **apply continua sendo copy-over** (`cp -R "$TMP"/. "$DEST"/`
após revisão de `diff -rq`): a customização local do adotante aparece como **diff a revisar** — que o
maestro pode clobar por engano — e **não** como conflito git de verdade. Falta o **never-clobber
estrutural**: um 3-way merge onde a divergência é um conflito real, resolvido com as ferramentas de git.

## 2. Decisão

`--update` passa a **mergear** uma branch **`onion/vendor`** (persistente, só-framework) na branch de
integração do adotante. O `onion/vendor` é a **fonte-de-merge**, atualizada a cada `--update` com o novo
manifest do core; o `git merge` traz o framework novo para a working tree da integração (onde o Claude
Code o lê) e **materializa a divergência como conflito git**.

### Invariante preservada (caveat do sinal)
`onion/vendor` **não é branch-que-se-usa-direto**: o Claude Code lê `.claude/` da working tree do branch
**atual**; trocar pra `onion/vendor` perderia o código de produto. Ela é **só a fonte de merge**; após o
merge, o framework vive na integração. Modelo = *vendor-branch-como-fonte-de-merge*.

### Por que NÃO git subtree
O framework está **espalhado** em `.claude/` + `docs/` (sem prefixo único que o subtree exige) e o subtree
**acoplaria** o adotante ao remote/história do core. A branch `onion/vendor` é git puro, offline-ok,
dependency-free — e **reusa** a maquinaria que já existe.

## 3. Mecanismo (fluxo)

### 3.1 Bootstrap do `onion/vendor` (na adoção, ou 1x em adotantes legados)
- Criar `onion/vendor` **ramificada** da integração (`git branch onion/vendor <integration-HEAD>`) — §5 Q1
  (órfã refutada por experimento: quebra a base comum do 3-way). O ponto de ramificação DEVE ser o estado
  de **framework limpo** (verdadeiro logo após o install da adoção, antes de customizações).
- `onion/vendor` compartilha história com a integração (base comum) e carrega o produto como snapshot
  **intocado** (nunca editado nela → merge limpo). Só arquivos de framework mudam no vendor.

### 3.2 `--update`
1. Atualizar `onion/vendor`: checkout (por-path/worktree) → extrair o manifest NOVO do core sobre ela →
   `durable-commit.sh "$TARGET" update "$NOW" onion/vendor` (o commit só materializa o delta do framework).
2. Voltar à branch de integração: `git -C "$TARGET" checkout <integration_branch>`.
3. **Merge**: `git -C "$TARGET" merge onion/vendor` (sem `--no-ff` obrigatório; mensagem estampa o pin).
   - **Sem conflito** → framework novo aplicado limpo.
   - **Conflito** (adotante customizou um arquivo do framework) → **conflito git real**; o maestro resolve
     com as ferramentas de git (é o never-clobber estrutural — a customização NÃO some silenciosamente).
4. Re-carimbar `.onion-version` (como hoje) + relatório downstream (como hoje).

### 3.3 Reuso
- `durable-commit.sh` — o passo de commit no `onion/vendor` (já testado, 6 selftests).
- A extração de manifest (`git archive | tar`) — idêntica à de hoje.
- `resolve-integration-branch.sh` — para saber em que branch mergear.

## 4. Never-clobber: copy-over → 3-way merge

| Aspecto | Hoje (copy-over + #301) | Com vendor-branch merge |
|---------|--------------------------|--------------------------|
| Divergência local | diff a revisar (clobável por engano) | **conflito git** (explícito, resolvível) |
| Durabilidade | commit durável (#301) | commit durável **+** história de merge |
| Ferramenta de resolução | olho humano no `diff -rq` | `git mergetool`/marcadores de conflito |
| 3-way (base comum) | não (é cp) | **sim** (base = último `onion/vendor` mergeado) |

## 5. Questões abertas (resolver no /engineer:plan)

1. **`onion/vendor` órfã vs ramificada — RESOLVIDA por experimento (2026-07-09):** **ramificada** da
   integração (`git branch onion/vendor <integration-HEAD>`). Órfã foi **refutada**: sem base comum, o
   `merge --allow-unrelated-histories` dá **conflito add/add em TODO arquivo de framework** (mesmo os
   não-customizados). Ramificada compartilha base comum → 3-way real: conflito **só** onde há customização
   local; os demais atualizam limpo; produto preservado; customização preservada nos marcadores (não
   clobada). O produto vive na branch (é ramo da integração) mas nunca é tocado nela → merge limpo.
   **Subtileza p/ legados (§refinada Q3):** se a customização do adotante já está COMMITADA na integração
   ANTES de o vendor existir, ela entra na base comum → o merge tomaria `theirs` (framework novo) =
   clobber silencioso. Fresh-adoption não sofre (customização vem depois do ponto de ramificação). Legado
   precisa de tratamento próprio (Fase 3).
2. **Por-path vs worktree** para mexer no `onion/vendor` sem sair da integração: worktree
   (`git worktree add`) evita o vai-e-volta de checkout e é à-prova-de-working-tree-suja. Ecoa a Fase 2a legacy.
3. **Adotantes legados** (sem `onion/vendor`): o 1º `--update` pós-migração faz o **bootstrap** (§3.1) antes
   do 1º merge. Precisa de guard idempotente.
4. **Relação com `onion/adopt` (#301):** `onion/adopt` (commit durável da adoção) e `onion/vendor`
   (fonte-de-merge do update) convergem? Provável: `onion/vendor` **substitui** o papel de fonte, e a
   adoção passa a semeá-la; o commit durável do `--update` cai no merge da integração, não numa
   `chore/onion-update-<pin>` avulsa. **Revisar a interação com o fluxo de #301.**
5. **Interação com #299** (KB embarcado no plugin): conforme mais KB migra pro plugin, a superfície L2 do
   `onion/vendor` **encolhe**. O manifest do vendor deve derivar do que NÃO está no plugin? (provável: não
   agora — manter L1+L2 completo pelo fallback; otimizar depois).
6. **`.gitattributes merge=union`** para arquivos append-only (CHANGELOG, `_processed/`)? Reduz conflito espúrio.

## 6. Verificação (plano)

- **Selftests** (estender `lint-selftest.sh`, padrão `run_durable_commit_selftests`): seed do vendor →
  update-sem-conflito (merge limpo) → update-COM-conflito (customização local vira conflito, não é clobada)
  → idempotência → adotante-legado-bootstrap.
- **Dogfood de campo**: um `--update` real num adotante (rhilo/goalflow) com um arquivo de framework
  **customizado** localmente — confirmar que o merge **conflita** (não clobba) e resolve.
- Gate mecânico: `lint-artifacts` + `lint-selftest` verdes.

## 7. Invariantes

- **`/meta:adopt` fica** (canal L2+3 + **fallback L1** — por isso vendor carrega L1+L2 completo).
- **Never-clobber** vira estrutural (mais forte, não mais fraco).
- L1-via-plugin **coexiste** (não reaberto) — o vendor é o caminho adopt, o plugin é o caminho marketplace.

## 8. Resolução e verificação (implementado 2026-07-09)

**Implementação** (`.claude/utils/adopt/vendor-branch.sh` + fiação no `adopt.md` + selftests):
- **Fase 1**: helper `seed`/`update` (worktree + reuso do `durable-commit.sh`) + `run_vendor_branch_selftests`
  (5 casos; total 176). **Fase 2**: adoção semeia `onion/vendor`; `--update` mergeia (copy-over saiu);
  `.gitattributes merge=union`; Contrato §3. **Fase 3**: dogfood de campo + este fechamento.

**Correção de rota (Q1) — dogfood > design:** a hipótese "órfã" foi **refutada** por experimento — sem base
comum, `merge --allow-unrelated-histories` dá conflito add/add em TODO arquivo. O correto é **ramificada**
(base comum → 3-way real).

**Verificação de campo (392 arquivos de framework REAIS):** com um arquivo customizado localmente + framework
novo tocando o mesmo arquivo → **conflito ISOLADO em 1 arquivo** (o customizado); os ~391 restantes
atualizaram limpo; customização preservada nos marcadores (não clobada); arquivo novo do framework veio
limpo; produto preservado. **7/7 asserts.** Prova que o never-clobber estrutural funciona em escala real,
sem conflito espúrio.

**Resolução das 6 questões:** Q1 ramificada (acima) · Q2 worktree · Q3 bootstrap de legado no 1º `--update`
(guard idempotente, coberto por selftest) · Q4 `onion/adopt`=integração-da-adoção, `onion/vendor`=fonte-de-merge
semeada dela; `chore/onion-update-<pin>` saiu do update · Q5 L1+L2 completo mantido · Q6 `.gitattributes merge=union`.

**Legado (§5 Q1) — RESOLVIDO (2026-07-09):** o bootstrap de `onion/vendor` num adotante legado (sem vendor,
customização já commitada) NÃO ramifica mais do HEAD — acha o **commit-base LIMPO** (o mais recente cuja
superfície de framework é blob-idêntica a `core@<pin-adotado>`, via `ls-tree -r` content-addressed
cross-repo) e ramifica dele. Assim a base do 3-way é o framework limpo, e a customização commitada vira
**conflito** (não clobber). Verificado por experimento + dogfood do helper (5/5) + selftest (caso "legado
c/ customização commitada → baseline limpo → CONFLITO"). **Fallback honesto:** se o core não tem mais o
pin (história reescrita) ou o framework nunca foi limpo (entrelaçado), o helper **avisa** e ramifica do
HEAD, sinalizando o risco — nunca clobra em silêncio.
