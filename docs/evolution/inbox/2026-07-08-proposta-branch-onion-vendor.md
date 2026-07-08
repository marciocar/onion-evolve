---
title: 'Proposta: framework numa branch `onion-*` versionada (vendor-branch) em vez de copy-over-working-tree'
date: 2026-07-08
from: maestro (via uso de campo — adoção rhilo-metagamify na KVM 8)
to: onion-evolve (core / "mestre")
re: /meta:adopt --update, durabilidade da instalação vendorizada
type: proposal (co-evolução — feedback de adoção, não-solicitado)
status: aberto — para triagem num /meta:evolve ou revisão do /meta:adopt
---

# Proposta: framework do Onion numa branch `onion-*` versionada

## Motivação (incidente de campo, 2026-07-08)

Ao reativar o Onion no `rhilo-metagamify` (agora na KVM 8), descobriu-se que a instalação do
`/meta:adopt --update` **tinha sumido**: os ~21 arquivos aplicados eram **uncommitted na working
tree** de um feature branch, e um `git checkout`/troca de branch **descartou tudo** — o
`.onion-version` inclusive reverteu pro pin antigo. A instalação durável só sobreviveu porque,
independentemente, alguém a **commitou no `develop`** (branch `chore/onion-resync`).

Raiz: `/meta:adopt --update` hoje **copia arquivos por cima da working tree** (revisão de diff +
`cp`). Isso é frágil por construção — trabalho uncommitted é descartável e invisível a quem troca
de branch.

## A proposta (do maestro)

Ter uma branch dedicada `onion-*` (ex.: `onion/framework`, `onion/vendor`, ou `onion/<versão>`) que
carregue o framework vendorizado + a identidade (`version`, `role: core|source|standalone|consumer`,
`source_commit`). O `--update` viraria um **`git merge`/rebase dessa branch** em vez de copy-over —
durável, ciente de conflito, nunca descartável por acidente.

## Análise (parecer da sessão do core)

- **É um padrão de _vendor branch_** clássico (como subtree/vendoring). Resolve a fragilidade de raiz:
  o framework passa a ser um **objeto git de verdade**, não arquivos soltos na working tree.
- **Update = merge** dá conflito-awareness (customização local do adotante aparece como conflito
  real, não como "diff a revisar" que pode ser clobado). Alinha com a doutrina never-clobber.
- **A identidade já existe** no `.onion-version` (`framework`/`role`/`source_commit`); a branch
  ancoraria isso. Nome da branch poderia espelhar `role`/versão.
- **Caveat crítico (não ignorar):** o Claude Code lê `.claude/` da working tree do branch **atual**.
  Logo a branch `onion-*` **não** é "troco pra ela e uso o Onion" (isso perderia o código de
  produto). Ela é a **fonte canônica de merge**; o framework ainda precisa estar presente na working
  tree do branch de integração (develop/main) pro Onion ser usável no dia a dia. O modelo é
  vendor-branch-como-fonte-de-merge, não branch-que-se-usa-direto.

## Achado de pesquisa (jul/2026): o padrão da comunidade NÃO é vendorizar — é PLUGIN + MARKETPLACE

Pesquisa web 2026 (fontes abaixo): o padrão-comunidade vigente para distribuir capacidades Claude
Code (comandos/agentes/skills/hooks/MCP) por múltiplos repos **não é** vendorizar `.claude/` em cada
repo — é empacotar como **Plugin** (bundle versionado) e distribuir por um **Marketplace** (repo com
`.claude-plugin/marketplace.json`), instalado/atualizado com **um comando**. Há marketplace oficial
da Anthropic + comunitários grandes (tonsofskills.com com CLI `ccpi`, wshobson/agents multi-harness).

**Por que isto é decisivo para a proposta:**
- O plugin **não vai pro git de cada repo** — é instalado/gerenciado como dependência. Isso **elimina
  de raiz** a fragilidade "arquivos uncommitted somem num checkout" (o incidente que originou este
  sinal). Torna a própria discussão vendor-branch parcialmente obsoleta.
- **Plugin ≠ produto público.** Um **marketplace privado é só um repo git** (ex.:
  `marciocar/onion-marketplace`). Satisfaz a restrição canônica do Onion ("não é produto npm, não
  distribuído publicamente" — CLAUDE.md) **E** resolve durabilidade/atualização. O `/meta:adopt`
  viraria "instala/atualiza o plugin" em vez de "copia arquivos por cima da working tree".
- Quando ainda se vendoriza (montar um marketplace de repos separados), o padrão é **git subtree/
  submodule** + `claudeMdExcludes`/`permissions.deny` — subtree é "quando vendoriza", plugin é "como
  distribui".

**Reframe da pergunta para o /meta:evolve:** deslocar de "como vendorizar melhor (vendor-branch)?"
para "por que ainda vendorizar, em vez de empacotar o Onion como plugin com marketplace privado?".
Fontes: code.claude.com/docs/en/plugins · anthropics/claude-plugins-official · support.claude.com
(manage plugins for org) · code.claude.com/docs/en/large-codebases.

## Reconciliação (achado NO PRÓPRIO repo, 2026-07-08) — o Onion JÁ decidiu isto

Exploração do repo revelou que **o Onion não só não rejeitou o plugin — já o adotou para a Camada 1**:
existe `.claude-plugin/marketplace.json` (marketplace privado `onion-evolve`, `pluginRoot: ./plugins`),
dois plugins já publicados (`plugins/onion-design`, `plugins/onion-compliance`, gerados de `.claude/` por
`assemble-plugin.sh` com `provenance.json` content-addressed estilo `gh skill`), e ADRs que traçam a
fronteira: `onion-adr-exchange-unit-2026-06.md` (aceito) e `onion-distribution-strategy-2026-06.md`. A
decisão vigente é um **híbrido de 3 camadas**:

- **Camada 1 (capacidade: `.claude/{commands,agents,skills,hooks,utils,validation}`)** → **plugin +
  marketplace** (já shipado; "supera nosso vendoring").
- **Camada 2 (`docs/{meta-specs,knowledge-base,sdaal}`)** → **NÃO cabe em plugin**: são autoridade
  endereçada por PATH (22/120/4 arquivos em `.claude/` fazem `Glob docs/meta-specs/*.md`, referenciam a
  KB, e o lint hard-coda `docs/sdaal/sdaal.md §7`). Precisam viver na árvore do consumidor → `/meta:adopt`.
- **Camada 3 (variantes/escopos: source/hub/standalone/consumer/distilled + pins/trust/federação/inbox)** →
  o control plane / moat, uniforme-em-plugin ≠ possível. `/meta:adopt` + `members.yaml`.

**Logo, o reframe "por que não virar plugin?" está parcialmente respondido:** a Camada 1 já é plugin.
O que este sinal REALMENTE ataca é a **durabilidade da entrega das Camadas 2+3** — o `/meta:adopt`
copy-over-working-tree que engoliu arquivos uncommitted (o incidente-fonte). Essa parte **não** é coberta
pelo plugin (plugins não carregam docs nem variantes) e continua valendo.

## Ação sugerida ao core (reconciliada)

Avaliar num próximo `/meta:evolve` ou revisão do `/meta:adopt`: migrar a entrega das **Camadas 2+3** de
copy-over-working-tree para **merge de uma branch vendor** (ou, no mínimo, **committar automaticamente**
a instalação num branch dedicado ao fim do `--update`), fechando o gap "uncommitted = descartável". A
Camada 1 já resolvida via plugin/marketplace — não reabrir. Relacionado à família "declarado ≠ verificado".
