# Automação graduada — a escada única (candidato)

> **Status: CANDIDATO** — esta KB **não inventa doutrina**: ela **nomeia e unifica** uma escada que o Onion
> já sobe, espalhada em ~6 docs que nunca se citaram como família. Entra no core **por uso** (padrão
> `candidato`). O movimento Elenxo que a gerou vive no grafo:
> [`graduated-automation-elenxo-2026-07.kg.yaml`](../../onion/graph/graduated-automation-elenxo-2026-07.kg.yaml).
> Fonte≠derivação: **cita**, não recopia — cada peça permanece soberana no seu arquivo.

## A máxima (cunhagem do maestro, 2026-07-24)

> **"Toda automação vem de uma ação; automatizar o que nunca foi realizado tem grandes chances de fracasso."**
> — Marcio Carvalho, 2026-07-24.

A automação **se conquista por ação provada**, não se concede por decreto. Enquanto um processo amadurece, o
**humano fica no loop**; depois, testes/monitores/alertas/contenção garantem a execução correta, e só então
o gate se **supera** — alguns dinamicamente, outros nunca (o humano é invariante onde o ato é irreversível).
É o [`declarado≠verificado`](knowledge-graph-sdaal.md) aplicado ao **enforcement**: não automatize o que você
não verificou que funciona à mão.

## Os dois eixos

**Eixo horizontal — a LINHA (o que é autônomo vs gated).** Fonte:
[`authorization-layers-intake-vs-execution.md`](authorization-layers-intake-vs-execution.md).
**INTAKE** (receber/verificar/guardar de contato permitido) é **autônomo**; **EXECUÇÃO** (aceitar/aplicar/
efeito-de-saída no repo dono) é **gated**. É o "melhor dos dois mundos": não paranoia (recebe sozinho), não
negligência (não aplica sozinho).

**Eixo vertical — a ESCADA (quanto de autonomia foi ganho).** Fonte:
[`onion-adr-autonomous-thread-runtime-2026-07.md`](../../analysis/onion-adr-autonomous-thread-runtime-2026-07.md).

| Degrau | O que roda sozinho | Quem decide o efeito | Gate de promoção (o que prova a subida) |
|--------|--------------------|----------------------|------------------------------------------|
| **HUMANO** (piso ATIVO) | atos 1-2 (transportar+notificar), propor, reversível-own-repo | humano em LOTE no repo dono | — (é o piso) |
| **MONITORADO** *(candidato — degrau novo)* | roda sozinho **sob observação** (shadow), efeito ainda proposto | humano confere o observado | N execuções shadow sem anomalia |
| **DINÂMICO** *(candidato)* | auto **dentro do escopo ganho** (path-allowlist mecânica) | política 100% mecânica | gate de promoção + rollback provado |
| **AUTO** (teto DESENHADO, gated) | auto-merge own-repo | mecânico | as 3 pré-condições duras (nunca cabeadas) |
| **MOAT** (invariante) | **nunca** — repo-alheio/deploy/irreversível | **sempre humano** | não se promove (`medir≠decidir`, [engine-economy](onion-engine-economy.md)) |

## A escada JÁ RODA — o que a federação provou (medido 2026-07-24)

Esta escada não é futuro a construir; **descreve o que o Onion já faz**, medido. O registry
[`automation-ladder-registry.txt`](../../../.claude/validation/automation-ladder-registry.txt) é a SSOT desse
estado (guardado pela REGRA 44). A medição mostra o Onion operando a escada em **dois eixos**:

- **STRUCTURAL (auto-por-construção):** regens (inventory, plugins, graph/map/console), o `--fix` que
  auto-corrige contagem, o radar — derivações determinísticas do SSOT, **sempre seguras**. Já automáticas
  **por construção** (o modo estrutural), não por confiança ganha.
- **HUMAN (ato-3, risco):** entregar/aceitar/aplicar/corrigir/triar — no piso. A **resolução-de-alvo do
  co-deliver** é a candidata madura a MONITORED (**91 entregas** + a falha multi-checkout **documentada** + o
  monitor Passo 2.1), mas só sobe com um run monitorado real (a máxima: não fabricar a subida).
- **MONITORED (eixo CONFIANÇA) — a máxima JÁ realizada:** **um adotante regulado** conquistou o direito de
  **corrigir a doutrina do core** (`can_correct_to`, 2026-07-06) **por ação provada** — achou+corrigiu um bug
  real de lint convergente com o nosso, com horas de diferença, zero comunicação. É o exemplo canônico:
  **autoridade conquistada por ação, não por decreto** — datada, medida, human-gated. E **um adotante de
  campo** alimentou o core com um bug de campo real. (O crédito nominal vive no diário privado, não aqui.)
