---
reviewed_diff_sha256: e43410aec0cf93bb439eec80e0c2fbbd8111f0fe97d68b2db168c019227d2b8a
findings_total: 28
findings_real: 28
tokens: 349054
duration_min: 33
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Refutador opus/high em worktree isolada, mandato REFUTAR, default REPROVADO: 184.628 tokens, 88
  chamadas, ~17 min. Placar dele: 3 aprovados (itens 1, 3, 4), 4 REPROVADOS (2, 5, 6, 7), 2
  não-verificados, 14 achados — 5 de 1ª classe e 2 fora da minha lista. Ele rodou os artefatos,
  refez os 4 mutantes com harness PRÓPRIO (confirmando que mordem) e acrescentou 2 que eu não tinha.
  Os achados de conteúdo (R2 cron, R3 "32 dias", R8 citação) foram RE-VERIFICADOS por mim na fonte
  antes de aceitar — veredito de subagente é hipótese. Os 14 estão curados nesta branch, com 8 casos
  de bancada e 8 mutantes mordendo; a única coisa que NÃO virou código é o R11 (guarda da classe),
  registrada como 4º candidato com defeito datado e passivo medido em ZERO, aguardando selo do
  maestro — eu não cunho REGRA numerada sozinho.
---

# Resíduo — `fix/medidores-que-cortam-em-silencio`

## A ironia é estrutural, e é o achado mais importante

Um PR cujo tema é *"medidor que corta em silêncio produz afirmação falsa"* entregou **um aviso que
declarava um corte falso**, **um nó que afirmava uma proibição falsa**, e **o corte silencioso intacto
exatamente onde o dano acontece**. O gate mecânico esteve **verde (0 HARD) nas duas rodadas** — e
nenhum dos cinco achados graves é detectável por lint. É precisamente o caso que o PR se propunha a
tratar.

## Placar e os cinco de 1ª classe

| # | Achado | Gravidade | Estado |
|---|---|---|---|
| **R1** | O `forge-census` tem **dois** cortes (o `head`, e rastreado-ausente-do-disco). Curei um e o aviso novo **mentia** sobre o outro — provado movendo um candidato do disco com `TOP=100000`: *"CORTADA: 58 de 59"* sem corte algum. E a rota de reparo era falsa: `--tsv` sofre o mesmo pulo | 🔴 | **curado** — compara contra `_rows_total` (o medido), e o descarte ganhou rótulo e lista próprios |
| **R2** | O nó `open` de maior atenção proibia cron citando MOAT W7 — **re-afirmando o não-sequitur** que o Elenxo citado pelo nó vizinho derrubou por medição, para excluir o candidato que aquela refutação chamou de *"resposta proporcional"* | 🔴 | **curado** — re-medi: zero menções a cron em `evolve.md`, **duas** entradas MOAT no registry (ambas de deploy). O (d) está na mesa |
| **R3** | *"32 dias sem rodar"* são **65** (07-30 → 10-03). O 32 era de 2026-08-31 | 🔴 | **curado** nos dois lugares |
| **R4+R5** | A lição foi para a migalha e **não** para `forge.md:28` (12 de 59) nem `onion-research/SKILL.md:23` (40 de 298). E minha cura **piorou** o segundo: um zero falso e **barulhento** virou um quarenta **quieto** e igualmente falso | 🔴 | **curado** — `forge.md` serve 59/59; o `kg-corpus-grep` ganhou `--top N` que **declara**, e a skill usa isso em vez de `head` |
| **R6** | A busca-frase morreu sem escotilha: `'o maestro'` passou de **396** nós precisos a **4114** | 🔴 | **curado** — `--phrase` restaurou os 396, e o aviso agora diz que separar **AMPLIA** |
| R7 | O aviso em stderr quebrava `--json` sob `2>&1` | 🟠 | **curado** — e a 1ª tentativa falhou: testar `JSON` no parse amarra à **ordem dos flags**. Buffer + emissor decide |
| R8 | Citação vestida de verbatim que não era: *"do eixo E2"* → *"no eixo da auto-evolução"*, *"loop"* → *"laço"* — substituição de conteúdo **dentro das aspas** | 🟠 | **curado** — verbatim, com o gloss fora |
| R9 | `FORGE_CENSUS_TOP=abc` → tabela vazia e **rc=0** | 🟡 | **curado** — recusa com rc=3 |
| R10 | A extração do `_tot` estava fora de `if` sob `set -euo pipefail`: **matava a suíte** em vez de reprovar o caso | 🟡 | **curado** |
| R11 | A **classe** segue sem guarda | 🟠 | **registrada** como 4º candidato (passivo = **zero**), gated no selo |
| R13 | Frase órfã na edição da migalha | 🟡 | **curada** |
| R14 | O caso (c) não cobrava o que importa (o zero virar achado) | 🟡 | **curado** — asserção `1 nó(s)` |

