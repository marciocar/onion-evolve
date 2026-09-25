---
title: 'Passada adversarial — o registro da dispensa era um contra-barra'
date: 2026-09-25
branch: fix/dispensation-record-was-a-backslash
reviewed_diff_sha256: c19aff1b94f210ff783c3587fa9c66d5f1318fc46dc2ef6aa66a4c511913f789
elenxo: sim
findings_total: 13
findings_real: 13
verdict: REPROVADO_E_CURADO
tokens: 219001
duration_min: 59
agents: 1
nota: 'Refutador opus/high em worktree isolada, mandato REFUTAR, default REPROVADO. Voltou REPROVADO com 13 achados reais e 1 não-medido declarado. Quatro eram medições anteriores a correções que eu já havia feito (verificadas uma a uma antes de descartar, não descartadas por conveniência); nove viraram cura com caso de bancada e mutante. Três derrubaram trabalho meu do mesmo PR, inclusive uma afirmação FALSA que eu havia escrito dentro do código. Depois do parecer, um reforço do maestro rendeu dois furos que nem eu nem o refutador achamos.'
---

# Resíduo — `fix/dispensation-record-was-a-backslash`

## O defeito de origem

`ops/pr-merge-verified.sh` montava o corpo do registro de dispensa com
`printf '%s\n' \\` — **dois** contra-barras. O primeiro escapava o segundo, o `printf` recebia um
contra-barra literal e a linha **terminava ali**; as linhas seguintes viraram um comando que o bash
tentou executar (`## ⚠️ Merge com check DISPENSADO: command not found`, visível na saída do merge do
#874). O `gh pr comment` postou `\`, saiu 0, o `die` nunca disparou, e o script imprimiu
**"✓ dispensa registrada"**.

O bloco se descreve como *"PRECONDIÇÃO do merge, não cortesia"* e como *"dispensa que só existe no meu
terminal não se audita"*. Ele não registrava nada. **O rc do comando é declaração sobre si; verificar
é contar o que ele produziu.**

## O que o refutador achou, e o que eu fiz com cada achado

| # | achado | desfecho |
|---|---|---|
| 1 | 4 HARD no lint | **caduco** — projeções regeneradas após a cure 4; re-medido rc=0 |
| 2 | REGRA 90 (Prosa de comando conhece os papéis que o script aceita) **vácua**: `grep -qiF "hub"` casa em `GitHub` | **curado em 3 voltas** (ver abaixo) |
| 3 | a guarda lia **comentário** do helper como aceitação | curado: `grep -v '^[[:space:]]*#'` antes; provado no helper real |
| 4 | `co-evolve.md` não protegido pela regra | **caduco** — par de união já adicionado; re-medido rc=1 ao mutilar |
| 5 | `exit 3` inalcançável | **caduco** — já separado de rc=1; re-medido rc=3 |
| 6 | minha afirmação sobre o corpus vivo é **falsa** | **confirmado e corrigido** (ver abaixo) |
| 7 | EPIPE sob `pipefail` recusa corpo VÁLIDO >64 KB | curado: `<<<` em vez de `printf \|` |
| 8 | `--motivo " "` torna o 3º elemento vácuo | curado: recusa motivo em branco |
| 9 | rótulo diz "credencial" para `HTTP 000` e `529` | curado: 6 faixas com ação nomeada + "não classifico" |
| 10 | "Não bloqueia o merge" é falso desde 2026-09-20 | curado: texto reescrito com o comando de dispensa |
| 11 | `from: avansat` carrega nome comercial | curado: slug neutro do registro |
| 12 | `edges:` **indentado** escapa da cura | curado: fecha em `edges:`/`meta:` em qualquer indentação |
| 13 | frente do workflow com **zero** bancada | curado: família que EXTRAI o bloco do YAML e o executa (7 casos) |

## Os três que doeram

**(2) A regra nova nascia vácua, e precisou de três predicados.** `grep -qiF "hub"` casa dentro de
`GitHub` — e "GitHub" é a palavra mais provável de aparecer num comando de co-evolução, então a guarda
escrita para matar o silêncio sobre `hub` estava viva **por sorte**. Fronteira de palavra curou `hub` e
**não** curou `source`: em "projeto open source", `source` é palavra com fronteira dos dois lados. A
terceira porta foi aceitar "papel na mesma linha que `role`" — e a mesma linha que diz `role: adopted`
dizia "open source". O que separa papel de homônimo é a **notação**: nesta casa papel se escreve em
crase. Fronteira de palavra resolve colisão de SUBSTRING; não resolve HOMONÍMIA.

**(6) Escrevi uma medição falsa dentro do código.** O comentário dos casos novos afirmava *"o corpus
vivo do core NÃO expõe isso: antes e depois dão saída IDÊNTICA"*. Sondei com 3 termos, mantive a frase
depois de sondar com 10, e as duas sondas não distinguiam os labels em disputa.
`claude-code-2.1-onion-2026-08.kg.yaml` tem **4 arestas rotuladas**, e o último nó dele
(`D_REGENERAR_BASELINE_POR_DESCOBERTA_NAO_POR_LISTA`) exibia o label da última aresta. O bug estava
**ativo**. Sondar no caminho errado é não ter medido — e eu transformei isso numa afirmação escrita,
que é como uma medição ruim vira doutrina.

**(7) Reintroduzi no gate de MERGE uma classe curada em 489 sítios.** `printf "$grande" | grep -q` sob
`pipefail` é corrida: o `grep` casa e sai, o `printf` morre de SIGPIPE, e a guarda chama de "corpo
INCOMPLETO" um corpo que contém o termo. Medido com motivo de 70 KB: 10 de 12 execuções falhando
espuriamente. Fail-closed e raro — e é o gate de merge, e eu não tinha caso nesse tamanho.

## O que o reforço do maestro achou, e nenhum dos dois

*"precisamos ver se o padrão `adopted|hub|standalone|source` está completo em todos os lugares"* —
varredura de todos os sítios que decidem por papel:

- **`resolve-target.sh` `todos`** era `tier hub` ∪ `tier standalone`, uma **lista**. A unificação de
  vocabulário de 2026-09-24 (`consumer`→`adopted`) criou um papel que a lista não conhecia, e `sge` —
  único membro `role: adopted` — ficava **fora de todo anúncio**. Nenhum gate acusava.
- **`co-deliver.sh`** recusava `adopted` com uma mensagem sobre `role=consumer`, conceito diferente.
- **`IS_DERIVED` do lint NÃO é furo**: a ausência de `standalone` é decisão medida e revertida no mesmo
  PR (2026-09-18) — dezessete guardas desligariam de uma vez. Lido antes de concluir.

A cura não foi acrescentar o papel às listas — foi **parar de enumerar**. A RFC-0003 §2.1 nunca falou
de nomes de papel: o critério é *"adota o core direto"* vs *"adota um hub"*, que no registro é o campo
`parent:`. Papel novo entra por construção.

E **duas armadilhas minhas na própria cura**, ambas achadas por caso de bancada que eu escrevi:

1. li a hierarquia por `graph.sh --triples` em vez do `member_field` que o script já usa — criando uma
   **segunda fonte** para a mesma pergunta. A bancada passa um `members.yaml` de sandbox pelo acessor,
   então o helper passou a julgar por um registro diferente do que recebia: **4 casos caíram de uma
   vez**, dois sem relação com papel. Um dado, um acessor.
2. derivei o id do core como *"o `parent` mais frequente"*. Num registro com UM membro cujo `parent` é
   um hub, o mais-frequente **é esse hub** — o helper elegia o hub como core e entregava a um T2
   exatamente o anúncio que a RFC manda o hub propagar. A heurística se auto-satisfazia no caso que
   mais importa barrar. Trocada por constante declarada com override de ambiente.

## Degradação declarada (o que a cura NÃO resolve)

`parent:` ausente → o registro não expressa hierarquia, e o papel é o único sinal. `hub` e `standalone`
passam (são T1/T3 por definição). **`adopted` sem `parent` é recusado pedindo o campo** — `adopted` é
exatamente a palavra ambígua, e escolher um lado por conveniência seria decidir o que não se sabe.

## Gate

- `lint-artifacts.sh` → **rc=0 · 0 HARD · 14 SOFT**
- `lint-selftest.sh --affected-staged --jobs auto` → **1487 casos · 0 falhas · 192 famílias · 882s**
- `prettierignore` falhou numa faixa e passou isolada e na re-rodada da faixa — classe flaky já
  registrada, **não** deste diff.
- `kg-radar --integrity --schema` → rc=0 · `members-validate.sh` → rc=0 (21 membros)
