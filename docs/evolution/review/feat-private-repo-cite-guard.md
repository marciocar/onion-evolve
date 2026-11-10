---
branch: feat/private-repo-cite-guard
pr: pendente
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 6
findings_blocking: 1
tokens: 0
duration_min: 60
findings_fixed: 5
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente; o brief proibiu subagente)
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
