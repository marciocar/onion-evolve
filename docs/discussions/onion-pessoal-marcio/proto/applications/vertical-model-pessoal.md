# Modelo candidato de verticais de uma pessoa — derivação Onion (camada 2)

> **Camada 2 — NOSSA derivação.** Cita a camada 1 ([`../theories/`](../theories/)), **nunca a reescreve**.
> Tudo aqui é **PLAUSÍVEL / open** — hipótese derivada da convergência acadêmica, não validada. Se uma
> ponte cair, a teoria (camada 1) não se contamina. Fonte da evidência: [`../../research/SYNTHESIS.md`](../../research/SYNTHESIS.md).

## A tese estrutural (não é uma lista)

A pergunta "quais as verticais?" resolve-se numa **arquitetura de três estruturas distintas** — tratá-las
igual seria erro de categoria:

```
                 ┌─ eixo transversal: CULTURA/VALORES ─┐  (re-pondera todas)
                 │                                      │
  vertical ──────┼──────────────────────────────────── ┼──── vertical
  de CONTEÚDO    │   cada vertical tem sua anatomia:     │    de CONTEÚDO
  (um domínio)   │   C/H/A (decomposição ortogonal)      │    (um domínio)
                 └─ eixo transversal: AUTONOMIA (SDT) ───┘  (o 'como' de cada uma)
```

- **Verticais de conteúdo** = os domínios de vida irredutíveis (os *peers* em tensão). O **quê**.
- **Eixos transversais** = atravessam e re-ponderam todas (autonomia/competência-processo do SDT;
  cultura/valores). O **como/quanto** — não são abas.
- **Decomposição ortogonal** = competência C/H/A aplicada *dentro* de cada vertical. A **anatomia**.

Deriva de: [whole-person-models](../theories/whole-person-models.md) (o quê),
[competency-cha](../theories/competency-cha.md) (a anatomia), [culture-as-axis](../theories/culture-as-axis.md)
(a ponderação). O grafo executável está em [`../marcio.kg.yaml`](../marcio.kg.yaml).

## Verticais de conteúdo candidatas

| Vertical | Sustentação (camada 1) | Status |
|---|---|---|
| **Relações/vínculo** | SDT-relacionamento; PERMA-R; Ryff; WHOQOL-social; Nussbaum-afiliação | núcleo convergente — **PLAUSÍVEL alta** |
| **Trabalho/realização** | PERMA A+E; Ryff; Locke&Latham; skills-graph | núcleo convergente — **PLAUSÍVEL alta** |
| **Sentido/propósito** | PERMA-M; Ryff-propósito; Nussbaum-razão-prática; ikigai | núcleo convergente — **PLAUSÍVEL alta** |
| **Saúde/vitalidade** | WHOQOL-físico; Nussbaum vida/saúde-corporal; Maslow-fisiológico | núcleo convergente — **PLAUSÍVEL alta** |
| **Recursos/finanças** | WHOQOL-ambiente; Nussbaum-controle-sobre-ambiente | **QUESTÃO ABERTA** — só 2 modelos isolam; peer ou subordinada a Trabalho? |
| **Espiritualidade/crença** | WHOQOL-SRPB; 4Bs de Saroglou | **QUESTÃO ABERTA** — dupla natureza (vertical ou lente) |

## O teste que decide "é vertical peer?"

Uma vertical é peer sse **irredutível** + **pode contradizer** as outras + **não-subordinável**. Dois
instrumentos derivados da pesquisa:

1. **Diagnóstico operacional:** dois candidatos com correlação **r>0,7** são o mesmo eixo (colapso de Ryff,
   Springer & Hauser 2006) → funde. Ver [whole-person-models](../theories/whole-person-models.md).
2. **Fundação honesta:** a irredutibilidade é **filosófica** (Nussbaum/Berlin — incomensurabilidade, "perda
   trágica"), **não psicométrica**. Modelada no grafo como a `invariant` `IN_INCOMENSURAVEL` com **status: open**
   — a pré-condição peer é fundamentada, mas não-testada psicometricamente.

## O que NÃO é vertical (e por quê)

| Candidato ingênuo | Veredito | Por quê |
|---|---|---|
| Competência / "skills" | **decomposição ortogonal** | todo domínio tem seu C/H/A (skill×contexto) — [competency-cha](../theories/competency-cha.md) |
| Cultura / geografia / crenças | **eixo de ponderação** | muda o *peso* de cada domínio, não é domínio (Oishi 1999) — [culture-as-axis](../theories/culture-as-axis.md); exceção: espiritualidade vivida |
| Autonomia | **eixo (SDT content-free)** | experimenta-se *dentro* de cada domínio; listá-la como aba é erro de categoria |

## Questões abertas (o design ainda decide)

1. **Recursos/finanças é peer?** Provável *sim* por irredutibilidade (Nussbaum), mas sub-teorizada. **Aberto.**
2. **Espiritualidade — vertical, eixo ou dupla natureza?** Recomendação: **domínio opcional de dupla natureza**.
3. **Vitalidade = 1 ou 2?** Física vs psicológica — o teste r>0,7 decide.

## Ponte para as próximas passadas (fora do escopo da P1)

O *diferenciador* não é esta lista — é a **reconciliação** (P2): o motor DEV↔PROD (intenção declarada ×
comportamento vivido), com o operador de Hegel (Aufhebung) e o discriminador contradição-motor vs
contradição-bug (Priest × Brandom). O grafo já traz **uma instância trabalhada** (a vertical Saúde:
declarado × vivido → `REFUTES` → superado-preservado), como gesto — não como o motor completo.
