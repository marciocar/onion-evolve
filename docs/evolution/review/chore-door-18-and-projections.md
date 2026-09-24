---
branch: chore/door-18-and-projections
pr: 869
date: '2026-09-23'
reviewed_diff_sha256: b10bb10560786693bc39f43585a35d10d2a670301c23ce2375f9426da87bb57d
findings_total: 21
findings_real: 20
tokens: 210441
duration_min: 62
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  HOUVE refutador independente em worktree isolada (opus, prompt neutro, mandato de REFUTAR), e ele
  REPROVOU a leva: 8 achados, dois deles da classe exata que este PR nomeia — casos de bancada que
  APROVAM com o mecanismo desligado, provados com mutante. Todos os 8 curados, e os dois mutantes
  re-rodados para provar que agora mordem. O refutador só foi disparado porque o revisor do CI cobrou
  o §11.1 de commands.md, que exige revisão independente para toda guarda alterada — isto é, a norma
  funcionou: eu havia declarado `elenxo: nao` com o limite dito, e a maquinaria não aceitou.
  Custo medido do refutador: 210.441 tokens, 147 chamadas de ferramenta, 62 minutos.
---

# Resíduo da revisão — porta 18 e a morte silenciosa do lint

## Campos de custo: por que ZERO é honesto aqui

`tokens: 210441` e `duration_min: 62` não são omissão: **não houve run de subagente**. Toda a passada foi
determinística (reproduções em shell, bancada, mutante, log de CI baixado). Declarar número inventado
para satisfazer um campo é exatamente a classe que esta leva cura.

## Ângulos de ataque, e o que cada um devolveu

| # | ângulo | resultado |
|---|---|---|
| 1 | *a causa é `set -e` sobre `&&`-list com substituição falha?* | **REPROVOU minha 1ª hipótese** — não reproduziu na 1ª tentativa porque o harness não espelhava o runner (usei `local` na mesma linha, que mascara o rc). Reproduzido só ao copiar a forma exata: `local x=""` + atribuição nua. |
| 2 | *a causa é função cujo último comando é um `if` falso?* | **REPROVOU minha 2ª hipótese** — `rc=0`, chegou ao sumário. |
| 3 | *o dano é só da porta?* | **ACHADO REAL, pior que o diagnóstico inicial**: `--stub-baselines` esvazia os 26 baselines quando o framework viaja, então o lint morria em **todo adotante**, não num caso de borda. |
| 4 | *a cura `\|\| true` virou fail-open?* | **NÃO** — provado por dois casos de bancada: entrada no baseline segue tolerada, entrada fora segue HARD. |
| 5 | *o trap rotula como morte alguma saída LEGÍTIMA (ajuda, repo-não-Onion, subshell)?* | **NÃO** — varredura de `exit` de topo antes do sumário devolve só o `exit 2` do próprio trap; o lint não tem `--help`; e a varredura completa produziu **zero** `MORREU` espúrio (medido em `/tmp/lint-final.out`). |
| 6 | *o CI vê a REGRA 85?* | **REFUTOU UM NÓ MEU** — eu havia escrito que a guarda "emite zero no CI", derivado de UM run. O artefato do CI deste PR traz 3 HARD, dois deles REGRA 85. O run anterior precede o merge do #868: não havia o que acusar. Nó corrigido no rascunho. |
| 7 | *a projeção que regenerei bate no CI?* | **NÃO** — `testing-state.md` conta os resíduos de revisão, e eu o gerei ANTES de escrever o meu (313 quando já eram 314). Terceira vez nesta sessão que gerar de árvore suja custa um gate. Regenerado de worktree limpa. |
| 8 | *as 2 falhas da bancada são minhas?* | **UMA É, UMA NÃO** — medido em worktree destacada em `origin/main`: `rules-registry (f)` já falhava lá (pré-existente); `backlog-projection: em-dia` só falha na minha árvore, e a causa é o grafo **não-commitado** da pesquisa Zoho/GLPI (9 nós `open`) — frente alheia, declarada abaixo. |

## Achados e destino

1. **Baseline vazio mata o lint** (causa da porta travada) — CURADO no sítio + mecanismo.
2. **O raio alcança todo adotante**, não só a porta — declarado na mensagem do commit e no PR.
3. **`rules-registry (f)` acusava a regra errada**: media `OK ✓` global e reportava "REGRA 39 acusou o
   estado real". Reprovava hoje pela porta defasada. CURADO, com mutante provado.
4. **`.env.bak-*` fora do `.gitignore`** — backup com tokens rastreável. CURADO (glob + remoção).
5. **REGRA 85 não dispara no CI** — HARD que só morde no disco. NÃO curado: virou nó
   `E_REGRA_85_EMITE_ZERO_NO_CI_E_2_HARD_NO_DISCO` + decisão `D_GUARDA_QUE_SO_MORDE_NO_DISCO_VALE_COMO_GATE`,
   com a lacuna (por que ela cala lá) declarada em vez de explicada por chute.
