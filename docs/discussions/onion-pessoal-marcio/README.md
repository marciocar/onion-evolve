# 🧅 Onion pessoal — um Company Brain para o Marcio (N=1)

> **Discussão isolada.** Pensa, não entrega. Nada aqui vai pro core sem o maestro pedir.
> Ponto de partida: [SEED.md](SEED.md). Este README amarra as **5 passadas** (P1–P5).

## A tese

Assim como um *Company Brain* é o cérebro reconciliado de uma organização, um **Onion pessoal** é o cérebro
reconciliado de **um indivíduo** — conhecimento, decisões, verdades pessoais/profissionais, mapeados e reconciliados
com o mesmo método **KG SDAAL** já apontado contra a identidade do framework. O Marcio (o criador) é o **1º dogfood
natural**. A pesquisa `knowledge-centric-ssot-2026` achou o eixo quente (Company Brain = aposta YC 2026) e o **combo
multi-vertical reconciliado desocupado** — o Onion pessoal é a versão N=1 desse combo.

## O método (idêntico em toda passada)

1. **Pesquisa orquestrada citada** — fan-out multi-fonte + verificação adversarial + síntese datada (o mesmo harness
   da `knowledge-centric`). *Evidência antes de posição — nunca derivar dos priors do assistente.*
2. **Derivação sob `fonte≠derivação`** — a teoria fiel mora em [`proto/theories/`](proto/theories/) (zero Onion); a
   **nossa** leitura em [`proto/applications/`](proto/applications/) e nos docs `0X-*.md`, que **citam, nunca reescrevem**.
3. **Proto executável** — cada tese vira um `.kg.yaml` que passa no `kg-radar.sh`, e cujo **nó mais central é a
   própria tese-núcleo** (o argumento se auto-prova no grafo).

**Lente governante:** **Aristóteles** (a régua — *tratar igual o que é igual, diferente o que é diferente*:
igual→transferir do Company Brain, diferente→desenhar fresco) + **Hegel** (o motor — a contradição gera
desenvolvimento; *Aufhebung* nega+conserva+eleva; **sem telos**).

## As 5 passadas

| # | Pergunta (SEED) | Resposta (tese-núcleo) | Doc | Proto executável | Commit |
|---|---|---|---|---|---|
| **P1** | Quais as verticais peer de uma pessoa? | **não é uma lista, é uma arquitetura**: domínio × C/H/A ortogonal × cultura transversal (derivada, não postulada; irredutibilidade filosófica Nussbaum/Berlin, não psicométrica) | [01-verticais-peer.md](01-verticais-peer.md) | [marcio.kg.yaml](proto/marcio.kg.yaml) | `a59529e` |
| **P2** | O que reconcilia (metas×ações, passado×presente)? | o motor: **compromisso ≠ fato** (objeto de 1ª classe; `ipse` de Ricoeur = 3ª camada); discriminador híbrido 3-órgãos; **anti-auto-engano via check externo DEV×PROD** | [02-reconciliacao.md](02-reconciliacao.md) | [reconciliation-engine.kg.yaml](proto/reconciliation-engine.kg.yaml) | `c29e093` |
| **P3** | Fronteira com o core: adotante × privado? | **falsa dicotomia** — membro adotante **pelo método**, soberano **no dado** (privacidade ≠ sair da federação; sem bypass do criador) | [03-fronteira-core.md](03-fronteira-core.md) | [fronteira-decision.kg.yaml](proto/fronteira-decision.kg.yaml) · [membership-marcio-pessoal.yaml](proto/membership-marcio-pessoal.yaml) | `218d9f1` |
| **P4** | Privacidade/soberania (`exposes:`/`de-identification`) | postura Onion **já certa**; 5 peças faltam; **classificação por vertical** (ipse/relações/saúde = `private`); o elo **sem cifra é a inferência** | [04-privacidade-soberania.md](04-privacidade-soberania.md) | [classification-por-vertical.kg.yaml](proto/classification-por-vertical.kg.yaml) | `470d135` |
| **P5** | *(fronteira aberta da P4)* Como se defender do motor que lê o grafo? | **feature dentro, perigo na fronteira**: para o dono, inferir é o produto; a defesa é **6 camadas negativas** na fronteira; a inferência interna é **indefesa por construção** — nomeada, não escondida | [05-mitigacao-inferencia.md](05-mitigacao-inferencia.md) | [inference-mitigation.kg.yaml](proto/inference-mitigation.kg.yaml) | `754497e` |

