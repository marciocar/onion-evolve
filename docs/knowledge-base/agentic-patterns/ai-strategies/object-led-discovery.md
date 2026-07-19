# Object-Led Discovery & Fitting — Promover Objeto a Papel

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Criado** | 2026-06-30 |
| **Status** | `assess` — veredito do maestro pendente |
| **Tags** | `transformer`, `discovery`, `capability`, `sdaal`, `object-led`, `fitting` |
| **Origem** | Sinal de campo um adotante (2026-06-29) + dogfood um componente de tabela premium |

---

## 🎯 O Problema

Quando o maestro pede "promova este objeto a um padrão premium" (ex: tabelas soltas →
`DataTable` rico e reutilizável), o agente hoje **improvisa imperativamente**:

1. Lê exemplos do repo
2. Infere requisitos sem framework
3. Escolhe ferramentas por intuição
4. Migra à mão, objeto a objeto
5. Re-improvisa a cada novo requisito do maestro

Funciona, mas é **não-reproduzível, não-catalogado e dependente da atenção pontual**.
A qualidade varia por sessão; não existe baseline para medir "bom vs improvisado".

---

## 💡 A Proposta

Canonizar o ciclo como uma **capability Onion dirigível**: o maestro nomeia o objeto e
o papel-alvo; o agente executa um ciclo estruturado com gates.

### O Ciclo (4+1 etapas)

```
Maestro: "promova <objeto> ao papel <alvo>"
     │
     ▼
1. ESPELHAR
   └─ Cria stub/draft descartável (worktree ou clone)
   └─ Sem tocar o original até o maestro aprovar

     │
     ▼
2. DESCOBRIR (object-led)
   └─ Introspecta o objeto e seus pares no repo
   └─ Monta o Capability Contract:
      • o que ele provê hoje (Bronze/Silver/Gold)
      • o que o papel-alvo requer
      • gap = o que falta

     │
     ▼
3. VESTIR (capability-fitting)
   └─ Seleciona do catálogo SDAAL os adapters/estratégias
      que fecham o gap (reusar antes de criar)
   └─ Proposta ao maestro: "estas ferramentas, nesta ordem"

     │
     ▼
4. MATERIALIZAR (dirigido pelo maestro)
   └─ Aplica com gates por etapa
   └─ Verificação: tsc / build / tests
   └─ Cada etapa → maestro aprova → próxima etapa

     │
     ▼
5. REALIMENTAR
   └─ Resíduo (o que não casou com playbook) → novo playbook
   └─ Fecha o loop do RFC-0002 (catálogo-first)
```

---

## 🏗️ Grounding (não é invenção — é síntese)

| Peça | Princípio | Já existe no core? |
|------|-----------|--------------------|
| **Information Expert** | "quem responde sobre o objeto é o objeto" | ✅ KB `onion-research-self-describing-components-2026-06` |
| **Capability Contract** | `provides/requires` + tiers Bronze/Silver/Gold | ✅ ADR aceito |
| **SDAAL** | adapters provider-agnósticos, LLM=runtime, Markdown=bytecode | ✅ `docs/sdaal/sdaal.md` |
| **Catálogo-first** | reconhece situação → seleciona playbook → reroute | ✅ RFC-0002 ratificado |
| **Transformer dirige** | maestro direciona; transformer executa com as peças certas | ✅ doutrina Onion |

**O que falta:** a **síntese operável** — um comando/skill que orquestre essas peças
em sequência, com gates e rastreabilidade.

---

## ❓ Questões em Aberto (com inclinação)

| Questão | Inclinação |
|---------|-----------|
| **Forma:** ADR + skill própria, ou extensão do RFC-0002 + Capability Contract? | Extensão (menor superfície); skill fina de orquestração |
| **Espelho:** artefato físico (worktree) ou conceitual (plano)? | Físico quando há risco de mutação (N arquivos); conceitual quando é leitura |
| **1º caso canônico:** qual o dogfood? | um componente de tabela premium do app de um adotante — resultado já à mão, bom baseline |
| **Relação com `create-*`:** mesmo toolbox? | Sim — "promover" (objeto existe) vs "criar" (do zero); gatilho diferente |

---

## 📊 Evidência de Campo

O um componente de tabela premium foi construído **imperativamente** — e essa prova é o gap mais limpo.

| | Processo Imperativo (o que aconteceu) | Processo Object-Led (o que deveria ser) |
|-|---------------------------------------|-----------------------------------------|
| **Descoberta** | Ad-hoc — leu exemplos, inferiu requisitos | Structured — Capability Contract monta o gap |
| **Fitting** | Escolha intuitiva de stack | Catálogo SDAAL → playbook de "tabela premium" |
| **Novos requisitos** | Re-improvisa a cada pedido | Gate no Materializar → acumula de forma rastreada |
| **Reprodutibilidade** | Depende da atenção da sessão | Ciclo documentado + playbook no catálogo |

**Artefatos existentes** (o app de um adotante, branch `feat/feature-viz`):
`apps/frontend/src/components/data-table/*` — 13 capacidades acumuladas por pedidos
sucessivos: sort/filtro/busca/agrupar/expandir/colunas/export/salvar-visão/seleção+bulk/
tela-cheia/densidade/resize/pin.

---

## 🗺️ Status e Próximos Passos

| Status atual | `assess` — aguarda veredito do maestro |
|---|---|
| **Se ACEITAR (`trial`)** | Abrir RFC/ADR → dogfood dirigido com DataTable → medir diferença |
| **Se ADIAR** | Mover para backlog gated; motivo registrado |
| **Se REJEITAR** | Arquivar; motivo registrado |
