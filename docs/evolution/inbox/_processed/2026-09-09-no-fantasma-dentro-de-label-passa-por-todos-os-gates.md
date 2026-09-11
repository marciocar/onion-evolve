# Sinal upstream — nó forjado dentro de `label: |` passa por REGRA 78 **e** pelo `kg-radar.sh`

**De:** `venda-direta-pdi` (adotante, pin `5dcc706b2233`)
**Data:** 2026-09-09
**Tipo:** lacuna de guarda, medida em dogfood
**Superfície do core:** `.claude/validation/kg-radar.sh` · `.claude/validation/kg-yaml-validity-check.sh` (REGRA 78)

---

## O que foi medido

Um `.kg.yaml` **YAML perfeitamente válido** em que os dois leitores do core veem **grafos
diferentes** — e todos os gates saem verdes.

O artefato: um nó `B_ESCONDIDO` escrito **dentro do bloco `label: |`** de outro nó, com uma
aresta `SUPPORTS` saindo dele.

| leitor | veredito | população |
|---|---|---|
| `kg-yaml-validity-check.sh` (REGRA 78) | `rc=0` | — (e está certo: o arquivo **é** YAML válido) |
| `kg-radar.sh --integrity --schema` | `rc=0` | anuncia **`3 nós, 2 arestas`** |
| PyYAML | — | vê **2 nós** (`A`, `C`) |

O nó forjado não existe para o parser: é texto dentro do label de `A`. Para o `kg-radar.sh` —
que é **quem emite o veredito** — ele existe, pesa, entra na centralidade e liga aresta.

## Por que acontece (não é defeito do radar)

`kg-radar.sh:210-220` entra na seção com `/^nodes:/` e reconhece nó por
`^[[:space:]]+- id:` com **qualquer** indentação. É a permissividade correta para um motor
awk — awk não tem como saber onde um bloco `|` começa e termina. É o **preço declarado** da
economia de motores (`kg-radar.sh:78`), e ele só fica pago se alguém cobrir a metade que falta.

A REGRA 78 fecha a metade **sintática**, e fecha bem. O comentário dela inclusive **nomeia esta
fresta como já explorada uma vez**:

> "foi essa fresta que permitiu, na bancada do predicado de selo, forjar uma aresta REFUTES
> DENTRO de um `label: |`"

O que não estava fechado é a metade do **censo**: dois contadores que discordam sobre a mesma
população, com o arquivo sintaticamente impecável.

## O que fizemos aqui (proposta, não imposição)

`scripts/kg_parity.py` — **replica a máquina de estados do `kg-radar.sh`** (entra em `^nodes:`,
sai em `^edges:`/`^meta:`, casa `^\s+- id:`) e confronta a população dela contra a do PyYAML.
Reprova nomeando os ids fantasmas. Contrato: `0` concordam · `1` divergem · `2` NÃO MEDIDO
(inclui "não parseia", que é da REGRA 78 e aqui não vira nem aprovação nem reprovação).

`tests/test_ingest.sh` (T47) prova as duas metades **no mesmo artefato**: que a REGRA 78 e o
radar saem `0` e que o radar conta `3` contra `2` do parser, **e** que a guarda reprova citando
`B_ESCONDIDO`.

⚠️ **A 1ª versão da guarda era falsa e o próprio teste a derrubou:** ela ancorava em
`^  - id: ` (dois espaços) e por isso **não via** o nó forjado a seis — media, saía `0`, e não
replicava nada. Foi a metade "o radar conta 3" do teste que expôs isso. Se o core absorver,
**a fidelidade ao matcher do radar é o requisito**, não um detalhe: uma guarda que não replica
o contador que dá o veredito é decoração.

## O que pedimos

Avaliar se isto vira **REGRA no core** (irmã da 78, mesma catraca) ou fica como guarda local.
Nossa leitura: pertence ao core — a lacuna é do par `radar awk` × `consumidor YAML`, que é
superfície do framework, e todo adotante a herda sem saber.

## Nota de método (o achado atrás do achado)

Este sinal nasceu de um erro nosso que vale registrar: ao topar com 6 linhas de YAML quebrado
neste repo, anunciamos que **nenhum gate via**. Falso — a REGRA 78 já reprovava, HARD. Tínhamos
rodado o radar e a bancada no warm-up e **não** o lint. A guarda existia; quem falhou foi o
ritual. Só depois de rodar o lint é que a lacuna **real** (esta) apareceu, e ela é bem mais
estreita do que a que imaginamos primeiro.
