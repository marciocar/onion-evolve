# Breadcrumbs (migalhas) no Onion — estigmergia em 2 dos 3 gêneros

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 2.0.0 |
| **Criado** | 2026-06-30 · **unificado** 2026-07-18 |
| **Status** | `accepted` — doutrina unificada (validação multi-lente + adversário; supersede o draft v1.0.0 "só-Absorção") |
| **Tags** | `transformer`, `breadcrumb`, `estigmergia`, `absorção`, `proveniência`, `trilha`, `ssot-runtime`, `sdaal` |

> **Proveniência:** validação orquestrada 2026-07-18 (3 lentes → síntese → verificação adversarial, CONFIRMADO com 2
> correções). Grafo: `docs/evolution/research/breadcrumb-doctrine-2026-07/breadcrumb-doctrine.kg.yaml` (radar exit 0,
> `SUPERSEDES` do draft). Pesquisa/prior-art: `docs/evolution/research/breadcrumb-doctrine-2026-07/SYNTHESIS.md`.

---

## 🎯 O problema (invariante)

O Transformer infere pelo **mais provável no corpus** — em sistemas idiossincráticos (Onion) o mais-provável está
**errado**. **Acomodação** = vai com o mais próximo sem questionar. **Absorção** = lê um sinal explícito e o segue.
Um **breadcrumb** é um sinal **persistente e estrutural** embutido **no artefato** (não no prompt) que sobrevive ao
contexto e chega ao modelo junto com o que descreve.

> "A IA se acomoda; ela absorve — a menos que você force com uma migalha de pão."

---

## 🧬 Os 3 gêneros (por DIREÇÃO do sinal)

A **família** é *breadcrumbs/migalhas*. **Estigmergia** (Grassé 1959 — coordenação via marca no ambiente,
reaplicada a agentes LLM em 2026) é a **propriedade** que **2 dos 3** gêneros têm; Proveniência não a tem.

| Gênero | Direção | Pergunta que resolve | Instrumento Onion | Estigmergia? |
|--------|---------|----------------------|-------------------|--------------|
| **① ABSORÇÃO** | presente / espacial | "o modelo lê isto certo **agora**?" (anti-acomodação) | CSS vars, `data-slot`, frontmatter enum, naming `_processed/` | **sim** (sematectônica — o sinal É a estrutura) |
| **② PROVENIÊNCIA** | aponta pra **trás** | "cadê a **fonte/evidência** deste claim?" (auditoria) | `trace:` no `.kg.yaml`, aresta `TRACES_TO`, `origin:` | **não** — é âncora/citação a um passado fixo |
| **③ TRILHA** | aponta pra **frente** | "pra onde a **próxima sessão** vai?" (navegação) | `next_recommended`/Next-crumb no diário; o **ato** `write(KG)` (novo nó/aresta) | **sim** (marker-based — marcador depositado) |

> **Correção que a validação impôs** (contra a hipótese inicial "o `trace:` é trilha entre nós"): grep de 6
> `.kg.yaml` provou que `trace:` aponta para a **fonte** (`SYNTHESIS.md`, `arquivo:linha`, URL) — é **Proveniência**,
> não Trilha. Nomear Proveniência como gênero próprio é o que impede recometer a confusão que a auditoria dissolve.

### Eixo transversal — VALIDADE/FRESCOR (não é 4º gênero, é modificador)
`conflict_class` (dynamic|static|conditional) · `valid_when` · `review_after`/⏰ · `verified_at` · `status:
assess|trial|backlog`. Qualquer gênero **carrega** este atributo ("até quando confio + como re-testo"). Erro do
draft v1: listava `status:` na tabela de *canais* de Absorção — misturava direção com validade. É cross-cutting.

---

## 🔁 A amarra com o SSOT-as-runtime (ESCOPADA ao gênero TRILHA)

A síntese "read=comer / act=andar / write=deixar = o mesmo loop" é **válida — mas só para a Trilha** (generalizar
aos 3 é overclaim: Absorção é estático-estrutural; Proveniência só aponta pra trás). O ciclo tem **4 pernas**
(`knowledge-graph-sdaal.md` §SSOT-as-runtime), mapeadas em Hansel-e-Gretel:

- **`read(KG)` = COMER a migalha** — localizar o nó, `kg-radar.sh` como 1º ato, citar por **id**, nunca re-derivar da prosa.
- **`verify(vivo)` = CHEIRAR antes de confiar** — nó PROD stale **mente**; cruzar contra o artefato vivo (`declarado≠verificado`).
- **`act` = ANDAR a rota** — o trabalho real, o terreno **entre** duas migalhas (não é comer nem deixar).
- **`write(KG)` = DEIXAR a migalha nova** — `REFUTES`/`SUPERSEDES`/nova aresta, append-mostly. *"Sem esta perna, o ciclo é leitura, não runtime — o grafo apodrece na próxima volta."*

> **Correção do adversário (locus-slip):** a Trilha **viva hoje** é **no DIÁRIO** (`next_recommended`; o loop
> auto-realimentante do `federation-radar` — deixou "staging backlog" → runtime comeu → deixou "self-heal" —
> `2026-07-18-self-reinforcing-radar-loop`). A Trilha **no KG** é **aspiração não-construída**: os `.kg.yaml` têm
> **zero** campo forward (`next_recommended`/`breadcrumb_for` = 0). **Assimetria de design real:** o KG tem campo
> de Proveniência (`trace:`) mas **nenhum campo de Trilha** — a trilha-no-KG é implícita no *ato* write(KG). Uma
> aresta/campo forward é candidato **dogfood-gated** (não inventar antes da prova).

---

## 🛡️ Guardas

- **Migalha stale MENTE, não corrompe** — o veredito é **re-verificar**, nunca "recusar". Nó PROD sem `verified_at` é declarado, não verificado.
- **Trilha falsa = migalha vencida seguida sem re-teste** — `review_after`/⏰ + `conflict_class` (dynamic→rodar o artefato; static→confrontar a melhor fonte; conditional→checar só a condição) é o guard.
- **Não confundir Proveniência com Trilha** pelo nome do campo — grep prova backward (fonte) vs forward (próximo passo).
- **Validade não é gênero** — é modificador; não listar `status:` como canal.
- **Radar-checkável, por gênero (honesto):** `kg-radar.sh` audita ② Proveniência (`TRACES_TO`, RULE-sem-trace) + frescor. **Faltam gates** para ③ Trilha (não há aresta-trilha ainda) e ① Absorção — gap nomeado, não escondido.

---

## 🔗 Conexão com o Onion (breadcrumbs já em uso)
① `origin:"env"`, `data-slot`, `_processed/`, `role:`, frontmatter `status:`. ② `trace:`/`TRACES_TO` no KG,
`arquivo:linha`. ③ `/meta:diary` ("sistema de breadcrumbs para o Transformer") `next_recommended`, o ciclo write(KG).

## 📎 Referências
- Pesquisa/prior-art (estigmergia 2026): `docs/evolution/research/breadcrumb-doctrine-2026-07/SYNTHESIS.md`
- SSOT-as-runtime: [knowledge-graph-sdaal.md](../../concepts/knowledge-graph-sdaal.md) §SSOT-as-runtime (§236)
- Dogfooding (re-testar, nunca re-carimbar): [onion-dogfooding-doctrine.md](../../concepts/onion-dogfooding-doctrine.md)
- Diário (Trilha viva): `/meta:diary` · migalha `2026-07-18-self-reinforcing-radar-loop`
- Origem (draft v1, só-Absorção): pesquisa `docs/analysis/onion-intelligent-breadcrumbs-research-2026-07.md`
