---
branch: fix/radar-allowlist-denylist
date: 2026-08-07
reviewed_diff_sha256: feab61839c253fa8532fefc7547a13e67abe3142e917195ee1e61b8af7ef3a3d
findings_total: 28
findings_real: 28
findings_fixed: 6
tokens: 530841
duration_min: 27
verdict: SEIS-CORRECOES-E-UM-FIO-MAIOR-QUE-O-PR
reviewer: Elenxo — 4 refutadores por lente + juiz (opus/high), wf_dce6b4e5-bf5
---

# Passada adversarial — a troca allowlist→denylist sob ataque

**4 refutadores, 28 ataques, 0 descartados** pela regra da superação. **Nenhuma lente falhou.**
Seis correções entraram antes do PR, e o achado mais grave do Elenxo **não é deste arquivo**.

## O que o ataque derrubou

**A fronteira estava escolhida por CONVENIÊNCIA.** Eu excluí `done` do lado do alvo porque
*"criaria 11 acusações novas"* — verdadeiro no número, **errado no motivo**. Testei a acusação:
uma `decision` fechada, superada por nó vivo, saía com **`✅ nenhum alvo por reconciliar`** —
fail-open com a assinatura exata do defeito que este arquivo cura. A razão certa é **tipo, não
status**: dos 11 alvos `done` do corpus, **11/11 são `question`**, e question fechada como `done`
é o remédio que a própria seção prescreve. `alvoPendente(s, t)` com exclusão tipada: churn **zero**
e o buraco fecha.

**Eu inflei a evidência.** Escrevi *"fail-open medido em 2026-08-07"*. Medição real: **0 nós
`drifted` em 2.095**, e **0 supersederes `drifted`/`unverifiable` em 137 arestas**. O que foi
medido naquele dia foi **a fixture que eu escrevi naquele dia**. É latente, não histórico.

**"Zero acusação nova" não prova a fronteira.** Mesmo `supersederConta(s){return 1}` — o predicado
maximamente quebrado — dá 0 avisos no corpus, porque os 137 alvos de SUPERSEDES já estão todos
reconciliados (113 `superseded` · 13 `refuted` · 11 `done`) e os 116 de REFUTES também. **A prova
de comportamento é a fixture, não o corpus.** Efeito interno que eu não tinha reportado:
`supersededByLive` passa a contar **119** arestas em vez de 102 (+17 de origem `done`).

**O sítio que REPROVA não tinha cobertura nenhuma.** Revertendo só a chamada de `alvoPendente` na
contradição de REFUTES e comparando os dois binários sobre os 73 `.kg.yaml` × 6 modos: **0 diffs
em 438 comparações**. A única linha capaz de travar o CI era a que ninguém podia mexer com
segurança. Nasceu a fixture separada `refutes-drifted.kg.yaml` + casos (g), (g-MUT).

**O comentário nasceu mentindo, no commit cuja tese é que texto mente.** Citei *"linhas
274/452/490"* e elas **apodreceram na própria inserção que as escreveu** — apontam para `}`, `}` e
`if (metaSchema == "") {`. Em três cópias (fonte + 2 plugins). Trocado por âncora de grep.
A fixture também mentia sobre si: seguia dizendo *"emite ⚠ para EXATAMENTE D_ALVO_VIVO e
Q_RESPONDIDA"* enquanto emitia 4. E o caso (a) ganhou asserção de **contagem** — sem ela um 5º
aviso entraria em silêncio, que é literalmente o defeito que originou este commit.

## O incidente que a bancada pegou e eu não

Escrevendo o comentário que explica por que allowlist falha em silêncio, entraram **duas aspas
simples e um `||`**. O programa `awk` inteiro vive entre aspas simples do shell: as aspas fecharam
a string, o `||` virou operador de shell, o comando curto-circuitou. Resultado medido:
**`kg-radar.sh` imprimindo ZERO linhas com EXIT 0, em qualquer grafo.** `bash -n` passou limpo.

O sintoma foram 6 casos falhando com `out=` **vazio** e o **sumário ausente** — que é o sinal de
"morreu", não de "reprovou". Nasceu a guarda `radar VIVO`, que roda antes de qualquer veredito
sobre conteúdo e cuja falha **nomeia a causa**.

**Alcance declarado, porque não provei mais que isso:** tentei reproduzir o silêncio por mutação
**quatro vezes** (1 aspa · 2 aspas · com e sem `||` · dentro e fora do bloco awk) e **todas
falharam ALTO** (exit 1, 2, 127). A maioria das injeções é barulhenta; o caso silencioso depende
do texto exato. Logo a guarda **não está provada por mutação** — nasce de incidente medido e cobre
o sintoma observado. Está escrito assim no código.

## O fio maior que este PR

🔴 **`kg-verification-coverage.sh:87,115` — a catraca da REGRA 49 — tem a MESMA allowlist, e ali o
fail-open é ATIVO.** O refutador reproduziu: trocar UM nó PROD/impact 5 de `confirmed` para
`drifted` (sem carimbar nada) faz o gate emitir *"entrada OBSOLETA (nó já carimbado ou removido) —
remova do baseline"*. **O gate afirma que o nó foi carimbado — falso — e convida a apagar a
entrada de um baseline que só pode encolher.** Isso destrói a propriedade fundadora escrita no
cabeçalho do próprio script: *"rodar o kg-freshness é a ÚNICA forma de diminuir o número"*.
Escrever `drifted` à mão é a segunda forma, e é silenciosa. **PR próprio, prioridade máxima.**

Outros dois, medidos e registrados: `kg-view.sh:101-107` carrega uma **cópia** de `statusFactor`
que não conhece os status novos → peso **0.0** justamente nos nós que este commit diz serem os
mais urgentes, e `--assert-parity` passa verde porque só compara contagens. E um **quarto**
predicado allowlist dentro do próprio radar (`--state`, `nstatus[id] != "open"`), fora do escopo
declarado deste PR.

## Verificação

- **10 casos** de `kg-reconcile`, incluindo 4 mutation tests com guarda-da-guarda
- fixture supersedes-mixed: **radar do main = 2 avisos · corrigido = 4**
- fixture refutes-drifted: **2 `✗` com o conserto · 0 sob a allowlist antiga**
- exclusão tipada: `decision` fechada **acusa**, `question` fechada **cala**, churn **0** no corpus
- **55 grafos: zero mudos** (contagem de linhas, não exit code) e zero regressão em `--integrity`
- `lint-selftest` **669 passam / 0 falham / 0 pulam** (env de CI exportado, corrida **SOLO**)
- `lint-artifacts` **0 HARD** · `consumed-mode-check` acusa 4 pares sem teste, **idêntico ao main**
  (pré-existente, verificado por `git stash`)
