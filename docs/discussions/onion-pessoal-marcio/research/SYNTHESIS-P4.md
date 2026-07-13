# Síntese de pesquisa P4 — Privacidade / soberania (Onion pessoal)

> Data: 2026-07-12 · Branch `discuss/onion-pessoal-marcio` · 2 frentes (1 interna: maquinaria de privacidade do Onion · 1 externa: engenharia de privacidade, ~20 fontes) · Âncoras: **Aristóteles** (a régua) + **Hegel** (o motor) · **Fecha as 4 perguntas do SEED.**
>
> **Régua aplicada ao método** (como na P3): P4 é majoritariamente **interna** (o Onion já tem `de-identification` SDAAL, secret-handling, níveis de classificação, `exposes:`, fail-safe) + 1 toque externo (o "como" técnico). A P3 já resolveu *onde* o dado vive; a P4 aprofunda *como* protegê-lo.

---

## 0. Veredito (a postura está certa; faltam 5 peças; a mais assustadora é a inferência)

A **postura** de privacidade do Onion já é exatamente a que o estado-da-arte de 2026 prescreve — a
convergência da P3 se repete: `none` fail-safe (recusa, não degrada), `a2a-verify` veta relógio
não-confiável, `fail-safe > fail-open` invariante, `private` inviolável mesmo para o core, "declarado ≠
verificado". Tudo isto **é** o "errar para não-vazar".

Mas aplicar ao KG de vida N=1 expõe **cinco gaps** — e o mais grave não tem cifra:

1. **Inferência (o elefante, sem mecanismo hoje):** um LLM sobre o KG deduz dado sensível **não-declarado**
   (Staab et al., ICLR 2024: 85–95%). O `de-identification` redige *strings* de PII (regex), mas **não faz
   nada** contra o transformer inferir uma condição de saúde de padrões de compromissos+relações. **O maior
   risco do Onion pessoal é o próprio motor raciocinando sobre o grafo** — o lado sombrio do grounding≠guidance.
2. **PII contextual não-redigível hoje:** o `regex` cobre formato fixo (CPF/email/telefone); a PII
   contextual (nomes, endereços, **relações**) precisa do `local-slm` — que está **spec'd/gated**. Um life-KG
   é *feito* de PII contextual → a redação que ele mais precisa não está viva.
3. **Sem orçamento de privacidade (ε):** "só destilado sai" **repetido no tempo** reconstrói o grafo
   (composição da DP). N=1 é o **pior caso** da DP (não há agregado onde se esconder). Falta um *budget ledger*.
4. **Sem disclosure seletivo:** o destilado deveria sair como **predicado provado** (SD-JWT VC / BBS / ZKP),
   não como payload. Peça nova (a P3 já a nomeou).
5. **Classificação por-entrada, não por-vertical nem por-inferência:** o Onion classifica migalha a migalha;
   um life-KG precisa de sensibilidade **por vertical** *e* **pelo pior caso de inferência**.

---

## 1. A maquinaria interna que TRANSFERE (aplicável já)

Fontes: `.claude/utils/de-identification/*` + ADR `onion-adr-slm-as-tool-de-identification-2026-06.md`;
`docs/knowledge-base/concepts/secret-handling-agent.md`; RFC-0003 §2.2/§2.3; `.claude/utils/trust/adapters/source.md`; `a2a-verify.sh`.

- **`de-identification` `none` fail-safe** — não é no-op: **recusa** redigir-e-passar, exige `allowUnredacted:true`
  (override humano explícito e auditável). "Compliance falha seguro: na dúvida, não vaze." Contrato de
  reversibilidade `restore(redact(t))===t` (placeholders tipados/numerados, reidentificação consistente).
- **Fronteira runtime-vs-ferramenta** — o SLM entra **como ferramenta atrás de adapter**, nunca orquestrador;
  roda **no alvo**, nunca no core (invariante de honestidade).
- **secret-handling-agent** — o agente **nunca** aceita segredo em texto claro no chat (persiste em
  transcript/log); projeta o fluxo para **não ver** o segredo (capability-split → terminal real → cache curto
  → fora-de-banda → container).
- **6 níveis de classificação** (RFC-0003 §2.2: `private·protected·peer·downstream·public·collective`) +
  `mode: regulated` → default `protected`, promoção a public/collective exige revisão humana explícita.
- **`exposes:` allow-list** + "o que o core NUNCA expõe" + `private` inviolável.
- **fail-safe > fail-open** (RFC-0004 §5) e **clock-untrusted → VETO** (a2a-verify): ausência de prova nunca é
  aprovação. "Declarado ≠ verificado" para todo dado auto-declarado.

---

## 2. O stack externo de 6 camadas (o "como", ~20 fontes)

Detalhe fiel em [proto/theories/privacy-engineering.md](../proto/theories/privacy-engineering.md).

