---
name: federation-member
description: Muta o registro de membros da federação (members.yaml) — OP-1 REGISTRAR neste ciclo (create). Valida a entrada por validador determinístico (members-validate.sh), verifica o pin por pin-integrity-check, regenera as projeções read-only (map/console) e commita no core. Ação por argumento (register); promote/update/revoke são costuras futuras (gated). NÃO é o /meta:federation-register (esse é o ledger de CONTRATOS, objeto diferente).
category: meta
tags: [federation, members, ledger, register, sdaal, spec-as-code]
version: "1.0.0"
updated: "2026-08-27"
allowed-tools: Read Write Edit Grep Glob Bash(bash .claude/validation/*) Bash(git *)
argument-hint: "register [--id <slug>] [--target <path-do-clone>]  (guiado se faltar argumento)"
---

# /meta:federation-member — Mutar o registro de membros (OP-1 REGISTRAR)

## 🎯 Objetivo

Dar **command-side** ao registro de membros da federação (`docs/evolution/federation/members.yaml`).
Neste ciclo, só a **OP-1 REGISTRAR** (create): escrever a entrada de um membro novo no ledger,
seguindo o **template comentado**, com o **pin VERIFICADO** por `pin-integrity-check.sh` — fechando a
fricção do passo final do `/meta:adopt`, que hoje faz toda a adoção técnica mas **apenas sugere** o
registro (o último passo virava edição manual de YAML).

> **Padrão (ajuste 6a):** este comando **orquestra**; a **validação determinística** vive em
> `.claude/validation/members-validate.sh` (espelha o par `/meta:inventory` ↔ `inventory.sh`). A
> validação **nunca** é um agente.

> **NÃO confundir com `/meta:federation-register`** — aquele registra **CONTRATOS** (`contracts/<id>.md`)
> no ledger externo de federação; **este** muta o **registro de MEMBROS** (`members.yaml`), objeto e
> repositório diferentes.

> **Fronteira (gated).** As OP-2/3/4 (PROMOVER/ATUALIZAR/REVOGAR) e o modelo de auth
> (Logto Organizations, plataforma admin multi-operador) **não** são construídos aqui — o gate da
> plataforma está FECHADO (0 `role:consumer`, `contracts/` inexistente) e o build se **re-deriva fresco
> no gatilho** (`gated-work-derives-fresh`). Este comando roda **nativo** para o operador-único de hoje:
> edita `members.yaml` + commit, **zero backend, zero OIDC**.

## 🟢 Quando usar

- No fim de uma adoção (`/meta:adopt`), para **registrar o alvo como membro** — o pin já carimbado.
- Para formalizar um clone/worktree que já existe na máquina mas ainda não está no ledger.
- **Só na FONTE** (`role: source`) — o `members.yaml` é SSOT do core; o command-side escreve nele.

## ⚡ Etapas (ação `register`)

### Passo 1 — Resolver a ação
- `$ARGUMENTS` começa com `register` → seguir. Qualquer outra ação (`promote`/`update`/`revoke`) →
  responder em pt-BR que é **gated / não implementada neste ciclo** (costura futura), sem inventar.

### Passo 2 — Coletar os campos do membro (guiado, pt-BR)
Seguir o **template comentado** de `members.yaml` como forma canônica. Campos:
- `id` (slug), `name` (ver Passo 5 — P6), `role` ∈ {`hub`,`standalone`,`consumer`},
  `kind` ∈ {`adopter`,`distillation`,`door`,`method`}, `parent` (default `onion-evolve`;
  um `consumer`/T2 usa `parent: <id-do-hub>`), `remote`, `local_path`, `mode`
  ∈ {`greenfield`,`legacy`,`regulated`}, `personality_summary` (1 linha), `specializations` (lista).
- `adopted_at` e `personality_last_sync` = **data corrente** (fonte de tempo do sistema).
- Bloco `trust:` = default do template (as 5 listas; `can_receive_from`/`can_advise_to`/
  `diary_readable_by` = `[onion-evolve]`, `can_correct_to`/`exposes_downstream` = `[]`).

### Passo 3 — Guarda de duplicidade (idempotência)
- Se o `id` **já existe** em `members.yaml` → **parar**: registrar é create. Para mudar um membro
  existente, apontar a OP-3 ATUALIZAR (futura). **Nunca duplica** a entrada.

### Passo 4 — Verificar o pin (fail-closed)
- Para `kind` que **vendoriza** (`adopter`/`door`): rodar
  ```bash
  bash .claude/validation/pin-integrity-check.sh "<SOURCE_ROOT>" "<local_path-do-alvo>"
  ```
  Escrever `onion_version: <sha>` **só** se a saída for `pin-ok <sha>` (usar o `<sha>` retornado —
  **nunca** o stamp cru). `pin-untrusted <motivo>` → **parar** e reportar o motivo (não escrever pin
  forjado). Se o `local_path` estiver ausente/remoto (pin **não-verificável**) → **bloquear** para
  kinds vendorizantes.
- Para `kind` que **não vendoriza** (`distillation`/`method`): `onion_version: n/a`, pin-check pulado.

### Passo 5 — Forma do `name:` antes de escrever (REGRA 30 / P6)
- **Ao montar o campo** `name:`, o trecho **antes de `(`** deve `norm()`-igualar o `id` (lowercase,
  sem não-alfanuméricos). Nome comercial/humano vai **dentro de parênteses**, ou marque
  `projection_name_exempt: true`. (A **confirmação** por `projection-safety.sh` — gate HARD
  anti-vazamento — roda **depois** da escrita, no Passo 8b.)

### Passo 6 — Escrever a entrada
- **Editar** `members.yaml`: inserir o bloco YAML ao **fim da lista `members:`**, imediatamente **antes**
  do comentário `# --- TEMPLATE`, com a indentação exata (2 espaços no `- id:`).

### Passo 7 — Validar (determinístico)
```bash
bash .claude/validation/members-validate.sh --json
```
- `valid:true` → segue. `valid:false` → **reverter a edição** e reportar os `errors[]` como **blocker**.

### Passo 8 — Regenerar as projeções read-only (senão o lint HARD reprova)
```bash
bash .claude/validation/graph.sh --map > docs/onion/federation-map.md          # REGRA 38
bash .claude/validation/federation-console.sh > docs/onion/federation-console.html  # REGRA 24
```
- `docs/onion/agent-card.json` (REGRA 25) só muda se o membro trouxer bloco `a2a:` com kids que o core
  pina — regenerar via `a2a-agent-card.sh` **só nesse caso** e conferir por `git diff`.

### Passo 8b — Confirmar projeção segura (REGRA 30)
```bash
bash .claude/validation/projection-safety.sh
```
- Gate HARD anti-vazamento de nome confidencial em superfície derivada. Falha → **reverter** e revisar
  o `name:` (Passo 5) / `projection_name_exempt`.

### Passo 9 — Confirmar verde
```bash
bash .claude/validation/lint-artifacts.sh
```
- Qualquer HARD → **parar** e corrigir antes de commitar.

### Passo 10 — Checkpoint do maestro → commit no core
- `members.yaml` vive **no core**; a sessão do core é o **um-escritor-do-próprio-repo** (permitido por
  I3 — não é repo alheio). Após o **checkpoint do maestro**:
  ```bash
  git add docs/evolution/federation/members.yaml docs/onion/federation-map.md docs/onion/federation-console.html
  git commit -m "feat(federation): registra membro <id> no ledger (OP-1)"
  ```
  Prefixo Conventional em **inglês**; assunto em **pt-BR**.

## 📤 Saída esperada

```
✅ membro <id> registrado em members.yaml (OP-1)
   ◆ pin: pin-ok <sha> (VERIFICADO)  |  onion_version: n/a (não-vendoriza)
   ◆ validação: members-validate OK · projection-safety OK · lint verde
   ◆ projeções regeneradas: federation-map.md · federation-console.html
   ◆ commit <sha>
```
ou, em falha:
```
❌ membro <id> NÃO registrado:
   ∟ <erro acionável — pin-untrusted / id duplicado / campo ausente / P6>
```

## ⚠️ Notas

- **6a (validação não-agente):** a regra dura vive em `.claude/validation/members-validate.sh`,
  exercitada por fixtures em `.claude/validation/fixtures/members/` (manifest + `lint-selftest.sh`).
- **Pin é HIPÓTESE, não fato:** `onion_version` só entra **VERIFICADO** por `pin-integrity-check.sh`,
  nunca do stamp declarado (incidente de campo 2026-06-30).
- **Read-side segue público e read-only** (console/`federation-status`) — sem login. Auth só entra no
  gatilho multi-operador, que **não** é este ciclo.
- **Escopo:** só `register`. `promote`/`update`/`revoke` são costuras futuras (gated).

## 🔗 Referências

- Spec (OP-1..4 + gate FECHADO da plataforma): `onion-m3-federation-admin-spec-2026-07` (core-only) — o desenho command-side da federação no core (core-privado; no adotante não existe)
- Grafo do fio: `docs/onion/graph/m3-federation-admin-2026-07.kg.yaml` (nó `C_op_register`)
- Validação: `.claude/validation/members-validate.sh` · pin: `.claude/validation/pin-integrity-check.sh`
- Precedente comando↔script: `/meta:inventory` ↔ `.claude/validation/inventory.sh`
- **Não** é: `/meta:federation-register` (ledger de **contratos**)
