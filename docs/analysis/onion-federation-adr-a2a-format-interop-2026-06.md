---
title: "ADR — A2A como projeção de formato, não runtime"
date: 2026-06-15
type: adr
status: accepted
decision-scope: federation
supersedes: none
related:
  - ../knowledge-base/concepts/multi-repo-federation.md
  - onion-federation-review-2026-06.md
  - onion-federation-design-v2-2026-06.md
  - ../knowledge-base/frameworks/agent-orchestration-landscape-2026.md
---

# ADR — A2A como projeção de formato (não runtime)

| Campo | Valor |
|-------|-------|
| **Decisão** | Partir a linha vermelha "A2A abandonado" em duas: **runtime A2A** permanece proibido; **formato/vocabulário A2A (Agent Card) como projeção one-way** passa a ser **permitido em princípio**, com implementação **diferida** até gatilho. |
| **Escopo** | Federação multi-repo do Onion (`multi-repo-federation.md`). Não toca produto/engenharia/compliance. |
| **Status** | ✅ **Aceito (doutrinário)** em 2026-06-15. **Nenhum código** muda agora — ver [Gatilho](#gatilho-de-implementação). |
| **Origem** | Ressalva §4 de [`onion-federation-review-2026-06.md`](onion-federation-review-2026-06.md), afiada nesta ADR. |

---

## Status

✅ **Aceito (doutrinário)** — 2026-06-15.
Implementação **diferida** (export-only projection não construído). O que foi decidido **agora** é a
*permissão*: a doutrina deixa de tratar A2A como monólito a rejeitar. O *fazer* espera o gatilho.

---

## Contexto

### As duas "federações"

A indústria usa a mesma palavra para coisas diferentes (review §1):

| | **A2A (indústria)** | **Federação do Onion** |
|---|---|---|
| O que federa | Agentes vivos de vendors distintos | Repositórios soberanos |
| Meio | HTTP/SSE/JSON-RPC, Agent Cards, runtime | **Git assíncrono** (ledger versionado) |
| Quem decide | Agente cliente orquestra | **Humano = maestro** |
| Unidade de verdade | Capability / Agent Card | **Contrato spec-as-code (semver)** |

A doutrina vigente (`multi-repo-federation.md §7`) registra A2A como **monólito abandonado**:
*"Instâncias vivas A2A / runtime distribuído — Fase 5 ABANDONADA … nunca IA-fala-IA em tempo real"*.

### O problema com "monólito a rejeitar"

A2A (jun/2026, sob Linux Foundation, 150+ orgs) **não é só runtime vivo**. Ele padroniza também a
**semântica de descoberta de capacidade** (o Agent Card). Tratar o protocolo inteiro como linha vermelha
confunde duas camadas separáveis:

- a camada de **transporte/runtime** (endpoint vivo, IA-fala-IA) — **incompatível** com a filosofia
  git-async do Onion, e legitimamente rejeitada;
- a camada de **formato/descoberta** (Agent Card como serialização) — **compatível** com git-async,
  porque um Agent Card é só um documento; nada nele exige conexão viva.

### Achado que afia a ressalva original

A review dizia que o Agent Card é "irmão do par `members.yaml` + `contracts/`". O mapeamento campo-a-campo
(abaixo) mostra que isso **mistura duas camadas**. A conclusão correta:

> **O Agent Card é irmão do `members.yaml` (manifesto/descoberta), NÃO dos `contracts/`.**
> Os `contracts/` — direcionalidade `producer→consumers`, semver-como-protocolo-de-breaking,
> `tests` + `fixtures` comportamentais — **são exatamente o que o A2A não tem**. São o diferencial do
> Onion, não algo a "traduzir para A2A".

Isso **redireciona** (e fortalece) a ideia: a projeção de formato aplica-se **só à camada de manifesto**,
deixando os contratos 100% nativos. Camadas limpas, não um blob.

---

## Decisão

Partir a linha vermelha da federação em duas regras independentes:

1. 🔴 **Runtime A2A permanece proibido (linha vermelha, inegociável).** Sem endpoint vivo, sem
   client↔remote agent, **nunca IA-fala-IA em tempo real**. A federação é assíncrona via git + forge.
   (Mantém a Fase 5 ABANDONADA — design §2.)

2. 🟢 **Formato/vocabulário A2A é permitido como projeção one-way (export-only).** O Onion pode
   **exportar** a camada de manifesto (`members.yaml`) num formato Agent Card-compatível, num path
   `.well-known/` do ledger, para que um leitor A2A (ou repo não-Onion) consiga **ler** a federação.
   O modelo interno permanece nativo; o Agent Card é uma **projeção**, não a fonte de verdade.
   Os `contracts/` **não** são projetados (o Agent Card não os cobre).

Direção (não invariante): **interop de *formato*, nunca de *runtime*.**

---

## Evidência — mapeamento Agent Card → Onion

Campos canônicos do A2A Agent Card (ver [caveat de frescor](#caveat-de-frescor)) contra o modelo do Onion:

| Campo do Agent Card | Propósito | Equivalente no Onion | Veredito |
|---|---|---|---|
| `name`, `description` | identidade | `members[].name` (+ `description` a adicionar) | ✅ limpo |
| `version` | versão | string solta | ⚠️ A2A não tem semver-como-protocolo-de-breaking |
| `provider` | organização | `members[].remote` | ~ frouxo |
| `skills[]` (id, name, tags, examples) | capacidades unilaterais | — | ⚠️ irmão do *conceito*, não dos contratos |
| `url` | endpoint runtime | — | ❌ sem sentido em git-async |
| `capabilities` (streaming, push) | features de runtime | — | ❌ runtime-only |
| `defaultInput/OutputModes` | content-types | — | ❌ runtime-only |
| `securitySchemes` / `authentication` | auth de runtime | — | ❌ runtime-only |
| `documentationUrl` | docs | link p/ KB/contrato | ~ mapeável |
| **`producer` / `consumers` (direcionalidade)** | — | `contracts/<id>.md` | **A2A não tem** |
| **`tests` + `fixtures` (gate comportamental)** | — | `contracts/<id>.md` | **A2A não tem** |

**Leitura:** ~metade do Agent Card é runtime-only e morre no git-async; a metade que mapeia cai no
`members.yaml`; os tesouros do contrato Onion não têm equivalente A2A. Logo, qualquer projeção é
**parcial e unidirecional** (Onion → Agent Card), restrita ao manifesto.

---

## Alternativas consideradas

- **A — Projeção export-only (one-way) ✅ ESCOLHIDA.** Emite Agent Card a partir do `members.yaml`;
  interno permanece nativo. *Prós:* reversível, zero acoplamento do modelo interno ao churn do A2A,
  destrava optionality. *Contras:* projeção parcial; exige tracking do spec A2A só no momento de exportar.
- **B — Adotar Agent Card como schema nativo do `members.yaml` ❌.** *Prós:* interop "de graça".
  *Contras:* acopla o modelo interno a um spec em evolução; campos esparsos/sem sentido (url, auth);
  pressiona a contaminar os `contracts/` com semântica A2A que eles não precisam. Rejeitada.
- **C — Status quo: rejeitar A2A inteiro ❌.** *Prós:* simplicidade. *Contras:* mantém a confusão
  doutrinária; faz o Onion parecer "atrasado" para leitor técnico de jun/2026 (review §3b/§5). Rejeitada.
- **D — Runtime A2A completo ❌.** Fora de escopo — é a linha vermelha mantida. Traz os riscos que o
  landscape marca como *não resolvidos por ninguém* (injeção cross-agent, exfiltração via tool-call,
  reprodutibilidade regulada — `agent-orchestration-landscape-2026.md`). Rejeitada.

---

## Consequências

### Positivas
- **Doutrina honesta:** o Onion deixa de "rejeitar A2A por inteiro" e passa a *posicionar a divergência*
  (runtime não; formato sim) — vira munição para `docs/materials/critical-article-outline.md`.
- **Optionality sem comprometimento:** se A2A virar lingua franca, a projeção export-only já está
  doutrinariamente liberada; basta implementar.
- **Diferencial preservado e nomeado:** fica explícito que `contracts/` (semver + tests + fixtures) é o
  que o Onion tem **a mais** que o A2A — não algo a traduzir.

### Negativas / trade-offs
- **Projeção parcial** pode iludir um consumidor A2A a esperar mais do que o manifesto expõe →
  documentar a fronteira no momento da implementação.
- **Custo de tracking** do spec A2A (que está em upgrade) recai sobre quem implementar a projeção.
- **Risco de scope creep:** a permissão de "formato" não pode virar porta dos fundos para runtime —
  por isso a regra 1 (runtime proibido) permanece **invariante** e separada.

---

## Gatilho de implementação

A projeção export-only **só** vai ao backlog ativo quando **um** destes ocorrer:

- surgir o **1º consumer não-Onion** (ou repo de stack heterogênea) na federação; **ou**
- houver **necessidade real e nomeada** de interop com um registry/ferramenta A2A externa.

Até lá: item **🟢 oportunístico** no backlog do `/meta:evolve`, **com este gatilho anexado** — não é
dívida ativa. Construir antes do gatilho seria especulação (review §4: não há consumer não-Onion hoje).

---

## Caveat de frescor

A lista de campos do Agent Card acima vem de conhecimento de treino e o **spec A2A está em upgrade**
(Google Cloud, 2026). **Antes de qualquer implementação**, revalidar os nomes/estrutura dos campos
contra o spec A2A vigente — não contra esta tabela. (Mesma disciplina de `[[kb-freshness-before-citing]]`.)

---

## Referências

- [`multi-repo-federation.md`](../knowledge-base/concepts/multi-repo-federation.md) — doutrina (linha vermelha partida em §7)
- [`onion-federation-review-2026-06.md`](onion-federation-review-2026-06.md) — revisão de origem (ressalva §4)
- [`onion-federation-design-v2-2026-06.md`](onion-federation-design-v2-2026-06.md) — design da federação (§2 linha vermelha runtime)
- [`agent-orchestration-landscape-2026.md`](../knowledge-base/frameworks/agent-orchestration-landscape-2026.md) — riscos não resolvidos do fan-out/A2A
- [Linux Foundation — A2A Protocol Project](https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project-to-enable-secure-intelligent-communication-between-ai-agents)
- [Google Cloud — Agent2Agent protocol is getting an upgrade](https://cloud.google.com/blog/products/ai-machine-learning/agent2agent-protocol-is-getting-an-upgrade)

---

**Mantido por:** Sistema Onion · **Última atualização:** 2026-06-15