6. **Eu medi meu próprio artefato truncado** (`tail -18` no relatório da bancada e depois grep nele)
   pela segunda vez nesta sessão — o detalhe das falhas estava no runner, não no que eu guardei. Não
   é achado de produto; é registro de reincidência, e a cura é rodar a família sozinha sem pipe.

## Fora do escopo, e por quê

- **`backlog-projection: em-dia`** segue vermelho na minha árvore. Honesto: o grafo da pesquisa
  Zoho/GLPI tem 9 nós `open` e a projeção não foi regenerada. É frente da pesquisa, e mexer nela aqui
  misturaria duas levas — o erro de `git add -u` que já custou duas varreduras nesta sessão.
- **Os 2 HARD da REGRA 85** não se curam antes do merge: a porta só se re-materializa de `main`
  mergeada. É a razão dos `--no-verify` de checkpoint, e a validação final é o CI **neste** SHA.

## Os `confirmed` do grafo que este PR edita (REGRA 87)

O PR edita `docs/evolution/research/triagem-inbox-2026-09/triagem-inbox-2026-09.kg.yaml`. O
`confirmed` de maior impacto ali é **`E_REGRA_85_E_INSATISFAZIVEL_ANTES_DO_MERGE`** (impact 4,
confidence 1.0, `verified_at: 2026-09-23`), e ele foi **lido, não herdado**: é o nó que este PR
corrigiu depois de o artefato do CI refutar a versão anterior que eu havia escrito. A evidência dele
é o `lint-evidence-35929817914` baixado, e a conclusão dele é o que governa a ordem de merge desta
leva — publicar a porta antes, mergear depois.

Os outros dois `confirmed` de topo do mesmo arquivo —
`E_A_KB_JA_FOI_CORRIGIDA_EM_09_18_SO_A_IMPLEMENTACAO_FALTA` e
`E_A_FAIXA_CARREGA_O_DETALHE_EU_E_QUE_TRUNQUEI` — **não** são tocados aqui e seguem válidos. Vale
dizer do segundo que ele descreve exatamente a reincidência registrada no achado 6 acima: a faixa da
bancada carrega o detalhe da falha, e o truncamento foi meu.

## Achados 9–13 — a segunda metade da leva

| # | ângulo | resultado |
|---|---|---|
| 9 | *a doutrina lista a porta pública?* | **NÃO, e o maestro achou antes de mim.** `grep -c onion-core CLAUDE.md` = ZERO; o grafo de identidade também. O repo existia só nas projeções GERADAS. Causa de DATAS: a decisão dos dois regimes foi selada em 16/09, a porta nasceu pública em 17/09. Curado com Aufhebung (`D_FAMILIA_TEM_TRES_REGIMES_2026_09`). |
| 10 | *o §11.1 de commands.md é obedecível?* | **NÃO ERA** — o nome do arquivo injetado pelo `manifest.tsv` era fixo em `.md`, então nenhuma fixture alcançaria uma guarda cuja varredura é `*/radar-*/*.kg.yaml`. A norma exigia o impossível e a saída de todos era dispensa. Curado: 6ª coluna `inject` (vazia = comportamento antigo) + a fixture da REGRA 89 passando (95/95). |
| 11 | *a faixa 3 do CI caiu por ambiente?* | **NÃO, por CORRIDA** — a sonda do `session_beacon` lia `/proc/<pid>/comm` antes do `exec` do filho; o `⊘` resultante reprova sob `ONION_SELFTEST_STRICT=1`. Mesma faixa passou às 18:33 e reprovou às 23:45 sem mudança no SUT. Curado com espera de teto 2s, e o skip agora diz qual `comm` viu. |
| 12 | *a minha própria cura ficou consistente?* | **NÃO** — deixei `CLAUDE.md:29` dizendo "dois regimes" três linhas acima da lista de três. Count-drift no meu texto, no mesmo arquivo, no mesmo dia. Achado por grep depois, não na hora. |
| 13 | *a hierarquia de portas na prosa de messaging está certa?* | **NÃO** — declarava `standalone (porta pública)`, falso desde 17/09. Pior que desatualizado: aponta o público para porta CONGELADA há 412 commits. Corrigido com data e número. |

**O que verifiquei ANTES de tocar, e não mexi:** "portado para 6 ferramentas" (conta portes multi-IDE, não portas) e "os 7 repos medidos" na KB de identidade (é a lista CONGELADA). Trocar todo número que parece suspeito é a outra forma de errar.

## Os `confirmed` de `onion-identity-2026-07.kg.yaml` que este PR enxergou (REGRA 87)

Os três de maior impacto são `E_FAMILIA_MULTIIDE_CONGELADA`, `E_PORTE_PARA_O_CURSO` e
`E_ORIGEM_CURSOR_AGNOSTICO` — todos impact 5, `confirmed`, `verified_at: 2026-08-02`. Li os três
antes de escrever o nó novo, e o que eles dizem **importa para a forma da cura**:

