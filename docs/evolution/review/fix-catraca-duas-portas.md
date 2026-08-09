---
branch: fix/catraca-duas-portas
date: 2026-08-09
reviewed_diff_sha256: ac88a8f76c17e881d915f486bf038ff8bd3410a498d82d4900230faadf17f09e
findings_total: 16
findings_real: 13
findings_fixed: 11
tokens: 460915
duration_min: 48
verdict: HARD-MAS-NAO-COMO-ESTAVA-A-CURA-DE-UMA-PORTA-ABRIU-DUAS
reviewer: Elenxo — 3 refutadores por lente + juiz (opus/high), wf_daef8e90-4ad
---

# Passada adversarial — a cura de uma porta abriu duas, e as duas eram minhas

**3 lentes, 16 achados, veredito `HARD-MAS-NÃO-COMO-ESTÁ`.** A tese central sobreviveu — *mover não é
remover, e apagar não descarrega medição* — e as cinco medições do enunciado conferiram uma a uma.
O que não sobreviveu foi a implementação.

## O defeito que o PR existe para fechar

```
git mv <um grafo> <dir>/fixtures/   →  48 vira 43, exit 0, CINCO SOFT "remova do baseline"
```

Os nós seguiam **intactos no disco, versionados, afirmando sobre produção**. O universo varria
`grep -v '/fixtures/'`, então mover o arquivo o tirava do universo e as entradas viravam *"nó que
NÃO EXISTE MAIS"*. A segunda porta era `REMOVIDO` ser SOFT: apagar também encolhe sem medir.

**A correção:** o universo passa a varrer **tudo**, com uma 7ª coluna dizendo se o path está no
escopo — resolver a chave exige o corpus inteiro; filtrar o escopo é **outra pergunta**. Classes
novas: `MUDOU-DE-PATH` (HARD fora do escopo, SOFT em path vivo), `REMOVIDO` HARD, `ID-AMBIGUO` HARD.

A justificativa do `REMOVIDO` HARD: **o grafo já tem a forma honesta de aposentar um nó** —
`superseded`/`refuted` com a aresta, que sai SOFT pelo ramo `RECONCILIADO`. Deletar é o atalho que
pula a aresta.

## Os três defeitos que EU criei ao curar

**1 · A catraca de crescimento estava morta no CI — e é anterior a este PR.** O `prev` vinha de
`git show HEAD:`, e o CI faz checkout do próprio commit: `prev == known` **sempre**, a comparação era
do commit contra ele mesmo. Isso derruba a propriedade que o cabeçalho declara como fundadora —
*"resíduo material auditado por TERCEIRO, desacoplado do ator"*. O terceiro nunca auditou.

Mas a minha 1ª cura **reabriu o bypass total** por outro lado: quando o ref resolvido não continha o
baseline, `prev` ficava vazio, `TO_JUDGE` virava só `known`, e o bloco (3) inteiro se calava.
Reproduzido pelo Elenxo num cenário **real, não forjado** — adotante recém-instalado, cujo baseline
nasce na própria branch: `48→43, exit 0, HARD 0, zero medição`.

**A função da base me pegou três vezes seguidas**, e sempre pelo mesmo motivo: eu tentava resolver
com **uma** regra o que são situações diferentes.

| tentativa | regra | o que quebrou |
|---|---|---|
| 1ª | *"nunca o HEAD"* | pré-commit, onde a mutação está no working tree — 4 selftests em `SEM-BASE` |
| 2ª | *"HEAD se o baseline dele diferir"* | o caso em que só o **grafo** muda |
| 3ª | *"1º ancestral cujo baseline difere"* | andava história adentro e ressuscitava 5 entradas quitadas em 04/08 |
| **agora** | **pré-commit (árvore suja) → ponto de ramificação → conteúdo** | os três fecham |

**2 · Abri o vetor da colisão de id ao abrir o universo.** A 2ª passada jogava o path fora e
desempatava com `head -1`. O corpus tem **13 ids duplicados** entre grafos, `E_ORBIT` **está no
baseline**, e `.claude/validation/fixtures/…` é o **primeiro** do `git ls-files` — então um fixture
homônimo sempre vencia. Antes deste diff, o `grep -v '/fixtures/'` impedia esse vetor.

O Elenxo mostrou a cadeia completa: apagar só o nó `E_ORBIT` dava `SOFT MUDOU-DE-PATH`; obedecendo o
conselho do gate commit a commit, o baseline ia **48→47, nó PROD/impact 5 apagado, zero medição,
verde do começo ao fim, guiado pelo próprio gate**.

