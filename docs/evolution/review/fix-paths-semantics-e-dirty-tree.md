---
title: 'A guarda lia uma forma de três, o revisor absolvia com árvore suja, e eu quase commitei um comentário mentindo sobre o código'
date: 2026-09-29
branch: fix/paths-semantics-e-dirty-tree
reviewed_diff_sha256: 4aee71815af776afd1fd8c04cfa80848ddde498d1f221da833bc68f3515d3e53
elenxo: nao
findings_total: 6
findings_real: 6
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, e o motivo é declarado: as duas curas nasceram de MEDIÇÃO contra o binário (lentes-sonda + o log instructions-loaded.jsonl) e de leitura do próprio workflow, não de tese a refutar. Além disso este PR edita `.github/workflows/onion-review.yml`, e a action se AUTO-PULA nesse caso — então a revisão semântica do CI também não julga esta mudança nela mesma. Os dois tetos ficam escritos em vez de descobertos depois.'
---

# Resíduo — `paths:` lido pela metade, e o verde que absolvia sem saber

## 1. A REGRA 53 lia UMA das TRÊS formas que o harness aceita

Medido em 2026-09-29 **contra o binário**, com lentes-sonda em `.claude/rules/` e o log
`.claude/sessions/instructions-loaded.jsonl`, que registra `path_glob_match` com o arquivo que disparou
— esse log é o instrumento que torna a pergunta *"a lente carregou?"* mensurável, e eu não sabia que
existia quando disse que não sabia responder.

| forma de `paths:` | harness | parser da REGRA 53 (antes) |
|---|---|---|
| bloco `paths:\n  - "x/**"` | carrega | lia |
| **escalar** `paths: "x/**"` | **carrega** (sonda) | **devolvia vazio ⇒ acusava "paths: VAZIO" em lente VIVA** |
| **flow-list** `paths: ["x/**"]` | **carrega** (sonda) | **idem** |

Curado: o parser lê as três. É ampliar o que a guarda **enxerga**, não afrouxar o que ela **cobra** — o
predicado de casamento segue idêntico, e as formas novas passam a ser julgadas por ele. Três fixtures
novas (`good-scalar-paths`, `good-flow-paths`, `bad-scalar-dead`), levando a regra de 5 para 8.

**Mutante provado sem tocar o arquivo vivo:** o awk antigo, rodado contra as duas formas novas, devolve
**vazio** — é a discriminação, e ela vive no nível do awk, não da bancada.

## 2. A divergência de casamento fica MEDIDA e NÃO curada

As outras duas formas confirmadas por sonda **não** foram tocadas, porque mexem na semântica de
casamento de uma guarda HARD:

- **`*` nu não cruza `/` no harness** (sonda carregou em `raso.kg.yaml`, não em `nivel/fundo.kg.yaml`),
  enquanto `git ls-files` **cruza** — `docs/*.md` devolve 1071 hits, **1069 profundos**. Efeito:
  **lente morta ABSOLVIDA**.
- **braces expandem no harness** e `git ls-files` devolve **0** para `docs/{a,b}/**`. Efeito: **lente
  viva ACUSADA**.

As duas lentes vivas do repo usam formas que por acidente concordam (`**/*.kg.yaml` e
`docs/evolution/research/**`) — é só por isso que a guarda nunca errou até hoje. GATILHO para curar: a
primeira lente legítima reprovada, ou a primeira morta absolvida em uso real.

## 3. O revisor do CI absolvia com a árvore suja

No PR #886 o parecer disse **"VEREDITO: conforme"**, o check disse **`pass`**, e a própria guarda
`dirty-tree` do workflow avisou que **trechos do parecer podiam ser de conteúdo que não é do PR** — os
3 arquivos acusados eram exatamente os 3 que o PR alterava.

**Causa medida:** `--allowedTools Read Grep Glob Bash`. `Bash` está na allowlist, e a proibição de
escrever é **prosa no prompt**. Mesma classe de 2026-09-20, quando um refutador com *"não modifique
nada"* escreveu em seis arquivos. Instrução em prosa não é fronteira.

**O que eu REJEITEI:** fechar o `Bash` por lista de comandos. `sed -i`, `python3` e `tee` escapam de
qualquer lista (classe "guarda por lista falha pelo vocabulário"), e apertar demais ressuscita a morte
por negação de permissão que o `--allowedTools` explícito curou.

**O que eu fiz:** usei o **terceiro desfecho que o contrato já tinha**. O `review-verdict.sh` define
`achados = -1` como *"não pude contar, nunca bloqueia"*, e diz no próprio comentário que transformar
ignorância em bloqueio é a classe que esta casa mais persegue. Árvore suja **é** ignorância:

- a detecção **mudou de lugar** — roda **antes** do step que decide a contagem (antes rodava depois e só
  carimbava o comentário);
- árvore suja ⇒ **`achados = -1`**, com `::warning::` nomeando a contagem desqualificada;
- o comentário passou a **reusar** a medição em vez de refazê-la — duas medições do mesmo fato em pontos
  diferentes do job divergem em silêncio, e a que o leitor vê não seria a que desqualificou;
- os dois `env` que sobraram mortos no step do comentário foram removidos, para não fingir que a
  medição acontece ali.

Não bloqueia nem absolve: **recusa afirmar**.

**Teto herdado, não resolvido:** sujar-e-limpar (`checkout` + `restore`) segue invisível — o comentário
original já declarava isso.

## 4. Eu quase commitei um comentário mentindo sobre o código

Testei o mutante do parser **trocando o arquivo vivo**, matei o processo no meio (com um `pkill -f` cujo
padrão casou o **próprio shell** — exit 144, e a guarda do repo já me avisara dessa armadilha hoje), e o
restore não rodou. Resultado: `lint-artifacts.sh` ficou com **o comentário novo prometendo as três
formas e o código antigo lendo uma**.

O que me salvou foi `diff`, não cuidado: `grep -c` do marcador dizia *"parser novo presente: 1"* e
estava tecnicamente certo — o **comentário** estava lá. **Marcador é declaração; `diff` é medição.**

Duas mudanças de método, registradas: **mutante nunca no arquivo vivo** (a discriminação do parser já
estava provada no nível do awk, e eu fui trocar o arquivo por reflexo), e `pgrep -A` / idioma do
colchete em vez de `pkill -f` com o padrão do próprio comando.

## 5. Contexto: o CI voltou, e não era a conta

Confirmado nesta sessão: os runs voltaram a nascer às ~14:59Z, **sem nenhuma mudança na conta ou no
repo**. Isso fecha o diagnóstico de **incidente de plataforma** e refuta em definitivo a atribuição a
cota que eu havia feito. O #886 foi o primeiro merge pelo caminho **normal** desde 26/09.

## Gates

- `lint-artifacts.sh` → 0 HARD (a confirmar no SHA final)
- `lint-selftest.sh --families fixtures` → as 8 fixtures da REGRA 53 exercitadas
- `/meta:realign` → **ALINHADO** nos 3 grafos, `--check` rc=0
- ⚠️ **A revisão semântica do CI NÃO julga este PR**: ele edita `onion-review.yml` e a action se
  auto-pula nesse caso. Declarado aqui porque o verde do `onion-review` neste PR não significa revisão.

## Declarado aberto, com gatilho

- **Semântica de casamento de `paths:`** (item 2) — medida, não curada.
- **`/meta:realign` não vê este tipo de defeito**: o Frankenstein do item 4 passaria ALINHADO, porque o
  grafo não fala do `awk`. Quem pega é `diff`, bancada e fixture. Vale como teto do comando, não defeito.
