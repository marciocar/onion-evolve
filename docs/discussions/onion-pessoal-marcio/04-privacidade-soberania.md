---
title: "P4 — Privacidade / soberania (o dado mais sensível que existe)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/onion-pessoal-marcio
lente: "Aristóteles (a régua) + Hegel (o motor)"
ancora_pesquisa: research/SYNTHESIS-P4.md
constroi_sobre: [01-verticais-peer.md, 02-reconciliacao.md, 03-fronteira-core.md]
---

# 🧵 P4 — Privacidade / soberania

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> **Derivação (camada 2):** consome [research/SYNTHESIS-P4.md](research/SYNTHESIS-P4.md); constrói sobre P1–P3.
> **Fecha as 4 perguntas do SEED.** Régua aplicada ao método: interna (a maquinaria do Onion) + 1 toque externo.

**Pergunta do SEED:** *o KG pessoal é o dado mais sensível que existe — como o `exposes:`/`de-identification` se aplica?*

---

## O veredito, em uma frase

> **A postura do Onion já é a certa; faltam cinco peças; a mais grave não tem cifra — a inferência.**
> A doutrina fail-safe do Onion (`none` recusa, VETO not skip, `fail-safe > fail-open`, `private` inviolável)
> **é** o "errar para não-vazar" que o estado-da-arte de 2026 prescreve. Mas o KG de vida N=1 precisa de cinco
> peças novas/ativadas — e o elo mais fraco é **o próprio motor inferindo o não-declarado**.

---

## 1. O que já transfere (a maquinaria do Onion aplicada)

A P4 não reinventa privacidade — o Onion já tem a espinha (detalhe em [SYNTHESIS-P4.md §1](research/SYNTHESIS-P4.md)):

- **`de-identification` `none` fail-safe** — recusa redigir-e-passar (não é no-op); exige override humano
  explícito e auditável (`allowUnredacted`). "Na dúvida, não vaze."
- **secret-handling** — o agente **nunca** vê segredo em texto claro; projeta o fluxo para não precisar ver.
- **6 níveis de classificação** (`private·protected·peer·downstream·public·collective`) + `mode: regulated` →
  default `protected`, promoção exige revisão humana.
- **`exposes:` allow-list** + `private` inviolável mesmo para o core + **fail-safe > fail-open** + "declarado ≠
  verificado" (VETO na ausência de prova).

A régua confirma: para o dado mais sensível, "errar para não-vazar" **já é** a doutrina. O que falta é o resto do stack.

---

## 2. A síntese própria da P4 — classificação POR VERTICAL (P1 × P4)

O Onion classifica **por entrada** (migalha a migalha). Um KG de vida precisa de sensibilidade **por vertical** —
porque ela **não é uniforme** — e refinada pelo **pior caso de inferência**:

| Vertical (P1) / camada | Sensibilidade | Default | Por quê |
|---|---|---|---|
| **`ipse` / fio-de-promessa** (P2) | **máxima** | `private` — nunca sai | o self-que-promete é introspecção pura, o dado mais íntimo |
| **Relações/vínculo** | máxima | `private` | expõe **terceiros** não-consentidos (dado de outros) |
| **Saúde/vitalidade** | alta | `private` | categoria especial (GDPR art. 9) |
| **Sentido/valores/crença** | alta | `private`/`protected` | foro íntimo |
| **Trabalho/realização** | média | `protected` | mas pode **inferir** as de cima |
| **Recursos/finanças** | média-alta | `protected` | |

> **Regra-mãe (Contextual Integrity + inferência):** um destilado herda a sensibilidade do que ele permite
> **INFERIR**, não do que literalmente contém. Carreira aparentemente inócua pode revelar saúde por linkage —
> logo o classificador é **por inferência, não por rótulo**, e **context-aware** (o mesmo fato é apropriado num
> fluxo e vazamento em outro).

Isto responde diretamente à Q4 do enquadramento original: o `ipse` que a P2 introduziu é, por classificação, o
**mais protegido de tudo** — nunca sai, nem destilado, sem gate humano triplo.

---

## 3. As cinco peças que faltam (o stack de 6 camadas aplicado)

O estado-da-arte externo dá um stack de 6 camadas (armazenamento · classificação · minimização · disclosure ·
orçamento · threat-model — [SYNTHESIS-P4.md §2](research/SYNTHESIS-P4.md)). Cruzado com o que o Onion já tem:

