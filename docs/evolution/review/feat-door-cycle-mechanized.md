---
title: 'Resíduo — o ciclo era prosa; e o meu dogfood media no substrato errado'
date: 2026-09-17
branch: feat/door-cycle-mechanized
reviewed_diff_sha256: e1cad679cd964add05c35d4b9290b0715ff91ceecc92b29a70f43fcca004e45a
findings_total: 14
findings_real: 14
findings_fixed: 14
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  O número que justifica esta entrega já existia e ninguém o tinha medido: a porta anterior estava
  377 commits atrás. Os três defeitos de harness que a bancada me cobrou são todos a MESMA
  armadilha — o baseline da guarda vive na superfície que ela julga. Os dois achados da segunda
  rodada não vieram de mim: vieram da PORTA, num sinal de campo, e o primeiro deles REFUTA o
  "0 HARD" que eu declarei desta mesma branch. A causa não foi desatenção — foi medir num
  substrato onde a guarda dá o veredito oposto.
---

# 377

O `materialize-door.sh` resolvia o **como** se publica a porta. O **quando** era uma frase:
*"toda leva mergeada em main que toque a superfície que viaja"*. Frase não dispara.

```
onion-standalone, pin 514dda85833a → 377 commits atrás na superfície que viaja
```

Parado desde 2026-07-19. Não é negligência de ninguém: é o modo de falha previsível de um gatilho
que depende de alguém lembrar. E o custo é específico — **porta defasada não fica "desatualizada",
ela MENTE sobre o que o core é** para quem a usa como referência.

## O mecanismo

**REGRA 85 (Porta pública espelha o core, com catraca)** — para cada membro `kind: door` do
registro, conta os commits que tocaram as raízes de `--emit-scrub-roots` desde o `onion_version`
dele.

**Catraca, nunca muro.** Reprovar toda porta defasada nasceria vermelho (377) e seria desligada na
primeira sexta-feira. O passivo entra no baseline e **só encolhe**; porta que **anda para trás** é
HARD. Porta nova nasce com teto baixo — o `onion-core` entrou com **1**.

**Conta só o que viaja.** Commit de biografia não defasa a porta: ela não o receberia de qualquer
forma, e contá-lo faria a catraca disparar a cada commit do core — ruído que ensina a ignorar.

E o `onion-core` entrou no `members.yaml` como `kind: door` com o pin da materialização, o que dá a
SSOT de graça: a mesma que a REGRA 66 (Registro da federação validado no gate) já valida.

## Os três defeitos de harness, e são todos a mesma armadilha

**O baseline da guarda vive em `.claude/validation/` — que É a superfície que ela julga.** Escrevi o
harness três vezes antes de ver isso:

1. **Tirei o pin antes de commitar o baseline** — a porta nascia 1 commit atrás *por construção*, e
   o caso (a) reprovava a guarda por defeito meu.
2. **Sobrou um `git commit` duplicado** — sem nada a commitar ele sai 1, e sob `set -e` isso **mata
   a suíte inteira**.
3. **O caso (c) preparava-se mexendo no baseline** — e assim mudava o que o caso media. Cura:
   sandbox próprio, onde o único commit pós-pin é o de biografia, que é a hipótese sob teste.

## Teto declarado

A guarda mede **distância em commits**, não se a porta foi de fato republicada — ela lê o `pin` do
registro, e o pin é atualizado à mão. Um pin mentiroso passa. O que ela garante é que **a distância
não cresce em silêncio**, que é o que faltava.

E ela não publica nada: publicar segue humano (I3). O ciclo agora **avisa**; fechá-lo continua
sendo um ato.

---

# Adendo — a sessão dentro da porta refutou o meu trabalho em quatro pontos

O maestro rodou `/warm-up` no `onion-core` publicado. O lint **da própria porta**: **41 HARD**.

Quatro achados, e o padrão comum é o mais instrutivo: **eu entreguei metade de cada cura.**

| achado | a metade que faltou |
|---|---|
| `onion-version.sh` respondia **`role: source`** numa projeção que o README chama de "não a fonte" | escrevi o README que diz "projeção" e não carimbei a identidade que faz o repo **saber** disso |
| **22× REGRA 45 (Link vendorizado não aponta caminho core-privado, com catraca)** | o `--stub-baselines` **esvazia** o baseline (certo) e ninguém o **re-emitia** do corpus da porta |
| `inventory.md`/`graph.md` ausentes, com o `CLAUDE.md` mandando lê-los | cortei `docs/onion/` sem gerar o substituto |
| **3× REGRA 48 (Referência de caminho `.claude/…` em backtick (prosa) que não resolve)** | `settings.json` não viaja **de propósito**, mas três docs que viajam o citam |