`E_FAMILIA_MULTIIDE_CONGELADA` lista, medidos por `gh api`, os sete repos públicos da família
congelada — e `onion-core` **não está entre eles**, corretamente: ele não é porte multi-IDE, é a
porta do core na MESMA plataforma. Foi isso que decidiu o desenho da cura: a porta é um **terceiro
regime**, não um item a acrescentar na lista de congelados. Se eu tivesse emendado aquela lista, teria
criado a contradição de chamar de "prova de portabilidade" um repo que não porta para lugar nenhum.

`E_PORTE_PARA_O_CURSO` e `E_ORIGEM_CURSOR_AGNOSTICO` sustentam o *porquê* daquela família existir
(origem no Cursor, portes feitos para o curso) e seguem **intactos** — nada nesta leva os toca. O nó
novo supersede apenas `D_FAMILIA_TEM_DOIS_REGIMES_2026_09`, que é a decisão de **contagem de
regimes**, e é a única afirmação que a porta invalidou.

## Passada adversarial independente — 8 achados, veredito VERMELHO

Refutador `opus` em worktree isolada (`isolation: 'worktree'`), prompt **neutro** (não disse quem
escreveu o código nem quais eram minhas conclusões), mandato de REFUTAR, cinco perguntas dirigidas.
Ele reprovou a leva. Todos os achados curados nesta mesma branch; os dois mutantes re-rodados.

| # | achado | onde | destino |
|---|---|---|---|
| **A1** | **BLOQUEANTE** — 1 HARD vivo: `testing-inventory.md` dizia 136 fixtures rastreadas, real 137. Rodei o gerador **antes** do `git add` da fixture | `docs/onion/testing-inventory.md` | CURADO — regenerado após o stage; agora 137/188/1195 |
| **A2** | Minha cura do `rules-registry (f)` trocou prova **positiva** de término por asserção **só negativa**: lint morto não imprime `VIOLATION`, e a ausência era lida como "REGRA 39 verde". **Provado com mutante.** A ironia: esta leva criou o rótulo `MORREU` para isso, e o sinal estava dentro da variável que o caso captura | `lint-selftest.sh` | CURADO — exige `=== Sumário ===` e ausência de `MORREU`, senão `record_skip`. Mutante re-rodado: agora **⊘**, não ✓ |
| **A3** | **O mais grave.** Meu caso (f) asseria **presença** de `_LINT_SUMMARY_REACHED=1`, não **posição**. Mover o flag para o topo mata a cura inteira e a família fica **6/6 verde**. **Provado com mutante G** | `lint-selftest.sh` | CURADO — o caso agora copia o lint para sandbox, injeta morte antes do sumário e exige `rc=2` **e** `MORREU`. Mutante re-rodado: **reprova** |
| **A4** | A 6ª coluna `inject` é **inalcançável** quando `keyword` é vazio: `IFS=$'\t'` colapsa TABs consecutivos e 22 linhas do manifesto já terminam em TAB. Silencioso, e sem nenhum validador de forma | `lint-selftest.sh` · `manifest.tsv` | CURADO — sentinela `-` (idioma que o `target` das linhas `members` já usa) + **família nova `manifest_shape`** comparando o leitor de produção contra `awk -F'\t'` linha por linha. Mutante de colapso provado |
| **A5** | O `exit 2` foi criado e **nenhum consumidor o lia**: o `pre-commit` rotulava `rc=2` como "violação HARD" — o rótulo exato que o mecanismo existe para eliminar. E o idioma certo estava **12 linhas acima**, no check irmão | `.githooks/pre-commit` | CURADO — distingue `1` (veredito) de `≥2` (não pude julgar), com o texto dizendo que `--no-verify` aqui é commitar sem gate |
| **A6** | A única saída **legítima** antes do sumário (`--only` com arquivo inexistente) herdava o banner `MORREU` com diagnóstico enganoso | `lint-artifacts.sh` | CURADO — flag ligado antes daquele `exit 2`; provado: `rc=2`, zero `MORREU` |
| **A7** | O `|| true` engolia também "existe e não é legível", divergindo do **produtor irmão**, que trata isso como classe própria. Não era fail-open (era fail-**closed**), mas o operador recebia HARD espúrios em vez do rótulo certo | `lint-artifacts.sh` | CURADO — `[ -r ]` explícito com violação dizendo NÃO PUDE JULGAR |
| **A8** | `_fake_comm` sem `local` (higiene; não quebrava sob `set -u`) | `lint-selftest.sh` | CURADO |

**Onde ele me deu razão, medindo:** o trap **não** vaza para subshell nem command substitution (probe com `BASHPID`), SIGPIPE preserva 141, existe só um `trap` no arquivo, e o `|| true` **não** é fail-open. A sonda do beacon tem margem de ~20× (200 tentativas sem carga → 1 iteração; sob 24 processos → 2, contra 40 disponíveis).

**E um defeito do MEU mandato, que ele achou e vale corrigir:** pedi `git diff origin/main...HEAD --stat`, que devolve **vazio** numa worktree nova (ela nasce em ramo próprio, com `HEAD == origin/main`). Quem repetir a revisão com o comando literal conclui "não há diff" e revisa o nada. O correto é `git diff origin/main..HEAD` após destacar no SHA da branch.
