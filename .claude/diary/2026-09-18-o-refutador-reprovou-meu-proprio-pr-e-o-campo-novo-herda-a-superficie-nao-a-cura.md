---
date: 2026-09-18
instance: onion-evolve
type: learning
classification: public
tags: [elenxo, parser, fail-open, guarda-por-topologia, porta-publica, catraca, pin]
affects: [meta, engineering, design]
breadcrumb_for: []
share_with: []
next_recommended: "ao acrescentar um campo a um parser existente, ler PRIMEIRO as curas dos campos vizinhos e aplicá-las; e ao materializar porta, conferir o pin no members.yaml antes de declarar feito"
review_after: 2026-12-18
conflict_class: static
---

# O refutador reprovou o meu próprio PR — e o campo novo herda a superfície, nunca a cura

## O que aconteceu

Um PR que curava **quatro guardas que diziam mais do que mediam** (sinais de campo de adotantes)
passou por uma passada adversarial com mandato de derrubar. Veredito: **REPROVADO**, com dez achados.
Todos da **mesma família que o PR já perseguia nos outros**.

O mais afiado: o leitor novo de `meta.review_after` no `kg-radar.sh` casava `^[[:space:]]*review_after:`
solto — **a trinta linhas** do bloco de comentário que explica, para o campo `target:`, as três portas
que esse padrão exato abre, e que foram fechadas em 2026-09-11 com `metaClosed` e `metaFieldIndent`.
As três reabriram. E na direção pior: com *last-wins*, um `review_after` **futuro** escondido num
submapa, num bloco literal ou num `meta:` reaberto depois de `nodes:` **sobrescreve o vencido** — o
grafo caduco sai verde.

Os dois HARD acertavam a tese do PR em cheio:

- `contrast-pairs.json` que **existe e não parseia** voltava a ser fail-open, imprimindo *"sem
  governance/contrast-pairs.json"* sobre um arquivo que está lá. Pior: como o aviso novo do modo
  escuro vive no mesmo ramo `then`, um JSON quebrado **silenciava as duas curas do PR de uma vez**.
  A doutrina certa estava escrita **sessenta linhas acima**, na função irmã. Ninguém a levou até ali.
- o detector do modo escuro era cego para a topologia que a **SSOT desta casa prescreve**
  (`modes/dark.tokens.json`, override cujos paths são os mesmos semânticos, sem prefixo
  `color.dark.`). Medido: na forma canônica, um `brand` a **2,15:1** no escuro passava com `OK ✓` e
  exit 0 — o defeito que a cura existe para fechar, **intacto dentro da forma que o próprio framework
  manda usar**.

E dois que só a execução revelaria: a comparação de data era de **string crua** (`em breve` e
`2026-9-8`, vencido há 10 dias, saíam ambos como "dentro da validade"), e o estado **NÃO MEDIDA**
nasceu num modo com **zero chamadores** — no `--all`, que é o dos 97 sítios, o radar ficava mudo.
Medido no corpus: **131 grafos, 25 falavam, 106 calavam**.

## As lições

**1. Campo novo em parser existente herda a superfície de ataque do parser, nunca as curas dele.**
Proximidade não é herança. Eu escrevi o padrão vulnerável ao lado do comentário que explica por que
ele é vulnerável, e não vi — porque estava lendo o comentário como *história do `target:`*, não como
*contrato do parser*.

**2. Escrever a guarda é quando se está MAIS perto de reincidir na classe que ela cura.** Não menos.
A atenção vai toda para o caso que motivou, e a superfície inteira fica descoberta. Os dez achados
eram da família "guarda que diz mais do que mede" — a família que o PR existia para curar.

**3. Detectar por chave só acha a topologia que eu imaginei.** A guarda tem de olhar a forma que a
SSOT **prescreve**, não a que o autor do sinal usou. Duas formas legítimas do mesmo conceito, e a
cura cobria uma.

**4. Doutrina que promete mais do que a máquina faz e máquina que faz mais do que a doutrina diz são
o MESMO defeito.** O PR nasceu corrigindo a KB que prometia reprovações inexistentes — e na mesma leva
pôs no motor uma saída (`--validade`) que a KB não listava. O leitor não consegue prever o
comportamento a partir do texto em nenhum dos dois casos.

## O que NÃO caiu, e por que isso importa

O refutador atacou e não derrubou: exit code do radar inalterado em **131/131** grafos reais,
quoting não-injetável, o `exit 2` novo sem quebrar consumidor nenhum, as três cópias derivadas sem
drift de lógica. **Passada adversarial que só lista o que caiu não diz o quanto o resto aguentou** —
e é o que sobrevive ao ataque que dá força ao selo.

## A segunda história do mesmo dia — materializar não é publicar

Na mesma sessão, a porta pública `onion-core` foi re-materializada para tirar nomes de cliente do
HEAD público. Duas coisas que só o fazer revelou:

- **A sequência não era motivo para adiar.** `materialize-door.sh` monta com `git archive HEAD`, e o
  HEAD da branch em curso tinha trabalho não-mergeado. A saída não foi esperar o merge: foi uma
  **worktree destacada em `origin/main`**, de onde o archive é exatamente a main mergeada.
- **O pin é metade da cura.** Materializada e publicada a porta, a catraca seguia acusando `4/4` —
  ela lê **só** o `onion_version` do `members.yaml`. Porta nova com pin velho é trabalho feito que o
  gate não enxerga. Avançado o pin, caiu para `0/0`.

## Onde isso virou mecanismo

- `kg-radar.sh`: as duas guardas do `meta:` aplicadas ao `review_after` + validação de formato +
  `NÃO MEDIDA` no `--all` + `hoje` vazio declarado. Bancada `radar_validade`: **4 → 11 casos**.
- `lint-design-tokens.sh`: ilegível ≠ ausente (`exit 2`), detecção por dois sinais, `dark` ancorado
  como segmento. Bancada `design_tokens`: **10 → 13 casos**.
- `knowledge-graph-sdaal.md`: a saída VALIDADE entra na lista, com o registro de por que faltava.
- `door-staleness-baseline.txt`: o método da worktree e a armadilha do pin, escritos onde a próxima
  materialização vai ler.

> **Por que esta entrada existe.** Eu havia concluído que lição virada mecanismo dispensa registro —
> *"migalha é para o que ainda depende de alguém lembrar"*. O maestro corrigiu na hora: **se a migalha
> é só para lembrar, o que não é migalha vai para o diário, para não perder história.** O mecanismo
> carrega o comportamento; ele não carrega *como se chegou nele*. Um comentário no código diz o que a
> guarda faz — não diz que ela nasceu de um refutador reprovando o PR do próprio autor.