Os três primeiros se curaram com helpers que **já existiam** (`regen-baselines.sh`,
`regen-ssot-projections.sh`) — escrever um quarto teria sido a quarta cópia.

## O recorte por papel, que é a peça de doutrina

Sobravam guardas acusando HARD enquanto **declaravam honestamente não ter julgado** — sem
`.kg.yaml`, sem `members.yaml`, sem PR. Elas estavam certas em não passar em silêncio e erradas em
tratar **ausência legítima** como defeito: uma porta que não recebe o corpus do core não pode ser
cobrada pela validade dele.

**E não virou silêncio** — seria trocar um fail-closed por um fail-open. Virou SOFT com classe
própria, `[papel/SEM-OBJETO]`, visível e contável. **No repo-fonte a mesma ausência continua HARD**,
porque ali ela *é* defeito — é o caso (b) da bancada. E o caso (c) garante que o corte é sobre **não
receber**, nunca sobre "está ruim": corpus presente e quebrado segue HARD em qualquer papel.

**Resultado: 41 HARD → 0.**

## O que me custou uma depuração

O predicado invocava `onion-version.sh` por dentro de `$( )` — onde o cache nunca persiste, e o
caminho quente abria um bash por violação. Passou a **ler o stamp direto**: mesma fonte, mais barato
e mais previsível que perguntar ao script que a lê.

## A catraca cobrou a própria leva que a criou

A REGRA 85 (Porta pública espelha o core, com catraca) acusou as duas portas de andarem para trás —
porque os commits desta leva mexeram na superfície que viaja. Baseline atualizado
(`onion-standalone 378`, `onion-core 2`). **O ciclo fechou sobre si mesmo na primeira volta**, que é
o teste que eu não teria como encomendar.


---

# Segunda rodada — o sinal veio da porta, e ele me refutou

Entre o carimbo anterior e este, a porta materializada abriu uma sessão limpa, rodou `/warm-up` e o
próprio lint, e escreveu um sinal ao core. Ele reprova exatamente o que o commit anterior desta branch
afirma no título: *"a porta passa no próprio lint"*.

```
/home/marcio/onion-core  (role: hub, pin 7a3504e6b121)
  Violações HARD : 1   ← .claude/rules/research-lens.md: nenhum glob de 'paths:' casa arquivo rastreado
  Violações SOFT : 6
```

Eu tinha declarado `rc=0 — nenhuma violação HARD`. **A declaração era minha e estava errada.**

## Achado 5 — a guarda dá vereditos OPOSTOS nos dois substratos

`_rule_glob_matches` tem dois ramos. Em repo git usa `git ls-files`. Fora dele:

```bash
pat="${g##*/}"                       # 'docs/evolution/research/**'  →  '**'
find "${REPO_ROOT}" -name "${pat}"   # -name '**' casa QUALQUER arquivo
```

O meu dogfood materializou a porta num destino **sem `git init`**. Ali toda regra path-scoped passa
trivialmente, porque `-name '**'` é um curinga que casa tudo. A porta real é repo git, e reprova.

O modo de falha é o pior que existe nesta casa: **a medição barata era a que mentia**, e ela é a que eu
escolhi. É [[testar-no-caminho-errado-e-nao-testar]] dentro do harness da própria porta — o mesmo erro
que a doutrina descreve, cometido no instrumento que deveria preveni-lo.

O ramo não-git agora respeita o **prefixo literal** do glob, como o pathspec do git faz. Dois casos de
bancada seguram os dois lados: (h) não casar quando o objeto não existe, (i) ainda casar quando existe
— porque cura que cega a guarda não é cura.

## Achado 6 — a allowlist separa a regra do objeto dela, e isso é CLASSE

| | core | porta (`hub`) |
|---|---|---|
| `.claude/rules/research-lens.md` | presente | presente, **byte-idêntica** |
| `docs/evolution/research/**` (o objeto) | 140 arquivos | **0** — não viaja, por desenho |
| veredito | regra útil | **HARD**, regra morta |

`.claude/**` viaja inteiro; `docs/evolution/` fica de fora porque *"inbox/inbound são infra LOCAL do
alvo"* (`vendor-manifest.sh:91`). As duas decisões estão certas isoladas. Juntas produzem uma regra que
**só pode** reprovar no alvo.

A irmã `kg-grammar.md` sobrevive por **acaso**: o glob `**/*.kg.yaml` casa as fixtures de
`.claude/validation/`, que viajam. Não é imunidade de desenho — é sorte do glob. Por isso o achado é
classe e não caso: hoje N=1, e a cada rule nova o dado é sorteado outra vez.