## Bancada: 8 casos, 8 mutantes

`run_silent_measurer_selftests` — (a) corte declarado · (b) **contraprova** (completa não avisa) ·
(c) frase separada **e o zero virou achado** · (d) zero explicado · (e) `--phrase` restringe e
separado amplia · (f) `--json` válido nas **duas ordens de flag** · (g) `--top` declara, cala e
recusa inválido · (h) ausente-do-disco com rótulo próprio.

M1–M8 mordem **exatamente** o seu caso, e os artefatos voltam **byte-idênticos** por `cmp` depois
de cada um.

## Dois defeitos meus no próprio conserto, porque são classe

1. **O caso (h) nasceu com `git archive HEAD`** — testaria o `forge-census` **commitado**, não o
   curado. Peguei antes de aplicar. A separação certa: a **população** vem do HEAD (é dado), o **SUT**
   vem da árvore viva.
2. **A cura do R7 falhou na 1ª tentativa por ordem de flag** — `'frase' --json` tem `JSON=0` na
   linha do parse. Decidir no parse amarra o comportamento à ordem; quem decide é o emissor, depois
   de todos os flags lidos.

## 2ª leva nesta branch — a guarda da REGRA 96, forjada PELA SUPERFÍCIE

O achado **R11** (a classe sem guarda) deixou de ser candidato: o maestro selou em 2026-10-04 e a
guarda foi forjada invocando `/meta:forge-guard` — **não à mão**. E isso importa, porque eu estava
escrevendo o predicado como função embutida no `lint-artifacts.sh`, que **não é o molde desta casa**;
o maestro interrompeu com *"dogfood use a forja"*, e invocar devolveu a forma certa em uma leitura.

**Três defeitos que só o dogfood acharia**, e o 1º é o mais grave: a guarda de **vacuidade era
inalcançável exatamente na situação para a qual existe** — `xargs grep -l` devolve 123 sem casamento
e, sob `set -euo pipefail`, isso matava o script antes de ela falar; pior, deixava o caso (c) **verde
pelo motivo errado**. O 2º: o sandbox do caso (c) nascera sem diretiva nenhuma, então a vacuidade
disparava antes do varredor e o caso era **incapaz de reprovar o que afirmava**. O 3º: o regex do
`sed -n 1,Np` não capturava a aspa de fechamento.

**E o gate achou um quarto que eu não vi:** a **REGRA 59 (Modo que a produção consome é exercitado
pela bancada)** acusou `MODO-SEM-TESTE [--tsv]` **com o caso existindo e passando** — porque eu
invocava por variável (`${chk}`) e o extrator casa pelo **nome do arquivo**. O modo estava coberto de
fato e **invisível ao medidor**, que para a regra é o mesmo que descoberto.

**Extensão de doutrina:** *"o mutante não mordeu"* tem **quatro** causas, não duas — além de caso
decorativo e mutante que não muda o afirmado, apareceram **mutante inerte** (não alterou o arquivo) e
**mutante fraco** (alterou o arquivo, não o comportamento: `printf '%s'` sem `\n` faz o `while read`
nunca executar o corpo). O harness agora **prova que mutou** antes de interpretar.

**E a classe se manifestou contra mim dentro da forja que a combate:** ao perguntar ao censo *"a
classe já está coberta?"*, rodei `guard-census.sh --markdown | head -14` — e o bloco que responde
isso mora na l.94. Meu próprio corte escondeu a resposta.

Verificado: `--selftest` **14/14** · família `run_injected_cut_selftests` **4/4** · **6 mutantes**
mordendo com prova de mutação · produção **rc=0** · censo confirmando registro nos **dois** lugares ·
`kg-radar` exit 0 nos dois grafos · as três projeções da catraca regeneradas.

