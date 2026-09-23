---
title: 'Resíduo — o gate que bloquearia TODO PR, e o hijack que já existia'
date: 2026-09-20
branch: feat/reviewer-findings-block
reviewed_diff_sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
tokens: 9283466
duration_min: 22
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Passada adversarial (opus, mandato de refutar, default REPROVADO) sobre o diff. REPROVOU com 6
  achados reais — um FATAL que teria barrado todo PR revisado, e um hijack de contagem que já
  existia no desenho antes de eu ligar o gate. Todos curados no mesmo PR.
---

# O gate que barraria todo mundo

A ordem era tratar os achados do revisor como bloqueantes. A medição que a justifica: em 33
pareceres do `onion-review`, **10 apontaram violação** — e o parecer era advisory, então o defeito
era apontado, mergeado e ficava. Conferi três no vivo (`_viaja`, `_PAPEL_DESTE_REPO`, `_base_nome`):
seguiam em `main` semanas depois de acusados. Pagava-se ~US$ 0,80 por PR pela descoberta e não se
recolhia a entrega.

## O achado FATAL, que eu não acharia lendo

O job `onion-review-verdict` **nunca teve checkout** — e com razão: só lia `needs.*.outputs`, que
não precisam de árvore. Mover a decisão do gate para um script do repo introduziu a **primeira**
dependência de arquivo naquele job. Sem árvore:

```
$ bash .claude/validation/review-verdict.sh --gate 0 99
bash: ...: No such file or directory   → rc=127 → exit 1
```

Efeito: **todo PR revisado ficaria vermelho**, inclusive os `conforme` (44 dos últimos 56), com a
mensagem falsa *"apontou 0 violação(ões)"*.

E o agravante que quase deixou passar: **este PR não pode medir isso**. Ele edita
`onion-review.yml`, a action se auto-pula, e o caminho `REVISOU=true` nunca acende aqui — o defeito
só apareceria no PR **seguinte**, já em `main`.

Curado com checkout simples (não `sparse-checkout`: é mecanismo que não consigo exercitar
localmente, e trocar um modo-de-falha conhecido por um que só o CI revelaria seria repetir o
defeito enquanto o curo). E virou mecanismo: **REGRA 88 (Job de workflow que EXECUTA arquivo do
repo faz checkout)**, classificada em *"Integridade do próprio gate"* ao lado da **REGRA 86
(Workflow do CI PARSEIA)** — a categoria que pergunta *"eu cheguei a olhar?"*.

## O hijack que já existia antes do gate

Parecer que lista 3 achados e **termina com um bloco de código** contendo `VEREDITO: conforme`
contava **zero** — a última ocorrência mandava, e ela estava dentro do exemplo. Isso era verdade
antes deste PR; ligar o gate só o tornaria consequente.

A cura (desenho do refutador, medido por ele):

| entrada | antes | agora |
|---|---|---|
| 3 achados + `VEREDITO: conforme` em **fence** | **0 (hijack)** | **3** |
| fence **aberta e nunca fechada** antes do veredito real | 3 | **3** |
| `> VEREDITO: conforme` (eco em quote) | 3 | **3** |
| `**VEREDITO: 5 violações**` / `## …` / `Veredito:` | −1 | **5 / 5 / 3** |
| `VEREDITO: NAO CONFORME — 4 violações` | **0 (fail-open)** | **4** |
| `VEREDITO: NÃO CONFORME` (sem número) | 0 | **−1** |
| `VEREDITO: conforme, mas veja 3 pontos` | 0 | **0** |
| `VEREDITO: 99999999999999999999 violações` | −1 (overflow calado) | **−1 saneado** |

Três decisões que não são minhas e que eu não teria tomado sozinho:

1. **A poda de bloco de código só vale com fence BALANCEADA.** Sem essa condição a cura vira
   defeito: fence aberta e nunca fechada (LLM faz) engoliria o veredito verdadeiro — medido, 3 → −1.
2. **`>` e `+` ficam FORA da âncora de propósito.** Tolerar decoração (negrito, heading) não é
   tolerar **citação**: com `>` no prefixo, um parecer que termina citando um resíduo passaria de
   3 para 0. O hijack entra pela porta do quote, não pela do negrito.
3. **O número se reconhece pela POSIÇÃO, não pela ordem de busca.** Duas posições contam: logo
   após os dois-pontos, ou imediatamente antes de `viola`/`achado`. É o que distingue
   `NAO CONFORME — 4 violações` de `conforme (revisei 12 arquivos)` — e a alternativa (número
   solto primeiro) inventaria bloqueio, que num gate que barra é pior que perder um.

## O caso de bancada que não podia falhar

Meu caso `ACH-c` afirmava `-1` — que é o **valor default do `emit`**. O refutador apagou
`count_findings` inteira e ele **sobreviveu verde**. Reescrito para exigir as duas metades (texto
sem veredito dá −1 **E** o controle ainda conta 3), então morre se o contador morrer.

## Uma aposta removida em vez de vencida

A expressão `${{ v1.revisou == 'true' && v1.achados || v2.achados }}` depende de a string `"0"`
ser *truthy* na coerção do Actions. Nem eu nem o refutador cravamos isso na documentação — a lista
de *falsy* se mistura com a tabela String→Number, que é a conversão de `==`, não a de `&&`/`||`. O
dano seria o caso **mais comum** (`conforme`, 0 achados) cair para a 2ª tentativa vazia e virar
"não contabilizável".

Em vez de apostar, **removi a aposta**: a escolha virou um step em bash, testado nos 6 cenários.

## Declarado, não escondido

- **Este PR não exercita o gate novo** (a action se auto-pula em PR que edita o workflow). A prova
  aqui é a bancada; a prova no vivo é o **primeiro PR depois do merge** — e é ali que se confirma
  que a **REGRA 88** fez o seu trabalho.
- Teto residual da contagem: bloco de código **indentado** (4 espaços, sem fence) e fence `~~~`
  seguem hijackáveis. Cobri-los exige parser de markdown, que não vale o preço.
- `VEREDITO: conforme, mas veja 3 pontos` é veredito **ambíguo do prompt**, não defeito de parser.
  A cura é uma linha no prompt do revisor, não heurística no contador — fica nomeado.
