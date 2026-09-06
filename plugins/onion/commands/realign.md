---
description: Revisão em camadas da jornada do plano × o vivo — o "selo realinhado" (passado/presente/futuro)
allowed-tools: Bash, Read
---

# 🧭 /onion:realign — selar o plano realinhado com o vivo

Ao **fim de uma etapa/onda/sessão** — ou **durante** a execução, quando o plano se ajusta a cada
interação — este comando faz uma **REVISÃO EM CAMADAS** do plano-grafo contra o estado atual e diz se
ainda coere. É o reforço-prosa do maestro (*"revise o alinhamento… coloque um mecanismo para nada ficar
sem controle"*) virado **maquinaria grafo-primeiro, radar-driven, verificável** — não um prompt que se
repete. Previne os três males (palavras do maestro): (1) driftar do plano em algo **sem importância**;
(2) causar **desalinhamento custoso no futuro**; (3) **desorganizar** elementos que ferem o **passado ou
o futuro** do plano.

> **NÃO é fonte, NÃO muta o grafo.** O grafo é a fonte; este comando **projeta** uma revisão e **propõe**;
> o maestro sela (append-mostly, via `/onion:kg-freshness` / edição do grafo). Espelha `/onion:backlog` e
> `/onion:kg-freshness`: gerador determinístico + comando fino.

## O que cada camada revê (a tríade, ancorada em defense-in-depth + reconcile-IaC + arXiv 2608.04066)

| Camada | Tempo | Custo | O que checa | Drift |
|---|---|---|---|---|
| **1 — integridade** | passado | barata (sempre) | alvo de `SUPERSEDES`/`REFUTES` ainda `confirmed`/`open` (Aufhebung não aplicada) | **(c)** desorganiza |
| **2 — frescor** | presente | média (por atenção) | `STALE`/`UNANCHORED` **com** `DEPENDS_ON` a jusante = **(b)**; sem dependentes = **(a)** | (b)/(a) |
| **3 — north-star** | futuro | cara (só em checkpoint) | **commitment-drift** (objetivo aberto/abandonado) vs **binding-drift** (vínculo objetivo↔artefato) | dissociados |

**Classificação (a)/(b)/(c):** (a) inócuo (baixa atenção, sem dependentes) · (b) custoso-futuro (tem
`DEPENDS_ON` a jusante) · (c) desorganiza passado/futuro (não-reconciliado). **Histerese (anti-thrashing,
SAGE):** a camada 3 só *pesa* no veredito quando o drift agregado (b+c) cruza o limiar (`REALIGN_THRESHOLD`,
default 15) — abaixo dele é informativo, não dispara realinhamento (evita cerimônia a cada tick).

## Procedimento

1. **Passo 0 — legibilidade antes de veredito** (o script já o faz e **para** se falhar): `kg-radar
   --integrity --schema`. Não se realinha grafo que o motor não lê.
2. **Projetar a revisão** — o argumento é o plano-grafo **deste** repo. O default sem argumento é o
   plano do CORE (`fios-abertos.kg.yaml`) e **não existe** num repo que apenas instalou o plugin:
   ali passe o seu grafo (`git ls-files '*.kg.yaml'` acha).
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-realign-project.sh <grafo.kg.yaml> # o caminho normal
   bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-realign-project.sh                 # só no core: fios-abertos.kg.yaml
   ```
   Consome `--triples` + `--freshness-tsv` do radar (reusa a régua; **não** reparseia YAML). Imprime as
   três camadas, os contadores e o **veredito**: `REALINHAR` (há tipo-(c)) · `ATENCAO` (agregado ≥ limiar)
   · `ALINHADO`.
3. **`--check` (dente, não advisory):** `bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-realign-project.sh <grafo> --check` —
   uma linha + **exit 1 se houver drift tipo-(c)**. É o gate que um wrapper de fim-de-onda pode encadear.
4. **Selar (propõe; o maestro decide) — repair antes de replan** (arXiv 2608.13292 TF+P):
   - **(c)** → reconciliar no grafo: novo nó + `SUPERSEDES`/`REFUTES` **datado**, alvo → `superseded`/
     `refuted` (Aufhebung — nunca apagar). Repair determinístico, custo-zero de LLM.
   - **(b)** de alta atenção → delegar a `/onion:kg-freshness` (mede vs o vivo, propõe-não-escreve).
   - **camada 3** acima do limiar → julgamento; **dente = achado vira nó no grafo** (visível
     no `/onion:backlog`), não um `.md` lateral. LLM-replan é a exceção cara, não o default.
5. **Fechar o loop:** após qualquer escrita, `kg-radar <grafo> --integrity --schema` tem de sair 0 (o
   radar é o revisor da própria reconciliação — [[grafo-sempre-atualizado]]).

## ⚠️ Honestidade declarada (herdada da KB de ontologia)

- **Confia no substrato de ESCRITA, não de leitura.** O radar reprova grafo inválido; ninguém garante que
  o grafo foi *lido* antes de agir. `/onion:realign` **revisa o que está escrito** — não força que tenha
  sido absorvido. (`${CLAUDE_PLUGIN_ROOT}/kb/onion-kg-ontology-hierarchy.md §5`.)
- **Camada 3 é parcial na Fase 1.** O **nó north-star imutável** e a **ordenação `DEPENDS_ON` direcionada**
  (o radar hoje não emite precedência — grau é não-direcionado por contrato do `fios-abertos`) são **Fase 2
  (gated)**. Hoje a camada 3 aproxima commitment/binding pelos sinais disponíveis (objetivo aberto sem
  apoio · decisão sem `trace:`, sem vínculo de saída **e** sem apoio de entrada — o dogfood do corpus
  real corrigiu o binding para não gritar em decisão bem-apoiada por evidência).

## 🔗 Referências
- Motor: `${CLAUDE_PLUGIN_ROOT}/validation/kg-realign-project.sh` · Fonte: `${CLAUDE_PLUGIN_ROOT}/validation/kg-radar.sh`
- Ontologia dos KINDS de grafo (Fase 0): KB `onion-kg-ontology-hierarchy` (viaja com o plugin em `kb/`)
- Irmãos-molde: [`/onion:backlog`](backlog.md) · [`/onion:kg-freshness`](kg-freshness.md) · [`/onion:kg`](kg.md)
- Plano-grafo de exemplo (**core-only**, não viaja): `docs/onion/graph/fios-abertos.kg.yaml` · Bancada (core-only): `run_realign_selftests`
