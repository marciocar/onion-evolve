---
title: "P3 — A fronteira com o core (adotante × privado)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/onion-pessoal-marcio
lente: "Aristóteles (a régua) + Hegel (o motor)"
ancora_pesquisa: research/SYNTHESIS-P3.md
constroi_sobre: [01-verticais-peer.md, 02-reconciliacao.md]
---

# 🧵 P3 — A fronteira com o core (adotante × privado)

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> **Derivação (camada 2):** consome [research/SYNTHESIS-P3.md](research/SYNTHESIS-P3.md) e constrói sobre P1/P2.
> Natureza diferente de P1/P2 (**a régua aplicada ao método**): P3 é decisão de arquitetura **dentro da doutrina de
> federação que o Onion já tem** — evidência majoritariamente interna; a pesquisa externa entra só na soberania de dado.

**Pergunta do SEED:** *o Onion pessoal é instância adotante na federação, ou algo à parte (privado)?*

A resposta desmonta a pergunta: **a dicotomia é falsa.**

---

## O veredito, em uma frase

> **Membro adotante PELO MÉTODO, soberano NO DADO.** O Onion pessoal é uma instância adotante (`role: standalone`,
> `mode: regulated`) — **dentro** da federação — porque **privacidade ≠ sair da federação**. O KG bruto **nunca
> federa** (fica local, `private` inviolável); só **destilado** circula, por opt-in gated. É *ao mesmo tempo* a
> doutrina "entrega-sem-commit / destilado, nunca o bruto" do Onion **e** o consenso pragmático de 2026 (local-first
> + federated-learning/DP + Verifiable Credentials). **A convergência interna×externa é o resultado forte da P3.**

---

## 1. Por que a dicotomia é falsa: privacidade e federação são eixos independentes

O SEED opõe "adotante na federação" **×** "à parte (privado)", como se fossem mutuamente exclusivos. A doutrina do
trust prova que **não são**:

> `.claude/utils/trust/adapters/source.md`, invariante 3: *"Soberania local — `private` inviolável mesmo para o core."*
> **Nem o core lê `private` de outro membro, em nenhuma circunstância.**

Logo um membro pode ser **máximo-privado E membro pleno** ao mesmo tempo — é exatamente o que o precedente **`granaai`**
(regulated) faz: `diary_readable_by: []`, `diary_classifications_shared: []`, default de classificação `protected`.
Estar na federação não expõe nada que o membro não escolha expor. "Privado" não custa a federação — custa **zerar dois
campos de trust e confiar na imutabilidade de `private`**.

As três posições que a doutrina oferece, e o veredito:

| Posição | O que é | Precedente | Veredito |
|---|---|---|---|
| **A. Adotante T3 standalone + `regulated`** | vendoriza `.claude/`, entra no `members.yaml`, trust zerado | `granaai` | ✅ **RECOMENDADA** |
| **B. `--in-place` (fora da federação)** | não instala, não carimba, "à parte" por construção | — | ❌ custa o método (co-evolução, updates) sem ganho real de privacidade |
| **C. Destilação curada** | `onion_version: n/a`, não vendoriza — *cita*, não *vive* | `onion-mini` | ❌ é para destilar doutrina, não para viver o método N=1 |

A posição B é a leitura ingênua de "à parte" — e ela **perde** o que importa (receber updates do core, co-evoluir,
usar os comandos) **sem comprar** privacidade que a posição A não já dê. Falsa distinção.

---

## 2. O criador-como-membro não tem privilégio (e a doutrina já prova)

O medo natural: *"o criador vira membro e ganha bypass; a federação aprende um padrão que ninguém pode seguir."* A
doutrina existente **dissolve** isso:

- **"Trust elevado, não role elevado"** — o `granaai` mereceu mais confiança por rigor comprovado, e a doutrina
  **recusou** elevar o papel: *"NÃO tem role:source próprio (fonte≠derivação: uma só fonte)"*. O criador-como-membro
  ganharia, no máximo, campos `trust:` generosos — **nunca** role `source` nem bypass.
- **"Declarado ≠ verificado", sem exceção para o dono** — as próprias instâncias do Marcio **já foram pegas** com pin
  **forjado** (`a458a0fc`, detectado por `pin-integrity-check.sh`) e data re-carimbada. Tratadas com o mesmo rigor. Um
  Onion pessoal passaria pelo mesmo gate — o sistema **já demonstrou** que não abre exceção para o criador.
- **`fonte≠derivação` aplicada à soberania** — o core (T0) é a **única fonte**; o Onion pessoal é **derivação que
  cita**. **Marcio-criador e Marcio-membro são camadas separadas**, mesmo sendo a mesma pessoa. (O mesmo princípio que
  separou `theories/` de `applications/` nas P1/P2, agora aplicado a papéis.)

Isto responde, de frente, a Q4 do enquadramento original ("o criador-como-membro não pode ter privilégio de bypass"):
**não tem — e não por promessa, por mecanismo já rodando.**

---

## 3. Pessoa ≠ repo de software — o gap real que a P3 nomeia

