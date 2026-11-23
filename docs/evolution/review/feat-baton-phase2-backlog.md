---
branch: feat/baton-phase2-backlog
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: e91b500030781050c90977487146cfd818c0be54bb07c610cb8b540aaceaf76d
reviewed_code_sha256: 18da9500e3bef8d30ceb1eb6f8e33e9233c8cf012706e9a1d69edd6c982438c2
findings_total: 19
findings_real: 12
findings_blocking: 3
tokens: 97177
duration_min: 28
findings_fixed: 11
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: code-reviewer em contexto isolado (subagente só leitura com tm.sh falsos; recebeu o diff e o objetivo, não a minha conclusão)
nota: "12 achados reais, 11 curados no mesmo PR com caso e mutante, 1 aceito como especificação e declarado (a batida fala enquanto a oferta existir). Os 3 que bloqueavam: card ofertado duas vezes, sha que mudava a cada batida com o provedor fora do ar, e a doutrina que ainda dizia «não grava nem oferta»."
---

# A oferta saía em dobro, e a queda do provedor fazia a batida falar sem parar

## O que muda

A fase 2 da batuta (SAC-507, SAC-508 e SAC-509), empilhada sobre o PR #1716:

- **`IDLE_WITH_BACKLOG`:** a sessão está ociosa, não tem fila no grafo e tem card aberto no task manager com o prefixo de dono dela no título. A leitura é única por batida e tem cache curto. Se falhar, vira lacuna.
- **Vagas de agente:** o teto é 5, menos os `AGENT_RUNNING` da sessão `--self`. Vaga livre com card pronto da própria sessão vira oferta.
- **`--quiet`:** a batida não cala enquanto houver oferta.
- **`--record`:** grava o `pulses.tsv` só com a flag.

O dogfood ao vivo, com o Linear real, mediu 29 cards prontos e 2 sessões `IDLE_WITH_BACKLOG`, com as ofertas de cada uma. Ele também achou dois defeitos antes da revisão:

- o cache nascia 644 numa pasta com ACL padrão (curado com `chmod` explícito);
- o `AGENT_STALLED` antigo zerava as vagas (agora só `AGENT_RUNNING` conta, como pedia o brief).

## Achados

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | o mesmo card era ofertado a duas sessões, ou pela ociosa e pela vaga de agente; as linhas não se distinguiam | bloqueia | curado: o card sai uma vez, com a ociosa antes da vaga; a sessão sai como `nome·sid`. Caso (cl) |
| 2 | card `started` contava como pronto | importante | curado: pronto é só backlog, unstarted e triage. Caso (cc) |
| 3 | com o provedor fora do ar, o stderr (request-id) entrava no sha, e a batida nunca calava | bloqueia | curado: só o rc entra no sha; o stderr sai num aviso. Caso (cm) |
| 4 | a doutrina ainda dizia «o pulso não grava nem oferta»; o cabeçalho e a descrição diziam «só mede e lê» | bloqueia | curado nos três lugares |
| 5 | `search.query ""` traz 100 cards abertos e fechados misturados e esconde os abertos antigos | importante | curado: `item.list --state-type backlog,unstarted,triage --limit 100`; desvio do brief declarado no `baton.md` |
| 6 | uma resposta torta com rc 0 ficava 300 s no cache | menor | curado: grava só se for JSON com `issues`. Caso (cn) |
| 7 | no ClickUp a fase 2 é lacuna permanente | menor | declarado: hoje só o adapter do Linear tem o `item.list` |
| 8 | o stderr do tm.sh ia cru para o chat | menor | curado: o stderr só sai no aviso, com o token mascarado. Caso (cm) |
| 9 | o `--record` somava fila e backlog, inclusive de PARKED e UNREACHABLE | menor | curado: colunas `queue` e `backlog` separadas; quem não pode pegar sai com backlog 0. Caso (cj) |
| 10 | card de dois donos (`[a/b]`) sumia | menor | curado: vale para os dois. Caso (cb) |
| 11 | a batida fala enquanto a oferta existir, sem memória de oferta já feita | menor | aceito: é a especificação da SAC-508 (limite abaixo) |
| 12 | o cache não tinha chave de repo | menor | curado: `backlog-cache-<hash do repo>.json` |
| 13-19 | PARKED e UNREACHABLE sem oferta; rótulo sem diferenciar maiúscula; cache e BATON_NOW; falha nunca vira zero; sha estável; mutantes válidos; nota antiga do «não lê transcript» | confirmação | — |

## Mutantes

Cada caso novo tem o seu mutante, provado pela `_prove_mutation`. Casos (ca) a (cn); o (ck) troca o `AGENT_CAP_DEFAULT`.

Ajustes em casos antigos: o (a) e o (au) mudaram de âncora, e o (aa) passou a casar `^agent<TAB>`, porque a linha `agent_slots` não é subagente.

## Limites declarados

- **Achado 11:** uma sessão ociosa que não vai pegar o card faz toda batida falar. Uma memória de «oferta já feita» seria a fase 3 (precisa de estado gravado por padrão, o que o nível 0 não faz).
- **«aceita» sai `-` no `pulses.tsv`:** o pulso não vê se a sessão pegou o card. A aceitação se lê cruzando batidas.
- **Só o Linear tem o `item.list`:** nos outros providers o backlog é lacuna declarada.

## Re-revisão: a pilha desfeita (22/11)

O #1716, base deste PR, entrou na main por squash. O rebase `--onto origin/main` tirou daqui os commits do #1716 que
já estão na main; o diff deste PR passa a ser só a fase 2 da batuta, sobre a main. Nenhuma linha da fase 2 mudou: o
hash de código mudou porque a base passou da branch do #1716 para a main. O carimbo volta a `pendente` para o
`pr-finalize` carimbar de novo.

## Re-revisão pós-rebase (2026-11-23)

A main ganhou, desde a base deste PR, o `/meta:restart` (ac055e161), que acrescentou ao `baton-pulse.sh` a leitura do
marcador «sem despacho novo» (`<sid>.draining`) e do bilhete de retomada (`<sid>.tsv`), com aviso e a chave `rs` no
sha do estado. O rebase sobre a `origin/main` deu conflito em dois pontos do `baton-pulse.sh`, e os dois lados eram
acréscimos independentes no mesmo lugar:

- o bloco do reinício gracioso (main) e o bloco das ofertas da fase 2 (este PR) ficaram os dois, nessa ordem: o
  primeiro só escreve em `warns`, o segundo em `gaps` e `OFFERS`, sem dependência entre eles;
- o `state` do sha guarda as duas chaves novas, `'rs': sorted(RS)` (main) e `'of'` das ofertas (este PR).

O resto (doutrina, `baton.md`, `lint-selftest.sh`) entrou sem conflito. `bash -n` limpo.

Bancada: `lint-selftest.sh --families baton_pulse,restart_drain` (a segunda exercita o aviso do marcador dentro do
`baton-pulse.sh`, o lado da main): **190 passaram, 0 pularam, 0 falharam**.

Limite declarado, sem mudança de comportamento neste rebase: uma sessão em drenagem que esteja `IDLE_WITH_BACKLOG`
ainda recebe oferta de card, ao lado do aviso «SEM DESPACHO NOVO». Os dois saem na mesma batida; tirar a oferta da
sessão em drenagem é mudança de desenho, que pede caso e mutante próprios, e fica para depois.

O carimbo volta a `pendente` para o `pr-finalize` carimbar de novo.
