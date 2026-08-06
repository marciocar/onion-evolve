---
reviewed_diff_sha256: 797a22ce7d2c685de1ff7040fc68d5fb53a6770e765dd75f702492b34a663601
scope: [.claude/hooks/, .claude/validation/]
findings_total: 12
findings_real: 12
tokens: 127472
duration_min: 20
verdict: corrigido-antes-do-PR
---

# Revisão adversarial — `feat/gate-anti-cegueira`

**O primeiro artefato da REGRA 56, e ele julga o próprio mecanismo que a criou.** Se este PR não
passar no gate que introduz, a regra não está pronta — foi a condição escrita no plano.

## O que a passada achou, e por que ela existia

A revisão foi rodada com um pedido explícito de ceticismo: *"este código foi escrito para curar a
cegueira do próprio autor, e por isso é o mais provável de repeti-la — procure a 4ª ocorrência da
família NESTE código"*. Achou, e mais de uma vez.

**12 achados, 12 reais.** Nenhum foi encontrado por releitura minha.

| # | severidade | achado | estado |
|---|---|---|---|
| 1 | **crítico** | a REGRA 56 **nunca executava no CI** — `onion-validate.yml` faz checkout com `ref: head.sha` → HEAD destacado, e o helper saía por `detached-head` **antes** do ramo escrito para o CI | corrigido (`GITHUB_HEAD_REF` primeiro) + caso (h) |
| 2 | **crítico** | no modo **TSV** — o que o lint consome — **toda isenção era zero byte**; o comentário afirmava "declara a ignorância" e isso só valia no modo humano. 5 classes de silêncio medidas | corrigido (`_skip` emite em TSV) + caso (i) |
| 3 | alto | **HARD sem adopter-awareness** viajando para a rede — repetição literal do episódio dos 11 falsos da manhã, com o idioma já existindo no repo | corrigido (`role: adopted\|hub` isenta) |
| 4 | alto | `_field` lia o **arquivo inteiro**: `tokens: gastei uns poucos` na prosa satisfazia o gate | corrigido (só frontmatter + campo numérico é número) |
| 5 | alto | o artefato **não precisava estar commitado** (`-f` testa disco): o resíduo podia nunca sair da máquina do autor | corrigido (`git cat-file -e HEAD:`) |
| 6 | médio | declarei o 5º detector *"falso-positivo estruturalmente impossível"* e **estava errado** — disparou 3× nos comandos de leitura do próprio revisor | corrigido (âncora em início de comando) |
| 7 | médio | o hash **não era canônico**: `diff.noprefix`/`core.abbrev` no `~/.gitconfig` davam hashes diferentes → artefato nasceria caduco sem pista | corrigido (forma canônica nos dois lados) |
| 8 | médio | a isenção ovo-galinha isentava PR **inteiro** que apenas *tocasse* o workflow (52 arquivos, 1 linha nele → isento) | corrigido (só quando o diff é exclusivamente o workflow) |
| 9 | médio | selftests frouxos: **(k) tautológico** (`gh pr checks` não pode conter `gh pr merge`); **(c)** só checava `rc=0` e passaria por fora-de-escopo — que é exatamente como o CI ficou cego | corrigido |
| 10 | baixo | citei uma **"REGRA 57" que não existe** — manchete acima da evidência, no meu próprio comentário | corrigido |
| 11 | baixo | `consumed-mode-check.sh`: cabeçalho declara 2 lacunas e a execução imprime 5; sem selftest | **aberto** — declarado, é instrumento não-ligado |
| 12 | baixo | `repo_root` documentado como opcional, mas `--format=tsv` sozinho dá exit 2 | **aberto** |

## O achado que vale mais que a soma dos outros

O nº 1 é o resultado desta sessão inteira, e é sobre mim:

> **Escrevi um mecanismo para não depender do maestro perguntar. Ele nunca rodava no único caminho
> que não depende do maestro perguntar.**

O ramo de CI que escrevi *pensando no CI* era **código morto neste repo** — porque eu verifiquei o
comportamento do script, não a **forma que o CI realmente tem**. É a mesma família dos outros três
erros do dia (guarda testada em modo humano e consumida em TSV · regra validada só no core e falsa no
adotante · ledger declarado medido e não commitado): **verifico o artefato, não o caminho de consumo.**

Quatro ocorrências em um dia, a última **dentro da cura das três primeiras**, com o diagnóstico fresco.
Isso é evidência forte de que a classe não se resolve por atenção — que é precisamente a tese que este
PR mecaniza.

## O que fica aberto, declarado

- **11 e 12** acima — cosméticos, no instrumento não-ligado.
- **`inventory.sh --markdown` e `migalhas-generate.sh --check`**: consumidos pela produção e **nunca**
  invocados pelo selftest. Lacunas reais achadas pelo `consumed-mode-check.sh`, verificadas à mão.
- **O teto do mecanismo, repetido porque é fácil de esquecer:** este repo não tem branch protection
  (403). **Nada impede um merge.** O que ficou impossível não é mergear errado — é mergear **sem
  saber**.

## Método

Agente `code-reviewer` (opus), prompt adversarial com o contexto dos 3 erros do dia e o pedido explícito
de procurar a 4ª ocorrência. Sandboxes em `/tmp`, read-only sobre o repo. Cada achado com comando de
reprodução; os que verifiquei de forma independente antes de corrigir estão marcados no commit
`11d9988`. O revisor também declarou **um não-achado** (o padrão `[ -n "${ONLY_PATH}" ] && return 0`
sob `set -e`), verificado e confirmado como correto — registrar o que **não** é defeito evita
re-suspeita depois.
