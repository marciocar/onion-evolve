---
title: "Comportamento acima de declaração — não confie no que o artefato diz sobre si"
category: agentic-patterns/ai-strategies
verified_at: 2026-07-25
kg: docs/onion/graph/doctrine-behavior-over-declaration-2026-07.kg.yaml
---

# Comportamento acima de declaração

> **Origem (crédito):** três casos de campo REAIS da mesma jornada — um adotante de campo e a
> stack Logto do próprio core — triados e sintetizados pelo core em 2026-07-25. Sinais no
> `_processed` do inbox (trace em cada seção).

## A tese

> **Não confie no que o artefato DIZ sobre si — confie no que ele FAZ, EXECUTA e ENTREGA.**

Um gate que roda verde *diz* "estou cobrindo". Uma branch que existe e uma prosa de workflow
que a chama de "integração" *dizem* "sou a origem do deploy". Um pin de versão herdado *diz,
pelo silêncio,* "sou só transporte, não me audite". As três declarações são textualmente
verdadeiras e **operacionalmente falsas**. O que o gate PEGA, o que os triggers DISPARAM e o
release que a versão ENTREGA contam outra história.

Esta é a **irmã, um nível acima do código, de `declarado ≠ verificado`**. Aquela família
manda desconfiar do que um agente ou um store *afirma* sobre um dado. Esta manda desconfiar do
que o *próprio artefato* afirma sobre a sua *função* — cobertura, autoridade, atualidade. O
artefato mente sobre si; o comportamento não sabe mentir. Ver os irmãos
[`verify-read-path-first.md`](./verify-read-path-first.md) (onde-o-dado-vive é hipótese até
rastrear o read-path) e a doutrina `verify-external-for-current` (algo atual/emergente se
verifica contra a fonte externa viva, nunca do cutoff).

---

## Caso 1 — L1: catraca correta que mede a coisa errada (falso-verde por escopo de detecção)

- **Declarado:** a catraca de CI (banindo import das primitivas do AI SDK — `streamText`,
  `generateText`, … — de `'ai'`) rodou "0 violações não declaradas, verde, allowlist
  completa". Lido como "o bypass do Contrato 2 está coberto / é impossível".
- **Verificado:** das 8 travessias reais da fronteira, **só 1 era pega**; 7/8 eram invisíveis
  ao gate. A pior (rota de usuário em produção) não importa de `'ai'` — importa um wrapper
  interno `streamAgent` de um propagador do projeto; e um `export { runAgent } from '../ai/agent'`
  num arquivo de 2.400 linhas "lava a origem", fazendo um terceiro arquivo cruzar a fronteira
  sem que o nome do propagador apareça nele. **Cobertura real: 1/8.**
- **Modo de falha:** falso-verde por **escopo de detecção** — um *terceiro* modo, distinto de
  falso-verde por **bug** (o jq de 2026-07-01) e por **vacuidade** (guarda de legibilidade
  vazia). Aqui o gate está correto e roda; "verde num gate estreito lê-se como coberto", mas o
  escopo declarado de cobertura é mais estreito que o real. Corolário de orquestração: a
  varredura paralela de subagentes (perguntando só por `'ai'`) também não viu as 7 travessias
  por propagador nem um arquivo inteiro omitido — **varredura de subagente não substitui
  re-derivação quando o resultado vai virar catraca**.
- **Trace:** `docs/evolution/inbox/_processed/2026-07-25-sinal-catraca-falso-verde-*.md`
  (L24-61, esp. L33-48); o `scripts/lint-provider-boundary.ts` do adotante; `source_commit 5e3ea5ee46ac`.
- **Cura (mecanismo):** o teste de aceite de um gate **não é** "roda e passa" — é **"ele pega
  o caso que motivou a existência dele?"**. Se o gate nasceu de um achado concreto de
  auditoria, esse achado é o **fixture obrigatório**. Verde na primeira execução *sem* esse
  fixture é sinal de alarme, não de sucesso. (Par no próprio core: `inventory_scope_excluded` /
  a exclusão de `inbox` — mesma classe: escopo declarado de cobertura mais estreito que o real.)

