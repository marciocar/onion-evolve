---
description: >
  Conduz o maestro a PUBLICAR uma porta do Onion — onion-plugins (o marketplace de plugins),
  onion-core, onion-standalone ou onion-mini — pelo /meta:publish: ensaio a partir de origin/main,
  verificação do bundle, confirmação, push e conferência no remoto. Ative quando o maestro quer
  publicar/gerar o marketplace de plugins ou atualizar uma porta pública (ex.: "publica o
  marketplace", "gera o repo de plugins", "materializa o onion-plugins", "atualiza a onion-core",
  "as portas estão em dia?"), mesmo sem dizer "publish". NÃO é adoção (/meta:adopt vendoriza num
  projeto; isto é o canal de distribuição). Só roda na FONTE (role: source).
allowed-tools: AskUserQuestion Read Bash(bash ops/publish-door.sh*) Bash(bash .claude/validation/onion-version.sh*)
---

# Onion Publish — a condução da publicação das portas

Front-end conversacional do [`/meta:publish`](../../commands/meta/publish.md). Colhe a intenção e
roteia para o **motor determinístico** `ops/publish-door.sh`. Nunca reimplementa o que o motor faz.
A doutrina (fonte em `origin/main`, verificação do montado, papel divergente recusa, push confirmado,
selo no carimbo) vive em [`common:prompts:publish-doctrine`](../../commands/common/prompts/publish-doctrine.md).

> **Mudou em 2026-10-10 (F3 das portas, SAC-92).** Esta skill chamava o
> `materialize-marketplace-repo.sh` direto, e ele montava os plugins da **árvore de trabalho** de quem
> rodava: publicar de uma branch de PR levaria código não mergeado ao repo público. Agora todo caminho
> passa pelo motor, que materializa a partir de uma worktree em `origin/main`. Pela matriz
> (`D_MATRIZ_DE_PORTAS_2026_10`), os plugins levam a **meta-fábrica**; o que não viaja é adoção,
> federação e grafo privado.

## A lei (o que esta skill NÃO faz)

- **Não empurra sem o "sim" do maestro.** O `--push` só é passado depois de uma AskUserQuestion
  explícita (I3: um escritor por repo).
- **Não publica fora da fonte.** Verifique `bash .claude/validation/onion-version.sh | grep '^role:'`.
  Se não for `source`, pare e explique que publicar portas é ato do core.

## O fluxo

1. **Status.** `bash ops/publish-door.sh --status` mostra a defasagem de cada porta, lida do remoto.
2. **Alvo.** Pergunte qual porta (ou `--all`), se o maestro não disse.
3. **Ensaio.** `bash ops/publish-door.sh <porta>`. Leia cada etapa: rc 1 é verificação reprovada
   (mostre o achado e pare), rc 2 é recusa, rc 3 é fonte irresolúvel.
4. **Confirmação** (AskUserQuestion): porta, papel, pin, resumo do commit ensaiado. Opções:
   publicar · parar.
5. **Publicação.** `bash ops/publish-door.sh <porta> --push --expect-pin <pin do ensaio>` (a main que andou desde o ensaio recusa), e confira com `--status`.
   Para os plugins, quem instala usa `/plugin marketplace add marciocar/onion-plugins` +
   `/plugin install onion@onion-plugins`.

## Referências

- Superfície: [`/meta:publish`](../../commands/meta/publish.md) · motor: `ops/publish-door.sh`
- Materializador de plugins: `.claude/utils/marketplace/materialize-marketplace-repo.sh`
- Guarda de moat: REGRA 61 (Fronteira de MOAT: manifesto de plugin publicável não vaza adoção, federação nem grafo privado), em `lint-artifacts.sh`
- Grafos: `docs/onion/graph/onion-plugin-publication-2026-08.kg.yaml` ·
  `docs/onion/graph/door-role-parity-2026-09.kg.yaml`
