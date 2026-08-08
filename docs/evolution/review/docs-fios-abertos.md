---
branch: docs/fios-abertos
date: 2026-08-08
reviewed_diff_sha256: e75855a608306a92e91c1bb06afed7672a67092f7afd6099578e59d8cde02360
findings_total: 30
findings_real: 22
findings_fixed: 11
tokens: 578249
duration_min: 20
verdict: HARD-MAS-NAO-COMO-ESTAVA-O-MECANISMO-VALE-O-SELO-MENTIA
reviewer: Elenxo — 4 refutadores por lente + juiz (opus/high), wf_53bf8317-f83
---

# Passada adversarial — o mecanismo funciona, e o nó que o selava mentia em três pontos

**4 lentes, 30 achados, nenhuma lente deu `CAI` — as quatro deram `FICA-COM-RESSALVA`.** Veredito do
juiz: **«HARD, mas NÃO como está.»**

O eixo sobreviveu inteiro e a manchete é verdadeira: a fila existe, ordena, e a allowlist escondia
mesmo um nó. O que não sobreviveu foi **o selo**, **a promessa de fail-visible** e **o lugar onde
escrevi a refutação**.

## O achado mais grave é mecânico, e eu conhecia a mecânica

Escrevi a refutação de `C_producao_nao_e_o_repo` e a política do WAHA dentro de
`fios-abertos.kg.yaml`. Mas **o radar só enxerga arestas dentro de um arquivo** — regra que está
escrita, por mim, no `meta:` desse mesmo arquivo.

Consequência medida: o `--reconcile` do grafo-dono continuava **cego**, e
`C_waha_orfao_desligar` (PROD/5, o nó mais quente daquele grafo) seguia ordenando **desligar uma
ferramenta que o maestro acabara de proibir encerrar**. Refutação em prosa não revoga nada.

**Curado onde tinha de ser:** `E_producao_alcancou_o_repo` e `PO_ferramenta_da_vps_nao_se_encerra`
nasceram **dentro de `stack-harmonia-2026-08.kg.yaml`**, com arestas internas `REFUTES`/`SUPERSEDES`,
e os status reconciliados (`refuted` / `superseded`). O `--reconcile` de lá agora lista as duas.
No grafo de backlog os dois deixaram de existir — o fato mora onde nasceu.

## O selo mentia em três pontos, e um deles é o defeito fundador da REGRA 49

`I_FILA_COMPLETA_DE_ABERTOS` fechou como `done` com
`verified_against: ...57-grafos-594-linhas...` e o label dizendo *"o nó PENDENTE DE MAIOR ATENÇÃO do
grafo da VPS"*. Medido:

```
grafos no corpus: 58 (não 57)     ·     linhas da fila: 593 (não 594)
topo pendente do grafo da VPS:  ENT_email 14.40  ·  D_email_plus_logto_connector é o 5º, com 8.00
```

E o pior: **594 era o valor de antes de o próprio nó virar `done`** — o carimbo mediu, e depois
mudou o mundo que mediu. É a REGRA 49 sendo violada no ato de selá-la.

O nó foi **colhido** junto com a onda W0, que é o que o desenho manda quando todos os itens da onda
fecham. E a colheita provou a mecânica que o `meta:` promete: ao remover os dois, `W1` ficou sem
`DEPENDS_ON` e as arestas de tese tiveram de ser **reescritas** para ela — o radar não deixa colher
pela metade.

**Nota de honestidade sobre a manchete:** a alegação central **reproduz** —
`D_email_plus_logto_connector` não aparecia no `--state` antigo e aparece no novo, em 2º lugar. Mas
no `--state` a cura é um **empate**: como ele trunca em 7, um id entra e outro
(`C_dissent_auth_transversal`) **sai da janela**. Quem entrega a fila de verdade é o `--open-tsv`.

## A denylist prometia fail-visible e entregava fail-quiet

O comentário do `trabalhoPendente` afirma que *"um status NOVO entra na fila por default"*. Entrava —
e o clamp `if (sf3 < 0) sf3 = 0` zerava a atenção, mandando o nó para o **fim** da fila ordenada, que
é exatamente onde o `--top N` corta. Medido: nó com `status: blocked` e `impact: 5` saía em **16º de
17**, abaixo de nós de impacto 1.

É o mesmo modo de falha que o comentário do `refuted` neste mesmo arquivo já nomeia — *"apaga o sinal
em vez de perdê-lo"* — cometido no bloco novo. Curado com **1.3**, a mesma escolha já tomada para
`drifted` e pelo mesmo motivo: status fora do enum é pergunta aberta sobre o próprio enum. E a fila
ganhou uma **12ª coluna de veredito** (`STATUS-DESCONHECIDO` / `SEM-STATUS`), como o irmão
`--freshness-tsv` já tinha.

