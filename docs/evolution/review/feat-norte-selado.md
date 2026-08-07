---
branch: feat/norte-selado
date: 2026-08-06
reviewed_diff_sha256: 4d551d349871cdef21ec7b700b4469be6c26150f1e8300d1af1461a99c181e97
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 446255
duration_min: 16
verdict: ELENXO-MUDOU-A-ORDEM
reviewer: Elenxo — 4 refutadores adversariais + juiz (opus/high), wf_48698acf-543
---

# Passada adversarial — as decisões de norte sob ataque

**A revisão foi o Elenxo, não um code-review**: quatro refutadores atacaram as três decisões
recém-tomadas, com a regra mecanizada *refutação sem `superacao` é DESCARTADA*.

**Zero descartadas por falta de superação.** As três decisões sobrevivem **RESTRINGIDAS**; nenhuma cai.

## Os ataques, e o que aconteceu com cada um

| ataque | veredito |
|---|---|
| **R1** — "só quem autora o grafo o consome" | **MORREU na medição.** O consumidor certo é a SESSÃO, não o corpo do PR: **1.022 execuções** do radar em 39/53 sessões · **61 de 132** pares (sessão×grafo) são leitura-sem-autoria · **54 de 55** citam id daquele grafo no texto do agente. O refutador ainda **corrigiu o próprio instrumento** (1ª rodada deu 0/55 por bug de resolução de caminho). |
| **R2** — orquestração é cara e não-medida | **SOBREVIVE restringindo:** o valor passa a ler-se "orquestração ancorada, COM régua de custo". |
| **R3** — ICP primário aspiracional | **REFUTADO por medição** (86 sinais em `inbox/_processed`). |
| **R4** — "ancorada" é retórica (79%) | **O NÚMERO ERA MEU E ESTAVA ERRADO:** 43% run-level, **76% na janela recente**. O denominador incluía runs operacionais que a doutrina nunca obrigou a virar grafo. |

## O que mudou de verdade

**A Fase 3 deixou de ser um passo e virou três, em ordem obrigatória** — e a ordem não é estética:
construir o selo antes do schema produz **um gate que só passa mentindo**. Verificado em sandbox,
com o status como única variável.

**E o que a Fase 3 cura mudou:** não é *"as orquestrações não ancoram"* (falso, 76%), é
**"o grafo não sabe dizer que envelheceu"**. Cura diferente, e mais barata.

**Entrou um item que não estava no plano** e governa o preço de tudo depois: a régua de W +
`tool_uses` no contrato do M6. Sem ela, todo Elenxo futuro sai com W=N por default.

**Desceu na fila** o lado paralelo do M8 (projeção ≥1,4M): a pergunta dele tem resposta mais barata em disco.

## O que este PR entrega

Fase 1 (as três decisões seladas, com a contradição medida registrada junto) e **Fase 3a**
(os dois status legais) — o pré-requisito sem o qual o resto seria fail-open.

---

## Re-carimbo — a REGRA 56 acusou ARTEFATO-CADUCO, e estava certa

