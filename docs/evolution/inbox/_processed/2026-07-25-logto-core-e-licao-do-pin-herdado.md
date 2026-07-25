---
title: 'Logto próprio do core no ar (1.41.0) — e a lição do pin herdado sem auditoria'
date: 2026-07-25
from: arandek (consumidor) / sessão operando o VPS do core
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core / sinal)
source_commit: 65d8a7501a03
contexto: >-
  O core ganhou provedor de identidade próprio no VPS srv1812846. O stack, o texto
  e o grafo vivem em /home/marcio/onion-logto (git local, commit 7c008b2).
---

# Logto do core no ar — e uma lição que vale como regra

`https://auth.onionevolve.com` está servindo OIDC (Logto 1.41.0), com console admin em
`console.onionevolve.com` ligado sob demanda. Stack, README e grafo em `/home/marcio/onion-logto`.

**Ponteiros:** `README.md` (o quê, por quê, como, planos) · `graph/logto-core.kg.yaml` (24 nós,
22 arestas, radar limpo).

---

## L2 — Pin herdado é declaração, e declaração se audita

Este é o item que quero que vire regra, não nota.

Montei o Logto destilando a fatia do `docker-compose.self-hosted.yml` do **Arandek**. Auditei quase
tudo do artefato herdado: tirei o `logto-init` (que provisiona applications do Arandek, não do core),
tranquei as portas no loopback, pus `mem_limit`, corrigi o `ENDPOINT` que anunciava `localhost` no
issuer. **Menos a versão.** O pin `1.36.0` passou intacto porque veio junto.

Eram **5 minors de atraso** (jan→jun/2026) num componente de **segurança**. No meio: correção de
*account enumeration* no fluxo de recuperação de senha (1.39), `PRIVATE_KEY_ROTATION_GRACE_PERIOD`
(1.39), MFA adaptativa e passkeys (1.38), política de expiração de senha (1.41). E faltava
`SECRET_VAULT_KEK` — a KEK AES-256 que embrulha as chaves do Secret Vault, recomendada pela doc
oficial.

Nada disso apareceu sozinho. Apareceu porque o maestro perguntou *"o Logto está na 1.41.0, conseguimos
atualizar?"*.

**O que me incomoda no meu próprio erro:** um pin em arquivo herdado é exatamente uma **declaração** —
a categoria que a doutrina desta linhagem manda não aceitar sem verificar. Eu apliquei ceticismo a
tudo naquele arquivo, e obedeci a versão. Como se número de versão fosse detalhe de transporte, não
conteúdo.

**Regra proposta:** ao adotar ou herdar tecnologia principal, a **versão faz parte do que se audita** —
verificar o delta contra o release atual, avaliar ganhos e riscos, e trazer a decisão ao maestro
**antes** de subir; peso extra quando o componente for de segurança (auth, cripto, gateway). Onde
mora: candidata a linha na `code-standards.md` ou a KB própria em `agentic-patterns/`, da mesma
família de `declarado ≠ verificado`.

**E o corolário sobre a correção:** a resposta certa não é `latest`. Num componente com migração de
banco, `latest` é pior — um `pull` + restart de rotina sobe versão cuja migração ninguém aplicou, que
é o *"undeployed database alterations exception"* documentado em postmortem pelo próprio Logto. O par
correto é **pin + verificador** (`check-version.sh` compara com o último release e reporta o delta;
cron semanal). Mecanismo em vez de disciplina.

---

## D4 — O compose self-hosted do Arandek propaga um entrypoint frágil

Interessa a **qualquer adotante** que use aquele arquivo como base, então mando ao core.

O `logto-init` do compose self-hosted é container separado — tudo bem. Mas o **staging** do Arandek
(SST, `infra/auth.ts`) roda o mesmo provisionamento **dentro** do entrypoint do Logto:

```sh
npm run cli db seed -- --swe && node /etc/logto-init/init.mjs && npm start
```

Encadeado com `&&`, antes do `npm start`. Se o provisionamento falha, **o Logto nunca sobe** — 503
permanente. E `healthCheckGracePeriodSeconds: 900` faz o `aws ecs wait services-stable` reportar
"estável", então o pipeline passa e o problema fica invisível.

**Evidência que isola a causa:** a mesma imagem, o mesmo `seed`, o mesmo Postgres **sobem limpos** no
VPS do core. Não é o Logto; é o desenho.

**A distinção que vale doutrina:** migração de *schema* **precisa** preceder o start (o código não pode
rodar contra tabela errada). *Provisionamento* **não** precisa — e encadeá-lo troca erro de
configuração por indisponibilidade de autenticação. No stack do core, o `alteration deploy` vive no
`upgrade.sh` como etapa observável, com backup antes, e o entrypoint termina em `npm start`.

---

## C2 — Correções minhas, para o registro

Duas leituras erradas que reportei ao maestro com confiança e depois desmenti:

1. **"0 usuários"** — havia o `marciocar`, criado pelo maestro entre as minhas duas medições.
2. **"upgrade in-place quebrado por construção"** — baseado em `alteration list` mostrando 198
   entradas desde 1.0.0, e em `logto_configs` sem registro de alteration. Ambos errados: o estado vive
   na tabela **`systems`** (`alterationState`), e `alteration list` lista **todas** as migrações da
   imagem, não as pendentes. As pendências reais eram **23**. O in-place era viável; o rebuild limpo
   foi conveniência autorizada, não necessidade.

Registro porque as duas seguem o mesmo padrão: **li ausência onde havia registro em outro lugar** —
primeiro `pass`/`.env` para a chave da Hostinger, depois `logto_configs` para o alteration state.
"Não achei" não é "não existe", e eu tratei como se fosse duas vezes no mesmo dia.

---

## V2 — O grafo do core ganhou plano PROD de verdade

`graph/logto-core.kg.yaml` é o primeiro desta linhagem com nós **`plane: PROD` legítimos**: serviço
vivo, verificado por `curl` contra endpoint público real, não por leitura de fonte. Todos os grafos
anteriores (incluindo o `master-plan-v1-vs-real` do Arandek) são `plane: DEV`/`verified_against:
branch`, com a lacuna `Q_NOTHING_VERIFIED_IN_PROD` explicitamente aberta.

Neste escopo ela fecha. E aponta para o passo maior: rodar o **Arandek reduzido** no mesmo VPS daria
ao core um plano PROD para cruzar claims contra sistema vivo em vez de contra fonte. É viável (17 GiB
livres, sem Marker), e está registrado como `Q_ARANDEK_ON_VPS`.

---

## Nota lateral — a caixa estava no limite

Ao medir o VPS para caber o Logto, achei a máquina com **swap 100% consumido** e 7,5 GiB
disponíveis de 31. Não era carga de produção: eram **41 processos do Claude Code** (até 15 dias de
vida) e **6 watchers `nest --watch`** de outro projeto, somando ~17 GiB parados a 0,5% de CPU.
Liberados com autorização do maestro; a caixa foi para 13 GiB usados e o swap voltou a respirar.

Interessa ao core porque `onionevolve.com` — a face pública do framework — divide host com ferramental
de dev, sem garantia de memória. O site sobreviveu por sorte, não por desenho. Vale considerar
`MemoryMin`/`MemoryLow` no systemd do Caddy e do bridge.
