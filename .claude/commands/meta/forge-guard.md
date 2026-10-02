---
description: Forja uma GUARDA (hook ou check de lint) pelo conjunto de 7 peças, medindo os moldes e o passivo antes de escrever. Core-only.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, TodoWrite
---

# 🛡️ /meta:forge-guard — forjar a guarda, não só escrevê-la

Irmã do [`/meta:forge`](forge.md), que forja **comando-com-framework**. Esta forja **guardas**: o
artefato que dispara sozinho e barra. A doutrina inteira — as 7 peças, as 6 cláusulas, o que ela não
promete — vive em [`common:prompts:guard-doctrine`](../common/prompts/guard-doctrine.md).
**Referencie, não copie.**

**Por que ela existe:** forjar guarda é o procedimento **mais repetido** desta casa (medido em
2026-10-02, PRÉ-leva: 206 famílias de bancada, 13 guardas com `--selftest` próprio — esta forja soma a 14ª) e era o único **sem
superfície**. Toda forja relia um molde escolhido **de memória**. Ela nasceu de uma forja à mão que o
maestro interrompeu com a pergunta certa: *"esta forja deveria ser reusável, ainda mais sendo uma
forja que primeiro forjou o molde, testa o molde…"*.

## Degrau e limites

- **Core-only** (Camada 1 = autoria do framework). **Maestro-invocado**; não auto-inicia.
- **Não sela.** Guarda nova muda o gate de todos — o merge é humano, e o Elenxo é obrigatório.
- **Entrevista, não assume.** O substrato (hook `Stop` · `PreToolUse` · check de lint) é **pergunta**,
  respondida pelo censo + pelo que a guarda precisa ver. Assumir petrifica a forma do 1º caso.
- **MOAT:** forjar guarda sem defeito medido e datado. O desfecho correto aí é **nó com gatilho
  nomeado** (cláusula 1), e dizer isso é entrega, não recusa.

## Contexto medido injetado (peça 3 — o medidor roda ANTES de você pensar)

**Hoje:** !`date +%F`

!`bash .claude/validation/guard-census.sh . --markdown`

> ⚠️ **AS DUAS LINHAS ACIMA SÃO DIRETIVAS DE INJEÇÃO — bang seguido de crase —, não instrução para
> a sessão rodar.** E há uma armadilha que esta própria superfície pagou na PRIMEIRA invocação: o
> harness executa **toda** diretiva do arquivo, inclusive uma escrita como EXEMPLO em prosa. A 1ª
> redação desta nota citava a forma literal entre crases duplas, e a carga do comando morreu com
> `cmd: command not found` — a superfície nasceu **morta na carga**, e só a invocação de verdade
> revelou (lint verde, bancada verde, comando inútil). Por isso a forma literal **não aparece em
> nenhum lugar deste arquivo**: ela é descrita, nunca escrita. A regra é geral — **toda diretiva de
> injeção num comando tem de ser um comando executável de verdade**.
>
> Houve um segundo defeito nesta mesma seção, e foi um achado do maestro: a 1ª versão dela trazia um
> bloco de shell mandando a sessão executar o censo. O `forge-census.sh` mediu e devolveu **peça 3 ausente**: eu
> havia construído o medidor e deixado **o disparo dele na disciplina da sessão**. É `gatilho
> social é cura nula` cometido na superfície que prega o contrário, e a própria doutrina do forge
> condena o parente mais brando disto ("contexto que alguém digita caduca em silêncio"). Agora o
> harness executa na carga e o resultado chega **antes** de qualquer raciocínio.
>
> Para focar a busca numa classe, rode à mão **além** da injeção:
> `GUARD_CENSUS_QUERY='<termos> ' bash .claude/validation/guard-census.sh . --markdown`

O censo responde três coisas que ninguém deve responder de memória: **os moldes por substrato** com
o número de casos de cada um (copie o mais exercitado), **se já existe guarda da classe** (não
re-forje), e **o passivo** — as duas mortes de guarda. Leia o TETO que ele declara: mede **forma**,
nunca qualidade, e **não** sabe se um caso tem mutante.

## Procedimento

1. **MEDIR** — o censo acima. Classe já coberta → pare e diga qual guarda cobre. Molde escolhido
   pelo censo, não por lembrança.
2. **DATAR O DEFEITO** (cláusula 1) — o dano observado, com data e evidência. Sem isso, **pare** e
   proponha o nó com gatilho. Guarda de hipótese é dívida sem credor.
3. **COPIAR O MOLDE** e escrever o artefato. O molde decide a forma do veto (`exit 2` no hook,
   `violation HARD/SOFT` no lint) — e **o motor do padrão decide a sintaxe** (cláusula 3: regex de
   Python ≠ POSIX do `grep`).
4. **AS DUAS POLARIDADES** no `--selftest`: acusa o defeito **verbatim como ele apareceu** e **cala**
   no caso honesto. O caso honesto é o que impede a guarda de treinar a sessão a ignorá-la.
5. **DOGFOOD** — rode o `--selftest` de verdade. Falhou? cure e re-rode **no mesmo laço**. (A 1ª
   execução já pegou defeito nas duas guardas forjadas por este procedimento em 2026-10-02.)
