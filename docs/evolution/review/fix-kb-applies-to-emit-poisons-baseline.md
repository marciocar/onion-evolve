---
branch: fix/kb-applies-to-emit-poisons-baseline
reviewed_diff_sha256: 9927774d14e307c50b06fa33423e75bb4394fa5b7c4478092cf68c5795326a93
elenxo: nao
verdict: CORRIGIDO
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 10
nota: "Sem passada adversarial dedicada: o achado veio do DOGFOOD da entrega — rodar o lint dentro do hub depois do update. O gate que eu acabara de instalar la bloqueava o repo do adotante por divida que nao era dele. Dois defeitos encadeados no meu emissor de baseline, os dois provados por execucao e cobertos por bancada nova (casos g e h)."
---

# Resíduo — o emissor saiu `exit 0` e produziu lixo

Achado no **dogfood da própria entrega**: rodei o lint dentro do hub depois de atualizá-lo, e ele
reprovou. O gate que eu acabara de instalar lá estava **bloqueando o repo do adotante por dívida que
não era dele**.

## Os dois defeitos, encadeados

**(1) O emissor escrevia o arquivo por conta própria.** A convenção da casa — e o que o
`regen-baselines.sh` faz para **todos** os baselines, por varredura — é
`bash <emissor> --emit-baseline > <baseline>`: **o stdout É o arquivo**. O meu escrevia direto em
`${BASELINE}` e deixava o stdout com outra coisa. As duas escritas colidiram e a do regen ganhou.

**(2) E o que sobrou no stdout eram as MENSAGENS DE ACHADO.** A varredura `echo`-a cada achado, e em
modo emissão isso ia para o mesmo stdout. Resultado medido no hub: um baseline com **três linhas de
prosa** em vez de caminhos.

Baseline que não casa com nada **não tolera nada**. As KBs legítimas e pré-existentes do adotante
viraram HARD, e o `install-onion-githook.sh` até imprimiu `✓ GATE VIVO — bloqueio PROVADO por
execução` — ele provou o bloqueio **na dívida que eu mesmo fabriquei**.

## A classe

`exit 0` é **declaração do script sobre si**. Ele saiu zero e produziu lixo; ninguém a jusante
conferiu o que ele produziu. É a mesma família de `exit-code-nao-e-a-verificacao`, agora no eixo do
**canal**: não basta o rc, tem de bater o que saiu, e por onde.

E há uma lição de fronteira: **emissor que inventa convenção própria quebra o mecanismo genérico**.
O `regen-baselines.sh` foi escrito exatamente para não ter lista de emissores para envelhecer — ele
varre `*-baseline.txt` e resolve o emissor de cada um. Quem sai da convenção não é pego por essa
generalidade; é quebrado por ela.

## Cura, e a guarda que a segura

- em modo `--emit-baseline`, achado vai para o **stderr** (segue visível a quem roda à mão) e o
  stdout carrega **só** o baseline;
- o baseline volta a sair no **stdout**, como os irmãos, e o rodapé do próprio arquivo passa a
  ensinar o redirecionamento.

Bancada, dois casos novos:

- **(g)** o stdout do `--emit-baseline` tem **caminhos e zero achado**;
- **(h)** o baseline emitido **TOLERA na varredura seguinte** (`rc=0`) — senão é decorativo. Este é o
  que teria pego o defeito inteiro, porque mede o par emissor↔leitor, não cada um de si.

## O que fica para a entrega

O baseline do hub precisa ser **regenerado com o emissor curado** no próximo update. O baseline do
**core** nunca esteve envenenado: eu o escrevi à mão, com a razão inline — foi sorte, não desenho, e é
mais uma razão para a guarda (h) existir.

## E o gate me pegou de novo, no mesmo PR

Escrevi os três nós do fio do saldo **dentro do `audit-textual-gates-2026-09`**, que declara no próprio
`meta:` um **teto de 26 nós** — e o levei a 28. A REGRA 58 (O backlog cumpre as promessas do próprio
`meta:`) reprovou **no CI**, com a frase do contrato: *"onda nova exige onda COLHIDA"*.

Duas coisas a registrar, porque nenhuma é sobre o grafo:

1. **Não pegou local porque eu commitei com `--no-verify`.** Rodei o lint ANTES de escrever os nós e
   depois usei o checkpoint. É literalmente o que a doutrina diz: `--no-verify` é checkpoint, **nunca**
   validação final — e o preço foi um ciclo de CI.
2. **Segunda vez no mesmo dia** que escrevo num grafo com teto selado (a primeira foi o
   `fios-abertos`, que deu origem ao `rito-task-manager`). A cura é a mesma: o fio ganha **casa
   própria** (`docs/onion/graph/review-gate-saldo-2026-09.kg.yaml`), em vez de eu advogar
   enquadramento contra um contrato que o maestro selou.

O grafo dos gates voltou a **25 nós**, sob o teto, e os dois passam no radar com `exit 0`.

## Os `confirmed` do grafo que este PR edita (REGRA 87)

O PR mexe no `audit-textual-gates-2026-09.kg.yaml` (para **remover** de lá os três nós que eu havia
escrito acima do teto). Os três `confirmed` de maior impacto dele, lidos antes de mexer:

- **`E_VETO_UNICO_ANTES_DA_RODADA`** — antes daquela rodada a sessão tinha **um** veto incondicional
  (`pretooluse-protect-main.sh`). Não conflita: nada aqui mexe em veto de sessão.
- **`E_HOST_SEM_PROTECAO_CI_E_AVISO`** — e este **muda como se lê a dispensa que fiz hoje**: o repo é
  privado sem GitHub Pro, `branch protection` devolve 403, logo **todo check de CI é AVISO**, não
  bloqueio estrutural. Quem impede o merge errado é o `ops/pr-merge-verified.sh`, não o forge. Ou seja:
  a dispensa nomeada não furou uma proteção do host — ela **é** o mecanismo, e por isso publicar o
  motivo no PR antes de mergear não é formalidade, é a única trilha que sobra.
- **`E_CURA_MERGE_GATE_2O_VETO`** — o hook veta `gh pr merge` fora do caminho verificado. Consistente
  com o que fiz: os merges de hoje foram todos pelo script, inclusive o dispensado.

Nenhum dos três refuta o que este PR propõe; o segundo **reforça** a exigência de registrar a dispensa.

## Gate

`lint-artifacts.sh` → **0 HARD**, `rc=0` · família `kb_applies_to` **8/8**.
