---
title: "Handoff — reativação da adoção Onion no Arandek (Fase 2)"
date: 2026-06-19
type: adoption-reactivation-handoff
authored-in: onion-evolve (core) — sessão de reconciliação de federação
for-session: sessão dedicada targeting /home/marciocar/arandek (um-escritor-por-repo)
relates:
  - ./onion-coevolution-backlog-2026-06-18.md (item #1)
  - ../evolution/inbox/_processed/2026-06-18-adopt-gitflow-develop-branch-config.md (sinal #1)
  - ../evolution/federation/members.yaml
---

# Handoff — reativar o Arandek (Fase 2)

> Doc-bridge core → sessão do Arandek. A diligência (read-only) já foi feita daqui; **não re-descubra**,
> aja a partir daqui. O core **não** escreveu no Arandek (um-escritor-por-repo). Abra uma sessão no
> `/home/marciocar/arandek` (ou no worktree) e conduza com o maestro presente — há **3 decisões de
> topologia** que só ele toma.

## Estado verificado do Arandek (2026-06-19)

- **Projeto ativo e real** (org `ArandekBR`; workflow-engine v2, logto SaaS multi-tenant, RAG/AI). Várias
  feature branches vivas. Branch dev atual: `feature/logto-saas-multi-tenancy-white-label`.
- **Adoção Onion INTACTA, porém isolada num worktree:** `/home/marciocar/onion-adopt-arandek`
  (branch `onion/adopt`, `18854f7f`) tem `.claude/` + `.onion-version` + `docs/evolution/`. **Nada se
  perdeu** — só nunca foi integrado ao mainline.
  - Stamp atual: `source_commit: 91439b65261d` · `2026-06-18` · `role: adopted` · `mode: legacy`.
- **Branch dev atual SEM Onion:** `.claude/` ausente no working tree de `feature/logto-...`.
- ⚠️ **`origin/arandek-evolve` existe** mas aponta para `9747cb4c` (**2026-06-12**, "Merge PR #172
  rework/workflow-engine-v2") — hoje carrega **história de produto**, anterior à adoção (06-18). O sinal #1
  *pretendia* `arandek-evolve` como alvo dos PRs de evolução Onion; o estado real precisa ser reconciliado.
- ⚠️ **Remotes duplos:** `origin` → `arandek.git` e `metagamify` → `metagamify.git`. O Arandek compartilha
  história com o metagamify (`main`: ahead 17 / behind 6 vs `metagamify/main`).
- **Não está no `members.yaml`** do core (a entrada entra na Fase 2, com o pin REAL pós-update).
- Defasagem: pin `91439b65` (06-18) vs HEAD do core hoje (`dad815e`, pós-#106).

## As 3 decisões de topologia (maestro, no início da sessão)

1. **Onde o Onion vive em definitivo?** A adoção está parada em `onion/adopt` (worktree). Opções:
   mergear `onion/adopt` → `main` (Onion no mainline) · manter como branch/worktree de evolução separada ·
   reintegrar via a branch de integração escolhida (decisão 2). Define como o `.claude/` chega ao fluxo diário.
2. **A branch de integração do Onion.** O sinal #1 quis `arandek-evolve` como alvo dos PRs de evolução,
   mas `origin/arandek-evolve` hoje tem história de produto (06-12). Decidir: **reconciliar/reusar**
   `arandek-evolve` como o alvo Onion (e o que fazer com a história de produto que está nela), **ou** usar
   um nome limpo (ex. `onion/integration`). O nome escolhido vira o `--integration-branch` (passo 3).
3. **Qual remote é o alvo do PR?** Com `origin` + `metagamify`, confirmar para qual o `/engineer:pr` abre
   PR de evolução (provável `origin`). Isso orienta o forge adapter no Arandek.

## Passos (após as decisões)

1. **Sessão no Arandek + `git fetch`** (outra instância pode ter mexido — ver lição stale-branch). Confirmar
   o estado das branches/worktree.
2. **`/meta:adopt --update /home/marciocar/arandek --integration-branch <nome-da-decisão-2>`** rodado da
   FONTE (`onion-evolve`) targeting o path. Traz o delta do framework (inclui a própria feature
   `--integration-branch`, #104) + o **Procedimento de Configuração pós-cópia** (merge never-clobber dos
   hooks no `settings.json` + starter `docs/evolution/`). O passo (3) do Procedimento seta
   `git config gitflow.branch.{develop,master}` local; o durável é o campo `integration_branch` no stamp.
3. **Postura legacy:** garantir `.claude/` **gitignorado** mas **`.onion-version` versionado** (lição
   adopt-gitignore-claude-dir) — senão o pin/`integration_branch` não viaja entre máquinas.
4. **Aterrissar** conforme a decisão 1 (mergear `onion/adopt` ou reintegrar via a branch de integração).
5. **Voltar ao core (edição no `onion-evolve`, branch+PR):** adicionar o Arandek ao `members.yaml` com o
   **pin REAL pós-update** + anúncio no `CHANGELOG` se aplicável. (Registro nunca vai à frente da realidade.)

## Verificação (na sessão do Arandek)

- `bash .claude/validation/resolve-integration-branch.sh` (no Arandek) retorna a branch de integração escolhida.
- `docs/evolution/inbox/` existe; o hook SessionStart "you have mail" está registrado no `settings.json`
  (merge, sem clobbar o que o Arandek já tiver); `/meta:co-evolve` detecta `role: adopted`.
- `.onion-version` versionado com o novo `source_commit` + `integration_branch`.
- O core (`members.yaml`) reflete o Arandek com o pin real.

## Invariantes

- **Um-escritor-por-repo:** commits do Arandek são escrita no repo do Arandek; logue no handoff quem fez.
- **Não bundlar** a edição do `members.yaml`/`CHANGELOG` (core) com os commits do Arandek — PRs separados,
  em repos separados.
- **Federação formal permanece inativa** — reativar o Arandek não dispara o gatilho de graduação
  (sem contrato breaking; <5 projetos).