---

## Caso 2 — develop-fantasma: existência ≠ autoridade

- **Declarado:** duas fontes declarativas convergiam para "develop é a branch de integração":
  (1) a mera **existência** do ref `origin/develop`; (2) a **prosa** dos comentários de
  `deploy-staging.yml` — "Promoção: develop --(tag staging-*)--> staging · develop->main -->
  produção" e "Staging é o gate antes de promover pra main". Duas declarações textuais de
  topologia GitFlow, no arquivo canônico de deploy.
- **Verificado:** os **triggers reais** não implementam nada disso. `deploy-prod.yml` dispara
  em `push` na `main`; `deploy-staging.yml` dispara por tag `staging-*` + `workflow_dispatch`
  (não olha branch — a tag é cortável de qualquer ref). `develop` **não aparece em nenhum
  caminho de deploy**: não builda, não deploya, não gateia. Cruzando origin/HEAD e rev-list:
  95 commits atrás, 43 dias parada. Existe e a prosa a confirma — mas não é origem de ambiente
  algum.
- **Modo de falha:** inferir autoridade de branch a partir de fonte **declarativa** (existência
  do ref, prosa de workflow/CONTRIBUTING) em vez de **mecanismo executável** (origin/HEAD,
  liderança via rev-list, e sobretudo os triggers de deploy) → "confirmada na crença errada com
  evidência textual". Não é chute: é leitura *correta* de uma fonte que mente. Vive no resolver
  do próprio core: `resolve-integration-branch.sh` passo (3), `git show-ref --verify
  refs/heads/develop` (L49) aceita a **existência nua** do ref antes de checar origin/HEAD (L63)
  e sem nunca checar triggers de deploy — a ordem invertida.
- **Trace:** `docs/evolution/inbox/_processed/2026-07-25-contra-sinal-develop-fantasma-v2.md`
  (L24-35 triggers; L37-55 prosa vs triggers; L62-72 ordem proposta); core
  `resolve-integration-branch.sh:49-51`; ação no adotante commit `b7182ccb` + cherry-pick
  `68588a63`.
- **Cura (mecanismo):** ler o que o repo **executa**, nunca o que ele **declara** sobre si.
  Cadeia (mecanismo antes de declaração): (1) `git symbolic-ref refs/remotes/origin/HEAD` — a
  default do remoto, o forge registra e não opina; (2) `git rev-list --left-right --count
  origin/<a>...origin/<b>` — quem lidera; (3) os **triggers dos workflows de deploy** — o sinal
  mais forte, porque ambiente é consequência e não intenção; (4) frescor do ref; (5) **só então,
  por último e como palpite a confirmar**, convenção de nome ("develop"/GitFlow). Itens 1-4 são
  mecanismo; o 5 é o único declarativo.

---

## Caso 3 — L2: pin de versão herdado não-auditado (herança seletiva de ceticismo)

- **Declarado:** ao destilar o `docker-compose.self-hosted.yml` de um adotante para montar o Logto
  do core, a sessão tratou (pela ação, não por afirmação) o pin herdado — `1.36.0` — como
  "detalhe de transporte". Todo o resto do artefato herdado foi revisado com ceticismo
  (removido o logto-init específico, portas no loopback, `mem_limit`, ENDPOINT corrigido) —
  mas a versão veio junto sem questionamento.
- **Verificado:** a versão é **conteúdo, não transporte**, e estava **5 minors atrás**
  (jan→jun/2026: `1.36.0` vs `1.41.0` real). No intervalo faltavam fixes de segurança
  concretos: account enumeration no fluxo de recuperação de senha (1.39),
  `PRIVATE_KEY_ROTATION_GRACE_PERIOD` (1.39), MFA adaptativa e passkeys (1.38), política de
  expiração de senha (1.41); e faltava `SECRET_VAULT_KEK` (a KEK AES-256 do Secret Vault). O
  gap **só apareceu porque o maestro perguntou** "o Logto está na 1.41.0, conseguimos
  atualizar?" — não foi achado pela auditoria da própria sessão.
