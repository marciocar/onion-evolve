---
branch: fix/scrub-term-granaai-hyphen
reviewed_diff_sha256: 973e36861236e1aa7f8f3652f0a1d9c56c1ff0802cf31ad17466381694cc5ce9
elenxo: sim
verdict: CORRIGIDO
findings_total: 9
findings_real: 9
tokens: 30393610
agents: 536
duration_min: 310
nota: "Elenxo veio das proprias rodadas de pesquisa (5 runs, 536 agentes, 30,4M tokens), que refutaram tres afirmacoes minhas: o '0 hallucinations' do JEV era slogan de REVENDEDOR; a cobertura de regra NAO destrava conflito (R1/R5 sobreviveram ao pre-registro); e o exit 2 que eu citaria como moat e substrato GRATIS da plataforma. Mais 4 defeitos achados por dogfood da propria entrega (vazamento de nome de cliente, ordem apply-vs-regen, corpus-grep sem bancada, mutante deixado no hook por kill)."
---

# Resíduo — cinco rodadas que me refutaram três vezes, e quatro defeitos achados usando o próprio produto

## O que entra

**Três curas de mecanismo**, cada uma com bancada e mutante:

1. **`kg-corpus-grep --query`** — a skill `onion-research` injetava `$ARGUMENTS` **sem quotes**, e uma
   pergunta com **parênteses** devolveu `syntax error` e **abortou a invocação inteira da skill**. O
   script que alimenta a 1ª cláusula da doutrina ("corpus primeiro") **não tinha bancada nenhuma**.
   Agora tem 6 casos, e os dois mutantes morrem — o defeito original **e** o que eu introduzi curando
   (`shift` dentro de `for a in "$@"` não move a iteração, e a frase entrava duas vezes).
2. **Invariante de ORDEM do hook** — a dependência estava escrita em **prosa** na linha 145
   (*"senão a cura acima cria outro defeito"*). Virou guarda: **nada pode mutar o índice depois do
   re-carimbo do SHA da REGRA 56**. 3 casos, 3 mutantes mortos.
3. **Scrub do nome vazado** — `/meta:kg-inbox` citava `_rejected/grana-ai-mapeamento-*` e isso viajava
   para **todo** adotante. A causa foi **vocabulário**: a guarda usa `grep -rilF` (**literal**), e o
   termo cadastrado era `Grana.Ai` — que **nunca** encontraria `grana-ai`. Eu afirmei que casava,
   testando **sem** o `-F`, e a medição me corrigiu. As quatro grafias entraram no registro.

**Cinco grafos de pesquisa** (182 nós, radar `exit 0` em todos) + **4 sínteses** com contrato de custo +
**a análise das três capacidades** que o maestro pediu antes de absorver qualquer uma.

## As três vezes em que a pesquisa me refutou

| eu afirmei | a medição disse |
|---|---|
| o JEV promete "0 hallucinations by construction" | **é slogan do REVENDEDOR** — o site não é do fabricante, e o preço dele está **6–10× inflado** |
| cobertura de regra destrava conflito e falso-positivo | **R1 e R5 sobreviveram ao pré-registro**: o campo detecta conflito **estaticamente sobre a definição**, nunca por contador de disparo |
| o `exit 2` de hook é o moat que compra o acoplamento | **é substrato NATIVO e GRÁTIS** da plataforma. O veto não é produto; o que se cobra é o corpus que decide e a prova que sobra |

A terceira é a mais cara de engolir: **as 26.596 linhas de shell que REPROVAM são a metade que o
mercado já provou não sustentar preço** — os produtos comerciais do OPA foram **doados** à CNCF, e a
Apple comprou o **time**, não a empresa.

## Os quatro defeitos que o dogfood da entrega achou

- **ordem apply→regen invertida** no `/meta:adopt`: regenerei baselines e **re-apliquei o bundle por
  cima**, apagando o que acabara de emitir. No repo do cliente isso significou **126 HARD** em vez de 15.
- **`git archive HEAD` lê o COMMIT**, não a árvore — o bundle carregava a cura não-commitada.
- **pin de branch carimbado** num adotante: empacotei do HEAD da branch em vez de `origin/main`.
  Corrigido antes de entregar; o conteúdo era idêntico, só o pin mentia.
- **mutante deixado no `pre-commit`** por um `exit 137` que matou a sessão no meio do teste. Restaurado e
  conferido **por ausência**. Lição: **teste de mutação sem `trap` de restauração deixa o repo pior que
  antes** — fica como fio.

## Gate

`lint-artifacts.sh` → **0 HARD**, `rc=0` · bancada: famílias `corpus_grep` (6), `hook_chain_order` (3) e
`kb_applies_to` (8) verdes · radar `exit 0` nos 5 grafos · índice de leitura do KG regenerado (1 entra,
0 sai).

Merge por **dispensa registrada**: o revisor do CI segue sem crédito **por decisão do maestro**
(`D_SEM_CREDITO_POR_ORA`).