### O veredito do 2º Elenxo (mandato: caçar FALSO POSITIVO) — **REPROVADO**, e os dois piores eram fatais

7 classes de falso positivo, 11 formas de truncar não declaradas, 5 achados de 1ª classe.

| # | Achado | Estado |
|---|---|---|
| **FP-1** | A guarda **proibia documentar a própria regra**: ele acrescentou ao `/meta:forge-guard` a seção que qualquer autor de doutrina escreveria e o lint **real** foi a `HARD:1/FALHOU`. A saída era `--no-verify` — a cláusula 4 realizada contra o próprio artefato | **curado**: diretiva **viva** ≠ **citada** (cerca, crase dupla, comentário, padrão entre aspas). Re-verificado ponta-a-ponta: guarda cala **e** lint 0 HARD com a documentação presente |
| **Achado A** | O dispatcher invoca `--tsv 2>/dev/null \|\| true`, então o fail-loud **nunca chegava ao lint**. Eu o escrevi, provei no CLI, mutei contra ele — e o consumidor o anulava. **Em produção a guarda já era fail-open ali** | **curado**: fail-loud em TSV por **stdout**. E ele não podia viver dentro de `$(_scan)`, onde `exit 2` encerra só o subshell: sentinela no varredor, decisão no chamador |
| **FN-B** | O predicado exigia `\|` **literal**, então `head -40 arquivo` era invisível e `sed -n 1,40p arquivo` — a redação **usual** — passava | **curado**: pipe deixa de ser obrigatório; entram `-n40`, `--lines=`, `awk NR<=N`, `grep -m N`, `sed Nq` |
| **FN-A** | A isenção `N<=2` é **sintática** e o teto afirmava o contrário: no mesmo cortador, `\| head -1` apaga **297 de 298** e passa calado | **declarado** em vez de disfarçado — fechar exige discriminante do **produtor**, e é leva própria |
| **FP-6** | Corte que **é a pergunta** (top-N) era vetado | **curado** por marcador **explícito** `# top-N`, não por heurística: adivinhar pelo pipeline isentaria `forge-census \| sort \| head -12`, que é o dano original |

**E a bancada achou o que o Elenxo não viu:** `printf \| grep -q` na guarda é a classe **EPIPE do
early-closer** — sítio novo acima da catraca, curado com here-string. Mais `role-cut: (k)`, que cobra
que todo comando citado por uma guarda **viaje para o adotante**, senão ele colhe a violação sem ter
o comando da cura.

**Duas afirmações minhas, corrigidas nos grafos:** os mutantes eram **5/6**, não 6/6 — o M4 era
**no-op semântico**, e é instância da **4ª causa que o meu próprio nó havia acabado de nomear**, com
o `verified_against` descrevendo uma medição que não aconteceu. E o gatilho do
`Q_SEGUNDA_SUPERFICIE` **já havia disparado** no mesmo dia em que o declarei não-disparado:
`plugins/onion/skills/onion/SKILL.md:21` tem diretiva **viva** com corte, no arquivo que os
adotantes **instalam**.

**E duas curas minhas se anularam no caminho:** a de *"padrão entre aspas é dado"* comia o argumento
legítimo do `sed -n '1,40p'`. Duas curas certas que se anulam é pior que uma errada, porque o sintoma
aponta para o lugar errado.

**Pós-cura:** `--selftest` **18/18** · **10 mutantes, 10 mordendo** (o M4 agora ataca o **mecanismo**,
porque os dois filtros são redundantes, e isso fica declarado) · produção **rc=0** · 44 casos nas 6
famílias afetadas, 0 falhas.

## Teto declarado

Os dois nós sobre o harness de mutantes (`C_TERCEIRA_CAUSA_DE_MUTANTE_QUE_NAO_MORDE` e
`E_REPLACE_PRIMEIRO_ACERTOU_O_COMENTARIO`) descrevem um script que **não viaja no repo** — o Elenxo
os marcou **NÃO-VERIFICADOS** com razão. A lição é real (o harness dele, independente, ancorou no
prefixo justamente por isso), mas enquanto o molde de harness não for versionado, ela se sustenta em
declaração minha sobre código descartado. Fica nomeado em vez de resolvido.
