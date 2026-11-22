---
title: "Proposta: /product:extract-meeting com saída de backlog por área (card SAC-480)"
date: 2026-11-21
from: onion-curation
to: onion-evolve (core)
type: doctrine-proposal
family: pratica
request: "Core → curadoria (2026-11-21): montar a proposta do /product:extract-meeting com saída de backlog por área — medir como o comando sai hoje, o padrão de mercado de ata→backlog (action items por responsável e área) e o texto proposto. Sinal pelo co-relay."
reviewed_for_public: true  # relido pelo core em 2026-11-22 como publicado: só a forma do comando, ids e fontes públicas de mercado, sem cliente, pessoa nem segredo
---

# Proposta — /product:extract-meeting com saída de backlog por área

A curadoria **propõe**; o core sela. Nada aqui é selado. O comando é vendorizado (vive em
`.claude/commands/product/extract-meeting.md`, medido na cópia da curadoria, v3.1.0); a **fonte é o
core**, então a mudança é dele.

## 1. Como o comando sai hoje (medido)

- Gera **dois artefatos** em `docs/meetings/`: `<nome>-extract.md` (resumo EXTRACT, níveis
  compact/executive/complete/graph) e `<nome>.kg.yaml` (grafo da reunião).
- As **tarefas** (dimensão T do EXTRACT) saem **planas, por responsável** — a tabela do nível executive é
  `| Responsável | Ação | Prazo |` (`.claude/commands/product/extract-meeting.md:152-154`).
- No grafo, cada `A_<ACAO>` carrega `x_owner` + `x_due` (opcional), **mas nenhuma área**
  (`extract-meeting.md:234-238`); os riscos `R_<RISCO>` idem.
- **Não há saída de backlog por área.** Não há `docs/backlog.md` na curadoria; o caminho para um backlog
  hoje é manual, "criar tasks no gerenciador (`@task-specialist`)" (`extract-meeting.md:387`).
- O grafo é o SSOT; o `.md` é projeção. O gate `meeting-graph-check.sh` já exige `x_meeting_role` em todo
  nó e um vocabulário `x_` **fechado**.

**A lacuna:** a ata vira tarefas por pessoa, mas não vira um **backlog organizado por área**; quem quer
ver "o que sobra em cada frente" tem de reagrupar à mão.

## 2. O padrão de mercado (fonte primária)

- **Item de ação = dono + prazo + verbo ativo + contexto bastante para começar**; 2–3 por pessoa; itens
  grandes levam marcos, não só prazo final; **o não resolvido transita para a próxima revisão, não
  some** (carry-over).
  — https://www.atlassian.com/work-management/project-collaboration/team-meetings/action-items
  — https://miro.com/templates/meeting-action-items/
- **Backlog agrupado por área = swimlane/épico/componente/tema** nos trackers. Restrição técnica
  importante: o agrupamento por swimlane só funciona com **campo de valor único** — "Components" com
  vários valores quebra o agrupamento; a saída é um campo de valor único ou o épico. Agrupamento em dois
  níveis (tema → épico) existe (Nimble).
  — https://jira.atlassian.com/browse/JSWCLOUD-17580
  — https://community.atlassian.com/t5/Jira-questions/why-is-components-not-approprirate-to-group-issues-in-an-agile/qaq-p/2689249
- **Mapa para o Onion:** owner + prazo já existem; falta a **área como campo de valor único** (a
  swimlane) e a **projeção do backlog agrupada por ela**, mantendo o carry-over do que fica aberto.

## 3. Texto proposto

> ### Saída de backlog por área no /product:extract-meeting
>
> **A. Campo `x_area` nos nós de ação e risco (valor único, vocabulário fechado).** Todo `A_<ACAO>` e
> `R_<RISCO>` do grafo da reunião ganha **`x_area`**, **um só valor** (a lição da swimlane: campo
> multivalor quebra o agrupamento), de um **vocabulário fechado declarado pelo repo**. Default proposto
> (o repo pode estreitar): `produto · tecnico · negocio · compliance · design · operacoes · pesquisa`.
> Área que ninguém nomeia = **`NAO_ESPECIFICADO`** (nunca inventar), e isso vira item a triar, não um
> item perdido.
>
> **B. Artefato novo `docs/meetings/<nome>-backlog.md`, projeção do grafo (SSOT).** Um `level=backlog`
> (ou `focus=backlog`) gera, **a partir do grafo** (nunca à mão), o backlog agrupado **por área**:
> uma seção por área, e dentro dela cada ação/risco aberto como
> `- [ ] <ação com verbo ativo> — dono: <owner|NAO_ESPECIFICADO> — prazo: <due|—>`.
> Os riscos entram marcados (`⚠️`). **Carry-over:** o item fica no backlog enquanto o nó está `open`; some
> só quando o nó fecha com motivo. A seção `NAO_ESPECIFICADO` vem primeiro (é o que precisa de triagem).
>
> **C. Duas vistas, um SSOT.** O backlog agrupa por **área** (a swimlane); a tabela por **responsável**
> segue existindo (`extract-meeting.md:152`). As duas são projeções do mesmo grafo — owner, prazo e área
> convivem no nó, e nenhuma vista é fonte da verdade.
>
> **D. Gate — a projeção não mente.** O `meeting-graph-check.sh` passa a exigir que todo `A_`/`R_`
> tenha `x_area` com **um** valor do vocabulário fechado (senão reprova, como já faz com o `x_`
> fechado). Assim o backlog projetado **nunca descarta um item em silêncio** (lição do "SSOT que mente"):
> item sem área não desaparece, aparece em `NAO_ESPECIFICADO` ou reprova o grafo.

## 4. Veredito e o que o core decide

**Veredito proposto: `costurar`.** Estende o comando e o grafo que já existem com **um campo** (`x_area`,
valor único), **uma projeção** (`<nome>-backlog.md`, no padrão de projeção do `docs/backlog.md`) e **um
check** no gate que já roda — reusando o vocabulário `x_` fechado e o SSOT→projeção. Não é `absorver` (sem
mecanismo novo), nem `rejeitar`/`parquear`.

**A decisão que fica para o maestro/core:** o **vocabulário de áreas** (a lista fechada por repo) — é o
único ponto que não deriva; proponho o default da cláusula A, a ajustar por repo. *Onde vive:* o comando
`extract-meeting.md` (nível/foco `backlog` + passo de projeção), o esquema do grafo (`x_area`) e o
`meeting-graph-check.sh` (o check) — tudo no core, que é a fonte do comando vendorizado.

*O que o core sela:* o texto, o vocabulário de áreas e o lugar. Se quiser, registro no corpus da
curadoria (`.kg.yaml` + PR); como foi pedida como sinal, entrego assim.

---

Orquestrado com 🧅 Onion Evolve
