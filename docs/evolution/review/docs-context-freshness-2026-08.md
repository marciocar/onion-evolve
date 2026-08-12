---
branch: docs/context-freshness-2026-08
pr: 585
date: 2026-08-12
reviewed_diff_sha256: 8ae03aa4861f212b6c1562950707c4584a605afacbbc4a63de1a528a1661388a
findings_total: 12
findings_real: 12
findings_fixed: 12
tokens: 243652
duration_min: 35
verdict: CORRIGIDO-E-RE-VALIDADO
reviewer: code-reviewer + metaspec-gate-keeper (opus, adversarial, lentes independentes)
---

# Passada adversarial — `docs/context-freshness-2026-08`

## Como a passada foi montada

Dois revisores `opus` **em paralelo, com lentes independentes**: um de **correção do shell** (atacar
os 3 feeders novos, o pré-filtro, as 6 fixtures, re-executar o lint) e um de **conformidade
doutrinária e veracidade dos labels** (gramática do `.kg.yaml`, medir cada afirmação factual do
grafo, caçar aresta-álibi). Ambos instruídos a **default para "está errado"** e a declarar
explicitamente onde a dimensão estivesse limpa.

Nenhum veredito foi aceito sem re-medição. **A passada aconteceu ANTES de abrir o PR** — ao
contrário do PR #584 do mesmo dia, em que a guarda de shell precisou me pegar por abrir primeiro.

## Achados

| # | sev | achado | status |
|---|---|---|---|
| 1 | ALTA | alternation aceitava `N comandos e M comandos` → `grep` falhava → `set -e` **matava o lint inteiro** em silêncio | corrigido |
| 2 | MÉDIA | `tr '\n' ' '` colava o arquivo inteiro: parágrafos distantes viravam falsa frase-de-total | corrigido (`awk RS=""`) |
| 3 | MÉDIA | acusação **em dobro** com o feeder irmão na ordem canônica | corrigido |
| 4 | MÉDIA | feeder novo sem as guardas anti-tabela/anti-frota que **todos** os irmãos têm | corrigido |
| 5 | MÉDIA | `bad-conjuntiva.md` era **fixture vazia** — sobrevivia à remoção do que testava | reescrita, load-bearing |
| 6 | MÉDIA | `bad-invocaveis-invertida.md` não exercitava a alternativa nova do pré-filtro | reescrita (`dez categorias`) |
| 7 | MÉDIA | promessa de superset do pré-filtro **não fecha** para leitura por parágrafo | limite **declarado** |
| 8 | BAIXA | case-sensitivity do feeder `Total` é load-bearing e não estava dito; "só 3 arquivos" era **falso** | documentado + corrigido |
| 9 | **ALTA** | `Q_CONTRADICAO_CROSS_DOMINIO` **REFUTADO** — `business-logic.md` diz **8**, o valor certo | nó reescrito |
| 10 | MÉDIA | `verified_against` publicava receita que **não reproduz** (`grep -c 'kind: adopter'` = 9) | corrigido |
| 11 | MÉDIA | tese central esticada: dos 5 sítios, **1** tem SSOT gerada | estreitada, confidence 1.0 → 0.8 |
| 12 | MÉDIA-ALTA | aresta-álibi por proximidade (2ª vez em um dia) + nó de run **sem artefato persistido** | aresta refeita, síntese persistida |

**Dimensões declaradas limpas** (registro importa tanto quanto o achado): gramática do `.kg.yaml`
campo a campo; uso correto de `CONSTRAINS` onde `REFUTES` seria contradição; os três achados de
maior impacto (`E_CITACAO_FABRICADA`, `C_NOTA_DE_FRESCOR_BLINDA`, `E_O_COMMIT_DE_CORRECAO_AFIRMOU_FALSO`)
verdadeiros **ao pé da letra**, inclusive a distância de nove linhas e o salto de referente; as 36
fixtures r16 antigas sem regressão; feeder `Total` com valores vazios/iguais inócuo.

## O que esta passada comprou

**O achado nº 1 é uma regressão que eu embarquei e defendi.** Eu havia testado exatamente esse
cenário e concluído que sobrevivia — testei num subshell `( )` interativo, enquanto o lint roda
como script standalone, onde morre. A medição errada me fez **descartar a hipótese certa** quando
a bancada abortou. É `bancada-espelha-o-runner` pela terceira vez no mesmo dia.

**O achado nº 9 é o mais desconfortável.** Acusei um arquivo de dizer "11 membros" quando ele diz
**"8 membros hoje"** — o valor correto. Casei o numeral com `11 skills`/`11 arquivos`. É
literalmente o defeito que o grafo desta branch **celebra ter pego num worker**: apliquei o Elenxo
aos outros e não a mim.

E o nº 12 registra a **segunda** aresta-álibi e a **segunda** citação de `run_id` sem artefato — as
duas classes curadas horas antes, no PR #584, reincidindo no arquivo seguinte. Virou KB e não virou
guarda.

## Teto declarado desta revisão

**Não houve segunda passada adversarial completa após as correções.** A re-validação foi por gate
mecânico — bancada **798/0/0 somando**, `lint-artifacts.sh` **0 HARD**, `kg-radar --integrity` e
`--schema` (rodados **separados**, porque a superfície descarta o 2º argumento) — mais **repro
dirigido de cada achado corrigido**: o lint agora sobrevive ao par repetido (antes: 0 sumários) e o
falso-positivo entre parágrafos foi a zero (antes: 2). Gate determinístico cobre o sintático;
**não substitui** verificador semântico, e essa dimensão fica nomeada como não-re-verificada.

Um dos revisores declarou **não ter verificado** o `baseline 792` (exigiria rodar a bancada de
~35min também em `main`); o outro rodou a bancada inteira e confirmou o 798. Registro os dois.
