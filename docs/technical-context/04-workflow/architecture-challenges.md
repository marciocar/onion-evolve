---
title: Desafios de arquitetura — o retrato fiel do que falta
date: 2026-07-25
---

# Desafios de arquitetura — o retrato fiel do que falta

> **Propósito.** Este arquivo é o inverso deliberado de um marketing técnico: lista o que o Sistema
> Onion (o **core**, framework template em `.claude/`, greenfield — nunca dogfoodou o próprio
> technical-context) **sabe que tem pela frente**. Cada afirmação está ancorada em arquivo/commit real
> (`docs/evolution/inbox/_processed/`, `docs/analysis/`, `docs/evolution/federation/`, `CLAUDE.md`) —
> nada aqui é extrapolação. Ver também o comando que gera achados equivalentes de forma contínua,
> `/meta:evolve` (auto-auditoria read-only), e a doutrina de dogfooding
> (`docs/knowledge-base/concepts/onion-dogfooding-doctrine.md`, citada em `CLAUDE.md:112`).

---

## 1. Backlog de campo aberto (inbox de co-evolução)

O canal `docs/evolution/inbox/` recebe sinais **upstream** (adotante → core) e regras de
processamento os move para `_processed/` quando triados — "processado" não significa "resolvido", só
"lido e roteado". Em 2026-07-25 havia **80 arquivos processados**
(`docs/evolution/inbox/_processed/`, contagem via `ls | wc -l`), 5 deles do próprio dia. Os mais
recentes e ainda **sem mecanismo aplicado**:

### 1.1 Paridade hook < CI — instrução de ferramenta sem consultar o alvo

Fonte: `docs/evolution/inbox/_processed/2026-07-25-sinal-adocao-arandek.md` (bloco D1).

