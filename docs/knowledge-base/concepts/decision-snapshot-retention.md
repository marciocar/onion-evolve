# Snapshot de Decisão — Retenção e Payload Mínimo

> **Versão**: 1.0.0 | **Última atualização**: 2026-06-22 | **Categoria**: Conceitos
> Diretriz canônica para **rastreabilidade atômica sustentável**: todo registro de decisão (decision
> snapshot) declara uma **política de retenção** e persiste o **payload mínimo** (a decisão, não o
> universo de entrada). Sem isso, a rastreabilidade — virtude do [Spec-as-Code](spec-as-code-strategy.md)
> — vira dívida de armazenamento ilimitada. Nasceu de um sinal de campo (upstream) de um adotante.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-06-22 |
| **Última Atualização** | 2026-06-22 |
| **Categoria** | Conceitos |
| **Quadrante (radar)** | MET (Método/Processo) |
| **Origem** | sinal de campo (2026-06-19) — [co-evolução upstream](../../evolution/README.md) |
| **Conceitos-irmãos** | [Spec-as-Code](spec-as-code-strategy.md) · [Ciclo de Vida do Contexto de Domínio](domain-context-lifecycle.md) |

---

## 🎯 Propósito

A doutrina **Spec-as-Code / rastreabilidade atômica** incentiva registrar **o porquê de cada decisão**
para auditabilidade e reprodutibilidade. Tomada ao pé da letra — "guardar tudo, completo, para sempre,
por garantia" — ela colide com a realidade: **volume × payload cheio × zero retenção = crescimento
ilimitado**.

Esta diretriz resolve a tensão sem abrir mão da rastreabilidade: o registro de decisão é **seletivo
por design** (responde *por quê*, não loga *tudo*) e tem **ciclo de vida** (quente → frio → arquivado),
nunca acúmulo perpétuo no caminho quente.

> ⚠️ **Confusão-raiz a evitar:** rastreabilidade ≠ logging bruto. Rastreabilidade responde
> *"por que esta decisão, e não a alternativa?"*. Logging bruto guarda *tudo que entrou*. Persistir o
> universo de entrada por decisão é logging disfarçado de rastreabilidade.

---

## 🚦 O que a diretriz exige (as 3 regras)

1. **Payload mínimo — a decisão, não o universo.**
   Persista o que torna a decisão **reconstruível como decisão**: o **escolhido** + os **top-N
   quase-escolhidos** com a razão de exclusão + config/seed/versão da regra. O **universo de entrada**
   (ex.: pool inteiro de candidatos) é **reconstruível** de `inputs + config + seed`; a decisão (o que
   venceu e por quê sobre os runners-up) **não é**.
   - **Teste do auditor:** um auditor consegue responder *"por que este, e não aquele?"* com o que está
     persistido? Se o universo cheio **não adiciona** nada a essa resposta, ele é ruído — corte.

2. **Política de retenção declarada (janela + destino).**
   Todo store de rastreabilidade **declara** uma janela de retenção (por tempo *ou* contagem) e **o que
   acontece além dela**. Retenção ilimitada é **bug-por-omissão**, não feature. A janela é decisão
   explícita de produto/compliance (*por quanto tempo precisamos responder "por quê?"*) — tomada de
   propósito, não por esquecimento.

3. **Frio → arquiva/comprime, não acumula (e raramente deleta).**
   Além da janela quente (consultável), **não delete** (auditabilidade) — **rebaixe**: comprimir
   (JSONB/TOAST, colunar), particionar por tempo, mover para tabela fria / log append-only / object
   storage. Recuperável, sem inflar o caminho quente.

---

## 📐 Worked example (evidência — não asserção)

Caso real que originou a diretriz ([sinal de campo, upstream](../../evolution/federation/CHANGELOG.md)):

| Sintoma | Diagnóstico | O que a diretriz teria evitado |
|---|---|---|
| Banco do adotante 32MB → **86MB em ~1 semana**; 80% em 3 tabelas | `WRRSelectionDecision`: **38MB / 2.781 linhas**, ~**79KB/linha** (máx 186KB) — cada decisão grava **o pool inteiro de candidatos (~300+)** + exclusões por estágio, **sem poda** | Regra 1 (payload mínimo: selecionado + top-N, não o pool) reduz ~79KB → poucos KB; Regra 2+3 (retenção + frio) limita o acúmulo no caminho quente |

A lição: a tabela não era um log — era a **rastreabilidade da spec do motor**. O problema não foi *registrar
a decisão*; foi **registrar o universo** e **nunca podar**. A rastreabilidade certa é mais barata **e**
mais legível (o auditor lê o que importa, não 300 candidatos).

---

## 🧭 Fronteira: diretriz (framework) vs implementação (local)

Esta é a divisão que o veredito de roteamento estabeleceu (impl local + diretriz de framework):

| Camada | Pertence a | Exemplos |
|---|---|---|
| **Diretriz (contrato)** | **Framework Onion** (este doc) | *declarar* retenção; payload mínimo (decisão, não universo); rebaixar-não-deletar; teste do auditor |
| **Implementação** | **Projeto adotante** (local) | job de poda por janela; TOAST/JSONB compression; partição temporal; tier de storage; cron/trigger de arquivamento — DB- e volume-específicos |

> O framework define **o que** garantir e **por quê**; o adotante decide **como** (Postgres vs outro,
> volume de bursts, SLA de auditoria). Se um adotante descobrir um formato de "snapshot mínimo" que
> generaliza, devolve como [sinal de campo](../../evolution/README.md) — insumo direto de uma v2 desta diretriz.

---

## 📚 Fontes e referências

- Pai: [Spec-as-Code Strategy](spec-as-code-strategy.md) — rastreabilidade é parte do spec-as-code (a decisão é spec; o código é saída)
- Parente: [Ciclo de Vida do Contexto de Domínio](domain-context-lifecycle.md) — pensamento de ciclo de vida (CRUD+) aplicado a artefatos vivos; snapshots também têm ciclo de vida
- Doutrina de evolução: [Modernização](onion-modernization-doctrine.md) (decide *o quê*) · [Dogfooding](onion-dogfooding-doctrine.md) (prova que funciona)
- Co-evolução (origem do sinal): [docs/evolution/README.md](../../evolution/README.md) · [CHANGELOG downstream](../../evolution/federation/CHANGELOG.md) (entrada 2026-06-22) · backlog `onion-coevolution-backlog-2026-06-18.md` (item #5)
