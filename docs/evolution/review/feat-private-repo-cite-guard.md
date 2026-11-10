---
branch: feat/private-repo-cite-guard
pr: 1576
date: 2026-11-10
reviewed_diff_sha256: df40417e4cdded0d2090ed62cfc756594ca45a7bd4bab573857743ea9353839f
reviewed_code_sha256: c8a8d8a37eb72ba856a7af88cf282a19d47af34db0a9348122455549686fd672
findings_total: 13
findings_real: 13
findings_blocking: 3
tokens: 0
duration_min: 120
findings_fixed: 12
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "revisão independente do PR #1576 (REJECTED, 2 bloqueios + 5 não bloqueantes), curada pelo agente de execução; antes, passada própria"
nota: "tokens 0 = não medido. Nenhum nome de repo privado entra em claro no diff: a lista guarda o nome nu por hash, o baseline guarda o repo por hash, e a bancada usa nomes inventados."
---

# Passada adversarial: `feat/private-repo-cite-guard`

## O que muda

- Nasce a REGRA 121 (Grafo novo ou tocado não cita repositório não conferível por terceiro), com o helper
  `.claude/validation/private-repo-cite-check.sh`. Ela só se aplica à fonte.
- Ela julga só os `.kg.yaml` que o diff contra o merge-base com a origin/main toca ou acrescenta, fora de vendor e
  de fixture. Citação nova de repo privado ou inalcançável sai **SOFT** (`NAO-CONFERIVEL`), como o maestro decidiu.
- A visibilidade vem da lista versionada `docs/evolution/federation/public-repos.tsv`, e o CI não consulta a rede. O
  `--verify-allowlist` reconfere a lista com `gh`, fora do CI.
- O passivo está em `docs/evolution/federation/private-repo-cite-baseline.txt`: 209 pares nó/repo, com o repo por hash. O
  número só cai. Se crescer em relação à origin/main, sai **HARD** (`CATRACA-VIOLADA`); se crescer porque a lista
  perdeu um repo no mesmo diff, sai SOFT.
- A doutrina entrou na lente `.claude/rules/kg-grammar.md`: omitir URL e hash, e escrever a classe «não conferível
  por terceiro» no `source`.
- O destino é o grafo `docs/evolution/research/guard-private-repo-cite-2026-11/`.

## Dogfood

- **Reconciliação com o kg-ssot.** No corpus da HEAD `ccd34171d`, a forma URL dá 47 pares nó/repo. É o mesmo 47 que o
  kg-ssot contou com `trace` e `narrative` (43 só em `provenance.source`). O kg-ssot deixou a forma `repo@sha` fora da
  conta; somada, o passivo vai a 209.
- **Bancada** (`--families private_repo_cite`, `LC_ALL=C`): 8 casos de produção e 21 mutantes, sendo (g) o lint real
  emitindo a REGRA 121.
- **Custo:** 0,3 s por execução.

## Achados

1. **BLOQUEANTE, curado (vocabulário).** A 1ª redação tirava o nome nu (`<repo>@<sha>` sem dono) só do
   `members.yaml`. O repo privado mais citado aparece 84 vezes assim e não está registrado, então a guarda via 2 das
   84. Agora o nome nu vem de três fontes: o registro, as URLs de dono julgado no corpus e 13 nomes medidos (`gh repo
   view`: privado ou não resolve), gravados por hash.
2. **Real, curado.** O lookbehind do `repo@sha` era redundante, porque a gula do motor já começa no token inteiro. E,
   por excluir `/`, ele calava `~/<nome>@<sha>`. Saiu, e entrou um caso que acusa essa forma, com um mutante que
   recoloca o lookbehind.
3. **Real, curado (bancada).** Dois mutantes reprovavam, mas em outro caso que não o nomeado. Tirar o `.` da fronteira
   do host derruba o caso do `gist.github.com`, porque o `docs.github.com/en/…` já cala por ter dono de terceiro. E o
   caso do comentário imprime outro rótulo. Corrigi os rótulos e conferi à mão, no mesmo arranjo.
