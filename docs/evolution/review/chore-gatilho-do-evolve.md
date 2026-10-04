---
reviewed_diff_sha256: fe6253d77ce337f01495db1cee5246beda522124b0c54e0ff484582fdaf98478
findings_total: 13
findings_real: 13
tokens: 174581
duration_min: 15
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Refutador opus/high em worktree isolada, mandato CAÇAR FALSO POSITIVO (não o defeito): 174.581
  tokens, 59 chamadas, ~15 min. Placar dele: 5 falsos positivos (2 BLOQUEANTES), 7 falsos
  negativos, 8 aprovados, 3 não-verificados — e **5 das minhas 6 afirmações caíram**. Todos os 12
  achados materiais estão curados nesta branch, com 11 casos no `--selftest`, 5 na bancada e 10
  mutantes mordendo. O mais importante não é o número: é que os dois fatais eram **estruturais** —
  a guarda punia quem obedecia ao conselho dela, e a tese de desenho que eu defendi (derivar é
  melhor que campo digitado) não se sustenta como foi afirmada. Os dois estão corrigidos no grafo,
  não só no código.
---

# Resíduo — `chore/gatilho-do-evolve`

## O fatal, e a ironia é exata: **a guarda punia quem obedecia**

Meu caso `(f)` e o `(b)` da bancada **afirmavam sobre o repo vivo**. Então bastava **rodar o
`/meta:evolve`** — o conselho que a própria guarda dá — para a bancada **falhar**. E como o
`lint-selftest.sh` sai 1 com qualquer FAIL, o *"SOFT por desenho"* era **ficção**: ela bloqueava o
gate. Pior: nascia **vermelha em todo adotante**, o que **refuta por execução** o item do meu próprio
teto que dizia *"o adotante recebe a bancada, que sintetiza a fixture"* — não sintetizava.

A cláusula 4 fala de veto ignorado. Isto é pior: **veto que pune a conformidade**.

## O segundo fatal: a tese de desenho caiu

Eu afirmei que derivar era melhor que `last_run:` digitado porque *"as duas pernas juntas são mais
difíceis de simular"*. Ele provou que **as pernas não são peer** — `_population_delta "${_LAST}"`
**consome a saída da perna 1** — e **calou as duas com um arquivo**:

```
### criado: onion-evolution-triagem-sinal-de-campo-2026-10-04.md
rc=0  saida=[]
  ✅ REGRA 97: auto-auditoria fresca (2026-10-04, 0d) e sem delta populacional
```

E **dois arquivos daquele tipo já existiam** no repo — são triagem de inbox (`type:
evolution-backlog`), não rodadas do evolve. Um `last_run:` digitado **não** é forjável assim.

O glob estrito fecha o caso medido; a **dependência estrutural permanece** e ficou **declarada** no
teto em vez de vendida como redundância.

## Os demais, e todos curados

| # | Achado | Cura |
|---|---|---|
| FP-2 | a perna 2 disparava em **52 de 60 dias** (limiar `>0`) — guarda que nunca cala é a que a sessão aprende a ignorar | `EVOLVE_DELTA_MIN`, default 40 (~10% da população vigiada) |
| FN-1 | `--since=<data nua>` significa *"essa data na HORA ATUAL"*, não o início do dia: a perna era **cega ao dia do relatório** | `T00:00:00` — e isso **corrige meu número de manchete: 289 → 291** |
| FN-3 | relatório com data **futura** calava as duas pernas **para sempre** | `EVOLVE-DATA-FUTURA` |
| FN-6 | o 3º fallback de data era **código morto** (aspa não fechada) **e a mensagem mentia sobre a causa** ("awk sem mktime" quando o awk tinha) | aspa fechada; o fallback devolve epoch |
| FN-4 | fail-open do dispatcher — **clone byte-a-byte do defeito da guarda irmã** | **curado nas duas**: uma invocação, rc lido, `>=2` vira HARD |
| caso (d) | **tautológico**: interrogava uma constante fabricada, e o mutante SOFT→HARD **sobrevivia** | interroga a **saída da guarda** |
| FN-7 | `ONLY_PATH` cobria 3 das 5 famílias que a perna 2 vigia | as cinco |
| FP-4 | `docs/analysis/` é opt-in genérico, e a mensagem afirmava *"o repo se chama Onion Evolve"* — falso num repo de cliente | mensagem reescrita; opt-in genérico **declarado** no teto |

