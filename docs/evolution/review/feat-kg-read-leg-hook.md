---
title: 'Resíduo — a perna de leitura do KG deixou de ser conselho'
date: 2026-09-16
branch: feat/kg-read-leg-hook
reviewed_diff_sha256: 18e490568b1d7bd767a52fd4d1e0cdb6b6661e4b8f50342a2b3785a647c50a2b
findings_total: 8
findings_real: 8
findings_fixed: 8
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Triagem de 10 sinais de campo (lidos por inteiro, 684 linhas) + a primeira cura. Sem refutador
  externo: o trabalho nasceu de sinais que JÁ são refutação de campo, e a bancada reprovou três
  vezes durante a construção. O que vale registrar não é o hook — é que quatro dos dez sinais
  já estavam curados, e eu teria proposto trabalho morto se tivesse triado pelo título.
---

# O grafo que não é lido é indistinguível do grafo que não foi escrito

A frase é de um adotante, e ele a comprou caro.

## A triagem — e por que ler por inteiro não era formalidade

Dez sinais acumulados. Medi **cada um contra o vivo** antes de triar, e **quatro já estavam
curados**:

| sinal | estado real |
|---|---|
| `/meta:adopt` gera inventário antes do commit | ✅ curado — `_tracked_or_find` pergunta "houve resultado?", e o comentário cita este sinal |
| proposta de 1 nó reprova no radar | ✅ curado — modo proposta (`meta.target` / `*.proposal.kg.yaml`) |
| `onion-research` volta vazio em fonte com sessão | ✅ curado — `unreachable` 12×, `zero claims`, `notVerifiedByBudget` |
| anúncio contradiz o relatório | ⚠️ **metade** — o `co-deliver` exige `.onion-version`; a metade do RELATO segue viva |

A última é a lição de método: **arquivar um sinal meio-curado apagaria o achado vivo**. Antes de
mover, registrei a metade sobrevivente como nó (`A_ANUNCIO_DERIVA_O_NUMERO_DA_MEDICAO`) — o anúncio
afirmava *"as portas estão OK"* enquanto a catraca da mesma leva tinha contado **38 exposições**, e
citava "3 fallbacks" onde o padrão produzia **19 em 10 variáveis**.

## O caso que justifica o hook

Sinal de 2026-09-11. Uma sessão leu **8.585 linhas** de fonte em quatro frentes e publicou **quatro
teses erradas em sequência** — todas derrubadas por correção do autor, nenhuma pelo método — num
corpus que tinha a resposta em **quatro nós** de um `.kg.yaml` que ela **citou no próprio prompt**,
como checklist de conferência e nunca como fonte.

Não foi falta de acesso nem de contexto. Foi falta de mecanismo. E o core sabia: o `grep -l
'\.kg\.yaml' .claude/hooks/*.sh` devolvia **zero** — a perna de leitura estava anunciada como
mecanismo e era conselho.

## O que foi construído

- **`--emit-index`** no `kg-trace-resolve.sh` — o **mesmo** parser que julga a âncora emite o índice.
  Um segundo extrator de `trace:` seria a segunda cópia da gramática, que é a classe que a REGRA 82
  (Os dois leitores do corpus CONCORDAM sobre quem é nó) existe para pegar. **1.844 pares**.
- **`docs/onion/kg-read-index.tsv`** — projeção commitada. Medido: gerar **7.722 ms** · consultar
  **8 ms**. Um hook de `PreToolUse` a 7,7 s por `Read` seria desligado no primeiro dia, e guarda
  desligada é pior que guarda ausente porque o desligamento não fica registrado em lugar nenhum.
- **`.claude/hooks/kg-read-leg.sh`** — ao abrir arquivo que algum nó aponta, diz **quais** nós.
  **Não bloqueia**, e é desenho: gate que impede trabalho é contornado com `--no-verify` na primeira
  sexta-feira, e aí se perde o mecanismo *e* a informação.
- **REGRA 84 (Índice de leitura do KG em sincronia com os traces)** — índice defasado não faz o hook
  gritar errado: faz ele **ficar calado** sobre um nó que existe, e calado é indistinguível de "não
  há grafo" — o fail-open exato que a perna de leitura foi ligada para curar.
