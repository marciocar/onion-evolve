---
title: 'A guarda media com a régua do git onde o harness usa outra, e eu curei um de dois ramos'
date: 2026-09-29
branch: fix/regra53-glob-semantics
reviewed_diff_sha256: 9332ad224852afa83b99c4f82aad795c3d8319187d3f5975d20753015a66ad87
elenxo: nao
findings_total: 10
findings_real: 10
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'DUAS levas no mesmo ramo, e a segunda INVERTEU uma decisão da primeira — a continuação está na seção final, sem reescrever o que veio antes. O arquivo é UM porque a REGRA 56 julga só `<branch-slug>.md`: um segundo `-v2.md` era invisível para a guarda, e artefato fora do mecanismo é o que esta casa recusa (o CI pegou, no ARTEFATO-CADUCO deste mesmo resíduo). SEM refutador, e o motivo é declarado: as duas divergências foram MEDIDAS contra o binário (lentes-sonda + o log instructions-loaded.jsonl) antes de qualquer cura, e cada cura tem fixture nas DUAS pontas com o caso que a derruba. Quem me reprovou aqui foi a BANCADA, não leitura — ela achou que eu havia curado só um dos dois ramos do helper. Refutador mediria o mesmo que as fixtures já medem.'
---

# Resíduo — `:(glob)`, braces, e o ramo que a bancada mede

## As duas divergências, medidas contra o binário

Sondas em `.claude/rules/` + o log `.claude/sessions/instructions-loaded.jsonl` (que registra
`path_glob_match` com o arquivo que disparou):

| forma | harness | `git ls-files` nu (o que a guarda usava) | efeito |
|---|---|---|---|
| `*` nu | **não cruza `/`** | **cruza** — `docs/*.md` → 1074 hits, **1072 profundos** | **lente morta ABSOLVIDA** (fail-open) |
| `{a,b}` | **expande** | **0 hits**, nem com magic | **lente viva ACUSADA** (falso positivo HARD) |

## As curas

- **`*`**: o pathspec passa a ser `:(glob)<g>` — o git **já tem** a semântica certa embutida. Medido:
  `docs/*.md` cai de 1074 para **2 hits, zero profundos**; `**` segue cruzando nos dois. Sem
  dependência nova, sem lista de casos.
- **braces**: expansão de **um nível** antes de consultar o git, casando por **qualquer** alternativa —
  que é o que o harness faz. Braces aninhadas ou com `/` dentro ficam **de fora, de propósito**:
  inflar o casamento trocaria um falso positivo por um fail-open, que é o pior dos dois.

**Prova do fail-open na forma exata:** `.claude/validation/fixtures/*.md` tinha **83 hits** pelo
pathspec nu (a guarda absolvia) e **0** com `:(glob)` — e 0 é o que o harness veria. O helper curado
**acusa**.

## O achado que só a bancada podia dar: eu curei UM de DOIS ramos

`_rule_glob_matches` tem ramo **git** e ramo **NÃO-GIT**. A sandbox de fixtures é montada com `tar`
(sem `.git`), então **a única cobertura ponta-a-ponta que existe exercita o ramo não-git** — exatamente
o que eu não tinha tocado. As três fixtures novas reprovaram, e não por estarem erradas: elas mediram
o caminho certo.

É `testar-no-caminho-errado-e-nao-testar` **invertida** — eu curei o caminho que eu **media** (o git, no
repo real, onde provei 83 → 0) e deixei intacto o que a bancada mede. Se eu tivesse só lido o código,
commitaria meia cura com três fixtures novas dando a impressão de prova.

O ramo não-git recebeu as mesmas duas semânticas: `-maxdepth 1` quando o glob não tem `**` (o `*` fica
num nível, como o harness) e a mesma expansão de braces antes do `find`. O comentário no código diz
**por que** esse ramo existe e **que é ele** que a bancada vê — para o próximo que cure metade não
repetir.

## As fixtures, nas duas pontas

`bad-star-only-deep` (o fail-open exato) · `good-brace-live` (viva com braces tem de passar) ·
`bad-brace-dead` (braces cujas alternativas nenhuma casa tem de ACUSAR — é o mutante da minha própria
expansão). A REGRA 53 vai de 8 para **11 fixtures**.

## Gates

- `lint-selftest.sh --families fixtures` → **102 ✓ / 0 ✗**, com as 11 da REGRA 53 verdes
- `lint-artifacts.sh` → 0 HARD (a confirmar no SHA final)
- `/meta:realign` → ALINHADO nos grafos, `--check` rc=0

## Declarado aberto

- **Braces aninhadas ou com `/` dentro** seguem pelo caminho literal, nos dois ramos. Não é
  esquecimento: é a fronteira que impede a expansão de virar fail-open. GATILHO: a primeira lente
  legítima que use uma dessas formas e seja reprovada.
- **A paridade entre os dois ramos não tem guarda.** Hoje ela existe porque eu escrevi as duas
  semânticas nos dois lugares; nada impede que a próxima cura toque um só — foi literalmente o que
  aconteceu nesta leva. GATILHO: a próxima divergência de semântica entre git e harness, ou a
  primeira vez que uma fixture passe no repo e falhe na sandbox (ou o inverso).

---

# CONTINUAÇÃO (2026-09-30) — a revisão que o maestro pediu INVERTEU uma decisão acima

O que segue foi escrito depois, no mesmo ramo, quando o maestro mandou revisar os dois fios que a
seção "Declarado aberto" acima deixou. **Um deles caiu por medição** — e o texto anterior fica onde
está, sem reescrita, porque corrigir apagando transformaria a correção em propaganda.

