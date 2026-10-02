---
reviewed_diff_sha256: 3c69c62025f51b12384334f12a35dc3de79a4d955ff7a5aae94b77dd518e19c4
findings_total: 12
findings_real: 12
tokens: 211468
duration_min: 18
verdict: REPROVADO_E_CURADO
elenxo: sim
---

# Resíduo da passada adversarial — `fix/hub-promotion-2026-10`

Refutador `opus/high` em worktree isolada, mandato de achar **falso positivo e fail-open**.
**12 achados, 12 reais, todos provados por execução. 4 bloqueadores.** Veredito: **REPROVADO**.
Curados aqui, com mutante por cura estrutural.

## O veredito que resume a leva

> *"A leva se propõe a curar 'o carimbo que mentiria sobre a versão do framework' e entrega **duas**
> formas vivas da mesma mentira."*

Ele está certo, e isso é o que torna esta passada a mais valiosa da sessão.

## Os quatro bloqueadores

**F1 — a MESMA cura, a OUTRA perna viva.** Eu curei `--commit` e deixei `--framework` **vivo**. Ele
deriva do remote do **próprio alvo**: medido ao vivo, o `onion-version.sh` do adotante devolve o nome
do repo DELE, que o snippet carimbava sobre `onion-evolve`. Pior — meu comentário **afirmava** que
`--framework` entrava no fallback. Não entrava: o chamador manda valor não-vazio e o **arg vence**.
Cura: o snippet não passa **nenhuma** das três flags de identidade.

**F2 — troquei ruído por silêncio, que é a pior regressão.** Meu fallback olhava só
`[ -z "${COMMIT}" ]`, então `--commit ""` — o que um `awk` quebrado produz, e esta casa já quebrou
**2×** nessa vizinhança — deixou de ser `rc=2` e passou a **herdar em silêncio**: stamp com
`updated_at` de **hoje** e pin **velho**. Medido nas duas pontas: `rc=2` em `origin/main`, `rc=0` na
branch. Cura: `*_SET` no parser — flag **ausente** herda, flag **presente e vazia** é erro que
**nomeia a flag**.

**F3 — caso DECORATIVO, quarta ocorrência da classe na mesma sessão.** O caso `(d)` **copiava** o
`case` do predicado para dentro de si e testava a **cópia**. O mutante que remove `*/index.lock` da
isenção — fail-open real, `git commit -a` deixaria de ser julgado — passava **8/8 verde**. O rótulo
dizia *"por EXECUÇÃO"*, e a execução era da cópia.

**F5 — o caso `(a)` cobrava FORMA, não comportamento.** O mesmo defeito em outra sintaxe
(`cd "$REPO" && git rev-parse`) passava verde, e a perna `--framework` nunca foi vista.

## E ao curar o F3 eu cometi a MESMA classe na outra ponta

O sandbox do caso nasce de `git archive HEAD` — logo ele testava o lint **commitado**, e o mutante
aplicado na **árvore** nunca chegava lá. **O próprio `lint-selftest.sh` avisa disso na l.514**, e eu
reescrevi o caso sem ler o aviso que o arquivo me dava. Cura: o SUT vem da **árvore de trabalho**, por
cima do archive. Classe: cópia do artefato **certo**, da **revisão errada**.

## O que uma queda de sessão ainda revelou

A bateria de mutantes morreu no meio. Ao retomar, verifiquei primeiro que **nenhum mutante ficou na
árvore** (só os hits legítimos da REGRA 94) — e a saída parcial trouxe dois fatos:

- **`M1` agora morde** (`.git/index.lock=SOFT` quando devia ser `HARD`): a cura do `(d)` pegou o
  fail-open;
- **`M-F2'` não mordia**, e a causa **não** era caso decorativo: ele faz o fallback sobrescrever
  `--commit` **mesmo com valor**, e o `(a2)` só exercita o arg **vazio**. O fail-open real é outro —
  um `--update` legítimo passando o pin **novo** teria a versão **revertida em silêncio**. Caso
  `(a2b)` fecha, e com o mutante dá `pin=[111111111111]` em vez de `222222222222`.

