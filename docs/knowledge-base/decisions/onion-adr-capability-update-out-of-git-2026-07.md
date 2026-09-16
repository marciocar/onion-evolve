---
title: "ADR/Spec — capability-update fora-do-git: o 4º modo de proveniência (adoção docs-only)"
date: 2026-07-10
type: adr
status: proposto — DESIGN ONLY; implementação GATED até o 1º `--update` docs-only real num adotante
decision-scope: adoption / capability delivery / out-of-git provenance
supersedes: none
related:
  - ../evolution/rfc/rfc-0005-scope-inheritance-polymorphism.md
  - ../evolution/rfc/rfc-0004-a2a-live-interop.md
  - ../evolution/inbox/_processed/2026-07-10-rfc5-docs-only-adoption-ground-truth.md
  - onion-adr-adopt-vendor-branch-merge-2026-07.md
  - (ADR de consolidação de um adotante — core-only, não referenciável daqui)
  - ../../.claude/commands/meta/co-deliver.md
  - ../../.claude/utils/adopt/write-stamp.sh
---

# ADR/Spec — capability-update fora-do-git (4º modo de proveniência)

| Campo | Valor |
|-------|-------|
| **Origem** | RFC-0005 §4.1 (adendo 2026-07-10) — sinal ground-truth um adotante (PR #1127 do alvo) |
| **Decisão** | `--update` de capability em adotante **docs-only** = **entrega-fora-do-git** com 3-way por **manifest de hashes**, maestro-gated |
| **Superfície** | só `.claude/` (+ `CLAUDE.md` se fora do git no alvo); a superfície **docs** continua no vendor-branch (tracked) |
| **Constrói sobre** | vendor-branch (Achado #2, o 3-way *com* git) · co-deliver (I3, entrega-sem-commit) · `write-stamp.sh` (stamp em disco) · `--show-scope` (proveniência auditável, PR #320) |
| **Status** | **DESIGN ONLY** — implementação gated; "estoura no 1º `--update` do time um adotante — desenhar antes disso" (RFC-0005 §4.1) ✅ desenhado |

## 1. Contexto e problema

No dia seguinte ao aceite da RFC-0005, o time um adotante materializou em `master` uma adoção
**docs-only** (PR #1127 do alvo, Mauricio: *"`.claude/` (capability layer) and `CLAUDE.md` stay OUT
of git"*), coexistindo com a adoção **full** em `develop`. Evidência verificada no clone local
read-only (2026-07-10):

```
$ git -C <repo-do-adotante> ls-tree origin/master -- .claude | wc -l   → 0   (não-tracked)
$ git -C <repo-do-adotante> ls-tree origin/master -- CLAUDE.md | wc -l → 0   (não-tracked)
$ git -C <repo-do-adotante> ls-tree origin/master --name-only -- docs  → docs (tracked)
$ git -C <repo-do-adotante> ls-tree origin/develop -- .claude | wc -l  → 1   (tracked — full)
$ ls <repo-do-adotante>/.claude → agents commands hooks settings.json … (capability EM DISCO)
```

**Por que o `--update` atual quebra no docs-only** (fluxo do `adopt.md` §"Atualizar um repo adotado"):

1. `vendor-branch.sh update` exige `.claude/` **na árvore git** (worktree + merge; `_update` guarda
   repo git + árvore limpa) — sem blobs tracked, não há o que mergear;
2. `pin-integrity-check.sh` compara canário **vendorizado** (tracked) com o conteúdo do pin;
3. o **commit durável** pós-merge não tem o que commitar (a superfície é untracked);
4. o 3-way do vendor-branch usa a base comum **do git** — que não existe para `.claude/`.

Sem um 4º modo, a escolha do time "vaza para branch" (master docs-only vs develop full) — exatamente
o uso de branch-como-escopo que a RFC-0005 §3 rejeita. A **forma de adoção** (`full | docs-only |
in-place`) é dimensão de 1ª classe e precisa de mecânica própria de update.

## 2. Decisão (headline)

O `--update` **particiona por superfície e por forma**:

- **docs** (tracked no docs-only) → continua no caminho atual (**vendor-branch 3-way**, sem mudança);
- **`.claude/` (capability, untracked)** → **4º modo**: staging + **manifest de hashes** como base do
  3-way *sem git* + apply **never-clobber** com sidecar — entrega-fora-do-git, **maestro-gated**
  (dry-run obrigatório → confirmação → apply), parente direto da entrega-sem-commit do carteiro
  (I3: o core **nunca** commita no repo alheio) e coerente com o `never-live-pull` do regulado
  (RFC-0004: o adotante recebe proposta, o gate humano aplica).

## 3. As decisões de design

### D1 — Detecção da forma docs-only (declarado ≠ verificado)

- **Verificado (autoridade):** `git -C <T> ls-tree HEAD -- .claude` **vazio** ∧ `.claude/` **existe em
  disco** ∧ superfície docs Onion **tracked** (`ls-tree HEAD -- docs` não-vazio). Determinístico,
  read-only, verificável hoje (§1).
- **Declarado:** campo novo `form: docs-only` no stamp `.claude/.onion-version` (extensão futura
  `--form` no `write-stamp.sh`) + `lineages.<branch>.form` no `members.yaml`. O `--show-scope`
  (PR #320) já lê `form:` do stamp — o vocabulário é o mesmo (`full | docs-only | in-place`).
- **Divergência declarado×verificado → avisar e confiar no verificado** (mesma doutrina do
  pin-integrity: o stamp é hipótese, não fato).

### D2 — Mecânica de entrega sem git: manifest de hashes (o núcleo)

O 3-way do vendor-branch usa a base comum do git; sem git, a base é um **manifest de hashes**:

- **`.claude/.onion-manifest`** — sha256 por arquivo do estado **ENTREGUE** na última
  adoção/update (escrito a cada entrega). É a **base** do 3-way.
- **ours** = disco do alvo · **theirs** = manifest novo extraído do core (`git archive` do manifest
  L1, mesma extração do vendor-branch) para staging temporário.
- **Classificação por arquivo** (espelha a semântica do merge):

| Caso | Condição | Ação |
|------|----------|------|
| unchanged | disco == base == theirs | nada |
| update-limpo | disco == base ∧ theirs ≠ base | aplica |
| novo | ∉ base ∧ ∉ disco | aplica |
| **customizado** | disco ≠ base ∧ theirs ≠ base | **CONFLITO**: never-clobber — grava sidecar `<arquivo>.onion-new` + lista no relatório (paridade com `.env.example.onion`) |
| local-only | ∈ disco ∧ ∉ manifest do core | intocado |

- **Primeiro update sem manifest** (adoção docs-only pré-ADR): baseline = conteúdo do **pin adotado**
  extraído do core (análogo ao `_clean_baseline` content-addressed do vendor-branch para legados) —
  nunca assumir disco==base.
- **Rsync cego rejeitado:** `rsync --ignore-existing` não atualiza nada já existente;
  `rsync` sem guarda clobra customização. Só o manifest dá o 3-way.
- O manifest é também a **trilha de auditoria do regulado**: sha256 do manifest = fingerprint do
  capability layer instalado, verificável offline; com o `--show-scope` (config) formam a dupla de
  proveniência auditável do plano config no docs-only.

### D3 — Gate do maestro (never-live-pull)

**Dry-run obrigatório** (relatório de classificação: N aplicáveis / M conflitos / K local-only) →
**confirmação explícita do maestro** → apply. Nenhum passo automático além do determinístico.
Coerente com RFC-0004 (regulado recebe sinal, nunca puxa framework ao vivo) e com o Contrato de
Segurança do `adopt.md`.

### D4 — Proveniência do update sem git (o "stamp sem git")

Três registros complementares, do menos ao mais durável:

1. **Re-stamp `.onion-version` em disco** via `write-stamp.sh` (já **não depende de git**; semântica
   preserve + `updated_at` intacta) — acrescido do campo `form:`;
2. **`.claude/.onion-manifest` novo** (pin + hashes do estado entregue);
3. **Relatório downstream TRACKED em `docs/evolution/inbound/` do alvo** — docs **são** versionados
   no docs-only: *o plano-docs versiona a proveniência do plano-capability que não se versiona*.
   Contém pin novo, sha256 do manifest e a lista de conflitos/sidecars. Entrega = **entrega-sem-commit**
   (I3, como o co-deliver): o arquivo entra untracked; **o time commita** — o objeto git auditável
   nasce na sessão do adotante, nunca na do core.

### D5 — O que fica GATED (explícito) e o que NÃO muda

**Gated até o 1º `--update` docs-only real:**
- o helper (`capability-update.sh` ou equivalente) + selftests;
- qualquer resolução automática de conflito (o sidecar é o teto);
- transporte automático/CI da entrega (o gatilho de graduação do carteiro governa);
- **opt-in reverso** (o time passar a versionar `.claude/`) — decisão do time, não do core.

**Não muda:**
- adotante **full** continua 100% no vendor-branch 3-way (Achado #2);
- a superfície **docs** do docs-only continua no vendor-branch;
- invariantes: never-clobber · I3 (um escritor por repo) · maestro no ato irreversível ·
  fail-safe > fail-open · `adopted_at` nunca re-carimba.

## 4. Questões abertas (para o plano de implementação futuro)

1. **`CLAUDE.md` fora do git no alvo** — mesmo tratamento never-clobber (base no manifest, sidecar
   `CLAUDE.md.onion-new`)? Provável sim; confirmar com o caso real (o skeleton do adopt já prevê
   `CLAUDE.onion.md` na colisão).
2. **Procedimento de configuração pós-cópia** (merge de `settings.json`, registro de hooks) — opera
   em disco, deve funcionar as-is; **registrar** que no docs-only o resultado fica untracked (o
   relatório D4 é quem o torna auditável).
3. **`git clean -fdx` no alvo apaga o capability layer inteiro** — risco estrutural da forma
   docs-only, aceito pelo time; documentar como caveat no relatório de cada update (ecoa o caveat do
   co-deliver sobre untracked). O manifest + pin permitem **reinstalar determinístico**.
4. **`beacons/` e outros estados efêmeros dentro de `.claude/`** — o manifest deve cobrir só a
   superfície entregue pelo core (manifest L1), nunca estado local (beacons, sessions) → já é
   local-only por construção; validar no dry-run real.

## 5. Verificação (plano — NADA roda agora, design only)

- **Selftests futuros** (padrão da casa, self-contained em mktemp): baseline→update-limpo ·
  customizado→CONFLITO-não-clobra (sidecar) · local-only intocado · idempotência ·
  primeiro-update-sem-manifest (baseline do pin) · form no stamp/members divergente→aviso.
- **Dogfood de campo:** o 1º `--update` docs-only real num adotante, na `master` dele (gate deste ADR abre a
  implementação nesse momento).
- Gate mecânico: `lint-artifacts` + `lint-selftest` verdes.

## 6. Invariantes

- **Forma de adoção é dimensão de 1ª classe** (`full | docs-only | in-place`) — nunca se expressa
  por branch (RFC-0005 §3/§4.1).
- **Never-clobber** vale com ou sem git — muda a base do 3-way (git → manifest), não a garantia.
- **O core nunca commita no repo alheio** (I3) — a proveniência tracked nasce na sessão do adotante.
- **Fail-safe:** sem manifest e sem pin recuperável → o helper avisa e exige o gate humano por
  arquivo; nunca aplica em silêncio.
