# Síntese de pesquisa P3 — A fronteira com o core (Onion pessoal)

> Data: 2026-07-12 · Branch `discuss/onion-pessoal-marcio` · 3 frentes (2 internas: doutrina de federação · tensão criador-como-membro; 1 externa: soberania de dado pessoal, ~20 fontes) · Âncoras: **Aristóteles** (a régua) + **Hegel** (o motor) · **Constrói sobre P1/P2**.
>
> **Natureza diferente de P1/P2** (régua aplicada ao método): P3 é decisão de **arquitetura dentro da doutrina que o Onion já tem** — a evidência é majoritariamente **interna** ao repo; a pesquisa externa entra só onde há arte real (soberania de dado pessoal). Disparar orquestração web ampla seria falsa analogia.

---

## 0. Veredito (o resultado é uma CONVERGÊNCIA)

A pergunta do SEED — *"o Onion pessoal é instância adotante na federação, ou algo à parte (privado)?"* — tem uma
**falsa dicotomia embutida**. A doutrina interna e o estado-da-arte externo **convergem** para a mesma resposta:

> **Membro adotante PELO MÉTODO, soberano NO DADO.** O Onion pessoal é uma **instância adotante** (`role: standalone`,
> `mode: regulated`) — dentro da federação — **porque privacidade ≠ sair da federação**. O KG bruto **nunca federa**
> (fica local, `private` inviolável); só **destilado** circula (sinais, migalhas, claims verificáveis), por opt-in
> gated. É *ao mesmo tempo* a doutrina "entrega-sem-commit / destilado, nunca o bruto" do Onion **e** o consenso
> pragmático de 2026 (local-first + federated-learning/DP + Verifiable Credentials). A convergência é o achado.

Três esclarecimentos que a P3 crava: **(1)** privacidade e pertencimento são **eixos independentes** (um membro pode
zerar o diário e seguir membro pleno — precedente `granaai`); **(2)** o criador **não** ganha bypass (precedente
"trust elevado, não role elevado"; `fonte≠derivação`: uma só fonte); **(3)** o alvo de adoção é um **repo que
hospeda o KG da vida**, não a pessoa — o que viaja é o método KG SDAAL, não a máquina de adoção.

---

## 1. As três posições que a doutrina já oferece (interno)

Fontes: `docs/knowledge-base/concepts/{onion-federation-and-adoption,federation-usage-modes}.md`,
`docs/evolution/federation/members.yaml`, `docs/evolution/rfc/rfc-0003-*.md`, `.claude/utils/trust/adapters/*.md`.

| Posição | Mecânica | Precedente | Veredito p/ Onion pessoal |
|---|---|---|---|
| **A. Adotante T3 standalone** | vendoriza `.claude/`, carimba `.onion-version` (adopted), entra no `members.yaml` | `pulse-mais`, `granaai` | **RECOMENDADA** (com `mode: regulated` + trust zerado) |
| **B. `--in-place` (efêmero)** | não instala, não carimba, **fora da federação por construção** | — | rejeitada — "à parte" custa o método (co-evolução, updates) sem ganho de privacidade real |
| **C. Destilação curada** | `role: standalone` mas `onion_version: n/a` — reescreve doutrina, não vendoriza | `onion-mini` | não se aplica (é para *citar/destilar*, não *viver* o método) |

**A chave que dissolve a dicotomia** (`.claude/utils/trust/adapters/source.md`, invariante 3): *"Soberania local
(`private` inviolável mesmo para o core)"* — **nem o core lê `private` de outro membro**. Logo "privado" **não exige**
sair da federação: exige `mode: regulated` + `diary_readable_by: []` + `diary_classifications_shared: []` (o que o
`granaai` já faz) + confiar na imutabilidade de `private`. Os seis níveis de classificação (RFC-0003 §2.2:
`private·protected·peer·downstream·public·collective`) dão o controle fino.

---

## 2. Criador-como-membro: sem privilégio, sem bypass (interno)

O medo de soberania ("o criador vira membro e tem privilégio") **é dissolvido pela doutrina existente**:

- **"Trust elevado, não role elevado"** (`members.yaml`, precedente `granaai`, linha 148): *"NÃO tem role:source
  próprio (doutrina fonte≠derivação: uma só fonte) — trust elevado (não role elevado) reconhece o rigor comprovado."*
  O criador-como-membro ganharia, no máximo, campos `trust:` mais generosos — **nunca** role `source` nem bypass.
- **"Declarado ≠ verificado" sem exceção para o dono:** as próprias instâncias do Marcio **já foram pegas** com pin
  forjado (`a458a0fc` FORJADO, detectado por `pin-integrity-check.sh`) e data re-carimbada (deslize contra a regra
  preserve). Tratadas com o mesmo rigor. Um Onion pessoal passaria pelo mesmo gate.
- **`fonte≠derivação` aplicada à soberania:** o core (T0) é a **única fonte**; o Onion pessoal é **derivação/instância
  que cita**. Marcio-criador e Marcio-membro são **camadas separadas**, mesmo sendo a mesma pessoa.

---

## 3. Pessoa ≠ repo de software (interno — um gap real)

