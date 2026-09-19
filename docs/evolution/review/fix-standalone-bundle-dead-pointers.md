---
title: 'Resíduo — o verde que eu reportei era comprado por isenção'
date: 2026-09-18
branch: fix/standalone-bundle-dead-pointers
reviewed_diff_sha256: 58e115b64442d29ae49c3acbc0f2d19857933136e7de944e7abf5828433a7e85
findings_total: 10
findings_real: 10
findings_fixed: 10
tokens: 187244
duration_min: 38
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  O refutador derrubou a afirmação central do PR executando: o "0 HARD" da porta não foi conquistado,
  foi comprado desligando ~17 guardas. Pior, a mesma mudança fazia uma porta pública com a biografia
  do core no painel passar em 0 HARD — eu curei a instância e apaguei o detector da classe no mesmo
  commit. Duas curas minhas foram revertidas por este resíduo.
---

# O verde era comprado, e o mecanismo pegou

O PR nasceu para desbloquear a decisão **(A) re-materializar o `onion-standalone`**, e reportou a
porta em **0 HARD**. A passada adversarial provou que aquele número era falso — não por erro de
medição, mas porque **a medição media um lint que eu mesmo havia cegado**.

## O achado central (HARD)

`IS_DERIVED` (`lint-artifacts.sh:96`) não é *"que papel é este"*. É um **porteiro**: **19 sítios** o
consomem, **17 deles** como `[ "${IS_DERIVED}" -eq 1 ] && return 0`. Acrescentar `standalone` ali
**desliga dezessete guardas de uma vez**.

Verifiquei pelo mesmo caminho do refutador — a **mesma árvore**, trocando só o carimbo:

```
role: standalone  →  0 HARD
role: source      →  3 HARD
```

E o dano que isso abria, que ele reconstruiu executando: revertendo **só** a cura do
`review-ledger.sh` e mantendo a de vocabulário, uma porta pública com **294 resíduos e 1.586 achados
do core** no painel dela passava em **`0 HARD`, rc=0**. Antes do PR, a REGRA 80 e a REGRA 81 pegavam
isso como HARD.

> **Eu curei a instância do defeito e removi o DETECTOR DA CLASSE no mesmo commit.** A cura entregue
> era de disciplina ("não invoque do CWD errado"); o mecanismo que reprovava foi desligado junto.

**Cura:** `standalone` revertido do porteiro. Ele fica **só** nos predicados que perguntam *"a
evidência core-privada está legitimamente ausente neste papel?"* — escada, resíduo de revisão,
carteiro, desacoplamento. Lá a ausência é **de objeto** e a isenção é correta. No porteiro a pergunta
é outra — *"devo julgar este repo?"* — e a porta **deve** ser julgada: ela distribui a maquinaria
completa.

## A regressão de capacidade (HARD) — duas curas minhas revertidas

Eu havia cortado **três** skills do papel `standalone`. O refutador derrubou duas, com argumento
melhor que o meu:

- **Quatro arquivos que viajam** continuam citando `onion-wizard`/`onion-onboarding` em **prosa** —
  entre eles `onion-guided-lifecycle.md`, que descreve a vertical de condução inteira em termos
  delas. A porta ganharia uma KB ensinando um caminho de entrada que ela não tem.
- **O lint não pega isso** (não são caminhos em backtick), logo o `0 HARD` ali **não era evidência de
  ausência**.
- Ao contrário de `onion-publish`, **`onion-onboarding` não é declarada core-only** em doutrina nenhuma.

**Cura:** só `onion-publish` sai. O ponteiro morto do wizard virou **role-aware no texto** — a skill
declara que a transição `adopt` só existe onde a meta-fábrica existe. Não se remove capacidade para
satisfazer lint.

## A bancada que prometia curar a classe tinha três buracos

- **Casava substring na LINHA inteira.** O predicado da escada é `local adopted=""; grep -qE '^(role:
  (adopted|hub...`. Procurar `adopted` na linha casava o **nome da variável** — então tirar `adopted`
  da alternação passava batido, justo o papel de **todos os adotantes reais**. Agora extrai a
  **alternação** e julga só ela.
- **Não cobria 1 dos 5 sítios que o próprio PR declarava** (`lint-artifacts.sh:3839`), e o teto
  `_checked -ge 4` **carimbava a cobertura incompleta como completa**.
- **Não varria o 6º sítio** (`decouple-source.sh:33`), onde um papel emitido pelo próprio
  `write-stamp.sh` era tratado como *"inesperado"*.

E ganhou o caso que faltava: **a EXCLUSÃO também é decisão, e decisão ganha catraca**. Quem
"consertar" o porteiro re-adicionando `standalone` cai num caso que explica o porquê. Sem ele, a cura
de hoje seria desfeita amanhã por alguém seguindo a regra geral.

**Os dois mutantes do refutador foram re-testados e são pegos.**

## Defeitos meus que a própria correção produziu

- **`set -e` matou a suíte** numa atribuição que recebia `rc=1` — a bancada abortava *antes* de dizer
  qual sítio faltava, e o segundo defeito escondia o primeiro.
- **Meu comentário explicativo recriava o ponteiro morto** que ele explicava, por citar o caminho em
  backtick.
- **A extração da alternação só conhecia uma forma** (`(a|b|c)`) e acusava o `case` (`a|b|c)`) de ter
  "mudado de forma" — quando quem não conhecia a forma era o caso.
- **Terceira vez no dia** que `git archive HEAD` me fez medir a versão commitada em vez da que está
  sob teste.

## O que o refutador atacou e NÃO derrubou

Vale tanto quanto o resto:

1. **Inércia no core** — provada pela raiz: `.claude/.onion-version` **não existe** no core, os cinco
   predicados nem leem.
2. **Papel `adopted` intocado** — provado duas vezes, inclusive num adotante **real** copiado para
   /tmp: **75 HARD antes e depois, `diff` rc=0**.
3. **A bancada cai com um 4º papel** — mutante em `write-stamp.sh` → 4 falhas nomeando os arquivos.
4. **Detecta sítio renomeado e âncora mudada** — não fica cega passando.
5. **Não passa vacuamente** com 0 sítios.
6. **`review-ledger.sh`** — a cura funciona, inclusive em worktree; `--dir` relativo preservado.
7. **268 caminhos, 3 skills cortadas, 294/1.586 fora do painel** — reproduzidos exatamente.

## A lição

Duas passadas adversariais no mesmo dia já tinham me mostrado que **escrever a guarda é quando se
está mais perto de reincidir na classe que ela cura**. Esta acrescenta a versão mais cara:

> **Medir o verde de um gate que você acabou de alterar não é verificação — é circularidade.** O
> número `0 HARD` era verdadeiro sobre o lint que eu havia cegado, e falso sobre o mundo. O teste que
> desfaz isso é barato e eu não o fiz: **trocar o carimbo e ver se o veredito muda**. Quando muda, o
> verde não é do artefato — é da isenção.
