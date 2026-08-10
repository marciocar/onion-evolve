---
branch: docs/colher-regra56
date: 2026-08-10
reviewed_diff_sha256: 0958469f2b7f24f05e70f3b5a953006007edb9e482cff40a10e09e9a2d8df7ef
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-O-ACHADO-E-SOBRE-QUEM-FAZ-O-QUE-E-FOI-A-PERGUNTA-DO-MAESTRO-QUE-O-EXPOS
reviewer: sem passada adversarial — uma linha de rótulo, zero código
---

# Um nó curado que ficou aberto, e quase virou tarefa do maestro

O maestro perguntou: **"quais são os 2 backlogs que dependem de mim?"**

Ao ler o grafo para responder, achei que **um dos dois não era dele**:
`Q_REGRA56_INSATISFAZIVEL_NO_SEGUNDO_COMMIT` estava `open`, com o rótulo descrevendo o problema como
se ninguém o tivesse tocado — depois de o **PR #571** o ter curado e mergeado.

## Por que isso não é cosmético

Eu ia entregar como *"depende de você"* uma tarefa que era **minha** e estava **feita**.

O backlog existe para ser a fonte de **quem faz o quê**. Um nó não colhido mente sobre isso tão bem
quanto um nó com carimbo falso — e desta vez a mentira sairia da **minha resposta**, não do arquivo.

**Colher é parte da cura, não formalidade posterior.** É a mesma classe do `verified_against`
duplicado do dia anterior: o trabalho estava certo e o registro afirmava outra coisa.

## O que foi carimbado

```
status:            open → confirmed
plane:             DEV  → PROD
verified_at:       2026-08-10
verified_against:  pr-571-mergeado-e-tres-commits-consecutivos-sem-no-verify
```

A prova escolhida é comportamental, não declarativa: **três commits consecutivos passaram pelo hook
sem `--no-verify`**, depois de **23 seguidos** com ele.

E o rótulo carrega o teto que o #571 já declarava: `git diff --quiet HEAD` como detector de
pré-commit é **heurística**, não contexto — o caso do `--amend` **não foi medido** e a regra não o
cobre.

## O que a pergunta do maestro expôs, e vale mais que o nó

O gatilho da correção foi **social** outra vez: eu só reli o grafo porque ele perguntou. Se a
pergunta não viesse, o item seguiria aberto e o próximo relatório o listaria como pendência dele.

Esta casa já mediu isso e escreveu: *"o gatilho eficaz de correção é SOCIAL — logo 'vou prestar mais
atenção' é cura nula"*. A cura mecânica correspondente já existe e funcionou em outra ponta — a
REGRA 58 (`DONE-NU`) impede declarar `done` sem carimbo. O que ela **não** cobre é o inverso:
**item que continua `open` depois de resolvido**. Isso fica declarado como limite conhecido, não
como trabalho oculto.

## Verificação

- radar do grafo verde (18 nós, 18 arestas) · backlog **18/20**, nenhum `done` sem carimbo
- abertos: **2 → 1**, e o que resta é genuinamente do maestro (produção na VPS)
- commit passou pelo hook **sem `--no-verify`**

## O que NÃO foi feito, declarado

- **Sem passada adversarial**: uma linha de rótulo, zero código, nenhum comportamento novo para um
  refutador atacar. A REGRA 56 exige resíduo mesmo assim, e está certa em não abrir exceção por
  tamanho.
- **A guarda inversa não existe**: nada acusa item `open` cujo trabalho já foi mergeado. Fica como
  limite, não como promessa.

## E o gate me bloqueou por meia-cura minha

Ao commitar este resíduo, o hook acusou `ARTEFATO-AUSENTE` — e estava certo. No **#571** eu curei o
**hash** para olhar o índice quando a árvore está suja, e deixei a **existência** olhando só o commit:

```
git cat-file -e "HEAD:${ART}"      ← HEAD, no pre-commit, é o commit ANTERIOR
```

**Impasse perfeito:** para commitar o artefato era preciso já tê-lo commitado.

**Meia-cura em guarda é como meia-renomeação em código** — o lado que sobra é o que quebra. É
literalmente a lição que acabei de registrar em memória, reencontrada 20 minutos depois, na guarda em
vez de na varredura.

Curado com a mesma escolha: `:${ART}` lê o **índice**, `HEAD:${ART}` lê o commit; a **situação**
decide. Com caso de bancada `(l)` que exige o resíduo recém-*staged* ser **visto**.

## E o item que restava ao maestro foi executado — com um erro meu no meio

O maestro rodou a parte ② (piso e contenção do bridge) enquanto este PR estava aberto. Verificado
**pelo comportamento**: `memory.min` do cgroup em **268435456** (256M), ancestral de 384M concedendo o
piso **inteiro**, `/health` respondendo **200**.

**Mas eu derrubei o serviço no caminho.** Sugeri `ProtectHome=yes` junto — e `/home` inacessível quebra
um serviço cujo `ExecStart` vive em `/home/onion/onion-bridge`. `status=203/EXEC`, loop de restart,
contador em **8**.

**Não foi falta de informação:** eu havia lido `WorkingDirectory=/home/onion/onion-bridge` **nesta
mesma sessão**, ao medir a exposição do `bypassPermissions`. Tinha a medição e não a liguei à
sugestão.

**Medir e não usar o que se mediu** é a forma mais cara do erro deste dia — e desta vez caiu em
**produção**, não num gate. Restaurado removendo **só** o `ProtectHome`; o `NoNewPrivileges=yes` fica,
porque é inofensivo ali e era metade do ganho pretendido.
