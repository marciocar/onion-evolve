# 🧪 proto/ — esqueleto do método rodando (sandbox de discussão)

> **Sandbox de discussão isolada — NÃO é a KB do core.** Nada aqui vai para `docs/knowledge-base/`
> sem o maestro pedir. É uma *ilustração executável* do método aplicado à pergunta P1 (as verticais
> peer de uma pessoa), não um artefato de produção.

## A regra das DUAS CAMADAS (fonte≠derivação, aplicada à pessoa)

Espelha a fronteira física da vertical `education/` do core (ver
[`docs/knowledge-base/education/README.md`](../../../knowledge-base/education/README.md) e a doutrina
[`source-vs-derivation.md`](../../../knowledge-base/concepts/source-vs-derivation.md)). **Não se mistura
o core das teorias com as nossas derivações** — a separação é estrutural, não por rótulo.

| Camada | Diretório | Regra |
|---|---|---|
| **1 — THEORIES** | [`theories/`](theories/) | A teoria **como é** — fiel às fontes, veredito só de *fidelidade*, **zero Onion**. Corrigir a teoria = mexer só aqui. |
| **2 — APPLICATIONS** | [`applications/`](applications/) | A **nossa** derivação — o modelo candidato de verticais; **cita a camada 1, nunca a reescreve**. Uma ponte refutada não contamina a teoria. |

Litmus: *"se a fonte mudar, edito em quantos lugares? → **um**"* (a camada 1).

## Mapa

**Camada 1 — teorias (fiel à fonte, zero Onion):**

| Arquivo | Passada | O quê |
|---|---|---|
| [theories/whole-person-models.md](theories/whole-person-models.md) | P1 | SDT, PERMA, Ryff (+colapso), WHOQOL, Nussbaum, Berlin, Maslow-renovado |
| [theories/competency-cha.md](theories/competency-cha.md) | P1 | McClelland/Boyatzis/Spencer (iceberg), CHA (Parry), Le Boterf/Zarifian, skills-graph |
| [theories/behavior-intention-action.md](theories/behavior-intention-action.md) | P1 | Sheeran, inclined abstainers, Gollwitzer, Fogg, COM-B, Locke&Latham |
| [theories/culture-as-axis.md](theories/culture-as-axis.md) | P1 | Hofstede, Schwartz, Haidt, WEIRD (Henrich), Oishi |
| [theories/hegel-dialectics.md](theories/hegel-dialectics.md) | P1 | Aufhebung, negação determinada, correção Chalybäus/Fichte, Priest×Brandom |
| [theories/self-in-time.md](theories/self-in-time.md) | P2 | Ainslie/Laibson (hiperbólico), Thaler-Shefrin, Parfit, Wrosch, McAdams, Ricoeur (ipse/idem) |
| [theories/formal-reconciliation.md](theories/formal-reconciliation.md) | P2 | AGM/Hansson, entrincheiramento, TMS/ATMS, PROV, Dung/ASPIC+/bipolar, QBAF, paraconsistência |
| [theories/discriminator-motor-bug.md](theories/discriminator-motor-bug.md) | P2 | info-sensibilidade, resíduo (Williams), hard/soft, Chang, Simon, Tetlock, Frankfurt, Higgins |
| [theories/data-sovereignty.md](theories/data-sovereignty.md) | P3 | Solid/PDS (fracasso), local-first (Ink&Switch/CRDTs), FL+DP, W3C VC, gradient-inversion |
| [theories/privacy-engineering.md](theories/privacy-engineering.md) | P4 | Privacy-by-Design, LINDDUN, Contextual Integrity, SD-JWT/BBS/ZKP, DP budget, Staab (inferência) |
| [theories/inference-defense.md](theories/inference-defense.md) | P5 | scrubbing insuficiente, FgAA/INTACT/TRACE-RPS, AskSafely, CI-CoT, C-Trace, Deng (feature/fronteira) |

**Camada 2 — derivação Onion (cita a camada 1):**

| Arquivo | Passada | O quê |
|---|---|---|
| [applications/vertical-model-pessoal.md](applications/vertical-model-pessoal.md) | P1 | modelo candidato (domínio × C/H/A × cultura) |
| [applications/reconciliation-engine.md](applications/reconciliation-engine.md) | P2 | spec do motor (compromisso≠fato · discriminador 3-órgãos · anti-auto-engano) |
| [marcio.kg.yaml](marcio.kg.yaml) | P1 (executável) | as verticais como grafo de **domínio** |
| [reconciliation-engine.kg.yaml](reconciliation-engine.kg.yaml) | P2 (executável) | o **motor** como grafo de **domínio** |
| [fronteira-decision.kg.yaml](fronteira-decision.kg.yaml) | P3 (executável) | a decisão da fronteira como grafo de **audit** (opções + REFUTES + decision) |
| [membership-marcio-pessoal.yaml](membership-marcio-pessoal.yaml) | P3 | entrada **hipotética** de `members.yaml` (standalone+regulated, trust zerado) |
| [classification-por-vertical.kg.yaml](classification-por-vertical.kg.yaml) | P4 (executável) | a **política de privacidade** por vertical como grafo de **domínio** (private/protected + gap de inferência) |
| [inference-mitigation.kg.yaml](inference-mitigation.kg.yaml) | P5 (executável) | a **mitigação de inferência** como grafo de **domínio** (6 camadas na fronteira + o gap irredutível) |

## Dogfood

```bash
bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/marcio.kg.yaml               # P1
bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/reconciliation-engine.kg.yaml # P2
bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/fronteira-decision.kg.yaml    # P3
```

Todos: **INTEGRIDADE exit 0** · **RECONCILIAÇÃO** mostra os `REFUTES`. O nó mais central de cada grafo é a
sua tese-núcleo: P1 → a invariante de **incomensurabilidade**; P2 → o **compromisso como objeto de 1ª classe**;
P3 → **membro pelo método, soberano no dado** (com as 2 opções rejeitadas refutadas). P1/P2 são camada
**domain** (⚠ estado-absorvente esperado); P3 é camada **audit** (uma decisão pura).