## Fio 1: a minha "fronteira declarada" era falso positivo

O resíduo anterior dizia que braces **aninhadas** ou com `/` dentro ficavam de fora *"de propósito:
inflar o casamento trocaria um falso positivo por um fail-open"*. **A medição refutou a justificativa.**

Sondas em `.claude/rules/` + o log `instructions-loaded.jsonl`:

| forma | harness | helper (antes) |
|---|---|---|
| `docs/x/{a,{b,d}}/**` | **CARREGA** | não casava ⇒ **falso positivo** |
| `docs/x/{a/f.md,b/c/g.md}` | **CARREGA** | não casava ⇒ **falso positivo** |

As duas formas são legítimas, e reprová-las é **exatamente o defeito que esta leva veio curar**. Pior: eu
declarei um teto **sem medir se havia algo atrás dele** — oitava ocorrência, nesta sessão, de afirmar a
partir do que eu imaginava.

**E o fail-open que eu temia não vem da recursão** — vem de tratar *"tem braces"* como *"casa"*. A fixture
`bad-brace-dead` (alternativas em que NENHUMA casa ⇒ ACUSA) é o mutante que separa as duas coisas, e ela
já existia e passava.

**Cura:** `_expand_braces`, recursivo, usado pelos **dois** ramos. Acha o `}` que fecha contando
profundidade e divide nas vírgulas de **nível zero** — vírgula dentro de brace aninhada pertence a ela.
Brace **não fechada** volta literal, sem chutar. Exercitado direto:
`a/{x,{y,w}}/z` → 3 alternativas · `a/{p/q.md,r/s.md}` → 2 · `a/{aberta` → literal.

Duas fixtures novas (`good-brace-nested`, `good-brace-slash`); a REGRA 53 vai de 11 para **13**.

## Fio 2: a paridade dos dois ramos virou GUARDA, e ela pega o meu erro de hoje

`_rule_glob_matches` tem ramo **git** e ramo **não-git**, e nesta mesma sessão eu curei **um só** — a
sandbox de fixtures é `tar` sem `.git`, então a cobertura ponta-a-ponta media justamente o ramo intacto.
Até agora a paridade dependia de eu escrever as duas semânticas nos dois lugares: **disciplina, não
mecanismo**.

Nova família `run_glob_branch_parity_selftests`. **O oráculo não é uma régua externa — é a CONCORDÂNCIA**:
os mesmos 8 globs, na mesma árvore mínima, em dois substratos (um com `git init`, um sem), têm de dar
veredito **idêntico**. Por isso o caso não caduca quando a semântica do harness mudar: ele só cobra que as
duas metades andem juntas. Os helpers são extraídos do arquivo **vivo**, não de cópia digitada.

**Mutante provado** — reintroduzi o meu erro (tirei o `-maxdepth` só do ramo não-git):

```
✗ glob-parity: (a) — 1 glob(s) com veredito DIVERGENTE entre os ramos —
  docs/fundo/*.md[git=NAO nogit=CASA]
```

Ela nomeia **qual** glob e **qual** lado. E o arquivo real foi restaurado por `diff`, não por marcador —
a lição de ontem, aplicada.

## Duas falhas MINHAS que só a bancada completa pegou

Nenhuma das duas apareceria em leitura, e as duas abortaram a suíte com `exit 127`:

1. **Harness sem a dependência nova.** `_expand_braces` é dependência NOVA de `_rule_glob_matches`, e a
   família `role_scope` extrai esse helper para uma sonda própria — sem copiá-la. Resultado:
   `_expand_braces: command not found`, worker morto, e um segundo ✗ (`role-scope: (h)`) que era
   **consequência**, não defeito separado. Classe [[fail-closed-exposes-incomplete-harness]], 3ª vez
   nesta casa: mexer no motor quebra todo harness que o copiava sem a peça nova. **Cura no HARNESS** —
   extrair `_expand_braces` E nomeá-la na lista de símbolos exigidos, para a próxima ausência ser
   **declarada** (`SEM-FUNCAO:`) em vez de descoberta por abort.
2. **Registro de família fundido.** A linha virou
   `_family run_forge_selftests_family run_forge_selftests`, porque eu usei `_family
   run_forge_selftests` como **âncora de inserção** e ela casou dentro do registro que já existia — o
   texto que eu queria ancorar ERA o texto que eu ia duplicar. Mesma raiz do dia: ancorei numa string
   que supus única.
   Conferido depois: **195 famílias registradas, todas com função definida**. O predicado que eu
   inventei para achar isso (contar campos das linhas `_family`) deu **7 falsos positivos** — linhas com
   `|| true` legítimo — e serviu porque eu li a saída inteira antes de concluir, em vez de tratar todo
   desvio como defeito.

## Gates

- `lint-artifacts.sh` → **0 HARD** / 17 SOFT (pré-existentes)
- `glob_branch_parity` → 1/1, com mutante vermelho
- REGRA 53 → **13 fixtures**; bancada completa a confirmar no SHA final
- `/meta:realign` → ALINHADO nos grafos

## Declarado aberto

- **A guarda de paridade compara os ramos entre si, não contra o harness.** Se ambos divergirem do
  binário do mesmo jeito, ela fica verde. Isso é deliberado — comparar contra o harness exigiria
  replicar o matcher dele, que é a dependência que esta casa recusou. GATILHO: a próxima sonda que
  mostre divergência harness × guarda em forma nova.
- **As sondas são manuais.** O método (lente-sonda + `instructions-loaded.jsonl`) está escrito nos
  dois resíduos, mas nada o executa por rotina. GATILHO: a terceira vez que uma forma de `paths:`
  precisar ser medida — aí a sonda vira script.