| Camada | Onion tem? | Gap / peça |
|---|---|---|
| **1. Armazenamento** local-first, sem cópia bruta; **não-retenção > cifra** (contra subpoena) | ✅ (P3: `private`, entrega-sem-commit) | reforçar: AES-256 at-rest |
| **2. Classificação** por inferência + Contextual Integrity | ⚠️ parcial (por-entrada) | **estender** por-vertical + por-inferência (§2) |
| **3. Minimização** (purpose limitation) | ✅ postura | formalizar o teto por propósito |
| **4. Disclosure** = predicado provado (**SD-JWT VC / BBS / ZKP**) | ❌ | **novo** — o canal do destilado (a peça da P3) |
| **5. Orçamento de privacidade (ε)** — *budget ledger* monotônico | ❌ (`review_after` é parente distante) | **novo** — "só destilado sai" repetido reconstrói |
| **6. Threat model** (LINDDUN; **o agente é vetor**) | ⚠️ (tem a2a-verify) | adotar LINDDUN recorrente; tratar o LLM como vetor |

**As cinco peças novas/ativadas:** (a) ativar o **`local-slm`** (PII contextual — hoje gated); (b) **disclosure
seletivo** (SD-JWT VC/BBS); (c) **budget ledger de ε**; (d) **classificação por-vertical + por-inferência**; (e) —
a mais grave — **mitigação de inferência**.

---

## 4. O elo mais fraco: a inferência (e não há cifra que a cubra)

O achado que a P4 crava, e que **subverte a celebração da P1**:

> Na P1 celebramos o **grounding ≠ guidance**: o KG *aterra* o raciocínio do transformer sobre "você". A P4
> mostra o **lado sombrio**: o transformer que aterra também **infere** — um LLM sobre o KG deduz atributos
> sensíveis **que você nunca inseriu** (Staab et al., ICLR 2024: 85–95%). Deduz uma condição de saúde de padrões
> de compromissos + relações + notas de carreira.

Consequências duras:
- O `de-identification` redige **strings** de PII (regex); **não faz nada** contra inferência. Nenhuma cifra
  protege contra um modelo que raciocina sobre o próprio grafo.
- O **próprio ato de consultar** o KG com um modelo (mesmo local) gera artefatos inferidos que precisam entrar
  no budget e no threat model — **consultas locais não são "internas e seguras" por serem locais**.
- Por isso a classificação tem que ser **pelo pior caso de inferência** (§2), e o agente é **parte do threat model**.

A P4 **não resolve** o gap de inferência — ela o **nomeia** como o elo mais fraco e sem mecanismo hoje. Declarar o
Onion pessoal "privado" sem endereçar inferência seria **falsa distinção às avessas**.

---

## 5. A configuração de proteção recomendada (concreta)

Estende a entrada de membro da P3 ([proto/membership-marcio-pessoal.yaml](proto/membership-marcio-pessoal.yaml)),
agora com a classificação por vertical. Modelo executável em
[proto/classification-por-vertical.kg.yaml](proto/classification-por-vertical.kg.yaml):

- **Bruto** = local-first, AES-256, `private`, **nunca copiado** (não-retenção > cifra).
- **Classificação por vertical** (§2): `ipse`/relações/saúde/crença = `private`; trabalho/recursos = `protected`.
- **`de-identification`** = `none` fail-safe por default; ativar `local-slm` no alvo para PII contextual (gap #1).
- **Saída** = só predicado provado (SD-JWT VC), debitando um **budget de ε** monotônico; budget incerto = **não sai**.
- **Threat model** = LINDDUN recorrente; **o LLM que lê o KG é vetor** (classificar por inferência, contabilizar consultas).
- **Gate humano** em todo ato irreversível de exposição (herdado: responder-gated, entrega-sem-commit).

---

## 6. Honestidade (o fecho)

- **Caveat intra-órbita (P1 §11):** inalterado — a P4 decide *proteção*, não move o north-star.
- **Lacuna da pesquisa externa:** "local-first como defesa a subpoena" é **dedução arquitetural**, não paper.
- **O gap de inferência é nomeado, não fechado** — é a fronteira aberta mais importante que as 4 passadas deixam.

---

## Fecho das 4 perguntas do SEED

| | Pergunta | Resposta |
|---|---|---|
| **P1** | Verticais peer de uma pessoa | arquitetura: domínio × C/H/A ortogonal × cultura transversal (derivada, não postulada) |
| **P2** | O que reconcilia (metas×ações, passado×presente) | o motor: compromisso≠fato, discriminador 3-órgãos, anti-auto-engano (DEV×PROD) |
| **P3** | Fronteira com o core: adotante × privado | **falsa dicotomia** — membro pelo método, soberano no dado |
| **P4** | Privacidade/soberania | postura certa; 5 peças faltam; **a inferência é o elo sem cifra** |

**A grande fronteira aberta que a discussão deixa:** a **mitigação de inferência** — o próprio motor que dá vida ao
Onion pessoal (o transformer sobre o KG) é também seu maior risco de privacidade. É o próximo tema, se o maestro quiser.

## Dogfood

```bash
bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/classification-por-vertical.kg.yaml
```
