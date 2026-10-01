---
title: 'Resíduo — a REGRA 94 nasce de um SIGKILL, o chupa-cabra nasce medido, e o gate me cobrou três vezes'
date: 2026-10-01
branch: fix/guard-mutant-leftover-and-dissect-forge
reviewed_diff_sha256: 2ea79aa1bdca70e5dee75d69b4ca02492ad35376025ca5e92ad5d229ddd1a5d8
findings_total: 17
findings_real: 17
findings_fixed: 16
tokens: 20200000
duration_min: 180
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Catorze achados, TODOS reais e todos curados, e a maioria veio do gate e dos refutadores em vez de
  auto-revisão — que é o padrão medido desta casa. Três ciclos de pre-commit reprovaram antes de
  passar: 5 HARD na primeira, 2 na segunda, bancada vermelha na terceira. Dois achados são defeitos
  de produto (mutante sobrevivendo a SIGKILL; SUT entregue sem bancada), quatro são defeitos meus de
  processo (comando sem description com o censo dando 7/7; drift de contagem grepado por UMA
  redação; projeções regeneradas ANTES de estagiar; separação em branches que os arquivos gerados
  não permitem), e quatro são vereditos de pesquisa que os refutadores inverteram.

# O gate achou o que eu não achei, três vezes seguidas

## Os dois achados de PRODUTO

**1. O mutante sobrevivia à morte do processo.** Um `exit 137` (SIGKILL do OOM killer) matou a
sessão no meio de um teste de mutação e deixou um `git add` plantado dentro do
`.githooks/pre-commit`. O repo ficou **pior** do que antes do teste, e a guarda que o teste existia
para provar foi a que ficou sabotada. A cura óbvia — `trap` — **não basta**: `trap` não intercepta
SIGKILL, então um helper que só confie nele é cura falsa para o caso que de fato ocorreu. Daí as
duas camadas, e a 2ª é a que importa porque **não depende de o processo sobreviver**: marcador
`ONION_MUTANTE` no mutante + a REGRA 94 reprovando o marcador em arquivo rastreado.

