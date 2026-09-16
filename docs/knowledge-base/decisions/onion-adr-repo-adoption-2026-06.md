---
title: "ADR — Adoção de repositório: comando in-platform, não CLI"
date: 2026-06-16
type: adr
status: accepted
decision-scope: adoption / installability
supersedes: none
related:
  - ../meta-specs/architecture.md
  - (doutrina de adoção — core-only)
  - ../knowledge-base/concepts/multi-repo-federation.md
  - onion-federation-adr-a2a-format-interop-2026-06 (core-only)
---

# ADR — Adoção de repositório: comando in-platform, não CLI

| Campo | Valor |
|-------|-------|
| **Decisão** | A capacidade "apontar o Onion para uma pasta/repo e assumir o controle" se realiza como **comando faseado in-platform** (`/meta:adopt`), **nunca** como CLI standalone. Suporta dois modelos de controle (instalar / operar in-place) + isolamento opcional em worktree. |
| **Escopo** | Adoção/instalação do framework em projeto-alvo. Reafirma `architecture.md §3/§5/§7` num contexto novo; introduz um pré-requisito (stamp de versão). |
| **Status** | ✅ **Aceito (doutrinário)** em 2026-06-16. Define a *forma*; o comando `/meta:adopt` é o **próximo artefato** (não diferido por gatilho — sequenciado). |
| **Origem** | Pergunta de design (2026-06-16): "o que precisamos para o Onion receber um caminho e assumir o controle?". |

---

## Status

✅ **Aceito (doutrinário)** — 2026-06-16. Nenhum código construído ainda. O que se decide **agora** é a
*forma* da capacidade (comando, não CLI) e seus pré-requisitos — para que a construção do `/meta:adopt`
não reintroduza um invariante abandonado nem ignore o stamp de versão ausente.

---

## Contexto

### A tensão: "assumir controle" ≠ CLF abandonado