**Curado com o teste do homônimo** — *"o nó já existia no destino ANTES desta branch?"* — provado com
ponto de ramificação real. E a 1ª versão desse teste tinha o seu próprio fail-open: com `BASE_REF`
vazia, `git show ":path"` lê o **índice**, que acabara de receber o arquivo movido, e o teste dizia
*"já existia"* sobre um `git mv` legítimo.

**3 · Medir não descarregava.** O bloco de path rodava **antes** do bloco de carimbo: um nó **com**
`verified_at` movido levava HARD dizendo *"SEM ser medido"*, e o remédio prescrito (*"meça"*) **não
limpava o HARD**. O instrumento afirmava sobre um campo que nunca leu — `declarado ≠ verificado`
dentro do gate que existe para cobrá-lo, o mesmo pecado que o cabeçalho comemora ter curado no
antigo `OBSOLETA`. E o ramo SOFT mandava **manter no baseline entradas já quitadas**, congelando a
métrica que o rodapé declara como saúde.

## O custo explodia exatamente onde as classes novas falam

```
0 órfãs → 0,88s   ·   5 órfãs → 47,26s (~9,4s/chave)   ·   15 órfãs → TIMEOUT (>120s)
```

A causa é um defeito que eu **já tinha corrigido neste mesmo arquivo e repeti**: `resolve_key` roda
em command substitution, então a memoização feita lá dentro morre com o subshell e o índice era
reconstruído a cada chave. Içado ao escopo pai — e só quando existe órfã — o custo virou **10,8s
fixos**, com o corpus limpo em 0,97s.

## O que o Elenxo cobrou e ficou de pé

- **`ID-AMBIGUO` é HARD**: um instrumento que não sabe qual nó é não pode mandar reescrever chave.
- ***"segue no escopo"* passou a ser MEDIDO**, não declarado — `rdentro` só dizia *"o path não está
  sob fixtures/"*, e a frase saía sobre um nó `superseded`, que a própria denylist põe fora.
- **`_run49` guarda o stderr** e os casos exigem **vazio**: era o único canal em que o gate grita
  erro, e a bancada o jogava fora.
- **Asserções de mensagem** em `(n)`, `(u)` e `(u2)` — o texto do conselho faz parte do contrato.

## Verificação

- bloco da catraca **19/19**, incluindo o **`(v)`** novo, que exercita os **três degraus da base**
  com cenário próprio e afere o **comportamento** (o bypass é pego?), não o ref escolhido
- corpus limpo `48 · 48 · 0 HARD · 0 SOFT`, `0,97s` · adotante `exit 1 · 5 HARD REMOVIDO`
- `git mv → fixtures/` **5 HARD** · `git mv` → path vivo com chave reescrita **exit 0** · `git rm`
  **5 HARD REMOVIDO** · nó **carimbado** movido **SOFT CARIMBADO, exit 0**
- bancada completa, corrida **SOLO**: ver rodapé · `lint-artifacts` 0 HARD

## O meta-achado: eu medi artefato defasado TRÊS vezes hoje

1. um sandbox onde o `git reset --hard` **reverteu o script que eu acabara de copiar** — o teste
   rodou contra a versão velha e disse que a cura falhou;
2. a âncora do meu extrator ficou **morta após um rename** (`SUMARIO_IMPRESSO` → `SUMMARY_PRINTED`),
   e o trap anti-abort deixou de entrar no runner;
3. um runner construído **antes** da edição — os dois últimos "18/18" mediram código sem o `(v)`.

As três produziram um número que eu quase relatei como verdade. **A cura foi a mesma nas três:
construir e medir na MESMA invocação, com uma guarda que recusa rodar se o artefato não contém o que
deveria** (`grep -q 'falha_v' "$T" || return 1`).

## Dívida declarada

- **A dobradinha `HARD NOVO` + `SOFT MUDOU-DE-PATH`**: mover sem reescrever a chave dá 5 HARD por
  **um** arquivo. É desenho (a chave mudou), mas a avalanche ensina a ignorar o gate. Suprimir o
  `NOVO` quando o mesmo hash existe em `prev` sob outro path, ou emitir um HARD por **arquivo**.
- **Ruído do rename já reconciliado**: não emitir quando a chave nova já está em `known`.
- **`(u2a)`** — o estado intermediário (mv sem reescrever) só existe na tabela, não no teste.
- **O custo residual**: 10,8s vem de um `sha1sum` por nó. A cura estrutural é a 8ª coluna emitida na
  mesma passada do `load_universe`, o que exige hash sem fork por nó.
- **A guarda anti-fail-open do shell superdispara** em `cmd > arquivo 2>&1` seguido de `rc=$?`:
  ela acusa `EXIT-CODE-DE-PIPE` onde não há pipe. Três ocorrências nesta sessão. Falso-positivo de
  guarda é o que ensina a ignorá-la — mesma família que este PR passou o dia curando.