- **Bancada `kg_read_leg` 7/7**, e dois casos existem contra a fraude mais barata: (c) o hook cala no
  arquivo sem nó — hook que fala sempre vira ruído e é desligado; (d) prefixo **não** conta como
  cobertura, senão `alvo.ts` apontaria nós ao abrir `alvo.ts.bak`, que é pior que silêncio porque
  parece informação.

## O que a máquina me cobrou (e eu não teria visto)

1. **REGRA 60 (Identificador de código em INGLÊS)** — 5 identificadores em pt-BR no hook.
2. **REGRA 59 (Modo que a produção consome é exercitado pela bancada)** — `--emit-index` é consumido
   em produção e não estava coberto. Dois casos novos, e o (g) prova o **fail-closed**: corpus sem
   trace resolvível sai ≠0, senão o regenerador gravaria um índice cego.
3. **`fail-closed-exposes-incomplete-harness`** — o caso (f) reprovou porque o sandbox copiava o
   motor sem `kg-fixture-paths.sh`. A cura é no harness, nunca afrouxar a guarda.
4. **`paste -sd' · '` não junta com " · "** — o `-d` é um *conjunto* e o paste cicla um caractere por
   junção. Saiu byte solto no meio dos nomes dos grafos.

## Teto declarado — e este é o que importa

**O hook não foi verificado em execução real nesta sessão.** Hook novo só passa a valer depois de
reiniciar a sessão (medido nesta casa em 2026-09-02, e eu já errei uma vez afirmando o contrário).
O que está provado é: o contrato de saída é JSON válido com `hookSpecificOutput.additionalContext`,
o índice resolve, e os 7 casos de bancada reagem. O que **falta** provar é o harness consumindo o
`additionalContext` de um `PreToolUse` — isso se vê na próxima sessão, abrindo um arquivo coberto.

Os outros três itens da ordem proposta pelo adotante (radar avisar vencimento · exigir o par
desvio↔redesenho · gatilho por contradição) ficam em `A_PERNA_DE_LEITURA_DO_KG_E_CONSELHO`, abertos.

---

# Adendo — a 5ª reprovação pela mesma causa, e o que ela ensinou

O CI do próprio PR reprovou em REGRA 80 (Números do harness saem de SSOT gerada, nunca de
comentário) e REGRA 81 (Painel de estado é GERADO dos produtores, nunca redigido). É a **quinta**
vez no dia que uma projeção gerada derruba o gate pela mesma causa estrutural.

De manhã eu "curei" isso acrescentando `testing-state.md` ao `regen-ssot-projections.sh`. À noite a
**REGRA 80** cobrou o `testing-inventory.md`, que eu também não tinha posto. **Curar um item de uma
lista que devia ser completa é curar o caso, não a classe** — e a classe volta no mesmo dia.

O critério agora está escrito no arquivo, para não haver terceira: **toda projeção gerada com
catraca no lint pertence a esta lista.** Hoje são quatro (REGRAS 8, 21, 80, 81), mais o índice de
leitura (REGRA 84, fora do laço por ser TSV em vez de markdown).

Lint após a cura: **0 HARD**, 12 SOFT.

---

# Adendo 2 — a bancada do CI pegou o que a minha passada local não rodou

O `selftest` do CI reprovou em `shell_pipefail_robustness` com **dois sítios novos da classe**, e
os dois são meus:

1. **`kg-read-leg.sh:50`** — `… | sort -u | head -8 | paste`. O `head` **fecha o pipe** ao atingir a
   conta, o produtor a montante toma EPIPE e, sob `pipefail`, o status vira 141. Trocado por
   `sed -n '1,8p'`, que **drena** a entrada até o fim — mesma saída, sem corrida.
2. **`lint-selftest.sh`** — as minhas famílias novas usavam `printf '%s' "${out}" | grep -q …`
   **17 vezes**, empurrando o contador da catraca de 41 para 43. Trocados por here-string
   (`grep -q PAD <<< "$var"`): sem pipe, sem EPIPE.

