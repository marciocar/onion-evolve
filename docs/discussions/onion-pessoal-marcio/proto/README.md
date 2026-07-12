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

| Arquivo | Camada | O quê |
|---|---|---|
| [theories/whole-person-models.md](theories/whole-person-models.md) | 1 | SDT, PERMA, Ryff (+colapso), WHOQOL, Nussbaum, Berlin, Maslow-renovado |
| [theories/competency-cha.md](theories/competency-cha.md) | 1 | McClelland/Boyatzis/Spencer (iceberg), CHA (Parry), Le Boterf/Zarifian, skills-graph 2022-2026 |
| [theories/behavior-intention-action.md](theories/behavior-intention-action.md) | 1 | Sheeran (lacuna), inclined abstainers, Gollwitzer, Fogg, COM-B, Locke&Latham (SRL/PLEA por referência) |
| [theories/culture-as-axis.md](theories/culture-as-axis.md) | 1 | Hofstede, Schwartz, Haidt, WEIRD (Henrich), Oishi (a prova-mãe) |
| [theories/hegel-dialectics.md](theories/hegel-dialectics.md) | 1 | Aufhebung, negação determinada, correção Chalybäus/Fichte, Priest×Brandom, Bildung |
| [applications/vertical-model-pessoal.md](applications/vertical-model-pessoal.md) | 2 | **Nossa** derivação: o modelo candidato (domínio × C/H/A × cultura), PLAUSÍVEL/open |
| [marcio.kg.yaml](marcio.kg.yaml) | 2 (executável) | O modelo como grafo de **domínio** — passa no `kg-radar.sh` |

## Dogfood

```bash
bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/marcio.kg.yaml
```

Esperado: **INTEGRIDADE exit 0** · **RECONCILIAÇÃO** mostra o `REFUTES` (declarado×vivido de Saúde,
superado-preservado = Aufhebung) · **RADAR-DE-DOMÍNIO** aponta ⚠ (estado-absorvente) — lacuna
*esperada* num esqueleto-hipótese, que vira agenda da P2. O nó mais central é a invariante de
**incomensurabilidade** — a pré-condição peer é, literalmente, o coração do modelo.