## Os fios que atravessam as 5 passadas

- **A convergência interna × externa** (P3, P4): três vezes a doutrina que o Onion já tem bateu, sem se conhecer, com
  o consenso externo de 2026 (local-first + destilado; fail-safe; "errar para não-vazar"). O Onion já é, por acidente
  de doutrina, o que o estado da arte recomenda para N=1.
- **O eixo DEV×PROD** (P2 → P5): intenção declarada × comportamento vivido é o motor de reconciliação (P2), o
  anti-auto-engano do árbitro (P2), e reaparece como o *self-red-team* de saída (P5).
- **A honestidade como invariante**: o **caveat intra-órbita** (o Marcio é o centro da órbita — prova o **método**,
  não o **mercado**) atravessa todas as passadas sem ser diluído. E os limites são **nomeados, não escondidos**:
  peer-ness filosófica não-psicométrica (P1), auto-engano do árbitro (P2), gap de mercado é hipótese (P3), inferência
  sem cifra (P4/P5). Declarar mais do que a evidência sustenta seria *falsa distinção às avessas*.
- **Dogfood recursivo**: rodar o `kg-radar` sobre cada proto é o Onion se olhando no espelho — e a **L5 self-red-team**
  da P5 é a doutrina de dogfood do próprio Onion aplicada à privacidade.

## Como usar (o baseline pé-no-chão)

**Usar o Onion pessoal hoje = `cd ~/onion-pessoal && claude` e conversar** (o `.kg.yaml` é mantido pela
conversa; `kg-radar` é a lente). O passo-a-passo durável está em **[USAGE.md](USAGE.md)** — o baseline
conversacional (F0/Wizard-of-Oz), antes da interface rica (`interface-state-of-art`, gated).

## O que fica (engenharia, não descoberta)

As 4 perguntas do SEED estão fechadas e a fronteira aberta da P4 (inferência) foi resolvida **até onde a honestidade
permite**. O que resta **não é uma P6 de descoberta** — é **construção**: o **SSOT único** que integra
classificação-por-inferência (P4) + gate-por-propósito/destinatário (P5) + ε-ledger num mecanismo executável para um
life-KG lido pelo próprio motor. A construir, se o Onion pessoal um dia sair do papel.

## Mapa de arquivos

```
onion-pessoal-marcio/
├── SEED.md                     · o ponto de partida (as 4 perguntas)
├── README.md                   · este índice
├── 01-verticais-peer.md        · P1
├── 02-reconciliacao.md         · P2
├── 03-fronteira-core.md        · P3
├── 04-privacidade-soberania.md · P4
├── 05-mitigacao-inferencia.md  · P5
├── research/                   · as sínteses de pesquisa citadas (SYNTHESIS.md, -P2..-P5)
└── proto/                      · o método rodando (ver proto/README.md)
    ├── theories/               · camada 1 — teoria fiel (fonte≠derivação)
    ├── applications/           · camada 2 — nossa derivação
    └── *.kg.yaml               · os grafos executáveis (dogfood)
```

## Dogfood — rodar todos os grafos

```bash
for kg in marcio reconciliation-engine fronteira-decision classification-por-vertical inference-mitigation; do
  echo "== $kg =="
  bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/$kg.kg.yaml | tail -3
done
```

Cada um: **INTEGRIDADE exit 0**, e o nó mais central é a tese-núcleo da passada. Detalhe do proto em
[proto/README.md](proto/README.md).
