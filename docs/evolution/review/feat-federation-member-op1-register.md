---
title: "Revisão — OP-1 REGISTRAR (/meta:federation-member register)"
date: 2026-08-27
branch: feat/federation-member-op1-register
reviewer: "passada adversarial (branch-code-reviewer) + triagem/verificação do autor + dogfood do validador"
reviewed_diff_sha256: c1e73b8b1257626d54ea40264c049ddc5cfcb08655e24824a7dc12f9f3e65aca
findings_total: 5
findings_real: 5
verdict: APROVADO-COM-RESSALVAS-ENDERECADAS
tokens: 75755
duration_min: 7
---

# Resíduo — REGRA 56 (OP-1 REGISTRAR da federação)

Fatia de-gated do fio `m3-federation-admin`: o command-side **OP-1 REGISTRAR**
(`/meta:federation-member register`) + o validador determinístico `members-validate.sh` (par 6a) +
5 fixtures no selftest + a fricção do `/meta:adopt` virando mecanismo. Gate da plataforma admin
segue **FECHADO** e intocado (`Q_gatilho`: 0 `role:consumer`, `contracts/` inexistente).

## Método — passada adversarial + verificação, não só spec

A revisão foi um `branch-code-reviewer` instruído a **quebrar**, não aprovar, com foco no código
executável (`members-validate.sh`) e na coerência comando↔validador↔scripts. O revisor rodou 9 modos
de falha adversariais pelo validador e verificou as interfaces citadas ao vivo. Cada achado foi
tratado como **hipótese** e re-verificado pelo autor antes de agir (o M1 foi reproduzido ao vivo
antes e depois da cura).

## Achados (5 reais, 0 HARD)

### 🟡 M1 — false-green de pin via `role:source` (o mais grave) — CORRIGIDO
A isenção de parent/pin/trust era só por `role == "source"`. **Reproduzido ao vivo:** um membro
`role:source` + `kind:adopter` **sem pin** retornava `valid:true`. Numa edição manual do `members.yaml`
(o cenário que o validador existe p/ proteger), trocar `role:standalone` por `role:source` num adopter
evaporava o requisito de pin VERIFICADO — o exato false-green de pin que o design cita (incidente de
pin forjado 2026-06-30). **Cura:** isenção pela NATUREZA (`kind:source`) + invariante
`role:source ⇔ kind:source`. Dogfood da cura: 5ª fixture `members-bad-fake-source.yaml` (fail).

### 🟡 M2 — o validador não é gate HARD do lint sobre o arquivo VIVO — NOMEADO (não expandido)
`members-validate.sh` roda na rota do comando (Passo 7) e no selftest sobre fixtures, mas **não** gateia
o `members.yaml` vivo no `lint-artifacts.sh` — uma edição manual com erro semântico-mas-parseável (id
dup, trust faltando, pin `n/a` em adopter) passaria no CI, enquanto o header prometia "barra ANTES do
commit". **Decisão (pull-not-push):** não expando este PR com regra nova; (a) suavizei o header p/ casar
com o que está de fato ligado (behavior-over-declaration) e (b) abri `Q_members_ci_gate` no grafo
(`open`, gatilho nomeado: 1ª mutação manual que o CI deixe passar OU nascimento de OP-2/3/4). Fio
preservado, não órfão.

### 🟢 N1 — invariante "exatamente uma fonte" — CORRIGIDO
Dois `kind:source` passavam. Adicionada a checagem `n_sources == 1` (fonte≠derivação).

### 🟢 N2 — ordenação Passo 5/6 do comando — CORRIGIDO
Passo 5 dizia "após escrever" mas vinha antes do passo de escrever. Virou "forma do `name` antes de
escrever" + confirmação `projection-safety.sh` no novo Passo 8b (pós-escrita).

### 🟢 N3 — header do validador não distinguia obrigatório × opcional — CORRIGIDO
Header agora lista os obrigatórios por membro derivado e os opcionais (`remote`, `local_path`, `a2a`…).

## Observações positivas (do revisor)
- Modos de falha exaustivamente cobertos, exit-codes 0/1/2/3 corretos; `exit 3` gracioso (python+yaml
  ausente) espelha o padrão do repo; `run_members_fixture` não deixa rc=2/rc=3 passar como `fail`.
- `--json` válido inclusive no caminho de erro de parse; `GIT_DIR`/`GIT_WORK_TREE` neutralizados.
- Coerência comando↔scripts verificada: `pin-integrity-check <source_root> <target_root>`, `graph.sh
  --map`, saídas `pin-ok`/`pin-untrusted` — todas batem; os 7 scripts citados existem.

## Verificação pós-cura (medida)
- `members-validate.sh` → `valid:true` no `members.yaml` vivo (13 membros); M1 repro agora **falha** com
  a invariante nomeada.
- 5 fixtures verdes no `lint-selftest` (good→pass; no-role/dup-id/missing-pin/fake-source→fail).
- `lint-artifacts.sh` → 0 HARD (só este resíduo faltava) · `kg-radar` do grafo exit 0 ·
  `C_op_register` → `done`, fora da fila; `Q_gatilho` intocado.

## Veredito
**APROVADO com as ressalvas endereçadas.** Nenhum HARD; o achado de maior valor (M1) era um false-green
real de pin, medido e fechado com teste que o dogfooda. M2 fica como fio nomeado com gatilho, não órfão.
