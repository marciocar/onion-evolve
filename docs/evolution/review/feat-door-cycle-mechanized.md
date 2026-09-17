---
title: 'Resíduo — o ciclo era prosa; e o meu dogfood media no substrato errado'
date: 2026-09-17
branch: feat/door-cycle-mechanized
reviewed_diff_sha256: 460ff75d8a9f10a00ff7532a2c701ce82ed12596871ef5c08973a98113bec1a5
findings_total: 6
findings_real: 6
findings_fixed: 6
tokens: 0
duration_min: 0
verdict: CORRIGIDO
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