## Eu destruí 387 linhas de um arquivo que já existia

`docs/onion/maintenance-checklist.md` **não era novo**. Usei `Write` sem lê-lo e substituí **387
linhas** (adicionar comando, adicionar agente, atualizar documentação, processo de release) por 57 de
rotina de VPS. O manual do curso cita esse arquivo como **fonte do §10** com status `✅`.

Restaurado **byte-idêntico ao BASE**, e a minha rotina foi **anexada** como seção nova. A regra que
fica: *antes de sobrescrever, olhe o alvo* — e `Write` sobre caminho existente exige leitura, não
suposição de que o nome estava livre.

## A cobertura: dois casos que faltavam, e um deles separava denylist de allowlist

O juiz mostrou que um mutante `s == "open" || s == "drifted" || s == "unverifiable"` — **allowlist
equivalente ao denylist para os 7 status conhecidos** — passava **6/6**. Só um valor **fora do enum**
os distingue.

- **(g)** nó com `status: blocked` tem de entrar, **subir** e trazer `STATUS-DESCONHECIDO`;
- **(b2)** a fórmula vale `18.00 / 13.00 / 8.00` na fixture, amarrando as três constantes que
  ninguém mais amarrava: a centralidade, o `1.3` do `drifted` e o `1.0` do `unverifiable`.

E o `sed` do mutation test **(f)** casava **duas** linhas (a do `--state` e a do `--open-tsv`); agora
é ancorado ao bloco que o rótulo nomeia — senão o `cmp` passaria a diferir por duas razões e o caso
mentiria sobre o que mutou.

## Verificação

- bancada **724 passam / 0 falham / 0 pulam**, corrida **SOLO** · bloco da fila **8/8**
- `lint-artifacts` **0 HARD** · `rules-registry` rc=0 · radar exit 0 nos dois grafos tocados
- `--reconcile` de `stack-harmonia` lista as duas reconciliações novas
- fila do corpus: **593 linhas** sobre **58 grafos** (o número agora é o medido, e o laço vai junto)
- os 7 plugins regenerados; as cópias vendorizadas do radar carregam o predicado novo
- `maintenance-checklist.md` conferido **byte-idêntico ao BASE** antes de anexar

## Dívida declarada — item no backlog, não neste PR

- **Gate de schema/integridade ANTES dos ramos de máquina** (`--open-tsv`, `--freshness-tsv`,
  `--triples`): hoje um grafo ilegível derrama **11 linhas de prosa pt-BR dentro do stdout do TSV**.
  Latente (os 58 grafos parseiam), e a cura correta é extrair `integridade()` e chamá-la nos três —
  não remendar um.
- **`tsvsafe()`** para TAB/CR/LF em `label` e `traceInline`, nos dois modos TSV. O campo é texto
  livre escrito por LLM.
- **`kg-view.sh` com os slots `drifted`/`unverifiable`** — e a correção de método: são **cinco**
  scripts versionados com `statusFactor` (medido com `git grep`, não `grep -rl` sobre o filesystem),
  e a justificativa que dei para adiar (*"latente, grafo sem lente"*) foi **refutada no mesmo dia**:
  `kg-view --json` roda naquele grafo com `rc=0`. O fio maior não é o arquivo — é que
  `--assert-parity` compara **contagem**, não **peso**.
- **Guarda da onda vazia e guarda do teto de 20**: o `meta:` promete as duas e **nenhuma existe**.
  `fix-must-become-mechanism` aplicado ao próprio arquivo que nomeia a doutrina.
- **Coluna `layer` na TSV ou tipagem do predicado**: `trabalhoPendente()` decide só por status,
  enquanto o vizinho `alvoPendente(s, t)` recebe o tipo justamente porque a 1ª versão errou nisso.
- **Sempre que um nó disser "REFUTA X"/"REVOGA X" em prosa**, um guard deveria resolver X no corpus e
  exigir aresta interna no grafo de X. Hoje é disciplina — e a disciplina falhou dentro do arquivo
  que a nomeia.

## O fio de método

O juiz fechou com a observação que mais importa: **quatro lentes acharam defeitos reproduzidos, e
nenhum deles apareceu para quem escreveu o código.** O mais grave não era bug de shell — era a
mecânica do próprio KG mordendo quem a conhece e a escreveu.

E a bancada mede o **snapshot**, não a **forma**: quatro mutantes semanticamente distintos passavam
6/6 num bloco escrito na mesma sessão em que se construiu o `_prove_mutation` para caçar passe vácuo.
O padrão a generalizar: **todo predicado escrito como denylist precisa de um caso que injete um valor
fora do enum** — senão o teste não distingue denylist de allowlist, e a lição fica no comentário em
vez de ficar no gate.
