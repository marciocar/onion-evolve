---
branch: fix/members-role-drift-doors
reviewed_diff_sha256: 93d3ad3872cca3151e131ca124193c0d1ae7733af09f7820db1e6bb773409f11
elenxo: sim
verdict: REPROVADO_E_CURADO
findings_total: 19
findings_real: 18
tokens: 255992
duration_min: 55
nota: "refutador opus/high em worktree isolada, mandato REFUTAR, default REPROVADO. 5 bloqueantes, 6 importantes, 8 menores; 18 confirmados por medicao propria e curados neste PR; 1 (o nucleo factual de B5) DERRUBADO por medicao. A bancada saiu de 7 para 15 casos por cobranca dele."
---

# Resíduo da passada adversarial — REGRA 92 e a recusa no materializador

Refutador `opus`, mandato **REFUTAR**, default **REPROVADO na dúvida**, em **worktree isolada**
(`isolation: 'worktree'`) — fronteira, não disciplina. Veredito dele: **REPROVADO**, e estava certo.

## Os cinco bloqueantes

| # | achado | o que eu fiz |
|---|---|---|
| **B1** | a bancada **abortava em exit 127**: `_family run_glob_branch_parity_selftests_family run_glob_branch_parity_selftests` chamava função inexistente, e por estar ANTES do registro da família nova, a própria família nunca rodava numa passada cheia | curado; eu havia achado em paralelo. É a **mesma classe** que corrigi horas antes no `forge`, no mesmo dia — registro malformado `X_family X` |
| **B2** | **2 HARD** da REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente): eu citei o slug de um adotante no SUT e na bancada, e `.claude/validation` é raiz de scrub declarada | generalizado. A ironia é medível: a entrada citada carrega no próprio registro o aviso de que o identificador é o que vai para as superfícies projetadas — **citei a lição e a violei no mesmo movimento** |
| **B3** | inserir o docstring da REGRA 92 **entre** o docstring da REGRA 85 (Porta pública espelha o core, com catraca) e a função dela fez a 85 perder a severidade derivada (`HARD + SOFT` → `HARD`), e eu **regenerei a projeção por cima da mentira** — catraca verde | bloco movido para depois de `check_door_staleness()`; severidade restaurada e verificada no gerador. É o defeito já documentado em 2026-08-03 (docstring longe da função publica severidade alheia), repetido |
| **B4** | minha justificativa era **factualmente falsa**: `ops/materialize-door.sh` **nunca** lê o `members.yaml` — `ROLE` é argumento com default `hub`. Logo nenhum lint de PR fica entre o operador e o comando que causou o dano | frase corrigida **e** a cura de raiz implantada: o materializador recusa (`rc=2`) quando `--role` contradiz o carimbo do destino, com `--force-role-change` para a troca deliberada. 4 casos de bancada |
| **B5** | `role: hub` gravou `onion-core tier hub` nas projeções, sem sub-adotado | **núcleo factual DERRUBADO por medição**: o vocabulário de tier é de CAPACIDADE (`members.yaml:73` anota `hub` como "central; **pode** ter sub-adotados") e um membro `hub` tem zero sub-adotados de fato. A parte que sobrevive — um campo com dois usos — ficou como nó aberto no grafo |

## Os que mudaram o motor

O refutador derrubou a extração por **regex** com quatro entradas YAML-legais: `kind: "door"` fazia a
porta **desaparecer** e a guarda então **afirmava** "nenhuma porta no registro" (afirmação falsa é pior
que erro); aspas no `role` davam falso `PAPEL-DIVERGE`; `\s` casa `\n`, então um `role:` aninhado em
`trust:` era lido como o da porta; e comentário inline entrava no valor. Raiz: o repo **já** lê este
arquivo com `yaml.safe_load` (`members-validate.sh`) — a regex era um **terceiro** leitor, menos fiel,
exatamente contra o que a guarda pregava em comentário. Motor reescrito com YAML de verdade.

Também dele: o mutante `-d`→`-f` **sobrevivia** aos 7 casos originais, porque nenhum variava a FORMA
do `local_path`; o caso novo distingue "clone ausente (CI)" de "clone presente SEM carimbo" (porta
quebrada, não caso de CI) e mata o mutante. E o HARD não tinha caminho para a troca *intencional* de
papel a não ser `--no-verify`; agora tem: materializa com `--force-role-change` pós-merge, e o PR
seguinte alinha o registro.

## O que ficou ABERTO, com gatilho nomeado

- **O teto da paridade**: ela é cega a "ambas as fontes erradas do mesmo modo" — se alguém alinhar a
  fonte errada, a guarda fica verde com a porta mutilada. O sucessor mede o **conteúdo** da porta
  contra o corte (`vendor-manifest.sh --role` discrimina as portas reais). Nó `Q_PREDICADO_SUCESSOR`.
  **Gatilho**: uma porta aparecer mutilada com a paridade verde.
- **O campo `role:` com dois usos** (tier na projeção, corte de papel na materialização). Nas portas
  convergem por capacidade; o nome único segue sendo dívida. Nó `Q_ROLE_DUPLA_LEITURA`.
- **A doutrina não lista `onion-core`**: a tabela de `public-door-vs-private-core.md` é de 2026-07 e a
  porta nasceu pública em 2026-09-17 — a mesma defasagem de datas que o CLAUDE.md já denuncia para
  `onion-codex` e `onion-core`. A mensagem HARD aponta para lá, então o ponteiro é parcial.

## Defeitos meus de MÉTODO nesta rodada, além dos de código

- **Medir enquanto escrevo produz estado que não existiu**: rodar lint e bancada em paralelo gerou um
  HARD **fantasma** (fixture transitória de plugin que o lint viu no meio da corrida e já não existe) e
  uma falha fantasma de `backlog-projection` (regenerei a projeção durante a bancada). Ambos verdes
  quando medidos em sequência.
- **`| tail` num comando de background mata a bancada por sinal**: `exit 144`, e a própria guarda dela
  acusa "ABORTOU ANTES DA SOMA". Sem pipe, mesma árvore: 1529 ✓ / 0 ✗. Medir em background exige
  redirecionar para arquivo.
- **Transcrevi texto de âncora de memória** em vez de derivar do arquivo, e dois `assert` falharam por
  indentação — a mesma lição de citar linha por `grep`, aplicada a edição.
- **`pgrep -f` casa o próprio shell** que o roda: escrevi um laço de espera que travaria para sempre, e
  a guarda de shell o barrou antes.

## Gates no SHA final

- lint: **0 HARD**, 14 SOFT (todos passivos conhecidos com catraca ou declarações de não-medido)
- bancada completa: **1529 ✓ / 0 ✗** em 820s, com o flaky `radar-staleness (f)` incluído; depois
  **1536 ✓** com as 15 novas, e **23/23** nas famílias tocadas medidas isoladas
- radar do grafo: exit 0 (8 nós, 7 arestas)
- mutação: mutante plausível morto pelo caso que o refutador provou faltar
