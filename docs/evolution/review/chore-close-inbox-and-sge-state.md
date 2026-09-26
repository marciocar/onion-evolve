---
title: 'Fecho dos sinais, re-teste da migalha, e o carimbo do pin construído'
date: 2026-09-26
branch: chore/close-inbox-and-sge-state
reviewed_diff_sha256: 239a0d6fd2230f535decb67276ebae51b31580b2254899022e5050e30c8cba37
elenxo: nao
findings_total: 5
findings_real: 5
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, declarado: o diff move dois arquivos já tratados para  e acrescenta um re-teste MEDIDO a uma migalha. Não introduz mecanismo nem propõe desenho — um refutador não teria artefato novo para atacar. Os 3 achados são meus, dois pegos por guarda e um por medição.'
---

# Resíduo — fecho dos sinais e re-teste da migalha

## O que o `/catch-up` achou, e o que cada item rendeu

**(1) Dois sinais de adotantes parados no 1º nível do `inbox/`.** Ambos curados e mergeados em
2026-09-25 — o `kg-corpus-grep` absorvendo `label:` de aresta (do `sge`) e a prosa de co-evolução
cega ao papel `hub`. Ninguém os moveu, então o hook os contaria para sempre e o "lido/não-lido"
git-visível mentia. **Mover É o registro**, e untracked morre num `git clean`.

**(2) A migalha de 2026-07-18, RE-TESTADA por execução.** A doutrina é re-testar, nunca re-carimbar, e
o re-teste virou achado: **o ITEM2 está feito e DISPARA** — provado com fixture de um `decision` sem
`trace:` e sem `TRACES_TO`, e a saída do radar é exatamente o escopo que a própria migalha
especificou (advisory, aditivo, não-HARD). O S4 também está feito. E o re-teste produziu uma
**re-leitura**: a Trilha-no-KG e os C-gated **não são "retomar fresco"** — são esperas com gatilho, e a
redação antiga convidava a próxima sessão a puxá-los sem o gatilho ter disparado. Validade nova:
2026-12-26, e ela vale **porque houve medição**.

**(3) A sessão `adopt-sge` mentia sobre o estado.** O `STATE.md` parou em
`NEXT: Fase 2 — instalar o framework`, e o `/catch-up` o leu como **próximo passo autoritativo** — mas
o alvo está adotado desde 2026-09-24 e hoje roda PRs próprios (#19, #20) com lint 0 HARD. Quem seguisse
o ponteiro re-instalaria o framework por cima de um alvo vivo. Arquivada com README de encerramento
(local — `.claude/sessions/` é gitignored, então não aparece neste diff).

## Os três defeitos meus

| # | o quê | quem pegou |
|---|---|---|
| 1 | citei um caminho **inexistente em crase**, justamente para dizer que não existe | a guarda de ponteiro morto: caminho em crase **é** afirmação de que resolve |
| 2 | concluí "o relatório nunca chegou ao SGE" listando só `inbound/*.md` de 1º nível | ir olhar `_processed/`, que é **exatamente** onde mensagem tratada mora |
| 3 | li `127` depois de pipe, duas vezes | o hook anti-fail-open do shell |

**(2) é o mais instrutivo**, porque eu quase transformei **sucesso em achado**: o SGE tinha feito o
dever de casa nos dois sentidos do doc-bridge — recebeu e processou o relatório de adoção, e relayou um
sinal de volta que o core curou. Medir o lugar errado não produz "não sei"; produz uma conclusão
confiante e falsa.

**(1) tem uma ironia que vale guardar:** a guarda não distingue "cito o caminho porque ele existe" de
"cito o caminho para dizer que não existe" — e está **certa** em não distinguir, porque a segunda
intenção não é verificável. A cura é escrever a ausência em prosa, não em crase.

## O que entrou DEPOIS, por decisão do maestro: `ops/door-seal-pin.sh`

O nó `Q_QUEM_CARIMBA_O_PIN_DA_PORTA` foi **selado e construído** na mesma sessão. O desenho saiu de um
formulário com as opções nomeadas, e as quatro escolhas foram: irmão novo em `ops/` · verifica o remoto
**e** carimba · invocado pelo maestro após o push · construir agora.

**Por que `ops/` e não regra de lint** — o mesmo motivo do `ops/audit-adopters-registry.sh`, e o motivo
é mais forte que o arquivo: precisa do **clone da porta no disco** e do **remoto pela rede**, e nenhum
dos dois existe no CI. Guarda que só passa na máquina de uma pessoa é armadilha para as outras. E
**não** é extensão do `pin-integrity-check.sh`: aquele valida o pin do **stamp** do alvo e o histórico do
`onion/vendor` — pergunta diferente, nome parecido, e juntá-las por semelhança de nome seria o erro.

**A cadeia é toda de recusas:** pin legível → commit real deste core → ancestral de
`origin/<integração>` → **push provado pelo remoto** (clone == remoto) → carimbo cirúrgico, que ainda
recusa gravar se a contagem de linhas do arquivo mudar. Carimbar sem o passo do remoto afirmaria
**público** um commit que só existe no disco — e é a porta que mais importa das seis.

**Fica manual, por decisão:** as duas linhas de dado do `door-staleness-baseline.txt`. A razão medida
ficou escrita para quem automatizar.

## Os dois defeitos que o carimbo rendeu

| # | o quê | quem pegou |
|---|---|---|
| 4 | `onion_version` em **backtick dentro de heredoc não-citado** virou substituição de comando e saiu **vazio** na instrução nova | **executar** o materializador, não reler |
| 5 | identificadores `porta`/`origem`/`registro` na bancada | **REGRA 60 (Identificador de código em INGLÊS)** |

**(4) é a terceira ocorrência da mesma família em dois dias** — backtick em prosa dentro de contexto que
o interpreta. Ontem partiu o registro de dispensa ao meio (`printf '%s\n' \\`); hoje apagou uma palavra
de uma instrução. Nas duas vezes o artefato **saiu 0** e parecia certo; nas duas, o que revelou foi
rodar e **olhar a saída**. Não há guarda para isso ainda, e isso está dito em vez de suposto.

## Gate

- `lint-artifacts.sh` → **rc=0 · 0 HARD · 14 SOFT**
- `lint-selftest.sh --affected-staged --jobs auto` → **45 casos · 0 falhas**
- `inbox/` de 1º nível → **0 arquivos** (o hook para de contar, e o registro é durável por commit)
- `lint-selftest.sh --affected-staged --jobs auto` (leva completa) → **1498 casos · 0 falhas**
- `ops/door-seal-pin.sh onion-core --dry-run` no estado vivo → **rc=0, `registro já em dia`**
- `kg-radar.sh --integrity --schema` → **exit 0** no grafo do nó selado