O hash anterior cobria o estado do fim do Elenxo (`ff48f51`). Depois vieram **dois merges de
`main`** (#552 e #553), e a regra acusou: *"a revisão registrada cobre outro diff — o código
mudou DEPOIS de revisado"*. Foi o **primeiro contato dela com um PR real**, e pegou o autor
da branch vizinha. Funcionou.

**Não bastava carimbar o hash novo — isso seria burlar o gate.** Medi o delta:

| origem | avaliação |
|---|---|
| conteúdo de **#552** e **#553** | cada um entrou com **artefato de revisão próprio** (`fix-review-verdict-caso-benigno.md`, `feat-gate-anti-cegueira.md`) — já revisado no seu PR |
| **minha resolução de conflito** | `lint-selftest.sh` (reaplicação da função de statusFactor) + 2 `provenance.json` (regenerados) |

**A resolução É trabalho novo, e merece a nota** — porque é exatamente onde eu errei uma vez
neste mesmo merge: a 1ª tentativa foi união cega dos hunks, as 4 funções apareceram
`def=1 reg=1`, e **o arquivo saiu com sintaxe quebrada** (`bash -n` exit 2). Contei presença
quando a contagem certa era executabilidade.

**Verificação da resolução (a que vale, não a que engana):** `bash -n` exit 0 · as 4 funções
`def=1 reg=1` · `lint-selftest` **663/663, 0 falhas** — a união das três frentes rodando
junta pela primeira vez · `kg-radar-integrity` exit 0 · `provenance.json` **regenerado da
fonte**, não escolhido por lado.

---

## 2º re-carimbo — a CI reprovou onde o local passava, e o culpado era a bancada

O `onion-validate` reprovou em 11m47s com **6 falhas**, todas em `review-artifact`, enquanto o
`lint-selftest` local dava **663/663**. Não era falso-positivo da CI: era a bancada mentindo local.

**Causa:** `review-artifact-check.sh` lê `BRANCH="${GITHUB_HEAD_REF:-}"` **antes** de perguntar ao
git. No runner essa variável vale o branch real do PR, e a sandbox — que só tem `feat-x.md` — passava
a ser julgada como se fosse o PR de verdade, procurando `feat-<branch-real>.md`. Local a variável
não existe, o helper cai no git, e tudo passa.

**Prova cruzada, não dedução:** o caso `(h)` é o único que fixa `GITHUB_HEAD_REF=feat/x`
explicitamente — e foi o único dos 9 que **passou** no CI. E o `(b)` passava **pelo motivo errado**:
ele espera `ARTEFATO-AUSENTE`, que é exatamente o que o vazamento fabrica.

**Não é regressão deste PR.** `feat/norte-selado` já reprovava em `1143a38d`. Mais grave: **#552 e
#553 mergearam com `onion-validate` de conclusão VAZIA** (cancelado no apagão do Actions de 08-06),
então os selftests da REGRA 56 nunca completaram no CI antes de entrar no `main`. O `main` estava
quebrado e ninguém podia saber — *"verde"* e *"não rodou"* indistinguíveis no ponto de decisão, que
é a mesma patologia que o #549 curou para o revisor.

### O que entrou (e por que não parei no conserto dos 6 casos)

| camada | o que é | por que não basta a anterior |
|---|---|---|
| **(a)** `GITHUB_HEAD_REF=feat/x` nas 4 invocações que simulam PR | conserta os 6 casos de hoje | é disciplina: não impede o 7º caso escrito amanhã |
| **(b)** `unset GITHUB_*` no topo do `lint-selftest.sh` | bancada **hermética por construção** | sem (c), quebrá-lo volta a virar 6 falhas crípticas |
| **(c)** guarda `bancada-hermetica`, antes do 1º caso | **nomeia a invariante** | — |

(b) mora colado ao `unset GIT_DIR GIT_INDEX_FILE …` que já existia **pela mesma razão** — ambiente
herdado contaminando sandbox. É o mesmo defeito uma camada acima, então a cura mora no mesmo lugar.

**E desfiz parte de (a) de propósito:** os casos `(a)` e `(i)` voltaram a ser invocação **nua**.
Blindá-los com `env -u` os tornaria auto-protegidos e portanto **cegos à falha de (b)** — passariam
em silêncio com o mecanismo quebrado. Nus, são 🐤 canários.

### Verificação (a que vale)

- **mutante sem o `unset`, com env de CI** → `661 passam · 3 FALHAM`, e a **primeira nomeia a causa**:
  `bancada-hermetica — ambiente do runner VAZOU: GITHUB_HEAD_REF GITHUB_REF_NAME GITHUB_EVENT_NAME`.
  O mecanismo é **load-bearing** e o canário não é decorativo. Guarda-da-guarda: mutação confirmada
  aplicada (`original=1 · mutante=0`) antes de rodar.
- **original corrigido, com env de CI, corrida SOLO** → **664 passam · 0 falham · 0 pulam**
  (663 + o novo `bancada-hermetica`).
- `bash -n` exit 0 · lint 0 HARD.

**Uma corrida intermediária foi DESCARTADA e vale o registro:** rodei original e mutante em paralelo
na mesma árvore e o original reprovou em 3 guardas alheias (`vendor-scrub`, `backtick-ref`,
`site-deeplink`), uma delas com o lint apontado para o worktree real em vez da sandbox. Contenção
entre duas suítes que forjam sandbox e invocam lint — **erro meu de higiene, cometido justamente ao
testar a correção da higiene da bancada**. Só o resultado solo conta. [[bancada-espelha-o-runner]]