A cura declara a isenção em vez de reprovar cego, e o predicado **deriva da SSOT do transporte**
(`vendor-manifest.sh --emit-scrub-roots`) em vez de repetir aqui uma lista de prefixos que envelheceria
sozinha. Três invariantes na bancada: na **fonte** a mesma ausência segue HARD (senão o recorte vira
fail-open universal); glob que mira superfície que **viaja** continua cobrado em qualquer papel; e sem
o manifesto **não se concede isenção** — fail-closed, porque "não sei" nunca pode virar "passa".

## A nota secundária do sinal, que era um fio solto de desenho

A porta descobriu o problema **ao tentar entregar o sinal**: `co-relay.sh:85` testava
`!= "adopted"` e mandava `hub` para o `exit 2` — enquanto a mensagem de erro três linhas acima já
prometia *"adopted ou hub"*, e o espelho downstream `co-deliver.sh:119` **aceita** `hub` e só entrega a
`hub`/`standalone`.

Ou seja: o core **entrega** anúncios à porta por desenho declarado, e a porta **não podia responder**. O
doc-bridge estava mecanizado num sentido só — justamente na superfície pública, que é a que mais gera
sinal de primeira impressão. Este sinal chegou à mão por causa disso.


## Achado 7 — a catraca que eu acabara de construir era uma ESTEIRA

Este não veio de sinal nem de refutador. Veio de **usar** o mecanismo.

A guarda media `git log <pin>..HEAD` — HEAD da **branch**. Então:

```
378 → 380 → 381     três tentativas de fechar o MESMO gate
```

Cada commit que toca `.claude/**` afasta a porta em +1. Subir o teto para destravar **exige um
commit**. Esse commit afasta de novo. E a saída legítima não existia: a porta só se re-materializa a
partir de `main` **mergeada**, então a cura que o gate cobra nunca está disponível quando ele cobra.

**Guarda satisfazível só depois do merge não é gate de pré-merge.** Eu tinha escrito, no baseline, que
isto era "catraca por disciplina, não por mecanismo" e que a cura provável era comparar contra
`origin/main` — e então tentei destravar mais uma vez e a esteira andou de novo. Aí deixou de ser uma
nota e virou bloqueio do merge.

Curado: a ponta é o **`merge-base`** com o ramo default. Trabalho em voo ainda não é algo que a porta
pudesse espelhar; quando a branch merga, `main` anda e o número sobe com honestidade — que é
exatamente o gatilho que esta guarda existe para dar. Fallback declarado: sem `origin/<default>`
local, cai em `HEAD` — o comportamento antigo, mais estrito, nunca mais frouxo.

**O efeito colateral é a prova:** os tetos **caíram** de `378/2` para `372/0` sem ninguém
re-materializar nada. Os números antigos cobravam por trabalho em voo. A catraca não afrouxou —
ficou honesta. Bancada: (e) commit em voo não defasa · (f) o **mesmo** commit já em main defasa.

E houve um erro meu no caminho, que o próprio harness pegou: o caso (f) usava `git push` para um
clone **não-bare** com `main` checada fora — recusado, subshell não-zero, e sob `set -e` a bancada
**abortou antes da soma**, exibindo cinco ✓ e nenhum ✗. O aviso que ela imprime nessa situação existe
justamente porque cinco ✓ parecem verde. Trocado por `update-ref` no ref remoto.


## Duas coisas medidas de passagem, nomeadas e não curadas

**O contador de sítios de asserção subestima.** Adicionei **8 casos** de bancada e a projeção
`testing-inventory.md` subiu **1065 → 1067**. O padrão é `^\s*(record_pass|record_fail|record_skip) `
— ancorado no início da linha —, e a forma idiomática desta família escreve
`if …; then record_pass "…"` / `else record_fail "…"; fi`, onde o verbo vem depois de `then `/`else `.
Os casos (a)(b)(c) que já existiam têm a mesma forma, então o número **sempre** subestimou; não é
regressão desta leva. Fica nomeado porque o arquivo se declara SSOT gerada, e um número gerado que
subestima é pior que um ausente — ele parece medido. Gatilho: a próxima vez que alguém citar esse
total como cobertura.

**A bancada escreve na árvore viva, e o `git add -A` varre.** Dois artefatos
(`__mbguard__*`, `site/__selftest-*`) entraram num commit meu e só apareceram depois, como `D`
inesperado no status, quando a suíte seguinte os apagou. A bancada limpa ao final — mas se ela morre
no meio (kill, timeout, `set -e`), os artefatos ficam. Curado por `.gitignore`: ignorar é mecanismo,
lembrar de conferir não é.


