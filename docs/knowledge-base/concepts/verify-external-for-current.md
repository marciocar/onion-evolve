# Verify-External-for-Current — atual/emergente/popular exige verificação web

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-19 | **Categoria**: Conceitos
> Uma **forcing function com gatilho explícito**: quando a pergunta/pesquisa toca algo **atual,
> emergente ou popular** (versão · device · projeto · player · framework · tendência), o loop **DEVE
> buscar informação externa** (web) **antes de afirmar** — nunca responder do conhecimento de cutoff.
> Sem verificar → **declarar "não verificado"** e parar. É `declarado≠verificado` afiado no mundo
> externo — o `verify(vivo)` do [SSOT-as-runtime](knowledge-graph-sdaal.md#ssot-as-runtime--o-kg-é-o-primeiro-ato-mecanismo-não-conselho)
> aplicado ao mundo, não só ao KG.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-19 |
| **Última Atualização** | 2026-07-19 |
| **Categoria** | Conceitos |
| **Origem** | Sinal de co-evolução (upstream) 2026-07-19, de um vertical privado do core — pedido explícito do maestro de recomendar ao core |
| **Padrão-parente** | [Knowledge Graph SDAAL](knowledge-graph-sdaal.md) §SSOT-as-runtime (a perna `verify(vivo)`) · [Fonte ≠ Derivação](source-vs-derivation.md) (família do `declarado≠verificado`) |

---

## 🎯 Propósito

O conhecimento de cutoff **envelhece** — e envelhece exatamente nas classes de fato que mais mudam:
versões de dependência, specs de device, quem são os players de um mercado, o estado de um framework,
uma tendência. Responder essas perguntas dos **priors** é apresentar uma verdade **incerta como
certa** — o pior modo de falha ([`worst-truth-is-uncertain`](#-ligações)).

A premissa: **o assistente não sabe de cabeça o que é atual.** Achar que sabe é a falha. A defesa não é
"lembrar de verificar" — é uma **forcing function** com gatilho nomeado, do mesmo tipo que o KG-first do
SSOT-as-runtime: mecanismo, não conselho.

---

## 🚦 A regra (o que exige, e nunca dispensa)

1. **Gatilho — o claim toca *current/emerging/popular*.** Concretamente: **versão** (de lib, SDK, runtime),
   **device** (specs de hardware recente), **projeto/player** (quem existe/lidera num espaço), **framework**
   (estado, features, breaking changes), **tendência** (o que está em alta agora). Qualquer um dispara.
2. **Ação obrigatória — buscar EXTERNO antes de afirmar.** `WebSearch`/`WebFetch` **antes** de a resposta
   virar premissa. Nunca derivar do cutoff quando o gatilho disparou.
3. **Fallback de transporte — `WebFetch` é budget SEPARADO do `WebSearch`.** Quando o `WebSearch` esgota
   na sessão, o `WebFetch` ainda verifica URLs conhecidas (npm, changelog, doc oficial, GSMArena). Busca é
   abstração SDAAL — esgotar um transporte **não** é desistir ([`search-is-sdaal-fallback-when-capped`](#-ligações)).
4. **Saída honesta — se ambos indisponíveis, declarar "não verificado".** Orçamento esgotado ou bloqueio
   de bot → **parar e declarar** que não foi verificado. Nunca chutar, nunca apresentar prior como fato.
   O "não sei ao certo" verificável vale mais que a certeza falsa.

---

## 🧪 Evidência de campo (sessão de origem, 2026-07-19)

- **Drift de 5 majors escondido no cutoff:** quase afirmei **Expo SDK 52** (prior); o drive-to-verify no
  npm ao vivo pegou **57**. Sem a busca, a premissa entraria errada no raciocínio.
- **Device 2026 fora do cutoff:** specs do Poco X8 Pro Max não estavam de cabeça; a regra obrigou a buscar
  (WebFetch) — e, quando o WebSearch esgotou **e** o GSMArena bloqueou, a saída correta foi **declarar
  "não verificado"**, não inventar.
- **Detalhe operacional que virou guarda:** foi justamente o `WebFetch`-como-budget-separado que salvou a
  verificação quando o `WebSearch` estava no teto.

---

## 🧭 Por que mecanismo, e não "lembre-se de verificar"

Porque conselho-que-depende-de-lembrar **já falhou** com esta mesma família de erro — é a razão de o
KG-first ser cabeado como **primeiro ato** e não como recomendação
([knowledge-graph-sdaal.md §Por que mecanismo](knowledge-graph-sdaal.md#ssot-as-runtime--o-kg-é-o-primeiro-ato-mecanismo-não-conselho)).
A defesa durável é o **gatilho explícito** dentro do fluxo de pesquisa: um passo que pergunta *"este claim
é sobre algo atual/emergente/popular? → então verify externo obrigatório; senão marcar não-verificado"* —
uma afordância no `/meta:orchestrate`, na skill `onion-orchestration` e nos comandos de research.

> **Cabeamento no fluxo de pesquisa é trabalho GATED.** Esta KB é a **doutrina durável** (o *quê* e o
> *porquê*); o wire-in mecânico deriva **fresco** contra o fluxo vivo quando o gate abrir
> ([`gated-work-derives-fresh`](#-ligações)) — não se pré-cozinha aqui.

---

## 🔗 Ligações

- [Knowledge Graph SDAAL](knowledge-graph-sdaal.md) §SSOT-as-runtime — o `verify(vivo)` do ciclo
  `read→verify→act→write`; esta KB é o mesmo `verify`, com o **mundo externo** no lugar do artefato vivo.
- [Fonte ≠ Derivação](source-vs-derivation.md) — a família `declarado≠verificado` de que esta regra é uma
  instância (a "declaração" aqui é o prior do cutoff; a "verificação" é a web).
- [Onion Dogfooding Doctrine](onion-dogfooding-doctrine.md) — "validação adversarial é insumo, não ordem":
  prior é hipótese a verificar, não fato.
- Memórias-âncora da instância: `verify-external-for-current`, `research-first-over-priors`,
  `worst-truth-is-uncertain`, `search-is-sdaal-fallback-when-capped`, `timestamp-verified-source`,
  `gated-work-derives-fresh`.
