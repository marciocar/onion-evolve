# A esteira de promoção — das ideias aos artefatos (camadas de teste e maturação)

> **Versão**: 1.0.0 | **Criada**: 2026-07-17 | **Categoria**: Conceitos
> **Consolida** o vocabulário de experimentação que já vivia **disperso** (spike, stub, quarentena, slice,
> candidato) numa esteira única, e **cita** — não recopia ([fonte≠derivação](source-vs-derivation.md)) — as
> réguas que já existem: P0-P3 (que CAIXA), `assess→trial→adopt` (promoção de padrão), `gated-until-trigger`
> (quando construir) e o dogfood (como sei que ficou certo). Nasce do pedido do maestro (2026-07-17):
> *"as diferentes camadas de teste e promoção destas ferramentas, peças do lego"*.

---

## Por que esta doutrina existe

O Onion tinha as **réguas de decisão** (P0-P3 · gated-until-trigger · dogfood) e o **ciclo de promoção**
(`assess→trial→adopt`), mas **não tinha nome para as fases de EXPERIMENTAÇÃO de uma ideia** antes de ela virar
artefato. O vocabulário existia solto — `spike` num lugar, `stub` noutro, `quarentena` num terceiro — sem uma
esteira que dissesse *o que cada camada prova, o que ela pode custar, e o gate para subir à próxima*. Sem isso,
um `spike` descartável e um `MVP` entregável eram tratados como o mesmo objeto epistêmico — o modo de falha que
a régua `worst-truth-is-uncertain` condena: **certeza de fase é CAMPO, não TOM**.

> **Correção factual (2026-07-17):** referências a *"a régua de promoção do `radar.md`"* apontam para um
> **artefato do adotante** (o radar de backlog de um adotante — *"mova os blips no SEU radar.md"*), **não**
> para uma SSOT ausente do core. A régua `assess→trial→adopt` **vive** em
> [toolbox-lifecycle](../../analysis/onion-adr-toolbox-lifecycle-2026-06.md) §Decisão 4; este KB a **completa**
> com as camadas de experimentação que faltavam.

## A esteira (o eixo de maturação)

```
impulso/ideia  →  EXPERIMENTO  →  ASSESS  →  TRIAL  →  ADOPT
                  (descartável)    (juízo)    (uso real)  (canon)
```

Ortogonal ao eixo está o **gate de cada transição** — nunca subir sem ele:

| Transição | Gate (o que prova a subida) | Fonte da régua |
|---|---|---|
| ideia → experimento | *vale gastar energia pra aprender?* (não simetria) | `gated-until-trigger` |
| experimento → assess | o experimento **respondeu** a pergunta que o motivou | dogfood (rodar, não planejar) |
| assess → trial | **uso real falhou por falta disto** (≥1×, não hipótese) | `gated-until-trigger` §3 perguntas |
| trial → adopt | **prova no par core↔derivado** (gate de uso vivo, não só mecânico) | toolbox-lifecycle §Dec.4 · dogfooding §gate-de-uso |

## As camadas de experimentação (o vocabulário, agora nomeado)

Cada camada carrega **grau de certeza próprio** — o output de um spike **não é** o output de um MVP, e a esteira
proíbe promover um ao outro sem o gate. Todas são **descartáveis por padrão** exceto onde marcado.

| Camada | O que prova | Custo/tempo | Descartável? | Já usado em |
|---|---|---|---|---|
| **PoC / spike** | 1 pergunta fechada ("isto é possível/como?"), tempo-caixa | mínimo | **sim** (o artefato morre; a lição fica) | `platforms/git-ledger-as-working-dir` (spike Fase 0) · `onion-f1-spike-adopt-domain-profile` |
| **stub** | a FORMA/contrato sem função (esqueleto que guia a implementação) | baixo | sim | `abstraction-patterns-catalog` (adapter STUB) · `ai-strategies/object-led-discovery` (stub/draft) |
| **simulação / ambiente paralelo** | o comportamento **sem tocar produção** (dogfood de modo-de-falha) | médio | sim | dogfooding-doctrine (gate de uso vivo) · o canário do `--update` |
| **protótipo em quarentena** | o desenho **wired mas isolado** (existe, não integrado ao core) | médio | não (promove ou remove) | `concepts/onion-guardrails` (R15 "desenhado, não wired") |
| **candidato** | um padrão **recebido** (ex.: via co-evolução) aguardando o 1º dogfood que o prove | — | não (gated) | `knowledge-graph-sdaal` (KB CANDIDATA até `/meta:kg` nascer) |
| **slice / MVP** | a **menor forma que entrega valor real** (não descartável — é o 1º corte do artefato) | o necessário | **não** | os `1º slice` das RFCs/pesquisas · a esteira mensageria F1 |

## Como isto se encaixa (sem recopiar as réguas)

- **P0-P3** decide *que CAIXA* o artefato final terá (script/comando/skill/KB/agente/SDAAL) — a esteira decide
  *quando* ele merece nascer. São eixos ortogonais: um spike pode virar qualquer caixa.
- **`gated-until-trigger`** é o gate da entrada e do meio da esteira — *"seria bom ter" não é gatilho; uso real
  que faltou é*. Toda camada acima da linha "adopt" precisa do gatilho **nomeado**.
- **Dogfood** é como cada gate de uso é exercido: **rodar o artefato de verdade**, testar o modo-de-falha. O
  gate mecânico (`.claude/validation/`) é o dogfood determinístico; o resto é *invocar e observar*.
- **`assess→trial→adopt`** é a metade **de promoção** (padrão já formado subindo a canon); as camadas de
  experimentação são a metade **anterior** (a ideia virando algo testável). Juntas: a esteira completa.

## Invariantes

- **Nunca promover pulando o gate.** Um spike verde não é um MVP; um candidato não é canon até o dogfood.
- **Grau de certeza é campo, não tom** ([worst-truth-is-uncertain]): rotular a camada honestamente — um
  resultado de simulação não pode ser citado como se fosse de produção.
- **Descartável é feature, não desperdício** ("não queremos economia, queremos eficiência e eficácia"): o spike
  que morre pagou-se na lição. O erro é **não** descartar — arrastar um experimento como se fosse artefato.

## Fontes (as SSOTs que esta esteira cita)

- Régua de caixa: [`onion/SKILL.md`](../../../.claude/skills/onion/SKILL.md) §"Criar Componentes" · P0-P3 em
  [toolbox-lifecycle](../../analysis/onion-adr-toolbox-lifecycle-2026-06.md).
- Quando construir: [modernization-doctrine](onion-modernization-doctrine.md) §`gated-until-trigger`.
- Como validar: [dogfooding-doctrine](onion-dogfooding-doctrine.md) §gate mecânico vs gate de uso.
- Promoção de padrão: toolbox-lifecycle §Decisão 4 (`assess→trial→adopt`, espelha `domain-context-lifecycle`).