O hook de pre-commit nativo Onion (`.claude/hooks/`) imprime `Rode 'pnpm install' p/ ativar` em **todo
commit**, mesmo em repos que **proíbem** pnpm por design (`package.json` do adotante Arandek declara
`"pnpm": ">=999.0.0"` — bloqueio deliberado; `CLAUDE.md` do adotante crava "nunca use npm, npx, yarn,
pnpm"). É a mesma classe do D3 documentado anteriormente: relatório de adoção instruindo
`cp .env.example .env` num repo cujo `CLAUDE.md` diz "NUNCA criar `.env` solto". **Padrão nomeado no
sinal**: "o Onion dá instrução de ferramenta sem consultar o que o alvo declara" — vale varredura para
achar mais ocorrências.

Fix sugerido na fonte: ler `packageManager` do `package.json` quando existir; senão, mensagem
agnóstica. Não implementado até este arquivo.

### 1.2 `install-onion-githook.sh` não refresca hook Onion antigo no `--update`

Fonte: `docs/evolution/inbox/_processed/2026-07-25-gap-githook-nao-refresca-no-update.md`.

O passo 6 da configuração pós-cópia do `/meta:adopt --update` é **never-clobber**: se o alvo já tem
`.githooks/pre-commit` (de uma adoção anterior), o script escreve a versão nova como sidecar
(`.githooks/pre-commit.onion`) e **deixa o hook velho ativo**. O never-clobber está certo para hook
**do adotante** — errado quando o arquivo existente **é o próprio hook Onion desatualizado**: aí a
regra deveria refrescar in-place, não sidecar. Existência de arquivo ≠ autoria do adotante (mesma
família do "contra-sinal develop-fantasma", §3). Consequência observada em campo: um fix crítico
(hook lendo `packageManager` em vez de mandar `pnpm install` cego) não teria pegado no adotante sem
promoção manual do sidecar.

Mecanismo candidato (não implementado): checar assinatura Onion (`🧅 Onion pre-commit`) antes de
decidir sidecar-vs-refresh; testável via `lint-selftest.sh` modo `githook`. A fonte nomeia a classe:
"vale varrer se outros passos install-only têm o mesmo modo-de-falha 'existe → não refresca'" — não
varrido ainda.

### 1.3 Falso-verde por escopo de detecção (lição de doutrina, sem casa fixa ainda)

Fonte: `docs/evolution/inbox/_processed/2026-07-25-sinal-adocao-arandek.md` (bloco L1).

Terceiro modo de falso-verde nomeado em campo, distinto dos dois que o core já documenta (bug —
`id_in_list()` do `trust-topology-check.sh`, ver §2 — e vacuidade — radar sem dado): **o gate está
correto, roda, e mede a coisa errada**. Caso concreto: uma catraca bloqueando import direto de um SDK
reportou "0 violações, verde" enquanto 7 de 8 travessias reais passavam por um wrapper interno que o
gate nunca soube procurar. Lição generalizável proposta pela fonte, ainda **sem casa** no framework:
"o teste de aceite de um gate nascido de um achado de auditoria não é 'roda e passa' — é 'ele pega o
caso que motivou a existência dele?'". Sugestão de destino:
`docs/knowledge-base/agentic-patterns/` (família `declarado ≠ verificado`) — não criado.

### 1.3b Vacuidade, exemplar do próprio core — o runner de dois desfechos (RESOLVIDO)

Fonte: `docs/evolution/inbox/_processed/2026-07-25-correcao-o-sinal-do-entrypoint-estava-errado.md`.

O modo **vacuidade** do §1.3 tinha um exemplar dentro de casa, e caro. O `lint-selftest.sh` só
distinguia `record_pass` de `record_fail`: **32 sítios registravam um skip por tooling ausente como
✓**. Medido, removendo só o `jq`: a suíte reportava `409 passaram / 0 falharam`, exit 0 — verde
indistinguível de uma máquina saudável, que roda **472** casos. Os 12 skips **escondiam 63 asserções**
(a função faz `return` após o skip, e as sub-provas dentro dela nunca rodam). Nada no sumário
denunciava as ausentes, porque não havia total esperado contra o que comparar.

Fecho: **terceiro desfecho** `record_skip` (⊘ NÃO VERIFICADO, contador e lista próprios) +
`ONION_SELFTEST_STRICT=1`, que transforma ⊘ em falha e é o modo do CI, precedido de uma asserção de
capacidade do runner. Generaliza para a suíte inteira o fail-loud que o gate de design tokens já
aplicava só a si mesmo. A guarda anti-drift é **por construção** (`selftest-outcomes` (a)): um
`record_pass` na mesma linha de um guard de tooling reprova — o skip-como-✓ não volta por descuido.

**Terceira ocorrência, achada dogfoodando o próprio fix (pré-existente, corrigida junto).** O
pre-commit **nunca conseguiu** rodar o auto-teste: `git commit` exporta `GIT_DIR`/`GIT_INDEX_FILE`, as
sandboxes git da suíte os herdavam e operavam no repo errado — a suíte **abortava no caso 93 de 472**
e o hook anunciava *"self-test das guardas falhou"*. **Abort apresentado como veredito**: o gate era
inutilizável exatamente nos commits que tocam as guardas, e a saída empurrava para `--no-verify`.
Fecho: `unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE …` no preâmbulo, com teste `(f)` **load-bearing**
(a mutação prova que, sem o unset, o `git` de fato quebra). Sob o env do hook: 93 → **473** casos.

**Resíduo declarado:** não há asserção de *total esperado* de casos. Uma guarda que deixe de ser
chamada (não que pule — que suma) ainda reduz a cobertura em silêncio. O ⊘ cobre o skip, não o
desaparecimento. Foi essa mesma cegueira que deixou o abort no caso 93 passar por "falha de guarda".

### 1.4 Resolver remote-aware de `develop`: heurística de existência é insuficiente

Fonte: `docs/evolution/inbox/_processed/2026-07-25-contra-sinal-develop-fantasma-v2.md` (supersede de
`...-v1.md`).

Um fix **pendente de merge** no core propunha detectar `origin/develop` remotamente para resolver a
branch de integração. Contra-sinal de campo (verificado no repo real do adotante Arandek) mostrou que
a heurística de **existência** de `develop` não basta: o repo tinha `origin/develop` (43 dias parada,
95 commits atrás de `main`) mas **nenhum workflow de deploy a referenciava** — `deploy-prod.yml`
dispara em `push` a `main`; `deploy-staging.yml` dispara por tag, não por branch. `develop` não era
origem de nenhum ambiente; a prosa do repo declarava GitFlow, os triggers reais não implementavam.
Conclusão do sinal: o resolver correto precisa checar **autoridade** (é origem de deploy?), não só
**existência**. Fix ainda não corrigido no core no momento deste arquivo — é a mesma classe do item
1.2 (existência ≠ autoridade), agora aplicada a branches em vez de hooks.

---

## 2. Federação formal: maquinaria construída, uso real zero

Tensão documentada e **intencional** (não é bug) entre dois canais que às vezes se confundem:

| Canal | O que é | Uso real |
|---|---|---|
| **Co-evolução informal** (doc-bridge) | `docs/evolution/inbox/`, `inbound/`, `CHANGELOG.md`, `/meta:co-announce`, `/meta:co-deliver`, `/meta:co-relay` | **Ativo** — `docs/evolution/federation/CHANGELOG.md` tem 58 entradas datadas (`grep -c "^## "`), a mais recente do próprio ciclo em curso; adotantes reais (arandek, metagamify, granaai, pedro) trocam sinais por este canal quase diariamente |
| **Federação formal** (RFC-0003) | `/meta:federation-register`, `-publish`, `-check`, `-rollback`; `contracts/<id>.md`; ledger git | **Zero contratos registrados** — `docs/evolution/federation/` só tem `CHANGELOG.md`, `members.yaml`, `outbox/` e `onboarding-remote-member.md`; nenhum diretório `contracts/` existe no filesystem |

A auditoria dedicada (`docs/analysis/onion-federation-audit-2026-07-01.md`) já havia caracterizado
isso: "o núcleo mecânico da Federação formal está saudável (scripts rodam, fixtures passam)" mas os
achados reais eram (a) um bug de parsing que inutilizava a topologia granular de confiança — **corrigido
na mesma sessão** —, (b) guard de identidade do `/meta:adopt` estruturalmente vazio — **corrigido** —, e
(c) **drift sistemático de vocabulário**: três namespaces de "role" (contrato / membro / stamp) nunca
nomeados como eixos distintos entre `members.yaml`, RFC-0003, KB e comandos. A KB
`docs/knowledge-base/concepts/federation-usage-modes.md` foi criada para reconciliar os eixos, mas o
gap estrutural — federação formal como maquinaria gated à espera de "contrato quebrável ou nº de
projetos que torne o roteamento manual custoso" (`docs/evolution/rfc/rfc-0001-co-evolution-comms.md`,
linha que cita o gatilho) — permanece: **nenhum gatilho disparou até hoje**. Item #9 da mesma auditoria
nota que parte da maquinaria de F3 (Trust SDAAL) foi entregue **antes** do gate de F1 (10 entradas de
diário/1 semana; real registrado: 0 entradas) — sequenciamento interno da própria RFC diluído, ainda
sem correção formal.