6. **MUTANTE** (cláusula 2) — reverta a cura e **exija** que o caso reprove; mostre a saída. Caso que
   passa verde com a cura revertida é enfeite e **dá licença**. Rode com `LC_ALL=C`.
7. **REGISTRAR** (peça 6) — `settings.json` para hook, dispatcher do `lint-artifacts.sh` para check —
   e **re-rodar o censo** para confirmar que saiu do passivo. Registro é parte da forja.
8. **BANCADA** — família `run_<n>_selftests` no `lint-selftest.sh` + entrada no
   `fixtures/manifest.tsv` se houver fixture. É onde as peças **4 (polaridades)** e **5 (mutante)**
   *do conjunto da GUARDA* de fato vivem.
9. **`write(KG)` — o DESTINO, e ele é obrigatório.**

   > ⚠️ **DOIS CONJUNTOS DE 7 PEÇAS COEXISTEM AQUI, e eu os misturei na 1ª redação.** O conjunto da
   > **GUARDA** (doutrina acima: 1 defeito · 2 molde · 3 artefato · 4 polaridades · 5 mutante ·
   > 6 registro · 7 teto) **não tem destino** — guarda barra, não produz. O conjunto do
   > **COMANDO-COM-FRAMEWORK** (`forge-doctrine`, que é o que o `forge-census.sh` mede e onde esta
   > superfície pontua) tem a peça 5 = **destino**. Este passo é a peça 5 **do conjunto do comando**,
   > não da guarda. Citar "peça 5" sem dizer de qual conjunto é a confusão que esta nota evita. Forjar guarda **produz conhecimento**:
   o defeito medido e datado, o molde escolhido e por quê, os mutantes que morderam, e o teto
   declarado. Antes disto, esse conhecimento vivia só na mensagem de commit e no resíduo — ou seja,
   **evaporava entre sessões**, que é exatamente o que a peça 5 existe para impedir. Escreva em
   `docs/evolution/research/guard-<nome>-<AAAA-MM>/<nome>-<AAAA-MM>.kg.yaml`:
   - 1 nó `evidence` com o **defeito medido** (data + evidência executada) — é a peça 1 virando nó;
   - 1 nó `decision` com o **substrato escolhido** e o molde copiado, citando o censo;
   - 1 nó por **teto declarado** (o que a guarda não vê), que é o que a próxima sessão precisa saber
     antes de confiar nela;
   - `# kg-backlog-guard: on` e `meta.review_after` pela cadência.

   **`kg-radar <grafo> --integrity --schema` exit 0 é obrigatório** antes de qualquer prosa. E vale
   a fronteira que o `fios-abertos` declara: **o fato mora aqui**, não no backlog — lá só entra o
   compromisso, citando este id.
10. **ELENXO + PR** — refutador em worktree isolada com mandato de achar o **falso positivo** (não o
   defeito: a cláusula 4 diz que falso positivo treina a sessão a ignorar o veto, e foi assim que a
   1ª guarda forjada por esta superfície quase nasceu vetando todo turno honesto); resíduo da
   REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial); **merge humano**.

## Peça 4 (orquestração faseada) — AUSENTE por desenho, declarado

A forja de guarda é **serial**: medir o censo, datar o defeito, copiar o molde, escrever, dogfood,
mutante, registrar, bancada. Não há fan-out com independência real, então um `.claude/workflows/*.js`
seria coordenação sem nada a coordenar. A doutrina do forge é explícita em que **só a peça 5 é
invariante**; as outras seis são variáveis. Esta ausência é escolha, não lacuna — e fica escrita
aqui para que o censo marcando `—` na coluna 4 seja lido como **declarado**, não como dívida.

**Gatilho nomeado:** se uma forja precisar refutar N moldes candidatos em paralelo, ou dogfoodar N
guardas de uma leva, aí a peça 4 nasce dos N casos — nunca de um.

## O que este comando NÃO faz

- **Não decide se a guarda deve existir.** Ele cobra o defeito datado; o julgamento é do maestro.
- **Não mede mutante** — nenhum script sabe. A cláusula 2 é de julgamento, e a doutrina assume isso.
- **Não garante que a guarda pegue a CLASSE**, só a forma do caso (cláusula 3).
- **Não substitui o `/meta:forge`**: comando-com-framework tem outro conjunto e outra doutrina.

## 🔗 Referências

- Doutrina: [`common:prompts:guard-doctrine`](../common/prompts/guard-doctrine.md)
- Lente (peça 6): `.claude/rules/guard-lens.md` — carrega a doutrina **sozinha** ao tocar
  `.claude/hooks/**` ou `.claude/validation/*-check.sh`, que é o ponto: doutrina que depende de
  alguém lembrar de abrir fica escrita e nunca é lida.
- Medidor (peça 3): `.claude/validation/guard-census.sh` · bancada: `run_guard_forge_selftests`
- Irmã para comandos: [`/meta:forge`](forge.md) · régua de transferência:
  [`transfer-heuristic-aristotle`](../../../docs/knowledge-base/concepts/transfer-heuristic-aristotle.md)