- **Modo de falha:** **herança seletiva de ceticismo** — verificar declarado-vs-verificado em
  cada campo estrutural (portas, init, env) mas tratar o **pin de versão** como dado neutro
  herdado por default, especialmente grave em componente de segurança (auth/cripto). Corolário
  D4: o mesmo compose propaga um entrypoint frágil — provisionamento encadeado com `&&` **antes**
  do `npm start`; falha de *config* (não de schema) derruba o serviço (503 permanente), e
  `healthCheckGracePeriodSeconds:900` faz o `aws ecs wait services-stable` reportar "estável"
  mesmo assim — invisível ao pipeline.
- **Trace:** `docs/evolution/inbox/_processed/2026-07-25-logto-core-e-licao-do-pin-herdado.md`;
  `source_commit 65d8a7501a03`; stack `/home/marcio/onion-logto` commit `7c008b2`.
- **Cura (mecanismo):** pin explícito + verificador automatizado (`check-version.sh`) que
  compara o pin corrente contra o último release e reporta o delta, em cron semanal — **nunca
  `latest`** (pull/restart de rotina pode subir versão cuja migração de banco ninguém aplicou =
  "undeployed database alterations exception"). Ao adotar/herdar tecnologia principal, a versão
  passa a ser parte explícita do que se audita: delta contra o release atual → ganhos/riscos →
  decisão ao maestro **antes de subir** — peso extra quando o componente é de segurança.
  Corolário D4: separar **migração de schema** (precede o start — código não roda contra tabela
  errada) de **provisionamento** (não encadear com `&&`, para não trocar erro de config por
  indisponibilidade de auth); o entrypoint termina em `npm start`.


## Caso 4 — farol de sessão: o sinal que a máquina emite para a máquina

- **Declarado:** no boot, o hook do farol injetava `🕯️ Onion farol: OUTRA sessão viva neste
  repo — …`. A sessão que leu **repassou ao maestro como observação própria**, com recomendação
  de conduta anexa ("um escritor por repo (I3): coordene antes de checkout/escrita"). Nenhuma
  medição foi feita: a declaração do mecanismo virou fato no relato, e o rótulo de origem se
  perdeu no caminho.
- **Verificado:** "viva" era `refreshed_at` dentro de um TTL de 480 min — **um carimbo que a
  própria sessão escreve**. E `refreshed_at` só avança no `UserPromptSubmit`: toda sessão que
  nasce e some sem `SessionEnd` (crash, kill, conexão de Remote Control, resume abortado) lia
  como VIVA por 8 horas. Medidos no core: os **2** faróis anunciados tinham
  `started_at == refreshed_at` (jamais receberam **um** prompt) e **nenhum processo
  correspondente**; um deles nascera 150s antes da própria sessão que leu o aviso, na mesma
  branch e worktree — era, com toda probabilidade, **ela mesma**. Quem furou o relato foi o
  maestro, perguntando "a viva pode ser você mesmo ou pelo uso do remote control".
- **Modo de falha:** **guarda que roda e mente** — o degrau caro acima de "guarda que ninguém vê"
  e "guarda que ninguém roda". Ela não falha em silêncio: emite um aviso confiante, sem rótulo
  de confiabilidade, que o consumidor não tem como calibrar sozinho. Efeito composto: aciona uma
  invariante real (I3), travando trabalho legítimo por até 8h — e **guarda que grita errado
  ensina a ignorar guarda**.
- **Trace:** `.claude/diary/2026-08-28-o-farol-anunciava-fantasma-como-sessao-viva.md`;
  `docs/onion/graph/guardas-revisao-2026-08.kg.yaml` (`E_FAROL_ANUNCIAVA_FANTASMA`,
  `C_GUARDA_QUE_GRITA_ERRADO`, `D_MEDIR_O_DONO_NAO_O_CARIMBO`, `D_AVISO_CARREGA_O_QUE_VALE`).