---

## 3. `design-context` como 4ª dimensão: promoção provisória e gated

`CLAUDE.md` (linha 17) declara explicitamente a tensão em vez de escondê-la: o Sistema Onion cobre
"três dimensões peer do ciclo: produto, engenharia, compliance/governança" e nomeia `design/` como
**categoria de comando**, não dimensão — mas registra que "a promoção de `design-context` a peer é
provisória e gated". Ou seja: existe pressão de campo (comandos `design:generate` e `design:identity`,
mais a skill `DesignSync`) empurrando design a se tornar a 4ª vertical peer, e a decisão de
promover-ou-não está **deliberadamente não tomada**. Ver `docs/onion/inventory.md` — a contagem de 99
comandos inclui `design/` com 2 comandos, dentro das 10 categorias, sem status de dimensão.

---

## 4. Mitigação de inferência (L1-L6): doutrina no core, mecanismo fora dele

`docs/knowledge-base/concepts/inference-mitigation.md` (linha 3) é explícito sobre o próprio limite:
"**Status:** doutrina (contrato), mecanismo executável **NÃO-embarcado** (é do adotante — ver §6)".
A KB modela seis camadas negativas de defesa na fronteira de saída de um KG lido por um LLM legítimo
(L1 escopo de consulta → L6, cada uma com "o que reduz" / "o que NÃO fecha" documentado
explicitamente — nenhuma camada é declarada suficiente sozinha). A honestidade dura registrada na
própria KB: "quase toda defesa forte resolve o threat model errado" (capability-split, TEE, DP,
unlearning, anonimização — nenhuma protege contra o motor legítimo-para-o-dono lendo seu próprio
grafo). O core carrega a **doutrina** (o "o quê" e o "por quê"); o **mecanismo executável** (a
implementação real das seis camadas) é responsabilidade declarada do adotante, com a ressalva de que
os específicos de qualquer N=1 "ficam privados" — isto é, o core **não tem, e não terá por design**,
um SDAAL de inference-mitigation embarcado. Gated permanentemente, não apenas temporariamente.

---

## 5. `.claude/validation/` — o gate mecânico determinístico, e onde ele já falhou

`CLAUDE.md` (seção "Evolução do Core") nomeia o gate mecânico (`lint` + `selftest` + `inventory`) como
o "dogfood determinístico" — mas o próprio arandek achou, em campo, 5 achados SOFT persistentes no
lint do core mesmo após pin 5e3ea3ee46ac (`docs/evolution/inbox/_processed/2026-07-25-sinal-adocao-
arandek.md`, tabela final): 1 falso-positivo confirmado (doc de produto do adotante mencionando "100+
agentes" interpretado como contagem do próprio framework) e **3 "CATRACA-FRACA"** — o próprio lint se
auto-acusa via mensagem de violação (`kg-coverage-baseline.txt`, `doctrine-freshness-baseline.txt`,
`kb-vendored-link-baseline.txt`) de comparar contra `HEAD` local: **crescimento já commitado não é
detectado**. É o mesmo modo-de-falha que o sinal 1.3 nomeia em geral (gate correto, escopo estreito) —
aqui auto-confessado pelo próprio texto da violação, não inferido de fora.

---

## 6. Como este backlog se resolve (mecanismo, não prosa solta)

Princípio operante do core, citado em `CLAUDE.md` ("Evolução do Core"): todo ajuste vindo do uso real
deve **virar mecanismo** (guarda > KB > crumb), não ficar como achado avulso. Os itens 1.1–1.4 acima
são exatamente isso — sinais já triados, com fix sugerido pela própria fonte, **aguardando** virar
commit no core. Este arquivo não substitui o inbox; é o retrato datado (2026-07-25) do que ele contém
sem mecanismo aplicado ainda. Para o estado corrente, ler `docs/evolution/inbox/` diretamente (arquivos
não movidos para `_processed/`) e `/meta:co-evolve` no início de sessão.
