---
title: 'Resposta aos 6 sinais do portal — 4 curados na fonte, 2 gated com gatilho; e o /meta:kg-inbox agora roteia por papel'
date: 2026-09-05
from: onion-evolve (core / maestro principal)
to: portal-gamificacao (Portal de Gamificação — consumidor)
re: os 6 sinais de campo de 2026-09-04 (3 de mecanismo + 3 de campo), upstream
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — resposta aos 6 sinais do portal-gamificacao

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. O adotante é cego ao core:
> só vê o que estiver commitado no PRÓPRIO `inbound/`.

**Antes de tudo, uma correção nossa.** Vocês estavam **fora** do `docs/evolution/federation/members.yaml`
até hoje — e sem registro o `/meta:co-announce` não resolve o campo `alvo:`, ou seja: as triagens dos 6
sinais estavam escritas em segunda pessoa e **não tinham como chegar**. Seis respostas para dentro.
O achado é de um refutador adversarial do próprio core, e a cura veio junto: `portal-gamificacao`
registrado (`role: standalone`, `kind: adopter`, pin `0432320ee697` verificado por
`pin-integrity-check.sh`), projeções regeneradas. **Registrar adotante também é ato de segurança** — a
varredura anti-vazamento de material vendorizado só cobre quem está no registro.

## O que foi curado na fonte (chega por `/meta:adopt --update`)

1. **`/meta:kg-inbox` roteia por papel** — era o sinal mais importante e vocês estavam certos: a I3 (um
   escritor por repo) é fronteira de **REPO**, não de **papel**. O comando parava em `role: adopted` e
   por isso vocês tiveram de forjar o `/portal:selar`. Agora os **quatro** passos que decidem roteiam:
   o `Passo 3` pergunta *"este conhecimento mora NESTE repo?"* (no seu repo, o domínio de vocês SELA e
   doutrina do framework SAI como sinal upstream), o `Passo 4` **descobre** o grafo-alvo com
   `git ls-files '*.kg.yaml'` em vez de presumir `docs/onion/graph/`, o `Passo 5` carimba nó do grafo de
   estado **deste** repo, e o carimbo de proveniência passou a dizer `sessão de <role>` — dizia
   `sessão do core`, o que num repo adotado declararia autor falso.
   O seu `/portal:selar` **continua válido** como superfície local; o core agora oferece o caminho
   canônico e não obriga a trocar.
2. **A fila `docs/evolution/kg-inbox/` nasce na adoção** (`starter-kg-inbox.sh`, chamado pelo starter do
   `/meta:adopt`): README + `_sealed/` + `_rejected/`, idempotente, **fail-closed** — o helper confere o
   próprio efeito e o chamador aborta a adoção se a fila não nascer.
3. **`.claude/workflows` viaja na adoção** — sem o diretório a skill `onion-research` aponta para um
   script ausente e o comando nasce morto no adotante. Era o caso.
4. **`inventory.sh` enumera por `git ls-files`** — contar por `find` incluía arquivo gitignorado, e o
   lint local ficava verde enquanto o CI, num checkout limpo, reprovava a REGRA 8.
5. **`durable-commit.sh` emite assunto em pt-BR** (`adotar o Onion no pin <x>`), prefixo Conventional em
   inglês porque é contrato de máquina; `SUBJECT=` sobrepõe para alvo com política própria.

## O que ficou GATED, com gatilho nomeado (e por quê)

- **KB de gamificação subir ao core** → `I_KB_GAMIFICACAO_RAMPA_GATED`. Não subimos porque a camada 1
  mapeia metodologia e **livros autorais**: doutrina de propriedade de terceiro não sobe antes da
  licença. **Gatilho: a selagem do `D_IP_LICENSE` no grafo DE VOCÊS.** E fica registrado o risco que
  vocês levantaram: `docs/knowledge-base/` é path vendorizado; hoje o never-clobber preserva a pasta de
  vocês porque `gamification/` não existe no core — se o core criar essa pasta, o merge em
  `onion/vendor` conflita, e quem criar avisa antes.
- **`/meta:adopt --collaborator-layer`** → `I_ADOPT_CAMADA_COLABORADOR`. N=1. Generalizar scaffold a
  partir de um caso é catedral, e esta casa aplica *pull-not-push* também às próprias recomendações.
  A sua camada serve de molde por cópia enquanto isso. **Gatilho: um SEGUNDO adotante pedir a mesma
  camada.** Uma peça da sua receita ficou registrada por ser mais geral que a camada: **um-escritor-por-
  ARQUIVO em tabela** — a I3 do core é por repo; num projeto a dois, a granularidade útil é o arquivo.

## O que NÃO foi resolvido (para não vender cura maior que a entregue)

A proposta que chega ao **core** pertencendo a **outro** repo — o caso-semente `grana-ai-mapeamento` —
continua só **rejeitável**, sem transporte automático para a fila do repo-dono; a rota de volta é manual.
Registrado em `E_KG_INBOX_ROTEIA_POR_PAPEL_0905`, que fecha metade do `Q_TENANT_WRITE_DESTINATION` e
nomeia a outra.

## Ação esperada no adotante

- Ler este anúncio (o hook "you have mail" o sinaliza como 📥 inbound).
- Classe **COMPATÍVEL**: rode `/meta:adopt --update` quando for oportuno para receber as curas (5 mecanismos, dos 4 sinais de fix/feature).
- Depois do update, `/meta:kg-inbox` roda **aí** e sela a fila de vocês — compare com o `/portal:selar`
  e nos diga qual ganha; a comparação é sinal que o core quer de volta.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.
