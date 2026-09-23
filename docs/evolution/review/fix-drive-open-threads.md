---
reviewed_diff_sha256: "3b603ee87f0c629b3712f9f68fc170f3ab92118b512fc7edc22622c78b7c22f6"
findings_total: 12
findings_real: 12
tokens: 277000
duration_min: 46
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Passada adversarial (opus/high, mandato REFUTAR, default REPROVADO, isolation worktree) sobre a
  REGRA 89 nova. REPROVOU com 12 achados, 2 bloqueantes — e o pior INVERTE a tese da própria
  regra: o universo media 1/6 da dívida, e a catraca "encolhia" por despejo, não por
  reconciliação. Refutou 8 dos meus ataques e declarou 5 lacunas.
---

# Resíduo — a guarda media 1/6 da dívida, e encolhia por despejo

## O achado que inverte a tese (C1)

Minha REGRA 89 varria só os `kg:` de `radar-baselines.yaml` — a rodada **atual** de cada eixo.
Medido pelo refutador: **6 das 7 rodadas seladas têm zero `SUPERSEDES`, e a guarda contava 1**.

O ponteiro do eixo E3 já passou por **cinco** rodadas (`maestro-vivo → 09-02 → 09-03 → 09-04 → r4
→ r5`), e **cada troca removeu a dívida anterior da contagem sem reconciliar nada**. Meu cabeçalho
afirmava *"cada rodada nova adiciona mais um órfão"*; o mecanismo fazia o **oposto** — despejava o
órfão anterior. A frase *"a métrica de saúde é este número diminuindo"* era falsa: o denominador
eram **eixos**, não rodadas seladas.

O universo passou a ser a convenção `docs/evolution/research/radar-*/` **união** os ponteiros. O
passivo real: **5**. O número subiu porque a medição ficou honesta.

## Seis evasões, todas reproduzidas

| # | a guarda deveria acusar e não acusava |
|---|---|
| A1 | `supersedes_none:` **vazio** — provado no grafo real. **Bastava a palavra**: o fail-open exato que a regra existe para impedir. E a variante `"   "` também |
| A2 | `kg:` com comentário no fim da linha ficava invisível — estilo que o arquivo real já usa |
| A3 | ponteiro pendurado sumia calado, e **nenhum caso da bancada cobria a linha** |
| A4 | declaração aceita em qualquer profundidade: dentro de um nó, e dentro de block scalar de prosa — forma nativa deste corpus |
| A5 | `edge_type: SUPERSEDES` **citado em prosa** contava; e o casamento por prefixo aceitava `SUPERSEDESX_INVENTADO` |

## A catraca virou chaveada

Inteiro nu não dizia **qual** rodada estava tolerada, sumia no diff quando uma saía e outra entrava,
e o parse `tr -dc '0-9'` transformava `"1 (era 2)"` em teto **12**. Agora é uma linha por rodada,
como os 11 baselines irmãos, e o lint compara **conjunto**: rodada nova sem Aufhebung é HARD mesmo
com o total parado. A forma chaveada resolve de brinde o **C3** — as linhas são caminhos do core,
que o `regen-baselines.sh` filtra por forma-de-caminho, então o adotante nasce com a lista vazia em
vez de herdar um teto que nunca mereceu.

## Dois bloqueantes que eu não tinha visto porque não rodei o gate inteiro

**B1:** a bancada **completa** reprovava em `regen-ensure-from: (g)` — meu baseline resolvia **zero**
emissores, porque o script não implementava `--emit-baseline` nem nomeava o próprio baseline. Eu
havia rodado só a família afetada. **B2:** as projeções do harness não tinham sido commitadas.

## A minha própria declaração tinha dois furos

Ela mirava o corpus `claude-code-2.1-onion-2026-08`, que **nunca foi baseline do E3** (a anterior é
a `r4`), e afirmava que o corpus *"não foi re-medido"* — quando um nó o re-mede em parte e o cita
como autoridade. Corrigidos: agora nomeia a r4, descreve o que a r5 de fato refina nela (a causa da
ausência de sinal de mercado, não a conclusão), e estreita a afirmação sobre o corpus.

## E o `/meta:radar` parou de mandar o impossível

Ele dizia apenas *"`SUPERSEDES` sobre os nós da baseline anterior"* enquanto a aresta do motor é
**intra-arquivo** (`kg-radar.sh` recebe um arquivo por invocação). Quem obedecia ao "grafo próprio
por rodada" **não alcançava** a baseline anterior. Agora documenta os três desfechos, e diz que os
dois `meta.*` exigem valor.

## O que o refutador refutou de mim

A intra-arquivo **é verdade** (`kg-radar.sh:91`), então a justificativa para `supersedes_external`
fica de pé. O flip de `E_BANCADA_…` está **certo** — ele reproduziu: a faixa carrega o detalhe
inline, e eu truncara com `| tail -14`. A contradição predicado × radar é **real**, reproduzida nos
dois sentidos. Não há idioma frágil no código novo. A bancada **não** é tautológica: 5 dos 7 casos
matam mutante sozinhos; só o (a) é redundante com o (e). E o custo é menor que eu declarei.

## Três coisas que a maquinaria pegou sozinha, sem o maestro

**REGRA 59 (Modo que a produção consome é exercitado pela bancada)** cobrou a bancada do script novo
antes de eu escrevê-la. **REGRA 60 (Identificador de código em INGLÊS)** — a guarda que eu mesmo
estendi hoje — me pegou escrevendo o script inteiro em pt-BR. E o caso `(i)` da bancada nova falhou
por `sut | grep -q` fechar o pipe cedo sob `pipefail`, a classe `pipefail-epipe-early-closer` que
esta casa já pagou: o SUT estava certo, o teste é que mentia.

## Teto declarado

A bancada foi de 5 para **17 casos**. A 1ª versão dela rodava o lint **inteiro 4 vezes** — 12+ min
numa família só, que cairia numa faixa do CI. Guarda extraída para script próprio e exercitada
direto: **~0,1 s** o check, **~3 s** a família. Bancada cara não é rigor, é imposto.

## O 2º sítio do pipefail, achado pela própria guarda no CI

Depois da 1ª cura, a faixa 4 do CI reprovou em `shell-pipefail: VEREDITO por <produtor>|grep -q ACIMA
da catraca` — e apontou **`lint-artifacts.sh`**, não o script novo. A função da regra filtrava o
baseline com `printf … | grep` em **dois** lugares. Curados com here-string, que é exatamente o que a
mensagem da própria guarda ensina: `grep PAD <<< "$var"`.

**Os dois sítios eram meus, e nenhum foi pego por mim.** O primeiro (no script) veio da faixa 4; o
segundo, de rodar a família `shell_pipefail_robustness` isolada depois. É a terceira vez nesta leva
que uma guarda da casa me barra antes do maestro — e as três eram defeito real.
