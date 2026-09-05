---
title: '/meta:kg-inbox para em role: adopted sem oferecer o caminho do adotante'
date: 2026-09-04
from: portal-gamificacao (consumidor)
to: core (onion-evolve)
type: feature-request
flow: upstream (consumidor→core)
---

## O que aconteceu
`.claude/commands/meta/kg-inbox.md` passo 1: `role: adopted|hub → parar: o adotante tem a própria fila`.
Correto pela I3 (um escritor por repo) — mas o adotante **não recebe** um mecanismo de selagem local, só a
recusa. Num projeto colaborativo (dono + colaborador visitante que propõe nós ao grafo) a fila
`docs/evolution/kg-inbox/*.proposal.kg.yaml` precisa de alguém que sele.

## Contorno aplicado aqui
Comando projeto-local `.claude/commands/portal/selar.md`: lista propostas, radar advisory, apenda no grafo-alvo,
`git mv` para `_sealed/` ou `_rejected/` com motivo. Só o dono roda.

## Proposta
Parametrizar `/meta:kg-inbox` por role (no adotante, sela a fila local do próprio repo) ou vendorizar um
`/meta:kg-seal-local`. O padrão "proposta → selo do dono" é o mesmo; muda só quem é o dono.

---

## Triagem do core — 2026-09-05

**Veredito: FEATURE — curado na fonte, em duas metades** (este PR).
Você estava certo e o defeito era conceitual: a I3 (um escritor por repo) é fronteira de **REPO**, não de
**papel**. O `/meta:kg-inbox` confundia as duas e **parava** em `role: adopted`, deixando o adotante sem
mecanismo de selagem — foi por isso que vocês tiveram de forjar o `/portal:selar`.

1. **O comando ROTEIA por papel em TODOS os passos que decidem** — e essa palavra "todos" é a correção
   que o Elenxo desta mudança impôs. A primeira versão roteava só o `Passo 1` e deixava o `Passo 3` — o
   filtro que o próprio texto chama de "o mais importante" — perguntando apenas pelo core e mandando
   REJEITAR "contexto de negócio de adotante". Ou seja: você passaria a porta e seria recusado no filtro
   seguinte, pelo mesmo conteúdo que é a razão de existir da sua fila. Meia cura. Agora:
   - `Passo 1` roteia: cada papel sela a fila `docs/evolution/kg-inbox/` do PRÓPRIO repo, e se ela não
     existir o comando manda criá-la antes de seguir (adoções anteriores a 2026-09-05 podem não tê-la).
   - `Passo 3` pergunta **"este conhecimento mora NESTE repo?"**, instanciada por papel numa tabela — o
     que o core rejeita por fronteira é exatamente o que um adotante sela, e vice-versa. No seu repo,
     doutrina do framework é o que sai (vira sinal upstream via `/meta:co-relay`, não selagem aqui).
   - `Passo 4` **descobre** o grafo-alvo (`git ls-files '*.kg.yaml'`) em vez de presumir
     `docs/onion/graph/<slug>.kg.yaml` — medimos: dos adotantes locais, nenhum usa essa raiz.
   - `Passo 5` carimba nó `open` do grafo de estado DESTE repo, não só o do core.
   - **A invariante da fronteira é sobre o ATO, não sobre um campo.** A 1ª redação a ancorou em
     `meta.target` — e medimos que **nenhum produtor emite esse campo** (as duas propostas reais do
     corpus não o trazem): era prosa inexequível. Agora o que se prova é que o **alvo escolhido resolve
     dentro deste repo**; `meta.target`, quando presente, é obedecido.

2. **A fila NASCE na adoção**: bloco `(2a)` do starter do `/meta:adopt` cria
   `docs/evolution/kg-inbox/` com README, `_sealed/` e `_rejected/`, idempotente (não clobba fila em uso).
   Sem isso o comando roteado não tinha onde operar no dia 1.

Guardas, e vale contar o que elas custaram porque a primeira versão delas era ruim: caso `(d)` extrai o
bloco `(2a)` do starter e o **EXECUTA** num sandbox (2ª passada prova idempotência; a fatia agora exige
teto de linhas e a chamada do helper, senão renomear a sentinela do bloco vizinho a fazia engolir o
arquivo); caso `(d2)` mede o **fail-closed** de verdade — helper contra um DEST somente-leitura tem de
sair `rc≠0` e o chamador tem de abortar a adoção; caso `(e)` varre os **quatro** passos que decidem.

Três rodadas adversariais bateram nessas guardas e **quatro delas passavam verdes com o defeito
presente** — cada uma virou mutante do banco:
- a versão que olhava só o `Passo 1` passava com o `Passo 3` ainda core-only (o defeito real deste PR);
- a recusa por papel **reescrita** (`pare` em vez de `parar`; ou "este comando não roda aqui") passava,
  porque a guarda decidia por **vocabulário**. Reancorada na **estrutura**: a linha da tabela do papel
  `adopted` tem de **nomear a fila que ela sela**, a recusa é barrada na forma diretiva, e nada no
  comando pode autorizar selar grafo de outro repo;
- duas asserções estavam **conflacionadas** — a frase do `Passo 1` cobria a ausência da guarda no
  `Passo 4`;
- e a guarda casava com a própria **nota histórica** que citava a pergunta antiga (guarda de string não
  distingue regra de citação → a nota passou a descrever, não citar).

Limite declarado, porque a guarda é sobre um comando em markdown: ela prova a **forma**, não o
comportamento do modelo lendo o comando. O que é executado de verdade é o starter (casos `(d)`/`(d2)`).

Um pedaço fica ABERTO e com gatilho, para não te vender cura maior do que a entregue: a proposta que
chega ao **core** pertencendo a **outro** repo — o caso-semente `grana-ai-mapeamento` — continua só
REJEITÁVEL, sem transporte automático para a fila do repo-dono; a rota de volta é manual (rejeitar +
registrar o gap + o dono propor na fila dele). Registrado em `E_KG_INBOX_ROTEIA_POR_PAPEL_0905` (grafo
`librechat-kg-runtime-2026-08`), que fecha metade do `Q_TENANT_WRITE_DESTINATION` e nomeia a outra.

O seu `/portal:selar` continua válido como superfície local — o core agora oferece o caminho canônico, e
ele não te obriga a trocar.