**As curas vieram sem caso, e os mutantes provaram:** 5 dos 10 sobreviviam à primeira passada
pós-cura. Daí `(h)` glob estrito, `(i)` limiar, `(j)` `--since` ancorado, `(k)` data futura.

## Três defeitos meus no próprio conserto, porque são classe

1. **`local` num bloco top-level** — o `bash -n` **não pega**; só executando aparece.
2. **`/bin/bash` relativo** quebrando depois do `cd` do sandbox → resolvido em **absoluto antes de
   qualquer `cd`**, preservando "é o artefato em teste".
3. **A minha mensagem de violação virou invocação fantasma** — ela escrevia
   `rode 'bash .../check.sh . --tsv' e leia o stderr`, e a **REGRA 59 (Modo que a produção consome
   é exercitado pela bancada)** leu `--tsv e` como flags. **Terceira ocorrência hoje** da família
   *documentação indistinguível de invocação viva*, e a primeira em que o lado curável era o meu
   texto: a mensagem **descreve** o comando em vez de escrevê-lo.

E um quarto, de método: o script de cura **escrevia o arquivo na última linha**, então um `assert`
que falhou no fim **descartou duas curas já aplicadas** — e eu li um `grep -c` como prova de que
tinham entrado. Fail-closed correto, leitura minha errada.

## O 13º achado veio do CI, não do Elenxo — e é de FRONTEIRA

O shard 2 reprovou com o gate local **verde**: o `ops/materialize-door.sh` recusa a projeção pública
quando um artefato cita um **documento nomeado** sob `docs/analysis/`. O diretório nu descreve a
arquitetura e fica; `docs/analysis/<algo>.md` é **ponteiro para documento core-privado** — e esta
guarda **viaja para a porta**. Minhas seis fixtures escreviam o nome literal (10 ocorrências).

**Cura:** os nomes de fixture são **compostos em runtime** (helper `_rel`), nunca literais. São
fixtures sintéticas, e compor diz isso ao leitor **e** ao detector. Medido: 10 literais → 0, e o
materializador deixou de acusar.

O caso `door: (g)` caía **por um motivo que nada tem a ver com o que ele mede** — o materializador
abortava antes do passo medido. É a assinatura exata de bancada medindo ambiente, e o comentário do
próprio caso já descrevia essa armadilha para outro cenário.

**E uma classe na minha verificação:** ao conferir a cura rodei o materializador com `--from HEAD`,
que lê o conteúdo **commitado** — ele seguia acusando as linhas antigas enquanto a árvore já estava
curada. **Testar o commitado em vez do da árvore, pela segunda vez hoje.**

## O que fica declarado em vez de resolvido

- **As pernas não são peer.** Pernas de fato independentes exigiriam a 2 medir contra um **marco
  próprio** (ex.: o commit que tocou o relatório). É leva própria, e está no grafo.
- **Granularidade de dia**: `T00:00:00` não ordena antes/depois **dentro** do dia do relatório.
  Preferi errar para o lado de **avisar** num caso de borda de um dia a deixar a perna cega ao dia
  inteiro, que era o defeito anterior.
- **O gatilho nasceu antes do comando re-forjado** (`Q_O_GATILHO_NASCE_ANTES_DO_COMANDO_RE_FORJADO`):
  se o re-forjar mudar o artefato que o evolve produz, a perna 1 cai em `EVOLVE-SEM-RODADA` — que é
  fail-safe, mas pelo motivo errado.
- **Não-verificados pelo refutador**: faixa concorrente sob `--jobs`, o caminho BSD `date -j`, e se
  `head -c N` pertence à classe. Declarados, não resolvidos.
