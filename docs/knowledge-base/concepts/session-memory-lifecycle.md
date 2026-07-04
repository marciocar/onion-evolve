# Ciclo de Vida da Memória de Sessão (memória como contexto auditável)

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-04 | **Categoria**: Conceitos
> Gramática operacional que trata a **memória persistente do harness** (`~/.claude/projects/<projeto>/memory/`)
> como o **4º contexto auditável** do ecossistema — depois das KBs (`/meta:kb-freshness`), dos contextos de
> domínio (`/meta:context-freshness`) e das migalhas do diário (`review_after` + re-teste por classe).
> Irmã de [domain-context-lifecycle.md](domain-context-lifecycle.md): a mesma tese, noutra camada.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-04 |
| **Última Atualização** | 2026-07-04 |
| **Origem** | Pergunta do maestro ("quando reavaliamos o que está em memória?") + varredura de campo no mesmo dia |
| **Costura executável** | `/meta:evolve` dimensão **D10** (varredura no contexto principal) |

---

## 1. O problema

A memória de sessão do Claude Code persiste fatos entre conversas — quirks de ambiente, preferências
do maestro, estado de trabalhos longos. Ela é **carregada em todo boot** (o índice `MEMORY.md` entra
no contexto) e, diferente de KB e contexto de domínio, **não tinha rito de reavaliação nenhum**.

Memória stale é **pior que ausente**: ela **engana ativamente** (mesma tese do
[domain-context-lifecycle](domain-context-lifecycle.md) — "stale engana ativamente"). Uma sessão que
confia numa memória apodrecida re-executa trabalho entregue, recomenda flag que não existe, ou aplica
workaround de um ambiente que mudou.

**Evidência de campo (2026-07-04):** a primeira varredura sistemática da memória do core encontrou
**1 entrada apodrecida em 6** — a visão de breadcrumbs dizia "pesquisa ampla pendente" quando a
pesquisa já tinha sido entregue, virado enabler no diário e alimentado o Knowledge Graph. Um boot
que a lesse re-pediria uma deep-research inteira já paga.

## 2. As três classes de apodrecimento (e o teste de cada uma)

A taxonomia espelha o `conflict_class` das migalhas do diário — a estrutura de decisão da migalha
generalizando para outra camada:

| Classe | Exemplo | Como apodrece | Teste de validade (barato) |
|---|---|---|---|
| **Fato-de-ambiente** (≈ `dynamic`) | "esta máquina não tem jq" | ambiente muda (install, máquina nova) | 1 comando: `command -v`, `curl`, `ls` |
| **Estado-de-trabalho** (≈ `conditional`) | "pesquisa X pendente", "retomar em Y" | o trabalho conclui e a memória fica para trás | `git log`/`ls` no artefato que o resolveria |
| **Preferência-do-maestro** (≈ `static`) | "auto-merge com rito", "quadro de tasks sempre" | só quando o maestro revoga/ajusta | nenhum automático — **só o maestro invalida**; nunca expirar sozinha |

## 3. Os três gatilhos de reavaliação

1. **Verificar-no-uso (sempre):** antes de **aplicar** uma memória recuperada, testar o fato contra a
   realidade — o arquivo/flag/endpoint que ela cita ainda existe? Doutrina que já existia para memórias
   recuperadas; aqui vira regra de 1ª classe.
2. **Varredura completa a cada rodada de `/meta:evolve` (dimensão D10):** a auto-auditoria do framework
   é também a auditoria da memória da sessão — para cada entrada do `MEMORY.md`, **1 teste barato de
   validade** conforme a classe (tabela §2). Corrigir ou apagar na hora; **nunca re-carimbar sem
   re-testar** (mesma regra da migalha ⏰ do diário). Roda no **contexto principal** (a memória é da
   sessão, não de subagente) e é **no-op gracioso** quando a sessão não tem memória.
3. **Apagar-quando-cumprida:** memória de estado/retomada (`resume-*`) morre no fim do trabalho; fato
   que o repo passou a registrar (ADR, KB, README, git) **vira ponteiro ou morre**.

## 4. O princípio: repo é fonte, memória é cache

A memória **nunca** é SSOT de nada que o repo saiba registrar. Ela guarda o que o repo **não pode**
saber: quirks da máquina do maestro, preferências de trabalho, estado efêmero entre sessões. Todo o
resto deve ser **ponteiro** para a fonte canônica — e quando a fonte nasce (a doutrina vira KB, o
estado vira PR mergeado), a memória correspondente **encolhe para ponteiro ou é apagada**.

Corolário anti-drift: uma memória que *repete* conteúdo do repo está errada por construção — na
primeira divergência, o leitor não sabe em quem acreditar.

## 5. Forma recomendada da entrada

O harness já impõe frontmatter (`name`, `description`, `metadata.type`). Para auditabilidade:

- **`description`** carrega o estado que o índice mostra no boot — é ela que apodrece primeiro;
  atualizá-la é parte da correção (o `MEMORY.md` é o que toda sessão lê).
- **Corpo** com `**Why:**` e `**How to apply:**` (padrão existente) + **datas absolutas** (nunca
  "semana passada") + **ponteiros** aos artefatos canônicos.
- **Linha do índice** da entrada de rito registra a última varredura:
  `(última varredura: AAAA-MM-DD, N rot em M)` — o carimbo de frescor da memória inteira.

## 6. Escopo e portabilidade

- Vale para **qualquer instância** (core e adotados): toda sessão Claude Code tem o mesmo mecanismo
  de memória do harness; adotantes herdam a doutrina por esta KB (chega via `/meta:adopt --update`).
- A varredura D10 audita a memória **da sessão que roda o evolve** — cada sessão/maestro cuida da sua
  (a memória é por-usuário-por-projeto; não há memória "central" a auditar remotamente).
- **Privacidade:** a memória pode conter contexto pessoal do maestro; a varredura **reporta contagens
  e vereditos** (N rot em M), nunca cola conteúdo de memória em relatório commitado sem necessidade.

## 7. Relações

- [domain-context-lifecycle.md](domain-context-lifecycle.md) — a tese-mãe ("stale engana ativamente"; fase Manage)
- `.claude/commands/meta/diary.md` — `conflict_class`/`valid_when` + re-teste por classe (a taxonomia §2 é a mesma estrutura noutra camada)
- `.claude/commands/meta/evolve.md` — dimensão **D10** (costura executável desta doutrina)
- [knowledge-graph-sdaal.md](knowledge-graph-sdaal.md) — quando a investigação é longa, o estado vai para `.kg.yaml` (auditável pelo radar), não para a memória