**É a terceira vez no mesmo dia que a classe `pipefail-epipe-early-closer` me pega** — antes no
harness do porte Codex e nos filtros da REGRA 83 (Id de modelo VERSIONADO só na SSOT declarada).
Nos três casos eu conhecia a classe e escrevi o defeito assim mesmo. Isso é dado sobre mim, não
sobre a guarda: o padrão `produtor | grep -q` é o reflexo, e só a catraca o intercepta.

E vale registrar por que o CI pegou e a minha passada local não: **eu rodei só as famílias que
julguei afetadas.** A `shell_pipefail_robustness` varre o repo inteiro atrás da classe — ela é
afetada por *qualquer* script novo, e eu não a tinha na lista. Rodar "as famílias afetadas" é uma
heurística minha; a passada cheia do CI é que é o gate.

Bancadas após a cura: `shell_pipefail_robustness` 3/3 · `kg_read_leg` + `model_ssot` 11/11.

---

# Adendo 3 — contaminação cross-branch: `git stash` não leva o que não é rastreado

O CI reprovou em REGRA 19 (Plugins de vertical (plugins/*) sincronizados com as fontes) apontando
`plugins/onion-design` — um plugin que este PR não tem razão nenhuma de tocar.

**Causa, medida:** enquanto o #839 rodava, puxei o fio do design-sink noutra branch e criei
`.claude/utils/design-sink/tokens-to-theme.sh` — **arquivo novo, não rastreado**. Ao voltar para cá
usei `git stash`, que **só guarda o que o git já rastreia**: o arquivo novo ficou no disco. O
`git add -A` do commit seguinte o varreu para dentro deste PR, e como ele é fonte do design-sink, a
REGRA 19 passou a exigir o `plugins/onion-design` regenerado — num PR sobre hook de leitura.

**Cura:** o arquivo sai daqui (`git rm`) e volta para a branch a que pertence, com o conteúdo
preservado fora da árvore antes da remoção.

**A lição, que é de método e não de git:** `git stash` sem `-u` é uma troca de contexto
**incompleta**, e `git add -A` transforma o resto num commit que ninguém revisou. É a mesma família
de `rebase-failed-never-reset-soft` — trabalho de uma branch aparecendo noutra sem que o autor peça.
O sinal barato de detectar: no `git diff origin/main...HEAD --name-only`, procurar arquivo que **não
tem relação com o tema do PR**. Aqui bastava olhar `design` num PR de hook de KG.

---

# Adendo 4 — a morte do worker no CI tinha causa, e ela não era carga

Quatro reprovações seguidas do `selftest`, sempre no mesmo ponto: o **worker 0 morre sem somar**,
deixando `regen_baselines` reivindicada e não concluída. E a bancada inteira **verde localmente**
com `--jobs auto`: **1283 passaram, 0 falharam**.

Passa isolada, morre na faixa. A casa já tinha classificado isso como *ambiente herdado*, sem
causa nomeada. Agora tem, e estava numa linha do log:

```
rm: cannot remove '/tmp/tmp.74xoKPesoc/.git/objects': Directory not empty
```

**A causa:** `git add`/`git commit` num sandbox disparam **`git gc --auto` em segundo plano**, e o
`rm -rf` da limpeza chega antes de ele soltar `.git/objects`. Sob `set -e`, esse `rm` não-zero mata
o worker na hora. Na minha máquina o gc termina primeiro; nos 4 workers do runner, não.

**A cura é de mecanismo, não de sítio.** Havia **55 `git init`** na bancada e **zero** com
`gc.auto` desligado. Corrigir um a um seria disciplina — e a lista cresceria com o próximo autor.
`GIT_CONFIG_*` exportado no topo aplica-se a **toda** invocação de git na árvore de processos:
uma linha alcança os 55 e os que ainda não existem. Desligar gc num sandbox descartável não custa
nada; ele vive segundos e é apagado.

A família `sandbox_gc` prende a cura — sem ela, a próxima refatoração a remove e o CI volta a
morrer quatro vezes antes de alguém desconfiar.

**O que isto ensina sobre a minha passada:** eu rodei famílias isoladas o dia todo e li verde. A
bancada completa em paralelo é outro sistema — e é o que o CI roda.