| # | Camada | Mecanismo canônico | Fecha (LINDDUN) |
|---|---|---|---|
| 1 | **Armazenamento** | local-first/on-device; AES-256 at-rest, TLS 1.3; **sem cópia bruta** | breach; **compulsão legal** (não-retenção > cifra) |
| 2 | **Classificação** | por **inferência**, não só por campo (Staab); Contextual Integrity (Nissenbaum: fluxo apropriado, não segredo) | Identifiability, Unawareness |
| 3 | **Minimização** | purpose limitation → data minimization (GDPR art. 5); "não retenha o que não precisa provar" | secondary use, Non-compliance |
| 4 | **Disclosure** | só **predicado provado**: SD-JWT VC (maduro/eIDAS) · BBS/ZKP (unlinkable) | Linkability, Non-repudiation |
| 5 | **Orçamento (ε)** | **privacy budget ledger** monotônico (PrivateKube): cada release debita ε; composição entre sessões; budget 0 = pare | Linkability por composição |
| 6 | **Threat model** | **LINDDUN** recorrente; **o próprio agente/LLM é vetor** (CI para agentes) | as 7 (camada meta) |

Princípios "by design" (Cavoukian) e minimização são **norte, não mecanismo** — e "by design" vira slogan sem
controle testável (Ruohonen, 2025). **A inferência é o elo mais fraco:** nenhuma cifra protege contra um modelo
que raciocina sobre o próprio grafo.

---

## 3. A síntese própria da P4 — classificação POR VERTICAL (P1 × P4)

O achado que só a P4 podia dar, cruzando as verticais da P1 com os níveis da RFC-0003 e o alerta de inferência:
a sensibilidade **não é uniforme**, e o rótulo tem que ser **por vertical + pior-caso-de-inferência**, não por campo.

| Vertical (P1) / camada | Sensibilidade | Classificação default | Nota |
|---|---|---|---|
| **`ipse` / fio-de-promessa** (P2) | **máxima** | `private` (nunca sai) | o self-que-promete é o dado mais íntimo — introspecção pura |
| **Relações/vínculo** | máxima | `private` | expõe terceiros (não-consentidos) — dado de outros |
| **Saúde/vitalidade** | alta | `private` | categoria especial (GDPR art. 9) |
| **Sentido/valores/crença** | alta | `private`/`protected` | crença é foro íntimo |
| **Trabalho/realização** | média | `protected` | mas pode **inferir** as de cima → herda sensibilidade |
| **Recursos/finanças** | média-alta | `protected` | |

Regra-mãe (Contextual Integrity + inferência): **um destilado herda a sensibilidade do que ele permite
INFERIR, não do que literalmente contém.** Carreira aparentemente inócua pode revelar saúde por linkage → o
classificador é *por inferência*, não *por rótulo*.

---

## 4. Tradução Onion (o que transfere / o que é novo)

| Peça externa | Doutrina Onion | Veredito |
|---|---|---|
| errar para não-vazar; fail-closed | `none` fail-safe; `fail-safe>fail-open`; VETO not skip | **IGUAL** — já é |
| non-retention > encryption | entrega-sem-commit (I3); local-first; `private` inviolável | **IGUAL** |
| classificação de sensibilidade | 6 níveis RFC-0003 + regulated | **IGUAL** (base) / **estender** por-vertical + por-inferência |
| PII contextual (nomes/relações) | `de-identification` `local-slm` | **gated** — ativar (o gap #2) |
| disclosure = predicado (SD-JWT/BBS/ZKP) | — | **DIFERENTE / novo** (a peça da P3) |
| privacy budget ledger (ε) | `review_after` do diário (parente distante) | **DIFERENTE / novo** |
| **mitigação de inferência** | — | **DIFERENTE / novo — e sem mecanismo hoje** (o gap mais grave) |

---

## 5. Ameaças à validade / caveat herdado

- **Caveat intra-órbita (P1 §11):** inalterado — P4 decide *proteção*, não move o north-star.
- **Lacuna honesta da pesquisa externa:** "local-first como defesa a subpoena" é **dedução arquitetural**
  (non-retention + minimização), não achado publicado citável — tratar como raciocínio, não paper.
- **O gap de inferência não é resolvido — é nomeado.** A P4 não entrega um mecanismo anti-inferência; entrega
  o *reconhecimento* de que ele falta e de que é o elo mais fraco. Declarar o Onion pessoal "privado" sem
  endereçar inferência seria falsa distinção às avessas.

---

## Fontes

**Interno:** `.claude/utils/de-identification/{interface,factory,detector,adapters/*}.md` · `scripts/redact-deterministic.sh` ·
`docs/analysis/onion-adr-slm-as-tool-de-identification-2026-06.md` · `docs/knowledge-base/concepts/secret-handling-agent.md` ·
RFC-0003 §2.2/§2.3 · RFC-0004 §5 · `.claude/utils/trust/adapters/source.md` · `.claude/utils/federation-transport/a2a-verify.sh`.

**Externo:** detalhe datado em [proto/theories/privacy-engineering.md](../proto/theories/privacy-engineering.md) —
Cavoukian (2009); Ruohonen (2025); GDPR art. 5/25; Nissenbaum Contextual Integrity (2004); LINDDUN/NIST; SD-JWT VC & BBS (IETF/IRTF, 2026);
Camenisch-Lysyanskaya/AnonCreds; DP composição & PrivateKube; **Staab et al. ICLR 2024** (inferência).

**Base:** P1 ([SYNTHESIS.md](SYNTHESIS.md)) · P2 ([SYNTHESIS-P2.md](SYNTHESIS-P2.md)) · P3 ([SYNTHESIS-P3.md](SYNTHESIS-P3.md)).