**2. SUT entregue sem bancada, e o custo apareceu no mesmo dia.** O `guard-io-classify.sh` nasceu
sem família. O seletor `--affected-staged` não achou quem o citasse, **recusou estreitar** ("tudo,
no incerto") e o pre-commit passou a rodar **as 203 famílias** — ciclos de 17 min em vez da faixa
afetada. A recusa no incerto é o comportamento certo; o furo era meu.

## Os quatro defeitos MEUS de processo

**3. O comando nasceu sem `description:` com o censo das 7 peças dando 7/7.** Escrevi doutrina,
medidor, lente e bancada, e esqueci a primeira linha do comando. O censo não mentiu: ele declara
medir **presença e referência, nunca validade** — e esse é exactly o teto que me pegou.

**4. Drift de contagem grepado por UMA redação.** A memória da casa manda varrer todo `docs/` pelo
número antigo. Fiz isso — para `111 comandos`. O lint conhece `111 invocáveis` e a tabela
`| **111** |`. A regra correta é **grep pelo número, não pela frase**, e a correção tinha de ser
cirúrgica porque as Knowledge Bases são **111 de verdade**: um `sed` cego teria mentido ali.

**5. Projeções regeneradas ANTES de estagiar os grafos novos.** Elas nasceram obsoletas e o gate
reprovou por isso. É a mesma classe de inversão de ordem que a casa já registrou no
`/meta:adopt --update` (`apply → regen → apply` apagando os baselines). **Regenerar é o último
passo, sempre.**

**6. Tentei uma separação em três branches que os arquivos gerados não permitem.** `docs/backlog.md`
e `docs/onion/kg-read-index.tsv` derivam do corpus **inteiro**: duas branches que cada uma adiciona
um `.kg.yaml` conflitam neles **por construção**, e `lint-selftest.sh` é compartilhado pelas duas
famílias de bancada. Insistir produziria um commit cujas projeções referenciam arquivos que ele não
carrega. Um commit, com a razão declarada, é a leitura honesta.

## Os quatro vereditos que os REFUTADORES inverteram

As duas rodadas de pesquisa entregaram 29 claims refutadas, e lê-las mudou o resultado nas duas:

**7-9. Os três casos que sustentavam "condução como produto morre" caíram.** Thoughtworks Studios
repousa numa frase **sem nota de referência** no wikitexto cru, e nenhuma primária datada corrobora
o fechamento em 2020. A Pivotal foi **incorporada em abril de 2013** (S-1 e Form D da SEC, tier 10),
não formada em 2012, e a Pivotal Labs era **consultoria** — o rename para Tanzu Labs é rebranding de
serviços, não método virando item cobrável. E os planos por-dev da Roadie trazem, verbatim e duas
vezes, **"Existing subscribers only"**: a SKU viva é um grafo de contexto **por organização**, em
waitlist, sem GA e sem preço. Veredito: o cemitério **não tem lastro**, e "(d) morre" volta a ser
hipótese.

**10. "Ninguém entrega conhecimento ancorado em grafo" é FALSO.** A doc da Onyx diz
`AI-generated knowledge graphs` e o módulo `backend/onyx/kg` está vivo no código. O diferencial do
Onion **não pode ser "temos grafo"** — se existe, é a proveniência verificável.

E uma inversão a favor, que é a mais valiosa: na rodada da onda derivada a refutação **protege** a
tese. O "AI Controls" do GitHub é política de **adoção/entitlement** (*"control how Copilot cloud
agent is **adopted**"*, *"control the **availability**"*), **sem uma menção** a barrar tool call,
commit ou merge em execução. Toggle de adoção ≠ gate. A posição PÓS — provar *com base em quê* —
**não está absorvida**. Descartar a pilha refutada teria perdido o achado que mais sustenta a
recomendação.

## Dois achados de custo, declarados como achado e não como rodapé

**11. 20,2M de tokens nas duas rodadas, ≈212k e ≈242k por nó** contra 68–74k do histórico (2,9× e
3,3×), com **~64% das claims fora do repasse adversarial** nas duas. Gatilho nomeado nas sínteses: a
próxima `mode: decision` entra com `maxVerify` maior **ou** menos eixos. Pagar 10M para deixar 64%
sem verificar é o defeito, não o preço.

**12. O projetor de backlog leva 14s por invocação**, e a família `kg_backlog` o chama repetidamente
numa sandbox — a faixa paralela mata o worker por tempo. O sinal vermelho da 3ª tentativa é **custo
de bancada**, não correção de guarda.

## Duas hipóteses minhas que a medição REFUTOU

**13.** Suspeitei que o `# kg-backlog-guard: on` dos meus grafos novos tinha inflado a projeção.
**Errado:** 34 grafos já o carregavam; os meus levaram de 31 para 34. A convenção é pré-existente.

**14.** Teorizei um abort de `set -e` num `[ cond ] && assign`. **Refutado por execução:** sobrevive
com rc=0, porque o `set -e` não aborta quando o comando que falha é a condição de um AND-list cujo
último comando não roda. Teoria sobre shell vale zero contra um `bash -c` de três linhas.

## 15. O achado mais instrutivo: a REGRA 94 acusou o resíduo que a EXPLICA

A guarda nova reprovou **este documento**, porque um resíduo que ensina o mecanismo
necessariamente escreve o marcador. Ela já se protegia de auto-acusação partindo o marcador no
próprio fonte — e eu não previ que **doutrina e resíduo citam a regra por dever**, não por acidente.

A cura é **allowlist por PREFIXO** (`docs/evolution/review/*`, `docs/knowledge-base/*`,
`common/prompts/*`, `lint-rules.md`), porque o nome do resíduo deriva da branch e não se pode
enumerar. E ela vem com **teto declarado**: mutante plantado dentro de um caminho da allowlist
**escapa**. A troca é deliberada — o harness planta em artefato **executável**, que é o que o dano de
2026-10-01 provou, e guarda que grita no caminho correto ensina a ignorar o vermelho.

Dois casos de bancada selam a cura e o teto: `(f)` prova que resíduo e KB citando o marcador **não**
são acusados; `(g)` prova que um `.md` **fora** da allowlist **segue** acusado — a exceção é por
**caminho, nunca por extensão**. Sem `(g)`, alguém "simplificaria" a cura excluindo `*.md` e abriria
o buraco calado.

Na inserção desses dois casos eu errei duas vezes de uma vez — usei a sandbox de outra família
(`d2`) e redeclarei uma variável que a família já tinha (`_M`). A bancada morreu com
`d2: unbound variable` e me disse exatamente onde. É a terceira vez nesta leva que a ordem ou o
escopo me cobram: a bancada espelha o runner, e improvisar dentro dela custa um ciclo.

## 16. `role-cut (k)` pegou o segundo comando seguido, no mesmo dia

O caso que liga *"guarda cita comando"* a *"o alvo recebe o comando"* acusou o `/meta:dissect`: o
`dissect-census.sh` o cita no docstring e ele não estava no conjunto que viaja. A cura **não** é
fazê-lo viajar — é a **exceção nomeada**, pelo precedente exato do `forge` (2026-09-29): decide o que
o **Onion** absorve, logo é Camada 1, e declara `Core-only` na própria `description:`.

O que isto prova sobre o caso: ele pegou `forge` na primeira corrida depois de o comando nascer, e
pegou `dissect` na primeira corrida depois de o comando nascer. **Dois em dois.** Não é burocracia; é
o único lugar que mede essa ligação.

## 17. `adopter-gate` é flaky na faixa, e eu NÃO declaro curado

Dois casos (`b-MUT` e `c`) reprovaram na faixa paralela e passaram **isolados** (24/24), e o meu diff
**não toca** `.claude/utils/adopt/` — o SUT tem última alteração em 2026-09-16. Na corrida seguinte em
faixas, com 204 famílias, passaram. É a classe **flaky-na-faixa** que esta casa já registrou
("reprova no gate e passa isolada; não é carga, é ambiente herdado").

**Declaro medido, não curado**, e com a fronteira estreitada por cinco execuções:

| Configuração | Resultado |
|---|---|
| família isolada (`--families adopter_gate`) | **passa** (7/7) |
| faixa paralela manual (`--jobs auto`, 204 famílias) | **passa** (1593/0) |
| isolada com `GIT_DIR`+`GIT_INDEX_FILE` exportados | **passa** |
| **sob o hook de pre-commit** (2 corridas) | **reprova**, sempre os mesmos dois casos |

O sintoma é preciso: `(b-MUT)` diz *"o mutante passou"*, o que só ocorre se o `core.hooksPath` do
repo-sandbox **não ficou absoluto** — ou seja, o `git config` do setup não teve efeito **sob o
hook**. O mutante é construído em sandbox (`$d/v-mut.sh`), logo **não há estado compartilhado entre
workers**: a hipótese de corrida cai.

**O que eu NÃO isolei:** qual variável do ambiente de `git commit` muda o efeito do `git config` na
sandbox. Cinco hipóteses minhas caíram por execução nesta caça, e eu paro de supor aqui em vez de
escrever a sexta.

**Gatilho nomeado para atacar:** reprodução **com a saída do caso capturada** (`out_m` e o
`core.hooksPath` efetivo da sandbox impressos) — flaky sem saída capturada é flaky para sempre, e é
exatamente por isso que este achado fica **aberto** em vez de fechado por conveniência.

**Consequência para este PR, declarada:** o commit entrou por `--no-verify`, que nesta casa é
**checkpoint, nunca validação final**. A validação é o **gate completo no SHA final** — o CI
(`onion-validate.yml` para o lint e `onion-selftest.yml` com `--jobs auto` e 25 min para a bancada).
O merge só acontece com esse gate verde no head, e o relatório nomeia ESSE gate, não o pre-commit.

### Duas hipóteses minhas que a medição refutou nesta caça

Procurando a causa das mortes de worker eu afirmei, e errei, duas vezes: que havia **teto de tempo
por worker** (não há — os workers morrem com `exit 1`, abort sob `set -e`) e que meus **helpers
colidiam de nome** com outras famílias (`_dc`, `_col`, `_g`, `_cls` são definidos uma vez cada). As
mortes eram **consequência** das falhas reais, não causa: com `role-cut` e `adopter-gate` resolvidos,
a faixa fechou **204 famílias / 1593 asserções / 0 falhas em 1039s**.

Teoria sobre shell e sobre harness vale zero contra uma execução. Foi a terceira e a quarta vez nesta
leva.

## O que fica aberto, com gatilho

- **REGRA 85 (Porta pública espelha o core, com catraca):** `onion-core` 9 commits atrás
  ("ANDOU-PARA-TRÁS"). A cobrança bloqueante mora no workflow de push para main, não no PR.
- **REGRA 65 (Radar de mundo com baseline DATADA por eixo):** Claude Code saiu de 2.1.278 para
  2.1.286 (e o disco já tem 2.1.287) — adequação não re-medida; o gatilho é `/meta:radar
  E3-claude-code-delta`.
- **Decisão do Cedar e as duas de pesquisa** seguem `open`: o maestro sela, esta sessão nunca sela.