- **Cura (mecanismo), em duas metades que não se substituem:**
  1. **Medir** — o beacon grava `owner_pid` + `owner_start` (starttime do `/proc`, defesa contra
     **reuso de pid**) e o veredito passa a ser observado: `live` · `declared` (dono não medido —
     cai no TTL e **bloqueia**, conservador) · `orphan` (dono medido morto — não bloqueia) ·
     `stale`. **A direção do erro é escolhida explicitamente**: um falso `orphan` (diz morta,
     está viva) reabre o incidente que criou a guarda; um falso `declared` custa uma verificação
     — logo ausência de prova cai no comportamento antigo, **nunca** em "pode escrever".
  2. **Rotular e mandar verificar** — medir não basta enquanto o aviso **afirma**. O sinal passa
     a carregar o que vale: rótulo (`VIVA` = dono medido × `DECLARADA` = não medido), a pista
     `NUNCA refrescou (0 prompts)`, e a ordem de **não relatar como sessão alheia viva o que não
     foi medido**. Testado no gate: o selftest reprova se o aviso perder qualquer das duas.
- **Corolário do dogfood:** a 1ª sonda casava `*claude*` no **cmdline** e elegeu o **shell
  transitório do próprio hook** — cujo path carrega `~/.claude/shell-snapshots/…`. Esse shell
  morre em segundos: o farol viraria `orphan` **com a sessão viva**, o erro na direção proibida.
  **Substring de path não é identidade**; a cura casa por `comm`. E o mesmo dogfood expôs um
  `exit 1` espúrio do `up` (cadeia `&&` como última instrução sob `set -e`) que o `|| true` do
  hook mascarava — [exit code não é a verificação](../../concepts/onion-dogfooding-doctrine.md).
- **Corolário da cópia:** o mapa da constelação carregava uma **segunda** implementação da regra
  de "vivo" por TTL. Cura no motor não alcança cópia — a regra passou a morar num lugar só
  (`session-beacon.sh verdict`). **Regra copiada envelhece separada.**

---

## A regra generalizável

> Ao **adotar, herdar ou gatear** qualquer artefato, verifique o **comportamento**, não a
> **declaração**. O que o gate diz que cobre não é o que ele pega; a branch que existe e que a
> prosa chama de integração não é a que deploya; o pin que veio junto não é neutro. **Peso
> extra quando o componente é de segurança** (auth, cripto, gateway, fronteira arquitetural):
> aí o falso-verde custa mais.

Sinais de que você está confiando na declaração:

- Um gate ficou **verde na primeira execução** e você leu isso como "coberto".
- Você concluiu topologia de deploy a partir de **existência de ref** ou **comentário de
  workflow**, sem abrir os triggers.
- Você herdou um artefato de terceiros e revisou **tudo menos a versão**.

## O corolário mecânico

A cura **nunca é disciplina** ("da próxima vez eu presto mais atenção") — é sempre um
**verificador, fixture ou mecanismo** que faz o comportamento se provar sozinho, repetível:

| Caso | Declaração enganosa | Mecanismo que prova o comportamento |
|---|---|---|
| L1 catraca | "verde = coberto" | **fixture-que-motivou-o-gate**: o achado que criou o gate é seu teste de aceite obrigatório |
| develop-fantasma | "existe / a prosa diz" | **ler-triggers-não-prosa**: origin/HEAD → rev-list → triggers de deploy → frescor → (só então) nome |
| L2 pin | "versão é transporte" | **pin + verifier, nunca `latest`**: `check-version.sh` compara delta contra o release atual em cron |

Regra-mãe do corolário: **quando uma claim `confirmed` vira atuador (gate/resolver/pin), o
fixture do atuador é a evidência que a confirmou.** Um atuador sem esse fixture está protegendo
o escopo que *diz* proteger, não o que *deveria*.

---

## Família doutrinária

Membro de "estado declarado ≠ fato verificado", um nível acima do código (o artefato mente
sobre a própria função, não sobre um dado):

- [`verify-read-path-first.md`](./verify-read-path-first.md) — onde-o-dado-vive é hipótese até
  rastrear o read-path real.
- `verify-external-for-current` (memória durável) — o atual/emergente se verifica contra a
  fonte externa viva, nunca do cutoff.
- **Este padrão** — o que o artefato *faz* (pega / dispara / entrega) acima do que ele *diz*
  sobre si (cobre / é integração / é transporte).