A leitura ingênua de "receber um caminho e assumir o controle" é um **CLI standalone**
(`onion adopt /path`). Isso **viola** `architecture.md §5/§7`: *"Não há CLI standalone — `onion
init/add/migrate` foram abandonados em 2026-05-18"*. O Onion **não é** binário que alcança pastas
externas; ele **roda dentro do Claude Code, num working directory**.

### O que "controle" significa de fato (dois modelos)

Não existe daemon controlando paths externos. Controle = uma de duas coisas:

| Modelo | Mecânica | Durabilidade |
|---|---|---|
| **Instalar** | Copia o framework (`.claude/` + skeleton de `docs/` + `CLAUDE.md` + `.env`) **para dentro** do alvo → vira **Onion soberano** que se auto-orquestra | permanente |
| **Operar in-place** | Monta o caminho como **additional working directory** do Claude Code e opera com agentes/comandos Onion **sem instalar nada** lá | efêmero |

### Prior art (não se parte do zero)

- **`/docs:reverse-consolidate`** já recebe um parâmetro `project_path` e faz engenharia reversa do
  stack — **o tijolo que já aceita caminho**.
- **`docs/applying/{greenfield,legacy,regulated}.md`** — a doutrina de adoção **já escrita**, porém
  como **prosa que um humano segue**, não como atuador executável.
- **`architecture.md §3`** — instalável "copiando ou clonando `.claude/` e `docs/`, sem paths
  absolutos". O `/meta:adopt` **automatiza** esse passo manual; não muda a §3.
- **Federação** (`multi-repo-federation.md`) — coordena repos **soberanos**. A adoção é **a rampa de
  entrada que falta**: como um repo *vira* membro soberano.

### O gap

Não há **um comando que execute a adoção fim-a-fim**. O conhecimento existe (doutrina +
`reverse-consolidate` + `setup-integration` + `build-*-docs`), mas ninguém os costura num fluxo
faseado retomável. **Pré-condição:** `/meta:adopt` roda a partir de uma sessão Claude Code que já
tem o framework Onion (a *fonte*); o alvo é o argumento `<path|git-url>`.

---

## Decisão

1. **Comando faseado in-platform, não CLI.** A capacidade é `/meta:adopt <path|git-url>` — comando do
   Claude Code, faseado e **retomável** (invariante de workflow faseado), que **orquestra atuadores
   existentes**. Reafirma o invariante anti-CLI no contexto de adoção.

2. **Dois modelos de controle + isolamento.** Suporta **instalar** (durável) e **operar in-place**
   (efêmero, via additional working directory), com **worktree/branch** como camada de segurança para
   legado/regulado. Progressivo: pode-se operar-in-place primeiro e instalar depois.

3. **Modo = trindade `applying/`.** Detecta/pergunta o cenário e mapeia em `greenfield` (scaffold) ·
   `legacy` (reverse-eng pesado, migração gradual) · `regulated` (+ compliance-context/agents).

4. **Stamp de versão do framework (pré-requisito novo).** Introduz um arquivo de proveniência
   `.claude/.onion-version` no alvo (`{source_ref, commit, adopted_at, mode}`) — registra de **qual**
   Onion o repo foi adotado, **sem** impor semver formal ao framework (preserva `architecture.md
   §6.1`). Necessário para (a) update/sync futuro de repos adotados e (b) a federação saber a versão
   de cada membro. *(Adicionar um arquivo — não diretório — não fere `§7`; merece nota em `§1.2`.)*

5. **Reusar, não reimplementar.** `/docs:reverse-consolidate` (stack) · `/meta:setup-integration`
   (.env) · `/docs:build-{business,tech,compliance}-docs` (contextos) · `@metaspec-gate-keeper`
   **dual-mode** (valida o alvo como **L1+**, não como L0 framework). Nada de lógica duplicada.

6. **Segurança e consentimento por contrato.** Operação de **alto impacto** (escreve em repo alheio):
   **dry-run/preview** obrigatório, operar em **branch/worktree**, **nunca clobrar** sem diff,
   confirmação explícita. Re-adoção é **idempotente** (atualiza, não sobrescreve).

7. **Adoção é a rampa da federação.** Um repo adotado é candidato a **membro soberano**. O stamp de
   versão (decisão 4) conecta os dois arcos.

---

## Alternativas consideradas

- **A — CLI standalone (`onion adopt`) ❌.** *Pró:* familiar. *Contra:* **viola `architecture.md §5/§7`**
  (abandonado em 2026-05-18); recria a expectativa de produto/binário que o Onion não é. Rejeitada.
- **B — Comando faseado in-platform ✅ ESCOLHIDA.** *Pró:* coerente com a plataforma única; reusa a
  orquestração; retomável. *Contra:* exige sessão Claude Code com o framework à mão (não é "double-click").
- **C — Operar in-place (additional working dir) ✅ (complementar).** *Pró:* rampa leve, zero
  instalação, ótimo para análise one-off. *Contra:* não "Onion-iza" o repo (controle efêmero). Adotada
  como **modo**, não como substituto de B.
- **D — Adoção isolada em worktree/branch ✅ (camada de segurança sobre B).** *Pró:* não clobra o alvo;
  ideal para legado/regulado. *Contra:* custo de setup. Adotada como **safety layer**, não default.

---

## Consequências

### Positivas
- **Operacionaliza a doutrina `applying/`** (prosa → atuador) sem violar a constituição.
- **Completa o arco** adoção → projeto soberano → federação.
- **Reuso máximo** dos atuadores existentes; superfície nova mínima (comando + manifesto + stamp).
- Força a resolver o **stamp de versão** — lacuna que já incomodava a federação.

### Negativas / trade-offs
- **Alto impacto inerente:** escrever em repo alheio exige a disciplina de segurança (decisão 6) — se
  relaxada, vira ferramenta perigosa.
- **Pré-condição de ambiente:** só roda dentro de uma sessão Claude Code com o framework — não atende
  quem espera um instalador "fora" do Claude Code (por design).
- **Stamp de versão** adiciona um artefato e uma nota a `architecture.md §1.2/§6.1` (mudança pequena,
  mas é mudança de constituição).

---

## Pré-requisitos / tijolos (o que construir, em ordem)

1. **`.claude/.onion-version`** (stamp) + nota em `architecture.md §1.2/§6.1`. — *fundação*
2. **Manifesto da superfície instalável** — o que copia para o alvo (agents/commands/skills/utils +
   skeletons de `docs/`), respeitando `§3` (zero path absoluto). — *fundação*
3. **`/meta:adopt` faseado** (greenfield-first): `detectar/clonar → reverse-consolidate → instalar
   (manifesto) → scaffold contextos → setup-integration → gerar CLAUDE.md do alvo → relatório`. — *MVP*
4. **Modos legacy/regulated** + safety em worktree/branch + idempotência. — *iteração 2*
5. **Caminho de update** (puxar versões novas do framework para repos adotados) — encosta na federação. — *iteração 3*

---

## Próximo passo

Scopar o **`/meta:adopt` greenfield-first** (tijolo 3), precedido pelo stamp (tijolo 1) — o menor
incremento que entrega valor real reusando `reverse-consolidate` + `setup-integration`.

---

## Referências

- [`architecture.md`](../../meta-specs/architecture.md) — §3 instalável · §5/§7 anti-CLI · §6.1 versionamento
- a doutrina de adoção (`applying/`, core-only) — doutrina de adoção (prosa que o comando operacionaliza)
- [`multi-repo-federation.md`](../../knowledge-base/concepts/multi-repo-federation.md) — federação (arco a jusante)
- `onion-federation-adr-a2a-format-interop-2026-06.md` (core-only) — ADR irmão (mesmo padrão)
- `/docs:reverse-consolidate` · `/meta:setup-integration` · `/docs:build-*-docs` — atuadores reusados

---

**Mantido por:** Sistema Onion · **Última atualização:** 2026-06-16
