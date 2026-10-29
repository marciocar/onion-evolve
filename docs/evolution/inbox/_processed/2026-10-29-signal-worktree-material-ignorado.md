---
title: "Sinal de campo: três atritos de worktree com material ignorado e caminho absoluto"
date: 2026-10-29
type: signal
from: adotante sem registro (role: adopted, pin 6c4272252528), recebido por mensagem entre sessões
to: onion-evolve (core)
reviewed_for_public: true  # transcrito pelo core sem conteúdo do cliente nem nome do adotante
status: open
---

# Três atritos de worktree, medidos num adotante em 2026-10-29

A sessão do adotante mandou por SendMessage e não commitou nada no core (I3, um escritor por repo). O core
transcreveu o sinal sem o nome do adotante.

1. **`core.hooksPath` absoluto.** O `session-currency-check.sh` avisou `<raiz>/.githooks`. Com isso, toda
   worktree roda o pre-commit do checkout principal, e um PR que mexe no pre-commit não se prova sozinho. A
   causa provável é a criação de worktree de agente pelo harness. O adotante corrigiu com
   `git config core.hooksPath .githooks`. **Pedido:** reescrever para relativo de forma automática, no
   `install-onion-githook.sh` ou num check de sessão, e não só avisar. O core sofre o mesmo atrito: a
   correção à mão é rotina.
2. **`meeting-graph-check.sh` reprova com FONTE-FORA-DA-RAIZ em worktree.** O material do cliente fica num
   diretório gitignored e não existe na worktree. O symlink para o checkout principal sai da raiz pelo
   realpath. O contorno foi `--root <checkout principal>`. **Pedido:** aceitar a fonte ignorada pela raiz do
   worktree principal (`git rev-parse --git-common-dir`/..), ou documentar o `--root` para esse caso.
3. **A regra `dir/` do .gitignore não cobre um symlink de mesmo nome.** O symlink é arquivo, então aparece
   untracked, e um `git add -A` o commitaria. O contorno foi `.git/info/exclude`. **Pedido:** a doutrina
   client-material recomendar a regra sem barra final (`_material`), ou as duas formas. O
   `/meta:adopt` do core gerou `_material/` com barra nesse adotante.

4. **A REGRA 55 (trace aponta para alvo que existe) barra todo grafo de reunião cujo material está ignorado.**
   O `/product:extract-meeting` grava `trace: <pasta-ignorada>/transcricao.md#Lx`, e o `kg-trace.sh` dá
   `integrity.trace-target-missing` em cada nó (20 HARD medidos). O `kg-trace.sh` só declara
   `--external-root memory/`, fixo no código. **O que o adotante fez, e propõe ao core:** o `kg-trace.sh`
   passa a ler, de forma opcional, `<raiz>/.kg-ssot/trace-external-roots.txt` (um prefixo por linha, `#`
   comenta, o mesmo parser do `trace-excludes.txt`) e soma cada prefixo como `--external-root`. Com isso o
   kg-trace saiu rc 0 e o lint com 0 HARD. **Atenção:** a mudança está num arquivo vendorizado do adotante e
   vai conflitar no próximo `--update` se o core não absorver. Sugere ainda que a adoção, ou o extract-meeting,
   crie esse arquivo quando a doutrina mandar o material para pasta ignorada.

**Decisão em aberto no adotante, levada ao maestro:** versionar ou não `docs/meetings/` (os derivados). O
CLAUDE.md do adotante manda versionar.

**Corolário:** com a guarda de isolamento de background, o material do cliente tem de ser escrito no
checkout principal, porque o arquivo ignorado some junto com a worktree. Vale a doutrina client-material
dizer isso.

Orquestrado com 🧅 Onion Evolve