---

# A bancada reprovou a pilha inteira — e tinha razão

Rodada completa: **1301 ✓ / 4 ✗**, reprodutíveis numa árvore limpa. A primeira coisa que fiz foi
medir se eram minhas: as mesmas três famílias numa worktree do `merge-base`.

```
merge-base (origin/main)   35 ✓ / 0 ✗
branch                     31 ✓ / 4 ✗
```

**Regressões desta pilha.** Eu tinha registrado a suspeita oposta ("provavelmente pré-existentes") —
a medição a derrubou. As quatro têm **uma causa comum**, e ela é a coisa mais séria desta onda.

## A classe: uma linha de segurança desligou duas guardas de outra família

A cura que impede a **chave privada** de viajar é um pathspec `:(exclude)` no manifesto de
transporte. Ela entrou, e:

**(1) `vendor-manifest` — o fail-loud contra o bundle vazio ficou MORTO.** O `:(exclude)` era
apendado **antes** da guarda `[ "${#_spec[@]}" -eq 0 ]`, então o array nunca era vazio. E a segunda
guarda caiu junto, porque um spec composto **só** de exclusão casa *tudo menos aquilo*: num repo sem
superfície Onion o manifesto saía **rc=0 mandando copiar o repositório inteiro** — biografia e
segredos junto. O comentário que descreve exatamente esse desastre estava três linhas acima, intacto,
enquanto a guarda que ele justifica não funcionava.

**(2) `vendor-branch` — a customização do adotante era SOBRESCRITA.** `git ls-tree` **recusa** magia
de pathspec. Ele errava, o `2>/dev/null` engolia, a variável voltava vazia, e `_clean_baseline` lia
esse vazio como *"não existe baseline limpo"* — ramificava do HEAD e o merge apagava a customização.
Medido na reprodução manual:

```
antes:  cmd v1 CUSTOM
depois: cmd v2          rc=0
```

Um `rc=0` e um arquivo do adotante perdido, em silêncio, na rota `--update`.

**O que a classe diz:** uma linha de segurança **não é local**. Ela muda o *valor* que atravessa
todos os consumidores, e cada consumidor tem contrato próprio — `git archive` aceita a magia e
**deve** recebê-la (é o transporte); `ls-tree` a recusa. E os dois defeitos falharam por **saída
vazia com rc escondido**, não por lógica errada: [[exit-code-nao-e-a-verificacao]] duas vezes no
mesmo commit.

Curas: a precondição conta só os **positivos** e roda **antes** de apendar a exclusão · quem
**compara** árvores usa `_manifest_positivo`, quem **transporta** usa o manifesto inteiro · o
`ls-tree` que falha agora **fala**, porque *"sem baseline"* e *"não consegui olhar"* não podem soar
igual — a diferença entre os dois é um merge que preserva a customização e um que a apaga.

## E dois casos de bancada que estavam certos para o que sabiam

`vendor-manifest (c)` acusava a exclusão de identidade de ser superfície não-varrida — mas
`:(exclude)` é o **oposto** de uma raiz: ele subtrai. A guarda lia ao contrário, reprovando
justamente a linha que impede a chave de viajar. Filtrado.

`role-cut (b3)` exigia **zero** excludes no `hub` ("fidelidade TOTAL", palavras do maestro). A
exceção mudou isso com razão: um hub que recebe a chave privada do core não trabalha como o core,
**vaza**. A invariante certa não é "nenhum exclude", é "nenhum exclude **além** dos de identidade,
que são declarados" — e a lista esperada é lida da SSOT, nunca redigida no caso, senão o oráculo vira
opinião. Qualquer exclude novo para `hub` continua reprovando, que era o ponto do caso.


---

# Achado 12 — o diagnóstico que a doutrina manda rodar estava MORTO

O `onion-review-verdict` reprovou este PR: o revisor semântico morreu duas vezes
(`is_error:true`, `turnos=1, custo=0`) — e **não é crédito nem credencial**, porque o pré-voo deu
`HTTP 200` contra `claude-sonnet-5`.

O próprio `onion-review.yml` diz o que fazer, e diz com uma nota epistêmica rara:

> *"este comentário já mentiu duas vezes … não reescreva causa neste bloco sem rodar o diagnóstico
> (`onion-review-diagnose.yml`)"*

Fui rodar. Resposta:

```
HTTP 422: failed to parse workflow: (Line: 39, Col: 5): 'env' is already defined
```