O framework **só adota repositórios de software** (`onion-adoption-manual.md`: *"template que se instala em `.claude/`
de qualquer repositório de software"*; `/meta:adopt` recebe *"repositório/pasta"*). Não há caminho para domínio
não-código. A tradução para o Onion pessoal:

- **A pessoa não é o alvo de adoção** — o alvo é um **repo git dedicado que hospeda o KG da vida** (`.kg.yaml`
  versionado, exatamente como os protos das P1/P2). O Marcio-pessoa não "adota" o Onion; o **repo do cérebro dele** adota.
- **O que viaja é o método, não a máquina** — KG SDAAL (schema + radar) aplica-se a qualquer domínio; a máquina de
  adoção de repo de código não precisa ir junto (coerente com o cold-adopter: *"o método viaja como schema+método,
  não código"*).
- **É um gap de doutrina** — "adotar o Onion para um domínio não-software" não tem guia (`applying/` só cobre
  greenfield/legacy/regulated de *código*). A P3 **nomeia** o gap; desenhá-lo é trabalho futuro (um 4º guia,
  `applying-personal` ou similar — gated, não agora).

---

## 4. O estado-da-arte externo confirma o híbrido — e a convergência é o achado

Não decidi isto pelo umbigo do Onion. A pesquisa externa (soberania de dado pessoal, ~20 fontes — detalhe em
[proto/theories/data-sovereignty.md](proto/theories/data-sovereignty.md)) chega **independentemente** à mesma
arquitetura:

- **Federar dado pessoal fracassou** em adoção (Solid, PDS, MyData, SSI: spec madura, massa nunca veio).
- **Local-first amadureceu** e dá o argumento duro: dado no próprio disco é **irrevogável e incoercível**.
- **"Share distilled, keep raw local"** é o padrão vencedor (federated learning + differential privacy), com **W3C
  Verifiable Credentials v2.0** (2025) como o mecanismo maduro de *destilado verificável* — provar um fato sem entregar
  a fonte.
- **Alerta que aperta o rigor:** *destilado ≠ seguro* (gradient inversion reconstrói o bruto) → **erra para não-sair.**

A tradução Onion (régua Aristóteles):

| Estado-da-arte 2026 | Doutrina Onion | Veredito |
|---|---|---|
| local-first radical (bruto irrevogável) | `private` inviolável mesmo p/ o core | **IGUAL** — transfere |
| share distilled, never raw (FL/DP) | entrega-sem-commit / "destilado, nunca o repo bruto" (RFC-0004, I3) | **IGUAL** |
| default fechado; abrir é ato explícito por destinatário | `mode: regulated` + classificação por entrada + gate humano | **IGUAL** (granaai) |
| destilado é poroso → erra p/ não-sair | `de-identification` `none` fail-safe (recusa, não degrada) | **IGUAL** |
| **Verifiable Credentials** (provar fato sem dar a fonte) | — | **DIFERENTE / novo** — peça a adotar |
| adoção de **domínio não-software** | `/meta:adopt` só faz repo de código | **DIFERENTE / gap** a desenhar |

Que a doutrina interna e a arte externa **converjam sem se conhecerem** é a validação mais forte que a P3 podia ter —
o Onion já é, por acidente de doutrina, o que o campo de soberania de dado pessoal recomenda para N=1.

---

## 5. A configuração recomendada (concreta)

O Onion pessoal registra-se como (sandbox em [proto/membership-marcio-pessoal.yaml](proto/membership-marcio-pessoal.yaml)):

- `role: standalone` · `parent: onion-evolve` · `mode: regulated` (nada sobe sem gate humano)
- `trust:` **zerado para exposição** — `diary_readable_by: []`, `diary_classifications_shared: []`, `exposes_downstream: []`
- **KG bruto** = `private` (inviolável, local-first, no device/VPS que o Marcio controla)
- **O que pode sair** (opt-in gated, destilado empobrecido): sinais de método (bugs/feedback do dogfood, como
  qualquer adotante), migalhas `public`/`collective` **só após revisão humana**, e — peça nova — **claims verificáveis**
  (VC) que provam um fato derivado sem entregar o KG.
- **Onde vive:** decisão das discussões irmãs (`onion-mobile-app` = superfície, `behavior-mapping-kg` = sensor) —
  device (local-first puro) / cliente-do-bridge / clone-no-VPS; princípio herdado: **soberania e de-identification
  ANTES do "como"**.

Modelo executável da decisão em [proto/fronteira-decision.kg.yaml](proto/fronteira-decision.kg.yaml) (grafo de audit:
as 3 opções como claims, a rejeitada por `REFUTES`, a escolhida como `decision`).

---

## 6. Honestidade (herdada)

- **Caveat intra-órbita (P1 §11):** o Onion pessoal do Marcio é o **centro da órbita** — prova de mercado **zero**
  (`Q_COLD_ADOPTER`). A P3 decide a *arquitetura da fronteira*; **não** move o north-star. Dogfood do método, não pull.
- **Incerteza externa (média):** *quanto* empobrecer o destilado não tem número fechado (destilado≠bruto é poroso) —
  regra: **na dúvida, não sai** (o `none` fail-safe).

---

## Ponte para a P4

A P3 fixou **onde** o dado vive (local, soberano) e **o que** pode circular (destilado, gated). A **P4** aprofunda o
*como* da proteção: classificação **por vertical** (saúde/relações/ipse >> carreira), `de-identification` `none`
fail-safe aplicado ao KG pessoal, `exposes:` afinado, e a peça nova que a P3 levantou — **Verifiable Credentials como
o formato canônico do destilado verificável**.

## Dogfood

```bash
bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/fronteira-decision.kg.yaml
```