O framework **só adota repositórios de software** (`docs/applying/onion-adoption-manual.md:50`: *"template que se
instala em `.claude/` de qualquer repositório de software"*; `adopt.md:4`: recebe *"repositório/pasta… caminho local
ou URL git"*). Não há caminho para domínio não-código. **O que muda:** a pessoa não é alvo de adoção — o alvo é um
**repo git dedicado que hospeda o KG da vida** (`.kg.yaml` versionado, como os protos das P1/P2). O que viaja é o
**método KG SDAAL** (schema + radar), não a máquina de adoção de repo — coerente com o cold-adopter (*"o método viaja
como schema+método, não código"*). É um **gap de doutrina** que a P3 nomeia (adoção de domínio não-software).

---

## 4. O estado-da-arte externo confirma o híbrido (externo, ~20 fontes)

**Veredito externo (confiança alta):** para o dado mais sensível que existe, a arte de 2026 recomenda **híbrido com
viés local-first radical** — nem local-only puro (perde toda alavanca de rede/prova) nem federação-de-store (o modelo
que **empiricamente fracassou**).

- **Federar dado pessoal fracassou em adoção** — Solid/pods, PDS, MyData, SSI amadureceram em *spec*, travaram em
  *massa*: exportar dado é penoso, o dado perde contexto fora da origem, e não há killer-app que só exista federando
  (Fallatah et al., Sensors 2023; Wikipedia/Solid 2025; repolex 2025). [conf alta]
- **Local-first foi o vetor que amadureceu** — CRDTs prontos (Automerge 3.0, mai/2025); e o argumento duro de 2026:
  dado no seu disco é **irrevogável e incoercível** ("um modelo no seu próprio disco não pode ser revogado" — após a
  diretriz de export-control de jun/2026). Piso, não teto. (Ink & Switch 2019; PowerSync 2025) [conf alta/média-alta]
- **"Share distilled, keep raw local" é o padrão vencedor** — federated learning + differential privacy; e o
  **mecanismo maduro de destilado verificável é o W3C Verifiable Credentials v2.0** (Recommendation, mai/2025):
  provar um fato derivado do KG com *selective disclosure*, **sem entregar o KG**. (EDPS TechDispatch 2025; W3C VC-DM 2.0) [conf alta]
- **O alerta que muda o rigor:** *destilado ≠ seguro.* Ataques de **gradient/model inversion** (2024-2026) reconstroem
  o bruto de gradientes/embeddings ricos; as defesas custam acurácia e não sabem *quais* gradientes vazam (USENIX
  Security 2025). **Consequência:** o destilado precisa ser *deliberadamente empobrecido* (minimização + orçamento DP
  + revisão do que sai); na dúvida, **não sai**. [conf alta]

Detalhe fiel das fontes em [proto/theories/data-sovereignty.md](../proto/theories/data-sovereignty.md).

---

## 5. A tradução Onion (o que transfere / o que é novo)

| Peça (estado-da-arte) | Doutrina Onion | Aristóteles |
|---|---|---|
| local-first radical (bruto irrevogável) | `private` inviolável mesmo p/ o core | **IGUAL** — transfere |
| share distilled, never raw (FL/DP) | entrega-sem-commit / "destilado, nunca o repo bruto" (RFC-0004, I3) | **IGUAL** |
| default fechado, abrir é ato explícito por destinatário | `mode: regulated` + classificação por entrada + gate humano | **IGUAL** (precedente granaai) |
| destilado é poroso → erra p/ não-sair | `de-identification` `none` fail-safe (recusa, não degrada) | **IGUAL** |
| **Verifiable Credentials** (provar fato sem dar a fonte) | — | **DIFERENTE / novo** — peça a adotar p/ o Onion pessoal |
| adoção de **domínio não-software** (repo do KG da vida) | `/meta:adopt` só faz repo de código | **DIFERENTE / gap** a desenhar |

---

## 6. Ameaças à validade / caveat herdado

- **Caveat intra-órbita (P1 §11, reafirmado):** o Onion pessoal do Marcio é o **centro da órbita** — prova de mercado
  **zero** (`Q_COLD_ADOPTER`). A P3 decide a *arquitetura* da fronteira; **não** move o north-star. Dogfood legítimo
  do método, não evidência de pull externo.
- **Incerteza externa residual (média):** *quanto* empobrecer o destilado não tem número fechado (a fronteira
  destilado≠bruto é porosa). Para dado dessa sensibilidade, a regra é **errar para não-sair**.
- **Argumento-por-omissão:** "federar store fracassou" é forte na evidência de adoção, mas o *futuro* de VC/eIDAS 2.0
  no trilho regulado ainda está em curva — a recomendação híbrida assume que o destilado-verificável amadurece, o bruto não.

---

## Fontes

**Interno (doutrina Onion):** `docs/knowledge-base/concepts/onion-federation-and-adoption.md` · `federation-usage-modes.md` ·
`docs/evolution/federation/members.yaml` · `docs/evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md` ·
`docs/evolution/rfc/rfc-0004-a2a-live-interop.md` · `.claude/utils/trust/adapters/{source,standalone}.md` ·
`docs/analysis/onion-adr-adopt-to-not-impose-2026-06.md` · `docs/analysis/onion-experiment-cold-adopter-2026-07.md` ·
`docs/knowledge-base/concepts/source-vs-derivation.md` · `docs/applying/onion-adoption-manual.md`.

**Externo (soberania de dado pessoal):** ver bibliografia datada em [proto/theories/data-sovereignty.md](../proto/theories/data-sovereignty.md)
— Ink & Switch (2019); PowerSync (2025); Solid/Inrupt (2025); Fallatah et al. Sensors (2023); arXiv 2504.10058 (2025);
W3C VC-DM 2.0 (2025); EDPS TechDispatch #1/2025; USENIX Security 2025 (gradient inversion); FPF (2026); Springer (2026).

**Base:** P1 ([SYNTHESIS.md](SYNTHESIS.md)) · P2 ([SYNTHESIS-P2.md](SYNTHESIS-P2.md)).
