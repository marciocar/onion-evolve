---
paths:
  - "ops/publish-door.sh"
  - "ops/materialize-door.sh"
  - ".claude/utils/marketplace/materialize-marketplace-repo.sh"
---

# Lente de publicação: carrega quando você toca o motor ou um materializador de porta

Superfície: [`/meta:publish`](../commands/meta/publish.md). Esta lente e a doutrina seguem o comando:
o corte por papel (`vendor-manifest.sh`) as tira dos papéis que não recebem o `/meta:publish`
(standalone, plugins, mini). Até 2026-10-11 elas viajavam ao standalone, porque o baseline da REGRA 100
as citava e contava como âncora; lá o `paths:` desta lente não casa nada, e a REGRA 53 (Regra
path-scoped declara `paths:` que casa algo real) reprovava o lint da porta com 1 HARD. A citação acima
é um segundo caminho para o mesmo corte (a "lente forçada"): ela cita um comando que o papel não leva.

Você está mexendo no caminho que leva o core a um repositório **público**. A doutrina inteira vive em
um fragmento, e vale lê-lo antes de mudar qualquer linha:
`.claude/commands/common/prompts/publish-doctrine.md`.

O mínimo que não se negocia aqui:

- **A fonte é `origin/<integração>`**, numa worktree destacada, e os materializadores rodam **dela**.
  `HEAD` local, árvore de trabalho e "o disco de quem chama" são a classe que já quase publicou código
  não mergeado duas vezes (2026-09-25 no materialize-door; o motor de plugins lia a árvore até a F3).
- **Verifique o MONTADO.** Varredura de vazamento com termos **derivados** (REGRA 36 + ids `onion-*` +
  contas de máquina do registro). Uma lista de exemplos tolerados falha pelo vocabulário. Paridade de
  papel no carimbo montado, lint da porta com 0 HARD e o core intacto no fim.
- **Push só com `--push`, e conferido no remoto.** Exit 0 de `git push` é declaração; `git ls-remote`
  é a medida.
- **Nada aqui escreve no core.** O selo é o carimbo da porta, lido do remoto por `--status`. Se você
  se pegar avançando o pin no `members.yaml` por PR, é o caminho antigo voltando.
- **Bancada:** `run_publish_selftests` (mundo falso sem rede: core e porta como bare locais, e o
  materializador esboçado mora no core falso). Todo caso novo leva mutante que reprova, rodado com
  `ops/mutate-and-restore.sh`.