**O instrumento estava inexecutável há um dia** — quebrado por `3d39372e` (2026-09-16), trabalho meu,
que acrescentou um bloco `env:` sem ver que já havia outro. A doutrina mandava não adivinhar e
apontava para uma ferramenta morta; adivinhar virava a única coisa que sobrava.

**Por que nada pegou**, e é a forma do defeito: `workflow_dispatch` só falha quando alguém *dispara*,
e o gatilho `pull_request` do arquivo é restrito a ele mesmo — ninguém mais o tocou desde a quebra. O
`harness-inventory.sh` **contava** os workflows e nunca os **lia**. Contar não é validar, e uma SSOT
que conta artefato quebrado exibe um número com cara de saúde.

Curado com a **REGRA 86 (Workflow de CI PARSEIA como YAML)**, HARD.

## Achado 13 — e a bancada pegou a minha própria cura pela metade

A 1ª redação da REGRA 86 usava `yaml.safe_load` nu. O caso (b) reprovou:

```
✗ workflow-parse: (b) — não pegou o env duplicado
```

**O YAML padrão ACEITA chave duplicada** (fica com a última); o parser do GitHub a **rejeita**. Ou
seja: a regra nova passava verde no defeito **exato** que a originou. Loader estrito, que levanta na
duplicata — o contrato do consumidor real, não o do parser mais próximo.

Duas lições de forma, as duas já registradas nesta casa e as duas reincidentes hoje:

- **[[bancada-espelha-o-runner]]** — a 1ª versão do harness *sourceava* o lint inteiro; o top-level
  fazia seu trabalho sob `>/dev/null` e a função saía muda. Dois casos reprovavam por defeito **do
  harness**, com o SUT correto. Trocado pela extração da função, que é o padrão desta família.
- **`out="$(_wp_run)"` sob `set -e`** matou a suíte antes do primeiro ✓ — o rc da substituição é o
  rc do comando. O aviso da própria bancada ("ABORTOU ANTES DA SOMA") foi o que me disse.

E o registro de regras cobrou na hora certa: `harness-inventory.sh` saiu `rc=2` com *"REGRA(S) sem
categoria: [86]"*, e o `regen-ssot-projections.sh` **removeu** a projeção em vez de escrever lixo,
avisando *"saída VAZIA (arquivo removido, o alvo cobrará)"*. Classificada em **Integridade do próprio
gate** — a categoria que pergunta *"eu cheguei a olhar?"* —, porque um workflow que não parseia não é
um gate que falhou: é um gate que **nunca rodou**.


---

# Achado 14 — o critério escrito não impediu a terceira vez

A REGRA 39 (Registro de REGRAS derivado e em paridade com as guardas) reprovou: a REGRA 86 entrou
no registro e `lint-rules.md` — projeção **gerada**, com catraca no lint — não estava na lista do
`regen-ssot-projections.sh`.

É a **terceira** ampliação da mesma lista pela mesma causa:

```
09-16 manhã   testing-state.md    (REGRA 81)  ← depois de reprovar 4× no CI
09-16 noite   testing-inventory.md (REGRA 80)
09-17         lint-rules.md        (REGRA 39)  ← aqui
```

Na segunda vez eu escrevi **no próprio arquivo**: *"CRITÉRIO, para não haver terceira: toda projeção
gerada com catraca no lint pertence a esta lista."* E houve terceira.

**Essa é a lição, e ela não é sobre a lista.** Critério escrito **descreve** o dever; não o
**executa**. A cura real é a bancada `regen_completude`, que **deriva** o conjunto esperado das
próprias mensagens do lint — toda violação que diz `regenere: bash .claude/validation/<gen>` nomeia
um par projeção↔gerador — e reprova quando um par não é coberto nem **isento com razão escrita**.

Na **estreia** ela achou um quinto gerador que a minha varredura manual tinha perdido
(`a2a-agent-card.sh`, cuja frase difere um pouco das outras). É exatamente a diferença entre
conferir por máquina e conferir por quem lembrou.

As quatro isenções são declaradas com o porquê, nunca uma lista muda: `federation-console.sh` e
`marketplace-root-check.sh` projetam em superfície core-only · `vendor-scrub-form-check.sh` emite
**baseline**, que é ledger do alvo e o do core nunca viaja · `kg-view.sh` é visualizador por-grafo,
não gerador · `a2a-agent-card.sh` deriva do `members.yaml`, core-only.

E o caso carrega **mutante**: tirar `rules-registry.sh` da lista tem de fazer o oráculo reprovar —
senão ele vira um `grep` que sempre acha algo, e guarda que não sabe reprovar não guarda nada.
