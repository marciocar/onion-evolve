---
reviewed_diff_sha256: pendente
reviewed_code_sha256: 76841511127dcdcead998c564acd7f54ed63d806faae64bf5c8e983f6472fa79
findings_total: 9
findings_real: 9
findings_fixed: 4
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: refutador independente (5293ef4aa) + verificação do diferencial pela sessão principal (e0545c889)
nota: >
  O refutador independente reprovou 5293ef4aa com 3 BLOQUEIA e 6 itens de teto. Os 3 BLOQUEIA e um item
  de teto de uma linha viraram cura em e0545c889, cada um com caso que falha antes e passa depois e com
  mutante; os outros 5 ficaram declarados no cabeçalho do hook. A sessão principal verificou o
  diferencial rodando o lab.py do refutador sobre git archive e0545c889: os BLOQUEIA viraram rc 2, e
  os FURO e FP restantes são exatamente os declarados. tokens e duration_min não foram medidos (0). Depois da verificação entrou uma só mudança, na bancada: o caso (b2)
  passou a ler por here-string (o pré-voo do pr-finalize acusou `produtor | grep -q`, a classe EPIPE sob pipefail);
  o hook, o juiz e a varredura não mudaram.
---

# Guarda da escrita na memória do Claude Code e a varredura do disco

## A passada adversarial

**Refutador independente, sobre 5293ef4aa: REPROVADO.** Laboratório dele: `lab.py`, `replay.py`, `mut.sh`,
`lat.sh`, com a casa falsa, o hook real e o rc lido do processo.

| # | achado | grau | destino |
|---|---|---|---|
| 1 | link até a memória passava no caminho quente: o filtro textual "memory" saía com rc 0 antes do realpath | BLOQUEIA | **cura**: sonda de link em bash, num só realpath; casos (v-b), (v-c) e mutante |
| 2 | `"$HOME"/…`, `~/".claude/…"`, `${HOME:?}` e `${HOME:-…}` não eram reconhecidos | BLOQUEIA | **cura**: aspas fora antes de tokenizar e toda grafia de expansão; casos (xvi-g) a (xvi-i2) e mutantes |
| 3 | `open(os.path.expanduser('~/…'),'w')` com parênteses aninhados escapava | BLOQUEIA | **cura**: dois níveis de parênteses e o caminho dentro do `open` de escrita; casos (xvi-j), (xvi-k) e mutantes |
| 4 | autoMemoryDirectory com `$HOME/…` no valor não armava | teto | **cura** de uma linha (`expandvars`); caso (iv-b) e mutante |
| 5 | conteúdo fora do texto do comando (`cp`, `cat arq >>`, rsync, mv) | teto | **declarado**: a varredura do SessionStart e a REGRA 116 pegam |
| 6 | envelope dividido em duas escritas | teto | **declarado**: a varredura pega |
| 7 | grafias que o harness não produz (`summary=` antes de `teammate_id=`, `&lt;`) | teto | **declarado** |
| 8 | link criado no mesmo comando | teto | **declarado** |
| 9 | falso positivo HARD em nota que documenta o formato | teto | **declarado**: 0 em 364 notas; a mensagem do HARD orienta a reescrita |

**Verificação do diferencial, pela sessão principal, sobre `git archive e0545c889`:** o `lab.py` do
refutador deu rc 2 nos três BLOQUEIA (link existente no Write e no Bash, `"$HOME"/…`, `${HOME:?}`, `open`
com `expanduser`) e no autoMemoryDirectory com `$HOME`. Os FURO e FP que restam são exatamente os
declarados no teto.

O que uma passada precisa saber antes de começar: o `--selftest` é meu e foi escrito junto com o
artefato. Três pontos cegos conhecidos. (1) O vocabulário do Bash: só se julga o caminho de memória
citado como DESTINO de uma forma listada; o replay de 618 escritas reais deu zero alarme, mas o
replay só mede o que esta máquina já fez. (2) A forma HARD é o par de envelope inteiro; uma nota
que documenta o formato abrindo E fechando a tag dentro de um bloco de código seria barrada, e
nenhum caso cobre isso. (3) A extração de memória em segundo plano do Claude Code não foi medida
contra o PreToolUse.

No adotante, o caso (e) monta o repo só com o manifesto do papel adopted e o registro do
`merge-onion-hooks.sh`; ele não exercita um `/meta:adopt --update` de verdade sobre um adotante clonado.

Os `confirmed` de maior impacto do grafo, que é o que a passada deve tentar refutar:
`E_DEFEITO_MEMGHOST_NO_CLAUDE_CODE_SDK`, `E_NENHUM_HOOK_OLHAVA_A_MEMORIA`,
`E_REPLAY_618_ESCRITAS_ZERO_ALARME` e `E_DOGFOOD_AO_VIVO_2_1_318`.

Grafo da forja: `docs/evolution/research/guard-memory-write-2026-11/memory-write-2026-11.kg.yaml`.