- **MOAT:** deploy ao VPS (site, bridge) — irreversível, **manual por desenho**.

A KB **nomeia** o que o dogfood já forjou (o padrão "candidato entra por USO"); o registry o **atesta**.

## Cada degrau tem três garantias (o "como não fracassar")

1. **Gate de promoção** — o que prova que a classe pode subir. A esteira
   [`onion-promotion-ladder.md`](onion-promotion-ladder.md) (`assess→trial→adopt`) é a versão para
   artefatos; a escada acima é a versão para **ações de runtime**. Invariante comum: **nunca promover
   pulando o gate**.
2. **Camada de contenção** — o que torna seguro destravar: `entrega-sem-commit`/`committed:false` (I3),
   `never-clobber`, `apply_mode:propose-only` (regulado), path-allowlist, budget-cap do loop, rollback
   ([`/meta:federation-rollback`](../../../.claude/commands/meta/federation-rollback.md)).
3. **Modo de enforcement** — como a garantia é feita, em ordem de robustez: **estrutural > determinístico >
   gated** ([`onion-guardrails.md §3`](onion-guardrails.md)). O estrutural é o topo: torna o erro
   *impossível por construção*.

## A catraca — introduzir automação sem quebrar o que nunca foi automatizado

A [catraca](onion-guardrails.md) (baseline que só encolhe, REGRA 29/42) é o análogo exato da máxima aplicado
a **gates**: passivo tolerado, HARD só para o NOVO, baseline só diminui. Provou-se (75→0 em seis levas). É
como um degrau novo entra numa base viva **sem reprovar o legado** — o mesmo espírito de "não automatize de
uma vez o que nunca foi automatizado".

## O espectro A2A (o caso concreto — federação)

O canal A2A já materializa a escada em 4 faixas (fonte:
[`a2a-verify.sh`](../../../.claude/utils/federation-transport/a2a-verify.sh) + RFC-0004): **Automático**
(atos 1-2, co-announce/deliver/relay, o verify emite veredito) · **GATED-humano** (aceitar/aplicar sinal —
`a2a-accept.sh` é o ato humano) · **GATED-com-degradação** (`mode:regulated → propose-only / never-live-pull`)
· **PROIBIDO** (IA-fala-IA autônoma cross-repo — a linha vermelha). O invariante: `gated:true`/`committed:false`
SEMPRE; o moat é **a aceitação gated, não a latência**.

## O mecanismo (senão é prosa)

Por [`mechanism-beats-prose`](../../../.claude/diary/2026-07-21-mechanism-beats-prose.md), esta KB só dura se
vier com um **gate**: [`ladder-integrity-check.sh`](../../../.claude/validation/ladder-integrity-check.sh) —
um registry `classe × degrau` (baseline à la catraca) que **reprova uma classe que subiu de degrau sem seu
gate de promoção declarado**. Nasce silencioso (nenhuma classe declara AUTO hoje). É o irmão da catraca
aplicado à automação: a escada não drifta porque um gate a guarda.

## As três lacunas genuinamente novas (Ondas 2-4, gated)

Confirmadas pela exploração como território **não pisado** (ver o grafo do Elenxo):
- **Degrau MONITORADO/shadow** (Onda 2) — promover o `onion-effect-gate.sh` órfão da worktree discuss;
  dogfood **interno primeiro** (decisão do maestro), não no onboarding do Pedro.
- **Alertas preditivos** (Onda 4) — o core é reativo/CI-safe por design; antecipar a falha é novo.
- **Critérios de promoção contáveis** (Onda 3) — "N execuções provadas ⇒ destrava" + rollback como
  pré-condição; hoje é juízo humano no checkpoint.

## 🔗 Referências (as peças que esta escada unifica)
- Escada de autonomia: [`onion-adr-autonomous-thread-runtime-2026-07.md`](../../analysis/onion-adr-autonomous-thread-runtime-2026-07.md)
- Esteira de promoção: [`onion-promotion-ladder.md`](onion-promotion-ladder.md)
- A linha intake≠execução: [`authorization-layers-intake-vs-execution.md`](authorization-layers-intake-vs-execution.md)
- Catraca + 3 modos: [`onion-guardrails.md`](onion-guardrails.md) §3/§7/§8
- Fronteira medir≠decidir: [`onion-engine-economy.md`](onion-engine-economy.md)
- Transporte A2A: RFC-0004 · [`a2a-verify.sh`](../../../.claude/utils/federation-transport/a2a-verify.sh)
- O Elenxo (grafo): [`graduated-automation-elenxo-2026-07.kg.yaml`](../../onion/graph/graduated-automation-elenxo-2026-07.kg.yaml)
