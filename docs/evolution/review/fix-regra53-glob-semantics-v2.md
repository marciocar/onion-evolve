---
title: 'A fronteira que eu declarei sem medir era falso positivo, e a paridade dos dois ramos virou guarda'
date: 2026-09-29
branch: fix/regra53-glob-semantics
reviewed_diff_sha256: 81da94cd3049a748470948c745ea24232a378b17c239ccdffa40677aaf2a7078
elenxo: nao
findings_total: 7
findings_real: 7
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'Continuação do resíduo fix-regra53-glob-semantics.md, no mesmo ramo, depois de o maestro pedir para revisar os dois fios que eu havia declarado abertos. SEM refutador: o que havia para refutar era "a fronteira das braces é defensável?", e a SONDA contra o binário respondeu — não é. Cada cura tem fixture nas duas pontas e mutante provado, inclusive a guarda de paridade, que reprova com a mensagem exata do meu erro de hoje.'
---

# Resíduo (v2) — os dois fios que eu declarei abertos, revisados e fechados

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