4. **Real, curado.** Acusar todo `palavra@sha` traria ruído medido no corpus (`grafo@`, `core@`, `develop@`, `16@`),
   e a cláusula 4 da doutrina manda errar para o lado de calar. Por isso o nome nu só acusa quando vem das três
   fontes.
5. **Real, curado.** O baseline com o nome do repo em claro republicaria o que a decisão manda omitir, e a saída do CI
   de um repo público é pública. Agora baseline e tsv levam o hash; o nome só aparece com `--show-names`, local.
6. **Real, ACEITO como teto.** Repo público do dono que ainda não está na lista sai SOFT, e isso é falso positivo
   (medido com um repo público real do dono). A mensagem já dá a cura: medir com `gh repo view` e acrescentar à lista.
   Listar todos os repos públicos do dono poria na árvore nomes que não têm por que estar lá.

## Teto declarado

Repo de terceiro que fechou ou sumiu; nome nu fora das três fontes; gist, GitLab, `commit abc1234` em prosa, sha sem
nome; grafo que o diff não toca; commit e corpo de PR. O hash curto do nome se enumera (o kg-ssot mediu menos de 1 s
para 365 mil candidatos): ele não esconde o nome, só evita gravá-lo em claro. Hoje a classe «não conferível por
terceiro» é só texto; nenhum leitor do kg-ssot a imprime ainda (`C_CLASSE_NAO_CONFERIVEL_SEM_LEITOR`).

## Revisão independente (REJECTED) e as curas

A revisão independente do #1576 rejeitou a 1ª versão. Cada ponto ganhou caso de bancada e mutante; a família
`private_repo_cite` passa 46 de 46 (9 casos de produção, 30 mutantes de vocabulário, 7 de produção).

7. **BLOQUEANTE, curado (porta).** A `onion-core` tem `role: source` e `kind: door` e não leva `docs/evolution/`.
   Medido numa cópia dela com a validação da branch, o lint já dava NÃO SE APLICA à REGRA 121 (papel
   `source-door`), mas o helper chamado direto saía rc 2. E a família de bancada ficava vermelha na porta, porque lá
   `SELFTEST_ROLE` é `source` e a lista core-only não a pula. Cura: o helper reconhece `kind: door` sem a lista e diz
   NÃO SE APLICA (rc 0); o caso (b) pula visível na porta; o caso (g) tira o carimbo do sandbox; o caso novo (i)
   prova helper e lint no papel source-porta, com um mutante para cada.
8. **BLOQUEANTE, curado (vocabulário).** Passavam calados `dono/repo#N`, `-R dono/repo`, `dono/repo` nu, o nome do
   registro depois de caminho (`worktrees/<nome>@sha`, que virava dono de terceiro), `<nome> @ sha` e
   `<nome> (HEAD sha)`. Entraram a forma `ref` (dono julgado, sem URL nem sha, inclusive `dono/repo/caminho` sem
   host) e as duas formas de prosa, só para nome do registro. O passivo foi de 209 a 255 (36 `ref`).
9. **Real, curado (catraca por contagem).** Trocar uma entrada velha por uma nova mantinha o número e passava. Agora
   a catraca compara o conjunto de entradas com o do merge-base.
10. **Real, curado (rebaixe largo).** Tirar qualquer repo da lista rebaixava qualquer crescimento a SOFT. Agora só sai
    SOFT a entrada cuja citação já estava no grafo na base; citação nova é HARD mesmo com repo saindo da lista.
11. **Real, curado.** A catraca compara com o merge-base, não com a ponta da origin/main. Teto: não há mutante que
    distinga as duas nos cenários da bancada.
12. **Real, curado.** Mutantes de produção para o escopo «touched» e para a catraca (contagem, rebaixe total,
    rebaixe nenhum, rc).
13. **Real, conferido sem mudança.** Os 13 nomes guardados por hash aparecem todos em claro na árvore, no mínimo 9
    vezes cada: nenhum é segredo que o hash exporia à confirmação por dicionário.