**Lição registrada no código:** *"o mutante não mordeu" tem DUAS causas* — caso decorativo, **ou**
mutante que não muda o que o caso afirma. Tratar as duas como a mesma coisa me faria "consertar" um
caso que estava certo.

## As demais, curadas

| # | achado | cura |
|---|---|---|
| F4 | a isenção da REGRA 84 cobre **qualquer** divergência sob nome estranho, e a mensagem **afirma** *"parece defasado sem estar"* | a frase passa a **declarar** em vez de afirmar |
| F6 | o nó novo nomeia como cura um predicado que esta casa **já refutou** (paridade cega em adotante → 12 falsos positivos medidos) | o nó recebe o predicado **unidirecional** (`carimbo hub ⟹ registro hub`) |
| F7 | *"o que NÃO ganha"* é declaração sem mecanismo: `vendor-manifest --role hub` e `--role adopted` são **byte a byte idênticos** | o anúncio troca o convite inverificável por um comando falsificável |
| F8 | a mensagem de erro dizia *"sem stamp existente"* para 2 causas em que o stamp **existe** | nomeia as duas: ausente **ou** presente sem o campo |
| F9 | `field()` sem normalizar — e o fallback é o 1º consumidor que **escreve de volta** o que ele lê; carimbo real tem `# pin da adoção` | normaliza comentário inline, como o `_norm_role` do irmão já fazia |
| F10 | o 2º sinal foi **curado e ficou órfão** — sem arquivamento e sem resposta, a um commit de distância do commit que curou exatamente isso | arquivado + parágrafo no anúncio |
| F11 | atribuição morta | removida |
| F12 | citação de linha imaginada (`730-735` quando a leitura é `l.729`; `l.42` é comentário, não predicado) | corrigidas |

## O que ele APROVOU, e vale registrar

- **Os números todos defensáveis**: "4 de 4 tentativas" é fiel ao sinal, "106 arquivos" bate com duas
  fontes, "799 linhas" confere, e `663fdbc5bdcc` é o merge do PR #903 (`pin-ok`, rc=0).
- **O predicado de índice está CERTO** nas outras formas de commit — ele mediu as seis com um hook que
  imprime `GIT_INDEX_FILE`: staged, `-a`, `-i`, `--amend` e worktree normal **julgam**; só
  `commit -- <path>` e `--only` isentam. `stash`/`rebase` não rodam `pre-commit`.
- `(b)` e `(c)` de `role_promotion` **não são decorativos** (M5 e M6 mordem).

## nota:
A **REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente)** barrou o commit depois das
curas, e foi o achado mais sério da volta: eu havia escrito o **nome do adotante** em `adopt.md`,
`write-stamp.sh` e `lint-selftest.sh` — os três **viajam para todo adotante**, então o nome de um
cliente iria para todos. **6 HARD, mesma causa.** Generalizado; o crédito nominal fica no
`members.yaml` e no outbox, que são core-privados.

E duas coisas que só a **leitura** pegou, não o lint: a substituição cirúrgica **quebrou uma frase**
(ficou *"carimbava um SHA / história do core"*, sem o *"inexistente na"*), e o `adopt.md` foi para
**800 linhas exatas** contra limite 800 — margem zero, comprimido para 799.

**NÃO VERIFICADO, declarado:** o F4 pede estreitar a isenção da REGRA 84 ao **subconjunto estrito**
(a causa medida), e eu **não** implementei isso nesta leva — só a redação honesta. Gatilho: o próximo
sinal de pathspec, ou a próxima leva que tocar a REGRA 84. Enquanto isso a isenção é mais larga que a
causa, e a mensagem agora diz que **não verificou** em vez de afirmar que não há defeito.
